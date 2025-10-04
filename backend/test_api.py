#!/usr/bin/env python3
"""
Script de exemplo para testar a API de localização em tempo real
SEM NECESSIDADE DE TOKEN - Autenticação removida
"""
import requests
import json
import time
import random
from datetime import datetime

# Configurações da API
BASE_URL = "http://127.0.0.1:8000/api/v1/driver-locations/send_location/"

# Headers básicos (sem autenticação)
headers = {
    "Content-Type": "application/json"
}

def send_location_data(latitude, longitude, speed=0, status="stopped"):
    """Envia dados de localização para a API"""
    
    location_data = {
        "latitude": latitude,
        "longitude": longitude,
        "accuracy": random.uniform(5, 15),
        "speed": speed,
        "heading": random.uniform(0, 360),
        "altitude": random.uniform(700, 800),
        "status": status,
        "battery_level": random.randint(20, 100),
        "is_gps_enabled": True,
        "device_id": "test-device-123",
        "app_version": "1.0.0",
        "timestamp": datetime.now().isoformat()
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/location/",
            headers=headers,
            json=location_data
        )
        
        if response.status_code == 201:
            print(f"✅ Localização enviada: {latitude}, {longitude} - {status}")
            return True
        else:
            print(f"❌ Erro ao enviar localização: {response.status_code}")
            print(f"Resposta: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conexão: {e}")
        return False

def test_api_connection():
    """Testa conexão básica com a API"""
    
    try:
        response = requests.get(f"{BASE_URL}/location/", headers=headers)
        
        if response.status_code == 200:
            print("✅ Conexão com a API estabelecida!")
            return True
        else:
            print(f"❌ Erro na conexão: {response.status_code}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conexão: {e}")
        return False

def get_locations():
    """Obtém todas as localizações"""
    
    try:
        response = requests.get(f"{BASE_URL}/location/", headers=headers)
        
        if response.status_code == 200:
            data = response.json()
            print(f"📍 Total de localizações: {len(data)}")
            for i, location in enumerate(data[-5:]):  # Mostra as últimas 5
                print(f"  {i+1}. Lat: {location['latitude']}, Lng: {location['longitude']}")
            return data
        else:
            print(f"❌ Erro ao obter localizações: {response.status_code}")
            return []
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conexão: {e}")
        return []

def simulate_driving_route():
    """Simula uma rota de direção"""
    
    # Coordenadas de São Paulo (ponto de partida)
    start_lat = -23.5505
    start_lng = -46.6333
    
    # Simula movimento ao longo de uma rota
    print("🚗 Iniciando simulação de viagem...")
    
    # Ponto de partida
    send_location_data(start_lat, start_lng, 0, "stopped")
    time.sleep(2)
    
    # Começa a dirigir
    send_location_data(start_lat, start_lng, 5, "driving")
    time.sleep(2)
    
    # Simula movimento
    for i in range(5):
        # Pequena variação nas coordenadas
        lat = start_lat + (i * 0.001)
        lng = start_lng + (i * 0.001)
        speed = random.randint(30, 60)
        
        send_location_data(lat, lng, speed, "driving")
        time.sleep(3)
    
    # Para o veículo
    final_lat = start_lat + 0.005
    final_lng = start_lng + 0.005
    send_location_data(final_lat, final_lng, 0, "stopped")
    
    print("🏁 Simulação de viagem concluída!")

def test_flutter_format():
    """Testa formato de dados do Flutter"""
    
    print("📱 Testando formato de dados do Flutter...")
    
    # Dados no formato que o Flutter envia
    flutter_data = {
        "latitude": -23.5505,
        "longitude": -46.6333,
        "accuracy": 10.5,
        "altitude": 750.0,
        "speed": 0.0,
        "heading": 180.0,
        "timestamp": datetime.now().isoformat(),
        "device_id": "flutter_device_123456789",
        "app_version": "1.0.0"
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/location/",
            headers=headers,
            json=flutter_data
        )
        
        if response.status_code == 201:
            print("✅ Dados do Flutter enviados com sucesso!")
            return True
        else:
            print(f"❌ Erro ao enviar dados do Flutter: {response.status_code}")
            print(f"Resposta: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conexão: {e}")
        return False

def main():
    """Função principal"""
    
    print("🚀 Teste da API de Localização em Tempo Real")
    print("🔓 SEM AUTENTICAÇÃO - Token removido")
    print("=" * 50)
    
    # Testa conexão básica
    print("1. Testando conexão com a API...")
    if not test_api_connection():
        print("❌ Não foi possível conectar à API. Verifique:")
        print("   - Se o servidor Django está rodando")
        print("   - Se a URL da API está correta")
        print("   - Se o endpoint /api/location/ existe")
        return
    
    # Testa formato do Flutter
    print("\n2. Testando formato de dados do Flutter...")
    test_flutter_format()
    
    # Lista localizações existentes
    print("\n3. Verificando localizações existentes...")
    get_locations()
    
    # Simula uma viagem
    print("\n4. Simulando uma viagem...")
    simulate_driving_route()
    
    # Verifica localizações finais
    print("\n5. Verificando localizações finais...")
    get_locations()
    
    print("\n✅ Teste concluído!")
    print("💡 A API agora funciona sem necessidade de token!")

if __name__ == "__main__":
    main()