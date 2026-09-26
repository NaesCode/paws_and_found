"""
Bridges Supabase Auth (used by the Flutter client) with Django REST Framework.

Flutter signs the user up/in directly against Supabase Auth and receives a
JWT. Every request to the Django API attaches that JWT as:

    Authorization: Bearer <token>

Django never sees a password — it only verifies that the token was signed
by Supabase (using the project's JWT secret) and, if valid, resolves it to
a local `User` profile row, creating one on first contact if needed.
"""

import jwt
from django.conf import settings
from rest_framework import authentication, exceptions

from .models import User


class SupabaseJWTAuthentication(authentication.BaseAuthentication):
    def authenticate(self, request):
        auth_header = request.headers.get("Authorization")
        if not auth_header or not auth_header.startswith("Bearer "):
            return None  # no credentials supplied on this request

        token = auth_header.split(" ", 1)[1]

        try:
            payload = jwt.decode(
                token,
                settings.SUPABASE_JWT_SECRET,
                algorithms=["HS256"],
                audience="authenticated",
            )
        except jwt.ExpiredSignatureError:
            raise exceptions.AuthenticationFailed("Token has expired.")
        except jwt.InvalidTokenError:
            raise exceptions.AuthenticationFailed("Invalid token.")

        supabase_user_id = payload.get("sub")
        if not supabase_user_id:
            raise exceptions.AuthenticationFailed("Token missing subject claim.")

        user, _ = User.objects.get_or_create(
            supabaseUserID=supabase_user_id,
            defaults={
                "name": payload.get("user_metadata", {}).get("name", ""),
                "email": payload.get("email", ""),
            },
        )

        return (user, token)
