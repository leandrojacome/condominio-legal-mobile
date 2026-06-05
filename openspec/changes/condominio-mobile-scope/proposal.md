## Why

O board já aprovou e o BA consolidou as specs do **backend** (`condominio-backend-scope`: 7 capacidades, 39 requisitos `MUST` testáveis, contrato REST/JSON = fonte da verdade) e do **frontend web** (`condominio-frontend-scope`: 9 capacidades). O board agora decidiu levar o **Condomínio Legal** para um **app mobile React Native**. Falta especificar o **mobile** em total sintonia com esse backend e com a paridade de comportamento do web, antes do design (UXDesigner) e da implementação (Dev Mobile, Fase 2).

Este change abre o escopo **mobile** e deriva, para cada módulo e perfil, as especificações de: (1) **telas/fluxos** por módulo e perfil, (2) **comportamento da tela** (estados loading/erro/vazio/sucesso adaptados a mobile, validações, navegação por perfil, permissões) e (3) **camada de serviços** que consome o contrato REST/JSON do backend. Escopo desta fase = **somente specs OpenSpec do mobile** (UI / comportamento / camada de consumo da API). **Nenhum código** é implementado aqui.

## What Changes

Derivamos as specs mobile 1:1 a partir das 7 capacidades do backend, mais duas capacidades transversais (acesso/perfis e camada de serviços), espelhando as 9 capacidades do web com sufixo `-mobile`. Cada spec de módulo cobre telas + comportamento + permissões por perfil; a camada de serviços é especificada uma vez, de forma transversal, mapeando os endpoints do contrato backend. Toda regra de negócio do backend mantém **cobertura observável** no mobile.

### Decisões herdadas (fonte da verdade — não reabrir)
- **Multi-tenant:** `condominioId` nos claims do JWT. O app **nunca** envia tenant arbitrário (sem campo manual, sem header de tenant) — o tenant viaja exclusivamente no token. Acesso cross-tenant → backend responde **403**, e o app trata como "sem acesso".
- **6 perfis:** `sindico`, `administradora`, `proprietario`, `inquilino`, `porteiro`, `conselho`. A navegação (stack/tabs) e as ações visíveis variam por perfil.
- **AuthN — Supabase Auth:** login/sessão/refresh pelo cliente Supabase; o **`access_token` JWT do Supabase** carrega os claims de aplicação `{ sub, condominioId, perfil, vinculoId? }`. O app anexa o `access_token` (Bearer) às chamadas ao backend; o `refresh_token` renova a sessão de forma transparente; falha de refresh = sessão encerrada. A spec é **agnóstica ao shape interno** do JWT.
- **Erros padronizados:** `{ code, message, details }` com HTTP `400` (validação), `401` (não autenticado), `403` (sem permissão/cross-tenant), `404` (não encontrado), `409` (conflito), `422` (regra de negócio), `500` (interno). O app mapeia cada status para um estado/feedback específico.
- **Paginação:** cursor-based (`?cursor=&limit=`) por padrão; offset apenas em relatórios estáticos (ex.: inadimplentes).

### Concerns transversais mobile (embutidos nas capacidades)
- **Armazenamento seguro de token:** sessão/tokens guardados no **Keychain (iOS) / Keystore (Android)**, nunca em armazenamento em texto puro.
- **Navegação por perfil:** stack/tabs montados conforme o `perfil`; guarda de navegação exige sessão válida; render condicional de ações por perfil.
- **Estados de tela mobile:** loading/erro/vazio/sucesso adaptados a mobile (skeletons, pull-to-refresh, toasts/snackbars, retry).
- **Push nativo:** **FCM (Android) / APNs (iOS)** como canal de `comunicacao` e de notificações de cobrança/encomenda.
- **Câmera/galeria:** captura/seleção de imagem para anexos em `ocorrencias-manutencao` e foto de encomenda em `portaria-acessos`.
- **Isolamento multi-tenant** e **autorização por perfil** presentes em todas as capacidades.

### Restrição de plataforma (board)
O app roda em **React Native bare (CLI), SEM Expo**. As specs de fundação refletem execução simples na máquina do dev (`npm install` + `npx react-native run-android` / `run-ios`), sem dependência de Expo. Nenhuma spec pressupõe Expo (push, câmera, secure storage e navegação são descritos por **comportamento observável**, não por SDK específico).

## Capabilities

### New Capabilities (mobile)
- `acesso-perfis-mobile` *(transversal)*: login multi-tenant via Supabase Auth, sessão/refresh transparente, **armazenamento seguro de token** (Keychain/Keystore), guarda de navegação, render condicional por perfil e troca de condomínio (multi-vínculo).
- `camada-servicos-api-mobile` *(transversal)*: clients tipados por endpoint do contrato, anexação automática de token/tenant, tratamento padronizado do envelope de erro, paginação por cursor e idempotência em ações sensíveis. Nenhuma tela chama `fetch` direto.
- `cadastro-mobile`: telas de condomínio, unidades, pessoas e vínculos.
- `financeiro-mobile`: cobranças por tipo, rateio, emissão boleto/Pix, conciliação, inadimplência e notificação de cobrança (com push nativo).
- `comunicacao-mobile`: mural/feed, publicação por tipo/perfil, entrega multicanal (incl. **push nativo**), confirmação de leitura.
- `reservas-areas-comuns-mobile`: catálogo, disponibilidade, fluxo de reserva, aprovação, bloqueios de regra, taxa e cancelamento.
- `assembleias-votacoes-mobile`: convocação, pauta, cabine de votação (incl. secreta/procuração), apuração e ata.
- `ocorrencias-manutencao-mobile`: abertura por tipo, acompanhamento por status, atribuição/SLA, **anexos via câmera/galeria**, comentários e avaliação.
- `portaria-acessos-mobile`: registro de acesso, pré-autorização/confirmação do morador, encomendas (com **foto via câmera**) e histórico auditável.

### Out of scope (mobile, 1ª versão)
- `documentos` (adiado no backend, idem aqui).
- **Implementação de código** (Fase 2 — Dev Mobile, após o board aprovar estas specs).
- ARD detalhado de stack/build/navegação (Fase 2, com o Dev Mobile).
- UI final/pixel-perfect — responsabilidade do **UXDesigner** após estas specs.

## Impact

- Novo projeto mobile (`condominio-legal-mobile`). Sem código legado afetado.
- Acoplamento ao **contrato de API do backend**: qualquer mudança de contrato exige revisão da `camada-servicos-api-mobile`.
- Paridade de requisitos com backend/web: toda regra de negócio do backend tem cobertura observável no mobile.

## Sequência sugerida (alinhada à do backend/web)

`acesso-perfis-mobile` + `camada-servicos-api-mobile` (fundação) → `cadastro-mobile` → `financeiro-mobile` → `comunicacao-mobile` → `reservas-areas-comuns-mobile` → `assembleias-votacoes-mobile` → `ocorrencias-manutencao-mobile` → `portaria-acessos-mobile`.

Próximo gate (Chefe): com estas specs validadas (`openspec validate --strict` = valid), abrir o fan-out mobile — **UXDesigner** (design das telas/navegação) → **Dev Mobile** (implementação, Fase 2) → **QA** (testes a partir dos cenários).
