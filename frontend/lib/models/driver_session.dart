/// Modelo de sessão do motorista após login
/// Baseado no formato especificado em README_API_ENDPOINTS.md
/// 
/// Obtido através de POST /api/usuarios/publico/login-cpf/
/// e armazenado localmente para uso em requisições autenticadas
class DriverSession {
  final String token;
  final int motoristaId;
  final String nomeMotorista;
  final String cpf;
  final String tipoUsuario;
  final String? telefone;

  const DriverSession({
    required this.token,
    required this.motoristaId,
    required this.nomeMotorista,
    required this.cpf,
    required this.tipoUsuario,
    this.telefone,
  });

  /// Cria DriverSession a partir da resposta do endpoint de login
  /// 
  /// Response do backend:
  /// {
  ///   "success": true,
  ///   "token": "abc123...",
  ///   "user": {
  ///     "id": 1,
  ///     "first_name": "João",
  ///     "last_name": "Silva",
  ///     "username": "motorista_user"
  ///   },
  ///   "perfil": {
  ///     "cpf": "12345678901",
  ///     "tipo_usuario": "MOTORISTA",
  ///     "telefone": "(11) 99999-9999"
  ///   }
  /// }
  factory DriverSession.fromLoginResponse(Map<String, dynamic> response) {
    final user = response['user'] as Map<String, dynamic>;
    final perfil = response['perfil'] as Map<String, dynamic>;
    final token = response['token'] as String;

    // Montar nome do motorista: first_name + last_name (ou username se vazio)
    final firstName = user['first_name'] as String? ?? '';
    final lastName = user['last_name'] as String? ?? '';
    String nomeMotorista;
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      nomeMotorista = '$firstName $lastName'.trim();
    } else {
      nomeMotorista = user['username'] as String? ?? 'Motorista';
    }

    return DriverSession(
      token: token,
      motoristaId: user['id'] as int,
      nomeMotorista: nomeMotorista,
      cpf: perfil['cpf'] as String? ?? '',
      tipoUsuario: perfil['tipo_usuario'] as String? ?? 'MOTORISTA',
      telefone: perfil['telefone'] as String?,
    );
  }

  /// Cria DriverSession a partir de JSON armazenado localmente
  factory DriverSession.fromJson(Map<String, dynamic> json) {
    return DriverSession(
      token: json['token'] as String,
      motoristaId: json['motorista_id'] as int,
      nomeMotorista: json['nome_motorista'] as String,
      cpf: json['cpf'] as String,
      tipoUsuario: json['tipo_usuario'] as String,
      telefone: json['telefone'] as String?,
    );
  }

  /// Converte DriverSession para JSON (para armazenamento local)
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'motorista_id': motoristaId,
      'nome_motorista': nomeMotorista,
      'cpf': cpf,
      'tipo_usuario': tipoUsuario,
      if (telefone != null) 'telefone': telefone,
    };
  }

  /// Valida se a sessão é válida
  bool get isValid {
    return token.isNotEmpty && 
           motoristaId > 0 && 
           nomeMotorista.isNotEmpty && 
           cpf.isNotEmpty && 
           tipoUsuario == 'MOTORISTA';
  }

  @override
  String toString() {
    return 'DriverSession(motoristaId: $motoristaId, nome: $nomeMotorista, cpf: $cpf)';
  }
}

