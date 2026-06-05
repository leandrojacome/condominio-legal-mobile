# Implementation Handoff Tasks

## Dependency Order

The mobile implementation MUST follow this delivery/archive chain:

1. `acesso-perfis-mobile` and `camada-servicos-api-mobile` are foundation changes and MUST be implemented before any feature module.
2. Feature modules SHOULD then land in this order unless the Chefe changes priority: `cadastro-mobile` -> `financeiro-mobile` -> `comunicacao-mobile` -> `reservas-areas-comuns-mobile` -> `assembleias-votacoes-mobile` -> `ocorrencias-manutencao-mobile` -> `portaria-acessos-mobile`.
3. `financeiro-mobile`, `comunicacao-mobile`, `ocorrencias-manutencao-mobile`, and `portaria-acessos-mobile` depend on native platform concerns (push, secure storage, camera/gallery, file upload) being proven in the React Native bare app.
4. OpenSpec archive order MUST match real implementation order: archive foundation only after it is implemented and validated, then archive each feature module after its own implementation and QA validation.

## UXDesigner

- [ ] Define the mobile information architecture for the 6 profiles (`sindico`, `administradora`, `proprietario`, `inquilino`, `porteiro`, `conselho`).
- [ ] Produce wireframes/flows for login, condo switcher, protected navigation, and the 7 module areas covered by the specs.
- [ ] Specify mobile states for loading, error, empty, success, pull-to-refresh, pagination, permission denial, and expired session.
- [ ] Specify native interaction states for push opt-in, camera/gallery permissions, upload progress, and deep links from notifications.

## Dev Mobile

- [ ] Scaffold or complete the React Native bare (CLI) TypeScript app without Expo assumptions.
- [ ] Implement foundation first: secure session storage, Supabase Auth restore/refresh/logout, profile-based navigation guard, and API service layer.
- [ ] Implement each module against the OpenSpec requirements and the backend REST/JSON contract under `/api/v1`.
- [ ] Ensure screens consume only typed services; no screen/component calls HTTP directly.
- [ ] Preserve multi-tenant isolation: the app never accepts or sends an arbitrary tenant value outside the token claims.
- [ ] Implement native push, camera/gallery, secure storage, and upload behavior with observable states described in the specs.

## Dev Backend / BFF

- [ ] Confirm the backend contract covers all mobile service calls, error envelopes, cursor pagination, idempotency keys, and upload/push flows referenced by the mobile specs.
- [ ] If a mobile-specific BFF is needed for payload shape, batching, deep links, or push registration, propose it as a separate dependency before Dev Mobile builds screens against it.

## DB Developer via Chefe

- [ ] Chefe MUST route any required Supabase schema/storage/RLS/auth/seed work to DB Developer before implementation if backend verification finds missing support for push tokens, storage buckets, upload policies, or multi-vinculo token claims.
- [ ] BA does not assign DB Developer directly; unresolved database needs block the affected implementation issue through Chefe.

## QA

- [ ] Convert every `#### Scenario:` in the 9 capability specs into traceable test cases.
- [ ] Cover auth/session, profile-based navigation, multi-tenant denial, service error mapping, pagination, offline/network failure states, push deep-link behavior, camera/gallery permission denial, upload retry, and each module's happy path/error states.
- [ ] Validate the OpenSpec change remains valid before implementation starts and again before archive.

## Commit / Archive

- [ ] Commit these OpenSpec artifacts through the Commit Agent; BA MUST NOT commit directly.
- [ ] Do not archive `condominio-mobile-scope` yet. Archive only after the mobile implementation is complete, QA has validated the scenarios, and dependencies have been archived or explicitly marked non-blocking.
