## ADDED Requirements

### Requirement: Login multi-tenant e sessão
O app mobile MUST oferecer uma tela de login que autentique o usuário via **Supabase Auth** e estabeleça uma sessão cujo token (o **`access_token` JWT do Supabase**) carregue os claims `condominioId`, `perfil` e `vinculoId?`. O app MUST anexar esse `access_token` como Bearer nas chamadas ao backend e MUST NOT solicitar nem enviar o `condominioId` como campo manual de formulário ou header — o tenant viaja exclusivamente nos claims do token. A spec é **agnóstica ao shape interno** do JWT: depende apenas de que os claims `condominioId`/`perfil`/`vinculoId?` estejam acessíveis na sessão, não de sua posição exata no payload.

#### Scenario: Login com credenciais válidas
- **GIVEN** um usuário com credenciais válidas vinculado a um condomínio
- **WHEN** ele envia e-mail e senha na tela de login
- **THEN** o Supabase autentica, a sessão (access_token + refresh_token) é estabelecida, o token passa a conter os claims `condominioId`/`perfil`, e o app navega para a tela inicial do seu perfil

#### Scenario: Credenciais inválidas
- **GIVEN** a tela de login
- **WHEN** o usuário envia credenciais inválidas (Supabase Auth rejeita o login)
- **THEN** a tela exibe mensagem de erro de autenticação, mantém o e-mail digitado, limpa a senha e não navega

#### Scenario: Estado de carregamento no envio
- **GIVEN** o formulário de login preenchido
- **WHEN** o usuário submete e a requisição está em andamento
- **THEN** o botão exibe estado de carregamento e fica desabilitado, impedindo envio duplicado

### Requirement: Armazenamento seguro de token
O app mobile MUST persistir os tokens de sessão (`access_token`/`refresh_token`) exclusivamente no **armazenamento seguro do dispositivo** — **Keychain no iOS** e **Keystore no Android** — e MUST NOT gravá-los em armazenamento em texto puro (ex.: `AsyncStorage` não criptografado), logs ou arquivos acessíveis. Ao iniciar o app com tokens válidos no armazenamento seguro, o app MUST restaurar a sessão sem novo login. No logout (ou falha definitiva de refresh), o app MUST apagar os tokens do armazenamento seguro.

#### Scenario: Sessão restaurada do armazenamento seguro
- **GIVEN** um usuário que já logou e cujos tokens válidos estão no Keychain/Keystore
- **WHEN** ele reabre o app
- **THEN** a sessão é restaurada a partir do armazenamento seguro e o usuário entra direto na tela inicial do seu perfil, sem digitar credenciais novamente

#### Scenario: Tokens nunca em armazenamento em texto puro
- **GIVEN** um usuário autenticado
- **WHEN** a sessão é persistida no dispositivo
- **THEN** os tokens residem apenas no Keychain (iOS) / Keystore (Android) e não aparecem em armazenamento não criptografado nem em logs

#### Scenario: Logout limpa o armazenamento seguro
- **GIVEN** um usuário autenticado com tokens no armazenamento seguro
- **WHEN** ele faz logout
- **THEN** o app apaga os tokens do Keychain/Keystore e retorna à tela de login, e uma reabertura do app não restaura a sessão

### Requirement: Guarda de navegação autenticada
O app mobile MUST proteger todas as telas de aplicação exigindo sessão Supabase válida, direcionando usuários não autenticados para o fluxo de login (stack de autenticação). Quando o `access_token` expira, o app MUST tentar renová-lo de forma transparente via `refresh_token` (refresh do cliente Supabase) e repetir a chamada original; somente quando o refresh falhar (refresh_token inválido/expirado) ou o backend responder 401 com a sessão já renovada o app MUST encerrar a sessão local, apagar os tokens do armazenamento seguro e direcionar ao login.

#### Scenario: Acesso sem sessão
- **GIVEN** um usuário não autenticado
- **WHEN** o app é aberto sem sessão válida
- **THEN** o app apresenta o stack de autenticação (login) e não monta as telas protegidas

#### Scenario: Access token expira mas refresh é válido
- **GIVEN** um usuário autenticado navegando no app cujo `access_token` acabou de expirar
- **WHEN** uma chamada à API retorna 401 por token expirado e o `refresh_token` ainda é válido
- **THEN** o app renova a sessão via Supabase de forma transparente, repete a chamada original e o usuário continua sem ser deslogado nem perder o contexto

#### Scenario: Sessão expira sem refresh possível
- **GIVEN** um usuário autenticado cujo `refresh_token` está expirado/inválido (ou o backend mantém 401 após o refresh)
- **WHEN** uma chamada à API retorna 401 e a renovação falha
- **THEN** o app encerra a sessão local, apaga os tokens do armazenamento seguro e direciona ao login informando que a sessão expirou

### Requirement: Navegação e render condicional por perfil
O app mobile MUST montar a navegação (stack/tabs) e exibir telas e ações conforme o `perfil` do usuário (`sindico`, `administradora`, `proprietario`, `inquilino`, `porteiro`, `conselho`), ocultando o que o perfil não pode executar, e MUST tratar uma resposta 403 do backend como "ação não permitida" sem expor dados. A navegação primária MUST ser organizada por tabs/stack apropriados ao perfil (ex.: tabs de gestão para `sindico`/`administradora`; tabs de morador para `proprietario`/`inquilino`; fluxo de portaria para `porteiro`).

#### Scenario: Morador não vê ação de gestão
- **GIVEN** um usuário com perfil `inquilino`
- **WHEN** ele acessa o módulo de Comunicação
- **THEN** a ação "Publicar comunicado" não é renderizada (apenas leitura/confirmação de ciência)

#### Scenario: Tabs montadas por perfil
- **GIVEN** um usuário com perfil `porteiro`
- **WHEN** o app monta a navegação após o login
- **THEN** as tabs/telas exibidas são as do fluxo de portaria (registro de acesso, encomendas), sem as telas exclusivas de gestão financeira/assembleias

#### Scenario: Defesa em profundidade contra 403
- **GIVEN** um usuário cujo perfil não autoriza uma ação, mas que aciona o endpoint mesmo assim
- **WHEN** o backend responde 403
- **THEN** o app exibe feedback de "permissão negada" e não renderiza nenhum dado retornado

#### Scenario: Acesso cross-tenant negado
- **GIVEN** um usuário do condomínio A
- **WHEN** uma navegação tenta acessar um recurso de outro condomínio e o backend responde 403
- **THEN** o app exibe estado de "sem acesso" e não vaza qualquer dado do outro condomínio

### Requirement: Troca de condomínio (multi-vínculo)
O app mobile MUST permitir que um usuário vinculado a mais de um condomínio (ex.: `administradora`) selecione/troque o condomínio ativo, refletindo a troca em um **token reemitido pelo Supabase** com o novo claim `condominioId` (sem novo login) e recarregando os dados no contexto do condomínio escolhido. Quando o usuário tem um único vínculo, o seletor MUST NOT ser exibido.

#### Scenario: Usuário com múltiplos condomínios
- **GIVEN** uma `administradora` vinculada aos condomínios A e B
- **WHEN** ela seleciona o condomínio B no seletor
- **THEN** o contexto ativo passa a B, o token reflete `condominioId` de B, e as telas recarregam apenas dados de B

#### Scenario: Usuário com vínculo único
- **GIVEN** um `proprietario` vinculado a um único condomínio
- **WHEN** ele acessa o app
- **THEN** o seletor de condomínio não é exibido e o contexto ativo é o seu único condomínio

### Requirement: Estados de tela mobile (transversal às 7 capacidades de módulo)
Todas as telas das 7 capacidades de módulo (`cadastro-mobile`, `financeiro-mobile`, `comunicacao-mobile`, `reservas-areas-comuns-mobile`, `assembleias-votacoes-mobile`, `ocorrencias-manutencao-mobile`, `portaria-acessos-mobile`) MUST apresentar estados de **loading**, **erro**, **vazio** e **sucesso** adaptados a mobile: indicador de carregamento (ex.: skeleton/spinner) enquanto busca dados; estado de erro recuperável com ação de tentar novamente; estado vazio com orientação/chamada para ação; e feedback de sucesso não bloqueante (ex.: toast/snackbar). Listas paginadas MUST oferecer **pull-to-refresh** e carregamento incremental ("carregar mais"/scroll infinito) coerente com a paginação por cursor. Este requisito é transversal e é **herdado por cada uma das 7 capacidades de módulo** acima.

#### Scenario: Estado de carregamento em lista
- **GIVEN** qualquer tela de lista das 7 capacidades buscando dados pela primeira vez
- **WHEN** a requisição está em andamento
- **THEN** o app exibe um indicador de carregamento (skeleton/spinner) e não mostra a lista ainda

#### Scenario: Estado de erro recuperável
- **GIVEN** uma tela cuja carga de dados falhou (ex.: 500 ou rede indisponível)
- **WHEN** o usuário visualiza a tela
- **THEN** o app exibe um estado de erro com mensagem e ação de "tentar novamente", sem travar a navegação

#### Scenario: Estado vazio
- **GIVEN** uma tela de lista sem itens para o usuário no condomínio ativo
- **WHEN** a carga conclui com lista vazia
- **THEN** o app exibe um estado vazio com orientação (ex.: chamada para a ação aplicável) em vez de uma lista em branco

#### Scenario: Pull-to-refresh e carregar mais
- **GIVEN** uma lista paginada já carregada com `nextCursor` não nulo
- **WHEN** o usuário puxa para atualizar e depois rola até o fim
- **THEN** o app recarrega a lista no pull-to-refresh e acrescenta a próxima página ao chegar ao fim, encerrando quando `nextCursor` for nulo
