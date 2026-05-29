-- ============================================================
-- Goal Sight MVP - Player/Profile Mapping
-- File: 009_player_profile_mapping.sql
-- Description:
-- Adds a nullable profile_id to players to link a player record
-- to a Supabase profile. Safe to re-run.
-- ============================================================

-- Add profile_id column if missing
alter table public.players
add column if not exists profile_id uuid;

-- Add FK constraint if missing (safe to re-run)
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'players_profile_id_fkey'
  ) then
    alter table public.players
      add constraint players_profile_id_fkey
      foreign key (profile_id)
      references public.profiles(id)
      on delete set null;
  end if;
end $$;

-- Index for faster lookups by profile_id
create index if not exists idx_players_profile_id
on public.players(profile_id);
