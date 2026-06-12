# Phase 15 Runtime Summary

## Verdict
FAILED

## Coverage
- PASS: 27
- PARTIAL: 0
- MISSING: 0

## Notes
- S1 debug: team_ok=false tried=phase15-team-logo-placeholder.txt,phase15/phase15-team-logo-placeholder.txt,phase15; player_ok=false tried=phase15-player-image-placeholder.txt,phase15/phase15-player-image-placeholder.txt,phase15
- Admin read 10 tables successfully.
- Admin insert, update, and delete succeeded.
- Admin read 12 notification rows.
- Admin read 101 activity rows.
- Manager-owned upload job created: 9f2f6968-7127-48e3-bd0c-7f1dab4df6e9
- Manager read own upload job 9f2f6968-7127-48e3-bd0c-7f1dab4df6e9.
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
- Fan inserted own activity 6a0f3f13-cf7e-40d9-ace7-34679c958ac5.
- Public bucket reads failed: team_ok=false tried=phase15-team-logo-placeholder.txt,phase15/phase15-team-logo-placeholder.txt,phase15; player_ok=false tried=phase15-player-image-placeholder.txt,phase15/phase15-player-image-placeholder.txt,phase15
- Manager uploaded phase15/match-videos/manager-upload-37c5f7f9-e18a-4ccf-ac61-482d19ad72a9.mp4.
- Manager downloaded match video.
- Player downloaded match video.
- Fan was denied match video download.
- Upload to match-videos/phase15-match-video-denied-779b187a-32e3-4885-9635-3c579f823373.txt denied as expected: 400 new row violates row-level security policy
- Timed out waiting for realtime payload.
- Timed out waiting for realtime payload.
- Timed out waiting for realtime payload.
- Timed out waiting for realtime payload.
- Timed out waiting for realtime payload.
- Timed out waiting for realtime payload.
