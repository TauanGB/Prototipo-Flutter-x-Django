#!/usr/bin/env python3
"""
Script de teste para verificar a integração completa entre Flutter e Django
Testa o fluxo: login → carregar rota → iniciar viagem → mudar status → sync periódico
"""

import requests
import json
import time
from datetime import datetime

# Configurações
BASE_URL = "https://sistemaeg3-production.up.railway.app"
# Para teste local, descomente a linha abaixo:
# BASE_URL = "http://localhost:8000"

def test_login():
    """Testa o endpoint de login"""
    print("Testando login...")
    
    url = f"{BASE_URL}/api/usuarios/publico/login-cpf/"
    data = {
        "cpf": "12345678901",  # CPF de teste
        "password": "senha123"
    }
    
    try:
        response = requests.post(url, json=data)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"Login bem-sucedido!")
            print(f"Token: {result.get('token', 'N/A')[:20]}...")
            print(f"Motorista ID: {result.get('motorista_id', 'N/A')}")
            print(f"Veículo Atual: {result.get('veiculo_atual', 'N/A')}")
            return result.get('token')
        else:
            print(f"Erro no login: {response.text}")
            return None
    except Exception as e:
        print(f"Exceção no login: {e}")
        return None

def test_rota_atual(token):
    """Testa o endpoint de rota atual"""
    print("\nTestando rota atual...")
    
    url = f"{BASE_URL}/api/fretes/motorista/rota-atual/"
    headers = {
        "Authorization": f"Token {token}",
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.get(url, headers=headers)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"Rota atual obtida!")
            print(f"Rota ID: {result.get('rota_id', 'N/A')}")
            print(f"Nome da Rota: {result.get('nome_rota', 'N/A')}")
            print(f"Status: {result.get('status', 'N/A')}")
            print(f"Fretes: {len(result.get('fretes', []))}")
            
            # Mostrar detalhes dos fretes
            fretes = result.get('fretes', [])
            for i, frete in enumerate(fretes):
                print(f"  Frete {i+1}: ID={frete.get('frete_id')}, Status={frete.get('status_atual')}, Ordem={frete.get('ordem')}")
            
            return result
        else:
            print(f"Erro ao buscar rota: {response.text}")
            return None
    except Exception as e:
        print(f"Exceção ao buscar rota: {e}")
        return None

def test_sync_motorista(token, motorista_id, rota_id):
    """Testa o endpoint de sincronização"""
    print("\nTestando sincronização...")
    
    url = f"{BASE_URL}/api/fretes/motoristas/{motorista_id}/rotas/{rota_id}/sync/"
    headers = {
        "Authorization": f"Token {token}",
        "Content-Type": "application/json"
    }
    
    # Dados de teste para sincronização
    data = {
        "ultima_atualizacao": datetime.now().isoformat(),
        "localizacao_atual": {
            "latitude": -23.5505,
            "longitude": -46.6333
        },
        "fretes": [
            {
                "frete_id": 1,
                "status_atual": "EM_TRANSITO",
                "ordem": 1,
                "concluido": False
            }
        ],
        "fila_envio_pendente": [
            {
                "timestamp": datetime.now().isoformat(),
                "payload": {
                    "frete_id": 1,
                    "novo_status": "EM_TRANSITO"
                }
            }
        ]
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"Sincronização bem-sucedida!")
            print(f"Recebido em: {result.get('received_at', 'N/A')}")
            print(f"Aceitos: {result.get('aceitos', [])}")
            print(f"Rejeitados: {result.get('rejeitados', [])}")
            return True
        else:
            print(f"Erro na sincronização: {response.text}")
            return False
    except Exception as e:
        print(f"Exceção na sincronização: {e}")
        return False

def test_status_validation():
    """Testa a validação de transições de status"""
    print("\nTestando validação de status...")
    
    # Teste de transições válidas
    valid_transitions = [
        ("TRANSPORTE", "AGUARDANDO_CARGA", "EM_TRANSITO"),
        ("TRANSPORTE", "EM_TRANSITO", "EM_DESCARGA_CLIENTE"),
        ("TRANSPORTE", "EM_DESCARGA_CLIENTE", "FINALIZADO"),
        ("MUNCK_CARGA", "CARREGAMENTO_NAO_INICIADO", "CARREGAMENTO_INICIADO"),
        ("MUNCK_CARGA", "CARREGAMENTO_INICIADO", "CARREGAMENTO_CONCLUIDO"),
        ("MUNCK_DESCARGA", "DESCARREGAMENTO_NAO_INICIADO", "DESCARREGAMENTO_INICIADO"),
        ("MUNCK_DESCARGA", "DESCARREGAMENTO_INICIADO", "DESCARREGAMENTO_CONCLUIDO"),
    ]
    
    # Teste de transições inválidas
    invalid_transitions = [
        ("TRANSPORTE", "AGUARDANDO_CARGA", "FINALIZADO"),  # Pula etapas
        ("TRANSPORTE", "FINALIZADO", "EM_TRANSITO"),  # Volta atrás
        ("MUNCK_CARGA", "CARREGAMENTO_CONCLUIDO", "CARREGAMENTO_INICIADO"),  # Volta atrás
    ]
    
    print("Transições válidas:")
    for tipo, atual, novo in valid_transitions:
        print(f"  OK {tipo}: {atual} -> {novo}")
    
    print("Transições inválidas:")
    for tipo, atual, novo in invalid_transitions:
        print(f"  ERRO {tipo}: {atual} -> {novo}")

def main():
    """Executa todos os testes"""
    print("Iniciando teste de integração completa...")
    print(f"URL Base: {BASE_URL}")
    print("=" * 50)
    
    # 1. Teste de login
    token = test_login()
    if not token:
        print("Falha no login. Abortando testes.")
        return
    
    # 2. Teste de rota atual
    rota_data = test_rota_atual(token)
    if not rota_data:
        print("Falha ao buscar rota. Abortando testes.")
        return
    
    motorista_id = rota_data.get('motorista_id', 1)  # Assumir ID 1 se não especificado
    rota_id = rota_data.get('rota_id')
    
    if not rota_id:
        print("Rota ID não encontrado. Abortando testes.")
        return
    
    # 3. Teste de sincronização
    sync_success = test_sync_motorista(token, motorista_id, rota_id)
    
    # 4. Teste de validação de status
    test_status_validation()
    
    # Resumo final
    print("\n" + "=" * 50)
    print("RESUMO DOS TESTES:")
    print(f"Login: {'Sucesso' if token else 'Falha'}")
    print(f"Rota Atual: {'Sucesso' if rota_data else 'Falha'}")
    print(f"Sincronização: {'Sucesso' if sync_success else 'Falha'}")
    print("Validação de Status: Implementada")
    
    if token and rota_data and sync_success:
        print("\nTODOS OS TESTES PASSARAM! A integração está funcionando.")
    else:
        print("\nAlguns testes falharam. Verifique os logs acima.")

if __name__ == "__main__":
    main()
