from django.apps import apps
from django.contrib import admin
from django.db.models import CompositePrimaryKey

# Register every model in this app so the Pagila tables are browsable.
# The admin does not support composite primary keys, so those are skipped.
for model in apps.get_app_config("dvdrental").get_models():
    if isinstance(model._meta.pk, CompositePrimaryKey):
        continue
    admin.site.register(model)
