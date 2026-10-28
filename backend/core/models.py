import uuid

from django.contrib.gis.db import models as gis_models
from django.contrib.postgres.fields import ArrayField
from django.db import models
from django.db.models.functions import Now

# Every model is managed = False: the Supabase CLI migration owns the schema.
# Tables resolve through the django_backend role's search_path (django, public, private, extensions).


class Profile(models.Model):
    id = models.UUIDField(primary_key=True)
    name = models.TextField(default="")
    email = models.TextField(null=True)
    phone_number = models.TextField(null=True)
    profile_photo_url = models.TextField(null=True)
    bio = models.TextField(null=True)
    address = models.TextField(null=True)
    created_at = models.DateTimeField(db_default=Now(), editable=False)

    class Meta:
        managed = False
        db_table = "profiles"

    def __str__(self):
        return f"{self.name} ({self.email})"


class Pet(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
    owner = models.ForeignKey(Profile, on_delete=models.DO_NOTHING, db_constraint=False, related_name="pets")
    name = models.TextField()
    species = models.TextField()
    breed = models.TextField(null=True)
    color = models.TextField(null=True)
    description = models.TextField(null=True)
    photo_urls = ArrayField(models.TextField(), default=list)
    last_known_location = gis_models.PointField(geography=True, srid=4326, null=True)
    status = models.TextField(default="safe")
    missing_since = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(db_default=Now(), editable=False)

    class Meta:
        managed = False
        db_table = "pets"

    def __str__(self):
        return f"{self.name} ({self.status})"


class Report(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
    reporter = models.ForeignKey(Profile, on_delete=models.DO_NOTHING, db_constraint=False, related_name="reports")
    pet = models.ForeignKey(Pet, null=True, on_delete=models.DO_NOTHING, db_constraint=False, related_name="reports")
    animal_type = models.TextField()
    description = models.TextField(default="")
    photo_url = models.TextField()
    location = gis_models.PointField(geography=True, srid=4326)
    status = models.TextField(default="stray")
    analysis_status = models.TextField(default="pending")
    created_at = models.DateTimeField(db_default=Now(), editable=False)

    class Meta:
        managed = False
        db_table = "reports"

    def __str__(self):
        return f"{self.animal_type} report ({self.status})"


class Match(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
    report = models.ForeignKey(Report, on_delete=models.DO_NOTHING, db_constraint=False, related_name="matches")
    pet = models.ForeignKey(Pet, on_delete=models.DO_NOTHING, db_constraint=False, related_name="matches")
    similarity_score = models.FloatField()
    distance_km = models.FloatField()
    status = models.TextField(default="pending")
    triggered_by = models.TextField(default="report")
    created_at = models.DateTimeField(db_default=Now(), editable=False)

    class Meta:
        managed = False
        db_table = "matches"

    def __str__(self):
        return f"Match {self.id} ({self.status})"


class Notification(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
    user = models.ForeignKey(Profile, on_delete=models.DO_NOTHING, db_constraint=False, related_name="notifications")
    type = models.TextField()
    message = models.TextField()
    related_match = models.ForeignKey(Match, null=True, on_delete=models.DO_NOTHING, db_constraint=False)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(db_default=Now(), editable=False)

    class Meta:
        managed = False
        db_table = "notifications"

    def __str__(self):
        return f"Notification to {self.user_id} ({self.type})"


class PetEmbedding(models.Model):
    pet = models.OneToOneField(Pet, primary_key=True, on_delete=models.DO_NOTHING, db_constraint=False)
    vector = ArrayField(models.FloatField())
    model_version = models.TextField(default="unversioned")
    updated_at = models.DateTimeField(db_default=Now())

    class Meta:
        managed = False
        db_table = "pet_embeddings"  # lives in schema "private"


class ReportEmbedding(models.Model):
    report = models.OneToOneField(Report, primary_key=True, on_delete=models.DO_NOTHING, db_constraint=False)
    vector = ArrayField(models.FloatField())
    model_version = models.TextField(default="unversioned")
    updated_at = models.DateTimeField(db_default=Now())

    class Meta:
        managed = False
        db_table = "report_embeddings"  # lives in schema "private"
