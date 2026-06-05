## ADDED Requirements

### Requirement: Tela de cobranças por tipo
O app mobile MUST oferecer, para perfis de gestão (`sindico`, `administradora`), uma tela para registrar e listar cobranças com `tipo` restrito a `taxa_mensal`, `fundo_reserva`, `extra_rateio`, `multa_juros`, `consumo`, informando valor, competência (mês/ano) e vencimento, exibindo o status (`em_aberto`, `paga`, `em_atraso`). A lista de gestão MUST exibir, por cobrança, o devedor/responsável (unidade e pessoa responsável), espelhando o backend F3: quando não houver `responsavel_financeiro`/`inquilino` designado, o app MUST apresentar o `proprietario` da unidade como responsável (fallback). Moradores (`proprietario`, `inquilino`, `responsavel_financeiro`) MUST ver apenas as cobranças sob sua responsabilidade.

#### Scenario: Registrar taxa mensal
- **GIVEN** um gestor na tela de nova cobrança
- **WHEN** ele seleciona `taxa_mensal`, informa valor, competência e vencimento válidos e salva
- **THEN** a cobrança é criada com status `em_aberto` e aparece na listagem da unidade

#### Scenario: Competência em formato inválido
- **GIVEN** o formulário de cobrança
- **WHEN** o gestor informa competência fora do formato AAAA-MM e o backend responde 400
- **THEN** o app destaca o campo competência com a mensagem de formato

#### Scenario: Morador vê apenas as suas cobranças
- **GIVEN** um usuário responsável financeiro de uma unidade
- **WHEN** ele abre a tela financeira
- **THEN** vê somente as cobranças sob sua responsabilidade, com status e valor, sem ações de gestão

#### Scenario: Lista de gestão exibe o devedor/responsável
- **GIVEN** um gestor na listagem de cobranças, com uma cobrança cuja unidade tem `responsavel_financeiro` designado e outra cuja unidade não tem responsável financeiro nem inquilino
- **WHEN** ele visualiza a lista
- **THEN** cada cobrança exibe a unidade e a pessoa responsável; na cobrança com responsável financeiro designado, exibe esse responsável; na cobrança sem responsável designado, exibe o `proprietario` da unidade como responsável (fallback), espelhando o backend F3

### Requirement: Tela de rateio de despesas
O app mobile MUST permitir ao gestor ratear uma despesa entre as unidades por critério `fracao_ideal` ou `igual`, exibindo uma prévia das parcelas geradas por unidade e o total, antes de confirmar, evidenciando que a soma das parcelas é igual ao valor total.

#### Scenario: Prévia de rateio por fração ideal
- **GIVEN** uma despesa de R$ 1.000,00 e unidades com frações distintas
- **WHEN** o gestor escolhe `fracao_ideal`
- **THEN** o app mostra a prévia proporcional por unidade e confirma que a soma é R$ 1.000,00 antes de gerar

#### Scenario: Prévia de rateio igualitário
- **GIVEN** uma despesa de R$ 1.000,00 e 10 unidades
- **WHEN** o gestor escolhe `igual`
- **THEN** o app mostra 10 parcelas de R$ 100,00 antes de confirmar

### Requirement: Emissão e acompanhamento de boleto e Pix
O app mobile MUST permitir emitir boleto e/ou Pix para uma cobrança `em_aberto` e exibir os artefatos retornados: linha digitável/nosso número (boleto, com ação de copiar/compartilhar) e QR Code/copia-e-cola/identificador (Pix, com ação de copiar). O app MUST refletir o estado de conciliação (passando a `paga` quando confirmada por qualquer método) e MUST indicar que, paga por um método, o outro deixa de ser pagável. Falha de emissão MUST manter a cobrança `em_aberto` com opção de tentar novamente (com idempotência).

#### Scenario: Emitir boleto com sucesso
- **GIVEN** uma cobrança `em_aberto`
- **WHEN** o gestor emite o boleto e a integração retorna sucesso
- **THEN** o app exibe a linha digitável e o nosso número e oferece copiar/compartilhar

#### Scenario: Emitir Pix com sucesso
- **GIVEN** uma cobrança `em_aberto`
- **WHEN** o gestor solicita a cobrança Pix com sucesso
- **THEN** o app exibe o QR Code e o copia-e-cola com ação de copiar

#### Scenario: Pagamento confirmado encerra os demais métodos
- **GIVEN** uma cobrança com boleto e Pix emitidos
- **WHEN** a conciliação confirma o pagamento por Pix
- **THEN** o app marca a cobrança como `paga` (data/valor/método) e sinaliza o boleto como não mais pagável

#### Scenario: Falha na emissão
- **GIVEN** uma cobrança `em_aberto`
- **WHEN** a integração retorna erro na emissão (ex.: 422/500)
- **THEN** o app mantém o status `em_aberto`, exibe o erro e oferece tentar novamente sem duplicar a emissão (idempotência)

### Requirement: Inadimplência e notificação de cobrança
O app mobile MUST exibir, para a gestão, a relação de inadimplentes (unidades/pessoas em atraso com valor devido, incluindo multa e juros quando aplicável) e MUST permitir disparar a notificação de cobrança ao responsável, com confirmação do envio. A notificação de cobrança ao morador MUST ser entregável também por **push nativo** (FCM/APNs) como canal, coerente com `comunicacao-mobile`.

#### Scenario: Relatório de inadimplentes
- **GIVEN** um condomínio com cobranças `em_atraso`
- **WHEN** o gestor abre o relatório de inadimplentes
- **THEN** o app lista as unidades/pessoas em atraso com o valor atualizado devido

#### Scenario: Disparar notificação de cobrança
- **GIVEN** uma cobrança `em_atraso` na listagem
- **WHEN** o gestor aciona "Notificar cobrança"
- **THEN** o app confirma o envio da notificação ao responsável e registra o feedback de sucesso

#### Scenario: Morador recebe notificação de cobrança por push
- **GIVEN** um morador responsável com push habilitado no dispositivo
- **WHEN** a gestão dispara a notificação de cobrança
- **THEN** o morador recebe uma notificação push nativa (FCM/APNs) e, ao tocá-la, o app abre a cobrança correspondente

#### Scenario: Relatório vazio
- **GIVEN** um condomínio sem cobranças em atraso
- **WHEN** o gestor abre o relatório de inadimplentes
- **THEN** o app exibe estado vazio informando que não há inadimplentes
