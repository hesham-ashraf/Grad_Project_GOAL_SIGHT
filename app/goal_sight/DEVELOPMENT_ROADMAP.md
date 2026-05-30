# GOALSIGHT MOBILE APP - DEVELOPMENT ROADMAP

This roadmap tracks the remaining work to fully complete the GoalSight app.

Status rules:
- `[x]` = implemented in the codebase
- `[ ]` = still pending
- `Sign-off` = fill your initials or name when you complete or verify the task

Recommended sign-off format:
- `Sign-off: AH | Date: 2026-05-27`

Last reviewed against the codebase: `2026-05-29`

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

- [x] Create `users` table | Sign-off: ______ | Date: ______
- [x] Create `teams` table | Sign-off: ______ | Date: ______
- [x] Create `players` table | Sign-off: ______ | Date: ______
- [ ] Create `managers` table | Sign-off: ______ | Date: ______
- [x] Create `matches` table | Sign-off: ______ | Date: ______
- [ ] Create `analyses` table | Sign-off: ______ | Date: ______
- [x] Create `match events` table | Sign-off: ______ | Date: ______
- [x] Create `videos` table | Sign-off: ______ | Date: ______
- [ ] Create `tactical_reports` table | Sign-off: ______ | Date: ______
- [x] Create `player_match_stats` table | Sign-off: ______ | Date: ______
- [ ] Create `notifications` table | Sign-off: ______ | Date: ______
- [x] Create `venues` table | Sign-off: ______ | Date: ______
- [x] Create `match_players` table | Sign-off: ______ | Date: ______
- [x] Create `upload_jobs` table | Sign-off: ______ | Date: ______
- [x] Create `subscription_plans` table | Sign-off: ______ | Date: ______
- [x] Create `user_subscriptions` table | Sign-off: ______ | Date: ______
- [x] Create `tracking_snapshots` table | Sign-off: ______ | Date: ______

### 10. Authentication Integration

- [ ] Connect login | Sign-off: ______ | Date: ______
- [ ] Connect signup | Sign-off: ______ | Date: ______
- [ ] Connect forgot password | Sign-off: ______ | Date: ______
- [ ] Connect email verification | Sign-off: ______ | Date: ______
- [ ] Connect role management | Sign-off: ______ | Date: ______
- [ ] Connect session persistence | Sign-off: ______ | Date: ______

### 11. Data Integration

- [ ] Replace mock repositories | Sign-off: ______ | Date: ______
- [ ] Create Supabase services | Sign-off: ______ | Date: ______
- [ ] Create async state management | Sign-off: ______ | Date: ______
- [ ] Add pagination | Sign-off: ______ | Date: ______
- [ ] Add caching | Sign-off: ______ | Date: ______
- [ ] Add proper error handling | Sign-off: ______ | Date: ______

### 12. Storage System

- [x] Match video uploads | Sign-off: ______ | Date: ______
- [x] Player images | Sign-off: ______ | Date: ______
- [x] Club logos | Sign-off: ______ | Date: ______
- [ ] Analysis exports | Sign-off: ______ | Date: ______
- [ ] Report storage | Sign-off: ______ | Date: ______

### 13. Realtime Features

- [x] Real-time infrastructure configured | Sign-off: ______ | Date: ______
- [ ] Live upload progress | Sign-off: ______ | Date: ______
- [ ] Live notifications | Sign-off: ______ | Date: ______
- [ ] Live activity feeds | Sign-off: ______ | Date: ______
- [ ] Real-time analysis updates | Sign-off: ______ | Date: ______

---

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

- [ ] Add role validation | Sign-off: ______ | Date: ______
- [ ] Secure uploads | Sign-off: ______ | Date: ______
- [ ] Secure storage access | Sign-off: ______ | Date: ______
- [ ] Validate permissions | Sign-off: ______ | Date: ______

### 20. Testing

- [ ] UI testing | Sign-off: ______ | Date: ______
- [ ] Responsive testing | Sign-off: ______ | Date: ______
- [ ] Navigation testing | Sign-off: ______ | Date: ______
- [ ] Upload workflow testing | Sign-off: ______ | Date: ______
- [ ] State management testing | Sign-off: ______ | Date: ______

### 21. Deployment

- [ ] App icons | Sign-off: ______ | Date: ______
- [ ] Splash screen | Sign-off: ______ | Date: ______
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
