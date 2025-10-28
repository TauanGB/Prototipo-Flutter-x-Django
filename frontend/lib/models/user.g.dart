// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  username: json['username'] as String,
  firstName: json['first_name'] as String?,
  lastName: json['last_name'] as String?,
  email: json['email'] as String?,
  isActive: json['is_active'] as bool,
  dateJoined: DateTime.parse(json['date_joined'] as String),
  perfil: User._perfilFromJson(json['perfil']),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'email': instance.email,
  'is_active': instance.isActive,
  'date_joined': instance.dateJoined.toIso8601String(),
  'perfil': User._perfilToJson(instance.perfil),
};
