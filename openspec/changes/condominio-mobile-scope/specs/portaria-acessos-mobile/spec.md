## ADDED Requirements

### Requirement: Registro de acesso na portaria
O app mobile MUST oferecer ao `porteiro` (e à gestão) uma tela para registrar acessos por `tipo` (`visitante`, `prestador`, `entrega`, `veiculo`), capturando identificação (nome e documento), unidade de destino, horário de entrada e autorizador, e MUST permitir registrar a saída posteriormente, refletindo o status ("no condomínio" → "encerrado"). O tipo MUST ser limitado na UI aos valores permitidos.

#### Scenario: Registrar entrada de visitante
- **GIVEN** um porteiro na tela de novo acesso
- **WHEN** ele registra um `visitante` com identificação, unidade de destino e autorizador
- **THEN** o acesso é criado com horário de entrada e status "no condomínio"

#### Scenario: Registrar saída
- **GIVEN** um acesso com entrada e sem saída
- **WHEN** o porteiro registra a saída
- **THEN** o app grava o horário de saída e marca o acesso como encerrado

#### Scenario: Tipo inválido bloqueado
- **GIVEN** o formulário de acesso
- **WHEN** o porteiro abre o seletor de tipo
- **THEN** apenas os tipos permitidos são oferecidos

### Requirement: Pré-autorização e confirmação na chegada
O app mobile MUST permitir ao morador pré-autorizar visitantes/prestadores (data e identificação), e MUST oferecer ao porteiro o fluxo de solicitar confirmação ao morador na chegada quando não houver pré-autorização. O app MUST impedir liberação sem autorização válida e refletir os estados `pre_autorizado` / `aguardando_confirmacao` / `autorizado` / `negado`. A solicitação de confirmação ao morador MUST poder chegar como **push nativo** (FCM/APNs), coerente com `comunicacao-mobile`.

#### Scenario: Acesso com pré-autorização
- **GIVEN** um morador que pré-autorizou um visitante para uma data
- **WHEN** o porteiro consulta a pré-autorização válida na chegada
- **THEN** o app mostra o acesso liberado, referenciando a pré-autorização

#### Scenario: Confirmação na chegada
- **GIVEN** um visitante sem pré-autorização
- **WHEN** o porteiro solicita confirmação e o morador confirma (ex.: ao tocar o push e confirmar no app)
- **THEN** o app libera o acesso referenciando a confirmação do morador

#### Scenario: Acesso negado
- **GIVEN** um visitante sem pré-autorização cujo morador recusa ou não responde
- **WHEN** o porteiro tenta liberar
- **THEN** o app não libera o acesso e registra a tentativa como `negada`

### Requirement: Gestão de encomendas com foto
O app mobile MUST permitir ao porteiro registrar o recebimento de encomendas (unidade de destino, remetente e **foto da encomenda/etiqueta capturada pela câmera** ou selecionada da galeria), notificar o morador (via Comunicação, incl. push nativo) e registrar a retirada (quem retirou e data/hora), refletindo o status "recebida" → "retirada". O app MUST solicitar a permissão de câmera/galeria quando necessária e tratar a negação sem travar o registro.

#### Scenario: Registrar encomenda com foto e notificar
- **GIVEN** um porteiro recebendo uma encomenda, com permissão de câmera concedida
- **WHEN** ele registra a encomenda com unidade de destino e captura a foto pela câmera
- **THEN** o app confirma o registro com a foto anexada e indica que o morador foi notificado (incl. push)

#### Scenario: Foto da galeria como alternativa
- **GIVEN** um porteiro registrando uma encomenda sem usar a câmera
- **WHEN** ele seleciona uma imagem da galeria como foto da encomenda
- **THEN** o app anexa a imagem ao registro da encomenda

#### Scenario: Registrar retirada
- **GIVEN** uma encomenda registrada e não retirada
- **WHEN** o porteiro registra a retirada com a identificação de quem retirou
- **THEN** o app grava quem retirou e a data/hora e marca a encomenda como "retirada"

#### Scenario: Permissão de câmera negada no registro de encomenda
- **GIVEN** um porteiro que nega a permissão de câmera
- **WHEN** ele registra a encomenda
- **THEN** o app permite concluir o registro (foto opcional ou via galeria) sem travar o fluxo

### Requirement: Histórico auditável de acessos e encomendas
O app mobile MUST oferecer à gestão a consulta do histórico de acessos e encomendas filtrável por unidade e por período, restrito ao condomínio ativo, com paginação, e MUST não exibir registros de outro condomínio.

#### Scenario: Consultar histórico por unidade e período
- **GIVEN** um condomínio com registros de acesso
- **WHEN** o gestor filtra por uma unidade e um período
- **THEN** o app lista os acessos e encomendas daquela unidade no período

#### Scenario: Isolamento do histórico
- **GIVEN** registros do condomínio A
- **WHEN** um usuário do condomínio B consulta o histórico
- **THEN** os registros do condomínio A não são exibidos
