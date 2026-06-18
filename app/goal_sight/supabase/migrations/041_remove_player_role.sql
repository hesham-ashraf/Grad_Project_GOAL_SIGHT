-- ============================================================
-- Goal Sight — Remove "player" as a login role
-- File: 041_remove_player_role.sql
-- Description:
--   Players are DATA records created by an admin/manager — they never log in.
--   This migration removes 'player' from the set of auth roles:
--     * converts any existing player accounts to 'fan'
--     * tightens profiles_role_check to (admin, manager, fan)
--     * drops the player-specific RLS policies
--     * makes role the single source of truth in public.profiles via
--       auth_role(), and rewrites has_role() on top of it (this also closes
--       the security hole where has_role() trusted user-editable
--       user_metadata.role — see migration 032).
-- Safe to re-run.
-- ============================================================

-- 1. Demote any existing player accounts to fan.
update public.profiles set role = 'fan' where role = 'player';

-- 2. Tighten the allowed role set.
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles
  add constraint profiles_role_check check (role in ('admin', 'manager', 'fan'));

-- 3. auth_role(): the caller's role, read from profiles (single source of
--    truth). SECURITY DEFINER so it bypasses RLS and cannot recurse into the
--    profiles policies that call has_role().
create or replace function public.auth_role()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select role from public.profiles where id = auth.uid();
$$;

-- 4. has_role() now compares against auth_role() (no JWT / user_metadata).
create or replace function public.has_role(role_name text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(lower(public.auth_role()) = lower(role_name), false);
$$;

-- 5. Drop the player-specific policies (the role no longer exists).
drop policy if exists "Player read own risk"          on public.player_risk_analysis;
drop policy if exists "Player read own intelligence"  on public.player_intelligence;
drop policy if exists "Player read own stats"         on public.player_match_stats;
drop policy if exists "Player read videos"            on public.videos;

-- 6. The "Player ..." profile policies were actually self-access policies
--    (auth.uid() = id) despite the name. Replace them with clearly-named
--    self-access policies so login hydration keeps working.
drop policy if exists "Player read own profile"   on public.profiles;
drop policy if exists "Player insert own profile" on public.profiles;
drop policy if exists "Player update own profile" on public.profiles;

drop policy if exists "Users read own profile"   on public.profiles;
drop policy if exists "Users insert own profile" on public.profiles;
drop policy if exists "Users update own profile" on public.profiles;

create policy "Users read own profile" on public.profiles
  for select to authenticated using (auth.uid() = id);
create policy "Users insert own profile" on public.profiles
  for insert to authenticated with check (auth.uid() = id);
create policy "Users update own profile" on public.profiles
  for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);
