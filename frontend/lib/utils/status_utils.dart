/// Utilitários para trabalhar com status de fretes
/// Baseado na máquina de estados documentada no README_API_ENDPOINTS.md
class StatusUtils {
  /// Obtém o próximo status válido para um tipo de serviço e status atual
  /// 
  /// Sequências válidas conforme README_API_ENDPOINTS.md:
  /// 
  /// TRANSPORTE:
  /// NAO_INICIADO → AGUARDANDO_CARGA → EM_TRANSITO → EM_DESCARGA_CLIENTE → FINALIZADO
  /// 
  /// MUNCK_CARGA:
  /// CARREGAMENTO_NAO_INICIADO → CARREGAMENTO_INICIADO → CARREGAMENTO_CONCLUIDO
  /// 
  /// MUNCK_DESCARGA:
  /// DESCARREGAMENTO_NAO_INICIADO → DESCARREGAMENTO_INICIADO → DESCARREGAMENTO_CONCLUIDO
  /// 
  /// Retorna null se não houver próximo status (já está finalizado) ou se status inválido
  static String? getProximoStatus(String tipoServico, String statusAtual) {
    // Definir sequências por tipo de serviço
    final sequencias = {
      'TRANSPORTE': [
        'NAO_INICIADO',
        'AGUARDANDO_CARGA',
        'EM_TRANSITO',
        'EM_DESCARGA_CLIENTE',
        'FINALIZADO'
      ],
      'MUNCK_CARGA': [
        'CARREGAMENTO_NAO_INICIADO',
        'CARREGAMENTO_INICIADO',
        'CARREGAMENTO_CONCLUIDO'
      ],
      'MUNCK_DESCARGA': [
        'DESCARREGAMENTO_NAO_INICIADO',
        'DESCARREGAMENTO_INICIADO',
        'DESCARREGAMENTO_CONCLUIDO'
      ],
    };

    final sequencia = sequencias[tipoServico];
    if (sequencia == null) {
      return null;
    }

    final indiceAtual = sequencia.indexOf(statusAtual);
    if (indiceAtual == -1) {
      return null; // Status atual não está na sequência
    }

    if (indiceAtual >= sequencia.length - 1) {
      return null; // Já está no status final
    }

    return sequencia[indiceAtual + 1];
  }

  /// Verifica se um status é status final para um tipo de serviço
  static bool isStatusFinal(String tipoServico, String status) {
    switch (tipoServico) {
      case 'TRANSPORTE':
        return status == 'FINALIZADO';
      case 'MUNCK_CARGA':
        return status == 'CARREGAMENTO_CONCLUIDO';
      case 'MUNCK_DESCARGA':
        return status == 'DESCARREGAMENTO_CONCLUIDO';
      default:
        return false;
    }
  }

  /// Converte status para texto legível
  static String statusParaTexto(String status) {
    final mapa = {
      'NAO_INICIADO': 'Não Iniciado',
      'AGUARDANDO_CARGA': 'Aguardando Carga',
      'EM_TRANSITO': 'Em Trânsito',
      'EM_DESCARGA_CLIENTE': 'Em Descarregamento no Cliente',
      'FINALIZADO': 'Finalizado',
      'CANCELADO': 'Cancelado',
      'CARREGAMENTO_NAO_INICIADO': 'Carregamento Não Iniciado',
      'CARREGAMENTO_INICIADO': 'Carregamento Iniciado',
      'CARREGAMENTO_CONCLUIDO': 'Carregamento Concluído',
      'DESCARREGAMENTO_NAO_INICIADO': 'Descarregamento Não Iniciado',
      'DESCARREGAMENTO_INICIADO': 'Descarregamento Iniciado',
      'DESCARREGAMENTO_CONCLUIDO': 'Descarregamento Concluído',
    };
    return mapa[status] ?? status;
  }

  /// Converte tipo de serviço para texto legível
  static String tipoServicoParaTexto(String tipoServico) {
    switch (tipoServico) {
      case 'TRANSPORTE':
        return 'Transporte de Materiais';
      case 'MUNCK_CARGA':
        return 'Serviço Munck - Carregamento';
      case 'MUNCK_DESCARGA':
        return 'Serviço Munck - Descarregamento';
      default:
        return tipoServico;
    }
  }

  /// Obtém o label amigável (humanizado) para o próximo status de um frete
  /// 
  /// Retorna um texto descritivo e amigável baseado no tipo de serviço e
  /// status atual, indicando qual será a ação do próximo passo lógico.
  /// 
  /// Exemplos:
  /// - TRANSPORTE, NAO_INICIADO → "Iniciar viagem"
  /// - TRANSPORTE, AGUARDANDO_CARGA → "Sinalizar que está aguardando carga"
  /// - TRANSPORTE, EM_TRANSITO → "Sinalizar que está em trânsito"
  /// - MUNCK_CARGA, CARREGAMENTO_NAO_INICIADO → "Indicar início de carregamento"
  /// 
  /// Retorna null se não houver próximo status ou se os parâmetros forem inválidos.
  static String? getLabelParaProximoStatus(String tipoServico, String statusAtual) {
    final proximoStatus = getProximoStatus(tipoServico, statusAtual);
    
    if (proximoStatus == null) {
      return null;
    }

    // Mapeamento de labels amigáveis por tipo de serviço e próximo status
    switch (tipoServico) {
      case 'TRANSPORTE':
        // Caso especial: primeiro status (NAO_INICIADO → AGUARDANDO_CARGA) = "Iniciar viagem"
        if (statusAtual == 'NAO_INICIADO' && proximoStatus == 'AGUARDANDO_CARGA') {
          return 'Iniciar viagem';
        }
        switch (proximoStatus) {
          case 'AGUARDANDO_CARGA':
            return 'Sinalizar que está aguardando carga';
          case 'EM_TRANSITO':
            return 'Sinalizar que está em trânsito';
          case 'EM_DESCARGA_CLIENTE':
            return 'Sinalizar descarga no cliente';
          case 'FINALIZADO':
            return 'Finalizar frete';
          default:
            // Fallback para status não mapeado
            return 'Avançar para ${statusParaTexto(proximoStatus)}';
        }

      case 'MUNCK_CARGA':
        switch (proximoStatus) {
          case 'CARREGAMENTO_INICIADO':
            return 'Indicar início de carregamento';
          case 'CARREGAMENTO_CONCLUIDO':
            return 'Confirmar carregamento concluído';
          default:
            return 'Avançar para ${statusParaTexto(proximoStatus)}';
        }

      case 'MUNCK_DESCARGA':
        switch (proximoStatus) {
          case 'DESCARREGAMENTO_INICIADO':
            return 'Indicar início de descarregamento';
          case 'DESCARREGAMENTO_CONCLUIDO':
            return 'Confirmar descarregamento concluído';
          default:
            return 'Avançar para ${statusParaTexto(proximoStatus)}';
        }

      default:
        // Fallback genérico
        return 'Avançar para ${statusParaTexto(proximoStatus)}';
    }
  }

  /// Obtém o label amigável para o status atual (para uso em diálogos de confirmação)
  /// 
  /// Retorna um texto descritivo do próximo status que será aplicado,
  /// formatado para ser usado em diálogos como:
  /// "Confirmar: marcar este frete como '<LABEL>'?"
  static String? getLabelConfirmacaoProximoStatus(String tipoServico, String statusAtual) {
    final proximoStatus = getProximoStatus(tipoServico, statusAtual);
    
    if (proximoStatus == null) {
      return null;
    }

    // Para diálogos de confirmação, usamos textos mais concisos
    switch (tipoServico) {
      case 'TRANSPORTE':
        switch (proximoStatus) {
          case 'AGUARDANDO_CARGA':
            return 'aguardando carga';
          case 'EM_TRANSITO':
            return 'em trânsito';
          case 'EM_DESCARGA_CLIENTE':
            return 'em descarga no cliente';
          case 'FINALIZADO':
            return 'finalizado';
          default:
            return statusParaTexto(proximoStatus).toLowerCase();
        }

      case 'MUNCK_CARGA':
        switch (proximoStatus) {
          case 'CARREGAMENTO_INICIADO':
            return 'com carregamento iniciado';
          case 'CARREGAMENTO_CONCLUIDO':
            return 'com carregamento concluído';
          default:
            return statusParaTexto(proximoStatus).toLowerCase();
        }

      case 'MUNCK_DESCARGA':
        switch (proximoStatus) {
          case 'DESCARREGAMENTO_INICIADO':
            return 'com descarregamento iniciado';
          case 'DESCARREGAMENTO_CONCLUIDO':
            return 'com descarregamento concluído';
          default:
            return statusParaTexto(proximoStatus).toLowerCase();
        }

      default:
        return statusParaTexto(proximoStatus).toLowerCase();
    }
  }
}

