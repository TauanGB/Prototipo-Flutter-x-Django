from django.contrib.auth import authenticate, login
from django.contrib.auth.models import User
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.utils.decorators import method_decorator
from django.views import View
import json
import logging

logger = logging.getLogger(__name__)


@method_decorator(csrf_exempt, name='dispatch')
class LoginView(View):
    """
    View para autenticação de usuários
    """
    
    def post(self, request):
        try:
            data = json.loads(request.body)
            username_or_email = data.get('username') or data.get('email')
            password = data.get('password')
            
            if not username_or_email or not password:
                return JsonResponse({
                    'success': False,
                    'message': 'Username/Email e senha são obrigatórios'
                }, status=400)
            
            # Tenta autenticar primeiro com username, depois com email
            user = authenticate(request, username=username_or_email, password=password)
            
            # Se não encontrou com username, tenta com email
            if user is None:
                try:
                    from django.contrib.auth import get_user_model
                    User = get_user_model()
                    user_obj = User.objects.get(email=username_or_email)
                    user = authenticate(request, username=user_obj.username, password=password)
                except User.DoesNotExist:
                    pass
            
            if user is not None:
                login(request, user)
                return JsonResponse({
                    'success': True,
                    'message': 'Login realizado com sucesso',
                    'user': {
                        'id': user.id,
                        'email': user.email,
                        'username': user.username,
                        'first_name': user.first_name,
                        'last_name': user.last_name,
                    }
                })
            else:
                return JsonResponse({
                    'success': False,
                    'message': 'Credenciais inválidas'
                }, status=401)
                
        except json.JSONDecodeError:
            return JsonResponse({
                'success': False,
                'message': 'Dados JSON inválidos'
            }, status=400)
        except Exception as e:
            logger.error(f"Erro no login: {str(e)}")
            return JsonResponse({
                'success': False,
                'message': 'Erro interno do servidor'
            }, status=500)


@method_decorator(csrf_exempt, name='dispatch')
class LogoutView(View):
    """
    View para logout de usuários
    """
    
    def post(self, request):
        try:
            from django.contrib.auth import logout
            logout(request)
            return JsonResponse({
                'success': True,
                'message': 'Logout realizado com sucesso'
            })
        except Exception as e:
            logger.error(f"Erro no logout: {str(e)}")
            return JsonResponse({
                'success': False,
                'message': 'Erro interno do servidor'
            }, status=500)


@method_decorator(csrf_exempt, name='dispatch')
class UserInfoView(View):
    """
    View para obter informações do usuário logado
    """
    
    def get(self, request):
        try:
            if request.user.is_authenticated:
                return JsonResponse({
                    'success': True,
                    'user': {
                        'id': request.user.id,
                        'email': request.user.email,
                        'username': request.user.username,
                        'first_name': request.user.first_name,
                        'last_name': request.user.last_name,
                    }
                })
            else:
                return JsonResponse({
                    'success': False,
                    'message': 'Usuário não autenticado'
                }, status=401)
        except Exception as e:
            logger.error(f"Erro ao obter informações do usuário: {str(e)}")
            return JsonResponse({
                'success': False,
                'message': 'Erro interno do servidor'
            }, status=500)
