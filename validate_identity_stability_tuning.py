import copy
import itertools
import json
from collections import defaultdict
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

import cv2
import numpy as np

import config
from camera_movement_estimator import CameraMovementEstimator
from identity_mapper import IdentityMapper
from trackers import Tracker
from utils import read_video
from view_transformer import ViewTransformer


def apply_manual_object_types_to_tracks(tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]]) -> Tuple[int, int]:
    moved_to_referees = 0
    ignored_tracks = 0

    if "referees" not in tracks:
        tracks["referees"] = [{} for _ in range(len(tracks.get("players", [])))]

    for frame_num, player_tracks in enumerate(tracks.get("players", [])):
        while len(tracks["referees"]) <= frame_num:
            tracks["referees"].append({})
        referee_tracks = tracks["referees"][frame_num]

        to_referees = []
        to_ignore = []
        for track_id, track_info in list(player_tracks.items()):
            object_type = str(track_info.get("object_type", "player")).strip().lower()
            if object_type == "referee":
                to_referees.append(track_id)
            elif object_type == "ignore":
                to_ignore.append(track_id)

        for track_id in to_referees:
            referee_payload = dict(player_tracks[track_id])
            referee_payload["object_type"] = "referee"
            referee_payload["include_in_player_analytics"] = False
            referee_tracks[track_id] = referee_payload
            del player_tracks[track_id]
            moved_to_referees += 1

        for track_id in to_ignore:
            del player_tracks[track_id]
            ignored_tracks += 1

    return moved_to_referees, ignored_tracks


def prepare_base(video_frames: List[np.ndarray]) -> Dict[str, List[Dict[Any, Dict[str, Any]]]]:
    tracker = Tracker(config.TRACKER_MODEL_PATH)
    tracks = tracker.get_object_tracks(
        video_frames,
        read_from_stub=config.USE_STUBS,
        stub_path=config.TRACK_STUB_PATH,
    )
    tracker.add_position_to_tracks(tracks)

    camera_movement_estimator = CameraMovementEstimator(video_frames[0])
    camera_movement_per_frame = camera_movement_estimator.get_camera_movement(
        video_frames,
        read_from_stub=config.USE_STUBS,
        stub_path=config.CAMERA_MOVEMENT_STUB_PATH,
    )
    camera_movement_estimator.add_adjust_positions_to_tracks(tracks, camera_movement_per_frame)

    view_transformer = ViewTransformer(
        pixel_vertices=config.PIXEL_VERTICES,
        pitch_length=config.PITCH_LENGTH,
        pitch_width=config.PITCH_WIDTH,
    )
    view_transformer.add_transformed_position_to_tracks(tracks)
    tracks["ball"] = tracker.interpolate_ball_positions(tracks["ball"])

    # Precompute appearance signatures once so each tuning pass uses identical visual priors.
    mapper = IdentityMapper(video_path=config.VIDEO_PATH)
    mapper.attach_appearance_features(video_frames, tracks)
    return tracks


def fill_teams_lightweight(tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]]) -> None:
    canonical_team_map: Dict[str, int] = {}

    for player_track in tracks.get("players", []):
        for track_info in player_track.values():
            canonical_id = track_info.get("canonical_id")
            team = track_info.get("team")
            if canonical_id and team in (1, 2):
                canonical_team_map[str(canonical_id)] = int(team)

    for frame_num, player_track in enumerate(tracks.get("players", [])):
        for player_id, track in player_track.items():
            locked_team = track.get("team") if track.get("identity_locked") else None
            if locked_team in (1, 2):
                resolved_team = int(locked_team)
            else:
                canonical_id = track.get("canonical_id")
                resolved_team = canonical_team_map.get(str(canonical_id), track.get("team") or 1)

            tracks["players"][frame_num][player_id]["team"] = int(resolved_team)


def summarize_identity_states(tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]]) -> Dict[str, int]:
    counts: Dict[str, int] = defaultdict(int)
    for frame_tracks in tracks.get("players", []):
        for track_info in frame_tracks.values():
            state = str(track_info.get("identity_state", "stable"))
            counts[state] += 1
    return dict(counts)


def count_locked_transition_violations(tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]]) -> int:
    previous_by_track: Dict[int, Tuple[Optional[str], bool]] = {}
    violations = 0

    for frame_tracks in tracks.get("players", []):
        for raw_track_id, track_info in frame_tracks.items():
            try:
                track_id = int(raw_track_id)
            except (TypeError, ValueError):
                continue

            canonical_id = track_info.get("canonical_id")
            identity_locked = bool(track_info.get("identity_locked", False))
            previous = previous_by_track.get(track_id)
            if previous is not None:
                previous_canonical, previous_locked = previous
                if previous_locked and identity_locked and previous_canonical and canonical_id and canonical_id != previous_canonical:
                    violations += 1

            previous_by_track[track_id] = (str(canonical_id) if canonical_id else None, identity_locked)

    return violations


def run_pass(
    pass_name: str,
    mapper_params: Dict[str, Any],
    video_frames: List[np.ndarray],
    base_tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]],
) -> Tuple[Dict[str, Any], Dict[str, List[Dict[Any, Dict[str, Any]]]]]:
    tracks = copy.deepcopy(base_tracks)

    mapper = IdentityMapper(video_path=config.VIDEO_PATH, **mapper_params)
    mapper.set_team_labels({"1": config.TEAM_1_NAME, "2": config.TEAM_2_NAME})
    mapper.bootstrap_from_tracks(tracks)
    mapper.load_corrections(str(Path(config.IDENTITY_CORRECTIONS_PATH)))
    mapper.apply_to_tracks(tracks)
    apply_manual_object_types_to_tracks(tracks)

    fill_teams_lightweight(tracks)
    mapper.sync_registry_from_tracks(tracks)
    mapper.reconcile_fragments(tracks)
    mapper.apply_to_tracks(tracks)
    apply_manual_object_types_to_tracks(tracks)

    mapper.detect_suspicious_events(tracks)
    mapper.detect_conflicts(tracks)
    summary = mapper.generate_summary(tracks, corrections_path=str(Path(config.IDENTITY_CORRECTIONS_PATH)))

    reason_counts = summary.get("identity_stability_guard_reason_counts", {})
    freeze_started = int(reason_counts.get("crossing_freeze_started", 0))
    freeze_maintained = int(reason_counts.get("crossing_freeze_maintained", 0))
    awaiting_post_sep = int(reason_counts.get("awaiting_post_separation_confirmation", 0))
    post_sep_started = int(reason_counts.get("post_separation_confirmation_started", 0))
    post_sep_passed = int(reason_counts.get("post_separation_confirmation_passed", 0))

    impossible_candidate = int(reason_counts.get("candidate_impossible_pitch_jump", 0))
    impossible_runtime = int(reason_counts.get("impossible_pitch_jump_rejected", 0))
    anchor_prefer_previous = int(reason_counts.get("anchor_continuity_prefers_previous", 0))

    focused = {
        "pass_name": pass_name,
        "params": mapper_params,
        "summary_counts": {
            "active_canonical_players": int(summary.get("active_canonical_players", 0)),
            "raw_active_canonical_players": int(summary.get("raw_active_canonical_players", 0)),
            "suspicious_switch_count": int(summary.get("suspicious_switch_count", 0)),
            "resolved_switch_count": int(summary.get("resolved_switch_count", 0)),
            "unresolved_conflict_count": int(summary.get("unresolved_conflict_count", 0)),
            "identity_stability_guard_count": int(summary.get("identity_stability_guard_count", 0)),
        },
        "focus_reason_counts": {
            "crossing_freeze_started": freeze_started,
            "crossing_freeze_maintained": freeze_maintained,
            "awaiting_post_separation_confirmation": awaiting_post_sep,
            "post_separation_confirmation_started": post_sep_started,
            "post_separation_confirmation_passed": post_sep_passed,
            "switch_blocked_due_to_locked_manual_anchor": int(
                reason_counts.get("switch_blocked_due_to_locked_manual_anchor", 0)
            ),
            "candidate_impossible_pitch_jump": impossible_candidate,
            "impossible_pitch_jump_rejected": impossible_runtime,
            "anchor_continuity_prefers_previous": anchor_prefer_previous,
            "label_drift_prevented": int(reason_counts.get("label_drift_prevented", 0)),
            "awaiting_multi_frame_confirmation": int(reason_counts.get("awaiting_multi_frame_confirmation", 0)),
        },
        "derived_metrics": {
            "freeze_maintained_per_start": round(freeze_maintained / max(1, freeze_started), 3),
            "post_separation_pass_rate": round(post_sep_passed / max(1, post_sep_started), 3),
            "impossible_jump_guard_total": int(impossible_candidate + impossible_runtime + anchor_prefer_previous),
            "locked_transition_violations": int(count_locked_transition_violations(tracks)),
            "identity_state_counts": summarize_identity_states(tracks),
        },
        "identity_stability_guard_logs": summary.get("identity_stability_guard_logs", []),
    }

    return focused, tracks


def short_canonical(canonical_id: Optional[str]) -> str:
    if canonical_id is None:
        return "-"
    text = str(canonical_id)
    if "_" in text:
        head, tail = text.split("_", 1)
        return f"{head[0]}{tail}"
    return text


def annotate_frame(
    frame: np.ndarray,
    tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]],
    frame_idx: int,
    focus_tracks: Set[int],
    panel_title: str,
) -> np.ndarray:
    canvas = frame.copy()
    player_tracks = tracks.get("players", [])[frame_idx] if frame_idx < len(tracks.get("players", [])) else {}

    for raw_track_id, info in player_tracks.items():
        bbox = info.get("bbox")
        if not isinstance(bbox, (list, tuple)) or len(bbox) < 4:
            continue

        try:
            track_id = int(raw_track_id)
        except (TypeError, ValueError):
            continue

        x1, y1, x2, y2 = [int(v) for v in bbox]
        identity_state = str(info.get("identity_state", "stable"))
        canonical_id = short_canonical(info.get("canonical_id"))
        locked = bool(info.get("identity_locked", False))

        if identity_state == "stable":
            color = (50, 200, 50)
        elif identity_state == "pitch_jump_guard":
            color = (0, 0, 255)
        elif "ambiguous" in identity_state or "awaiting" in identity_state:
            color = (0, 165, 255)
        else:
            color = (255, 200, 0)

        thickness = 2
        if track_id in focus_tracks:
            thickness = 4
            cv2.circle(canvas, (max(0, x1), max(0, y1 - 8)), 6, (255, 255, 255), -1)

        cv2.rectangle(canvas, (x1, y1), (x2, y2), color, thickness)
        label = f"t{track_id} c{canonical_id} {identity_state}"
        if locked:
            label += " L"

        cv2.putText(
            canvas,
            label[:64],
            (x1, max(16, y1 - 6)),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.45,
            (255, 255, 255),
            2,
            cv2.LINE_AA,
        )
        cv2.putText(
            canvas,
            label[:64],
            (x1, max(16, y1 - 6)),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.45,
            (0, 0, 0),
            1,
            cv2.LINE_AA,
        )

    cv2.rectangle(canvas, (8, 8), (640, 40), (0, 0, 0), -1)
    cv2.putText(
        canvas,
        panel_title,
        (14, 31),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.65,
        (255, 255, 255),
        2,
        cv2.LINE_AA,
    )
    return canvas


def build_focus_frames(
    baseline_logs: List[Dict[str, Any]],
    tuned_logs: List[Dict[str, Any]],
    max_frames: int = 8,
) -> List[Tuple[int, Set[int], List[str]]]:
    priority_reasons = [
        "candidate_impossible_pitch_jump",
        "impossible_pitch_jump_rejected",
        "switch_blocked_due_to_locked_manual_anchor",
        "awaiting_post_separation_confirmation",
        "post_separation_confirmation_started",
        "crossing_freeze_started",
    ]

    grouped: Dict[int, Dict[str, Any]] = {}
    for source_name, logs in (("baseline", baseline_logs), ("tuned", tuned_logs)):
        for item in logs:
            reason = str(item.get("reason", ""))
            if reason not in priority_reasons:
                continue

            frame_num = int(item.get("frame_num", 0))
            track_id = int(item.get("track_id", -1))
            bucket = grouped.setdefault(frame_num, {"tracks": set(), "reasons": set(), "sources": set()})
            if track_id >= 0:
                bucket["tracks"].add(track_id)
            bucket["reasons"].add(reason)
            bucket["sources"].add(source_name)

    ranked = sorted(
        grouped.items(),
        key=lambda kv: (
            -len(kv[1]["reasons"]),
            -len(kv[1]["sources"]),
            kv[0],
        ),
    )

    selected = []
    for frame_num, data in ranked[:max_frames]:
        selected.append(
            (
                frame_num,
                set(data["tracks"]),
                sorted(data["reasons"]),
            )
        )
    return selected


def load_focus_frames_from_report(report_path: Path) -> List[Tuple[int, Set[int], List[str]]]:
    if not report_path.exists():
        return []

    try:
        with report_path.open("r", encoding="utf-8") as f:
            payload = json.load(f)
    except (json.JSONDecodeError, OSError):
        return []

    restored: List[Tuple[int, Set[int], List[str]]] = []
    for item in payload.get("focus_frames", []):
        frame_num = int(item.get("frame_num", 0))
        focus_tracks = {int(track_id) for track_id in item.get("focus_tracks", [])}
        reasons = [str(reason) for reason in item.get("reasons", [])]
        restored.append((frame_num, focus_tracks, reasons))

    return restored


def get_player_track_info(
    tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]],
    frame_num: int,
    track_id: int,
) -> Optional[Dict[str, Any]]:
    players_by_frame = tracks.get("players", [])
    if frame_num < 0 or frame_num >= len(players_by_frame):
        return None

    frame_tracks = players_by_frame[frame_num]
    if track_id in frame_tracks:
        return frame_tracks[track_id]

    str_track_id = str(track_id)
    if str_track_id in frame_tracks:
        return frame_tracks[str_track_id]

    for raw_track_id, track_info in frame_tracks.items():
        try:
            if int(raw_track_id) == track_id:
                return track_info
        except (TypeError, ValueError):
            continue

    return None


def bucket_identity_state(state: str) -> str:
    normalized = str(state)
    if normalized == "stable":
        return "stable"
    if normalized == "pitch_jump_guard":
        return "pitch_jump_guard"
    if "ambiguous" in normalized or "awaiting" in normalized:
        return "crossing_or_confirmation"
    return "other"


def evaluate_focus_frame_stability(
    reference_tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]],
    candidate_tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]],
    focus_frames: List[Tuple[int, Set[int], List[str]]],
) -> Dict[str, Any]:
    metrics: Dict[str, int] = defaultdict(int)

    for frame_num, focus_tracks, _ in focus_frames:
        for track_id in focus_tracks:
            reference_info = get_player_track_info(reference_tracks, frame_num, track_id)
            candidate_info = get_player_track_info(candidate_tracks, frame_num, track_id)

            if reference_info is None and candidate_info is None:
                continue

            metrics["samples"] += 1
            if reference_info is None:
                metrics["newly_present_in_candidate"] += 1
                continue
            if candidate_info is None:
                metrics["missing_in_candidate"] += 1
                continue

            reference_bucket = bucket_identity_state(reference_info.get("identity_state", "stable"))
            candidate_bucket = bucket_identity_state(candidate_info.get("identity_state", "stable"))
            metrics[f"candidate_bucket_{candidate_bucket}"] += 1

            if reference_bucket != "stable" and candidate_bucket == "stable":
                metrics["stable_upgrades"] += 1
            if reference_bucket == "stable" and candidate_bucket != "stable":
                metrics["stable_regressions"] += 1
            if reference_bucket != "pitch_jump_guard" and candidate_bucket == "pitch_jump_guard":
                metrics["added_pitch_jump_guard"] += 1

            reference_canonical = reference_info.get("canonical_id")
            candidate_canonical = candidate_info.get("canonical_id")
            if reference_canonical and candidate_canonical and reference_canonical != candidate_canonical:
                metrics["canonical_id_mismatches"] += 1

    stable_upgrades = int(metrics.get("stable_upgrades", 0))
    stable_regressions = int(metrics.get("stable_regressions", 0))
    added_pitch_jump_guard = int(metrics.get("added_pitch_jump_guard", 0))

    if stable_upgrades > stable_regressions and added_pitch_jump_guard <= 1:
        verdict = "improved"
    elif stable_upgrades == 0 and stable_regressions == 0 and added_pitch_jump_guard == 0:
        verdict = "no_change"
    elif stable_regressions > stable_upgrades or added_pitch_jump_guard >= 3:
        verdict = "regressed"
    else:
        verdict = "mixed"

    return {
        "verdict": verdict,
        "metrics": dict(metrics),
    }


def compute_delta_vs_reference(candidate_result: Dict[str, Any], reference_result: Dict[str, Any]) -> Dict[str, Any]:
    delta_summary = {
        key: int(candidate_result.get("summary_counts", {}).get(key, 0))
        - int(reference_result.get("summary_counts", {}).get(key, 0))
        for key in set(candidate_result.get("summary_counts", {})) | set(reference_result.get("summary_counts", {}))
    }
    delta_focus = {
        key: int(candidate_result.get("focus_reason_counts", {}).get(key, 0))
        - int(reference_result.get("focus_reason_counts", {}).get(key, 0))
        for key in set(candidate_result.get("focus_reason_counts", {}))
        | set(reference_result.get("focus_reason_counts", {}))
    }

    candidate_states = candidate_result.get("derived_metrics", {}).get("identity_state_counts", {})
    reference_states = reference_result.get("derived_metrics", {}).get("identity_state_counts", {})
    delta_states = {
        key: int(candidate_states.get(key, 0)) - int(reference_states.get(key, 0))
        for key in set(candidate_states) | set(reference_states)
    }

    delta_derived = {
        "impossible_jump_guard_total": int(candidate_result.get("derived_metrics", {}).get("impossible_jump_guard_total", 0))
        - int(reference_result.get("derived_metrics", {}).get("impossible_jump_guard_total", 0)),
        "freeze_maintained_per_start": round(
            float(candidate_result.get("derived_metrics", {}).get("freeze_maintained_per_start", 0.0))
            - float(reference_result.get("derived_metrics", {}).get("freeze_maintained_per_start", 0.0)),
            3,
        ),
        "post_separation_pass_rate": round(
            float(candidate_result.get("derived_metrics", {}).get("post_separation_pass_rate", 0.0))
            - float(reference_result.get("derived_metrics", {}).get("post_separation_pass_rate", 0.0)),
            3,
        ),
    }

    return {
        "summary_counts": delta_summary,
        "focus_reason_counts": delta_focus,
        "identity_state_counts": delta_states,
        "derived_metrics": delta_derived,
    }


def evaluate_jump_catch_tradeoff(candidate_result: Dict[str, Any], delta: Dict[str, Any]) -> Dict[str, Any]:
    candidate_focus = candidate_result.get("focus_reason_counts", {})
    candidate_states = candidate_result.get("derived_metrics", {}).get("identity_state_counts", {})
    delta_focus = delta.get("focus_reason_counts", {})
    delta_states = delta.get("identity_state_counts", {})
    delta_derived = delta.get("derived_metrics", {})

    impossible_jump_delta = int(delta_derived.get("impossible_jump_guard_total", 0))
    pitch_jump_guard_delta = int(delta_states.get("pitch_jump_guard", 0))
    crossing_ambiguous_delta = int(delta_states.get("ambiguous_crossing", 0))
    confirmation_wait_delta = int(delta_states.get("awaiting_post_separation_confirmation", 0))

    catches_improved = impossible_jump_delta > 0
    overfreezing = (
        pitch_jump_guard_delta > 120
        or crossing_ambiguous_delta > 80
        or confirmation_wait_delta > 80
        or int(delta_focus.get("crossing_freeze_maintained", 0)) > 90
    )

    if catches_improved and not overfreezing:
        verdict = "improved_without_overfreezing"
    elif catches_improved and overfreezing:
        verdict = "more_jump_catches_but_overfreezing"
    elif not catches_improved and overfreezing:
        verdict = "overfreezing_without_jump_gain"
    else:
        verdict = "no_additional_jump_catches"

    return {
        "verdict": verdict,
        "catches_improved": catches_improved,
        "overfreezing": overfreezing,
        "signals": {
            "impossible_jump_guard_total": int(candidate_result.get("derived_metrics", {}).get("impossible_jump_guard_total", 0)),
            "candidate_impossible_pitch_jump": int(candidate_focus.get("candidate_impossible_pitch_jump", 0)),
            "impossible_pitch_jump_rejected": int(candidate_focus.get("impossible_pitch_jump_rejected", 0)),
            "anchor_continuity_prefers_previous": int(candidate_focus.get("anchor_continuity_prefers_previous", 0)),
            "pitch_jump_guard_state_count": int(candidate_states.get("pitch_jump_guard", 0)),
            "pitch_jump_guard_delta_vs_tuned": pitch_jump_guard_delta,
            "ambiguous_crossing_delta_vs_tuned": crossing_ambiguous_delta,
            "awaiting_confirmation_delta_vs_tuned": confirmation_wait_delta,
        },
    }


def pick_best_candidate(candidates: List[Dict[str, Any]]) -> Optional[str]:
    if not candidates:
        return None

    def score(item: Dict[str, Any]) -> float:
        tradeoff = item.get("jump_tradeoff", {})
        visual = item.get("visual_stability_vs_tuned", {})
        delta = item.get("delta_vs_tuned", {})

        catches = 1 if bool(tradeoff.get("catches_improved", False)) else 0
        overfreeze_penalty = 2 if bool(tradeoff.get("overfreezing", False)) else 0

        visual_verdict = str(visual.get("verdict", "mixed"))
        if visual_verdict == "improved":
            visual_score = 2
        elif visual_verdict == "no_change":
            visual_score = 1
        elif visual_verdict == "mixed":
            visual_score = 0
        else:
            visual_score = -2

        pitch_delta = int(delta.get("identity_state_counts", {}).get("pitch_jump_guard", 0))
        pitch_penalty = 1 if pitch_delta > 80 else 0

        return (catches * 4) + visual_score - (overfreeze_penalty * 3) - pitch_penalty

    ranked = sorted(candidates, key=score, reverse=True)
    return str(ranked[0].get("pass_name")) if ranked else None


def write_visual_comparisons(
    output_dir: Path,
    video_frames: List[np.ndarray],
    left_tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]],
    right_tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]],
    focus_frames: List[Tuple[int, Set[int], List[str]]],
    left_label: str = "LEFT",
    right_label: str = "RIGHT",
) -> List[str]:
    output_dir.mkdir(parents=True, exist_ok=True)
    written_paths: List[str] = []

    for frame_num, focus_tracks, reasons in focus_frames:
        if frame_num < 0 or frame_num >= len(video_frames):
            continue

        base_img = annotate_frame(
            video_frames[frame_num],
            left_tracks,
            frame_num,
            focus_tracks,
            f"{left_label} frame={frame_num}",
        )
        tuned_img = annotate_frame(
            video_frames[frame_num],
            right_tracks,
            frame_num,
            focus_tracks,
            f"{right_label} frame={frame_num}",
        )

        h = max(base_img.shape[0], tuned_img.shape[0])
        if base_img.shape[0] != h:
            base_img = cv2.copyMakeBorder(base_img, 0, h - base_img.shape[0], 0, 0, cv2.BORDER_CONSTANT, value=(0, 0, 0))
        if tuned_img.shape[0] != h:
            tuned_img = cv2.copyMakeBorder(tuned_img, 0, h - tuned_img.shape[0], 0, 0, cv2.BORDER_CONSTANT, value=(0, 0, 0))

        combined = np.concatenate([base_img, tuned_img], axis=1)
        reason_text = ", ".join(reasons)[:180]
        cv2.rectangle(combined, (12, 48), (combined.shape[1] - 12, 84), (0, 0, 0), -1)
        cv2.putText(
            combined,
            f"reasons: {reason_text}",
            (18, 74),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.52,
            (255, 255, 255),
            1,
            cv2.LINE_AA,
        )

        out_path = output_dir / f"comparison_frame_{frame_num:04d}.jpg"
        cv2.imwrite(str(out_path), combined)
        written_paths.append(str(out_path))

    return written_paths


def main() -> None:
    print("Loading video and preparing base tracks...")
    video_frames = read_video(config.VIDEO_PATH)
    base_tracks = prepare_base(video_frames)

    tuned_name = "tuned_crossing_anchor_v1"
    tuned_params = {
        "abrupt_jump_threshold_m": 8.0,
        "crossing_freeze_min_frames": 3,
        "crossing_release_distance_m": 3.6,
        "post_separation_confirmation_frames": 2,
        "switch_min_confidence": 1.1,
    }

    print(f"\nRunning reference pass: {tuned_name}")
    tuned_result, tuned_tracks = run_pass(
        pass_name=tuned_name,
        mapper_params=tuned_params,
        video_frames=video_frames,
        base_tracks=base_tracks,
    )

    focus_frames = load_focus_frames_from_report(Path("output_videos/identity_stability_tuning_runs.json"))
    if not focus_frames:
        focus_frames = build_focus_frames(
            baseline_logs=tuned_result.get("identity_stability_guard_logs", []),
            tuned_logs=tuned_result.get("identity_stability_guard_logs", []),
            max_frames=10,
        )

    fixed_crossing = {
        "crossing_freeze_min_frames": 3,
        "crossing_release_distance_m": 3.6,
        "post_separation_confirmation_frames": 2,
    }
    jump_threshold_values = [7.0, 7.25, 7.5]
    switch_conf_values = [1.1, 1.125, 1.15]

    comparison_root = Path("output_videos/identity_stability_middle_sweep_frames")
    candidates: List[Dict[str, Any]] = []

    for abrupt_jump_threshold_m, switch_min_confidence in itertools.product(jump_threshold_values, switch_conf_values):
        pass_name = f"middle_jump_a{abrupt_jump_threshold_m:.2f}_c{switch_min_confidence:.3f}".replace(".", "p")
        params = {
            **fixed_crossing,
            "abrupt_jump_threshold_m": abrupt_jump_threshold_m,
            "switch_min_confidence": switch_min_confidence,
        }

        print(f"\nRunning candidate: {pass_name}")
        candidate_result, candidate_tracks = run_pass(
            pass_name=pass_name,
            mapper_params=params,
            video_frames=video_frames,
            base_tracks=base_tracks,
        )

        delta = compute_delta_vs_reference(candidate_result, tuned_result)
        jump_tradeoff = evaluate_jump_catch_tradeoff(candidate_result, delta)
        visual_assessment = evaluate_focus_frame_stability(
            reference_tracks=tuned_tracks,
            candidate_tracks=candidate_tracks,
            focus_frames=focus_frames,
        )

        comparison_dir = comparison_root / pass_name
        comparison_images = write_visual_comparisons(
            output_dir=comparison_dir,
            video_frames=video_frames,
            left_tracks=tuned_tracks,
            right_tracks=candidate_tracks,
            focus_frames=focus_frames,
            left_label="TUNED_REF",
            right_label=pass_name,
        )

        candidate_payload = {
            "pass_name": pass_name,
            "params": params,
            "summary_counts": candidate_result.get("summary_counts", {}),
            "focus_reason_counts": candidate_result.get("focus_reason_counts", {}),
            "derived_metrics": candidate_result.get("derived_metrics", {}),
            "delta_vs_tuned": delta,
            "jump_tradeoff": jump_tradeoff,
            "visual_stability_vs_tuned": visual_assessment,
            "comparison_images": comparison_images,
        }
        candidates.append(candidate_payload)

        print("  key counts:")
        print(f"    focus_reason_counts={candidate_payload['focus_reason_counts']}")
        print(f"    delta_vs_tuned_focus={candidate_payload['delta_vs_tuned']['focus_reason_counts']}")
        print(f"    jump_tradeoff={candidate_payload['jump_tradeoff']}")
        print(f"    visual_stability_vs_tuned={candidate_payload['visual_stability_vs_tuned']['verdict']}")

    best_candidate_name = pick_best_candidate(candidates)

    payload = {
        "video_path": config.VIDEO_PATH,
        "reference_profile": {
            "name": tuned_name,
            "params": tuned_params,
            "summary_counts": tuned_result.get("summary_counts", {}),
            "focus_reason_counts": tuned_result.get("focus_reason_counts", {}),
            "derived_metrics": tuned_result.get("derived_metrics", {}),
        },
        "focus_frames": [
            {
                "frame_num": frame_num,
                "focus_tracks": sorted(int(track_id) for track_id in tracks),
                "reasons": reasons,
            }
            for frame_num, tracks, reasons in focus_frames
        ],
        "candidates": candidates,
        "recommended_candidate": best_candidate_name,
    }

    output_json = Path("output_videos/identity_stability_middle_sweep_runs.json")
    output_json.parent.mkdir(parents=True, exist_ok=True)
    with output_json.open("w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, ensure_ascii=False)

    print(f"\nSaved middle sweep report: {output_json}")
    print(f"Saved comparison frames root: {comparison_root}")
    print(f"Candidate runs evaluated: {len(candidates)}")
    print(f"Recommended candidate: {best_candidate_name}")


if __name__ == "__main__":
    main()
