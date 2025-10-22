from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django.utils import timezone
from django.shortcuts import get_object_or_404
from django.db import transaction

from apps.core.models import Driver, DriverLocation, DriverTrip
from apps.api.serializers import (
    DriverSerializer, DriverLocationSerializer, DriverLocationCreateSerializer,
    DriverTripSerializer, TripStartSerializer, TripEndSerializer, DriverDataSerializer
)


class DriverViewSet(viewsets.ModelViewSet):
    """
    ViewSet para gerenciar motoristas
    """
    queryset = Driver.objects.all()
    serializer_class = DriverSerializer
    permission_classes = [AllowAny]
    lookup_field = 'cpf'

    @action(detail=False, methods=['post'])
    def send_location(self, request):
        """
        POST /api/drivers/send_location/
        Envia localização com CPF do motorista
        REGRA: Motorista deve existir previamente
        """
        serializer = DriverLocationCreateSerializer(data=request.data)
        if serializer.is_valid():
            cpf = serializer.validated_data['cpf']
            
            # Busca o motorista (NÃO cria se não existir)
            try:
                driver = Driver.objects.get(cpf=cpf, is_active=True)
            except Driver.DoesNotExist:
                return Response(
                    {'error': 'Motorista não encontrado ou inativo'}, 
                    status=status.HTTP_404_NOT_FOUND
                )
            
            with transaction.atomic():
                # Verifica se há viagem ativa
                active_trip = DriverTrip.objects.filter(
                    driver=driver, 
                    status='started'
                ).first()
                
                # Cria a localização
                location = DriverLocation.objects.create(
                    driver=driver,
                    latitude=serializer.validated_data['latitude'],
                    longitude=serializer.validated_data['longitude'],
                    accuracy=serializer.validated_data.get('accuracy'),
                    speed=serializer.validated_data.get('speed'),
                    battery_level=serializer.validated_data.get('battery_level'),
                    timestamp=timezone.now()
                )
                
                # Se há viagem ativa, atualiza a posição atual da viagem
                if active_trip:
                    active_trip.current_latitude = location.latitude
                    active_trip.current_longitude = location.longitude
                    active_trip.save()
            
            response_serializer = DriverLocationSerializer(location)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['post'])
    def start_trip(self, request):
        """
        POST /api/drivers/start_trip/
        Sinal de início de viagem de motorista
        REGRA: Motorista deve existir e não pode ter viagem ativa
        """
        serializer = TripStartSerializer(data=request.data)
        if serializer.is_valid():
            cpf = serializer.validated_data['cpf']
            
            # Busca o motorista (NÃO cria se não existir)
            try:
                driver = Driver.objects.get(cpf=cpf, is_active=True)
            except Driver.DoesNotExist:
                return Response(
                    {'error': 'Motorista não encontrado ou inativo'}, 
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Verifica se já há viagem ativa
            active_trip = DriverTrip.objects.filter(
                driver=driver, 
                status='started'
            ).first()
            
            if active_trip:
                return Response(
                    {'error': 'Motorista já possui uma viagem ativa'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            with transaction.atomic():
                # Cria a viagem
                trip = DriverTrip.objects.create(
                    driver=driver,
                    start_latitude=serializer.validated_data['start_latitude'],
                    start_longitude=serializer.validated_data['start_longitude'],
                    current_latitude=serializer.validated_data['start_latitude'],
                    current_longitude=serializer.validated_data['start_longitude'],
                    status='started',
                    started_at=timezone.now()
                )
            
            response_serializer = DriverTripSerializer(trip)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['post'])
    def end_trip(self, request):
        """
        POST /api/drivers/end_trip/
        Sinal de fim de viagem de motorista
        REGRA: Deve haver viagem ativa para finalizar
        """
        serializer = TripEndSerializer(data=request.data)
        if serializer.is_valid():
            cpf = serializer.validated_data['cpf']
            
            # Busca o motorista
            try:
                driver = Driver.objects.get(cpf=cpf, is_active=True)
            except Driver.DoesNotExist:
                return Response(
                    {'error': 'Motorista não encontrado ou inativo'}, 
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Busca a viagem ativa
            try:
                trip = DriverTrip.objects.filter(
                    driver=driver, 
                    status='started'
                ).latest('started_at')
            except DriverTrip.DoesNotExist:
                return Response(
                    {'error': 'Nenhuma viagem ativa encontrada'}, 
                    status=status.HTTP_404_NOT_FOUND
                )
            
            with transaction.atomic():
                # Atualiza a viagem
                trip.end_latitude = serializer.validated_data['end_latitude']
                trip.end_longitude = serializer.validated_data['end_longitude']
                trip.status = 'completed'
                trip.completed_at = timezone.now()
                
                # Calcula duração se possível
                if trip.started_at:
                    duration = trip.completed_at - trip.started_at
                    trip.duration_minutes = int(duration.total_seconds() / 60)
                
                # Adiciona distância se fornecida
                if serializer.validated_data.get('distance_km'):
                    trip.distance_km = serializer.validated_data['distance_km']
                
                trip.save()
            
            response_serializer = DriverTripSerializer(trip)
            return Response(response_serializer.data)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['get'])
    def get_driver_data(self, request):
        """
        GET /api/drivers/get_driver_data/?cpf=12345678901
        Puxar dados de um CPF específico
        """
        cpf = request.query_params.get('cpf')
        if not cpf:
            return Response(
                {'error': 'CPF é obrigatório'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            driver = Driver.objects.get(cpf=cpf)
        except Driver.DoesNotExist:
            return Response(
                {'error': 'Motorista não encontrado'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Inclui localizações e viagens
        driver.locations = driver.locations.all()[:50]  # Últimas 50 localizações
        driver.trips = driver.trips.all()[:20]  # Últimas 20 viagens
        
        serializer = DriverDataSerializer(driver)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def check_driver(self, request):
        """
        GET /api/drivers/check_driver/?cpf=12345678901
        Verificar se um CPF específico está cadastrado
        """
        cpf = request.query_params.get('cpf')
        if not cpf:
            return Response(
                {'error': 'CPF é obrigatório'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            driver = Driver.objects.get(cpf=cpf)
            # Retorna informações básicas do motorista
            response_data = {
                'cpf': driver.cpf,
                'name': driver.name,
                'phone': driver.phone,
                'is_active': driver.is_active,
                'is_registered': True,
                'created_at': driver.created_at,
                'last_activity': driver.locations.latest('timestamp').timestamp if driver.locations.exists() else None
            }
            return Response(response_data)
        except Driver.DoesNotExist:
            return Response({
                'cpf': cpf,
                'is_registered': False,
                'message': 'CPF não encontrado no sistema'
            })
        except Exception as e:
            return Response(
                {'error': f'Erro ao verificar CPF: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class DriverLocationViewSet(viewsets.ModelViewSet):
    """
    ViewSet para gerenciar localizações dos motoristas
    """
    queryset = DriverLocation.objects.all()
    serializer_class = DriverLocationSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        queryset = DriverLocation.objects.all()
        cpf = self.request.query_params.get('cpf')
        if cpf:
            queryset = queryset.filter(driver__cpf=cpf)
        return queryset.order_by('-timestamp')


class DriverTripViewSet(viewsets.ModelViewSet):
    """
    ViewSet para gerenciar viagens dos motoristas
    """
    queryset = DriverTrip.objects.all()
    serializer_class = DriverTripSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        queryset = DriverTrip.objects.all()
        cpf = self.request.query_params.get('cpf')
        if cpf:
            queryset = queryset.filter(driver__cpf=cpf)
        return queryset.order_by('-created_at')