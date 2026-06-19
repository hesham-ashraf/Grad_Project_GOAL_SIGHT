-- 053 — Adapt the schema to the REAL football_ai model outputs.
-- Additive only: new nullable columns + new child tables. No drops, no NOT NULL
-- on existing rows. Unsupported model fields (goals/assists/tackles/key_passes/
-- score/jersey) are left in place but simply not populated (app hides them).
-- Applied to the live remote DB via MCP on 2026-06-19.

-- ── match_player_analysis: PLAYER ANALYTICS + FINAL REPORT (per player/match) ──
alter table public.match_player_analysis
  add column if not exists track_id integer,
  add column if not exists model_team_id integer,
  add column if not exists total_distance_m double precision,
  add column if not exists avg_speed_kmh double precision,
  add column if not exists max_speed_kmh double precision,
  add column if not exists work_rate text,
  add column if not exists activity_level_label text,
  add column if not exists fatigue_label text;

-- ── match_analyses: FINAL REPORT + POSSESSION summary + team->home mapping ──
alter table public.match_analyses
  add column if not exists summary text,
  add column if not exists key_insights jsonb not null default '[]'::jsonb,
  add column if not exists motm_track_id integer,
  add column if not exists weakest_track_id integer,
  add column if not exists team0_possession numeric,
  add column if not exists team1_possession numeric,
  add column if not exists possession_dominant_team integer,
  add column if not exists home_model_team_id integer,
  add column if not exists total_frames integer,
  add column if not exists fps numeric;

-- ── team_match_analysis: TEAM TACTICAL labels ──
alter table public.team_match_analysis
  add column if not exists model_team_id integer,
  add column if not exists team_shape text,
  add column if not exists attacking_zone text,
  add column if not exists transition_speed text,
  add column if not exists build_up_style text;

-- ── team_tactical_metrics: TEAM TACTICAL numeric metrics + explainable reasons ──
create table if not exists public.team_tactical_metrics (
  id uuid primary key default gen_random_uuid(),
  match_analysis_id uuid not null references public.match_analyses(id) on delete cascade,
  model_team_id integer not null,
  compactness_m double precision,
  width_m double precision,
  depth_m double precision,
  centroid_x double precision,
  centroid_y double precision,
  block_height_m double precision,
  avg_speed_kmh double precision,
  reasons jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists idx_ttm_match on public.team_tactical_metrics(match_analysis_id);

-- ── player_tracking_metrics: RAW ANALYTICS per-track speed/distance ──
create table if not exists public.player_tracking_metrics (
  id uuid primary key default gen_random_uuid(),
  match_analysis_id uuid not null references public.match_analyses(id) on delete cascade,
  player_id uuid references public.players(id) on delete set null,
  track_id integer not null,
  model_team_id integer,
  role text,
  player_name text,
  total_distance_m double precision,
  avg_speed_kmh double precision,
  max_speed_kmh double precision,
  valid_samples integer,
  invalid_jumps integer,
  insufficient_data boolean default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_ptm_match on public.player_tracking_metrics(match_analysis_id);

-- ── match_possession_timeline: POSSESSION per-frame [frame, team] ──
create table if not exists public.match_possession_timeline (
  id uuid primary key default gen_random_uuid(),
  match_analysis_id uuid not null references public.match_analyses(id) on delete cascade,
  frame_number integer not null,
  team_id integer,                 -- 0 / 1, null = loose ball
  created_at timestamptz not null default now()
);
create index if not exists idx_mpt_match on public.match_possession_timeline(match_analysis_id);

-- ── ai_recommendations: FINAL REPORT recommendations + key insights ──
create table if not exists public.ai_recommendations (
  id uuid primary key default gen_random_uuid(),
  match_analysis_id uuid not null references public.match_analyses(id) on delete cascade,
  kind text not null default 'recommendation',   -- recommendation | key_insight
  text text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists idx_airec_match on public.ai_recommendations(match_analysis_id);

-- ── heatmaps: team + best-player PNGs the model emits (per-match/per-player
--    heatmaps continue to live on match_analyses.heatmap_url /
--    match_player_analysis.heatmap_url) ──
create table if not exists public.heatmaps (
  id uuid primary key default gen_random_uuid(),
  match_analysis_id uuid not null references public.match_analyses(id) on delete cascade,
  owner_club_id uuid,
  scope text not null,             -- team | best_player | match | player
  model_team_id integer,
  player_id uuid references public.players(id) on delete set null,
  url text not null,
  created_at timestamptz not null default now()
);
create index if not exists idx_heatmaps_match on public.heatmaps(match_analysis_id);

-- ── RLS: new tables are club-scoped via their parent match_analyses, matching
--    the existing club_all_match_player_analysis pattern ──
do $$
declare t text;
begin
  foreach t in array array['team_tactical_metrics','player_tracking_metrics',
                           'match_possession_timeline','ai_recommendations','heatmaps']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists club_all_%1$s on public.%1$s', t);
    execute format($f$
      create policy club_all_%1$s on public.%1$s
      for all
      using (
        public.auth_role() = any (array['admin','manager'])
        and exists (select 1 from public.match_analyses ma
                    where ma.id = %1$s.match_analysis_id
                      and ma.owner_club_id = public.auth_club_id())
      )
      with check (
        public.auth_role() = any (array['admin','manager'])
        and exists (select 1 from public.match_analyses ma
                    where ma.id = %1$s.match_analysis_id
                      and ma.owner_club_id = public.auth_club_id())
      )
    $f$, t);
  end loop;
end $$;
