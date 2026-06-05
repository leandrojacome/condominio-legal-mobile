## ADDED Requirements

### Requirement: Cliente HTTP tipado por endpoint do contrato backend
O app mobile MUST expor uma camada de serviços que encapsule todo acesso à API do backend em clients/funções tipadas, organizadas por módulo do contrato (`cadastro`, `financeiro`, `comunicacao`, `reservas`, `assembleias`, `ocorrencias`, `portaria`), versionadas sob `/api/v1`. Nenhuma tela/componente MUST chamar `fetch` (ou equivalente HTTP) diretamente — todo acesso passa pela camada de serviços. Cada função MUST declarar tipos TypeScript de entrada (request) e de saída (response) derivados do contrato backend.

#### Scenario: Tela consome via service, não fetch direto
- **GIVEN** uma tela que precisa listar unidades
- **WHEN** ela busca os dados
- **THEN** ela invoca `cadastroService.listarUnidades(...)` da camada de serviços, recebendo um tipo `Unidade[]` tipado, sem montar a chamada HTTP por conta própria

#### Scenario: Resposta fora do tipo esperado
- **GIVEN** uma chamada de serviço cuja resposta não corresponde ao tipo declarado do contrato
- **WHEN** a camada de serviços processa a resposta
- **THEN** o erro é tratado como falha de contrato (estado de erro), e o dado inválido não é propagado para a tela

### Requirement: Anexação automática de autenticação e tenant
A camada de serviços MUST anexar automaticamente a credencial de sessão (o `access_token` do Supabase, lido do armazenamento seguro Keychain/Keystore) como Bearer a toda requisição autenticada, sem que cada chamada precise repassá-la manualmente. O `condominioId` (tenant) MUST ser derivado dos claims do token e nunca aceito como parâmetro arbitrário vindo da UI.

#### Scenario: Requisição autenticada
- **GIVEN** um usuário com sessão ativa
- **WHEN** qualquer função de serviço é chamada
- **THEN** a requisição parte com o `access_token` da sessão anexado como Bearer, e o backend resolve o tenant a partir do token

#### Scenario: Requisição sem sessão
- **GIVEN** um usuário sem sessão válida
- **WHEN** uma função de serviço autenticada é chamada
- **THEN** a camada de serviços não emite a chamada anônima; encaminha o fluxo de não-autenticado (direciona ao login)

#### Scenario: Tenant nunca vem da UI
- **GIVEN** uma tela que dispara uma ação no condomínio ativo
- **WHEN** a função de serviço monta a requisição
- **THEN** o `condominioId` provém dos claims do token e a UI não consegue injetar um tenant arbitrário na chamada

### Requirement: Tratamento padronizado de erros da API
A camada de serviços MUST interpretar o envelope de erro do backend `{ code, message, details }` e mapear o status HTTP para um tipo de erro de aplicação previsível: `400 VALIDATION` (com `details` por campo), `401 UNAUTHENTICATED`, `403 FORBIDDEN`, `404 NOT_FOUND`, `409 CONFLICT`, `422 BUSINESS_RULE`, `500 INTERNAL`. As telas MUST consumir esse erro tipado para escolher o feedback adequado (erro de campo, sem permissão, conflito, etc.). A camada MUST também tratar falha de rede/timeout (sem resposta HTTP) como um erro recuperável distinto, oferecendo "tentar novamente".

#### Scenario: Erro de validação com detalhes por campo
- **GIVEN** um formulário enviado com um campo inválido
- **WHEN** o backend responde 400 com `details` indicando o campo
- **THEN** a camada retorna um erro `VALIDATION` com os campos, e a tela destaca o(s) campo(s) correspondente(s)

#### Scenario: Regra de negócio violada
- **GIVEN** uma ação que viola uma regra de negócio (ex.: voto sem quórum)
- **WHEN** o backend responde 422
- **THEN** a camada retorna `BUSINESS_RULE` com a mensagem, e a tela exibe o motivo do bloqueio sem tratá-lo como erro de campo

#### Scenario: Falha de rede sem resposta
- **GIVEN** o dispositivo sem conectividade ou um timeout de requisição
- **WHEN** uma função de serviço é chamada e não há resposta HTTP
- **THEN** a camada retorna um erro de rede recuperável e a tela exibe estado de erro com opção de tentar novamente, sem expor detalhes técnicos

### Requirement: Paginação por cursor na camada de serviços
A camada de serviços MUST suportar a paginação cursor-based do backend (`?cursor=&limit=`), expondo às telas uma forma de carregar a próxima página a partir do `nextCursor`, e MUST tratar `nextCursor: null` como fim da lista. Relatórios estáticos (ex.: inadimplentes) MAY usar paginação por offset quando o contrato assim expuser.

#### Scenario: Carregar próxima página
- **GIVEN** uma lista paginada com `nextCursor` não nulo
- **WHEN** a tela solicita mais itens
- **THEN** a camada chama o endpoint com o `cursor` recebido e acrescenta os novos itens à lista

#### Scenario: Fim da lista
- **GIVEN** uma resposta com `nextCursor: null`
- **WHEN** a tela tenta carregar mais
- **THEN** a camada sinaliza fim de lista e a UI encerra o "carregar mais"

### Requirement: Idempotência em ações sensíveis
Para ações sensíveis a duplicidade que o contrato backend protege por `Idempotency-Key` (ex.: emissão de cobrança, confirmação de voto, registro de pagamento, registro de acesso), a camada de serviços MUST gerar e enviar uma chave de idempotência por tentativa lógica do usuário, garantindo que reenvios (retry/duplo toque) não produzam efeitos duplicados.

#### Scenario: Duplo toque em ação sensível
- **GIVEN** um usuário que aciona "Emitir boleto" e toca duas vezes rapidamente
- **WHEN** a camada de serviços envia as requisições
- **THEN** ambas carregam a mesma `Idempotency-Key` da ação lógica, e o backend executa a emissão uma única vez

#### Scenario: Retry após falha de rede preserva a chave
- **GIVEN** uma ação sensível cujo envio falhou por rede antes de confirmar
- **WHEN** o usuário aciona "tentar novamente" na mesma tentativa lógica
- **THEN** a camada reenvia com a mesma `Idempotency-Key`, evitando efeito duplicado caso a primeira chamada tenha chegado ao backend
