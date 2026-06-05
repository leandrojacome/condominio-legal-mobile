# Condominio Legal Mobile Design

Fonte viva de UX e design system do app mobile React Native bare do Condominio Legal. Este documento traduz a change OpenSpec `openspec/changes/condominio-mobile-scope` em arquitetura de informacao, fluxos e especificacoes de interacao para implementacao.

## Principios

- **Mobile primeiro, tarefa primeiro.** Cada tela deve expor a proxima acao provavel do perfil ativo, evitando dashboards genericos. Lentes: Hick's Law, Pareto, Progressive Disclosure.
- **Permissao como modelo mental.** A UI deve ocultar acoes indisponiveis por perfil, mas sempre tratar `403` com mensagem de "sem permissao" sem vazar dados. Lentes: Nielsen - error prevention, Postel's Law, WCAG POUR.
- **Listas previsiveis.** Modulos operacionais usam lista -> detalhe -> acao contextual. Lentes: Jakob's Law, Recognition over Recall, F-pattern.
- **Feedback rapido.** Toques em acoes sensiveis entram em loading em ate 100ms, bloqueiam envio duplicado e usam idempotencia na camada de servicos. Lentes: Doherty Threshold, Fitts's Law, Forgiveness.
- **Acessibilidade como restricao.** Alvos minimos de 44x44 pt, contraste AA, sem depender apenas de cor para status, texto claro em portugues brasileiro. Lentes: WCAG POUR, Inclusive Design.

## Tokens

Todos os estilos devem vir destes tokens. Se um caso exigir outro valor, proponha mudanca neste documento antes de implementar.

### Cor

- `color.bg.app`: `#F6F7F9`
- `color.bg.surface`: `#FFFFFF`
- `color.bg.subtle`: `#EEF2F6`
- `color.text.primary`: `#17202A`
- `color.text.secondary`: `#5C6672`
- `color.text.inverse`: `#FFFFFF`
- `color.border.default`: `#D8DEE6`
- `color.brand.primary`: `#166A5B`
- `color.brand.primaryPressed`: `#0F4F44`
- `color.brand.soft`: `#E7F4F1`
- `color.action.info`: `#1D5FBF`
- `color.feedback.success`: `#147A3D`
- `color.feedback.warning`: `#A15C00`
- `color.feedback.danger`: `#B42318`
- `color.status.neutral`: `#64748B`

Status nunca deve depender so de cor: sempre combinar texto, icone e/ou badge.

### Tipografia

- `font.family.base`: fonte nativa do sistema.
- `text.title`: 24/32, weight 700.
- `text.section`: 18/26, weight 700.
- `text.body`: 16/24, weight 400.
- `text.bodyStrong`: 16/24, weight 600.
- `text.meta`: 14/20, weight 400.
- `text.caption`: 12/16, weight 500.

### Espacamento, raio e elevacao

- `space-1`: 4
- `space-2`: 8
- `space-3`: 12
- `space-4`: 16
- `space-5`: 20
- `space-6`: 24
- `space-8`: 32
- `radius-sm`: 6
- `radius-md`: 8
- `radius-lg`: 12, somente para bottom sheets e banners.
- `shadow-surface`: sombra leve para header/bottom sheet; cards de lista usam borda, nao sombra pesada.

### Movimento

- `motion.fast`: 120ms, feedback de toque e entrada de snackbar.
- `motion.base`: 200ms, transicao de sheet/modal.
- `motion.slow`: 300ms, somente mudanca de estado maior.
- Respeitar reduced motion: substituir deslocamentos por fade curto.

## Componentes

- `AppShell`: guarda de sessao, restauracao de token, deep link router e montagem de stacks/tabs por perfil.
- `TopBar`: titulo da area atual, seletor de condominio quando houver multiplos vinculos, menu de conta. Altura 56.
- `BottomTabs`: ate 5 destinos primarios por perfil. Quando houver mais, usar tab `Mais`.
- `ModuleListScreen`: padrao de lista com `TopBar`, filtros compactos, `FlatList`, pull-to-refresh, paginacao por cursor e estados de loading/erro/vazio.
- `EntityCard`: item de lista com titulo, metadados, status badge e acao principal de toque no card.
- `StatusBadge`: variante `neutral`, `info`, `success`, `warning`, `danger`; sempre incluir label textual.
- `PrimaryButton`, `SecondaryButton`, `DestructiveButton`, `IconButton`: alvos minimos 44x44, estado loading e disabled.
- `FormField`: label persistente, ajuda opcional, erro inline, mascara quando aplicavel (CPF, telefone, moeda, competencia).
- `SelectField`: bottom sheet com busca quando a lista tiver mais de 7 opcoes. Lente: Miller's Law.
- `DateTimeField`: seletor nativo, com resumo textual antes de confirmar.
- `BottomSheet`: escolhas de baixo risco e seletores; nao usar para confirmacao destrutiva.
- `ConfirmDialog`: confirmacoes destrutivas ou irreversiveis, com acao primaria explicita e acao de cancelar.
- `Snackbar`: sucesso/erro nao bloqueante, duracao 4s, uma linha principal e acao opcional.
- `EmptyState`: icone simples, titulo orientado a tarefa, corpo curto e CTA quando o perfil puder criar.
- `ErrorState`: mensagem clara, codigo opcional em detalhe recolhido, botao `Tentar novamente`.
- `PermissionState`: explica a permissao negada e oferece alternativa ou atalho para ajustes quando aplicavel.
- `UploadRow`: miniatura, nome, progresso, status, retry e remover.
- `FAB`: permitido somente para acao principal de criacao em listas de gestao; evitar mais de um FAB por tela.

## Arquitetura De Informacao

### Estrutura Global

1. `AuthStack`: login, recuperacao de senha (se backend/Supabase estiver habilitado), sessao expirada.
2. `TenantSwitch`: sheet acionada pelo `TopBar` para usuarios multi-vinculo; nao renderizar para vinculo unico.
3. `ProtectedTabs`: tabs por perfil, cada tab aponta para um stack de modulo.
4. `MoreStack`: modulo secundario, configuracoes, conta, logout e termos.
5. `DeepLinkRouter`: push abre rota protegida; sem sessao, guarda o destino e abre apos login.

### Tabs Por Perfil

| Perfil | Tabs primarias | Em `Mais` |
| --- | --- | --- |
| `sindico` | Inicio, Comunicacao, Financeiro, Ocorrencias, Mais | Cadastro, Reservas, Assembleias, Portaria, Configuracoes |
| `administradora` | Inicio, Cadastro, Financeiro, Comunicacao, Mais | Reservas, Assembleias, Ocorrencias, Portaria, Configuracoes |
| `proprietario` | Inicio, Comunicados, Financeiro, Reservas, Mais | Assembleias, Ocorrencias, Portaria/Visitantes, Conta |
| `inquilino` | Inicio, Comunicados, Reservas, Ocorrencias, Mais | Financeiro quando responsavel, Assembleias quando elegivel, Visitantes, Conta |
| `porteiro` | Portaria, Encomendas, Comunicados, Ocorrencias, Mais | Historico, Conta |
| `conselho` | Inicio, Financeiro, Comunicacao, Assembleias, Mais | Ocorrencias, Reservas, Conta |

`Inicio` deve ser uma lista de pendencias e atalhos por perfil, nao um painel cheio: proximas votacoes, cobrancas em aberto, reservas pendentes, ocorrencias atrasadas, encomendas, comunicados nao lidos.

## Estados Transversais

- Loading inicial: skeleton de lista ou formulario; spinner apenas para acoes locais curtas.
- Loading de acao: botao com spinner, label preservado quando couber, demais campos bloqueados somente se a acao depender deles.
- Erro recuperavel (`500`, rede): `ErrorState` com `Tentar novamente`; manter navegacao.
- Validacao (`400`): erro inline por campo quando `details` mapear campo; snackbar apenas para resumo.
- Regra de negocio (`422`): mensagem perto da acao bloqueada e snackbar curto.
- Conflito (`409`): preservar dados do formulario e indicar item conflitado.
- Nao autenticado (`401`): tentar refresh; se falhar, limpar sessao e abrir login com aviso "Sua sessao expirou".
- Sem permissao (`403`): `PermissionState` sem dados do recurso.
- Vazio: `EmptyState` com CTA somente se o perfil pode criar; caso contrario, texto de leitura.
- Sucesso: `Snackbar` e atualizacao otimista quando reversivel; para acoes irreversiveis, esperar resposta.
- Pull-to-refresh: atualizar do cursor inicial; preservar scroll quando possivel.
- Paginacao: `ListFooterLoading`; quando `nextCursor` for nulo, nao exibir botao morto.
- Offline/rede indisponivel: banner discreto no topo da lista e estado de erro em novas cargas.

## Fluxos De Fundacao

### Login E Sessao

Tela: `LoginScreen`

- Campos: e-mail, senha, botao `Entrar`.
- Erro de credenciais: manter e-mail, limpar senha, foco retorna para senha.
- Envio: `PrimaryButton` loading e disabled para evitar duplo toque.
- Sucesso: `AppShell` monta tabs pelo `perfil` do token.
- Sessao restaurada: splash leve com texto "Entrando..." por ate o tempo necessario da restauracao; se falhar, login.

### Troca De Condominio

Tela: `TenantSwitcherSheet`

- Entrada pelo nome do condominio no `TopBar`.
- Lista de condominios do usuario com busca quando houver mais de 7.
- Ao selecionar: sheet fecha apos token reemitido; telas mostram skeleton e recarregam no novo contexto.
- Falha: manter condominio anterior e exibir erro recuperavel.

### Push E Deep Link

Tela/estado: `NotificationOptInPrompt`

- Pedir permissao no primeiro momento de valor, nao no primeiro launch: apos login, quando o usuario acessa Comunicacao, Financeiro, Portaria ou Ocorrencias pela primeira vez.
- Negado: registrar estado e oferecer ativacao em Configuracoes; nao bloquear o modulo.
- Push recebido: abrir rota especifica (`comunicado`, `cobranca`, `ocorrencia`, `confirmacao_acesso`, `encomenda`) via `DeepLinkRouter`.

### Camera, Galeria E Upload

- Ao anexar, abrir `BottomSheet` com Camera e Galeria.
- Permissao negada de camera: `PermissionState` inline e alternativa Galeria.
- Upload: `UploadRow` com progresso, retry e remover. Falha preserva comentario/formulario.
- Nao assumir foto obrigatoria quando OpenSpec permite alternativa ou opcionalidade.

## Modulos

### Cadastro

Perfis: criacao/edicao para `sindico`, `administradora`; leitura para moradores quando exposto.

Telas:

- `CadastroHome`: atalhos Condominio, Unidades, Pessoas, Vinculos.
- `CondominioDetailForm`: nome, endereco, blocos/torres.
- `UnidadesList` + `UnidadeForm`: tipo, bloco/torre, numero.
- `PessoasList` + `PessoaForm`: nome, CPF, e-mail, telefone.
- `VinculosScreen`: busca pessoa/unidade e papel.

Decisoes:

- Formularios em coluna unica. Lentes: Formulários e erros, Cognitive Load.
- Duplicidade `409` deve aparecer junto aos campos de identificacao, nao so em toast.
- Seletores de tipo/papel devem listar apenas valores permitidos.

### Financeiro

Perfis: gestao para `sindico`, `administradora`, `conselho` conforme permissao; moradores veem suas cobrancas.

Telas:

- `CobrancasList`: filtros por status/tipo/competencia.
- `CobrancaDetail`: devedor/responsavel, valor, status, metodos.
- `CobrancaForm`: tipo, competencia, valor, responsavel.
- `RateioPreview`: tabela mobile por unidade, total fixo no rodape, confirmacao.
- `PagamentoArtifacts`: boleto/Pix com copiar/compartilhar.
- `InadimplentesList`: valor atualizado, dias em atraso, acao notificar.

Decisoes:

- Valores monetarios alinhados a direita em cards e listas.
- Boleto/Pix exigem feedback de copiar. Lente: Feedback, Recognition over Recall.
- Notificar cobranca usa `ConfirmDialog` para evitar envio acidental. Lente: Forgiveness.

### Comunicacao

Perfis: leitura para todos; publicar para `sindico`, `administradora`, e `porteiro` em aviso individual conforme spec.

Telas:

- `FeedComunicados`: cards por tipo, leitura pendente destacada.
- `ComunicadoDetail`: conteudo, anexos se houver, confirmar ciencia.
- `ComunicadoCompose`: tipo, publico-alvo, titulo, corpo, canais.
- `DeliveryStatus`: status por canal e pendencias de leitura.

Decisoes:

- Comunicados nao lidos usam badge textual e posicao no topo; nao depender apenas de cor.
- Confirmar ciencia deve ser botao fixo no rodape do detalhe quando pendente.
- Falha de canal deve ser apresentada como parcial, preservando sucesso dos demais. Lente: Nielsen - visibility of system status.

### Reservas

Perfis: moradores solicitam/cancelam; gestao configura areas e aprova.

Telas:

- `AreasCatalog`: lista de areas com granularidade, taxa e modo.
- `AreaAvailability`: calendario/turno/horario conforme granularidade.
- `ReservaReview`: resumo, taxa, regras e confirmacao.
- `MinhasReservas`: status e cancelamento.
- `ReservasPendentes`: fila de aprovacao para gestao.
- `AreaConfigForm`: configuracao da area.

Decisoes:

- Periodos indisponiveis devem ser desabilitados, nao apenas marcados.
- Taxa/penalidade aparece antes da confirmacao. Lentes: Loss Aversion, Ethics.
- Recusa com motivo opcional em sheet; se informado, morador ve no detalhe.

### Assembleias E Votacoes

Perfis: gestao convoca/apura; proprietario/inquilino/conselho votam quando elegiveis.

Telas:

- `AssembleiasList`: proximas, em votacao, encerradas.
- `AssembleiaDetail`: pauta, status, documentos/ata quando disponivel.
- `ConvocacaoForm`: data/hora, local, itens de pauta.
- `VotingBooth`: um item por passo, resumo final e confirmacao.
- `ResultadosAta`: quorum, resultado por item, baixar/compartilhar ata.

Decisoes:

- Cabine de votacao usa fluxo passo-a-passo para reduzir erro. Lentes: Working Memory, Goal-Gradient.
- Voto secreto nunca mostra identidade associada a opcao; usar texto "Voto secreto registrado".
- Bloqueio por inadimplencia deve explicar motivo sem expor detalhes financeiros alem do necessario.

### Ocorrencias E Manutencao

Perfis: todos abrem; gestao/portaria/responsaveis acompanham e transicionam conforme permissao.

Telas:

- `OcorrenciasList`: filtros por status, prioridade, SLA.
- `OcorrenciaForm`: tipo, titulo, descricao, anexos.
- `OcorrenciaDetail`: status, responsavel, SLA, historico, comentarios, anexos.
- `StatusTransitionSheet`: somente transicoes validas.
- `AvaliacaoAtendimento`: disponivel apenas encerrada.

Decisoes:

- SLA estourado usa badge `danger`, icone e texto "SLA estourado".
- Historico cronologico deve separar comentario, mudanca de status e anexo por icones/labels.
- Avaliacao nao renderiza antes do encerramento; se `422`, explicar que a ocorrencia ainda nao foi encerrada.

### Portaria E Acessos

Perfis: `porteiro` operacional; gestao consulta historico; moradores pre-autorizam e confirmam.

Telas:

- `PortariaToday`: acessos em aberto, pre-autorizacoes do dia, acoes rapidas.
- `AcessoForm`: tipo, identificacao, unidade, autorizador.
- `ConfirmacaoMorador`: confirmar/negar chegada via deep link.
- `EncomendasList`: recebidas/retiradas.
- `EncomendaForm`: unidade, remetente, foto opcional/galeria, notificar.
- `HistoricoPortaria`: filtros por unidade/periodo, paginacao.

Decisoes:

- Porteiro precisa de alvos grandes e poucos campos por etapa. Lentes: Thumb zones, Fitts's Law, Paradox of the Active User.
- Liberacao sem autorizacao valida deve ser bloqueada por constraint visual e confirmacao explicita.
- Registro de saida/retirada deve estar na linha do item aberto, sem procurar em menu secundario.

## Handoff Para Dev Mobile

- Implementar navegacao conforme `Tabs Por Perfil`; qualquer diferenca deve voltar para UX/Chefe antes de construir.
- Toda tela de lista deve usar `ModuleListScreen`, `EntityCard`, `EmptyState`, `ErrorState`, pull-to-refresh e paginacao por cursor.
- Toda tela de formulario deve usar `FormField`, `SelectField`, validacao inline e preservar dados apos erro `400`, `409` ou `422`.
- A camada de UI nunca envia `condominioId` manual. O contexto visual do condominio vem do token/sessao e do seletor multi-vinculo.
- Acoes sensiveis devem usar botao loading + idempotencia no service: criar cobranca, emitir boleto/Pix, confirmar voto, aprovar/recusar reserva, notificar cobranca, registrar acesso, confirmar/recusar acesso, registrar encomenda.
- Push, camera/galeria, upload e deep links devem implementar os estados definidos em `Fluxos De Fundacao`.

## Handoff Para QA

Validar em viewports reais mobile equivalentes a 390x844 e, quando houver tablet/simulador maior, ao menos 768x1024. Cobrir:

- Login valido/invalido, sessao restaurada, refresh transparente e sessao expirada.
- Navegacao por cada um dos 6 perfis, incluindo acoes ocultas e `403`.
- Troca de condominio para multi-vinculo e ausencia do seletor para vinculo unico.
- Estados loading, erro, vazio, sucesso, pull-to-refresh e paginacao em ao menos uma lista por modulo.
- Push opt-in negado/concedido e deep links para comunicado, cobranca, ocorrencia, confirmacao de acesso e encomenda.
- Camera/galeria negada/concedida e upload com progresso, erro e retry.
- Cada requisito OpenSpec das 9 capacidades deve ter teste rastreavel.

## Lacunas De Produto

Estas lacunas nao bloqueiam a implementacao de IA/base, mas devem ser decididas pelo Chefe/BA antes de telas finais ou regras de negocio finas:

- Recuperacao de senha no mobile: habilitar no primeiro release ou deixar fora do AuthStack?
- Grau de permissao do `conselho` em Financeiro e Comunicacao: leitura, aprovacao ou acoes operacionais?
- Foto em encomenda: obrigatoria por regra do condominio ou opcional por padrao? A spec permite alternativa sem travar quando camera negada.
- Push opt-in: texto legal/privacidade padrao da empresa ainda nao definido.
- Nomes finais de labels: "Comunicados" vs "Comunicacao", "Portaria" vs "Acessos" devem ser validados em produto antes de UI final.

