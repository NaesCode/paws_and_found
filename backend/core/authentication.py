import jwt
from django.conf import settings
from jwt import PyJWKClient
from jwt.exceptions import InvalidTokenError, PyJWKClientError
from rest_framework import authentication, exceptions

_jwks_client = None


def _jwks():
    global _jwks_client
    if _jwks_client is None:
        base_url = settings.SUPABASE_URL.replace("/rest/v1", "").rstrip("/")
        _jwks_client = PyJWKClient(
            f"{base_url}/auth/v1/.well-known/jwks.json", cache_keys=True
        )
    return _jwks_client


class SupabaseUser:
    """Lightweight principal. Identity lives in Supabase Auth / public.profiles; Django owns no users."""

    is_authenticated = True
    is_anonymous = False

    def __init__(self, user_id, email="", claims=None):
        self.id = user_id
        self.pk = user_id
        self.email = email
        self.claims = claims or {}

    def __str__(self):
        return str(self.id)


class SupabaseJWTAuthentication(authentication.BaseAuthentication):
    def authenticate_header(self, request):
        return "Bearer"  # makes failures return 401 instead of 403

    def authenticate(self, request):
        header = request.headers.get("Authorization", "")
        if not header.startswith("Bearer "):
            return None
        token = header.split(" ", 1)[1].strip()

        try:
            alg = jwt.get_unverified_header(token).get("alg")
            if alg == "HS256":
                if not settings.SUPABASE_JWT_SECRET:
                    raise exceptions.AuthenticationFailed("HS256 token but no legacy secret configured.")
                key, algorithms = settings.SUPABASE_JWT_SECRET, ["HS256"]
            elif alg in ("ES256", "RS256"):
                key, algorithms = _jwks().get_signing_key_from_jwt(token).key, [alg]
            else:
                raise exceptions.AuthenticationFailed("Unsupported token algorithm.")
            payload = jwt.decode(token, key, algorithms=algorithms, audience="authenticated")
        except jwt.ExpiredSignatureError:
            raise exceptions.AuthenticationFailed("Token has expired.")
        except (InvalidTokenError, PyJWKClientError):
            raise exceptions.AuthenticationFailed("Invalid token.")

        sub = payload.get("sub")
        if not sub:
            raise exceptions.AuthenticationFailed("Token missing subject claim.")
        return (SupabaseUser(sub, payload.get("email", ""), payload), token)
