from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone
from django.shortcuts import render
from datetime import timedelta

from apps.core.models import Location, TestSession, DriverLocation, DriverTrip
from django.contrib.auth import get_user_model

User = get_user_model()
from apps.api.serializers import (
    UserSerializer, LocationSerializer, DriverLocationSerializer,
    DriverLocationCreateSerializer, DriverTripSerializer, TestSessionSerializer,
    HomeLocationUpdateSerializer
)


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['username', 'email', 'first_name', 'last_name']
    ordering_fields = ['username', 'email', 'created_at']
    ordering = ['username']


class LocationViewSet(viewsets.ModelViewSet):
    queryset = Location.objects.all()
    serializer_class = LocationSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'address', 'description']
    ordering_fields = ['name', 'created_at']
    ordering = ['-created_at']


class DriverLocationViewSet(viewsets.ModelViewSet):
    """
    ViewSet para gerenciar localizaÃ§Ãµes em tempo real dos motoristas
    """
    queryset = DriverLocation.objects.all()
    serializer_class = DriverLocationSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['driver', 'status', 'is_gps_enabled']
    search_fields = ['driver__username', 'driver__first_name', 'driver__last_name']
    ordering_fields = ['timestamp', 'created_at', 'speed']
    ordering = ['-timestamp']

    def get_serializer_class(self):
        if self.action == 'create':
            return DriverLocationCreateSerializer
        return DriverLocationSerializer

    def perform_create(self, serializer):
        # Se houver usuário autenticado, usa ele; senão, cria um usuário padrão
        if self.request.user.is_authenticated:
            serializer.save(driver=self.request.user)
        else:
            # Cria ou obtém um usuário padrão para dados não autenticados
            default_user, created = User.objects.get_or_create(
                username='anonymous_driver',
                defaults={
                    'email': 'anonymous@example.com',
                    'first_name': 'Motorista',
                    'last_name': 'Anônimo',
                    'is_active': True
                }
            )
            serializer.save(driver=default_user)

    @action(detail=False, methods=['post'])
    def send_location(self, request):
        """
        Endpoint para receber dados de localizaÃ§Ã£o do celular do motorista
        """
        serializer = DriverLocationCreateSerializer(data=request.data)
        if serializer.is_valid():
            # Se houver usuário autenticado, usa ele; senão, cria um usuário padrão
            if request.user.is_authenticated:
                location = serializer.save(driver=request.user)
            else:
                # Cria ou obtém um usuário padrão para dados não autenticados
                default_user, created = User.objects.get_or_create(
                    username='anonymous_driver',
                    defaults={
                        'email': 'anonymous@example.com',
                        'first_name': 'Motorista',
                        'last_name': 'Anônimo',
                        'is_active': True
                    }
                )
                location = serializer.save(driver=default_user)
            
            # Retorna os dados da localizaÃ§Ã£o criada
            response_serializer = DriverLocationSerializer(location)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['get'])
    def current_location(self, request):
        """
        Retorna a localizaÃ§Ã£o mais recente do motorista
        """
        try:
            if request.user.is_authenticated:
                latest_location = DriverLocation.objects.filter(
                    driver=request.user
                ).latest('timestamp')
            else:
                # Busca a localização mais recente do usuário padrão
                default_user = User.objects.get(username='anonymous_driver')
                latest_location = DriverLocation.objects.filter(
                    driver=default_user
                ).latest('timestamp')
            
            serializer = DriverLocationSerializer(latest_location)
            return Response(serializer.data)
        except (DriverLocation.DoesNotExist, User.DoesNotExist):
            return Response(
                {'error': 'Nenhuma localizaÃ§Ã£o encontrada'}, 
                status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=False, methods=['get'])
    def location_history(self, request):
        """
        Retorna o histÃ³rico de localizaÃ§Ãµes do motorista
        """
        hours = request.query_params.get('hours', 24)  # PadrÃ£o: Ãºltimas 24 horas
        try:
            hours = int(hours)
        except ValueError:
            hours = 24
        
        since = timezone.now() - timedelta(hours=hours)
        
        if request.user.is_authenticated:
            locations = DriverLocation.objects.filter(
                driver=request.user,
                timestamp__gte=since
            ).order_by('-timestamp')
        else:
            # Busca histórico do usuário padrão
            try:
                default_user = User.objects.get(username='anonymous_driver')
                locations = DriverLocation.objects.filter(
                    driver=default_user,
                    timestamp__gte=since
                ).order_by('-timestamp')
            except User.DoesNotExist:
                locations = DriverLocation.objects.none()
        
        serializer = DriverLocationSerializer(locations, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def online_drivers(self, request):
        """
        Retorna todos os motoristas online
        """
        online_locations = DriverLocation.objects.filter(
            status='online'
        ).select_related('driver').order_by('-timestamp')
        
        # Remove duplicatas por motorista, mantendo apenas a mais recente
        seen_drivers = set()
        unique_locations = []
        for location in online_locations:
            if location.driver.id not in seen_drivers:
                unique_locations.append(location)
                seen_drivers.add(location.driver.id)
        
        serializer = DriverLocationSerializer(unique_locations, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def update_status(self, request):
        """
        Atualiza o status do motorista (online, offline, driving, etc.)
        """
        new_status = request.data.get('status')
        if not new_status:
            return Response(
                {'error': 'Status Ã© obrigatÃ³rio'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Valida se o status Ã© vÃ¡lido
        valid_statuses = [choice[0] for choice in DriverLocation.STATUS_CHOICES]
        if new_status not in valid_statuses:
            return Response(
                {'error': f'Status invÃ¡lido. OpÃ§Ãµes: {valid_statuses}'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Busca a localizaÃ§Ã£o mais recente do motorista
        try:
            if request.user.is_authenticated:
                latest_location = DriverLocation.objects.filter(
                    driver=request.user
                ).latest('timestamp')
            else:
                # Busca a localização mais recente do usuário padrão
                default_user = User.objects.get(username='anonymous_driver')
                latest_location = DriverLocation.objects.filter(
                    driver=default_user
                ).latest('timestamp')
            
            latest_location.status = new_status
            latest_location.save()
            
            serializer = DriverLocationSerializer(latest_location)
            return Response(serializer.data)
        except (DriverLocation.DoesNotExist, User.DoesNotExist):
            return Response(
                {'error': 'Nenhuma localizaÃ§Ã£o encontrada'}, 
                status=status.HTTP_404_NOT_FOUND
            )


class DriverTripViewSet(viewsets.ModelViewSet):
    queryset = DriverTrip.objects.all()
    serializer_class = DriverTripSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['driver', 'status']
    ordering_fields = ['started_at', 'completed_at', 'created_at']
    ordering = ['-created_at']

    def get_queryset(self):
        # Motoristas sÃ³ veem suas prÃ³prias viagens
        return DriverTrip.objects.filter(driver=self.request.user)

    @action(detail=False, methods=['post'])
    def start_trip(self, request):
        """
        Inicia uma nova viagem para o motorista
        """
        # Busca a localizaÃ§Ã£o atual do motorista
        try:
            current_location = DriverLocation.objects.filter(
                driver=request.user
            ).latest('timestamp')
        except DriverLocation.DoesNotExist:
            return Response(
                {'error': 'LocalizaÃ§Ã£o atual nÃ£o encontrada'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        trip = DriverTrip.objects.create(
            driver=request.user,
            start_location=current_location,
            status='started',
            started_at=timezone.now()
        )
        
        serializer = DriverTripSerializer(trip)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def complete_trip(self, request, pk=None):
        """
        Completa uma viagem
        """
        trip = self.get_object()
        
        # Busca a localizaÃ§Ã£o atual do motorista
        try:
            current_location = DriverLocation.objects.filter(
                driver=request.user
            ).latest('timestamp')
        except DriverLocation.DoesNotExist:
            return Response(
                {'error': 'LocalizaÃ§Ã£o atual nÃ£o encontrada'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        trip.end_location = current_location
        trip.status = 'completed'
        trip.completed_at = timezone.now()
        
        # Calcula duraÃ§Ã£o se possÃ­vel
        if trip.started_at:
            duration = trip.completed_at - trip.started_at
            trip.duration_minutes = int(duration.total_seconds() / 60)
        
        trip.save()
        
        serializer = DriverTripSerializer(trip)
        return Response(serializer.data)


class TestSessionViewSet(viewsets.ModelViewSet):
    queryset = TestSession.objects.all()
    serializer_class = TestSessionSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'created_by']
    search_fields = ['name', 'description']
    ordering_fields = ['name', 'created_at']
    ordering = ['-created_at']


class HomeViewSet(viewsets.ViewSet):
    """
    ViewSet para a página home com atualizações de localização
    """
    permission_classes = [AllowAny]  # Permite acesso sem autenticação para demonstração

    def list(self, request):
        """
        Retorna uma lista com atualizações de localização para a página home
        """
        # Busca as últimas localizações de todos os motoristas
        recent_locations = DriverLocation.objects.select_related('driver').order_by('-timestamp')[:50]
        
        # Processa os dados para a página home
        location_updates = []
        for location in recent_locations:
            # Calcula se está online (última atualização há menos de 10 minutos)
            is_online = (timezone.now() - location.timestamp).total_seconds() < 600  # 10 minutos
            
            # Calcula minutos desde a última atualização
            last_update_minutes = int((timezone.now() - location.timestamp).total_seconds() / 60)
            
            location_data = {
                'id': location.id,
                'driver_name': location.full_name,
                'driver_username': location.driver.username,
                'latitude': location.latitude,
                'longitude': location.longitude,
                'status': location.status,
                'speed': location.speed,
                'battery_level': location.battery_level,
                'timestamp': location.timestamp,
                'created_at': location.created_at,
                'is_online': is_online,
                'last_update_minutes_ago': last_update_minutes
            }
            location_updates.append(location_data)
        
        serializer = HomeLocationUpdateSerializer(location_updates, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def stats(self, request):
        """
        Retorna estatísticas gerais para a página home
        """
        now = timezone.now()
        
        # Motoristas online (última atualização há menos de 10 minutos)
        online_drivers = DriverLocation.objects.filter(
            timestamp__gte=now - timedelta(minutes=10)
        ).values('driver').distinct().count()
        
        # Total de motoristas
        total_drivers = User.objects.filter(is_staff=False).count()
        
        # Viagens em andamento
        active_trips = DriverTrip.objects.filter(status='in_progress').count()
        
        # Viagens completadas hoje
        trips_today = DriverTrip.objects.filter(
            completed_at__date=now.date(),
            status='completed'
        ).count()
        
        # Localizações registradas hoje
        locations_today = DriverLocation.objects.filter(
            created_at__date=now.date()
        ).count()
        
        stats = {
            'online_drivers': online_drivers,
            'total_drivers': total_drivers,
            'active_trips': active_trips,
            'trips_today': trips_today,
            'locations_today': locations_today,
            'last_updated': now
        }
        
        return Response(stats)


def home_page(request):
    """
    View para renderizar a página home HTML
    """
    return render(request, 'home.html')
