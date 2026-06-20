"""Persist a finished analysis into Supabase (DB rows + Storage files).

This is the "backend uploads outputs to Supabase, app fetches" half of the
approved architecture. It runs with the **service-role key** (bypasses RLS;
stamps owner_club_id explicitly) after the model finishes Stage 2.

Mapping (model JSON → adapted schema from migration 053):
  final_report   → match_analyses (header) + ai_recommendations + team blocks
  team_tactical  → team_match_analysis (labels) + team_tactical_metrics
  player_analytics + final_report → match_player_analysis (per-player verdict)
  speed_distance → player_tracking_metrics
  possession     → match_analyses (summary) + match_possession_timeline
  all 5 JSONs    → analysis_artifacts (artifact_type='model_output', verbatim)
  video + heatmaps → Storage (signed URLs stored on the rows)

team_id 0/1 → home/away: the team the manager picked (``my_team_id``) is the
home/club team. Only home-team tracks are resolved/created as club ``players``;
opponent tracks are stored name-only (player_id NULL) so the squad stays clean.
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any, Dict, List, Optional

from . import settings


def _norm(name: str) -> str:
    return re.sub(r"\s+", " ", (name or "").strip().lower())


class SupabaseSink:
    def __init__(self) -> None:
        from supabase import create_client  # lazy: keep API-only runs import-free

        self._sb = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_KEY)

    # ── public entry ────────────────────────────────────────────────────────
    def persist(self, job, result: Dict[str, Any]) -> Optional[str]:
        """Write everything; return the new match_analyses id (or None)."""
        club_id = job.club_id
        if not club_id:
            raise RuntimeError("Job has no club_id; cannot scope analysis rows.")

        files = result.get("files", {})
        raw: Dict[str, Any] = files.get("raw", {})
        final = raw.get("final_report", {}) or {}
        possession = raw.get("possession", {}) or {}
        tactical = {t["team_id"]: t for t in (raw.get("team_tactical", {}) or {}).get("teams", [])}
        my_team = int(result.get("my_team_id", 0))
        mapping: Dict[str, dict] = result.get("player_mapping", {})  # track_id(str) -> {...}

        # 1) Upload artifacts to Storage → signed URLs.
        video_url = self._upload_video(club_id, job.stem, files.get("analyzed_video_path"))
        heatmap_urls = self._upload_heatmaps(club_id, job.stem, files.get("heatmap_paths", {}))

        # 2) Per-team average ratings (model gives none) from player ratings.
        players_perf = (raw.get("player_analytics", {}) or {}).get("players", [])
        team_avg = self._team_avg_ratings(players_perf)

        # 2b) Match intensity (0–100). The model emits no single intensity score,
        #     so derive one from the teams' average on-ball speed (km/h).
        intensity = self._match_intensity(tactical)

        # 3) Analysis header.
        analysis_id = self._insert_header(
            job, club_id, my_team, final, possession, video_url,
            heatmap_urls.get(f"team{my_team}"), team_avg, intensity,
        )

        # 4) Raw JSONs (Phase 7 — keep everything, verbatim).
        self._safe(self._insert_artifacts, analysis_id, raw)

        # 5) Team tactical blocks + metrics.
        self._safe(self._insert_teams, analysis_id, my_team, final, tactical,
                   possession, team_avg, job.home_team, job.away_team)

        # 6) Per-player verdicts (+ resolve/create club players for my team).
        self._safe(self._insert_players, analysis_id, club_id, my_team,
                   players_perf, final, mapping, heatmap_urls)

        # 7) Raw per-track speed/distance.
        self._safe(self._insert_tracking, analysis_id,
                   (raw.get("speed_distance", {}) or {}).get("tracks", []))

        # 8) Possession timeline + recommendations + heatmap rows.
        self._safe(self._insert_timeline, analysis_id, possession.get("timeline", []))
        self._safe(self._insert_recommendations, analysis_id, final)
        self._safe(self._insert_heatmaps, analysis_id, club_id, heatmap_urls)

        return analysis_id

    # ── storage ───────────────────────────────────────────────────────────--
    def _upload_video(self, club_id: str, stem: str, path: Optional[str]) -> Optional[str]:
        if not path or not Path(path).is_file():
            return None
        key = f"{club_id}/analyzed/{stem}.mp4"
        return self._upload(settings.BUCKET_VIDEOS, key, Path(path), "video/mp4")

    def _upload_heatmaps(self, club_id: str, stem: str, paths: Dict[str, str]) -> Dict[str, str]:
        urls: Dict[str, str] = {}
        for key, p in (paths or {}).items():
            if p and Path(p).is_file():
                obj = f"{club_id}/{stem}/{key}.png"
                url = self._upload(settings.BUCKET_HEATMAPS, obj, Path(p), "image/png")
                if url:
                    urls[key] = url
        return urls

    def _upload(self, bucket: str, key: str, path: Path, content_type: str) -> Optional[str]:
        try:
            data = path.read_bytes()
            store = self._sb.storage.from_(bucket)
            try:
                store.upload(key, data, {"content-type": content_type, "upsert": "true"})
            except Exception:
                store.update(key, data, {"content-type": content_type})  # already exists
            signed = store.create_signed_url(key, 60 * 60 * 24 * 365)  # 1 year
            return signed.get("signedURL") or signed.get("signedUrl") or signed.get("signed_url")
        except Exception as exc:  # noqa: BLE001
            print(f"[sink] upload failed {bucket}/{key}: {exc}")
            return None

    # ── inserts ─────────────────────────────────────────────────────────────
    def _insert_header(self, job, club_id, my_team, final, possession, video_url,
                       my_heatmap_url, team_avg, intensity=None) -> str:
        row = {
            "intensity": intensity,
            "owner_club_id": club_id,
            "generated_by": job.uploaded_by,
            "status": "completed",
            "home_team_name": job.home_team,
            "away_team_name": job.away_team,
            "date_label": job.match_date,
            "result_status": "FT",
            "summary": final.get("summary"),
            "overall_narrative": final.get("summary"),
            "dominant_team": final.get("dominant_team"),
            "key_insights": final.get("key_insights", []),
            "recommendations": final.get("recommendations", []),
            "key_moments": [],
            "motm_track_id": final.get("man_of_the_match"),
            "weakest_track_id": final.get("weakest_player"),
            "home_model_team_id": my_team,
            "team0_possession": possession.get("team_0_possession"),
            "team1_possession": possession.get("team_1_possession"),
            "possession_dominant_team": possession.get("dominant_team"),
            "total_frames": possession.get("total_frames"),
            "home_avg_rating": team_avg.get(my_team),
            "away_avg_rating": team_avg.get(1 - my_team),
            "analyzed_video_url": video_url,
            "heatmap_url": my_heatmap_url,
        }
        res = self._sb.table("match_analyses").insert(_clean(row)).execute()
        return res.data[0]["id"]

    def _insert_artifacts(self, analysis_id: str, raw: Dict[str, Any]) -> None:
        rows = [{
            "match_analysis_id": analysis_id,
            "artifact_type": "model_output",
            "data": {"model_name": name, "payload": payload},
        } for name, payload in raw.items()]
        if rows:
            self._sb.table("analysis_artifacts").insert(rows).execute()

    def _insert_teams(self, analysis_id, my_team, final, tactical, possession, team_avg,
                      home_name=None, away_name=None) -> None:
        rows, metric_rows = [], []
        poss = {0: possession.get("team_0_possession"), 1: possession.get("team_1_possession")}
        for t in final.get("teams", []):
            tid = int(t["team_id"])
            tac = tactical.get(tid, {})
            is_home = tid == my_team
            rows.append(_clean({
                "match_analysis_id": analysis_id,
                "side": "home" if is_home else "away",
                # Carry the human team name onto the block so the app shows it
                # instead of an empty label.
                "team_name": (home_name if is_home else away_name),
                "model_team_id": tid,
                "possession": _int(poss.get(tid)),
                "style": t.get("style"),
                "pressure_style": t.get("pressure"),
                "compactness": t.get("compactness"),
                "transition_speed": t.get("transition_speed"),
                "team_shape": tac.get("team_shape"),
                "attacking_zone": tac.get("attacking_zone"),
                "build_up_style": tac.get("build_up_style"),
                "attacking_zones": [tac["attacking_zone"]] if tac.get("attacking_zone") else [],
                "avg_rating": team_avg.get(tid),
                "top_players": [], "worst_players": [],
            }))
            m = tac.get("metrics", {})
            metric_rows.append(_clean({
                "match_analysis_id": analysis_id, "model_team_id": tid,
                "compactness_m": m.get("compactness_m"), "width_m": m.get("width_m"),
                "depth_m": m.get("depth_m"), "centroid_x": m.get("centroid_x"),
                "centroid_y": m.get("centroid_y"), "block_height_m": m.get("block_height_m"),
                "avg_speed_kmh": m.get("avg_speed_kmh"), "reasons": tac.get("reasons", {}),
            }))
        if rows:
            self._sb.table("team_match_analysis").insert(rows).execute()
        if metric_rows:
            self._sb.table("team_tactical_metrics").insert(metric_rows).execute()

    def _insert_players(self, analysis_id, club_id, my_team, players_perf, final,
                        mapping, heatmap_urls) -> None:
        impact_by_track = {p["track_id"]: p for p in final.get("players", [])}
        motm = final.get("man_of_the_match")
        worst = final.get("weakest_player")
        squad = self._load_squad(club_id)
        rows = []
        for p in players_perf:
            tid = int(p["track_id"])
            model_team = p.get("team_id")
            is_home = model_team == my_team
            mapped = mapping.get(str(tid), {})
            player_id = self._resolve_player_id(club_id, squad, mapped, p, is_home)
            best_key = f"team{model_team}_best_player"
            rows.append(_clean({
                "match_analysis_id": analysis_id,
                "player_id": player_id,
                "player_key": player_id or _norm(p.get("player_display_name", "")),
                "player_name": mapped.get("player_name") or p.get("player_display_name"),
                "player_position": p.get("role"),
                "track_id": tid,
                "model_team_id": model_team,
                "rating": p.get("player_rating"),
                # DB enum is lowercase (excellent/good/average/poor/terrible);
                # the model emits Title Case ("Excellent").
                "performance_status": (p.get("performance_status") or "").lower() or None,
                "impact": (impact_by_track.get(tid) or {}).get("impact"),
                "insight": p.get("insight"),
                "work_rate": p.get("work_rate"),
                "activity_level_label": p.get("activity_level"),
                "fatigue_label": p.get("fatigue_level"),
                "total_distance_m": p.get("total_distance_m"),
                "avg_speed_kmh": p.get("avg_speed_kmh"),
                "max_speed_kmh": p.get("max_speed_kmh"),
                "is_motm": tid == motm,
                "is_worst": tid == worst,
                "heatmap_url": heatmap_urls.get(best_key) if is_home else None,
            }))
        if rows:
            # Insert in one call → fires the player_intelligence aggregation
            # trigger for every row whose player_id is set (home squad only).
            self._sb.table("match_player_analysis").insert(rows).execute()

    def _insert_tracking(self, analysis_id, tracks) -> None:
        rows = [_clean({
            "match_analysis_id": analysis_id,
            "track_id": int(t["track_id"]),
            "model_team_id": t.get("team_id"),
            "role": t.get("role"),
            "player_name": t.get("player_name") or t.get("player_display_name"),
            "total_distance_m": t.get("total_distance_m"),
            "avg_speed_kmh": t.get("avg_speed_kmh"),
            "max_speed_kmh": t.get("max_speed_kmh"),
            "valid_samples": t.get("valid_samples"),
            "invalid_jumps": t.get("invalid_jumps"),
            "insufficient_data": t.get("insufficient_data", False),
        }) for t in tracks]
        if rows:
            self._sb.table("player_tracking_metrics").insert(rows).execute()

    def _insert_timeline(self, analysis_id, timeline) -> None:
        rows = [{"match_analysis_id": analysis_id, "frame_number": int(f), "team_id": team}
                for f, team in timeline]
        # Chunk: 750+ rows per match.
        for i in range(0, len(rows), 500):
            self._sb.table("match_possession_timeline").insert(rows[i:i + 500]).execute()

    def _insert_recommendations(self, analysis_id, final) -> None:
        rows = []
        for i, r in enumerate(final.get("recommendations", [])):
            rows.append({"match_analysis_id": analysis_id, "kind": "recommendation",
                         "text": str(r), "sort_order": i})
        for i, r in enumerate(final.get("key_insights", [])):
            rows.append({"match_analysis_id": analysis_id, "kind": "key_insight",
                         "text": str(r), "sort_order": i})
        if rows:
            self._sb.table("ai_recommendations").insert(rows).execute()

    def _insert_heatmaps(self, analysis_id, club_id, heatmap_urls) -> None:
        rows = []
        for key, url in heatmap_urls.items():
            best = key.endswith("_best_player")
            team = int(key[4]) if key.startswith("team") and key[4:5].isdigit() else None
            rows.append(_clean({
                "match_analysis_id": analysis_id, "owner_club_id": club_id,
                "scope": "best_player" if best else "team",
                "model_team_id": team, "url": url,
            }))
        if rows:
            self._sb.table("heatmaps").insert(rows).execute()

    # ── player resolution (Phase 4: track_id → player_id) ────────────────────
    def _load_squad(self, club_id: str) -> List[dict]:
        res = (self._sb.table("players").select("id, full_name, jersey_number")
               .eq("owner_club_id", club_id).execute())
        return res.data or []

    def _resolve_player_id(self, club_id, squad, mapped, perf, is_home) -> Optional[str]:
        # Explicit link from the naming screen wins.
        if mapped.get("player_id"):
            return mapped["player_id"]
        # Opponent tracks are not this club's players → store name-only.
        if not is_home:
            return None
        name = _norm(mapped.get("player_name") or perf.get("player_display_name", ""))
        if not name or name.startswith("player "):
            return None  # unnamed track → don't pollute the squad
        for p in squad:
            if _norm(p.get("full_name", "")) == name:
                return p["id"]
        # Newly named home player → create in the club squad.
        created = self._sb.table("players").insert({
            "full_name": (mapped.get("player_name") or perf.get("player_display_name")).strip(),
            "team_id": club_id, "owner_club_id": club_id,
            "position": perf.get("role"), "season_rating": perf.get("player_rating"),
        }).execute()
        pid = created.data[0]["id"]
        squad.append({"id": pid, "full_name": mapped.get("player_name"), "jersey_number": None})
        return pid

    # ── helpers ───────────────────────────────────────────────────────────--
    @staticmethod
    def _match_intensity(tactical: Dict[int, dict]) -> Optional[int]:
        """Derive a 0–100 intensity from teams' average on-ball speed (km/h).
        ~12 km/h sustained ≈ a full-tilt match → 100. None if no speeds."""
        speeds = []
        for t in tactical.values():
            s = (t.get("metrics", {}) or {}).get("avg_speed_kmh")
            if s is not None:
                try:
                    speeds.append(float(s))
                except (TypeError, ValueError):
                    pass
        if not speeds:
            return None
        avg = sum(speeds) / len(speeds)
        return max(0, min(100, round(avg / 12.0 * 100)))

    @staticmethod
    def _team_avg_ratings(players_perf) -> Dict[int, float]:
        sums: Dict[int, List[float]] = {}
        for p in players_perf:
            t = p.get("team_id")
            if t in (0, 1) and p.get("player_rating") is not None:
                sums.setdefault(t, []).append(float(p["player_rating"]))
        return {t: round(sum(v) / len(v), 2) for t, v in sums.items() if v}

    def _safe(self, fn, *args) -> None:
        try:
            fn(*args)
        except Exception as exc:  # noqa: BLE001 — one section must not abort the rest
            print(f"[sink] {fn.__name__} failed: {exc}")


def _int(v):
    try:
        return int(round(float(v)))
    except (TypeError, ValueError):
        return None


def _clean(row: dict) -> dict:
    """Drop None values so DB defaults/NULLs apply cleanly."""
    return {k: v for k, v in row.items() if v is not None}
