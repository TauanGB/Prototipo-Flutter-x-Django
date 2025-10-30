# App Motorista - Sistema de Gestão de Fretes (Mobile)

## 📱 Plataformas Suportadas

**Este aplicativo é exclusivamente para dispositivos móveis:**
- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 12.0+)
- ❌ ~~Web~~ (não suportado)
- ❌ ~~Windows~~ (não suportado)
- ❌ ~~macOS~~ (não suportado)
- ❌ ~~Linux~~ (não suportado)

## 🚀 Funcionalidades Principais

- **Gestão de Rotas**: Visualização e execução de rotas de entrega
- **Rastreamento GPS**: Localização em tempo real com serviço em background
- **Status de Fretes**: Controle de status por tipo de serviço:
  - **TRANSPORTE**: Aguardando Carga → Em Trânsito → Descarregando → Finalizado
  - **MUNCK_CARGA**: Carregamento Iniciado → Carregamento Concluído
  - **MUNCK_DESCARGA**: Descarregamento Iniciado → Descarregamento Concluído
- **Interface Simplificada**: Dashboard integrado sem telas intermediárias
- **Sincronização**: Integração com sistema backend via API REST

## 🛠️ Tecnologias Mobile

- **Flutter**: Framework multiplataforma (apenas mobile)
- **Dart**: Linguagem de programação
- **Geolocator**: Serviços de localização GPS
- **Background Service**: Rastreamento em background
- **HTTP**: Comunicação com API REST
- **Shared Preferences**: Armazenamento local de dados

## 📋 Pré-requisitos Mobile

### Android
- Android Studio
- Android SDK (API 21+)
- Dispositivo Android ou Emulador
- Permissões de localização

### iOS
- Xcode
- iOS Simulator ou dispositivo iOS
- macOS (para desenvolvimento iOS)
- Permissões de localização

## 🚀 Como Executar

### Android
```bash
flutter run --debug
# ou especificamente para Android
flutter run -d android
```

### iOS
```bash
flutter run --debug
# ou especificamente para iOS
flutter run -d ios
```

## 📦 Build para Produção Mobile

### Android APK
```bash
flutter build apk --release
```

### iOS IPA
```bash
flutter build ios --release
```

## 🔧 Configuração Mobile

1. **Configurar CPF**: Configure o CPF do motorista no app
2. **Permissões**: Permita acesso à localização GPS
3. **Conexão**: Conecte-se à internet para sincronização
4. **Background**: Permita execução em background para rastreamento

## 📱 Recursos Móveis Utilizados

- **GPS/Localização**: Rastreamento em tempo real
- **Background Service**: Continua funcionando com app minimizado
- **Notificações**: Alertas de status e atualizações
- **Armazenamento Local**: Cache de dados offline
- **Câmera**: Para fotos de evidência (futuro)
- **Sensores**: Acelerômetro para detecção de movimento

## 🎯 Fluxo de Uso Mobile

1. **Login**: Motorista faz login com CPF
2. **Dashboard**: Visualiza fretes ativos e rotas
3. **Iniciar Viagem**: Busca rota ativa automaticamente
4. **Execução**: Atualiza status de cada frete conforme executa
5. **Rastreamento**: GPS ativo durante toda a viagem
6. **Finalização**: Completa rota e para rastreamento

## 📊 Dados Enviados (Mobile)

```json
{
  "latitude": -23.5505,
  "longitude": -46.6333,
  "accuracy": 10.5,
  "speed": 25.0,
  "heading": 180.0,
  "altitude": 760.0,
  "status": "EM_TRANSITO",
  "battery_level": 85,
  "is_gps_enabled": true,
  "device_id": "android_1234567890",
  "app_version": "1.0.0",
  "platform": "android"
}
```

## 🔒 Segurança Mobile

- **Autenticação**: Token JWT para segurança
- **Criptografia**: Dados sensíveis criptografados
- **Permissões**: Controle granular de acesso
- **Background**: Execução segura em background

## ⚠️ Importante

Este aplicativo foi desenvolvido especificamente para dispositivos móveis Android e iOS. Não há suporte para outras plataformas como web, desktop ou outros sistemas operacionais.

## 🐛 Troubleshooting Mobile

### Erro de Localização
- Verifique permissões de localização
- Confirme se o GPS está habilitado
- Teste em ambiente externo para melhor precisão

### Erro de Background
- Permita execução em background
- Desative otimização de bateria para o app
- Verifique configurações de energia

### Erro de Conexão
- Verifique conectividade móvel/WiFi
- Confirme URL da API em produção
- Teste em diferentes redes