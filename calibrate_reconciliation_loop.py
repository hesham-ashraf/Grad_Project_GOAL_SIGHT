import copy
import json
from pathlib import Path
from typing import Any, Dict, List

import numpy as np

import config
from camera_movement_estimator import CameraMovementEstimator
from identity_mapper import IdentityMapper
from team_assigner import TeamAssigner
from trackers import Tracker
from utils import read_video
from view_transformer import ViewTransformer


def apply_manual_object_types_to_tracks(tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]]) -> None:
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

        for track_id in to_ignore:
            del player_tracks[track_id]


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
    return tracks


def assign_teams_fast(video_frames: List[np.ndarray], tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]]) -> None:
    team_assigner = TeamAssigner()

    all_player_colors: Dict[Any, List[List[float]]] = {}
    sample_frames = min(10, len(video_frames))

    for frame_idx in range(sample_frames):
        frame = video_frames[frame_idx]
        player_track = tracks["players"][frame_idx]
        for player_id, track in player_track.items():
            bbox = track.get("bbox")
            if bbox is None:
                continue
            color = team_assigner.get_player_color(frame, bbox)
            if color is not None:
                identity_key = track.get("canonical_id", player_id)
                all_player_colors.setdefault(identity_key, []).append(color)

    avg_colors = {pid: np.mean(colors, axis=0) for pid, colors in all_player_colors.items() if colors}
    if avg_colors:
        team_assigner.assign_team_color_from_colors(avg_colors)

    canonical_team_map: Dict[Any, int] = {}
    if team_assigner.kmeans is not None and team_assigner.cluster_to_team is not None:
        for identity_key, color in avg_colors.items():
            color_arr = np.asarray(color, dtype=np.float64).reshape(1, -1)
            cluster_idx = int(team_assigner.kmeans.predict(color_arr)[0])
            team_id = team_assigner.cluster_to_team.get(cluster_idx)
            if team_id in (1, 2):
                canonical_team_map[identity_key] = int(team_id)

    for frame_num, player_track in enumerate(tracks["players"]):
        for player_id, track in player_track.items():
            locked_team = track.get("team") if track.get("identity_locked") else None
            if locked_team in (1, 2):
                team = locked_team
            else:
                identity_key = track.get("canonical_id", player_id)
                team = canonical_team_map.get(identity_key)
            if team is None:
                team = track.get("team") or 1
            tracks["players"][frame_num][player_id]["team"] = team


def count_player_registry_entries(mapper: IdentityMapper) -> int:
    count = 0
    for entry in mapper.player_registry.values():
        if str(entry.object_type).strip().lower() == "player":
            count += 1
    return count


def compute_overmerge_warnings(merge_history: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    warnings: List[Dict[str, Any]] = []
    for item in merge_history:
        gap = int(item.get("gap_frames", 0) or 0)
        distance = float(item.get("distance", 0.0) or 0.0)
        appearance_delta = float(item.get("appearance_delta", 0.0) or 0.0)
        forced = bool(item.get("forced_overflow_merge", False))

        if forced or gap >= 45 or distance >= 35.0 or appearance_delta >= 60.0:
            warnings.append(
                {
                    "source": item.get("source_canonical_id", item.get("fragment_canonical_id")),
                    "target": item.get("target_canonical_id"),
                    "gap_frames": gap,
                    "distance": round(distance, 3),
                    "appearance_delta": round(appearance_delta, 3),
                    "forced_overflow_merge": forced,
                    "score": item.get("score"),
                }
            )
    return warnings


def suspicious_remaining_canonicals(
    mapper: IdentityMapper,
    total_frames: int,
    pass_params: Dict[str, Any],
    top_k: int = 10,
) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    short_life = int(pass_params.get("fragment_short_lifetime_frames", 45))
    low_dist_m = float(pass_params.get("fragment_low_distance_m", 20.0))
    low_dist_px = float(pass_params.get("fragment_low_distance_px", 240.0))

    for canonical_id, stat in mapper.canonical_debug_stats.items():
        if stat.get("merge_target"):
            continue
        entry = mapper.player_registry.get(canonical_id)
        if entry is None or str(entry.object_type).strip().lower() != "player":
            continue

        distance = float(stat.get("total_distance", 0.0) or 0.0)
        frames_seen = int(stat.get("total_frames_seen", 0) or 0)
        first_frame = int(stat.get("first_frame", 0) or 0)
        space = stat.get("distance_space")
        low_dist_threshold = low_dist_m if space == "pitch" else low_dist_px

        low_distance_flag = distance <= low_dist_threshold
        short_life_flag = frames_seen <= short_life
        late_flag = first_frame >= int(total_frames * 0.65)
        weak_flag = (stat.get("team") is None) or (len(stat.get("track_ids", [])) <= 1)

        suspicion_score = int(low_distance_flag) + int(short_life_flag) + int(late_flag) + int(weak_flag)
        if suspicion_score == 0:
            continue

        rows.append(
            {
                "canonical_id": canonical_id,
                "frames_seen": frames_seen,
                "frame_span": int(stat.get("frame_span", 0) or 0),
                "first_frame": first_frame,
                "last_frame": int(stat.get("last_frame", 0) or 0),
                "distance": round(distance, 3),
                "team": stat.get("team"),
                "track_ids": stat.get("track_ids", []),
                "suspicion_score": suspicion_score,
                "flags": {
                    "low_distance": low_distance_flag,
                    "short_lifetime": short_life_flag,
                    "late_appearance": late_flag,
                    "weak_distinct_evidence": weak_flag,
                },
            }
        )

    rows.sort(
        key=lambda r: (
            -r["suspicion_score"],
            r["distance"],
            r["frames_seen"],
            -r["first_frame"],
        )
    )
    return rows[:top_k]


def run_pass(
    pass_name: str,
    pass_params: Dict[str, Any],
    video_frames: List[np.ndarray],
    base_tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]],
) -> Dict[str, Any]:
    tracks = copy.deepcopy(base_tracks)

    mapper = IdentityMapper(video_path=config.VIDEO_PATH, **pass_params)
    mapper.attach_appearance_features(video_frames, tracks)
    mapper.bootstrap_from_tracks(tracks)

    bootstrap_player_canonicals = len(
        {
            cid
            for cid in mapper.default_track_to_canonical.values()
            if cid is not None and str(cid).startswith("player_")
        }
    )

    mapper.load_corrections(str(Path(config.IDENTITY_CORRECTIONS_PATH)))
    mapper.apply_to_tracks(tracks)
    apply_manual_object_types_to_tracks(tracks)

    assign_teams_fast(video_frames, tracks)

    mapper.sync_registry_from_tracks(tracks)
    pre_reconcile_registry_count = count_player_registry_entries(mapper)

    reconciliation = mapper.reconcile_fragments(tracks)
    mapper.apply_to_tracks(tracks)
    apply_manual_object_types_to_tracks(tracks)

    conflicts = mapper.detect_conflicts(tracks)
    summary = mapper.generate_summary(tracks, corrections_path=str(Path(config.IDENTITY_CORRECTIONS_PATH)))

    post_reconcile_registry_count = count_player_registry_entries(mapper)
    created_during_reconcile = max(0, post_reconcile_registry_count - pre_reconcile_registry_count)

    merge_history = summary.get("merge_history", [])
    overmerge_warnings = compute_overmerge_warnings(merge_history)

    result = {
        "pass_name": pass_name,
        "params": pass_params,
        "active_canonical_players": int(summary.get("active_canonical_players", 0)),
        "raw_active_canonical_players": int(summary.get("raw_active_canonical_players", 0)),
        "merged_fragment_count": int(summary.get("merged_fragment_count", 0)),
        "unresolved_fragment_count": int(summary.get("unresolved_fragment_count", 0)),
        "suppressed_fragment_count": int(summary.get("suppressed_fragment_count", 0)),
        "unresolved_conflict_count": int(summary.get("unresolved_conflict_count", 0)),
        "new_canonicals_created": int(bootstrap_player_canonicals + created_during_reconcile),
        "new_canonicals_created_bootstrap": int(bootstrap_player_canonicals),
        "new_canonicals_created_reconcile": int(created_during_reconcile),
        "canonicals_merged": int(reconciliation.get("merged_fragment_count", 0)),
        "overmerge_warning_count": int(len(overmerge_warnings)),
        "overmerge_warnings": overmerge_warnings[:8],
        "suspicious_remaining_canonicals": suspicious_remaining_canonicals(
            mapper,
            total_frames=len(video_frames),
            pass_params=pass_params,
            top_k=12,
        ),
    }
    return result


def main() -> None:
    video_frames = read_video(config.VIDEO_PATH)
    base_tracks = prepare_base(video_frames)

    passes = [
        {
            "name": "baseline_current_mapper",
            "params": {},
        },
        {
            "name": "pass_1_guarded_overflow",
            "params": {
                "fragment_match_gap_frames": 65,
                "fragment_short_lifetime_frames": 65,
                "fragment_small_span_frames": 105,
                "fragment_low_distance_m": 16.0,
                "fragment_low_distance_px": 190.0,
                "fragment_merge_score_threshold": 68.0,
                "appearance_change_threshold": 48.0,
                "fragment_relaxed_gap_multiplier": 3.0,
                "fragment_relaxed_distance_multiplier": 1.7,
                "fragment_relaxed_appearance_multiplier": 1.3,
                "fragment_over_expected_strict_bonus": 8.0,
                "fragment_over_expected_relaxed_bonus": 14.0,
                "fragment_overflow_merge_bonus": 40.0,
                "fragment_suppress_short_lifetime_frames": 8,
                "fragment_suppress_low_distance_m": 2.2,
                "fragment_suppress_low_distance_px": 32.0,
            },
        },
        {
            "name": "pass_2_balanced_merge_suppress",
            "params": {
                "fragment_match_gap_frames": 72,
                "fragment_short_lifetime_frames": 72,
                "fragment_small_span_frames": 112,
                "fragment_low_distance_m": 17.5,
                "fragment_low_distance_px": 205.0,
                "fragment_merge_score_threshold": 72.0,
                "appearance_change_threshold": 52.0,
                "fragment_relaxed_gap_multiplier": 3.5,
                "fragment_relaxed_distance_multiplier": 1.9,
                "fragment_relaxed_appearance_multiplier": 1.35,
                "fragment_over_expected_strict_bonus": 9.0,
                "fragment_over_expected_relaxed_bonus": 16.0,
                "fragment_overflow_merge_bonus": 48.0,
                "fragment_suppress_short_lifetime_frames": 10,
                "fragment_suppress_low_distance_m": 2.5,
                "fragment_suppress_low_distance_px": 36.0,
            },
        },
    ]

    all_results = []
    for item in passes:
        name = item["name"]
        params = item["params"]
        print(f"\\n=== Running {name} ===")
        result = run_pass(name, params, video_frames, base_tracks)
        all_results.append(result)
        print(
            "metrics: "
            f"active={result['active_canonical_players']} "
            f"raw_active={result['raw_active_canonical_players']} "
            f"merged={result['merged_fragment_count']} "
            f"unresolved_fragments={result['unresolved_fragment_count']} "
            f"suppressed_fragments={result['suppressed_fragment_count']} "
            f"conflicts={result['unresolved_conflict_count']} "
            f"new_canonicals={result['new_canonicals_created']} "
            f"merged_count={result['canonicals_merged']} "
            f"overmerge_warnings={result['overmerge_warning_count']}"
        )

    output_path = Path("output_videos/reconciliation_calibration_runs.json")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8") as f:
        json.dump(all_results, f, indent=2, ensure_ascii=False)

    print(f"\\nSaved calibration runs to {output_path}")


if __name__ == "__main__":
    main()
