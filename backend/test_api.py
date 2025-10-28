#!/usr/bin/env python
"""
Script para testar a API de login
"""
import requests
import json

def test_login_api():
    """Testa a API de login"""
    # Testa tanto localhost quanto 10.0.2.2
    urls = [
        "http://127.0.0.1:8000/api/v1/auth/login/",
        "http://10.0.2.2:8000/api/v1/auth/login/",
    ]
    
    for url in urls:
        print(f"\n=== Testando URL: {url} ===")
        test_single_url(url)

def test_single_url(url):
    data = {
        "username": "motorista_teste",
        "password": "123456"
    }
    
    headers = {
        "Content-Type": "application/json"
    }
    
    try:
        print(f"Testando URL: {url}")
        print(f"Data: {json.dumps(data, indent=2)}")
        print(f"Headers: {headers}")
        print("-" * 50)
        
        response = requests.post(url, json=data, headers=headers)
        
        print(f"Status Code: {response.status_code}")
        print(f"Headers: {dict(response.headers)}")
        print(f"Content-Type: {response.headers.get('content-type', 'N/A')}")
        print("-" * 50)
        
        if response.headers.get('content-type', '').startswith('application/json'):
            try:
                json_data = response.json()
                print("Resposta JSON:")
                print(json.dumps(json_data, indent=2, ensure_ascii=False))
                print("SUCESSO - API funcionando!")
            except json.JSONDecodeError as e:
                print(f"Erro ao decodificar JSON: {e}")
                print("Resposta bruta:")
                print(response.text)
        else:
            print("ERRO - Resposta não é JSON:")
            print(response.text)
            
    except requests.exceptions.ConnectionError:
        print("ERRO - Não foi possível conectar ao servidor")
        print("Verifique se o servidor Django está rodando")
    except Exception as e:
        print(f"ERRO: {e}")

if __name__ == '__main__':
    test_login_api()