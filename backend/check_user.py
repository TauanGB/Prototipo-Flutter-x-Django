#!/usr/bin/env python
"""
Script para verificar usuário no banco de dados
"""
import os
import sys
import django

# Configura o Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.contrib.auth import get_user_model
from django.contrib.auth import authenticate

User = get_user_model()

def check_user():
    """Verifica se o usuário existe e pode fazer login"""
    try:
        # Lista todos os usuários
        print("=== Usuários no banco de dados ===")
        users = User.objects.all()
        for user in users:
            print(f"ID: {user.id}")
            print(f"Username: {user.username}")
            print(f"Email: {user.email}")
            print(f"First Name: {user.first_name}")
            print(f"Last Name: {user.last_name}")
            print(f"Is Active: {user.is_active}")
            print("-" * 30)
        
        # Testa autenticação
        print("\n=== Testando autenticação ===")
        user = authenticate(username='motorista_teste', password='123456')
        if user:
            print("SUCESSO - Autenticação com username funcionou!")
            print(f"Usuário: {user.username}")
        else:
            print("ERRO - Autenticação com username falhou")
            
        # Testa com email
        user = authenticate(username='motorista@teste.com', password='123456')
        if user:
            print("SUCESSO - Autenticação com email funcionou!")
            print(f"Usuário: {user.username}")
        else:
            print("ERRO - Autenticação com email falhou")
            
    except Exception as e:
        print(f"Erro: {e}")

if __name__ == '__main__':
    check_user()
