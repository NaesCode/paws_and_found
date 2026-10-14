from django.contrib import admin
from .models import User, Pet, Report, Match, Notification


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    # Columns shown in the main table list
    list_display = ("name", "email", "phoneNumber", "dateRegistered")
    
    # Allows clicking into details, and adds a search bar
    search_fields = ("name", "email", "supabaseUserID")
    
    # Shows the non-editable fields inside the form
    readonly_fields = ("userID", "dateRegistered")


admin.site.register(Pet)
admin.site.register(Report)
admin.site.register(Match)
admin.site.register(Notification)