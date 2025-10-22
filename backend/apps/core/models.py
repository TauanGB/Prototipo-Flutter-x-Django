from django.db import models
from django.utils import timezone


class TimeStampedModel(models.Model):
    """
    Modelo abstrato que fornece campos de timestamp automaticos
    """
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class Driver(TimeStampedModel):
    """
    Modelo simplificado para motoristas usando CPF como identificador
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