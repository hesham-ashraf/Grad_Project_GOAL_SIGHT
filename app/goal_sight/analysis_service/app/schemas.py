"""API request/response contracts (Pydantic).

These describe the wire format between the Flutter app and the service. The
model's own JSON output structure is preserved verbatim inside
``AnalysisResult.raw`` (Phase 7: store everything, rename nothing).
"""

from __future__ import annotations

from enum import Enum
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


class JobStatus(str, Enum):
    """Lifecycle of one upload→analysis job."""

    queued = "queued"                  # accepted, not started
    detecting = "detecting"            # detection→tracking→roles running
    awaiting_naming = "awaiting_naming"  # paused; app must POST names
    analyzing = "analyzing"            # full analysis running after naming
    completed = "completed"            # result ready
    failed = "failed"


class DetectedPlayer(BaseModel):
    """One detected track served to the naming screen."""

    track_id: int
    auto_role: str                     # player | goalkeeper | referee | unknown
    team_id: Optional[int] = None      # detected cluster 0/1 (None for non-players)
    track_length: int = 0              # frames observed (confidence proxy)
    role_confidence: float = 0.0
    crop_url: Optional[str] = None     # representative jersey crop image
    suggested_name: Optional[str] = None  # model's prior name if any


class TeamLegendEntry(BaseModel):
    """Visual legend so the manager can tell team 0 from team 1."""

    team_id: int
    label: str                         # e.g. "Red shirts"
    color_rgb: List[int] = Field(default_factory=list)
    crop_urls: List[str] = Field(default_factory=list)


class NamingData(BaseModel):
    """Everything the naming screen needs after Stage 1 detection."""

    job_id: str
    players: List[DetectedPlayer]
    team_legend: List[TeamLegendEntry]


class JobCreateResponse(BaseModel):
    job_id: str
    status: JobStatus


class JobStatusResponse(BaseModel):
    job_id: str
    status: JobStatus
    stage_label: str = ""              # human label for the progress UI
    progress: float = 0.0              # 0..1 best-effort
    error: Optional[str] = None


class PlayerNameMapping(BaseModel):
    track_id: int
    player_name: str                   # manager-entered name (may be temp)
    player_id: Optional[str] = None    # existing club player id, if linked


class ConfirmPlayersRequest(BaseModel):
    """Stage 2 trigger: names + which detected team is the manager's club."""

    mappings: List[PlayerNameMapping]
    my_team_id: int = Field(..., description="Detected team_id (0 or 1) that is the manager's club")


class AnalysisResult(BaseModel):
    """Normalized result the app reads. Raw model JSONs preserved under `raw`."""

    job_id: str
    my_team_id: int
    # Supabase match_analyses id once persisted (None if the sink is disabled).
    analysis_id: Optional[str] = None
    # File URLs (served by this service or, later, Supabase Storage signed URLs).
    analyzed_video_url: Optional[str] = None
    heatmap_urls: Dict[str, str] = Field(default_factory=dict)  # key -> url
    # The five model outputs, structure-preserved (Phase 7).
    raw: Dict[str, Any] = Field(default_factory=dict)
    # track_id -> name/player_id mapping that was applied (Phase 4).
    player_mapping: Dict[str, Dict[str, Any]] = Field(default_factory=dict)
