from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.api.views import (
    UserViewSet, LocationViewSet, DriverLocationViewSet, 
    DriverTripViewSet, TestSessionViewSet, HomeViewSet
)

router = DefaultRouter()
router.register(r'users', UserViewSet)
router.register(r'locations', LocationViewSet)
router.register(r'driver-locations', DriverLocationViewSet)
router.register(r'driver-trips', DriverTripViewSet)
router.register(r'test-sessions', TestSessionViewSet)
router.register(r'home', HomeViewSet, basename='home')

urlpatterns = [
    path('', include(router.urls)),
]
