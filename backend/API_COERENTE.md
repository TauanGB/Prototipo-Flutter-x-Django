# API Reestruturada com Lógica Coerente

## Visão Geral

A API foi completamente reestruturada para ter **coerência e consistência** nas operações, implementando regras de negócio que garantem a integridade dos dados e o fluxo correto das operações.

## 🔧 **Principais Mudanças Implementadas**

### 1. **Regras de Negócio Coerentes**

#### ❌ **ANTES (Inconsistente):**
- API criava motoristas automaticamente
- Não verificava viagens ativas
- Não mantinha posição atual durante viagem
- Operações sem validação de contexto

#### ✅ **AGORA (Coerente):**
- **Motorista deve existir previamente** - não cria automaticamente
- **Verifica viagens ativas** antes de permitir novas
- **Atualiza posição atual** durante viagem ativa
- **Mantém histórico** de todas as posições
- **Validação de contexto** em todas as operações

### 2. **Novos Campos no Modelo DriverTrip**

```python
# Campos adicionados para rastreamento em tempo real
current_latitude = models.DecimalField(...)  # Posição atual durante viagem
current_longitude = models.DecimalField(...) # Posição atual durante viagem
```

### 3. **Lógica Coerente das Operações**

#### **POST /api/v1/drivers/send_location/**
- ✅ **Verifica se motorista existe** (não cria automaticamente)
- ✅ **Atualiza posição atual** se há viagem ativa
- ✅ **Mantém histórico** de todas as localizações
- ❌ **Retorna 404** se motorista não existe

#### **POST /api/v1/drivers/start_trip/**
- ✅ **Verifica se motorista existe** (não cria automaticamente)
- ✅ **Verifica se não há viagem ativa** (evita duplicatas)
- ✅ **Define posição atual** inicial
- ❌ **Retorna 404** se motorista não existe
- ❌ **Retorna 400** se já há viagem ativa

#### **POST /api/v1/drivers/end_trip/**
- ✅ **Verifica se há viagem ativa** para finalizar
- ✅ **Atualiza posição final** da viagem
- ✅ **Calcula duração** automaticamente
- ❌ **Retorna 404** se não há viagem ativa

## 📋 **Regras de Negócio Implementadas**

### **Regra 1: Motorista Deve Existir**
```python
# ANTES: Criava automaticamente
driver, created = Driver.objects.get_or_create(...)

# AGORA: Busca e valida existência
try:
    driver = Driver.objects.get(cpf=cpf, is_active=True)
except Driver.DoesNotExist:
    return Response({'error': 'Motorista não encontrado'}, status=404)
```

### **Regra 2: Uma Viagem Ativa por Motorista**
```python
# Verifica se já há viagem ativa
active_trip = DriverTrip.objects.filter(
    driver=driver, 
    status='started'
).first()

if active_trip:
    return Response({'error': 'Motorista já possui uma viagem ativa'}, status=400)
```

### **Regra 3: Atualização de Posição Durante Viagem**
```python
# Se há viagem ativa, atualiza posição atual
if active_trip:
    active_trip.current_latitude = location.latitude
    active_trip.current_longitude = location.longitude
    active_trip.save()
```

### **Regra 4: Transações Atômicas**
```python
# Todas as operações críticas usam transações
with transaction.atomic():
    # Operações que devem ser consistentes
    location = DriverLocation.objects.create(...)
    if active_trip:
        active_trip.current_latitude = location.latitude
        active_trip.save()
```

## 🧪 **Cenários de Teste Implementados**

### **Cenário 1: Operações sem Motorista Cadastrado**
- ❌ Enviar localização → **404 Motorista não encontrado**
- ❌ Iniciar viagem → **404 Motorista não encontrado**

### **Cenário 2: Operações com Motorista Cadastrado**
- ✅ Enviar localização → **201 Localização criada**
- ✅ Iniciar viagem → **201 Viagem iniciada**
- ❌ Iniciar viagem duplicada → **400 Viagem já ativa**
- ✅ Enviar localização durante viagem → **201 + Atualiza posição atual**
- ✅ Finalizar viagem → **200 Viagem finalizada**
- ❌ Finalizar viagem sem ativa → **404 Nenhuma viagem ativa**

## 📊 **Fluxo de Dados Coerente**

```
1. Motorista deve estar cadastrado previamente
   ↓
2. Enviar localização → Salva no histórico
   ↓
3. Iniciar viagem → Define posição inicial + posição atual
   ↓
4. Enviar localizações → Atualiza posição atual da viagem
   ↓
5. Finalizar viagem → Define posição final + calcula duração
```

## 🔍 **Validações Implementadas**

### **Validação de Existência**
- Motorista deve existir e estar ativo
- Viagem ativa deve existir para finalizar

### **Validação de Estado**
- Não pode iniciar viagem se já há uma ativa
- Não pode finalizar viagem se não há ativa

### **Validação de Contexto**
- Localizações durante viagem atualizam posição atual
- Histórico é sempre mantido

## 📁 **Arquivos Modificados**

1. **`backend/apps/core/models.py`** - Adicionados campos `current_latitude` e `current_longitude`
2. **`backend/apps/api/views.py`** - Lógica completamente reestruturada
3. **`backend/apps/api/serializers.py`** - Serializers atualizados
4. **`backend/test_coherent_api.py`** - Script de teste para validar coerência

## 🚀 **Como Usar a API Coerente**

### **1. Cadastrar Motoristas (Futuro)**
```bash
# Futuramente será implementado endpoint para cadastrar motoristas
POST /api/v1/drivers/register/
```

### **2. Usar Dados de Teste**
```bash
# Criar dados de teste
python add_test_drivers.py

# Testar API coerente
python test_coherent_api.py
```

### **3. Operações Válidas**
```bash
# 1. Verificar se motorista existe
GET /api/v1/drivers/check_driver/?cpf=12345678901

# 2. Enviar localização (motorista deve existir)
POST /api/v1/drivers/send_location/
{
    "cpf": "12345678901",
    "latitude": -23.5505,
    "longitude": -46.6333
}

# 3. Iniciar viagem (sem viagem ativa)
POST /api/v1/drivers/start_trip/
{
    "cpf": "12345678901",
    "start_latitude": -23.5505,
    "start_longitude": -46.6333
}

# 4. Enviar localizações durante viagem
POST /api/v1/drivers/send_location/
{
    "cpf": "12345678901",
    "latitude": -23.5515,
    "longitude": -46.6343
}

# 5. Finalizar viagem
POST /api/v1/drivers/end_trip/
{
    "cpf": "12345678901",
    "end_latitude": -23.5525,
    "end_longitude": -46.6353,
    "distance_km": 5.2
}
```

## ✅ **Benefícios da Reestruturação**

1. **Consistência**: Operações seguem regras de negócio claras
2. **Integridade**: Dados sempre em estado válido
3. **Rastreabilidade**: Histórico completo de localizações
4. **Prevenção de Erros**: Validações impedem operações inválidas
5. **Manutenibilidade**: Código mais organizado e previsível

## 🎯 **Próximos Passos**

1. **Implementar cadastro de motoristas** (quando necessário)
2. **Adicionar mais validações** conforme necessário
3. **Implementar relatórios** baseados no histórico
4. **Adicionar notificações** para eventos importantes

A API agora tem **lógica coerente** e **regras de negócio bem definidas**, garantindo que todas as operações sejam consistentes e previsíveis.
