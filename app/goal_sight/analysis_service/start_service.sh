#!/usr/bin/env bash
# GoalSight — one command to (1) auto-sync the ngrok URL into both .env files
# and (2) start the analysis service. Run from WSL:
#
#     bash start_service.sh
#
# Prerequisite: your ngrok tunnel is already running (ngrok http 8000) in
# another terminal. If it isn't, the sync step warns and the service still
# starts (crop/video links just won't be absolute).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_PY="$HOME/gsvenv/bin/python"
[ -x "$VENV_PY" ] || VENV_PY="python3"

echo "[1/2] Syncing ngrok URL into the .env files ..."
"$VENV_PY" "$SCRIPT_DIR/_sync_env.py" || true

# Free port 8000 if a previous service instance is still holding it.
if command -v fuser >/dev/null && fuser 8000/tcp >/dev/null 2>&1; then
  echo "      port 8000 busy — stopping the old instance ..."
  fuser -k 8000/tcp >/dev/null 2>&1 || true
  sleep 1
fi

echo "[2/2] Starting the analysis service (uvicorn on :8000) ..."
echo "      Watch for: [startup] Supabase persistence ENABLED."
cd "$SCRIPT_DIR"
exec "$VENV_PY" -m uvicorn app.main:app --host 0.0.0.0 --port 8000
