# Phase 15 Coverage Matrix

| Test | Status | Executed | Notes |
| --- | --- | --- | --- |
| A1 Admin can read all target tables | PASS | pass | Admin read 10 tables successfully. |
| A2 Admin can manage upload jobs | PASS | pass | Admin insert, update, and delete succeeded. |
| A3 Admin notification access | PASS | pass | Admin read 8 notification rows. |
| A4 Admin activity log access | PASS | pass | Admin read 41 activity rows. |
| M1 Manager can create own upload job | PASS | pass | Manager-owned upload job created: 1ae6c2a6-aabb-4382-b7d0-ae2f1318c4c2 |
| M2 Manager can read own upload job | PASS | pass | Manager read own upload job 1ae6c2a6-aabb-4382-b7d0-ae2f1318c4c2. |
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
| F8 Fan activity ownership | PASS | pass | Insert into activity_logs denied as expected: 403 new row violates row-level security policy for table "activity_logs"; Fan inserted own activity 50928643-36a0-4f59-944c-cbc96640ae5a. |
| S1 Public buckets are readable | FAIL | fail | No existing public objects were found in team-logos or player-images. |
| S2 Manager can upload match video | PASS | pass | Manager uploaded phase15/match-videos/manager-upload-337bc1c8-47f5-4f80-8645-aa446fe954cd.mp4. |
| S3 Manager can read match video | PASS | pass | Manager downloaded match video. |
| S4 Player can read match video | PASS | pass | Player downloaded match video. |
| S5 Fan cannot read match video | PASS | pass | Fan was denied match video download. |
| S6 Fan cannot upload match video | PASS | pass | Upload to match-videos/phase15-match-video-denied-1bde1c90-5297-4ffa-b997-7ab2aa671885.txt denied as expected: 400 new row violates row-level security policy |
| R1 Manager receives own upload job updates | FAIL | fail | Timed out waiting for realtime payload. |
| R2 Manager does not receive other user's upload job updates | FAIL | fail | Timed out waiting for realtime payload. |
| R3 Player receives own stats updates only | FAIL | fail | Timed out waiting for realtime payload. |
| R4 Player does not receive another player's stats | FAIL | fail | Timed out waiting for realtime payload. |
| R5 User receives own notification updates only | FAIL | fail | Timed out waiting for realtime payload. |
| R6 Admin receives activity feed updates | FAIL | fail | Timed out waiting for realtime payload. |
