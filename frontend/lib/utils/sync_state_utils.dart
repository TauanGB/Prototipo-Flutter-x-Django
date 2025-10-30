import '../models/driver_session.dart';
import '../models/sync_state.dart';
import '../services/storage_service.dart';
import 'dart:developer' as developer;

/// Utilitários para carregar e salvar DriverSession e SyncState
/// 
/// Facilita a integração dos modelos com StorageService
class SyncStateUtils {
  /// Carrega DriverSession do armazenamento local
  /// Retorna null se não existir ou se houver erro
  static Future<DriverSession?> loadDriverSession() async {
    try {
      final sessionJson = await StorageService.loadDriverSession();
      if (sessionJson != null) {
        final session = DriverSession.fromJson(sessionJson);
        if (session.isValid) {
          developer.log('✅ DriverSession carregada: ${session.motoristaId}', name: 'SyncStateUtils');
          return session;
        } else {
          developer.log('⚠️ DriverSession inválida', name: 'SyncStateUtils');
          return null;
        }
      }
      return null;
    } catch (e) {
      developer.log('❌ Erro ao carregar DriverSession: $e', name: 'SyncStateUtils');
      return null;
    }
  }

  /// Salva DriverSession no armazenamento local
  static Future<void> saveDriverSession(DriverSession session) async {
    try {
      await StorageService.saveDriverSession(session.toJson());
      developer.log('✅ DriverSession salva: ${session.motoristaId}', name: 'SyncStateUtils');
    } catch (e) {
      developer.log('❌ Erro ao salvar DriverSession: $e', name: 'SyncStateUtils');
    }
  }

  /// Carrega SyncState do armazenamento local
  /// Retorna null se não existir ou se houver erro
  static Future<SyncState?> loadSyncState() async {
    try {
      final syncStateJson = await StorageService.loadSyncState();
      if (syncStateJson != null) {
        final syncState = SyncState.fromJson(syncStateJson);
        developer.log('✅ SyncState carregado: motorista ${syncState.motoristaId}, rota ${syncState.rotaId}', name: 'SyncStateUtils');
        return syncState;
      }
      return null;
    } catch (e) {
      developer.log('❌ Erro ao carregar SyncState: $e', name: 'SyncStateUtils');
      return null;
    }
  }

  /// Salva SyncState no armazenamento local
  static Future<void> saveSyncState(SyncState state) async {
    try {
      await StorageService.saveSyncState(state.toJson());
      developer.log('✅ SyncState salvo: motorista ${state.motoristaId}, rota ${state.rotaId}', name: 'SyncStateUtils');
    } catch (e) {
      developer.log('❌ Erro ao salvar SyncState: $e', name: 'SyncStateUtils');
    }
  }

  /// Limpa SyncState (para logout)
  static Future<void> clearSyncState() async {
    try {
      await StorageService.clearSyncState();
      developer.log('✅ SyncState limpo', name: 'SyncStateUtils');
    } catch (e) {
      developer.log('❌ Erro ao limpar SyncState: $e', name: 'SyncStateUtils');
    }
  }

  /// Limpa DriverSession (para logout)
  static Future<void> clearDriverSession() async {
    try {
      await StorageService.clearDriverSession();
      developer.log('✅ DriverSession limpa', name: 'SyncStateUtils');
    } catch (e) {
      developer.log('❌ Erro ao limpar DriverSession: $e', name: 'SyncStateUtils');
    }
  }

  /// Limpa tudo (logout completo)
  /// Chama StorageService.clearAll() que já limpa tudo
  static Future<void> clearAll() async {
    try {
      await StorageService.clearAll();
      developer.log('✅ Todos os dados limpos', name: 'SyncStateUtils');
    } catch (e) {
      developer.log('❌ Erro ao limpar dados: $e', name: 'SyncStateUtils');
    }
  }

  /// Inicializa SyncState vazio após login
  /// Deve ser chamado imediatamente após o login bem-sucedido
  static Future<SyncState> inicializarSyncStateVazio(int motoristaId) async {
    final syncState = SyncState.empty(motoristaId: motoristaId);
    await saveSyncState(syncState);
    developer.log('✅ SyncState vazio inicializado para motorista $motoristaId', name: 'SyncStateUtils');
    return syncState;
  }
}

