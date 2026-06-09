# Phase 15 Authenticated Runtime Validation

This file completes Phase 15 after the catalog audit in `032_policy_validation_queries.sql`.

Catalog validation can prove that policies exist. It cannot prove runtime authorization. The tests below must be executed through real authenticated Supabase client sessions using the supplied users.

## Test Users
| Role | User ID |
| --- | --- |
| Admin | `26357f17-0004-426f-83c3-1a127e8ff83e` |
| Manager | `baf4f830-9142-46da-8ebc-adf80919ac8e` |
| Player | `35783d1b-90f3-4f79-8cf4-ffb2b03bd530` |
| Fan | `a14fa62f-b619-4821-b256-d2da35d0a7ca` |

Player mapping:
- Player name: `Ahmed Striker`
- `players.profile_id = 35783d1b-90f3-4f79-8cf4-ffb2b03bd530`

## Important Runtime Finding: `has_role()`
Observed issue:
- `select public.has_role('manager')` returned `FALSE` for the manager profile even though `profiles.role = 'manager'`.
- Previous SQL Editor simulations also produced stack depth errors and unreliable `auth.uid()` behavior.

Likely causes:
- SQL Editor calls are not authenticated as the target end user, so `auth.uid()` is normally `null`; `public.has_role('manager')` should return `FALSE` in that context.
- `public.has_role(role_name text)` reads `public.profiles`.
- `public.profiles` has admin policies that call `public.has_role('admin')`.
- Under authenticated runtime RLS, this can recurse: policy calls `has_role()`, `has_role()` queries `profiles`, `profiles` policy calls `has_role()` again, causing `stack depth limit exceeded`.

Runtime correctness verdict:
- All policies that depend on `public.has_role()` require authenticated client validation.
- If stack depth errors occur in real authenticated clients, production approval is blocked until `public.has_role()` is redesigned to avoid RLS recursion.

Recommended follow-up if runtime tests fail:
- Replace `public.has_role()` with a non-recursive security-definer helper or another role source that does not query `profiles` through its own RLS policies.
- Re-run catalog validation and this authenticated runtime suite after the fix.

## Policies Referencing `has_role()`
These policy groups depend on `public.has_role()` and therefore require authenticated client validation:

| Area | Tables / policies | Runtime status |
| --- | --- | --- |
| Core admin access | `profiles`, `teams`, `players`, `matches`, `match_events`, `player_match_stats`, `videos`, `venues`, `match_players`, `subscription_plans`, `user_subscriptions`, `tracking_snapshots` admin policies | Requires authenticated client validation |
| Core manager access | `teams`, `players`, `matches`, `match_events`, `player_match_stats`, `videos` manager policies | Requires authenticated client validation |
| Public role reads | `teams`, `players`, `matches`, `match_events`, `match_players`, `venues`, `subscription_plans`, `tracking_snapshots` role-read policies | Requires authenticated client validation |
| Player scoped reads | `player_match_stats`, `player_risk_analysis`, `player_intelligence`, `videos` player policies | Requires authenticated client validation |
| Upload workflow | `upload_jobs` admin and manager policies | Requires authenticated client validation |
| Storage | `match-videos` admin, manager, and player storage policies | Requires authenticated client validation |
| Analysis layer | `match_analyses`, `team_match_analysis`, `match_player_analysis`, `tactical_insights`, `analysis_artifacts` | Requires authenticated client validation |
| Engagement layer | `notifications`, `notification_preferences`, `activity_logs`, `highlights` admin/manager/role policies | Requires authenticated client validation |
| Team/manager layer | `team_season_stats`, `team_managers`, `managers` | Requires authenticated client validation |

## Test Execution Rules
- Do not run these tests by spoofing JWT claims in SQL Editor.
- Use real sign-in sessions through Supabase Flutter, Supabase JS, PostgREST, or the Supabase Dashboard API tools.
- Use the anon key for client tests.
- Do not use the service-role key for authorization tests.
- Cleanup writes after each test using an admin or service-role maintenance session only after recording pass/fail results.

## 1. Admin Authorization Tests
### Test A1: Admin can read all target tables
- Exact action: Sign in as admin `26357f17-0004-426f-83c3-1a127e8ff83e` and run `select()` on `profiles`, `teams`, `players`, `matches`, `match_events`, `player_match_stats`, `videos`, `upload_jobs`, `notifications`, and `activity_logs`.
- Expected result: Each query succeeds without RLS errors.
- Pass criteria: All target table reads return HTTP 200 / client success.
- Fail criteria: Any target table returns permission denied, stack depth error, or unexpected empty access caused by RLS.

### Test A2: Admin can manage upload jobs
- Exact action: As admin, insert an `upload_jobs` row with `uploaded_by = baf4f830-9142-46da-8ebc-adf80919ac8e`, then update its `status` and delete it.
- Expected result: Insert, update, and delete succeed.
- Pass criteria: All three operations succeed and the row is removed.
- Fail criteria: Any operation is rejected by RLS or triggers stack depth errors.

### Test A3: Admin notification access
- Exact action: As admin, read notifications for all four users.
- Expected result: Admin can read all notification rows.
- Pass criteria: Query succeeds and is not limited to admin-owned notifications only.
- Fail criteria: Query is denied, restricted unexpectedly, or stack depth error occurs.

### Test A4: Admin activity log access
- Exact action: As admin, read all `activity_logs`.
- Expected result: Read succeeds.
- Pass criteria: Query succeeds.
- Fail criteria: Query is denied or stack depth error occurs.

Note: Admin write access to `activity_logs` is not granted by current policies. If product requires admin-authored activity logs, add a policy before production.

## 2. Manager `upload_jobs` Ownership Tests
### Test M1: Manager can create own upload job
- Exact action: Sign in as manager `baf4f830-9142-46da-8ebc-adf80919ac8e` and insert:
  - `uploaded_by = baf4f830-9142-46da-8ebc-adf80919ac8e`
  - `status = uploaded`
  - `progress = 0`
  - `file_name = phase15-manager-owned.mp4`
- Expected result: Insert succeeds.
- Pass criteria: Row is created and returned to the manager.
- Fail criteria: Insert is denied, `has_role('manager')` evaluates incorrectly, or stack depth error occurs.

### Test M2: Manager can read own upload job
- Exact action: As the manager, query `upload_jobs` filtered by `uploaded_by = baf4f830-9142-46da-8ebc-adf80919ac8e`.
- Expected result: The row from M1 is visible.
- Pass criteria: Own row is returned.
- Fail criteria: Own row is hidden or query errors.

### Test M3: Manager can update own upload job
- Exact action: As the manager, update the M1 row to `status = processing`, `progress = 35`.
- Expected result: Update succeeds.
- Pass criteria: Updated row returns with `progress = 35`.
- Fail criteria: Update is denied or no row is updated.

### Test M4: Manager cannot create upload job for another user
- Exact action: As the manager, attempt to insert `upload_jobs.uploaded_by = a14fa62f-b619-4821-b256-d2da35d0a7ca`.
- Expected result: Insert is rejected by RLS.
- Pass criteria: Client receives an RLS permission error and no row is created.
- Fail criteria: Row is created for the fan.

### Test M5: Manager cannot update another user's upload job
- Exact action: Create a non-manager-owned upload job using admin/service maintenance, then as manager attempt to update it.
- Expected result: Update is rejected or affects zero rows.
- Pass criteria: Other user's row is unchanged.
- Fail criteria: Manager changes another user's row.

## 3. Player Self-Access Tests
### Test P1: Player can read own profile
- Exact action: Sign in as player `35783d1b-90f3-4f79-8cf4-ffb2b03bd530` and query `profiles` where `id = 35783d1b-90f3-4f79-8cf4-ffb2b03bd530`.
- Expected result: Own profile row is returned.
- Pass criteria: One row returns with `role = player`.
- Fail criteria: Row is hidden, denied, or stack depth error occurs.

### Test P2: Player cannot read another user's profile
- Exact action: As the player, query `profiles` where `id = baf4f830-9142-46da-8ebc-adf80919ac8e`.
- Expected result: Manager profile is not returned.
- Pass criteria: Zero rows returned.
- Fail criteria: Player can read manager profile.

### Test P3: Player mapping is correct
- Exact action: As a maintenance/admin check, query `players` for `full_name = Ahmed Striker`.
- Expected result: `profile_id = 35783d1b-90f3-4f79-8cf4-ffb2b03bd530`.
- Pass criteria: Mapping exactly matches the supplied player user ID.
- Fail criteria: Mapping is missing or points to another profile.

### Test P4: Player can read own linked stats
- Exact action: As the player, query `player_match_stats` joined or filtered to Ahmed Striker's `players.id`.
- Expected result: Ahmed Striker stats are visible.
- Pass criteria: Linked player stat rows return.
- Fail criteria: Own stats are hidden, denied, or stack depth error occurs.

### Test P5: Player cannot read another player's stats
- Exact action: As the player, query `player_match_stats` for a different `player_id`.
- Expected result: Other player stats are not returned.
- Pass criteria: Zero rows returned for other player.
- Fail criteria: Other player stats are visible.

### Test P6: Player cannot read upload jobs
- Exact action: As the player, query `upload_jobs`.
- Expected result: No rows are returned.
- Pass criteria: Zero rows returned or access is denied according to client behavior.
- Fail criteria: Player can view manager upload jobs.

## 4. Fan Isolation Tests
### Test F1: Fan can read own profile
- Exact action: Sign in as fan `a14fa62f-b619-4821-b256-d2da35d0a7ca` and query own `profiles` row.
- Expected result: Own profile row is returned.
- Pass criteria: One row returns with `role = fan`.
- Fail criteria: Own row is hidden or denied.

### Test F2: Fan cannot read other profiles
- Exact action: As fan, query manager profile `baf4f830-9142-46da-8ebc-adf80919ac8e`.
- Expected result: Manager profile is not returned.
- Pass criteria: Zero rows returned.
- Fail criteria: Fan can read manager profile.

### Test F3: Fan can read public football data
- Exact action: As fan, query `teams`, `players`, `matches`, and `match_events`.
- Expected result: Queries succeed.
- Pass criteria: Client receives successful responses.
- Fail criteria: Any query is denied or triggers stack depth errors.

### Test F4: Fan cannot read player stats
- Exact action: As fan, query `player_match_stats`.
- Expected result: No rows are returned.
- Pass criteria: Zero rows returned or access is denied according to client behavior.
- Fail criteria: Fan can view player stats.

### Test F5: Fan cannot read videos
- Exact action: As fan, query `videos`.
- Expected result: No rows are returned.
- Pass criteria: Zero rows returned or access is denied according to client behavior.
- Fail criteria: Fan can view videos.

### Test F6: Fan cannot read upload jobs
- Exact action: As fan, query `upload_jobs`.
- Expected result: No rows are returned.
- Pass criteria: Zero rows returned or access is denied according to client behavior.
- Fail criteria: Fan can view upload jobs.

### Test F7: Fan notification ownership
- Exact action: As fan, query `notifications` where `user_id = a14fa62f-b619-4821-b256-d2da35d0a7ca`, then query another user's notifications.
- Expected result: Own notifications are visible; other users' notifications are hidden.
- Pass criteria: Own rows only.
- Fail criteria: Other users' notifications are visible.

### Test F8: Fan activity ownership
- Exact action: As fan, insert `activity_logs.actor_id = a14fa62f-b619-4821-b256-d2da35d0a7ca`, then try `actor_id = baf4f830-9142-46da-8ebc-adf80919ac8e`.
- Expected result: Own insert succeeds; other-user insert is rejected.
- Pass criteria: RLS enforces `actor_id = auth.uid()`.
- Fail criteria: Fan can write activity for another user.

## 5. Storage Authorization Tests
### Test S1: Public buckets are readable
- Exact action: Without signing in, read an existing object from `team-logos` and `player-images`.
- Expected result: Public read succeeds.
- Pass criteria: Object URLs or downloads succeed.
- Fail criteria: Public reads are denied unexpectedly.

### Test S2: Manager can upload match video
- Exact action: As manager, upload a small test object to `match-videos`.
- Expected result: Upload succeeds.
- Pass criteria: Object is created in `match-videos`.
- Fail criteria: Upload is denied or stack depth error occurs.

### Test S3: Manager can read match video
- Exact action: As manager, download/read the S2 object.
- Expected result: Read succeeds.
- Pass criteria: Object downloads.
- Fail criteria: Read is denied.

### Test S4: Player can read match video
- Exact action: As player, download/read the S2 object.
- Expected result: Read succeeds.
- Pass criteria: Object downloads.
- Fail criteria: Read is denied.

### Test S5: Fan cannot read match video
- Exact action: As fan, attempt to download/read the S2 object.
- Expected result: Read is denied.
- Pass criteria: Client receives storage authorization error.
- Fail criteria: Fan can read private match video.

### Test S6: Fan cannot upload match video
- Exact action: As fan, attempt to upload to `match-videos`.
- Expected result: Upload is denied.
- Pass criteria: Client receives storage authorization error and no object is created.
- Fail criteria: Fan upload succeeds.

## 6. Realtime Authorization Tests
### Test R1: Manager receives own upload job updates
- Exact action: As manager, subscribe to `upload_jobs` filtered by `uploaded_by = baf4f830-9142-46da-8ebc-adf80919ac8e`, then update the M1 row.
- Expected result: Realtime update arrives.
- Pass criteria: Manager receives payload for own row.
- Fail criteria: No payload arrives or subscription errors.

### Test R2: Manager does not receive other user's upload job updates
- Exact action: As manager, keep the same subscription and update another user's upload job using admin/service maintenance.
- Expected result: No payload arrives for the other user's row.
- Pass criteria: Manager receives no unauthorized payload.
- Fail criteria: Manager receives another user's upload job payload.

### Test R3: Player receives own stats updates only
- Exact action: As player, subscribe to `player_match_stats` for Ahmed Striker's `player_id`, then update that stat row using admin/service maintenance.
- Expected result: Player receives the linked stat update.
- Pass criteria: Linked payload arrives.
- Fail criteria: No linked payload arrives or subscription errors.

### Test R4: Player does not receive another player's stats
- Exact action: As player, update another player's `player_match_stats` using admin/service maintenance.
- Expected result: No unauthorized payload arrives.
- Pass criteria: Player receives no other-player payload.
- Fail criteria: Player receives another player's stat update.

### Test R5: User receives own notification updates only
- Exact action: As fan, subscribe to `notifications` filtered by `user_id = a14fa62f-b619-4821-b256-d2da35d0a7ca`, then insert/update a fan notification and another user's notification using admin/service maintenance.
- Expected result: Fan receives only own notification payload.
- Pass criteria: Own payload arrives; other-user payload does not.
- Fail criteria: Fan receives another user's notification.

### Test R6: Admin receives activity feed updates
- Exact action: As admin, subscribe to `activity_logs`, then insert activity rows for manager/player/fan.
- Expected result: Admin receives allowed activity payloads.
- Pass criteria: Admin receives activity feed updates.
- Fail criteria: Admin receives no payload due to policy failure or stack depth error.

## Phase 15 Completion Rule
Phase 15 is complete only when:
- `032_policy_validation_queries.sql` returns no `FAIL` rows.
- Every authenticated runtime test above is executed with real sessions.
- Every runtime test passes.
- Any `has_role()` stack depth or false-role behavior is fixed and retested.

Do not assign a production readiness percentage until this authenticated runtime validation is completed successfully.
