# GOALSIGHT — Maintenance & New Features Plan

> Working backlog converted from raw notes ("Maintenance or new features").
> Last updated: 2026-06-17 · Status legend: ☐ todo · ◐ in progress · ☑ done
>
> Scope tags: `[auth]` `[admin]` `[manager]` `[fan]` `[whole-app]` `[backend]`
> Each item lists: **Problem → Goal → Affected files → Approach → Acceptance**.

---

## Priority overview

| # | Item | Scope | Type | Priority | Effort |
|---|------|-------|------|----------|--------|
| 1 | Bottom nav bar overlaps page content | whole-app | Bug | **P0** | S |
| 2 | Remove mock login | auth | Cleanup | **P0** | S |
| 3 | Email OTP verification (SMTP) | auth/backend | Feature | **P0** | M |
| 4 | Forgot password with OTP | auth/backend | Feature | **P0** | M |
| 5 | Google Sign-In (front + back) | auth/backend | Feature | **P1** | M |
| 6 | Admin ⇄ Managers org hierarchy (club tenancy) | admin/backend | Feature | **P1** | L |
| 7 | Replace remaining mock data | whole-app | Integration | **P1** | L |
| 8 | Admin notifications (logic + wiring) | admin/backend | Feature | **P1** | M |
| 9 | Manager players filtering | manager | Bug/Feature | **P1** | M |
| 10 | Analyzed-video output in match analysis | manager/backend | Feature | **P1** | L |
| 11 | Fan profile page UX redesign | fan | UX | **P2** | M |
| 12 | Tools & settings actions wired | whole-app | Bug | **P2** | M |
| 13 | Add 1→5 call-to-actions across app | whole-app | UX | **P2** | M |

---

## 1. ☑ `[whole-app]` Bottom nav bar overlays pages

**Problem.** The bottom navigation bar floats over and covers the bottom of page content on all three roles.

**Goal.** Page scroll content ends above the nav bar; no content is hidden behind it.

**Affected files.**
- `lib/presentation/screens/fan/fan_navigation_screen.dart`
- `lib/presentation/screens/admin/admin_navigation_screen.dart`
- `lib/features/manager/screens/manager_navigation_screen.dart`
- `lib/presentation/widgets/{fan,admin}/*_bottom_navigation_bar.dart`, `lib/features/manager/widgets/manager_bottom_navigation_bar.dart`
- Individual screens that set their own bottom padding (e.g. `clubs_screen.dart` already pads `100`).

**Approach.**
- Decide one consistent strategy: either (a) `Scaffold(bottomNavigationBar: ...)` with `extendBody: false` so the body is laid out above it, or (b) keep the floating/`IndexedStack` overlay but expose a single `kBottomNavHeight` constant and have each screen reserve it via bottom padding / `SafeArea(bottom:false)` + explicit padding.
- Audit each role's navigation screen — the issue is almost certainly an overlaid `Stack` with the nav bar positioned on top instead of a real `bottomNavigationBar` slot.
- Standardize the reserved height constant in `core/` and replace the ad-hoc `100`/`120` paddings.

**Acceptance.** On every tab of every role, the last list item / button is fully visible and tappable above the nav bar on a small device.

---

## 2. ☑ `[auth]` Remove mock login

**Problem.** Demo / quick-role login chips (`DemoLoginSection`) and any hardcoded credential path still exist; auth is now real Supabase.

**Goal.** Only real Supabase email/password (+ Google, item 5) login remains. No demo bypass in production builds.

**Affected files.**
- `lib/presentation/widgets/auth_card_widgets.dart` (`DemoLoginSection`)
- `lib/presentation/screens/auth/login_screen.dart`
- `lib/features/auth/auth_controller.dart`

**Approach.**
- Remove `DemoLoginSection` usage from `login_screen.dart` (or gate behind a `kDebugMode && kEnableDemoLogin` flag).
- Delete/disable any controller path that signs in without hitting Supabase.
- Verify the three demo accounts noted in memory are no longer required for navigation.

**Acceptance.** Fresh install can only authenticate via real credentials / Google; no chips visible in release mode.

---

## 3. ☑ `[auth][backend]` Email OTP verification (SMTP)

**Problem.** Need email verification via an OTP code sent to the user's email (not just a magic link).

**Goal.** On register, user receives a 6-digit OTP by email; entering it verifies the account.

**Affected files.**
- `lib/presentation/screens/auth/email_verification_screen.dart` (OTP input UI)
- `lib/features/auth/auth_controller.dart`, `auth_state.dart` (`emailVerificationRequired` already exists)
- `lib/data/repositories/auth_repository.dart`
- Supabase: Auth email templates + custom SMTP, or an Edge Function for OTP.

**Approach.**
- Configure **custom SMTP** in Supabase Auth settings (use the `supabase` skill).
- Use Supabase OTP flow: `signInWithOtp` / `verifyOTP(type: email)` — Supabase supports email OTP codes; switch the email template to the `{{ .Token }}` 6-digit code instead of a confirmation link.
- Build OTP entry UI (6 boxes) in `email_verification_screen.dart`; on submit call `verifyOTP`.
- Add resend-with-cooldown.

**Acceptance.** Register → email arrives with 6-digit code → entering correct code authenticates; wrong/expired code shows error; resend works.

---

## 4. ☑ `[auth][backend]` Forgot password with OTP

**Problem.** Forgot-password should use an OTP code, not a reset link.

**Goal.** User enters email → receives OTP → verifies → sets new password.

**Affected files.**
- `lib/presentation/screens/auth/forgot_password_screen.dart`
- `auth_repository.dart`, `auth_controller.dart`

**Approach.**
- Use `resetPasswordForEmail` configured for OTP template, then `verifyOTP(type: recovery)` to get a session, then `updateUser(password:)`.
- Reuse the OTP widget from item 3 (extract a shared `OtpInput` widget).
- Three-step flow: email → OTP → new password.

**Acceptance.** Full reset cycle works end-to-end; old password no longer valid, new one logs in.

---

## 5. ☑ `[auth][backend]` Google Sign-In (front + back)

**Problem.** No "Sign in with Google".

**Goal.** Google OAuth login on the login + register screens, wired to Supabase.

**Affected files.**
- `lib/presentation/screens/auth/login_screen.dart`, `register_screen.dart`
- `auth_repository.dart`, `auth_controller.dart`
- `android/app/...` (OAuth client, SHA-1, deep-link/redirect), `pubspec.yaml` (`google_sign_in` or native Supabase OAuth + deep link)
- Supabase: enable Google provider, set client IDs + redirect URL.

**Approach.**
- Enable Google provider in Supabase; create Google Cloud OAuth credentials (Android client w/ SHA-1, plus web client for Supabase).
- Use `supabase.auth.signInWithOAuth(OAuthProvider.google)` with app deep-link redirect (`io.supabase.goalsight://login-callback`) OR `signInWithIdToken` via `google_sign_in` for native UX.
- Configure Android intent filter for the redirect scheme.
- Ensure a `profiles` row + default role is created on first Google login (trigger or post-login upsert).

**Acceptance.** Tapping "Continue with Google" completes OAuth and lands the user on their role home with a profile row created.

---

## 6. ☑ `[admin][backend]` Admin ⇄ Managers org hierarchy (club tenancy)

**Problem.** Admin should behave like a **club owner**: managers belong to the admin's club, do the analyses, and the admin sees all data produced by his managers. Currently admin and managers aren't linked.

**Goal.** Model the org so an admin owns a club; managers are attached to that club/admin; admin reads aggregated data of his managers only (multi-tenant by club).

**Affected files / DB.**
- New/extended schema: a `club_id` (or `org_id`) owner relationship — `profiles.club_id`, `clubs.owner_admin_id`, `managers.club_id`.
- RLS policies: admin can `SELECT` rows where `club_id = his club`; managers scoped to their own club.
- `lib/features/admin/admin_controller.dart`, `admin_state.dart`
- `lib/data/repositories/supabase/supabase_manager_repository.dart`, `supabase_analysis_repository.dart`, `supabase_player_repository.dart`
- Admin providers: `adminManagersProvider`, `adminSquadProvider`, `adminSystemOverviewProvider` (filter by admin's club).
- New migration `036_org_hierarchy.sql`.

**Approach.**
1. Add `club_id` to `profiles` (both admins and managers carry it); admin's profile is the club owner.
2. Backfill/seed: each admin → one club; managers reference that `club_id`.
3. Rewrite admin repository queries to filter by the signed-in admin's `club_id` (managers, analyses, players, uploads, overview counts).
4. Add RLS so the filtering is enforced server-side, not just client-side.
5. Admin UI (managers list, squad, analytics) now reflects only his club's data.

**Acceptance.** Admin A sees only managers/analyses/players belonging to club A; admin B sees only club B's; a manager's new analysis appears under their owning admin automatically.

> Depends on item 7 (real data) and informs items 8 & 10.

---

## 7. ☑ `[whole-app]` Replace remaining mock data

**Problem.** Parts of the app still read mock data.

**Goal.** All user-facing data flows from Supabase. Mock files retained only for tests/empty-state fallbacks if needed.

**Known remaining mock surfaces** (from CLAUDE.md + memory):
- `lib/features/manager/manager_dashboard_mock_data.dart`
- `lib/features/manager/manager_matches_mock_data.dart`
- `lib/features/manager/manager_upload_mock_data.dart`
- `lib/features/manager/players_mock_data.dart`
- `lib/features/admin/data/admin_mock_data.dart` (`tacticalInsights` still used in `admin_home_dashboard.dart`; `AdminDashboardHero` reads managers/squad/alerts)
- `fanLiveMatchesProvider` (no live matches table yet)

**Approach.**
- Audit each mock file → confirm whether a Supabase repository + table already exists; if yes, wire the screen to the provider (follow the Phase-2 pattern); if no, add table + repository + migration.
- For `fanLiveMatches` and dashboard heroes, define the missing tables (e.g. a `matches` table) before wiring.
- Track each conversion as a sub-checkbox below.

**Sub-tasks.**
- ☑ Manager dashboard → Supabase
- ☑ Manager matches → Supabase
- ☑ Manager upload history → already Supabase (verified)
- ☑ Manager players → already Supabase (verified)
- ☑ Admin tactical insights / hero / squad / analytics → Supabase
- ☐ Fan live matches → deferred (needs `matches` table)

**Acceptance.** `grep` for `*_mock_data` shows no imports from screens/providers in production paths (tests excepted).

---

## 8. ☑ `[admin][backend]` Notifications — logic + wiring

**Problem.** Admin notifications don't work and the trigger logic is undefined.

**Goal.** Define what generates a notification, persist them, and show them in the admin UI.

**Proposed notification logic (to confirm).** Emit a notification to the club's admin when:
- a manager uploads a match / an analysis completes,
- an upload job fails,
- a player crosses a risk threshold (high/critical),
- a new manager is added to the club.

**Affected files / DB.**
- New `notifications` table (`id, recipient_id, club_id, type, title, body, related_id, read, created_at`) + RLS (recipient-scoped) → migration `037_notifications.sql`.
- DB triggers or Edge Functions to insert notifications on the events above.
- `lib/data/repositories/supabase/` → new `supabase_notification_repository.dart`.
- Provider + admin notifications screen/badge.

**Approach.**
- Build the table + repository first; back the existing admin notifications UI with a `notificationsProvider` (filtered by recipient = admin, scoped by club from item 6).
- Add triggers incrementally (start with upload-complete + risk-threshold).
- Mark-as-read + unread count badge.

**Acceptance.** Completing an upload as a manager creates a notification visible to that club's admin; tapping marks read; badge count updates.

---

## 9. ☑ `[manager]` Players page filtering

**Problem.** Filtering on the manager players page is incorrect and lacks enough filters.

**Goal.** Working, comprehensive filters.

**Affected files.**
- `lib/features/manager/screens/players_screen.dart`
- `lib/features/manager/players_mock_data.dart` (→ replace per item 7)

**Approach.**
- Fix current filter logic bugs (verify predicate composition / case sensitivity).
- Add filters: position, status (active/injured/suspended), risk level, form/trend, rating range, search by name. Combine as AND.
- Push filtering server-side via repository (`fetchPlayersPaged` already supports `.ilike` + column mapping) where feasible; keep client filter for small lists.

**Acceptance.** Each filter narrows results correctly; combined filters intersect; clearing resets.

---

## 10. ☑ `[manager][backend]` Analyzed-video output in match analysis

**Problem.** The model output includes an **analyzed/annotated video** in addition to stats; after upload + analysis the app should display this video output.

**Goal.** When analysis completes, the result screen surfaces the analyzed video alongside the existing tactical output.

**Affected files / DB.**
- `match_analyses` (or `analysis_artifacts`) — store `analyzed_video_path` / artifact row pointing to a Storage object.
- Reuse `analysis-exports` Storage bucket or a dedicated `analyzed-videos` bucket.
- `lib/data/models/match_analysis_model.dart` — add video URL/artifact field.
- `lib/data/repositories/supabase/supabase_analysis_repository.dart` — return the video artifact + signed URL.
- Upload/result screens under `lib/features/manager/` — add a video player section (add `video_player` / `chewie` to `pubspec.yaml`).

**Approach.**
- Backend/model writes the analyzed video to Storage and records the artifact (path, type=`analyzed_video`) when the job finishes.
- App polls/loads analysis → if a video artifact exists, fetch a signed URL and render a player; otherwise show "video processing".
- Gate the player behind job status = completed.

**Acceptance.** After a successful analysis, the result screen plays the annotated video; while processing it shows a placeholder; stats still render independently.

---

## 11. ☑ `[fan]` Fan profile page UX redesign

**Problem.** Fan profile page UX is poor — too much information crammed in.

**Goal.** Cleaner, scannable profile with clear hierarchy and progressive disclosure.

**Affected files.**
- `lib/presentation/screens/fan/profile_screen.dart`
- `lib/presentation/widgets/fan/profile_widgets.dart`

**Approach.**
- Restructure into sections: identity header → key stats (3–4 max) → grouped settings list → secondary info behind expandable tiles / a separate "Account details" screen.
- Apply design-system spacing/typography; reduce simultaneous on-screen density.
- Consider `ui-ux-pro-max` skill for layout pass.

**Acceptance.** Profile reads top-to-bottom with clear groups; no wall of fields; primary actions reachable in one scroll.

---

## 12. ☑ `[whole-app]` Tools & settings actions wired

**Problem.** Tools & settings entries in profile pages (manager and others) do nothing.

**Goal.** Every settings/tools row performs a real action or is removed.

**Affected files.**
- `lib/features/manager/widgets/profile_header.dart` + manager profile screen
- `lib/presentation/screens/fan/profile_screen.dart`
- `lib/presentation/screens/admin/admin_profile_page.dart`

**Approach.**
- Inventory each row (edit profile, change password, notifications prefs, theme, logout, about, help…).
- Wire to real flows: edit profile → Supabase `updateUser`; change password → reuse OTP flow; logout → auth controller; notifications prefs → item 8; remove anything not yet supported.

**Acceptance.** No dead taps in any profile page; each row navigates or performs its action.

---

## 13. ☑ `[whole-app]` Add 1→5 call-to-actions

**Problem.** Screens lack clear next-step actions ("1 → 5 call to actions for anything in the app").

**Goal.** Each major screen offers clear primary (and where useful secondary) CTAs guiding the user's next step.

**Approach.**
- Audit each role's main screens; for each, define a primary CTA (e.g. Fan club detail → "Follow"; Manager dashboard → "Upload match"; Admin → "Invite manager"; analysis result → "Export / Share").
- Add empty-state CTAs (e.g. no analyses yet → "Upload your first match").
- Keep consistent button styling (`AppGradients.brand`, `HapticService`).

**Acceptance.** Every primary screen and empty state has at least one obvious CTA; no dead-end views.

---

## Suggested execution order

1. **Quick wins / unblockers:** #1 (nav overlap), #2 (remove mock login).
2. **Auth completion:** #3 OTP verify → #4 forgot-OTP → #5 Google.
3. **Tenancy foundation:** #6 admin/manager hierarchy (unblocks #8 scoping).
4. **Data + features:** #7 mock removal, #9 filters, #8 notifications, #10 analyzed video.
5. **UX polish:** #11 fan profile, #12 settings wiring, #13 CTAs.

## New migrations introduced by this plan
- `036_org_hierarchy.sql` — club ownership + `club_id` on profiles/managers + RLS (#6)
- `037_notifications.sql` — notifications table + triggers/RLS (#8)
- analysis schema change for `analyzed_video` artifact (#10) — fold into existing analysis migration or add `038_analyzed_video.sql`
