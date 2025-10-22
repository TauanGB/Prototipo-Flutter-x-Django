#!/usr/bin/env python3
"""
Script para testar a API simplificada
"""
import requests
import json
from datetime import datetime

# URL base da API
BASE_URL = "http://localhost:8000/api/v1"

def test_send_location():
    """Testa POST localização com CPF do motorista"""
    print("=== TESTE: Enviar Localização ===")
    
    url = f"{BASE_URL}/drivers/send_location/"
    data = {
        "cpf": "12345678901",
        "latitude": -23.5505,
        "longitude": -46.6333,
        "accuracy": 10.5,
        "speed": 25.0,
        "battery_level": 85
    }
    
    try:
        response = requests.post(url, json=data)
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        return response.status_code == 201
    except Exception as e:
        print(f"Erro: {e}")
        return False

def test_start_trip():
    """Testa POST sinal de início de viagem"""
    print("\n=== TESTE: Iniciar Viagem ===")
    
    url = f"{BASE_URL}/drivers/start_trip/"
    data = {
        "cpf": "12345678901",
        "start_latitude": -23.5505,
        "start_longitude": -46.6333
    }
    
    try:
        response = requests.post(url, json=data)
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        return response.status_code == 201
    except Exception as e:
        print(f"Erro: {e}")
        return False

def test_end_trip():
    """Testa POST sinal de fim de viagem"""
    print("\n=== TESTE: Finalizar Viagem ===")
    
    url = f"{BASE_URL}/drivers/end_trip/"
    data = {
        "cpf": "12345678901",
        "end_latitude": -23.5515,
        "end_longitude": -46.6343,
        "distance_km": 5.2
    }
    
    try:
        response = requests.post(url, json=data)
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        return response.status_code == 200
    except Exception as e:
        print(f"Erro: {e}")
        return False

def test_get_driver_data():
    """Testa GET puxar dados de um CPF específico"""
    print("\n=== TESTE: Buscar Dados do Motorista ===")
    
    url = f"{BASE_URL}/drivers/get_driver_data/"
    params = {"cpf": "12345678901"}
    
    try:
        response = requests.get(url, params=params)
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        return response.status_code == 200
    except Exception as e:
        print(f"Erro: {e}")
        return False

def test_driver_locations():
    """Testa GET localizações de um motorista"""
    print("\n=== TESTE: Localizações do Motorista ===")
    
    url = f"{BASE_URL}/driver-locations/"
    params = {"cpf": "12345678901"}
    
    try:
        response = requests.get(url, params=params)
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        return response.status_code == 200
    except Exception as e:
        print(f"Erro: {e}")
        return False

def test_driver_trips():
    """Testa GET viagens de um motorista"""
    print("\n=== TESTE: Viagens do Motorista ===")
    
    url = f"{BASE_URL}/driver-trips/"
    params = {"cpf": "12345678901"}
    
    try:
        response = requests.get(url, params=params)
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        return response.status_code == 200
    except Exception as e:
        print(f"Erro: {e}")
        return False

def test_check_driver():
    """Testa GET verificar cadastro de CPF"""
    print("\n=== TESTE: Verificar Cadastro de CPF ===")
    
    url = f"{BASE_URL}/drivers/check_driver/"
    params = {"cpf": "12345678901"}
    
    try:
        response = requests.get(url, params=params)
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        return response.status_code == 200
    except Exception as e:
        print(f"Erro: {e}")
        return False

def test_check_driver_not_found():
    """Testa GET verificar cadastro de CPF não existente"""
    print("\n=== TESTE: Verificar CPF Não Cadastrado ===")
    
    url = f"{BASE_URL}/drivers/check_driver/"
    params = {"cpf": "99999999999"}
    
    try:
        response = requests.get(url, params=params)
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        return response.status_code == 200
    except Exception as e:
        print(f"Erro: {e}")
        return False

def main():
    """Executa todos os testes"""
    print("🚀 TESTANDO API SIMPLIFICADA")
    print("=" * 50)
    
    # Lista de testes
    tests = [
        ("Enviar Localização", test_send_location),
        ("Iniciar Viagem", test_start_trip),
        ("Finalizar Viagem", test_end_trip),
        ("Buscar Dados do Motorista", test_get_driver_data),
        ("Localizações do Motorista", test_driver_locations),
        ("Viagens do Motorista", test_driver_trips),
        ("Verificar Cadastro de CPF", test_check_driver),
        ("Verificar CPF Não Cadastrado", test_check_driver_not_found),
    ]
    
    results = []
    
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ Erro no teste {test_name}: {e}")
            results.append((test_name, False))
    
    # Resumo dos resultados
    print("\n" + "=" * 50)
    print("📊 RESUMO DOS TESTES")
    print("=" * 50)
    
    passed = 0
    for test_name, result in results:
        status = "✅ PASSOU" if result else "❌ FALHOU"
        print(f"{test_name}: {status}")
        if result:
            passed += 1
    
    print(f"\n🎯 Resultado: {passed}/{len(results)} testes passaram")
    
    if passed == len(results):
        print("🎉 Todos os testes passaram! API funcionando corretamente.")
    else:
        print("⚠️  Alguns testes falharam. Verifique os logs acima.")

if __name__ == "__main__":
    main()
