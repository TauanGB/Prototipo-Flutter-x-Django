# App Motorista - Sistema de Gestão de Fretes

## 📱 Sobre o Projeto

Este é um aplicativo Flutter standalone para motoristas, desenvolvido exclusivamente para dispositivos móveis (Android e iOS). O app permite que motoristas gerenciem suas rotas de entrega, atualizem status de fretes e enviem dados de localização em tempo real.

## 🚀 Funcionalidades Principais

- **🔐 Autenticação**: Login via CPF + senha
- **🗺️ Gestão de Rotas**: Visualização e execução de rotas de entrega
- **📍 Rastreamento GPS**: Localização em tempo real com serviço em background
- **📦 Status de Fretes**: Controle sequencial de status por tipo de serviço
- **🔄 Sincronização**: Integração com backend via API REST
- **📱 Interface Mobile**: Dashboard otimizado para dispositivos móveis

## 🛠️ Tecnologias Utilizadas

- **Flutter**: Framework multiplataforma (mobile-only)
- **Dart**: Linguagem de programação
- **Geolocator**: Serviços de localização GPS
- **Background Service**: Rastreamento em background
- **HTTP**: Comunicação com API REST
- **Shared Preferences**: Armazenamento local de dados

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

### Instalação
```bash
# Clone o repositório
git clone <url-do-repositorio>
cd app-motorista

# Instale as dependências
flutter pub get
```

### Execução
```bash
# Android
flutter run -d android

# iOS
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

1. **Configurar CPF**: Configure o CPF do motorista no app
2. **Permissões**: Permita acesso à localização GPS
3. **Conexão**: Conecte-se à internet para sincronização
4. **Background**: Permita execução em background para rastreamento

## 📱 Recursos Móveis

- **GPS/Localização**: Rastreamento em tempo real
- **Background Service**: Continua funcionando com app minimizado
- **Notificações**: Alertas de status e atualizações
- **Armazenamento Local**: Cache de dados offline
- **Câmera**: Para fotos de evidência (futuro)
- **Sensores**: Acelerômetro para detecção de movimento

## 🎯 Fluxo de Uso

1. **Login** → Motorista faz login com CPF + senha
2. **Dashboard** → Visualiza fretes ativos e rotas
3. **Iniciar Viagem** → Busca rota ativa automaticamente
4. **Execução** → Atualiza status de cada frete conforme executa
5. **Rastreamento** → GPS ativo durante toda a viagem
6. **Finalização** → Completa rota e para o rastreamento

## 🔒 Segurança

- **Autenticação**: Token JWT para segurança
- **Criptografia**: Dados sensíveis criptografados
- **Permissões**: Controle granular de acesso
- **Background**: Execução segura em background

## ⚠️ Importante

Este aplicativo foi desenvolvido especificamente para dispositivos móveis Android e iOS. Não há suporte para outras plataformas como web, desktop ou outros sistemas operacionais.

## 🐛 Troubleshooting

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

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.

## 🤝 Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📞 Suporte

Para suporte, abra uma issue no repositório ou entre em contato através do email.
