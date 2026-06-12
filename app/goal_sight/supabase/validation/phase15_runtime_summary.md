# Phase 15 Runtime Summary

## Verdict
FAILED

## Coverage
- PASS: 27
- PARTIAL: 0
- MISSING: 0

## Notes
- Admin read 10 tables successfully.
- Admin insert, update, and delete succeeded.
- Admin read 8 notification rows.
- Admin read 41 activity rows.
- Manager-owned upload job created: 1ae6c2a6-aabb-4382-b7d0-ae2f1318c4c2
- Manager read own upload job 1ae6c2a6-aabb-4382-b7d0-ae2f1318c4c2.
- Manager own upload job updated to 35%.
- Insert into upload_jobs denied as expected: 403 new row violates row-level security policy for table "upload_jobs"
- Update on upload_jobs returned an empty success response.
- Player profile read succeeded.
- Player could not read manager profile.
- Ahmed Striker mapped to 05cc12a7-ffc8-4532-885e-daa345c1954d.
- Player could not read own linked stats.
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
- Fan inserted own activity 50928643-36a0-4f59-944c-cbc96640ae5a.
- No existing public objects were found in team-logos or player-images.
- Manager uploaded phase15/match-videos/manager-upload-337bc1c8-47f5-4f80-8645-aa446fe954cd.mp4.
- Manager downloaded match video.
- Player downloaded match video.
- Fan was denied match video download.
- Upload to match-videos/phase15-match-video-denied-1bde1c90-5297-4ffa-b997-7ab2aa671885.txt denied as expected: 400 new row violates row-level security policy
- Timed out waiting for realtime payload.
- Timed out waiting for realtime payload.
- Timed out waiting for realtime payload.
- Timed out waiting for realtime payload.
- Timed out waiting for realtime payload.
- Timed out waiting for realtime payload.
