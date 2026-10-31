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
from .matching import MatchSummary, match_pet_against_reports, match_report_against_pets
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
            # If the user selected cat or dog, but the detector found no animal (confidence < 0.35 and no crop)
            # flag the post for admin review to prevent spam, offensive images, or non-animal posts.
            target_species = report.animal_type.lower()
            is_canine_or_feline = target_species in ("canine", "feline", "dog", "cat")
            is_unrecognized = not emb_result.used_crop and emb_result.detector_score < 0.35

            if is_canine_or_feline and is_unrecognized:
                with transaction.atomic():
                    report.moderation_status = "flagged"
                    report.moderation_notes = (
                        f"Flagged by AI: Low animal confidence score ({emb_result.detector_score:.2f}) "
                        f"for claimed {report.animal_type} sighting. Pending administrative verification."
                    )
                    report.analysis_status = "done"
                    report.save(update_fields=["moderation_status", "moderation_notes", "analysis_status"])

                logger.warning("Report %s flagged by AI moderation (score: %.2f)", report.id, emb_result.detector_score)

                return Response({
                    "status": "flagged",
                    "report_id": str(report.id),
                    "reason": "Image flagged for administrative review: no clear animal detected.",
                    "detector_score": emb_result.detector_score,
                    "matches_created": 0,
                    "matches_updated": 0,
                    "notifications_sent": 0,
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

        return Response({
            "status": match.status,
            "match_id": str(match.id),
        })
