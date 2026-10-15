from django.contrib import admin
from .models import Profile, Pet, Report, Match, Notification


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ("id", "name", "email", "phone_number", "created_at")
    search_fields = ("name", "email", "id")
    readonly_fields = ("id", "created_at")


admin.site.register(Pet)
admin.site.register(Report)
admin.site.register(Match)
admin.site.register(Notification)