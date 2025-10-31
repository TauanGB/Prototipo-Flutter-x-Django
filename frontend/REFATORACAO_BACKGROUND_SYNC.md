# Refatoração: Serviço de Background Sync

## 📋 Objetivo

Refatorar o serviço de background de sync para garantir que:
1. **Inicie automaticamente** quando houver rota ativa (mesmo sem clicar em "Iniciar viagem")
2. **Exiba notificação Android** durante a execução
3. **Pare automaticamente** quando a rota for cancelada/concluída
4. **Seja reinicializável** ao reabrir o app

## ✅ Implementações Realizadas

### 1. Notificação Android
- Adicionada dependência `flutter_local_notifications: ^17.2.2`
- Implementada notificação persistente quando o serviço está rodando
- Notificação mostra: "EG3 Driver — Sincronizando rota..."
- Notificação é exibida/removida automaticamente

### 2. Logs Detalhados
Todos os logs agora usam o prefixo `BG-SYNC:` para fácil identificação:
- `🚀 BG-SYNC: start` - Serviço iniciado
- `🔄 BG-SYNC: tick` - Sincronização executando
- `🛑 BG-SYNC: stop (razão)` - Serviço parado com razão
- `🔍 BG-SYNC: startIfNeeded` - Verificação automática

### 3. Método `startIfNeeded()`
Novo método centralizado que:
- Verifica se há rota ativa ou frete em execução
- Inicia o serviço automaticamente se necessário
- Para o serviço se não houver condições
- **É chamado no `init` da Home e no `resume` do app**

### 4. Inicialização no `main.dart`
- Notificações são inicializadas na inicialização do app
- Garante que o serviço esteja pronto para rodar

### 5. Proteção de Estado
- Serviço **não para automaticamente** se o backend não retornar rota no primeiro GET
- Só para quando:
  - Rota concluída/cancelada confirmada pelo backend OU
  - Usuário cancelou rota OU
  - Backend devolveu 401 (token inválido)
  - Backend devolveu 409 (conflito)

## 📝 Arquivos Modificados

### `lib/services/background_sync_service.dart`
**Adições:**
- `initializeNotifications()` - Inicializa notificações
- `_showSyncNotification()` - Exibe notificação Android
- `_hideSyncNotification()` - Remove notificação
- `startIfNeeded()` - Inicia serviço automaticamente conforme estado
- Logs detalhados em todos os métodos

**Comportamento:**
- Notificação é exibida quando `startBackgroundSyncLoop()` é chamado
- Notificação é removida quando `stopBackgroundSyncLoop()` é chamado
- Logs detalhados para debug

### `lib/main.dart`
**Mudanças:**
- Import de `BackgroundSyncService`
- Chamada `await BackgroundSyncService.initializeNotifications()` no `main()`

### `lib/screens/home_motorista_page.dart`
**Mudanças:**
- `_loadData()`: Agora chama `BackgroundSyncService.startIfNeeded()` ao carregar
- `didChangeAppLifecycleState()`: Chama `startIfNeeded()` quando app volta ao foreground

### `pubspec.yaml`
**Adições:**
- Dependência `flutter_local_notifications: ^17.2.2`

## 🔍 Fluxo de Execução

### Cenário 1: Abrir app com rota ativa já salva
1. App inicializa
2. `main.dart` inicializa notificações
3. `HomeMotoristaPage._loadData()` carrega o estado
4. Detecta `rotaAtiva = true`
5. Chama `BackgroundSyncService.startIfNeeded()`
6. Serviço inicia **automaticamente**
7. Notificação aparece **imediatamente**
8. Sync começa a rodar

### Cenário 2: Clicar "Iniciar viagem"
1. Usuário clica no botão
2. `_iniciarViagem()` ativa rota localmente
3. Chama `BackgroundSyncService.startBackgroundSyncLoop()`
4. Serviço inicia
5. Notificação aparece

### Cenário 3: Cancelar rota
1. Usuário confirma cancelamento
2. `_cancelarRota()` marca rota como cancelada
3. Chama `BackgroundSyncService.stopBackgroundSyncLoop(reason: 'manual')`
4. Serviço para
5. Notificação some

### Cenário 4: App voltar ao foreground
1. Android resume app
2. `didChangeAppLifecycleState()` é chamado
3. Chama `BackgroundSyncService.startIfNeeded()`
4. Serviço verifica estado e reinicia se necessário

## 🎯 Critérios de Aceite

✅ **Abrir o app com rota ativa já salva → serviço inicia sozinho → notificação Android aparece**
- Implementado em `_loadData()` chamando `startIfNeeded()`

✅ **Clicar "Iniciar viagem" → serviço inicia → notificação aparece**
- Já estava implementado, mantido

✅ **Cancelar rota → serviço para → notificação some**
- Já estava implementado, mantido

✅ **Logs mostram o sync tick**
- Todos os logs agora têm prefixo `BG-SYNC:` e são detalhados

✅ **A Home continua mostrando o banner**
- Banner não foi modificado, mantido em `_buildBackgroundSyncBanner()`

## 🔧 Configurações Android

O `AndroidManifest.xml` já possuía todas as permissões necessárias:
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_LOCATION`
- `FOREGROUND_SERVICE_DATA_SYNC`
- `POST_NOTIFICATIONS`

## 🐛 Problemas Resolvidos

1. ✅ **Serviço não iniciava ao abrir app com rota ativa**
   - Resolvido: `startIfNeeded()` chamado no `_loadData()`

2. ✅ **Notificação Android não aparecia**
   - Resolvido: Implementada notificação via `flutter_local_notifications`

3. ✅ **Banner sozinho não era suficiente**
   - Resolvido: Notificação Android permanente durante execução

4. ✅ **Difícil debugar quando serviço morria**
   - Resolvido: Logs detalhados com prefixo `BG-SYNC:`

## 📊 Logs de Debug

Para acompanhar o comportamento do serviço, procure por logs com prefixo `BG-SYNC:`:

```
🚀 BG-SYNC: start (intervalo: 30s)
🔄 BG-SYNC: tick executando...
✅ BG-SYNC: tick - bem-sucedido: 2 processados, 0 rejeitados
🛑 BG-SYNC: stop (rota_inativa)
🔍 BG-SYNC: startIfNeeded - rota ativa detectada, iniciando serviço
```

## 🚀 Próximos Passos (Opcional)

1. Testar em dispositivo físico Android
2. Adicionar métricas/analytics do tempo de sync
3. Implementar retry automático para erros de rede
4. Adicionar notificação com percentual de progresso da rota

