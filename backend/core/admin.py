from django.contrib import admin
from .models import User, Pet, Report, Match, Notification

admin.site.register(User)
admin.site.register(Pet)
admin.site.register(Report)
admin.site.register(Match)
admin.site.register(Notification)