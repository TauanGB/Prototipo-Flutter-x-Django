from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.api.views import (
    DriverViewSet, DriverLocationViewSet, DriverTripViewSet
)

router = DefaultRouter()
router.register(r'drivers', DriverViewSet)
router.register(r'driver-locations', DriverLocationViewSet)
router.register(r'driver-trips', DriverTripViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
