# Run GoalSight end-to-end (WSL + ngrok) — thesis demo

Flutter app → **ngrok** → **WSL FastAPI** → **AI model** → **Supabase** → app fetches.
Everything is already built. This is the run procedure.

## One-time prerequisites (already done on this PC)
- WSL Ubuntu with the model at `/mnt/e/Grad AI Model/Ai_football/football_ai`.
- Python env at `~/gsvenv` (torch + ultralytics + service deps).
- Get your Supabase **service_role** key: Supabase dashboard → Project Settings →
  API → `service_role` secret. (Server-only — never put it in the app.)
- Install ngrok in WSL: `curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list && sudo apt update && sudo apt install ngrok`
  then `ngrok config add-authtoken <token from ngrok.com>`.

## Each run
**1. Start ngrok** (WSL terminal A):
```bash
ngrok http 8000
```
Copy the `https://xxxx.ngrok-free.app` URL it prints.

**2. Start the analysis service** (WSL terminal B):
```bash
cd "/mnt/c/Users/ahmed/OneDrive/Documents/Grad_Project_GOAL_SIGHT/app/goal_sight/analysis_service"
export GOALSIGHT_MODEL_DIR="/mnt/e/Grad AI Model/Ai_football/football_ai"
export GOALSIGHT_DEVICE=cpu
export SUPABASE_URL="https://<your-project-ref>.supabase.co"
export SUPABASE_SERVICE_KEY="<service_role key>"
export GOALSIGHT_PUBLIC_BASE_URL="https://xxxx.ngrok-free.app"   # the ngrok URL
~/gsvenv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```
Check it's alive: open `https://xxxx.ngrok-free.app/health` in a browser → `{"status":"ok",...}`.

**3. Point the app at it:** edit `app/goal_sight/.env`, set:
```
ANALYSIS_API_URL=https://xxxx.ngrok-free.app
```
Rebuild/run the app (`run-flutter.bat` or `flutter run`).

**4. Use it:** log in as a **manager** (with a club) → **Upload** tab → pick a
video → fill match details → **Confirm** → wait for detection → the
**Player Naming** screen appears → pick which team is your club, name players →
**Confirm Players & Analyze** → wait → the analyzed match appears in Matches /
Player profiles (read live from Supabase).

## ⚠️ Speed reality
This PC runs the model on **CPU (~4 s/frame)** — a full match clip takes
**hours**. For a live demo:
- Use a **short clip** (a few seconds), or
- Pre-run one analysis and demo the already-stored result, or
- Run on a real GPU host (AWS) for full-speed clips.

The integration is identical regardless of speed — only the wait differs.

## Troubleshooting
- App says "No analysis server configured" → `ANALYSIS_API_URL` not set / app not rebuilt.
- Naming screen images blank → set `GOALSIGHT_PUBLIC_BASE_URL` to the ngrok URL (so crop URLs are absolute).
- Success screen empty → `SUPABASE_SERVICE_KEY` not set, so the sink didn't write; check the uvicorn log for `[sink]`/`[jobs]` errors.
- "No club assigned" → the manager's profile has no `club_id`; an admin must add them to a club.
