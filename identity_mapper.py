from __future__ import annotations

import json
import os
from collections import defaultdict, deque
from dataclasses import asdict, dataclass
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple

import cv2
import numpy as np

from utils import get_center_of_bbox, is_valid_bbox, measure_distance


@dataclass
class PlayerRegistryEntry:
    canonical_id: str
    object_type: str = "player"
    name: str = ""
    jersey_number: Optional[str] = None
    team: Optional[int] = None
    locked: bool = False
    identity_confidence: float = 0.6
    source: str = "auto"
    merge_target: Optional[str] = None

    @property
    def display_name(self) -> str:
        return self.name or self.canonical_id or self.object_type

    def to_dict(self) -> Dict[str, Any]:
        payload = asdict(self)
        payload["display_name"] = self.display_name
        return payload


class IdentityMapper:
    """
    Canonical identity adapter for the offline tracking pipeline.

    Mental model:
    - track_id: transient tracker observation from ByteTrack
    - canonical_id: stable player identity used by downstream analytics
    """

    def __init__(
        self,
        video_path: str = "",
        gap_window_frames: int = 15,
        reappear_distance_threshold_px: float = 85.0,
        reappear_distance_threshold_m: float = 7.5,
        abrupt_jump_threshold_px: float = 120.0,
        abrupt_jump_threshold_m: float = 10.0,
        appearance_change_threshold: float = 46.0,
        manual_propagation_gap_limit: int = 20,
        expected_player_count: int = 22,
        fragment_match_gap_frames: int = 65,
        fragment_short_lifetime_frames: int = 70,
        fragment_small_span_frames: int = 120,
        fragment_low_distance_m: float = 18.0,
        fragment_low_distance_px: float = 210.0,
        fragment_merge_score_threshold: float = 66.0,
        fragment_merge_distance_multiplier: float = 1.25,
        fragment_relaxed_gap_multiplier: float = 2.8,
        fragment_relaxed_distance_multiplier: float = 1.5,
        fragment_relaxed_appearance_multiplier: float = 1.2,
        fragment_over_expected_strict_bonus: float = 8.0,
        fragment_over_expected_relaxed_bonus: float = 12.0,
        fragment_overflow_merge_bonus: float = 34.0,
        fragment_suppress_short_lifetime_frames: int = 10,
        fragment_suppress_low_distance_m: float = 2.2,
        fragment_suppress_low_distance_px: float = 32.0,
        fragment_suppress_late_start_ratio: float = 0.45,
        fragment_suppress_late_max_frames: int = 280,
        fragment_suppress_late_distance_m: float = 28.0,
        fragment_suppress_late_distance_px: float = 300.0,
        switch_confirmation_frames: int = 3,
        locked_switch_confirmation_frames: int = 5,
        switch_min_support: int = 2,
        locked_switch_min_support: int = 3,
        switch_min_confidence: float = 1.0,
        ambiguous_overlap_distance_px: float = 45.0,
        ambiguous_overlap_distance_m: float = 2.8,
        ambiguous_overlap_iou: float = 0.12,
        crossing_min_motion_similarity: float = -0.2,
        crossing_max_appearance_delta: float = 58.0,
        crossing_ambiguity_support_threshold: int = 2,
        locked_crossing_ambiguity_support_threshold: int = 1,
        crossing_confirmation_separated_frames: int = 2,
        crossing_release_iou: float = 0.05,
        crossing_freeze_min_frames: int = 5,
        crossing_release_distance_px: float = 70.0,
        crossing_release_distance_m: float = 4.2,
        post_separation_confirmation_frames: int = 3,
        crossing_state_ttl_frames: int = 18,
        appearance_profile_init_frames: int = 90,
        appearance_profile_history_min_samples: int = 3,
        crossing_appearance_context_frames: int = 8,
        strong_appearance_margin: float = 0.06,
        strong_appearance_support_weight: int = 2,
        identity_stability_debug: bool = True,
    ):
        self.video_path = video_path
        self.gap_window_frames = gap_window_frames
        self.reappear_distance_threshold_px = reappear_distance_threshold_px
        self.reappear_distance_threshold_m = reappear_distance_threshold_m
        self.abrupt_jump_threshold_px = abrupt_jump_threshold_px
        self.abrupt_jump_threshold_m = abrupt_jump_threshold_m
        self.appearance_change_threshold = appearance_change_threshold
        self.manual_propagation_gap_limit = manual_propagation_gap_limit
        self.expected_player_count = expected_player_count
        self.fragment_match_gap_frames = fragment_match_gap_frames
        self.fragment_short_lifetime_frames = fragment_short_lifetime_frames
        self.fragment_small_span_frames = fragment_small_span_frames
        self.fragment_low_distance_m = fragment_low_distance_m
        self.fragment_low_distance_px = fragment_low_distance_px
        self.fragment_merge_score_threshold = fragment_merge_score_threshold
        self.fragment_merge_distance_multiplier = fragment_merge_distance_multiplier
        self.fragment_relaxed_gap_multiplier = fragment_relaxed_gap_multiplier
        self.fragment_relaxed_distance_multiplier = fragment_relaxed_distance_multiplier
        self.fragment_relaxed_appearance_multiplier = fragment_relaxed_appearance_multiplier
        self.fragment_over_expected_strict_bonus = fragment_over_expected_strict_bonus
        self.fragment_over_expected_relaxed_bonus = fragment_over_expected_relaxed_bonus
        self.fragment_overflow_merge_bonus = fragment_overflow_merge_bonus
        self.fragment_suppress_short_lifetime_frames = fragment_suppress_short_lifetime_frames
        self.fragment_suppress_low_distance_m = fragment_suppress_low_distance_m
        self.fragment_suppress_low_distance_px = fragment_suppress_low_distance_px
        self.fragment_suppress_late_start_ratio = fragment_suppress_late_start_ratio
        self.fragment_suppress_late_max_frames = fragment_suppress_late_max_frames
        self.fragment_suppress_late_distance_m = fragment_suppress_late_distance_m
        self.fragment_suppress_late_distance_px = fragment_suppress_late_distance_px
        self.switch_confirmation_frames = max(1, int(switch_confirmation_frames))
        self.locked_switch_confirmation_frames = max(
            self.switch_confirmation_frames,
            int(locked_switch_confirmation_frames),
        )
        self.switch_min_support = max(1, int(switch_min_support))
        self.locked_switch_min_support = max(self.switch_min_support, int(locked_switch_min_support))
        self.switch_min_confidence = float(switch_min_confidence)
        self.ambiguous_overlap_distance_px = float(ambiguous_overlap_distance_px)
        self.ambiguous_overlap_distance_m = float(ambiguous_overlap_distance_m)
        self.ambiguous_overlap_iou = float(max(0.0, min(1.0, ambiguous_overlap_iou)))
        self.crossing_min_motion_similarity = float(np.clip(crossing_min_motion_similarity, -1.0, 1.0))
        self.crossing_max_appearance_delta = float(max(0.0, crossing_max_appearance_delta))
        self.crossing_ambiguity_support_threshold = max(1, int(crossing_ambiguity_support_threshold))
        self.locked_crossing_ambiguity_support_threshold = max(
            1,
            int(locked_crossing_ambiguity_support_threshold),
        )
        self.crossing_confirmation_separated_frames = max(1, int(crossing_confirmation_separated_frames))
        self.crossing_release_iou = float(max(0.0, min(1.0, crossing_release_iou)))
        self.crossing_freeze_min_frames = max(1, int(crossing_freeze_min_frames))
        self.crossing_release_distance_px = max(
            self.ambiguous_overlap_distance_px + 1.0,
            float(crossing_release_distance_px),
        )
        self.crossing_release_distance_m = max(
            self.ambiguous_overlap_distance_m + 0.1,
            float(crossing_release_distance_m),
        )
        self.post_separation_confirmation_frames = max(1, int(post_separation_confirmation_frames))
        self.crossing_state_ttl_frames = max(2, int(crossing_state_ttl_frames))
        self.appearance_profile_init_frames = max(1, int(appearance_profile_init_frames))
        self.appearance_profile_history_min_samples = max(1, int(appearance_profile_history_min_samples))
        self.crossing_appearance_context_frames = max(1, int(crossing_appearance_context_frames))
        self.strong_appearance_margin = float(max(0.01, strong_appearance_margin))
        self.strong_appearance_support_weight = max(1, int(strong_appearance_support_weight))
        self.identity_stability_debug = bool(identity_stability_debug)

        self.frame_track_to_canonical: Dict[int, Dict[int, str]] = defaultdict(dict)
        self.default_track_to_canonical: Dict[int, str] = {}
        self.frame_track_to_object_type: Dict[int, Dict[int, str]] = defaultdict(dict)
        self.default_track_to_object_type: Dict[int, str] = {}
        self.track_frames: Dict[int, List[int]] = defaultdict(list)
        self.player_registry: Dict[str, PlayerRegistryEntry] = {}
        self.manual_assignments: List[Dict[str, Any]] = []
        self.suspicious_events: List[Dict[str, Any]] = []
        self.conflicts: List[Dict[str, Any]] = []
        self.canonical_merge_map: Dict[str, str] = {}
        self.merge_history: List[Dict[str, Any]] = []
        self.unresolved_fragments: List[Dict[str, Any]] = []
        self.canonical_debug_stats: Dict[str, Dict[str, Any]] = {}
        self.reconciliation_summary: Dict[str, Any] = {}
        self.identity_stability_logs: List[Dict[str, Any]] = []
        self.team_labels: Dict[str, str] = {"1": "Team 1", "2": "Team 2"}
        self.canonical_anchor_state: Dict[str, Dict[str, Any]] = {}
        self.corrections_path: Optional[str] = None
        self._next_player_index = 1
        self._next_ref_index = 1

    def _normalize_track_id(self, track_id: Any) -> int:
        if isinstance(track_id, (np.integer, int)):
            return int(track_id)
        return int(track_id)

    def _normalize_object_type(self, object_type: Optional[str]) -> str:
        normalized = str(object_type or "player").strip().lower()
        if normalized not in {"player", "referee", "ignore"}:
            return "player"
        return normalized

    def set_team_labels(self, teams: Optional[Dict[Any, Any]]) -> None:
        if not isinstance(teams, dict):
            return

        normalized: Dict[str, str] = {}
        for key, value in teams.items():
            if value is None:
                continue
            normalized[str(key)] = str(value)

        if normalized:
            self.team_labels.update(normalized)

    def _infer_object_type_from_canonical(self, canonical_id: Optional[str]) -> str:
        if not canonical_id:
            return "player"
        canonical_id = str(canonical_id)
        if canonical_id.startswith("ref_"):
            return "referee"
        if canonical_id.startswith("player_"):
            return "player"
        return "player"

    def _ensure_registry_entry(
        self,
        canonical_id: str,
        metadata: Optional[Dict[str, Any]] = None,
        source: str = "auto",
    ) -> PlayerRegistryEntry:
        metadata = metadata or {}
        object_type = self._normalize_object_type(
            metadata.get("object_type", self._infer_object_type_from_canonical(canonical_id))
        )

        if canonical_id not in self.player_registry:
            self.player_registry[canonical_id] = PlayerRegistryEntry(
                canonical_id=canonical_id,
                object_type=object_type,
                source=source,
                identity_confidence=1.0 if source == "manual" else 0.6,
            )

        entry = self.player_registry[canonical_id]
        entry.object_type = object_type

        if "name" in metadata and metadata["name"] is not None:
            entry.name = str(metadata["name"]).strip()
        if "display_name" in metadata and metadata["display_name"] and not entry.name:
            entry.name = str(metadata["display_name"]).strip()
        if "jersey_number" in metadata and metadata["jersey_number"] not in (None, ""):
            entry.jersey_number = str(metadata["jersey_number"])
        if "team" in metadata and metadata["team"] not in (None, ""):
            entry.team = int(metadata["team"])
        if "locked" in metadata:
            entry.locked = bool(metadata["locked"])
        if "identity_locked" in metadata:
            entry.locked = bool(metadata["identity_locked"])
        if "merge_target" in metadata:
            merge_target = metadata.get("merge_target")
            entry.merge_target = str(merge_target) if merge_target else None
        if entry.object_type != "player":
            # Team assignment is player-only, but referee jersey can be optionally kept.
            entry.team = None
        if entry.object_type == "ignore":
            entry.jersey_number = None
        if "identity_confidence" in metadata and metadata["identity_confidence"] is not None:
            entry.identity_confidence = float(metadata["identity_confidence"])
        elif source == "manual":
            entry.identity_confidence = max(entry.identity_confidence, 0.95 if entry.locked else 0.9)
        entry.source = source if source else entry.source
        return entry

    def _update_next_index(self, canonical_id: str) -> None:
        if canonical_id.startswith("player_"):
            suffix = canonical_id.split("_")[-1]
            if suffix.isdigit():
                self._next_player_index = max(self._next_player_index, int(suffix) + 1)
            return

        if canonical_id.startswith("ref_"):
            suffix = canonical_id.split("_")[-1]
            if suffix.isdigit():
                self._next_ref_index = max(self._next_ref_index, int(suffix) + 1)

    def _resolve_merge_alias(self, canonical_id: Optional[str]) -> Optional[str]:
        if not canonical_id:
            return None

        canonical_id = str(canonical_id)
        visited = set()
        while canonical_id in self.canonical_merge_map:
            if canonical_id in visited:
                break
            visited.add(canonical_id)
            canonical_id = self.canonical_merge_map[canonical_id]
        return canonical_id

    def _manual_canonical_ids(self) -> set:
        manual_ids = set()
        for assignment in self.manual_assignments:
            canonical_id = assignment.get("canonical_id")
            if canonical_id:
                manual_ids.add(str(canonical_id))
        return manual_ids

    def _is_manual_anchor_canonical(self, canonical_id: Optional[str]) -> bool:
        canonical_id = self._resolve_merge_alias(canonical_id)
        if not canonical_id:
            return False

        if canonical_id in self._manual_canonical_ids():
            return True

        entry = self.player_registry.get(canonical_id)
        if entry is None:
            return False
        return bool(entry.locked or str(entry.source).strip().lower() == "manual")

    def _active_player_canonical_ids(self) -> List[str]:
        active_ids = []
        for canonical_id, entry in self.player_registry.items():
            if self._normalize_object_type(entry.object_type) != "player":
                continue
            resolved = self._resolve_merge_alias(canonical_id)
            if resolved != canonical_id:
                continue
            if entry.merge_target:
                continue
            active_ids.append(canonical_id)
        return active_ids

    def create_canonical_id(self, object_type: str = "player") -> str:
        object_type = self._normalize_object_type(object_type)

        if object_type == "referee":
            while True:
                candidate = f"ref_{self._next_ref_index}"
                self._next_ref_index += 1
                if candidate not in self.player_registry:
                    self._ensure_registry_entry(candidate, metadata={"object_type": "referee"})
                    return candidate

        # "ignore" does not produce canonical IDs.
        while True:
            candidate = f"player_{self._next_player_index}"
            self._next_player_index += 1
            if candidate not in self.player_registry:
                self._ensure_registry_entry(candidate, metadata={"object_type": "player"})
                return candidate

    def _distance_threshold_for_space(self, position_space: Optional[str], gap_frames: int) -> float:
        gap_factor = 1.0 + max(0, gap_frames) * 0.06
        if position_space == "pitch":
            return self.fragment_low_distance_m * gap_factor
        return self.fragment_low_distance_px * gap_factor

    def _aggregate_appearance_signature(self, signatures: List[List[float]]) -> Optional[List[float]]:
        if not signatures:
            return None
        arr = np.asarray(signatures, dtype=float)
        if arr.size == 0:
            return None
        return np.median(arr, axis=0).astype(float).tolist()

    def _sanitize_appearance_profile(self, values: Any) -> Optional[np.ndarray]:
        if not isinstance(values, (list, tuple, np.ndarray)):
            return None
        try:
            arr = np.asarray(values, dtype=float).reshape(-1)
        except (TypeError, ValueError):
            return None
        if arr.size < 8 or not np.all(np.isfinite(arr)):
            return None
        norm = float(np.linalg.norm(arr))
        if norm <= 1e-6:
            return None
        return (arr / norm).astype(float)

    def _aggregate_appearance_profile(self, profile_samples: List[List[float]]) -> Optional[List[float]]:
        if not profile_samples:
            return None

        grouped: Dict[int, List[np.ndarray]] = defaultdict(list)
        for sample in profile_samples:
            normalized = self._sanitize_appearance_profile(sample)
            if normalized is None:
                continue
            grouped[int(normalized.shape[0])].append(normalized)

        if not grouped:
            return None

        target_length = max(grouped.keys(), key=lambda key: len(grouped[key]))
        selected_group = grouped[target_length]
        stacked = np.vstack(selected_group)
        centroid = np.median(stacked, axis=0).astype(float)
        centroid_norm = float(np.linalg.norm(centroid))
        if centroid_norm <= 1e-6:
            return None
        centroid = centroid / centroid_norm
        return centroid.tolist()

    def _appearance_profile_similarity(self, first: Any, second: Any) -> Optional[float]:
        first_arr = self._sanitize_appearance_profile(first)
        second_arr = self._sanitize_appearance_profile(second)
        if first_arr is None or second_arr is None:
            return None
        if first_arr.shape[0] != second_arr.shape[0]:
            return None
        return float(np.dot(first_arr, second_arr))

    def _appearance_profile_distance(self, first: Any, second: Any) -> Optional[float]:
        similarity = self._appearance_profile_similarity(first, second)
        if similarity is None:
            return None
        return float(1.0 - similarity)

    def _normalize_position_payload(self, value: Any) -> Optional[List[float]]:
        if not isinstance(value, (list, tuple, np.ndarray)) or len(value) < 2:
            return None
        try:
            x = float(value[0])
            y = float(value[1])
        except (TypeError, ValueError):
            return None
        if not np.isfinite(x) or not np.isfinite(y):
            return None
        return [round(x, 3), round(y, 3)]

    def _upsert_anchor_state(
        self,
        canonical_id: Optional[str],
        metadata: Optional[Dict[str, Any]] = None,
        frame_num: Optional[int] = None,
    ) -> None:
        canonical_id = self._resolve_merge_alias(canonical_id)
        if not canonical_id:
            return

        metadata = metadata or {}
        state = self.canonical_anchor_state.setdefault(canonical_id, {})

        object_type = metadata.get("object_type")
        if object_type is not None:
            state["object_type"] = self._normalize_object_type(object_type)

        if "locked" in metadata:
            state["locked"] = bool(metadata.get("locked"))

        if metadata.get("source"):
            state["source"] = str(metadata.get("source"))

        if metadata.get("name"):
            state["name"] = str(metadata.get("name")).strip()

        if metadata.get("team") in (1, 2):
            state["team"] = int(metadata.get("team"))

        initial_pitch = self._normalize_position_payload(metadata.get("initial_pitch_position"))
        if initial_pitch is not None and not state.get("initial_pitch_position"):
            state["initial_pitch_position"] = initial_pitch

        initial_image = self._normalize_position_payload(metadata.get("initial_image_position"))
        if initial_image is not None and not state.get("initial_image_position"):
            state["initial_image_position"] = initial_image

        initial_frame = metadata.get("initial_frame", frame_num)
        if initial_frame is not None and state.get("initial_frame") is None:
            try:
                state["initial_frame"] = int(initial_frame)
            except (TypeError, ValueError):
                pass

        last_pitch = self._normalize_position_payload(metadata.get("last_pitch_position"))
        if last_pitch is not None:
            state["last_pitch_position"] = last_pitch
            if frame_num is not None:
                state["last_pitch_frame"] = int(frame_num)

    def _build_transient_track_profiles(
        self,
        tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]],
    ) -> Dict[int, Dict[str, Any]]:
        profiles: Dict[int, Dict[str, Any]] = {}

        for frame_num, frame_tracks in enumerate(tracks.get("players", [])):
            for raw_track_id, track_info in frame_tracks.items():
                track_id = self._normalize_track_id(raw_track_id)
                profile = profiles.setdefault(
                    track_id,
                    {
                        "track_id": track_id,
                        "frames": [],
                        "positions": [],
                        "team_votes": defaultdict(int),
                        "appearance_samples": [],
                        "appearance_profile_samples": [],
                    },
                )

                profile["frames"].append(frame_num)
                position, position_space = self._resolve_position(track_info)
                if position is not None:
                    profile["positions"].append((frame_num, position, position_space))

                team = track_info.get("team")
                if team in (1, 2):
                    profile["team_votes"][int(team)] += 1

                appearance = track_info.get("appearance_color")
                if isinstance(appearance, (list, tuple, np.ndarray)) and len(appearance) >= 3:
                    profile["appearance_samples"].append([float(appearance[0]), float(appearance[1]), float(appearance[2])])

                appearance_profile = self._sanitize_appearance_profile(track_info.get("appearance_descriptor"))
                if appearance_profile is not None:
                    profile["appearance_profile_samples"].append(appearance_profile.tolist())

        for profile in profiles.values():
            profile["frames"] = sorted(set(profile["frames"]))
            profile["first_frame"] = profile["frames"][0]
            profile["last_frame"] = profile["frames"][-1]
            profile["total_frames_seen"] = len(profile["frames"])
            profile["frame_span"] = profile["last_frame"] - profile["first_frame"] + 1

            sorted_positions = sorted(profile["positions"], key=lambda item: item[0])
            profile["positions"] = sorted_positions
            if sorted_positions:
                profile["first_position"] = sorted_positions[0][1]
                profile["first_position_space"] = sorted_positions[0][2]
                profile["last_position"] = sorted_positions[-1][1]
                profile["last_position_space"] = sorted_positions[-1][2]
            else:
                profile["first_position"] = None
                profile["first_position_space"] = None
                profile["last_position"] = None
                profile["last_position_space"] = None

            total_distance = 0.0
            previous_position = None
            previous_space = None
            for _, current_position, current_space in sorted_positions:
                if previous_position is not None and previous_space == current_space:
                    total_distance += measure_distance(previous_position, current_position)
                previous_position = current_position
                previous_space = current_space
            profile["total_distance"] = float(total_distance)

            team_votes = profile["team_votes"]
            if team_votes:
                profile["team"] = int(max(team_votes.items(), key=lambda item: item[1])[0])
            else:
                profile["team"] = None

            profile["appearance_signature"] = self._aggregate_appearance_signature(profile["appearance_samples"])
            profile["appearance_profile"] = self._aggregate_appearance_profile(
                profile["appearance_profile_samples"]
            )

        return profiles

    def _merge_track_profile_into_canonical_profile(
        self,
        canonical_profiles: Dict[str, Dict[str, Any]],
        canonical_id: str,
        track_profile: Dict[str, Any],
    ) -> None:
        profile = canonical_profiles.get(canonical_id)
        if profile is None:
            profile = {
                "canonical_id": canonical_id,
                "first_frame": track_profile["first_frame"],
                "last_frame": track_profile["last_frame"],
                "first_position": track_profile.get("first_position"),
                "first_position_space": track_profile.get("first_position_space"),
                "last_position": track_profile.get("last_position"),
                "last_position_space": track_profile.get("last_position_space"),
                "team_votes": defaultdict(int),
                "appearance_samples": [],
                "appearance_profile_samples": [],
                "track_ids": set(),
            }
            canonical_profiles[canonical_id] = profile

        if track_profile["first_frame"] < profile["first_frame"]:
            profile["first_frame"] = track_profile["first_frame"]
            profile["first_position"] = track_profile.get("first_position")
            profile["first_position_space"] = track_profile.get("first_position_space")

        if track_profile["last_frame"] >= profile["last_frame"]:
            profile["last_frame"] = track_profile["last_frame"]
            profile["last_position"] = track_profile.get("last_position")
            profile["last_position_space"] = track_profile.get("last_position_space")

        for team_id, vote_count in track_profile.get("team_votes", {}).items():
            profile["team_votes"][int(team_id)] += int(vote_count)

        appearance_signature = track_profile.get("appearance_signature")
        if appearance_signature is not None:
            profile["appearance_samples"].append(appearance_signature)

        appearance_profile = track_profile.get("appearance_profile")
        if appearance_profile is not None:
            profile["appearance_profile_samples"].append(appearance_profile)

        profile["track_ids"].add(track_profile["track_id"])

        if profile["team_votes"]:
            profile["team"] = int(max(profile["team_votes"].items(), key=lambda item: item[1])[0])
        else:
            profile["team"] = None
        profile["appearance_signature"] = self._aggregate_appearance_signature(profile["appearance_samples"])
        profile["appearance_profile"] = self._aggregate_appearance_profile(
            profile["appearance_profile_samples"]
        )

    def _find_fragment_match_for_bootstrap(
        self,
        track_profile: Dict[str, Any],
        canonical_profiles: Dict[str, Dict[str, Any]],
    ) -> Tuple[Optional[str], Optional[Dict[str, Any]]]:
        best_candidate = None
        best_metrics = None
        best_score = None

        for canonical_id, canonical_profile in canonical_profiles.items():
            gap_frames = track_profile["first_frame"] - canonical_profile["last_frame"]
            if gap_frames <= 0 or gap_frames > self.fragment_match_gap_frames:
                continue

            team_current = track_profile.get("team")
            team_existing = canonical_profile.get("team")
            team_consistent = (
                team_current is None
                or team_existing is None
                or int(team_current) == int(team_existing)
            )
            if not team_consistent:
                continue

            distance = None
            if (
                track_profile.get("first_position") is not None
                and canonical_profile.get("last_position") is not None
                and track_profile.get("first_position_space") == canonical_profile.get("last_position_space")
            ):
                distance = measure_distance(
                    track_profile["first_position"],
                    canonical_profile["last_position"],
                )
                distance_threshold = self._distance_threshold_for_space(
                    track_profile.get("first_position_space"),
                    gap_frames,
                )
                if distance > distance_threshold:
                    continue

            appearance_delta = self._appearance_distance(
                track_profile.get("appearance_signature"),
                canonical_profile.get("appearance_signature"),
            )
            if appearance_delta is not None and appearance_delta > self.appearance_change_threshold:
                continue

            evidence_terms = 0
            hard_evidence_terms = 0
            score = float(gap_frames) * 2.0
            if distance is not None:
                evidence_terms += 1
                hard_evidence_terms += 1
                score += float(distance)
            if appearance_delta is not None:
                evidence_terms += 1
                hard_evidence_terms += 1
                score += float(appearance_delta) * 0.35
            if team_current is not None and team_existing is not None:
                evidence_terms += 1

            if evidence_terms == 0 or hard_evidence_terms == 0:
                continue

            if len(canonical_profiles) >= self.expected_player_count:
                # Soft soccer prior: once we exceed expected on-pitch players,
                # prefer reusing an existing canonical identity when plausible.
                score -= 12.0

            if best_score is None or score < best_score:
                best_score = score
                best_candidate = canonical_id
                best_metrics = {
                    "gap_frames": int(gap_frames),
                    "distance": None if distance is None else round(float(distance), 3),
                    "appearance_delta": None if appearance_delta is None else round(float(appearance_delta), 3),
                    "score": round(float(score), 3),
                }

        if best_candidate is None:
            return None, None

        if best_score is not None and best_score > self.fragment_merge_score_threshold:
            return None, None

        return best_candidate, best_metrics

    def bootstrap_from_tracks(self, tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]]) -> None:
        """Build default canonical mapping with fragment-aware transient reconciliation."""
        self.frame_track_to_canonical = defaultdict(dict)
        self.default_track_to_canonical = {}
        self.frame_track_to_object_type = defaultdict(dict)
        self.default_track_to_object_type = {}
        self.track_frames = defaultdict(list)
        self.player_registry = {}
        self.manual_assignments = []
        self.suspicious_events = []
        self.conflicts = []
        self.canonical_merge_map = {}
        self.merge_history = []
        self.unresolved_fragments = []
        self.canonical_debug_stats = {}
        self.reconciliation_summary = {}
        self.canonical_anchor_state = {}
        self._next_player_index = 1
        self._next_ref_index = 1

        track_profiles = self._build_transient_track_profiles(tracks)
        canonical_profiles: Dict[str, Dict[str, Any]] = {}
        bootstrap_reuse_log: List[Dict[str, Any]] = []
        reused_segments = 0
        created_segments = 0

        ordered_profiles = sorted(
            track_profiles.values(),
            key=lambda profile: (profile["first_frame"], profile["track_id"]),
        )

        for track_profile in ordered_profiles:
            track_id = int(track_profile["track_id"])
            canonical_id, match_metrics = self._find_fragment_match_for_bootstrap(track_profile, canonical_profiles)

            if canonical_id is None:
                canonical_id = self.create_canonical_id(object_type="player")
                created_segments += 1
            else:
                reused_segments += 1
                bootstrap_reuse_log.append(
                    {
                        "track_id": track_id,
                        "canonical_id": canonical_id,
                        "reason": "bootstrap_fragment_match",
                        "metrics": match_metrics or {},
                    }
                )

            self.default_track_to_object_type[track_id] = "player"
            self.default_track_to_canonical[track_id] = canonical_id
            self._ensure_registry_entry(canonical_id, metadata={"object_type": "player"})

            for frame_num in track_profile["frames"]:
                self.frame_track_to_object_type[frame_num][track_id] = "player"
                self.frame_track_to_canonical[frame_num][track_id] = canonical_id
                self.track_frames[track_id].append(frame_num)

            self._merge_track_profile_into_canonical_profile(canonical_profiles, canonical_id, track_profile)

        self.reconciliation_summary = {
            "bootstrap_created_canonical_count": int(created_segments),
            "bootstrap_reused_fragment_count": int(reused_segments),
            "bootstrap_fragment_matches": bootstrap_reuse_log,
        }

    def get_object_type(self, frame_num: int, track_id: Any) -> str:
        track_id = self._normalize_track_id(track_id)
        if track_id in self.frame_track_to_object_type.get(frame_num, {}):
            return self._normalize_object_type(self.frame_track_to_object_type[frame_num][track_id])
        if track_id in self.default_track_to_object_type:
            object_type = self._normalize_object_type(self.default_track_to_object_type[track_id])
            self.frame_track_to_object_type[frame_num][track_id] = object_type
            return object_type
        return "player"

    def get_canonical_id(self, frame_num: int, track_id: Any) -> Optional[str]:
        track_id = self._normalize_track_id(track_id)
        if self.get_object_type(frame_num, track_id) == "ignore":
            return None
        if track_id in self.frame_track_to_canonical.get(frame_num, {}):
            canonical_id = self._resolve_merge_alias(self.frame_track_to_canonical[frame_num][track_id])
            self.frame_track_to_canonical[frame_num][track_id] = canonical_id
            return canonical_id
        if track_id in self.default_track_to_canonical:
            canonical_id = self._resolve_merge_alias(self.default_track_to_canonical[track_id])
            self.default_track_to_canonical[track_id] = canonical_id
            self.frame_track_to_canonical[frame_num][track_id] = canonical_id
            return canonical_id
        return None

    def _propagation_frames(self, track_id: int, start_frame: int, propagate_forward: bool) -> List[int]:
        if not propagate_forward:
            return [start_frame]

        relevant_frames = [frame for frame in self.track_frames.get(track_id, []) if frame >= start_frame]
        if not relevant_frames:
            return [start_frame]

        frames_to_update = []
        previous_frame = None
        manual_anchor_frames = {
            assignment["frame_num"]
            for assignment in self.manual_assignments
            if assignment["track_id"] == track_id and assignment["frame_num"] > start_frame
        }

        for frame in relevant_frames:
            if previous_frame is not None and frame - previous_frame > self.manual_propagation_gap_limit:
                break
            if frame in manual_anchor_frames:
                break
            frames_to_update.append(frame)
            previous_frame = frame

        return frames_to_update or [start_frame]

    def _upsert_manual_assignment(self, assignment: Dict[str, Any]) -> None:
        assignment_key = (assignment["frame_num"], assignment["track_id"])
        self.manual_assignments = [
            item
            for item in self.manual_assignments
            if (item["frame_num"], item["track_id"]) != assignment_key
        ]
        self.manual_assignments.append(assignment)
        self.manual_assignments.sort(key=lambda item: (item["frame_num"], item["track_id"]))

    def _reassign_track_canonical(self, track_id: int, canonical_id: str) -> None:
        self.default_track_to_canonical[track_id] = canonical_id
        for frame_num in self.track_frames.get(track_id, []):
            self.frame_track_to_canonical[frame_num][track_id] = canonical_id

    def _enforce_manual_anchor_consistency(self) -> None:
        manual_anchor_tracks: Dict[str, set] = defaultdict(set)
        for assignment in self.manual_assignments:
            canonical_id = assignment.get("canonical_id")
            object_type = self._normalize_object_type(assignment.get("object_type", "player"))
            if not canonical_id or object_type != "player":
                continue
            canonical_id = self._resolve_merge_alias(str(canonical_id))
            manual_anchor_tracks[canonical_id].add(self._normalize_track_id(assignment["track_id"]))

        if not manual_anchor_tracks:
            return

        track_frame_sets = {
            track_id: set(frames)
            for track_id, frames in self.track_frames.items()
        }

        for canonical_id, anchor_tracks in manual_anchor_tracks.items():
            anchor_frame_union = set()
            for track_id in anchor_tracks:
                anchor_frame_union.update(track_frame_sets.get(track_id, set()))

            for track_id, mapped_canonical in list(self.default_track_to_canonical.items()):
                if self._resolve_merge_alias(mapped_canonical) != canonical_id:
                    continue
                if track_id in anchor_tracks:
                    continue
                if self._normalize_object_type(self.default_track_to_object_type.get(track_id, "player")) != "player":
                    continue

                frame_overlap = bool(track_frame_sets.get(track_id, set()).intersection(anchor_frame_union))
                if not frame_overlap:
                    continue

                replacement_canonical = self.create_canonical_id(object_type="player")
                self._reassign_track_canonical(track_id, replacement_canonical)

    def _enforce_non_overlapping_canonical_segments(self) -> None:
        manual_anchor_tracks: Dict[str, set] = defaultdict(set)
        for assignment in self.manual_assignments:
            canonical_id = assignment.get("canonical_id")
            object_type = self._normalize_object_type(assignment.get("object_type", "player"))
            if not canonical_id or object_type != "player":
                continue
            canonical_id = self._resolve_merge_alias(str(canonical_id))
            manual_anchor_tracks[canonical_id].add(self._normalize_track_id(assignment["track_id"]))

        canonical_to_tracks: Dict[str, List[int]] = defaultdict(list)
        for track_id, canonical_id in self.default_track_to_canonical.items():
            canonical_id = self._resolve_merge_alias(canonical_id)
            if canonical_id is None:
                continue
            if self._normalize_object_type(self.default_track_to_object_type.get(track_id, "player")) != "player":
                continue
            canonical_to_tracks[canonical_id].append(track_id)

        track_frame_sets = {
            track_id: set(frames)
            for track_id, frames in self.track_frames.items()
        }

        for canonical_id, track_ids in canonical_to_tracks.items():
            anchors = manual_anchor_tracks.get(canonical_id, set())
            kept_track_ids: List[int] = []
            kept_frame_sets: List[set] = []

            ordered_track_ids = sorted(
                track_ids,
                key=lambda tid: (
                    0 if tid in anchors else 1,
                    min(track_frame_sets.get(tid, {10**9})),
                    tid,
                ),
            )

            for track_id in ordered_track_ids:
                current_frames = track_frame_sets.get(track_id, set())
                if not current_frames:
                    continue

                overlaps_existing = any(bool(current_frames.intersection(existing_frames)) for existing_frames in kept_frame_sets)
                if overlaps_existing and track_id not in anchors:
                    replacement_canonical = self.create_canonical_id(object_type="player")
                    self._reassign_track_canonical(track_id, replacement_canonical)
                    continue

                kept_track_ids.append(track_id)
                kept_frame_sets.append(current_frames)

    def _find_matching_canonical_id(self, object_type: str, metadata: Dict[str, Any]) -> Optional[str]:
        object_type = self._normalize_object_type(object_type)
        name = str(metadata.get("name") or metadata.get("display_name") or "").strip()
        jersey_number = metadata.get("jersey_number")
        if jersey_number in ("", None):
            jersey_number = None
        else:
            jersey_number = str(jersey_number)
        team = metadata.get("team")
        if team in ("", None):
            team = None
        else:
            team = int(team)

        for canonical_id, entry in self.player_registry.items():
            if self._resolve_merge_alias(canonical_id) != canonical_id:
                continue
            if entry.merge_target:
                continue
            if self._normalize_object_type(entry.object_type) != object_type:
                continue

            if object_type == "player":
                if jersey_number and team is not None and entry.jersey_number == jersey_number and entry.team == team:
                    return canonical_id
                if name and entry.name and entry.name.strip().lower() == name.lower():
                    return canonical_id
            elif object_type == "referee":
                if name and entry.name and entry.name.strip().lower() == name.lower():
                    return canonical_id

        return None

    def assign_object_annotation(
        self,
        frame_num: int,
        track_id: Any,
        object_type: str,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> Optional[str]:
        """
        First-class semantic annotation entrypoint.

        object_type determines downstream behavior:
        - player: canonical player identity (player_N)
        - referee: canonical referee identity (ref_N)
        - ignore: excluded from player analytics
        """
        track_id = self._normalize_track_id(track_id)
        metadata = metadata or {}
        object_type = self._normalize_object_type(object_type)
        propagate_forward = bool(metadata.get("propagate_forward", True))
        source = str(metadata.get("source", "manual"))
        initial_pitch_position = self._normalize_position_payload(metadata.get("initial_pitch_position"))
        initial_image_position = self._normalize_position_payload(metadata.get("initial_image_position"))
        appearance_signature = None
        raw_appearance = metadata.get("appearance_signature")
        if isinstance(raw_appearance, (list, tuple, np.ndarray)) and len(raw_appearance) >= 3:
            try:
                appearance_signature = [
                    round(float(raw_appearance[0]), 3),
                    round(float(raw_appearance[1]), 3),
                    round(float(raw_appearance[2]), 3),
                ]
            except (TypeError, ValueError):
                appearance_signature = None
        try:
            initial_frame = int(metadata.get("initial_frame", frame_num))
        except (TypeError, ValueError):
            initial_frame = int(frame_num)

        if propagate_forward and source == "manual":
            target_frames = [frame for frame in self.track_frames.get(track_id, []) if frame >= frame_num]
            if not target_frames:
                target_frames = [frame_num]
        else:
            target_frames = self._propagation_frames(track_id, frame_num, propagate_forward)
        for target_frame in target_frames:
            self.frame_track_to_object_type[target_frame][track_id] = object_type
        self.default_track_to_object_type[track_id] = object_type

        if object_type == "ignore":
            for target_frame in target_frames:
                self.frame_track_to_canonical[target_frame].pop(track_id, None)

            if source == "manual":
                assignment = {
                    "frame_num": int(frame_num),
                    "track_id": int(track_id),
                    "object_type": "ignore",
                    "canonical_id": None,
                    "name": str(metadata.get("name") or metadata.get("display_name") or "").strip(),
                    "jersey_number": None,
                    "team": None,
                    "locked": bool(metadata.get("locked") or metadata.get("identity_locked")),
                    "propagate_forward": propagate_forward,
                    "initial_pitch_position": initial_pitch_position,
                    "initial_image_position": initial_image_position,
                    "appearance_signature": appearance_signature,
                    "initial_frame": initial_frame,
                    "source": source,
                }
                self._upsert_manual_assignment(assignment)

            self.refresh_event_statuses()
            return None

        canonical_id = metadata.get("canonical_id")
        if canonical_id:
            canonical_id = self._resolve_merge_alias(str(canonical_id))

        if not canonical_id:
            current_canonical = self.frame_track_to_canonical.get(frame_num, {}).get(track_id)
            if current_canonical:
                current_entry = self.player_registry.get(current_canonical)
                if current_entry and self._normalize_object_type(current_entry.object_type) == object_type:
                    canonical_id = current_canonical

        if not canonical_id:
            canonical_id = self._find_matching_canonical_id(object_type, metadata)

        if not canonical_id:
            canonical_id = self.create_canonical_id(object_type=object_type)

        self._update_next_index(canonical_id)
        registry_metadata = dict(metadata)
        registry_metadata["object_type"] = object_type
        entry = self._ensure_registry_entry(canonical_id, registry_metadata, source=source)
        self._upsert_anchor_state(
            canonical_id,
            metadata={
                "object_type": object_type,
                "locked": bool(entry.locked),
                "source": source,
                "name": entry.name,
                "team": entry.team,
                "initial_pitch_position": initial_pitch_position,
                "initial_image_position": initial_image_position,
                "initial_frame": initial_frame,
            },
            frame_num=frame_num,
        )

        for target_frame in target_frames:
            self.frame_track_to_canonical[target_frame][track_id] = canonical_id
        self.default_track_to_canonical[track_id] = canonical_id

        if source == "manual":
            assignment = {
                "frame_num": int(frame_num),
                "track_id": int(track_id),
                "object_type": object_type,
                "canonical_id": canonical_id,
                "name": entry.name,
                "jersey_number": entry.jersey_number if object_type in {"player", "referee"} else None,
                "team": entry.team if object_type == "player" else None,
                "locked": bool(entry.locked),
                "propagate_forward": propagate_forward,
                "initial_pitch_position": initial_pitch_position,
                "initial_image_position": initial_image_position,
                "appearance_signature": appearance_signature,
                "initial_frame": initial_frame,
                "source": source,
            }
            self._upsert_manual_assignment(assignment)

        self.refresh_event_statuses()
        return canonical_id

    def assign_canonical_id(
        self,
        frame_num: int,
        track_id: Any,
        canonical_id: str,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> str:
        """Backward-compatible wrapper for legacy canonical-first callers."""
        metadata = metadata or {}
        object_type = self._normalize_object_type(
            metadata.get("object_type", self._infer_object_type_from_canonical(canonical_id))
        )
        wrapped_metadata = dict(metadata)
        wrapped_metadata["canonical_id"] = canonical_id
        assigned_canonical = self.assign_object_annotation(
            frame_num=frame_num,
            track_id=track_id,
            object_type=object_type,
            metadata=wrapped_metadata,
        )
        return assigned_canonical or ""

    def load_corrections(self, path: str) -> Dict[str, Any]:
        self.corrections_path = path
        if not path or not os.path.exists(path):
            return {}

        with open(path, "r", encoding="utf-8") as file:
            payload = json.load(file)

        self.manual_assignments = []
        self.canonical_merge_map = {}
        self.merge_history = []
        self.unresolved_fragments = []
        self.canonical_debug_stats = {}
        self.reconciliation_summary = {}
        self.canonical_anchor_state = {}

        teams_payload = payload.get("teams")
        if isinstance(teams_payload, dict):
            self.set_team_labels(teams_payload)

        for canonical_id, metadata in payload.get("player_registry", {}).items():
            self._update_next_index(canonical_id)
            merged_metadata = dict(metadata)
            merged_metadata.setdefault("object_type", self._infer_object_type_from_canonical(canonical_id))
            self._ensure_registry_entry(canonical_id, merged_metadata, source="manual")
            self._upsert_anchor_state(canonical_id, merged_metadata)
            merge_target = merged_metadata.get("merge_target")
            if merge_target:
                self.canonical_merge_map[str(canonical_id)] = str(merge_target)

        for canonical_id, anchor_payload in payload.get("canonical_anchor_state", {}).items():
            self._upsert_anchor_state(canonical_id, metadata=anchor_payload)

        annotations = payload.get("annotations")
        if not isinstance(annotations, list):
            annotations = payload.get("assignments", [])

        for assignment in annotations:
            legacy_metadata = assignment.get("metadata", {})
            object_type = self._normalize_object_type(
                assignment.get("object_type")
                or legacy_metadata.get("object_type")
                or self._infer_object_type_from_canonical(assignment.get("canonical_id"))
            )

            merged_metadata = {
                "name": assignment.get("name", legacy_metadata.get("name", legacy_metadata.get("display_name", ""))),
                "jersey_number": assignment.get("jersey_number", legacy_metadata.get("jersey_number")),
                "team": assignment.get("team", legacy_metadata.get("team")),
                "locked": assignment.get("locked", legacy_metadata.get("locked", legacy_metadata.get("identity_locked", False))),
                "identity_confidence": assignment.get("identity_confidence", legacy_metadata.get("identity_confidence")),
                "propagate_forward": assignment.get("propagate_forward", True),
                "initial_pitch_position": assignment.get("initial_pitch_position", legacy_metadata.get("initial_pitch_position")),
                "initial_image_position": assignment.get("initial_image_position", legacy_metadata.get("initial_image_position")),
                "appearance_signature": assignment.get("appearance_signature", legacy_metadata.get("appearance_signature")),
                "initial_frame": assignment.get("initial_frame", assignment.get("frame_num")),
                "source": assignment.get("source", "manual"),
                "object_type": object_type,
            }

            canonical_id = assignment.get("canonical_id")
            if canonical_id is not None:
                merged_metadata["canonical_id"] = str(canonical_id)

            self.assign_object_annotation(
                frame_num=int(assignment["frame_num"]),
                track_id=assignment["track_id"],
                object_type=object_type,
                metadata=merged_metadata,
            )

        self._enforce_manual_anchor_consistency()
        self._enforce_non_overlapping_canonical_segments()

        return payload

    def save_corrections(self, path: str) -> str:
        self.corrections_path = path
        directory = os.path.dirname(path)
        if directory:
            os.makedirs(directory, exist_ok=True)

        annotations = sorted(
            self.manual_assignments,
            key=lambda item: (int(item.get("frame_num", 0)), int(item.get("track_id", 0))),
        )

        payload = {
            "version": 2,
            "video_path": self.video_path,
            "updated_at": datetime.utcnow().isoformat() + "Z",
            "teams": dict(self.team_labels),
            "player_registry": {
                canonical_id: entry.to_dict()
                for canonical_id, entry in sorted(self.player_registry.items())
            },
            "canonical_anchor_state": self.canonical_anchor_state,
            "annotations": annotations,
            "assignments": annotations,
        }

        with open(path, "w", encoding="utf-8") as file:
            json.dump(payload, file, indent=2, ensure_ascii=False)

        return path

    def _clamp_bbox(self, bbox: List[float], width: int, height: int) -> Optional[List[int]]:
        if not is_valid_bbox(bbox):
            return None
        x1, y1, x2, y2 = [int(v) for v in bbox]
        x1 = max(0, min(x1, width - 1))
        x2 = max(0, min(x2, width - 1))
        y1 = max(0, min(y1, height - 1))
        y2 = max(0, min(y2, height - 1))
        if x2 <= x1 or y2 <= y1:
            return None
        return [x1, y1, x2, y2]

    def _extract_appearance_signature(self, frame: np.ndarray, bbox: List[float]) -> Optional[List[float]]:
        if frame is None or frame.size == 0:
            return None

        height, width = frame.shape[:2]
        bbox = self._clamp_bbox(bbox, width, height)
        if bbox is None:
            return None

        x1, y1, x2, y2 = bbox
        crop = frame[y1:y2, x1:x2]
        if crop.size == 0:
            return None

        top_half = crop[: max(1, crop.shape[0] // 2), :]
        hsv = cv2.cvtColor(top_half, cv2.COLOR_BGR2HSV)
        h = hsv[..., 0]
        s = hsv[..., 1]
        v = hsv[..., 2]

        jersey_mask = ((s >= 35) & (v >= 35)) | ((s < 35) & (v > 160))
        grass_mask = (h >= 35) & (h <= 90) & (s >= 40) & (s <= 170) & (v >= 40) & (v <= 220)
        valid_pixels = hsv[jersey_mask & (~grass_mask)]
        if valid_pixels.shape[0] < 25:
            valid_pixels = hsv.reshape(-1, 3)

        signature = np.median(valid_pixels, axis=0)
        return signature.astype(float).tolist()

    def _extract_appearance_descriptor(self, frame: np.ndarray, bbox: List[float]) -> Optional[List[float]]:
        if frame is None or frame.size == 0:
            return None

        height, width = frame.shape[:2]
        bbox = self._clamp_bbox(bbox, width, height)
        if bbox is None:
            return None

        x1, y1, x2, y2 = bbox
        crop = frame[y1:y2, x1:x2]
        if crop.size == 0:
            return None

        upper_body = crop[: max(1, int(crop.shape[0] * 0.65)), :]
        if upper_body.size == 0:
            return None

        hsv = cv2.cvtColor(upper_body, cv2.COLOR_BGR2HSV)
        gray = cv2.cvtColor(upper_body, cv2.COLOR_BGR2GRAY)

        h = hsv[..., 0]
        s = hsv[..., 1]
        v = hsv[..., 2]

        jersey_mask = ((s >= 35) & (v >= 35)) | ((s < 35) & (v > 160))
        grass_mask = (h >= 35) & (h <= 90) & (s >= 40) & (s <= 170) & (v >= 40) & (v <= 220)
        valid_mask = jersey_mask & (~grass_mask)
        if int(np.count_nonzero(valid_mask)) < 36:
            valid_mask = np.ones_like(valid_mask, dtype=bool)

        mask_u8 = (valid_mask.astype(np.uint8) * 255)

        h_hist = cv2.calcHist([hsv], [0], mask_u8, [16], [0, 180]).reshape(-1)
        s_hist = cv2.calcHist([hsv], [1], mask_u8, [8], [0, 256]).reshape(-1)
        v_hist = cv2.calcHist([hsv], [2], mask_u8, [8], [0, 256]).reshape(-1)

        grad_x = cv2.Sobel(gray, cv2.CV_32F, 1, 0, ksize=3)
        grad_y = cv2.Sobel(gray, cv2.CV_32F, 0, 1, ksize=3)
        grad_mag = cv2.magnitude(grad_x, grad_y)
        grad_values = grad_mag[valid_mask]
        if grad_values.size == 0:
            grad_values = grad_mag.reshape(-1)
        texture_hist, _ = np.histogram(
            np.clip(grad_values, 0.0, 255.0),
            bins=8,
            range=(0.0, 256.0),
        )

        descriptor = np.concatenate(
            [
                h_hist.astype(np.float32),
                s_hist.astype(np.float32),
                v_hist.astype(np.float32),
                texture_hist.astype(np.float32),
            ],
            axis=0,
        )
        descriptor_norm = float(np.linalg.norm(descriptor))
        if descriptor_norm <= 1e-6:
            return None

        descriptor = descriptor / descriptor_norm
        return descriptor.astype(float).tolist()

    def attach_appearance_features(
        self,
        video_frames: List[np.ndarray],
        tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]],
    ) -> None:
        for frame_num, player_tracks in enumerate(tracks.get("players", [])):
            if frame_num >= len(video_frames):
                break
            frame = video_frames[frame_num]
            for raw_track_id, track_info in player_tracks.items():
                bbox = track_info.get("bbox")
                if not is_valid_bbox(bbox):
                    continue
                if track_info.get("appearance_color") is None:
                    signature = self._extract_appearance_signature(frame, bbox)
                    if signature is not None:
                        tracks["players"][frame_num][raw_track_id]["appearance_color"] = signature
                if track_info.get("appearance_descriptor") is None:
                    descriptor = self._extract_appearance_descriptor(frame, bbox)
                    if descriptor is not None:
                        tracks["players"][frame_num][raw_track_id]["appearance_descriptor"] = descriptor

    def _resolve_position(self, track_info: Dict[str, Any]) -> Tuple[Optional[Tuple[float, float]], Optional[str]]:
        for key, kind in (("position_transformed", "pitch"), ("position_adjusted", "pixel"), ("position", "pixel")):
            value = track_info.get(key)
            if isinstance(value, (list, tuple, np.ndarray)) and len(value) >= 2:
                return (float(value[0]), float(value[1])), kind

        bbox = track_info.get("bbox")
        center = get_center_of_bbox(bbox) if is_valid_bbox(bbox) else None
        if center is not None:
            return (float(center[0]), float(center[1])), "pixel"

        return None, None

    def _appearance_distance(self, first: Optional[List[float]], second: Optional[List[float]]) -> Optional[float]:
        if first is None or second is None:
            return None

        h1, s1, v1 = [float(value) for value in first]
        h2, s2, v2 = [float(value) for value in second]
        hue_delta = min(abs(h1 - h2), 180.0 - abs(h1 - h2))
        return hue_delta * 1.5 + abs(s1 - s2) * 0.25 + abs(v1 - v2) * 0.1

    def _overlap_distance_for_space(self, position_space: Optional[str]) -> float:
        if position_space == "pitch":
            return self.ambiguous_overlap_distance_m
        return self.ambiguous_overlap_distance_px

    def _release_distance_for_space(self, position_space: Optional[str]) -> float:
        if position_space == "pitch":
            return self.crossing_release_distance_m
        return self.crossing_release_distance_px

    def _resolve_space_position(
        self,
        track_info: Dict[str, Any],
        target_space: str,
    ) -> Optional[Tuple[float, float]]:
        target_space = str(target_space).strip().lower()
        key_order = []
        if target_space == "pitch":
            key_order = ["position_transformed"]
        else:
            key_order = ["position_adjusted", "position"]

        for key in key_order:
            value = track_info.get(key)
            if isinstance(value, (list, tuple, np.ndarray)) and len(value) >= 2:
                try:
                    return float(value[0]), float(value[1])
                except (TypeError, ValueError):
                    continue

        if target_space != "pitch":
            bbox = track_info.get("bbox")
            center = get_center_of_bbox(bbox) if is_valid_bbox(bbox) else None
            if center is not None:
                return float(center[0]), float(center[1])

        return None

    def _bbox_iou(
        self,
        first_bbox: Optional[List[float]],
        second_bbox: Optional[List[float]],
    ) -> Optional[float]:
        if not is_valid_bbox(first_bbox) or not is_valid_bbox(second_bbox):
            return None

        fx1, fy1, fx2, fy2 = [float(value) for value in first_bbox]
        sx1, sy1, sx2, sy2 = [float(value) for value in second_bbox]

        inter_x1 = max(fx1, sx1)
        inter_y1 = max(fy1, sy1)
        inter_x2 = min(fx2, sx2)
        inter_y2 = min(fy2, sy2)
        inter_w = max(0.0, inter_x2 - inter_x1)
        inter_h = max(0.0, inter_y2 - inter_y1)
        inter_area = inter_w * inter_h
        if inter_area <= 0.0:
            return 0.0

        first_area = max(0.0, fx2 - fx1) * max(0.0, fy2 - fy1)
        second_area = max(0.0, sx2 - sx1) * max(0.0, sy2 - sy1)
        union_area = first_area + second_area - inter_area
        if union_area <= 1e-6:
            return None

        return float(inter_area / union_area)

    def _compute_crossing_pair_metrics(
        self,
        first_observation: Dict[str, Any],
        second_observation: Dict[str, Any],
    ) -> Dict[str, Any]:
        image_distance = None
        first_image = first_observation.get("image_position")
        second_image = second_observation.get("image_position")
        if first_image is not None and second_image is not None:
            image_distance = float(measure_distance(first_image, second_image))

        pitch_distance = None
        first_pitch = first_observation.get("pitch_position")
        second_pitch = second_observation.get("pitch_position")
        if first_pitch is not None and second_pitch is not None:
            pitch_distance = float(measure_distance(first_pitch, second_pitch))

        bbox_iou = self._bbox_iou(first_observation.get("bbox"), second_observation.get("bbox"))

        first_team = first_observation.get("team")
        second_team = second_observation.get("team")
        team_consistent = not (
            first_team in (1, 2)
            and second_team in (1, 2)
            and int(first_team) != int(second_team)
        )

        motion_similarity = self._vector_similarity(
            first_observation.get("velocity"),
            second_observation.get("velocity"),
        )
        motion_coherent = motion_similarity is None or motion_similarity >= self.crossing_min_motion_similarity

        appearance_distance = self._appearance_distance(
            first_observation.get("appearance"),
            second_observation.get("appearance"),
        )
        appearance_profile_similarity = self._appearance_profile_similarity(
            first_observation.get("appearance_profile"),
            second_observation.get("appearance_profile"),
        )
        appearance_similar = (
            appearance_distance is None
            or appearance_distance <= self.crossing_max_appearance_delta
        )

        image_close = image_distance is not None and image_distance <= self.ambiguous_overlap_distance_px
        pitch_close = pitch_distance is not None and pitch_distance <= self.ambiguous_overlap_distance_m
        overlap_strong = bbox_iou is not None and bbox_iou >= self.ambiguous_overlap_iou
        locked_pair = bool(first_observation.get("manual_locked") or second_observation.get("manual_locked"))

        support_count = 0
        if image_close:
            support_count += 1
        if pitch_close:
            support_count += 1
        if overlap_strong:
            support_count += 1

        support_threshold = (
            self.locked_crossing_ambiguity_support_threshold
            if locked_pair
            else self.crossing_ambiguity_support_threshold
        )
        start_ambiguity = (
            team_consistent
            and motion_coherent
            and appearance_similar
            and support_count >= support_threshold
        )

        return {
            "image_distance": image_distance,
            "pitch_distance": pitch_distance,
            "bbox_iou": bbox_iou,
            "motion_similarity": motion_similarity,
            "appearance_distance": appearance_distance,
            "appearance_profile_similarity": appearance_profile_similarity,
            "team_consistent": bool(team_consistent),
            "motion_coherent": bool(motion_coherent),
            "appearance_similar": bool(appearance_similar),
            "support_count": int(support_count),
            "support_threshold": int(support_threshold),
            "start_ambiguity": bool(start_ambiguity),
            "locked_pair": bool(locked_pair),
        }

    def _pair_is_separated(self, pair_metrics: Dict[str, Any]) -> bool:
        image_distance = pair_metrics.get("image_distance")
        pitch_distance = pair_metrics.get("pitch_distance")
        bbox_iou = pair_metrics.get("bbox_iou")

        has_measurement = (
            image_distance is not None
            or pitch_distance is not None
            or bbox_iou is not None
        )
        if not has_measurement:
            return False

        image_released = (
            image_distance is None
            or float(image_distance) >= self.crossing_release_distance_px
        )
        pitch_released = (
            pitch_distance is None
            or float(pitch_distance) >= self.crossing_release_distance_m
        )
        overlap_released = (
            bbox_iou is None
            or float(bbox_iou) <= self.crossing_release_iou
        )

        return bool(image_released and pitch_released and overlap_released)

    def _crossing_pair_log_metrics(
        self,
        pair_key: Tuple[int, int],
        pair_metrics: Optional[Dict[str, Any]],
        extra: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        pair_metrics = pair_metrics or {}
        image_distance = pair_metrics.get("image_distance")
        pitch_distance = pair_metrics.get("pitch_distance")
        bbox_iou = pair_metrics.get("bbox_iou")
        motion_similarity = pair_metrics.get("motion_similarity")
        appearance_distance = pair_metrics.get("appearance_distance")
        appearance_profile_similarity = pair_metrics.get("appearance_profile_similarity")

        primary_space = "pitch" if pitch_distance is not None else "pixel"
        primary_distance = pitch_distance if pitch_distance is not None else image_distance

        payload: Dict[str, Any] = {
            "pair_track_ids": [int(pair_key[0]), int(pair_key[1])],
            "distance": None if primary_distance is None else round(float(primary_distance), 3),
            "space": primary_space,
            "image_distance": None if image_distance is None else round(float(image_distance), 3),
            "pitch_distance": None if pitch_distance is None else round(float(pitch_distance), 3),
            "bbox_iou": None if bbox_iou is None else round(float(bbox_iou), 4),
            "motion_similarity": None if motion_similarity is None else round(float(motion_similarity), 3),
            "appearance_distance": (
                None if appearance_distance is None else round(float(appearance_distance), 3)
            ),
            "appearance_profile_similarity": (
                None
                if appearance_profile_similarity is None
                else round(float(appearance_profile_similarity), 4)
            ),
            "support_count": int(pair_metrics.get("support_count", 0) or 0),
            "support_threshold": int(pair_metrics.get("support_threshold", 0) or 0),
            "locked_pair": bool(pair_metrics.get("locked_pair", False)),
        }
        if extra:
            payload.update(extra)
        return payload

    def _update_crossing_appearance_context(
        self,
        pair_key: Tuple[int, int],
        frame_observations: Dict[int, Dict[str, Any]],
        canonical_appearance_profile_lookup: Dict[str, Optional[List[float]]],
        track_appearance_context: Dict[int, Dict[str, Any]],
        frame_num: int,
    ) -> Dict[str, Any]:
        first_track_id, second_track_id = pair_key
        first_observation = frame_observations.get(first_track_id)
        second_observation = frame_observations.get(second_track_id)
        if first_observation is None or second_observation is None:
            return {}

        first_previous = self._resolve_merge_alias(first_observation.get("previous_stable_canonical_id"))
        second_previous = self._resolve_merge_alias(second_observation.get("previous_stable_canonical_id"))
        if not first_previous or not second_previous or first_previous == second_previous:
            return {}

        first_profile = first_observation.get("appearance_profile")
        second_profile = second_observation.get("appearance_profile")

        first_keep = self._appearance_profile_similarity(
            first_profile,
            canonical_appearance_profile_lookup.get(first_previous),
        )
        first_swap = self._appearance_profile_similarity(
            first_profile,
            canonical_appearance_profile_lookup.get(second_previous),
        )
        second_keep = self._appearance_profile_similarity(
            second_profile,
            canonical_appearance_profile_lookup.get(second_previous),
        )
        second_swap = self._appearance_profile_similarity(
            second_profile,
            canonical_appearance_profile_lookup.get(first_previous),
        )

        updates: Dict[int, float] = {}
        first_bias = None
        second_bias = None
        if first_keep is not None and first_swap is not None:
            first_bias = float(first_keep - first_swap)
            updates[first_track_id] = first_bias
        if second_keep is not None and second_swap is not None:
            second_bias = float(second_keep - second_swap)
            updates[second_track_id] = second_bias

        for track_id, bias_value in updates.items():
            state = track_appearance_context.get(track_id)
            if state is None:
                state = {
                    "ema_bias": float(np.clip(bias_value, -1.0, 1.0)),
                    "samples": 1,
                }
            else:
                previous_bias = float(state.get("ema_bias", 0.0))
                smoothed_bias = previous_bias * 0.65 + float(bias_value) * 0.35
                state["ema_bias"] = float(np.clip(smoothed_bias, -1.0, 1.0))
                state["samples"] = int(state.get("samples", 0)) + 1

            state["expires_frame"] = int(frame_num + self.crossing_appearance_context_frames)
            state["pair_key"] = [int(pair_key[0]), int(pair_key[1])]
            track_appearance_context[track_id] = state

        def _vote_label(bias: Optional[float]) -> Optional[str]:
            if bias is None:
                return None
            if bias >= self.strong_appearance_margin:
                return "keep"
            if bias <= -self.strong_appearance_margin:
                return "swap"
            return "neutral"

        return {
            "appearance_context_first_bias": None if first_bias is None else round(float(first_bias), 4),
            "appearance_context_second_bias": None if second_bias is None else round(float(second_bias), 4),
            "appearance_context_first_vote": _vote_label(first_bias),
            "appearance_context_second_vote": _vote_label(second_bias),
        }

    def _pitch_continuity_limit(self, frame_gap: int, locked: bool = False) -> float:
        base_limit = max(2.0, float(self.abrupt_jump_threshold_m))
        gap_factor = 1.0 + min(10, max(0, int(frame_gap) - 1)) * 0.12
        if locked:
            gap_factor *= 0.9
        return float(base_limit * gap_factor)

    def _canonical_pitch_anchor(
        self,
        canonical_id: Optional[str],
        canonical_runtime_state: Optional[Dict[str, Dict[str, Any]]] = None,
    ) -> Optional[Tuple[float, float]]:
        canonical_id = self._resolve_merge_alias(canonical_id)
        if not canonical_id:
            return None

        runtime_state = {}
        if canonical_runtime_state is not None:
            runtime_state = canonical_runtime_state.get(canonical_id, {})
        runtime_position = runtime_state.get("position")
        runtime_space = runtime_state.get("position_space")
        if isinstance(runtime_position, (list, tuple, np.ndarray)) and len(runtime_position) >= 2 and runtime_space == "pitch":
            try:
                return float(runtime_position[0]), float(runtime_position[1])
            except (TypeError, ValueError):
                pass

        anchor_state = self.canonical_anchor_state.get(canonical_id, {})
        for anchor_key in ("last_pitch_position", "initial_pitch_position"):
            normalized = self._normalize_position_payload(anchor_state.get(anchor_key))
            if normalized is not None:
                return float(normalized[0]), float(normalized[1])
        return None

    def _evaluate_pitch_switch_guard(
        self,
        previous_canonical_id: str,
        candidate_canonical_id: str,
        observation: Dict[str, Any],
        canonical_runtime_state: Dict[str, Dict[str, Any]],
        previous_locked: bool,
    ) -> Dict[str, Any]:
        obs_position = observation.get("position")
        obs_space = observation.get("position_space")
        if obs_position is None or obs_space != "pitch":
            return {"blocked": False, "reason": None, "metrics": {}}

        previous_anchor = self._canonical_pitch_anchor(previous_canonical_id, canonical_runtime_state)
        candidate_anchor = self._canonical_pitch_anchor(candidate_canonical_id, canonical_runtime_state)
        if candidate_anchor is None:
            return {"blocked": False, "reason": None, "metrics": {}}

        frame_gap = max(1, int(observation.get("frame_gap", 1) or 1))
        continuity_limit = self._pitch_continuity_limit(frame_gap=frame_gap, locked=previous_locked)
        previous_anchor_distance = None
        if previous_anchor is not None:
            previous_anchor_distance = float(measure_distance(obs_position, previous_anchor))
        candidate_anchor_distance = float(measure_distance(obs_position, candidate_anchor))

        metrics = {
            "position_space": obs_space,
            "frame_gap": int(frame_gap),
            "continuity_limit": round(float(continuity_limit), 3),
            "previous_anchor_distance": (
                None if previous_anchor_distance is None else round(float(previous_anchor_distance), 3)
            ),
            "candidate_anchor_distance": round(float(candidate_anchor_distance), 3),
        }

        if candidate_anchor_distance > continuity_limit:
            previous_is_plausible = (
                previous_anchor_distance is not None
                and previous_anchor_distance <= continuity_limit
            )
            if previous_locked or previous_is_plausible:
                return {
                    "blocked": True,
                    "reason": "candidate_impossible_pitch_jump",
                    "metrics": metrics,
                }

        if (
            previous_anchor_distance is not None
            and candidate_anchor_distance > previous_anchor_distance + 1.0
        ):
            return {
                "blocked": True,
                "reason": "anchor_continuity_prefers_previous",
                "metrics": metrics,
            }

        return {"blocked": False, "reason": None, "metrics": metrics}

    def _vector_similarity(
        self,
        first: Optional[Tuple[float, float]],
        second: Optional[Tuple[float, float]],
    ) -> Optional[float]:
        if first is None or second is None:
            return None
        first_arr = np.asarray(first, dtype=float)
        second_arr = np.asarray(second, dtype=float)
        first_norm = float(np.linalg.norm(first_arr))
        second_norm = float(np.linalg.norm(second_arr))
        if first_norm <= 1e-6 or second_norm <= 1e-6:
            return None
        return float(np.dot(first_arr, second_arr) / (first_norm * second_norm))

    def _canonical_runtime_team(
        self,
        canonical_id: str,
        canonical_team_lookup: Dict[str, Optional[int]],
        canonical_runtime_state: Dict[str, Dict[str, Any]],
    ) -> Optional[int]:
        runtime_team = canonical_runtime_state.get(canonical_id, {}).get("team")
        if runtime_team in (1, 2):
            return int(runtime_team)
        static_team = canonical_team_lookup.get(canonical_id)
        if static_team in (1, 2):
            return int(static_team)
        entry = self.player_registry.get(canonical_id)
        if entry and entry.team in (1, 2):
            return int(entry.team)
        return None

    def _canonical_runtime_appearance(
        self,
        canonical_id: str,
        canonical_appearance_lookup: Dict[str, Optional[List[float]]],
        canonical_runtime_state: Dict[str, Dict[str, Any]],
    ) -> Optional[List[float]]:
        runtime_appearance = canonical_runtime_state.get(canonical_id, {}).get("appearance")
        if runtime_appearance is not None:
            return runtime_appearance
        return canonical_appearance_lookup.get(canonical_id)

    def _canonical_runtime_appearance_profile(
        self,
        canonical_id: str,
        canonical_appearance_profile_lookup: Dict[str, Optional[List[float]]],
        canonical_runtime_state: Dict[str, Dict[str, Any]],
    ) -> Optional[List[float]]:
        runtime_profile = canonical_runtime_state.get(canonical_id, {}).get("appearance_profile")
        if runtime_profile is not None:
            return runtime_profile
        return canonical_appearance_profile_lookup.get(canonical_id)

    def _compute_switch_evidence(
        self,
        previous_canonical_id: str,
        candidate_canonical_id: str,
        observation: Dict[str, Any],
        canonical_runtime_state: Dict[str, Dict[str, Any]],
        canonical_team_lookup: Dict[str, Optional[int]],
        canonical_appearance_lookup: Dict[str, Optional[List[float]]],
        canonical_appearance_profile_lookup: Dict[str, Optional[List[float]]],
        previous_locked: bool = False,
        strong_appearance_mode: bool = False,
        appearance_context_bias: Optional[float] = None,
    ) -> Dict[str, Any]:
        support_count = 0
        against_count = 0

        distance_prev = None
        distance_candidate = None
        velocity_prev = None
        velocity_candidate = None
        appearance_prev = None
        appearance_candidate = None
        appearance_profile_similarity_prev = None
        appearance_profile_similarity_candidate = None
        anchor_prev_distance = None
        anchor_candidate_distance = None
        continuity_limit = None
        candidate_impossible_jump = False

        obs_position = observation.get("position")
        obs_space = observation.get("position_space")

        previous_state = canonical_runtime_state.get(previous_canonical_id, {})
        candidate_state = canonical_runtime_state.get(candidate_canonical_id, {})

        prev_position = previous_state.get("position")
        prev_space = previous_state.get("position_space")
        cand_position = candidate_state.get("position")
        cand_space = candidate_state.get("position_space")

        if (
            obs_position is not None
            and prev_position is not None
            and cand_position is not None
            and obs_space is not None
            and obs_space == prev_space
            and obs_space == cand_space
        ):
            distance_prev = float(measure_distance(obs_position, prev_position))
            distance_candidate = float(measure_distance(obs_position, cand_position))
            distance_margin = 0.6 if obs_space == "pitch" else 12.0
            if distance_candidate + distance_margin < distance_prev:
                support_count += 1
            elif distance_prev + distance_margin < distance_candidate:
                against_count += 1

        obs_velocity = observation.get("velocity")
        previous_velocity = previous_state.get("velocity")
        candidate_velocity = candidate_state.get("velocity")
        velocity_prev = self._vector_similarity(obs_velocity, previous_velocity)
        velocity_candidate = self._vector_similarity(obs_velocity, candidate_velocity)
        if velocity_prev is not None and velocity_candidate is not None:
            if velocity_candidate > velocity_prev + 0.2:
                support_count += 1
            elif velocity_prev > velocity_candidate + 0.2:
                against_count += 1

        obs_appearance = observation.get("appearance")
        previous_appearance = self._canonical_runtime_appearance(
            previous_canonical_id,
            canonical_appearance_lookup,
            canonical_runtime_state,
        )
        candidate_appearance = self._canonical_runtime_appearance(
            candidate_canonical_id,
            canonical_appearance_lookup,
            canonical_runtime_state,
        )
        appearance_prev = self._appearance_distance(obs_appearance, previous_appearance)
        appearance_candidate = self._appearance_distance(obs_appearance, candidate_appearance)
        if appearance_prev is not None and appearance_candidate is not None:
            appearance_margin = 3.0
            if appearance_candidate + appearance_margin < appearance_prev:
                support_count += 1
            elif appearance_prev + appearance_margin < appearance_candidate:
                against_count += 1

        obs_appearance_profile = observation.get("appearance_profile")
        previous_appearance_profile = self._canonical_runtime_appearance_profile(
            previous_canonical_id,
            canonical_appearance_profile_lookup,
            canonical_runtime_state,
        )
        candidate_appearance_profile = self._canonical_runtime_appearance_profile(
            candidate_canonical_id,
            canonical_appearance_profile_lookup,
            canonical_runtime_state,
        )
        appearance_profile_similarity_prev = self._appearance_profile_similarity(
            obs_appearance_profile,
            previous_appearance_profile,
        )
        appearance_profile_similarity_candidate = self._appearance_profile_similarity(
            obs_appearance_profile,
            candidate_appearance_profile,
        )
        if (
            appearance_profile_similarity_prev is not None
            and appearance_profile_similarity_candidate is not None
        ):
            profile_margin = (
                self.strong_appearance_margin
                if strong_appearance_mode
                else max(0.1, self.strong_appearance_margin + 0.04)
            )
            profile_weight = self.strong_appearance_support_weight if strong_appearance_mode else 1
            if appearance_profile_similarity_candidate > appearance_profile_similarity_prev + profile_margin:
                support_count += profile_weight
            elif appearance_profile_similarity_prev > appearance_profile_similarity_candidate + profile_margin:
                against_count += profile_weight

        normalized_context_bias = None
        if appearance_context_bias is not None:
            normalized_context_bias = float(np.clip(float(appearance_context_bias), -1.0, 1.0))
            if strong_appearance_mode:
                if normalized_context_bias >= self.strong_appearance_margin:
                    against_count += self.strong_appearance_support_weight
                elif normalized_context_bias <= -self.strong_appearance_margin:
                    support_count += self.strong_appearance_support_weight

        obs_team = observation.get("team")
        previous_team = self._canonical_runtime_team(
            previous_canonical_id,
            canonical_team_lookup,
            canonical_runtime_state,
        )
        candidate_team = self._canonical_runtime_team(
            candidate_canonical_id,
            canonical_team_lookup,
            canonical_runtime_state,
        )
        if obs_team in (1, 2):
            if candidate_team == int(obs_team) and previous_team != int(obs_team):
                support_count += 1
            elif previous_team == int(obs_team) and candidate_team != int(obs_team):
                against_count += 1

        if obs_position is not None and obs_space == "pitch":
            previous_anchor = self._canonical_pitch_anchor(previous_canonical_id, canonical_runtime_state)
            candidate_anchor = self._canonical_pitch_anchor(candidate_canonical_id, canonical_runtime_state)

            if previous_anchor is not None:
                anchor_prev_distance = float(measure_distance(obs_position, previous_anchor))
            if candidate_anchor is not None:
                anchor_candidate_distance = float(measure_distance(obs_position, candidate_anchor))

            if anchor_prev_distance is not None and anchor_candidate_distance is not None:
                anchor_margin = 0.45
                if anchor_candidate_distance + anchor_margin < anchor_prev_distance:
                    support_count += 1
                elif anchor_prev_distance + anchor_margin < anchor_candidate_distance:
                    against_count += 1

            frame_gap = max(1, int(observation.get("frame_gap", 1) or 1))
            continuity_limit = self._pitch_continuity_limit(frame_gap=frame_gap, locked=previous_locked)
            if anchor_candidate_distance is not None and anchor_candidate_distance > continuity_limit:
                candidate_impossible_jump = True
                against_count += 2

        candidate_confidence = float(support_count) - float(against_count) * 0.8
        return {
            "support_count": int(support_count),
            "against_count": int(against_count),
            "candidate_confidence": round(candidate_confidence, 3),
            "distance_prev": None if distance_prev is None else round(distance_prev, 3),
            "distance_candidate": None if distance_candidate is None else round(distance_candidate, 3),
            "velocity_prev": None if velocity_prev is None else round(float(velocity_prev), 3),
            "velocity_candidate": None if velocity_candidate is None else round(float(velocity_candidate), 3),
            "appearance_prev": None if appearance_prev is None else round(float(appearance_prev), 3),
            "appearance_candidate": None if appearance_candidate is None else round(float(appearance_candidate), 3),
            "appearance_profile_prev_similarity": (
                None
                if appearance_profile_similarity_prev is None
                else round(float(appearance_profile_similarity_prev), 4)
            ),
            "appearance_profile_candidate_similarity": (
                None
                if appearance_profile_similarity_candidate is None
                else round(float(appearance_profile_similarity_candidate), 4)
            ),
            "strong_appearance_mode": bool(strong_appearance_mode),
            "appearance_context_bias": (
                None if normalized_context_bias is None else round(float(normalized_context_bias), 4)
            ),
            "obs_team": None if obs_team not in (1, 2) else int(obs_team),
            "previous_team": previous_team,
            "candidate_team": candidate_team,
            "anchor_prev_distance": None if anchor_prev_distance is None else round(float(anchor_prev_distance), 3),
            "anchor_candidate_distance": (
                None if anchor_candidate_distance is None else round(float(anchor_candidate_distance), 3)
            ),
            "pitch_continuity_limit": None if continuity_limit is None else round(float(continuity_limit), 3),
            "candidate_impossible_jump": bool(candidate_impossible_jump),
        }

    def _log_identity_stability_guard(
        self,
        frame_num: int,
        track_id: int,
        from_canonical_id: Optional[str],
        to_canonical_id: Optional[str],
        reason: str,
        metrics: Optional[Dict[str, Any]] = None,
    ) -> None:
        log_key = (int(frame_num), int(track_id), str(from_canonical_id), str(to_canonical_id), str(reason))
        if not hasattr(self, "_identity_stability_seen"):
            self._identity_stability_seen = set()
        if log_key in self._identity_stability_seen:
            return
        self._identity_stability_seen.add(log_key)

        payload = {
            "frame_num": int(frame_num),
            "track_id": int(track_id),
            "from_canonical_id": from_canonical_id,
            "to_canonical_id": to_canonical_id,
            "reason": str(reason),
            "metrics": metrics or {},
        }
        self.identity_stability_logs.append(payload)
        if len(self.identity_stability_logs) > 500:
            self.identity_stability_logs = self.identity_stability_logs[-500:]

        if self.identity_stability_debug:
            print(
                "[IdentityMapper] "
                f"{reason} frame={frame_num} track={track_id} "
                f"from={from_canonical_id} to={to_canonical_id}"
            )

    def _event_key(self, event_type: str, frame_num: int, track_id: int, related_track_id: Optional[int]) -> Tuple[Any, ...]:
        return (event_type, frame_num, track_id, related_track_id)

    def _add_event(
        self,
        events: List[Dict[str, Any]],
        seen_keys: set,
        event_type: str,
        frame_num: int,
        track_id: int,
        related_track_id: Optional[int],
        description: str,
        metrics: Dict[str, Any],
        reference_frame: Optional[int] = None,
    ) -> None:
        event_key = self._event_key(event_type, frame_num, track_id, related_track_id)
        if event_key in seen_keys:
            return
        seen_keys.add(event_key)

        severity = "high"
        if event_type in {"abrupt_color_change", "sudden_team_flip"}:
            severity = "medium"

        events.append(
            {
                "event_id": f"{event_type}_{frame_num}_{track_id}_{related_track_id or 'na'}",
                "event_type": event_type,
                "frame_num": int(frame_num),
                "track_id": int(track_id),
                "related_track_id": int(related_track_id) if related_track_id is not None else None,
                "reference_frame": int(reference_frame) if reference_frame is not None else None,
                "severity": severity,
                "description": description,
                "metrics": metrics,
                "resolved": False,
                "resolved_canonical_id": None,
            }
        )

    def detect_suspicious_events(self, tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]]) -> List[Dict[str, Any]]:
        events: List[Dict[str, Any]] = []
        seen_keys = set()
        last_seen_by_track: Dict[int, Dict[str, Any]] = {}
        previous_frame_track_ids: set = set()
        recently_disappeared: deque = deque(maxlen=300)

        for frame_num, frame_tracks in enumerate(tracks.get("players", [])):
            normalized_tracks = {}
            for raw_track_id, track_info in frame_tracks.items():
                track_id = self._normalize_track_id(raw_track_id)
                if self.get_object_type(frame_num, track_id) != "player":
                    continue
                normalized_tracks[track_id] = track_info

            current_track_ids = set(normalized_tracks.keys())

            disappeared_track_ids = previous_frame_track_ids - current_track_ids
            for disappeared_track_id in disappeared_track_ids:
                previous_snapshot = last_seen_by_track.get(disappeared_track_id)
                if previous_snapshot is not None:
                    recently_disappeared.append(previous_snapshot)

            for track_id, track_info in normalized_tracks.items():
                position, position_space = self._resolve_position(track_info)
                team = track_info.get("team")
                appearance = track_info.get("appearance_color")
                previous_snapshot = last_seen_by_track.get(track_id)

                if previous_snapshot is not None:
                    gap = frame_num - previous_snapshot["frame_num"]
                    distance = None
                    if (
                        position is not None
                        and previous_snapshot["position"] is not None
                        and position_space == previous_snapshot["position_space"]
                    ):
                        distance = measure_distance(position, previous_snapshot["position"])

                    if distance is not None:
                        distance_threshold = (
                            self.abrupt_jump_threshold_m
                            if position_space == "pitch"
                            else self.abrupt_jump_threshold_px
                        ) * max(1, gap)
                        if gap <= max(2, self.gap_window_frames // 2) and distance > distance_threshold:
                            self._add_event(
                                events=events,
                                seen_keys=seen_keys,
                                event_type="abrupt_position_jump",
                                frame_num=frame_num,
                                track_id=track_id,
                                related_track_id=None,
                                reference_frame=previous_snapshot["frame_num"],
                                description=(
                                    f"Track {track_id} jumped {distance:.2f} "
                                    f"{'m' if position_space == 'pitch' else 'px'} between observations."
                                ),
                                metrics={
                                    "gap_frames": gap,
                                    "distance": round(distance, 3),
                                    "space": position_space,
                                },
                            )

                    appearance_delta = self._appearance_distance(appearance, previous_snapshot["appearance"])
                    if appearance_delta is not None and appearance_delta > self.appearance_change_threshold:
                        self._add_event(
                            events=events,
                            seen_keys=seen_keys,
                            event_type="abrupt_color_change",
                            frame_num=frame_num,
                            track_id=track_id,
                            related_track_id=None,
                            reference_frame=previous_snapshot["frame_num"],
                            description=f"Track {track_id} changed appearance signature abruptly.",
                            metrics={
                                "gap_frames": gap,
                                "appearance_delta": round(appearance_delta, 3),
                            },
                        )

                    previous_team = previous_snapshot["team"]
                    if previous_team is not None and team is not None and int(previous_team) != int(team):
                        self._add_event(
                            events=events,
                            seen_keys=seen_keys,
                            event_type="sudden_team_flip",
                            frame_num=frame_num,
                            track_id=track_id,
                            related_track_id=None,
                            reference_frame=previous_snapshot["frame_num"],
                            description=f"Track {track_id} flipped from team {previous_team} to team {team}.",
                            metrics={
                                "previous_team": int(previous_team),
                                "current_team": int(team),
                            },
                        )

                last_seen_by_track[track_id] = {
                    "track_id": track_id,
                    "frame_num": frame_num,
                    "position": position,
                    "position_space": position_space,
                    "appearance": appearance,
                    "team": int(team) if team is not None else None,
                }

            new_track_ids = current_track_ids - previous_frame_track_ids
            for new_track_id in new_track_ids:
                new_snapshot = last_seen_by_track.get(new_track_id)
                if new_snapshot is None:
                    continue

                best_candidate = None
                best_score = None
                for old_snapshot in list(recently_disappeared):
                    if old_snapshot["track_id"] == new_track_id:
                        continue
                    gap = frame_num - old_snapshot["frame_num"]
                    if gap <= 0 or gap > self.gap_window_frames:
                        continue
                    if new_snapshot["position_space"] != old_snapshot["position_space"]:
                        continue
                    if new_snapshot["position"] is None or old_snapshot["position"] is None:
                        continue

                    distance = measure_distance(new_snapshot["position"], old_snapshot["position"])
                    distance_threshold = (
                        self.reappear_distance_threshold_m
                        if new_snapshot["position_space"] == "pitch"
                        else self.reappear_distance_threshold_px
                    )
                    if distance > distance_threshold:
                        continue

                    appearance_delta = self._appearance_distance(
                        new_snapshot["appearance"], old_snapshot["appearance"]
                    )
                    if appearance_delta is not None and appearance_delta > self.appearance_change_threshold:
                        continue

                    team_consistent = (
                        new_snapshot["team"] is None
                        or old_snapshot["team"] is None
                        or new_snapshot["team"] == old_snapshot["team"]
                    )
                    if not team_consistent:
                        continue

                    candidate_score = distance + (appearance_delta or 0.0) * 0.25 + gap * 2.0
                    if best_score is None or candidate_score < best_score:
                        best_candidate = old_snapshot
                        best_score = candidate_score

                if best_candidate is not None:
                    gap = frame_num - best_candidate["frame_num"]
                    distance = measure_distance(new_snapshot["position"], best_candidate["position"])
                    appearance_delta = self._appearance_distance(
                        new_snapshot["appearance"], best_candidate["appearance"]
                    )
                    self._add_event(
                        events=events,
                        seen_keys=seen_keys,
                        event_type="gap_based_reuse",
                        frame_num=frame_num,
                        track_id=new_track_id,
                        related_track_id=best_candidate["track_id"],
                        reference_frame=best_candidate["frame_num"],
                        description=(
                            f"Track {best_candidate['track_id']} disappeared and track {new_track_id} "
                            f"appeared nearby {gap} frame(s) later."
                        ),
                        metrics={
                            "gap_frames": gap,
                            "distance": round(distance, 3),
                            "space": new_snapshot["position_space"],
                            "appearance_delta": round(appearance_delta, 3)
                            if appearance_delta is not None
                            else None,
                        },
                    )

            previous_frame_track_ids = current_track_ids

        self.suspicious_events = sorted(events, key=lambda event: (event["frame_num"], event["event_type"]))
        self.refresh_event_statuses()
        return self.suspicious_events

    def _build_canonical_stats(
        self,
        tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]],
    ) -> Dict[str, Dict[str, Any]]:
        stats: Dict[str, Dict[str, Any]] = {}

        for frame_num, frame_tracks in enumerate(tracks.get("players", [])):
            for raw_track_id, track_info in frame_tracks.items():
                track_id = self._normalize_track_id(raw_track_id)
                if self.get_object_type(frame_num, track_id) != "player":
                    continue

                canonical_id = track_info.get("canonical_id") or self.get_canonical_id(frame_num, track_id)
                canonical_id = self._resolve_merge_alias(canonical_id)
                if canonical_id is None:
                    continue

                stat = stats.setdefault(
                    canonical_id,
                    {
                        "canonical_id": canonical_id,
                        "frame_set": set(),
                        "track_ids": set(),
                        "positions_by_frame": {},
                        "team_votes": defaultdict(int),
                        "appearance_samples": [],
                        "appearance_profile_samples": [],
                    },
                )

                stat["frame_set"].add(frame_num)
                stat["track_ids"].add(track_id)

                team = track_info.get("team")
                if team in (1, 2):
                    stat["team_votes"][int(team)] += 1

                position, position_space = self._resolve_position(track_info)
                if position is not None:
                    existing = stat["positions_by_frame"].get(frame_num)
                    if existing is None:
                        stat["positions_by_frame"][frame_num] = (position, position_space)

                appearance = track_info.get("appearance_color")
                if isinstance(appearance, (list, tuple, np.ndarray)) and len(appearance) >= 3:
                    stat["appearance_samples"].append([float(appearance[0]), float(appearance[1]), float(appearance[2])])

                appearance_profile = self._sanitize_appearance_profile(track_info.get("appearance_descriptor"))
                if appearance_profile is not None:
                    stat["appearance_profile_samples"].append(appearance_profile.tolist())

        for canonical_id, stat in stats.items():
            frame_list = sorted(stat["frame_set"])
            if not frame_list:
                continue

            stat["first_frame"] = int(frame_list[0])
            stat["last_frame"] = int(frame_list[-1])
            stat["total_frames_seen"] = int(len(frame_list))
            stat["frame_span"] = int(stat["last_frame"] - stat["first_frame"] + 1)

            sorted_positions = sorted(stat["positions_by_frame"].items(), key=lambda item: item[0])
            if sorted_positions:
                first_pos, first_space = sorted_positions[0][1]
                last_pos, last_space = sorted_positions[-1][1]
            else:
                first_pos = last_pos = None
                first_space = last_space = None
            stat["first_position"] = first_pos
            stat["first_position_space"] = first_space
            stat["last_position"] = last_pos
            stat["last_position_space"] = last_space

            total_distance = 0.0
            previous_pos = None
            previous_space = None
            for _, (current_pos, current_space) in sorted_positions:
                if previous_pos is not None and previous_space == current_space:
                    total_distance += measure_distance(previous_pos, current_pos)
                previous_pos = current_pos
                previous_space = current_space
            stat["total_distance"] = float(total_distance)
            stat["distance_space"] = previous_space

            team_votes = stat["team_votes"]
            stat["team"] = int(max(team_votes.items(), key=lambda item: item[1])[0]) if team_votes else None
            stat["appearance_signature"] = self._aggregate_appearance_signature(stat["appearance_samples"])
            stat["appearance_profile"] = self._aggregate_appearance_profile(stat["appearance_profile_samples"])
            stat["track_ids"] = sorted(int(track_id) for track_id in stat["track_ids"])

            entry = self.player_registry.get(canonical_id)
            stat["identity_locked"] = bool(entry.locked) if entry else False
            stat["source"] = entry.source if entry else "auto"
            stat["merge_target"] = (
                self._resolve_merge_alias(entry.merge_target)
                if entry and entry.merge_target
                else self._resolve_merge_alias(self.canonical_merge_map.get(canonical_id))
            )

        return stats

    def _build_crossing_appearance_profiles(
        self,
        tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]],
    ) -> Dict[str, Optional[List[float]]]:
        selected_samples: Dict[str, List[List[float]]] = defaultdict(list)
        fallback_samples: Dict[str, List[List[float]]] = defaultdict(list)

        for frame_num, frame_tracks in enumerate(tracks.get("players", [])):
            for raw_track_id, track_info in frame_tracks.items():
                track_id = self._normalize_track_id(raw_track_id)
                if self.get_object_type(frame_num, track_id) != "player":
                    continue

                canonical_id = track_info.get("canonical_id") or self.get_canonical_id(frame_num, track_id)
                canonical_id = self._resolve_merge_alias(canonical_id)
                if canonical_id is None:
                    continue

                descriptor = self._sanitize_appearance_profile(track_info.get("appearance_descriptor"))
                if descriptor is None:
                    continue

                descriptor_list = descriptor.tolist()
                fallback_samples[canonical_id].append(descriptor_list)

                identity_state = str(track_info.get("identity_state", "")).strip().lower()
                include_selected = (
                    frame_num <= self.appearance_profile_init_frames
                    or bool(track_info.get("identity_locked", False))
                    or identity_state == "stable"
                )
                if include_selected:
                    selected_samples[canonical_id].append(descriptor_list)

        profile_lookup: Dict[str, Optional[List[float]]] = {}
        canonical_ids = set(fallback_samples.keys()) | set(selected_samples.keys())
        for canonical_id in canonical_ids:
            samples = selected_samples.get(canonical_id)
            if samples is None or len(samples) < self.appearance_profile_history_min_samples:
                samples = fallback_samples.get(canonical_id, [])
            profile_lookup[canonical_id] = self._aggregate_appearance_profile(samples)

        return profile_lookup

    def _is_fragment_candidate(
        self,
        canonical_id: str,
        stat: Dict[str, Any],
        active_player_count: int,
    ) -> Tuple[bool, List[str]]:
        reasons: List[str] = []

        if stat.get("merge_target"):
            return False, reasons
        if self._is_manual_anchor_canonical(canonical_id):
            return False, reasons

        entry = self.player_registry.get(canonical_id)
        if entry and self._normalize_object_type(entry.object_type) != "player":
            return False, reasons

        if int(stat.get("total_frames_seen", 0)) <= self.fragment_short_lifetime_frames:
            reasons.append("short_lifetime")
        if int(stat.get("frame_span", 0)) <= self.fragment_small_span_frames:
            reasons.append("small_frame_span")

        distance_threshold = (
            self.fragment_low_distance_m
            if stat.get("distance_space") == "pitch"
            else self.fragment_low_distance_px
        )
        if float(stat.get("total_distance", 0.0)) <= float(distance_threshold):
            reasons.append("low_total_distance")

        if active_player_count > self.expected_player_count:
            reasons.append("over_expected_player_count")

        if len(reasons) >= 2:
            return True, reasons
        if active_player_count > self.expected_player_count and reasons:
            return True, reasons
        return False, reasons

    def _should_suppress_fragment(
        self,
        canonical_id: str,
        stat: Dict[str, Any],
        max_frame_index: int,
    ) -> bool:
        if self._is_manual_anchor_canonical(canonical_id):
            return False

        total_frames_seen = int(stat.get("total_frames_seen", 0))
        first_frame = int(stat.get("first_frame", 0))

        distance_threshold = (
            self.fragment_suppress_low_distance_m
            if stat.get("distance_space") == "pitch"
            else self.fragment_suppress_low_distance_px
        )
        total_distance = float(stat.get("total_distance", 0.0))

        track_ids = stat.get("track_ids", []) or []
        if len(track_ids) > 1:
            return False

        short_low_motion = (
            total_frames_seen <= int(self.fragment_suppress_short_lifetime_frames)
            and total_distance <= float(distance_threshold)
        )

        late_distance_threshold = (
            self.fragment_suppress_late_distance_m
            if stat.get("distance_space") == "pitch"
            else self.fragment_suppress_late_distance_px
        )
        late_low_motion = (
            total_frames_seen <= int(self.fragment_suppress_late_max_frames)
            and first_frame >= int(max_frame_index * float(self.fragment_suppress_late_start_ratio))
            and total_distance <= float(late_distance_threshold)
        )

        if not short_low_motion and not late_low_motion:
            return False

        return True

    def _suppress_canonical_identity(self, canonical_id: str) -> List[int]:
        canonical_id = self._resolve_merge_alias(canonical_id)
        if canonical_id is None:
            return []

        suppressed_track_ids: List[int] = []
        for track_id, mapped_canonical in list(self.default_track_to_canonical.items()):
            if self._resolve_merge_alias(mapped_canonical) != canonical_id:
                continue

            suppressed_track_ids.append(int(track_id))
            self.default_track_to_object_type[track_id] = "ignore"
            for frame_num in self.track_frames.get(track_id, []):
                self.frame_track_to_object_type[frame_num][track_id] = "ignore"
                self.frame_track_to_canonical[frame_num].pop(track_id, None)

        entry = self.player_registry.get(canonical_id)
        if entry is not None:
            entry.object_type = "ignore"

        return sorted(set(suppressed_track_ids))

    def _compute_merge_candidate_score(
        self,
        fragment_id: str,
        target_id: str,
        fragment_stat: Dict[str, Any],
        target_stat: Dict[str, Any],
        allow_relaxed: bool = False,
    ) -> Optional[Dict[str, Any]]:
        fragment_team = fragment_stat.get("team")
        target_team = target_stat.get("team")
        if fragment_team is not None and target_team is not None and int(fragment_team) != int(target_team):
            return None

        overlap_frames = len(fragment_stat["frame_set"].intersection(target_stat["frame_set"]))
        if overlap_frames > 0:
            return None

        gap_frames = 0
        link_distance = None
        link_space = None
        has_temporal_relation = False

        if fragment_stat["first_frame"] > target_stat["last_frame"]:
            has_temporal_relation = True
            gap_frames = int(fragment_stat["first_frame"] - target_stat["last_frame"])
            link_space = fragment_stat.get("first_position_space")
            if (
                fragment_stat.get("first_position") is not None
                and target_stat.get("last_position") is not None
                and fragment_stat.get("first_position_space") == target_stat.get("last_position_space")
            ):
                link_distance = measure_distance(fragment_stat["first_position"], target_stat["last_position"])
        elif target_stat["first_frame"] > fragment_stat["last_frame"]:
            has_temporal_relation = True
            gap_frames = int(target_stat["first_frame"] - fragment_stat["last_frame"])
            link_space = fragment_stat.get("last_position_space")
            if (
                fragment_stat.get("last_position") is not None
                and target_stat.get("first_position") is not None
                and fragment_stat.get("last_position_space") == target_stat.get("first_position_space")
            ):
                link_distance = measure_distance(fragment_stat["last_position"], target_stat["first_position"])

        if not has_temporal_relation:
            return None

        gap_limit = self.fragment_match_gap_frames * (
            self.fragment_relaxed_gap_multiplier if allow_relaxed else 2
        )
        if gap_frames > gap_limit:
            return None

        if link_distance is not None:
            max_distance = self._distance_threshold_for_space(link_space, gap_frames) * (
                self.fragment_relaxed_distance_multiplier
                if allow_relaxed
                else self.fragment_merge_distance_multiplier
            )
            if link_distance > max_distance:
                return None

        appearance_delta = self._appearance_distance(
            fragment_stat.get("appearance_signature"),
            target_stat.get("appearance_signature"),
        )
        appearance_threshold = self.appearance_change_threshold * (
            self.fragment_relaxed_appearance_multiplier if allow_relaxed else 1.2
        )
        if appearance_delta is not None and appearance_delta > appearance_threshold:
            return None

        evidence_terms = 0
        hard_evidence_terms = 0
        score = float(gap_frames) * 2.0 + float(overlap_frames) * 15.0
        if link_distance is not None:
            score += float(link_distance)
            evidence_terms += 1
            hard_evidence_terms += 1
        if appearance_delta is not None:
            score += float(appearance_delta) * 0.35
            evidence_terms += 1
            hard_evidence_terms += 1
        if fragment_team is not None and target_team is not None:
            evidence_terms += 1

        if evidence_terms == 0 or hard_evidence_terms == 0:
            return None

        if self._is_manual_anchor_canonical(target_id):
            score -= 6.0

        return {
            "fragment_canonical_id": fragment_id,
            "target_canonical_id": target_id,
            "gap_frames": int(gap_frames),
            "overlap_frames": int(overlap_frames),
            "distance": None if link_distance is None else round(float(link_distance), 3),
            "appearance_delta": None if appearance_delta is None else round(float(appearance_delta), 3),
            "score": round(float(score), 3),
        }

    def _apply_canonical_merge(self, source_canonical_id: str, target_canonical_id: str, reason: Dict[str, Any]) -> None:
        source_canonical_id = self._resolve_merge_alias(source_canonical_id)
        target_canonical_id = self._resolve_merge_alias(target_canonical_id)
        if not source_canonical_id or not target_canonical_id:
            return
        if source_canonical_id == target_canonical_id:
            return

        self.canonical_merge_map[source_canonical_id] = target_canonical_id

        for frame_mapping in self.frame_track_to_canonical.values():
            for track_id, canonical_id in list(frame_mapping.items()):
                if self._resolve_merge_alias(canonical_id) == source_canonical_id:
                    frame_mapping[track_id] = target_canonical_id

        for track_id, canonical_id in list(self.default_track_to_canonical.items()):
            if self._resolve_merge_alias(canonical_id) == source_canonical_id:
                self.default_track_to_canonical[track_id] = target_canonical_id

        source_entry = self.player_registry.get(source_canonical_id)
        target_entry = self._ensure_registry_entry(target_canonical_id, metadata={"object_type": "player"})

        if source_entry is not None:
            if not target_entry.name and source_entry.name:
                target_entry.name = source_entry.name
            if target_entry.team is None and source_entry.team is not None:
                target_entry.team = source_entry.team
            if target_entry.jersey_number is None and source_entry.jersey_number is not None:
                target_entry.jersey_number = source_entry.jersey_number
            target_entry.identity_confidence = max(target_entry.identity_confidence, source_entry.identity_confidence)
            source_entry.merge_target = target_canonical_id
            source_entry.identity_confidence = min(source_entry.identity_confidence, 0.55)

        merge_record = dict(reason)
        merge_record["source_canonical_id"] = source_canonical_id
        merge_record["target_canonical_id"] = target_canonical_id
        self.merge_history.append(merge_record)

    def reconcile_fragments(
        self,
        tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]],
    ) -> Dict[str, Any]:
        """Merge likely fragmented canonical identities while preserving manual anchors."""
        pre_stats = self._build_canonical_stats(tracks)
        active_players = [
            canonical_id
            for canonical_id, stat in pre_stats.items()
            if not stat.get("merge_target")
            and self._normalize_object_type(self.player_registry.get(canonical_id, PlayerRegistryEntry(canonical_id)).object_type)
            == "player"
        ]

        suspect_fragments: Dict[str, List[str]] = {}
        for canonical_id in active_players:
            is_suspect, reasons = self._is_fragment_candidate(
                canonical_id,
                pre_stats[canonical_id],
                active_player_count=len(active_players),
            )
            if is_suspect:
                suspect_fragments[canonical_id] = reasons

        merged_count = 0
        unresolved: List[Dict[str, Any]] = []
        merge_attempts: List[Dict[str, Any]] = []

        for fragment_id in sorted(
            suspect_fragments.keys(),
            key=lambda cid: (
                pre_stats[cid].get("total_frames_seen", 0),
                pre_stats[cid].get("total_distance", 0.0),
            ),
        ):
            if fragment_id in self.canonical_merge_map:
                continue
            if self._is_manual_anchor_canonical(fragment_id):
                continue

            fragment_stat = pre_stats[fragment_id]
            best_reason = None
            best_target = None
            best_score = None

            for target_id in active_players:
                target_id = self._resolve_merge_alias(target_id)
                if target_id is None or target_id == fragment_id:
                    continue
                if target_id in self.canonical_merge_map:
                    continue

                target_stat = pre_stats.get(target_id)
                if target_stat is None:
                    continue

                reason = self._compute_merge_candidate_score(
                    fragment_id,
                    target_id,
                    fragment_stat,
                    target_stat,
                    allow_relaxed=False,
                )
                if reason is None:
                    continue

                score = reason["score"]
                if best_score is None or score < best_score:
                    best_score = score
                    best_target = target_id
                    best_reason = reason

            current_active_estimate = len(active_players) - merged_count
            strict_threshold = self.fragment_merge_score_threshold
            if current_active_estimate > self.expected_player_count:
                strict_threshold += self.fragment_over_expected_strict_bonus

            if (
                (best_target is None or best_score is None or best_score > strict_threshold)
                and current_active_estimate > self.expected_player_count
            ):
                for target_id in active_players:
                    target_id = self._resolve_merge_alias(target_id)
                    if target_id is None or target_id == fragment_id:
                        continue
                    if target_id in self.canonical_merge_map:
                        continue

                    target_stat = pre_stats.get(target_id)
                    if target_stat is None:
                        continue

                    reason = self._compute_merge_candidate_score(
                        fragment_id,
                        target_id,
                        fragment_stat,
                        target_stat,
                        allow_relaxed=True,
                    )
                    if reason is None:
                        continue

                    score = reason["score"]
                    if best_score is None or score < best_score:
                        best_score = score
                        best_target = target_id
                        best_reason = reason

            if best_target is not None and best_score is not None:
                threshold = strict_threshold
                if current_active_estimate > self.expected_player_count:
                    threshold += self.fragment_over_expected_relaxed_bonus

                if best_score <= threshold:
                    self._apply_canonical_merge(fragment_id, best_target, best_reason or {})
                    merged_count += 1
                    merge_attempts.append(best_reason or {})
                    continue

            unresolved.append(
                {
                    "canonical_id": fragment_id,
                    "reasons": suspect_fragments.get(fragment_id, []),
                    "first_frame": fragment_stat.get("first_frame"),
                    "last_frame": fragment_stat.get("last_frame"),
                    "total_frames_seen": fragment_stat.get("total_frames_seen"),
                    "total_distance": round(float(fragment_stat.get("total_distance", 0.0)), 3),
                    "team": fragment_stat.get("team"),
                }
            )

        iterative_stats = self._build_canonical_stats(tracks)
        current_active = [
            canonical_id
            for canonical_id, stat in iterative_stats.items()
            if not stat.get("merge_target")
            and self._normalize_object_type(self.player_registry.get(canonical_id, PlayerRegistryEntry(canonical_id)).object_type)
            == "player"
        ]

        if len(current_active) > self.expected_player_count:
            overflow_candidates = sorted(
                [canonical_id for canonical_id in current_active if not self._is_manual_anchor_canonical(canonical_id)],
                key=lambda cid: (
                    iterative_stats[cid].get("total_frames_seen", 0),
                    iterative_stats[cid].get("total_distance", 0.0),
                ),
            )

            for fragment_id in overflow_candidates:
                current_active = [
                    canonical_id
                    for canonical_id, stat in iterative_stats.items()
                    if not stat.get("merge_target")
                    and self._normalize_object_type(self.player_registry.get(canonical_id, PlayerRegistryEntry(canonical_id)).object_type)
                    == "player"
                ]
                if len(current_active) <= self.expected_player_count:
                    break
                if fragment_id not in iterative_stats:
                    continue
                if self._is_manual_anchor_canonical(fragment_id):
                    continue

                fragment_stat = iterative_stats[fragment_id]
                best_reason = None
                best_target = None
                best_score = None

                for target_id in current_active:
                    if target_id == fragment_id:
                        continue
                    target_stat = iterative_stats.get(target_id)
                    if target_stat is None:
                        continue

                    reason = self._compute_merge_candidate_score(
                        fragment_id,
                        target_id,
                        fragment_stat,
                        target_stat,
                        allow_relaxed=True,
                    )
                    if reason is None:
                        continue

                    if best_score is None or reason["score"] < best_score:
                        best_score = reason["score"]
                        best_target = target_id
                        best_reason = reason

                if best_target is None or best_reason is None:
                    continue

                if best_reason["score"] <= self.fragment_merge_score_threshold + self.fragment_overflow_merge_bonus:
                    best_reason["forced_overflow_merge"] = True
                    self._apply_canonical_merge(fragment_id, best_target, best_reason)
                    merged_count += 1
                    merge_attempts.append(best_reason)
                    iterative_stats = self._build_canonical_stats(tracks)

        unresolved = [
            fragment
            for fragment in unresolved
            if self._resolve_merge_alias(fragment.get("canonical_id")) == fragment.get("canonical_id")
        ]

        self._enforce_non_overlapping_canonical_segments()

        post_adjustment_stats = self._build_canonical_stats(tracks)
        max_frame_index = 0
        if post_adjustment_stats:
            max_frame_index = max(int(item.get("last_frame", 0)) for item in post_adjustment_stats.values())
        suppressed_fragments: List[Dict[str, Any]] = []
        for fragment in list(unresolved):
            canonical_id = self._resolve_merge_alias(fragment.get("canonical_id"))
            if canonical_id is None:
                continue
            stat = post_adjustment_stats.get(canonical_id)
            if stat is None:
                continue
            if not self._should_suppress_fragment(canonical_id, stat, max_frame_index=max_frame_index):
                continue

            suppressed_track_ids = self._suppress_canonical_identity(canonical_id)
            suppressed_fragments.append(
                {
                    "canonical_id": canonical_id,
                    "track_ids": suppressed_track_ids,
                    "first_frame": stat.get("first_frame"),
                    "last_frame": stat.get("last_frame"),
                    "total_frames_seen": stat.get("total_frames_seen"),
                    "total_distance": round(float(stat.get("total_distance", 0.0)), 3),
                    "team": stat.get("team"),
                    "reason": "low_evidence_fragment_suppressed",
                }
            )

        if suppressed_fragments:
            unresolved = [
                fragment
                for fragment in unresolved
                if self._resolve_merge_alias(fragment.get("canonical_id"))
                not in {item["canonical_id"] for item in suppressed_fragments}
            ]

        post_stats = self._build_canonical_stats(tracks)
        self.canonical_debug_stats = post_stats
        self.unresolved_fragments = unresolved

        active_post_count = sum(
            1
            for canonical_id, stat in post_stats.items()
            if not stat.get("merge_target")
            and self._normalize_object_type(self.player_registry.get(canonical_id, PlayerRegistryEntry(canonical_id)).object_type)
            == "player"
        )
        resolved_active_count = max(0, active_post_count - len(unresolved))

        summary = {
            "expected_player_count": int(self.expected_player_count),
            "active_canonical_players": int(resolved_active_count),
            "raw_active_canonical_players": int(active_post_count),
            "merged_fragment_count": int(merged_count),
            "unresolved_fragment_count": int(len(unresolved)),
            "suppressed_fragment_count": int(len(suppressed_fragments)),
            "merge_mapping": dict(self.canonical_merge_map),
            "merge_history": self.merge_history,
            "unresolved_fragments": unresolved,
            "suppressed_fragments": suppressed_fragments,
            "merge_attempts": merge_attempts,
        }

        existing_summary = dict(self.reconciliation_summary)
        existing_summary.update(summary)
        self.reconciliation_summary = existing_summary
        self.refresh_event_statuses()
        return summary

    def apply_to_tracks(self, tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]]) -> None:
        """
        Enrich the existing tracks structure in-place without changing its shape.
        Downstream modules can keep iterating tracks[players][frame][track_id], but
        now each player dict carries the stable canonical identity payload.
        """
        canonical_stats = self._build_canonical_stats(tracks)
        canonical_team_lookup: Dict[str, Optional[int]] = {}
        canonical_appearance_lookup: Dict[str, Optional[List[float]]] = {}
        canonical_appearance_profile_lookup: Dict[str, Optional[List[float]]] = self._build_crossing_appearance_profiles(
            tracks
        )
        for canonical_id, stat in canonical_stats.items():
            canonical_team_lookup[canonical_id] = stat.get("team")
            canonical_appearance_lookup[canonical_id] = stat.get("appearance_signature")
            if canonical_appearance_profile_lookup.get(canonical_id) is None:
                canonical_appearance_profile_lookup[canonical_id] = stat.get("appearance_profile")
        for canonical_id, entry in self.player_registry.items():
            resolved = self._resolve_merge_alias(canonical_id)
            if resolved is None:
                continue
            if resolved not in canonical_team_lookup and entry.team in (1, 2):
                canonical_team_lookup[resolved] = int(entry.team)
            canonical_appearance_lookup.setdefault(resolved, None)
            canonical_appearance_profile_lookup.setdefault(resolved, None)

        track_runtime_state: Dict[int, Dict[str, Any]] = {}
        canonical_runtime_state: Dict[str, Dict[str, Any]] = {}
        track_appearance_context: Dict[int, Dict[str, Any]] = {}
        pending_switch_counts: Dict[Tuple[int, str, str], int] = defaultdict(int)
        pending_switch_last_frame: Dict[Tuple[int, str, str], int] = {}
        crossing_pair_states: Dict[Tuple[int, int], Dict[str, Any]] = {}

        self.identity_stability_logs = []
        self._identity_stability_seen = set()

        for frame_num, frame_tracks in enumerate(tracks.get("players", [])):
            stale_context_tracks = [
                track_id
                for track_id, context in track_appearance_context.items()
                if frame_num > int(context.get("expires_frame", frame_num))
            ]
            for stale_track_id in stale_context_tracks:
                track_appearance_context.pop(stale_track_id, None)

            frame_observations: Dict[int, Dict[str, Any]] = {}
            for raw_track_id, track_info in frame_tracks.items():
                track_id = self._normalize_track_id(raw_track_id)
                object_type = self.get_object_type(frame_num, track_id)
                if object_type != "player":
                    continue

                pitch_position = self._resolve_space_position(track_info, "pitch")
                image_position = self._resolve_space_position(track_info, "pixel")
                position, position_space = self._resolve_position(track_info)
                if position is None:
                    if pitch_position is not None:
                        position = pitch_position
                        position_space = "pitch"
                    elif image_position is not None:
                        position = image_position
                        position_space = "pixel"
                previous_track_state = track_runtime_state.get(track_id)
                frame_gap = max(1, int(frame_num - previous_track_state.get("frame_num", frame_num - 1))) if previous_track_state is not None else 1
                velocity = None
                if (
                    previous_track_state is not None
                    and position is not None
                    and previous_track_state.get("position") is not None
                    and previous_track_state.get("position_space") == position_space
                ):
                    previous_position = previous_track_state["position"]
                    velocity = (
                        float(position[0] - previous_position[0]) / float(frame_gap),
                        float(position[1] - previous_position[1]) / float(frame_gap),
                    )

                baseline_canonical_id = self.get_canonical_id(frame_num, track_id)
                baseline_canonical_id = self._resolve_merge_alias(baseline_canonical_id)
                if baseline_canonical_id is None:
                    baseline_canonical_id = self.create_canonical_id(object_type="player")

                previous_stable_canonical_id = None
                if previous_track_state is not None:
                    previous_stable_canonical_id = self._resolve_merge_alias(
                        previous_track_state.get("last_stable_canonical_id")
                        or previous_track_state.get("stable_canonical_id")
                    )

                baseline_locked = self._is_manual_anchor_canonical(baseline_canonical_id)
                previous_locked = self._is_manual_anchor_canonical(previous_stable_canonical_id)
                observation_locked = bool(track_info.get("identity_locked", False))
                manual_locked = bool(observation_locked or baseline_locked or previous_locked)
                appearance_profile = track_info.get("appearance_descriptor")
                if appearance_profile is None and previous_track_state is not None:
                    appearance_profile = previous_track_state.get("appearance_profile")

                frame_observations[track_id] = {
                    "track_info": track_info,
                    "position": position,
                    "position_space": position_space,
                    "image_position": image_position,
                    "pitch_position": pitch_position,
                    "velocity": velocity,
                    "team": int(track_info.get("team")) if track_info.get("team") in (1, 2) else None,
                    "appearance": track_info.get("appearance_color"),
                    "appearance_profile": appearance_profile,
                    "bbox": track_info.get("bbox"),
                    "frame_gap": int(frame_gap),
                    "baseline_canonical_id": baseline_canonical_id,
                    "previous_stable_canonical_id": previous_stable_canonical_id,
                    "manual_locked": bool(manual_locked),
                }

            track_crossing_state: Dict[int, str] = {}
            active_pair_keys: set = set()
            observation_track_ids = sorted(frame_observations.keys())
            for index, first_track_id in enumerate(observation_track_ids):
                first_observation = frame_observations[first_track_id]
                for second_track_id in observation_track_ids[index + 1 :]:
                    second_observation = frame_observations[second_track_id]
                    pair_metrics = self._compute_crossing_pair_metrics(first_observation, second_observation)
                    if not pair_metrics.get("start_ambiguity"):
                        continue

                    pair_key = (min(first_track_id, second_track_id), max(first_track_id, second_track_id))
                    active_pair_keys.add(pair_key)
                    pair_state = crossing_pair_states.get(pair_key)
                    appearance_context_metrics = self._update_crossing_appearance_context(
                        pair_key=pair_key,
                        frame_observations=frame_observations,
                        canonical_appearance_profile_lookup=canonical_appearance_profile_lookup,
                        track_appearance_context=track_appearance_context,
                        frame_num=frame_num,
                    )
                    log_metrics = self._crossing_pair_log_metrics(
                        pair_key,
                        pair_metrics,
                        extra=appearance_context_metrics,
                    )

                    if pair_state is None or pair_state.get("state") != "ambiguous_crossing":
                        crossing_pair_states[pair_key] = {
                            "state": "ambiguous_crossing",
                            "started_frame": int(frame_num),
                            "freeze_until_frame": int(frame_num + self.crossing_freeze_min_frames - 1),
                            "last_seen_frame": int(frame_num),
                            "post_sep_count": 0,
                            "last_metrics": pair_metrics,
                        }
                        for crossing_track_id in pair_key:
                            track_crossing_state[crossing_track_id] = "ambiguous_crossing"
                            crossing_observation = frame_observations.get(crossing_track_id, {})
                            self._log_identity_stability_guard(
                                frame_num=frame_num,
                                track_id=crossing_track_id,
                                from_canonical_id=self._resolve_merge_alias(
                                    crossing_observation.get("previous_stable_canonical_id")
                                ),
                                to_canonical_id=self._resolve_merge_alias(
                                    crossing_observation.get("baseline_canonical_id")
                                ),
                                reason="crossing_freeze_started",
                                metrics=log_metrics,
                            )
                    else:
                        pair_state["last_seen_frame"] = int(frame_num)
                        pair_state["last_metrics"] = pair_metrics
                        pair_state["freeze_until_frame"] = max(
                            int(pair_state.get("freeze_until_frame", frame_num)),
                            int(frame_num + self.crossing_freeze_min_frames - 1),
                        )
                        for crossing_track_id in pair_key:
                            track_crossing_state[crossing_track_id] = "ambiguous_crossing"
                            crossing_observation = frame_observations.get(crossing_track_id, {})
                            self._log_identity_stability_guard(
                                frame_num=frame_num,
                                track_id=crossing_track_id,
                                from_canonical_id=self._resolve_merge_alias(
                                    crossing_observation.get("previous_stable_canonical_id")
                                ),
                                to_canonical_id=self._resolve_merge_alias(
                                    crossing_observation.get("baseline_canonical_id")
                                ),
                                reason="crossing_freeze_maintained",
                                metrics=log_metrics,
                            )

            for pair_key, pair_state in list(crossing_pair_states.items()):
                if pair_key in active_pair_keys:
                    continue

                first_track_id, second_track_id = pair_key
                first_observation = frame_observations.get(first_track_id)
                second_observation = frame_observations.get(second_track_id)
                first_visible = first_observation is not None
                second_visible = second_observation is not None
                both_visible = first_visible and second_visible

                last_seen_frame = int(pair_state.get("last_seen_frame", frame_num))
                if not first_visible and not second_visible:
                    if frame_num - last_seen_frame > self.crossing_state_ttl_frames:
                        crossing_pair_states.pop(pair_key, None)
                    continue

                pair_state_name = str(pair_state.get("state", "ambiguous_crossing"))

                if pair_state_name == "ambiguous_crossing":
                    freeze_until_frame = int(pair_state.get("freeze_until_frame", frame_num))
                    if frame_num <= freeze_until_frame:
                        pair_state["last_seen_frame"] = int(frame_num)
                        pair_metrics = pair_state.get("last_metrics") or {}
                        for crossing_track_id in pair_key:
                            if crossing_track_id in frame_observations:
                                track_crossing_state[crossing_track_id] = "ambiguous_crossing"
                                crossing_observation = frame_observations.get(crossing_track_id, {})
                                self._log_identity_stability_guard(
                                    frame_num=frame_num,
                                    track_id=crossing_track_id,
                                    from_canonical_id=self._resolve_merge_alias(
                                        crossing_observation.get("previous_stable_canonical_id")
                                    ),
                                    to_canonical_id=self._resolve_merge_alias(
                                        crossing_observation.get("baseline_canonical_id")
                                    ),
                                    reason="crossing_freeze_maintained",
                                    metrics=self._crossing_pair_log_metrics(
                                        pair_key,
                                        pair_metrics,
                                        extra={
                                            "freeze_until_frame": freeze_until_frame,
                                        },
                                    ),
                                )
                        continue

                    if not both_visible:
                        pair_state["state"] = "awaiting_post_separation_confirmation"
                        pair_state["post_sep_count"] = 0
                        pair_state["last_seen_frame"] = int(frame_num)
                        pair_metrics = pair_state.get("last_metrics") or {}
                        for crossing_track_id in pair_key:
                            if crossing_track_id in frame_observations:
                                track_crossing_state[crossing_track_id] = "awaiting_post_separation_confirmation"
                                crossing_observation = frame_observations.get(crossing_track_id, {})
                                self._log_identity_stability_guard(
                                    frame_num=frame_num,
                                    track_id=crossing_track_id,
                                    from_canonical_id=self._resolve_merge_alias(
                                        crossing_observation.get("previous_stable_canonical_id")
                                    ),
                                    to_canonical_id=self._resolve_merge_alias(
                                        crossing_observation.get("baseline_canonical_id")
                                    ),
                                    reason="awaiting_post_separation_confirmation",
                                    metrics=self._crossing_pair_log_metrics(
                                        pair_key,
                                        pair_metrics,
                                        extra={
                                            "state": "awaiting_post_separation_confirmation",
                                            "post_sep_count": 0,
                                            "required_frames": int(
                                                max(
                                                    self.post_separation_confirmation_frames,
                                                    self.crossing_confirmation_separated_frames,
                                                )
                                            ),
                                            "reason_detail": "one_track_hidden",
                                        },
                                    ),
                                )
                        continue

                    pair_metrics = self._compute_crossing_pair_metrics(first_observation, second_observation)
                    pair_state["last_seen_frame"] = int(frame_num)
                    pair_state["last_metrics"] = pair_metrics
                    appearance_context_metrics = self._update_crossing_appearance_context(
                        pair_key=pair_key,
                        frame_observations=frame_observations,
                        canonical_appearance_profile_lookup=canonical_appearance_profile_lookup,
                        track_appearance_context=track_appearance_context,
                        frame_num=frame_num,
                    )

                    if pair_metrics.get("start_ambiguity"):
                        pair_state["freeze_until_frame"] = int(frame_num)
                        for crossing_track_id in pair_key:
                            track_crossing_state[crossing_track_id] = "ambiguous_crossing"
                            crossing_observation = frame_observations.get(crossing_track_id, {})
                            self._log_identity_stability_guard(
                                frame_num=frame_num,
                                track_id=crossing_track_id,
                                from_canonical_id=self._resolve_merge_alias(
                                    crossing_observation.get("previous_stable_canonical_id")
                                ),
                                to_canonical_id=self._resolve_merge_alias(
                                    crossing_observation.get("baseline_canonical_id")
                                ),
                                reason="crossing_freeze_maintained",
                                metrics=self._crossing_pair_log_metrics(
                                    pair_key,
                                    pair_metrics,
                                    extra={
                                        "reason_detail": "ambiguous_evidence_continues",
                                        **appearance_context_metrics,
                                    },
                                ),
                            )
                        continue

                    if self._pair_is_separated(pair_metrics):
                        pair_state["state"] = "awaiting_post_separation_confirmation"
                        pair_state["post_sep_count"] = 1
                        for crossing_track_id in pair_key:
                            track_crossing_state[crossing_track_id] = "awaiting_post_separation_confirmation"
                            crossing_observation = frame_observations.get(crossing_track_id, {})
                            self._log_identity_stability_guard(
                                frame_num=frame_num,
                                track_id=crossing_track_id,
                                from_canonical_id=self._resolve_merge_alias(
                                    crossing_observation.get("previous_stable_canonical_id")
                                ),
                                to_canonical_id=self._resolve_merge_alias(
                                    crossing_observation.get("baseline_canonical_id")
                                ),
                                reason="post_separation_confirmation_started",
                                metrics=self._crossing_pair_log_metrics(
                                    pair_key,
                                    pair_metrics,
                                    extra={
                                        "state": "awaiting_post_separation_confirmation",
                                        "post_sep_count": 1,
                                        "required_frames": int(
                                            max(
                                                self.post_separation_confirmation_frames,
                                                self.crossing_confirmation_separated_frames,
                                            )
                                        ),
                                        **appearance_context_metrics,
                                    },
                                ),
                            )
                            self._log_identity_stability_guard(
                                frame_num=frame_num,
                                track_id=crossing_track_id,
                                from_canonical_id=self._resolve_merge_alias(
                                    crossing_observation.get("previous_stable_canonical_id")
                                ),
                                to_canonical_id=self._resolve_merge_alias(
                                    crossing_observation.get("baseline_canonical_id")
                                ),
                                reason="awaiting_post_separation_confirmation",
                                metrics=self._crossing_pair_log_metrics(
                                    pair_key,
                                    pair_metrics,
                                    extra={
                                        "state": "awaiting_post_separation_confirmation",
                                        "post_sep_count": 1,
                                        "required_frames": int(
                                            max(
                                                self.post_separation_confirmation_frames,
                                                self.crossing_confirmation_separated_frames,
                                            )
                                        ),
                                        **appearance_context_metrics,
                                    },
                                ),
                            )
                    else:
                        pair_state["freeze_until_frame"] = int(frame_num)
                        for crossing_track_id in pair_key:
                            track_crossing_state[crossing_track_id] = "ambiguous_crossing"
                            crossing_observation = frame_observations.get(crossing_track_id, {})
                            self._log_identity_stability_guard(
                                frame_num=frame_num,
                                track_id=crossing_track_id,
                                from_canonical_id=self._resolve_merge_alias(
                                    crossing_observation.get("previous_stable_canonical_id")
                                ),
                                to_canonical_id=self._resolve_merge_alias(
                                    crossing_observation.get("baseline_canonical_id")
                                ),
                                reason="crossing_freeze_maintained",
                                metrics=self._crossing_pair_log_metrics(
                                    pair_key,
                                    pair_metrics,
                                    extra={
                                        "reason_detail": "separation_not_confirmed",
                                        **appearance_context_metrics,
                                    },
                                ),
                            )

                else:
                    if not both_visible:
                        pair_state["last_seen_frame"] = int(frame_num)
                        pair_state["post_sep_count"] = 0
                        pair_metrics = pair_state.get("last_metrics") or {}
                        for crossing_track_id in pair_key:
                            if crossing_track_id in frame_observations:
                                track_crossing_state[crossing_track_id] = "awaiting_post_separation_confirmation"
                                crossing_observation = frame_observations.get(crossing_track_id, {})
                                self._log_identity_stability_guard(
                                    frame_num=frame_num,
                                    track_id=crossing_track_id,
                                    from_canonical_id=self._resolve_merge_alias(
                                        crossing_observation.get("previous_stable_canonical_id")
                                    ),
                                    to_canonical_id=self._resolve_merge_alias(
                                        crossing_observation.get("baseline_canonical_id")
                                    ),
                                    reason="awaiting_post_separation_confirmation",
                                    metrics=self._crossing_pair_log_metrics(
                                        pair_key,
                                        pair_metrics,
                                        extra={
                                            "state": "awaiting_post_separation_confirmation",
                                            "post_sep_count": 0,
                                            "required_frames": int(
                                                max(
                                                    self.post_separation_confirmation_frames,
                                                    self.crossing_confirmation_separated_frames,
                                                )
                                            ),
                                            "reason_detail": "one_track_hidden",
                                        },
                                    ),
                                )
                        if frame_num - last_seen_frame > self.crossing_state_ttl_frames:
                            crossing_pair_states.pop(pair_key, None)
                        continue

                    pair_metrics = self._compute_crossing_pair_metrics(first_observation, second_observation)
                    pair_state["last_seen_frame"] = int(frame_num)
                    pair_state["last_metrics"] = pair_metrics
                    appearance_context_metrics = self._update_crossing_appearance_context(
                        pair_key=pair_key,
                        frame_observations=frame_observations,
                        canonical_appearance_profile_lookup=canonical_appearance_profile_lookup,
                        track_appearance_context=track_appearance_context,
                        frame_num=frame_num,
                    )

                    if pair_metrics.get("start_ambiguity"):
                        pair_state["state"] = "ambiguous_crossing"
                        pair_state["started_frame"] = int(frame_num)
                        pair_state["freeze_until_frame"] = int(frame_num + self.crossing_freeze_min_frames - 1)
                        pair_state["post_sep_count"] = 0
                        for crossing_track_id in pair_key:
                            track_crossing_state[crossing_track_id] = "ambiguous_crossing"
                            crossing_observation = frame_observations.get(crossing_track_id, {})
                            self._log_identity_stability_guard(
                                frame_num=frame_num,
                                track_id=crossing_track_id,
                                from_canonical_id=self._resolve_merge_alias(
                                    crossing_observation.get("previous_stable_canonical_id")
                                ),
                                to_canonical_id=self._resolve_merge_alias(
                                    crossing_observation.get("baseline_canonical_id")
                                ),
                                reason="crossing_freeze_started",
                                metrics=self._crossing_pair_log_metrics(
                                    pair_key,
                                    pair_metrics,
                                    extra={
                                        "trigger": "reentered_ambiguity",
                                        **appearance_context_metrics,
                                    },
                                ),
                            )
                        continue

                    separated = self._pair_is_separated(pair_metrics)
                    post_sep_count = int(pair_state.get("post_sep_count", 0))
                    if separated:
                        post_sep_count = post_sep_count + 1
                    else:
                        post_sep_count = 0
                    pair_state["post_sep_count"] = post_sep_count

                    required_confirmation_frames = int(
                        max(
                            self.post_separation_confirmation_frames,
                            self.crossing_confirmation_separated_frames,
                        )
                    )
                    if post_sep_count >= required_confirmation_frames:
                        for crossing_track_id in pair_key:
                            crossing_observation = frame_observations.get(crossing_track_id, {})
                            self._log_identity_stability_guard(
                                frame_num=frame_num,
                                track_id=crossing_track_id,
                                from_canonical_id=self._resolve_merge_alias(
                                    crossing_observation.get("previous_stable_canonical_id")
                                ),
                                to_canonical_id=self._resolve_merge_alias(
                                    crossing_observation.get("baseline_canonical_id")
                                ),
                                reason="post_separation_confirmation_passed",
                                metrics=self._crossing_pair_log_metrics(
                                    pair_key,
                                    pair_metrics,
                                    extra={
                                        "confirmed_frames": int(post_sep_count),
                                        "required_frames": required_confirmation_frames,
                                        **appearance_context_metrics,
                                    },
                                ),
                            )
                        crossing_pair_states.pop(pair_key, None)
                    else:
                        for crossing_track_id in pair_key:
                            track_crossing_state[crossing_track_id] = "awaiting_post_separation_confirmation"
                            crossing_observation = frame_observations.get(crossing_track_id, {})
                            self._log_identity_stability_guard(
                                frame_num=frame_num,
                                track_id=crossing_track_id,
                                from_canonical_id=self._resolve_merge_alias(
                                    crossing_observation.get("previous_stable_canonical_id")
                                ),
                                to_canonical_id=self._resolve_merge_alias(
                                    crossing_observation.get("baseline_canonical_id")
                                ),
                                reason="awaiting_post_separation_confirmation",
                                metrics=self._crossing_pair_log_metrics(
                                    pair_key,
                                    pair_metrics,
                                    extra={
                                        "state": "awaiting_post_separation_confirmation",
                                        "post_sep_count": int(post_sep_count),
                                        "required_frames": required_confirmation_frames,
                                        "reason_detail": (
                                            "insufficient_separated_frames"
                                            if separated
                                            else "not_separated"
                                        ),
                                        **appearance_context_metrics,
                                    },
                                ),
                            )

            # Prevent contradictory fast mutual swaps in the same frame.
            for index, first_track_id in enumerate(observation_track_ids):
                first_observation = frame_observations[first_track_id]
                first_prev = self._resolve_merge_alias(first_observation.get("previous_stable_canonical_id"))
                first_base = self._resolve_merge_alias(first_observation.get("baseline_canonical_id"))
                if not first_prev or not first_base or first_prev == first_base:
                    continue

                for second_track_id in observation_track_ids[index + 1 :]:
                    second_observation = frame_observations[second_track_id]
                    second_prev = self._resolve_merge_alias(second_observation.get("previous_stable_canonical_id"))
                    second_base = self._resolve_merge_alias(second_observation.get("baseline_canonical_id"))
                    if not second_prev or not second_base or second_prev == second_base:
                        continue

                    if first_base == second_prev and second_base == first_prev:
                        pair_key = (min(first_track_id, second_track_id), max(first_track_id, second_track_id))
                        pair_metrics = self._compute_crossing_pair_metrics(first_observation, second_observation)
                        pair_metrics["start_ambiguity"] = True
                        pair_state = crossing_pair_states.get(pair_key)
                        appearance_context_metrics = self._update_crossing_appearance_context(
                            pair_key=pair_key,
                            frame_observations=frame_observations,
                            canonical_appearance_profile_lookup=canonical_appearance_profile_lookup,
                            track_appearance_context=track_appearance_context,
                            frame_num=frame_num,
                        )

                        if pair_state is None or pair_state.get("state") != "ambiguous_crossing":
                            crossing_pair_states[pair_key] = {
                                "state": "ambiguous_crossing",
                                "started_frame": int(frame_num),
                                "freeze_until_frame": int(frame_num + self.crossing_freeze_min_frames - 1),
                                "last_seen_frame": int(frame_num),
                                "post_sep_count": 0,
                                "last_metrics": pair_metrics,
                            }
                            event_reason = "crossing_freeze_started"
                        else:
                            pair_state["last_seen_frame"] = int(frame_num)
                            pair_state["last_metrics"] = pair_metrics
                            pair_state["freeze_until_frame"] = max(
                                int(pair_state.get("freeze_until_frame", frame_num)),
                                int(frame_num + self.crossing_freeze_min_frames - 1),
                            )
                            event_reason = "crossing_freeze_maintained"

                        track_crossing_state[first_track_id] = "ambiguous_crossing"
                        track_crossing_state[second_track_id] = "ambiguous_crossing"
                        for crossing_track_id in pair_key:
                            crossing_observation = frame_observations.get(crossing_track_id, {})
                            self._log_identity_stability_guard(
                                frame_num=frame_num,
                                track_id=crossing_track_id,
                                from_canonical_id=self._resolve_merge_alias(
                                    crossing_observation.get("previous_stable_canonical_id")
                                ),
                                to_canonical_id=self._resolve_merge_alias(
                                    crossing_observation.get("baseline_canonical_id")
                                ),
                                reason=event_reason,
                                metrics=self._crossing_pair_log_metrics(
                                    pair_key,
                                    pair_metrics,
                                    extra={
                                        "trigger": "fast_mutual_swap",
                                        **appearance_context_metrics,
                                    },
                                ),
                            )

            canonical_in_use: Dict[str, int] = {}
            for raw_track_id, track_info in frame_tracks.items():
                track_id = self._normalize_track_id(raw_track_id)
                object_type = self.get_object_type(frame_num, track_id)

                track_info["transient_track_id"] = int(track_id)
                track_info["object_type"] = object_type
                track_info["include_in_player_analytics"] = object_type == "player"

                if object_type == "ignore":
                    track_info["canonical_id"] = None
                    track_info["display_name"] = track_info.get("display_name") or f"ignored_track_{track_id}"
                    track_info["jersey_number"] = None
                    track_info["identity_locked"] = bool(track_info.get("identity_locked", False))
                    track_info["identity_confidence"] = float(track_info.get("identity_confidence", 0.0))
                    track_info["identity_source"] = track_info.get("identity_source", "manual")
                    track_info["team"] = None
                    continue

                observation = frame_observations.get(track_id, {})
                baseline_canonical_id = self._resolve_merge_alias(observation.get("baseline_canonical_id"))
                previous_stable_canonical_id = self._resolve_merge_alias(observation.get("previous_stable_canonical_id"))
                canonical_id = baseline_canonical_id
                identity_state = track_crossing_state.get(track_id, "stable")

                if canonical_id is None:
                    canonical_id = self.get_canonical_id(frame_num, track_id)
                    canonical_id = self._resolve_merge_alias(canonical_id)

                if canonical_id is None:
                    canonical_id = self.create_canonical_id(object_type=object_type)

                if (
                    object_type == "player"
                    and identity_state in {"ambiguous_crossing", "awaiting_post_separation_confirmation"}
                    and previous_stable_canonical_id is not None
                ):
                    canonical_id = previous_stable_canonical_id
                    if (
                        baseline_canonical_id is not None
                        and baseline_canonical_id != previous_stable_canonical_id
                    ):
                        for stale_key in [key for key in list(pending_switch_counts.keys()) if key[0] == track_id]:
                            pending_switch_counts.pop(stale_key, None)
                            pending_switch_last_frame.pop(stale_key, None)
                        self._log_identity_stability_guard(
                            frame_num=frame_num,
                            track_id=track_id,
                            from_canonical_id=previous_stable_canonical_id,
                            to_canonical_id=baseline_canonical_id,
                            reason="label_drift_prevented",
                            metrics={
                                "identity_state": identity_state,
                            },
                        )

                if object_type == "player" and previous_stable_canonical_id and canonical_id != previous_stable_canonical_id:
                    previous_locked = self._is_manual_anchor_canonical(previous_stable_canonical_id)
                    candidate_locked = self._is_manual_anchor_canonical(canonical_id)
                    evidence: Dict[str, Any] = {}
                    if candidate_locked:
                        canonical_id = previous_stable_canonical_id
                        for stale_key in [key for key in list(pending_switch_counts.keys()) if key[0] == track_id]:
                            pending_switch_counts.pop(stale_key, None)
                            pending_switch_last_frame.pop(stale_key, None)
                        self._log_identity_stability_guard(
                            frame_num=frame_num,
                            track_id=track_id,
                            from_canonical_id=previous_stable_canonical_id,
                            to_canonical_id=self._resolve_merge_alias(observation.get("baseline_canonical_id")),
                            reason="switch_blocked_due_to_locked_manual_anchor",
                            metrics={
                                "identity_state": identity_state,
                                "locked_anchor_source": "candidate",
                            },
                        )
                    elif previous_locked:
                        canonical_id = previous_stable_canonical_id
                        for stale_key in [key for key in list(pending_switch_counts.keys()) if key[0] == track_id]:
                            pending_switch_counts.pop(stale_key, None)
                            pending_switch_last_frame.pop(stale_key, None)
                        self._log_identity_stability_guard(
                            frame_num=frame_num,
                            track_id=track_id,
                            from_canonical_id=previous_stable_canonical_id,
                            to_canonical_id=self._resolve_merge_alias(observation.get("baseline_canonical_id")),
                            reason="switch_blocked_due_to_locked_manual_anchor",
                            metrics={
                                "identity_state": identity_state,
                                "locked_anchor_source": "previous",
                            },
                        )
                    elif identity_state in {"ambiguous_crossing", "awaiting_post_separation_confirmation"}:
                        canonical_id = previous_stable_canonical_id
                        for stale_key in [key for key in list(pending_switch_counts.keys()) if key[0] == track_id]:
                            pending_switch_counts.pop(stale_key, None)
                            pending_switch_last_frame.pop(stale_key, None)
                        self._log_identity_stability_guard(
                            frame_num=frame_num,
                            track_id=track_id,
                            from_canonical_id=previous_stable_canonical_id,
                            to_canonical_id=self._resolve_merge_alias(observation.get("baseline_canonical_id")),
                            reason="label_drift_prevented",
                            metrics={
                                "identity_state": identity_state,
                            },
                        )
                    else:
                        guard_reason = None
                        appearance_context_state = track_appearance_context.get(track_id, {})
                        appearance_context_bias = None
                        appearance_context_samples = 0
                        strong_appearance_mode = False
                        if appearance_context_state:
                            context_expires = int(appearance_context_state.get("expires_frame", -1))
                            if frame_num <= context_expires:
                                strong_appearance_mode = True
                                appearance_context_bias = appearance_context_state.get("ema_bias")
                                appearance_context_samples = int(appearance_context_state.get("samples", 0))

                        pitch_guard = self._evaluate_pitch_switch_guard(
                            previous_canonical_id=previous_stable_canonical_id,
                            candidate_canonical_id=canonical_id,
                            observation=observation,
                            canonical_runtime_state=canonical_runtime_state,
                            previous_locked=previous_locked,
                        )
                        if pitch_guard.get("blocked"):
                            canonical_id = previous_stable_canonical_id
                            guard_reason = str(pitch_guard.get("reason") or "candidate_impossible_pitch_jump")
                            evidence = dict(pitch_guard.get("metrics") or {})
                            for stale_key in [key for key in list(pending_switch_counts.keys()) if key[0] == track_id]:
                                pending_switch_counts.pop(stale_key, None)
                                pending_switch_last_frame.pop(stale_key, None)
                        if guard_reason is None:
                            evidence = self._compute_switch_evidence(
                                previous_canonical_id=previous_stable_canonical_id,
                                candidate_canonical_id=canonical_id,
                                observation=observation,
                                canonical_runtime_state=canonical_runtime_state,
                                canonical_team_lookup=canonical_team_lookup,
                                canonical_appearance_lookup=canonical_appearance_lookup,
                                canonical_appearance_profile_lookup=canonical_appearance_profile_lookup,
                                previous_locked=previous_locked,
                                strong_appearance_mode=strong_appearance_mode,
                                appearance_context_bias=appearance_context_bias,
                            )
                            if pitch_guard.get("metrics"):
                                evidence.update(pitch_guard.get("metrics") or {})
                            if appearance_context_samples > 0:
                                evidence["appearance_context_samples"] = int(appearance_context_samples)

                            required_support = self.locked_switch_min_support if previous_locked else self.switch_min_support
                            required_confirmation_frames = (
                                self.locked_switch_confirmation_frames
                                if previous_locked
                                else self.switch_confirmation_frames
                            )
                            pending_key = (track_id, previous_stable_canonical_id, self._resolve_merge_alias(observation.get("baseline_canonical_id")) or "")
                            if (
                                evidence["support_count"] >= required_support
                                and evidence["candidate_confidence"] >= self.switch_min_confidence
                            ):
                                last_pending_frame = pending_switch_last_frame.get(pending_key)
                                if last_pending_frame is not None and frame_num - last_pending_frame <= 1:
                                    pending_switch_counts[pending_key] += 1
                                else:
                                    pending_switch_counts[pending_key] = 1
                                pending_switch_last_frame[pending_key] = frame_num

                                if pending_switch_counts[pending_key] < required_confirmation_frames:
                                    canonical_id = previous_stable_canonical_id
                                    guard_reason = "awaiting_multi_frame_confirmation"
                                else:
                                    for stale_key in [key for key in list(pending_switch_counts.keys()) if key[0] == track_id]:
                                        pending_switch_counts.pop(stale_key, None)
                                        pending_switch_last_frame.pop(stale_key, None)
                            else:
                                canonical_id = previous_stable_canonical_id
                                guard_reason = "awaiting_multi_frame_confirmation"
                                for stale_key in [key for key in list(pending_switch_counts.keys()) if key[0] == track_id]:
                                    pending_switch_counts.pop(stale_key, None)
                                    pending_switch_last_frame.pop(stale_key, None)
                        elif pitch_guard.get("metrics"):
                            evidence.update(pitch_guard.get("metrics") or {})

                        if guard_reason:
                            self._log_identity_stability_guard(
                                frame_num=frame_num,
                                track_id=track_id,
                                from_canonical_id=previous_stable_canonical_id,
                                to_canonical_id=self._resolve_merge_alias(observation.get("baseline_canonical_id")),
                                reason=guard_reason,
                                metrics=evidence,
                            )

                # Avoid contradictory same-frame collisions on canonical IDs.
                canonical_id = self._resolve_merge_alias(canonical_id)
                if canonical_id in canonical_in_use and canonical_in_use[canonical_id] != track_id:
                    fallback_canonical_id = previous_stable_canonical_id
                    if fallback_canonical_id and fallback_canonical_id not in canonical_in_use:
                        self._log_identity_stability_guard(
                            frame_num=frame_num,
                            track_id=track_id,
                            from_canonical_id=canonical_id,
                            to_canonical_id=fallback_canonical_id,
                            reason="ambiguous_overlap",
                            metrics={
                                "collision_with_track_id": int(canonical_in_use[canonical_id]),
                            },
                        )
                        canonical_id = fallback_canonical_id

                self.frame_track_to_canonical[frame_num][track_id] = canonical_id
                canonical_in_use[canonical_id] = track_id

                registry_entry = self._ensure_registry_entry(
                    canonical_id,
                    metadata={"object_type": object_type},
                )
                track_info["canonical_id"] = canonical_id
                track_info["display_name"] = registry_entry.display_name
                track_info["jersey_number"] = (
                    registry_entry.jersey_number
                    if object_type in {"player", "referee"}
                    else None
                )
                track_info["identity_locked"] = bool(registry_entry.locked)
                track_info["identity_confidence"] = float(registry_entry.identity_confidence)
                track_info["identity_source"] = registry_entry.source
                track_info["object_type"] = object_type
                track_info["include_in_player_analytics"] = object_type == "player"

                if object_type == "player" and registry_entry.team is not None and track_info.get("team") is None:
                    track_info["team"] = int(registry_entry.team)
                elif object_type != "player":
                    track_info["team"] = None

                current_position, current_space = self._resolve_position(track_info)
                if current_position is not None and current_space == "pitch":
                    self._upsert_anchor_state(
                        canonical_id,
                        metadata={
                            "object_type": object_type,
                            "locked": bool(registry_entry.locked),
                            "source": registry_entry.source,
                            "name": registry_entry.name,
                            "team": registry_entry.team,
                            "last_pitch_position": [float(current_position[0]), float(current_position[1])],
                        },
                        frame_num=frame_num,
                    )

                anchor_state = self.canonical_anchor_state.get(canonical_id, {})
                track_info["initial_pitch_position"] = anchor_state.get("initial_pitch_position")
                track_info["initial_image_position"] = anchor_state.get("initial_image_position")
                track_info["initial_frame"] = anchor_state.get("initial_frame")
                track_info["last_stable_pitch_position"] = anchor_state.get("last_pitch_position")

                if object_type == "player":
                    observation_position = observation.get("position")
                    observation_space = observation.get("position_space")
                    observation_velocity = observation.get("velocity")
                    observation_appearance = observation.get("appearance")
                    observation_appearance_profile = observation.get("appearance_profile")
                    observation_team = observation.get("team")
                    previous_state = track_runtime_state.get(track_id, {})
                    previous_last_stable_canonical = self._resolve_merge_alias(
                        previous_state.get("last_stable_canonical_id") or previous_stable_canonical_id
                    )
                    previous_last_stable_position = previous_state.get("last_stable_position")
                    previous_last_stable_velocity = previous_state.get("last_stable_velocity")
                    previous_last_stable_frame_idx = previous_state.get("last_stable_frame_idx")

                    if identity_state == "stable" or previous_last_stable_canonical is None:
                        last_stable_canonical_id = canonical_id
                        last_stable_position = observation_position
                        last_stable_velocity = observation_velocity
                        last_stable_frame_idx = int(frame_num)
                    else:
                        last_stable_canonical_id = previous_last_stable_canonical or canonical_id
                        last_stable_position = (
                            previous_last_stable_position
                            if previous_last_stable_position is not None
                            else observation_position
                        )
                        last_stable_velocity = (
                            previous_last_stable_velocity
                            if previous_last_stable_velocity is not None
                            else observation_velocity
                        )
                        last_stable_frame_idx = (
                            int(previous_last_stable_frame_idx)
                            if previous_last_stable_frame_idx is not None
                            else int(frame_num)
                        )

                    if (
                        identity_state == "stable"
                        and observation_position is not None
                        and observation_space == "pitch"
                        and previous_last_stable_canonical == canonical_id
                        and previous_last_stable_position is not None
                    ):
                        pitch_frame_gap = max(1, int(observation.get("frame_gap", 1) or 1))
                        pitch_jump_limit = self._pitch_continuity_limit(
                            frame_gap=pitch_frame_gap,
                            locked=self._is_manual_anchor_canonical(canonical_id),
                        )
                        pitch_jump_distance = float(measure_distance(observation_position, previous_last_stable_position))
                        if pitch_jump_distance > pitch_jump_limit:
                            identity_state = "pitch_jump_guard"
                            last_stable_canonical_id = previous_last_stable_canonical
                            last_stable_position = previous_last_stable_position
                            last_stable_velocity = previous_last_stable_velocity
                            last_stable_frame_idx = (
                                int(previous_last_stable_frame_idx)
                                if previous_last_stable_frame_idx is not None
                                else int(frame_num - pitch_frame_gap)
                            )
                            self._log_identity_stability_guard(
                                frame_num=frame_num,
                                track_id=track_id,
                                from_canonical_id=canonical_id,
                                to_canonical_id=last_stable_canonical_id,
                                reason="impossible_pitch_jump_rejected",
                                metrics={
                                    "distance": round(float(pitch_jump_distance), 3),
                                    "continuity_limit": round(float(pitch_jump_limit), 3),
                                    "frame_gap": int(pitch_frame_gap),
                                    "position_space": observation_space,
                                },
                            )

                    track_info["identity_state"] = identity_state
                    track_info["identity_frozen"] = identity_state != "stable"
                    track_info["last_stable_canonical_id"] = last_stable_canonical_id
                    track_info["last_stable_frame_idx"] = int(last_stable_frame_idx)

                    track_runtime_state[track_id] = {
                        "stable_canonical_id": canonical_id,
                        "identity_state": identity_state,
                        "last_stable_canonical_id": last_stable_canonical_id,
                        "last_stable_position": last_stable_position,
                        "last_stable_velocity": last_stable_velocity,
                        "last_stable_frame_idx": int(last_stable_frame_idx),
                        "frame_num": int(frame_num),
                        "position": observation_position,
                        "position_space": observation_space,
                        "velocity": observation_velocity,
                        "appearance_profile": observation_appearance_profile,
                    }

                    if last_stable_position is not None and observation_space == "pitch":
                        self._upsert_anchor_state(
                            canonical_id,
                            metadata={
                                "object_type": object_type,
                                "locked": bool(registry_entry.locked),
                                "source": registry_entry.source,
                                "name": registry_entry.name,
                                "team": track_info.get("team"),
                                "last_pitch_position": [float(last_stable_position[0]), float(last_stable_position[1])],
                            },
                            frame_num=frame_num,
                        )
                        track_info["last_stable_pitch_position"] = self.canonical_anchor_state.get(
                            canonical_id,
                            {},
                        ).get("last_pitch_position")

                    runtime_position = observation_position
                    runtime_space = observation_space
                    runtime_velocity = observation_velocity
                    if identity_state != "stable" and last_stable_position is not None:
                        runtime_position = last_stable_position
                        runtime_space = previous_state.get("position_space") or observation_space
                        runtime_velocity = last_stable_velocity

                    canonical_runtime_state[canonical_id] = {
                        "frame_num": int(frame_num),
                        "position": runtime_position,
                        "position_space": runtime_space,
                        "velocity": runtime_velocity,
                        "team": observation_team if observation_team in (1, 2) else canonical_team_lookup.get(canonical_id),
                        "appearance": observation_appearance or canonical_appearance_lookup.get(canonical_id),
                        "appearance_profile": (
                            observation_appearance_profile
                            or canonical_appearance_profile_lookup.get(canonical_id)
                        ),
                    }

    def sync_registry_from_tracks(self, tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]]) -> None:
        for frame_num, frame_tracks in enumerate(tracks.get("players", [])):
            for raw_track_id, track_info in frame_tracks.items():
                track_id = self._normalize_track_id(raw_track_id)
                object_type = self._normalize_object_type(track_info.get("object_type", self.get_object_type(frame_num, track_id)))
                if object_type == "ignore":
                    continue

                canonical_id = track_info.get("canonical_id") or self.get_canonical_id(frame_num, track_id)
                if canonical_id is None:
                    continue
                canonical_id = self._resolve_merge_alias(canonical_id)
                self.frame_track_to_canonical[frame_num][track_id] = canonical_id
                self.default_track_to_canonical[track_id] = canonical_id

                metadata = {
                    "object_type": object_type,
                    "name": track_info.get("display_name"),
                    "jersey_number": track_info.get("jersey_number"),
                    "team": track_info.get("team"),
                    "identity_locked": track_info.get("identity_locked"),
                    "identity_confidence": track_info.get("identity_confidence"),
                    "initial_pitch_position": track_info.get("initial_pitch_position"),
                    "initial_image_position": track_info.get("initial_image_position"),
                    "initial_frame": track_info.get("initial_frame", frame_num),
                    "last_pitch_position": track_info.get("last_stable_pitch_position"),
                }
                source = track_info.get("identity_source", "auto")
                self._ensure_registry_entry(canonical_id, metadata, source=source)
                self._upsert_anchor_state(canonical_id, metadata=metadata, frame_num=frame_num)

    def detect_conflicts(self, tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]]) -> List[Dict[str, Any]]:
        conflicts = []
        for frame_num, frame_tracks in enumerate(tracks.get("players", [])):
            canonical_to_tracks: Dict[str, List[int]] = defaultdict(list)
            for raw_track_id, track_info in frame_tracks.items():
                track_id = self._normalize_track_id(raw_track_id)
                if self.get_object_type(frame_num, track_id) != "player":
                    continue

                canonical_id = track_info.get("canonical_id") or self.get_canonical_id(frame_num, track_id)
                if canonical_id is None:
                    continue
                canonical_id = self._resolve_merge_alias(canonical_id)
                canonical_to_tracks[canonical_id].append(track_id)

            for canonical_id, track_ids in canonical_to_tracks.items():
                if len(track_ids) > 1:
                    conflicts.append(
                        {
                            "frame_num": int(frame_num),
                            "canonical_id": canonical_id,
                            "track_ids": sorted(int(track_id) for track_id in track_ids),
                            "description": (
                                f"Canonical player {canonical_id} is assigned to multiple boxes in frame {frame_num}."
                            ),
                        }
                    )

        self.conflicts = conflicts
        return conflicts

    def refresh_event_statuses(self) -> None:
        for event in self.suspicious_events:
            related_track_id = event.get("related_track_id")
            if related_track_id is None:
                event["resolved"] = False
                event["resolved_canonical_id"] = None
                continue

            reference_frame = event.get("reference_frame")
            frame_num = event["frame_num"]
            primary_id = self.get_canonical_id(frame_num, event["track_id"])
            related_id = self.get_canonical_id(
                reference_frame if reference_frame is not None else max(frame_num - 1, 0),
                related_track_id,
            )
            is_resolved = bool(primary_id and related_id and primary_id == related_id)
            event["resolved"] = is_resolved
            event["resolved_canonical_id"] = primary_id if is_resolved else None

    def _canonical_debug_rows(self, stats: Dict[str, Dict[str, Any]]) -> List[Dict[str, Any]]:
        rows: List[Dict[str, Any]] = []
        for canonical_id, stat in sorted(
            stats.items(),
            key=lambda item: (item[1].get("first_frame", 10**9), item[0]),
        ):
            rows.append(
                {
                    "canonical_id": canonical_id,
                    "first_frame": stat.get("first_frame"),
                    "last_frame": stat.get("last_frame"),
                    "total_frames_seen": stat.get("total_frames_seen", 0),
                    "total_distance": round(float(stat.get("total_distance", 0.0)), 3),
                    "team": stat.get("team"),
                    "track_ids": stat.get("track_ids", []),
                    "identity_locked": bool(stat.get("identity_locked", False)),
                    "source": stat.get("source", "auto"),
                    "merge_target": stat.get("merge_target"),
                }
            )
        return rows

    def generate_summary(
        self,
        tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]],
        corrections_path: Optional[str] = None,
    ) -> Dict[str, Any]:
        self.refresh_event_statuses()
        conflicts = self.detect_conflicts(tracks)
        resolved_switch_count = sum(1 for event in self.suspicious_events if event.get("resolved"))
        canonical_stats = self._build_canonical_stats(tracks)
        self.canonical_debug_stats = canonical_stats

        active_canonical_players = sum(
            1
            for canonical_id, stat in canonical_stats.items()
            if not stat.get("merge_target")
            and self._normalize_object_type(self.player_registry.get(canonical_id, PlayerRegistryEntry(canonical_id)).object_type)
            == "player"
        )

        merged_fragment_count = len(self.canonical_merge_map)
        unresolved_fragment_count = len(self.unresolved_fragments)
        suppressed_fragments = self.reconciliation_summary.get("suppressed_fragments", [])
        suppressed_fragment_count = int(self.reconciliation_summary.get("suppressed_fragment_count", len(suppressed_fragments)))
        resolved_active_canonical_players = max(0, active_canonical_players - unresolved_fragment_count)
        guard_reason_counts: Dict[str, int] = defaultdict(int)
        for payload in self.identity_stability_logs:
            guard_reason_counts[str(payload.get("reason", "unknown"))] += 1

        return {
            "generated_at": datetime.utcnow().isoformat() + "Z",
            "video_path": self.video_path,
            "corrections_file_path": corrections_path or self.corrections_path,
            "player_registry_count": len(self.player_registry),
            "active_canonical_players": int(resolved_active_canonical_players),
            "raw_active_canonical_players": int(active_canonical_players),
            "manual_assignment_count": len(self.manual_assignments),
            "suspicious_switch_count": len(self.suspicious_events),
            "resolved_switch_count": resolved_switch_count,
            "unresolved_conflict_count": len(conflicts),
            "merged_fragment_count": int(merged_fragment_count),
            "unresolved_fragment_count": int(unresolved_fragment_count),
            "suppressed_fragment_count": int(suppressed_fragment_count),
            "identity_stability_guard_count": int(len(self.identity_stability_logs)),
            "identity_stability_guard_reason_counts": dict(guard_reason_counts),
            "merge_mapping": dict(self.canonical_merge_map),
            "reconciliation_summary": self.reconciliation_summary,
            "canonical_player_debug": self._canonical_debug_rows(canonical_stats),
            "merge_history": self.merge_history,
            "unresolved_fragments": self.unresolved_fragments,
            "suppressed_fragments": suppressed_fragments,
            "suspicious_events": self.suspicious_events,
            "unresolved_conflicts": conflicts,
            "identity_stability_guard_logs": self.identity_stability_logs,
            "canonical_anchor_state": self.canonical_anchor_state,
        }

    def write_summary_report(
        self,
        path: str,
        tracks: Dict[str, List[Dict[Any, Dict[str, Any]]]],
        corrections_path: Optional[str] = None,
    ) -> str:
        directory = os.path.dirname(path)
        if directory:
            os.makedirs(directory, exist_ok=True)

        summary = self.generate_summary(tracks, corrections_path=corrections_path)
        with open(path, "w", encoding="utf-8") as file:
            json.dump(summary, file, indent=2, ensure_ascii=False)
        return path
