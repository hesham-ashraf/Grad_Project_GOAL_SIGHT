-- ============================================================
-- Goal Sight MVP - Role-Based RLS Policies
-- File: 007_role_based_policies.sql
-- Description:
-- Replaces temporary dev policies with role-based access rules
-- for admin, manager, player, and fan.
-- Safe to re-run.
-- ============================================================

-- Helper to check the current user's role
create or replace function public.has_role(role_name text)
returns boolean
language sql
stable
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = role_name
  );
$$;

-- Ensure RLS is enabled (safe to re-run)
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

-- Drop old development policies (safe to re-run)
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

-- Drop role-based policies if re-running this migration
-- Admin full access policies
-- profiles
-- teams
-- players
-- matches
-- match_events
-- player_match_stats
-- videos
-- venues
-- match_players
-- subscription_plans
-- user_subscriptions
-- tracking_snapshots

drop policy if exists "Admin full access profiles" on public.profiles;
drop policy if exists "Admin full access teams" on public.teams;
drop policy if exists "Admin full access players" on public.players;
drop policy if exists "Admin full access matches" on public.matches;
drop policy if exists "Admin full access match events" on public.match_events;
drop policy if exists "Admin full access player match stats" on public.player_match_stats;
drop policy if exists "Admin full access videos" on public.videos;
drop policy if exists "Admin full access venues" on public.venues;
drop policy if exists "Admin full access match players" on public.match_players;
drop policy if exists "Admin full access subscription plans" on public.subscription_plans;
drop policy if exists "Admin full access user subscriptions" on public.user_subscriptions;
drop policy if exists "Admin full access tracking snapshots" on public.tracking_snapshots;

-- Manager policies
drop policy if exists "Manager full access teams" on public.teams;
drop policy if exists "Manager full access players" on public.players;
drop policy if exists "Manager full access matches" on public.matches;
drop policy if exists "Manager full access match events" on public.match_events;
drop policy if exists "Manager full access player match stats" on public.player_match_stats;
drop policy if exists "Manager read videos" on public.videos;
drop policy if exists "Manager upload videos" on public.videos;

-- Public read policies for football data
drop policy if exists "Role read teams" on public.teams;
drop policy if exists "Role read players" on public.players;
drop policy if exists "Role read matches" on public.matches;
drop policy if exists "Role read match events" on public.match_events;
drop policy if exists "Role read match players" on public.match_players;
drop policy if exists "Role read venues" on public.venues;
drop policy if exists "Role read subscription plans" on public.subscription_plans;
drop policy if exists "Role read tracking snapshots" on public.tracking_snapshots;

-- Player policies
drop policy if exists "Player read own profile" on public.profiles;
drop policy if exists "Player insert own profile" on public.profiles;
drop policy if exists "Player update own profile" on public.profiles;
drop policy if exists "Player read own stats" on public.player_match_stats;
drop policy if exists "Player read videos" on public.videos;

-- User subscription policies
drop policy if exists "Users read own subscriptions" on public.user_subscriptions;

-- ============================================================
-- Admin: full access to all tables
-- ============================================================

create policy "Admin full access profiles"
on public.profiles
for all
to authenticated
using (public.has_role('admin'))
with check (public.has_role('admin'));

create policy "Admin full access teams"
on public.teams
for all
to authenticated
using (public.has_role('admin'))
with check (public.has_role('admin'));

create policy "Admin full access players"
on public.players
for all
to authenticated
using (public.has_role('admin'))
with check (public.has_role('admin'));

create policy "Admin full access matches"
on public.matches
for all
to authenticated
using (public.has_role('admin'))
with check (public.has_role('admin'));

create policy "Admin full access match events"
on public.match_events
for all
to authenticated
using (public.has_role('admin'))
with check (public.has_role('admin'));

create policy "Admin full access player match stats"
on public.player_match_stats
for all
to authenticated
using (public.has_role('admin'))
with check (public.has_role('admin'));

create policy "Admin full access videos"
on public.videos
for all
to authenticated
using (public.has_role('admin'))
with check (public.has_role('admin'));

create policy "Admin full access venues"
on public.venues
for all
to authenticated
using (public.has_role('admin'))
with check (public.has_role('admin'));

create policy "Admin full access match players"
on public.match_players
for all
to authenticated
using (public.has_role('admin'))
with check (public.has_role('admin'));

create policy "Admin full access subscription plans"
on public.subscription_plans
for all
to authenticated
using (public.has_role('admin'))
with check (public.has_role('admin'));

create policy "Admin full access user subscriptions"
on public.user_subscriptions
for all
to authenticated
using (public.has_role('admin'))
with check (public.has_role('admin'));

create policy "Admin full access tracking snapshots"
on public.tracking_snapshots
for all
to authenticated
using (public.has_role('admin'))
with check (public.has_role('admin'));

-- ============================================================
-- Manager: read/write core football data
-- ============================================================

create policy "Manager full access teams"
on public.teams
for all
to authenticated
using (public.has_role('manager'))
with check (public.has_role('manager'));

create policy "Manager full access players"
on public.players
for all
to authenticated
using (public.has_role('manager'))
with check (public.has_role('manager'));

create policy "Manager full access matches"
on public.matches
for all
to authenticated
using (public.has_role('manager'))
with check (public.has_role('manager'));

create policy "Manager full access match events"
on public.match_events
for all
to authenticated
using (public.has_role('manager'))
with check (public.has_role('manager'));

create policy "Manager full access player match stats"
on public.player_match_stats
for all
to authenticated
using (public.has_role('manager'))
with check (public.has_role('manager'));

-- Manager can upload and view videos
create policy "Manager read videos"
on public.videos
for select
to authenticated
using (public.has_role('manager'));

create policy "Manager upload videos"
on public.videos
for insert
to authenticated
with check (public.has_role('manager'));

-- ============================================================
-- Public football data: readable by admin/manager/player/fan
-- ============================================================

create policy "Role read teams"
on public.teams
for select
to authenticated
using (
  public.has_role('admin') or public.has_role('manager') or
  public.has_role('player') or public.has_role('fan')
);

create policy "Role read players"
on public.players
for select
to authenticated
using (
  public.has_role('admin') or public.has_role('manager') or
  public.has_role('player') or public.has_role('fan')
);

create policy "Role read matches"
on public.matches
for select
to authenticated
using (
  public.has_role('admin') or public.has_role('manager') or
  public.has_role('player') or public.has_role('fan')
);

create policy "Role read match events"
on public.match_events
for select
to authenticated
using (
  public.has_role('admin') or public.has_role('manager') or
  public.has_role('player') or public.has_role('fan')
);

create policy "Role read match players"
on public.match_players
for select
to authenticated
using (
  public.has_role('admin') or public.has_role('manager') or
  public.has_role('player') or public.has_role('fan')
);

create policy "Role read venues"
on public.venues
for select
to authenticated
using (
  public.has_role('admin') or public.has_role('manager') or
  public.has_role('player') or public.has_role('fan')
);

create policy "Role read subscription plans"
on public.subscription_plans
for select
to authenticated
using (
  public.has_role('admin') or public.has_role('manager') or
  public.has_role('player') or public.has_role('fan')
);

create policy "Role read tracking snapshots"
on public.tracking_snapshots
for select
to authenticated
using (
  public.has_role('admin') or public.has_role('manager') or
  public.has_role('player') or public.has_role('fan')
);

-- ============================================================
-- Player: own profile and own stats
-- ============================================================

create policy "Player read own profile"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

create policy "Player insert own profile"
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);

create policy "Player update own profile"
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

-- Assumes player_id matches auth.uid() for player accounts
create policy "Player read own stats"
on public.player_match_stats
for select
to authenticated
using (public.has_role('player') and player_id = auth.uid());

-- Players can view videos (read only)
create policy "Player read videos"
on public.videos
for select
to authenticated
using (public.has_role('player'));

-- ============================================================
-- User subscriptions: read own only
-- ============================================================

create policy "Users read own subscriptions"
on public.user_subscriptions
for select
to authenticated
using (auth.uid() = user_id);
