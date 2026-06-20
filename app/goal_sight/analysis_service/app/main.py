"""GoalSight Analysis Service — FastAPI app.

Stateful, multi-step contract (matches the approved app flow):

    POST /jobs                      multipart video + match metadata → job_id
    GET  /jobs/{id}                 status + progress (poll)
    GET  /jobs/{id}/naming          detected players + team legend (Stage 1 done)
    POST /jobs/{id}/players         names + my_team_id → starts Stage 2
    GET  /jobs/{id}/result          normalized analysis + raw model JSONs
    GET  /jobs/{id}/crops/{name}    serve a jersey-crop image (naming UI)
    GET  /jobs/{id}/files/{kind}    serve analyzed video / heatmap / positions
    GET  /health
"""

from __future__ import annotations

from pathlib import Path
from typing import Optional

from fastapi import FastAPI, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse

from . import settings
from .jobs import store
from .schemas import (
    AnalysisResult,
    ConfirmPlayersRequest,
    DetectedPlayer,
    JobCreateResponse,
    JobStatus,
    JobStatusResponse,
    NamingData,
    TeamLegendEntry,
)

app = FastAPI(title="GoalSight Analysis Service", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_methods=["*"], allow_headers=["*"],
)


@app.on_event("startup")
def _warn_if_no_supabase() -> None:
    """Make a missing-persistence config obvious at boot — otherwise analyses
    silently fail to save and the app can't open them."""
    if settings.has_supabase():
        print("[startup] Supabase persistence ENABLED.")
    else:
        print("[startup] WARNING: SUPABASE_URL / SUPABASE_SERVICE_KEY not set — "
              "analyses will NOT be saved and the app cannot open them. "
              "Export both and restart.")


def _url(path: str) -> str:
    """Prefix a relative API path with the public base URL when configured."""
    return f"{settings.PUBLIC_BASE_URL}{path}" if settings.PUBLIC_BASE_URL else path


@app.get("/health")
def health() -> dict:
    return {
        "status": "ok",
        "service": "goalsight-analysis",
        "model_dir": str(settings.MODEL_DIR),
        "model_present": settings.MODEL_DIR.is_dir(),
        "device": settings.DEVICE,
        # So you can confirm persistence is configured from a browser.
        "supabase": settings.has_supabase(),
    }


@app.post("/jobs", response_model=JobCreateResponse)
async def create_job(
    video: UploadFile,
    home_team: str = Form(""),
    away_team: str = Form(""),
    competition: str = Form(""),
    venue: str = Form(""),
    match_date: str = Form(""),
    club_id: Optional[str] = Form(None),
    uploaded_by: Optional[str] = Form(None),
) -> JobCreateResponse:
    data = await video.read()
    if not data:
        raise HTTPException(status_code=400, detail="Empty video upload.")
    job = store.create(
        video_bytes=data,
        filename=video.filename or "match.mp4",
        meta={
            "home_team": home_team, "away_team": away_team,
            "competition": competition, "venue": venue,
            "match_date": match_date, "club_id": club_id,
            "uploaded_by": uploaded_by,
        },
    )
    return JobCreateResponse(job_id=job.id, status=job.status)


@app.get("/jobs/{job_id}", response_model=JobStatusResponse)
def job_status(job_id: str) -> JobStatusResponse:
    job = store.get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Unknown job id.")
    return JobStatusResponse(
        job_id=job.id, status=job.status,
        stage_label=job.stage_label, progress=job.progress, error=job.error,
    )


@app.get("/jobs/{job_id}/naming", response_model=NamingData)
def job_naming(job_id: str) -> NamingData:
    job = store.get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Unknown job id.")
    if job.status != JobStatus.awaiting_naming:
        raise HTTPException(
            status_code=409,
            detail=f"Job is '{job.status.value}', not awaiting naming yet.",
        )
    players = [
        DetectedPlayer(
            track_id=p["track_id"], auto_role=p["auto_role"],
            team_id=p.get("team_id"), track_length=p.get("track_length", 0),
            role_confidence=p.get("role_confidence", 0.0),
            crop_url=_crop_url(job_id, p.get("crop_path")),
            crop_urls=[
                u
                for u in (_crop_url(job_id, c) for c in p.get("crop_paths", []))
                if u
            ],
            suggested_name=p.get("suggested_name"),
        )
        for p in job.naming_players
    ]
    legend = [
        TeamLegendEntry(
            team_id=e["team_id"], label=e.get("label", ""),
            color_rgb=e.get("color_rgb", []),
            crop_urls=[_crop_url(job_id, c) for c in e.get("crop_paths", []) if c],
        )
        for e in job.team_legend
    ]
    return NamingData(job_id=job_id, players=players, team_legend=legend)


@app.delete("/jobs/{job_id}", status_code=200)
def cancel_job(job_id: str) -> dict:
    job = store.get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Unknown job id.")
    ok = store.cancel(job_id)
    if not ok:
        raise HTTPException(status_code=409, detail="Could not cancel job.")
    return {"job_id": job_id, "status": JobStatus.failed.value}


@app.post("/jobs/{job_id}/players", status_code=202)
def confirm_players(job_id: str, body: ConfirmPlayersRequest) -> dict:
    job = store.get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Unknown job id.")
    if job.status != JobStatus.awaiting_naming:
        raise HTTPException(
            status_code=409,
            detail=f"Job is '{job.status.value}'; cannot accept names now.",
        )
    if body.my_team_id not in (0, 1):
        raise HTTPException(status_code=400, detail="my_team_id must be 0 or 1.")
    ok = store.confirm_players(
        job_id,
        mappings=[m.model_dump() for m in body.mappings],
        my_team_id=body.my_team_id,
    )
    if not ok:
        raise HTTPException(status_code=409, detail="Could not start analysis.")
    return {"job_id": job_id, "status": JobStatus.analyzing.value}


@app.get("/jobs/{job_id}/result", response_model=AnalysisResult)
def job_result(job_id: str) -> AnalysisResult:
    job = store.get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Unknown job id.")
    if job.status != JobStatus.completed or job.result is None:
        raise HTTPException(
            status_code=409,
            detail=f"Job is '{job.status.value}', result not ready.",
        )
    files = job.result.get("files", {})
    heatmaps = {
        key: _url(f"/jobs/{job_id}/files/heatmap_{key}")
        for key in files.get("heatmap_paths", {})
    }
    video_url = (
        _url(f"/jobs/{job_id}/files/video")
        if files.get("analyzed_video_path") else None
    )
    return AnalysisResult(
        job_id=job_id,
        my_team_id=job.result.get("my_team_id", 0),
        analysis_id=job.result.get("analysis_id"),
        analyzed_video_url=video_url,
        heatmap_urls=heatmaps,
        raw=files.get("raw", {}),
        player_mapping=job.result.get("player_mapping", {}),
    )


# ── File serving ─────────────────────────────────────────────────────────--

@app.get("/jobs/{job_id}/crops/{name}")
def serve_crop(job_id: str, name: str):
    job = store.get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Unknown job id.")
    # Crops live under outputs/manual_review/<stem>/. Guard against traversal.
    safe = Path(name).name
    crop = settings.OUTPUTS_DIR / "manual_review" / job.stem / safe
    if not crop.is_file():
        raise HTTPException(status_code=404, detail="Crop not found.")
    return FileResponse(str(crop), media_type="image/jpeg")


@app.get("/jobs/{job_id}/files/{kind}")
def serve_file(job_id: str, kind: str):
    job = store.get(job_id)
    if job is None or job.result is None:
        raise HTTPException(status_code=404, detail="No result for job.")
    files = job.result.get("files", {})
    if kind == "video":
        path = files.get("analyzed_video_path")
        return _file_or_404(path, "video/mp4")
    if kind == "field_positions":
        return _file_or_404(files.get("field_positions_path"), "application/json")
    if kind.startswith("heatmap_"):
        key = kind[len("heatmap_"):]
        return _file_or_404(files.get("heatmap_paths", {}).get(key), "image/png")
    raise HTTPException(status_code=404, detail="Unknown file kind.")


def _file_or_404(path: Optional[str], media: str):
    if not path or not Path(path).is_file():
        raise HTTPException(status_code=404, detail="File not found.")
    return FileResponse(path, media_type=media)


def _crop_url(job_id: str, crop_path: Optional[str]) -> Optional[str]:
    if not crop_path:
        return None
    return _url(f"/jobs/{job_id}/crops/{Path(crop_path).name}")


@app.exception_handler(Exception)
async def _unhandled(_request, exc: Exception):  # pragma: no cover - safety net
    return JSONResponse(status_code=500, content={"detail": f"Internal error: {exc}"})
