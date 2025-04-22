import json
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
from .models import CustomUser
from .serializers import CustomUserSerializer

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

def upload_firmware(request):
    if request.method == 'POST' and request.FILES.get('firmware'):
        firmware = request.FILES['firmware']
        path = f'tmp/{firmware.name}'

        with open(path, 'wb+') as f:
            for chunk in firmware.chunks():
                f.write(chunk)

        url = upload_to_drive(path, firmware.name)

        topic = request.POST.get('topic')
        payload = json.dumps({'url': url})
        publish.single(topic, payload, hostname="broker.emqx.io")

        return JsonResponse({'message': 'Uploaded & URL sent', 'url':url})
    return JsonResponse({'error': 'Invalid request'}, status=400)

def get_dht22_data(request):
    data = DHT22Data.objects.order_by('-timestamp')[:10]
    return JsonResponse({'data': list(data.values())})

def get_log_data(request):
    data = LogOTA.objects.order_by('-timestamp')[:10]
    return JsonResponse({'data': list(data.values())})

def get_waternode_data(request):
    data = WaterNodeData.objects.order_by('-timestamp')[:10]
    return JsonResponse({'data': list(data.values())})