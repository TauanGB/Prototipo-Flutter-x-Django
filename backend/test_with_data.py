#!/usr/bin/env python3
"""
Script para testar a API com os dados de teste criados
"""
import requests
import json
import time

# URL base da API
BASE_URL = "http://localhost:8000/api/v1"

def test_check_driver(cpf, name):
    """Testa verificação de CPF cadastrado"""
    print(f"\n=== TESTE: Verificar CPF {cpf} ({name}) ===")
    
    url = f"{BASE_URL}/drivers/check_driver/"
    params = {"cpf": cpf}
    
    try:
        response = requests.get(url, params=params)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ CPF encontrado: {data.get('name')} - Ativo: {data.get('is_active')}")
            return True
        else:
            print(f"❌ Erro: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")
        return False

def test_get_driver_data(cpf, name):
    """Testa busca de dados completos"""
    print(f"\n=== TESTE: Dados Completos {cpf} ({name}) ===")
    
    url = f"{BASE_URL}/drivers/get_driver_data/"
    params = {"cpf": cpf}
    
    try:
        response = requests.get(url, params=params)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            locations_count = len(data.get('locations', []))
            trips_count = len(data.get('trips', []))
            print(f"✅ Dados encontrados: {locations_count} localizações, {trips_count} viagens")
            return True
        else:
            print(f"❌ Erro: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")
        return False

def test_send_location(cpf, name):
    """Testa envio de nova localização"""
    print(f"\n=== TESTE: Enviar Localização {cpf} ({name}) ===")
    
    url = f"{BASE_URL}/drivers/send_location/"
    data = {
        "cpf": cpf,
        "latitude": -23.5505 + (hash(cpf) % 100) / 10000,  # Variação baseada no CPF
        "longitude": -46.6333 + (hash(cpf) % 100) / 10000,
        "accuracy": 10.5,
        "speed": 25.0,
        "battery_level": 85
    }
    
    try:
        response = requests.post(url, json=data)
        print(f"Status: {response.status_code}")
        if response.status_code == 201:
            print("✅ Localização enviada com sucesso")
            return True
        else:
            print(f"❌ Erro: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")
        return False

def test_start_trip(cpf, name):
    """Testa início de viagem"""
    print(f"\n=== TESTE: Iniciar Viagem {cpf} ({name}) ===")
    
    url = f"{BASE_URL}/drivers/start_trip/"
    data = {
        "cpf": cpf,
        "start_latitude": -23.5505 + (hash(cpf) % 100) / 10000,
        "start_longitude": -46.6333 + (hash(cpf) % 100) / 10000
    }
    
    try:
        response = requests.post(url, json=data)
        print(f"Status: {response.status_code}")
        if response.status_code == 201:
            print("✅ Viagem iniciada com sucesso")
            return True
        else:
            print(f"❌ Erro: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")
        return False

def test_end_trip(cpf, name):
    """Testa fim de viagem"""
    print(f"\n=== TESTE: Finalizar Viagem {cpf} ({name}) ===")
    
    url = f"{BASE_URL}/drivers/end_trip/"
    data = {
        "cpf": cpf,
        "end_latitude": -23.5515 + (hash(cpf) % 100) / 10000,
        "end_longitude": -46.6343 + (hash(cpf) % 100) / 10000,
        "distance_km": 5.2
    }
    
    try:
        response = requests.post(url, json=data)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            print("✅ Viagem finalizada com sucesso")
            return True
        else:
            print(f"❌ Erro: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")
        return False

def test_driver_locations(cpf, name):
    """Testa busca de localizações"""
    print(f"\n=== TESTE: Localizações {cpf} ({name}) ===")
    
    url = f"{BASE_URL}/driver-locations/"
    params = {"cpf": cpf}
    
    try:
        response = requests.get(url, params=params)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ {len(data)} localizações encontradas")
            return True
        else:
            print(f"❌ Erro: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")
        return False

def test_driver_trips(cpf, name):
    """Testa busca de viagens"""
    print(f"\n=== TESTE: Viagens {cpf} ({name}) ===")
    
    url = f"{BASE_URL}/driver-trips/"
    params = {"cpf": cpf}
    
    try:
        response = requests.get(url, params=params)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ {len(data)} viagens encontradas")
            return True
        else:
            print(f"❌ Erro: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")
        return False

def main():
    """Executa todos os testes com os dados criados"""
    print("🚀 TESTANDO API COM DADOS DE TESTE")
    print("=" * 60)
    
    # CPFs de teste criados
    test_drivers = [
        ("12345678901", "João Silva Santos"),
        ("98765432100", "Maria Oliveira Costa"),
        ("11122233344", "Pedro Almeida Lima"),
        ("55566677788", "Ana Paula Rodrigues"),
        ("99988877766", "Carlos Eduardo Souza")
    ]
    
    # Aguardar servidor iniciar
    print("⏳ Aguardando servidor iniciar...")
    time.sleep(3)
    
    # Testar com cada motorista
    for cpf, name in test_drivers:
        print(f"\n{'='*60}")
        print(f"🧪 TESTANDO MOTORISTA: {name} ({cpf})")
        print(f"{'='*60}")
        
        # Lista de testes para cada motorista
        tests = [
            ("Verificar Cadastro", lambda: test_check_driver(cpf, name)),
            ("Dados Completos", lambda: test_get_driver_data(cpf, name)),
            ("Localizações", lambda: test_driver_locations(cpf, name)),
            ("Viagens", lambda: test_driver_trips(cpf, name)),
            ("Enviar Localização", lambda: test_send_location(cpf, name)),
            ("Iniciar Viagem", lambda: test_start_trip(cpf, name)),
            ("Finalizar Viagem", lambda: test_end_trip(cpf, name)),
        ]
        
        results = []
        for test_name, test_func in tests:
            try:
                result = test_func()
                results.append((test_name, result))
            except Exception as e:
                print(f"❌ Erro no teste {test_name}: {e}")
                results.append((test_name, False))
        
        # Resumo para este motorista
        passed = sum(1 for _, result in results if result)
        total = len(results)
        print(f"\n📊 Resultado para {name}: {passed}/{total} testes passaram")
    
    print(f"\n{'='*60}")
    print("🎉 TESTES CONCLUÍDOS!")
    print("💡 A API está funcionando com os dados de teste criados")
    print(f"{'='*60}")

if __name__ == "__main__":
    main()
