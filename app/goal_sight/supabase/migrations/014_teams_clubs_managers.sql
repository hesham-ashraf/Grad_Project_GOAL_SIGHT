-- ============================================================
-- Goal Sight — Teams (Clubs) enrichment, season stats & manager ownership
-- File: 014_teams_clubs_managers.sql
-- Description:
--   * Enriches `teams` to match the app's ClubModel (stadium, league, etc.)
--   * Adds `team_season_stats` (ClubStats — also drives standings)
--   * Adds `team_managers` (manager -> club ownership)
--   * Adds a shared `set_updated_at()` trigger function.
-- Safe to re-run.
-- ============================================================

-- Shared updated_at trigger function (used by many new tables)
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---- Enrich teams to match ClubModel ----
alter table public.teams add column if not exists stadium       text;
alter table public.teams add column if not exists league        text;
alter table public.teams add column if not exists country       text;
alter table public.teams add column if not exists founded_year  integer;
alter table public.teams add column if not exists coach         text;
alter table public.teams add column if not exists playing_style text;
alter table public.teams add column if not exists primary_color text;       -- hex e.g. '#1E88E5'
alter table public.teams add column if not exists description   text;
alter table public.teams add column if not exists updated_at    timestamptz not null default now();

drop trigger if exists trg_teams_updated_at on public.teams;
create trigger trg_teams_updated_at before update on public.teams
  for each row execute function public.set_updated_at();

-- ---- Team season stats (ClubStats) ----
create table if not exists public.team_season_stats (
  id              uuid primary key default gen_random_uuid(),
  team_id         uuid not null references public.teams(id) on delete cascade,
  season          text not null default 'current',
  matches_played  integer not null default 0,
  wins            integer not null default 0,
  draws           integer not null default 0,
  losses          integer not null default 0,
  goals_scored    integer not null default 0,
  goals_conceded  integer not null default 0,
  clean_sheets    integer not null default 0,
  points          integer not null default 0,
  ranking         integer,
  avg_possession  integer not null default 0,
  total_shots     integer not null default 0,
  yellow_cards    integer not null default 0,
  red_cards       integer not null default 0,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (team_id, season),
  constraint team_season_stats_possession_chk check (avg_possession between 0 and 100)
);
create index if not exists idx_team_season_stats_team_id on public.team_season_stats(team_id);
create index if not exists idx_team_season_stats_season  on public.team_season_stats(season);

drop trigger if exists trg_team_season_stats_updated_at on public.team_season_stats;
create trigger trg_team_season_stats_updated_at before update on public.team_season_stats
  for each row execute function public.set_updated_at();

-- ---- Manager -> club ownership ----
create table if not exists public.team_managers (
  id          uuid primary key default gen_random_uuid(),
  team_id     uuid not null references public.teams(id) on delete cascade,
  profile_id  uuid not null references public.profiles(id) on delete cascade,
  is_primary  boolean not null default true,
  created_at  timestamptz not null default now(),
  unique (team_id, profile_id)
);
create index if not exists idx_team_managers_team_id    on public.team_managers(team_id);
create index if not exists idx_team_managers_profile_id on public.team_managers(profile_id);

-- ---- RLS ----
alter table public.team_season_stats enable row level security;
alter table public.team_managers     enable row level security;

drop policy if exists "Admin full access team season stats" on public.team_season_stats;
drop policy if exists "Manager full access team season stats" on public.team_season_stats;
drop policy if exists "Role read team season stats" on public.team_season_stats;
create policy "Admin full access team season stats" on public.team_season_stats
  for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));
create policy "Manager full access team season stats" on public.team_season_stats
  for all to authenticated using (public.has_role('manager')) with check (public.has_role('manager'));
create policy "Role read team season stats" on public.team_season_stats
  for select to authenticated using (
    public.has_role('admin') or public.has_role('manager') or
    public.has_role('player') or public.has_role('fan'));

drop policy if exists "Admin full access team managers" on public.team_managers;
drop policy if exists "Manager read own team managers" on public.team_managers;
create policy "Admin full access team managers" on public.team_managers
  for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));
create policy "Manager read own team managers" on public.team_managers
  for select to authenticated using (profile_id = (select auth.uid()));
