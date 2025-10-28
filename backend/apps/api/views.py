from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django.utils import timezone
from django.shortcuts import get_object_or_404
from django.db import transaction
from django.contrib.auth import get_user_model

from apps.core.models import Driver, DriverLocation, DriverTrip, Frete, PontoLocalizacao, Rota, FreteRota
from apps.api.serializers import (
    DriverSerializer, DriverLocationSerializer, DriverLocationCreateSerializer,
    DriverTripSerializer, TripStartSerializer, TripEndSerializer, DriverDataSerializer
)

User = get_user_model()


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

    @action(detail=False, methods=['get'])
    def get_active_fretes(self, request):
        """
        GET /api/drivers/get_active_fretes/?cpf=12345678901
        Retorna fretes ativos de um motorista
        """
        cpf = request.query_params.get('cpf')
        if not cpf:
            return Response(
                {'error': 'CPF é obrigatório'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            # Busca o usuário pelo CPF
            user = User.objects.get(cpf=cpf)
            
            # Busca fretes ativos do motorista
            fretes_ativos = Frete.objects.filter(
                motorista=user,
                status_atual__in=['AGUARDANDO_CARGA', 'EM_TRANSITO', 'EM_DESCARGA_CLIENTE'],
                ativo=True
            ).order_by('-data_criacao')
            
            fretes_data = []
            for frete in fretes_ativos:
                fretes_data.append({
                    'id': frete.id,
                    'nome_frete': frete.nome_frete,
                    'numero_nota_fiscal': frete.numero_nota_fiscal,
                    'codigo_publico': frete.codigo_publico,
                    'status_atual': frete.status_atual,
                    'origem': frete.origem,
                    'destino': frete.destino,
                    'data_agendamento': frete.data_agendamento,
                    'observacoes': frete.observacoes,
                    'cliente_nome': frete.cliente.nome if frete.cliente else 'N/A'
                })
            
            return Response({
                'cpf': cpf,
                'motorista': user.get_full_name(),
                'fretes_ativos': fretes_data,
                'total': len(fretes_data)
            })
            
        except User.DoesNotExist:
            return Response(
                {'error': 'Motorista não encontrado'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {'error': f'Erro ao buscar fretes: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])
    def send_location_with_frete(self, request):
        """
        POST /api/drivers/send_location_with_frete/
        Envia localização associada a um frete específico
        """
        cpf = request.data.get('cpf')
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        frete_id = request.data.get('frete_id')
        accuracy = request.data.get('accuracy')
        speed = request.data.get('speed')
        battery_level = request.data.get('battery_level')
        
        if not all([cpf, latitude, longitude]):
            return Response(
                {'error': 'CPF, latitude e longitude são obrigatórios'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            # Busca o usuário pelo CPF
            user = User.objects.get(cpf=cpf)
            
            with transaction.atomic():
                # Cria localização do motorista (compatibilidade com API existente)
                driver = Driver.objects.get(cpf=cpf)
                location = DriverLocation.objects.create(
                    driver=driver,
                    latitude=latitude,
                    longitude=longitude,
                    accuracy=accuracy,
                    speed=speed,
                    battery_level=battery_level,
                    timestamp=timezone.now()
                )
                
                # Se frete_id foi fornecido, também registra no frete
                if frete_id:
                    try:
                        frete = Frete.objects.get(id=frete_id, motorista=user)
                        ponto_frete = PontoLocalizacao.objects.create(
                            frete=frete,
                            latitude=latitude,
                            longitude=longitude,
                            timestamp=timezone.now()
                        )
                        
                        return Response({
                            'message': 'Localização registrada com sucesso',
                            'driver_location_id': location.id,
                            'frete_location_id': ponto_frete.id,
                            'frete_id': frete.id
                        }, status=status.HTTP_201_CREATED)
                        
                    except Frete.DoesNotExist:
                        return Response(
                            {'error': 'Frete não encontrado ou não atribuído ao motorista'}, 
                            status=status.HTTP_404_NOT_FOUND
                        )
                else:
                    return Response({
                        'message': 'Localização registrada com sucesso',
                        'driver_location_id': location.id
                    }, status=status.HTTP_201_CREATED)
                    
        except User.DoesNotExist:
            return Response(
                {'error': 'Motorista não encontrado'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Driver.DoesNotExist:
            return Response(
                {'error': 'Driver não encontrado'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {'error': f'Erro ao registrar localização: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def get_active_rotas(self, request):
        """
        GET /api/drivers/get_active_rotas/?cpf=12345678901
        Retorna rotas ativas de um motorista
        """
        cpf = request.query_params.get('cpf')
        if not cpf:
            return Response(
                {'error': 'CPF é obrigatório'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            # Busca o usuário pelo CPF
            user = User.objects.get(cpf=cpf)
            
            # Busca rotas ativas do motorista
            rotas_ativas = Rota.objects.filter(
                motorista=user,
                status__in=['PLANEJADA', 'EM_ANDAMENTO'],
                ativo=True
            ).order_by('-data_criacao')
            
            rotas_data = []
            for rota in rotas_ativas:
                # Busca fretes da rota com detalhes
                fretes_rota = FreteRota.objects.filter(rota=rota).select_related('frete').order_by('ordem')
                fretes_data = []
                
                for frete_rota in fretes_rota:
                    frete = frete_rota.frete
                    fretes_data.append({
                        'id': frete.id,
                        'nome_frete': frete.nome_frete,
                        'numero_nota_fiscal': frete.numero_nota_fiscal,
                        'codigo_publico': frete.codigo_publico,
                        'tipo_servico': frete.tipo_servico,
                        'tipo_servico_display': frete.get_tipo_servico_display(),
                        'status_atual': frete.status_atual,
                        'status_atual_display': frete.get_status_atual_display(),
                        'origem': frete.origem,
                        'destino': frete.destino,
                        'data_agendamento': frete.data_agendamento,
                        'observacoes': frete.observacoes,
                        'cliente_nome': frete.cliente.nome if frete.cliente else 'N/A',
                        'ordem': frete_rota.ordem,
                        'status_rota': frete_rota.status_rota,
                        'data_inicio_execucao': frete_rota.data_inicio_execucao,
                        'data_conclusao_execucao': frete_rota.data_conclusao_execucao,
                    })
                
                # Calcula estatísticas da rota
                total_fretes = fretes_rota.count()
                fretes_concluidos = fretes_rota.filter(status_rota='CONCLUIDO').count()
                progresso_percentual = (fretes_concluidos / total_fretes * 100) if total_fretes > 0 else 0
                
                rotas_data.append({
                    'id': rota.id,
                    'nome': rota.nome,
                    'motorista_id': rota.motorista.id if rota.motorista else None,
                    'motorista_nome': rota.motorista.get_full_name() if rota.motorista else None,
                    'data_criacao': rota.data_criacao,
                    'data_inicio': rota.data_inicio,
                    'data_conclusao': rota.data_conclusao,
                    'status': rota.status,
                    'status_display': rota.get_status_display(),
                    'observacoes': rota.observacoes,
                    'ativo': rota.ativo,
                    'fretes_rota': fretes_data,
                    'total_fretes': total_fretes,
                    'fretes_concluidos': fretes_concluidos,
                    'progresso_percentual': round(progresso_percentual, 2),
                })
            
            return Response({
                'cpf': cpf,
                'motorista': user.get_full_name(),
                'rotas_ativas': rotas_data,
                'total': len(rotas_data)
            })
            
        except User.DoesNotExist:
            return Response(
                {'error': 'Motorista não encontrado'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {'error': f'Erro ao buscar rotas: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])
    def update_frete_status(self, request):
        """
        POST /api/drivers/update_frete_status/
        Atualiza status de um frete específico
        """
        frete_id = request.data.get('frete_id')
        novo_status = request.data.get('novo_status')
        cpf = request.data.get('cpf')
        
        if not all([frete_id, novo_status, cpf]):
            return Response(
                {'error': 'frete_id, novo_status e cpf são obrigatórios'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            # Busca o usuário pelo CPF
            user = User.objects.get(cpf=cpf)
            
            # Busca o frete
            frete = Frete.objects.get(id=frete_id, motorista=user)
            
            # Valida se o frete pertence a uma rota do motorista
            frete_rota = FreteRota.objects.filter(frete=frete, rota__motorista=user).first()
            if not frete_rota:
                return Response(
                    {'error': 'Frete não pertence a uma rota do motorista'}, 
                    status=status.HTTP_403_FORBIDDEN
                )
            
            with transaction.atomic():
                # Valida transição de status
                status_atual = frete.status_atual
                tipo_servico = frete.tipo_servico
                
                # Define próximos status válidos baseado no tipo de serviço
                valid_transitions = {
                    'TRANSPORTE': {
                        'NAO_INICIADO': ['AGUARDANDO_CARGA'],
                        'AGUARDANDO_CARGA': ['EM_TRANSITO'],
                        'EM_TRANSITO': ['EM_DESCARGA_CLIENTE'],
                        'EM_DESCARGA_CLIENTE': ['FINALIZADO'],
                    },
                    'MUNCK_CARGA': {
                        'NAO_INICIADO': ['CARREGAMENTO_INICIADO'],
                        'CARREGAMENTO_INICIADO': ['CARREGAMENTO_CONCLUIDO'],
                    },
                    'MUNCK_DESCARGA': {
                        'NAO_INICIADO': ['DESCARREGAMENTO_INICIADO'],
                        'DESCARREGAMENTO_INICIADO': ['DESCARREGAMENTO_CONCLUIDO'],
                    }
                }
                
                if novo_status not in valid_transitions.get(tipo_servico, {}).get(status_atual, []):
                    return Response(
                        {'error': f'Transição de status inválida: {status_atual} → {novo_status} para tipo {tipo_servico}'}, 
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                # Atualiza timestamps baseado no novo status
                agora = timezone.now()
                
                if novo_status == 'AGUARDANDO_CARGA':
                    frete.data_chegada_cd = agora
                elif novo_status == 'EM_TRANSITO':
                    frete.data_inicio_viagem = agora
                elif novo_status == 'EM_DESCARGA_CLIENTE':
                    frete.data_chegada_destino = agora
                elif novo_status == 'FINALIZADO':
                    frete.data_finalizacao = agora
                elif novo_status == 'CARREGAMENTO_INICIADO':
                    frete.data_inicio_operacao_munck = agora
                elif novo_status == 'CARREGAMENTO_CONCLUIDO':
                    frete.data_fim_operacao_munck = agora
                elif novo_status == 'DESCARREGAMENTO_INICIADO':
                    frete.data_inicio_operacao_munck = agora
                elif novo_status == 'DESCARREGAMENTO_CONCLUIDO':
                    frete.data_fim_operacao_munck = agora
                
                # Atualiza status do frete
                frete.status_atual = novo_status
                frete.save()
                
                # Atualiza status do FreteRota
                if novo_status in ['FINALIZADO', 'CARREGAMENTO_CONCLUIDO', 'DESCARREGAMENTO_CONCLUIDO']:
                    frete_rota.status_rota = 'CONCLUIDO'
                    frete_rota.data_conclusao_execucao = agora
                elif novo_status in ['AGUARDANDO_CARGA', 'EM_TRANSITO', 'EM_DESCARGA_CLIENTE', 'CARREGAMENTO_INICIADO', 'DESCARREGAMENTO_INICIADO']:
                    frete_rota.status_rota = 'EM_EXECUCAO'
                    if not frete_rota.data_inicio_execucao:
                        frete_rota.data_inicio_execucao = agora
                
                frete_rota.save()
                
                # Registra no histórico de status
                from apps.core.models import StatusHistory
                StatusHistory.objects.create(
                    frete=frete,
                    status_anterior=status_atual,
                    status_novo=novo_status,
                    usuario=user,
                    observacoes=f'Status atualizado via app móvel'
                )
            
            return Response({
                'message': 'Status atualizado com sucesso',
                'frete_id': frete.id,
                'status_anterior': status_atual,
                'status_novo': novo_status,
                'tipo_servico': tipo_servico
            })
            
        except User.DoesNotExist:
            return Response(
                {'error': 'Motorista não encontrado'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Frete.DoesNotExist:
            return Response(
                {'error': 'Frete não encontrado ou não atribuído ao motorista'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {'error': f'Erro ao atualizar status: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])
    def start_rota(self, request):
        """
        POST /api/drivers/start_rota/
        Inicia uma rota (muda status para EM_ANDAMENTO)
        """
        rota_id = request.data.get('rota_id')
        cpf = request.data.get('cpf')
        
        if not all([rota_id, cpf]):
            return Response(
                {'error': 'rota_id e cpf são obrigatórios'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            # Busca o usuário pelo CPF
            user = User.objects.get(cpf=cpf)
            
            # Busca a rota
            rota = Rota.objects.get(id=rota_id, motorista=user)
            
            if rota.status != 'PLANEJADA':
                return Response(
                    {'error': f'Rota deve estar com status PLANEJADA para ser iniciada. Status atual: {rota.status}'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            with transaction.atomic():
                # Atualiza status da rota
                rota.status = 'EM_ANDAMENTO'
                rota.data_inicio = timezone.now()
                rota.save()
                
                # Marca primeiro frete como EM_EXECUCAO se ainda estiver PENDENTE
                primeiro_frete_rota = FreteRota.objects.filter(
                    rota=rota, 
                    status_rota='PENDENTE'
                ).order_by('ordem').first()
                
                if primeiro_frete_rota:
                    primeiro_frete_rota.status_rota = 'EM_EXECUCAO'
                    primeiro_frete_rota.data_inicio_execucao = timezone.now()
                    primeiro_frete_rota.save()
            
            return Response({
                'message': 'Rota iniciada com sucesso',
                'rota_id': rota.id,
                'status': rota.status,
                'data_inicio': rota.data_inicio
            })
            
        except User.DoesNotExist:
            return Response(
                {'error': 'Motorista não encontrado'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Rota.DoesNotExist:
            return Response(
                {'error': 'Rota não encontrada ou não atribuída ao motorista'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {'error': f'Erro ao iniciar rota: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])
    def complete_rota(self, request):
        """
        POST /api/drivers/complete_rota/
        Finaliza uma rota (muda status para CONCLUIDA)
        """
        rota_id = request.data.get('rota_id')
        cpf = request.data.get('cpf')
        
        if not all([rota_id, cpf]):
            return Response(
                {'error': 'rota_id e cpf são obrigatórios'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            # Busca o usuário pelo CPF
            user = User.objects.get(cpf=cpf)
            
            # Busca a rota
            rota = Rota.objects.get(id=rota_id, motorista=user)
            
            if rota.status != 'EM_ANDAMENTO':
                return Response(
                    {'error': f'Rota deve estar com status EM_ANDAMENTO para ser finalizada. Status atual: {rota.status}'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Verifica se todos os fretes estão concluídos
            fretes_pendentes = FreteRota.objects.filter(
                rota=rota, 
                status_rota__in=['PENDENTE', 'EM_EXECUCAO']
            ).count()
            
            if fretes_pendentes > 0:
                return Response(
                    {'error': f'Ainda existem {fretes_pendentes} frete(s) pendente(s) na rota'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            with transaction.atomic():
                # Atualiza status da rota
                rota.status = 'CONCLUIDA'
                rota.data_conclusao = timezone.now()
                rota.save()
            
            return Response({
                'message': 'Rota finalizada com sucesso',
                'rota_id': rota.id,
                'status': rota.status,
                'data_conclusao': rota.data_conclusao
            })
            
        except User.DoesNotExist:
            return Response(
                {'error': 'Motorista não encontrado'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Rota.DoesNotExist:
            return Response(
                {'error': 'Rota não encontrada ou não atribuída ao motorista'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {'error': f'Erro ao finalizar rota: {str(e)}'}, 
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