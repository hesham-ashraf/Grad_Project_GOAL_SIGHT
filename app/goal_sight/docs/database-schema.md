
# Goal Sight Database Schema (Supabase)

## Overview
Goal Sight uses Supabase PostgreSQL as the shared database layer for the Flutter
mobile app and a future web dashboard. Supabase also provides Auth, RLS, Storage,
and Realtime for the MVP backend.

## Why UUIDs Are Used
UUIDs are used as primary keys because they scale well across distributed
clients (mobile, web) and future backend/AI services. They avoid collisions
and do not require a centralized ID generator.

## Main Entities and Relationships

### profiles
**Purpose:** Stores user profile data linked to Supabase Auth users.
**Important fields:** `id`, `full_name`, `role`, `avatar_url`, `created_at`.
**Relationships:** `profiles.id -> auth.users.id`.

### teams
**Purpose:** Teams used in matches and player rosters.
**Important fields:** `id`, `name`, `logo_url`.
**Relationships:**
- `teams.id -> players.team_id`
- `teams.id -> matches.home_team_id`
- `teams.id -> matches.away_team_id`
- `teams.id -> match_players.team_id`

### players
**Purpose:** Player records.
**Important fields:** `id`, `team_id`, `full_name`, `position`, `jersey_number`.
**Relationships:**
- `players.id -> match_players.player_id`
- `players.id -> match_events.player_id`
- `players.id -> player_match_stats.player_id`

### matches
**Purpose:** Match records and scores.
**Important fields:** `id`, `home_team_id`, `away_team_id`, `venue_id`,
`match_date`, `status`, `home_score`, `away_score`.
**Relationships:**
- `matches.id -> match_players.match_id`
- `matches.id -> match_events.match_id`
- `matches.id -> player_match_stats.match_id`
- `matches.id -> videos.match_id`
- `matches.id -> tracking_snapshots.match_id`

### venues
**Purpose:** Stadium/venue metadata.
**Important fields:** `id`, `name`, `location`, `capacity`.
**Relationships:** `venues.id -> matches.venue_id`.

### match_players
**Purpose:** Join table for which players appeared in a match.
**Important fields:** `match_id`, `player_id`, `team_id`, `is_starter`.
**Relationships:**
- `match_players.match_id -> matches.id`
- `match_players.player_id -> players.id`
- `match_players.team_id -> teams.id`

### match_events
**Purpose:** Timeline events (goals, assists, cards, fouls, etc.).
**Important fields:** `match_id`, `player_id`, `event_type`, `minute`, `second`.
**Relationships:**
- `match_events.match_id -> matches.id`
- `match_events.player_id -> players.id`

### player_match_stats
**Purpose:** Per-player stats in a match.
**Important fields:** `match_id`, `player_id`, `distance_covered_m`,
`passes_completed`, `goals`, `assists`.
**Relationships:**
- `player_match_stats.match_id -> matches.id`
- `player_match_stats.player_id -> players.id`

### videos
**Purpose:** Metadata for match video uploads (actual files are in storage).
**Important fields:** `match_id`, `uploaded_by`, `video_url`, `processing_status`.
**Relationships:**
- `videos.match_id -> matches.id`
- `videos.uploaded_by -> profiles.id`

### subscription_plans
**Purpose:** Defines subscription tiers.
**Important fields:** `name`, `price`, `duration_days`, `features`.
**Relationships:** `subscription_plans.id -> user_subscriptions.plan_id`.

### user_subscriptions
**Purpose:** Tracks which plan a user has.
**Important fields:** `user_id`, `plan_id`, `status`, `starts_at`, `ends_at`.
**Relationships:**
- `user_subscriptions.user_id -> profiles.id`
- `user_subscriptions.plan_id -> subscription_plans.id`

### tracking_snapshots
**Purpose:** Simplified AI tracking data for MVP analytics.
**Important fields:** `match_id`, `frame_number`, `object_type`, `object_id`,
`x_position`, `y_position`, `speed`.
**Relationships:** `tracking_snapshots.match_id -> matches.id`.

## Constraints
- `teams.name` is unique
- `venues.name` is unique
- `subscription_plans.name` is unique
- `match_players` has `unique(match_id, player_id)`
- `player_match_stats` has `unique(match_id, player_id)`

## Status and Type Allowed Values
- `matches.status`: `scheduled`, `live`, `finished`
- `match_events.event_type`: `goal`, `assist`, `foul`, `yellow_card`, `red_card`, `shot`, `pass`
- `videos.processing_status`: `uploaded`, `processing`, `completed`, `failed`
- `user_subscriptions.status`: `active`, `expired`, `cancelled`
- `tracking_snapshots.object_type`: `player`, `ball`, `referee`

## Storage Buckets
- `match-videos`
- `team-logos`
- `player-images`

## Realtime Enabled Tables
- `matches`
- `match_events`
- `player_match_stats`
- `tracking_snapshots`
- `videos`

## Why Supabase/PostgreSQL Was Selected
- PostgreSQL relational database
- built-in auth
- RLS
- storage
- realtime
- easy Flutter/Web integration

## MVP Limitation
`tracking_snapshots` stores simplified AI tracking data inside PostgreSQL for
the MVP. In production, high-volume frame-by-frame tracking may move to
NoSQL or time-series storage.
