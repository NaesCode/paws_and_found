import uuid
from contextlib import contextmanager
from unittest.mock import MagicMock, patch
import jwt
import numpy as np

from django.conf import settings
from django.test import SimpleTestCase, override_settings
from rest_framework import status
from rest_framework.test import APIClient

from .ai.features import cosine_similarity, extract_features
from .authentication import SupabaseUser
from .matching import cosine, radius_for, required_similarity


@contextmanager
def dummy_atomic():
    """Mock context manager for transaction.atomic() during unit tests."""
    yield


class MatchingRuleTests(SimpleTestCase):
    """Tests for pure matching engine rules: time-widened radius and distance-tiered similarity."""

    def test_radius_for_time_steps(self):
        # 0 days -> 10 km
        self.assertEqual(radius_for(0.0), 10_000)
        self.assertEqual(radius_for(1.5), 10_000)
        self.assertEqual(radius_for(2.99), 10_000)

        # 3 days -> 50 km
        self.assertEqual(radius_for(3.0), 50_000)
        self.assertEqual(radius_for(5.0), 50_000)
        self.assertEqual(radius_for(6.99), 50_000)

        # 7+ days -> 150 km
        self.assertEqual(radius_for(7.0), 150_000)
        self.assertEqual(radius_for(30.0), 150_000)

    @override_settings(MATCH_BASE_SIMILARITY=0.80)
    def test_required_similarity_distance_tiers(self):
        # Base: 0.80
        # Tier 1: <= 10 km -> 0.80 + 0.00 = 0.80
        self.assertEqual(required_similarity(0), 0.80)
        self.assertEqual(required_similarity(5_000), 0.80)
        self.assertEqual(required_similarity(10_000), 0.80)

        # Tier 2: 10 km - 50 km -> 0.80 + 0.05 = 0.85
        self.assertEqual(required_similarity(10_001), 0.85)
        self.assertEqual(required_similarity(30_000), 0.85)
        self.assertEqual(required_similarity(50_000), 0.85)

        # Tier 3: 50 km - 150 km -> 0.80 + 0.10 = 0.90
        self.assertEqual(required_similarity(50_001), 0.90)
        self.assertEqual(required_similarity(100_000), 0.90)
        self.assertEqual(required_similarity(150_000), 0.90)

        # Beyond last tier: > 150 km -> None (never matched)
        self.assertIsNone(required_similarity(150_001))
        self.assertIsNone(required_similarity(500_000))

    def test_cosine_similarity_pure(self):
        v1 = [1.0, 0.0]
        v2 = [1.0, 0.0]
        self.assertAlmostEqual(cosine(v1, v2), 1.0)

        v_ortho = [0.0, 1.0]
        self.assertAlmostEqual(cosine(v1, v_ortho), 0.0)

        v_zero = [0.0, 0.0]
        self.assertEqual(cosine(v1, v_zero), 0.0)


class CosineSimilarityTests(SimpleTestCase):
    """Tests for vector feature extraction and cosine similarity calculations (no DB needed)."""

    def test_identical_vectors_have_similarity_one(self):
        v = [0.6, 0.8]
        score = cosine_similarity(v, v)
        self.assertAlmostEqual(score, 1.0, places=4)

    def test_orthogonal_vectors_have_similarity_zero(self):
        v1 = [1.0, 0.0, 0.0]
        v2 = [0.0, 1.0, 0.0]
        score = cosine_similarity(v1, v2)
        self.assertAlmostEqual(score, 0.0, places=4)

    def test_zero_vector_returns_zero(self):
        v1 = [0.0, 0.0, 0.0]
        v2 = [1.0, 2.0, 3.0]
        self.assertEqual(cosine_similarity(v1, v2), 0.0)

    @patch("core.ai.features.embed_image")
    def test_extract_features_is_deterministic_and_normalized(self, mock_embed):
        from .ai.features import EmbeddingResult
        fake_vec = [float(1.0 / np.sqrt(512))] * 512
        mock_embed.return_value = EmbeddingResult(
            vector=fake_vec,
            model_version="resnet18-in1k-v1+ssdlite-crop-v1",
            used_crop=True,
            detector_score=0.85,
        )
        data = b"sample_animal_photo_bytes_12345"
        vec1 = extract_features(data)
        vec2 = extract_features(data)

        self.assertEqual(vec1, vec2)
        self.assertEqual(len(vec1), 512)

        norm = np.linalg.norm(vec1)
        self.assertAlmostEqual(norm, 1.0, places=4)


class AuthenticationUnitTests(SimpleTestCase):
    """Tests for SupabaseJWTAuthentication supporting HS256 and asymmetric JWKS."""

    def setUp(self):
        self.client = APIClient()
        self.user_id = str(uuid.uuid4())
        self.secret = "test_supabase_jwt_secret_for_unit_tests_only"

    @patch("core.models.Profile.objects.exists", return_value=True)
    @override_settings(SUPABASE_JWT_SECRET="test_supabase_jwt_secret_for_unit_tests_only")
    def test_hs256_token_authentication_success(self, mock_exists):
        payload = {
            "sub": self.user_id,
            "email": "testuser@pawsandfound.org",
            "aud": "authenticated",
        }
        token = jwt.encode(payload, self.secret, algorithm="HS256")

        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
        response = self.client.get("/api/health/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["user_id"], self.user_id)
        self.assertEqual(response.data["db"], "ok")

    def test_unauthenticated_request_returns_401(self):
        response = self.client.get("/api/health/")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_invalid_token_returns_401(self):
        self.client.credentials(HTTP_AUTHORIZATION="Bearer completely_invalid_jwt_token")
        response = self.client.get("/api/health/")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    @patch("core.models.Profile.objects.exists", return_value=True)
    @patch("core.authentication._jwks")
    def test_asymmetric_es256_jwks_authentication(self, mock_jwks, mock_exists):
        mock_key = MagicMock()
        mock_key.key = "mock_public_key"
        mock_client = MagicMock()
        mock_client.get_signing_key_from_jwt.return_value = mock_key
        mock_jwks.return_value = mock_client

        with patch("jwt.get_unverified_header", return_value={"alg": "ES256"}), \
             patch("jwt.decode", return_value={"sub": self.user_id, "email": "jwks@example.com"}):
            self.client.credentials(HTTP_AUTHORIZATION="Bearer mock_es256_token")
            response = self.client.get("/api/health/")

            self.assertEqual(response.status_code, status.HTTP_200_OK)
            self.assertEqual(response.data["user_id"], self.user_id)


@patch("core.views.transaction.atomic", dummy_atomic)
class OrchestratorOwnershipAndWorkflowTests(SimpleTestCase):
    """
    Tests ownership validation, AI matching pipeline, idempotency,
    and match confirmation/rejection workflow using SimpleTestCase (no cloud CREATEDB needed).
    """

    def setUp(self):
        self.client = APIClient()
        self.user_a_id = uuid.uuid4()
        self.user_b_id = uuid.uuid4()
        self.report_id = uuid.uuid4()
        self.pet_id = uuid.uuid4()
        self.match_id = uuid.uuid4()

    def _auth_as(self, user_id: uuid.UUID):
        self.client.force_authenticate(user=SupabaseUser(str(user_id)))

    @patch("core.models.Report.objects.get")
    def test_analyze_report_forbidden_for_non_reporter(self, mock_get_report):
        mock_report = MagicMock()
        mock_report.id = self.report_id
        mock_report.reporter_id = self.user_b_id  # Reporter is Bob
        mock_get_report.return_value = mock_report

        # Alice (User A) attempts to analyze Bob's report -> 403 Forbidden
        self._auth_as(self.user_a_id)
        response = self.client.post(f"/api/reports/{self.report_id}/analyze/")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    @patch("core.models.Pet.objects.get")
    def test_analyze_pet_forbidden_for_non_owner(self, mock_get_pet):
        mock_pet = MagicMock()
        mock_pet.id = self.pet_id
        mock_pet.owner_id = self.user_a_id  # Owner is Alice
        mock_get_pet.return_value = mock_pet

        # Bob (User B) attempts to trigger pet analysis for Alice's pet -> 403 Forbidden
        self._auth_as(self.user_b_id)
        response = self.client.post(f"/api/pets/{self.pet_id}/analyze/")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    @patch("core.models.PetEmbedding.objects.filter")
    @patch("core.models.PetEmbedding.objects.update_or_create")
    @patch("core.views.embed_image")
    @patch("core.views._download_image")
    @patch("core.models.Pet.objects.get")
    def test_analyze_pet_success_workflow(
        self, mock_get_pet, mock_download, mock_embed, mock_emb_update, mock_filter
    ):
        from core.ai.features import EmbeddingResult

        mock_filter.return_value.first.return_value = None
        mock_pet = MagicMock()
        mock_pet.id = self.pet_id
        mock_pet.pk = self.pet_id
        mock_pet.owner_id = self.user_a_id
        mock_pet.status = "safe"
        mock_pet.photo_urls = ["https://example.com/pet.jpg"]
        mock_get_pet.return_value = mock_pet
        mock_download.return_value = b"sample_pet_photo_bytes"
        mock_embed.return_value = EmbeddingResult(
            vector=[1.0 / np.sqrt(512)] * 512,
            model_version="resnet18-in1k-v1+ssdlite-crop-v1",
            used_crop=True,
            detector_score=0.92,
        )

        self._auth_as(self.user_a_id)
        response = self.client.post(f"/api/pets/{self.pet_id}/analyze/", data={"refresh": True}, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["status"], "done")
        self.assertEqual(response.data["photos_analyzed"], 1)
        mock_emb_update.assert_called_once()

    @patch("core.models.PetEmbedding.objects.filter")
    @patch("core.views.embed_image")
    @patch("core.models.Pet.objects.get")
    def test_analyze_pet_skips_when_embedding_up_to_date(self, mock_get_pet, mock_embed, mock_filter):
        mock_filter.return_value.first.return_value = MagicMock()  # existing embedding present
        mock_pet = MagicMock()
        mock_pet.id = self.pet_id
        mock_pet.pk = self.pet_id
        mock_pet.owner_id = self.user_a_id
        mock_pet.status = "safe"
        mock_get_pet.return_value = mock_pet

        self._auth_as(self.user_a_id)
        response = self.client.post(f"/api/pets/{self.pet_id}/analyze/", data={}, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["status"], "done")
        self.assertEqual(response.data["photos_analyzed"], 0)
        mock_embed.assert_not_called()

    @patch("core.models.Report.objects.get")
    def test_analyze_report_skips_owner_listing(self, mock_get_report):
        mock_report = MagicMock()
        mock_report.id = self.report_id
        mock_report.reporter_id = self.user_a_id
        mock_report.pet_id = self.pet_id  # Owner missing listing has pet_id set
        mock_report.status = "missing"
        mock_get_report.return_value = mock_report

        self._auth_as(self.user_a_id)
        response = self.client.post(f"/api/reports/{self.report_id}/analyze/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["status"], "done")
        self.assertEqual(response.data["skipped"], "owner_listing")
        self.assertEqual(mock_report.analysis_status, "done")

    @patch("core.models.Match.objects.select_related")
    def test_respond_forbidden_for_third_party(self, mock_select_related):
        mock_match = MagicMock()
        mock_match.id = self.match_id
        mock_match.status = "pending"
        mock_match.report.reporter_id = self.user_b_id
        mock_match.pet.owner_id = self.user_a_id
        mock_select_related.return_value.get.return_value = mock_match

        third_party_id = uuid.uuid4()
        self._auth_as(third_party_id)

        response = self.client.post(
            f"/api/matches/{self.match_id}/respond/",
            data={"decision": "confirm"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    @patch("core.models.Match.objects.select_related")
    def test_cannot_respond_twice(self, mock_select_related):
        mock_match = MagicMock()
        mock_match.id = self.match_id
        mock_match.status = "confirmed"  # Already resolved
        mock_match.report.reporter_id = self.user_b_id
        mock_match.pet.owner_id = self.user_a_id
        mock_select_related.return_value.get.return_value = mock_match

        self._auth_as(self.user_a_id)
        response = self.client.post(
            f"/api/matches/{self.match_id}/respond/",
            data={"decision": "confirm"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("already been resolved", response.data["error"])

    @patch("core.models.Notification.objects.get_or_create")
    @patch("core.models.Report.objects.filter")
    @patch("core.models.Match.objects.select_related")
    def test_respond_confirm_workflow(self, mock_select_related, mock_report_filter, mock_notif_get_or_create):
        mock_match = MagicMock()
        mock_match.id = self.match_id
        mock_match.status = "pending"
        mock_match.report.reporter_id = self.user_b_id
        mock_match.report.status = "stray"
        mock_match.pet.owner_id = self.user_a_id
        mock_match.pet.name = "Milo"
        mock_match.pet.status = "missing"
        mock_match.pet.missing_since = None
        mock_match.pet.last_known_location = None
        mock_select_related.return_value.get.return_value = mock_match
        mock_notif_get_or_create.return_value = (MagicMock(), True)

        # Pet owner (User A) confirms the match
        self._auth_as(self.user_a_id)
        response = self.client.post(
            f"/api/matches/{self.match_id}/respond/",
            data={"decision": "confirm"},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["status"], "confirmed")
        self.assertEqual(mock_match.status, "confirmed")
        self.assertEqual(mock_match.pet.status, "safe")
        self.assertIsNone(mock_match.pet.missing_since)
        self.assertIsNone(mock_match.pet.last_known_location)
        self.assertEqual(mock_match.report.status, "found")
        mock_notif_get_or_create.assert_called_once()

    @patch("core.models.Notification.objects.get_or_create")
    @patch("core.models.Match.objects.select_related")
    def test_respond_reject_workflow(self, mock_select_related, mock_notif_get_or_create):
        mock_match = MagicMock()
        mock_match.id = self.match_id
        mock_match.status = "pending"
        mock_match.report.reporter_id = self.user_b_id
        mock_match.report.reporter = self.user_b_id
        mock_match.report.animal_type = "dog"
        mock_match.pet.owner_id = self.user_a_id
        mock_match.pet.name = "Milo"
        mock_select_related.return_value.get.return_value = mock_match
        mock_notif_get_or_create.return_value = (MagicMock(), True)

        # Pet owner (User A) rejects the match
        self._auth_as(self.user_a_id)
        response = self.client.post(
            f"/api/matches/{self.match_id}/respond/",
            data={"decision": "reject"},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["status"], "rejected")
        self.assertEqual(mock_match.status, "rejected")
        mock_notif_get_or_create.assert_called_once()
        call_kwargs = mock_notif_get_or_create.call_args[1]
        self.assertEqual(call_kwargs["user"], self.user_b_id)
        self.assertEqual(call_kwargs["type"], "report_update")
        self.assertIn("not Milo", call_kwargs["defaults"]["message"])

    @patch("core.models.Notification.objects.create")
    @patch("core.views.match_report_against_pets")
    @patch("core.views.embed_image")
    @patch("core.models.ReportEmbedding.objects.update_or_create")
    @patch("core.views._download_image")
    @patch("core.models.Report.objects.get")
    def test_analyze_report_smart_moderation_flags_non_animal(
        self,
        mock_get_report,
        mock_download,
        mock_emb_update,
        mock_embed,
        mock_match,
        mock_notif_create,
    ):
        from core.ai.features import EmbeddingResult

        mock_report = MagicMock()
        mock_report.id = self.report_id
        mock_report.reporter_id = self.user_b_id
        mock_report.photo_url = "https://supabase.example.com/storage/v1/object/public/animal-photos/spam.jpg"
        mock_report.animal_type = "dog"
        mock_report.pet_id = None
        mock_report.status = "stray"
        mock_report.analysis_status = "pending"
        mock_get_report.return_value = mock_report
        mock_download.return_value = b"fake_meme_or_spam_bytes"

        # Mock SSDLite320 detecting no animal (score = 0.0, no crop)
        mock_embed.return_value = EmbeddingResult(
            vector=[1.0 / np.sqrt(512)] * 512,
            model_version="resnet18-in1k-v1+ssdlite-crop-v1",
            used_crop=False,
            detector_score=0.05,
        )

        self._auth_as(self.user_b_id)
        response = self.client.post(
            f"/api/reports/{self.report_id}/analyze/",
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["status"], "flagged")
        self.assertEqual(mock_report.moderation_status, "flagged")
        self.assertIn("Flagged by AI", mock_report.moderation_notes)
        self.assertEqual(response.data["matches_created"], 0)
        self.assertEqual(response.data["notifications_sent"], 1)
        mock_notif_create.assert_called_once()
        call_kwargs = mock_notif_create.call_args[1]
        self.assertEqual(call_kwargs["user_id"], self.user_b_id)
        self.assertEqual(call_kwargs["type"], "warning")
        self.assertIn("Post Under Review", call_kwargs["message"])

    @patch("core.models.PetEmbedding.objects.filter")
    @patch("core.models.Notification.objects.create")
    @patch("core.models.PetEmbedding.objects.update_or_create")
    @patch("core.views.embed_image")
    @patch("core.views._download_image")
    @patch("core.models.Pet.objects.get")
    def test_analyze_pet_smart_moderation_flags_non_animal(
        self,
        mock_get_pet,
        mock_download,
        mock_embed,
        mock_emb_update,
        mock_notif_create,
        mock_emb_filter,
    ):
        from core.ai.features import EmbeddingResult

        mock_emb_filter.return_value.first.return_value = None

        mock_pet = MagicMock()
        mock_pet.id = self.pet_id
        mock_pet.owner_id = self.user_a_id
        mock_pet.name = "Buster"
        mock_pet.photo_urls = ["https://supabase.example.com/storage/v1/object/public/animal-photos/fake_pet.jpg"]
        mock_pet.status = "safe"
        mock_get_pet.return_value = mock_pet
        mock_download.return_value = b"fake_non_animal_selfie_bytes"

        # SSDLite320 detecting no animal (score = 0.08, no crop)
        mock_embed.return_value = EmbeddingResult(
            vector=[1.0 / np.sqrt(512)] * 512,
            model_version="resnet18-in1k-v1+ssdlite-crop-v1",
            used_crop=False,
            detector_score=0.08,
        )

        self._auth_as(self.user_a_id)
        response = self.client.post(f"/api/pets/{self.pet_id}/analyze/")

        self.assertEqual(response.status_code, status.HTTP_422_UNPROCESSABLE_ENTITY)
        self.assertEqual(response.data["status"], "flagged_unrelated")
        self.assertIn("No clear animal", response.data["error"])
        mock_emb_update.assert_not_called()
        mock_notif_create.assert_called_once()
        call_kwargs = mock_notif_create.call_args[1]
        self.assertEqual(call_kwargs["user_id"], self.user_a_id)
        self.assertEqual(call_kwargs["type"], "warning")
        self.assertIn("Pet Profile Under Review", call_kwargs["message"])

    @patch("core.views.match_report_against_pets")
    @patch("core.views.embed_image")
    @patch("core.models.ReportEmbedding.objects.update_or_create")
    @patch("core.views._download_image")
    @patch("core.models.Report.objects.get")
    def test_analyze_report_workflow_and_idempotency(
        self,
        mock_get_report,
        mock_download,
        mock_report_emb,
        mock_embed,
        mock_match_fn,
    ):
        from core.ai.features import EmbeddingResult
        from core.matching import MatchSummary

        mock_report = MagicMock()
        mock_report.id = self.report_id
        mock_report.reporter_id = self.user_b_id
        mock_report.photo_url = "https://supabase.example.com/storage/v1/object/public/animal-photos/dog.jpg"
        mock_report.animal_type = "dog"
        mock_report.pet_id = None
        mock_report.status = "stray"
        mock_report.analysis_status = "pending"
        mock_get_report.return_value = mock_report
        mock_download.return_value = b"golden_retriever_photo_bytes"
        mock_embed.return_value = EmbeddingResult(
            vector=[1.0 / np.sqrt(512)] * 512,
            model_version="resnet18-in1k-v1+ssdlite-crop-v1",
            used_crop=True,
            detector_score=0.88,
        )
        mock_report_emb.return_value = (MagicMock(), True)

        # Case 1: First run — 1 match created, 2 notifications sent
        mock_match_fn.return_value = MatchSummary(
            matches_created=1, matches_updated=0, notifications_sent=2
        )
        self._auth_as(self.user_b_id)
        response = self.client.post(f"/api/reports/{self.report_id}/analyze/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["status"], "done")
        self.assertEqual(response.data["matches_created"], 1)
        self.assertEqual(response.data["notifications_sent"], 2)
        self.assertEqual(mock_report.analysis_status, "done")
        mock_match_fn.assert_called_once_with(mock_report)

        # Case 2: Idempotency — re-running produces 0 new matches (engine updated the existing one)
        mock_match_fn.reset_mock()
        mock_match_fn.return_value = MatchSummary(
            matches_created=0, matches_updated=1, notifications_sent=0
        )
        response_retry = self.client.post(f"/api/reports/{self.report_id}/analyze/")
        self.assertEqual(response_retry.status_code, status.HTTP_200_OK)
        self.assertEqual(response_retry.data["matches_created"], 0)
        self.assertEqual(response_retry.data["matches_updated"], 1)
        self.assertEqual(response_retry.data["notifications_sent"], 0)

    @override_settings(SUPABASE_URL="https://abc.supabase.co")
    @patch("core.models.Report.objects.get")
    def test_analyze_report_rejects_untrusted_photo_url(self, mock_get_report):
        """Security: photo URLs outside the Supabase Storage bucket must be rejected."""
        mock_report = MagicMock()
        mock_report.id = self.report_id
        mock_report.reporter_id = self.user_a_id
        mock_report.pet_id = None
        mock_report.status = "stray"
        mock_report.photo_url = "https://evil.com/malware.jpg"  # Untrusted external URL
        mock_get_report.return_value = mock_report

        self._auth_as(self.user_a_id)
        response = self.client.post(f"/api/reports/{self.report_id}/analyze/")

        self.assertEqual(response.status_code, status.HTTP_500_INTERNAL_SERVER_ERROR)
        # analysis_status must be set to 'failed' so the client can retry properly
        self.assertEqual(mock_report.analysis_status, "failed")

    @patch("core.views.cosine")
    @patch("core.views.embed_image")
    @patch("core.models.Report.objects.filter")
    def test_match_candidates_strict_species_filtering_and_threshold(
        self,
        mock_report_filter,
        mock_embed,
        mock_cosine,
    ):
        """
        Verify that MatchCandidatesView:
        1. Excludes cross-species candidates (e.g. Dog vs Cat).
        2. Rejects matches with similarity < 0.75.
        3. Returns valid matches with matching species and >= 0.75 similarity.
        """
        from io import BytesIO
        from core.ai.features import EmbeddingResult

        # Query image is a Dog (detected by detector and/or form dropdown)
        mock_embed.return_value = EmbeddingResult(
            vector=[0.1] * 512,
            model_version="resnet18-v1",
            used_crop=True,
            detector_score=0.88,
            detected_species="dog",
        )

        # Mock three missing reports:
        # 1. Cat (Georgei) -> should be filtered out by species!
        # 2. Dog (Pinky) with low similarity 0.64 -> should be filtered out by threshold!
        # 3. Dog (Tucker) with high similarity 0.85 -> should be included!
        rep_cat = MagicMock()
        rep_cat.id = "rep-cat-1"
        rep_cat.pet_id = "pet-cat-1"
        rep_cat.pet.name = "Georgei"
        rep_cat.pet.species = "Cat"
        rep_cat.animal_type = "feline"
        rep_cat.pet.photo_urls = ["https://example.com/cat.jpg"]
        rep_cat.reporter.name = "Cat Owner"
        rep_cat.pet.owner.name = "Cat Owner"
        rep_cat.description = "Lost ginger cat"
        rep_cat.location_name = "Area A"
        rep_cat.photo_url = None
        rep_cat.created_at = None
        rep_cat.pet.missing_since = None

        rep_dog_low = MagicMock()
        rep_dog_low.id = "rep-dog-low"
        rep_dog_low.pet_id = "pet-dog-low"
        rep_dog_low.pet.name = "Pinky"
        rep_dog_low.pet.species = "Dog"
        rep_dog_low.animal_type = "canine"
        rep_dog_low.pet.photo_urls = ["https://example.com/pinky.jpg"]
        rep_dog_low.reporter.name = "Dog Owner"
        rep_dog_low.pet.owner.name = "Dog Owner"
        rep_dog_low.description = "Lost chihuahua"
        rep_dog_low.location_name = "Area B"
        rep_dog_low.photo_url = None
        rep_dog_low.created_at = None
        rep_dog_low.pet.missing_since = None

        rep_dog_high = MagicMock()
        rep_dog_high.id = "rep-dog-high"
        rep_dog_high.pet_id = "pet-dog-high"
        rep_dog_high.pet.name = "Tucker"
        rep_dog_high.pet.species = "Dog"
        rep_dog_high.animal_type = "canine"
        rep_dog_high.pet.photo_urls = ["https://example.com/tucker.jpg"]
        rep_dog_high.reporter.name = "Dog Owner 2"
        rep_dog_high.pet.owner.name = "Dog Owner 2"
        rep_dog_high.description = "Lost golden retriever"
        rep_dog_high.location_name = "Area C"
        rep_dog_high.photo_url = None
        rep_dog_high.created_at = None
        rep_dog_high.pet.missing_since = None

        mock_qs = MagicMock()
        mock_qs.select_related.return_value = mock_qs
        mock_qs.exclude.return_value = mock_qs
        mock_qs.__getitem__.return_value = [rep_cat, rep_dog_low, rep_dog_high]
        mock_report_filter.return_value = mock_qs

        # Mock embeddings
        with patch("core.models.PetEmbedding.objects.filter") as mock_pet_emb:
            mock_emb_inst = MagicMock()
            mock_emb_inst.vector = [0.1] * 512
            mock_pet_emb.return_value.first.return_value = mock_emb_inst

            # Cosine scores: Cat = 0.63, Dog Low = 0.64, Dog High = 0.85
            mock_cosine.side_effect = [0.64, 0.85]

            fake_file = BytesIO(b"fake_jpeg_data")
            fake_file.name = "query.jpg"

            response = self.client.post(
                "/api/ai/match-candidates/",
                {"image": fake_file, "animal_type": "canine"},
                format="multipart",
            )

            self.assertEqual(response.status_code, status.HTTP_200_OK)
            candidates = response.data["candidates"]
            # Georgei the cat MUST NOT be in candidates (cross species)
            # Pinky (0.64) MUST NOT be in candidates (below 0.75 threshold)
            # Only Tucker (0.85) should be present
            self.assertEqual(len(candidates), 1)
            self.assertEqual(candidates[0]["pet_name"], "Tucker")
            self.assertEqual(candidates[0]["similarity_percent"], 85)

