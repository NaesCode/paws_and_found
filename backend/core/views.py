import logging
from typing import List

import requests
from django.conf import settings
from django.db import transaction
from django.utils import timezone
from rest_framework import status
from rest_framework.response import Response
from rest_framework.throttling import UserRateThrottle
from rest_framework.views import APIView

from .ai.features import average_embeddings, embed_image
from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.geos import Point
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.permissions import AllowAny
from .matching import MatchSummary, cosine, match_pet_against_reports, match_report_against_pets
from .models import Match, Notification, Pet, PetEmbedding, Profile, Report, ReportEmbedding
from .serializers import MatchRespondSerializer

logger = logging.getLogger(__name__)

ALLOWED_IMAGE_CONTENT_TYPES = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
}


class AiAnalyzeThrottle(UserRateThrottle):
    """Tighter per-user throttle applied only to CPU-intensive AI analyze endpoints."""
    scope = "ai_analyze"


def _download_image(url: str, max_bytes: int = None) -> bytes:
    """
    Download image bytes from an untrusted remote URL with strict security guards:
    - URL must start with {SUPABASE_URL}/storage/v1/object/public/animal-photos/
    - No HTTP redirects allowed (allow_redirects=False)
    - Strict connect/read timeouts (3, 10)
    - Streamed payload size cap (MAX_IMAGE_BYTES)
    - Content-Type header allowlist
    """
    if not url or not isinstance(url, str):
        raise ValueError("Invalid image URL provided.")

    supabase_url = getattr(settings, "SUPABASE_URL", "").rstrip("/")
    if supabase_url.endswith("/rest/v1"):
        supabase_url = supabase_url[:-8].rstrip("/")
    expected_prefix = f"{supabase_url}/storage/v1/object/public/animal-photos/"

    if not url.startswith(expected_prefix):
        raise ValueError(f"Untrusted photo URL. Must begin with {expected_prefix}")

    max_bytes = max_bytes or getattr(settings, "MAX_IMAGE_BYTES", 10 * 1024 * 1024)

    try:
        response = requests.get(url, timeout=(3, 10), stream=True, allow_redirects=False)
        response.raise_for_status()

        raw_content_type = response.headers.get("Content-Type", "")
        content_type = raw_content_type.split(";")[0].strip().lower()

        if content_type not in ALLOWED_IMAGE_CONTENT_TYPES:
            raise ValueError(f"Unsupported image content type: '{content_type}'")

        content = bytearray()
        for chunk in response.iter_content(chunk_size=65536):
            content.extend(chunk)
            if len(content) > max_bytes:
                raise ValueError(f"Image exceeds maximum size of {max_bytes} bytes.")

        return bytes(content)
    except Exception as e:
        logger.warning("Failed to download image from %s: %s", url, e)
        raise


class HealthView(APIView):
    """
    Health check endpoint.
    Proves JWT verification and database connectivity.
    """

    def get(self, request):
        Profile.objects.exists()
        return Response({
            "user_id": str(request.user.id),
            "db": "ok",
        })


class ReportAnalyzeView(APIView):
    """
    POST /api/reports/{id}/analyze/
    Caller must be the report's reporter.
    - If the report is an owner's missing listing (pet_id not null) or its status is not
      'stray'/'found': sets analysis_status='done' and skips matching.
    - Otherwise fetches photo, extracts 512-d feature vector with crop, upserts
      ReportEmbedding with current model_version, and runs forward matching.
    - Idempotent and atomic.
    """
    throttle_classes = [AiAnalyzeThrottle]

    def post(self, request, id):
        try:
            report = Report.objects.get(id=id)
        except Report.DoesNotExist:
            return Response({"error": "Report not found."}, status=status.HTTP_404_NOT_FOUND)

        # 1. Ownership check: caller must be report.reporter_id
        if str(report.reporter_id) != str(request.user.id):
            return Response(
                {"error": "You are not authorized to analyze this report."},
                status=status.HTTP_403_FORBIDDEN,
            )

        # 2. Skip matching if this is an owner's missing pet listing or non-sighting status
        if report.pet_id is not None or report.status not in ("stray", "found"):
            report.analysis_status = "done"
            report.save(update_fields=["analysis_status"])
            return Response({"status": "done", "skipped": "owner_listing"})

        try:
            # 3. Securely fetch photo and run AI embedding pipeline
            photo_bytes = _download_image(report.photo_url)
            emb_result = embed_image(photo_bytes)

            # Smart Content Moderation check via SSDLite320
            # If the detector found no animal (confidence < 0.25 and no crop) across any claimed species,
            # flag the post for admin review to prevent spam, unrelated images, or non-animal posts.
            is_unrecognized = not emb_result.used_crop and emb_result.detector_score < 0.25

            if is_unrecognized:
                with transaction.atomic():
                    report.moderation_status = "flagged"
                    report.moderation_notes = (
                        f"Flagged by AI: No clear animal detected (confidence: {emb_result.detector_score:.2f}) "
                        f"for claimed '{report.animal_type}' post. Pending administrative verification."
                    )
                    report.analysis_status = "done"
                    report.save(update_fields=["moderation_status", "moderation_notes", "analysis_status"])

                    # Notify author that their sighting was flagged for review
                    report_short_id = str(report.id)[:6].upper()
                    Notification.objects.create(
                        user_id=report.reporter_id,
                        type="warning",
                        message=(
                            f"Post Under Review: Sighting #{report_short_id} was flagged by AI as no clear animal was detected. "
                            f"If this was a mistake, an admin will review and verify it shortly."
                        ),
                    )

                logger.warning("Report %s flagged by AI moderation (score: %.2f)", report.id, emb_result.detector_score)

                return Response({
                    "status": "flagged",
                    "report_id": str(report.id),
                    "reason": "Image flagged for administrative review: no clear animal detected.",
                    "detector_score": emb_result.detector_score,
                    "matches_created": 0,
                    "matches_updated": 0,
                    "notifications_sent": 1,
                })

            with transaction.atomic():
                # 4. Upsert report embedding with model version
                ReportEmbedding.objects.update_or_create(
                    report=report,
                    defaults={
                        "vector": emb_result.vector,
                        "model_version": emb_result.model_version,
                        "updated_at": timezone.now(),
                    },
                )

                # 5. Mark report analysis as complete & approved
                report.analysis_status = "done"
                report.moderation_status = "approved"
                report.save(update_fields=["analysis_status", "moderation_status"])

            # 6. Run forward matching against currently missing pets
            summary = match_report_against_pets(report)

            return Response({
                "status": "done",
                "report_id": str(report.id),
                "matches_created": summary.matches_created,
                "matches_updated": summary.matches_updated,
                "notifications_sent": summary.notifications_sent,
            })

        except Exception as e:
            logger.exception("Error analyzing report %s: %s", id, e)
            try:
                report.analysis_status = "failed"
                report.save(update_fields=["analysis_status"])

                Notification.objects.create(
                    user_id=report.reporter_id,
                    type="report_update",
                    message="Photo Processing Issue: We couldn't process the photo for your recent sighting. Please ensure you upload a clear JPEG or PNG image.",
                )
            except Exception:
                pass
            return Response(
                {"error": "Analysis failed", "detail": "An internal error occurred during report analysis."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


class PetAnalyzeView(APIView):
    """
    POST /api/pets/{id}/analyze/
    Caller must be the pet's owner.
    - Builds embedding from up to 5 photos and upserts PetEmbedding.
    - Skips re-extraction if embedding exists for current model_version unless body has {"refresh": true}.
    - Runs reverse matching if pet status is 'missing'.
    - Returns counts only.
    """
    throttle_classes = [AiAnalyzeThrottle]

    def post(self, request, id):
        try:
            pet = Pet.objects.get(id=id)
        except Pet.DoesNotExist:
            return Response({"error": "Pet not found."}, status=status.HTTP_404_NOT_FOUND)

        # 1. Ownership check: caller must be pet.owner_id
        if str(pet.owner_id) != str(request.user.id):
            return Response(
                {"error": "You are not authorized to analyze this pet."},
                status=status.HTTP_403_FORBIDDEN,
            )

        current_version = getattr(settings, "EMBEDDING_MODEL_VERSION", "resnet18-in1k-v1+ssdlite-crop-v1")
        req_body = request.data if isinstance(request.data, dict) else {}
        force_refresh = bool(req_body.get("refresh", False))

        # Check existing embedding for current model version
        existing_embedding = PetEmbedding.objects.filter(pet_id=pet.id, model_version=current_version).first()

        try:
            if existing_embedding and not force_refresh:
                logger.info("Pet %s already has up-to-date embedding (%s); skipping photo re-extraction.", pet.id, current_version)
                photos_analyzed = 0
            else:
                if not pet.photo_urls:
                    return Response(
                        {"error": "Pet has no photos to extract embeddings from."},
                        status=status.HTTP_400_BAD_REQUEST,
                    )

                vectors: List[List[float]] = []
                # Cap at 5 photos
                candidate_urls = pet.photo_urls[:5]

                for photo_url in candidate_urls:
                    try:
                        img_bytes = _download_image(photo_url)
                        emb = embed_image(img_bytes)
                        vectors.append(emb.vector)
                    except Exception as ex:
                        logger.warning("Could not process pet photo %s: %s", photo_url, ex)

                if not vectors:
                    return Response(
                        {"error": "Could not download or process any valid pet photos."},
                        status=status.HTTP_502_BAD_GATEWAY,
                    )

                # Centroid average and re-normalize across photos
                final_vector = average_embeddings(vectors)

                PetEmbedding.objects.update_or_create(
                    pet=pet,
                    defaults={
                        "vector": final_vector,
                        "model_version": current_version,
                        "updated_at": timezone.now(),
                    },
                )
                photos_analyzed = len(vectors)

            # 2. If pet is currently missing, run reverse matching against recent sightings
            matches_created = 0
            matches_updated = 0
            notifications_sent = 0

            if pet.status == "missing":
                summary: MatchSummary = match_pet_against_reports(pet)
                matches_created = summary.matches_created
                matches_updated = summary.matches_updated
                notifications_sent = summary.notifications_sent

            return Response({
                "status": "done",
                "pet_id": str(pet.id),
                "photos_analyzed": photos_analyzed,
                "matches_created": matches_created,
                "matches_updated": matches_updated,
                "notifications_sent": notifications_sent,
            })

        except Exception as e:
            logger.exception("Error analyzing pet %s: %s", id, e)
            return Response(
                {"error": "Pet analysis failed", "detail": "An internal error occurred during pet analysis."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


class MatchRespondView(APIView):
    """
    POST /api/matches/{id}/respond/
    Body: {"decision": "confirm" | "reject"}
    Caller must be the report's reporter or the pet's owner.
    - Confirm: match 'confirmed', pet 'safe' (missing_since and last_known_location cleared),
      the pet's missing listing(s) 'found', notification to the other party.
    - Reject: match 'rejected'.
    - Rejects invalid transitions or double responses.
    """

    def post(self, request, id):
        try:
            match = Match.objects.select_related("report", "pet", "pet__owner", "report__reporter").get(id=id)
        except Match.DoesNotExist:
            return Response({"error": "Match not found."}, status=status.HTTP_404_NOT_FOUND)

        caller_id = str(request.user.id)
        reporter_id = str(match.report.reporter_id)
        owner_id = str(match.pet.owner_id)

        # 1. Ownership check: caller must be reporter or pet owner
        if caller_id not in (reporter_id, owner_id):
            return Response(
                {"error": "You are not authorized to respond to this match."},
                status=status.HTTP_403_FORBIDDEN,
            )

        # 2. Reject invalid transitions (e.g., responding twice)
        if match.status != "pending":
            return Response(
                {"error": f"Match has already been resolved with status '{match.status}'."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 3. Validate request body
        serializer = MatchRespondSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        decision = serializer.validated_data["decision"]

        with transaction.atomic():
            if decision == "confirm":
                match.status = "confirmed"
                match.save(update_fields=["status"])

                # Pet is returned to safe; clear missing_since and last_known_location
                pet = match.pet
                pet.status = "safe"
                pet.missing_since = None
                pet.last_known_location = None
                pet.save(update_fields=["status", "missing_since", "last_known_location"])

                # Update the sighting report to found
                report = match.report
                report.status = "found"
                report.save(update_fields=["status"])

                # Close any other open missing listings for this pet
                Report.objects.filter(pet=pet, status="missing").update(status="found")

                # Notify the other party
                if caller_id == owner_id:
                    recipient = report.reporter
                    msg = f"Great news! The match for {pet.name} was confirmed by the owner."
                else:
                    recipient = pet.owner
                    msg = f"Great news! The sighting match for your pet {pet.name} was confirmed."

                Notification.objects.get_or_create(
                    user=recipient,
                    related_match=match,
                    type="match_confirmed",
                    defaults={"message": msg},
                )

            elif decision == "reject":
                match.status = "rejected"
                match.save(update_fields=["status"])

                pet = match.pet
                report = match.report

                # Notify the other party about the rejection
                if caller_id == owner_id:
                    recipient = report.reporter
                    msg = f"Update on Sighting: The owner reviewed your sighting of the {report.animal_type} and concluded it was not {pet.name}. Thank you for your sharp eyes and support!"
                else:
                    recipient = pet.owner
                    msg = f"Update on Match: The sighting reporter reviewed the match for {pet.name} and indicated it was not a match."

                Notification.objects.get_or_create(
                    user=recipient,
                    related_match=match,
                    type="report_update",
                    defaults={"message": msg},
                )

        return Response({
            "status": match.status,
            "match_id": str(match.id),
        })


class MatchCandidatesView(APIView):
    """
    POST /api/ai/match-candidates/
    Ephemeral visual search for real-time camera pre-matching (Google Lens-style).

    Receives an unsubmitted image stream in-memory:
    1. Extracts 512-d ResNet-18 visual feature embedding with SSDLite animal cropping.
    2. Zero database or disk persistence for the uploaded photo (kept strictly in RAM).
    3. Finds active missing pets/reports in Supabase and annotates PostGIS geographic distance.
    4. Computes cosine similarity against existing precomputed pet/report embeddings.
    5. Returns ranked list of candidate matches formatted for AiMatchCandidate in Flutter.
    """
    parser_classes = [MultiPartParser, FormParser]
    permission_classes = [AllowAny]
    throttle_classes = [AiAnalyzeThrottle]

    def post(self, request):
        image_file = request.FILES.get("image")
        if not image_file:
            return Response(
                {"error": "No image file provided in multipart request."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            image_bytes = image_file.read()
        except Exception as e:
            return Response(
                {"error": f"Failed to read image stream: {e}"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not image_bytes:
            return Response(
                {"error": "Uploaded image is empty."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 1. Extract 512-d visual embedding using ResNet-18 (in-memory, ephemeral)
        try:
            emb_result = embed_image(image_bytes, use_detector=True)
            query_vector = emb_result.vector
        except Exception as ex:
            logger.warning("Ephemeral embed_image failed: %s", ex)
            return Response(
                {"error": f"AI visual feature extraction failed: {ex}"},
                status=status.HTTP_422_UNPROCESSABLE_ENTITY,
            )

        # Gate: Do not suggest missing pet matches if no animal was detected in the photo
        if not emb_result.used_crop and emb_result.detector_score < 0.25:
            logger.info(
                "MatchCandidatesView: No animal detected in query image (score=%.2f); skipping suggestions.",
                emb_result.detector_score,
            )
            return Response({"candidates": []})

        # 2. Parse GPS coordinates and animal type
        lat_raw = request.data.get("lat")
        lng_raw = request.data.get("lng")
        point = None
        if lat_raw is not None and lng_raw is not None:
            try:
                lat = float(lat_raw)
                lng = float(lng_raw)
                if -90.0 <= lat <= 90.0 and -180.0 <= lng <= 180.0:
                    point = Point(lng, lat, srid=4326)
            except (ValueError, TypeError):
                point = None

        animal_type = str(request.data.get("animal_type", "")).strip().lower()

        # 3. Query active missing reports
        missing_reports = (
            Report.objects.filter(status="missing")
            .select_related("pet", "pet__owner", "reporter")
        )

        if hasattr(Report, "moderation_status"):
            missing_reports = missing_reports.exclude(moderation_status="flagged")

        # Visual search scans all active missing reports regardless of form dropdown
        # (True Google Lens behavior: visual features determine the match)

        # Annotate distance if spotter's GPS is provided
        if point is not None:
            missing_reports = missing_reports.annotate(
                distance=Distance("location", point)
            )

        candidates = []
        for report in missing_reports[:30]:
            pet = report.pet
            pet_embedding = None
            if pet:
                pet_embedding = PetEmbedding.objects.filter(pet_id=pet.id).first()

            report_embedding = None
            if not pet_embedding:
                report_embedding = ReportEmbedding.objects.filter(report_id=report.id).first()

            target_vector = None
            if pet_embedding and pet_embedding.vector:
                target_vector = pet_embedding.vector
            elif report_embedding and report_embedding.vector:
                target_vector = report_embedding.vector

            if not target_vector:
                continue

            score = cosine(query_vector, target_vector)

            # Require minimum visual similarity threshold (>= 0.60) to consider a plausible match
            if score < 0.60:
                continue

            distance_km = None
            if point is not None and hasattr(report, "distance") and report.distance is not None:
                try:
                    distance_km = round(report.distance.km, 1)
                except Exception:
                    distance_km = None

            pet_name = pet.name if (pet and pet.name) else (report.description[:20] if report.description else "Missing Pet")
            species = pet.species if (pet and pet.species) else report.animal_type
            photo_url = report.photo_url or (pet.photo_urls[0] if (pet and pet.photo_urls) else "")
            owner_name = report.reporter.name if (report.reporter and report.reporter.name) else (pet.owner.name if (pet and pet.owner) else "Pet Owner")
            missing_since = pet.missing_since if (pet and pet.missing_since) else report.created_at

            candidates.append({
                "pet_id": str(report.pet_id or report.id),
                "report_id": str(report.id),
                "pet_name": pet_name,
                "species": species,
                "photo_url": photo_url,
                "similarity_score": round(score, 4),
                "similarity_percent": int(round(score * 100)),
                "distance_km": distance_km,
                "last_seen_location": report.location_name or "Nearby Area",
                "owner_name": owner_name,
                "missing_since": missing_since.isoformat() if missing_since else None,
            })

        # Sort: Highest visual similarity score first, closest distance second
        candidates.sort(
            key=lambda c: (c["similarity_score"], -(c["distance_km"] if c["distance_km"] is not None else 9999)),
            reverse=True,
        )

        return Response({"candidates": candidates[:5]})