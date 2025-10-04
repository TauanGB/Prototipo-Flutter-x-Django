# 🧪 Testes da API - SEM TOKEN

## 📋 Scripts de Teste Disponíveis

### 1. **quick_test.py** - Teste Rápido
```bash
python quick_test.py
```
- ✅ Teste mais simples
- ✅ Verifica se a API está funcionando
- ✅ Envia um dado de teste
- ✅ Ideal para verificação rápida

### 2. **test_api.py** - Teste Completo
```bash
python test_api.py
```
- ✅ Teste completo da API
- ✅ Simula viagem com múltiplas localizações
- ✅ Testa formato do Flutter
- ✅ Lista localizações existentes

### 3. **test_flutter_api.py** - Teste Específico do Flutter
```bash
python test_flutter_api.py
```
- ✅ Testa endpoint exato do Flutter
- ✅ Simula múltiplas requisições
- ✅ Testa formato de dados do app
- ✅ Ideal para debug do Flutter

## 🚀 Como Executar

### 1. Iniciar o Servidor Django
```bash
cd backend
python manage.py runserver
```

### 2. Executar Testes
```bash
# Teste rápido
python quick_test.py

# Teste completo
python test_api.py

# Teste do Flutter
python test_flutter_api.py
```

## 🔧 Configurações

### URL da API
- **Base**: `http://localhost:8000`
- **Endpoint**: `/api/location/`
- **URL Completa**: `http://localhost:8000/api/location/`

### Headers (SEM AUTENTICAÇÃO)
```python
headers = {
    "Content-Type": "application/json",
    "Accept": "application/json"
}
```

### Formato dos Dados
```python
data = {
    "latitude": -23.5505,
    "longitude": -46.6333,
    "accuracy": 10.0,
    "altitude": 750.0,
    "speed": 0.0,
    "heading": 180.0,
    "timestamp": "2024-01-01T12:00:00Z",
    "device_id": "flutter_device_123"
}
```

## ✅ Resultados Esperados

### Sucesso (Status 200/201)
```
✅ SUCESSO! API funcionando sem token!
```

### Erro de Conexão
```
❌ ERRO! Servidor não está rodando
💡 Execute: python manage.py runserver
```

## 🐛 Troubleshooting

### Problema: "Connection Error"
**Solução**: Verifique se o servidor Django está rodando
```bash
python manage.py runserver
```

### Problema: "404 Not Found"
**Solução**: Verifique se o endpoint existe
```bash
python manage.py show_urls | grep location
```

### Problema: "500 Internal Server Error"
**Solução**: Verifique os logs do Django
```bash
python manage.py runserver --verbosity=2
```

## 📱 Testando com Flutter

### 1. Configurar no App Flutter
- **URL**: `http://localhost:8000`
- **Endpoint**: `/api/location/`
- **Autenticação**: Nenhuma

### 2. Executar Teste
```bash
python test_flutter_api.py
```

### 3. Verificar Dados
- Acesse: `http://localhost:8000/admin/`
- Verifique se os dados foram salvos

## 🎯 Objetivos dos Testes

1. **Verificar se a API funciona sem token**
2. **Testar formato de dados do Flutter**
3. **Simular uso real do aplicativo**
4. **Validar endpoints e respostas**
5. **Garantir compatibilidade com o app**

## 📊 Exemplo de Saída

```
🚀 Teste Rápido da API
==============================
📡 Testando: http://localhost:8000/api/location/
📦 Dados: {
  "latitude": -23.5505,
  "longitude": -46.6333,
  "accuracy": 10.0,
  "altitude": 750.0,
  "speed": 0.0,
  "heading": 180.0,
  "timestamp": "2024-01-01T12:00:00Z",
  "device_id": "test-device-123"
}

📤 Enviando dados...
Status: 201
Resposta: {"id": 1, "latitude": -23.5505, ...}
✅ SUCESSO! API funcionando sem token!
```
