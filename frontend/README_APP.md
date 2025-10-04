# App Motorista - Frontend Flutter

Este é um aplicativo Flutter simples que permite enviar dados de localização de motoristas para a API do backend Django.

## Funcionalidades

- **Envio de Localização**: Envia dados de GPS do dispositivo para a API
- **Atualização de Status**: Permite alterar o status do motorista (online, offline, dirigindo, etc.)
- **Informações de Bateria**: Opcionalmente envia o nível da bateria
- **Visualização de Dados**: Mostra a última localização enviada com sucesso
- **Integração com API**: Comunica-se com o backend Django através de requisições HTTP

## Como Usar

### 1. Configuração Inicial

1. Certifique-se de que o backend Django está rodando em `http://127.0.0.1:8000`
2. Execute o aplicativo Flutter:
   ```bash
   flutter run
   ```

### 2. Permissões

Na primeira execução, o app solicitará permissões de localização:
- **Permissão de Localização**: Necessária para obter coordenadas GPS
- **Serviços de Localização**: Deve estar habilitado no dispositivo

### 3. Envio de Dados

1. **Definir Status**: Selecione o status do motorista no dropdown
2. **Nível de Bateria** (opcional): Digite o percentual da bateria
3. **Enviar Localização**: Toque no botão "Enviar Localização" para:
   - Obter coordenadas GPS atuais
   - Enviar dados para a API
   - Exibir resultado na tela

### 4. Atualização de Status

- Use o botão "Atualizar Status" para alterar apenas o status sem enviar nova localização
- Útil quando o motorista muda de status (ex: online → dirigindo)

## Endpoints da API Utilizados

- `POST /api/v1/driver-locations/send_location/` - Envia dados de localização
- `POST /api/v1/driver-locations/update_status/` - Atualiza status do motorista
- `GET /api/v1/driver-locations/current_location/` - Obtém localização atual
- `GET /api/v1/driver-locations/location_history/` - Histórico de localizações
- `GET /api/v1/driver-locations/online_drivers/` - Motoristas online

## Estrutura do Projeto

```
lib/
├── main.dart                 # Ponto de entrada do app
├── models/
│   ├── driver_location.dart  # Modelo de dados
│   └── driver_location.g.dart # Serialização JSON (gerado)
├── services/
│   ├── api_service.dart      # Comunicação com API
│   └── location_service.dart # Serviços de localização
└── screens/
    └── home_screen.dart      # Tela principal
```

## Dados Enviados

O aplicativo envia os seguintes dados para a API:

```json
{
  "latitude": -23.5505,
  "longitude": -46.6333,
  "accuracy": 10.5,
  "speed": 25.0,
  "heading": 180.0,
  "altitude": 760.0,
  "status": "online",
  "battery_level": 85,
  "is_gps_enabled": true,
  "device_id": "flutter_app_1234567890",
  "app_version": "1.0.0"
}
```

## Tratamento de Erros

- **Sem permissão de localização**: Solicita permissão automaticamente
- **GPS desabilitado**: Exibe mensagem de erro
- **Falha na API**: Mostra mensagem de erro com detalhes
- **Sem conexão**: Trata erros de rede graciosamente

## Status Disponíveis

- **online**: Motorista disponível
- **offline**: Motorista indisponível
- **driving**: Motorista dirigindo
- **stopped**: Motorista parado
- **break**: Motorista em pausa

## Observações

- O backend cria automaticamente um usuário anônimo para dados não autenticados
- As localizações são armazenadas no banco de dados SQLite do Django
- O app funciona sem necessidade de login/autenticação
- Dados são enviados em tempo real para a API

## Troubleshooting

### Erro de Conexão
- Verifique se o backend está rodando
- Confirme a URL da API em `api_service.dart`
- Teste a conectividade de rede

### Erro de Localização
- Verifique permissões de localização
- Confirme se o GPS está habilitado
- Teste em ambiente externo para melhor precisão

### Erro de Compilação
- Execute `flutter pub get` para instalar dependências
- Verifique se todas as dependências estão corretas no `pubspec.yaml`
