# Phase 15 Runtime Summary

## Verdict
PASS

## Coverage
- PASS: 35
- PARTIAL: 0
- MISSING: 0

## Notes
- Admin read 10 tables successfully.
- Admin insert, update, and delete succeeded.
- Admin read 12 notification rows.
- Admin read 150 activity rows.
- Manager-owned upload job created: 3da50e2d-34f8-42b8-b57b-aed73023c542
- Manager read own upload job 3da50e2d-34f8-42b8-b57b-aed73023c542.
- Manager own upload job updated to 35%.
- Insert into upload_jobs denied as expected: 403 new row violates row-level security policy for table "upload_jobs"
- Update on upload_jobs returned an empty success response.
- Player profile read succeeded.
- Player could not read manager profile.
- Ahmed Striker mapped to 05cc12a7-ffc8-4532-885e-daa345c1954d.
- Player linked stats are visible.
- Other player stats stayed hidden.
- Upload jobs denied to player.
- Fan profile read succeeded.
- Manager profile hidden from fan.
- Fan read teams, players, matches, and match events.
- Fan player stats request remained empty or denied.
- Fan videos request remained empty or denied.
- Fan upload_jobs request remained empty or denied.
- Fan saw own notification and not manager notification.
- Insert into activity_logs denied as expected: 403 new row violates row-level security policy for table "activity_logs"
- Fan inserted own activity f7540085-96e5-468e-951f-181a4ff5d889.
- Anonymous read succeeded for team-logos and player-images.
- Manager uploaded phase15/match-videos/manager-upload-935dbb08-158a-4f2f-a81b-b39fd9391c4d.mp4.
- Manager downloaded match video.
- Player downloaded match video.
- Fan was denied match video download.
- Upload to match-videos/phase15-match-video-denied-3ebb47d7-9ea1-40ea-8cac-b74b4034cf3a.txt denied as expected: 400 new row violates row-level security policy
- Manager realtime update received for own upload job.
- Manager did not receive another user's upload job update.
- Player realtime update received for own stats.
- Player did not receive another player's stats payload.
- Fan received own notification update only.
- Admin received 3 activity feed payloads.
