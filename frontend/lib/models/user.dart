import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// Modelo de usuário do SistemaEG3
@JsonSerializable()
class User {
  final int id;
  final String username;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  final String? email;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'date_joined')
  final DateTime dateJoined;
  @JsonKey(name: 'perfil', fromJson: _perfilFromJson, toJson: _perfilToJson)
  final Map<String, dynamic>? perfil;

  const User({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.email,
    required this.isActive,
    required this.dateJoined,
    this.perfil,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// Converte perfil de JSON para Map
  static Map<String, dynamic>? _perfilFromJson(dynamic json) {
    if (json == null) return null;
    if (json is Map<String, dynamic>) return json;
    return null;
  }

  /// Converte perfil de Map para JSON
  static dynamic _perfilToJson(Map<String, dynamic>? perfil) {
    return perfil;
  }

  /// Nome completo do usuário
  String get fullName {
    final first = firstName ?? '';
    final last = lastName ?? '';
    return '$first $last'.trim();
  }

  /// Nome de exibição (nome completo ou username)
  String get displayName => fullName.isNotEmpty ? fullName : username;

  @override
  String toString() => 'User(id: $id, username: $username, name: $displayName)';
}
