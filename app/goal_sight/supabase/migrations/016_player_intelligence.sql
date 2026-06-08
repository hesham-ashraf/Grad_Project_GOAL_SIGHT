-- ============================================================
-- Goal Sight — Player Intelligence & Risk
-- File: 016_player_intelligence.sql
-- Description:
--   * player_risk_analysis  -> RiskAnalysisModel (per-analysis snapshot)
--   * player_intelligence   -> one living AI profile per player
--                              (PlayerProfileModel + PlayerAnalysisModel)
-- Safe to re-run.
-- ============================================================

create table if not exists public.player_risk_analysis (
  id                       uuid primary key default gen_random_uuid(),
  player_id                uuid not null references public.players(id) on delete cascade,
  fatigue_risk             numeric(5,2) not null default 0 check (fatigue_risk between 0 and 100),
  injury_risk              numeric(5,2) not null default 0 check (injury_risk between 0 and 100),
  consistency_risk         numeric(5,2) not null default 0 check (consistency_risk between 0 and 100),
  tactical_risk            numeric(5,2) not null default 0 check (tactical_risk between 0 and 100),
  workload_score           numeric(5,2) not null default 0 check (workload_score between 0 and 100),
  risk_level               text not null default 'low'
                             check (risk_level in ('low','medium','high','critical')),
  next_match_risk_factor   numeric(5,2) not null default 0,
  days_until_full_recovery integer not null default 0,
  recommendations          jsonb not null default '[]'::jsonb,
  analyzed_at              timestamptz not null default now(),
  created_at               timestamptz not null default now()
);
create index if not exists idx_player_risk_player on public.player_risk_analysis(player_id);
create index if not exists idx_player_risk_level  on public.player_risk_analysis(risk_level);

-- One living AI profile row per player (PlayerProfileModel + PlayerAnalysisModel)
create table if not exists public.player_intelligence (
  id                     uuid primary key default gen_random_uuid(),
  player_id              uuid not null unique references public.players(id) on delete cascade,
  current_rating         numeric(4,2) not null default 0,
  average_rating         numeric(4,2) not null default 0,
  fatigue                integer not null default 0 check (fatigue between 0 and 100),
  activity_level         integer not null default 0 check (activity_level between 0 and 100),
  work_rate              numeric(5,2) not null default 0,
  tactical_impact        numeric(5,2) not null default 0,
  injury_risk            numeric(5,2) not null default 0,
  primary_contribution   text,
  secondary_contribution text,
  trend                  text not null default 'stable' check (trend in ('improving','declining','stable')),
  status                 text,
  improvement_rate       numeric(6,2) not null default 0,
  key_strengths          jsonb not null default '[]'::jsonb,
  weaknesses             jsonb not null default '[]'::jsonb,
  insights               jsonb not null default '[]'::jsonb,
  ratings_history        jsonb not null default '[]'::jsonb,
  total_matches          integer not null default 0,
  total_goals            integer not null default 0,
  total_assists          integer not null default 0,
  total_tackles          integer not null default 0,
  updated_at             timestamptz not null default now(),
  created_at             timestamptz not null default now()
);
create index if not exists idx_player_intelligence_player on public.player_intelligence(player_id);

drop trigger if exists trg_player_intelligence_updated_at on public.player_intelligence;
create trigger trg_player_intelligence_updated_at before update on public.player_intelligence
  for each row execute function public.set_updated_at();

-- ---- RLS ----
alter table public.player_risk_analysis enable row level security;
alter table public.player_intelligence  enable row level security;

drop policy if exists "Admin full access player risk" on public.player_risk_analysis;
drop policy if exists "Manager full access player risk" on public.player_risk_analysis;
drop policy if exists "Role read player risk" on public.player_risk_analysis;
drop policy if exists "Player read own risk" on public.player_risk_analysis;
create policy "Admin full access player risk" on public.player_risk_analysis
  for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));
create policy "Manager full access player risk" on public.player_risk_analysis
  for all to authenticated using (public.has_role('manager')) with check (public.has_role('manager'));
create policy "Role read player risk" on public.player_risk_analysis
  for select to authenticated using (
    public.has_role('admin') or public.has_role('manager') or public.has_role('fan'));
create policy "Player read own risk" on public.player_risk_analysis
  for select to authenticated using (
    public.has_role('player') and exists (
      select 1 from public.players p
      where p.id = player_risk_analysis.player_id and p.profile_id = (select auth.uid())));

drop policy if exists "Admin full access player intelligence" on public.player_intelligence;
drop policy if exists "Manager full access player intelligence" on public.player_intelligence;
drop policy if exists "Role read player intelligence" on public.player_intelligence;
drop policy if exists "Player read own intelligence" on public.player_intelligence;
create policy "Admin full access player intelligence" on public.player_intelligence
  for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));
create policy "Manager full access player intelligence" on public.player_intelligence
  for all to authenticated using (public.has_role('manager')) with check (public.has_role('manager'));
create policy "Role read player intelligence" on public.player_intelligence
  for select to authenticated using (
    public.has_role('admin') or public.has_role('manager') or public.has_role('fan'));
create policy "Player read own intelligence" on public.player_intelligence
  for select to authenticated using (
    public.has_role('player') and exists (
      select 1 from public.players p
      where p.id = player_intelligence.player_id and p.profile_id = (select auth.uid())));
