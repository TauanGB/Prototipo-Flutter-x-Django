# Exemplo de Uso da API por ID do Motorista

## Nova API Criada

### Backend (SistemaEG3)
- **Endpoint:** `/api/usuarios/motorista/fretes-ativos-por-id/?motorista_id={id}`
- **Método:** GET
- **Parâmetro:** `motorista_id` (número inteiro)

### Frontend (Flutter)
- **Endpoint:** `rastreioActiveFretesPorId`
- **Método:** `FreteService.getFretesAtivosPorId()`

## Como Usar

### 1. No Dashboard (Flutter)

```dart
// Método atual (por CPF)
final fretes = await FreteService.getFretesAtivos();

// Novo método (por ID do motorista)
final fretes = await FreteService.getFretesAtivosPorId();
```

### 2. Exemplo de Resposta da API

```json
{
  "motorista_id": 1,
  "motorista": "Roberto Alves",
  "fretes_ativos": [
    {
      "id": 1,
      "nome_frete": "Transporte SP-RJ",
      "numero_nota_fiscal": "12345",
      "codigo_publico": "FRT-2024-001",
      "status_atual": "EM_TRANSITO",
      "origem": "São Paulo, SP",
      "destino": "Rio de Janeiro, RJ",
      "data_agendamento": "2024-01-15T08:00:00Z",
      "observacoes": "Frete urgente",
      "cliente_nome": "Cliente Teste"
    }
  ],
  "total": 1
}
```

### 3. Comparação das APIs

| Aspecto | Por CPF | Por ID do Motorista |
|---------|---------|-------------------|
| **Endpoint** | `/motorista/fretes-ativos/?cpf=` | `/motorista/fretes-ativos-por-id/?motorista_id=` |
| **Parâmetro** | CPF (string) | ID (número) |
| **Método Flutter** | `getFretesAtivos()` | `getFretesAtivosPorId()` |
| **Vantagem** | Mais direto para login | Mais eficiente para consultas |

### 4. Quando Usar Cada Uma

**Use por CPF quando:**
- Login foi feito por CPF
- CPF está disponível facilmente
- Quer manter consistência com autenticação

**Use por ID quando:**
- ID do motorista está disponível
- Quer melhor performance (busca por chave primária)
- Sistema interno usa IDs

### 5. Implementação no Dashboard

Para alternar entre as duas APIs no dashboard, você pode modificar o método `_loadFretesAtivos()`:

```dart
Future<void> _loadFretesAtivos() async {
  setState(() {
    _loadingFretes = true;
  });

  try {
    // Tentar primeiro por ID (mais eficiente)
    List<FreteEG3> fretes;
    try {
      fretes = await FreteService.getFretesAtivosPorId();
    } catch (e) {
      // Fallback para CPF se ID não funcionar
      developer.log('⚠️ Falha com ID, tentando CPF: $e', name: 'Dashboard');
      fretes = await FreteService.getFretesAtivos();
    }
    
    setState(() {
      _fretesAtivos = fretes;
    });
    developer.log('✅ ${fretes.length} fretes carregados no dashboard', name: 'Dashboard');
  } catch (e) {
    developer.log('❌ Erro ao carregar fretes: $e', name: 'Dashboard');
    _showSnackBar('Erro ao carregar fretes ativos', isError: true);
  } finally {
    setState(() {
      _loadingFretes = false;
    });
  }
}
```

## Benefícios da Nova API

1. **Performance:** Busca por chave primária é mais rápida
2. **Flexibilidade:** Duas opções para diferentes cenários
3. **Compatibilidade:** Mantém a API por CPF funcionando
4. **Robustez:** Fallback entre as duas APIs
5. **Escalabilidade:** ID é mais eficiente em grandes volumes

## Teste da API

Para testar a nova API diretamente:

```bash
curl "https://sistemaeg3-production.up.railway.app/api/usuarios/motorista/fretes-ativos-por-id/?motorista_id=1"
```

Substitua `1` pelo ID real do motorista.




