const fs = require('fs');

const migrationPath = 'supabase/migrations/20260605152000_create_api_idempotency_keys.sql';

const sql = fs.readFileSync(migrationPath, 'utf8').replace(/\s+/g, ' ');

describe('CODAA-271 api_idempotency_keys migration contract', () => {
  it('defines the persisted idempotency table with reservation and replay columns', () => {
    expect(sql).toContain('create table if not exists public.api_idempotency_keys');
    expect(sql).toContain('user_id uuid not null references auth.users (id) on delete cascade');
    expect(sql).toContain('scope text not null');
    expect(sql).toContain('idempotency_key text not null');
    expect(sql).toContain('request_hash text');
    expect(sql).toContain("state text not null default 'processing'");
    expect(sql).toContain('status_code integer');
    expect(sql).toContain('response_body jsonb');
    expect(sql).toContain('response_headers jsonb');
    expect(sql).toContain('locked_at timestamptz not null default now()');
    expect(sql).toContain('completed_at timestamptz');
    expect(sql).toContain('failed_at timestamptz');
    expect(sql).toContain('expires_at timestamptz');

    expect(sql).not.toContain('status_code integer not null');
    expect(sql).not.toContain("response_body jsonb not null default '{}'::jsonb");
  });

  it('enforces duplicate-key rejection, state transitions, and payload shape constraints', () => {
    expect(sql).toContain(
      'constraint api_idempotency_keys_user_scope_key_unique unique (user_id, scope, idempotency_key)',
    );
    expect(sql).toContain(
      'constraint api_idempotency_keys_scope_not_blank check (length(btrim(scope)) > 0)',
    );
    expect(sql).toContain(
      'constraint api_idempotency_keys_idempotency_key_not_blank check (length(btrim(idempotency_key)) > 0)',
    );
    expect(sql).toContain(
      "constraint api_idempotency_keys_state_valid check (state in ('processing', 'completed', 'failed'))",
    );
    expect(sql).toContain(
      'constraint api_idempotency_keys_status_code_valid check (status_code is null or status_code between 100 and 599)',
    );
    expect(sql).toContain(
      "constraint api_idempotency_keys_response_body_object check (response_body is null or jsonb_typeof(response_body) = 'object')",
    );
    expect(sql).toContain(
      "constraint api_idempotency_keys_response_headers_object check (response_headers is null or jsonb_typeof(response_headers) = 'object')",
    );
    expect(sql).toContain('constraint api_idempotency_keys_terminal_response_complete');
    expect(sql).toContain("state = 'processing' and status_code is null and response_body is null");
    expect(sql).toContain("state = 'completed' and status_code is not null and response_body is not null");
    expect(sql).toContain("state = 'failed' and status_code is not null and response_body is not null");
  });

  it('creates lookup, cleanup indexes and updated_at trigger', () => {
    expect(sql).toContain(
      'create index if not exists api_idempotency_keys_lookup_idx on public.api_idempotency_keys (user_id, scope, idempotency_key)',
    );
    expect(sql).toContain(
      'create index if not exists api_idempotency_keys_expires_at_idx on public.api_idempotency_keys (expires_at) where expires_at is not null',
    );
    expect(sql).toContain(
      'create index if not exists api_idempotency_keys_created_at_idx on public.api_idempotency_keys (created_at)',
    );
    expect(sql).toContain(
      'create index if not exists api_idempotency_keys_state_locked_at_idx on public.api_idempotency_keys (state, locked_at)',
    );
    expect(sql).toContain('create or replace function public.set_api_idempotency_keys_updated_at()');
    expect(sql).toContain('create trigger set_api_idempotency_keys_updated_at');
    expect(sql).toContain('before update on public.api_idempotency_keys');
  });

  it('defines service-role RPCs for atomic reservation and terminal completion', () => {
    expect(sql).toContain('create or replace function public.reserve_api_idempotency_key(');
    expect(sql).toContain('perform pg_advisory_xact_lock(');
    expect(sql).toContain("hashtextextended(p_user_id::text || ':' || p_scope || ':' || p_idempotency_key, 0)");
    expect(sql).toContain('on conflict (user_id, scope, idempotency_key) do nothing');
    expect(sql).toContain('true as was_reserved');
    expect(sql).toContain('false as was_reserved');
    expect(sql).toContain("values ( p_user_id, p_scope, p_idempotency_key, p_request_hash, 'processing', now(), p_expires_at )");

    expect(sql).toContain('create or replace function public.complete_api_idempotency_key(');
    expect(sql).toContain("if p_state not in ('completed', 'failed') then");
    expect(sql).toContain("and target.state = 'processing'");
    expect(sql).toContain('return v_row');
  });

  it('limits direct authenticated access to selecting own rows', () => {
    expect(sql).toContain('alter table public.api_idempotency_keys enable row level security');
    expect(sql).toContain('create policy "api_idempotency_keys_select_own"');
    expect(sql).toContain('for select to authenticated using (auth.uid() = user_id)');
    expect(sql).toContain('revoke all on table public.api_idempotency_keys from anon');
    expect(sql).toContain('revoke all on table public.api_idempotency_keys from authenticated');
    expect(sql).toContain('grant select on table public.api_idempotency_keys to authenticated');
    expect(sql).toContain('grant all on table public.api_idempotency_keys to service_role');
    expect(sql).toContain(
      'revoke all on function public.reserve_api_idempotency_key(uuid, text, text, text, timestamptz) from public, anon, authenticated',
    );
    expect(sql).toContain(
      'revoke all on function public.complete_api_idempotency_key(uuid, text, text, integer, jsonb, jsonb, text) from public, anon, authenticated',
    );
    expect(sql).toContain(
      'grant execute on function public.reserve_api_idempotency_key(uuid, text, text, text, timestamptz) to service_role',
    );
    expect(sql).toContain(
      'grant execute on function public.complete_api_idempotency_key(uuid, text, text, integer, jsonb, jsonb, text) to service_role',
    );

    expect(sql).not.toMatch(/for insert to authenticated/);
    expect(sql).not.toMatch(/for update to authenticated/);
    expect(sql).not.toMatch(/for delete to authenticated/);
  });
});
