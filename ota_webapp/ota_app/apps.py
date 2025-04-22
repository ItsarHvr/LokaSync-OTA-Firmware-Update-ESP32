import os
from django.apps import AppConfig

class OtaAppConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'ota_app'

    def ready(self):
        # hanya untuk development, kalo udh live server, ini hapus trs DEBUGnya dibikin false di settings.py
        if os.environ.get('RUN_MAIN') == 'true':
            from .mqtt_client import start_mqtt
            start_mqtt()