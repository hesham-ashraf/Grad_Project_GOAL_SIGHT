-- ============================================================
-- Goal Sight MVP - Backend Extension Tables
-- File: 002_backend_extensions.sql
-- Description:
-- This file extends the initial schema with extra backend tables
-- needed for admin management, match squads, subscriptions,
-- venues, and AI/tracking output snapshots.
-- ============================================================

-- Enable UUID generation
create extension if not exists "pgcrypto";

-- ============================================================
-- 1) Venues Table
-- Purpose:
-- Stores stadium/venue information.
-- Used by admins when configuring matches.
-- ============================================================

create table if not exists public.venues (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  location text,
  capacity int,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 2) Add venue_id to matches
-- Purpose:
-- Links each match to a venue.
-- The old text column "venue" can still exist for simple MVP display.
-- ============================================================

alter table public.matches
add column if not exists venue_id uuid references public.venues(id) on delete set null;

-- ============================================================
-- 3) Match Players Table
-- Purpose:
-- Stores the squad/player participation for each match.
-- This allows the system to know which players appeared in a match,
-- their shirt number, role, and whether they started.
-- ============================================================

create table if not exists public.match_players (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches(id) on delete cascade,
  player_id uuid not null references public.players(id) on delete cascade,
  team_id uuid references public.teams(id) on delete set null,
  is_starter boolean not null default false,
  shirt_number int,
  position text,
  created_at timestamptz not null default now(),

  unique(match_id, player_id)
);

-- ============================================================
-- 4) Subscription Plans Table
-- Purpose:
-- Stores available subscription plans.
-- This supports the admin management requirement from the report.
-- ============================================================

create table if not exists public.subscription_plans (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  price numeric(10, 2) not null default 0,
  duration_days int not null default 30,
  features jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 5) User Subscriptions Table
-- Purpose:
-- Stores which subscription plan each user has.
-- ============================================================

create table if not exists public.user_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  plan_id uuid references public.subscription_plans(id) on delete set null,
  status text not null default 'active',
  starts_at timestamptz not null default now(),
  ends_at timestamptz,

  constraint user_subscriptions_status_check
  check (status in ('active', 'expired', 'cancelled'))
);

-- ============================================================
-- 6) Tracking Snapshots Table
-- Purpose:
-- Stores simplified frame-level tracking data produced by the AI pipeline.
-- For the MVP, this allows the app to display tracking/analytics samples
-- without needing a separate MongoDB service yet.
-- raw_data can store the original AI payload as JSONB.
-- ============================================================

create table if not exists public.tracking_snapshots (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches(id) on delete cascade,
  frame_number int,
  timestamp_ms int,
  object_type text not null,
  object_id uuid,
  x_position float8,
  y_position float8,
  speed float8,
  raw_data jsonb,
  created_at timestamptz not null default now(),

  constraint tracking_snapshots_object_type_check
  check (object_type in ('player', 'ball', 'referee'))
);

-- ============================================================
-- Helpful indexes for common queries
-- ============================================================

create index if not exists idx_players_team_id
on public.players(team_id);

create index if not exists idx_matches_home_team_id
on public.matches(home_team_id);

create index if not exists idx_matches_away_team_id
on public.matches(away_team_id);

create index if not exists idx_matches_venue_id
on public.matches(venue_id);

create index if not exists idx_match_events_match_id
on public.match_events(match_id);

create index if not exists idx_player_match_stats_match_id
on public.player_match_stats(match_id);

create index if not exists idx_match_players_match_id
on public.match_players(match_id);

create index if not exists idx_match_players_player_id
on public.match_players(player_id);

create index if not exists idx_tracking_snapshots_match_id
on public.tracking_snapshots(match_id);

create index if not exists idx_tracking_snapshots_object_type
on public.tracking_snapshots(object_type);


-- ============================================================
-- Unique constraints for safe seed re-runs
-- ============================================================

-- These unique constraints prevent duplicate seed data when migrations are re-run.

alter table public.venues
add constraint venues_name_unique unique (name);

alter table public.subscription_plans
add constraint subscription_plans_name_unique unique (name);