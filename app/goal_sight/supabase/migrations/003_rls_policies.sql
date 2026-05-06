-- ============================================================
-- Goal Sight MVP - Row Level Security Policies
-- File: 003_rls_policies.sql
-- Description:
-- Enables Row Level Security for all public tables and adds
-- temporary development read policies for Flutter/Web testing.
--
-- IMPORTANT:
-- The anon read policies are for development only.
-- Before production, replace them with authenticated role-based
-- policies for admin, coach, player, and fan users.
-- ============================================================

-- ============================================================
-- 1) Enable RLS on all tables
-- ============================================================

alter table public.profiles enable row level security;
alter table public.teams enable row level security;
alter table public.players enable row level security;
alter table public.matches enable row level security;
alter table public.match_events enable row level security;
alter table public.player_match_stats enable row level security;
alter table public.videos enable row level security;
alter table public.venues enable row level security;
alter table public.match_players enable row level security;
alter table public.subscription_plans enable row level security;
alter table public.user_subscriptions enable row level security;
alter table public.tracking_snapshots enable row level security;

-- ============================================================
-- 2) Drop old development policies if they already exist
-- This makes the file safe to re-run during development.
-- ============================================================

drop policy if exists "Dev read teams" on public.teams;
drop policy if exists "Dev read players" on public.players;
drop policy if exists "Dev read matches" on public.matches;
drop policy if exists "Dev read match events" on public.match_events;
drop policy if exists "Dev read player match stats" on public.player_match_stats;
drop policy if exists "Dev read videos" on public.videos;
drop policy if exists "Dev read venues" on public.venues;
drop policy if exists "Dev read match players" on public.match_players;
drop policy if exists "Dev read subscription plans" on public.subscription_plans;
drop policy if exists "Dev read tracking snapshots" on public.tracking_snapshots;

drop policy if exists "Users can read own profile" on public.profiles;
drop policy if exists "Users can insert own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;

drop policy if exists "Users can read own subscriptions" on public.user_subscriptions;

-- Optional cleanup for earlier policy names used during testing
drop policy if exists "Anyone can read teams temporarily" on public.teams;
drop policy if exists "Authenticated users can read teams" on public.teams;
drop policy if exists "Authenticated users can read players" on public.players;
drop policy if exists "Authenticated users can read matches" on public.matches;
drop policy if exists "Authenticated users can read match events" on public.match_events;
drop policy if exists "Authenticated users can read player stats" on public.player_match_stats;
drop policy if exists "Authenticated users can read videos" on public.videos;

-- ============================================================
-- 3) Temporary development read policies
-- Purpose:
-- Allows Flutter/Web to read public football data during MVP UI
-- development without requiring login on every screen.
--
-- WARNING:
-- These policies should be removed or replaced before production.
-- ============================================================

create policy "Dev read teams"
on public.teams
for select
to anon, authenticated
using (true);

create policy "Dev read players"
on public.players
for select
to anon, authenticated
using (true);

create policy "Dev read matches"
on public.matches
for select
to anon, authenticated
using (true);

create policy "Dev read match events"
on public.match_events
for select
to anon, authenticated
using (true);

create policy "Dev read player match stats"
on public.player_match_stats
for select
to anon, authenticated
using (true);

create policy "Dev read videos"
on public.videos
for select
to anon, authenticated
using (true);

create policy "Dev read venues"
on public.venues
for select
to anon, authenticated
using (true);

create policy "Dev read match players"
on public.match_players
for select
to anon, authenticated
using (true);

create policy "Dev read subscription plans"
on public.subscription_plans
for select
to anon, authenticated
using (true);

create policy "Dev read tracking snapshots"
on public.tracking_snapshots
for select
to anon, authenticated
using (true);

-- ============================================================
-- 4) Profile security policies
-- Purpose:
-- Users can only access and modify their own profile.
-- This is safer than making profiles public.
-- ============================================================

create policy "Users can read own profile"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

create policy "Users can insert own profile"
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);

create policy "Users can update own profile"
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

-- ============================================================
-- 5) User subscription security policies
-- Purpose:
-- Users can only read their own subscriptions.
-- Admin policies will be added later.
-- ============================================================

create policy "Users can read own subscriptions"
on public.user_subscriptions
for select
to authenticated
using (auth.uid() = user_id);

-- ============================================================
-- Production TODO:
-- Replace development read policies with role-based access:
--
-- Admin:
--   Can manage all tables.
--
-- Coach:
--   Can manage their teams, players, matches, videos, and stats.
--
-- Player:
--   Can read their own stats and public match/team data.
--
-- Fan:
--   Can read public teams, players, matches, events, and reports.
-- ============================================================