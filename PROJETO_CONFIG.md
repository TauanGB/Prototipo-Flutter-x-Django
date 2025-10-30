# Configuração do Projeto - App Motorista

## 📋 Informações do Projeto

- **Nome**: App Motorista
- **Descrição**: Sistema de Gestão de Fretes para Motoristas
- **Plataformas**: Android e iOS (mobile-only)
- **Tecnologia**: Flutter + Dart

## 🔧 Configurações Atuais

### URLs da API
- **Base URL**: `https://api.motorista-app.com`
- **Web App**: `https://app.motorista-app.com`

### Estrutura do Projeto
```
app-motorista/
├── frontend/           # Código Flutter
│   ├── lib/
│   │   ├── config/     # Configurações
│   │   ├── models/     # Modelos de dados
│   │   ├── screens/    # Telas do app
│   │   ├── services/   # Serviços
│   │   ├── utils/      # Utilitários
│   │   └── widgets/    # Widgets customizados
│   ├── android/        # Configurações Android
│   ├── ios/           # Configurações iOS
│   └── assets/        # Recursos (imagens, etc.)
├── cursorrules        # Regras de desenvolvimento
└── README.md         # Documentação principal
```

## 🚀 Próximos Passos para Renomeação

Se você quiser renomear o projeto completamente:

1. **Renomear pasta raiz**:
   ```bash
   mv Prototipo-Flutter-x-Django app-motorista
   ```

2. **Atualizar pubspec.yaml**:
   - Alterar `name: app_motorista` para o novo nome
   - Atualizar `description` se necessário

3. **Atualizar configurações**:
   - Modificar URLs em `lib/config/api_endpoints.dart`
   - Atualizar URLs em `lib/config/app_config.dart`
   - Alterar URLs em `lib/screens/webview_screen.dart`

4. **Atualizar documentação**:
   - Modificar `README.md`
   - Atualizar `frontend/README.md`
   - Alterar `frontend/README_APP.md`

5. **Atualizar cursorrules**:
   - Modificar contexto do projeto
   - Atualizar URLs de referência

## 📝 Notas Importantes

- O projeto foi completamente limpo de referências ao SistemaEG3
- Backend Django obsoleto foi removido
- Todas as configurações foram atualizadas para URLs genéricas
- O projeto está pronto para ser um aplicativo Flutter standalone
- Mantida compatibilidade com funcionalidades existentes

## 🔄 Status da Reestruturação

✅ **Concluído**:
- Remoção do backend Django obsoleto
- Atualização de configurações e endpoints
- Limpeza de documentação obsoleta
- Atualização do cursorrules
- Reestruturação da documentação

✅ **Pronto para**:
- Desenvolvimento contínuo
- Deploy em produção
- Renomeação completa do projeto
- Integração com novo backend
