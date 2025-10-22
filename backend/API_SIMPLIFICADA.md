# API Simplificada - Documentação

## Visão Geral

A API foi reconfigurada para trabalhar de forma simples, focando apenas nas funcionalidades essenciais solicitadas. A API agora trabalha com CPF como identificador principal dos motoristas.

## Modelos Simplificados

### Driver (Motorista)
- `cpf`: CPF do motorista (único)
- `name`: Nome completo do motorista
- `phone`: Telefone (opcional)
- `is_active`: Status ativo/inativo

### DriverLocation (Localização)
- `driver`: Referência ao motorista
- `latitude`: Latitude da localização
- `longitude`: Longitude da localização
- `accuracy`: Precisão em metros (opcional)
- `speed`: Velocidade em km/h (opcional)
- `battery_level`: Nível da bateria em % (opcional)
- `timestamp`: Timestamp do GPS

### DriverTrip (Viagem)
- `driver`: Referência ao motorista
- `start_latitude`: Latitude de início
- `start_longitude`: Longitude de início
- `end_latitude`: Latitude de fim
- `end_longitude`: Longitude de fim
- `status`: Status da viagem (started, completed, cancelled)
- `distance_km`: Distância em km (opcional)
- `duration_minutes`: Duração em minutos (opcional)
- `started_at`: Data/hora de início
- `completed_at`: Data/hora de fim

## Endpoints da API

### 1. POST /api/v1/drivers/send_location/
**Enviar localização com CPF do motorista**

**Payload:**
```json
{
    "cpf": "12345678901",
    "latitude": -23.5505,
    "longitude": -46.6333,
    "accuracy": 10.5,
    "speed": 25.0,
    "battery_level": 85
}
```

**Resposta (201):**
```json
{
    "id": 1,
    "driver": 1,
    "driver_name": "Motorista 12345678901",
    "driver_cpf": "12345678901",
    "latitude": "-23.5505000",
    "longitude": "-46.6333000",
    "accuracy": 10.5,
    "speed": 25.0,
    "battery_level": 85,
    "timestamp": "2025-01-10T15:30:00Z",
    "created_at": "2025-01-10T15:30:00Z",
    "updated_at": "2025-01-10T15:30:00Z"
}
```

### 2. POST /api/v1/drivers/start_trip/
**Sinal de início de viagem de motorista**

**Payload:**
```json
{
    "cpf": "12345678901",
    "start_latitude": -23.5505,
    "start_longitude": -46.6333
}
```

**Resposta (201):**
```json
{
    "id": 1,
    "driver": 1,
    "driver_name": "Motorista 12345678901",
    "driver_cpf": "12345678901",
    "start_latitude": "-23.5505000",
    "start_longitude": "-46.6333000",
    "end_latitude": null,
    "end_longitude": null,
    "status": "started",
    "distance_km": null,
    "duration_minutes": null,
    "started_at": "2025-01-10T15:30:00Z",
    "completed_at": null,
    "created_at": "2025-01-10T15:30:00Z",
    "updated_at": "2025-01-10T15:30:00Z"
}
```

### 3. POST /api/v1/drivers/end_trip/
**Sinal de fim de viagem de motorista**

**Payload:**
```json
{
    "cpf": "12345678901",
    "end_latitude": -23.5515,
    "end_longitude": -46.6343,
    "distance_km": 5.2
}
```

**Resposta (200):**
```json
{
    "id": 1,
    "driver": 1,
    "driver_name": "Motorista 12345678901",
    "driver_cpf": "12345678901",
    "start_latitude": "-23.5505000",
    "start_longitude": "-46.6333000",
    "end_latitude": "-23.5515000",
    "end_longitude": "-46.6343000",
    "status": "completed",
    "distance_km": 5.2,
    "duration_minutes": 15,
    "started_at": "2025-01-10T15:30:00Z",
    "completed_at": "2025-01-10T15:45:00Z",
    "created_at": "2025-01-10T15:30:00Z",
    "updated_at": "2025-01-10T15:45:00Z"
}
```

### 4. GET /api/v1/drivers/get_driver_data/?cpf=12345678901
**Puxar dados de um CPF específico**

**Resposta (200):**
```json
{
    "id": 1,
    "cpf": "12345678901",
    "name": "Motorista 12345678901",
    "phone": null,
    "is_active": true,
    "locations": [
        {
            "id": 1,
            "driver": 1,
            "driver_name": "Motorista 12345678901",
            "driver_cpf": "12345678901",
            "latitude": "-23.5505000",
            "longitude": "-46.6333000",
            "accuracy": 10.5,
            "speed": 25.0,
            "battery_level": 85,
            "timestamp": "2025-01-10T15:30:00Z",
            "created_at": "2025-01-10T15:30:00Z",
            "updated_at": "2025-01-10T15:30:00Z"
        }
    ],
    "trips": [
        {
            "id": 1,
            "driver": 1,
            "driver_name": "Motorista 12345678901",
            "driver_cpf": "12345678901",
            "start_latitude": "-23.5505000",
            "start_longitude": "-46.6333000",
            "end_latitude": "-23.5515000",
            "end_longitude": "-46.6343000",
            "status": "completed",
            "distance_km": 5.2,
            "duration_minutes": 15,
            "started_at": "2025-01-10T15:30:00Z",
            "completed_at": "2025-01-10T15:45:00Z",
            "created_at": "2025-01-10T15:30:00Z",
            "updated_at": "2025-01-10T15:45:00Z"
        }
    ],
    "created_at": "2025-01-10T15:30:00Z",
    "updated_at": "2025-01-10T15:30:00Z"
}
```

### 5. GET /api/v1/drivers/check_driver/?cpf=12345678901
**Verificar se um CPF específico está cadastrado**

**Resposta (200) - CPF Cadastrado:**
```json
{
    "cpf": "12345678901",
    "name": "Motorista 12345678901",
    "phone": null,
    "is_active": true,
    "is_registered": true,
    "created_at": "2025-01-10T15:30:00Z",
    "last_activity": "2025-01-10T15:30:00Z"
}
```

**Resposta (200) - CPF Não Cadastrado:**
```json
{
    "cpf": "99999999999",
    "is_registered": false,
    "message": "CPF não encontrado no sistema"
}
```

## Endpoints Adicionais

### GET /api/v1/driver-locations/?cpf=12345678901
**Buscar localizações de um motorista específico**

### GET /api/v1/driver-trips/?cpf=12345678901
**Buscar viagens de um motorista específico**

### GET /api/v1/drivers/
**Listar todos os motoristas**

### GET /api/v1/driver-locations/
**Listar todas as localizações**

### GET /api/v1/driver-trips/
**Listar todas as viagens**

## Como Usar

1. **Iniciar o servidor:**
   ```bash
   cd backend
   python manage.py runserver
   ```

2. **Testar a API:**
   ```bash
   python test_simple_api.py
   ```

## Características da API Simplificada

- ✅ **Simples**: Apenas 4 endpoints principais
- ✅ **Baseada em CPF**: Identificação única por CPF
- ✅ **Sem autenticação**: Permite acesso direto
- ✅ **Extensível**: Preparada para receber mais requisições
- ✅ **Dados completos**: Retorna informações detalhadas
- ✅ **Validação**: Valida coordenadas e dados de entrada

## Próximos Passos

A API está preparada para receber mais requisições conforme a necessidade. Basta adicionar novos endpoints no `DriverViewSet` ou criar novos ViewSets conforme necessário.

## Estrutura de Arquivos

```
backend/
├── apps/
│   ├── core/
│   │   └── models.py          # Modelos simplificados
│   └── api/
│       ├── views.py           # Views simplificadas
│       ├── serializers.py     # Serializers simplificados
│       └── urls.py           # URLs da API
├── test_simple_api.py         # Script de teste
└── API_SIMPLIFICADA.md       # Esta documentação
```
