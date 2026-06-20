"""Headless orchestration of the football_ai model — the integration core.

This module imports the model's *own* ``main.py`` module-level functions and
``RoleCorrectionRunner`` and drives them in two stages. It NEVER launches the
desktop Tkinter review UI; instead the manager's names arrive from the app and
are written as the model's standard corrections JSON.

Stage 1 — :func:`run_detection_stage`
    DetectionPipeline.run → run_stitching → run_swap_correction
    → run_role_refinement → RoleCorrectionRunner.build_review_dataset
    Produces stable track ids, the auto roles/teams, and per-track jersey
    crops + a team legend for the naming screen. Pauses here.

Stage 2 — :func:`run_analysis_stage`
    Write corrections JSON (track_id → {role, team_id, player_name}) →
    RoleCorrectionRunner.run_apply → run_possession → run_minimap
    (run_minimap internally does speed/distance, player performance,
    heatmaps, tactical, field possession, final report, and the final
    annotated video — exactly as in ``main.py``).

The model is imported lazily (heavy: torch/ultralytics) so the API process can
start fast and import errors surface as a clear job failure, not a crash.
"""

from __future__ import annotations

import json
import os
import sys
import threading
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from . import settings

# Import the model exactly once, with MODEL_DIR on sys.path and as CWD (the
# model uses paths relative to its own root: "config/...", "outputs/...",
# "weights/..."). A single lock serializes model runs (one GPU).
_model_lock = threading.Lock()
_model_ready = False


def _ensure_model_imported() -> None:
    global _model_ready
    if _model_ready:
        return
    model_dir = str(settings.MODEL_DIR)
    if not settings.MODEL_DIR.is_dir():
        raise RuntimeError(
            f"GOALSIGHT_MODEL_DIR does not exist: {model_dir}. "
            "Point it at the football_ai project root."
        )
    if model_dir not in sys.path:
        sys.path.insert(0, model_dir)
    # The model writes outputs relative to CWD; run from its root.
    os.chdir(model_dir)
    settings.UPLOADS_DIR.mkdir(parents=True, exist_ok=True)
    settings.OUTPUTS_DIR.mkdir(parents=True, exist_ok=True)
    _model_ready = True


def _config_path() -> str:
    p = Path(settings.MODEL_CONFIG)
    return str(p if p.is_absolute() else settings.MODEL_DIR / p)


def _outputs() -> Path:
    return settings.OUTPUTS_DIR


# ───────────────────────────── Stage 1: detect ──────────────────────────────

def run_detection_stage(video_path: Path, stem: str) -> Dict[str, Any]:
    """Run detection→tracking→roles and build the naming dataset.

    Returns a dict with the tracks/roles JSON paths and the naming payload
    (players + team legend). Blocks; call inside a worker thread.
    """
    with _model_lock:
        _ensure_model_imported()
        import main as model_main  # the model orchestrator (importable)
        from detection.pipeline import DetectionPipeline
        from manual_correction.correction_runner import RoleCorrectionRunner
        from utils.config_loader import load_config

        # Build config exactly like a CLI run up to roles (NOT --all, so no
        # minimap/analytics and no manual-correction UI step).
        args = model_main.parse_args([
            "--video", str(video_path),
            "--tracking", "--stitch-tracks", "--fix-swaps",
            "--role-refinement",
            "--device", settings.DEVICE,
        ])
        config = load_config(_config_path())
        config = model_main.apply_overrides(config, args)
        if settings.IMAGE_SIZE:
            config.model.image_size = settings.IMAGE_SIZE

        summary = DetectionPipeline(config).run(video_path)
        if config.tracking.stitching.enabled and summary.get("tracks_json"):
            model_main.run_stitching(config, video_path, summary)
        if config.tracking.swap_correction.enabled and summary.get("tracks_json"):
            model_main.run_swap_correction(config, video_path, summary)

        role_summary = model_main.run_role_refinement(config, video_path, summary)
        if not role_summary or not role_summary.get("roles_json"):
            raise RuntimeError("Role refinement produced no roles JSON.")

        tracks_json = summary["tracks_json"]
        roles_json = role_summary["roles_json"]

        runner = RoleCorrectionRunner(config.manual_correction)
        dataset = runner.build_review_dataset(video_path, tracks_json, roles_json)
        manifest_path = dataset["manifest"]

        players, legend = _parse_naming_manifest(manifest_path)
        return {
            "tracks_json": tracks_json,
            "roles_json": roles_json,
            "manifest": manifest_path,
            "corrections_file": config.manual_correction.corrections_file,
            "players": players,       # list of dicts (DetectedPlayer fields)
            "team_legend": legend,    # list of dicts (TeamLegendEntry fields)
        }


def _parse_naming_manifest(manifest_path: str) -> Tuple[List[dict], List[dict]]:
    """Turn the review manifest into naming-screen payloads."""
    data = json.loads(Path(manifest_path).read_text(encoding="utf-8"))
    players: List[dict] = []
    for c in data.get("candidates", []):
        crops = c.get("crop_paths") or []
        # Jersey number is the most reliable human-readable identifier from
        # broadcast footage (faces are too few pixels to recognise). The model
        # may key it under several names; take the first non-empty one and pass
        # it through as a string. Absent → null (badge simply won't render).
        jersey = (
            c.get("jersey_number")
            or c.get("jersey")
            or c.get("number")
        )
        jersey_str = str(jersey).strip() if jersey not in (None, "") else None
        players.append({
            "track_id": int(c["track_id"]),
            "auto_role": str(c.get("current_role", "unknown")),
            "team_id": c.get("team_id"),
            "jersey_number": jersey_str,
            "track_length": int(c.get("track_length", 0)),
            "role_confidence": float(c.get("role_confidence", 0.0)),
            # First crop kept for backwards-compat; full list powers the
            # multi-frame verification gallery on the naming screen.
            "crop_path": crops[0] if crops else None,
            "crop_paths": list(crops),
            "suggested_name": None,
        })
    legend: List[dict] = []
    for _, entry in (data.get("team_legend") or {}).items():
        legend.append({
            "team_id": int(entry.get("team_id")),
            "label": str(entry.get("label", "")),
            "color_rgb": list(entry.get("color_rgb", [])),
            "crop_paths": list(entry.get("crop_paths", [])),
        })
    # Players first (best tracks first), goalkeepers/unknowns after.
    players.sort(key=lambda p: (p["auto_role"] != "player", -p["track_length"]))
    return players, legend


# ───────────────────────────── Stage 2: analyze ─────────────────────────────

def run_analysis_stage(
    video_path: Path,
    stem: str,
    tracks_json: str,
    roles_json: str,
    corrections_file: str,
    mappings: List[dict],          # [{track_id, player_name, player_id?}]
    my_team_id: int,
) -> Dict[str, Any]:
    """Apply names then run the full analysis (analytics + heatmaps + video)."""
    with _model_lock:
        _ensure_model_imported()
        import main as model_main
        from manual_correction.correction_models import Correction
        from manual_correction.correction_runner import (
            RoleCorrectionRunner,
            load_auto_roles,
        )
        from manual_correction.correction_store import CorrectionStore
        from utils.config_loader import load_config

        # 1) Write the model's standard corrections file from the app's names.
        #    We preserve each track's auto role + team (so apply is not a
        #    no-op) and attach the manager-entered player_name (Phase 4).
        auto = load_auto_roles(roles_json)
        corrections: Dict[int, Correction] = {}
        applied_map: Dict[str, Dict[str, Any]] = {}
        for m in mappings:
            tid = int(m["track_id"])
            a = auto.get(tid)
            if a is None:
                continue
            name = (m.get("player_name") or "").strip() or None
            corrections[tid] = Correction(
                role=a.refined_role,
                team_id=a.team_id,
                player_name=name,
                user_initialized=True,
            )
            applied_map[str(tid)] = {
                "player_name": name,
                "player_id": m.get("player_id"),
                "team_id": a.team_id,
                "role": a.refined_role,
            }
        CorrectionStore(corrections_file).save(corrections)

        # 2) Build a full-pipeline config, but reuse the Stage-1 tracks so we
        #    do NOT re-run detection/tracking (fast hybrid). Auto-calibration
        #    turns on automatically when the keypoint model is present.
        args = model_main.parse_args([
            "--video", str(video_path),
            "--all", "--reuse-tracks",
            "--device", settings.DEVICE,
        ])
        config = load_config(_config_path())
        config = model_main.apply_overrides(config, args)
        if settings.IMAGE_SIZE:
            config.model.image_size = settings.IMAGE_SIZE

        reuse = model_main._find_reusable_tracks(config, video_path) or tracks_json
        summary = {"tracking": True, "reused": True, "tracks_json": reuse}

        # 3) Overlay names onto the auto roles → <stem>_roles_final.json.
        final_roles = str(_outputs() / f"{stem}_roles_final.json")
        runner = RoleCorrectionRunner(config.manual_correction)
        runner.run_apply(
            video_path=video_path,
            roles_json_path=roles_json,
            corrections_file=corrections_file,
            final_output_path=final_roles,
            tracks_json_path=reuse,
            render_video=False,
        )
        role_summary = {"roles_json": final_roles}

        # 4) Possession + the big minimap/analytics/report/video pass — the
        #    exact functions main.py calls, in the same order.
        model_main.run_possession(config, video_path, summary, role_summary)
        model_main.run_minimap(config, video_path, summary, role_summary)

        return {
            "my_team_id": my_team_id,
            "player_mapping": applied_map,
            "files": _collect_outputs(stem),
        }


# ───────────────────────────── Output collection ────────────────────────────

# Model output files keyed by stem. JSONs are loaded inline (Phase 7: keep all
# raw outputs); large per-frame files and binaries are referenced by path.
_RAW_JSONS = {
    "final_report": "{stem}_final_report.json",
    "player_analytics": "{stem}_player_analytics.json",
    "speed_distance": "{stem}_analytics.json",
    "team_tactical": "{stem}_team_tactical.json",
    "possession": "{stem}_possession.json",
}
_HEATMAPS = {
    "team0": "{stem}_team0_heatmap.png",
    "team1": "{stem}_team1_heatmap.png",
    "team0_best_player": "{stem}_team0_best_player_heatmap.png",
    "team1_best_player": "{stem}_team1_best_player_heatmap.png",
}


def _collect_outputs(stem: str) -> Dict[str, Any]:
    """Gather produced artifacts. Returns inline JSON + on-disk file paths."""
    out = _outputs()
    raw: Dict[str, Any] = {}
    for key, pattern in _RAW_JSONS.items():
        p = out / pattern.format(stem=stem)
        if p.is_file():
            try:
                raw[key] = json.loads(p.read_text(encoding="utf-8"))
            except Exception:
                raw[key] = {"_error": "could not parse", "_path": str(p)}

    heatmaps: Dict[str, str] = {}
    for key, pattern in _HEATMAPS.items():
        p = out / pattern.format(stem=stem)
        if p.is_file():
            heatmaps[key] = str(p)

    video = out / f"{stem}_final_with_minimap.mp4"
    field_positions = out / f"{stem}_field_positions.json"
    return {
        "raw": raw,
        "heatmap_paths": heatmaps,
        "analyzed_video_path": str(video) if video.is_file() else None,
        "field_positions_path": str(field_positions) if field_positions.is_file() else None,
    }
