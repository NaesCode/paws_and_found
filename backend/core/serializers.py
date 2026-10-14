from rest_framework import serializers
from .models import User


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            "userID",
            "name",
            "email",
            "phoneNumber",
            "address",
            "profilePhotoURL",
            "bio",
            "dateRegistered",
        ]
        # email/userID/dateRegistered come from Supabase/system — not user-editable here
        read_only_fields = ["userID", "email", "dateRegistered"]