"""In-process job store + background execution.

Jobs run on a single-worker thread pool so the GPU is used by one run at a
time (the model is not concurrency-safe and one run already saturates a GPU).
State is in memory: a server restart loses in-flight jobs, which is acceptable
for this stateful-but-short pipeline (the app re-uploads on failure). Swap this
for Redis/DB-backed jobs if horizontal scaling is needed later.
"""

from __future__ import annotations

import threading
import time
import traceback
import uuid
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional

from . import model_runner, settings
from .schemas import JobStatus

_STAGE_LABELS = {
    JobStatus.queued: "Queued",
    JobStatus.detecting: "Detecting players",
    JobStatus.awaiting_naming: "Waiting for player names",
    JobStatus.analyzing: "Analyzing match (tracking, possession, tactics)",
    JobStatus.completed: "Analysis ready",
    JobStatus.failed: "Failed",
}
_PROGRESS = {
    JobStatus.queued: 0.02,
    JobStatus.detecting: 0.25,
    JobStatus.awaiting_naming: 0.45,
    JobStatus.analyzing: 0.75,
    JobStatus.completed: 1.0,
    JobStatus.failed: 0.0,
}


@dataclass
class Job:
    id: str
    status: JobStatus = JobStatus.queued
    error: Optional[str] = None
    created_at: float = field(default_factory=time.time)

    # Match metadata supplied at upload (from the app).
    home_team: str = ""
    away_team: str = ""
    competition: str = ""
    venue: str = ""
    match_date: str = ""
    club_id: Optional[str] = None
    uploaded_by: Optional[str] = None

    # Filled by Stage 1.
    video_path: Optional[Path] = None
    stem: str = ""
    tracks_json: Optional[str] = None
    roles_json: Optional[str] = None
    corrections_file: Optional[str] = None
    naming_players: List[dict] = field(default_factory=list)
    team_legend: List[dict] = field(default_factory=list)

    # Filled by Stage 2.
    result: Optional[Dict[str, Any]] = None

    @property
    def stage_label(self) -> str:
        return _STAGE_LABELS.get(self.status, "")

    @property
    def progress(self) -> float:
        return _PROGRESS.get(self.status, 0.0)


class JobStore:
    def __init__(self) -> None:
        self._jobs: Dict[str, Job] = {}
        self._lock = threading.Lock()
        # One worker: serialize GPU-bound model runs.
        self._pool = ThreadPoolExecutor(max_workers=1, thread_name_prefix="gsmodel")

    def get(self, job_id: str) -> Optional[Job]:
        with self._lock:
            return self._jobs.get(job_id)

    def create(self, video_bytes: bytes, filename: str, meta: dict) -> Job:
        job_id = uuid.uuid4().hex
        # Use the job id as the file stem so all model outputs are isolated
        # (outputs/<job_id>_*.json) and never collide across uploads.
        settings.UPLOADS_DIR.mkdir(parents=True, exist_ok=True)
        suffix = Path(filename).suffix or ".mp4"
        video_path = settings.UPLOADS_DIR / f"{job_id}{suffix}"
        video_path.write_bytes(video_bytes)

        job = Job(
            id=job_id,
            video_path=video_path,
            stem=video_path.stem,
            home_team=meta.get("home_team", ""),
            away_team=meta.get("away_team", ""),
            competition=meta.get("competition", ""),
            venue=meta.get("venue", ""),
            match_date=meta.get("match_date", ""),
            club_id=meta.get("club_id"),
            uploaded_by=meta.get("uploaded_by"),
        )
        with self._lock:
            self._jobs[job_id] = job
        self._pool.submit(self._run_detection, job_id)
        return job

    def confirm_players(
        self, job_id: str, mappings: List[dict], my_team_id: int
    ) -> bool:
        job = self.get(job_id)
        if job is None or job.status != JobStatus.awaiting_naming:
            return False
        self._pool.submit(self._run_analysis, job_id, mappings, my_team_id)
        return True

    # ── Worker bodies ────────────────────────────────────────────────────--
    def _set(self, job_id: str, status: JobStatus, error: Optional[str] = None) -> None:
        with self._lock:
            job = self._jobs.get(job_id)
            if job is None:
                return
            job.status = status
            if error is not None:
                job.error = error

    def _run_detection(self, job_id: str) -> None:
        job = self.get(job_id)
        if job is None or job.video_path is None:
            return
        self._set(job_id, JobStatus.detecting)
        try:
            out = model_runner.run_detection_stage(job.video_path, job.stem)
            with self._lock:
                j = self._jobs[job_id]
                j.tracks_json = out["tracks_json"]
                j.roles_json = out["roles_json"]
                j.corrections_file = out["corrections_file"]
                j.naming_players = out["players"]
                j.team_legend = out["team_legend"]
                j.status = JobStatus.awaiting_naming
        except Exception as exc:  # noqa: BLE001 — surface any model failure
            self._set(job_id, JobStatus.failed,
                      f"Detection failed: {exc}\n{traceback.format_exc()}")

    def _run_analysis(self, job_id: str, mappings: List[dict], my_team_id: int) -> None:
        job = self.get(job_id)
        if job is None or job.video_path is None:
            return
        self._set(job_id, JobStatus.analyzing)
        try:
            out = model_runner.run_analysis_stage(
                video_path=job.video_path,
                stem=job.stem,
                tracks_json=job.tracks_json or "",
                roles_json=job.roles_json or "",
                corrections_file=job.corrections_file or "",
                mappings=mappings,
                my_team_id=my_team_id,
            )
            # Persist to Supabase (DB rows + Storage). Best-effort: the result
            # is still served from this service even if the sink fails, so a
            # Storage/DB hiccup never loses a completed analysis.
            analysis_id = None
            if settings.has_supabase():
                try:
                    from .supabase_sink import SupabaseSink
                    analysis_id = SupabaseSink().persist(job, out)
                except Exception as exc:  # noqa: BLE001
                    print(f"[jobs] Supabase persist failed for {job_id}: {exc}\n"
                          f"{traceback.format_exc()}")
            out["analysis_id"] = analysis_id
            with self._lock:
                j = self._jobs[job_id]
                j.result = out
                j.status = JobStatus.completed
        except Exception as exc:  # noqa: BLE001
            self._set(job_id, JobStatus.failed,
                      f"Analysis failed: {exc}\n{traceback.format_exc()}")


store = JobStore()
