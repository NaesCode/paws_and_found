import logging
import requests
import numpy as np

from django.conf import settings
from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.measure import D
from django.db import transaction
from django.utils import timezone
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from .ai.features import cosine_similarity, extract_features
from .models import Match, Notification, Pet, PetEmbedding, Profile, Report, ReportEmbedding
from .serializers import MatchRespondSerializer

logger = logging.getLogger(__name__)

MAX_IMAGE_SIZE_BYTES = 10 * 1024 * 1024  # 10 MB limit


def _download_image(url: str, max_bytes: int = MAX_IMAGE_SIZE_BYTES) -> bytes:
    """
    Download image bytes from a remote URL with strict timeouts,
    size caps, and content-type validation.
    """
    try:
        response = requests.get(url, timeout=10, stream=True)
        response.raise_for_status()

        content_type = response.headers.get("Content-Type", "").lower()
        # Accept common image content types or octet-stream from storage buckets
        if not (content_type.startswith("image/") or "octet-stream" in content_type):
            raise ValueError(f"Invalid content type: {content_type}. Expected an image.")

        content = bytearray()
        for chunk in response.iter_content(chunk_size=65536):
            content.extend(chunk)
            if len(content) > max_bytes:
                raise ValueError("Image exceeds maximum allowed size (10 MB).")

        return bytes(content)
    except Exception as e:
        logger.warning("Failed to fetch image from %s: %s", url, e)
        raise


class HealthView(APIView):
    """Health check endpoint.
    Proves JWT verification and the database connection."""

    def get(self, request):
        Profile.objects.exists()
        return Response({
            "user_id": request.user.id,
            "db": "ok",
        })


class ReportAnalyzeView(APIView):
    """
    POST /api/reports/{id}/analyze/
    Idempotent AI feature extraction and candidate spatial matching.
    Caller must be the report's reporter.
    """

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

        try:
            # 2. Fetch the photo
            photo_bytes = _download_image(report.photo_url)

            # 3. Extract visual features
            feature_vector = extract_features(photo_bytes)

            with transaction.atomic():
                # 4. Upsert report embedding into private schema
                ReportEmbedding.objects.update_or_create(
                    report=report,
                    defaults={
                        "vector": feature_vector,
                        "updated_at": timezone.now(),
                    },
                )

                # 5. Candidate search with GeoDjango PostGIS
                # Find missing pets within radius, excluding reporter's own pets
                search_radius_m = getattr(settings, "MATCH_SEARCH_RADIUS_M", 10000)
                min_similarity = getattr(settings, "MATCH_MIN_SIMILARITY", 0.75)

                candidate_pets = (
                    Pet.objects.filter(
                        status="missing",
                        last_known_location__dwithin=(report.location, D(m=search_radius_m)),
                    )
                    .exclude(owner_id=report.reporter_id)
                    .annotate(distance=Distance("last_known_location", report.location))
                )

                matches_created_or_updated = 0

                # 6. Score candidate pets using cosine similarity
                for pet in candidate_pets:
                    try:
                        pet_embedding = PetEmbedding.objects.get(pet=pet)
                    except PetEmbedding.DoesNotExist:
                        continue  # Skip pets with no embedding

                    score = cosine_similarity(feature_vector, pet_embedding.vector)

                    if score >= min_similarity:
                        distance_km = round(pet.distance.km, 2) if hasattr(pet.distance, "km") else 0.0

                        match, _ = Match.objects.update_or_create(
                            report=report,
                            pet=pet,
                            defaults={
                                "similarity_score": round(score, 4),
                                "distance_km": distance_km,
                                "status": "pending",
                            },
                        )
                        matches_created_or_updated += 1

                        # Idempotent notifications: do not duplicate for the same match
                        if not Notification.objects.filter(related_match=match, type="match_found").exists():
                            Notification.objects.create(
                                user=pet.owner,
                                type="match_found",
                                message=f"A pet that looks like {pet.name} was reported nearby.",
                                related_match=match,
                            )

                        if not Notification.objects.filter(related_match=match, type="verification_request").exists():
                            Notification.objects.create(
                                user=report.reporter,
                                type="verification_request",
                                message=f"A potential match was found for your {report.animal_type} sighting.",
                                related_match=match,
                            )

                # 7. Mark report analysis as complete
                report.analysis_status = "done"
                report.save(update_fields=["analysis_status"])

            return Response({
                "status": "done",
                "report_id": str(report.id),
                "matches_scored": matches_created_or_updated,
            })

        except Exception as e:
            logger.exception("Error analyzing report %s: %s", id, e)
            try:
                report.analysis_status = "failed"
                report.save(update_fields=["analysis_status"])
            except Exception:
                pass
            return Response(
                {"error": "Analysis failed", "detail": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


class PetAnalyzeView(APIView):
    """
    POST /api/pets/{id}/analyze/
    Recomputes and upserts pet_embeddings from the pet's photo URLs.
    Caller must be the pet's owner.
    """

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

        if not pet.photo_urls:
            return Response(
                {"error": "Pet has no photos to extract embeddings from."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            vectors = []
            for photo_url in pet.photo_urls:
                try:
                    img_bytes = _download_image(photo_url)
                    vec = extract_features(img_bytes)
                    vectors.append(vec)
                except Exception as ex:
                    logger.warning("Could not download pet photo %s: %s", photo_url, ex)

            if not vectors:
                return Response(
                    {"error": "Could not download any valid pet photos."},
                    status=status.HTTP_502_BAD_GATEWAY,
                )

            # Average over photos and L2 normalize
            avg_vector = np.mean(vectors, axis=0)
            norm = np.linalg.norm(avg_vector)
            if norm > 0:
                final_vector = (avg_vector / norm).tolist()
            else:
                final_vector = avg_vector.tolist()

            PetEmbedding.objects.update_or_create(
                pet=pet,
                defaults={
                    "vector": [float(x) for x in final_vector],
                    "updated_at": timezone.now(),
                },
            )

            return Response({
                "status": "done",
                "pet_id": str(pet.id),
                "photos_analyzed": len(vectors),
            })

        except Exception as e:
            logger.exception("Error analyzing pet %s: %s", id, e)
            return Response(
                {"error": "Pet analysis failed", "detail": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


class MatchRespondView(APIView):
    """
    POST /api/matches/{id}/respond/
    Body: {"decision": "confirm" | "reject"}
    Caller must be the report's reporter or the pet's owner.
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

                # Pet is returned to safe and clears last known location
                pet = match.pet
                pet.status = "safe"
                pet.last_known_location = None
                pet.save(update_fields=["status", "last_known_location"])

                # Update the sighting report to found
                report = match.report
                report.status = "found"
                report.save(update_fields=["status"])

                # Close any other open missing reports for this pet
                Report.objects.filter(pet=pet, status="missing").update(status="found")

                # Notify the other party
                if caller_id == owner_id:
                    recipient = report.reporter
                    msg = f"Great news! The match for {pet.name} was confirmed by the owner."
                else:
                    recipient = pet.owner
                    msg = f"Great news! The sighting match for your pet {pet.name} was confirmed."

                Notification.objects.create(
                    user=recipient,
                    type="match_confirmed",
                    message=msg,
                    related_match=match,
                )

            elif decision == "reject":
                match.status = "rejected"
                match.save(update_fields=["status"])

        return Response({
            "status": match.status,
            "match_id": str(match.id),
        })
