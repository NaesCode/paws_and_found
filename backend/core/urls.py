from django.urls import path
from .views import HealthView, MatchRespondView, PetAnalyzeView, ReportAnalyzeView

urlpatterns = [
    path("health/", HealthView.as_view(), name="health"),
    path("reports/<uuid:id>/analyze/", ReportAnalyzeView.as_view(), name="report-analyze"),
    path("pets/<uuid:id>/analyze/", PetAnalyzeView.as_view(), name="pet-analyze"),
    path("matches/<uuid:id>/respond/", MatchRespondView.as_view(), name="match-respond"),
]
