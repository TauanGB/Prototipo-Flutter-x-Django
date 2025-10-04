#!/usr/bin/env python3
"""
Script específico para testar a API no formato do Flutter
Testa o endpoint exato que o app Flutter usa
"""
import requests
import json
import time
from datetime import datetime

# Configurações da API (mesmo formato do Flutter)
BASE_URL = "http://localhost:8000"
ENDPOINT = "/api/location/"

# Headers básicos (sem autenticação)
headers = {
    "Content-Type": "application/json",
    "Accept": "application/json"
}

def test_flutter_endpoint():
    """Testa o endpoint exato que o Flutter usa"""
    
    print("📱 Testando endpoint do Flutter...")
    print(f"URL: {BASE_URL}{ENDPOINT}")
    
    # Dados exatamente como o Flutter envia
    flutter_data = {
        "latitude": -23.5505,
        "longitude": -46.6333,
        "accuracy": 10.5,
        "altitude": 750.0,
        "speed": 0.0,
        "heading": 180.0,
        "timestamp": datetime.now().isoformat(),
        "device_id": "flutter_device_123456789"
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}{ENDPOINT}",
            headers=headers,
            json=flutter_data,
            timeout=30
        )
        
        print(f"Status Code: {response.status_code}")
        print(f"Headers: {dict(response.headers)}")
        
        if response.status_code == 201:
            print("✅ Dados enviados com sucesso!")
            print(f"Resposta: {response.text}")
            return True
        elif response.status_code == 200:
            print("✅ Dados processados com sucesso!")
            print(f"Resposta: {response.text}")
            return True
        else:
            print(f"❌ Erro: {response.status_code}")
            print(f"Resposta: {response.text}")
            return False
            
    except requests.exceptions.Timeout:
        print("❌ Timeout na requisição")
        return False
    except requests.exceptions.ConnectionError:
        print("❌ Erro de conexão - Verifique se o servidor está rodando")
        return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro na requisição: {e}")
        return False

def test_get_locations():
    """Testa obter localizações"""
    
    print("\n📍 Testando obter localizações...")
    
    try:
        response = requests.get(
            f"{BASE_URL}{ENDPOINT}",
            headers=headers,
            timeout=30
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ {len(data)} localizações encontradas")
            for i, location in enumerate(data[-3:]):  # Últimas 3
                print(f"  {i+1}. Lat: {location.get('latitude', 'N/A')}, Lng: {location.get('longitude', 'N/A')}")
            return True
        else:
            print(f"❌ Erro: {response.status_code}")
            print(f"Resposta: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro: {e}")
        return False

def test_multiple_requests():
    """Testa múltiplas requisições como o Flutter faria"""
    
    print("\n🔄 Testando múltiplas requisições...")
    
    # Simula 5 envios de localização
    for i in range(5):
        lat = -23.5505 + (i * 0.001)
        lng = -46.6333 + (i * 0.001)
        
        data = {
            "latitude": lat,
            "longitude": lng,
            "accuracy": 10.0,
            "altitude": 750.0,
            "speed": i * 10,
            "heading": i * 45,
            "timestamp": datetime.now().isoformat(),
            "device_id": f"flutter_device_{i}"
        }
        
        try:
            response = requests.post(
                f"{BASE_URL}{ENDPOINT}",
                headers=headers,
                json=data,
                timeout=10
            )
            
            if response.status_code in [200, 201]:
                print(f"✅ Envio {i+1}/5: {lat}, {lng}")
            else:
                print(f"❌ Erro no envio {i+1}: {response.status_code}")
                
        except requests.exceptions.RequestException as e:
            print(f"❌ Erro no envio {i+1}: {e}")
        
        time.sleep(1)  # Pausa entre envios

def main():
    """Função principal"""
    
    print("🚀 Teste Específico da API Flutter")
    print("🔓 SEM AUTENTICAÇÃO - Token removido")
    print("=" * 50)
    
    # Testa endpoint do Flutter
    print("1. Testando endpoint do Flutter...")
    if not test_flutter_endpoint():
        print("\n❌ Falha no teste básico. Verifique:")
        print("   - Servidor Django rodando: python manage.py runserver")
        print("   - URL correta: http://localhost:8000")
        print("   - Endpoint existe: /api/location/")
        return
    
    # Testa obter localizações
    print("\n2. Testando obter localizações...")
    test_get_locations()
    
    # Testa múltiplas requisições
    print("\n3. Testando múltiplas requisições...")
    test_multiple_requests()
    
    print("\n✅ Teste concluído!")
    print("💡 A API está pronta para receber dados do Flutter!")

if __name__ == "__main__":
    main()
