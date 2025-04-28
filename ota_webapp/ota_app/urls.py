from django.urls import path
from .views import register, login
from . import views

urlpatterns= [
    path('register/', register),
    path('login/', login),
    path('api/upload-firmware/', views.upload_firmware, name='upload_firmware'),
    path('api/dht22/', views.get_dht22_data),
    path('api/logs/', views.get_log_data),
    path('api/waternode/', views.get_waternode_data),
    path('up-firmware/', views.upload_firmware_view, name='up_firmware'),
    path('dashboard/', views.dashboard_view, name='dasboard'),
]