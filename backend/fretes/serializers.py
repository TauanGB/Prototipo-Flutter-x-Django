from rest_framework import serializers
from apps.core.models import Frete, Material, StatusHistory, FotoFrete, PontoLocalizacao, Rota, FreteRota
from apps.users.models import Cliente, User


class MaterialSerializer(serializers.ModelSerializer):
    class Meta:
        model = Material
        fields = ['id', 'nome', 'quantidade', 'unidade_medida']


class StatusHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = StatusHistory
        fields = ['id', 'status_anterior', 'status_novo', 'usuario', 'data_alteracao', 'observacoes']
        read_only_fields = ['id', 'data_alteracao']


class FotoFreteSerializer(serializers.ModelSerializer):
    class Meta:
        model = FotoFrete
        fields = ['id', 'imagem', 'legenda', 'timestamp']
        read_only_fields = ['id', 'timestamp']


class PontoLocalizacaoSerializer(serializers.ModelSerializer):
    class Meta:
        model = PontoLocalizacao
        fields = ['id', 'latitude', 'longitude', 'timestamp']
        read_only_fields = ['id', 'timestamp']


class ClienteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Cliente
        fields = ['id', 'nome', 'cnpj', 'telefone', 'email']


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'email', 'cpf']


class FreteSerializer(serializers.ModelSerializer):
    cliente_nome = serializers.CharField(source='cliente.nome', read_only=True)
    motorista_nome = serializers.CharField(source='motorista.get_full_name', read_only=True)
    materiais = MaterialSerializer(many=True, read_only=True)
    historico_status = StatusHistorySerializer(many=True, read_only=True)
    fotos = FotoFreteSerializer(many=True, read_only=True)
    pontos_localizacao = PontoLocalizacaoSerializer(many=True, read_only=True)
    
    class Meta:
        model = Frete
        fields = [
            'id', 'nome_frete', 'numero_nota_fiscal', 'codigo_publico',
            'cliente', 'cliente_nome', 'motorista', 'motorista_nome',
            'tipo_servico', 'origem', 'origem_link_google', 'destino', 'destino_link_google',
            'data_agendamento', 'hora_agendamento', 'data_hora_agendamento',
            'status_atual', 'data_criacao', 'data_atualizacao',
            'data_chegada_cd', 'data_inicio_viagem', 'data_chegada_destino', 'data_finalizacao',
            'data_inicio_operacao_munck', 'data_fim_operacao_munck',
            'tempo_estimado_horas', 'data_limite_notificacao', 'observacoes', 'ativo',
            'materiais', 'historico_status', 'fotos', 'pontos_localizacao'
        ]
        read_only_fields = ['id', 'codigo_publico', 'data_criacao', 'data_atualizacao']


class FreteCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Frete
        fields = [
            'nome_frete', 'numero_nota_fiscal', 'cliente', 'motorista',
            'tipo_servico', 'origem', 'origem_link_google', 'destino', 'destino_link_google',
            'data_agendamento', 'hora_agendamento', 'data_hora_agendamento',
            'tempo_estimado_horas', 'observacoes'
        ]


class FreteUpdateStatusSerializer(serializers.Serializer):
    status_novo = serializers.ChoiceField(choices=Frete._meta.get_field('status_atual').choices)
    observacoes = serializers.CharField(required=False, allow_blank=True)


class RotaSerializer(serializers.ModelSerializer):
    motorista_nome = serializers.CharField(source='motorista.get_full_name', read_only=True)
    
    class Meta:
        model = Rota
        fields = [
            'id', 'nome', 'motorista', 'motorista_nome', 'data_criacao',
            'data_inicio', 'data_conclusao', 'status', 'observacoes', 'ativo'
        ]
        read_only_fields = ['id', 'data_criacao']


class FreteRotaSerializer(serializers.ModelSerializer):
    frete_nome = serializers.CharField(source='frete.nome_frete', read_only=True)
    
    class Meta:
        model = FreteRota
        fields = [
            'id', 'rota', 'frete', 'frete_nome', 'ordem', 'status_rota',
            'data_inicio_execucao', 'data_conclusao_execucao'
        ]
        read_only_fields = ['id']


# Serializers para compatibilidade com APIs existentes do Flutter
class DriverFreteSerializer(serializers.ModelSerializer):
    """
    Serializer simplificado para compatibilidade com APIs existentes do Flutter
    """
    class Meta:
        model = Frete
        fields = [
            'id', 'nome_frete', 'numero_nota_fiscal', 'codigo_publico',
            'status_atual', 'data_criacao', 'origem', 'destino',
            'data_agendamento', 'observacoes'
        ]
        read_only_fields = ['id', 'codigo_publico', 'data_criacao']


class DriverLocationFreteSerializer(serializers.Serializer):
    """
    Serializer para envio de localização com frete ativo
    """
    cpf = serializers.CharField(max_length=14)
    latitude = serializers.DecimalField(max_digits=10, decimal_places=7)
    longitude = serializers.DecimalField(max_digits=10, decimal_places=7)
    accuracy = serializers.FloatField(required=False, allow_null=True)
    speed = serializers.FloatField(required=False, allow_null=True)
    battery_level = serializers.IntegerField(required=False, allow_null=True)
    frete_id = serializers.IntegerField(required=False, allow_null=True)
    
    def validate_latitude(self, value):
        if not (-90 <= value <= 90):
            raise serializers.ValidationError("Latitude deve estar entre -90 e 90 graus")
        return value
    
    def validate_longitude(self, value):
        if not (-180 <= value <= 180):
            raise serializers.ValidationError("Longitude deve estar entre -180 e 180 graus")
        return value
