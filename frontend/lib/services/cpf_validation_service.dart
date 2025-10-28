import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/api_config.dart';

class CpfValidationResult {
  final String cpf;
  final bool isRegistered;
  final String? name;
  final String? phone;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? lastActivity;
  final String? message;
  final String? error;

  CpfValidationResult({
    required this.cpf,
    required this.isRegistered,
    this.name,
    this.phone,
    this.isActive,
    this.createdAt,
    this.lastActivity,
    this.message,
    this.error,
  });

  factory CpfValidationResult.fromJson(Map<String, dynamic> json) {
    return CpfValidationResult(
      cpf: json['cpf'] ?? '',
      isRegistered: json['is_registered'] ?? false,
      name: json['name'],
      phone: json['phone'],
      isActive: json['is_active'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      lastActivity: json['last_activity'] != null 
          ? DateTime.parse(json['last_activity']) 
          : null,
      message: json['message'],
      error: json['error'],
    );
  }

  bool get hasError => error != null;
  bool get isActiveDriver => isRegistered && (isActive ?? false);
}

class CpfValidationService {
  // Obtém a URL base dinamicamente
  static String get baseUrl => AppConfig.apiBaseUrl;
  
  // Headers padrão para as requisições
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Verifica se um CPF está cadastrado no sistema
  static Future<CpfValidationResult> checkCpf(String cpf) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/drivers/check_driver/?cpf=$cpf');
      log('GET para: $uri', name: 'CpfValidationService');
      
      final response = await http.get(
        uri,
        headers: _headers,
      );

      log('Resposta da API: ${response.statusCode} - ${response.body}', name: 'CpfValidationService');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CpfValidationResult.fromJson(data);
      } else if (response.statusCode == 404) {
        // CPF não encontrado - resposta válida
        final data = json.decode(response.body);
        return CpfValidationResult.fromJson(data);
      } else {
        // Erro do servidor
        final data = json.decode(response.body);
        return CpfValidationResult(
          cpf: cpf,
          isRegistered: false,
          error: data['error'] ?? 'Erro ao verificar CPF',
        );
      }
    } catch (e, stackTrace) {
      log('Erro na requisição de validação de CPF', name: 'CpfValidationService', error: e, stackTrace: stackTrace);
      return CpfValidationResult(
        cpf: cpf,
        isRegistered: false,
        error: 'Erro de conexão: $e',
      );
    }
  }

  /// Valida CPF localmente e verifica se está cadastrado
  static Future<CpfValidationResult> validateAndCheckCpf(String cpf) async {
    // Primeiro valida localmente
    final cleanCpf = cpf.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanCpf.length != 11) {
      return CpfValidationResult(
        cpf: cpf,
        isRegistered: false,
        error: 'CPF deve ter 11 dígitos',
      );
    }

    // Verifica se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cleanCpf)) {
      return CpfValidationResult(
        cpf: cpf,
        isRegistered: false,
        error: 'CPF inválido',
      );
    }

    // Calcula os dígitos verificadores
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cleanCpf[i]) * (10 - i);
    }
    int remainder = sum % 11;
    int digit1 = remainder < 2 ? 0 : 11 - remainder;
    
    if (int.parse(cleanCpf[9]) != digit1) {
      return CpfValidationResult(
        cpf: cpf,
        isRegistered: false,
        error: 'CPF inválido',
      );
    }
    
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cleanCpf[i]) * (11 - i);
    }
    remainder = sum % 11;
    int digit2 = remainder < 2 ? 0 : 11 - remainder;
    
    if (int.parse(cleanCpf[10]) != digit2) {
      return CpfValidationResult(
        cpf: cpf,
        isRegistered: false,
        error: 'CPF inválido',
      );
    }

    // Se chegou até aqui, o CPF é válido localmente
    // Agora verifica se está cadastrado no sistema
    return await checkCpf(cleanCpf);
  }
}
