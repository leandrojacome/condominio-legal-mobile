## ADDED Requirements

### Requirement: Catálogo e configuração de áreas comuns
O app mobile MUST exibir o catálogo de áreas comuns reserváveis do condomínio com sua configuração (granularidade `dia_inteiro`/`turno`/`horario`, política `exclusiva`/`capacidade`, modo `automatica`/`requer_aprovacao`, taxa e regras), e MUST oferecer à gestão (`sindico`, `administradora`) o formulário de cadastro/edição dessa configuração. Moradores veem o catálogo apenas para reservar.

#### Scenario: Gestor cadastra área
- **GIVEN** um gestor na tela de nova área
- **WHEN** ele cria "Salão de Festas" com granularidade `dia_inteiro`, política `exclusiva` e modo `requer_aprovacao`
- **THEN** a área é persistida com essa configuração e passa a aparecer no catálogo disponível para reserva

#### Scenario: Catálogo expõe granularidade por área
- **GIVEN** um condomínio com "Salão" (`dia_inteiro`) e "Quadra" (`horario`)
- **WHEN** um morador abre o catálogo
- **THEN** cada área apresenta sua própria granularidade no fluxo de reserva

### Requirement: Disponibilidade e fluxo de reserva
O app mobile MUST apresentar a disponibilidade do período conforme a granularidade da área (ex.: calendário/seleção de turno/horário) e MUST conduzir a solicitação de reserva, refletindo a política de conflito: em área `exclusiva`, períodos já reservados aparecem indisponíveis; em área com `capacidade`, exibe vagas restantes. O app MUST tratar recusa por indisponibilidade/capacidade esgotada (409) com feedback claro.

#### Scenario: Período indisponível em área exclusiva
- **GIVEN** uma área `exclusiva` com um período já reservado
- **WHEN** o morador abre a disponibilidade
- **THEN** o período reservado aparece bloqueado e não é selecionável

#### Scenario: Capacidade esgotada
- **GIVEN** uma área com `capacidade` de 10 vagas e 10 reservas no período
- **WHEN** o morador tenta reservar e o backend responde 409
- **THEN** o app informa capacidade esgotada e não cria a reserva

#### Scenario: Reserva confirmada automaticamente
- **GIVEN** uma área `automatica` com o período disponível
- **WHEN** o morador solicita a reserva
- **THEN** o app mostra a reserva como `confirmada` imediatamente

### Requirement: Aprovação de reservas pendentes
O app mobile MUST, para áreas `requer_aprovacao`, exibir a reserva como `pendente` ao morador e oferecer à gestão uma fila de reservas pendentes com ações de aprovar/recusar, atualizando o status resultante (`confirmada` ao aprovar, `recusada` ao recusar). Ao recusar, o app MUST refletir o status `recusada` e MUST comunicar a recusa ao morador (feedback visível na reserva do morador), permitindo opcionalmente registrar/exibir o motivo da recusa quando fornecido pela gestão.

#### Scenario: Reserva fica pendente
- **GIVEN** uma área `requer_aprovacao`
- **WHEN** o morador solicita a reserva
- **THEN** o app exibe a reserva como `pendente` aguardando decisão

#### Scenario: Gestor aprova reserva
- **GIVEN** uma reserva `pendente` na fila da gestão
- **WHEN** o gestor a aprova
- **THEN** o app atualiza a reserva para `confirmada` e notifica visualmente o sucesso

#### Scenario: Gestor recusa reserva
- **GIVEN** uma reserva `pendente` na fila da gestão
- **WHEN** o gestor a recusa (informando opcionalmente o motivo)
- **THEN** o app atualiza a reserva para `recusada`, remove-a da fila de pendentes e o morador passa a ver a reserva como `recusada` com o feedback da recusa (incluindo o motivo, quando informado)

### Requirement: Bloqueio de inadimplente e validações de regra
O app mobile MUST impedir/sinalizar a reserva por unidade inadimplente (recusa do backend por inadimplência) e MUST validar antecedência mínima/máxima e limite por unidade, exibindo o motivo específico da recusa.

#### Scenario: Inadimplente bloqueado
- **GIVEN** uma unidade com cobrança `em_atraso`
- **WHEN** o morador tenta reservar e o backend recusa por inadimplência
- **THEN** o app informa o bloqueio por inadimplência e orienta a regularização

#### Scenario: Antecedência insuficiente
- **GIVEN** uma área que exige antecedência mínima de 2 dias
- **WHEN** o morador tenta reservar para o dia seguinte
- **THEN** o app recusa com mensagem de antecedência insuficiente

#### Scenario: Limite por unidade atingido
- **GIVEN** uma área com limite de 1 reserva/mês e a unidade já com 1 no mês
- **WHEN** o morador tenta uma segunda reserva no mês
- **THEN** o app informa que o limite por unidade foi atingido

### Requirement: Taxa de uso e cancelamento
O app mobile MUST informar, antes da confirmação, quando a área possui taxa de uso (e que será gerada cobrança no Financeiro ao confirmar), e MUST permitir cancelar uma reserva exibindo a regra de prazo: dentro do prazo sem penalidade; fora do prazo, alertando sobre a penalidade configurada antes de confirmar o cancelamento.

#### Scenario: Reserva com taxa avisa sobre cobrança
- **GIVEN** uma área com taxa de uso
- **WHEN** o morador confirma a reserva
- **THEN** o app avisa que uma cobrança será gerada no Financeiro vinculada à reserva

#### Scenario: Cancelamento fora do prazo alerta penalidade
- **GIVEN** uma reserva confirmada com taxa, cancelada fora do prazo
- **WHEN** o morador inicia o cancelamento
- **THEN** o app alerta sobre a penalidade configurada antes de confirmar e, ao confirmar, reflete a penalidade aplicada
