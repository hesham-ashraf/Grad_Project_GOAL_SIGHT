-- ============================================================
-- Goal Sight — Player squad/view-model fields
-- File: 021_player_squad_fields.sql
-- Description:
--   Adds the denormalized season/display fields the Flutter `ClubPlayer`
--   view-model needs (rating, season goals/assists, market value, tier, ...),
--   so the Supabase ClubRepository can reconstruct a club squad.
-- Safe to re-run.
-- ============================================================

alter table public.players add column if not exists nationality         text;
alter table public.players add column if not exists age                 integer;
alter table public.players add column if not exists market_value        text;
alter table public.players add column if not exists is_captain          boolean not null default false;
alter table public.players add column if not exists appearances         integer not null default 0;
alter table public.players add column if not exists season_goals        integer not null default 0;
alter table public.players add column if not exists season_assists      integer not null default 0;
alter table public.players add column if not exists season_tackles      integer not null default 0;
alter table public.players add column if not exists season_clean_sheets integer not null default 0;
alter table public.players add column if not exists season_rating       numeric(4,2);
alter table public.players add column if not exists performance_tier    text
  check (performance_tier in ('elite','good','average','poor','critical'));
alter table public.players add column if not exists performance_summary text;
