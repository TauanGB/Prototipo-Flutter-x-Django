# Sistema EG3 - App para Motoristas

## 📱 Plataformas Suportadas

**Este aplicativo é exclusivamente para dispositivos móveis:**
- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 12.0+)
- ❌ ~~Web~~ (não suportado)
- ❌ ~~Windows~~ (não suportado)
- ❌ ~~macOS~~ (não suportado)
- ❌ ~~Linux~~ (não suportado)

## 🚀 Funcionalidades

- **Gestão de Rotas**: Visualização e execução de rotas de entrega
- **Rastreamento GPS**: Localização em tempo real com serviço em background
- **Status de Fretes**: Controle de status por tipo de serviço (TRANSPORTE, MUNCK_CARGA, MUNCK_DESCARGA)
- **Interface Simplificada**: Dashboard integrado sem telas intermediárias
- **Sincronização**: Integração com sistema backend Django

## 🛠️ Tecnologias

- **Flutter**: Framework multiplataforma (apenas mobile)
- **Dart**: Linguagem de programação
- **Geolocator**: Serviços de localização
- **Background Service**: Rastreamento em background
- **HTTP**: Comunicação com API REST

## 📋 Pré-requisitos

### Android
- Android Studio
- Android SDK (API 21+)
- Dispositivo Android ou Emulador

### iOS
- Xcode
- iOS Simulator ou dispositivo iOS
- macOS (para desenvolvimento iOS)

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

## 📦 Build para Produção

### Android APK
```bash
flutter build apk --release
```

### iOS IPA
```bash
flutter build ios --release
```

## 🔧 Configuração

1. Configure o CPF do motorista no app
2. Permita acesso à localização
3. Conecte-se à internet para sincronização

## 📱 Recursos Móveis Utilizados

- **GPS/Localização**: Rastreamento em tempo real
- **Background Service**: Continua funcionando com app minimizado
- **Notificações**: Alertas de status e atualizações
- **Armazenamento Local**: Cache de dados offline

## ⚠️ Importante

Este aplicativo foi desenvolvido especificamente para dispositivos móveis Android e iOS. Não há suporte para outras plataformas como web, desktop ou outros sistemas operacionais.