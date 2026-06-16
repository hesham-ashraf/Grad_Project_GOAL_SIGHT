# GOALSIGHT MOBILE APP - DEVELOPMENT ROADMAP

This roadmap tracks the remaining work to fully complete the GoalSight app.

Status rules:
- `[x]` = implemented in the codebase
- `[ ]` = still pending
- `Sign-off` = fill your initials or name when you complete or verify the task

Recommended sign-off format:
- `Sign-off: AH | Date: 2026-05-27`

Last reviewed against the codebase: `2026-06-16`

---

## Phase Overview

### Phase 1 - Flutter Frontend
- Focus: authentication, UI system, fan role, manager role, admin role, mock data, UX polish

### Phase 2 - Backend + Supabase
- Focus: Supabase setup, database design, auth integration, data integration, storage, realtime

### Phase 3 - AI Integration
- Focus: AI API, analysis, visualizations, player intelligence

### Phase 4 - Production Polish
- Focus: performance, security, testing, deployment

---

## PHASE 1 - COMPLETE FLUTTER FRONTEND

### Goal

Finish the full Flutter application visually and functionally with realistic mock data before completing backend and AI integration.

### 1. Authentication Flow

- [x] Build Forgot Password flow | Sign-off: ______ | Date: ______
- [x] Build Email Verification flow | Sign-off: ______ | Date: ______
- [x] Add Splash Screen | Sign-off: ______ | Date: ______
- [x] Add Session Loading Screen | Sign-off: ______ | Date: ______
- [x] Add Logout Flow | Sign-off: ______ | Date: ______
- [x] Add Better Error States | Sign-off: AH | Date: 2026-05-29
- [x] Add Better Loading States | Sign-off: AH | Date: 2026-05-29
- [x] Add Route Protection UX | Sign-off: ______ | Date: ______
- [ ] Add Onboarding Flow (optional) | Sign-off: ______ | Date: ______

### 2. Global UI / Design System

#### Shared Components

- [x] Create reusable analytics cards | Sign-off: ______ | Date: ______
- [x] Create reusable tactical insight cards | Sign-off: ______ | Date: ______
- [x] Create reusable AI recommendation cards | Sign-off: ______ | Date: ______
- [x] Create reusable match cards | Sign-off: ______ | Date: ______
- [x] Create reusable player cards | Sign-off: ______ | Date: ______
- [x] Create reusable risk badges | Sign-off: ______ | Date: ______
- [x] Create reusable stat widgets | Sign-off: ______ | Date: ______
- [x] Create reusable chart wrappers | Sign-off: ______ | Date: ______
- [x] Create reusable section headers | Sign-off: ______ | Date: ______
- [x] Create reusable glassmorphism containers | Sign-off: ______ | Date: ______

#### App States

- [x] Create loading skeletons | Sign-off: ______ | Date: ______
- [x] Create empty states | Sign-off: ______ | Date: ______
- [x] Create error states | Sign-off: ______ | Date: ______
- [x] Create retry states | Sign-off: ______ | Date: ______
- [x] Create offline states | Sign-off: ______ | Date: ______

#### Animations

- [x] Add staggered reveal animations | Sign-off: ______ | Date: ______
- [x] Add smooth page transitions | Sign-off: ______ | Date: ______
- [x] Add animated cards | Sign-off: ______ | Date: ______
- [x] Add shimmer loading animations | Sign-off: AH | Date: 2026-05-29
- [x] Add animated tactical widgets | Sign-off: ______ | Date: ______
- [x] Add animated AI sections | Sign-off: ______ | Date: ______

#### Responsiveness

- [x] Optimize tablet layouts | Sign-off: ______ | Date: ______
- [x] Optimize landscape layouts | Sign-off: ______ | Date: ______
- [x] Fix all overflow issues | Sign-off: ______ | Date: ______
- [x] Improve responsive charts | Sign-off: ______ | Date: ______
- [x] Improve adaptive grids | Sign-off: ______ | Date: ______

### 3. Fan Role

#### Fan Home

- [x] Add live animated indicators | Sign-off: ______ | Date: ______
- [x] Add trending matches section | Sign-off: ______ | Date: ______
- [x] Add tactical insight section | Sign-off: ______ | Date: ______
- [x] Add AI recommendations section | Sign-off: ______ | Date: ______
- [x] Add animated stats cards | Sign-off: ______ | Date: ______
- [x] Improve featured match experience | Sign-off: ______ | Date: ______

#### Matches Screen

- [x] Add search functionality | Sign-off: ______ | Date: ______
- [x] Add league filtering | Sign-off: ______ | Date: ______
- [x] Add date filtering | Sign-off: ______ | Date: ______
- [x] Add match intensity indicators | Sign-off: ______ | Date: ______
- [x] Improve match cards UI | Sign-off: ______ | Date: ______
- [x] Add match status badges | Sign-off: ______ | Date: ______

#### Match Analysis Screen

- [x] Add tactical summary section | Sign-off: ______ | Date: ______
- [x] Add team comparison analytics | Sign-off: ______ | Date: ______
- [x] Add possession charts | Sign-off: ______ | Date: ______
- [x] Add momentum graphs | Sign-off: ______ | Date: ______
- [x] Add tactical strengths section | Sign-off: ______ | Date: ______
- [x] Add tactical weaknesses section | Sign-off: ______ | Date: ______
- [x] Add attack zones visualization | Sign-off: ______ | Date: ______
- [x] Add coach recommendations | Sign-off: ______ | Date: ______
- [x] Add player impact analysis | Sign-off: ______ | Date: ______
- [x] Add fatigue analysis | Sign-off: ______ | Date: ______
- [x] Add risk analysis | Sign-off: ______ | Date: ______
- [x] Add heatmaps | Sign-off: ______ | Date: ______
- [x] Add formation visualizations | Sign-off: ______ | Date: ______
- [x] Add bird-eye tactical section | Sign-off: ______ | Date: ______
- [x] Add AI insights cards | Sign-off: ______ | Date: ______

#### Clubs Experience

- [x] Add club tactical identity section | Sign-off: ______ | Date: ______
- [x] Add club analytics dashboard | Sign-off: ______ | Date: ______
- [x] Add performance trend charts | Sign-off: ______ | Date: ______
- [x] Add recent analyses section | Sign-off: ______ | Date: ______
- [x] Add top players section | Sign-off: ______ | Date: ______
- [x] Add tactical summaries | Sign-off: ______ | Date: ______

#### Player Profile Screen

- [x] Add rating progression charts | Sign-off: ______ | Date: ______
- [x] Add speed analytics | Sign-off: ______ | Date: ______
- [x] Add distance analytics | Sign-off: ______ | Date: ______
- [x] Add fatigue indicators | Sign-off: ______ | Date: ______
- [x] Add workload analysis | Sign-off: ______ | Date: ______
- [x] Add consistency analysis | Sign-off: ______ | Date: ______
- [x] Add tactical contribution section | Sign-off: ______ | Date: ______
- [x] Add strengths and weaknesses | Sign-off: ______ | Date: ______
- [x] Add AI insights section | Sign-off: ______ | Date: ______
- [x] Add match-by-match history | Sign-off: ______ | Date: ______
- [x] Add risk analysis dashboard | Sign-off: ______ | Date: ______
- [x] Add season intelligence summary | Sign-off: ______ | Date: ______

#### Fan Profile

- [x] Add notifications settings | Sign-off: ______ | Date: ______
- [x] Add favorites system | Sign-off: ______ | Date: ______
- [x] Add saved matches | Sign-off: ______ | Date: ______
- [x] Add preferences/settings | Sign-off: ______ | Date: ______
- [x] Add account management | Sign-off: ______ | Date: ______

### 4. Manager Role

#### Manager Dashboard

- [x] Add tactical recommendations | Sign-off: ______ | Date: ______
- [x] Add fatigue alerts | Sign-off: ______ | Date: ______
- [x] Add underperforming players section | Sign-off: ______ | Date: ______
- [x] Add AI insight feed | Sign-off: ______ | Date: ______
- [x] Add tactical identity overview | Sign-off: ______ | Date: ______
- [x] Add club analytics widgets | Sign-off: ______ | Date: ______
- [x] Add performance trend charts | Sign-off: ______ | Date: ______

#### Upload Workflow

##### Upload Screen

- [x] Build dedicated upload page | Sign-off: ______ | Date: ______
- [x] Add video picker | Sign-off: ______ | Date: ______
- [x] Add drag and drop UI | Sign-off: ______ | Date: ______
- [x] Add team selection form | Sign-off: ______ | Date: ______
- [x] Add match metadata form | Sign-off: ______ | Date: ______
- [x] Add upload confirmation flow | Sign-off: ______ | Date: ______

##### AI Processing Experience

- [x] Create upload progress screen | Sign-off: ______ | Date: ______
- [x] Create AI processing animations | Sign-off: ______ | Date: ______
- [x] Create staged progress system | Sign-off: ______ | Date: ______

##### Processing Stages
- [x] Detecting players... | Sign-off: ______ | Date: ______
- [x] Tracking ball... | Sign-off: ______ | Date: ______
- [x] Estimating possession... | Sign-off: ______ | Date: ______
- [x] Calculating speed... | Sign-off: ______ | Date: ______
- [x] Generating tactical insights... | Sign-off: ______ | Date: ______
- [x] Finalizing report... | Sign-off: ______ | Date: ______

##### Upload Results

- [x] Create analysis completed screen | Sign-off: ______ | Date: ______
- [x] Create upload failed screen | Sign-off: ______ | Date: ______
- [x] Create retry upload flow | Sign-off: ______ | Date: ______
- [x] Create upload success animations | Sign-off: ______ | Date: ______

#### Upload History

- [x] Build upload history page | Sign-off: ______ | Date: ______
- [x] Add processing status badges | Sign-off: ______ | Date: ______
- [x] Add completed analyses list | Sign-off: ______ | Date: ______
- [x] Add failed uploads list | Sign-off: ______ | Date: ______
- [x] Add upload filtering/search | Sign-off: ______ | Date: ______

#### Match Analysis Dashboard

- [x] Add tactical identity section | Sign-off: ______ | Date: ______
- [x] Add possession analytics | Sign-off: ______ | Date: ______
- [x] Add team comparison charts | Sign-off: ______ | Date: ______
- [x] Add tactical strengths | Sign-off: ______ | Date: ______
- [x] Add tactical weaknesses | Sign-off: ______ | Date: ______
- [x] Add attack zones visualization | Sign-off: ______ | Date: ______
- [x] Add risk analysis dashboard | Sign-off: ______ | Date: ______
- [x] Add fatigue analytics | Sign-off: ______ | Date: ______
- [x] Add player impact analysis | Sign-off: ______ | Date: ______
- [x] Add coach recommendations | Sign-off: ______ | Date: ______
- [x] Add AI-generated insights | Sign-off: ______ | Date: ______
- [x] Add momentum charts | Sign-off: ______ | Date: ______
- [x] Add heatmaps | Sign-off: ______ | Date: ______
- [x] Add formation maps | Sign-off: ______ | Date: ______
- [x] Add bird-eye tactical views | Sign-off: ______ | Date: ______
- [x] Add pressure maps | Sign-off: ______ | Date: ______
- [x] Add passing networks | Sign-off: ______ | Date: ______

#### Players Intelligence System

##### Players Overview

- [x] Add search system | Sign-off: ______ | Date: ______
- [x] Add filters | Sign-off: ______ | Date: ______
- [x] Add sorting system | Sign-off: ______ | Date: ______
- [x] Add risk indicators | Sign-off: ______ | Date: ______
- [x] Add fatigue ranking | Sign-off: ______ | Date: ______
- [x] Add performance ranking | Sign-off: ______ | Date: ______

##### Player Intelligence Page

- [x] Add performance charts | Sign-off: ______ | Date: ______
- [x] Add workload analysis | Sign-off: ______ | Date: ______
- [x] Add fatigue analysis | Sign-off: ______ | Date: ______
- [x] Add consistency analysis | Sign-off: ______ | Date: ______
- [x] Add tactical contribution | Sign-off: ______ | Date: ______
- [x] Add AI insights | Sign-off: ______ | Date: ______
- [x] Add match history | Sign-off: ______ | Date: ______
- [x] Add strengths and weaknesses | Sign-off: ______ | Date: ______
- [x] Add risk analysis | Sign-off: ______ | Date: ______
- [x] Add performance progression | Sign-off: ______ | Date: ______

### 5. Admin Role

#### Admin Dashboard

- [x] Improve tactical analytics | Sign-off: ______ | Date: ______
- [x] Improve AI insights feed | Sign-off: ______ | Date: ______
- [x] Add better activity feed | Sign-off: ______ | Date: ______
- [x] Add squad condition analytics | Sign-off: ______ | Date: ______
- [x] Add advanced quick actions | Sign-off: ______ | Date: ______
- [x] Add alerts system | Sign-off: ______ | Date: ______

#### Managers Management

- [x] Add Add Manager flow | Sign-off: ______ | Date: ______
- [x] Add Remove Manager flow | Sign-off: ______ | Date: ______
- [x] Add permissions management UI | Sign-off: ______ | Date: ______
- [x] Add enable/disable access | Sign-off: ______ | Date: ______
- [x] Add manager activity analytics | Sign-off: ______ | Date: ______
- [x] Add manager search/filter | Sign-off: ______ | Date: ______

#### Manager Details

- [x] Add upload analytics | Sign-off: ______ | Date: ______
- [x] Add activity history | Sign-off: ______ | Date: ______
- [x] Add performance charts | Sign-off: ______ | Date: ______
- [x] Add permissions controls | Sign-off: ______ | Date: ______
- [x] Add manager statistics | Sign-off: ______ | Date: ______

#### Squad Intelligence

- [x] Add player intelligence overview | Sign-off: ______ | Date: ______
- [x] Add risk rankings | Sign-off: ______ | Date: ______
- [x] Add fatigue rankings | Sign-off: ______ | Date: ______
- [x] Add tactical contribution analytics | Sign-off: ______ | Date: ______
- [x] Add player performance overview | Sign-off: ______ | Date: ______

#### Club Analytics

- [x] Add tactical evolution charts | Sign-off: ______ | Date: ______
- [x] Add performance trends | Sign-off: ______ | Date: ______
- [x] Add season analytics | Sign-off: ______ | Date: ______
- [x] Add tactical identity section | Sign-off: ______ | Date: ______
- [x] Add fatigue overview | Sign-off: ______ | Date: ______
- [x] Add match intensity analytics | Sign-off: ______ | Date: ______

#### Admin Profile

- [x] Add club settings | Sign-off: ______ | Date: ______
- [x] Add security settings | Sign-off: ______ | Date: ______
- [x] Add notification settings | Sign-off: ______ | Date: ______
- [x] Add admin preferences | Sign-off: ______ | Date: ______

### 6. Mock Data Architecture

#### Models

- [x] Create ClubModel | Sign-off: ______ | Date: ______
- [x] Create PlayerModel | Sign-off: ______ | Date: ______
- [x] Create MatchModel | Sign-off: ______ | Date: ______
- [x] Create MatchAnalysisModel | Sign-off: ______ | Date: ______
- [x] Create UploadJobModel | Sign-off: ______ | Date: ______
- [x] Create TacticalInsightModel | Sign-off: ______ | Date: ______
- [x] Create RiskAnalysisModel | Sign-off: ______ | Date: ______
- [x] Create ManagerModel | Sign-off: ______ | Date: ______
- [x] Create ActivityModel | Sign-off: ______ | Date: ______

#### Mock Repositories

- [x] Create clubs repository | Sign-off: ______ | Date: ______
- [x] Create players repository | Sign-off: ______ | Date: ______
- [x] Create matches repository | Sign-off: ______ | Date: ______
- [x] Create analysis repository | Sign-off: ______ | Date: ______
- [x] Create uploads repository | Sign-off: ______ | Date: ______
- [x] Create managers repository | Sign-off: ______ | Date: ______

#### Realistic Mock Data

- [x] Create realistic clubs | Sign-off: ______ | Date: ______
- [x] Create realistic players | Sign-off: ______ | Date: ______
- [x] Create realistic matches | Sign-off: ______ | Date: ______
- [x] Create realistic AI reports | Sign-off: ______ | Date: ______
- [x] Create realistic tactical reports | Sign-off: ______ | Date: ______
- [x] Create realistic recommendations | Sign-off: ______ | Date: ______

### 7. App UX Polish

#### UX Improvements

- [x] Add pull-to-refresh | Sign-off: ______ | Date: ______
- [x] Add success animations | Sign-off: ______ | Date: ______
- [x] Add empty states | Sign-off: ______ | Date: ______
- [x] Add retry actions | Sign-off: ______ | Date: ______
- [x] Add haptic feedback | Sign-off: ______ | Date: ______
- [x] Add micro-interactions | Sign-off: ______ | Date: ______
- [x] Improve scrolling experience | Sign-off: ______ | Date: ______

#### AI UX

- [x] Add futuristic loading screens | Sign-off: ______ | Date: ______
- [x] Add AI processing visuals | Sign-off: ______ | Date: ______
- [x] Add insight reveal animations | Sign-off: ______ | Date: ______
- [x] Add animated tactical diagrams | Sign-off: ______ | Date: ______

---

## PHASE 2 - BACKEND + SUPABASE

### Goal

Connect the app to real backend infrastructure after frontend completion.

### 8. Supabase Setup

- [x] Create Supabase project | Sign-off: ______ | Date: ______
- [x] Configure authentication | Sign-off: ______ | Date: ______
- [x] Configure storage buckets | Sign-off: ______ | Date: ______
- [x] Configure row-level security | Sign-off: ______ | Date: ______
- [x] Configure environment variables | Sign-off: ______ | Date: ______

### 9. Database Design

- [x] Create `users` table (implemented as `profiles`, 1:1 with auth.users) | Sign-off: AH | Date: 2026-06-08
- [x] Create `teams` table | Sign-off: ______ | Date: ______
- [x] Create `players` table | Sign-off: ______ | Date: ______
- [x] Create `managers` table (admin directory table + `team_managers` ownership; login managers = `profiles` role) | Sign-off: AH | Date: 2026-06-09
- [x] Create `matches` table | Sign-off: ______ | Date: ______
- [x] Create `analyses` table (implemented as `match_analyses` + `team_match_analysis` + `match_player_analysis` + `analysis_artifacts`) | Sign-off: AH | Date: 2026-06-08
- [x] Create `match events` table | Sign-off: ______ | Date: ______
- [x] Create `videos` table | Sign-off: ______ | Date: ______
- [x] Create `tactical_reports` table (implemented as `tactical_insights`) | Sign-off: AH | Date: 2026-06-08
- [x] Create `player_match_stats` table | Sign-off: ______ | Date: ______
- [x] Create `notifications` table (+ `notification_preferences`) | Sign-off: AH | Date: 2026-06-08
- [x] Create `venues` table | Sign-off: ______ | Date: ______
- [x] Create `match_players` table | Sign-off: ______ | Date: ______
- [x] Create `upload_jobs` table | Sign-off: ______ | Date: ______
- [x] Create `subscription_plans` table | Sign-off: ______ | Date: ______
- [x] Create `user_subscriptions` table | Sign-off: ______ | Date: ______
- [x] Create `tracking_snapshots` table | Sign-off: ______ | Date: ______

### 10. Authentication Integration

- [x] Connect login | Sign-off: AH | Date: 2026-06-08
- [x] Connect signup | Sign-off: AH | Date: 2026-06-08
- [x] Connect forgot password | Sign-off: AH | Date: 2026-06-08
- [x] Connect email verification (OTP; needs `{{ .Token }}` in the Supabase email template) | Sign-off: AH | Date: 2026-06-08
- [x] Connect role management (role from `profiles`; router guards already enforced) | Sign-off: AH | Date: 2026-06-08
- [x] Connect session persistence (Supabase session + restore on splash) | Sign-off: AH | Date: 2026-06-08

### 11. Data Integration

- [x] Replace mock repositories (clubs, analyses, matches, uploads, managers, standings, highlights → Supabase; remaining items in §11b) | Sign-off: AH | Date: 2026-06-09
- [x] Create Supabase services (`SupabaseClub/Analysis/Upload/Manager` repositories + Supabase-backed `MatchRepository`, under `lib/data/repositories/supabase/`) | Sign-off: AH | Date: 2026-06-09
- [x] Create async state management (Riverpod `AsyncValue` + sync-bridge providers; `clubs_screen` & `upload_history_screen` converted) | Sign-off: AH | Date: 2026-06-09
- [x] Add pagination (reusable `PaginatedNotifier` + `PaginatedListView` infinite-scroll infra; wired to fan Clubs grid via `clubsPagedProvider` → `fetchClubsPaged`; supports list + grid, end-of-list, error recovery, pull-to-refresh) | Sign-off: AH | Date: 2026-06-16
- [x] Add caching (CacheService TTL cache integrated into SupabaseClubRepository + SupabasePlayerRepository) | Sign-off: AH | Date: 2026-06-16
- [x] Add proper error handling (AppError sealed class + AppErrorView widget; squad_overview_page uses it) | Sign-off: AH | Date: 2026-06-16

### 11b. Data Integration — Remaining

> Added 2026-06-09. Factual/entity data is now Supabase-backed across 8 verticals
> (clubs, squads, league standings, match analyses, fan matches/home, fan
> highlights, manager upload history, admin managers). DB migrations `021`–`029`
> applied + filed. Verified at `flutter analyze` + DB/RLS/seed level; not yet
> runtime-tested on a device. The items below remain.

- [x] Connect Admin Squad players (`adminSquadProvider` derives `PlayerAnalysisModel` from `squadProvider` + `squadRiskProvider`; `squad_overview_page` converted to `ConsumerStatefulWidget`) | Sign-off: AH | Date: 2026-06-16
- [x] Connect admin system overview counts (`adminSystemOverviewProvider` → Supabase count queries on `profiles`, `match_analyses`, `upload_jobs`) | Sign-off: AH | Date: 2026-06-16
- [x] Replace remaining inline mock providers (`teamMembersProvider` + `coachTeamNameProvider` now derive from Supabase clubs; `adminSystemAlertsProvider` derives from real overview counts; `fan_mock_providers` `mockClubsProvider`/`mockStandingsProvider` removed) | Sign-off: AH | Date: 2026-06-16
- [x] Retire dead mock code (deleted `lib/data/repositories/mock/` (5 files) + unused Dio `auth_remote_datasource`/`match_remote_datasource` + their providers. NOTE: `admin_remote_datasource` retained — still wired to the routed `/admin-panel` screen via `adminControllerProvider`) | Sign-off: AH | Date: 2026-06-16
- [x] Seed real data for still-empty tables (migration 034 seeds `player_intelligence` + `player_risk_analysis` for all 20 players; venues/subscription_plans/matches seeded in migration 030) | Sign-off: AH | Date: 2026-06-16
- [ ] Runtime/visual QA of all Supabase-backed screens on a device/emulator | Sign-off: ______ | Date: ______

> Deferred to Phase 3 (AI-narrative — no real source until the AI engine exists):
> admin tactical insights / activity feed / alerts / performance trends /
> manager performance records; manager dashboard AI content; manager matches
> mock; and the upload AI-processing simulation.

### 12. Storage System

- [x] Match video uploads | Sign-off: ______ | Date: ______
- [x] Player images | Sign-off: ______ | Date: ______
- [x] Club logos | Sign-off: ______ | Date: ______
- [x] Analysis exports (private `analysis-exports` bucket + `analysis_exports` table + `SupabaseStorageRepository` upload/list/signed-URL/delete APIs; migration `035`) | Sign-off: AH | Date: 2026-06-16
- [x] Report storage (private `reports` bucket + `stored_reports` table + repository APIs + `storedReportsProvider`; metadata JSONB, owner-scoped RLS; migration `035`) | Sign-off: AH | Date: 2026-06-16

### 13. Realtime Features

- [x] Real-time infrastructure configured | Sign-off: ______ | Date: ______
- [x] Live upload progress (Supabase Realtime publication + runtime R1/R2 validation for `upload_jobs`) | Sign-off: Codex | Date: 2026-06-15
- [x] Live notifications (runtime R5 validation for user-scoped `notifications`) | Sign-off: Codex | Date: 2026-06-15
- [x] Live activity feeds (runtime R6 validation for admin `activity_logs` feed updates) | Sign-off: Codex | Date: 2026-06-15
- [x] Real-time analysis updates (Realtime publication for `player_match_stats`, `tracking_snapshots`, and `videos`; runtime R3/R4 validation for player stats) | Sign-off: Codex | Date: 2026-06-15

---
### 14 Runtime Validation

- [x] Admin runtime validation
- [x] Manager runtime validation
- [x] Player runtime validation
- [x] Fan runtime validation
- [x] Storage authorization validation
- [x] Realtime authorization validation
- [x] RLS validation
- [x] has_role recursion remediation

## PHASE 3 - AI MODEL INTEGRATION

### Goal

Connect the AI pipeline to the mobile app.

### 14. AI API Connection

- [ ] Create upload endpoint | Sign-off: ______ | Date: ______
- [ ] Create processing status endpoint | Sign-off: ______ | Date: ______
- [ ] Create analysis results endpoint | Sign-off: ______ | Date: ______
- [ ] Create tracking JSON endpoint | Sign-off: ______ | Date: ______

### 15. Analysis Integration

- [ ] Connect tactical reports | Sign-off: ______ | Date: ______
- [ ] Connect AI recommendations | Sign-off: ______ | Date: ______
- [ ] Connect player analytics | Sign-off: ______ | Date: ______
- [ ] Connect fatigue analysis | Sign-off: ______ | Date: ______
- [ ] Connect risk analysis | Sign-off: ______ | Date: ______

### 16. Tactical Visualization Integration

- [ ] Connect heatmaps | Sign-off: ______ | Date: ______
- [ ] Connect bird-eye tactical views | Sign-off: ______ | Date: ______
- [ ] Connect movement tracking | Sign-off: ______ | Date: ______
- [ ] Connect formation maps | Sign-off: ______ | Date: ______
- [ ] Connect pressure maps | Sign-off: ______ | Date: ______

### 17. Player Intelligence Integration

- [ ] Connect real performance history | Sign-off: ______ | Date: ______
- [ ] Connect workload tracking | Sign-off: ______ | Date: ______
- [ ] Connect fatigue metrics | Sign-off: ______ | Date: ______
- [ ] Connect tactical contribution data | Sign-off: ______ | Date: ______

---

## PHASE 4 - FINAL PRODUCTION POLISH

### 18. Performance Optimization

- [ ] Optimize rendering | Sign-off: ______ | Date: ______
- [ ] Optimize charts | Sign-off: ______ | Date: ______
- [ ] Optimize animations | Sign-off: ______ | Date: ______
- [ ] Optimize image loading | Sign-off: ______ | Date: ______
- [ ] Optimize memory usage | Sign-off: ______ | Date: ______

### 19. Security

- [x] Add role validation (JWT role claim hardening via migration `032_role_claim_hardening.sql`) | Sign-off: Codex | Date: 2026-06-15
- [x] Secure uploads (manager-owned upload/job and storage authorization validated in Phase 15 runtime tests) | Sign-off: Codex | Date: 2026-06-15
- [x] Secure storage access (role-scoped `match-videos` access + public image buckets validated in S1-S6) | Sign-off: Codex | Date: 2026-06-15
- [x] Validate permissions (Phase 15 authenticated runtime suite passed 35/35 authorization checks) | Sign-off: Codex | Date: 2026-06-15

### 20. Testing

- [ ] UI testing | Sign-off: ______ | Date: ______
- [ ] Responsive testing | Sign-off: ______ | Date: ______
- [ ] Navigation testing | Sign-off: ______ | Date: ______
- [ ] Upload workflow testing | Sign-off: ______ | Date: ______
- [ ] State management testing | Sign-off: ______ | Date: ______

### 21. Deployment

- [x] App icons | Sign-off: Codex | Date: 2026-06-15
- [x] Splash screen | Sign-off: Codex | Date: 2026-06-15
- [ ] Store screenshots | Sign-off: ______ | Date: ______
- [ ] Android production build | Sign-off: ______ | Date: ______
- [ ] iOS production build | Sign-off: ______ | Date: ______
- [ ] Store deployment assets | Sign-off: ______ | Date: ______

---

## Final Goal

The final GoalSight app should feel like an AI football intelligence operating system with:

- premium Flutter UI
- tactical intelligence
- AI-powered analytics
- role-based workflows
- production-level UX
- real football intelligence systems
