-- ============================================================
-- Goal Sight MVP - Supabase Realtime Setup
-- File: realtime_setup.sql
-- Description:
-- Enables realtime updates for the main Goal Sight tables that
-- Flutter/Web clients may subscribe to during live matches.
--
-- Important:
-- Supabase Realtime works by adding tables to the
-- supabase_realtime publication.
-- ============================================================

-- ============================================================
-- 1) Enable replica identity
--
-- This allows realtime payloads to include full row data during
-- update/delete events where needed.
-- ============================================================

alter table public.matches replica identity full;
alter table public.match_events replica identity full;
alter table public.player_match_stats replica identity full;
alter table public.tracking_snapshots replica identity full;
alter table public.videos replica identity full;

-- ============================================================
-- 2) Add tables to Supabase Realtime publication
--
-- These are the tables most likely to change during match analysis.
-- ============================================================

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
    and schemaname = 'public'
    and tablename = 'matches'
  ) then
    alter publication supabase_realtime add table public.matches;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
    and schemaname = 'public'
    and tablename = 'match_events'
  ) then
    alter publication supabase_realtime add table public.match_events;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
    and schemaname = 'public'
    and tablename = 'player_match_stats'
  ) then
    alter publication supabase_realtime add table public.player_match_stats;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
    and schemaname = 'public'
    and tablename = 'tracking_snapshots'
  ) then
    alter publication supabase_realtime add table public.tracking_snapshots;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
    and schemaname = 'public'
    and tablename = 'videos'
  ) then
    alter publication supabase_realtime add table public.videos;
  end if;
end $$;

-- ============================================================
-- MVP Realtime Tables:
--
-- matches:
--   Used for live match status and score updates.
--
-- match_events:
--   Used for timeline updates such as goals, assists, fouls,
--   yellow cards, red cards, shots, and passes.
--
-- player_match_stats:
--   Used for updated player performance statistics.
--
-- tracking_snapshots:
--   Used for AI-generated tracking data samples.
--
-- videos:
--   Used for video processing status changes.
-- ============================================================