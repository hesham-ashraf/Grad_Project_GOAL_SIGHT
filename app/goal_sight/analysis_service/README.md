# GoalSight Analysis Service

Stateful FastAPI service that wraps the **football_ai** computer-vision model and
exposes the upload → detect → **name players** → full-analysis flow to the
GoalSight mobile app.

It **does not modify the model**. It imports the model's own `main.py`
orchestration functions (`run_role_refinement`, `run_possession`,
`run_minimap`, …) plus `RoleCorrectionRunner`/`CorrectionStore` and drives them
in two stages — supplying player names from the app via the model's standard
**corrections JSON** instead of the desktop Tkinter review UI.

## Flow

```
POST /jobs ───────────────▶ Stage 1 (background, GPU)
  multipart: video + meta     DetectionPipeline → stitching → swap-correction
                              → role refinement → build_review_dataset
  ◀── { job_id, status }      status becomes "awaiting_naming"

GET /jobs/{id}                poll status/progress
GET /jobs/{id}/naming         detected players (track_id, role, team_id, crop_url)
                              + team legend (which colour is team 0 vs 1)

POST /jobs/{id}/players ──▶  Stage 2 (background, GPU)
  { mappings:[{track_id,         write corrections JSON → run_apply
     player_name,player_id?}],  → run_possession → run_minimap
    my_team_id: 0|1 }           (analytics, heatmaps, tactical, report, video)
  ◀── 202 { status }            status becomes "completed"

GET /jobs/{id}/result         normalized result + ALL raw model JSONs (Phase 7)
GET /jobs/{id}/files/video     analyzed match video (<stem>_final_with_minimap.mp4)
GET /jobs/{id}/files/heatmap_* team0/team1/best-player heatmap PNGs
GET /jobs/{id}/crops/{name}    jersey-crop images for the naming screen
GET /health
```

`my_team_id` records which detected team (0/1) is the manager's club — used app-
side to map team 0/1 → home/away. The model's `team_id` labels are left untouched.

## Run locally (dev, against your GPU)

```bash
cd app/goal_sight/analysis_service
python -m venv .venv && . .venv/Scripts/activate     # Windows: .venv\Scripts\activate
pip install -r requirements.txt
# The model's own deps must also be importable. Easiest: run inside the
# football_ai venv (which already has torch/ultralytics/opencv) and just add
# the service deps there.

export GOALSIGHT_MODEL_DIR="E:/Grad AI Model/Ai_football/football_ai"
export GOALSIGHT_DEVICE=cuda:0
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Smoke test:
```bash
curl -F "video=@/path/to/clip.mp4" -F home_team=AlAhly -F away_team=Zamalek \
     http://localhost:8000/jobs
# poll GET /jobs/<id> until "awaiting_naming", then GET /jobs/<id>/naming
```

## Deploy on AWS EC2 GPU (Docker)

1. Launch a `g4dn.xlarge` (NVIDIA T4) with a recent Deep Learning AMI (has the
   NVIDIA driver + `nvidia-container-toolkit`).
2. Copy the `football_ai` model (code **and** `weights/`) onto the host, e.g.
   `/home/ubuntu/football_ai`.
3. Build and run:
   ```bash
   docker build -t goalsight-analysis ./analysis_service
   docker run --gpus all -p 8000:8000 \
     -v /home/ubuntu/football_ai:/opt/football_ai \
     -e GOALSIGHT_DEVICE=cuda:0 \
     -e GOALSIGHT_PUBLIC_BASE_URL=https://<your-domain-or-ip> \
     -e SUPABASE_URL=... -e SUPABASE_SERVICE_KEY=... \
     goalsight-analysis
   ```
4. Put it behind HTTPS (nginx/ALB) and point the app's `ANALYSIS_API_URL` at it.

The model weights live in the mounted volume, not the image.

## Notes / current status

- **Built and ready for verification** — not yet executed end-to-end against the
  model (that runs on the GPU host). See the repo integration plan for the test
  checklist.
- **Concurrency:** one GPU run at a time (internal lock + single worker). Jobs
  are in-memory; a restart drops in-flight jobs (app re-uploads on failure).
- **Next increment (after the Supabase schema lands):** a `supabase_sink` that
  uploads the analyzed video + heatmaps to Storage and writes the adapted DB
  rows, so the app fetches from Supabase. Until then the app can read results
  directly from this service's `/result` + `/files/*` endpoints.
- **Raw outputs (Phase 7):** every model JSON is returned verbatim under
  `result.raw`; nothing is dropped or renamed.
```
