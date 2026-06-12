# Phase 15 Coverage Matrix

| Test | Status | Executed | Notes |
| --- | --- | --- | --- |
| A1 Admin can read all target tables | PASS | pass | Admin read 10 tables successfully. |
| A2 Admin can manage upload jobs | PASS | pass | Admin insert, update, and delete succeeded. |
| A3 Admin notification access | PASS | pass | Admin read 12 notification rows. |
| A4 Admin activity log access | PASS | pass | Admin read 101 activity rows. |
| M1 Manager can create own upload job | PASS | pass | Manager-owned upload job created: 9f2f6968-7127-48e3-bd0c-7f1dab4df6e9 |
| M2 Manager can read own upload job | PASS | pass | Manager read own upload job 9f2f6968-7127-48e3-bd0c-7f1dab4df6e9. |
| M3 Manager can update own upload job | PASS | pass | Manager own upload job updated to 35%. |
| M4 Manager cannot create upload job for another user | PASS | pass | Insert into upload_jobs denied as expected: 403 new row violates row-level security policy for table "upload_jobs" |
| M5 Manager cannot update another user's upload job | PASS | pass | Update on upload_jobs returned an empty success response. |
| P1 Player can read own profile | PASS | pass | Player profile read succeeded. |
| P2 Player cannot read another user's profile | PASS | pass | Player could not read manager profile. |
| P3 Player mapping is correct | PASS | pass | Ahmed Striker mapped to 05cc12a7-ffc8-4532-885e-daa345c1954d. |
| P4 Player can read own linked stats | FAIL | fail | Player could not read own linked stats. |
| P5 Player cannot read another player's stats | PASS | pass | Other player stats stayed hidden. |
| P6 Player cannot read upload jobs | PASS | pass | Upload jobs denied to player. |
| F1 Fan can read own profile | PASS | pass | Fan profile read succeeded. |
| F2 Fan cannot read other profiles | PASS | pass | Manager profile hidden from fan. |
| F3 Fan can read public football data | PASS | pass | Fan read teams, players, matches, and match events. |
| F4 Fan cannot read player stats | PASS | pass | Fan player stats request remained empty or denied. |
| F5 Fan cannot read videos | PASS | pass | Fan videos request remained empty or denied. |
| F6 Fan cannot read upload jobs | PASS | pass | Fan upload_jobs request remained empty or denied. |
| F7 Fan notification ownership | PASS | pass | Fan saw own notification and not manager notification. |
| F8 Fan activity ownership | PASS | pass | Insert into activity_logs denied as expected: 403 new row violates row-level security policy for table "activity_logs"; Fan inserted own activity 6a0f3f13-cf7e-40d9-ace7-34679c958ac5. |
| S1 Public buckets are readable | FAIL | fail | Public bucket reads failed: team_ok=false tried=phase15-team-logo-placeholder.txt,phase15/phase15-team-logo-placeholder.txt,phase15; player_ok=false tried=phase15-player-image-placeholder.txt,phase15/phase15-player-image-placeholder.txt,phase15 |
| S2 Manager can upload match video | PASS | pass | Manager uploaded phase15/match-videos/manager-upload-37c5f7f9-e18a-4ccf-ac61-482d19ad72a9.mp4. |
| S3 Manager can read match video | PASS | pass | Manager downloaded match video. |
| S4 Player can read match video | PASS | pass | Player downloaded match video. |
| S5 Fan cannot read match video | PASS | pass | Fan was denied match video download. |
| S6 Fan cannot upload match video | PASS | pass | Upload to match-videos/phase15-match-video-denied-779b187a-32e3-4885-9635-3c579f823373.txt denied as expected: 400 new row violates row-level security policy |
| R1 Manager receives own upload job updates | FAIL | fail | Timed out waiting for realtime payload. |
| R2 Manager does not receive other user's upload job updates | FAIL | fail | Timed out waiting for realtime payload. |
| R3 Player receives own stats updates only | FAIL | fail | Timed out waiting for realtime payload. |
| R4 Player does not receive another player's stats | FAIL | fail | Timed out waiting for realtime payload. |
| R5 User receives own notification updates only | FAIL | fail | Timed out waiting for realtime payload. |
| R6 Admin receives activity feed updates | FAIL | fail | Timed out waiting for realtime payload. |
