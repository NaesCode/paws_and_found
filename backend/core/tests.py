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


@contextmanager
def dummy_atomic():
    """Mock context manager for transaction.atomic() during unit tests."""
    yield


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

    def test_extract_features_is_deterministic_and_normalized(self):
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

    @patch("core.models.PetEmbedding.objects.update_or_create")
    @patch("core.views._download_image")
    @patch("core.models.Pet.objects.get")
    def test_analyze_pet_success_workflow(self, mock_get_pet, mock_download, mock_emb_update):
        mock_pet = MagicMock()
        mock_pet.id = self.pet_id
        mock_pet.owner_id = self.user_a_id
        mock_pet.photo_urls = ["https://example.com/pet.jpg"]
        mock_get_pet.return_value = mock_pet
        mock_download.return_value = b"sample_pet_photo_bytes"

        self._auth_as(self.user_a_id)
        response = self.client.post(f"/api/pets/{self.pet_id}/analyze/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["status"], "done")
        self.assertEqual(response.data["photos_analyzed"], 1)
        mock_emb_update.assert_called_once()

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

    @patch("core.models.Notification.objects.create")
    @patch("core.models.Report.objects.filter")
    @patch("core.models.Match.objects.select_related")
    def test_respond_confirm_workflow(self, mock_select_related, mock_report_filter, mock_notif_create):
        mock_match = MagicMock()
        mock_match.id = self.match_id
        mock_match.status = "pending"
        mock_match.report.reporter_id = self.user_b_id
        mock_match.report.status = "stray"
        mock_match.pet.owner_id = self.user_a_id
        mock_match.pet.name = "Milo"
        mock_match.pet.status = "missing"
        mock_select_related.return_value.get.return_value = mock_match

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
        self.assertIsNone(mock_match.pet.last_known_location)
        self.assertEqual(mock_match.report.status, "found")
        mock_notif_create.assert_called_once()

    @patch("core.models.Notification.objects.filter")
    @patch("core.models.Notification.objects.create")
    @patch("core.models.Match.objects.update_or_create")
    @patch("core.models.PetEmbedding.objects.get")
    @patch("core.models.Pet.objects.filter")
    @patch("core.models.ReportEmbedding.objects.update_or_create")
    @patch("core.views._download_image")
    @patch("core.models.Report.objects.get")
    def test_analyze_report_workflow_and_idempotency(
        self,
        mock_get_report,
        mock_download,
        mock_report_emb,
        mock_pet_filter,
        mock_pet_emb_get,
        mock_match_update,
        mock_notif_create,
        mock_notif_filter,
    ):
        mock_report = MagicMock()
        mock_report.id = self.report_id
        mock_report.reporter_id = self.user_b_id
        mock_report.photo_url = "https://example.com/photo.jpg"
        mock_report.animal_type = "dog"
        mock_report.location = MagicMock()
        mock_report.analysis_status = "pending"
        mock_get_report.return_value = mock_report

        # Deterministic photo bytes
        sample_bytes = b"golden_retriever_photo_seed_data"
        mock_download.return_value = sample_bytes
        vector = extract_features(sample_bytes)

        # Candidate pet
        mock_pet = MagicMock()
        mock_pet.name = "Milo"
        mock_pet.owner_id = self.user_a_id
        mock_pet.owner = MagicMock()
        mock_pet.distance.km = 0.45
        mock_pet_filter.return_value.exclude.return_value.annotate.return_value = [mock_pet]

        # Return matching embedding (vector identical -> score = 1.0)
        mock_pet_emb = MagicMock()
        mock_pet_emb.vector = vector
        mock_pet_emb_get.return_value = mock_pet_emb

        mock_match = MagicMock()
        mock_match_update.return_value = (mock_match, True)

        # Case 1: First run - notifications do not exist yet
        mock_notif_filter.return_value.exists.return_value = False

        self._auth_as(self.user_b_id)
        response = self.client.post(f"/api/reports/{self.report_id}/analyze/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["status"], "done")
        self.assertEqual(response.data["matches_scored"], 1)
        self.assertEqual(mock_report.analysis_status, "done")
        self.assertEqual(mock_notif_create.call_count, 2)  # 1 for owner, 1 for reporter

        # Case 2: Idempotency check - notifications already exist
        mock_notif_create.reset_mock()
        mock_notif_filter.return_value.exists.return_value = True

        response_retry = self.client.post(f"/api/reports/{self.report_id}/analyze/")
        self.assertEqual(response_retry.status_code, status.HTTP_200_OK)
        # Should NOT create duplicate notifications
        mock_notif_create.assert_not_called()
