import 'package:flutter/services.dart';

class CpfValidator {
  /// Remove formatação do CPF (pontos, hífens, espaços)
  static String cleanCpf(String cpf) {
    return cpf.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// Formata CPF com pontos e hífen
  static String formatCpf(String cpf) {
    final clean = cleanCpf(cpf);
    if (clean.length != 11) return cpf;
    
    return '${clean.substring(0, 3)}.${clean.substring(3, 6)}.${clean.substring(6, 9)}-${clean.substring(9, 11)}';
  }

  /// Valida se o CPF é válido
  static bool isValidCpf(String cpf) {
    final clean = cleanCpf(cpf);
    
    // Verifica se tem 11 dígitos
    if (clean.length != 11) return false;
    
    // Verifica se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1{10}$').hasMatch(clean)) return false;
    
    // Calcula os dígitos verificadores
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(clean[i]) * (10 - i);
    }
    int remainder = sum % 11;
    int digit1 = remainder < 2 ? 0 : 11 - remainder;
    
    if (int.parse(clean[9]) != digit1) return false;
    
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(clean[i]) * (11 - i);
    }
    remainder = sum % 11;
    int digit2 = remainder < 2 ? 0 : 11 - remainder;
    
    return int.parse(clean[10]) == digit2;
  }

  /// Valida e formata CPF (apenas validação local)
  static String? validateAndFormat(String cpf) {
    final clean = cleanCpf(cpf);
    if (clean.isEmpty) return 'CPF é obrigatório';
    
    if (!isValidCpf(clean)) {
      return 'CPF inválido';
    }
    
    return null; // CPF válido localmente
  }
}

/// Formatter para CPF que adiciona pontos e hífen automaticamente
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final clean = CpfValidator.cleanCpf(text);
    
    if (clean.length > 11) {
      return oldValue; // Não permite mais de 11 dígitos
    }
    
    String formatted = clean;
    if (clean.length > 3) {
      formatted = '${clean.substring(0, 3)}.${clean.substring(3)}';
    }
    if (clean.length > 6) {
      formatted = '${clean.substring(0, 3)}.${clean.substring(3, 6)}.${clean.substring(6)}';
    }
    if (clean.length > 9) {
      formatted = '${clean.substring(0, 3)}.${clean.substring(3, 6)}.${clean.substring(6, 9)}-${clean.substring(9)}';
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
