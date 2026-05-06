-- ============================================================
-- Goal Sight MVP - Initial Database Schema
-- File: 001_initial_schema.sql
-- Description:
-- This file creates the core database tables required for the
-- Goal Sight MVP backend using Supabase PostgreSQL.
-- ============================================================

-- Enable UUID generation
create extension if not exists "pgcrypto";

-- ============================================================
-- 1) Profiles Table
-- Purpose:
-- Stores extra user information connected to Supabase Auth users.
-- Each profile row has the same ID as the user inside auth.users.
-- ============================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null default 'fan',
  avatar_url text,
  created_at timestamptz not null default now(),

  constraint profiles_role_check
  check (role in ('admin', 'coach', 'player', 'fan'))
);

-- ============================================================
-- 2) Teams Table
-- Purpose:
-- Stores football teams that appear in the system.
-- Used by Flutter and Web to display teams and match participants.
-- ============================================================

create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  -- Unique team names prevent duplicate seed data on re-run.
  name text not null unique,
  logo_url text,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 3) Players Table
-- Purpose:
-- Stores player information.
-- Each player can optionally belong to a team.
-- ============================================================

create table if not exists public.players (
  id uuid primary key default gen_random_uuid(),
  team_id uuid references public.teams(id) on delete set null,
  full_name text not null,
  position text,
  jersey_number int,
  height_cm int,
  weight_kg int,
  image_url text,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 4) Matches Table
-- Purpose:
-- Stores football match information.
-- Each match has a home team, away team, score, date, venue, and status.
-- ============================================================

create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  home_team_id uuid references public.teams(id) on delete set null,
  away_team_id uuid references public.teams(id) on delete set null,
  match_date timestamptz,
  venue text,
  status text not null default 'scheduled',
  home_score int not null default 0,
  away_score int not null default 0,
  created_at timestamptz not null default now(),

  constraint matches_status_check
  check (status in ('scheduled', 'live', 'finished'))
);

-- ============================================================
-- 5) Match Events Table
-- Purpose:
-- Stores match timeline events such as goals, assists, fouls, cards, etc.
-- This table will later receive AI-generated events.
-- ============================================================

create table if not exists public.match_events (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches(id) on delete cascade,
  player_id uuid references public.players(id) on delete set null,
  event_type text not null,
  minute int,
  second int,
  description text,
  created_at timestamptz not null default now(),

  constraint match_events_type_check
  check (
    event_type in (
      'goal',
      'assist',
      'foul',
      'yellow_card',
      'red_card',
      'shot',
      'pass'
    )
  )
);

-- ============================================================
-- 6) Player Match Stats Table
-- Purpose:
-- Stores per-player statistics for each match.
-- Used for player analytics screens and match reports.
-- ============================================================

create table if not exists public.player_match_stats (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches(id) on delete cascade,
  player_id uuid not null references public.players(id) on delete cascade,
  distance_covered_m float8 default 0,
  avg_speed float8 default 0,
  max_speed float8 default 0,
  passes_completed int default 0,
  shots int default 0,
  goals int default 0,
  assists int default 0,
  fouls int default 0,
  created_at timestamptz not null default now(),

  unique(match_id, player_id)
);

-- ============================================================
-- 7) Videos Table
-- Purpose:
-- Stores video metadata for uploaded match footage.
-- The actual files should be stored in Supabase Storage.
-- ============================================================

create table if not exists public.videos (
  id uuid primary key default gen_random_uuid(),
  match_id uuid references public.matches(id) on delete cascade,
  uploaded_by uuid references public.profiles(id) on delete set null,
  video_url text not null,
  file_name text,
  processing_status text not null default 'uploaded',
  created_at timestamptz not null default now(),

  constraint videos_status_check
  check (processing_status in ('uploaded', 'processing', 'completed', 'failed'))
);