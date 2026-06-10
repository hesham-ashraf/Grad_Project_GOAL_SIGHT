-- ============================================================
-- Goal Sight — Role Claim Hardening
-- File: 032_role_claim_hardening.sql
-- Description:
--   Replaces the recursive profile lookup inside public.has_role()
--   with a JWT claim check and backfills the current auth.users rows
--   so authenticated sessions carry the role claim nonrecursively.
-- Safe to re-run.
-- ============================================================

create or replace function public.has_role(role_name text)
returns boolean
language sql
stable
set search_path = public, auth
as $$
  select coalesce(
    lower(auth.jwt() -> 'app_metadata' ->> 'role') = lower(role_name),
    lower(auth.jwt() -> 'user_metadata' ->> 'role') = lower(role_name),
    false
  );
$$;

do $$
begin
  update auth.users u
  set raw_app_meta_data = jsonb_set(
        coalesce(u.raw_app_meta_data, '{}'::jsonb),
        '{role}',
        to_jsonb(p.role),
        true
      ),
      raw_user_meta_data = jsonb_set(
        coalesce(u.raw_user_meta_data, '{}'::jsonb),
        '{role}',
        to_jsonb(p.role),
        true
      )
  from public.profiles p
  where p.id = u.id
    and p.role in ('admin', 'manager', 'player', 'fan');
end $$;
