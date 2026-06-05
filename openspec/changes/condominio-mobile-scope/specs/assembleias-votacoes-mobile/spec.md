## ADDED Requirements

### Requirement: Convocação de assembleia com pauta
O app mobile MUST permitir à gestão (`sindico`, `administradora`) convocar uma assembleia híbrida informando data/hora, local e uma pauta com um ou mais itens de votação, cada item com critério de voto (`por_unidade`/`por_fracao`), quórum mínimo e marcação opcional de voto secreto. O formulário MUST exigir ao menos um item de pauta.

#### Scenario: Convocar assembleia com múltiplos itens
- **GIVEN** um síndico na tela de nova convocação
- **WHEN** ele informa data, local e 3 itens de pauta e convoca
- **THEN** a assembleia é criada com status `convocada` e os 3 itens aparecem na agenda

#### Scenario: Convocação sem pauta bloqueada
- **GIVEN** o formulário de convocação sem itens de pauta
- **WHEN** o síndico tenta convocar
- **THEN** a validação de cliente impede o envio exigindo ao menos um item de pauta

### Requirement: Cabine de votação online
O app mobile MUST oferecer ao votante elegível uma cabine de votação para registrar seu voto por item de pauta durante a janela aberta, respeitando o critério configurado, e MUST impedir/sinalizar voto duplicado pela mesma unidade no mesmo item (409). Itens marcados como secretos MUST NOT expor, na UI, a associação entre voto e identidade.

#### Scenario: Registrar voto em item aberto
- **GIVEN** um votante elegível e um item de pauta com votação aberta
- **WHEN** ele seleciona uma opção e confirma
- **THEN** o app registra o voto e marca o item como "já votado" para aquela unidade

#### Scenario: Voto duplicado bloqueado
- **GIVEN** uma unidade que já votou em um item
- **WHEN** um novo voto é submetido para a mesma unidade/item e o backend responde 409
- **THEN** o app informa que a unidade já votou e não registra novo voto

#### Scenario: Item secreto não revela identidade
- **GIVEN** um item de pauta marcado como secreto
- **WHEN** o votante confirma o voto
- **THEN** o app confirma o registro sem exibir, em nenhum momento, quem votou em qual opção

### Requirement: Elegibilidade e procuração na UI
O app mobile MUST sinalizar quando o votante está bloqueado por inadimplência (recusa do backend) e MUST permitir que um votante com procuração registrada vote em nome da unidade representada, deixando claro em nome de qual unidade o voto está sendo computado.

#### Scenario: Inadimplente não vota
- **GIVEN** uma unidade com cobrança `em_atraso`
- **WHEN** seu representante tenta votar e o backend recusa por inadimplência
- **THEN** o app informa o bloqueio por inadimplência e não permite registrar o voto

#### Scenario: Voto por procuração
- **GIVEN** um morador com procuração para representar a unidade 502
- **WHEN** ele abre a cabine
- **THEN** o app deixa claro que o voto será computado para a unidade 502 e registra o voto nesse nome

### Requirement: Apuração, resultado e ata
O app mobile MUST exibir o resultado apurado por item (incluindo indicação de quórum atingido/não atingido), MUST permitir à gestão gerar/baixar/compartilhar a ata oficial e disparar a divulgação do resultado aos moradores (via Comunicação), e MUST oferecer a consulta do histórico auditável respeitando o sigilo das pautas secretas.

#### Scenario: Resultado por item após apuração
- **GIVEN** uma assembleia com votação encerrada e quórum atingido
- **WHEN** a gestão abre a apuração
- **THEN** cada item exibe seu resultado (aprovado/reprovado) conforme a contagem

#### Scenario: Quórum não atingido
- **GIVEN** um item cujo quórum mínimo não foi atingido
- **WHEN** a votação é encerrada
- **THEN** o app sinaliza o item como "sem quórum" e não apresenta o resultado como homologado

#### Scenario: Gerar ata e divulgar resultado
- **GIVEN** uma assembleia apurada
- **WHEN** o gestor gera a ata e dispara a divulgação
- **THEN** o app disponibiliza a ata oficial (baixar/compartilhar) e confirma o envio do comunicado de resultado aos moradores

#### Scenario: Auditoria respeita sigilo
- **GIVEN** uma assembleia encerrada com itens secretos e abertos
- **WHEN** um auditor consulta o histórico
- **THEN** o app mostra a contagem dos itens secretos sem identidade e a rastreabilidade dos itens abertos
