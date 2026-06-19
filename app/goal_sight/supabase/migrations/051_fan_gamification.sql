-- ============================================================
-- Goal Sight — Fan gamification (XP / tiers / achievements)
-- File: 051_fan_gamification.sql
-- Description:
--   The fan Profile screen showed gamification (XP bar, tier badge,
--   achievements, "matches viewed / analyses read") with NO backing store —
--   pure hard-coded fiction. This adds the real tables so those numbers are
--   persisted per user:
--     • fan_stats          — xp, tier, counters (1 row per profile)
--     • achievements       — catalog of unlockable achievements (public read)
--     • user_achievements  — which achievements a user has unlocked
--   Plus a trigger to auto-create a fan_stats row for every new profile, a
--   backfill for existing profiles, and demo values for the fan demo account.
--   Idempotent.
-- ============================================================

-- ── Tables ──────────────────────────────────────────────────────────────────

create table if not exists public.fan_stats (
  user_id        uuid primary key references public.profiles(id) on delete cascade,
  xp             integer not null default 0,
  level_tier     text    not null default 'Bronze'
                   check (level_tier in ('Bronze','Silver','Gold','Platinum','Diamond')),
  xp_to_next     integer not null default 1000,
  matches_viewed integer not null default 0,
  analyses_read  integer not null default 0,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create table if not exists public.achievements (
  id          text primary key,
  title       text not null,
  description text not null,
  icon        text not null default 'emoji_events',
  xp_reward   integer not null default 0,
  sort_order  integer not null default 0
);

create table if not exists public.user_achievements (
  user_id        uuid not null references public.profiles(id) on delete cascade,
  achievement_id text not null references public.achievements(id) on delete cascade,
  unlocked_at    timestamptz not null default now(),
  primary key (user_id, achievement_id)
);

-- ── RLS ─────────────────────────────────────────────────────────────────────

alter table public.fan_stats         enable row level security;
alter table public.achievements       enable row level security;
alter table public.user_achievements  enable row level security;

drop policy if exists fan_stats_own on public.fan_stats;
create policy fan_stats_own on public.fan_stats
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists achievements_read on public.achievements;
create policy achievements_read on public.achievements
  for select to authenticated
  using (true);

drop policy if exists user_achievements_own on public.user_achievements;
create policy user_achievements_own on public.user_achievements
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- ── Auto-create a fan_stats row for every new profile ────────────────────────

create or replace function public.create_fan_stats_for_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.fan_stats (user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists trg_create_fan_stats on public.profiles;
create trigger trg_create_fan_stats
  after insert on public.profiles
  for each row execute function public.create_fan_stats_for_profile();

-- ── Backfill existing profiles ───────────────────────────────────────────────

insert into public.fan_stats (user_id)
select id from public.profiles
on conflict (user_id) do nothing;

-- ── Achievements catalog ─────────────────────────────────────────────────────

insert into public.achievements (id, title, description, icon, xp_reward, sort_order) values
  ('first_login',    'Welcome Aboard',   'Signed in to GoalSight for the first time.',      'login',          100, 1),
  ('match_explorer', 'Match Explorer',   'Viewed 25 match analyses.',                       'sports_soccer',  500, 2),
  ('analyst',        'Armchair Analyst', 'Read 20 full AI match reports.',                  'analytics',      500, 3),
  ('superfan',       'Superfan',         'Followed 3 or more clubs.',                       'favorite',       300, 4),
  ('night_owl',      'Night Owl',        'Watched a highlight reel after midnight.',        'dark_mode',      200, 5),
  ('completionist',  'Completionist',    'Unlocked every other achievement.',               'workspace_premium', 1000, 6)
on conflict (id) do update set
  title = excluded.title,
  description = excluded.description,
  icon = excluded.icon,
  xp_reward = excluded.xp_reward,
  sort_order = excluded.sort_order;

-- ── Demo values for the fan demo account (fan@goalsight.ai) ───────────────────

update public.fan_stats
set xp = 3240, level_tier = 'Gold', xp_to_next = 5000,
    matches_viewed = 47, analyses_read = 23, updated_at = now()
where user_id = 'a14fa62f-b619-4821-b256-d2da35d0a7ca';

insert into public.user_achievements (user_id, achievement_id) values
  ('a14fa62f-b619-4821-b256-d2da35d0a7ca', 'first_login'),
  ('a14fa62f-b619-4821-b256-d2da35d0a7ca', 'match_explorer'),
  ('a14fa62f-b619-4821-b256-d2da35d0a7ca', 'superfan')
on conflict (user_id, achievement_id) do nothing;

-- Follow 3 clubs so "Clubs Followed" + the Superfan achievement are real.
insert into public.user_favorite_teams (user_id, team_id) values
  ('a14fa62f-b619-4821-b256-d2da35d0a7ca', 'd4444444-4444-4444-4444-444444444444'),
  ('a14fa62f-b619-4821-b256-d2da35d0a7ca', 'e0000001-0000-0000-0000-000000000001'),
  ('a14fa62f-b619-4821-b256-d2da35d0a7ca', 'e0000002-0000-0000-0000-000000000002')
on conflict do nothing;
