#!/usr/bin/env bash
# GoalSight — ONE command to run everything from WSL:
#
#     bash run_all.sh
#
# It will: install ngrok (first run only) → authenticate it with the token in
# .env → start the tunnel → write the URL into both .env files → start the
# analysis service. Stop with Ctrl+C (ngrok is stopped too if we started it).
#
# Prereqs in analysis_service/.env: NGROK_AUTHTOKEN, SUPABASE_URL,
# SUPABASE_SERVICE_KEY (already set).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
VENV_PY="$HOME/gsvenv/bin/python"
[ -x "$VENV_PY" ] || VENV_PY="python3"
NGROK_API="http://localhost:4040/api/tunnels"
PORT=8000

read_env() {  # read_env KEY  → value from .env (quotes/space trimmed)
  grep -E "^$1=" "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2- \
    | sed "s/^[\"' ]*//; s/[\"' ]*$//"
}

# ── locate or install ngrok (no sudo: static binary into ~/bin) ──────────────
NGROK_BIN="$(command -v ngrok || true)"
[ -z "$NGROK_BIN" ] && [ -x "$HOME/bin/ngrok" ] && NGROK_BIN="$HOME/bin/ngrok"
if [ -z "$NGROK_BIN" ]; then
  echo "[ngrok] not found — downloading the static binary to ~/bin ..."
  mkdir -p "$HOME/bin"
  curl -sL "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz" -o /tmp/ngrok.tgz
  tar -xzf /tmp/ngrok.tgz -C "$HOME/bin"
  NGROK_BIN="$HOME/bin/ngrok"
  echo "[ngrok] installed → $NGROK_BIN"
fi

# ── authenticate (idempotent) ────────────────────────────────────────────────
TOKEN="$(read_env NGROK_AUTHTOKEN)"
if [ -z "$TOKEN" ] || [ "$TOKEN" = "PASTE_YOUR_NGROK_AUTHTOKEN_HERE" ]; then
  echo "[ngrok] ERROR: NGROK_AUTHTOKEN not set in $ENV_FILE."
  echo "        Get it from ngrok.com → dashboard → 'Your Authtoken', paste it there, re-run."
  exit 1
fi
"$NGROK_BIN" config add-authtoken "$TOKEN" >/dev/null 2>&1 || true

# ── start the tunnel (reuse one if already up) ───────────────────────────────
NGROK_STARTED=0
if curl -s --max-time 2 "$NGROK_API" | grep -q '"public_url":"https'; then
  echo "[ngrok] a tunnel is already running — reusing it."
else
  echo "[ngrok] starting tunnel on :$PORT ..."
  "$NGROK_BIN" http "$PORT" --log=stdout >/tmp/ngrok.log 2>&1 &
  NGROK_PID=$!
  NGROK_STARTED=1
fi

# ── wait for the public URL ──────────────────────────────────────────────────
echo "[ngrok] waiting for the public URL ..."
for _ in $(seq 1 30); do
  curl -s --max-time 2 "$NGROK_API" | grep -q '"public_url":"https' && break
  sleep 1
done
if ! curl -s --max-time 2 "$NGROK_API" | grep -q '"public_url":"https'; then
  echo "[ngrok] ERROR: tunnel did not come up. Last log lines:"; tail -8 /tmp/ngrok.log || true
  exit 1
fi

# ── write the URL into both .env files ───────────────────────────────────────
"$VENV_PY" "$SCRIPT_DIR/_sync_env.py" || true

# ── stop ngrok when the service exits (only if we started it) ────────────────
cleanup() { [ "$NGROK_STARTED" = "1" ] && kill "${NGROK_PID:-0}" 2>/dev/null || true; }
trap cleanup EXIT INT TERM

# ── free the port if a previous service instance is still holding it ─────────
if command -v fuser >/dev/null && fuser "$PORT/tcp" >/dev/null 2>&1; then
  echo "[service] port $PORT busy — stopping the old instance ..."
  fuser -k "$PORT/tcp" >/dev/null 2>&1 || true
  sleep 1
fi

# ── start the service (foreground) ───────────────────────────────────────────
echo "[service] starting uvicorn on :$PORT — watch for 'Supabase persistence ENABLED' ..."
cd "$SCRIPT_DIR"
"$VENV_PY" -m uvicorn app.main:app --host 0.0.0.0 --port "$PORT"
