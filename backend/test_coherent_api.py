#!/usr/bin/env python
"""
Script para testar a compatibilidade das APIs reorganizadas
"""
import os
import sys
import django
from django.conf import settings

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.test import TestCase
from django.test.client import Client
from django.contrib.auth import get_user_model
from apps.core.models import Driver, DriverLocation, DriverTrip, Frete
from apps.users.models import Cliente, PerfilUsuario
import json

User = get_user_model()

def test_api_compatibility():
    """Testa a compatibilidade das APIs reorganizadas"""
    print("🚀 Testando compatibilidade das APIs reorganizadas...")
    
    client = Client()
    
    # 1. Testar criação de usuário com perfil
    print("\n1. Testando criação de usuário com perfil...")
    try:
        user_data = {
            'username': 'teste_motorista',
            'email': 'motorista@teste.com',
            'password': 'teste123',
            'first_name': 'João',
            'last_name': 'Silva',
            'cpf': '12345678901'
        }
        
        # Criar usuário
        user = User.objects.create_user(**user_data)
        print(f"✅ Usuário criado: {user.username}")
        
        # Verificar se o perfil foi criado automaticamente
        if hasattr(user, 'perfil'):
            print(f"✅ Perfil criado automaticamente: {user.perfil.tipo_usuario}")
        else:
            print("❌ Perfil não foi criado automaticamente")
            
    except Exception as e:
        print(f"❌ Erro ao criar usuário: {e}")
    
    # 2. Testar criação de cliente
    print("\n2. Testando criação de cliente...")
    try:
        cliente = Cliente.objects.create(
            nome='Empresa Teste',
            cnpj='12345678000199',
            telefone='11999999999',
            email='empresa@teste.com',
            usuario_empresa_principal=user
        )
        print(f"✅ Cliente criado: {cliente.nome}")
    except Exception as e:
        print(f"❌ Erro ao criar cliente: {e}")
    
    # 3. Testar criação de frete
    print("\n3. Testando criação de frete...")
    try:
        frete = Frete.objects.create(
            nome_frete='Frete Teste',
            numero_nota_fiscal='NF001',
            cliente=cliente,
            motorista=user,
            origem='São Paulo, SP',
            destino='Rio de Janeiro, RJ',
            status_atual='AGUARDANDO_CARGA'
        )
        print(f"✅ Frete criado: {frete.nome_frete} - {frete.codigo_publico}")
    except Exception as e:
        print(f"❌ Erro ao criar frete: {e}")
    
    # 4. Testar API de verificação de motorista
    print("\n4. Testando API de verificação de motorista...")
    try:
        response = client.get('/api/v1/drivers/check_driver/?cpf=12345678901')
        if response.status_code == 200:
            data = response.json()
            print(f"✅ API check_driver funcionando: {data.get('is_registered')}")
        else:
            print(f"❌ Erro na API check_driver: {response.status_code}")
    except Exception as e:
        print(f"❌ Erro ao testar API check_driver: {e}")
    
    # 5. Testar API de fretes ativos
    print("\n5. Testando API de fretes ativos...")
    try:
        response = client.get('/api/v1/drivers/get_active_fretes/?cpf=12345678901')
        if response.status_code == 200:
            data = response.json()
            print(f"✅ API get_active_fretes funcionando: {data.get('total')} fretes")
        else:
            print(f"❌ Erro na API get_active_fretes: {response.status_code}")
    except Exception as e:
        print(f"❌ Erro ao testar API get_active_fretes: {e}")
    
    # 6. Testar API de envio de localização
    print("\n6. Testando API de envio de localização...")
    try:
        location_data = {
            'cpf': '12345678901',
            'latitude': -23.5505,
            'longitude': -46.6333,
            'frete_id': frete.id,
            'accuracy': 10.0,
            'speed': 50.0,
            'battery_level': 85
        }
        
        response = client.post('/api/v1/drivers/send_location_with_frete/', 
                             data=json.dumps(location_data),
                             content_type='application/json')
        
        if response.status_code == 201:
            data = response.json()
            print(f"✅ API send_location_with_frete funcionando: {data.get('message')}")
        else:
            print(f"❌ Erro na API send_location_with_frete: {response.status_code} - {response.content}")
    except Exception as e:
        print(f"❌ Erro ao testar API send_location_with_frete: {e}")
    
    # 7. Testar APIs de fretes
    print("\n7. Testando APIs de fretes...")
    try:
        # Listar fretes
        response = client.get('/api/v1/fretes/fretes/')
        if response.status_code == 200:
            data = response.json()
            print(f"✅ API de fretes funcionando: {len(data.get('results', []))} fretes")
        else:
            print(f"❌ Erro na API de fretes: {response.status_code}")
    except Exception as e:
        print(f"❌ Erro ao testar API de fretes: {e}")
    
    print("\n🎉 Teste de compatibilidade concluído!")

if __name__ == '__main__':
    test_api_compatibility()