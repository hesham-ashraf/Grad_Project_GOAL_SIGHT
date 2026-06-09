-- ============================================================
-- Goal Sight — Analysis view-model fields
-- File: 023_analysis_viewmodel_fields.sql
-- Description:
--   Adds denormalized columns so a match analysis can be reconstructed into
--   the Flutter MatchAnalysisModel without resolving player/team UUID FKs
--   (the mock analysis uses local player keys p1..pN and team names).
-- Safe to re-run.
-- ============================================================

alter table public.match_analyses add column if not exists home_team_name   text;
alter table public.match_analyses add column if not exists away_team_name   text;
alter table public.match_analyses add column if not exists score            text;
alter table public.match_analyses add column if not exists date_label       text;
alter table public.match_analyses add column if not exists result_status    text default 'FT';
alter table public.match_analyses add column if not exists motm_player_key  text;
alter table public.match_analyses add column if not exists worst_player_key text;

alter table public.team_match_analysis add column if not exists team_name text;

alter table public.match_player_analysis add column if not exists player_key      text;
alter table public.match_player_analysis add column if not exists player_name     text;
alter table public.match_player_analysis add column if not exists player_position text;
