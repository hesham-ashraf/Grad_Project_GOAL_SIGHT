-- ============================================================
-- Goal Sight MVP - Real Demo Data Seed
-- File: 030_real_demo_data_seed.sql
-- Description:
-- Seeds realistic football demo data for Phase 2 backend testing.
-- Safe to re-run.
-- ============================================================

-- ============================================================
-- 1) Venues
-- ============================================================

insert into public.venues (name, location, capacity)
select v.name, v.location, v.capacity
from (
  values
    ('Zewail Stadium', '6th of October City, Egypt', 5000),
    ('Cairo International Stadium', 'Nasr City, Cairo, Egypt', 75000),
    ('Alexandria Stadium', 'Alexandria, Egypt', 20000),
    ('Borg El Arab Stadium', 'Borg El Arab, Alexandria, Egypt', 86000),
    ('PetroSport Stadium', 'Cairo, Egypt', 16000),
    ('Al Salam Stadium', 'Cairo, Egypt', 30000),
    ('El Mahalla Stadium', 'El Mahalla El Kubra, Egypt', 30000),
    ('Suez Stadium', 'Suez, Egypt', 25000),
    ('Haras El Hodoud Stadium', 'Alexandria, Egypt', 22000),
    ('30 June Stadium', 'Cairo, Egypt', 30000)
) as v(name, location, capacity)
on conflict (name) do nothing;

-- ============================================================
-- 2) Subscription Plans
-- ============================================================

insert into public.subscription_plans (name, price, duration_days, features)
values
  (
    'Fan Free',
    0,
    30,
    '["View teams", "View matches", "View match summaries"]'::jsonb
  ),
  (
    'Coach Pro',
    249.99,
    30,
    '["Live analytics", "Upload videos", "Player tracking", "Advanced reports"]'::jsonb
  ),
  (
    'Club Elite',
    599.99,
    30,
    '["Multi-team access", "Priority analysis", "Video archive", "Admin tools"]'::jsonb
  )
on conflict (name) do nothing;

-- ============================================================
-- 3) Matches
-- ============================================================

with teams_cte as (
  select
    (select id from public.teams where name = 'Zewail FC') as zewail_id,
    (select id from public.teams where name = 'Cairo United') as cairo_id
),
venues_cte as (
  select id, name, row_number() over (order by name) as rn
  from public.venues
),
match_rows as (
  select * from (
    values
      (1,  '2026-05-01 18:00:00+00'::timestamptz, 'finished', 2, 1),
      (2,  '2026-05-02 18:00:00+00'::timestamptz, 'finished', 1, 1),
      (3,  '2026-05-03 19:00:00+00'::timestamptz, 'finished', 0, 2),
      (4,  '2026-05-04 18:30:00+00'::timestamptz, 'live', 1, 0),
      (5,  '2026-05-05 17:30:00+00'::timestamptz, 'scheduled', 0, 0),
      (6,  '2026-05-06 19:30:00+00'::timestamptz, 'finished', 3, 2),
      (7,  '2026-05-07 18:15:00+00'::timestamptz, 'finished', 1, 0),
      (8,  '2026-05-08 20:00:00+00'::timestamptz, 'live', 0, 0),
      (9,  '2026-05-09 18:45:00+00'::timestamptz, 'scheduled', 0, 0),
      (10, '2026-05-10 19:15:00+00'::timestamptz, 'finished', 2, 2),
      (11, '2026-05-11 18:00:00+00'::timestamptz, 'finished', 4, 1),
      (12, '2026-05-12 17:00:00+00'::timestamptz, 'scheduled', 0, 0),
      (13, '2026-05-13 18:00:00+00'::timestamptz, 'finished', 1, 3),
      (14, '2026-05-14 19:00:00+00'::timestamptz, 'live', 2, 1),
      (15, '2026-05-15 18:00:00+00'::timestamptz, 'scheduled', 0, 0),
      (16, '2026-05-16 20:00:00+00'::timestamptz, 'finished', 0, 0),
      (17, '2026-05-17 18:00:00+00'::timestamptz, 'finished', 3, 1),
      (18, '2026-05-18 19:00:00+00'::timestamptz, 'scheduled', 0, 0),
      (19, '2026-05-19 18:00:00+00'::timestamptz, 'live', 1, 1),
      (20, '2026-05-20 18:30:00+00'::timestamptz, 'finished', 2, 0)
  ) as m(ordinal, match_date, status, home_score, away_score)
)
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
  t.zewail_id,
  t.cairo_id,
  v.id,
  v.name,
  m.match_date,
  m.status,
  m.home_score,
  m.away_score
from match_rows m
cross join teams_cte t
join venues_cte v on v.rn = ((m.ordinal - 1) % 10) + 1
where not exists (
  select 1
  from public.matches existing
  where existing.home_team_id = t.zewail_id
    and existing.away_team_id = t.cairo_id
    and existing.match_date = m.match_date
    and existing.venue_id = v.id
)
order by m.match_date;

-- ============================================================
-- 4) Match Events
-- ============================================================

with event_templates as (
  select * from (
    values
      ('goal', 14, 22, 'Early goal for Zewail FC', 'Ahmed Striker'),
      ('assist', 14, 15, 'Assist leading to the opening goal', 'Youssef Winger'),
      ('foul', 38, 8, 'Midfield foul by Cairo United', 'Hassan Defender'),
      ('yellow_card', 61, 44, 'Warning for defensive challenge', 'Hassan Defender'),
      ('shot', 72, 11, 'Long-range attempt on goal', 'Omar Midfielder')
  ) as e(event_type, minute, second, description, player_name)
)
insert into public.match_events (match_id, player_id, event_type, minute, second, description)
select
  m.id,
  p.id,
  e.event_type,
  e.minute,
  e.second,
  e.description
from public.matches m
join event_templates e on true
join public.players p on p.full_name = e.player_name
where p.team_id in (m.home_team_id, m.away_team_id)
  and m.home_team_id is not null
  and m.away_team_id is not null
  and not exists (
    select 1
    from public.match_events existing
    where existing.match_id = m.id
      and existing.event_type = e.event_type
      and existing.minute = e.minute
      and existing.description = e.description
  );

-- ============================================================
-- 5) Player Match Stats
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
  s.distance_covered_m,
  s.avg_speed,
  s.max_speed,
  s.passes_completed,
  s.shots,
  s.goals,
  s.assists,
  s.fouls
from public.matches m
join public.players p on p.team_id in (m.home_team_id, m.away_team_id)
cross join lateral (
  values
    ('Ahmed Striker', 9600, 6.9, 30.1, 24, 5, 2, 0, 0),
    ('Youssef Winger', 10450, 7.3, 31.4, 31, 4, 0, 1, 0),
    ('Karim Defender', 8920, 5.8, 26.2, 18, 0, 0, 0, 1),
    ('Omar Midfielder', 10120, 6.7, 29.7, 36, 3, 1, 1, 0),
    ('Ali Goalkeeper', 4300, 5.1, 24.0, 12, 0, 0, 0, 0),
    ('Hassan Defender', 9100, 5.9, 25.8, 20, 0, 0, 0, 2),
    ('Mostafa Goalkeeper', 4150, 5.0, 23.4, 11, 0, 0, 0, 0),
    ('Tarek Forward', 9800, 6.8, 30.0, 27, 3, 1, 0, 0)
) as s(player_name, distance_covered_m, avg_speed, max_speed, passes_completed, shots, goals, assists, fouls)
where p.full_name = s.player_name
  and not exists (
    select 1
    from public.player_match_stats existing
    where existing.match_id = m.id
      and existing.player_id = p.id
  );

-- ============================================================
-- 6) Sample Subscriptions
-- ============================================================

insert into public.user_subscriptions (user_id, plan_id, status, starts_at, ends_at)
select
  p.id,
  sp.id,
  'active',
  now() - interval '7 days',
  now() + interval '23 days'
from public.profiles p
join public.subscription_plans sp on sp.name = 'Coach Pro'
where p.role in ('manager', 'admin')
  and not exists (
    select 1
    from public.user_subscriptions us
    where us.user_id = p.id
      and us.plan_id = sp.id
  );

insert into public.user_subscriptions (user_id, plan_id, status, starts_at, ends_at)
select
  p.id,
  sp.id,
  'active',
  now() - interval '2 days',
  now() + interval '28 days'
from public.profiles p
join public.subscription_plans sp on sp.name = 'Fan Free'
where p.role = 'fan'
  and not exists (
    select 1
    from public.user_subscriptions us
    where us.user_id = p.id
      and us.plan_id = sp.id
  );
