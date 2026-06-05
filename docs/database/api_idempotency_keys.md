# `api_idempotency_keys`

Migration: `supabase/migrations/20260605152000_create_api_idempotency_keys.sql`

Stores an atomic reservation plus the first terminal response for mobile API actions protected by the `Idempotency-Key` header. The backend must reserve `(user_id, scope, idempotency_key)` before executing a sensitive use case; only the caller that creates the `processing` row may execute the side effect. Conflicting callers read the existing row and wait, reject mismatched payload reuse, or replay the stored terminal response without reexecuting.

## Table Contract

| Column | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | `uuid` | yes | Primary key, defaults to `gen_random_uuid()`. |
| `user_id` | `uuid` | yes | References `auth.users(id)` with `on delete cascade`. |
| `scope` | `text` | yes | Stable operation scope such as `portaria.acessos.create`, `portaria.encomendas.create`, `assembleias.votos.cast`, `financeiro.boletos.emit`, or `financeiro.pix.emit`. Must not be blank. |
| `idempotency_key` | `text` | yes | Raw `Idempotency-Key` header value. Must not be blank. |
| `request_hash` | `text` | no | Optional backend-computed digest of the normalized request body. Use it to reject the same key with a different payload. |
| `state` | `text` | yes | `processing`, `completed`, or `failed`. Defaults to `processing` for the atomic reservation. |
| `status_code` | `integer` | no | HTTP status from the first terminal execution. Must be `100..599` when present. Null while `processing`. |
| `response_body` | `jsonb` | no | JSON object body to replay after terminal completion. Null while `processing`. |
| `response_headers` | `jsonb` | no | Optional JSON object of response headers to replay. |
| `locked_at` | `timestamptz` | yes | Timestamp when the backend reserved the key before executing the use case. |
| `completed_at` | `timestamptz` | no | Set when `state = 'completed'`. |
| `failed_at` | `timestamptz` | no | Set when `state = 'failed'`. |
| `expires_at` | `timestamptz` | no | Optional retention boundary for cleanup. |
| `created_at` | `timestamptz` | yes | Defaults to `now()`. |
| `updated_at` | `timestamptz` | yes | Defaults to `now()`, refreshed by trigger on update. |

## Constraints And Indexes

- Unique constraint: `(user_id, scope, idempotency_key)`.
- Lookup index: `(user_id, scope, idempotency_key)`.
- Cleanup indexes: `expires_at` where not null, plus `created_at`.
- Processing monitor index: `(state, locked_at)`.
- `state` is restricted to `processing`, `completed`, and `failed`.
- `processing` rows must not have `status_code`, `response_body`, `completed_at`, or `failed_at`.
- `completed` rows must have `status_code`, `response_body`, and `completed_at`.
- `failed` rows must have `status_code`, `response_body`, and `failed_at`.
- JSON constraints keep `response_body` and `response_headers` as objects when present.

## RPC Contract

The backend should use the service role for writes. The migration exposes two service-role-only helpers:

### `public.reserve_api_idempotency_key(...)`

Arguments:

| Argument | Type | Notes |
| --- | --- | --- |
| `p_user_id` | `uuid` | Auth user that owns the action. |
| `p_scope` | `text` | Stable operation scope. |
| `p_idempotency_key` | `text` | Raw header value. |
| `p_request_hash` | `text` | Optional normalized request digest. |
| `p_expires_at` | `timestamptz` | Optional cleanup boundary. |

Returns the idempotency row plus `was_reserved`.

- `was_reserved = true`: this call inserted the `processing` row atomically and owns execution of the sensitive use case.
- `was_reserved = false` and `state = 'processing'`: another request already owns execution. The backend must not execute the use case again; it should wait, poll, or return a conflict/in-progress response according to the API contract.
- `was_reserved = false` and `state in ('completed', 'failed')`: replay the stored `status_code`, `response_body`, and optional `response_headers`.

The function takes a transaction-scoped advisory lock derived from `(user_id, scope, idempotency_key)` before `insert ... on conflict (user_id, scope, idempotency_key) do nothing`. This serializes same-key reservations so a conflicting caller either receives the visible existing row or waits for the owner path, and the unique constraint remains the physical guard.

### `public.complete_api_idempotency_key(...)`

Arguments:

| Argument | Type | Notes |
| --- | --- | --- |
| `p_user_id` | `uuid` | Auth user that owns the action. |
| `p_scope` | `text` | Stable operation scope. |
| `p_idempotency_key` | `text` | Raw header value. |
| `p_status_code` | `integer` | Terminal HTTP response code. |
| `p_response_body` | `jsonb` | Terminal JSON object body. Defaults to `{}`. |
| `p_response_headers` | `jsonb` | Optional headers to replay. |
| `p_state` | `text` | `completed` by default; may be `failed`. |

Only `processing` reservations can be completed. If no matching `processing` row exists, the function raises an error so the backend cannot overwrite an already-terminal response.

## RLS And Grants

RLS is enabled.

- `anon`: no grants.
- `authenticated`: `SELECT` only, restricted to `auth.uid() = user_id`.
- `service_role`: `ALL` grants for backend/server management and `EXECUTE` on the reservation/completion helpers. Supabase service role bypasses RLS.
- RPCs: `anon` and `authenticated` have no execute grant on `reserve_api_idempotency_key` or `complete_api_idempotency_key`.

The intended backend flow is:

1. Resolve `user_id` from the authenticated request/session.
2. Normalize the operation into a stable `scope`.
3. Compute `request_hash` if payload-reuse detection is required.
4. Call `reserve_api_idempotency_key`.
5. If `was_reserved = true`, execute the sensitive use case once, then call `complete_api_idempotency_key` with `completed` or `failed` and the terminal response.
6. If `was_reserved = false`, compare `request_hash` when present. If it differs from the stored hash, reject key reuse with a different payload.
7. If the existing row is `processing`, wait/poll or return an in-progress response. Do not execute the use case.
8. If the existing row is `completed` or `failed`, replay the stored response.

Recommended initial scopes for CODAA-245/CODAA-263:

- `portaria.acessos.create`
- `portaria.encomendas.create`
- `assembleias.votos.cast`
- `financeiro.boletos.emit`
- `financeiro.pix.emit`
