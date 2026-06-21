# Setup Instructions & Environment Requirements

This guide brings up the three GoalSight tiers locally: the **AI model
(`football_ai`)**, the **analysis service (FastAPI)**, and the **Flutter app**.
For deploying to a server, see [DEPLOYMENT.md](DEPLOYMENT.md).

---

## 1. Environment requirements

### Tooling

| Tool | Version | Used by |
|---|---|---|
| **Flutter SDK** | 3.x (Dart `>=3.4.3 <4.0.0`) | Flutter app |
| **Android Studio / Xcode** | latest | Android emulator / iOS simulator + device builds |
| **Python** | 3.10+ | AI model + analysis service |
| **pip / venv** | bundled with Python | Python dependency management |
| **Git** | 2.x | source control |
| **ngrok** *(demo only)* | latest | exposes the local service over HTTPS |
| **Docker** *(deploy only)* | latest | containerised service image |

### Hardware

| Resource | Minimum | Recommended |
|---|---|---|
| RAM | 8 GB | 16 GB+ |
| GPU | none (CPU works, but ~4 s/frame) | NVIDIA GPU with CUDA (e.g. T4 / RTX 3050+) |
| Disk | ~10 GB free | 20 GB+ (model weights, outputs, videos) |

> **Speed reality:** CPU inference is hours-per-match. For development and demos
> use a **short clip** (a few seconds) or a GPU host.

### Cloud accounts

- A **Supabase** project (free tier is sufficient for development). You will need:
  - `SUPABASE_URL` — `https://<project-ref>.supabase.co`
  - **anon key** — public, used by the Flutter app
  - **service-role key** — secret, used **only** by the analysis service

---

## 2. Clone the repository

```bash
git clone <repository-url>
cd Grad_Project_GOAL_SIGHT
```

The trained YOLO weights (`weights/best.pt`) and large media artifacts (`*.mp4`,
`*.pt`, `*.pkl`) are **git-ignored** — obtain the weights file separately and
place it under the model's `weights/` directory.

---

## 3. AI model (`football_ai`) — Tier 3a

```bash
cd football_ai
python -m venv .venv
source .venv/bin/activate          # Windows: .\.venv\Scripts\activate
pip install -r requirements.txt

# place the trained detection weights:
#   football_ai/weights/best.pt

# run the full pipeline on a clip:
python main.py --video input_video.mp4 --all --device auto
# → outputs/<stem>_final_with_minimap.mp4  (+ all JSON / PNG artifacts)
```

Key flags: `--all` enables the full pipeline; `--device auto|cpu|cuda:0`;
`--reuse-tracks` re-uses prior tracks so human labels stay valid across re-runs.
All tunable parameters live in `config/config.yaml`.

The pipeline runs **10 phases** (detection → tracking → stitching → swap
correction → role/team refinement → manual review → calibration → speed/distance
→ possession → heatmaps → tactical → AI report). Each phase reads the previous
artifact and writes its own, so every stage is independently inspectable.

---

## 4. Analysis service (FastAPI) — Tier 2

The service imports the model's own `main.py` functions, so the model's
dependencies (torch / ultralytics / opencv) must be importable. The simplest
setup is to install the service deps **into the same virtualenv** as the model.

```bash
cd app/goal_sight/analysis_service
pip install -r requirements.txt        # ideally into the football_ai venv
```

### Configure `analysis_service/.env`

The service auto-loads `analysis_service/.env` at startup (real environment
variables always win). This is the recommended way to keep the Supabase keys
across restarts — the #1 cause of analyses silently not being saved.

```dotenv
# Model location (absolute path to the football_ai project root)
GOALSIGHT_MODEL_DIR=/path/to/football_ai
GOALSIGHT_MODEL_CONFIG=config/config.yaml

# Inference device
GOALSIGHT_DEVICE=cuda:0          # or cpu
GOALSIGHT_IMAGE_SIZE=0           # 0 = use config.yaml (960/736 fit small GPUs)

# Persistence (without BOTH of these, analyses are NOT saved)
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_SERVICE_KEY=<service_role key>     # server-only secret

# Storage buckets
GOALSIGHT_BUCKET_VIDEOS=match-videos
GOALSIGHT_BUCKET_HEATMAPS=heatmaps
GOALSIGHT_BUCKET_REPORTS=reports

# Public base URL so the app can fetch crops/video by absolute URL
GOALSIGHT_PUBLIC_BASE_URL=https://<your-public-url>

# Server
GOALSIGHT_HOST=0.0.0.0
GOALSIGHT_PORT=8000
GOALSIGHT_JOB_TIMEOUT=3600
```

### Run

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### Verify

Open `http://localhost:8000/health`. A healthy response:

```json
{ "status": "ok", "service": "goalsight-analysis",
  "model_present": true, "device": "cuda:0", "supabase": true }
```

If `"supabase"` is `false`, persistence is off — set `SUPABASE_URL` and
`SUPABASE_SERVICE_KEY` and restart.

---

## 5. Environment variables reference

| Variable | Where | Required | Purpose |
|---|---|---|---|
| `GOALSIGHT_MODEL_DIR` | service | ✅ | absolute path to the `football_ai` project root |
| `GOALSIGHT_MODEL_CONFIG` | service | – | model config file (default `config/config.yaml`) |
| `GOALSIGHT_DEVICE` | service | – | `cpu` / `cuda:0` (default `cuda:0`) |
| `GOALSIGHT_IMAGE_SIZE` | service | – | override YOLO image size; `0` = config default |
| `SUPABASE_URL` | service + app | ✅ for persistence | Supabase project URL |
| `SUPABASE_SERVICE_KEY` | service | ✅ for persistence | service-role key (**server only**, never in the app) |
| `SUPABASE_ANON_KEY` | app | ✅ | public anon key for the Flutter client |
| `GOALSIGHT_BUCKET_VIDEOS` | service | – | storage bucket for annotated videos |
| `GOALSIGHT_BUCKET_HEATMAPS` | service | – | storage bucket for heatmap PNGs |
| `GOALSIGHT_BUCKET_REPORTS` | service | – | storage bucket for reports |
| `GOALSIGHT_PUBLIC_BASE_URL` | service | – (✅ for remote app) | absolute base URL for served crops/video |
| `GOALSIGHT_HOST` / `GOALSIGHT_PORT` | service | – | bind host/port (default `0.0.0.0:8000`) |
| `GOALSIGHT_JOB_TIMEOUT` | service | – | per-job cap in seconds (default `3600`) |
| `ANALYSIS_API_URL` | app `.env` | ✅ | the analysis-service URL the app calls |

---

## 6. Flutter app — Tier 1

```bash
cd app/goal_sight
flutter pub get
```

### Configure `app/goal_sight/.env`

```dotenv
ANALYSIS_API_URL=https://<service-url>     # the FastAPI service (ngrok / AWS)
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon key>
```

### Run

```bash
flutter devices                 # list emulators / connected devices
flutter run -d emulator-5554    # or your device id
```

### Useful commands

```bash
flutter analyze        # static analysis (kept clean)
flutter test           # widget / unit tests
flutter build apk      # release Android build (see DEPLOYMENT.md)
```

---

## 7. Database setup (Supabase)

The schema is defined under [`supabase/migrations/`](../supabase/migrations/).
Apply migrations to your Supabase project (via the Supabase CLI or dashboard SQL
editor) before running the service against it. Create the three storage buckets
(`match-videos`, `heatmaps`, `reports`). See
[DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) for the full table inventory and
multi-tenancy (RLS) model.

---

## 8. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `/health` shows `"supabase": false` | keys not set | put `SUPABASE_URL` + `SUPABASE_SERVICE_KEY` in `analysis_service/.env`, restart |
| Analysis runs but match never appears in history | persistence skipped | same as above — verify `/health` |
| Service can't import the model | model deps not in the venv | install service deps into the `football_ai` venv, or set `GOALSIGHT_MODEL_DIR` correctly |
| CUDA out of memory | image size too large | set `GOALSIGHT_IMAGE_SIZE=960` (or `736`) |
| App can't reach the service | wrong URL / tunnel down | confirm `ANALYSIS_API_URL` and that `/health` is reachable from the device |
| Analysis takes hours | running on CPU | use a short clip or a GPU host (`GOALSIGHT_DEVICE=cuda:0`) |
