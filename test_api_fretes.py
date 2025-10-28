#!/usr/bin/env python3
"""
Script de teste para verificar a API de fretes ativos
Testa tanto a API por CPF quanto por ID do motorista
"""

import requests
import json
import sys

# Configuração da API
BASE_URL = "https://sistemaeg3-production.up.railway.app"
API_BASE = f"{BASE_URL}/api/usuarios/motorista"

def test_api_response(url, description):
    """Testa uma URL da API e exibe a resposta"""
    print(f"\n{'='*60}")
    print(f"🧪 TESTANDO: {description}")
    print(f"📡 URL: {url}")
    print(f"{'='*60}")
    
    try:
        response = requests.get(url, timeout=10)
        
        print(f"📊 Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Resposta recebida com sucesso!")
            
            # Exibir estrutura da resposta
            if isinstance(data, dict):
                print(f"📋 Tipo: Dict com {len(data)} chaves")
                print(f"🔑 Chaves: {list(data.keys())}")
                
                if 'fretes_ativos' in data:
                    fretes = data['fretes_ativos']
                    print(f"📦 Fretes encontrados: {len(fretes)}")
                    
                    if fretes:
                        print(f"📄 Exemplo do primeiro frete:")
                        primeiro_frete = fretes[0]
                        for key, value in primeiro_frete.items():
                            print(f"   {key}: {value} ({type(value).__name__})")
                    else:
                        print("⚠️ Nenhum frete ativo encontrado")
                else:
                    print("⚠️ Chave 'fretes_ativos' não encontrada na resposta")
            else:
                print(f"📋 Tipo: {type(data).__name__}")
                print(f"📄 Conteúdo: {data}")
                
        else:
            print(f"❌ Erro HTTP {response.status_code}")
            try:
                error_data = response.json()
                print(f"💥 Erro: {error_data}")
            except:
                print(f"💥 Erro: {response.text}")
                
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conexão: {e}")
    except json.JSONDecodeError as e:
        print(f"❌ Erro ao decodificar JSON: {e}")
    except Exception as e:
        print(f"❌ Erro inesperado: {e}")

def main():
    print("🚀 INICIANDO TESTES DA API DE FRETES ATIVOS")
    print("=" * 60)
    
    # CPF de teste (substitua por um CPF válido do sistema)
    cpf_teste = "094.492.955-90"
    
    # ID de motorista de teste (substitua por um ID válido do sistema)
    motorista_id_teste = 1
    
    # Teste 1: API por CPF
    url_cpf = f"{API_BASE}/fretes-ativos/?cpf={cpf_teste}"
    test_api_response(url_cpf, f"API por CPF (CPF: {cpf_teste})")
    
    # Teste 2: API por ID do motorista
    url_id = f"{API_BASE}/fretes-ativos-por-id/?motorista_id={motorista_id_teste}"
    test_api_response(url_id, f"API por ID do Motorista (ID: {motorista_id_teste})")
    
    print(f"\n{'='*60}")
    print("✅ TESTES CONCLUÍDOS")
    print("=" * 60)
    
    print("\n📋 RESUMO DOS TESTES:")
    print("1. ✅ API por CPF testada")
    print("2. ✅ API por ID do motorista testada")
    print("\n💡 PRÓXIMOS PASSOS:")
    print("- Verificar se os campos obrigatórios estão sendo retornados")
    print("- Testar com dados reais do sistema")
    print("- Verificar se o Flutter consegue fazer o parsing corretamente")

if __name__ == "__main__":
    main()



