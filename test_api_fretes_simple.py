#!/usr/bin/env python3
"""
Script de teste simplificado para verificar a API de fretes ativos
Usa apenas bibliotecas padrão do Python
"""

import urllib.request
import urllib.parse
import json
import sys

def test_api_response(url, description):
    """Testa uma URL da API e exibe a resposta"""
    print(f"\n{'='*60}")
    print(f"TESTANDO: {description}")
    print(f"URL: {url}")
    print(f"{'='*60}")
    
    try:
        # Criar requisição
        req = urllib.request.Request(url)
        req.add_header('User-Agent', 'Python-API-Test/1.0')
        
        # Fazer requisição
        with urllib.request.urlopen(req, timeout=10) as response:
            status_code = response.getcode()
            data = response.read().decode('utf-8')
            
            print(f"Status Code: {status_code}")
            
            if status_code == 200:
                try:
                    json_data = json.loads(data)
                    print(f"Resposta recebida com sucesso!")
                    
                    # Exibir estrutura da resposta
                    if isinstance(json_data, dict):
                        print(f"Tipo: Dict com {len(json_data)} chaves")
                        print(f"Chaves: {list(json_data.keys())}")
                        
                        if 'fretes_ativos' in json_data:
                            fretes = json_data['fretes_ativos']
                            print(f"Fretes encontrados: {len(fretes)}")
                            
                            if fretes:
                                print(f"Exemplo do primeiro frete:")
                                primeiro_frete = fretes[0]
                                for key, value in primeiro_frete.items():
                                    print(f"   {key}: {value} ({type(value).__name__})")
                            else:
                                print("Nenhum frete ativo encontrado")
                        else:
                            print("Chave 'fretes_ativos' não encontrada na resposta")
                    else:
                        print(f"Tipo: {type(json_data).__name__}")
                        print(f"Conteúdo: {json_data}")
                        
                except json.JSONDecodeError as e:
                    print(f"Erro ao decodificar JSON: {e}")
                    print(f"Resposta bruta: {data[:500]}...")
            else:
                print(f"Erro HTTP {status_code}")
                print(f"Resposta: {data}")
                
    except urllib.error.HTTPError as e:
        print(f"Erro HTTP {e.code}: {e.reason}")
        try:
            error_data = e.read().decode('utf-8')
            print(f"Erro: {error_data}")
        except:
            pass
    except urllib.error.URLError as e:
        print(f"Erro de URL: {e.reason}")
    except Exception as e:
        print(f"Erro inesperado: {e}")

def main():
    print("INICIANDO TESTES DA API DE FRETES ATIVOS")
    print("=" * 60)
    
    # CPF de teste (substitua por um CPF válido do sistema)
    cpf_teste = "094.492.955-90"
    
    # ID de motorista de teste (substitua por um ID válido do sistema)
    motorista_id_teste = 1
    
    # Teste 1: API por CPF
    url_cpf = f"https://sistemaeg3-production.up.railway.app/api/usuarios/motorista/fretes-ativos/?cpf={cpf_teste}"
    test_api_response(url_cpf, f"API por CPF (CPF: {cpf_teste})")
    
    # Teste 2: API por ID do motorista
    url_id = f"https://sistemaeg3-production.up.railway.app/api/usuarios/motorista/fretes-ativos-por-id/?motorista_id={motorista_id_teste}"
    test_api_response(url_id, f"API por ID do Motorista (ID: {motorista_id_teste})")
    
    print(f"\n{'='*60}")
    print("TESTES CONCLUIDOS")
    print("=" * 60)
    
    print("\nRESUMO DOS TESTES:")
    print("1. API por CPF testada")
    print("2. API por ID do motorista testada")
    print("\nPROXIMOS PASSOS:")
    print("- Verificar se os campos obrigatorios estao sendo retornados")
    print("- Testar com dados reais do sistema")
    print("- Verificar se o Flutter consegue fazer o parsing corretamente")

if __name__ == "__main__":
    main()