# ⚠️ BACKEND OBSOLETO - MIGRADO PARA SISTEMAEG3

## 🚨 AVISO IMPORTANTE

**Este backend foi migrado para o SistemaEG3 e está obsoleto.**

- **✅ Nova Localização:** `../SistemaEG3/`
- **📅 Data de Migração:** 2024
- **🔄 Status:** Migração Concluída
- **📖 Documentação:** `../SistemaEG3/MIGRACAO_FLUTTER.md`

### ⚡ Para Desenvolvimento Atual:
1. Use o **SistemaEG3** como backend principal
2. Consulte a documentação de migração
3. APIs mantêm compatibilidade com o app Flutter

### 🔗 Links Úteis:
- [SistemaEG3](../SistemaEG3/)
- [Documentação de Migração](../SistemaEG3/MIGRACAO_FLUTER.md)
- [Mapeamento de APIs](../SistemaEG3/MIGRACAO_FLUTER.md#mapeamento-de-endpoints)

---

# Sistema de LocalizaÃ§Ã£o em Tempo Real para Motoristas

Este projeto implementa uma API Django para receber dados de localizaÃ§Ã£o em tempo real de motoristas atravÃ©s de seus celulares.

**⚠️ NOTA:** Este backend está obsoleto. Use o SistemaEG3 para desenvolvimento futuro.

## Funcionalidades

- âœ… Recebimento de dados de localizaÃ§Ã£o GPS em tempo real
- âœ… Rastreamento de status dos motoristas (online, dirigindo, parado, etc.)
- âœ… HistÃ³rico de localizaÃ§Ãµes
- âœ… GestÃ£o de viagens
- âœ… Monitoramento de bateria e precisÃ£o do GPS
- âœ… API RESTful com autenticaÃ§Ã£o
- âœ… ValidaÃ§Ãµes de dados geogrÃ¡ficos
- âœ… Filtros e busca avanÃ§ada

## Tecnologias Utilizadas

- **Backend**: Django 4.2.7 + Django REST Framework
- **Banco de Dados**: SQLite (desenvolvimento)
- **AutenticaÃ§Ã£o**: Token Authentication
- **ValidaÃ§Ã£o**: Serializers com validaÃ§Ãµes customizadas
- **Filtros**: django-filter

## InstalaÃ§Ã£o

### 1. Clone o repositÃ³rio
`ash
git clone <url-do-repositorio>
cd "Sistema Teste Ray/backend"
`

### 2. Crie um ambiente virtual
`ash
python -m venv venv

# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate
`

### 3. Instale as dependÃªncias
`ash
pip install -r requirements.txt
`

### 4. Configure as variÃ¡veis de ambiente
Crie um arquivo .env baseado no env.example:
`ash
cp env.example .env
`

### 5. Execute as migraÃ§Ãµes
`ash
python manage.py makemigrations
python manage.py migrate
`

### 6. Crie um superusuÃ¡rio
`ash
python manage.py createsuperuser
`

### 7. Execute o servidor
`ash
python manage.py runserver
`

## Uso da API

### AutenticaÃ§Ã£o

Primeiro, obtenha um token de autenticaÃ§Ã£o:

`ash
# Crie um token para um usuÃ¡rio
python manage.py drf_create_token <username>
`

### Endpoints Principais

#### Enviar LocalizaÃ§Ã£o
`ash
POST /api/driver-locations/send_location/
`

Exemplo de payload:
`json
{
    "latitude": -23.5505,
    "longitude": -46.6333,
    "accuracy": 10.5,
    "speed": 45.2,
    "status": "driving",
    "battery_level": 85,
    "device_id": "mobile-123",
    "app_version": "1.0.0"
}
`

#### Obter LocalizaÃ§Ã£o Atual
`ash
GET /api/driver-locations/current_location/
`

#### HistÃ³rico de LocalizaÃ§Ãµes
`ash
GET /api/driver-locations/location_history/?hours=24
`

#### Motoristas Online
`ash
GET /api/driver-locations/online_drivers/
`

## Teste da API

Execute o script de teste incluÃ­do:

`ash
# Configure o token no arquivo test_api.py
python test_api.py
`

## Estrutura do Projeto

`
backend/
â”œâ”€â”€ apps/
â”‚   â”œâ”€â”€ api/           # Views e serializers da API
â”‚   â”œâ”€â”€ core/          # Modelos principais
â”‚   â””â”€â”€ users/         # Modelo de usuÃ¡rio customizado
â”œâ”€â”€ config/            # ConfiguraÃ§Ãµes do Django
â”œâ”€â”€ logs/              # Logs da aplicaÃ§Ã£o
â”œâ”€â”€ media/             # Arquivos de mÃ­dia
â”œâ”€â”€ staticfiles/       # Arquivos estÃ¡ticos
â””â”€â”€ requirements.txt   # DependÃªncias
`

## Modelos de Dados

### DriverLocation
- Armazena localizaÃ§Ã£o GPS em tempo real
- Inclui dados como velocidade, direÃ§Ã£o, precisÃ£o
- Status do motorista (online, dirigindo, parado, etc.)
- InformaÃ§Ãµes do dispositivo e bateria

### DriverTrip
- Gerencia viagens dos motoristas
- Rastreia inÃ­cio e fim das viagens
- Calcula distÃ¢ncia e duraÃ§Ã£o

### User (Customizado)
- UsuÃ¡rio base com campos adicionais
- Integrado com sistema de localizaÃ§Ã£o

## ConfiguraÃ§Ã£o para ProduÃ§Ã£o

### 1. Banco de Dados
Para produÃ§Ã£o, configure um banco PostgreSQL:

`python
# config/settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'your_db_name',
        'USER': 'your_db_user',
        'PASSWORD': 'your_db_password',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}
`

### 2. VariÃ¡veis de Ambiente
`ash
DEBUG=False
SECRET_KEY=your-secret-key
ALLOWED_HOSTS=your-domain.com,www.your-domain.com
`

### 3. ConfiguraÃ§Ãµes de SeguranÃ§a
`python
# config/settings.py
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
`

## Monitoramento

### Logs
Os logs sÃ£o salvos em logs/django.log e incluem:
- RequisiÃ§Ãµes Ã  API
- Erros de validaÃ§Ã£o
- OperaÃ§Ãµes de banco de dados

### MÃ©tricas
- NÃºmero de localizaÃ§Ãµes por hora
- Motoristas online
- Status de bateria dos dispositivos
- PrecisÃ£o mÃ©dia do GPS

## IntegraÃ§Ã£o com Aplicativo Mobile

### Flutter/Dart
`dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendLocation() async {
  final response = await http.post(
    Uri.parse('http://your-api.com/api/driver-locations/send_location/'),
    headers: {
      'Authorization': 'Token ',
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'status': 'driving',
      'battery_level': batteryLevel,
    }),
  );
}
`

### React Native
`javascript
const sendLocation = async (locationData) => {
  const response = await fetch('/api/driver-locations/send_location/', {
    method: 'POST',
    headers: {
      'Authorization': Token ,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(locationData),
  });
  
  return response.json();
};
`

## ContribuiÃ§Ã£o

1. FaÃ§a um fork do projeto
2. Crie uma branch para sua feature
3. Commit suas mudanÃ§as
4. Push para a branch
5. Abra um Pull Request

## LicenÃ§a

Este projeto estÃ¡ sob a licenÃ§a MIT. Veja o arquivo LICENSE para mais detalhes.

## Suporte

Para suporte, abra uma issue no repositÃ³rio ou entre em contato atravÃ©s do email.
