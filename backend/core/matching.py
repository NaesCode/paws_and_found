import logging
from datetime import timedelta
from typing import List, NamedTuple, Optional, Tuple, Union

import numpy as np
from django.conf import settings
from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.measure import D
from django.db import IntegrityError, transaction
from django.utils import timezone

from .models import Match, Notification, Pet, PetEmbedding, Report, ReportEmbedding

logger = logging.getLogger(__name__)


class MatchSummary(NamedTuple):
    matches_created: int
    matches_updated: int
    notifications_sent: int


# =====================================================================
# Pure, testable helper functions
# =====================================================================


def radius_for(days_missing: float) -> int:
    """
    Returns the search radius in meters for a pet missing for `days_missing` days.
    Matches the last step in settings.MATCH_RADIUS_STEPS whose min_days_missing <= days_missing.
    """
    steps = getattr(settings, "MATCH_RADIUS_STEPS", [(0, 10_000), (3, 50_000), (7, 150_000)])
    matched_radius = steps[0][1]
    for min_days, radius in steps:
        if days_missing >= min_days:
            matched_radius = radius
    return matched_radius


def required_similarity(distance_m: float) -> Optional[float]:
    """
    Calculates the minimum required cosine similarity for a match at distance_m.
    Adds the extra similarity penalty from the first tier with distance_m <= max_distance_m.
    Distances beyond the last tier return None (never matched).
    """
    base = getattr(settings, "MATCH_BASE_SIMILARITY", 0.80)
    tiers = getattr(settings, "MATCH_DISTANCE_TIERS", [(10_000, 0.00), (50_000, 0.05), (150_000, 0.10)])

    for max_dist, extra in tiers:
        if distance_m <= max_dist:
            return round(base + extra, 4)
    return None


def cosine(v1: Union[List[float], np.ndarray], v2: Union[List[float], np.ndarray]) -> float:
    """
    Computes cosine similarity between two feature vectors.
    Returns float in range [0.0, 1.0].
    """
    a = np.asarray(v1, dtype=np.float32)
    b = np.asarray(v2, dtype=np.float32)

    norm_a = np.linalg.norm(a)
    norm_b = np.linalg.norm(b)

    if norm_a == 0.0 or norm_b == 0.0:
        return 0.0

    score = float(np.dot(a, b) / (norm_a * norm_b))
    return max(0.0, min(1.0, score))


def _calculate_days_missing(pet: Pet, now=None) -> float:
    if pet.missing_since is None:
        return 0.0
    now = now or timezone.now()
    delta = now - pet.missing_since
    return max(0.0, delta.total_seconds() / 86400.0)


# =====================================================================
# Database-facing matching engine functions
# =====================================================================


def match_report_against_pets(report: Report) -> MatchSummary:
    """
    Forward matching: Compares a new sighting report against currently missing pets.
    Triggered after POST /api/reports/{id}/analyze/.
    """
    # 1. Sightings must be independent stray/found reports with completed analysis
    if report.pet_id is not None or report.status not in ("stray", "found") or report.analysis_status != "done":
        logger.info("Report %s skipped from forward matching (not an eligible sighting)", report.id)
        return MatchSummary(0, 0, 0)

    try:
        report_embedding = ReportEmbedding.objects.get(report=report)
    except ReportEmbedding.DoesNotExist:
        logger.warning("Report %s has no embedding; skipping matching.", report.id)
        return MatchSummary(0, 0, 0)

    # 2. PostGIS spatial query against the largest configured distance tier
    tiers = getattr(settings, "MATCH_DISTANCE_TIERS", [(10_000, 0.00), (50_000, 0.05), (150_000, 0.10)])
    max_search_radius_m = tiers[-1][0]
    sighting_pad_hours = getattr(settings, "MATCH_SIGHTING_PAD_HOURS", 24)

    candidate_pets = (
        Pet.objects.filter(
            status="missing",
            last_known_location__isnull=False,
            last_known_location__dwithin=(report.location, D(m=max_search_radius_m)),
        )
        .exclude(owner_id=report.reporter_id)
        .annotate(distance=Distance("last_known_location", report.location))
        .select_related("owner")
    )

    qualifying_candidates: List[Tuple[float, float, Pet, Optional[Match]]] = []

    # 3. Evaluate each candidate against tiered distance and model version rules
    for pet in candidate_pets:
        if pet.missing_since is None:
            continue

        # Time window: report.created_at >= pet.missing_since - MATCH_SIGHTING_PAD_HOURS
        min_allowed_time = pet.missing_since - timedelta(hours=sighting_pad_hours)
        if report.created_at < min_allowed_time:
            continue

        # Per-pet radius based on days missing
        days_missing = max(0.0, (report.created_at - pet.missing_since).total_seconds() / 86400.0)
        pet_allowed_radius = radius_for(days_missing)

        dist_m = pet.distance.m if hasattr(pet.distance, "m") else float(pet.distance)
        if dist_m > pet_allowed_radius:
            continue

        req_sim = required_similarity(dist_m)
        if req_sim is None:
            continue

        try:
            pet_embedding = PetEmbedding.objects.get(pet=pet)
        except PetEmbedding.DoesNotExist:
            continue

        # Model version compatibility check
        if pet_embedding.model_version != report_embedding.model_version:
            logger.debug("Model version mismatch between report %s and pet %s", report.id, pet.id)
            continue

        score = cosine(report_embedding.vector, pet_embedding.vector)
        if score < req_sim:
            continue

        existing_match = Match.objects.filter(report=report, pet=pet).first()
        if existing_match and existing_match.status != "pending":
            # Never resurrect or reset confirmed or rejected matches
            continue

        qualifying_candidates.append((score, dist_m, pet, existing_match))

    # 4. Sort by similarity score descending
    qualifying_candidates.sort(key=lambda x: x[0], reverse=True)

    matches_created = 0
    matches_updated = 0
    notifications_sent = 0
    max_notified = getattr(settings, "MATCH_MAX_NOTIFIED_PER_RUN", 3)

    # 5. Persist matches and generate notifications inside an atomic transaction
    with transaction.atomic():
        for score, dist_m, pet, existing_match in qualifying_candidates:
            dist_km = round(dist_m / 1000.0, 2)
            score_rounded = round(score, 4)

            if existing_match:
                existing_match.similarity_score = score_rounded
                existing_match.distance_km = dist_km
                existing_match.save(update_fields=["similarity_score", "distance_km"])
                matches_updated += 1
                match_obj = existing_match
                is_new = False
            else:
                try:
                    match_obj, created = Match.objects.get_or_create(
                        report=report,
                        pet=pet,
                        defaults={
                            "similarity_score": score_rounded,
                            "distance_km": dist_km,
                            "status": "pending",
                            "triggered_by": "report",
                        },
                    )
                    if created:
                        matches_created += 1
                        is_new = True
                    else:
                        is_new = False
                except IntegrityError:
                    match_obj = Match.objects.get(report=report, pet=pet)
                    is_new = False

            # Notify top N newly created matches
            if is_new and matches_created <= max_notified:
                dist_km_msg = f"{round(dist_km, 1):.1f}"

                loc_context = f" in {report.location_name}" if getattr(report, "location_name", None) else ""

                # Notification to pet owner
                _, owner_notif_created = Notification.objects.get_or_create(
                    user=pet.owner,
                    related_match=match_obj,
                    type="match_found",
                    defaults={
                        "message": f"A pet that looks like {pet.name} was reported nearby{loc_context} ({dist_km_msg} km away).",
                    },
                )
                if owner_notif_created:
                    notifications_sent += 1

                # Notification to sighting reporter
                _, reporter_notif_created = Notification.objects.get_or_create(
                    user=report.reporter,
                    related_match=match_obj,
                    type="verification_request",
                    defaults={
                        "message": f"A potential match was found for your {report.animal_type} sighting{loc_context} ({dist_km_msg} km away).",
                    },
                )
                if reporter_notif_created:
                    notifications_sent += 1

    return MatchSummary(matches_created, matches_updated, notifications_sent)


def match_pet_against_reports(pet: Pet) -> MatchSummary:
    """
    Reverse matching: Compares a newly missing or re-analyzed missing pet against recent sightings.
    Triggered after POST /api/pets/{id}/analyze/ when pet is 'missing'.
    """
    if pet.status != "missing" or pet.last_known_location is None or pet.missing_since is None:
        logger.info("Pet %s skipped from reverse matching (status is not missing or missing coordinates/time)", pet.id)
        return MatchSummary(0, 0, 0)

    try:
        pet_embedding = PetEmbedding.objects.get(pet=pet)
    except PetEmbedding.DoesNotExist:
        logger.warning("Pet %s has no embedding; skipping matching.", pet.id)
        return MatchSummary(0, 0, 0)

    # 1. Search radius based on pet's days missing
    now = timezone.now()
    days_missing = _calculate_days_missing(pet, now)
    search_radius_m = radius_for(days_missing)

    # 2. Time window: sightings created >= pet.missing_since - MATCH_SIGHTING_PAD_HOURS
    sighting_pad_hours = getattr(settings, "MATCH_SIGHTING_PAD_HOURS", 24)
    min_created_at = pet.missing_since - timedelta(hours=sighting_pad_hours)

    candidate_reports = (
        Report.objects.filter(
            pet_id__isnull=True,
            status__in=["stray", "found"],
            analysis_status="done",
            created_at__gte=min_created_at,
            location__dwithin=(pet.last_known_location, D(m=search_radius_m)),
        )
        .exclude(reporter_id=pet.owner_id)
        .annotate(distance=Distance("location", pet.last_known_location))
        .select_related("reporter")
    )

    qualifying_candidates: List[Tuple[float, float, Report, Optional[Match]]] = []

    # 3. Filter candidates by tiered similarity and model version
    for report in candidate_reports:
        dist_m = report.distance.m if hasattr(report.distance, "m") else float(report.distance)
        req_sim = required_similarity(dist_m)
        if req_sim is None:
            continue

        try:
            report_embedding = ReportEmbedding.objects.get(report=report)
        except ReportEmbedding.DoesNotExist:
            continue

        if report_embedding.model_version != pet_embedding.model_version:
            logger.debug("Model version mismatch between pet %s and report %s", pet.id, report.id)
            continue

        score = cosine(pet_embedding.vector, report_embedding.vector)
        if score < req_sim:
            continue

        existing_match = Match.objects.filter(report=report, pet=pet).first()
        if existing_match and existing_match.status != "pending":
            continue

        qualifying_candidates.append((score, dist_m, report, existing_match))

    # 4. Sort by similarity score descending
    qualifying_candidates.sort(key=lambda x: x[0], reverse=True)

    matches_created = 0
    matches_updated = 0
    notifications_sent = 0
    max_notified = getattr(settings, "MATCH_MAX_NOTIFIED_PER_RUN", 3)

    # 5. Persist inside an atomic transaction
    with transaction.atomic():
        for score, dist_m, report, existing_match in qualifying_candidates:
            dist_km = round(dist_m / 1000.0, 2)
            score_rounded = round(score, 4)

            if existing_match:
                existing_match.similarity_score = score_rounded
                existing_match.distance_km = dist_km
                existing_match.save(update_fields=["similarity_score", "distance_km"])
                matches_updated += 1
                match_obj = existing_match
                is_new = False
            else:
                try:
                    match_obj, created = Match.objects.get_or_create(
                        report=report,
                        pet=pet,
                        defaults={
                            "similarity_score": score_rounded,
                            "distance_km": dist_km,
                            "status": "pending",
                            "triggered_by": "pet",
                        },
                    )
                    if created:
                        matches_created += 1
                        is_new = True
                    else:
                        is_new = False
                except IntegrityError:
                    match_obj = Match.objects.get(report=report, pet=pet)
                    is_new = False

            if is_new and matches_created <= max_notified:
                dist_km_msg = f"{round(dist_km, 1):.1f}"

                loc_context = f" in {report.location_name}" if getattr(report, "location_name", None) else ""

                # Notification to pet owner
                _, owner_notif_created = Notification.objects.get_or_create(
                    user=pet.owner,
                    related_match=match_obj,
                    type="match_found",
                    defaults={
                        "message": f"A pet that looks like {pet.name} was reported nearby{loc_context} ({dist_km_msg} km away).",
                    },
                )
                if owner_notif_created:
                    notifications_sent += 1

                # Notification to sighting reporter
                _, reporter_notif_created = Notification.objects.get_or_create(
                    user=report.reporter,
                    related_match=match_obj,
                    type="verification_request",
                    defaults={
                        "message": f"A potential match was found for your {report.animal_type} sighting{loc_context} ({dist_km_msg} km away).",
                    },
                )
                if reporter_notif_created:
                    notifications_sent += 1

    return MatchSummary(matches_created, matches_updated, notifications_sent)

