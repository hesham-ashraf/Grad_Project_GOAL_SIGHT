-- ============================================================
-- Goal Sight MVP - Seed Data
-- File: 004_seed_data.sql
-- Description:
-- Adds sample data for frontend testing, MVP demos, and backend
-- validation. This data is safe to re-run as much as possible.
-- ============================================================

-- ============================================================
-- 1) Seed Teams
-- ============================================================

-- Uses unique name constraints to prevent duplicate seed data on re-run.

insert into public.teams (name, logo_url)
values
  ('Zewail FC', null),
  ('Cairo United', null)
on conflict (name) do nothing;

-- ============================================================
-- 2) Seed Venue
-- ============================================================

insert into public.venues (name, location, capacity)
values
  ('Zewail Stadium', '6th of October City, Egypt', 5000)
on conflict (name) do nothing;

-- ============================================================
-- 3) Seed Players
-- Note:
-- We use WHERE NOT EXISTS to reduce duplicate players when re-running.
-- ============================================================

insert into public.players (team_id, full_name, position, jersey_number, height_cm, weight_kg, image_url)
select t.id, 'Ahmed Striker', 'Forward', 9, 181, 76, null
from public.teams t
where t.name = 'Zewail FC'
and not exists (
  select 1 from public.players p
  where p.full_name = 'Ahmed Striker'
);

insert into public.players (team_id, full_name, position, jersey_number, height_cm, weight_kg, image_url)
select t.id, 'Mostafa Goalkeeper', 'Goalkeeper', 1, 188, 82, null
from public.teams t
where t.name = 'Zewail FC'
and not exists (
  select 1 from public.players p
  where p.full_name = 'Mostafa Goalkeeper'
);

insert into public.players (team_id, full_name, position, jersey_number, height_cm, weight_kg, image_url)
select t.id, 'Karim Defender', 'Defender', 4, 184, 80, null
from public.teams t
where t.name = 'Zewail FC'
and not exists (
  select 1 from public.players p
  where p.full_name = 'Karim Defender'
);

insert into public.players (team_id, full_name, position, jersey_number, height_cm, weight_kg, image_url)
select t.id, 'Youssef Winger', 'Winger', 11, 176, 70, null
from public.teams t
where t.name = 'Zewail FC'
and not exists (
  select 1 from public.players p
  where p.full_name = 'Youssef Winger'
);

insert into public.players (team_id, full_name, position, jersey_number, height_cm, weight_kg, image_url)
select t.id, 'Omar Midfielder', 'Midfielder', 8, 178, 73, null
from public.teams t
where t.name = 'Cairo United'
and not exists (
  select 1 from public.players p
  where p.full_name = 'Omar Midfielder'
);

insert into public.players (team_id, full_name, position, jersey_number, height_cm, weight_kg, image_url)
select t.id, 'Ali Goalkeeper', 'Goalkeeper', 1, 190, 84, null
from public.teams t
where t.name = 'Cairo United'
and not exists (
  select 1 from public.players p
  where p.full_name = 'Ali Goalkeeper'
);

insert into public.players (team_id, full_name, position, jersey_number, height_cm, weight_kg, image_url)
select t.id, 'Hassan Defender', 'Defender', 5, 183, 79, null
from public.teams t
where t.name = 'Cairo United'
and not exists (
  select 1 from public.players p
  where p.full_name = 'Hassan Defender'
);

insert into public.players (team_id, full_name, position, jersey_number, height_cm, weight_kg, image_url)
select t.id, 'Tarek Forward', 'Forward', 10, 180, 75, null
from public.teams t
where t.name = 'Cairo United'
and not exists (
  select 1 from public.players p
  where p.full_name = 'Tarek Forward'
);

-- ============================================================
-- 4) Seed Match
-- ============================================================

insert into public.matches (
  home_team_id,
  away_team_id,
  venue_id,
  venue,
  match_date,
  status,
  home_score,
  away_score
)
select
  home_team.id,
  away_team.id,
  v.id,
  'Zewail Stadium',
  now(),
  'finished',
  2,
  1
from public.teams home_team
cross join public.teams away_team
cross join public.venues v
where home_team.name = 'Zewail FC'
and away_team.name = 'Cairo United'
and v.name = 'Zewail Stadium'
and not exists (
  select 1 from public.matches m
  where m.home_team_id = home_team.id
  and m.away_team_id = away_team.id
  and m.venue = 'Zewail Stadium'
);

-- ============================================================
-- 5) Seed Match Players
-- ============================================================

insert into public.match_players (
  match_id,
  player_id,
  team_id,
  is_starter,
  shirt_number,
  position
)
select
  m.id,
  p.id,
  p.team_id,
  true,
  p.jersey_number,
  p.position
from public.matches m
join public.players p on p.team_id in (m.home_team_id, m.away_team_id)
where m.venue = 'Zewail Stadium'
on conflict (match_id, player_id) do nothing;

-- ============================================================
-- 6) Seed Match Events
-- ============================================================

insert into public.match_events (match_id, player_id, event_type, minute, second, description)
select
  m.id,
  p.id,
  'goal',
  23,
  15,
  'Opening goal scored by Ahmed Striker'
from public.matches m
join public.players p on p.full_name = 'Ahmed Striker'
where m.venue = 'Zewail Stadium'
and not exists (
  select 1 from public.match_events e
  where e.match_id = m.id
  and e.event_type = 'goal'
  and e.minute = 23
);

insert into public.match_events (match_id, player_id, event_type, minute, second, description)
select
  m.id,
  p.id,
  'assist',
  23,
  10,
  'Assist before the opening goal'
from public.matches m
join public.players p on p.full_name = 'Youssef Winger'
where m.venue = 'Zewail Stadium'
and not exists (
  select 1 from public.match_events e
  where e.match_id = m.id
  and e.event_type = 'assist'
  and e.minute = 23
);

insert into public.match_events (match_id, player_id, event_type, minute, second, description)
select
  m.id,
  p.id,
  'foul',
  61,
  30,
  'Midfield foul committed by Hassan Defender'
from public.matches m
join public.players p on p.full_name = 'Hassan Defender'
where m.venue = 'Zewail Stadium'
and not exists (
  select 1 from public.match_events e
  where e.match_id = m.id
  and e.event_type = 'foul'
  and e.minute = 61
);

-- ============================================================
-- 7) Seed Player Match Stats
-- ============================================================

insert into public.player_match_stats (
  match_id,
  player_id,
  distance_covered_m,
  avg_speed,
  max_speed,
  passes_completed,
  shots,
  goals,
  assists,
  fouls
)
select
  m.id,
  p.id,
  9500,
  6.8,
  28.4,
  22,
  4,
  1,
  0,
  0
from public.matches m
join public.players p on p.full_name = 'Ahmed Striker'
where m.venue = 'Zewail Stadium'
on conflict (match_id, player_id) do nothing;

insert into public.player_match_stats (
  match_id,
  player_id,
  distance_covered_m,
  avg_speed,
  max_speed,
  passes_completed,
  shots,
  goals,
  assists,
  fouls
)
select
  m.id,
  p.id,
  10200,
  7.1,
  30.2,
  31,
  2,
  0,
  1,
  0
from public.matches m
join public.players p on p.full_name = 'Youssef Winger'
where m.venue = 'Zewail Stadium'
on conflict (match_id, player_id) do nothing;

insert into public.player_match_stats (
  match_id,
  player_id,
  distance_covered_m,
  avg_speed,
  max_speed,
  passes_completed,
  shots,
  goals,
  assists,
  fouls
)
select
  m.id,
  p.id,
  8700,
  5.9,
  24.8,
  18,
  0,
  0,
  0,
  1
from public.matches m
join public.players p on p.full_name = 'Hassan Defender'
where m.venue = 'Zewail Stadium'
on conflict (match_id, player_id) do nothing;

-- ============================================================
-- 8) Seed Subscription Plans
-- ============================================================

insert into public.subscription_plans (name, price, duration_days, features)
values
  (
    'Basic Fan Plan',
    0,
    30,
    '["View teams", "View matches", "View post-match reports"]'::jsonb
  ),
  (
    'Coach Pro Plan',
    299.99,
    30,
    '["Live analytics", "Video upload", "Player tracking", "Advanced reports"]'::jsonb
  )
on conflict (name) do nothing;

-- ============================================================
-- 9) Seed Tracking Snapshots
-- ============================================================

insert into public.tracking_snapshots (
  match_id,
  frame_number,
  timestamp_ms,
  object_type,
  object_id,
  x_position,
  y_position,
  speed,
  raw_data
)
select
  m.id,
  120,
  4000,
  'player',
  p.id,
  34.5,
  18.2,
  6.7,
  jsonb_build_object(
    'source', 'seed',
    'confidence', 0.94,
    'note', 'Sample AI tracking snapshot'
  )
from public.matches m
join public.players p on p.full_name = 'Ahmed Striker'
where m.venue = 'Zewail Stadium'
and not exists (
  select 1 from public.tracking_snapshots ts
  where ts.match_id = m.id
  and ts.frame_number = 120
  and ts.object_id = p.id
);

insert into public.tracking_snapshots (
  match_id,
  frame_number,
  timestamp_ms,
  object_type,
  object_id,
  x_position,
  y_position,
  speed,
  raw_data
)
select
  m.id,
  121,
  4033,
  'ball',
  null,
  41.8,
  22.6,
  12.4,
  jsonb_build_object(
    'source', 'seed',
    'confidence', 0.91,
    'note', 'Sample ball tracking snapshot'
  )
from public.matches m
where m.venue = 'Zewail Stadium'
and not exists (
  select 1 from public.tracking_snapshots ts
  where ts.match_id = m.id
  and ts.frame_number = 121
  and ts.object_type = 'ball'
);