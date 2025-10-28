from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'fretes', views.FreteViewSet)
router.register(r'materiais', views.MaterialViewSet)
router.register(r'historico-status', views.StatusHistoryViewSet)
router.register(r'fotos', views.FotoFreteViewSet)
router.register(r'localizacoes', views.PontoLocalizacaoViewSet)
router.register(r'rotas', views.RotaViewSet)
router.register(r'fretes-rota', views.FreteRotaViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
