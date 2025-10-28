from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django.utils import timezone
from django.shortcuts import get_object_or_404
from django.db import transaction
from django.contrib.auth import get_user_model

from apps.core.models import Frete, Material, StatusHistory, FotoFrete, PontoLocalizacao, Rota, FreteRota
from apps.users.models import Cliente
from .serializers import (
    FreteSerializer, FreteCreateSerializer, FreteUpdateStatusSerializer,
    MaterialSerializer, StatusHistorySerializer, FotoFreteSerializer,
    PontoLocalizacaoSerializer, RotaSerializer, FreteRotaSerializer,
    DriverFreteSerializer, DriverLocationFreteSerializer
)

User = get_user_model()


class FreteViewSet(viewsets.ModelViewSet):
    """
    ViewSet para gerenciar fretes - Compatível com SistemaEG3
    """
    queryset = Frete.objects.all()
    serializer_class = FreteSerializer
    permission_classes = [AllowAny]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return FreteCreateSerializer
        return FreteSerializer
    
    def get_queryset(self):
        queryset = Frete.objects.all()
        status_filter = self.request.query_params.get('status')
        cliente_id = self.request.query_params.get('cliente')
        motorista_id = self.request.query_params.get('motorista')
        
        if status_filter:
            queryset = queryset.filter(status_atual=status_filter)
        if cliente_id:
            queryset = queryset.filter(cliente_id=cliente_id)
        if motorista_id:
            queryset = queryset.filter(motorista_id=motorista_id)
            
        return queryset.order_by('-data_criacao')
    
    @action(detail=True, methods=['post'])
    def update_status(self, request, pk=None):
        """
        Atualiza o status de um frete
        """
        frete = self.get_object()
        serializer = FreteUpdateStatusSerializer(data=request.data)
        
        if serializer.is_valid():
            status_anterior = frete.status_atual
            status_novo = serializer.validated_data['status_novo']
            
            with transaction.atomic():
                # Atualiza o status do frete
                frete.status_atual = status_novo
                frete.save()
                
                # Cria histórico de status
                StatusHistory.objects.create(
                    frete=frete,
                    status_anterior=status_anterior,
                    status_novo=status_novo,
                    usuario=request.user if request.user.is_authenticated else None,
                    observacoes=serializer.validated_data.get('observacoes', '')
                )
            
            return Response({'message': 'Status atualizado com sucesso'})
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'])
    def add_location(self, request, pk=None):
        """
        Adiciona ponto de localização ao frete
        """
        frete = self.get_object()
        serializer = PontoLocalizacaoSerializer(data=request.data)
        
        if serializer.is_valid():
            serializer.save(frete=frete)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def by_driver(self, request):
        """
        GET /api/fretes/by_driver/?cpf=12345678901
        Retorna fretes de um motorista específico
        """
        cpf = request.query_params.get('cpf')
        if not cpf:
            return Response(
                {'error': 'CPF é obrigatório'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            motorista = User.objects.get(cpf=cpf)
            fretes = Frete.objects.filter(motorista=motorista).order_by('-data_criacao')
            serializer = DriverFreteSerializer(fretes, many=True)
            return Response(serializer.data)
        except User.DoesNotExist:
            return Response(
                {'error': 'Motorista não encontrado'}, 
                status=status.HTTP_404_NOT_FOUND
            )
    
    @action(detail=False, methods=['post'])
    def send_location_with_frete(self, request):
        """
        POST /api/fretes/send_location_with_frete/
        Envia localização associada a um frete específico
        """
        serializer = DriverLocationFreteSerializer(data=request.data)
        if serializer.is_valid():
            cpf = serializer.validated_data['cpf']
            frete_id = serializer.validated_data.get('frete_id')
            
            try:
                motorista = User.objects.get(cpf=cpf)
            except User.DoesNotExist:
                return Response(
                    {'error': 'Motorista não encontrado'}, 
                    status=status.HTTP_404_NOT_FOUND
                )
            
            with transaction.atomic():
                # Cria ponto de localização
                location_data = {
                    'latitude': serializer.validated_data['latitude'],
                    'longitude': serializer.validated_data['longitude'],
                    'timestamp': timezone.now()
                }
                
                if frete_id:
                    try:
                        frete = Frete.objects.get(id=frete_id, motorista=motorista)
                        location = PontoLocalizacao.objects.create(
                            frete=frete,
                            **location_data
                        )
                        return Response({
                            'message': 'Localização registrada com sucesso',
                            'frete_id': frete.id,
                            'location_id': location.id
                        }, status=status.HTTP_201_CREATED)
                    except Frete.DoesNotExist:
                        return Response(
                            {'error': 'Frete não encontrado ou não atribuído ao motorista'}, 
                            status=status.HTTP_404_NOT_FOUND
                        )
                else:
                    # Busca frete ativo do motorista
                    frete_ativo = Frete.objects.filter(
                        motorista=motorista,
                        status_atual__in=['AGUARDANDO_CARGA', 'EM_TRANSITO', 'EM_DESCARGA_CLIENTE']
                    ).first()
                    
                    if frete_ativo:
                        location = PontoLocalizacao.objects.create(
                            frete=frete_ativo,
                            **location_data
                        )
                        return Response({
                            'message': 'Localização registrada com sucesso',
                            'frete_id': frete_ativo.id,
                            'location_id': location.id
                        }, status=status.HTTP_201_CREATED)
                    else:
                        return Response(
                            {'error': 'Nenhum frete ativo encontrado para o motorista'}, 
                            status=status.HTTP_404_NOT_FOUND
                        )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class MaterialViewSet(viewsets.ModelViewSet):
    """
    ViewSet para gerenciar materiais dos fretes
    """
    queryset = Material.objects.all()
    serializer_class = MaterialSerializer
    permission_classes = [AllowAny]
    
    def get_queryset(self):
        queryset = Material.objects.all()
        frete_id = self.request.query_params.get('frete')
        if frete_id:
            queryset = queryset.filter(frete_id=frete_id)
        return queryset


class StatusHistoryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet para consultar histórico de status
    """
    queryset = StatusHistory.objects.all()
    serializer_class = StatusHistorySerializer
    permission_classes = [AllowAny]
    
    def get_queryset(self):
        queryset = StatusHistory.objects.all()
        frete_id = self.request.query_params.get('frete')
        if frete_id:
            queryset = queryset.filter(frete_id=frete_id)
        return queryset.order_by('-data_alteracao')


class FotoFreteViewSet(viewsets.ModelViewSet):
    """
    ViewSet para gerenciar fotos dos fretes
    """
    queryset = FotoFrete.objects.all()
    serializer_class = FotoFreteSerializer
    permission_classes = [AllowAny]
    
    def get_queryset(self):
        queryset = FotoFrete.objects.all()
        frete_id = self.request.query_params.get('frete')
        if frete_id:
            queryset = queryset.filter(frete_id=frete_id)
        return queryset.order_by('-timestamp')


class PontoLocalizacaoViewSet(viewsets.ModelViewSet):
    """
    ViewSet para gerenciar pontos de localização dos fretes
    """
    queryset = PontoLocalizacao.objects.all()
    serializer_class = PontoLocalizacaoSerializer
    permission_classes = [AllowAny]
    
    def get_queryset(self):
        queryset = PontoLocalizacao.objects.all()
        frete_id = self.request.query_params.get('frete')
        if frete_id:
            queryset = queryset.filter(frete_id=frete_id)
        return queryset.order_by('-timestamp')


class RotaViewSet(viewsets.ModelViewSet):
    """
    ViewSet para gerenciar rotas
    """
    queryset = Rota.objects.all()
    serializer_class = RotaSerializer
    permission_classes = [AllowAny]
    
    def get_queryset(self):
        queryset = Rota.objects.all()
        motorista_id = self.request.query_params.get('motorista')
        status_filter = self.request.query_params.get('status')
        
        if motorista_id:
            queryset = queryset.filter(motorista_id=motorista_id)
        if status_filter:
            queryset = queryset.filter(status=status_filter)
            
        return queryset.order_by('-data_criacao')


class FreteRotaViewSet(viewsets.ModelViewSet):
    """
    ViewSet para gerenciar fretes em rotas
    """
    queryset = FreteRota.objects.all()
    serializer_class = FreteRotaSerializer
    permission_classes = [AllowAny]
    
    def get_queryset(self):
        queryset = FreteRota.objects.all()
        rota_id = self.request.query_params.get('rota')
        if rota_id:
            queryset = queryset.filter(rota_id=rota_id)
        return queryset.order_by('ordem')
