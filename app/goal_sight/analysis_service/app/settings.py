"""Runtime configuration for the analysis service.

All values come from environment variables so the same image runs on the dev
PC, the AWS GPU instance, or a CPU fallback. Defaults assume the Docker layout
described in the Dockerfile (model copied to /opt/football_ai).
"""

from __future__ import annotations

import os
from pathlib import Path


def _env(name: str, default: str = "") -> str:
    return os.environ.get(name, default).strip()


# ── Model location ──────────────────────────────────────────────────────────
# Absolute path to the football_ai project root (the dir that contains main.py,
# config/, weights/, outputs/). The service inserts this on sys.path and runs
# with it as the working directory (the model uses paths relative to its root).
MODEL_DIR = Path(_env("GOALSIGHT_MODEL_DIR", "/opt/football_ai")).resolve()

# Model config file (relative to MODEL_DIR unless absolute).
MODEL_CONFIG = _env("GOALSIGHT_MODEL_CONFIG", "config/config.yaml")

# Inference device passed to the model: "auto" | "cpu" | "cuda:0" ...
DEVICE = _env("GOALSIGHT_DEVICE", "cuda:0")

# Optional override of the model's YOLO inference image size (imgsz). On small
# GPUs (e.g. a 4 GB RTX 3050) the default 1280 can OOM; 960/736 fit and run
# faster with minimal accuracy loss. 0 = keep the config.yaml value.
IMAGE_SIZE = int(_env("GOALSIGHT_IMAGE_SIZE", "0") or "0")

# Where uploaded videos are copied before processing. Each job uses its job id
# as the file stem so all model outputs (outputs/<job_id>_*.json) are isolated.
UPLOADS_DIR = MODEL_DIR / "uploads"

# The model's output directory (config.video.output_dir is "outputs").
OUTPUTS_DIR = MODEL_DIR / "outputs"

# Cap a single processing run (seconds). A long clip on CPU can be very slow.
JOB_TIMEOUT_SECONDS = int(_env("GOALSIGHT_JOB_TIMEOUT", "3600"))

# ── Supabase (used by the persistence step, added after the DB schema lands) ──
SUPABASE_URL = _env("SUPABASE_URL")
SUPABASE_SERVICE_KEY = _env("SUPABASE_SERVICE_KEY")  # service-role key (server only)

# Storage buckets the service uploads generated artifacts to.
BUCKET_VIDEOS = _env("GOALSIGHT_BUCKET_VIDEOS", "match-videos")
BUCKET_HEATMAPS = _env("GOALSIGHT_BUCKET_HEATMAPS", "heatmaps")
BUCKET_REPORTS = _env("GOALSIGHT_BUCKET_REPORTS", "reports")

# ── Server ────────────────────────────────────────────────────────────────--
HOST = _env("GOALSIGHT_HOST", "0.0.0.0")
PORT = int(_env("GOALSIGHT_PORT", "8000"))

# Public base URL the mobile app uses to fetch crop images served by this
# service (e.g. https://api.example.com). Empty → relative URLs.
PUBLIC_BASE_URL = _env("GOALSIGHT_PUBLIC_BASE_URL").rstrip("/")


def has_supabase() -> bool:
    return bool(SUPABASE_URL and SUPABASE_SERVICE_KEY)
