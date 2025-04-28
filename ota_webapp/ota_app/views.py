import os
import json
from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import render
from django.http import JsonResponse
from .drive_helper import upload_to_drive
import paho.mqtt.publish as publish
from django.contrib.auth import authenticate
from .models import DHT22Data, LogOTA, WaterNodeData
from django.core.serializers import serialize
from rest_framework import status
from rest_framework.response import Response
from rest_framework.decorators import api_view
from rest_framework.authtoken.models import Token
from rest_framework.views import APIView
from .models import CustomUser
from .serializers import CustomUserSerializer, LogOTASerializer

@api_view(['POST'])
def register(request):
    serializer = CustomUserSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        token, created = Token.objects.get_or_create(user=user)
        return Response({'token': token.key, 'user':serializer.data}, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def login(request):
    email = request.data.get('email')
    password = request.data.get('password')
    user = authenticate(email=email, password=password)
    if user:
        token, created = Token.objects.get_or_create(user=user)
        return Response({'token': token.key}, status=status.HTTP_200_OK)
    return Response({'error': 'Invalid Credentials'}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def upload_firmware(request):
    if request.method == 'POST' and request.FILES.get('firmware'):
        firmware = request.FILES['firmware']
        path = f'tmp/{firmware.name}'

        if not os.path.exists('tmp'):
            os.makedirs('tmp')

        try:
            with open(path, 'wb+') as f:
                for chunk in firmware.chunks():
                    f.write(chunk)
        except Exception as e:
            return JsonResponse({'error': f'Error while saving file: {str(e)}'},status=500)

        folder_id = "1pVjAcP7A9dlvLBrqNhE-SXJXESsLXXR5"
        try:
            url = upload_to_drive(path, firmware.name, folder_id)
        except Exception as e:
            return JsonResponse({'error': f'Error uploading to Google Drive: {str(e)}'})

        node = request.POST.get('node')

        if node == 'Node-DHT':
            topic = 'OTA/NODE-DHT'
        elif node == 'Water_Node':
            topic = 'OTA/Water_Node'
        else:
            return JsonResponse({'error': 'Invalid node Selected'}, status=400)

        payload = json.dumps({'url': url})
        publish.single(topic, payload, hostname="broker.emqx.io")

        return JsonResponse({'message': 'Uploaded & URL sent', 'url':url})
    return JsonResponse({'error': 'Invalid request'}, status=400)

def upload_firmware_view(request):
    return render(request, 'upload_firmware.html')

def dashboard_view(request):
    return render(request, 'dashboard.html')

def get_dht22_data(request):
    data = DHT22Data.objects.order_by('-timestamp')[:10]
    return JsonResponse({'data': list(data.values())})

def get_log_data(request):
    data = LogOTA.objects.order_by('-timestamp')[:10]
    return JsonResponse({'data': list(data.values())})

def get_waternode_data(request):
    data = WaterNodeData.objects.order_by('-timestamp')[:10]
    return JsonResponse({'data': list(data.values())})
