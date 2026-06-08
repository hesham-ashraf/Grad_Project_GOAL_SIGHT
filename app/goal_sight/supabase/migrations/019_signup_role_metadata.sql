-- ============================================================
-- Goal Sight — Honor signup role from auth metadata
-- File: 019_signup_role_metadata.sql
-- Description:
--   Updates handle_new_user() so the role chosen at registration
--   (passed via auth signUp `data: { role }`) is written to the
--   profile, instead of always defaulting to 'fan'. The role is
--   whitelisted against the profiles.role CHECK set.
--
-- SECURITY NOTE (tracked for Phase 4 §19): this lets a user self-assign
-- 'manager'/'admin' at signup, matching the current register UX. Before
-- production, gate elevated roles behind admin approval or an invite flow.
-- Safe to re-run.
-- ============================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  requested_role text;
begin
  requested_role := coalesce(new.raw_user_meta_data->>'role', 'fan');
  if requested_role not in ('admin','manager','player','fan') then
    requested_role := 'fan';
  end if;

  insert into public.profiles (id, full_name, role, avatar_url, created_at)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.email, 'New User'),
    requested_role,
    new.raw_user_meta_data->>'avatar_url',
    now()
  )
  on conflict (id) do nothing;

  return new;
end;
$$;
