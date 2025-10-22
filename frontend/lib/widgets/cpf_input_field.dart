import 'package:flutter/material.dart';
import '../utils/cpf_validator.dart';
import '../services/cpf_validation_service.dart';

class CpfInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(CpfValidationResult)? onValidationComplete;
  final bool enabled;

  const CpfInputField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
    this.onValidationComplete,
    this.enabled = true,
  });

  @override
  State<CpfInputField> createState() => _CpfInputFieldState();
}

class _CpfInputFieldState extends State<CpfInputField> {
  bool _isValidating = false;
  CpfValidationResult? _lastValidation;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: 'CPF do Motorista',
            hintText: '000.000.000-00',
            prefixIcon: const Icon(Icons.person),
            border: const OutlineInputBorder(),
            suffixIcon: _buildSuffixIcon(),
            errorText: _errorMessage,
          ),
          inputFormatters: [CpfInputFormatter()],
          keyboardType: TextInputType.number,
          onChanged: (value) {
            widget.onChanged?.call(value);
            
            // Limpa validação anterior quando CPF muda
            if (_lastValidation?.cpf != value) {
              setState(() {
                _lastValidation = null;
                _errorMessage = null;
              });
            }
            
            // Valida automaticamente quando CPF estiver completo
            if (value.length == 14) { // CPF formatado tem 14 caracteres
              _validateCpf(value);
            }
          },
          validator: widget.validator ?? _defaultValidator,
        ),
        
        // Status da validação
        if (_isValidating)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Verificando CPF...'),
              ],
            ),
          ),
          
        if (_lastValidation != null && !_isValidating) ...[
          const SizedBox(height: 8),
          _buildValidationStatus(),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (_isValidating) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    
    if (_lastValidation != null) {
      if (_lastValidation!.isRegistered) {
        return const Icon(Icons.check_circle, color: Colors.green);
      } else {
        return const Icon(Icons.error, color: Colors.red);
      }
    }
    
    return null;
  }

  Widget _buildValidationStatus() {
    if (_lastValidation!.hasError) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade600, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _lastValidation!.error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }
    
    if (_lastValidation!.isRegistered) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'CPF cadastrado',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (_lastValidation!.name != null) ...[
              const SizedBox(height: 4),
              Text(
                'Motorista: ${_lastValidation!.name}',
                style: TextStyle(color: Colors.green.shade600, fontSize: 11),
              ),
            ],
            if (_lastValidation!.lastActivity != null) ...[
              Text(
                'Última atividade: ${_formatDate(_lastValidation!.lastActivity!)}',
                style: TextStyle(color: Colors.green.shade600, fontSize: 11),
              ),
            ],
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange.shade600, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _lastValidation!.message ?? 'CPF não cadastrado no sistema',
              style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _validateCpf(String cpf) async {
    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final result = await CpfValidationService.validateAndCheckCpf(cpf);
      
      setState(() {
        _lastValidation = result;
        _isValidating = false;
        
        if (result.hasError) {
          _errorMessage = result.error;
        } else if (!result.isRegistered) {
          _errorMessage = 'CPF não cadastrado no sistema';
        }
      });
      
      widget.onValidationComplete?.call(result);
    } catch (e) {
      setState(() {
        _isValidating = false;
        _errorMessage = 'Erro ao verificar CPF';
      });
    }
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'CPF é obrigatório';
    }
    
    // Se há validação do backend, usa ela
    if (_lastValidation != null) {
      if (_lastValidation!.hasError) {
        return _lastValidation!.error;
      }
      if (!_lastValidation!.isRegistered) {
        return 'CPF não cadastrado no sistema';
      }
    }
    
    // Fallback para validação local
    return CpfValidator.validateAndFormat(value);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
