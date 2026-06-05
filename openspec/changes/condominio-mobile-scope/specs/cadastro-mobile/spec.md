## ADDED Requirements

### Requirement: Telas de gestão de condomínio
O app mobile MUST oferecer telas para cadastrar, consultar e editar o condomínio (nome, endereço e blocos/torres opcionais), disponíveis apenas para perfis de gestão (`sindico`, `administradora`). Perfis de morador MUST NOT ver ações de criação/edição de condomínio.

#### Scenario: Gestor cadastra condomínio com dados mínimos
- **GIVEN** um gestor autenticado na tela de novo condomínio
- **WHEN** ele preenche nome e endereço válidos e salva
- **THEN** a camada de serviços cria o condomínio, o app exibe confirmação de sucesso e navega para o detalhe do condomínio criado

#### Scenario: Validação de nome obrigatório
- **GIVEN** o formulário de condomínio
- **WHEN** o gestor tenta salvar sem nome e o backend responde 400 no campo nome
- **THEN** o app destaca o campo nome com a mensagem de obrigatoriedade e não navega

#### Scenario: Morador não vê edição
- **GIVEN** um usuário com perfil `proprietario`
- **WHEN** ele acessa os dados do condomínio
- **THEN** vê apenas leitura, sem ações de criar/editar

### Requirement: Telas de unidades
O app mobile MUST oferecer listagem paginada e formulário de cadastro/edição de unidades, com `tipo` restrito a `apartamento`, `casa`, `comercial`, `garagem`, `deposito`, e identificação por bloco/torre + número. O app MUST tratar erros de duplicidade (409) e de tipo inválido (400) com feedback específico.

#### Scenario: Cadastro de unidade com bloco e número
- **GIVEN** um gestor na tela de nova unidade
- **WHEN** ele seleciona tipo `apartamento`, informa Bloco B / número 302 e salva
- **THEN** a unidade é criada e aparece na listagem vinculada ao condomínio ativo

#### Scenario: Unidade duplicada
- **GIVEN** o condomínio já possui a unidade Bloco B / número 302
- **WHEN** o gestor tenta criar outra Bloco B / número 302 e o backend responde 409
- **THEN** o app exibe erro de identificação duplicada (bloco + número) sem perder os dados do formulário

#### Scenario: Tipo inválido bloqueado na UI
- **GIVEN** o formulário de unidade
- **WHEN** o gestor abre o seletor de tipo
- **THEN** apenas os tipos permitidos são oferecidos, impedindo o envio de tipo fora da lista

#### Scenario: Lista vazia de unidades
- **GIVEN** um condomínio recém-criado sem unidades
- **WHEN** o gestor abre a listagem de unidades
- **THEN** o app exibe estado vazio com chamada para cadastrar a primeira unidade

### Requirement: Telas de pessoas
O app mobile MUST oferecer listagem e formulário de pessoas com os campos obrigatórios nome, CPF, e-mail e telefone, validando o formato no cliente e tratando duplicidade de CPF (409) e campos faltantes (400) com feedback de campo.

#### Scenario: Cadastro de pessoa válida
- **GIVEN** um gestor na tela de nova pessoa
- **WHEN** ele preenche nome, CPF, e-mail e telefone válidos e salva
- **THEN** a pessoa é criada e passa a constar na listagem

#### Scenario: Campo obrigatório ausente
- **GIVEN** o formulário de pessoa sem CPF
- **WHEN** o gestor tenta salvar
- **THEN** a validação de cliente impede o envio e destaca o campo CPF como obrigatório

#### Scenario: CPF duplicado no condomínio
- **GIVEN** uma pessoa com determinado CPF já existe no condomínio
- **WHEN** o gestor tenta cadastrar outra com o mesmo CPF e o backend responde 409
- **THEN** o app exibe erro de CPF duplicado preservando o formulário

### Requirement: Tela de vínculos pessoa↔unidade
O app mobile MUST permitir vincular uma pessoa a uma ou mais unidades com `papel` em `proprietario`, `inquilino`, `morador`, `responsavel_financeiro`, `imobiliaria`, exibindo os vínculos existentes de cada unidade/pessoa. O app MUST oferecer apenas pessoas e unidades do condomínio ativo e tratar 403 de violação de isolamento.

#### Scenario: Vincular proprietário
- **GIVEN** uma unidade e uma pessoa do condomínio ativo
- **WHEN** o gestor cria o vínculo com papel `proprietario`
- **THEN** o vínculo aparece na unidade e a pessoa consta como proprietária

#### Scenario: Pessoa em múltiplas unidades
- **GIVEN** uma pessoa já vinculada à unidade 101
- **WHEN** o gestor a vincula também à unidade 202
- **THEN** o app mostra ambos os vínculos coexistindo para a mesma pessoa

#### Scenario: Papel inválido indisponível
- **GIVEN** o formulário de vínculo
- **WHEN** o gestor abre o seletor de papel
- **THEN** apenas os papéis permitidos são oferecidos
