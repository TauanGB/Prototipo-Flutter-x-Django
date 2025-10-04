# Configuração da API - App Motorista

Este documento explica como usar a nova funcionalidade de configuração de parâmetros da API no aplicativo Flutter.

## Visão Geral

O aplicativo agora permite configurar dinamicamente os parâmetros de conexão com a API do backend Django, incluindo:
- **Protocolo**: HTTP ou HTTPS
- **Host/Endereço IP**: Endereço do servidor
- **Porta**: Porta do servidor
- **Caminho Base**: Caminho base da API

## Como Acessar a Configuração

1. Abra o aplicativo Flutter
2. Na tela principal (HomeScreen), clique no ícone de configurações (⚙️) na barra superior
3. A tela de configuração será aberta

## Parâmetros Configuráveis

### Protocolo
- **HTTP**: Para desenvolvimento local
- **HTTPS**: Para produção (requer certificado SSL)

### Host/Endereço IP
- **Para Android (emulador)**: `10.0.2.2` (mapeia para localhost do host)
- **Para Desktop/Web**: `127.0.0.1` ou `localhost`
- **Para dispositivos físicos**: IP real da máquina que roda o backend

### Porta
- **Padrão Django**: `8000`
- **Outras portas**: Qualquer porta entre 1 e 65535

### Caminho Base da API
- **Padrão**: `/api/v1`
- **Personalizado**: Qualquer caminho que comece com `/`

## Funcionalidades da Tela de Configuração

### 1. Visualização da Configuração Atual
- Mostra todos os parâmetros atuais
- Exibe a URL completa construída

### 2. Edição de Parâmetros
- Campos de texto para cada parâmetro
- Validação em tempo real
- Dropdown para seleção do protocolo

### 3. Teste de Conexão
- Botão "Testar Conexão" para verificar se os parâmetros estão corretos
- Feedback visual do resultado do teste

### 4. Reset para Padrão
- Botão "Resetar" para voltar às configurações padrão
- Configuração padrão baseada na plataforma (Android vs Desktop)

### 5. Salvar Configuração
- Botão "Salvar Configuração" para persistir as alterações
- As configurações são salvas no dispositivo usando SharedPreferences

## Configurações Padrão

### Android (Emulador)
```
Protocolo: http
Host: 10.0.2.2
Porta: 8000
Caminho Base: /api/v1
URL Completa: http://10.0.2.2:8000/api/v1
```

### Desktop/Web
```
Protocolo: http
Host: 127.0.0.1
Porta: 8000
Caminho Base: /api/v1
URL Completa: http://127.0.0.1:8000/api/v1
```

## Como Usar

1. **Configurar pela primeira vez**:
   - Acesse a tela de configuração
   - Ajuste os parâmetros conforme seu ambiente
   - Teste a conexão
   - Salve a configuração

2. **Alterar configuração existente**:
   - Acesse a tela de configuração
   - Modifique os parâmetros necessários
   - Teste a nova configuração
   - Salve as alterações

3. **Resetar para padrão**:
   - Na tela de configuração, clique em "Resetar"
   - Confirme a ação
   - As configurações voltarão aos valores padrão da plataforma

## Persistência

- As configurações são salvas automaticamente no dispositivo
- Não é necessário reconfigurar a cada vez que o app é aberto
- As configurações persistem mesmo após reinicialização do dispositivo

## Validação

O sistema inclui validação para:
- **Host**: Não pode estar vazio
- **Porta**: Deve ser um número entre 1 e 65535
- **Protocolo**: Deve ser HTTP ou HTTPS
- **Caminho Base**: Deve começar com `/`

## Troubleshooting

### Problemas Comuns

1. **"Falha na conexão"**:
   - Verifique se o backend Django está rodando
   - Confirme se a porta está correta
   - Para Android emulador, use `10.0.2.2` como host

2. **"Erro ao salvar configuração"**:
   - Verifique se todos os campos estão preenchidos corretamente
   - Certifique-se de que a porta é um número válido

3. **Configuração não persiste**:
   - Reinicie o aplicativo
   - Verifique se há espaço suficiente no dispositivo

### Logs de Debug

O aplicativo exibe mensagens de erro detalhadas no console para ajudar no debugging:
- Erros de conexão
- Problemas de validação
- Falhas ao salvar configurações

## Arquivos Relacionados

- `lib/models/api_config.dart`: Modelo de dados para configuração
- `lib/services/config_service.dart`: Serviço para gerenciar configurações
- `lib/screens/config_screen.dart`: Tela de configuração
- `lib/config/app_config.dart`: Configurações globais do app
- `lib/services/api_service.dart`: Serviço da API (atualizado para usar configurações dinâmicas)

## Dependências Adicionadas

- `shared_preferences: ^2.2.2`: Para persistir configurações no dispositivo



