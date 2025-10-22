#!/usr/bin/env python3
"""
Script para testar a API com lógica coerente
"""
import requests
import json
import time

# URL base da API
BASE_URL = "http://localhost:8000/api/v1"

def test_send_location_without_driver():
    """Testa envio de localização com CPF não cadastrado"""
    print("\n=== TESTE: Enviar Localização - CPF Não Cadastrado ===")
    
    url = f"{BASE_URL}/drivers/send_location/"
    data = {
        "cpf": "00000000000",  # CPF que não existe
        "latitude": -23.5505,
        "longitude": -46.6333,
        "accuracy": 10.5,
        "speed": 25.0,
        "battery_level": 85
    }
    
    try:
        response = requests.post(url, json=data)
        print(f"Status: {response.status_code}")
        if response.status_code == 404:
            print("✅ CORRETO: Motorista não encontrado (como esperado)")
            return True
        else:
            print(f"❌ ERRO: Deveria retornar 404, mas retornou {response.status_code}")
            print(f"Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")
        return False

def test_send_location_with_driver(cpf, name):
    """Testa envio de localização com CPF cadastrado"""
    print(f"\n=== TESTE: Enviar Localização - {name} ({cpf}) ===")
    
    url = f"{BASE_URL}/drivers/send_location/"
    data = {
        "cpf": cpf,
        "latitude": -23.5505 + (hash(cpf) % 100) / 10000,
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

def test_start_trip_without_driver():
    """Testa início de viagem com CPF não cadastrado"""
    print("\n=== TESTE: Iniciar Viagem - CPF Não Cadastrado ===")
    
    url = f"{BASE_URL}/drivers/start_trip/"
    data = {
        "cpf": "00000000000",  # CPF que não existe
        "start_latitude": -23.5505,
        "start_longitude": -46.6333
    }
    
    try:
        response = requests.post(url, json=data)
        print(f"Status: {response.status_code}")
        if response.status_code == 404:
            print("✅ CORRETO: Motorista não encontrado (como esperado)")
            return True
        else:
            print(f"❌ ERRO: Deveria retornar 404, mas retornou {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")
        return False

def test_start_trip_with_driver(cpf, name):
    """Testa início de viagem com CPF cadastrado"""
    print(f"\n=== TESTE: Iniciar Viagem - {name} ({cpf}) ===")
    
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

def test_start_trip_already_active(cpf, name):
    """Testa início de viagem quando já há viagem ativa"""
    print(f"\n=== TESTE: Iniciar Viagem Duplicada - {name} ({cpf}) ===")
    
    url = f"{BASE_URL}/drivers/start_trip/"
    data = {
        "cpf": cpf,
        "start_latitude": -23.5505 + (hash(cpf) % 100) / 10000,
        "start_longitude": -46.6333 + (hash(cpf) % 100) / 10000
    }
    
    try:
        response = requests.post(url, json=data)
        print(f"Status: {response.status_code}")
        if response.status_code == 400:
            print("✅ CORRETO: Viagem duplicada bloqueada (como esperado)")
            return True
        else:
            print(f"❌ ERRO: Deveria retornar 400, mas retornou {response.status_code}")
            print(f"Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")
        return False

def test_send_location_during_trip(cpf, name):
    """Testa envio de localização durante viagem ativa"""
    print(f"\n=== TESTE: Localização Durante Viagem - {name} ({cpf}) ===")
    
    url = f"{BASE_URL}/drivers/send_location/"
    data = {
        "cpf": cpf,
        "latitude": -23.5515 + (hash(cpf) % 100) / 10000,
        "longitude": -46.6343 + (hash(cpf) % 100) / 10000,
        "accuracy": 8.5,
        "speed": 30.0,
        "battery_level": 80
    }
    
    try:
        response = requests.post(url, json=data)
        print(f"Status: {response.status_code}")
        if response.status_code == 201:
            print("✅ Localização atualizada durante viagem")
            return True
        else:
            print(f"❌ Erro: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")
        return False

def test_end_trip_without_active(cpf, name):
    """Testa fim de viagem sem viagem ativa"""
    print(f"\n=== TESTE: Finalizar Viagem Sem Viagem Ativa - {name} ({cpf}) ===")
    
    url = f"{BASE_URL}/drivers/end_trip/"
    data = {
        "cpf": cpf,
        "end_latitude": -23.5515,
        "end_longitude": -46.6343,
        "distance_km": 5.2
    }
    
    try:
        response = requests.post(url, json=data)
        print(f"Status: {response.status_code}")
        if response.status_code == 404:
            print("✅ CORRETO: Nenhuma viagem ativa (como esperado)")
            return True
        else:
            print(f"❌ ERRO: Deveria retornar 404, mas retornou {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")
        return False

def test_end_trip_with_active(cpf, name):
    """Testa fim de viagem com viagem ativa"""
    print(f"\n=== TESTE: Finalizar Viagem Ativa - {name} ({cpf}) ===")
    
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

def test_get_trip_status(cpf, name):
    """Testa busca de status da viagem"""
    print(f"\n=== TESTE: Status da Viagem - {name} ({cpf}) ===")
    
    url = f"{BASE_URL}/driver-trips/"
    params = {"cpf": cpf}
    
    try:
        response = requests.get(url, params=params)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            if data:
                latest_trip = data[0]  # Viagem mais recente
                print(f"✅ Viagem encontrada: Status = {latest_trip.get('status')}")
                if latest_trip.get('current_latitude'):
                    print(f"   Posição atual: {latest_trip.get('current_latitude')}, {latest_trip.get('current_longitude')}")
                return True
            else:
                print("⚠️  Nenhuma viagem encontrada")
                return True
        else:
            print(f"❌ Erro: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")
        return False

def main():
    """Executa todos os testes com lógica coerente"""
    print("TESTANDO API COM LOGICA COERENTE")
    print("=" * 60)
    
    # CPFs de teste (que existem no banco)
    test_drivers = [
        ("12345678901", "Joao Silva Santos"),
        ("98765432100", "Maria Oliveira Costa"),
    ]
    
    # Aguardar servidor iniciar
    print("Aguardando servidor iniciar...")
    time.sleep(3)
    
    results = []
    
    # Teste 1: Tentar enviar localização sem motorista cadastrado
    print(f"\n{'='*60}")
    print("TESTE 1: OPERACOES SEM MOTORISTA CADASTRADO")
    print(f"{'='*60}")
    
    test1_result = test_send_location_without_driver()
    results.append(("Enviar Localizacao - CPF Nao Cadastrado", test1_result))
    
    test2_result = test_start_trip_without_driver()
    results.append(("Iniciar Viagem - CPF Nao Cadastrado", test2_result))
    
    # Teste 2: Operações com motorista cadastrado
    for cpf, name in test_drivers:
        print(f"\n{'='*60}")
        print(f"TESTE 2: OPERACOES COM {name} ({cpf})")
        print(f"{'='*60}")
        
        # Enviar localização
        test3_result = test_send_location_with_driver(cpf, name)
        results.append((f"Enviar Localizacao - {name}", test3_result))
        
        # Iniciar viagem
        test4_result = test_start_trip_with_driver(cpf, name)
        results.append((f"Iniciar Viagem - {name}", test4_result))
        
        # Tentar iniciar viagem duplicada
        test5_result = test_start_trip_already_active(cpf, name)
        results.append((f"Viagem Duplicada - {name}", test5_result))
        
        # Enviar localização durante viagem
        test6_result = test_send_location_during_trip(cpf, name)
        results.append((f"Localizacao Durante Viagem - {name}", test6_result))
        
        # Verificar status da viagem
        test7_result = test_get_trip_status(cpf, name)
        results.append((f"Status da Viagem - {name}", test7_result))
        
        # Finalizar viagem
        test8_result = test_end_trip_with_active(cpf, name)
        results.append((f"Finalizar Viagem - {name}", test8_result))
        
        # Tentar finalizar viagem novamente
        test9_result = test_end_trip_without_active(cpf, name)
        results.append((f"Finalizar Viagem Sem Ativa - {name}", test9_result))
    
    # Resumo dos resultados
    print(f"\n{'='*60}")
    print("RESUMO DOS TESTES")
    print(f"{'='*60}")
    
    passed = 0
    for test_name, result in results:
        status = "PASSOU" if result else "FALHOU"
        print(f"{test_name}: {status}")
        if result:
            passed += 1
    
    print(f"\nResultado: {passed}/{len(results)} testes passaram")
    
    if passed == len(results):
        print("Todos os testes passaram! API com logica coerente funcionando.")
    else:
        print("Alguns testes falharam. Verifique a logica da API.")

if __name__ == "__main__":
    main()
