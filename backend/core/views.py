from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Profile


class HealthView(APIView):
    """Health check endpoint.
    Proves JWT verification and the database connection."""

    def get(self, request):
        # Trigger a lightweight DB query to prove connection works
        Profile.objects.exists()
        return Response({
            "user_id": request.user.id,
            "db": "ok",
        })