from django.apps import AppConfig


class OtaAppConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'ota_app'

    def ready(self):
        from .mqtt_client import start_mqtt
        start_mqtt()