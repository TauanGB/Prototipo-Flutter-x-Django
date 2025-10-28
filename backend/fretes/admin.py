from django.contrib import admin
from apps.core.models import Frete, Material, StatusHistory, FotoFrete, PontoLocalizacao, Rota, FreteRota


@admin.register(Frete)
class FreteAdmin(admin.ModelAdmin):
    list_display = ['nome_frete', 'numero_nota_fiscal', 'cliente', 'motorista', 'status_atual', 'data_criacao']
    list_filter = ['status_atual', 'tipo_servico', 'data_criacao']
    search_fields = ['nome_frete', 'numero_nota_fiscal', 'codigo_publico']
    readonly_fields = ['codigo_publico', 'data_criacao', 'data_atualizacao']


@admin.register(Material)
class MaterialAdmin(admin.ModelAdmin):
    list_display = ['frete', 'nome', 'quantidade', 'unidade_medida']
    list_filter = ['unidade_medida']


@admin.register(StatusHistory)
class StatusHistoryAdmin(admin.ModelAdmin):
    list_display = ['frete', 'status_anterior', 'status_novo', 'usuario', 'data_alteracao']
    list_filter = ['status_novo', 'data_alteracao']
    readonly_fields = ['data_alteracao']


@admin.register(FotoFrete)
class FotoFreteAdmin(admin.ModelAdmin):
    list_display = ['frete', 'legenda', 'timestamp']
    list_filter = ['timestamp']


@admin.register(PontoLocalizacao)
class PontoLocalizacaoAdmin(admin.ModelAdmin):
    list_display = ['frete', 'latitude', 'longitude', 'timestamp']
    list_filter = ['timestamp']


@admin.register(Rota)
class RotaAdmin(admin.ModelAdmin):
    list_display = ['nome', 'motorista', 'status', 'data_criacao']
    list_filter = ['status', 'data_criacao']
    search_fields = ['nome']


@admin.register(FreteRota)
class FreteRotaAdmin(admin.ModelAdmin):
    list_display = ['rota', 'frete', 'ordem', 'status_rota']
    list_filter = ['status_rota']
