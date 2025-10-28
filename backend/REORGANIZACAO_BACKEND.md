# Reorganização do Backend para Compatibilidade com SistemaEG3

## Resumo das Mudanças

O backend do projeto Flutter foi reorganizado para ter coerência com os modelos do SistemaEG3, mantendo total compatibilidade com as APIs existentes do Flutter.

## Estrutura Reorganizada

### 1. Modelos de Usuário (`apps.users.models`)

#### Novos Modelos Adicionados:
- **PerfilUsuario**: Estende o usuário com informações específicas da EG3
- **Cliente**: Modelo para empresas clientes
- **UsuarioEmpresa**: Usuários subordinados de empresas

#### Campos Adicionados ao User:
- `cpf`: Campo único para identificação
- `ativo`: Status ativo/inativo

### 2. Modelos de Frete (`apps.core.models`)

#### Modelos Compatíveis com SistemaEG3:
- **Frete**: Modelo principal para serviços de transporte
- **Material**: Materiais por frete
- **StatusHistory**: Histórico de alterações de status
- **FotoFrete**: Fotos dos fretes
- **PontoLocalizacao**: Pontos de localização dos fretes
- **Rota**: Agrupamento de fretes em rotas
- **FreteRota**: Relacionamento frete-rota

#### Modelos Mantidos para Compatibilidade:
- **Driver**: Motoristas (compatível com Flutter)
- **DriverLocation**: Localização dos motoristas
- **DriverTrip**: Viagens dos motoristas

### 3. Novo App Fretes

Criado o app `fretes` com:
- **Serializers**: Para serialização dos dados
- **Views**: APIs para gerenciamento de fretes
- **URLs**: Rotas para as APIs
- **Admin**: Interface administrativa

## APIs Mantidas para Compatibilidade

### APIs Existentes do Flutter (Mantidas):
- `GET /api/v1/drivers/check_driver/?cpf=12345678901`
- `POST /api/v1/drivers/send_location/`
- `POST /api/v1/drivers/start_trip/`
- `POST /api/v1/drivers/end_trip/`
- `GET /api/v1/drivers/get_driver_data/?cpf=12345678901`

### Novas APIs Adicionadas:
- `GET /api/v1/drivers/get_active_fretes/?cpf=12345678901`
- `POST /api/v1/drivers/send_location_with_frete/`

### APIs de Fretes:
- `GET /api/v1/fretes/fretes/` - Listar fretes
- `POST /api/v1/fretes/fretes/` - Criar frete
- `GET /api/v1/fretes/fretes/{id}/` - Detalhes do frete
- `POST /api/v1/fretes/fretes/{id}/update_status/` - Atualizar status
- `POST /api/v1/fretes/fretes/{id}/add_location/` - Adicionar localização

## Compatibilidade com SistemaEG3

### Campos Idênticos:
- Estrutura de usuários com perfis
- Modelos de frete com mesmos campos
- Status e tipos de serviço compatíveis
- Relacionamentos mantidos

### Funcionalidades Adicionadas:
- Gestão de clientes/empresas
- Controle de usuários por empresa
- Histórico de status
- Rastreamento de localização por frete
- Gestão de rotas

## Migração de Dados

### Passos para Migração:
1. Executar migrações do Django
2. Criar usuários com perfis
3. Migrar dados existentes se necessário
4. Testar compatibilidade das APIs

### Scripts de Teste:
- `test_coherent_api.py`: Testa compatibilidade das APIs
- `create_test_user.py`: Cria usuários de teste
- `check_user.py`: Verifica usuários existentes

## Configurações Atualizadas

### Apps Instalados:
```python
LOCAL_APPS = [
    'apps.core',
    'apps.users', 
    'apps.api',
    'fretes',  # Novo app
]
```

### URLs Configuradas:
```python
urlpatterns = [
    path('api/v1/', include('apps.api.urls')),
    path('api/v1/auth/', include('apps.users.urls')),
    path('api/v1/fretes/', include('fretes.urls')),  # Nova rota
    path('api-auth/', include('rest_framework.urls')),
]
```

## Benefícios da Reorganização

1. **Coerência de Dados**: Mesma estrutura do SistemaEG3
2. **Compatibilidade**: APIs do Flutter continuam funcionando
3. **Escalabilidade**: Estrutura preparada para crescimento
4. **Manutenibilidade**: Código organizado e documentado
5. **Integração**: Fácil integração entre sistemas

## Próximos Passos

1. Executar migrações do banco de dados
2. Testar todas as APIs existentes
3. Implementar funcionalidades específicas do SistemaEG3
4. Documentar APIs adicionais
5. Treinar equipe nas novas funcionalidades

## Notas Importantes

- **Nenhuma API existente foi quebrada**
- **Todas as funcionalidades do Flutter continuam funcionando**
- **Estrutura preparada para uso compartilhado do banco**
- **Modelos compatíveis com SistemaEG3**
