# Goal Sight Backend Testing Checklist (Supabase)

This checklist verifies the MVP backend phases for the Goal Sight Supabase stack.
Use it during backend QA or before handoff to the frontend team.

## 1) Database Schema
- [ ] Table exists: profiles
- [ ] Table exists: teams
- [ ] Table exists: players
- [ ] Table exists: matches
- [ ] Table exists: match_events
- [ ] Table exists: player_match_stats
- [ ] Table exists: videos
- [ ] Table exists: venues
- [ ] Table exists: match_players
- [ ] Table exists: subscription_plans
- [ ] Table exists: user_subscriptions
- [ ] Table exists: tracking_snapshots

## 2) Relationships (Foreign Keys)
- [ ] profiles.id -> auth.users.id
- [ ] players.team_id -> teams.id
- [ ] matches.home_team_id -> teams.id
- [ ] matches.away_team_id -> teams.id
- [ ] matches.venue_id -> venues.id
- [ ] match_players.match_id -> matches.id
- [ ] match_players.player_id -> players.id
- [ ] match_players.team_id -> teams.id
- [ ] match_events.match_id -> matches.id
- [ ] match_events.player_id -> players.id
- [ ] player_match_stats.match_id -> matches.id
- [ ] player_match_stats.player_id -> players.id
- [ ] videos.match_id -> matches.id
- [ ] videos.uploaded_by -> profiles.id
- [ ] user_subscriptions.user_id -> profiles.id
- [ ] user_subscriptions.plan_id -> subscription_plans.id
- [ ] tracking_snapshots.match_id -> matches.id

## 3) Unique Constraints
- [ ] teams.name unique
- [ ] venues.name unique
- [ ] subscription_plans.name unique
- [ ] match_players unique(match_id, player_id)
- [ ] player_match_stats unique(match_id, player_id)

## 4) Seed Data
- [ ] teams count > 0
- [ ] players count > 0
- [ ] matches count > 0
- [ ] match_events count > 0
- [ ] player_match_stats count > 0
- [ ] subscription_plans count > 0
- [ ] tracking_snapshots count > 0

## 5) RLS Policies
- [ ] RLS enabled on all public tables
- [ ] Development read policies exist for public football data
- [ ] profiles are protected
- [ ] user_subscriptions are protected

## 6) Storage
- [ ] Bucket exists: match-videos (private)
- [ ] Bucket exists: team-logos (public)
- [ ] Bucket exists: player-images (public)

## 7) Realtime
- [ ] matches added to supabase_realtime
- [ ] match_events added to supabase_realtime
- [ ] player_match_stats added to supabase_realtime
- [ ] tracking_snapshots added to supabase_realtime
- [ ] videos added to supabase_realtime

## 8) Flutter Connectivity (Smoke Test)
- [ ] Flutter test page successfully fetched teams: Zewail FC, Cairo United

## 9) Useful SQL Testing Queries

### List all public tables
```sql
select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;
```

### Check duplicate teams, venues, and subscription plans
```sql
-- Teams
select name, count(*)
from public.teams
group by name
having count(*) > 1;

-- Venues
select name, count(*)
from public.venues
group by name
having count(*) > 1;

-- Subscription plans
select name, count(*)
from public.subscription_plans
group by name
having count(*) > 1;
```

### Check seed counts
```sql
select
  (select count(*) from public.teams) as teams,
  (select count(*) from public.players) as players,
  (select count(*) from public.matches) as matches,
  (select count(*) from public.match_events) as match_events,
  (select count(*) from public.player_match_stats) as player_match_stats,
  (select count(*) from public.subscription_plans) as subscription_plans,
  (select count(*) from public.tracking_snapshots) as tracking_snapshots;
```

### Check RLS status
```sql
select relname as table_name, relrowsecurity as rls_enabled
from pg_class
where relnamespace = 'public'::regnamespace
order by relname;
```

### Check policies
```sql
select schemaname, tablename, policyname, permissive, roles, cmd
from pg_policies
where schemaname = 'public'
order by tablename, policyname;
```

### Check storage buckets
```sql
select id, name, public
from storage.buckets
order by name;
```

### Check realtime publication tables
```sql
select schemaname, tablename
from pg_publication_tables
where pubname = 'supabase_realtime'
order by schemaname, tablename;
```

### Sample match with team names
```sql
select
  m.id,
  m.match_date,
  m.status,
  home.name as home_team,
  away.name as away_team
from public.matches m
join public.teams home on home.id = m.home_team_id
join public.teams away on away.id = m.away_team_id
order by m.match_date desc
limit 5;
```

## 10) Final Backend Definition of Done
Backend is MVP-ready when all the following are checked:
- [ ] schema exists
- [ ] relationships exist
- [ ] seed data exists
- [ ] RLS enabled
- [ ] storage buckets created
- [ ] realtime enabled
- [ ] docs completed
- [ ] frontend can fetch data
