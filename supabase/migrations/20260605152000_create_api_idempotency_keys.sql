-- Persisted idempotency contract for sensitive mobile API actions.
-- Backend/service_role owns writes; authenticated users can only read their
-- own keys if this table is ever exposed through PostgREST.

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.api_idempotency_keys (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  scope text not null,
  idempotency_key text not null,
  request_hash text,
  state text not null default 'processing',
  status_code integer,
  response_body jsonb,
  response_headers jsonb,
  locked_at timestamptz not null default now(),
  completed_at timestamptz,
  failed_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint api_idempotency_keys_scope_not_blank
    check (length(btrim(scope)) > 0),
  constraint api_idempotency_keys_idempotency_key_not_blank
    check (length(btrim(idempotency_key)) > 0),
  constraint api_idempotency_keys_state_valid
    check (state in ('processing', 'completed', 'failed')),
  constraint api_idempotency_keys_status_code_valid
    check (status_code is null or status_code between 100 and 599),
  constraint api_idempotency_keys_response_body_object
    check (response_body is null or jsonb_typeof(response_body) = 'object'),
  constraint api_idempotency_keys_response_headers_object
    check (response_headers is null or jsonb_typeof(response_headers) = 'object'),
  constraint api_idempotency_keys_terminal_response_complete
    check (
      (
        state = 'processing'
        and status_code is null
        and response_body is null
        and completed_at is null
        and failed_at is null
      )
      or (
        state = 'completed'
        and status_code is not null
        and response_body is not null
        and completed_at is not null
        and failed_at is null
      )
      or (
        state = 'failed'
        and status_code is not null
        and response_body is not null
        and completed_at is null
        and failed_at is not null
      )
    ),
  constraint api_idempotency_keys_user_scope_key_unique
    unique (user_id, scope, idempotency_key)
);

comment on table public.api_idempotency_keys is
  'Stores atomic reservations and terminal responses for Idempotency-Key protected mobile API actions.';
comment on column public.api_idempotency_keys.user_id is
  'Supabase Auth user that owns the logical action.';
comment on column public.api_idempotency_keys.scope is
  'Stable operation scope, for example portaria.acessos.create or assembleias.votos.cast.';
comment on column public.api_idempotency_keys.idempotency_key is
  'Value received from the Idempotency-Key HTTP header.';
comment on column public.api_idempotency_keys.request_hash is
  'Optional backend-computed digest of the normalized request body to detect key reuse with a different payload.';
comment on column public.api_idempotency_keys.state is
  'Lifecycle state for the idempotency record: processing reserves the key before side effects; completed/failed records the terminal response.';
comment on column public.api_idempotency_keys.status_code is
  'HTTP status code from the first terminal execution; null while processing.';
comment on column public.api_idempotency_keys.response_body is
  'JSON object body returned by the first terminal execution; null while processing.';
comment on column public.api_idempotency_keys.response_headers is
  'Optional response headers that must be replayed with the cached response.';
comment on column public.api_idempotency_keys.locked_at is
  'Time when the backend atomically reserved this idempotency key for processing.';
comment on column public.api_idempotency_keys.completed_at is
  'Time when the backend stored a successful terminal response.';
comment on column public.api_idempotency_keys.failed_at is
  'Time when the backend stored a failed terminal response.';
comment on column public.api_idempotency_keys.expires_at is
  'Optional retention boundary for cleanup jobs.';

create index if not exists api_idempotency_keys_lookup_idx
  on public.api_idempotency_keys (user_id, scope, idempotency_key);

create index if not exists api_idempotency_keys_expires_at_idx
  on public.api_idempotency_keys (expires_at)
  where expires_at is not null;

create index if not exists api_idempotency_keys_created_at_idx
  on public.api_idempotency_keys (created_at);

create index if not exists api_idempotency_keys_state_locked_at_idx
  on public.api_idempotency_keys (state, locked_at);

create or replace function public.set_api_idempotency_keys_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_api_idempotency_keys_updated_at on public.api_idempotency_keys;
create trigger set_api_idempotency_keys_updated_at
  before update on public.api_idempotency_keys
  for each row
  execute function public.set_api_idempotency_keys_updated_at();

create or replace function public.reserve_api_idempotency_key(
  p_user_id uuid,
  p_scope text,
  p_idempotency_key text,
  p_request_hash text default null,
  p_expires_at timestamptz default null
)
returns table (
  id uuid,
  user_id uuid,
  scope text,
  idempotency_key text,
  request_hash text,
  state text,
  status_code integer,
  response_body jsonb,
  response_headers jsonb,
  locked_at timestamptz,
  completed_at timestamptz,
  failed_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz,
  was_reserved boolean
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform pg_advisory_xact_lock(
    hashtextextended(p_user_id::text || ':' || p_scope || ':' || p_idempotency_key, 0)
  );

  return query
  with inserted as (
    insert into public.api_idempotency_keys (
      user_id,
      scope,
      idempotency_key,
      request_hash,
      state,
      locked_at,
      expires_at
    )
    values (
      p_user_id,
      p_scope,
      p_idempotency_key,
      p_request_hash,
      'processing',
      now(),
      p_expires_at
    )
    on conflict (user_id, scope, idempotency_key) do nothing
    returning
      api_idempotency_keys.id,
      api_idempotency_keys.user_id,
      api_idempotency_keys.scope,
      api_idempotency_keys.idempotency_key,
      api_idempotency_keys.request_hash,
      api_idempotency_keys.state,
      api_idempotency_keys.status_code,
      api_idempotency_keys.response_body,
      api_idempotency_keys.response_headers,
      api_idempotency_keys.locked_at,
      api_idempotency_keys.completed_at,
      api_idempotency_keys.failed_at,
      api_idempotency_keys.expires_at,
      api_idempotency_keys.created_at,
      api_idempotency_keys.updated_at
  )
  select
    inserted.id,
    inserted.user_id,
    inserted.scope,
    inserted.idempotency_key,
    inserted.request_hash,
    inserted.state,
    inserted.status_code,
    inserted.response_body,
    inserted.response_headers,
    inserted.locked_at,
    inserted.completed_at,
    inserted.failed_at,
    inserted.expires_at,
    inserted.created_at,
    inserted.updated_at,
    true as was_reserved
  from inserted

  union all

  select
    existing.id,
    existing.user_id,
    existing.scope,
    existing.idempotency_key,
    existing.request_hash,
    existing.state,
    existing.status_code,
    existing.response_body,
    existing.response_headers,
    existing.locked_at,
    existing.completed_at,
    existing.failed_at,
    existing.expires_at,
    existing.created_at,
    existing.updated_at,
    false as was_reserved
  from public.api_idempotency_keys existing
  where existing.user_id = p_user_id
    and existing.scope = p_scope
    and existing.idempotency_key = p_idempotency_key
    and not exists (select 1 from inserted);
end;
$$;

comment on function public.reserve_api_idempotency_key(uuid, text, text, text, timestamptz) is
  'Atomically reserves an idempotency key before side effects using a transaction-scoped advisory lock and unique constraint. Returns was_reserved=true for the caller that owns execution; conflicts return the existing row for wait/replay handling.';

create or replace function public.complete_api_idempotency_key(
  p_user_id uuid,
  p_scope text,
  p_idempotency_key text,
  p_status_code integer,
  p_response_body jsonb default '{}'::jsonb,
  p_response_headers jsonb default null,
  p_state text default 'completed'
)
returns public.api_idempotency_keys
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_row public.api_idempotency_keys;
begin
  if p_state not in ('completed', 'failed') then
    raise exception 'Invalid terminal idempotency state: %', p_state
      using errcode = '22023';
  end if;

  update public.api_idempotency_keys target
  set
    state = p_state,
    status_code = p_status_code,
    response_body = coalesce(p_response_body, '{}'::jsonb),
    response_headers = p_response_headers,
    completed_at = case when p_state = 'completed' then now() else null end,
    failed_at = case when p_state = 'failed' then now() else null end
  where target.user_id = p_user_id
    and target.scope = p_scope
    and target.idempotency_key = p_idempotency_key
    and target.state = 'processing'
  returning target.* into v_row;

  if v_row.id is null then
    raise exception 'No processing idempotency reservation found for user %, scope %, key %',
      p_user_id, p_scope, p_idempotency_key
      using errcode = 'P0002';
  end if;

  return v_row;
end;
$$;

comment on function public.complete_api_idempotency_key(uuid, text, text, integer, jsonb, jsonb, text) is
  'Completes a processing idempotency reservation with the terminal response that later calls can replay.';

alter table public.api_idempotency_keys enable row level security;

drop policy if exists "api_idempotency_keys_select_own" on public.api_idempotency_keys;
create policy "api_idempotency_keys_select_own"
  on public.api_idempotency_keys
  for select
  to authenticated
  using (auth.uid() = user_id);

revoke all on table public.api_idempotency_keys from anon;
revoke all on table public.api_idempotency_keys from authenticated;
grant select on table public.api_idempotency_keys to authenticated;
grant all on table public.api_idempotency_keys to service_role;

revoke all on function public.reserve_api_idempotency_key(uuid, text, text, text, timestamptz) from public, anon, authenticated;
revoke all on function public.complete_api_idempotency_key(uuid, text, text, integer, jsonb, jsonb, text) from public, anon, authenticated;
grant execute on function public.reserve_api_idempotency_key(uuid, text, text, text, timestamptz) to service_role;
grant execute on function public.complete_api_idempotency_key(uuid, text, text, integer, jsonb, jsonb, text) to service_role;
