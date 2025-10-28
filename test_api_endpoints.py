#!/usr/bin/env python3
"""
Script de teste para verificar se todas as APIs estão funcionando corretamente
Execute este script após aplicar as correções para validar os endpoints
"""

import requests
import json
import sys
from datetime import datetime

# Configurações
BASE_URL = "http://127.0.0.1:8000/api/v1"
TEST_CPF = "12345678901"  # CPF de teste - ajuste conforme necessário

def test_endpoint(method, url, data=None, description=""):
    """Testa um endpoint específico"""
    try:
        print(f"\n🔍 Testando: {description}")
        print(f"   {method} {url}")
        
        if method == "GET":
            response = requests.get(url, timeout=10)
        elif method == "POST":
            response = requests.post(url, json=data, timeout=10)
        elif method == "PUT":
            response = requests.put(url, json=data, timeout=10)
        elif method == "PATCH":
            response = requests.patch(url, json=data, timeout=10)
        elif method == "DELETE":
            response = requests.delete(url, timeout=10)
        
        print(f"   Status: {response.status_code}")
        
        if response.status_code < 400:
            print(f"   ✅ SUCESSO")
            if response.content:
                try:
                    json_data = response.json()
                    print(f"   Resposta: {json.dumps(json_data, indent=2, ensure_ascii=False)[:200]}...")
                except:
                    print(f"   Resposta: {response.text[:200]}...")
        else:
            print(f"   ❌ ERRO")
            print(f"   Resposta: {response.text[:200]}...")
            
        return response.status_code < 400
        
    except requests.exceptions.ConnectionError:
        print(f"   ❌ ERRO: Não foi possível conectar ao servidor")
        print(f"   Verifique se o Django está rodando em {BASE_URL}")
        return False
    except requests.exceptions.Timeout:
        print(f"   ❌ ERRO: Timeout na requisição")
        return False
    except Exception as e:
        print(f"   ❌ ERRO: {str(e)}")
        return False

def main():
    """Executa todos os testes"""
    print("🚀 INICIANDO TESTES DE API - SistemaEG3")
    print(f"📅 Data/Hora: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}")
    print(f"🌐 Base URL: {BASE_URL}")
    print("=" * 60)
    
    # Verificar se o servidor está rodando
    print("\n🔍 Verificando se o servidor está rodando...")
    try:
        response = requests.get(f"{BASE_URL}/", timeout=5)
        print("✅ Servidor está rodando!")
    except:
        print("❌ Servidor não está rodando!")
        print("Execute: cd backend && python manage.py runserver")
        sys.exit(1)
    
    # Lista de testes
    tests = [
        # Autenticação
        ("POST", f"{BASE_URL}/auth/login/", 
         {"username": "admin", "password": "admin"}, 
         "Login de autenticação"),
        
        # Drivers - Rastreamento
        ("GET", f"{BASE_URL}/drivers/check_driver/?cpf={TEST_CPF}", 
         None, 
         "Verificar se motorista existe"),
        
        ("POST", f"{BASE_URL}/drivers/send_location/", 
         {"cpf": TEST_CPF, "latitude": -23.5505, "longitude": -46.6333}, 
         "Enviar localização do motorista"),
        
        ("POST", f"{BASE_URL}/drivers/start_trip/", 
         {"cpf": TEST_CPF, "start_latitude": -23.5505, "start_longitude": -46.6333}, 
         "Iniciar viagem"),
        
        ("POST", f"{BASE_URL}/drivers/end_trip/", 
         {"cpf": TEST_CPF, "end_latitude": -23.5505, "end_longitude": -46.6333}, 
         "Finalizar viagem"),
        
        ("GET", f"{BASE_URL}/drivers/get_driver_data/?cpf={TEST_CPF}", 
         None, 
         "Obter dados do motorista"),
        
        ("GET", f"{BASE_URL}/drivers/get_active_fretes/?cpf={TEST_CPF}", 
         None, 
         "Obter fretes ativos"),
        
        ("GET", f"{BASE_URL}/drivers/get_active_rotas/?cpf={TEST_CPF}", 
         None, 
         "Obter rotas ativas"),
        
        # Fretes
        ("GET", f"{BASE_URL}/fretes/fretes/", 
         None, 
         "Listar fretes"),
        
        ("GET", f"{BASE_URL}/fretes/by_driver/?cpf={TEST_CPF}", 
         None, 
         "Fretes por motorista"),
        
        ("GET", f"{BASE_URL}/fretes/materiais/", 
         None, 
         "Listar materiais"),
        
        ("GET", f"{BASE_URL}/fretes/historico-status/", 
         None, 
         "Histórico de status"),
        
        ("GET", f"{BASE_URL}/fretes/fotos/", 
         None, 
         "Listar fotos"),
        
        ("GET", f"{BASE_URL}/fretes/localizacoes/", 
         None, 
         "Listar localizações"),
        
        ("GET", f"{BASE_URL}/fretes/rotas/", 
         None, 
         "Listar rotas"),
        
        ("GET", f"{BASE_URL}/fretes/fretes-rota/", 
         None, 
         "Listar fretes em rotas"),
        
        # Driver Locations e Trips
        ("GET", f"{BASE_URL}/driver-locations/", 
         None, 
         "Listar localizações dos motoristas"),
        
        ("GET", f"{BASE_URL}/driver-trips/", 
         None, 
         "Listar viagens dos motoristas"),
    ]
    
    # Executar testes
    passed = 0
    failed = 0
    
    for method, url, data, description in tests:
        if test_endpoint(method, url, data, description):
            passed += 1
        else:
            failed += 1
    
    # Resultado final
    print("\n" + "=" * 60)
    print("📊 RESULTADO DOS TESTES")
    print(f"✅ Sucessos: {passed}")
    print(f"❌ Falhas: {failed}")
    print(f"📈 Taxa de sucesso: {(passed/(passed+failed)*100):.1f}%")
    
    if failed == 0:
        print("\n🎉 TODOS OS TESTES PASSARAM!")
        print("✅ As APIs estão funcionando corretamente")
        print("✅ O Flutter deve conseguir se comunicar com o backend")
    else:
        print(f"\n⚠️ {failed} TESTE(S) FALHARAM")
        print("❌ Verifique os erros acima")
        print("❌ Algumas APIs podem não estar funcionando")
    
    print("\n📋 PRÓXIMOS PASSOS:")
    print("1. Se todos os testes passaram, use os arquivos corrigidos no Flutter")
    print("2. Se alguns falharam, verifique se o backend tem dados de teste")
    print("3. Execute: cd backend && python manage.py createsuperuser")
    print("4. Crie alguns dados de teste no Django Admin")
    print("5. Execute este script novamente")

if __name__ == "__main__":
    main()
