from rest_framework.views import APIView
from rest_framework.response import Response
from .serializers import UserSerializer


class MeView(APIView):
    """GET: return the logged-in user's profile.
    PATCH: update editable fields (name, phoneNumber, profilePhotoURL)."""

    def get(self, request):
        return Response(UserSerializer(request.user).data)

    def patch(self, request):
        serializer = UserSerializer(request.user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)