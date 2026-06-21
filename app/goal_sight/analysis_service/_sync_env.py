"""Fetch the running ngrok HTTPS URL and write it into BOTH .env files.

Run automatically by ``start_service.sh`` before launching the service, so you
never hand-copy the ngrok URL again. It updates:

  * analysis_service/.env  -> GOALSIGHT_PUBLIC_BASE_URL   (absolute crop/video URLs)
  * app/goal_sight/.env    -> ANALYSIS_API_URL            (the URL the app calls)

No-op (with a clear warning) if ngrok isn't running yet. Uses only the stdlib.
"""

from __future__ import annotations

import json
import re
import sys
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent          # …/analysis_service
SERVICE_ENV = HERE / ".env"
APP_ENV = HERE.parent / ".env"                  # …/app/goal_sight/.env
NGROK_API = "http://localhost:4040/api/tunnels"


def ngrok_https_url() -> str | None:
    """Return the first https public URL ngrok is forwarding, or None."""
    try:
        with urllib.request.urlopen(NGROK_API, timeout=2) as resp:
            data = json.load(resp)
    except Exception:
        return None
    for tunnel in data.get("tunnels", []):
        url = tunnel.get("public_url", "")
        if url.startswith("https"):
            return url
    return None


def set_env(path: Path, key: str, value: str) -> None:
    """Replace ``KEY=…`` in ``path`` (or append it). CRLF/quote tolerant."""
    lines = path.read_text(encoding="utf-8").splitlines() if path.exists() else []
    out, found = [], False
    for line in lines:
        if re.match(rf"\s*{re.escape(key)}\s*=", line):
            out.append(f"{key}={value}")
            found = True
        else:
            out.append(line)
    if not found:
        out.append(f"{key}={value}")
    path.write_text("\n".join(out) + "\n", encoding="utf-8")


def main() -> int:
    url = ngrok_https_url()
    if not url:
        print("[sync] No ngrok tunnel found on :4040.")
        print("[sync] Start ngrok (e.g. `ngrok http 8000`) in another terminal, then re-run.")
        print("[sync] Continuing WITHOUT a public URL — crop/video links will be relative.")
        return 0
    set_env(SERVICE_ENV, "GOALSIGHT_PUBLIC_BASE_URL", url)
    set_env(APP_ENV, "ANALYSIS_API_URL", url)
    print(f"[sync] ngrok URL: {url}")
    print(f"[sync]   → GOALSIGHT_PUBLIC_BASE_URL written to {SERVICE_ENV}")
    print(f"[sync]   → ANALYSIS_API_URL written to {APP_ENV}")
    print("[sync] Remember to (re)start the Flutter app so it re-reads its .env.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
