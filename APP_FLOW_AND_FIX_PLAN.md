# GoalSight — App Flow, Logic Review & Fix Plan

> **Purpose:** Structured reference for fixing all broken data flows, missing features, and
> logical inconsistencies found during the full codebase audit (2026-06-17).
> The AI model is not yet integrated — all AI-output sections are skipped.
>
> **Status legend:** ✅ Working · ⚠️ Partial / wrong · ❌ Broken / missing

---

## 1. Intended App Architecture

```
Admin (Club Owner)
    └── owns exactly 1 Club (e.g. "GoalSight FC")
         ├── has N Managers (staff he invites)
         │    ├── upload match videos  →  triggers AI analysis job
         │    ├── add / manage players
         │    └── view match analysis + per-player analysis
         └── sees EVERYTHING his managers produce
                (all analyses, all player profiles, all uploads)

Fan  (public, read-only)
    └── browse clubs · standings · match analyses · player profiles
```

This model is **logically correct** and fully supported by the DB schema.
The problem is the Flutter app does not wire it up properly.

---

## 2. Role-by-Role Flow Review

### 2.1 Admin Flow

| # | Screen | Expected Behaviour | Current Reality | Broken? |
|---|--------|--------------------|-----------------|---------|
| 1 | Login | Sign in → fetch club_id from profiles → store in UserModel | Signs in → fetches role only, club_id never loaded | ❌ |
| 2 | Dashboard | Stats for HIS club only | All clubs unscoped (clubId = null passed everywhere) | ❌ |
| 3 | Managers tab | Managers belonging to HIS club | All managers in DB | ❌ |
| 4 | Squad tab | Players of HIS club | All players in DB | ❌ |
| 5 | Analytics tab | Analyses produced by HIS club's managers | All analyses in DB | ❌ |
| 6 | Player detail | Player profile + intelligence for his club | Works but unscoped | ⚠️ |
| 7 | Manager detail | Single manager drill-down | Works | ✅ |
| 8 | Notifications | Alerts scoped to his club | ✅ Scoped by recipient_id + RLS | ✅ |
| 9 | Invite Manager | Add a new manager to his club | No proper flow / coming-soon snackbar | ❌ |

**Root cause for rows 2–6:** `club_id` is never hydrated after login.
Every provider that needs it passes `null` → repositories fetch everything.

---

### 2.2 Manager Flow

| # | Screen | Expected Behaviour | Current Reality | Broken? |
|---|--------|--------------------|-----------------|---------|
| 1 | Login | Sign in → knows his club | Works via DB join in dashboard | ✅ |
| 2 | Dashboard | His club's stats | ✅ Supabase join works | ✅ |
| 3 | Upload Match | Form → create DB job → wait for AI → see result | Form exists but NEVER writes to DB. Fake timer + mock analysis | ❌ |
| 4 | Upload History | Past uploads from DB | ✅ Reads upload_jobs table | ✅ |
| 5 | Players list | His club's players with filters | ⚠️ Works but uses hardcoded club name 'GoalSight FC' | ⚠️ |
| 6 | Add Player | Form to create a player record | ❌ Screen does not exist | ❌ |
| 7 | Player Profile | Player stats + match history from DB | Match history is fake generated data, not from DB | ⚠️ |
| 8 | Match Analysis view | Full analysis detail | ✅ Reads from DB | ✅ |
| 9 | Profile / Settings | Change password, logout | ✅ Wired | ✅ |

---

### 2.3 Fan Flow

| # | Screen | Expected Behaviour | Current Reality | Broken? |
|---|--------|--------------------|-----------------|---------|
| 1 | Home | Live matches + highlights | Highlights ✅. Live matches ❌ mock (no matches table) | ⚠️ |
| 2 | Clubs | Browse all clubs, paginated | ✅ Supabase paginated | ✅ |
| 3 | Club Details | Club info + squad preview | ✅ | ✅ |
| 4 | Standings | League table sorted by points | ✅ Derived from teams table | ✅ |
| 5 | Match Analysis | Full analysis detail (read-only) | ✅ Reads from DB | ✅ |
| 6 | Player Profile | Player detail (public) | ✅ | ✅ |
| 7 | Profile / Settings | Account management | ✅ | ✅ |

---

## 3. Data Flow Audit — Why DB Is Not Working

### 3.1 club_id Never Loaded After Login

**Impact:** Every club-scoped query gets `null` → returns all data or nothing.

```
Files involved:
  lib/data/repositories/auth_repository.dart    → _hydrate() method
  lib/features/auth/auth_state.dart             → UserModel class
  lib/providers/repository_providers.dart       → adminSquadProvider, adminManagersProvider, etc.

Problem:
  - _hydrate() fetches: id, name, email, role
  - _hydrate() does NOT fetch: club_id
  - UserModel has no club_id field
  - adminSquadProvider calls squadProvider(null)          ← null club
  - adminManagersProvider calls managerListProvider('')   ← no club filter
  - adminTacticalInsightsProvider calls matchAnalysisListProvider(null) ← all analyses
```

---

### 3.2 Repository Methods Ignore club_id Parameter

**Impact:** Even when a `clubId` IS passed, repositories don't filter by it.

```
File: lib/data/repositories/supabase/supabase_analysis_repository.dart
  - fetchAnalyses(clubId) → clubId is accepted but never used in the query

File: lib/data/repositories/supabase/supabase_manager_repository.dart
  - fetchManagers(clubId, activeOnly) → clubId accepted but ignored in query

File: lib/data/repositories/supabase/supabase_player_repository.dart
  - fetchSquad(clubId) → filters by team_id only, not club tenancy
```

Note: RLS at the DB level protects data correctly, but the app fetches unscoped
sets and shows them all — this is a UX/logic bug, not a security bug.

---

### 3.3 Upload Screen Is Completely Disconnected From DB

**Impact:** Uploads never persist. The "Upload History" screen shows real DB data
but the upload wizard writes nothing to it.

```
File: lib/features/manager/screens/upload_match_screen.dart

What the screen does:
  1. Collects form data (home team, away team, score, date, file)
  2. Runs a fake timer to simulate processing stages
  3. Generates a mock MatchAnalysisModel locally
  4. Shows fake "Upload Complete" with mock results

What it SHOULD do:
  1. Collect form data
  2. Call uploadRepositoryProvider.createUploadJob(formData) → writes to upload_jobs
  3. Subscribe to watchJob(jobId) stream → shows real progress from DB
  4. On job completion → navigate to real analysis result from DB

Repository is fully implemented and ready:
  lib/data/repositories/supabase/supabase_upload_repository.dart
    - createUploadJob()  ← never called by screen
    - watchJob(jobId)    ← never subscribed to
    - updateJobStatus()  ← only called internally by backend (trigger/edge fn)
```

---

### 3.4 Players Screen Uses Hardcoded Club Name

**Impact:** Works only if 'GoalSight FC' exists in DB. Breaks for any other club.

```
File: lib/features/manager/providers/manager_players_provider.dart  (approx line 16)
  Current:  looks up club by name == 'GoalSight FC'
  Should:   looks up club by club_id from auth.user.club_id
```

---

### 3.5 Player Match History Is Fake Generated Data

**Impact:** Manager and admin see fabricated match history per player, not real data.

```
File: lib/features/manager/providers/manager_players_provider.dart
  - generateMatchHistory() creates 3 fake matches with random stats
  - Should query match_player_analysis table filtered by player_id
```

---

### 3.6 Add Player Feature Does Not Exist

**Impact:** Manager cannot add players. Players only exist via DB seed migrations.

```
Missing:
  - Screen: "Add Player" form (name, position, jersey number, image)
  - Repository method: IPlayerRepository.createPlayer()
  - Supabase implementation: INSERT into players table
  - Route: /manager/add-player
  - Entry point: FAB or button on players screen
```

---

### 3.7 Fan Live Matches Have No DB Table

**Impact:** Fan home "Live Matches" section always shows mock data.

```
File: lib/providers/app_providers.dart → fanLiveMatchesProvider
  → calls MatchRepository.fetchMatches()
  → MockMatchRepository (no real implementation)

DB has: match_analyses (completed AI results)
DB does NOT have: a matches / live_matches table

Options:
  A. Add a matches table (with status: live/upcoming/completed)
  B. Repurpose match_analyses as the matches feed (completed only)
  C. Remove "live matches" section from fan home until table exists
```

---

### 3.8 Manager Permissions Not Stored in DB

**Impact:** Admin cannot grant/revoke manager permissions — changes are lost.

```
File: lib/data/repositories/supabase/supabase_manager_repository.dart
  - updatePermissions() is a no-op

DB: managers table does NOT have permission columns
    (canUpload, canEditPlayers, canManageStaff exist only in ManagerModel)

Fix: Add permission columns to managers table OR a separate manager_permissions table
```

---

### 3.9 Google Sign-In Incomplete

**Impact:** "Continue with Google" button may crash or silently fail.

```
File: lib/data/repositories/auth_repository.dart  (line ~154)
  - webClientId is a placeholder string, not a real OAuth client ID

Fix: Configure Google Cloud OAuth credentials + set correct webClientId
```

---

## 4. What IS Working Correctly

| Feature | Provider / File | Status |
|---------|----------------|--------|
| Email login / register | auth_repository.dart | ✅ |
| Email OTP verification | auth_repository.dart | ✅ |
| Forgot password OTP | auth_repository.dart | ✅ |
| Role-based routing | router_provider.dart | ✅ |
| Clubs list (paginated) | SupabaseClubRepository | ✅ |
| League standings | standingsProvider | ✅ |
| Highlights feed | SupabaseHighlightsRepository | ✅ |
| Upload history list | SupabaseUploadRepository | ✅ |
| Admin notifications | SupabaseNotificationRepository | ✅ |
| Notification realtime | watchNotifications() stream | ✅ |
| Match analysis detail | SupabaseAnalysisRepository | ✅ |
| Player intelligence | SupabasePlayerRepository | ✅ |
| Manager dashboard stats | managerDashboardProvider | ✅ |
| DB schema + RLS design | supabase/migrations/ | ✅ |

---

## 5. Fix Plan — Prioritised

### P0 — Core DB Wiring (App Unusable Without These)

```
P0-1  Add club_id to UserModel + fetch it in _hydrate() after login
      Files: auth_repository.dart, auth_state.dart (UserModel)
      Test:  After login, user.club_id is non-null for admin and manager

P0-2  Pass club_id to all admin providers
      Files: app_providers.dart (adminSquadProvider, adminManagersProvider,
             adminTacticalInsightsProvider)
      Test:  Admin dashboard shows only his club's players/managers/analyses

P0-3  Implement club_id filtering in repository query methods
      Files: supabase_analysis_repository.dart  → add .eq('club_id', clubId)
             supabase_manager_repository.dart   → add .eq('club_id', clubId)
             supabase_player_repository.dart    → fix team_id vs club_id

P0-4  Wire upload screen to call createUploadJob() and watch the job stream
      Files: upload_match_screen.dart
             upload_repository_provider (already implemented, just not called)
      Flow:  Submit form → createUploadJob() → subscribe watchJob(id) →
             show real progress → on complete → navigate to real analysis
```

### P1 — Missing Core Features

```
P1-1  Add Player screen + repository method
      Files (new): lib/features/manager/screens/add_player_screen.dart
                   lib/data/repositories/interfaces/i_player_repository.dart (add createPlayer)
                   lib/data/repositories/supabase/supabase_player_repository.dart
      Route (new): /manager/add-player
      Entry point: FAB on players_screen.dart

P1-2  Fix manager players lookup — replace hardcoded 'GoalSight FC' with auth club_id
      File: lib/features/manager/providers/manager_players_provider.dart

P1-3  Replace fake player match history with real data from match_player_analysis table
      File: lib/features/manager/providers/manager_players_provider.dart
      Query: SELECT * FROM match_player_analysis WHERE player_id = ?

P1-4  Decide on fan live matches strategy (pick one):
      Option A — Add a matches table (recommended)
      Option B — Show match_analyses as the matches feed
      Option C — Remove live section until table is ready
```

### P2 — Secondary Issues

```
P2-1  Add permission columns to managers table
      Migration needed: ALTER TABLE managers ADD COLUMN can_upload BOOLEAN DEFAULT TRUE, ...
      Then wire: supabase_manager_repository.updatePermissions()

P2-2  Configure Google Sign-In webClientId
      File: auth_repository.dart (~line 154)
      Needs: Real OAuth client ID from Google Cloud Console + SHA-1 fingerprint

P2-3  Implement "Invite Manager" flow end-to-end
      Current: shows coming-soon snackbar
      Should:  Form → INSERT into managers table with club_id → send invite email
```

---

## 6. DB Schema Quick Reference

| Table | Purpose | Club-scoped? |
|-------|---------|-------------|
| profiles | Auth users + role + club_id | via club_id |
| teams | Club records | is the club |
| team_season_stats | League stats per club | via team_id |
| players | Player records | via team_id |
| player_intelligence | Season ratings, fatigue, insights | via player→team |
| player_risk_analysis | Risk snapshots per player | via player→team |
| managers | Staff directory | via club_id ← 036 |
| match_analyses | AI analysis results | via manager→profile→club |
| team_match_analysis | Per-team breakdown inside analysis | via analysis |
| match_player_analysis | Per-player stats inside analysis | via analysis |
| analysis_artifacts | Video/PDF artifacts per analysis | via analysis |
| upload_jobs | Job queue for uploads | via manager_id |
| notifications | Admin alerts | via club_id + recipient_id |
| highlights | Fan-facing video highlights | public |

**auth_club_id() helper function** (migration 036):
Returns `profiles.club_id` for the currently signed-in user.
Used in all RLS policies. Already in DB — just not used by app queries.

---

## 7. File Map for Each Fix

| Fix | Primary File(s) |
|-----|----------------|
| P0-1 club_id in UserModel | `lib/features/auth/auth_state.dart`, `lib/data/repositories/auth_repository.dart` |
| P0-2 admin provider scoping | `lib/providers/app_providers.dart` |
| P0-3 repo club filtering | `lib/data/repositories/supabase/supabase_analysis_repository.dart`, `supabase_manager_repository.dart`, `supabase_player_repository.dart` |
| P0-4 upload wiring | `lib/features/manager/screens/upload_match_screen.dart` |
| P1-1 add player | `lib/features/manager/screens/add_player_screen.dart` *(new)*, `lib/data/repositories/supabase/supabase_player_repository.dart` |
| P1-2 player lookup fix | `lib/features/manager/providers/manager_players_provider.dart` |
| P1-3 real match history | `lib/features/manager/providers/manager_players_provider.dart` |
| P1-4 live matches | `lib/providers/app_providers.dart`, new migration if Option A |
| P2-1 manager permissions | New migration + `supabase_manager_repository.dart` |
| P2-2 Google OAuth | `lib/data/repositories/auth_repository.dart` |
| P2-3 invite manager | New screen + `supabase_manager_repository.dart` |

---

## 8. Correct Full App Flow (Target State)

### Admin
```
Login
  → _hydrate() fetches club_id → stored in UserModel
  → Router → /admin

/admin (Dashboard)
  → adminSquadProvider(user.club_id)       → squad stats for HIS club
  → adminManagersProvider(user.club_id)    → manager count for HIS club
  → adminTacticalInsightsProvider(club_id) → analyses for HIS club

/admin/managers
  → managerListProvider(user.club_id)      → his managers only
  → tap manager → /admin/managers/:id      → manager detail

/admin/squad
  → squadProvider(user.club_id)            → his players only
  → tap player → /admin/player/:id         → player profile + intelligence

/admin/club-analytics
  → matchAnalysisListProvider(user.club_id) → his analyses only

/admin/notifications
  → notificationsProvider                  → his alerts (recipient_id scoped)
```

### Manager
```
Login
  → _hydrate() fetches club_id → stored in UserModel
  → Router → /manager

/manager (Dashboard)
  → managerDashboardProvider               → his club's stats (already correct)

/manager (Matches tab)
  → uploadHistoryProvider(user.id)         → his past jobs

/manager (Upload tab)
  → Fill form
  → createUploadJob(formData, club_id)     → INSERT upload_jobs
  → watchJob(jobId) stream                 → real progress
  → on completed → navigate to analysis result

/manager (Players tab)
  → managerPlayersProvider(user.club_id)   → his club's players (NOT hardcoded)
  → tap "Add Player" FAB → /manager/add-player
  → tap player → /manager-player-profile  → real match history from DB

/manager (Profile tab)
  → change password / logout
```

### Fan
```
Login (optional — fans may be unauthenticated)
  → Router → /fan

/fan (Home)
  → fanLiveMatchesProvider    → live/upcoming matches (needs matches table)
  → fanHighlightsProvider     → highlights (already Supabase)

/fan (Clubs tab)
  → clubsPagedProvider        → all clubs paginated (already Supabase)
  → tap club → /fan-club-details

/fan (Standings tab)
  → standingsProvider         → sorted clubs (already Supabase)

/fan (Matches tab)
  → match list                → needs matches table OR use analyses feed

/fan (Profile tab)
  → account settings, change password
```

---

*Generated: 2026-06-17 · Scope: full codebase audit · AI model integration excluded*
