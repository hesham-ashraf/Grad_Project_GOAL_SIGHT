-- ============================================================
-- Goal Sight — Analyzed-video playback + player-profile aggregation
-- File: 044_analyzed_video_and_player_aggregation.sql
-- Description:
--   1. match_analyses.analyzed_video_url — stores the URL of the analyzed
--      (model-output) video so the app can play the analysed match.
--   2. aggregate_player_intelligence() trigger — every time a per-match player
--      verdict (match_player_analysis) is written, the player's living profile
--      (player_intelligence) is recomputed from ALL of that player's verdicts
--      in the same club: totals, average + current rating, rating history,
--      latest fatigue and trend. This is the "collect each match's player
--      analysis into the player's profile" requirement.
-- Safe to re-run.
-- ============================================================

-- 1. Output video URL on the analysis header.
alter table public.match_analyses
  add column if not exists analyzed_video_url text;

-- 2. Recompute-from-scratch aggregation (idempotent).
create or replace function public.aggregate_player_intelligence()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_player   uuid := coalesce(new.player_id, old.player_id);
  v_club     uuid;
  v_total    int;
  v_goals    int;
  v_assists  int;
  v_tackles  int;
  v_avg      numeric;
  v_current  numeric;
  v_fatigue  int;
  v_ratings  jsonb;
  v_prev     numeric;
  v_trend    text;
begin
  -- Aggregation only applies to real, identified players.
  if v_player is null then
    return new;
  end if;

  -- Tenant (club) that owns the analysis this verdict belongs to.
  select owner_club_id into v_club
  from match_analyses
  where id = coalesce(new.match_analysis_id, old.match_analysis_id);

  -- Totals + rating history across all of this player's verdicts in the club.
  select
    count(*),
    coalesce(sum(mpa.goals), 0),
    coalesce(sum(mpa.assists), 0),
    coalesce(sum(mpa.tackles), 0),
    round(coalesce(avg(mpa.rating), 0)::numeric, 2),
    coalesce(jsonb_agg(mpa.rating order by ma.created_at), '[]'::jsonb)
  into v_total, v_goals, v_assists, v_tackles, v_avg, v_ratings
  from match_player_analysis mpa
  join match_analyses ma on ma.id = mpa.match_analysis_id
  where mpa.player_id = v_player
    and (v_club is null or ma.owner_club_id is not distinct from v_club);

  -- Most-recent rating + fatigue.
  select mpa.rating, mpa.fatigue
  into v_current, v_fatigue
  from match_player_analysis mpa
  join match_analyses ma on ma.id = mpa.match_analysis_id
  where mpa.player_id = v_player
    and (v_club is null or ma.owner_club_id is not distinct from v_club)
  order by ma.created_at desc
  limit 1;

  -- Previous rating → trend.
  select mpa.rating into v_prev
  from match_player_analysis mpa
  join match_analyses ma on ma.id = mpa.match_analysis_id
  where mpa.player_id = v_player
    and (v_club is null or ma.owner_club_id is not distinct from v_club)
  order by ma.created_at desc
  offset 1 limit 1;

  v_trend := case
    when v_prev is null then 'stable'
    when v_current > v_prev + 0.2 then 'improving'
    when v_current < v_prev - 0.2 then 'declining'
    else 'stable'
  end;

  insert into player_intelligence (
    player_id, owner_club_id, current_rating, average_rating, fatigue,
    trend, total_matches, total_goals, total_assists, total_tackles,
    ratings_history, updated_at
  )
  values (
    v_player, v_club, coalesce(v_current, 0), coalesce(v_avg, 0), coalesce(v_fatigue, 0),
    v_trend, v_total, v_goals, v_assists, v_tackles,
    v_ratings, now()
  )
  on conflict (player_id) do update set
    owner_club_id   = coalesce(excluded.owner_club_id, player_intelligence.owner_club_id),
    current_rating  = excluded.current_rating,
    average_rating  = excluded.average_rating,
    fatigue         = excluded.fatigue,
    trend           = excluded.trend,
    total_matches   = excluded.total_matches,
    total_goals     = excluded.total_goals,
    total_assists   = excluded.total_assists,
    total_tackles   = excluded.total_tackles,
    ratings_history = excluded.ratings_history,
    updated_at      = now();

  return new;
end;
$$;

drop trigger if exists trg_aggregate_player_intel on public.match_player_analysis;
create trigger trg_aggregate_player_intel
  after insert or update on public.match_player_analysis
  for each row execute function public.aggregate_player_intelligence();
