## ADDED Requirements

### Requirement: Mural/feed de comunicados
O app mobile MUST exibir a todos os perfis um mural/feed dos comunicados destinados ao usuário no condomínio ativo, ordenados por data, com tipo (`aviso_geral`, `aviso_segmentado`, `aviso_individual`, `convocacao`), título e conteúdo, e MUST restringir a visibilidade ao condomínio ativo (não exibir comunicados de outro condomínio). O feed MUST oferecer pull-to-refresh e paginação por cursor.

#### Scenario: Morador vê seus comunicados
- **GIVEN** um morador com comunicados destinados a ele
- **WHEN** ele abre o mural
- **THEN** vê os comunicados aplicáveis, com tipo e conteúdo, ordenados por data

#### Scenario: Isolamento entre condomínios
- **GIVEN** um comunicado publicado no condomínio A
- **WHEN** um usuário do condomínio B abre o mural
- **THEN** o comunicado do condomínio A não é exibido

#### Scenario: Mural vazio
- **GIVEN** um usuário sem comunicados
- **WHEN** ele abre o mural
- **THEN** o app exibe estado vazio informando que não há comunicados

### Requirement: Publicação de comunicado restrita por perfil
O app mobile MUST exibir a ação de publicar comunicado apenas para `sindico`, `administradora`, `porteiro`, `conselho`, ocultando-a de moradores. Para `aviso_segmentado` e `aviso_individual`, o formulário MUST exigir o público-alvo correspondente antes de permitir o envio.

#### Scenario: Morador não vê publicar
- **GIVEN** um usuário `inquilino`
- **WHEN** ele acessa Comunicação
- **THEN** a ação "Publicar" não é renderizada

#### Scenario: Público-alvo obrigatório em aviso segmentado
- **GIVEN** um autor selecionando `aviso_segmentado`
- **WHEN** ele tenta publicar sem definir o público-alvo (ex.: Bloco B)
- **THEN** a validação de cliente impede o envio e destaca o público-alvo como obrigatório

#### Scenario: Porteiro publica aviso individual
- **GIVEN** um usuário `porteiro`
- **WHEN** ele publica um `aviso_individual` para uma unidade (ex.: encomenda)
- **THEN** o comunicado é criado e direcionado à unidade, com confirmação no app

### Requirement: Entrega multicanal com push nativo
O app mobile MUST exibir ao autor/gestão o status de entrega de cada comunicado por canal (`in_app`, `email`, `push`, `sms_whatsapp`) e por destinatário, evidenciando falhas de canal sem tratá-las como falha total do comunicado. O app MUST receber o canal `push` como **notificação nativa** via **FCM (Android) / APNs (iOS)**: ao iniciar, MUST solicitar permissão de notificação e registrar o token do dispositivo na camada de serviços; ao receber um push de comunicado, com o app em primeiro plano, segundo plano ou fechado, tocar a notificação MUST abrir (deep link) o comunicado correspondente no mural.

#### Scenario: Visualizar status por canal
- **GIVEN** um comunicado publicado
- **WHEN** o autor abre o detalhe de entrega
- **THEN** o app mostra, por destinatário, o status de cada canal (entregue/falha/pendente)

#### Scenario: Falha de um canal destacada
- **GIVEN** um comunicado cujo canal `sms_whatsapp` falhou
- **WHEN** o autor consulta o status
- **THEN** o app mostra `in_app`/`email`/`push` entregues e `sms_whatsapp` em falha, sem indicar o comunicado como não entregue

#### Scenario: Registro do token de push
- **GIVEN** um usuário que concede permissão de notificação no primeiro uso
- **WHEN** o app obtém o token FCM/APNs do dispositivo
- **THEN** o app registra esse token na camada de serviços para que o backend possa entregar push ao usuário no condomínio ativo

#### Scenario: Push abre o comunicado (deep link)
- **GIVEN** um comunicado entregue pelo canal `push` ao dispositivo do destinatário
- **WHEN** o destinatário toca a notificação nativa (app em background ou fechado)
- **THEN** o app abre diretamente no comunicado correspondente no mural

#### Scenario: Permissão de push negada
- **GIVEN** um usuário que nega a permissão de notificação
- **WHEN** o app continua em uso
- **THEN** o canal `push` não é registrado para o dispositivo, os comunicados continuam visíveis no mural (`in_app`), e o app não bloqueia o uso por falta de push

### Requirement: Confirmação de leitura
O app mobile MUST permitir que o destinatário confirme a leitura/ciência de um comunicado e MUST oferecer ao autor/gestão a consulta de quem já confirmou e quem ainda está pendente.

#### Scenario: Destinatário confirma ciência
- **GIVEN** um comunicado entregue a um destinatário
- **WHEN** ele aciona "Confirmar leitura"
- **THEN** o app registra a confirmação e atualiza o estado do comunicado para "lido"

#### Scenario: Autor consulta pendências de leitura
- **GIVEN** um comunicado com parte dos destinatários sem confirmar
- **WHEN** o autor abre o status de leitura
- **THEN** o app lista quem confirmou e quem está pendente
