"""
Django models for Paws and Found, mirroring the Data Dictionary in the SDD.

Field names follow the camelCase used in the Data Dictionary for easy
cross-reference with that document. Standard Django/PEP8 style normally
prefers snake_case (e.g. user_id) — feel free to rename if your team
prefers that convention, just keep it consistent across the codebase.

Notes:
- `User` here is NOT Django's built-in auth user. Supabase Auth owns
  credentials; this table stores only app-facing profile data plus a
  reference to the Supabase Auth user id.
- `PointField(geography=True)` stores coordinates as a PostGIS geography
  column, which is what enables efficient radius queries like
  `Pet.objects.filter(lastKnownLocation__distance_lte=(point, D(km=5)))`.
"""

import uuid

from django.contrib.gis.db import models as gis_models
from django.contrib.postgres.fields import ArrayField
from django.db import models


class User(models.Model):
    userID = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    supabaseUserID = models.UUIDField(unique=True, db_index=True)
    name = models.CharField(max_length=255)
    email = models.EmailField(unique=True)
    phoneNumber = models.CharField(max_length=32, blank=True, null=True)
    profilePhotoURL = models.URLField(blank=True, null=True)
    dateRegistered = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.email})"


class Pet(models.Model):
    class Status(models.TextChoices):
        MISSING = "Missing", "Missing"
        RECOVERED = "Recovered", "Recovered"

    petID = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    ownerUserID = models.ForeignKey(User, on_delete=models.CASCADE, related_name="pets")
    name = models.CharField(max_length=255)
    species = models.CharField(max_length=100)
    breed = models.CharField(max_length=100, blank=True, null=True)
    color = models.CharField(max_length=255)
    distinguishingMarks = models.TextField(blank=True, null=True)
    photoURLs = ArrayField(models.URLField(), default=list, blank=True)
    featureVector = ArrayField(models.FloatField(), default=list, blank=True)
    lastKnownLocation = gis_models.PointField(geography=True, srid=4326)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.MISSING)
    dateReported = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.status})"


class Report(models.Model):
    class Status(models.TextChoices):
        STRAY = "Stray", "Stray"
        MISSING = "Missing", "Missing"
        FOUND = "Found", "Found"

    reportID = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    reporterUserID = models.ForeignKey(User, on_delete=models.CASCADE, related_name="reports")
    animalType = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    photoURL = models.URLField()
    featureVector = ArrayField(models.FloatField(), default=list, blank=True)
    location = gis_models.PointField(geography=True, srid=4326)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.STRAY)
    dateTime = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.animalType} report ({self.status})"


class Match(models.Model):
    class Status(models.TextChoices):
        PENDING = "Pending", "Pending"
        CONFIRMED = "Confirmed", "Confirmed"
        REJECTED = "Rejected", "Rejected"

    matchID = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    reportID = models.ForeignKey(Report, on_delete=models.CASCADE, related_name="matches")
    petID = models.ForeignKey(Pet, on_delete=models.CASCADE, related_name="matches")
    similarityScore = models.FloatField()
    distanceKM = models.FloatField()
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    dateGenerated = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Match {self.matchID} ({self.status})"


class Notification(models.Model):
    class NotifType(models.TextChoices):
        MATCH_FOUND = "MatchFound", "MatchFound"
        REPORT_UPDATE = "ReportUpdate", "ReportUpdate"
        VERIFICATION_REQUEST = "VerificationRequest", "VerificationRequest"
        MATCH_CONFIRMED = "MatchConfirmed", "MatchConfirmed"

    notificationID = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    userID = models.ForeignKey(User, on_delete=models.CASCADE, related_name="notifications")
    type = models.CharField(max_length=30, choices=NotifType.choices)
    message = models.TextField()
    relatedMatchID = models.ForeignKey(
        Match, on_delete=models.SET_NULL, null=True, blank=True, related_name="notifications"
    )
    isRead = models.BooleanField(default=False)
    dateTime = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Notification to {self.userID_id} ({self.type})"
