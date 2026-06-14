# Phase 15 Coverage Matrix

| Test | Status | Executed | Notes |
| --- | --- | --- | --- |
| A1 Admin can read all target tables | PASS | pass | Admin read 10 tables successfully. |
| A2 Admin can manage upload jobs | PASS | pass | Admin insert, update, and delete succeeded. |
| A3 Admin notification access | PASS | pass | Admin read 12 notification rows. |
| A4 Admin activity log access | PASS | pass | Admin read 150 activity rows. |
| M1 Manager can create own upload job | PASS | pass | Manager-owned upload job created: 3da50e2d-34f8-42b8-b57b-aed73023c542 |
| M2 Manager can read own upload job | PASS | pass | Manager read own upload job 3da50e2d-34f8-42b8-b57b-aed73023c542. |
| M3 Manager can update own upload job | PASS | pass | Manager own upload job updated to 35%. |
| M4 Manager cannot create upload job for another user | PASS | pass | Insert into upload_jobs denied as expected: 403 new row violates row-level security policy for table "upload_jobs" |
| M5 Manager cannot update another user's upload job | PASS | pass | Update on upload_jobs returned an empty success response. |
| P1 Player can read own profile | PASS | pass | Player profile read succeeded. |
| P2 Player cannot read another user's profile | PASS | pass | Player could not read manager profile. |
| P3 Player mapping is correct | PASS | pass | Ahmed Striker mapped to 05cc12a7-ffc8-4532-885e-daa345c1954d. |
| P4 Player can read own linked stats | PASS | pass | Player linked stats are visible. |
| P5 Player cannot read another player's stats | PASS | pass | Other player stats stayed hidden. |
| P6 Player cannot read upload jobs | PASS | pass | Upload jobs denied to player. |
| F1 Fan can read own profile | PASS | pass | Fan profile read succeeded. |
| F2 Fan cannot read other profiles | PASS | pass | Manager profile hidden from fan. |
| F3 Fan can read public football data | PASS | pass | Fan read teams, players, matches, and match events. |
| F4 Fan cannot read player stats | PASS | pass | Fan player stats request remained empty or denied. |
| F5 Fan cannot read videos | PASS | pass | Fan videos request remained empty or denied. |
| F6 Fan cannot read upload jobs | PASS | pass | Fan upload_jobs request remained empty or denied. |
| F7 Fan notification ownership | PASS | pass | Fan saw own notification and not manager notification. |
| F8 Fan activity ownership | PASS | pass | Insert into activity_logs denied as expected: 403 new row violates row-level security policy for table "activity_logs"; Fan inserted own activity f7540085-96e5-468e-951f-181a4ff5d889. |
| S1 Public buckets are readable | PASS | pass | Anonymous read succeeded for team-logos and player-images. |
| S2 Manager can upload match video | PASS | pass | Manager uploaded phase15/match-videos/manager-upload-935dbb08-158a-4f2f-a81b-b39fd9391c4d.mp4. |
| S3 Manager can read match video | PASS | pass | Manager downloaded match video. |
| S4 Player can read match video | PASS | pass | Player downloaded match video. |
| S5 Fan cannot read match video | PASS | pass | Fan was denied match video download. |
| S6 Fan cannot upload match video | PASS | pass | Upload to match-videos/phase15-match-video-denied-3ebb47d7-9ea1-40ea-8cac-b74b4034cf3a.txt denied as expected: 400 new row violates row-level security policy |
| R1 Manager receives own upload job updates | PASS | pass | Manager realtime update received for own upload job. |
| R2 Manager does not receive other user's upload job updates | PASS | pass | Manager did not receive another user's upload job update. |
| R3 Player receives own stats updates only | PASS | pass | Player realtime update received for own stats. |
| R4 Player does not receive another player's stats | PASS | pass | Player did not receive another player's stats payload. |
| R5 User receives own notification updates only | PASS | pass | Fan received own notification update only. |
| R6 Admin receives activity feed updates | PASS | pass | Admin received 3 activity feed payloads. |
