import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

/// Serviço de armazenamento local atualizado para SistemaEG3
/// Gerencia tokens de autenticação, dados do usuário e configurações de API
class StorageService {
  // === CHAVES DE ARMAZENAMENTO ===
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserData = 'user_data';
  static const String _keyPerfilData = 'perfil_data';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyDriverId = 'driver_id';
  static const String _keyCpf = 'driver_cpf';
  static const String _keyLastLogin = 'last_login';
  
  // Novas chaves para DriverSession e SyncState
  static const String _keyDriverSession = 'driver_session';
  static const String _keySyncState = 'sync_state';
  
  // === TOKEN DE AUTENTICAÇÃO ===
  /// Salva token de autenticação
  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAuthToken, token);
    developer.log('🔑 Token salvo com sucesso', name: 'StorageService');
  }
  
  /// Obtém token de autenticação
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyAuthToken);
    developer.log('🔑 Token obtido: ${token != null ? "✅ Existe" : "❌ Não existe"}', name: 'StorageService');
    return token;
  }
  
  /// Limpa token de autenticação
  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAuthToken);
    developer.log('🔑 Token removido', name: 'StorageService');
  }
  
  // === DADOS DO USUÁRIO ===
  /// Salva dados completos do usuário e perfil
  static Future<void> saveUserData(dynamic user, dynamic perfil) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Converter objetos para JSON se necessário
    final userJson = user is Map ? user : user.toJson();
    final perfilJson = perfil is Map ? perfil : perfil.toJson();
    
    await prefs.setString(_keyUserData, json.encode(userJson));
    await prefs.setString(_keyPerfilData, json.encode(perfilJson));
    
    // Marca como logado
    await prefs.setBool(_keyIsLoggedIn, true);
    
    // Salva o ID do motorista
    await prefs.setInt(_keyDriverId, userJson['id'] ?? 0);
    
    developer.log('👤 Dados do usuário salvos: ${userJson['username']}', name: 'StorageService');
  }
  
  /// Obtém dados completos do usuário e perfil
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_keyUserData);
    final perfilData = prefs.getString(_keyPerfilData);
    
    if (userData != null && perfilData != null) {
      try {
        final user = json.decode(userData);
        final perfil = json.decode(perfilData);
        
        developer.log('👤 Dados do usuário obtidos: ${user['username']}', name: 'StorageService');
        
        return {
          'user': user,
          'perfil': perfil,
        };
      } catch (e) {
        developer.log('❌ Erro ao decodificar dados do usuário: $e', name: 'StorageService');
        return null;
      }
    }
    
    developer.log('❌ Dados do usuário não encontrados', name: 'StorageService');
    return null;
  }
  
  /// Limpa dados do usuário
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserData);
    await prefs.remove(_keyPerfilData);
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyDriverId);
    developer.log('👤 Dados do usuário removidos', name: 'StorageService');
  }
  
  // === CPF DO MOTORISTA ===
  /// Salva CPF do motorista
  static Future<void> saveCpf(String cpf) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCpf, cpf);
    developer.log('📋 CPF salvo: $cpf', name: 'StorageService');
  }
  
  /// Obtém CPF salvo
  static Future<String?> getCpf() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCpf);
  }
  
  // === ÚLTIMO LOGIN ===
  /// Salva data/hora do último login
  static Future<void> saveLastLogin(DateTime dateTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastLogin, dateTime.toIso8601String());
    developer.log('🕐 Último login salvo: ${dateTime.toIso8601String()}', name: 'StorageService');
  }
  
  /// Obtém data/hora do último login
  static Future<DateTime?> getLastLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLoginStr = prefs.getString(_keyLastLogin);
    if (lastLoginStr != null) {
      try {
        return DateTime.parse(lastLoginStr);
      } catch (e) {
        developer.log('❌ Erro ao parsear último login: $e', name: 'StorageService');
        return null;
      }
    }
    return null;
  }
  
  // === UTILIDADES ===
  /// Verifica se usuário está logado
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    final hasToken = await getAuthToken() != null;
    
    // Considera logado apenas se tem token E está marcado como logado
    final result = isLoggedIn && hasToken;
    developer.log('🔐 Status de login: ${result ? "✅ Logado" : "❌ Não logado"}', name: 'StorageService');
    return result;
  }
  
  /// Obtém ID do motorista
  static Future<int?> getDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDriverId);
  }
  
  /// Obtém nome completo do motorista
  static Future<String?> getDriverName() async {
    final userData = await getUserData();
    if (userData != null) {
      final user = userData['user'];
      final firstName = user['first_name'] ?? '';
      final lastName = user['last_name'] ?? '';
      return '$firstName $lastName'.trim();
    }
    return null;
  }
  
  /// Obtém email do motorista
  static Future<String?> getDriverEmail() async {
    final userData = await getUserData();
    if (userData != null) {
      return userData['user']['email'];
    }
    return null;
  }
  
  /// Obtém CPF do motorista
  static Future<String?> getDriverCpf() async {
    final userData = await getUserData();
    if (userData != null) {
      return userData['perfil']['cpf'];
    }
    return null;
  }
  
  /// Obtém tipo de usuário
  static Future<String?> getUserType() async {
    final userData = await getUserData();
    if (userData != null) {
      return userData['perfil']['tipo_usuario'];
    }
    return null;
  }
  
  /// Obtém informações de debug
  static Future<Map<String, dynamic>> getDebugInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'hasToken': await getAuthToken() != null,
      'hasUserData': prefs.containsKey(_keyUserData),
      'hasPerfilData': prefs.containsKey(_keyPerfilData),
      'isLoggedIn': await isLoggedIn(),
      'driverId': await getDriverId(),
      'userType': await getUserType(),
      'cpf': await getCpf(),
      'lastLogin': (await getLastLogin())?.toIso8601String(),
    };
  }

  // === MÉTODOS GENÉRICOS ===
  /// Salva uma string genérica
  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  /// Obtém uma string genérica
  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// Salva um inteiro genérico
  static Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  /// Obtém um inteiro genérico
  static Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  /// Remove uma chave genérica
  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  // === DRIVER SESSION ===
  /// Salva a sessão do motorista (DriverSession)
  /// Usa SharedPreferences para persistência
  static Future<void> saveDriverSession(Map<String, dynamic> sessionData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDriverSession, json.encode(sessionData));
    developer.log('💾 DriverSession salva com sucesso', name: 'StorageService');
  }

  /// Carrega a sessão do motorista (DriverSession)
  /// Retorna null se não existir
  static Future<Map<String, dynamic>?> loadDriverSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_keyDriverSession);
    
    if (sessionJson != null) {
      try {
        final session = json.decode(sessionJson) as Map<String, dynamic>;
        developer.log('✅ DriverSession carregada', name: 'StorageService');
        return session;
      } catch (e) {
        developer.log('❌ Erro ao decodificar DriverSession: $e', name: 'StorageService');
        return null;
      }
    }
    
    developer.log('ℹ️ DriverSession não encontrada', name: 'StorageService');
    return null;
  }

  /// Limpa a sessão do motorista
  static Future<void> clearDriverSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDriverSession);
    developer.log('🧹 DriverSession removida', name: 'StorageService');
  }

  // === SYNC STATE ===
  /// Salva o SyncState (estado operacional offline)
  /// Usa SharedPreferences para persistência
  static Future<void> saveSyncState(Map<String, dynamic> syncStateData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySyncState, json.encode(syncStateData));
    developer.log('💾 SyncState salvo com sucesso', name: 'StorageService');
  }

  /// Carrega o SyncState
  /// Retorna null se não existir
  static Future<Map<String, dynamic>?> loadSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    final syncStateJson = prefs.getString(_keySyncState);
    
    if (syncStateJson != null) {
      try {
        final syncState = json.decode(syncStateJson) as Map<String, dynamic>;
        developer.log('✅ SyncState carregado', name: 'StorageService');
        return syncState;
      } catch (e) {
        developer.log('❌ Erro ao decodificar SyncState: $e', name: 'StorageService');
        return null;
      }
    }
    
    developer.log('ℹ️ SyncState não encontrado', name: 'StorageService');
    return null;
  }

  /// Limpa o SyncState
  static Future<void> clearSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySyncState);
    developer.log('🧹 SyncState removido', name: 'StorageService');
  }

  /// Limpa todos os dados (logout completo)
  /// Agora também limpa DriverSession e SyncState
  static Future<void> clearAll() async {
    await clearAuthToken();
    await clearUserData();
    await clearDriverSession();
    await clearSyncState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCpf);
    await prefs.remove(_keyLastLogin);
    developer.log('🧹 Todos os dados removidos', name: 'StorageService');
  }
}

