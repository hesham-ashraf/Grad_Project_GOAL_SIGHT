-- ============================================================
-- Goal Sight — Wipe demo / seed data
-- File: 045_wipe_demo_seed.sql
-- Description:
--   Removes all the demo content (celebrity managers, demo players, matches,
--   analyses, seeded clubs & standings) so the app starts clean: the only data
--   that exists from here on is what real admins/managers create. Auth users
--   and their profiles are preserved (deleting the seeded teams just nulls any
--   profiles.club_id via the existing ON DELETE SET NULL — admins then create
--   their own club with create_admin_club()).
-- Children are deleted before parents so this works regardless of cascade.
-- Safe to re-run (idempotent — deletes are no-ops once empty).
-- ============================================================

-- AI analysis layer (children → header)
delete from public.analysis_artifacts;
delete from public.tactical_insights;
delete from public.match_player_analysis;
delete from public.team_match_analysis;
delete from public.match_analyses;

-- Player intelligence / risk
delete from public.player_risk_analysis;
delete from public.player_intelligence;

-- Raw match data
delete from public.player_match_stats;
delete from public.match_events;

-- Uploads & videos
delete from public.upload_jobs;
delete from public.videos;

-- Squad & fixtures
delete from public.players;
delete from public.matches;

-- Admin-managed directory & engagement seed
delete from public.managers;
delete from public.highlights;

-- Clubs & standings (admins re-create their club via create_admin_club()).
delete from public.team_season_stats;
delete from public.teams;
