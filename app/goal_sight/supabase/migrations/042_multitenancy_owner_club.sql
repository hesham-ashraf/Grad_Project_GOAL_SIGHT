-- ============================================================
-- Goal Sight — Multi-tenant club isolation
-- File: 042_multitenancy_owner_club.sql
-- Description:
--   One admin = one club. The admin + the managers they promote share a
--   single club_id; they can see ONLY their own club's data and never another
--   club's. This migration:
--     * adds owner_club_id (the tenant key) to the root tenant tables
--     * stamps it automatically on INSERT via a trigger
--     * REPLACES the old role-only "full access / Role read" policies (which
--       granted every manager access to every row) with club-scoped policies
--     * child tables inherit tenancy through their parent via EXISTS
--     * teams + team_season_stats stay publicly readable (clubs + standings)
-- Safe to re-run.
-- NOTE: this supersedes the broken club-scoping attempted in 036.
-- ============================================================

-- ------------------------------------------------------------
-- 0. Tenant helpers
-- ------------------------------------------------------------

-- The caller's club_id, read from profiles (recreated idempotently from 036).
create or replace function public.auth_club_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select club_id from public.profiles where id = auth.uid();
$$;

-- BEFORE INSERT trigger: stamp the row with the caller's club when not set,
-- so a manager can never insert data into another club's tenant.
create or replace function public.set_owner_club_id()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.owner_club_id is null then
    new.owner_club_id := public.auth_club_id();
  end if;
  return new;
end;
$$;

-- ------------------------------------------------------------
-- 1. Add owner_club_id + index + stamping trigger to root tables
-- ------------------------------------------------------------
do $$
declare
  t text;
  root_tables text[] := array[
    'players', 'matches', 'videos', 'upload_jobs',
    'match_analyses', 'player_intelligence', 'player_risk_analysis'
  ];
begin
  foreach t in array root_tables loop
    execute format(
      'alter table public.%I add column if not exists owner_club_id uuid '
      || 'references public.teams(id) on delete cascade', t);
    execute format(
      'create index if not exists idx_%s_owner_club on public.%I(owner_club_id)', t, t);
    execute format('drop trigger if exists trg_set_owner_club_%s on public.%I', t, t);
    execute format(
      'create trigger trg_set_owner_club_%s before insert on public.%I '
      || 'for each row execute function public.set_owner_club_id()', t, t);
  end loop;
end $$;

-- ------------------------------------------------------------
-- 2. Drop the old role-only policies on every tenant table
--    (these OR-combined to grant managers access to ALL rows).
-- ------------------------------------------------------------
-- players
drop policy if exists "Admin full access players"   on public.players;
drop policy if exists "Manager full access players" on public.players;
drop policy if exists "Role read players"           on public.players;
-- matches
drop policy if exists "Admin full access matches"   on public.matches;
drop policy if exists "Manager full access matches" on public.matches;
drop policy if exists "Role read matches"           on public.matches;
-- videos
drop policy if exists "Admin full access videos" on public.videos;
drop policy if exists "Manager read videos"      on public.videos;
drop policy if exists "Manager upload videos"    on public.videos;
-- upload_jobs (007/012 role policies + the broken 036 attempt)
drop policy if exists "upload_jobs_club_select"       on public.upload_jobs;
drop policy if exists "Admin full access upload jobs"  on public.upload_jobs;
drop policy if exists "Manager create upload jobs"     on public.upload_jobs;
drop policy if exists "Manager read own upload jobs"   on public.upload_jobs;
drop policy if exists "Manager update own upload jobs" on public.upload_jobs;
-- match_analyses (incl. the broken 036 attempt)
drop policy if exists "analyses_club_select"               on public.match_analyses;
drop policy if exists "Admin full access match analyses"   on public.match_analyses;
drop policy if exists "Manager full access match analyses" on public.match_analyses;
drop policy if exists "Role read match analyses"           on public.match_analyses;
-- match_analyses children
drop policy if exists "Admin full access team match analysis"   on public.team_match_analysis;
drop policy if exists "Manager full access team match analysis" on public.team_match_analysis;
drop policy if exists "Role read team match analysis"           on public.team_match_analysis;
drop policy if exists "Admin full access match player analysis"   on public.match_player_analysis;
drop policy if exists "Manager full access match player analysis" on public.match_player_analysis;
drop policy if exists "Role read match player analysis"           on public.match_player_analysis;
drop policy if exists "Admin full access tactical insights"   on public.tactical_insights;
drop policy if exists "Manager full access tactical insights" on public.tactical_insights;
drop policy if exists "Role read tactical insights"           on public.tactical_insights;
drop policy if exists "Admin full access analysis artifacts"   on public.analysis_artifacts;
drop policy if exists "Manager full access analysis artifacts" on public.analysis_artifacts;
drop policy if exists "Role read analysis artifacts"           on public.analysis_artifacts;
-- player intelligence / risk
drop policy if exists "Admin full access player intelligence"   on public.player_intelligence;
drop policy if exists "Manager full access player intelligence" on public.player_intelligence;
drop policy if exists "Role read player intelligence"           on public.player_intelligence;
drop policy if exists "Admin full access player risk"   on public.player_risk_analysis;
drop policy if exists "Manager full access player risk" on public.player_risk_analysis;
drop policy if exists "Role read player risk"           on public.player_risk_analysis;
-- matches children
drop policy if exists "Admin full access match events"   on public.match_events;
drop policy if exists "Manager full access match events" on public.match_events;
drop policy if exists "Role read match events"           on public.match_events;
drop policy if exists "Admin full access player match stats"   on public.player_match_stats;
drop policy if exists "Manager full access player match stats" on public.player_match_stats;
drop policy if exists "Role read player match stats"           on public.player_match_stats;
-- managers directory (incl. 036 attempt)
drop policy if exists "Admin full access managers" on public.managers;
drop policy if exists "Role read managers"         on public.managers;
drop policy if exists "managers_club_select"       on public.managers;

-- ------------------------------------------------------------
-- 3. Club-scoped policies — ROOT tables (filter by owner_club_id column).
--    Admin + manager of the owning club get full access; nobody else.
-- ------------------------------------------------------------
do $$
declare
  t text;
  root_tables text[] := array[
    'players', 'matches', 'videos', 'upload_jobs',
    'match_analyses', 'player_intelligence', 'player_risk_analysis'
  ];
begin
  foreach t in array root_tables loop
    execute format('drop policy if exists "club_all_%s" on public.%I', t, t);
    execute format($f$
      create policy "club_all_%s" on public.%I
        for all to authenticated
        using (
          public.auth_role() in ('admin','manager')
          and owner_club_id = public.auth_club_id()
        )
        with check (
          public.auth_role() in ('admin','manager')
          and owner_club_id = public.auth_club_id()
        )
    $f$, t, t);
  end loop;
end $$;

-- ------------------------------------------------------------
-- 4. Club-scoped policies — CHILD tables (inherit via parent EXISTS).
-- ------------------------------------------------------------
-- helper to build a child policy keyed off match_analyses
do $$
declare
  t text;
  ma_children text[] := array[
    'team_match_analysis', 'match_player_analysis',
    'tactical_insights', 'analysis_artifacts'
  ];
begin
  foreach t in array ma_children loop
    execute format('drop policy if exists "club_all_%s" on public.%I', t, t);
    execute format($f$
      create policy "club_all_%s" on public.%I
        for all to authenticated
        using (
          public.auth_role() in ('admin','manager')
          and exists (
            select 1 from public.match_analyses ma
            where ma.id = %I.match_analysis_id
              and ma.owner_club_id = public.auth_club_id()
          )
        )
        with check (
          public.auth_role() in ('admin','manager')
          and exists (
            select 1 from public.match_analyses ma
            where ma.id = %I.match_analysis_id
              and ma.owner_club_id = public.auth_club_id()
          )
        )
    $f$, t, t, t, t);
  end loop;
end $$;

-- matches children (match_events, player_match_stats) inherit via matches
do $$
declare
  t text;
  m_children text[] := array['match_events', 'player_match_stats'];
begin
  foreach t in array m_children loop
    execute format('drop policy if exists "club_all_%s" on public.%I', t, t);
    execute format($f$
      create policy "club_all_%s" on public.%I
        for all to authenticated
        using (
          public.auth_role() in ('admin','manager')
          and exists (
            select 1 from public.matches m
            where m.id = %I.match_id
              and m.owner_club_id = public.auth_club_id()
          )
        )
        with check (
          public.auth_role() in ('admin','manager')
          and exists (
            select 1 from public.matches m
            where m.id = %I.match_id
              and m.owner_club_id = public.auth_club_id()
          )
        )
    $f$, t, t, t, t);
  end loop;
end $$;

-- ------------------------------------------------------------
-- 5. Managers directory — club-scoped.
--    Admin manages managers of their own club; managers can read their
--    colleagues in the same club.
-- ------------------------------------------------------------
drop policy if exists "managers_admin_manage" on public.managers;
drop policy if exists "managers_club_read"    on public.managers;
create policy "managers_admin_manage" on public.managers
  for all to authenticated
  using (public.auth_role() = 'admin' and club_id = public.auth_club_id())
  with check (public.auth_role() = 'admin' and club_id = public.auth_club_id());
create policy "managers_club_read" on public.managers
  for select to authenticated
  using (
    public.auth_role() in ('admin','manager') and club_id = public.auth_club_id()
  );

-- ------------------------------------------------------------
-- 6. Public reference data — teams (clubs) + standings stay readable by
--    everyone (including fans). Writes limited to admin/manager.
-- ------------------------------------------------------------
drop policy if exists "Role read teams"             on public.teams;
drop policy if exists "Admin full access teams"     on public.teams;
drop policy if exists "Manager full access teams"   on public.teams;
drop policy if exists "teams_public_read"           on public.teams;
drop policy if exists "teams_staff_write"           on public.teams;
create policy "teams_public_read" on public.teams
  for select to anon, authenticated using (true);
create policy "teams_staff_write" on public.teams
  for all to authenticated
  using (public.auth_role() in ('admin','manager'))
  with check (public.auth_role() in ('admin','manager'));

drop policy if exists "Role read team season stats"            on public.team_season_stats;
drop policy if exists "Admin full access team season stats"    on public.team_season_stats;
drop policy if exists "Manager full access team season stats"  on public.team_season_stats;
drop policy if exists "team_season_stats_public_read"          on public.team_season_stats;
drop policy if exists "team_season_stats_staff_write"          on public.team_season_stats;
create policy "team_season_stats_public_read" on public.team_season_stats
  for select to anon, authenticated using (true);
create policy "team_season_stats_staff_write" on public.team_season_stats
  for all to authenticated
  using (public.auth_role() in ('admin','manager'))
  with check (public.auth_role() in ('admin','manager'));

-- ------------------------------------------------------------
-- 7. Profiles — same-club visibility (recreated idempotently from 036),
--    plus admin manages profiles of their own club.
-- ------------------------------------------------------------
drop policy if exists "profiles_same_club_select" on public.profiles;
create policy "profiles_same_club_select" on public.profiles
  for select to authenticated
  using (club_id = public.auth_club_id() or id = auth.uid());

drop policy if exists "profiles_admin_manage_club" on public.profiles;
create policy "profiles_admin_manage_club" on public.profiles
  for update to authenticated
  using (public.auth_role() = 'admin' and club_id = public.auth_club_id())
  with check (public.auth_role() = 'admin' and club_id = public.auth_club_id());
