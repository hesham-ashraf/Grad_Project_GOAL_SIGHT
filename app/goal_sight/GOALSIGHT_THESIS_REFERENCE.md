# GoalSight — Complete Technical Reference for the Graduation Thesis

> **Purpose of this document.** This is an exhaustive, single-source technical description of the **GoalSight** mobile application, written from the **Software Engineering (SWE)** perspective. The team is 4 students: **2 AI students** (built the football computer-vision / ML models) and **2 Software students** (built the Flutter application, the Supabase backend, the integration layer, and the supporting micro-services). The AI models already work in isolation; the **integration seam** that plugs them into the app is built and documented here (it is the `ANALYSIS_API_URL` HTTP contract — see §5.4 and §4.4). This document is organised to map **section-by-section onto the official Zewail City CSAI thesis template**, so you can lift each part directly into the report. Every claim here was read directly from the codebase on **2026-06-19**.

> **How to read this.** Each chapter heading below corresponds to a chapter in the thesis template. Inside each you will find the concrete material (facts, tables, diagrams-as-text, code snippets, file paths) you need to write that chapter. Where the template asks for something the SWE side owns (architecture, implementation, database, API, deployment, testing, security), the detail is deep. Where the template asks for AI-model internals (training, datasets, model metrics), this document gives the **integration contract and the data the models must return**, and flags those subsections as "owned by the AI sub-team."

---

## 0. Project Identity & Fast Facts

| Field | Value |
|---|---|
| Product name | **GoalSight** (app title in code: `Goal Sight AI`) |
| One-line pitch | AI-powered football match-analysis platform that turns an uploaded match video into per-player and per-team tactical intelligence. |
| Platform | **Flutter** cross-platform app (Android primary; iOS, Web, Windows, macOS, Linux targets present). |
| Flutter/Dart SDK | Dart SDK constraint `>=3.4.3 <4.0.0`; Material 3. |
| App version | `1.0.0+1` (`pubspec.yaml`). |
| Backend | **Supabase** (managed PostgreSQL + Auth + Storage + Realtime + RLS). 33 tables, all Row-Level-Security enabled. |
| AI integration | External ML service reached over HTTP (`ANALYSIS_API_URL`); a deterministic **simulator** stands in when the service is not configured so the flow is always demoable. |
| Side micro-service | **Python FastAPI + fpdf2** PDF report generator (`pdf_service/`). |
| Roles | **Fan**, **Manager**, **Admin** (three role-scoped experiences). |
| Multi-tenancy | One Admin = one Club; managers inherit the admin's `club_id`; data isolated per club via `owner_club_id` + RLS. |
| State management | **Riverpod** (`flutter_riverpod`). |
| Routing | **GoRouter** with role-based redirect guards. |
| Repository | `lib/` (Flutter app) + `pdf_service/` + `supabase/migrations/` (52 numbered SQL migrations). |

---

# Chapter 1 — Introduction

### 1.1 Background
Professional and semi-professional football staff increasingly rely on video analysis to evaluate players and opponents, but the tooling (Hudl, Wyscout, InStat, SciSports) is **expensive, desktop-bound, and built for large analytics departments**. Smaller clubs, academies, and individual coaches in markets such as the Egyptian league rarely have access to automated tactical intelligence. At the same time, advances in computer vision (player detection, tracking, pose estimation, event spotting) make it feasible to extract structured tactical data from a single broadcast or sideline video. GoalSight applies this: a coach records or exports a match video, uploads it from a phone, and receives an automated, per-player and per-team analysis with ratings, fatigue, tactical style, key moments, heatmaps, and recommendations.

### 1.2 Problem Statement
**Football match analysis is inaccessible on mobile, manual, and locked behind enterprise tooling.** There is no affordable, phone-first product that lets a manager upload a match video and automatically receive structured, explainable tactical intelligence per player and per team, while keeping each club's data private and giving fans a lightweight way to follow analyzed matches and standings.

### 1.3 Motivation
- **Cost & accessibility gap** — enterprise analysis suites are out of reach for academies and smaller clubs.
- **Mobile-first reality** — coaching staff increasingly work from phones, not analysis suites.
- **Automation** — manual tagging of a match takes hours; an ML pipeline produces it in minutes.
- **Local relevance** — a seeded Egyptian-league context (Al Ahly, Zamalek, Pyramids, etc.) demonstrates a real, under-served market.

### 1.4 Proposed Solution
A three-sided Flutter application backed by Supabase:
1. **Manager** uploads a match video → the app stores it privately, creates an upload job, calls the ML service, and persists the returned analysis. The manager browses match analyses, a living per-player profile (the "Player Intelligence"), squad risk, and exports a per-player PDF report.
2. **Admin** owns the club: creates the club, promotes managers, and views club-wide analytics, squad intelligence, and managers' activity.
3. **Fan** browses clubs, league standings, highlights, and a gamified profile (XP, achievements).

The AI models are **decoupled** behind a single HTTP contract, so the SWE app and the AI models were developed in parallel and integrate at one well-defined seam.

### 1.5 Project Objectives
1. Build a production-grade, role-based Flutter app with a premium dark UI.
2. Design a secure, multi-tenant PostgreSQL schema with strict per-club isolation (RLS).
3. Implement the full upload → analysis → persistence → visualization pipeline.
4. Define and implement a clean integration contract so the AI models plug in with **one config value** (`ANALYSIS_API_URL`).
5. Provide an exportable player report (PDF micro-service).
6. Keep the system demoable end-to-end **with or without** the live ML backend.

### 1.6 Scope
**In scope (SWE):** Flutter app (3 roles), Supabase schema + RLS + auth, upload/storage pipeline, analysis persistence + aggregation, real-time channels, PDF service, the AI integration HTTP contract, the deterministic simulator fallback.
**In scope (AI sub-team):** the 4 models (tracking, possession, events, tactical) producing the JSON + analyzed video.
**Out of scope (current build):** payment processing (subscription tables exist but are not monetized), live in-stadium streaming ingestion, native desktop store distribution.

### 1.7 Challenges Addressed
- Strict **multi-tenant data isolation** with Supabase RLS (a real privilege-escalation bug was found and fixed — see §8 and §5.2).
- **Decoupling** a long-running, external ML job from a responsive mobile UI.
- **Graceful degradation** (simulator fallback) so demos never fail.
- **Auto-reconciliation** of detected players against an existing squad (jersey → name match, auto-create).
- Building a **living aggregate profile** per player (DB trigger recomputes on every new verdict).

### 1.8 Contributions
- A reusable **engine-abstraction pattern** (`IAnalysisEngine` → `ModelAnalysisEngine` / `SimulatedAnalysisEngine`) for integrating heavy ML behind a mobile app.
- A documented, versioned, **RLS-hardened multi-tenant schema** for sports analytics.
- A complete, role-scoped Flutter reference implementation with a cohesive design system.
- A stateless **PDF reporting micro-service** decoupled from the app and DB.

### 1.9 Report Organization
Chapters follow the template: Market & Business Case (2), Literature Review (3), System Design (4), Implementation (5), Testing & Evaluation (6), Results (7), Ethics & Compliance (8), Conclusions & Future Work (9), References, Appendices.

---

# Chapter 2 — Market Visibility & Business Case

### 2.1 Market Relevance
Sports analytics is a fast-growing segment; video-based performance analysis is standard at the elite level but **absent at the long tail** (academies, lower divisions, individual coaches). Mobile penetration in these segments is high while desktop analytics adoption is low — a structural opening for a phone-first product.

### 2.2 Target Users & Stakeholders
| Stakeholder | Role in product | Primary value |
|---|---|---|
| **Club Admin** | Owns the club tenant, promotes managers | Club-wide oversight, squad intelligence, governance |
| **Manager / Coach** | Uploads matches, reviews analysis | Automated per-player & tactical analysis, PDF reports |
| **Player** (data subject, not a login role) | Analyzed entity | Objective performance/fatigue tracking |
| **Fan** | Public consumer | Standings, clubs, highlights, gamified engagement |
| **AI sub-team** | Model provider | Clean integration contract |

> Note: **"Player" is intentionally not a login role** (removed in migration 041). Players are pure data records (`players` table). Login roles are exactly `{fan, manager, admin}`.

### 2.3 Existing Market Gaps
- No affordable **mobile-first** automated analysis.
- Enterprise tools assume a dedicated analyst, not a self-serve coach.
- Little support for **per-club data privacy** in lightweight tools.
- Local-league (e.g. Egyptian Premier League) coverage is thin.

### 2.4 Competitive Analysis
| Product | Platform | Automation | Target | Price tier | Mobile self-serve |
|---|---|---|---|---|---|
| Hudl / Hudl Sportscode | Desktop/Web | Semi-manual tagging | Pro/college | $$$ | Limited |
| Wyscout | Web | Scouting DB + manual | Pro scouting | $$$ | No |
| InStat / Hudl InStat | Web | Operator-tagged | Pro | $$$ | No |
| SciSports | Web/API | Automated tracking | Pro/data teams | $$$ | No |
| **GoalSight** | **Flutter mobile** | **Automated ML pipeline** | **Academies, small clubs, coaches** | **Low / freemium-ready** | **Yes** |

### 2.5 Potential Impact
Lowers the cost and skill floor for tactical analysis; brings objective player evaluation to under-served clubs; gives fans a lightweight analytics-flavored engagement layer.

### 2.6 Innovation Aspects
- **One-seam AI integration** with automatic simulator fallback.
- **Living player-intelligence aggregate** maintained by a DB trigger.
- **Strict per-club multi-tenancy** on a managed Postgres with verified RLS isolation.

### 2.7 Feasibility & Sustainability
Built entirely on managed/free-tier-friendly infrastructure (Supabase, FastAPI). The app degrades gracefully without the ML backend, so it is demoable and shippable incrementally. `subscription_plans` / `user_subscriptions` tables already exist (3 plans seeded) to support future monetization.

### 2.8 Scalability & Commercialization
- Multi-tenant from day one — adding clubs is additive, not structural.
- Stateless micro-services (PDF, analysis client) scale horizontally.
- A freemium model (free fan tier, paid manager/club tier) is pre-wired via the subscription tables.

---

# Chapter 3 — Literature Review & Needed Background

> The deep ML literature (player detection, multi-object tracking, event spotting, pose estimation) is **owned by the AI sub-team**. From the SWE side, the relevant background is the system/architecture and integration literature.

### 3.1 Existing Systems & Tools
- **Computer-vision sports analysis**: player detection/tracking, possession estimation, event detection, tactical pattern mining (the 4 model families this project consumes).
- **Backend-as-a-Service**: Supabase (Postgres + Auth + Storage + Realtime + RLS) as an alternative to a hand-built backend.
- **Cross-platform mobile**: Flutter/Dart for a single codebase across Android/iOS/Web/desktop.

### 3.2 Background Concepts the SWE Report Should Define
- **Row-Level Security (RLS)** and policy-based tenant isolation.
- **Repository pattern** + dependency inversion for swappable data sources.
- **Reactive state management** (Riverpod providers, `FutureProvider`, `StreamProvider`).
- **JWT-based auth** and session restoration.
- **The Strategy pattern** as used for the analysis engine (real vs simulated).

### 3.3 Comparative Analysis & Positioning
See the table in §2.4. GoalSight's differentiator is **mobile-first + automated + multi-tenant-private + graceful-degradation**, an integration architecture rather than a new model.

### 3.4 Identified Gaps
Existing tools couple the model tightly to a desktop product; GoalSight's contribution is the **clean decoupling** of an arbitrary ML backend from a polished mobile client via a single typed HTTP contract.

---

# Chapter 4 — System Design

## 4.1 Functional Requirements

### 4.1.1 Cross-cutting
- FR-1: Email/password registration & login; Google OAuth sign-in.
- FR-2: Email OTP verification (6-digit) when confirmation is enabled.
- FR-3: Password reset via OTP.
- FR-4: Session restoration on app launch (splash gate).
- FR-5: Role-based routing & access control (fan/manager/admin shells).

### 4.1.2 Manager
- FR-M1: Upload a match video from the device gallery.
- FR-M2: Enter match metadata (teams, competition, venue, date, notes).
- FR-M3: Trigger AI analysis and watch staged progress.
- FR-M4: View persisted match analysis (teams, players, key moments, recommendations, analyzed video).
- FR-M5: Browse all club match analyses.
- FR-M6: Manage squad (list players, add player with full bio).
- FR-M7: View a player's living profile, rating history, match history, fatigue, risk, and per-match heatmaps.
- FR-M8: Export a player report as PDF.
- FR-M9: View upload history with status.

### 4.1.3 Admin
- FR-A1: Create the club (one admin = one club).
- FR-A2: Promote/add managers and set permissions (`can_upload`, `can_edit_players`, `can_manage_staff`).
- FR-A3: View system overview (counts: profiles, analyses, uploads).
- FR-A4: View squad intelligence & per-player drill-down.
- FR-A5: View club analytics & tactical insights.
- FR-A6: Receive notifications (realtime) and view activity feed.

### 4.1.4 Fan
- FR-F1: Browse clubs (paginated, searchable).
- FR-F2: View league standings.
- FR-F3: View club details.
- FR-F4: View highlights.
- FR-F5: Gamified profile (XP, level tier, achievements, followed clubs).

### 4.1.5 Key Use Cases (text form)
**UC-Upload (primary):** Manager → pick video → fill details → confirm → app uploads to private bucket → creates `upload_jobs` row → calls `ModelAnalysisEngine.analyzeUpload()` → (real ML or simulator) returns structured result → persister writes `match_analyses` + `team_match_analysis` + `match_player_analysis` (+ artifacts + heatmaps) → DB trigger recomputes `player_intelligence` → providers invalidated → all club screens refresh → manager taps "View Analysis."

## 4.2 Non-Functional Requirements
| NFR | How the design meets it |
|---|---|
| **Security** | Supabase Auth (JWT); RLS on all 33 tables; per-club `owner_club_id`; SECURITY DEFINER role helpers read from `profiles` (not user-editable metadata); private storage buckets with path-scoped policies; secrets in `.env` (gitignored). |
| **Multi-tenancy / Reliability** | `owner_club_id` tenant key + `auth_club_id()`; verified isolation via rollback-transaction tests. |
| **Performance** | In-memory TTL `CacheService` (clubs 10 min, players 8 min); server-side pagination; lazy `FutureProvider`s; cache invalidation on writes. |
| **Scalability** | Stateless micro-services; managed Postgres; additive multi-tenant model. |
| **Maintainability** | Repository pattern + interfaces; design tokens centralized; dual-engine abstraction; 52 numbered, idempotent migrations. |
| **Usability** | Cohesive dark design system, staggered reveal animations, haptics, shimmer skeletons, pull-to-refresh, AI-loader overlay, success overlays. |
| **Availability of demo** | Simulator fallback guarantees the flow works offline / without ML. |

## 4.3 Development Approach & Lifecycle
- **Iterative, phase-based** delivery (see `DEVELOPMENT_ROADMAP.md`): Phase 1 Flutter frontend (mock data) → Phase 2 Supabase data integration (feature-by-feature) → multi-tenancy hardening → AI integration seam → PDF reporting.
- **Parallel sub-teams**: SWE built the app + backend + contract; AI built the models; they meet at the HTTP contract.
- **Integration strategy**: bridge providers (keep a provider's name, swap its source from mock to Supabase) to avoid rewriting consumers; repository interfaces so the data source can change with zero UI changes.

## 4.4 AI/ML Pipeline (integration view — model internals owned by AI sub-team)
The app treats the ML system as a black box reached at `POST ${ANALYSIS_API_URL}/analyze`. The 4 model families and their outputs:

| Model family | Produces | Lands in DB as |
|---|---|---|
| **Tracking** | player/ball positions, movement | `analysis_artifacts(artifact_type='model_output', data.model_name='tracking')`; drives heatmaps |
| **Possession** | possession %, zones | `team_match_analysis.possession`, `.attacking_zones`; artifact |
| **Events** | goals, key moments | `match_analyses.key_moments`, per-player goals/assists/tackles/key_passes; artifact |
| **Tactical** | style, pressure, compactness, narrative, recommendations | `team_match_analysis.style/pressure_style/compactness`, `match_analyses.overall_narrative/recommendations`; artifact |

**Request body** (sent by `ModelAnalysisEngine`):
```json
{ "upload_job_id": "...", "video_url": "<signed URL>", "home_team": "...",
  "away_team": "...", "competition": "...", "venue": "...", "match_date": "ISO-8601" }
```
**Response body the models must return** (see exact parser in `lib/data/services/analysis_engine.dart`):
```json
{
  "analyzed_video_url": "https://.../analyzed.mp4",
  "heatmap_url": "https://.../match_heatmap.png",
  "match":  { "score": "2 - 1", "result_status": "FT", "intensity": 78,
              "dominant_team": "...", "home_avg_rating": 7.4, "away_avg_rating": 6.9,
              "highlight_text": "...", "overall_narrative": "...",
              "key_moments": ["..."], "recommendations": ["..."] },
  "teams":  { "home": <team>, "away": <team> },
  "players":[ { "jersey_number": 10, "player_name": "...", "position": "CAM",
                "rating": 8.3, "fatigue": 64, "performance_status": "excellent",
                "contribution": "attack", "impact": "High", "insight": "...",
                "goals": 1, "assists": 1, "tackles": 2, "key_passes": 4,
                "is_motm": true, "is_worst": false, "heatmap_url": "https://.../p.png" } ],
  "model_outputs": { "tracking": {...}, "possession": {...}, "events": {...}, "tactical": {...} }
}
```
`<team> = { team_name, possession, style, pressure_style, compactness, attacking_zones[], avg_rating, top_players[], worst_players[] }`

**The only step to go live with the real models:** set `ANALYSIS_API_URL` in `.env`. Empty → simulator.

## 4.5 Architecture Design

### 4.5.1 High-level architecture (text diagram)
```
┌────────────────────────────────────────────────────────────────────┐
│                       GoalSight Flutter App                        │
│  Presentation (screens/widgets, 3 role shells)                     │
│        │  watches                                                  │
│  State (Riverpod providers: Future/Stream/StateNotifier)           │
│        │  calls                                                    │
│  Domain/Data (Repository interfaces → Supabase implementations)    │
│        │              │                  │                         │
│  Auth repo      Data repos         Analysis Engine (Strategy)      │
└────────┼──────────────┼──────────────────┼────────────────────────┘
         │              │                  │
         ▼              ▼                  ▼
   Supabase Auth   Supabase Postgres   ML Service (ANALYSIS_API_URL)
   (JWT, OAuth)    + Storage + Realtime  POST /analyze → JSON+video
                    + 33 RLS tables             │
                                                ▼
                                    persists analysis back into Postgres
   ┌───────────────────────────────────────────────────────────────┐
   │  PDF micro-service (FastAPI + fpdf2)  ←  manager "Export PDF"  │
   └───────────────────────────────────────────────────────────────┘
```

### 4.5.2 Component diagram (modules)
- **Core** (`lib/core/`): theme/design tokens, responsive utils, services (api, websocket, secure storage, cache, haptics, auth interceptor), Supabase config, constants, errors, config (analysis/pdf).
- **Data** (`lib/data/`): 27 models, repository interfaces, Supabase repository implementations, `analysis_engine.dart`, `pdf_export_service.dart`.
- **Providers** (`lib/providers/`): Riverpod wiring (repository providers, router, paginated notifier, feature providers).
- **Features** (`lib/features/`): auth controller/state, admin controller/state, manager screens + widgets, match controllers.
- **Presentation** (`lib/presentation/`): fan/admin/auth/dashboard screens + widgets.
- **Shared** (`lib/shared/`): animations, charts (custom painters), components, responsive, states, transitions, primitive widgets.

### 4.5.3 Technology Stack
| Layer | Technology |
|---|---|
| Mobile UI | Flutter (Material 3, Google Fonts), custom design system |
| State | Riverpod (`flutter_riverpod` 2.5) |
| Routing | GoRouter 14.6 |
| Networking | Dio 5.7 (ML + PDF), `http`, `supabase_flutter` 2.8 |
| Realtime | `supabase_flutter` channels + `socket_io_client` 3.0 (live match WS) |
| Auth | Supabase Auth + `google_sign_in` 6.2 |
| Local storage | `flutter_secure_storage` 9.2, `shared_preferences`, `sqflite` |
| Media | `image_picker` 1.0 (video), `video_player` 2.9, `printing` 5.13 |
| Charts | `fl_chart` 0.66 + custom `CustomPainter`s |
| Misc UI | `shimmer`, splash/launcher icon generators, `flutter_dotenv` |
| Backend | Supabase (PostgreSQL, Auth, Storage, Realtime, RLS) |
| AI service | External HTTP (`ANALYSIS_API_URL`) — owned by AI sub-team |
| PDF service | Python FastAPI + fpdf2 |
| Tests | `flutter_test`, `mocktail` |

### 4.5.4 Database Design / ERD (live schema: 33 tables, all RLS-enabled)
Grouped by concern (row counts are the live demo state on 2026-06-19):

**Identity & tenancy**
- `profiles` (15) — one per auth user; `role ∈ {admin,manager,fan}`, `club_id` (tenant link). Source of truth for role.
- `teams` (8) — the app's "Club" entity (clubs == teams); enriched club row.
- `team_season_stats` (8) — season aggregates + standings rank.
- `managers` (3) — managers **directory** table (optional `profile_id` link, `can_upload/can_edit_players/can_manage_staff`).
- `team_managers` (0) — join (admin↔manager↔team ownership).
- `venues` (9), `subscription_plans` (3), `user_subscriptions` (4).

**Squad & matches**
- `players` (22) — squad records with full bio (`jersey_number, age, height_cm, weight_kg, nationality, market_value, is_captain`); tenant key `owner_club_id` + `team_id` (two FKs to teams — must disambiguate embeds, see §5/§8).
- `matches` (0), `match_events` (0), `match_players` (0), `player_match_stats` (0) — raw match state (Realtime-enabled).
- `videos` (0) — uploaded match-video metadata + `processing_status`.
- `upload_jobs` (2) — manager upload + AI processing progress (Realtime-enabled).
- `tracking_snapshots` (0).

**AI output layer**
- `match_analyses` (2) — analysis header: score, ratings, intensity, narrative, key_moments, recommendations, `analyzed_video_url`, `heatmap_url`, `motm_player_key`, `worst_player_key`.
- `team_match_analysis` (4) — per-team tactical block (possession, style, pressure, compactness, zones, avg rating, top/worst players).
- `match_player_analysis` (44) — per-player **AI verdict** per match (rating, fatigue, contribution, impact, insight, goals/assists/tackles/key_passes, motm/worst, `heatmap_url`). Distinct from raw `player_match_stats`.
- `tactical_insights` (0), `analysis_artifacts` (0 live; typed JSONB store, `artifact_type` incl. `'model_output'`), `player_risk_analysis` (0).
- `player_intelligence` (22) — one **living aggregate** AI profile per player; rebuilt by trigger on each new verdict.

**Engagement & gamification**
- `notifications` (8, Realtime), `notification_preferences` (0), `activity_logs` (156, Realtime).
- `user_favorite_teams` (3), `user_favorite_players` (0), `saved_matches` (0), `highlights` (6).
- `fan_stats` (15), `achievements` (6), `user_achievements` (3).

**Key relationships (ERD edges):**
`profiles.club_id → teams.id` · `players.owner_club_id → teams.id` & `players.team_id → teams.id` · `upload_jobs → match_analyses` · `match_analyses → team_match_analysis`, `match_player_analysis`, `analysis_artifacts` · `match_player_analysis.player_id → players.id` · `players → player_intelligence` (1:1) · `team_season_stats.team_id → teams.id`.

### 4.5.5 API Design
**(a) Supabase data API** — used via `supabase_flutter` PostgREST client inside repository classes (`.from('table').select()/insert()/update()`); access enforced by RLS. Realtime via `.channel()` / `StreamProvider`.

**(b) ML Analysis API** — `POST ${ANALYSIS_API_URL}/analyze`, Bearer = user's Supabase JWT, timeouts 5 min send / 10 min receive (Dio). Contract in §4.4.

**(c) PDF API** — `POST ${PDF_API_URL}/player-report` (JSON player snapshot → `application/pdf`), `GET /health`. Stateless, no DB.

**(d) Live-match WebSocket** — `socket_io_client` to `ApiConstants.wsUrl`; events `match:update`, `match:join`, `match:leave`; auth via token.

### 4.5.6 Deployment Architecture
- **App**: built APK (Android emulator/device) — `flutter build apk --debug`; multi-platform build folders present.
- **Backend**: Supabase cloud project (live); 52 SQL migrations in `supabase/migrations/` (history table empty — applied via SQL editor/MCP + filed as numbered files).
- **PDF service**: `uvicorn main:app --host 0.0.0.0 --port 8000`; reachable from Android emulator at `http://10.0.2.2:8000` (`PDF_API_URL`); manifest `usesCleartextTraffic=true` for local dev.
- **ML service**: external; configured via `ANALYSIS_API_URL`.

## 4.6 UI/UX Design

### 4.6.1 Navigation flow
- `/splash` (session gate) → role redirect.
- **Auth**: `/login`, `/register`, `/forgot-password`, `/email-verification`.
- **Manager shell** `/manager` (IndexedStack tabs: Home → Matches → Upload → Players → Profile); sub-routes `/manager/add-player`, `/manager/upload-match`, `/manager/upload-history`.
- **Admin shell** `/admin` (tabs index 0–4: Home, Managers, Squad, Club-Analytics, Profile); drill-downs `/admin/managers/:id`, `/admin/player/:id`, `/admin/notifications`.
- **Fan shell** `/fan` (Home, Matches, Clubs, Standings, Profile).
- **Shared read-only routes** (any role): `/fan-match-analysis`, `/fan-club-details`, `/fan-player-profile`.
- Object passing via `state.extra`; custom transitions (`slideLeft` drill-down, `fade` top-level, `modal` sheets, `slideUp`).

### 4.6.2 Design system (see `lib/core/theme/app_theme.dart`)
- **Palette**: background `#050816`; surfaces `#0D1324`/`#141C31`/`#1A2340`; brand `primaryPurple #705AF5`, `primaryBlue #356BFF`, `accentCyan #2DE2E6`, `accentGreen #70F59A`; semantic `success/warning/danger`.
- **Type scale**: headline 34/w800, title 20/w700, body 14/w500, caption 12, button 14/w700.
- **Radii**: card 20, cardLarge 24, button 18, input 16, chip pill.
- **Gradients**: brand (purple→cyan), live (cyan→green), surface.
- **Shadows**: card, cardGlow, buttonGlow.
- **Rule enforced**: use `.withValues(alpha:)` not deprecated `.withOpacity()`.
- **Responsive**: `ResponsiveContext` extension (`context.rs/.sp/.adaptiveLayout`), 390-pt baseline, global text-scale clamp 0.92–1.12.

### 4.6.3 Motion & feedback
Single `AnimationController` per screen with `Interval`-staggered fade+slide reveals; `HapticService` (selection/light/medium/success/error/refresh/aiReveal/longPress); `GsShimmer` skeletons; `GsPullRefresh`; `GsAiLoader` (rotating rings + stage timeline) during processing; `GsSuccessOverlay`.

### 4.6.4 Wireframes / screenshots
Use `screenshot.png` (repo root) as an existing capture. For the thesis, capture one screen per shell tab from a running emulator (the Appendix-1 user guide lists every screen).

---

# Chapter 5 — Implementation Details

## 5.1 Technologies, Tools & Environments
- **Dart/Flutter**, Material 3. Editors: VS Code / Android Studio (`.vscode`, `.idea`, `goal_sight.iml`).
- **Commands**: `flutter pub get`, `flutter analyze`, `flutter test`, `flutter run -d <device>`, `flutter build apk --debug`.
- **Config**: `.env` (Supabase URL/anon key, `ANALYSIS_API_URL`, `PDF_API_URL`), bundled as a Flutter asset and read with `flutter_dotenv`.
- **Icons/splash**: `flutter_launcher_icons` + `flutter_native_splash` (splash color `#0A0A0F`).

## 5.2 Module — Authentication
- **Purpose**: identity, role resolution, session lifecycle.
- **Files**: `lib/data/repositories/auth_repository.dart` (`IAuthRepository` + `SupabaseAuthRepository`), `lib/features/auth/auth_controller.dart` + `auth_state.dart`, auth screens in `lib/presentation/screens/auth/`.
- **Internal workflow**: `signInWithPassword` / `signUp(data:{full_name, role})` / `verifyOTP(OtpType.signup|recovery)` / `resetPasswordForEmail` / `signInWithIdToken(google)` → `_hydrate(user, session)` reads **`profiles.full_name, role, club_id`** as source of truth (never trusts metadata for routing), mirrors token+role into `flutter_secure_storage`.
- **Key engineering decisions**: role from DB not JWT metadata (defends against user-editable metadata); `UserModel.clubId` carried through for tenancy; Google sign-in uses a Web Client ID `serverClientId` and exchanges the Google ID token with Supabase.
- **Snippet (role hydration):**
```dart
final profile = await _client.from('profiles')
    .select('full_name, role, club_id').eq('id', user.id).maybeSingle();
role  = parseUserRole((profile['role'] ?? 'fan').toString());
clubId = profile['club_id']?.toString();
```

## 5.3 Module — Routing & Access Control
- **File**: `lib/providers/router_provider.dart`. `routerProvider` watches `authControllerProvider`; a single `redirect` enforces: splash/loading gating, email-verification gating, unauthenticated → `/login`, and **role guards** (admin can't enter `/manager`/`/fan`; manager can't enter `/admin`/`/fan`; fan can't enter `/admin`/`/manager`), with shared read-only routes whitelisted.

## 5.4 Module — AI Analysis Engine (the integration core)
- **Purpose**: run (or simulate) analysis for a completed upload and persist it.
- **File**: `lib/data/services/analysis_engine.dart` (~728 lines). Pattern: **Strategy** behind `IAnalysisEngine`.
  - `ModelAnalysisEngine` (the wired provider) — `POST /analyze` with Dio + JWT, parses the response (`_parseResponse`/`_parseTeam`/`_parseVerdict`), **falls back to the simulator on missing config or any error**.
  - `SimulatedAnalysisEngine` — deterministic (`Random(uploadJobId.hashCode)`) believable analysis; if the club squad is empty it "detects" an 11-player roster (`_detectedRoster`) that the persister auto-creates.
  - `_AnalysisPersister` (shared) — writes `match_analyses` (+ `analyzed_video_url`, `heatmap_url`, motm/worst keys), `analysis_artifacts` (each raw model JSON as `artifact_type='model_output'`), `team_match_analysis` (home/away), `match_player_analysis` (per-player verdict). Players are matched **jersey → name**, **auto-created** if newly detected.
- **Config**: `lib/core/config/analysis_config.dart` — `analysisApiBaseUrl` / `hasAnalysisApi` from `.env`.
- **Why this design**: lets the SWE and AI teams build in parallel; guarantees a working demo; isolates all persistence in one place so the contract can evolve without touching UI.
- **Snippet (engine selection + fallback):**
```dart
if (!hasAnalysisApi) return _fallback.analyzeUpload(...);   // simulator
try {
  final resp = await _dio.post('$base/analyze', data: {...}, options: Options(
      headers: {if (token != null) 'Authorization': 'Bearer $token'}));
  final result = _parseResponse(data, sourceVideoUrl);
  return const _AnalysisPersister().persist(...);
} catch (_) { return _fallback.analyzeUpload(...); }          // graceful degradation
```

## 5.5 Module — Upload Workflow
- **File**: `lib/features/manager/screens/upload_match_screen.dart`. Finite-state UI: `fileSelection → matchDetails → confirmation → processing → success | failed`.
- **Internal flow**: `image_picker.pickVideo(gallery)` → upload bytes to private **`match-videos`** bucket under `<club_id>/<uid>/<ts>_<file>` (`SupabaseStorageRepository.uploadMatchVideo`, returns 7-day signed URL) → `createUploadJob` → staged progress animation (`ProcessingStage` enum) → `engine.analyzeUpload(sourceVideoUrl: signedUrl)` → fetch persisted analysis → `updateJobStatus(completed)` → **cache bust + provider invalidation** (`squad:`/`player:` prefixes; `matchAnalysisListProvider`, `squadProvider`, `squadRiskProvider`, `uploadHistoryProvider`, `managerPlayersProvider`, `managerDashboardProvider`) so every club screen refreshes. Real upload failure routes to `failed` (no fake success).

## 5.6 Module — Data Layer (Repositories & Models)
- **Repository interfaces** (`lib/data/repositories/interfaces/`): `IClubRepository`, `IPlayerRepository`, `IAnalysisRepository`, `IUploadRepository`, `IManagerRepository` — each backed by a `Supabase*Repository` (`lib/data/repositories/supabase/`). Providers in `lib/providers/repository_providers.dart` keep names stable so swapping the source needs **zero UI changes**.
- **27 models** (`lib/data/models/`): `user_model`, `club_model`, `player_profile_model`, `match_analysis_model`, `player_analysis_model`, `risk_analysis_model`, `upload_job_model`, `manager_model`, `notification_model`, `fan_profile_model`, `fan_highlight_model`, `player_heatmap_model`, `standing_entry_model`, `system_overview_model`, `tactical_insight_model`, `analysis_export_model`, etc.
- **Example domain rules**: `RiskAnalysisModel.compositeScore = 0.35·fatigue + 0.35·injury + 0.15·consistency + 0.15·tactical`; `RiskLevel` severities low/med/high/critical = 0.15/0.45/0.72/0.95; `PlayerProfileModel` derives `goalsPerMatch`, trend labels, etc.

## 5.7 Module — Database & Backend
- **Supabase Postgres**, 33 RLS tables (§4.5.4). 52 migrations `001…052`.
- **Tenancy/RLS** (migrations 041–047): `owner_club_id` tenant key stamped by trigger `set_owner_club_id()` = `auth_club_id()`; `club_all_<table>` policies = `auth_role() in ('admin','manager') AND owner_club_id = auth_club_id()`; child tables inherit via `EXISTS` on parent. `auth_role()`/`has_role()`/`auth_club_id()` are SECURITY DEFINER reading `profiles`.
- **Admin onboarding**: `create_admin_club(name)` RPC creates a `teams` row, sets `profiles.club_id`, seeds a zeroed `team_season_stats` row; `promote_to_manager` is admin-only and derives club from the admin's profile (hardened against a privilege-escalation hole that trusted caller-supplied club_id).
- **Aggregation**: trigger `aggregate_player_intelligence()` recomputes `player_intelligence` from all of a player's `match_player_analysis` verdicts on each insert.
- **Storage**: private buckets `match-videos`, `analysis-exports`, `reports`; club-scoped object policies (path's first segment must equal `auth_club_id()`).
- **Realtime**: `matches`, `match_events`, `videos`, `upload_jobs`, `notifications`, `activity_logs` are in the realtime publication.

## 5.8 Module — PDF Reporting Micro-service
- **Files**: `pdf_service/main.py` (FastAPI), `pdf_generator.py` (fpdf2 layout), `requirements.txt`, `sample_player.json`, `test_generate.py`.
- **Contract**: `POST /player-report` (JSON `PlayerProfileModel` snapshot + heatmaps) → `application/pdf`; `GET /health`. CORS `*`. Stateless (no DB).
- **Flutter side**: `lib/core/config/pdf_config.dart` (`PDF_API_URL`), `lib/data/services/pdf_export_service.dart`, "Export PDF" app-bar action in the manager `player_profile_screen` → `Printing.sharePdf`.
- **Status**: tested working (valid ~94 KB PDF with header, stat boxes, season stats, AI insights, recent-matches table, embedded heatmaps on page 2).

## 5.9 Cross-cutting Engineering
- **Error model**: `lib/core/errors/app_error.dart` — sealed `AppError` (Network/Database/Auth/Permission/NotFound/Storage/Unknown) + reusable `app_error_view.dart`.
- **Caching**: `lib/core/services/cache_service.dart` — in-memory TTL cache + prefix invalidation.
- **Pagination**: `PaginatedNotifier<T>` + `PaginatedListView` (infinite scroll over any repo `*Paged` method).
- **Secure storage / interceptor**: `secure_storage_service.dart`, `auth_interceptor.dart` (attaches token to Dio).

## 5.10 Known Engineering Challenges & Resolutions
| Challenge | Resolution |
|---|---|
| Two FKs from `players` to `teams` broke PostgREST embed (300 error, fan Clubs list down) | Disambiguated embed to `players!players_team_id_fkey(*)`. |
| RLS OR-combined role policies leaked all clubs to every manager | Dropped role-only policies; introduced `club_all_*` with `owner_club_id = auth_club_id()`; verified isolation via rollback transactions. |
| `promote_to_manager` trusted caller-supplied `club_id` (privilege escalation) | Hardened to admin-only, club derived from admin profile. |
| Long-running ML decoupled from UI | Engine abstraction + staged progress + simulator fallback. |
| Recurring dev disk-full truncating builds | Documented; free `~/.gradle/caches`; builds need ~1.5–2 GB. |

---

# Chapter 6 — Testing & Evaluation

## 6.1 Testing Types Performed
- **Static analysis**: `flutter analyze` kept clean (0 prod issues at integration milestones).
- **Unit tests** (`test/`): `core/services/api_service_test.dart`, `core/services/auth_interceptor_test.dart`, `features/auth/auth_controller_test.dart`, `widget_test.dart` (`flutter_test` + `mocktail`).
- **Integration / RLS isolation tests**: rollback-transaction tests against Supabase using `set local role authenticated` + `set_config('request.jwt.claims', …)` — verified two admins each see only their own club's players (0 cross-club), manager path identical, and the aggregation trigger building `player_intelligence`. Cross-manager sharing within one club also verified.
- **Manual system testing**: end-to-end upload→analysis→view on the Android emulator; PDF generation tested (`python test_generate.py` → valid PDF; `curl POST /player-report` → HTTP 200 `application/pdf`).
- **Usability**: role-based walkthroughs of each shell.

## 6.2 Evaluation Metrics (SWE side)
- **Functional correctness**: each FR demonstrably satisfied end-to-end.
- **RLS isolation**: 0 cross-tenant rows leaked (pass/fail security metric).
- **Latency**: cache hit avoids DB round-trip (clubs 10-min / players 8-min TTL); pagination page size 12.
- **Pipeline resilience**: simulator fallback success rate 100% when ML unavailable.
> Model accuracy / precision / recall / F1 metrics are **owned by the AI sub-team** and reported against their datasets.

## 6.3 Experimental Setup
- **Software**: Flutter (Dart 3.4+), Android emulator (`emulator-5554`), Supabase cloud project, FastAPI/uvicorn local (`:8000`).
- **Data**: seeded **Al Ahly** demo tenant — club AlAhly, admin `ahmed.sameh@alahly.com`, managers `mohamed.wael@…` / `karim.hassan@…` (password `Ahmed123`), 22 players with full bios, 2 pre-analyzed matches (Al Ahly 2-1 Zamalek, 3-0 Pyramids), 44 per-player verdicts → 22 `player_intelligence` profiles; 7 additional public Egyptian-league clubs for fan standings; fan demo `fan@goalsight.ai`.
- **Configurations**: `.env` with Supabase keys; `ANALYSIS_API_URL` empty (simulator) for offline runs, set for live-model runs; `PDF_API_URL=http://10.0.2.2:8000`.

---

# Chapter 7 — Results & Discussion

## 7.1 Results (SWE)
- Fully working three-role app on a live multi-tenant Supabase backend.
- End-to-end pipeline: upload → private storage → job → analysis (sim or real) → persisted `match_analyses`+children → `player_intelligence` aggregation → refreshed UI → playable analyzed video + per-player verdicts + heatmaps.
- Verified per-club isolation (0 cross-tenant leakage) and within-club manager sharing.
- Working PDF export (≈94 KB, multi-section, embedded heatmaps).
- Live demo data: 33 tables populated (e.g. `match_player_analysis` 44 rows, `player_intelligence` 22, `activity_logs` 156).

## 7.2 Discussion / Trade-offs
- **Simulator fallback** trades "always real" for "always demoable" — chosen so the SWE deliverable never blocks on the ML service.
- **Repository + bridge providers** trade some indirection for zero-UI-change backend swaps — paid off repeatedly during integration.
- **Role from DB (not JWT)** trades a per-request `profiles` read for security correctness — chosen deliberately.
- **In-memory cache** trades possible staleness for latency — mitigated by explicit invalidation on writes.

## 7.3 Limitations
- Fan home still shows curated/static matches because club-scoped RLS makes `match_analyses` unreadable to fans (a deliberate privacy stance; making it public is a product decision).
- Very large video upload is `readAsBytes`-into-memory (streaming upload is a TODO).
- `matches`/`match_events` live-match tables exist and are Realtime-enabled but not yet populated by a live source.
- Real ML model accuracy is reported by the AI sub-team, not here.

---

# Chapter 8 — Ethics, Compliance & Standards

## 8.1 Ethical AI Considerations
- **Explainability**: every player verdict carries an `insight` string and structured sub-scores rather than an opaque number.
- **Fairness/bias**: ratings/fatigue come from the AI sub-team's models; the SWE layer stores raw `analysis_artifacts` (`model_output`) so outputs are auditable and re-derivable.
- **Human-in-the-loop**: analysis informs the coach; it does not take roster decisions automatically.

## 8.2 Ethical Risks Assessed & Mitigated
| Risk | Mitigation |
|---|---|
| **Cross-tenant data exposure** | RLS `owner_club_id = auth_club_id()` on every table; verified isolation; private storage buckets path-scoped to club. |
| **Privilege escalation** | Role from `profiles` via SECURITY DEFINER helpers; `promote_to_manager` admin-only; `players` no longer a login role. |
| **AI over-trust / misuse** | Explainable verdicts + raw artifacts retained; human-in-the-loop framing. |
| **Player privacy** | Player data is club-private; not exposed to fans. |
| **Reliability/safety** | Graceful degradation (simulator), failure states surfaced (no fake success). |

## 8.3 Data Handling & Consent
- **Auth & consent**: email/password or Google OAuth; email OTP verification.
- **Storage & protection**: private buckets (`match-videos`, `analysis-exports`, `reports`); signed URLs (7-day) for playback.
- **Access control**: RLS on all 33 tables; owner-scoped + role-scoped policies.
- **Secrets**: `.env` gitignored; never committed; anon key only client-side, service operations behind RLS.

## 8.4 Standards Followed & Why
- **OWASP** (web/mobile top-10 mindset): least-privilege policies, no trust in client metadata, secrets management, transport (HTTPS for cloud; cleartext only for local dev `10.0.2.2`).
- **GDPR principles**: data minimization (players store only needed bio), purpose limitation (per-club), right-to-erasure feasible (owner-scoped rows), private-by-default storage.
- **Secure SWE practices**: dependency inversion, defense-in-depth (RLS + app guards + routing guards), idempotent migrations, auditable `activity_logs`.
- **Accessibility**: responsive scaling, high-contrast dark theme, large tap targets, haptic feedback.

## 8.5 Known pre-existing advisor notes (disclosed)
`handle_new_user` is SECURITY DEFINER and callable by anon/authenticated (signup trigger); leaked-password protection toggle and a couple of public storage buckets are environment-level Supabase settings to harden before production.

---

# Chapter 9 — Conclusions & Future Work

## 9.1 Achievements
A complete, secure, multi-tenant, three-role football-analysis mobile app with a clean, single-seam AI integration that is demoable with or without the live models, plus a working PDF reporting service and a verified RLS isolation model.

## 9.2 Lessons Learned
- Decoupling heavy ML behind one HTTP contract + a simulator made parallel team-work and reliable demos possible.
- RLS is powerful but subtle — OR-combined role policies silently broke isolation until rewritten and **tested**.
- Repository + bridge-provider patterns made an incremental mock→real migration painless.

## 9.3 Future Work
- **Plug in the real models** (set `ANALYSIS_API_URL`) and report end-to-end model metrics.
- **Streaming/resumable** large-video upload.
- **Live match** ingestion to populate `matches`/`match_events` (Realtime already wired).
- **Monetization** via the existing subscription tables (freemium fan/paid club).
- **Public fan analytics** (decide RLS/privacy policy for exposing analyzed matches to fans).
- **Push notifications**, CI/CD pipeline, and store distribution.

## 9.4 Long-term Vision
An affordable, mobile-first tactical-intelligence platform for the long tail of football, expandable to other sports by swapping the model backend behind the same contract.

---

# References (starter list — format in IEEE for the final report)
- Flutter & Dart documentation — https://flutter.dev , https://dart.dev
- Riverpod — https://riverpod.dev
- GoRouter — https://pub.dev/packages/go_router
- Supabase (Auth, Postgres, Storage, Realtime, RLS) — https://supabase.com/docs
- PostgreSQL Row-Level Security — https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- FastAPI — https://fastapi.tiangolo.com ; fpdf2 — https://py-pdf.github.io/fpdf2/
- OWASP Mobile / Top Ten — https://owasp.org/www-project-top-ten/
- I. Sommerville, *Software Engineering*, 10th ed., Pearson, 2016.
- (AI sub-team) references for player detection, multi-object tracking, event spotting, pose estimation, tactical analysis datasets.

---

# Appendix 1 — User Guide

### System requirements
Android device/emulator (API level per Flutter min); internet for Supabase; optional local PDF service; optional ML service.

### Installation & setup (developer)
1. Install Flutter SDK (Dart ≥3.4.3). 2. `flutter pub get`. 3. Create `.env` (copy `.env.example`) with `SUPABASE_URL`, `SUPABASE_ANON_KEY`, optional `ANALYSIS_API_URL`, `PDF_API_URL`. 4. `flutter run -d <device>` or `flutter build apk --debug`.
- **PDF service**: `cd pdf_service && pip install -r requirements.txt && uvicorn main:app --host 0.0.0.0 --port 8000`. Emulator reaches it at `http://10.0.2.2:8000`.
- **DB**: apply `supabase/migrations/*.sql` in order in the Supabase SQL editor.

### Demo accounts
- Admin: `ahmed.sameh@alahly.com` / `Ahmed123` · Managers: `mohamed.wael@alahly.com`, `karim.hassan@alahly.com` / `Ahmed123` · Fan: `fan@goalsight.ai`.

### Workflows (per role)
- **Manager — analyze a match**: Login → Upload tab → pick video → enter teams/competition/venue/date → Review & Confirm → watch AI Processing → Analysis Ready → "View Analysis"; manage squad via Players → +; export a player PDF from a player profile.
- **Admin — set up club**: Login → if no club, "Create Club" banner → create → promote managers (set permissions) → review squad intelligence, club analytics, notifications.
- **Fan**: Browse Clubs (search), Standings, Highlights, gamified Profile.

### Troubleshooting
- "No club assigned" on upload → ask admin to add you to a club.
- Build fails with `mergeDebugJavaResource` EOF → free disk (`~/.gradle/caches`), need ~1.5–2 GB.
- Data shows in Supabase but not the app → rebuild/reinstall APK (stale build).
- Fan Clubs list error → ensure the disambiguated `players!players_team_id_fkey(*)` embed is present.

---

# Appendix 2 — Lessons, Challenges, Improvements
- **Challenges**: RLS isolation correctness; decoupling ML; recurring disk-full builds; PostgREST embed ambiguity.
- **Improvements/extensions**: streaming upload; live-match ingestion; push notifications; CI/CD; monetization; public fan analytics; multi-sport via the same model contract.

---

## Appendix — File/Module Index (for quick citation in the report)
| Concern | Path |
|---|---|
| App entry | `lib/main.dart` |
| Design tokens | `lib/core/theme/app_theme.dart` |
| Routing/guards | `lib/providers/router_provider.dart` |
| Auth | `lib/data/repositories/auth_repository.dart`, `lib/features/auth/` |
| **AI engine + contract** | `lib/data/services/analysis_engine.dart`, `lib/core/config/analysis_config.dart` |
| Upload workflow | `lib/features/manager/screens/upload_match_screen.dart` |
| Repositories | `lib/data/repositories/interfaces/`, `…/supabase/`, `lib/providers/repository_providers.dart` |
| Models (27) | `lib/data/models/` |
| Cache/errors/pagination | `lib/core/services/cache_service.dart`, `lib/core/errors/app_error.dart`, `lib/providers/paginated_notifier.dart` |
| Realtime WS | `lib/core/services/websocket_service.dart` |
| PDF service | `pdf_service/main.py`, `pdf_service/pdf_generator.py` |
| DB migrations (52) | `supabase/migrations/001…052_*.sql` |
| Tests | `test/` |
| Roadmap / plans | `DEVELOPMENT_ROADMAP.md`, `MAINTENANCE_AND_FEATURES_PLAN.md`, `CLAUDE.md` |
