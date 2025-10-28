from django.db import models
from django.utils import timezone
from datetime import timedelta
import random
import string


class TimeStampedModel(models.Model):
    """
    Modelo abstrato que fornece campos de timestamp automaticos
    """
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


def get_default_user():
    """
    Função para obter um usuário padrão, evitando importação circular
    """
    from django.contrib.auth import get_user_model
    User = get_user_model()
    try:
        return User.objects.first()
    except:
        return None


class Driver(TimeStampedModel):
    """
    Modelo simplificado para motoristas usando CPF como identificador
    Mantém compatibilidade com APIs existentes do Flutter
    """
    cpf = models.CharField(max_length=14, unique=True, help_text="CPF do motorista")
    name = models.CharField(max_length=100, help_text="Nome completo do motorista")
    phone = models.CharField(max_length=20, blank=True, null=True, help_text="Telefone do motorista")
    is_active = models.BooleanField(default=True, help_text="Motorista ativo")

    class Meta:
        verbose_name = 'Motorista'
        verbose_name_plural = 'Motoristas'
        ordering = ['name']

    def __str__(self):
        return f"{self.name} - {self.cpf}"


class DriverLocation(TimeStampedModel):
    """
    Modelo simplificado para localização do motorista
    Mantém compatibilidade com APIs existentes do Flutter
    """
    driver = models.ForeignKey(Driver, on_delete=models.CASCADE, related_name='locations')
    latitude = models.DecimalField(max_digits=10, decimal_places=7)
    longitude = models.DecimalField(max_digits=10, decimal_places=7)
    accuracy = models.FloatField(null=True, blank=True, help_text="Precisão da localização em metros")
    speed = models.FloatField(null=True, blank=True, help_text="Velocidade em km/h")
    battery_level = models.IntegerField(null=True, blank=True, help_text="Nível da bateria em %")
    timestamp = models.DateTimeField(default=timezone.now, help_text="Timestamp do GPS")

    class Meta:
        verbose_name = 'Localização do Motorista'
        verbose_name_plural = 'Localizações dos Motoristas'
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['driver', '-timestamp']),
        ]

    def __str__(self):
        return f"{self.driver.name} - {self.latitude}, {self.longitude}"


class DriverTrip(TimeStampedModel):
    """
    Modelo simplificado para viagens dos motoristas
    Mantém compatibilidade com APIs existentes do Flutter
    """
    STATUS_CHOICES = [
        ('started', 'Iniciada'),
        ('completed', 'Concluída'),
        ('cancelled', 'Cancelada'),
    ]

    driver = models.ForeignKey(Driver, on_delete=models.CASCADE, related_name='trips')
    start_latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    start_longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    end_latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    end_longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    # Posição atual durante a viagem
    current_latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True, help_text="Posição atual durante a viagem")
    current_longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True, help_text="Posição atual durante a viagem")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='started')
    distance_km = models.FloatField(null=True, blank=True)
    duration_minutes = models.IntegerField(null=True, blank=True)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = 'Viagem do Motorista'
        verbose_name_plural = 'Viagens dos Motoristas'
        ordering = ['-created_at']

    def __str__(self):
        return f"Viagem {self.id} - {self.driver.name} - {self.status}"


# ===== MODELOS COMPATÍVEIS COM SISTEMAEG3 =====

def get_default_user():
    """Função para obter usuário padrão"""
    from django.contrib.auth import get_user_model
    User = get_user_model()
    user, created = User.objects.get_or_create(username='cliente_padrao')
    return user.pk


# Adicionamos um campo para diferenciar os tipos de serviço, como pedido na especificação
TIPO_SERVICO_CHOICES = [
    ('TRANSPORTE', 'Transporte de Materiais'),
    ('MUNCK_CARGA', 'Serviço Munck - Carregamento'),
    ('MUNCK_DESCARGA', 'Serviço Munck - Descarregamento'),
]

# para o motorista será feita na view, baseada no TIPO_SERVICO_CHOICES.
STATUS_CHOICES = [
    # Status Geral
    ('NAO_INICIADO', 'Não Iniciado'),
    ('CANCELADO', 'Cancelado'),
    
    # Status para TRANSPORTE
    ('AGUARDANDO_CARGA', 'Aguardando Carga'),
    ('EM_TRANSITO', 'Em Trânsito'),
    ('EM_DESCARGA_CLIENTE', 'Chegou no Destino'),
    ('FINALIZADO', 'Entrega Finalizada'),
    
    # Status para MUNCK_CARGA
    ('CARREGAMENTO_NAO_INICIADO', 'Carregamento não Iniciado'),
    ('CARREGAMENTO_INICIADO', 'Carregamento Iniciado'),
    ('CARREGAMENTO_CONCLUIDO', 'Carregamento Concluído'),

    # Status para MUNCK_DESCARGA
    ('DESCARREGAMENTO_NAO_INICIADO', 'Descarregamento não Iniciado'),
    ('DESCARREGAMENTO_INICIADO', 'Descarregamento Iniciado'),
    ('DESCARREGAMENTO_CONCLUIDO', 'Descarregamento Concluído'),
]


class Frete(models.Model):
    """
    Modelo principal para serviços de transporte e Munck da EG3 Logística
    Compatível com SistemaEG3
    """
    # --- Identificação e Relacionamentos ---
    nome_frete = models.CharField(max_length=255, default="Frete", help_text="Nome/Descrição do Frete (ex: Frete Postes, Entrega Material)")
    numero_nota_fiscal = models.CharField(max_length=50, unique=True, null=True, blank=True, help_text="Número da Nota Fiscal (opcional)")
    codigo_publico = models.CharField(max_length=10, unique=True, blank=True, help_text="Código público para acompanhamento sem login")
    cliente = models.ForeignKey('users.Cliente', on_delete=models.PROTECT, related_name='fretes', default=get_default_user)
    motorista = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True, blank=True, related_name='fretes_como_motorista')
    
    # --- Tipo de Serviço ---
    tipo_servico = models.CharField(max_length=20, choices=TIPO_SERVICO_CHOICES, default='TRANSPORTE', help_text="Define o fluxo de trabalho do serviço")

    # --- Informações da Carga ---
    origem = models.CharField(max_length=255, blank=True, null=True, help_text="Endereço de partida (opcional)")
    origem_link_google = models.URLField(max_length=500, blank=True, null=True, help_text="Link do Google Maps para a origem")
    destino = models.CharField(max_length=255, blank=True, null=True, help_text="Endereço de entrega (opcional)")
    destino_link_google = models.URLField(max_length=500, blank=True, null=True, help_text="Link do Google Maps para o destino")
    
    # --- Data de Agendamento ---
    data_agendamento = models.DateField(default=timezone.now, help_text="Data agendada para o serviço")
    hora_agendamento = models.TimeField(null=True, blank=True, help_text="Hora agendada para o serviço (formato HH:MM)")
    data_hora_agendamento = models.DateTimeField(null=True, blank=True, help_text="Data e hora completa do agendamento")

    # --- Status e Timestamps ---
    status_atual = models.CharField(max_length=30, choices=STATUS_CHOICES, default='NAO_INICIADO')
    data_criacao = models.DateTimeField(auto_now_add=True, help_text="Data de criação do registro no sistema")
    data_atualizacao = models.DateTimeField(auto_now=True)
    
    # Timestamps para Transporte de Materiais
    data_chegada_cd = models.DateTimeField(null=True, blank=True, help_text="Transporte: Chegou para carregar")
    data_inicio_viagem = models.DateTimeField(null=True, blank=True, help_text="Transporte: Carga concluída, viagem iniciada")
    data_chegada_destino = models.DateTimeField(null=True, blank=True, help_text="Transporte: Chegou ao destino para descarregar")
    data_finalizacao = models.DateTimeField(null=True, blank=True, help_text="Transporte: Entrega finalizada com sucesso")

    # Timestamps para Munck
    data_inicio_operacao_munck = models.DateTimeField(null=True, blank=True, help_text="Munck: Início do carregamento/descarregamento")
    data_fim_operacao_munck = models.DateTimeField(null=True, blank=True, help_text="Munck: Fim do carregamento/descarregamento")
    
    # Campos para controle de tempo e notificações
    tempo_estimado_horas = models.IntegerField(default=2, help_text="Tempo estimado em horas para conclusão da operação")
    data_limite_notificacao = models.DateTimeField(null=True, blank=True, help_text="Data limite calculada para notificações")
    
    # Campos adicionais
    observacoes = models.TextField(blank=True, null=True, help_text="Observações gerais sobre o serviço")
    ativo = models.BooleanField(default=True)

    def __str__(self):
        nf_info = f" - NF: {self.numero_nota_fiscal}" if self.numero_nota_fiscal else ""
        destino_info = f" - {self.destino}" if self.destino else ""
        return f"{self.nome_frete}{nf_info} - {self.cliente.nome}{destino_info}"
    
    def save(self, *args, **kwargs):
        if not self.codigo_publico:
            self.codigo_publico = self.gerar_codigo_publico()
        
        # Calcular data limite de notificação se não existir
        if not self.data_limite_notificacao and self.data_hora_agendamento:
            self.data_limite_notificacao = self.data_hora_agendamento + timedelta(hours=self.tempo_estimado_horas)
        
        super().save(*args, **kwargs)
    
    def gerar_codigo_publico(self):
        """Gera um código público único de 8 caracteres"""
        while True:
            codigo = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
            if not Frete.objects.filter(codigo_publico=codigo).exists():
                return codigo


class Material(models.Model):
    """
    Para permitir múltiplos materiais por frete, como na especificação.
    """
    frete = models.ForeignKey(Frete, on_delete=models.CASCADE, related_name='materiais')
    nome = models.CharField(max_length=200, help_text="Ex: Poste Circular-12/1000")
    quantidade = models.DecimalField(max_digits=10, decimal_places=2)
    unidade_medida = models.CharField(max_length=50, default='un.', help_text="Ex: un., metros, kg")

    def __str__(self):
        return f"{self.quantidade} {self.unidade_medida} de {self.nome}"


class StatusHistory(models.Model):
    """
    Histórico de alterações de status para auditoria e timeline
    """
    frete = models.ForeignKey(Frete, on_delete=models.CASCADE, related_name='historico_status')
    status_anterior = models.CharField(max_length=30, choices=STATUS_CHOICES, blank=True, null=True)
    status_novo = models.CharField(max_length=30, choices=STATUS_CHOICES)
    usuario = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True, blank=True)
    data_alteracao = models.DateTimeField(auto_now_add=True)
    observacoes = models.TextField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'Histórico de Status'
        verbose_name_plural = 'Histórico de Status'
        ordering = ['-data_alteracao']
    
    def __str__(self):
        return f"Frete {self.frete.numero_nota_fiscal} - {self.get_status_novo_display()} em {self.data_alteracao.strftime('%d/%m/%Y %H:%M')}"


class FotoFrete(models.Model):
    """
    Para permitir o upload de fotos opcionais, como no item 6 da especificação.
    """
    frete = models.ForeignKey(Frete, on_delete=models.CASCADE, related_name='fotos')
    imagem = models.ImageField(upload_to='fotos_fretes/')
    legenda = models.CharField(max_length=255, blank=True, null=True)
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Foto do Frete #{self.frete.id} em {self.timestamp.strftime('%d/%m/%Y')}"


class PontoLocalizacao(models.Model):
    """
    Armazena um ponto geográfico (latitude/longitude) de um frete em um determinado momento.
    """
    frete = models.ForeignKey(Frete, on_delete=models.CASCADE, related_name='pontos_localizacao')
    latitude = models.DecimalField(max_digits=10, decimal_places=7)
    longitude = models.DecimalField(max_digits=10, decimal_places=7)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"Localização de Frete #{self.frete.id} em {self.timestamp.strftime('%d/%m/%Y %H:%M')}"


class Rota(models.Model):
    """
    Modelo para agrupar fretes em rotas sequenciais para motoristas
    """
    STATUS_CHOICES = [
        ('PLANEJADA', 'Planejada'),
        ('EM_ANDAMENTO', 'Em Andamento'),
        ('CONCLUIDA', 'Concluída'),
        ('CANCELADA', 'Cancelada')
    ]
    
    nome = models.CharField(max_length=255, help_text="Nome identificador da rota")
    motorista = models.ForeignKey(
        'users.User', 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='rotas_atribuidas',
        help_text="Motorista responsável pela rota"
    )
    data_criacao = models.DateTimeField(auto_now_add=True)
    data_inicio = models.DateTimeField(null=True, blank=True, help_text="Data/hora de início da rota")
    data_conclusao = models.DateTimeField(null=True, blank=True, help_text="Data/hora de conclusão da rota")
    status = models.CharField(
        max_length=20, 
        choices=STATUS_CHOICES, 
        default='PLANEJADA',
        help_text="Status atual da rota"
    )
    observacoes = models.TextField(blank=True, null=True, help_text="Observações sobre a rota")
    ativo = models.BooleanField(default=True)
    
    class Meta:
        verbose_name = 'Rota'
        verbose_name_plural = 'Rotas'
        ordering = ['-data_criacao']
    
    def __str__(self):
        motorista_info = f" - {self.motorista.get_full_name()}" if self.motorista else ""
        return f"{self.nome}{motorista_info}"


class FreteRota(models.Model):
    """
    Modelo intermediário para relacionar fretes com rotas, incluindo ordem e status
    """
    STATUS_ROTA_CHOICES = [
        ('PENDENTE', 'Pendente'),
        ('EM_EXECUCAO', 'Em Execução'),
        ('CONCLUIDO', 'Concluído')
    ]
    
    rota = models.ForeignKey(
        Rota, 
        on_delete=models.CASCADE, 
        related_name='fretes_rota',
        help_text="Rota à qual o frete pertence"
    )
    frete = models.ForeignKey(
        Frete, 
        on_delete=models.CASCADE,
        help_text="Frete incluído na rota"
    )
    ordem = models.PositiveIntegerField(help_text="Ordem de execução do frete na rota")
    status_rota = models.CharField(
        max_length=20, 
        choices=STATUS_ROTA_CHOICES, 
        default='PENDENTE',
        help_text="Status do frete dentro da rota"
    )
    data_inicio_execucao = models.DateTimeField(null=True, blank=True, help_text="Data/hora de início da execução")
    data_conclusao_execucao = models.DateTimeField(null=True, blank=True, help_text="Data/hora de conclusão da execução")
    
    class Meta:
        ordering = ['ordem']
        unique_together = ['rota', 'frete']
        verbose_name = 'Frete da Rota'
        verbose_name_plural = 'Fretes da Rota'
    
    def __str__(self):
        return f"{self.rota.nome} - {self.frete.nome_frete} (Ordem: {self.ordem})"