-- ============================================================
-- Goal Sight — AI Analysis Layer
-- File: 015_ai_analysis_layer.sql
-- Description:
--   Stores the full AI MatchAnalysisModel output.
--     match_analyses        -> header (MatchSummaryModel + recommendations)
--     team_match_analysis   -> TeamAnalysisModel (per side)
--     match_player_analysis -> PlayerModel verdict (per player)
--     tactical_insights     -> TacticalInsightModel
--     analysis_artifacts    -> scalable JSONB viz store (heatmaps,
--                              passing networks, formations, pressure maps...)
-- Safe to re-run.
-- ============================================================

create table if not exists public.match_analyses (
  id                uuid primary key default gen_random_uuid(),
  match_id          uuid references public.matches(id) on delete set null,
  upload_job_id     uuid references public.upload_jobs(id) on delete set null,
  generated_by      uuid references public.profiles(id) on delete set null,
  status            text not null default 'completed'
                      check (status in ('pending','processing','completed','failed')),
  dominant_team     text,
  home_avg_rating   numeric(4,2),
  away_avg_rating   numeric(4,2),
  motm_player_id    uuid references public.players(id) on delete set null,
  worst_player_id   uuid references public.players(id) on delete set null,
  intensity         integer default 0 check (intensity between 0 and 100),
  highlight_text    text,
  overall_narrative text,
  key_moments       jsonb not null default '[]'::jsonb,
  recommendations   jsonb not null default '[]'::jsonb,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index if not exists idx_match_analyses_match_id      on public.match_analyses(match_id);
create index if not exists idx_match_analyses_upload_job_id on public.match_analyses(upload_job_id);
create index if not exists idx_match_analyses_generated_by  on public.match_analyses(generated_by);
create index if not exists idx_match_analyses_motm_player   on public.match_analyses(motm_player_id);
create index if not exists idx_match_analyses_worst_player  on public.match_analyses(worst_player_id);

drop trigger if exists trg_match_analyses_updated_at on public.match_analyses;
create trigger trg_match_analyses_updated_at before update on public.match_analyses
  for each row execute function public.set_updated_at();

-- Per-team tactical block (TeamAnalysisModel)
create table if not exists public.team_match_analysis (
  id                uuid primary key default gen_random_uuid(),
  match_analysis_id uuid not null references public.match_analyses(id) on delete cascade,
  team_id           uuid references public.teams(id) on delete set null,
  side              text not null check (side in ('home','away')),
  possession        integer check (possession between 0 and 100),
  style             text,
  pressure_style    text,
  compactness       text,
  attacking_zones   jsonb not null default '[]'::jsonb,
  avg_rating        numeric(4,2),
  top_players       jsonb not null default '[]'::jsonb,
  worst_players     jsonb not null default '[]'::jsonb,
  created_at        timestamptz not null default now(),
  unique (match_analysis_id, side)
);
create index if not exists idx_team_match_analysis_analysis on public.team_match_analysis(match_analysis_id);
create index if not exists idx_team_match_analysis_team     on public.team_match_analysis(team_id);

-- Per-player AI verdict (PlayerModel) -- distinct from raw player_match_stats
create table if not exists public.match_player_analysis (
  id                 uuid primary key default gen_random_uuid(),
  match_analysis_id  uuid not null references public.match_analyses(id) on delete cascade,
  player_id          uuid references public.players(id) on delete set null,
  team_id            uuid references public.teams(id) on delete set null,
  rating             numeric(4,2),
  fatigue            integer check (fatigue between 0 and 100),
  performance_status text check (performance_status in ('excellent','good','average','poor','terrible')),
  contribution       text check (contribution in ('attack','defense','balanced')),
  impact             text,
  insight            text,
  goals              integer not null default 0,
  assists            integer not null default 0,
  tackles            integer not null default 0,
  key_passes         integer not null default 0,
  is_motm            boolean not null default false,
  is_worst           boolean not null default false,
  created_at         timestamptz not null default now(),
  unique (match_analysis_id, player_id)
);
create index if not exists idx_mpa_analysis on public.match_player_analysis(match_analysis_id);
create index if not exists idx_mpa_player   on public.match_player_analysis(player_id);
create index if not exists idx_mpa_team     on public.match_player_analysis(team_id);

-- Tactical insights (TacticalInsightModel)
create table if not exists public.tactical_insights (
  id                uuid primary key default gen_random_uuid(),
  match_analysis_id uuid references public.match_analyses(id) on delete cascade,
  match_id          uuid references public.matches(id) on delete set null,
  team_id           uuid references public.teams(id) on delete set null,
  title             text not null,
  description       text,
  category          text check (category in ('Strength','Weakness','Opportunity','Threat','Recommendation')),
  impact_score      numeric(4,2) check (impact_score between 0 and 10),
  created_at        timestamptz not null default now()
);
create index if not exists idx_tactical_insights_analysis on public.tactical_insights(match_analysis_id);
create index if not exists idx_tactical_insights_match    on public.tactical_insights(match_id);
create index if not exists idx_tactical_insights_team     on public.tactical_insights(team_id);

-- Scalable AI artifact store (heatmaps, passing networks, formations, pressure
-- maps, attack zones, momentum, possession timelines, shot maps...) as typed JSONB.
create table if not exists public.analysis_artifacts (
  id                uuid primary key default gen_random_uuid(),
  match_analysis_id uuid not null references public.match_analyses(id) on delete cascade,
  player_id         uuid references public.players(id) on delete set null,
  team_id           uuid references public.teams(id) on delete set null,
  artifact_type     text not null check (artifact_type in
                      ('heatmap','passing_network','formation','pressure_map',
                       'attack_zones','momentum','possession_timeline','shot_map','xg_timeline')),
  data              jsonb not null default '{}'::jsonb,
  created_at        timestamptz not null default now()
);
create index if not exists idx_analysis_artifacts_analysis on public.analysis_artifacts(match_analysis_id);
create index if not exists idx_analysis_artifacts_type     on public.analysis_artifacts(artifact_type);
create index if not exists idx_analysis_artifacts_player   on public.analysis_artifacts(player_id);
create index if not exists idx_analysis_artifacts_team     on public.analysis_artifacts(team_id);

-- ---- RLS: AI football data -> everyone reads, admin/manager write ----
alter table public.match_analyses        enable row level security;
alter table public.team_match_analysis   enable row level security;
alter table public.match_player_analysis enable row level security;
alter table public.tactical_insights     enable row level security;
alter table public.analysis_artifacts    enable row level security;

-- match_analyses
drop policy if exists "Admin full access match analyses" on public.match_analyses;
drop policy if exists "Manager full access match analyses" on public.match_analyses;
drop policy if exists "Role read match analyses" on public.match_analyses;
create policy "Admin full access match analyses" on public.match_analyses
  for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));
create policy "Manager full access match analyses" on public.match_analyses
  for all to authenticated using (public.has_role('manager')) with check (public.has_role('manager'));
create policy "Role read match analyses" on public.match_analyses
  for select to authenticated using (
    public.has_role('admin') or public.has_role('manager') or
    public.has_role('player') or public.has_role('fan'));

-- team_match_analysis
drop policy if exists "Admin full access team match analysis" on public.team_match_analysis;
drop policy if exists "Manager full access team match analysis" on public.team_match_analysis;
drop policy if exists "Role read team match analysis" on public.team_match_analysis;
create policy "Admin full access team match analysis" on public.team_match_analysis
  for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));
create policy "Manager full access team match analysis" on public.team_match_analysis
  for all to authenticated using (public.has_role('manager')) with check (public.has_role('manager'));
create policy "Role read team match analysis" on public.team_match_analysis
  for select to authenticated using (
    public.has_role('admin') or public.has_role('manager') or
    public.has_role('player') or public.has_role('fan'));

-- match_player_analysis
drop policy if exists "Admin full access match player analysis" on public.match_player_analysis;
drop policy if exists "Manager full access match player analysis" on public.match_player_analysis;
drop policy if exists "Role read match player analysis" on public.match_player_analysis;
create policy "Admin full access match player analysis" on public.match_player_analysis
  for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));
create policy "Manager full access match player analysis" on public.match_player_analysis
  for all to authenticated using (public.has_role('manager')) with check (public.has_role('manager'));
create policy "Role read match player analysis" on public.match_player_analysis
  for select to authenticated using (
    public.has_role('admin') or public.has_role('manager') or
    public.has_role('player') or public.has_role('fan'));

-- tactical_insights
drop policy if exists "Admin full access tactical insights" on public.tactical_insights;
drop policy if exists "Manager full access tactical insights" on public.tactical_insights;
drop policy if exists "Role read tactical insights" on public.tactical_insights;
create policy "Admin full access tactical insights" on public.tactical_insights
  for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));
create policy "Manager full access tactical insights" on public.tactical_insights
  for all to authenticated using (public.has_role('manager')) with check (public.has_role('manager'));
create policy "Role read tactical insights" on public.tactical_insights
  for select to authenticated using (
    public.has_role('admin') or public.has_role('manager') or
    public.has_role('player') or public.has_role('fan'));

-- analysis_artifacts
drop policy if exists "Admin full access analysis artifacts" on public.analysis_artifacts;
drop policy if exists "Manager full access analysis artifacts" on public.analysis_artifacts;
drop policy if exists "Role read analysis artifacts" on public.analysis_artifacts;
create policy "Admin full access analysis artifacts" on public.analysis_artifacts
  for all to authenticated using (public.has_role('admin')) with check (public.has_role('admin'));
create policy "Manager full access analysis artifacts" on public.analysis_artifacts
  for all to authenticated using (public.has_role('manager')) with check (public.has_role('manager'));
create policy "Role read analysis artifacts" on public.analysis_artifacts
  for select to authenticated using (
    public.has_role('admin') or public.has_role('manager') or
    public.has_role('player') or public.has_role('fan'));
