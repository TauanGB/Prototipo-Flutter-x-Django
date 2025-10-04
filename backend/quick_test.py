#!/usr/bin/env python3
"""
Teste rápido da API - Verifica se está funcionando
"""
import requests
import json

def quick_test():
    """Teste rápido da API"""
    
    print("🚀 Teste Rápido da API")
    print("=" * 30)
    
    # URL da API
    url = "http://localhost:8000/api/location/"
    
    # Headers simples
    headers = {
        "Content-Type": "application/json"
    }
    
    # Dados de teste
    test_data = {
        "latitude": -23.5505,
        "longitude": -46.6333,
        "accuracy": 10.0,
        "altitude": 750.0,
        "speed": 0.0,
        "heading": 180.0,
        "timestamp": "2024-01-01T12:00:00Z",
        "device_id": "test-device-123"
    }
    
    print(f"📡 Testando: {url}")
    print(f"📦 Dados: {json.dumps(test_data, indent=2)}")
    
    try:
        # Teste POST
        print("\n📤 Enviando dados...")
        response = requests.post(url, headers=headers, json=test_data, timeout=10)
        
        print(f"Status: {response.status_code}")
        print(f"Resposta: {response.text}")
        
        if response.status_code in [200, 201]:
            print("✅ SUCESSO! API funcionando sem token!")
        else:
            print("❌ ERRO! Verifique a configuração da API")
            
    except requests.exceptions.ConnectionError:
        print("❌ ERRO! Servidor não está rodando")
        print("💡 Execute: python manage.py runserver")
        
    except requests.exceptions.Timeout:
        print("❌ ERRO! Timeout na requisição")
        
    except Exception as e:
        print(f"❌ ERRO! {e}")

if __name__ == "__main__":
    quick_test()
