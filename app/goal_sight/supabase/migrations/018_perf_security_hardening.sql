-- ============================================================
-- Goal Sight — Performance & Security Hardening
-- File: 018_perf_security_hardening.sql
-- Description:
--   * Pins search_path on helper functions (security advisor 0011)
--   * Adds covering indexes for all unindexed foreign keys
--     (new + pre-existing tables)
--   * (RLS initplan optimization with (select auth.uid()) is applied
--     inline in migrations 014/016/017.)
-- Safe to re-run.
-- ============================================================

-- ---- 1. Harden function search_path (security advisor) ----
create or replace function public.has_role(role_name text)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
	select exists (
		select 1 from public.profiles p
		where p.id = auth.uid() and p.role = role_name
	);
$$;

alter function public.has_role(text)   set search_path = '';
alter function public.set_updated_at() set search_path = '';

-- ---- 2. Covering indexes for unindexed foreign keys ----
-- Pre-existing tables (hygiene)
create index if not exists idx_match_events_player_id       on public.match_events(player_id);
create index if not exists idx_match_players_team_id        on public.match_players(team_id);
create index if not exists idx_player_match_stats_player_id on public.player_match_stats(player_id);
create index if not exists idx_user_subscriptions_user      on public.user_subscriptions(user_id);
create index if not exists idx_user_subscriptions_plan      on public.user_subscriptions(plan_id);
create index if not exists idx_videos_match_id              on public.videos(match_id);
create index if not exists idx_videos_uploaded_by           on public.videos(uploaded_by);
