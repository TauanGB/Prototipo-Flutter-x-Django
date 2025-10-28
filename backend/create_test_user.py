#!/usr/bin/env python
"""
Script para criar um usuário de teste para o sistema de login
"""
import os
import sys
import django

# Configura o Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.contrib.auth import get_user_model
from django.core.management import execute_from_command_line

User = get_user_model()

def create_test_user():
    """Cria um usuário de teste para login"""
    try:
        # Verifica se o usuário já existe
        if User.objects.filter(email='motorista@teste.com').exists():
            print("Usuário de teste já existe!")
            user = User.objects.get(email='motorista@teste.com')
            print(f"Email: {user.email}")
            print(f"Username: {user.username}")
            print("Senha: 123456")
            return user
        
        # Cria o usuário
        user = User.objects.create_user(
            username='motorista_teste',
            email='motorista@teste.com',
            password='123456',
            first_name='João',
            last_name='Silva',
            is_active=True,
            is_verified=True
        )
        
        print("Usuário de teste criado com sucesso!")
        print(f"Email: {user.email}")
        print(f"Username: {user.username}")
        print("Senha: 123456")
        print("\nUse essas credenciais para testar o login no app Flutter.")
        
        return user
        
    except Exception as e:
        print(f"Erro ao criar usuário de teste: {e}")
        return None

if __name__ == '__main__':
    create_test_user()

