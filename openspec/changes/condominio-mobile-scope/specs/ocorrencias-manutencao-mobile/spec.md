## ADDED Requirements

### Requirement: Abertura de ocorrência por tipo
O app mobile MUST permitir que qualquer morador (`proprietario`, `inquilino`, `morador`) e a gestão/portaria (`sindico`, `administradora`, `porteiro`) abram ocorrências com `tipo` restrito a `manutencao`, `reclamacao`, `sugestao`, `seguranca`, `achados`, informando título e descrição, com o tipo limitado na UI aos valores permitidos.

#### Scenario: Morador abre ocorrência de manutenção
- **GIVEN** um morador autenticado na tela de nova ocorrência
- **WHEN** ele seleciona `manutencao`, informa título e descrição e envia
- **THEN** a ocorrência é criada no status inicial do fluxo do condomínio, vinculada ao autor, e aparece na sua lista

#### Scenario: Tipo limitado na UI
- **GIVEN** o formulário de ocorrência
- **WHEN** o usuário abre o seletor de tipo
- **THEN** apenas os tipos permitidos são oferecidos, impedindo envio de tipo inválido

#### Scenario: Campos obrigatórios
- **GIVEN** o formulário sem título
- **WHEN** o usuário tenta enviar
- **THEN** a validação de cliente impede o envio e destaca o campo título

### Requirement: Acompanhamento por status configurável
O app mobile MUST exibir as ocorrências em uma visão por status (lista/agrupamento por status) refletindo o fluxo configurado pelo condomínio, e MUST oferecer apenas as transições válidas para o responsável, tratando recusa de transição inválida (422) com feedback.

> **Nota (backend O5 — notificação do autor):** o disparo da notificação ao autor a cada atualização de status é orquestrado server-side e NÃO constitui funcionalidade dedicada nesta tela de ocorrências (N/A na tela de ocorrências). A entrega ao autor é consumida no mural/feed e no status de entrega multicanal definidos em `comunicacao-mobile` (canais `in_app` e `push`). A tela de ocorrências apenas reflete o histórico de mudanças de status (ver "Anexos e histórico de comentários"); a visibilidade da notificação ao autor é coberta pelo cenário abaixo via `comunicacao-mobile`.

#### Scenario: Transição válida disponível
- **GIVEN** um condomínio cujo fluxo permite `aberta → em_andamento`
- **WHEN** o responsável abre uma ocorrência `aberta`
- **THEN** a ação de mover para `em_andamento` está disponível e, ao acionar, atualiza o status

#### Scenario: Transição inválida bloqueada
- **GIVEN** um fluxo que não permite `aberta → fechada` diretamente
- **WHEN** o responsável tenta essa transição e o backend responde 422
- **THEN** o app recusa a mudança e informa que a transição não é permitida pelo fluxo

#### Scenario: Autor é notificado da atualização via mural/push (backend O5)
- **GIVEN** uma ocorrência cujo autor é um morador e cujo status foi atualizado pelo responsável
- **WHEN** o backend orquestra a notificação ao autor (O5)
- **THEN** a notificação é entregue pelos canais `in_app`/`push` e fica visível ao autor no mural/feed de `comunicacao-mobile`, sem exigir uma funcionalidade de notificação dedicada na tela de ocorrências (N/A na tela de ocorrências)

### Requirement: Atribuição, prioridade e SLA
O app mobile MUST permitir à gestão atribuir a ocorrência a um responsável, definir prioridade e SLA, e MUST sinalizar visualmente quando o SLA está estourado.

#### Scenario: Atribuir responsável e prioridade
- **GIVEN** uma ocorrência aberta
- **WHEN** o gestor a atribui a um responsável com prioridade `alta` e SLA de 24h
- **THEN** o app passa a exibir responsável, prioridade e prazo na ocorrência

#### Scenario: SLA estourado sinalizado
- **GIVEN** uma ocorrência com SLA vencido sem resolução
- **WHEN** o gestor visualiza a lista
- **THEN** a ocorrência aparece destacada como "SLA estourado"

### Requirement: Anexos via câmera/galeria e histórico de comentários
O app mobile MUST permitir anexar imagens a uma ocorrência **capturando foto pela câmera do dispositivo ou selecionando da galeria**, e adicionar comentários, exibindo o histórico cronológico de comentários e mudanças de status com autor e data. O app MUST solicitar a permissão de câmera/galeria quando necessária e tratar a negação sem travar; o upload MUST exibir estados de progresso e erro (com opção de tentar novamente).

#### Scenario: Anexar foto pela câmera
- **GIVEN** uma ocorrência existente e permissão de câmera concedida
- **WHEN** o autor captura uma foto pela câmera e anexa
- **THEN** o app mostra progresso de upload e, ao concluir, o anexo fica disponível na ocorrência

#### Scenario: Anexar imagem da galeria
- **GIVEN** uma ocorrência existente
- **WHEN** o autor seleciona uma imagem existente da galeria e anexa
- **THEN** o app envia a imagem com progresso e, ao concluir, o anexo fica disponível na ocorrência

#### Scenario: Permissão de câmera negada
- **GIVEN** um usuário que nega a permissão de câmera
- **WHEN** ele tenta anexar capturando uma foto
- **THEN** o app informa que a permissão é necessária e oferece a alternativa de selecionar da galeria, sem travar o fluxo

#### Scenario: Comentar andamento
- **GIVEN** uma ocorrência em andamento
- **WHEN** o responsável adiciona um comentário
- **THEN** o comentário aparece no histórico com autor e data

### Requirement: Avaliação ao encerrar
O app mobile MUST permitir que o autor avalie o atendimento somente quando a ocorrência estiver encerrada, ocultando/bloqueando a avaliação enquanto não encerrada (recusa 422 do backend tratada na UI).

#### Scenario: Avaliar atendimento encerrado
- **GIVEN** uma ocorrência em status de encerramento
- **WHEN** o autor registra uma avaliação
- **THEN** o app persiste a avaliação vinculada à ocorrência e confirma o sucesso

#### Scenario: Avaliação indisponível antes do encerramento
- **GIVEN** uma ocorrência ainda em andamento
- **WHEN** o autor abre a ocorrência
- **THEN** a ação de avaliar não está disponível
