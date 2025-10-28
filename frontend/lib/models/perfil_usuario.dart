import 'package:json_annotation/json_annotation.dart';

part 'perfil_usuario.g.dart';

/// Modelo de perfil de usuário do SistemaEG3
@JsonSerializable()
class PerfilUsuario {
  final int id;
  @JsonKey(name: 'tipo_usuario')
  final String tipoUsuario;
  @JsonKey(name: 'tipo_usuario_display')
  final String? tipoUsuarioDisplay;
  final String? telefone;
  final String? cpf;
  @JsonKey(name: 'data_criacao')
  final DateTime dataCriacao;
  @JsonKey(name: 'data_atualizacao')
  final DateTime dataAtualizacao;
  final bool ativo;

  const PerfilUsuario({
    required this.id,
    required this.tipoUsuario,
    this.tipoUsuarioDisplay,
    this.telefone,
    this.cpf,
    required this.dataCriacao,
    required this.dataAtualizacao,
    required this.ativo,
  });

  factory PerfilUsuario.fromJson(Map<String, dynamic> json) => _$PerfilUsuarioFromJson(json);
  Map<String, dynamic> toJson() => _$PerfilUsuarioToJson(this);

  /// Verifica se é motorista
  bool get isMotorista => tipoUsuario == 'MOTORISTA';

  /// Verifica se é gestor
  bool get isGestor => tipoUsuario == 'GESTOR';

  /// Verifica se é empresa
  bool get isEmpresa => tipoUsuario == 'EMPRESA';

  /// Verifica se é cliente
  bool get isCliente => tipoUsuario == 'CLIENTE';

  /// Verifica se é administrativo
  bool get isAdministrativo => tipoUsuario == 'ADMINISTRATIVO';

  /// CPF formatado
  String? get cpfFormatado {
    if (cpf == null || cpf!.isEmpty) return null;
    final cleanCpf = cpf!.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanCpf.length != 11) return cpf;
    
    return '${cleanCpf.substring(0, 3)}.${cleanCpf.substring(3, 6)}.${cleanCpf.substring(6, 9)}-${cleanCpf.substring(9)}';
  }

  /// Telefone formatado
  String? get telefoneFormatado {
    if (telefone == null || telefone!.isEmpty) return null;
    final cleanPhone = telefone!.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanPhone.length == 11) {
      return '(${cleanPhone.substring(0, 2)}) ${cleanPhone.substring(2, 7)}-${cleanPhone.substring(7)}';
    } else if (cleanPhone.length == 10) {
      return '(${cleanPhone.substring(0, 2)}) ${cleanPhone.substring(2, 6)}-${cleanPhone.substring(6)}';
    }
    
    return telefone;
  }

  @override
  String toString() => 'PerfilUsuario(id: $id, tipo: $tipoUsuario, cpf: $cpf)';
}
