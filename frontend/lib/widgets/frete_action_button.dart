import 'package:flutter/material.dart';
import '../models/frete_eg3.dart';

/// Widget reutilizável para botão de ação do frete
/// Texto e cor mudam dinamicamente baseado no tipo de serviço e status atual
class FreteActionButton extends StatelessWidget {
  final FreteEG3 frete;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool isLoading;

  const FreteActionButton({
    super.key,
    required this.frete,
    this.onPressed,
    this.enabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final acaoBotao = frete.acaoBotaoAtual ?? 'Ação';
    final corBotao = frete.corBotaoAtual ?? 'blue';
    final isStatusFinal = frete.isStatusFinalAtual ?? false;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (enabled && !isLoading && !isStatusFinal) ? onPressed : null,
        icon: isLoading 
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isStatusFinal ? Colors.grey : _getColorFromString(corBotao),
                ),
              ),
            )
          : Icon(
              _getIconForTipoServico(frete.tipoServico),
              size: 18,
            ),
        label: Text(
          isLoading ? 'Atualizando...' : acaoBotao,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isStatusFinal 
            ? Colors.grey.shade300 
            : _getColorFromString(corBotao),
          foregroundColor: isStatusFinal 
            ? Colors.grey.shade600 
            : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: isStatusFinal ? 0 : 2,
        ),
      ),
    );
  }

  /// Converte string de cor para Color
  Color _getColorFromString(String corString) {
    switch (corString.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  /// Retorna ícone baseado no tipo de serviço
  IconData _getIconForTipoServico(String tipoServico) {
    switch (tipoServico) {
      case 'TRANSPORTE':
        return Icons.local_shipping;
      case 'MUNCK_CARGA':
        return Icons.keyboard_arrow_up;
      case 'MUNCK_DESCARGA':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.local_shipping;
    }
  }
}
