from django.contrib.auth.models import AbstractUser
from django.db import models
from django.db.models.signals import post_save
from django.dispatch import receiver
from apps.core.models import TimeStampedModel


class User(AbstractUser, TimeStampedModel):
    """
    Modelo de usuário customizado compatível com SistemaEG3
    """
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=20, blank=True, null=True)
    avatar = models.ImageField(upload_to='avatars/', blank=True, null=True)
    is_verified = models.BooleanField(default=False)
    cpf = models.CharField(max_length=14, blank=True, null=True, unique=True)
    ativo = models.BooleanField(default=True)

    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = ['email']

    class Meta:
        verbose_name = 'Usuário'
        verbose_name_plural = 'Usuários'

    def __str__(self):
        return self.email


class PerfilUsuario(models.Model):
    """
    Modelo para estender o usuário padrão com informações específicas
    para o sistema de logística da EG3 (compatível com SistemaEG3)
    """
    TIPO_USUARIO_CHOICES = [
        ('MOTORISTA', 'Motorista/Operador'),
        ('CLIENTE', 'Cliente'),
        ('EMPRESA', 'Empresa'),
        ('ADMINISTRATIVO', 'Equipe Administrativa (Backoffice)'),
        ('GESTOR', 'Gestor'),
    ]
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='perfil')
    tipo_usuario = models.CharField(max_length=20, choices=TIPO_USUARIO_CHOICES, default='CLIENTE')
    telefone = models.CharField(max_length=20, blank=True, null=True)
    ativo = models.BooleanField(default=True)
    data_criacao = models.DateTimeField(auto_now_add=True)
    data_atualizacao = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Perfil de Usuário'
        verbose_name_plural = 'Perfis de Usuários'
    
    def __str__(self):
        return f"{self.user.get_full_name()} - {self.get_tipo_usuario_display()}"


@receiver(post_save, sender=User)
def criar_perfil_usuario(sender, instance, created, **kwargs):
    """
    Cria automaticamente um perfil quando um usuário é criado
    """
    if created:
        PerfilUsuario.objects.create(user=instance)


class Cliente(models.Model):
    """
    Modelo para clientes da EG3 Logística (Empresas) - Compatível com SistemaEG3
    """
    nome = models.CharField(max_length=255, help_text="Nome do cliente (ex: Dínamo, Ellca)")
    cnpj = models.CharField(max_length=18, blank=True, null=True)
    telefone = models.CharField(max_length=20, blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    endereco = models.TextField(blank=True, null=True)
    ativo = models.BooleanField(default=True)
    data_criacao = models.DateTimeField(auto_now_add=True)
    
    # Referência ao usuário empresa principal (quem criou a conta)
    usuario_empresa_principal = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='empresa_principal',
        null=True, 
        blank=True,
        help_text="Usuário principal da empresa que gerencia esta conta"
    )
    
    class Meta:
        verbose_name = 'Cliente'
        verbose_name_plural = 'Clientes'
        ordering = ['nome']
    
    def __str__(self):
        return self.nome


class UsuarioEmpresa(models.Model):
    """
    Modelo para usuários subordinados de uma empresa - Compatível com SistemaEG3
    """
    TIPO_ACESSO_CHOICES = [
        ('ADMIN_EMPRESA', 'Administrador da Empresa'),
        ('OPERADOR', 'Operador'),
        ('VISUALIZADOR', 'Apenas Visualização'),
    ]
    
    usuario = models.OneToOneField(
        User, 
        on_delete=models.CASCADE, 
        related_name='usuario_empresa'
    )
    empresa = models.ForeignKey(
        Cliente, 
        on_delete=models.CASCADE, 
        related_name='usuarios_empresa'
    )
    tipo_acesso = models.CharField(
        max_length=20, 
        choices=TIPO_ACESSO_CHOICES, 
        default='OPERADOR'
    )
    ativo = models.BooleanField(default=True)
    data_criacao = models.DateTimeField(auto_now_add=True)
    criado_por = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='usuarios_criados'
    )
    
    class Meta:
        verbose_name = 'Usuário da Empresa'
        verbose_name_plural = 'Usuários da Empresa'
        unique_together = ['usuario', 'empresa']
    
    def __str__(self):
        return f"{self.usuario.get_full_name()} - {self.empresa.nome}"

