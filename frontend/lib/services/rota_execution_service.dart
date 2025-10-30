import 'dart:convert';
import '../config/api_endpoints.dart';
import '../models/rota.dart';
import '../models/frete_eg3.dart';
import '../models/frete_rota.dart';
import 'api_client.dart';
import 'storage_service.dart';
import 'background_location_service.dart';
import 'frete_service.dart';
import 'dart:developer' as developer;

/// Serviço para gerenciar execução de rotas
/// Controla o fluxo de trabalho dos fretes dentro de uma rota
class RotaExecutionService {
  static const String _rotaAtivaKey = 'rota_ativa';
  static const String _freteAtualKey = 'frete_atual_id';
  
  /// Obtém endpoints configurados
  static Future<ApiEndpoints> _getEndpoints() async {
    return ApiEndpoints();
  }
  
  /// Busca rota ativa automaticamente (sem interação do usuário)
  static Future<Rota?> buscarRotaAtivaAutomatica() async {
    try {
      final rotas = await getRotasAtivas();
      if (rotas.isNotEmpty) {
        return rotas.first; // Retorna a primeira rota ativa
      }
      return null;
    } catch (e) {
      developer.log('❌ Erro ao buscar rota ativa: $e', name: 'RotaExecutionService');
      return null;
    }
  }

  /// Inicia viagem com rota automaticamente
  static Future<bool> iniciarViagemComRota() async {
    try {
      final rota = await buscarRotaAtivaAutomatica();
      if (rota == null) {
        developer.log('ℹ️ Nenhuma rota ativa encontrada', name: 'RotaExecutionService');
        return false;
      }

      // Salvar rota ativa
      await salvarRotaAtiva(rota);
      
      // Iniciar rastreamento automaticamente
      await iniciarRastreamentoParaRota(rota);
      
      developer.log('✅ Viagem iniciada automaticamente com rota: ${rota.nome}', name: 'RotaExecutionService');
      return true;
    } catch (e) {
      developer.log('❌ Erro ao iniciar viagem: $e', name: 'RotaExecutionService');
      return false;
    }
  }

  /// Atualiza status de um frete individual
  static Future<bool> atualizarStatusFrete(int freteId) async {
    try {
      final rotaAtiva = await getRotaAtiva();
      if (rotaAtiva == null) {
        developer.log('❌ Nenhuma rota ativa encontrada', name: 'RotaExecutionService');
        return false;
      }

      // Encontrar o frete na rota
      final freteRota = rotaAtiva.fretesRota?.firstWhere(
        (fr) => fr.frete == freteId,
        orElse: () => throw Exception('Frete não encontrado na rota'),
      );

      if (freteRota == null) {
        throw Exception('Frete não encontrado na rota');
      }

      // Obter dados do frete (pode estar em freteData ou precisar buscar)
      final frete = freteRota.freteData;
      if (frete == null) {
        throw Exception('Dados do frete não disponíveis');
      }
      
      developer.log('🔍 Frete atual: ID=${frete.id}, Tipo=${frete.tipoServico}, Status=${frete.statusAtual}', name: 'RotaExecutionService');
      
      final proximoStatus = FreteEG3.getProximoStatus(frete.tipoServico, frete.statusAtual);
      developer.log('🔄 Próximo status calculado: $proximoStatus', name: 'RotaExecutionService');
      
      if (proximoStatus == null) {
        developer.log('❌ Não há próximo status válido para ${frete.tipoServico}/${frete.statusAtual}', name: 'RotaExecutionService');
        return false;
      }

      // Atualizar status
      final sucesso = await avancarFreteStatus(freteId, frete.tipoServico, frete.statusAtual);
      
      if (sucesso) {
        developer.log('✅ Status do frete $freteId atualizado: ${frete.statusAtual} → $proximoStatus', name: 'RotaExecutionService');
      }
      
      return sucesso;
    } catch (e) {
      developer.log('❌ Erro ao atualizar status do frete: $e', name: 'RotaExecutionService');
      return false;
    }
  }

  /// Busca rotas ativas do motorista
  static Future<List<Rota>> getRotasAtivas() async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('🛣️ Buscando rotas ativas...', name: 'RotaExecutionService');
      
      // Obter CPF do motorista logado
      final cpf = await StorageService.getCpf();
      if (cpf == null || cpf.isEmpty) {
        throw Exception('CPF do motorista não encontrado. Faça login novamente.');
      }
      
      // Tentar primeiro o endpoint de rotas ativas
      try {
        final url = '${endpoints.drivers}/get_active_rotas/?cpf=$cpf';
        final response = await ApiClient.get(url);
        
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          
          List<dynamic> jsonList;
          if (responseData is List) {
            jsonList = responseData;
          } else if (responseData is Map && responseData.containsKey('rotas_ativas')) {
            jsonList = responseData['rotas_ativas'];
          } else {
            throw Exception('Formato de resposta inválido');
          }
          
          final rotas = jsonList.map((json) => Rota.fromJson(json)).toList();
          
          developer.log('✅ ${rotas.length} rotas ativas encontradas', name: 'RotaExecutionService');
          return rotas;
        } else {
          developer.log('❌ Erro ao buscar rotas: ${response.statusCode}', name: 'RotaExecutionService');
        }
      } catch (e) {
        developer.log('⚠️ Endpoint de rotas não disponível, usando fallback: $e', name: 'RotaExecutionService');
      }
      
      // Fallback: usar fretes ativos e criar rota virtual
      final response = await ApiClient.get('${endpoints.rastreioActiveFretes}?cpf=$cpf');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fretes = (data['fretes_ativos'] as List)
            .map((freteData) => FreteEG3.fromJson(freteData))
            .toList();
        
        // Criar rota virtual com os fretes ativos
        if (fretes.isNotEmpty) {
          // Log dos status dos fretes para debug
          for (final frete in fretes) {
            developer.log('📦 Frete ${frete.id}: Status=${frete.statusAtual}, Tipo=${frete.tipoServico}', name: 'RotaExecutionService');
          }
          
          final rotaVirtual = Rota(
            id: 999, // ID virtual
            nome: 'Rota Virtual - Fretes Ativos',
            motorista: fretes.first.motoristaId ?? 0,
            status: 'EM_ANDAMENTO',
            dataCriacao: DateTime.now(),
            ativo: true,
            totalFretes: fretes.length,
            fretesConcluidos: 0,
            progressoPercentual: 0.0,
            fretesRota: fretes.map((frete) {
              // Determinar status da rota baseado no status atual do frete
              String statusRota;
              if (frete.statusAtual == 'FINALIZADO') {
                statusRota = 'CONCLUIDO';
              } else if (frete.statusAtual == 'NAO_INICIADO') {
                statusRota = 'PENDENTE';
              } else {
                statusRota = 'EM_EXECUCAO';
              }
              
              developer.log('📦 Frete ${frete.id}: StatusFrete=${frete.statusAtual} → StatusRota=$statusRota', name: 'RotaExecutionService');
              
              // Mapear status da rota para display
              String statusRotaDisplay;
              switch (statusRota) {
                case 'PENDENTE':
                  statusRotaDisplay = 'Pendente';
                  break;
                case 'EM_EXECUCAO':
                  statusRotaDisplay = 'Em Execução';
                  break;
                case 'CONCLUIDO':
                  statusRotaDisplay = 'Concluído';
                  break;
                default:
                  statusRotaDisplay = statusRota;
              }
              
              return FreteRota(
                id: frete.id,
                rota: 999, // ID virtual da rota (usar 999 como definido na linha 166)
                frete: frete.id,
                freteData: frete,
                ordem: frete.id, // Usar ID como ordem temporariamente
                statusRota: statusRota,
                statusRotaDisplay: statusRotaDisplay,
                dataCriacao: DateTime.now(),
                dataAtualizacao: DateTime.now(),
              );
            }).toList(),
          );
          
          developer.log('✅ Rota virtual criada com ${fretes.length} fretes', name: 'RotaExecutionService');
          return [rotaVirtual];
        }
      }
      
      developer.log('ℹ️ Nenhuma rota ativa encontrada', name: 'RotaExecutionService');
      return [];
    } catch (e) {
      developer.log('❌ Erro na busca de rotas: $e', name: 'RotaExecutionService');
      return [];
    }
  }
  
  /// Inicia uma rota
  static Future<bool> iniciarRota(int rotaId) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('🚀 Iniciando rota $rotaId', name: 'RotaExecutionService');
      
      // Obter CPF do motorista logado
      final cpf = await StorageService.getCpf();
      if (cpf == null || cpf.isEmpty) {
        throw Exception('CPF do motorista não encontrado. Faça login novamente.');
      }
      
      // Tentar primeiro o endpoint de iniciar rota
      try {
        final response = await ApiClient.post(
          '${endpoints.drivers}/start_rota/',
          {
            'rota_id': rotaId,
            'cpf': cpf,
          },
        );
        
        if (response.statusCode == 200) {
          developer.log('✅ Rota iniciada com sucesso', name: 'RotaExecutionService');
          
          // Busca os detalhes da rota atualizada
          final rotaDetalhes = await getRotaDetalhes(rotaId);
          await salvarRotaAtiva(rotaDetalhes);
          
          return true;
        } else {
          developer.log('❌ Erro ao iniciar rota: ${response.statusCode}', name: 'RotaExecutionService');
        }
      } catch (e) {
        developer.log('⚠️ Endpoint de iniciar rota não disponível: $e', name: 'RotaExecutionService');
      }
      
      // Fallback: apenas salvar a rota como ativa
      final rotaDetalhes = await getRotaDetalhes(rotaId);
      await salvarRotaAtiva(rotaDetalhes);
      
      return true;
    } catch (e) {
      developer.log('❌ Erro ao iniciar rota: $e', name: 'RotaExecutionService');
      return false;
    }
  }
  
  /// Obtém detalhes de uma rota específica
  static Future<Rota> getRotaDetalhes(int rotaId) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('🛣️ Buscando detalhes da rota $rotaId...', name: 'RotaExecutionService');
      
      // Tentar primeiro o endpoint de detalhes da rota
      try {
        final response = await ApiClient.get(endpoints.rotaDetail(rotaId));
        
        if (response.statusCode == 200) {
          final rota = Rota.fromJson(json.decode(response.body));
          developer.log('✅ Detalhes da rota obtidos: ${rota.nome}', name: 'RotaExecutionService');
          return rota;
        } else {
          developer.log('❌ Erro ao buscar detalhes: ${response.statusCode}', name: 'RotaExecutionService');
        }
      } catch (e) {
        developer.log('⚠️ Endpoint de detalhes não disponível: $e', name: 'RotaExecutionService');
      }
      
      // Fallback: buscar fretes ativos e criar rota virtual
      final cpf = await StorageService.getCpf();
      if (cpf == null || cpf.isEmpty) {
        throw Exception('CPF do motorista não encontrado. Faça login novamente.');
      }
      
      final response = await ApiClient.get('${endpoints.rastreioActiveFretes}?cpf=$cpf');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fretes = (data['fretes_ativos'] as List)
            .map((freteData) => FreteEG3.fromJson(freteData))
            .toList();
        
        if (fretes.isNotEmpty) {
          final rotaVirtual = Rota(
            id: rotaId,
            nome: 'Rota Virtual - Fretes Ativos',
            motorista: fretes.first.motoristaId ?? 0,
            status: 'EM_ANDAMENTO',
            dataCriacao: DateTime.now(),
            ativo: true,
            totalFretes: fretes.length,
            fretesConcluidos: 0,
            progressoPercentual: 0.0,
            fretesRota: fretes.map((frete) {
              // Determinar status da rota baseado no status atual do frete
              String statusRota;
              if (frete.statusAtual == 'FINALIZADO') {
                statusRota = 'CONCLUIDO';
              } else if (frete.statusAtual == 'NAO_INICIADO') {
                statusRota = 'PENDENTE';
              } else {
                statusRota = 'EM_EXECUCAO';
              }
              
              // Mapear status da rota para display
              String statusRotaDisplay;
              switch (statusRota) {
                case 'PENDENTE':
                  statusRotaDisplay = 'Pendente';
                  break;
                case 'EM_EXECUCAO':
                  statusRotaDisplay = 'Em Execução';
                  break;
                case 'CONCLUIDO':
                  statusRotaDisplay = 'Concluído';
                  break;
                default:
                  statusRotaDisplay = statusRota;
              }
              
              return FreteRota(
                id: frete.id,
                rota: rotaId,
                frete: frete.id,
                freteData: frete,
                ordem: frete.id,
                statusRota: statusRota,
                statusRotaDisplay: statusRotaDisplay,
                dataCriacao: DateTime.now(),
                dataAtualizacao: DateTime.now(),
              );
            }).toList(),
          );
          
          developer.log('✅ Rota virtual criada: ${rotaVirtual.nome}', name: 'RotaExecutionService');
          return rotaVirtual;
        }
      }
      
      throw Exception('Não foi possível obter detalhes da rota');
    } catch (e) {
      developer.log('❌ Erro na busca de detalhes: $e', name: 'RotaExecutionService');
      rethrow;
    }
  }
  
  /// Avança o status de um frete
  static Future<bool> avancarFreteStatus(int freteId, String tipoServico, String statusAtual) async {
    try {
      developer.log('📦 Avançando status do frete $freteId', name: 'RotaExecutionService');
      
      // Obter próximo status válido
      developer.log('🔍 Calculando próximo status: Tipo=$tipoServico, StatusAtual=$statusAtual', name: 'RotaExecutionService');
      final proximoStatus = FreteEG3.getProximoStatus(tipoServico, statusAtual);
      developer.log('✅ Próximo status calculado: $proximoStatus', name: 'RotaExecutionService');
      
      if (proximoStatus == null) {
        developer.log('❌ Não há próximo status válido para $tipoServico/$statusAtual', name: 'RotaExecutionService');
        return false;
      }
      
      // Usar FreteService que já tem fallback implementado
      final sucesso = await FreteService.atualizarStatusFrete(freteId, proximoStatus);
      
      if (sucesso) {
        developer.log('✅ Status do frete atualizado: $statusAtual → $proximoStatus', name: 'RotaExecutionService');
        
        // Atualizar frete atual no storage
        await _atualizarFreteAtual(freteId, proximoStatus);
      } else {
        developer.log('❌ Falha ao atualizar status do frete $freteId', name: 'RotaExecutionService');
      }
      
      return sucesso;
    } catch (e) {
      developer.log('❌ Erro ao avançar status: $e', name: 'RotaExecutionService');
      return false;
    }
  }
  
  /// Finaliza uma rota
  static Future<bool> finalizarRota(int rotaId) async {
    try {
      final endpoints = await _getEndpoints();
      developer.log('🏁 Finalizando rota $rotaId', name: 'RotaExecutionService');
      
      // Obter CPF do motorista logado
      final cpf = await StorageService.getCpf();
      if (cpf == null || cpf.isEmpty) {
        throw Exception('CPF do motorista não encontrado. Faça login novamente.');
      }
      
      // Tentar primeiro o endpoint de finalizar rota
      try {
        final response = await ApiClient.post(
          '${endpoints.drivers}/complete_rota/',
          {
            'rota_id': rotaId,
            'cpf': cpf,
          },
        );
        
        if (response.statusCode == 200) {
          developer.log('✅ Rota finalizada com sucesso', name: 'RotaExecutionService');
          
          // Limpar dados da rota ativa
          await limparRotaAtiva();
          
          return true;
        } else {
          developer.log('❌ Erro ao finalizar rota: ${response.statusCode}', name: 'RotaExecutionService');
        }
      } catch (e) {
        developer.log('⚠️ Endpoint de finalizar rota não disponível: $e', name: 'RotaExecutionService');
      }
      
      // Fallback: apenas limpar localmente
      await limparRotaAtiva();
      developer.log('✅ Rota finalizada localmente', name: 'RotaExecutionService');
      
      return true;
    } catch (e) {
      developer.log('❌ Erro ao finalizar rota: $e', name: 'RotaExecutionService');
      return false;
    }
  }
  
  /// Salva rota ativa no storage local
  static Future<void> salvarRotaAtiva(Rota rota) async {
    try {
      await StorageService.setString(_rotaAtivaKey, json.encode(rota.toJson()));
      
      // Define o primeiro frete como atual se não houver um definido
      final freteAtual = getFreteAtualDaRota(rota);
      if (freteAtual != null) {
        await StorageService.setInt(_freteAtualKey, freteAtual.id);
      }
      
      developer.log('💾 Rota ativa salva: ${rota.nome}', name: 'RotaExecutionService');
    } catch (e) {
      developer.log('❌ Erro ao salvar rota ativa: $e', name: 'RotaExecutionService');
    }
  }
  
  /// Busca rota ativa do storage local
  static Future<Rota?> getRotaAtiva() async {
    try {
      final rotaJson = await StorageService.getString(_rotaAtivaKey);
      if (rotaJson != null && rotaJson.isNotEmpty) {
        final rota = Rota.fromJson(json.decode(rotaJson));
        developer.log('📱 Rota ativa restaurada: ${rota.nome}', name: 'RotaExecutionService');
        return rota;
      }
      return null;
    } catch (e) {
      developer.log('❌ Erro ao restaurar rota ativa: $e', name: 'RotaExecutionService');
      return null;
    }
  }
  
  /// Limpa rota ativa do storage
  static Future<void> limparRotaAtiva() async {
    try {
      await StorageService.remove(_rotaAtivaKey);
      await StorageService.remove(_freteAtualKey);
      
      developer.log('🗑️ Rota ativa removida do storage', name: 'RotaExecutionService');
    } catch (e) {
      developer.log('❌ Erro ao limpar rota ativa: $e', name: 'RotaExecutionService');
    }
  }
  
  /// Retorna frete atual em execução ou próximo pendente da rota
  static FreteEG3? getFreteAtualDaRota(Rota rota) {
    if (rota.fretesRota == null) return null;
    
    // Busca frete em execução
    try {
      final freteEmExecucao = rota.fretesRota!.firstWhere(
        (f) => f.statusRota == 'EM_EXECUCAO',
      );
      return freteEmExecucao.freteData;
    } catch (e) {
      // Se não há frete em execução, busca o primeiro pendente
      try {
        final primeiroPendente = rota.fretesRota!.firstWhere(
          (f) => f.statusRota == 'PENDENTE',
        );
        return primeiroPendente.freteData;
      } catch (e) {
        return null;
      }
    }
  }
  
  /// Retorna próximo frete da rota após o atual
  static FreteEG3? getProximoFreteDaRota(Rota rota) {
    if (rota.fretesRota == null) return null;
    
    final fretesPendentes = rota.fretesRota!.where((f) => f.statusRota == 'PENDENTE').toList();
    if (fretesPendentes.isNotEmpty) {
      fretesPendentes.sort((a, b) => a.ordem.compareTo(b.ordem));
      return fretesPendentes.first.freteData;
    }
    
    return null;
  }
  
  /// Verifica se a rota está completa
  static bool isRotaCompleta(Rota rota) {
    if (rota.fretesRota == null) return false;
    
    return rota.fretesRota!.every((f) => f.statusRota == 'CONCLUIDO');
  }
  
  /// Atualiza frete atual no storage
  static Future<void> _atualizarFreteAtual(int freteId, String novoStatus) async {
    try {
      // Se o status é final, busca próximo frete
      if (FreteEG3.isStatusFinal(novoStatus)) {
        final rotaAtiva = await getRotaAtiva();
        if (rotaAtiva != null) {
          final proximoFrete = getProximoFreteDaRota(rotaAtiva);
          if (proximoFrete != null) {
            await StorageService.setInt(_freteAtualKey, proximoFrete.id);
            developer.log('🔄 Próximo frete definido: ${proximoFrete.id}', name: 'RotaExecutionService');
          } else {
            // Não há mais fretes, rota completa
            await StorageService.remove(_freteAtualKey);
            developer.log('✅ Todos os fretes concluídos', name: 'RotaExecutionService');
          }
        }
      } else {
        // Mantém o mesmo frete atual
        await StorageService.setInt(_freteAtualKey, freteId);
      }
    } catch (e) {
      developer.log('❌ Erro ao atualizar frete atual: $e', name: 'RotaExecutionService');
    }
  }
  
  /// Obtém ID do frete atual
  static Future<int?> getFreteAtualId() async {
    try {
      return await StorageService.getInt(_freteAtualKey);
    } catch (e) {
      developer.log('❌ Erro ao obter frete atual: $e', name: 'RotaExecutionService');
      return null;
    }
  }
  
  /// Inicia rastreamento para a rota
  static Future<void> iniciarRastreamentoParaRota(Rota rota) async {
    try {
      // Salva CPF para o background service
      final cpf = await StorageService.getCpf();
      if (cpf != null) {
        await BackgroundLocationService.saveCpf(cpf);
      }
      
      // Inicia o serviço de rastreamento
      await BackgroundLocationService.startService();
      
      developer.log('📍 Rastreamento iniciado para rota: ${rota.nome}', name: 'RotaExecutionService');
    } catch (e) {
      developer.log('❌ Erro ao iniciar rastreamento: $e', name: 'RotaExecutionService');
    }
  }
  
  /// Para o rastreamento
  static Future<void> pararRastreamento() async {
    try {
      await BackgroundLocationService.stopService();
      developer.log('📍 Rastreamento parado', name: 'RotaExecutionService');
    } catch (e) {
      developer.log('❌ Erro ao parar rastreamento: $e', name: 'RotaExecutionService');
    }
  }
}