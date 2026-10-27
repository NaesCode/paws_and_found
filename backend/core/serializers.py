from rest_framework import serializers
from .models import Profile


class ProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = Profile
        fields = [
            "id",
            "name",
            "email",
            "phone_number",
            "address",
            "profile_photo_url",
            "bio",
            "created_at",
        ]
        read_only_fields = ["id", "email", "created_at"]


class MatchRespondSerializer(serializers.Serializer):
    decision = serializers.ChoiceField(choices=["confirm", "reject"])
