from rest_framework import serializers
from apps.core.models import Driver, DriverLocation, DriverTrip
from django.utils import timezone


class DriverSerializer(serializers.ModelSerializer):
    """
    Serializer para motoristas
    """
    class Meta:
        model = Driver
        fields = ['id', 'cpf', 'name', 'phone', 'is_active', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class DriverLocationSerializer(serializers.ModelSerializer):
    """
    Serializer para localização do motorista
    """
    driver_name = serializers.CharField(source='driver.name', read_only=True)
    driver_cpf = serializers.CharField(source='driver.cpf', read_only=True)
    
    class Meta:
        model = DriverLocation
        fields = [
            'id', 'driver', 'driver_name', 'driver_cpf', 'latitude', 'longitude',
            'accuracy', 'speed', 'battery_level', 'timestamp', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def validate_latitude(self, value):
        """Valida se a latitude está dentro do range válido"""
        if not (-90 <= value <= 90):
            raise serializers.ValidationError("Latitude deve estar entre -90 e 90 graus")
        return value
    
    def validate_longitude(self, value):
        """Valida se a longitude está dentro do range válido"""
        if not (-180 <= value <= 180):
            raise serializers.ValidationError("Longitude deve estar entre -180 e 180 graus")
        return value
    
    def validate_speed(self, value):
        """Valida se a velocidade é positiva"""
        if value is not None and value < 0:
            raise serializers.ValidationError("Velocidade não pode ser negativa")
        return value
    
    def validate_battery_level(self, value):
        """Valida se o nível da bateria está entre 0 e 100"""
        if value is not None and not (0 <= value <= 100):
            raise serializers.ValidationError("Nível da bateria deve estar entre 0 e 100%")
        return value


class DriverLocationCreateSerializer(serializers.Serializer):
    """
    Serializer para criação de localização com CPF do motorista
    """
    cpf = serializers.CharField(max_length=14, help_text="CPF do motorista")
    latitude = serializers.DecimalField(max_digits=10, decimal_places=7)
    longitude = serializers.DecimalField(max_digits=10, decimal_places=7)
    accuracy = serializers.FloatField(required=False, allow_null=True)
    speed = serializers.FloatField(required=False, allow_null=True)
    battery_level = serializers.IntegerField(required=False, allow_null=True)
    
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
            raise serializers.ValidationError("Velocidade não pode ser negativa")
        return value
    
    def validate_battery_level(self, value):
        if value is not None and not (0 <= value <= 100):
            raise serializers.ValidationError("Nível da bateria deve estar entre 0 e 100%")
        return value


class DriverTripSerializer(serializers.ModelSerializer):
    """
    Serializer para viagens do motorista
    """
    driver_name = serializers.CharField(source='driver.name', read_only=True)
    driver_cpf = serializers.CharField(source='driver.cpf', read_only=True)
    
    class Meta:
        model = DriverTrip
        fields = [
            'id', 'driver', 'driver_name', 'driver_cpf', 'start_latitude', 'start_longitude',
            'end_latitude', 'end_longitude', 'current_latitude', 'current_longitude',
            'status', 'distance_km', 'duration_minutes', 'started_at', 'completed_at', 
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class TripStartSerializer(serializers.Serializer):
    """
    Serializer para início de viagem
    """
    cpf = serializers.CharField(max_length=14, help_text="CPF do motorista")
    start_latitude = serializers.DecimalField(max_digits=10, decimal_places=7)
    start_longitude = serializers.DecimalField(max_digits=10, decimal_places=7)
    
    def validate_start_latitude(self, value):
        if not (-90 <= value <= 90):
            raise serializers.ValidationError("Latitude deve estar entre -90 e 90 graus")
        return value
    
    def validate_start_longitude(self, value):
        if not (-180 <= value <= 180):
            raise serializers.ValidationError("Longitude deve estar entre -180 e 180 graus")
        return value


class TripEndSerializer(serializers.Serializer):
    """
    Serializer para fim de viagem
    """
    cpf = serializers.CharField(max_length=14, help_text="CPF do motorista")
    end_latitude = serializers.DecimalField(max_digits=10, decimal_places=7)
    end_longitude = serializers.DecimalField(max_digits=10, decimal_places=7)
    distance_km = serializers.FloatField(required=False, allow_null=True)
    
    def validate_end_latitude(self, value):
        if not (-90 <= value <= 90):
            raise serializers.ValidationError("Latitude deve estar entre -90 e 90 graus")
        return value
    
    def validate_end_longitude(self, value):
        if not (-180 <= value <= 180):
            raise serializers.ValidationError("Longitude deve estar entre -180 e 180 graus")
        return value


class DriverDataSerializer(serializers.ModelSerializer):
    """
    Serializer para dados completos de um motorista
    """
    locations = DriverLocationSerializer(many=True, read_only=True)
    trips = DriverTripSerializer(many=True, read_only=True)
    
    class Meta:
        model = Driver
        fields = [
            'id', 'cpf', 'name', 'phone', 'is_active', 
            'locations', 'trips', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']