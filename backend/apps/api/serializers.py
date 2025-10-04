from rest_framework import serializers
from apps.core.models import Location, TestSession, DriverLocation, DriverTrip
from django.contrib.auth import get_user_model

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'phone', 'is_verified']
        read_only_fields = ['id', 'is_verified']


class LocationSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.full_name', read_only=True)
    
    class Meta:
        model = Location
        fields = ['id', 'name', 'address', 'latitude', 'longitude', 'description', 
                 'created_by', 'created_by_name', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class DriverLocationSerializer(serializers.ModelSerializer):
    driver_name = serializers.CharField(source='driver.full_name', read_only=True)
    driver_username = serializers.CharField(source='driver.username', read_only=True)
    
    class Meta:
        model = DriverLocation
        fields = [
            'id', 'driver', 'driver_name', 'driver_username', 'latitude', 'longitude',
            'accuracy', 'speed', 'heading', 'altitude', 'status', 'battery_level',
            'is_gps_enabled', 'device_id', 'app_version', 'timestamp',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'timestamp']
    
    def validate_latitude(self, value):
        """Valida se a latitude estÃ¡ dentro do range vÃ¡lido"""
        if not (-90 <= value <= 90):
            raise serializers.ValidationError("Latitude deve estar entre -90 e 90 graus")
        return value
    
    def validate_longitude(self, value):
        """Valida se a longitude estÃ¡ dentro do range vÃ¡lido"""
        if not (-180 <= value <= 180):
            raise serializers.ValidationError("Longitude deve estar entre -180 e 180 graus")
        return value
    
    def validate_speed(self, value):
        """Valida se a velocidade Ã© positiva"""
        if value is not None and value < 0:
            raise serializers.ValidationError("Velocidade nÃ£o pode ser negativa")
        return value
    
    def validate_battery_level(self, value):
        """Valida se o nÃ­vel da bateria estÃ¡ entre 0 e 100"""
        if value is not None and not (0 <= value <= 100):
            raise serializers.ValidationError("NÃ­vel da bateria deve estar entre 0 e 100%")
        return value


class DriverLocationCreateSerializer(serializers.ModelSerializer):
    """
    Serializer simplificado para criaÃ§Ã£o de localizaÃ§Ã£o do motorista
    """
    class Meta:
        model = DriverLocation
        fields = [
            'latitude', 'longitude', 'accuracy', 'speed', 'heading', 'altitude',
            'status', 'battery_level', 'is_gps_enabled', 'device_id', 'app_version'
        ]
    
    def validate_latitude(self, value):
        if not (-90 <= value <= 90):
            raise serializers.ValidationError("Latitude deve estar entre -90 e 90 graus")
        return value
    
    def validate_longitude(self, value):
        if not (-180 <= value <= 180):
            raise serializers.ValidationError("Longitude deve estar entre -180 e 180 graus")
        return value
    
    def validate_speed(self, value):
        if value is not None and value < 0:
            raise serializers.ValidationError("Velocidade nÃ£o pode ser negativa")
        return value
    
    def validate_battery_level(self, value):
        if value is not None and not (0 <= value <= 100):
            raise serializers.ValidationError("NÃ­vel da bateria deve estar entre 0 e 100%")
        return value


class DriverTripSerializer(serializers.ModelSerializer):
    driver_name = serializers.CharField(source='driver.full_name', read_only=True)
    
    class Meta:
        model = DriverTrip
        fields = [
            'id', 'driver', 'driver_name', 'start_location', 'end_location',
            'status', 'distance_km', 'duration_minutes', 'started_at',
            'completed_at', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class TestSessionSerializer(serializers.ModelSerializer):
    location_name = serializers.CharField(source='location.name', read_only=True)
    created_by_name = serializers.CharField(source='created_by.full_name', read_only=True)
    
    class Meta:
        model = TestSession
        fields = ['id', 'name', 'description', 'location', 'location_name', 'status',
                 'started_at', 'completed_at', 'created_by', 'created_by_name',
                 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at', 'started_at', 'completed_at']


class HomeLocationUpdateSerializer(serializers.Serializer):
    """
    Serializer para atualizações de localização na página home
    """
    id = serializers.IntegerField()
    driver_name = serializers.CharField()
    driver_username = serializers.CharField()
    latitude = serializers.DecimalField(max_digits=10, decimal_places=7)
    longitude = serializers.DecimalField(max_digits=10, decimal_places=7)
    status = serializers.CharField()
    speed = serializers.FloatField(allow_null=True)
    battery_level = serializers.IntegerField(allow_null=True)
    timestamp = serializers.DateTimeField()
    created_at = serializers.DateTimeField()
    is_online = serializers.BooleanField()
    last_update_minutes_ago = serializers.IntegerField()
