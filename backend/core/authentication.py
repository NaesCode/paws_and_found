"""
Bridges Supabase Auth (used by the Flutter client) with Django REST Framework.

Supports both:
- Asymmetric keys (ES256 / RS256) via Supabase JWKS (.well-known/jwks.json)
- Symmetric shared secrets (HS256 / HS384 / HS512) via SUPABASE_JWT_SECRET

Hardened against algorithm confusion and unauthorized audience claims.
"""

import base64
import jwt
from django.conf import settings
from rest_framework import authentication, exceptions

from .models import User

# Clean up base URL for Supabase Auth JWKS endpoint
_BASE_SUPABASE_URL = getattr(settings, "SUPABASE_URL", "").split("/rest/v1")[0].rstrip("/")
_JWKS_URL = f"{_BASE_SUPABASE_URL}/auth/v1/.well-known/jwks.json" if _BASE_SUPABASE_URL else None
_jwks_client = jwt.PyJWKClient(_JWKS_URL) if _JWKS_URL else None


class SupabaseJWTAuthentication(authentication.BaseAuthentication):
    def authenticate(self, request):
        auth_header = request.headers.get("Authorization")
        if not auth_header or not auth_header.startswith("Bearer "):
            return None  # no credentials supplied on this request

        token = auth_header.split(" ", 1)[1]

        # 1. Inspect token header safely for algorithm
        try:
            unverified_header = jwt.get_unverified_header(token)
            alg = unverified_header.get("alg")
        except Exception:
            raise exceptions.AuthenticationFailed("Invalid token header format.")

        if not alg:
            raise exceptions.AuthenticationFailed("Token missing 'alg' in header.")

        payload = None

        # 2. Asymmetric verification (ES256 / RS256 via Supabase JWKS)
        if alg in ("ES256", "RS256"):
            if not _jwks_client:
                raise exceptions.AuthenticationFailed("JWKS client not configured on server.")
            try:
                signing_key = _jwks_client.get_signing_key_from_jwt(token)
                payload = jwt.decode(
                    token,
                    signing_key.key,
                    algorithms=[alg],
                    audience="authenticated",  # Strictly require authenticated audience
                )
            except jwt.ExpiredSignatureError:
                raise exceptions.AuthenticationFailed("Token has expired.")
            except Exception as e:
                raise exceptions.AuthenticationFailed(f"Invalid token: {e}")

        # 3. Symmetric verification fallback (HS256 with SUPABASE_JWT_SECRET)
        elif alg in ("HS256", "HS384", "HS512"):
            secrets = []
            jwt_secret = getattr(settings, "SUPABASE_JWT_SECRET", "")
            try:
                secrets.append(base64.b64decode(jwt_secret))
            except Exception:
                pass
            secrets.append(jwt_secret)

            last_err = None
            for secret in secrets:
                try:
                    payload = jwt.decode(
                        token,
                        secret,
                        algorithms=[alg],
                        audience="authenticated",  # Strictly require authenticated audience
                    )
                    break
                except jwt.ExpiredSignatureError:
                    raise exceptions.AuthenticationFailed("Token has expired.")
                except Exception as e:
                    last_err = e
                    continue

            if not payload:
                raise exceptions.AuthenticationFailed(f"Invalid token signature: {last_err}")

        # 4. Reject any other algorithms (prevents 'none' algorithm exploits)
        else:
            raise exceptions.AuthenticationFailed(f"Unsupported token algorithm: '{alg}'.")

        supabase_user_id = payload.get("sub")
        if not supabase_user_id:
            raise exceptions.AuthenticationFailed("Token missing subject ('sub') claim.")

        user, _ = User.objects.get_or_create(
            supabaseUserID=supabase_user_id,
            defaults={
                "name": payload.get("user_metadata", {}).get("name", ""),
                "email": payload.get("email", ""),
            },
        )

        return (user, token)
