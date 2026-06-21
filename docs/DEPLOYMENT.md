# Deployment Instructions

GoalSight has three deployable units:

1. **Analysis service + AI model** — runs on a GPU host (or CPU fallback).
2. **Supabase** — managed cloud (PostgreSQL + Auth + Storage).
3. **Flutter app** — built as an Android APK / iOS build and pointed at the
   service + Supabase.

For local bring-up see [SETUP.md](SETUP.md). This document covers shipping it.

---

## Option A — Demo setup (WSL + ngrok)

The fastest way to demo end-to-end from a single laptop. The model + service run
locally; **ngrok** exposes the service over public HTTPS so a phone/emulator can
reach it.

```bash
# Terminal A — public HTTPS tunnel
ngrok http 8000                        # copy the https forwarding URL

# Terminal B — the service (inside the football_ai venv)
cd app/goal_sight/analysis_service
export GOALSIGHT_MODEL_DIR="/path/to/football_ai"
export GOALSIGHT_DEVICE=cpu                          # or cuda:0 on a GPU host
export SUPABASE_URL="https://<project-ref>.supabase.co"
export SUPABASE_SERVICE_KEY="<service_role key>"     # server-only secret
export GOALSIGHT_PUBLIC_BASE_URL="https://<ngrok>.ngrok-free.app"
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Then set the app's `ANALYSIS_API_URL` (in `app/goal_sight/.env`) to the ngrok
HTTPS URL and run the app.

Verify: open `https://<ngrok>.ngrok-free.app/health` → it should return
`{"status":"ok","supabase":true,...}`.

> Prefer putting the Supabase keys in `analysis_service/.env` (auto-loaded) so
> they survive uvicorn/WSL restarts rather than re-`export`-ing each time. There
> is a step-by-step WSL+ngrok runbook at
> [`app/goal_sight/analysis_service/RUN_WSL_NGROK.md`](../app/goal_sight/analysis_service/RUN_WSL_NGROK.md).

---

## Option B — Production (AWS EC2 GPU + Docker)

1. **Launch a GPU instance.** A `g4dn.xlarge` (NVIDIA T4) with a recent Deep
   Learning AMI works well — it ships with the NVIDIA driver and
   `nvidia-container-toolkit`.

2. **Copy the model.** Put the `football_ai` project (code **and** `weights/`)
   on the host, e.g. `/home/ubuntu/football_ai`. The weights stay in the mounted
   volume, **not** in the image.

3. **Build and run the service image:**

   ```bash
   docker build -t goalsight-analysis ./app/goal_sight/analysis_service
   docker run --gpus all -p 8000:8000 \
     -v /home/ubuntu/football_ai:/opt/football_ai \
     -e GOALSIGHT_DEVICE=cuda:0 \
     -e GOALSIGHT_PUBLIC_BASE_URL=https://<your-domain-or-ip> \
     -e SUPABASE_URL=... \
     -e SUPABASE_SERVICE_KEY=... \
     goalsight-analysis
   ```

   The container mounts the model at `/opt/football_ai`, which is the default
   `GOALSIGHT_MODEL_DIR`.

4. **Put it behind HTTPS.** Terminate TLS with nginx or an AWS ALB and point the
   app's `ANALYSIS_API_URL` at the public HTTPS endpoint.

### Operational notes

- **Concurrency:** one GPU run at a time (internal lock + single worker).
- **Job state is in-memory:** a restart drops in-flight jobs; the app re-uploads
  on failure. Completed analyses persisted to Supabase are unaffected.
- **Persistence gate:** the service only writes to Supabase when `SUPABASE_URL`
  and `SUPABASE_SERVICE_KEY` are present; otherwise it logs a loud warning and
  skips persistence (the app can still render from raw output).

---

## Supabase (database + storage)

1. Create a Supabase project.
2. Apply the migrations in [`supabase/migrations/`](../supabase/migrations/)
   (Supabase CLI `supabase db push`, or paste into the dashboard SQL editor).
3. Create the storage buckets: `match-videos`, `heatmaps`, `reports`.
4. Confirm Row-Level Security policies are enabled (multi-tenant isolation by
   `owner_club_id`). See [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md).
5. Collect the project URL, anon key, and service-role key for the app/service
   configuration.

---

## Flutter app (release build)

### Configure

`app/goal_sight/.env` must point at the deployed service and Supabase:

```dotenv
ANALYSIS_API_URL=https://<service-domain>
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon key>
```

### Android APK / App Bundle

```bash
cd app/goal_sight
flutter pub get
flutter build apk --release            # → build/app/outputs/flutter-apk/app-release.apk
# or, for the Play Store:
flutter build appbundle --release      # → build/app/outputs/bundle/release/app-release.aab
```

> Building the APK requires Gradle to download Flutter engine artifacts from
> Google's Maven repos; ensure network access to `dl.google.com`. All Dart-level
> errors are caught earlier by `flutter analyze`.

### iOS

```bash
cd app/goal_sight
flutter build ios --release            # requires macOS + Xcode + signing
```

Distribute the APK directly for the defense/demo, or publish via the Play Store /
App Store as needed.

---

## Post-deployment checklist

- [ ] `GET /health` returns `"status":"ok"` and `"supabase":true`.
- [ ] A short test clip completes the full upload → naming → analysis flow.
- [ ] The annotated video and heatmaps load in the app.
- [ ] The completed match appears in history/squad (confirms persistence).
- [ ] The app's `ANALYSIS_API_URL` points at the HTTPS endpoint, not localhost.
- [ ] The service-role key is **only** on the server, never in the app bundle.
