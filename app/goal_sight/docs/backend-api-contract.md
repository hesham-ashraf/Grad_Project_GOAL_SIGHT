
# Goal Sight Backend API Contract (Supabase)

This document describes the Supabase backend contract for the Goal Sight MVP.
It is written for frontend teammates who will consume the database and services
from Flutter and future web clients.

## Backend Provider
Goal Sight uses Supabase as the MVP backend provider. Supabase gives us:
- PostgreSQL database
- Authentication
- Row Level Security (RLS)
- Storage buckets
- Realtime database subscriptions

## Important Frontend Rule
- Flutter/Web must use the Supabase Project URL and anon public key only.
- Never use the service_role key inside Flutter, React, or any client-side app.

## Core Tables and Queries

Below are the main tables and their purpose. Query examples are in Dart
using the Supabase Flutter client.

### profiles
**Purpose:** User profile data linked to Supabase Auth users.
**Key fields:** `id`, `full_name`, `role`, `avatar_url`.

### teams
**Purpose:** Football teams.
**Key fields:** `id`, `name`, `logo_url`.

```dart
// Fetch teams
final teams = await supabase.from('teams').select();
```

### players
**Purpose:** Player records.
**Key fields:** `id`, `team_id`, `full_name`, `position`, `jersey_number`.

```dart
// Fetch players
final players = await supabase.from('players').select();

// Fetch players by team
final playersByTeam = await supabase
	.from('players')
	.select()
	.eq('team_id', teamId);
```

### matches
**Purpose:** Match records and scores.
**Key fields:** `id`, `home_team_id`, `away_team_id`, `venue_id`, `match_date`,
`status`, `home_score`, `away_score`.

```dart
// Fetch matches
final matches = await supabase.from('matches').select();

// Fetch matches with team names
final matchesWithTeams = await supabase
	.from('matches')
	.select('*, home_team:home_team_id(name, logo_url), away_team:away_team_id(name, logo_url)');
```

### venues
**Purpose:** Stadium/venue metadata.
**Key fields:** `id`, `name`, `location`, `capacity`.

```dart
// Fetch venues
final venues = await supabase.from('venues').select();
```

### match_players
**Purpose:** Which players participated in a match.
**Key fields:** `match_id`, `player_id`, `team_id`, `is_starter`, `shirt_number`.

```dart
// Fetch match players by match
final matchPlayers = await supabase
	.from('match_players')
	.select()
	.eq('match_id', matchId);

// Fetch match players with player details
final matchPlayersWithDetails = await supabase
	.from('match_players')
	.select('*, player:player_id(full_name, position, jersey_number, image_url)')
	.eq('match_id', matchId);
```

### match_events
**Purpose:** Timeline events (goals, assists, cards, fouls, etc.).
**Key fields:** `match_id`, `player_id`, `event_type`, `minute`, `second`.

```dart
// Fetch match events
final events = await supabase
	.from('match_events')
	.select()
	.eq('match_id', matchId)
	.order('minute', ascending: true);

// Fetch match events with player
final eventsWithPlayer = await supabase
	.from('match_events')
	.select('*, player:player_id(full_name, jersey_number)')
	.eq('match_id', matchId)
	.order('minute', ascending: true);
```

### player_match_stats
**Purpose:** Per-player stats for a match.
**Key fields:** `match_id`, `player_id`, `distance_covered_m`, `passes_completed`, etc.

```dart
// Fetch player match stats
final stats = await supabase
	.from('player_match_stats')
	.select()
	.eq('match_id', matchId);

// Fetch stats with player details
final statsWithPlayer = await supabase
	.from('player_match_stats')
	.select('*, player:player_id(full_name, position, jersey_number)')
	.eq('match_id', matchId);
```

### videos
**Purpose:** Metadata for uploaded match videos (files live in storage).
**Key fields:** `match_id`, `uploaded_by`, `video_url`, `processing_status`.

```dart
// Fetch videos by match
final videos = await supabase
	.from('videos')
	.select()
	.eq('match_id', matchId);
```

### subscription_plans
**Purpose:** Subscription tiers for the app.
**Key fields:** `name`, `price`, `duration_days`, `features`.

```dart
// Fetch subscription plans
final plans = await supabase.from('subscription_plans').select();
```

### user_subscriptions
**Purpose:** Which subscription plan a user has.
**Key fields:** `user_id`, `plan_id`, `status`, `starts_at`, `ends_at`.

```dart
// Fetch current user subscriptions
final userId = supabase.auth.currentUser!.id;
final userPlans = await supabase
	.from('user_subscriptions')
	.select()
	.eq('user_id', userId);
```

### tracking_snapshots
**Purpose:** Simplified AI tracking snapshots (MVP data model).
**Key fields:** `match_id`, `frame_number`, `object_type`, `object_id`, `x_position`, `y_position`.

```dart
// Fetch tracking snapshots by match
final snapshots = await supabase
	.from('tracking_snapshots')
	.select()
	.eq('match_id', matchId);
```

## Storage Buckets
- `match-videos`: private bucket for uploaded match footage
- `team-logos`: public bucket for team logo images
- `player-images`: public bucket for player profile images

Production should restrict match video upload and access to admins/coaches.

## Realtime Tables
Realtime is enabled for:
- `matches`
- `match_events`
- `player_match_stats`
- `tracking_snapshots`
- `videos`

```dart
// Listen to inserted match events
final matchEventsChannel = supabase
	.channel('public:match_events')
	.onPostgresChanges(
	  event: PostgresChangeEvent.insert,
	  schema: 'public',
	  table: 'match_events',
	  callback: (payload) {
		// Handle new event
	  },
	)
	.subscribe();

// Listen to updated matches
final matchesChannel = supabase
	.channel('public:matches')
	.onPostgresChanges(
	  event: PostgresChangeEvent.update,
	  schema: 'public',
	  table: 'matches',
	  callback: (payload) {
		// Handle match updates
	  },
	)
	.subscribe();
```

## RLS Development Notes
- Temporary anon read policies are enabled during MVP development for public football data.
- These are for development only.
- Before production, replace them with role-based policies.

## Production Security TODO
- Remove temporary anon read policies.
- Add admin role policies.
- Add coach role policies.
- Add player role policies.
- Add fan read-only policies.
- Restrict video upload to admins/coaches.
- Restrict private match video access.
- Keep service_role key only in secure server-side environments.
