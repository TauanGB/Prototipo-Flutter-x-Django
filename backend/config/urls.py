"""
URL configuration for config project.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from apps.api.views import home_page

urlpatterns = [
    # path('admin/', admin.site.urls),  # Temporariamente desabilitado
    path('api/v1/', include('apps.api.urls')),
    path('api-auth/', include('rest_framework.urls')),
    path('', home_page, name='home'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)

