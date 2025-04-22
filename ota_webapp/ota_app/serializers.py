import re
from rest_framework import serializers
from .models import CustomUser
from .models import DHT22Data, LogOTA, WaterNodeData

class CustomUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['id', 'email', 'username', 'full_name', 'phone_number', 'password']
        extra_kwargs = {'password': {'write_only':True}}

        def validate_password(self, value):
            """Validate aturan password"""
            if len(value) < 8:
                raise serializers.ValidationError("Password minimal berisi 8 karakter.")
            if not re.search(r"[A-Z]", value):
                raise serializers.ValidationError("Password harus mengandung setidaknya satu huruf besar.")
            if not re.search(r"[a-z]", value):
                raise serializers.ValidationError("Password harus mengandung setidaknya satu huruf kecil.")
            if not re.search(r"\d", value):
                raise serializers.ValidationError("Password harus mengandung setidaknya satu angka.")
            return value
        
        def create(self, validated_data):
            user = CustomUser.objects.create_user(**validated_data)
            return user

class LogOTASerializer(serializers.ModelSerializer):
    class Meta:
        model = LogOTA
        fields = '__all__'
