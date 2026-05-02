"""
Minimal offline UI for semantic object labeling and ID-switch review.

Run with:
    streamlit run correction_ui.py
"""

from __future__ import annotations

import copy
import math
import pickle
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import cv2
import numpy as np
import streamlit as st

try:
    from streamlit_image_coordinates import streamlit_image_coordinates
except ImportError:
    streamlit_image_coordinates = None

import config
from identity_mapper import IdentityMapper
from utils import get_center_of_bbox, get_foot_position, is_valid_bbox
from view_transformer import ViewTransformer


@st.cache_data(show_spinner=False)
def load_video_info(video_path: str) -> Dict[str, Any]:
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        return {"frame_count": 0, "fps": 0.0, "width": 0, "height": 0}

    info = {
        "frame_count": int(cap.get(cv2.CAP_PROP_FRAME_COUNT)),
        "fps": float(cap.get(cv2.CAP_PROP_FPS) or 0.0),
        "width": int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)),
        "height": int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT)),
    }
    cap.release()
    return info


def load_video_frame(video_path: str, frame_index: int):
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        return None

    safe_index = max(0, int(frame_index))
    cap.set(cv2.CAP_PROP_POS_FRAMES, safe_index)
    ok, frame = cap.read()
    cap.release()
    if not ok:
        return None
    return frame


@st.cache_resource(show_spinner=False)
def load_stub_tracks(track_stub_path: str):
    with open(track_stub_path, "rb") as file:
        return pickle.load(file)


def add_positions_to_tracks(tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]]) -> None:
    for object_type, object_tracks in tracks.items():
        for frame_num, frame_tracks in enumerate(object_tracks):
            for track_id, track_info in frame_tracks.items():
                bbox = track_info.get("bbox")
                if not is_valid_bbox(bbox):
                    tracks[object_type][frame_num][track_id]["position"] = None
                    continue

                if object_type == "ball":
                    position = get_center_of_bbox(bbox)
                else:
                    position = get_foot_position(bbox)
                tracks[object_type][frame_num][track_id]["position"] = position


def _has_transformed_positions(tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]]) -> bool:
    for frame_tracks in tracks.get("players", []):
        for track_info in frame_tracks.values():
            pitch_pos = track_info.get("position_transformed")
            if isinstance(pitch_pos, (list, tuple)) and len(pitch_pos) >= 2:
                return True
    return False


def ensure_transformed_positions(tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]]) -> None:
    if _has_transformed_positions(tracks):
        return

    transformer = ViewTransformer(
        pixel_vertices=config.PIXEL_VERTICES,
        pitch_length=config.PITCH_LENGTH,
        pitch_width=config.PITCH_WIDTH,
    )
    transformer.add_transformed_position_to_tracks(tracks)


def build_mapper_context(video_path: str, track_stub_path: str, corrections_path: str):
    raw_tracks = load_stub_tracks(track_stub_path)
    tracks = copy.deepcopy(raw_tracks)
    add_positions_to_tracks(tracks)
    ensure_transformed_positions(tracks)

    mapper = IdentityMapper(video_path=video_path)
    mapper.set_team_labels({"1": config.TEAM_1_NAME, "2": config.TEAM_2_NAME})
    mapper.bootstrap_from_tracks(tracks)
    mapper.load_corrections(corrections_path)
    mapper.apply_to_tracks(tracks)
    suspicious_events = mapper.detect_suspicious_events(tracks)
    conflicts = mapper.detect_conflicts(tracks)
    return tracks, mapper, suspicious_events, conflicts


def frame_options(tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]]) -> List[int]:
    frames_with_players = [
        frame_num
        for frame_num, player_tracks in enumerate(tracks.get("players", []))
        if len(player_tracks) > 0
    ]
    return frames_with_players[: max(1, config.IDENTITY_UI_INITIAL_FRAMES)]


def team_label(team: int) -> str:
    if team == 1:
        return f"Team 1 ({config.TEAM_1_NAME})"
    if team == 2:
        return f"Team 2 ({config.TEAM_2_NAME})"
    return "Unset"


def player_label(track_id: Any, track_info: Dict[str, Any]) -> str:
    object_type = str(track_info.get("object_type", "player")).strip().lower()
    canonical_id = track_info.get("canonical_id")
    display_name = track_info.get("display_name") or canonical_id or f"track_{track_id}"
    jersey = track_info.get("jersey_number")
    team = track_info.get("team")
    jersey_suffix = f" | #{jersey}" if jersey not in (None, "") else ""
    team_suffix = f" | {team_label(int(team))}" if team in (1, 2) else ""
    return f"track {track_id} | {object_type} -> {display_name}{jersey_suffix}{team_suffix}"


def normalize_object_type(object_type: Any) -> str:
    normalized = str(object_type or "player").strip().lower()
    if normalized not in {"player", "referee", "ignore"}:
        return "player"
    return normalized


def bbox_center(bbox: List[float]) -> Tuple[int, int]:
    x1, y1, x2, y2 = normalized_bbox(bbox)
    return ((x1 + x2) // 2, (y1 + y2) // 2)


def normalized_bbox(bbox: List[float]) -> Tuple[int, int, int, int]:
    x1, y1, x2, y2 = [int(v) for v in bbox]
    left, right = sorted((x1, x2))
    top, bottom = sorted((y1, y2))
    return left, top, right, bottom


def track_style(object_type: str, is_selected: bool, is_emphasized: bool) -> Tuple[Tuple[int, int, int], int]:
    if is_selected:
        return (0, 255, 255), 4
    if is_emphasized:
        return (255, 191, 0), 3
    if object_type == "referee":
        return (0, 140, 255), 2
    if object_type == "ignore":
        return (130, 130, 130), 2
    return (60, 180, 75), 2


def resolve_clicked_track_id(
    player_tracks: Dict[Any, Dict[str, Any]],
    click_x: int,
    click_y: int,
    image_width: int,
    image_height: int,
) -> Tuple[Optional[Any], str, Optional[float]]:
    contained: List[Tuple[int, int, Any]] = []
    nearest_track: Optional[Any] = None
    nearest_distance_sq = float("inf")

    for track_id, track_info in player_tracks.items():
        bbox = track_info.get("bbox")
        if not is_valid_bbox(bbox):
            continue

        x1, y1, x2, y2 = normalized_bbox(bbox)
        center_x, center_y = bbox_center(bbox)
        distance_sq = (click_x - center_x) ** 2 + (click_y - center_y) ** 2

        if x1 <= click_x <= x2 and y1 <= click_y <= y2:
            area = max(1, (x2 - x1) * (y2 - y1))
            contained.append((area, distance_sq, track_id))

        if distance_sq < nearest_distance_sq:
            nearest_distance_sq = distance_sq
            nearest_track = track_id

    if contained:
        contained.sort(key=lambda item: (item[0], item[1]))
        resolved = contained[0]
        return resolved[2], "inside_bbox", math.sqrt(resolved[1])

    if nearest_track is None:
        return None, "no_visible_bbox", None

    fallback_threshold_px = max(24.0, 0.035 * math.hypot(image_width, image_height))
    nearest_distance = math.sqrt(nearest_distance_sq)
    if nearest_distance <= fallback_threshold_px:
        return nearest_track, "nearest_center_fallback", nearest_distance

    return None, "outside_fallback_threshold", nearest_distance


def normalized_pitch_position(track_info: Dict[str, Any]) -> Optional[Tuple[float, float]]:
    position = track_info.get("position_transformed")
    if not isinstance(position, (list, tuple, np.ndarray)) or len(position) < 2:
        return None

    try:
        x = float(position[0])
        y = float(position[1])
    except (TypeError, ValueError):
        return None

    if not np.isfinite(x) or not np.isfinite(y):
        return None
    if x < 0 or y < 0 or x > float(config.PITCH_LENGTH) or y > float(config.PITCH_WIDTH):
        return None
    return x, y


def minimap_marker_color(track_info: Dict[str, Any]) -> Tuple[int, int, int]:
    object_type = normalize_object_type(track_info.get("object_type", "player"))
    if object_type == "ignore":
        return (120, 120, 120)
    if object_type == "referee":
        return (0, 220, 255)

    team = track_info.get("team")
    if team == 1:
        return (255, 80, 80)
    if team == 2:
        return (80, 80, 255)
    return (80, 220, 80)


def pitch_to_minimap_xy(
    pitch_x: float,
    pitch_y: float,
    map_width: int,
    map_height: int,
    margin: int,
) -> Tuple[int, int]:
    playable_width = max(1, map_width - 2 * margin)
    playable_height = max(1, map_height - 2 * margin)
    x = margin + int(round((pitch_x / float(config.PITCH_LENGTH)) * playable_width))
    y = margin + int(round((pitch_y / float(config.PITCH_WIDTH)) * playable_height))
    x = min(max(x, margin), margin + playable_width)
    y = min(max(y, margin), margin + playable_height)
    return x, y


def render_pitch_minimap(
    player_tracks: Dict[Any, Dict[str, Any]],
    selected_track_id: Optional[Any],
    width: int = 560,
    height: int = 360,
    margin: int = 24,
) -> Tuple[np.ndarray, Dict[Any, Dict[str, Any]], List[Any]]:
    canvas = np.zeros((height, width, 3), dtype=np.uint8)
    canvas[:] = (28, 92, 42)

    cv2.rectangle(canvas, (margin, margin), (width - margin, height - margin), (255, 255, 255), 2)
    mid_x = (width // 2)
    cv2.line(canvas, (mid_x, margin), (mid_x, height - margin), (255, 255, 255), 2)
    circle_radius = int((9.15 / float(config.PITCH_LENGTH)) * (width - 2 * margin))
    cv2.circle(canvas, (mid_x, height // 2), circle_radius, (230, 230, 230), 2)
    cv2.circle(canvas, (mid_x, height // 2), 3, (255, 255, 255), -1)

    marker_lookup: Dict[Any, Dict[str, Any]] = {}
    missing_pitch_tracks: List[Any] = []

    for track_id, track_info in player_tracks.items():
        pitch_position = normalized_pitch_position(track_info)
        if pitch_position is None:
            missing_pitch_tracks.append(track_id)
            continue

        pitch_x, pitch_y = pitch_position
        marker_x, marker_y = pitch_to_minimap_xy(pitch_x, pitch_y, width, height, margin)
        is_selected = track_id == selected_track_id
        color = minimap_marker_color(track_info)
        radius = 10 if is_selected else 7

        cv2.circle(canvas, (marker_x, marker_y), radius, color, -1)
        cv2.circle(canvas, (marker_x, marker_y), radius + 1, (255, 255, 255), 2)
        if is_selected:
            cv2.circle(canvas, (marker_x, marker_y), radius + 6, (0, 255, 255), 2)

        if bool(track_info.get("identity_locked")):
            cv2.putText(
                canvas,
                "L",
                (marker_x + 8, marker_y - 8),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.45,
                (0, 0, 0),
                2,
                cv2.LINE_AA,
            )
            cv2.putText(
                canvas,
                "L",
                (marker_x + 8, marker_y - 8),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.45,
                (255, 255, 255),
                1,
                cv2.LINE_AA,
            )

        marker_lookup[track_id] = {
            "marker_x": marker_x,
            "marker_y": marker_y,
            "pitch_position": [round(float(pitch_x), 3), round(float(pitch_y), 3)],
        }

    legend_items = [
        ("Team 1", (255, 80, 80)),
        ("Team 2", (80, 80, 255)),
        ("Referee", (0, 220, 255)),
        ("Ignore", (120, 120, 120)),
    ]
    legend_x = margin + 6
    legend_y = height - margin + 6
    for label, color in legend_items:
        cv2.circle(canvas, (legend_x, legend_y), 5, color, -1)
        cv2.putText(canvas, label, (legend_x + 10, legend_y + 4), cv2.FONT_HERSHEY_SIMPLEX, 0.35, (255, 255, 255), 1, cv2.LINE_AA)
        legend_x += 125

    return cv2.cvtColor(canvas, cv2.COLOR_BGR2RGB), marker_lookup, missing_pitch_tracks


def resolve_clicked_minimap_track_id(
    marker_lookup: Dict[Any, Dict[str, Any]],
    click_x: int,
    click_y: int,
    image_width: int,
    image_height: int,
) -> Tuple[Optional[Any], str, Optional[float]]:
    if not marker_lookup:
        return None, "no_pitch_markers", None

    nearest_track: Optional[Any] = None
    nearest_distance_sq = float("inf")
    for track_id, marker in marker_lookup.items():
        marker_x = int(marker.get("marker_x", -1))
        marker_y = int(marker.get("marker_y", -1))
        if marker_x < 0 or marker_y < 0:
            continue
        distance_sq = (click_x - marker_x) ** 2 + (click_y - marker_y) ** 2
        if distance_sq < nearest_distance_sq:
            nearest_distance_sq = distance_sq
            nearest_track = track_id

    if nearest_track is None:
        return None, "no_pitch_markers", None

    nearest_distance = math.sqrt(nearest_distance_sq)
    fallback_threshold_px = max(12.0, 0.03 * math.hypot(image_width, image_height))
    if nearest_distance <= fallback_threshold_px:
        return nearest_track, "nearest_pitch_marker", nearest_distance
    return None, "outside_pitch_marker_threshold", nearest_distance


def render_clickable_minimap_surface(
    minimap_rgb: np.ndarray,
    marker_lookup: Dict[Any, Dict[str, Any]],
    viewer_key: str,
) -> Dict[str, Any]:
    click = streamlit_image_coordinates(
        minimap_rgb,
        key=viewer_key,
        use_column_width="always",
        click_and_drag=False,
        cursor="crosshair",
    )
    if not click:
        return {"has_click": False}

    mapped = map_display_to_image_coords(
        click,
        image_width=minimap_rgb.shape[1],
        image_height=minimap_rgb.shape[0],
    )
    if not mapped:
        return {
            "has_click": True,
            "selected_track_id": None,
            "selection_method": "invalid_click",
            "nearest_distance_px": None,
        }

    resolved_track_id, selection_method, nearest_distance_px = resolve_clicked_minimap_track_id(
        marker_lookup,
        mapped["image_x"],
        mapped["image_y"],
        mapped["image_width"],
        mapped["image_height"],
    )

    return {
        "has_click": True,
        "selected_track_id": resolved_track_id,
        "selection_method": selection_method,
        "nearest_distance_px": nearest_distance_px,
        **mapped,
    }


def map_display_to_image_coords(
    click: Dict[str, Any],
    image_width: int,
    image_height: int,
) -> Optional[Dict[str, Any]]:
    display_x = int(click.get("x", -1))
    display_y = int(click.get("y", -1))
    display_width = int(click.get("width", 0) or 0)
    display_height = int(click.get("height", 0) or 0)

    if display_x < 0 or display_y < 0 or display_width <= 0 or display_height <= 0:
        return None

    scale_x = float(image_width) / float(display_width)
    scale_y = float(image_height) / float(display_height)

    image_x = int(round(display_x * scale_x))
    image_y = int(round(display_y * scale_y))
    image_x = min(max(image_x, 0), max(0, image_width - 1))
    image_y = min(max(image_y, 0), max(0, image_height - 1))

    return {
        "display_x": display_x,
        "display_y": display_y,
        "display_width": display_width,
        "display_height": display_height,
        "image_x": image_x,
        "image_y": image_y,
        "image_width": image_width,
        "image_height": image_height,
        "scale_x": scale_x,
        "scale_y": scale_y,
    }


def annotate_frame(
    frame,
    player_tracks: Dict[Any, Dict[str, Any]],
    selected_track_id: Optional[Any] = None,
    emphasized_track_ids: Optional[List[Any]] = None,
):
    canvas = frame.copy()
    emphasized_track_ids = set(emphasized_track_ids or [])

    for track_id, track_info in player_tracks.items():
        bbox = track_info.get("bbox")
        if not is_valid_bbox(bbox):
            continue

        x1, y1, x2, y2 = normalized_bbox(bbox)
        center_x, center_y = bbox_center(bbox)
        object_type = normalize_object_type(track_info.get("object_type", "player"))
        is_selected = track_id == selected_track_id
        is_emphasized = track_id in emphasized_track_ids
        color, thickness = track_style(object_type, is_selected=is_selected, is_emphasized=is_emphasized)

        cv2.rectangle(canvas, (x1, y1), (x2, y2), color, thickness)
        cv2.circle(canvas, (center_x, center_y), 4, color, -1)

        if object_type == "ignore":
            cv2.line(canvas, (x1, y1), (x2, y2), color, 2)
            cv2.line(canvas, (x1, y2), (x2, y1), color, 2)

        label = player_label(track_id, track_info)
        cv2.rectangle(canvas, (x1, max(0, y1 - 20)), (min(canvas.shape[1] - 1, x1 + 260), y1), color, -1)
        cv2.putText(
            canvas,
            label[:34],
            (x1 + 4, max(14, y1 - 5)),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.45,
            (0, 0, 0),
            1,
            cv2.LINE_AA,
        )

    return cv2.cvtColor(canvas, cv2.COLOR_BGR2RGB)


def initialize_selected_track_state(
    selection_state_key: str,
    frame_state_key: str,
    frame_num: int,
    track_options: List[Any],
    preferred_track_id: Optional[Any] = None,
) -> Optional[Any]:
    if not track_options:
        st.session_state[selection_state_key] = None
        st.session_state[frame_state_key] = frame_num
        return None

    previous_frame = st.session_state.get(frame_state_key)
    current_track = st.session_state.get(selection_state_key)
    if previous_frame != frame_num or current_track not in track_options:
        fallback_track = preferred_track_id if preferred_track_id in track_options else track_options[0]
        st.session_state[selection_state_key] = fallback_track
        st.session_state[frame_state_key] = frame_num

    return st.session_state.get(selection_state_key)


def set_selected_track_state(selection_state_key: str, track_id: Any) -> None:
    st.session_state[selection_state_key] = track_id
    st.session_state["selected_track_id"] = track_id


def render_clickable_track_surface(
    frame,
    player_tracks: Dict[Any, Dict[str, Any]],
    selected_track_id: Optional[Any],
    viewer_key: str,
    emphasized_track_ids: Optional[List[Any]] = None,
) -> Dict[str, Any]:
    rendered = annotate_frame(
        frame,
        player_tracks,
        selected_track_id=selected_track_id,
        emphasized_track_ids=emphasized_track_ids,
    )
    click = streamlit_image_coordinates(
        rendered,
        key=viewer_key,
        use_column_width="always",
        click_and_drag=False,
        cursor="crosshair",
    )
    if not click:
        return {"has_click": False}

    mapped = map_display_to_image_coords(
        click,
        image_width=rendered.shape[1],
        image_height=rendered.shape[0],
    )
    if not mapped:
        return {
            "has_click": True,
            "selected_track_id": None,
            "selection_method": "invalid_click",
            "nearest_distance_px": None,
        }

    resolved_track_id, selection_method, nearest_distance_px = resolve_clicked_track_id(
        player_tracks,
        mapped["image_x"],
        mapped["image_y"],
        mapped["image_width"],
        mapped["image_height"],
    )

    return {
        "has_click": True,
        "selected_track_id": resolved_track_id,
        "selection_method": selection_method,
        "nearest_distance_px": nearest_distance_px,
        **mapped,
    }


def format_click_debug(click_result: Optional[Dict[str, Any]]) -> Dict[str, Any]:
    if not click_result:
        return {"has_click": False}

    return {
        "has_click": bool(click_result.get("has_click", False)),
        "display_coords": [click_result.get("display_x"), click_result.get("display_y")],
        "display_size": [click_result.get("display_width"), click_result.get("display_height")],
        "image_coords": [click_result.get("image_x"), click_result.get("image_y")],
        "image_size": [click_result.get("image_width"), click_result.get("image_height")],
        "scale_xy": [
            round(float(click_result.get("scale_x", 0.0)), 4),
            round(float(click_result.get("scale_y", 0.0)), 4),
        ],
        "selected_track_id": click_result.get("selected_track_id"),
        "selection_method": click_result.get("selection_method"),
        "nearest_distance_px": (
            None
            if click_result.get("nearest_distance_px") is None
            else round(float(click_result.get("nearest_distance_px")), 2)
        ),
    }


def assignment_metadata(
    object_type: str,
    name: str,
    jersey_number: str,
    team: int,
    locked: bool,
    propagate_forward: bool,
) -> Dict[str, Any]:
    object_type = str(object_type).strip().lower()
    metadata: Dict[str, Any] = {
        "object_type": object_type,
        "name": name.strip(),
        "locked": locked,
        "propagate_forward": propagate_forward,
        "source": "manual",
        "identity_confidence": 1.0 if locked else 0.9,
    }

    if object_type == "player":
        metadata["jersey_number"] = jersey_number.strip() or None
        metadata["team"] = team if team in (1, 2) else None
    elif object_type == "referee":
        metadata["jersey_number"] = jersey_number.strip() or None
        metadata["team"] = None
    else:
        metadata["jersey_number"] = None
        metadata["team"] = None

    return metadata


def annotation_anchor_metadata(frame_num: int, track_info: Dict[str, Any]) -> Dict[str, Any]:
    payload: Dict[str, Any] = {
        "initial_frame": int(frame_num),
    }

    pitch_position = normalized_pitch_position(track_info)
    if pitch_position is not None:
        payload["initial_pitch_position"] = [round(float(pitch_position[0]), 3), round(float(pitch_position[1]), 3)]

    image_position = track_info.get("position")
    if not isinstance(image_position, (list, tuple, np.ndarray)) or len(image_position) < 2:
        bbox = track_info.get("bbox")
        if is_valid_bbox(bbox):
            cx, cy = bbox_center(bbox)
            image_position = [cx, cy]

    if isinstance(image_position, (list, tuple, np.ndarray)) and len(image_position) >= 2:
        payload["initial_image_position"] = [
            round(float(image_position[0]), 3),
            round(float(image_position[1]), 3),
        ]

    appearance_signature = track_info.get("appearance_color")
    if isinstance(appearance_signature, (list, tuple, np.ndarray)) and len(appearance_signature) >= 3:
        payload["appearance_signature"] = [
            round(float(appearance_signature[0]), 3),
            round(float(appearance_signature[1]), 3),
            round(float(appearance_signature[2]), 3),
        ]

    return payload


def apply_assignment(
    mapper: IdentityMapper,
    corrections_path: str,
    frame_num: int,
    track_id: Any,
    object_type: str,
    metadata: Dict[str, Any],
):
    canonical_id = mapper.assign_object_annotation(
        frame_num=frame_num,
        track_id=track_id,
        object_type=object_type,
        metadata=metadata,
    )
    mapper.save_corrections(corrections_path)
    return canonical_id


def prefill_values(track_info: Dict[str, Any]) -> Dict[str, Any]:
    object_type = normalize_object_type(track_info.get("object_type", "player"))
    default_name = track_info.get("display_name", "") or ""
    if object_type == "referee" and not default_name:
        default_name = "Referee"

    team = track_info.get("team")
    team_value = int(team) if team in (1, 2) else 0

    return {
        "object_type": object_type,
        "name": default_name,
        "jersey_number": "" if track_info.get("jersey_number") is None else str(track_info.get("jersey_number")),
        "team": team_value,
        "locked": bool(track_info.get("identity_locked", False)),
        "propagate_forward": True,
    }


def render_semantic_annotation_form(form_key: str, defaults: Dict[str, Any]):
    object_type_options = ["player", "referee", "ignore"]
    current_object_type = defaults.get("object_type", "player")
    if current_object_type not in object_type_options:
        current_object_type = "player"

    with st.form(form_key):
        object_type = st.selectbox(
            "Object type",
            options=object_type_options,
            index=object_type_options.index(current_object_type),
        )

        name = defaults.get("name", "")
        jersey_number = defaults.get("jersey_number", "")
        team = defaults.get("team", 0)

        if object_type == "player":
            name = st.text_input("Player name", value=name)
            jersey_number = st.text_input("Jersey number", value=jersey_number)
            team = st.selectbox(
                "Team",
                options=[0, 1, 2],
                index={0: 0, 1: 1, 2: 2}.get(team, 0),
                format_func=team_label,
            )
        elif object_type == "referee":
            default_ref_name = name if name else "Referee"
            name = st.text_input("Referee name", value=default_ref_name)
            include_ref_jersey = st.checkbox(
                "Add optional referee jersey number",
                value=bool(jersey_number),
            )
            if include_ref_jersey:
                jersey_number = st.text_input("Referee jersey number", value=jersey_number)
            else:
                jersey_number = ""
        else:
            name = st.text_input(
                "Optional label",
                value=name,
                help="Ignored tracks are excluded from player analytics.",
            )
            jersey_number = ""
            team = 0

        locked = st.checkbox("Lock identity", value=bool(defaults.get("locked", False)))
        propagate_forward = st.checkbox(
            "Propagate forward on this transient track",
            value=bool(defaults.get("propagate_forward", True)),
        )

        save_btn = st.form_submit_button("Save semantic annotation")

    action_type: Optional[str] = object_type if save_btn else None
    action_label: Optional[str] = "Saved semantic annotation" if save_btn else None

    if action_type is None:
        return None

    metadata = assignment_metadata(
        object_type=action_type,
        name=name,
        jersey_number=jersey_number,
        team=team,
        locked=locked,
        propagate_forward=propagate_forward,
    )
    return {
        "object_type": action_type,
        "metadata": metadata,
        "action_label": action_label,
    }


def _track_sort_key(track_id: Any) -> Tuple[int, str]:
    try:
        return 0, f"{int(track_id):010d}"
    except (TypeError, ValueError):
        return 1, str(track_id)


def _manual_assignments_by_track(manual_assignments: List[Dict[str, Any]]) -> Dict[int, List[Dict[str, Any]]]:
    by_track: Dict[int, List[Dict[str, Any]]] = {}
    for assignment in manual_assignments:
        try:
            track_id = int(assignment.get("track_id"))
            frame_num = int(assignment.get("frame_num"))
        except (TypeError, ValueError):
            continue

        item = dict(assignment)
        item["track_id"] = track_id
        item["frame_num"] = frame_num
        by_track.setdefault(track_id, []).append(item)

    for track_id in by_track:
        by_track[track_id].sort(key=lambda item: int(item.get("frame_num", 0)))
    return by_track


def _resolve_manual_assignment_for_frame(
    assignments_for_track: List[Dict[str, Any]],
    frame_num: int,
) -> Optional[Dict[str, Any]]:
    effective: Optional[Dict[str, Any]] = None
    for assignment in assignments_for_track:
        start_frame = int(assignment.get("frame_num", 0))
        if start_frame > frame_num:
            break

        propagate = bool(assignment.get("propagate_forward", True))
        if frame_num == start_frame or (propagate and start_frame < frame_num):
            effective = assignment

    return effective


def build_initialization_completeness(
    mapper: IdentityMapper,
    tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]],
    initialization_frames: List[int],
) -> Dict[str, Any]:
    assignments_by_track = _manual_assignments_by_track(mapper.manual_assignments)

    frame_summaries: List[Dict[str, Any]] = []
    unresolved_tracks: List[Dict[str, Any]] = []
    total_visible = 0
    total_labeled = 0
    total_type_counts = {"player": 0, "referee": 0, "ignore": 0}

    for frame_num in initialization_frames:
        if frame_num < 0 or frame_num >= len(tracks.get("players", [])):
            continue

        frame_tracks = tracks["players"][frame_num]
        track_ids = sorted(frame_tracks.keys(), key=_track_sort_key)
        visible_count = len(track_ids)
        labeled_count = 0
        type_counts = {"player": 0, "referee": 0, "ignore": 0}
        unlabeled_track_ids: List[Any] = []

        for track_id in track_ids:
            try:
                normalized_track_id = int(track_id)
            except (TypeError, ValueError):
                unlabeled_track_ids.append(track_id)
                continue

            manual_assignment = _resolve_manual_assignment_for_frame(
                assignments_by_track.get(normalized_track_id, []),
                frame_num,
            )
            if manual_assignment is None:
                unlabeled_track_ids.append(track_id)
                continue

            labeled_count += 1
            object_type = normalize_object_type(manual_assignment.get("object_type", "player"))
            type_counts[object_type] += 1
            total_type_counts[object_type] += 1

        unlabeled_count = visible_count - labeled_count
        total_visible += visible_count
        total_labeled += labeled_count
        completeness_pct = 100.0 if visible_count == 0 else (100.0 * labeled_count / visible_count)

        frame_summaries.append(
            {
                "frame": frame_num,
                "visible": visible_count,
                "labeled": labeled_count,
                "unlabeled": unlabeled_count,
                "player": type_counts["player"],
                "referee": type_counts["referee"],
                "ignore": type_counts["ignore"],
                "complete_pct": round(completeness_pct, 1),
            }
        )

        if unlabeled_track_ids:
            unresolved_tracks.append(
                {
                    "frame": frame_num,
                    "track_ids": unlabeled_track_ids,
                }
            )

    overall_pct = 100.0 if total_visible == 0 else (100.0 * total_labeled / total_visible)
    return {
        "frame_summaries": frame_summaries,
        "unresolved_tracks": unresolved_tracks,
        "visible_total": total_visible,
        "labeled_total": total_labeled,
        "unlabeled_total": max(0, total_visible - total_labeled),
        "type_counts_total": total_type_counts,
        "overall_complete_pct": round(overall_pct, 1),
    }


def render_initialization_completeness_panel(
    mapper: IdentityMapper,
    tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]],
    initialization_frames: List[int],
) -> None:
    summary = build_initialization_completeness(
        mapper=mapper,
        tracks=tracks,
        initialization_frames=initialization_frames,
    )

    st.caption("Initialization completeness")

    overall_cols = st.columns([1.45, 1.0, 1.0, 1.0, 1.25])
    overall_cols[0].metric(
        "Coverage",
        f"{summary['labeled_total']}/{summary['visible_total']}",
        f"{summary['overall_complete_pct']}%",
    )
    overall_cols[1].metric("Player", str(summary["type_counts_total"]["player"]))
    overall_cols[2].metric("Referee", str(summary["type_counts_total"]["referee"]))
    overall_cols[3].metric("Ignore", str(summary["type_counts_total"]["ignore"]))
    overall_cols[4].metric("Unlabeled", str(summary["unlabeled_total"]))

    st.progress(
        float(summary["overall_complete_pct"]) / 100.0,
        text=f"Overall initialization completeness: {summary['overall_complete_pct']}%",
    )

    if summary["frame_summaries"]:
        frame_table_height = 76 + min(len(summary["frame_summaries"]), 7) * 34
        st.dataframe(
            summary["frame_summaries"],
            use_container_width=True,
            hide_index=True,
            height=frame_table_height,
            column_config={
                "frame": "Frame",
                "visible": "Visible",
                "labeled": "Labeled",
                "unlabeled": "Unlabeled",
                "player": "Player",
                "referee": "Referee",
                "ignore": "Ignore",
                "complete_pct": st.column_config.ProgressColumn(
                    "Complete %",
                    min_value=0,
                    max_value=100,
                    format="%.1f%%",
                ),
            },
        )

    unresolved = summary["unresolved_tracks"]
    is_blocked = summary["unlabeled_total"] > 0
    if is_blocked and st.session_state.get("initialization_ready", False):
        st.session_state["initialization_ready"] = False

    if unresolved:
        unresolved_rows = [
            {
                "frame": item["frame"],
                "unlabeled_count": len(item["track_ids"]),
                "track_ids": ", ".join(str(track_id) for track_id in item["track_ids"]),
            }
            for item in unresolved
        ]
        unresolved_height = 76 + min(len(unresolved_rows), 6) * 34
        st.warning(
            f"Still unlabeled visible tracks: {summary['unlabeled_total']} total across {len(unresolved_rows)} frame(s)."
        )
        st.dataframe(
            unresolved_rows,
            use_container_width=True,
            hide_index=True,
            height=unresolved_height,
            column_config={
                "frame": "Frame",
                "unlabeled_count": "Count",
                "track_ids": "Track IDs",
            },
        )
    else:
        st.success("All visible initialization tracks are labeled.")

    if is_blocked:
        st.caption("Finish is blocked until every visible initialization track has a semantic label.")

    finish_clicked = st.button(
        "Finish initialization",
        key="finish_initialization_button",
        disabled=is_blocked,
        help=(
            "Blocked while unlabeled visible tracks remain."
            if is_blocked
            else "Marks initialization as complete for the current corrections state."
        ),
    )
    if finish_clicked:
        st.session_state["initialization_ready"] = True
        st.success("Initialization complete: all visible tracks across initialization frames are labeled.")

    if st.session_state.get("initialization_ready", False):
        st.caption("Initialization status: ready")


def main():
    st.set_page_config(page_title="Identity Correction UI", layout="wide")
    st.title("Semantic Tracking Annotation")
    st.caption(
        "Define each tracked object semantically (player/referee/ignore). "
        "Canonical identities are created automatically behind the scenes."
    )

    if streamlit_image_coordinates is None:
        st.error("Missing dependency: streamlit-image-coordinates")
        st.code("python -m pip install streamlit-image-coordinates")
        st.stop()

    video_path = st.text_input("Video path", value=config.VIDEO_PATH)
    track_stub_path = st.text_input("Track stub path", value=config.TRACK_STUB_PATH)
    corrections_path = st.text_input("Corrections JSON path", value=config.IDENTITY_CORRECTIONS_PATH)

    if not Path(video_path).exists():
        st.error(f"Video not found: {video_path}")
        return
    if not Path(track_stub_path).exists():
        st.error(f"Track stub not found: {track_stub_path}")
        return

    with st.spinner("Loading frames, tracks, and current corrections..."):
        tracks, mapper, suspicious_events, conflicts = build_mapper_context(
            video_path=video_path,
            track_stub_path=track_stub_path,
            corrections_path=corrections_path,
        )

    video_info = load_video_info(video_path)
    frame_count = max(int(video_info.get("frame_count", 0)), len(tracks.get("players", [])))

    initial_frames = frame_options(tracks)
    debug_click_resolution = st.checkbox(
        "Debug click mapping",
        value=True,
        help="Shows raw click coordinates, mapped image coordinates, and resolution method.",
    )
    st.write(
        f"Loaded {frame_count} frames, {len(mapper.player_registry)} canonical identities, "
        f"{len(suspicious_events)} suspicious events, {len(conflicts)} conflicts."
    )

    initial_tab, suspicious_tab, conflicts_tab = st.tabs(
        ["Initial Assignment", "Suspicious Events", "Conflicts"]
    )

    with initial_tab:
        st.caption(
            "Initialization flow: choose a tracked object in the frame or minimap, "
            "define semantic identity, and save anchors for later ID stability."
        )
        if not initial_frames:
            st.info("No player detections were found in the first frames.")
        else:
            selected_frame = st.selectbox("Frame", options=initial_frames, index=0, key="initial_selected_frame")
            player_tracks = tracks["players"][selected_frame]
            track_options = list(player_tracks.keys())
            selected_frame_img = load_video_frame(video_path, selected_frame)

            if not track_options:
                st.info("No tracks were found in this frame.")
            else:
                selected_track = initialize_selected_track_state(
                    selection_state_key="selected_track_id_initial",
                    frame_state_key="selected_frame_initial",
                    frame_num=selected_frame,
                    track_options=track_options,
                )

                minimap_rgb, marker_lookup, missing_pitch_tracks = render_pitch_minimap(
                    player_tracks=player_tracks,
                    selected_track_id=selected_track,
                )

                frame_col, minimap_col, form_col = st.columns([1.35, 1.15, 1.0])
                with frame_col:
                    st.caption("Frame view (click a person to select)")
                    if selected_frame_img is None:
                        st.warning(f"Could not read frame {selected_frame} from video")
                    else:
                        frame_click = render_clickable_track_surface(
                            selected_frame_img,
                            player_tracks,
                            selected_track_id=selected_track,
                            viewer_key=f"initial_click_surface_{selected_frame}",
                        )
                        if frame_click.get("has_click"):
                            st.session_state["click_debug_initial_frame"] = frame_click
                        clicked_track = frame_click.get("selected_track_id")
                        if clicked_track in track_options and clicked_track != selected_track:
                            set_selected_track_state("selected_track_id_initial", clicked_track)
                            st.rerun()

                with minimap_col:
                    st.caption("Pitch minimap (click marker to select same track)")
                    minimap_click = render_clickable_minimap_surface(
                        minimap_rgb=minimap_rgb,
                        marker_lookup=marker_lookup,
                        viewer_key=f"initial_minimap_surface_{selected_frame}",
                    )
                    if minimap_click.get("has_click"):
                        st.session_state["click_debug_initial_minimap"] = minimap_click
                    clicked_track = minimap_click.get("selected_track_id")
                    if clicked_track in track_options and clicked_track != selected_track:
                        set_selected_track_state("selected_track_id_initial", clicked_track)
                        st.rerun()

                    if not marker_lookup:
                        st.warning("No valid transformed pitch positions found for this frame.")
                    elif selected_track not in marker_lookup:
                        st.info("Selected track has no valid pitch projection in this frame.")

                    if missing_pitch_tracks:
                        st.caption(
                            "Tracks without pitch projection: "
                            + ", ".join(str(track_id) for track_id in sorted(missing_pitch_tracks))
                        )

                with form_col:
                    fallback_track = st.selectbox(
                        "Track selector",
                        options=track_options,
                        index=track_options.index(selected_track) if selected_track in track_options else 0,
                        format_func=lambda track_id: player_label(track_id, player_tracks[track_id]),
                        key=f"initial_fallback_selector_{selected_frame}",
                        help="Use this selector when clicks are ambiguous.",
                    )
                    if fallback_track != selected_track:
                        set_selected_track_state("selected_track_id_initial", fallback_track)
                        st.rerun()

                    selected_info = player_tracks.get(selected_track, {})
                    selected_pitch_anchor = marker_lookup.get(selected_track, {}).get("pitch_position")

                    st.json(
                        {
                            "track_id": selected_track,
                            "object_type": selected_info.get("object_type", "player"),
                            "canonical_id": selected_info.get("canonical_id"),
                            "display_name": selected_info.get("display_name"),
                            "jersey_number": selected_info.get("jersey_number"),
                            "team": selected_info.get("team"),
                            "identity_locked": selected_info.get("identity_locked"),
                            "pitch_position": selected_pitch_anchor,
                            "image_position": selected_info.get("position"),
                            "include_in_player_analytics": selected_info.get("include_in_player_analytics", True),
                        }
                    )

                    if debug_click_resolution:
                        st.caption("Frame click debug")
                        st.json(format_click_debug(st.session_state.get("click_debug_initial_frame")))
                        st.caption("Minimap click debug")
                        st.json(format_click_debug(st.session_state.get("click_debug_initial_minimap")))

                    action = render_semantic_annotation_form(
                        "initial_annotation_form",
                        prefill_values(selected_info),
                    )

                    if action:
                        metadata = dict(action["metadata"])
                        metadata.update(annotation_anchor_metadata(selected_frame, selected_info))
                        if selected_pitch_anchor is not None:
                            metadata["initial_pitch_position"] = selected_pitch_anchor

                        canonical_id = apply_assignment(
                            mapper=mapper,
                            corrections_path=corrections_path,
                            frame_num=selected_frame,
                            track_id=selected_track,
                            object_type=action["object_type"],
                            metadata=metadata,
                        )
                        if canonical_id:
                            st.success(
                                f"{action['action_label']} (canonical_id={canonical_id}) and saved to {corrections_path}"
                            )
                        else:
                            st.success(f"{action['action_label']} and saved to {corrections_path}")
                        st.rerun()

            st.divider()
            render_initialization_completeness_panel(
                mapper=mapper,
                tracks=tracks,
                initialization_frames=initial_frames,
            )

    with suspicious_tab:
        if not suspicious_events:
            st.info("No suspicious events were detected with the current heuristics.")
        else:
            selected_event_index = st.selectbox(
                "Suspicious event",
                options=list(range(len(suspicious_events))),
                format_func=lambda idx: (
                    f"frame {suspicious_events[idx]['frame_num']} | "
                    f"{suspicious_events[idx]['event_type']} | "
                    f"track {suspicious_events[idx]['track_id']}"
                    + (
                        f" -> {suspicious_events[idx]['related_track_id']}"
                        if suspicious_events[idx].get("related_track_id") is not None
                        else ""
                    )
                ),
            )
            event = suspicious_events[selected_event_index]
            event_frame = event["frame_num"]
            event_track_ids = [event["track_id"]]
            if event.get("related_track_id") is not None:
                event_track_ids.append(event["related_track_id"])

            event_frame_img = load_video_frame(video_path, event_frame)
            event_tracks = tracks["players"][event_frame]
            event_track_options = list(event_tracks.keys())
            preferred_track = event["track_id"] if event.get("track_id") in event_track_options else None
            selected_suspicious_track = initialize_selected_track_state(
                selection_state_key="selected_track_id_suspicious",
                frame_state_key="selected_frame_suspicious",
                frame_num=event_frame,
                track_options=event_track_options,
                preferred_track_id=preferred_track,
            )

            frame_cols = st.columns(2 if event.get("reference_frame") is not None else 1)
            with frame_cols[0]:
                if event_frame_img is None:
                    st.warning(f"Could not read event frame {event_frame}")
                else:
                    st.caption("Click the event frame to choose which track to annotate.")
                    click_result = render_clickable_track_surface(
                        event_frame_img,
                        event_tracks,
                        selected_track_id=selected_suspicious_track,
                        viewer_key=f"suspicious_click_surface_{event_frame}_{selected_event_index}",
                        emphasized_track_ids=event_track_ids,
                    )
                    if click_result.get("has_click"):
                        st.session_state["click_debug_suspicious"] = click_result
                    clicked_track = click_result.get("selected_track_id")
                    if clicked_track in event_track_options and clicked_track != selected_suspicious_track:
                        set_selected_track_state("selected_track_id_suspicious", clicked_track)
                        selected_suspicious_track = clicked_track
                        st.rerun()

                if event_track_options:
                    suspicious_fallback_track = st.selectbox(
                        "Fallback track selector",
                        options=event_track_options,
                        index=(
                            event_track_options.index(selected_suspicious_track)
                            if selected_suspicious_track in event_track_options
                            else 0
                        ),
                        format_func=lambda track_id: player_label(track_id, event_tracks[track_id]),
                        key=f"suspicious_fallback_selector_{event_frame}_{selected_event_index}",
                        help="Use this only if click selection is ambiguous.",
                    )
                    if suspicious_fallback_track != selected_suspicious_track:
                        set_selected_track_state("selected_track_id_suspicious", suspicious_fallback_track)
                        selected_suspicious_track = suspicious_fallback_track

            if event.get("reference_frame") is not None:
                reference_frame = event["reference_frame"]
                reference_frame_img = load_video_frame(video_path, reference_frame)
                with frame_cols[1]:
                    if reference_frame_img is None:
                        st.warning(f"Could not read reference frame {reference_frame}")
                    else:
                        st.image(
                            annotate_frame(
                                reference_frame_img,
                                tracks["players"][reference_frame],
                                selected_track_id=event.get("related_track_id"),
                            ),
                            caption=f"Reference frame {reference_frame}",
                            use_container_width=True,
                        )

            st.json(event)
            if debug_click_resolution:
                st.caption("Click resolution debug")
                st.json(format_click_debug(st.session_state.get("click_debug_suspicious")))

            active_event_track_id = (
                selected_suspicious_track
                if selected_suspicious_track in event_tracks
                else event.get("track_id")
            )
            current_track_info = event_tracks.get(active_event_track_id, {})
            related_track_info = {}
            if event.get("reference_frame") is not None and event.get("related_track_id") is not None:
                related_track_info = tracks["players"][event["reference_frame"]].get(event["related_track_id"], {})

            prefill = prefill_values(current_track_info)
            if not prefill.get("name"):
                prefill["name"] = related_track_info.get("display_name", "") or ""
            if not prefill.get("jersey_number"):
                related_jersey = related_track_info.get("jersey_number")
                prefill["jersey_number"] = "" if related_jersey is None else str(related_jersey)
            if prefill.get("team", 0) == 0 and related_track_info.get("team") in (1, 2):
                prefill["team"] = int(related_track_info.get("team"))
            prefill["locked"] = True if prefill.get("object_type", "player") == "player" else prefill.get("locked", False)

            action = render_semantic_annotation_form("suspicious_event_form", prefill)
            if action:
                metadata = dict(action["metadata"])
                metadata.update(annotation_anchor_metadata(event_frame, current_track_info))
                canonical_id = apply_assignment(
                    mapper=mapper,
                    corrections_path=corrections_path,
                    frame_num=event_frame,
                    track_id=active_event_track_id,
                    object_type=action["object_type"],
                    metadata=metadata,
                )
                if canonical_id:
                    st.success(
                        f"{action['action_label']} (canonical_id={canonical_id}) and saved to {corrections_path}"
                    )
                else:
                    st.success(f"{action['action_label']} and saved to {corrections_path}")
                st.rerun()

    with conflicts_tab:
        if not conflicts:
            st.success("No unresolved canonical conflicts detected.")
        else:
            st.error("Resolve these before exporting corrected tracking data.")
            for conflict in conflicts:
                st.json(conflict)


if __name__ == "__main__":
    main()
