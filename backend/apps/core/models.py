from django.db import models


class TimeStampedModel(models.Model):
    """
    Modelo abstrato que fornece campos de timestamp automaticos
    """
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class Location(TimeStampedModel):
    """
    Modelo para armazenar localizacoes fixas
    """
    name = models.CharField(max_length=100)
    address = models.TextField()
    latitude = models.DecimalField(max_digits=10, decimal_places=7)
    longitude = models.DecimalField(max_digits=10, decimal_places=7)
    description = models.TextField(blank=True, null=True)
    created_by = models.ForeignKey('users.User', on_delete=models.CASCADE)

    class Meta:
        verbose_name = 'Localizacao'
        verbose_name_plural = 'Localizacoes'

    def __str__(self):
        return self.name


class DriverLocation(TimeStampedModel):
    """
    Modelo para armazenar localizacao em tempo real do motorista
    """
    STATUS_CHOICES = [
        ('online', 'Online'),
        ('offline', 'Offline'),
        ('driving', 'Dirigindo'),
        ('stopped', 'Parado'),
        ('break', 'Em Pausa'),
    ]

    driver = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='driver_locations')
    latitude = models.DecimalField(max_digits=10, decimal_places=7)
    longitude = models.DecimalField(max_digits=10, decimal_places=7)
    accuracy = models.FloatField(null=True, blank=True, help_text="Precisao da localizacao em metros")
    speed = models.FloatField(null=True, blank=True, help_text="Velocidade em km/h")
    heading = models.FloatField(null=True, blank=True, help_text="Direcao em graus")
    altitude = models.FloatField(null=True, blank=True, help_text="Altitude em metros")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='online')
    battery_level = models.IntegerField(null=True, blank=True, help_text="Nivel da bateria em %")
    is_gps_enabled = models.BooleanField(default=True)
    device_id = models.CharField(max_length=100, blank=True, null=True, help_text="ID unico do dispositivo")
    app_version = models.CharField(max_length=20, blank=True, null=True)
    timestamp = models.DateTimeField(auto_now_add=True, help_text="Timestamp do GPS")

    class Meta:
        verbose_name = 'Localizacao do Motorista'
        verbose_name_plural = 'Localizacoes dos Motoristas'
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['driver', '-timestamp']),
            models.Index(fields=['status', '-timestamp']),
        ]

    def __str__(self):
        return f"{self.driver.username} - {self.latitude}, {self.longitude} - {self.status}"

    @property
    def full_name(self):
        return f"{self.driver.first_name} {self.driver.last_name}".strip() or self.driver.username


class DriverTrip(TimeStampedModel):
    """
    Modelo para armazenar viagens dos motoristas
    """
    STATUS_CHOICES = [
        ('started', 'Iniciada'),
        ('in_progress', 'Em Andamento'),
        ('completed', 'Concluida'),
        ('cancelled', 'Cancelada'),
    ]

    driver = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='trips')
    start_location = models.ForeignKey(
        DriverLocation, 
        on_delete=models.SET_NULL, 
        null=True, 
        related_name='trips_started'
    )
    end_location = models.ForeignKey(
        DriverLocation, 
        on_delete=models.SET_NULL, 
        null=True, 
        related_name='trips_ended'
    )
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
        return f"Viagem {self.id} - {self.driver.username} - {self.status}"


class TestSession(TimeStampedModel):
    """
    Modelo para sessoes de teste
    """
    STATUS_CHOICES = [
        ('draft', 'Rascunho'),
        ('active', 'Ativa'),
        ('completed', 'Concluida'),
        ('cancelled', 'Cancelada'),
    ]

    name = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True)
    location = models.ForeignKey(Location, on_delete=models.CASCADE)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    created_by = models.ForeignKey('users.User', on_delete=models.CASCADE)

    class Meta:
        verbose_name = 'Sessao de Teste'
        verbose_name_plural = 'Sessoes de Teste'

    def __str__(self):
        return self.name