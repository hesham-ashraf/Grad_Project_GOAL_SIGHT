"""
GoalSight — Player Profile PDF microservice (FastAPI).

Endpoints:
  GET  /health          → liveness probe
  POST /player-report   → body = player profile JSON (see pdf_generator),
                          returns application/pdf bytes.

Run:
  pip install -r requirements.txt
  uvicorn main:app --host 0.0.0.0 --port 8000

The Flutter manager app POSTs the PlayerProfileModel snapshot it already holds
(plus the player's match heatmaps) and shares/prints the returned PDF. The
service is stateless — no database access — so it is trivial to test and deploy.
"""

from __future__ import annotations

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from pdf_generator import build_player_pdf

app = FastAPI(title="GoalSight PDF Service", version="1.0.0")

# Allow the Flutter web build (served from localhost:<random-port>) to POST
# cross-origin. Harmless for the Android emulator, required for web/desktop.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "service": "goalsight-pdf"}


@app.post("/player-report")
async def player_report(request: Request) -> Response:
    try:
        data = await request.json()
    except Exception:
        return JSONResponse(
            status_code=400, content={"error": "Invalid or missing JSON body."}
        )
    if not isinstance(data, dict):
        return JSONResponse(
            status_code=400, content={"error": "Body must be a JSON object."}
        )

    try:
        pdf_bytes = build_player_pdf(data)
    except Exception as exc:  # pragma: no cover - defensive
        return JSONResponse(
            status_code=500, content={"error": f"PDF generation failed: {exc}"}
        )

    safe_name = (
        "".join(c for c in str(data.get("name", "player")) if c.isalnum() or c in " -_")
        .strip()
        .replace(" ", "_")
        or "player"
    )
    filename = f"{safe_name}_report.pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
