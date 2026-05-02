"""
Opta-Style Tracking Data Structure
================================
Professional tracking data format with real-world coordinates (meters)

 Raw Tracking Frame Format:
{
  "frame": 10234,
  "timestamp": 425.33,
  "players": {
    "12": { "x": 34.2, "y": 51.7, "speed": 12.5, "team": 1 },
    "7":  { "x": 61.1, "y": 22.9, "speed": 8.3, "team": 2 }
  },
  "ball": { "x": 49.3, "y": 33.2 },
    "game_state": "live"
}

Pitch Model (FIFA Standard):
(0,0) -------- (105,0)
  |                |
  |                |
(0,68) ------ (105,68)

Coordinates are in real meters, not pixels!
"""

import json
import numpy as np
from dataclasses import dataclass, field, asdict
from typing import Any, Dict, List, Optional, Tuple
from enum import Enum
from datetime import datetime


class GameState(Enum):
    """حالة اللعب - تُستخدم لاستبعاد المسافة في أوقات التوقف"""
    LIVE = "live"                                    
    DEAD_BALL = "dead_ball"                                             
    STOPPAGE = "stoppage"                                          
    SUBSTITUTION = "substitution"           
    HALFTIME = "halftime"                     


@dataclass
class Position:
    """موقع في الملعب بالمتر"""
    x: float                       
    y: float                      
    
    def to_tuple(self) -> Tuple[float, float]:
        return (self.x, self.y)
    
    def distance_to(self, other: 'Position') -> float:
        """حساب المسافة بين نقطتين بالمتر"""
        return np.sqrt((self.x - other.x)**2 + (self.y - other.y)**2)
    
    @staticmethod
    def from_tuple(pos: Tuple[float, float]) -> 'Position':
        return Position(x=pos[0], y=pos[1])
    
    def is_valid(self, pitch_length: float = 105.0, pitch_width: float = 68.0, margin: float = 5.0) -> bool:
        """التحقق من صحة الموقع"""
        return (-margin <= self.x <= pitch_length + margin and 
                -margin <= self.y <= pitch_width + margin)
    
    def clamp(self, pitch_length: float = 105.0, pitch_width: float = 68.0) -> 'Position':
        """تحديد الموقع ضمن حدود الملعب"""
        return Position(
            x=max(0, min(self.x, pitch_length)),
            y=max(0, min(self.y, pitch_width))
        )


@dataclass
class PlayerData:
    """بيانات لاعب في فريم واحد"""
    track_id: Any
    position: Position
    canonical_id: Optional[str] = None
    display_name: str = ""
    jersey_number: Optional[str] = None
    identity_locked: bool = False
    identity_confidence: float = 0.0
    speed: float = 0.0                 
    distance: float = 0.0                                       
    team: int = 0                        
    is_goalkeeper: bool = False
    has_ball: bool = False
    
                   
    raw_speed: float = 0.0                           
    acceleration: float = 0.0          
    direction: float = 0.0                                   
    
    def to_dict(self) -> dict:
        track_id = int(self.track_id) if isinstance(self.track_id, np.integer) else self.track_id
        return {
            "track_id": track_id,
            "canonical_id": self.canonical_id,
            "display_name": self.display_name or self.canonical_id or str(track_id),
            "jersey_number": self.jersey_number,
            "identity_locked": self.identity_locked,
            "identity_confidence": round(self.identity_confidence, 3),
            "x": round(self.position.x, 2),
            "y": round(self.position.y, 2),
            "speed": round(self.speed, 2),
            "distance": round(self.distance, 1),
            "team": self.team,
            "is_goalkeeper": self.is_goalkeeper,
            "has_ball": self.has_ball
        }


@dataclass
class BallData:
    """بيانات الكرة في فريم واحد"""
    position: Optional[Position]
    speed: float = 0.0                 
    height: float = 0.0                                
    in_play: bool = True                                  
    
    def to_dict(self) -> dict:
        if self.position is None:
            return {"x": None, "y": None}
        return {
            "x": round(self.position.x, 2),
            "y": round(self.position.y, 2),
            "speed": round(self.speed, 2),
            "in_play": self.in_play
        }


@dataclass
class TrackingFrame:
    """
    فريم تتبع واحد - يحتوي على كل البيانات لحظة واحدة
    
     Raw Tracking Frame Format (Opta Style)
    """
    frame: int                                           
    timestamp: float                                         
    players: Dict[str, PlayerData]                                   
    ball: Optional[BallData] = None
    game_state: GameState = GameState.LIVE
    
                   
    match_clock: float = 0.0                                      
    period: int = 1                                          
    
    def to_dict(self) -> dict:
        """تحويل لـ JSON format"""
        return {
            "frame": self.frame,
            "timestamp": round(self.timestamp, 3),
            "match_clock": round(self.match_clock, 1),
            "period": self.period,
            "game_state": self.game_state.value,
            "players": {
                str(track_id): player.to_dict() 
                for track_id, player in self.players.items()
            },
            "ball": self.ball.to_dict() if self.ball else None
        }


@dataclass
class TrackingSession:
    """
    جلسة تتبع كاملة - تحتوي على كل الفريمات
    """
    frames: List[TrackingFrame] = field(default_factory=list)
    
                                    
    pitch_length: float = 105.0
    pitch_width: float = 68.0
    
                     
    fps: float = 24.0
    video_path: str = ""
    
                    
    home_team: str = "Team 1"
    away_team: str = "Team 2"
    match_date: str = ""
    corrections_file_path: str = ""
    suspicious_switch_count: int = 0
    resolved_switch_count: int = 0
    unresolved_conflict_count: int = 0
    active_canonical_players: int = 0
    merged_fragment_count: int = 0
    unresolved_fragment_count: int = 0
    
              
    total_frames: int = 0
    duration_seconds: float = 0.0
    
    def add_frame(self, frame: TrackingFrame):
        """إضافة فريم جديد"""
        self.frames.append(frame)
        self.total_frames = len(self.frames)
        self.duration_seconds = self.total_frames / self.fps
    
    def get_frame(self, frame_num: int) -> Optional[TrackingFrame]:
        """الحصول على فريم بالرقم"""
        if 0 <= frame_num < len(self.frames):
            return self.frames[frame_num]
        return None
    
    def get_player_trajectory(self, track_id: Any) -> List[Tuple[int, Position]]:
        """الحصول على مسار لاعب معين"""
        trajectory = []
        player_key = str(track_id)
        for frame in self.frames:
            if player_key in frame.players:
                trajectory.append((frame.frame, frame.players[player_key].position))
        return trajectory
    
    def get_player_stats(self, track_id: Any) -> dict:
        """الحصول على إحصائيات لاعب"""
        speeds = []
        positions = []
        last_distance = 0
        player_key = str(track_id)
        
        for frame in self.frames:
            if player_key in frame.players:
                player = frame.players[player_key]
                speeds.append(player.speed)
                positions.append(player.position.to_tuple())
                last_distance = player.distance
        
        if not speeds:
            return {}
        
        return {
            "track_id": track_id,
            "total_distance_m": round(last_distance, 1),
            "max_speed_kmh": round(max(speeds), 2),
            "avg_speed_kmh": round(np.mean(speeds), 2),
            "appearances": len(speeds),
            "avg_position": {
                "x": round(np.mean([p[0] for p in positions]), 2),
                "y": round(np.mean([p[1] for p in positions]), 2)
            }
        }
    
    def to_json(self, filepath: str):
        """حفظ البيانات كـ JSON"""
        data = {
            "metadata": {
                "pitch_length": self.pitch_length,
                "pitch_width": self.pitch_width,
                "fps": self.fps,
                "video_path": self.video_path,
                "home_team": self.home_team,
                "away_team": self.away_team,
                "match_date": self.match_date or datetime.now().isoformat(),
                "total_frames": self.total_frames,
                "duration_seconds": round(self.duration_seconds, 2),
                "corrections_file_path": self.corrections_file_path,
                "suspicious_switch_count": self.suspicious_switch_count,
                "resolved_switch_count": self.resolved_switch_count,
                "unresolved_conflict_count": self.unresolved_conflict_count,
                "active_canonical_players": self.active_canonical_players,
                "merged_fragment_count": self.merged_fragment_count,
                "unresolved_fragment_count": self.unresolved_fragment_count,
            },
            "frames": [frame.to_dict() for frame in self.frames]
        }
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        print(f" Saved tracking data: {filepath} ({self.total_frames} frames)")
    
    @staticmethod
    def from_json(filepath: str) -> 'TrackingSession':
        """تحميل البيانات من JSON"""
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        session = TrackingSession(
            pitch_length=data['metadata'].get('pitch_length', 105.0),
            pitch_width=data['metadata'].get('pitch_width', 68.0),
            fps=data['metadata'].get('fps', 24.0),
            video_path=data['metadata'].get('video_path', ''),
            home_team=data['metadata'].get('home_team', 'Team 1'),
            away_team=data['metadata'].get('away_team', 'Team 2'),
            match_date=data['metadata'].get('match_date', ''),
            corrections_file_path=data['metadata'].get('corrections_file_path', ''),
            suspicious_switch_count=data['metadata'].get('suspicious_switch_count', 0),
            resolved_switch_count=data['metadata'].get('resolved_switch_count', 0),
            unresolved_conflict_count=data['metadata'].get('unresolved_conflict_count', 0),
            active_canonical_players=data['metadata'].get('active_canonical_players', 0),
            merged_fragment_count=data['metadata'].get('merged_fragment_count', 0),
            unresolved_fragment_count=data['metadata'].get('unresolved_fragment_count', 0),
        )
        
        for frame_data in data['frames']:
            players = {}
            for player_key, player_data in frame_data.get('players', {}).items():
                track_id = player_data.get('track_id', player_key)
                players[str(player_key)] = PlayerData(
                    track_id=track_id,
                    position=Position(x=player_data['x'], y=player_data['y']),
                    canonical_id=player_data.get('canonical_id'),
                    display_name=player_data.get('display_name', ''),
                    jersey_number=player_data.get('jersey_number'),
                    identity_locked=player_data.get('identity_locked', False),
                    identity_confidence=player_data.get('identity_confidence', 0.0),
                    speed=player_data.get('speed', 0),
                    distance=player_data.get('distance', 0),
                    team=player_data.get('team', 0),
                    is_goalkeeper=player_data.get('is_goalkeeper', False),
                    has_ball=player_data.get('has_ball', False)
                )
            
            ball_data = frame_data.get('ball')
            ball = None
            if ball_data and ball_data.get('x') is not None:
                ball = BallData(
                    position=Position(x=ball_data['x'], y=ball_data['y']),
                    speed=ball_data.get('speed', 0),
                    in_play=ball_data.get('in_play', True)
                )
            
            frame = TrackingFrame(
                frame=frame_data['frame'],
                timestamp=frame_data['timestamp'],
                players=players,
                ball=ball,
                game_state=GameState(frame_data.get('game_state', 'live')),
                match_clock=frame_data.get('match_clock', 0),
                period=frame_data.get('period', 1)
            )
            session.add_frame(frame)
        
        return session


class TrackingDataBuilder:
    """
    بناء بيانات التتبع من tracks الموجودة
    """
    
    def __init__(
        self,
        fps: float = 24.0,
        pitch_length: float = 105.0,
        pitch_width: float = 68.0,
        identity_metadata: Optional[Dict[str, Any]] = None,
    ):
        self.fps = fps
        self.pitch_length = pitch_length
        self.pitch_width = pitch_width
        identity_metadata = identity_metadata or {}
        self.session = TrackingSession(
            fps=fps,
            pitch_length=pitch_length,
            pitch_width=pitch_width,
            corrections_file_path=identity_metadata.get('corrections_file_path', ''),
            suspicious_switch_count=identity_metadata.get('suspicious_switch_count', 0),
            resolved_switch_count=identity_metadata.get('resolved_switch_count', 0),
            unresolved_conflict_count=identity_metadata.get('unresolved_conflict_count', 0),
            active_canonical_players=identity_metadata.get('active_canonical_players', 0),
            merged_fragment_count=identity_metadata.get('merged_fragment_count', 0),
            unresolved_fragment_count=identity_metadata.get('unresolved_fragment_count', 0),
        )
    
    def build_from_tracks(self, tracks: dict) -> TrackingSession:
        """
        بناء TrackingSession من tracks dictionary
        
        tracks format:
        {
            'players': [{track_id: {'position_transformed': [x, y], 'team': 1, ...}}, ...],
            'ball': [{1: {'position_transformed': [x, y], ...}}, ...],
            'referees': [...]
        }
        """
        num_frames = len(tracks.get('players', []))
        canonical_key_collisions = 0
        
        for frame_num in range(num_frames):
            timestamp = frame_num / self.fps
            
                                  
            players = {}
            for track_id, track_info in tracks['players'][frame_num].items():
                object_type = str(track_info.get('object_type', 'player')).strip().lower()
                if object_type != 'player':
                    continue

                pos = track_info.get('position_transformed')
                if pos is None or not isinstance(pos, (list, tuple)) or len(pos) < 2:
                    continue
                
                position = Position(x=float(pos[0]), y=float(pos[1]))
                if not position.is_valid(self.pitch_length, self.pitch_width):
                    position = position.clamp(self.pitch_length, self.pitch_width)

                canonical_id = track_info.get('canonical_id')
                base_player_key = str(canonical_id or track_id)
                player_key = base_player_key
                if player_key in players:
                    # Preserve both boxes when the same canonical identity is duplicated
                    # in one frame (conflict state) instead of overwriting observations.
                    canonical_key_collisions += 1
                    player_key = f"{base_player_key}__track_{track_id}"

                players[player_key] = PlayerData(
                    track_id=track_id,
                    position=position,
                    canonical_id=canonical_id,
                    display_name=track_info.get('display_name', canonical_id or str(track_id)),
                    jersey_number=track_info.get('jersey_number'),
                    identity_locked=track_info.get('identity_locked', False),
                    identity_confidence=track_info.get('identity_confidence', 0.0),
                    speed=track_info.get('speed', 0),
                    distance=track_info.get('distance', 0),
                    team=track_info.get('team', 0),
                    is_goalkeeper=track_info.get('is_goalkeeper', False),
                    has_ball=track_info.get('has_ball', False)
                )
            
                               
            ball = None
            if 'ball' in tracks and frame_num < len(tracks['ball']):
                ball_info = tracks['ball'][frame_num].get(1, {})
                ball_pos = ball_info.get('position_transformed')
                if ball_pos and isinstance(ball_pos, (list, tuple)) and len(ball_pos) >= 2:
                    ball = BallData(
                        position=Position(x=float(ball_pos[0]), y=float(ball_pos[1])),
                        speed=ball_info.get('speed', 0),
                        in_play=True
                    )
            
                              
            game_state = self._detect_game_state(players, ball)
            
                          
            frame = TrackingFrame(
                frame=frame_num,
                timestamp=timestamp,
                players=players,
                ball=ball,
                game_state=game_state,
                match_clock=timestamp / 60.0,                
                period=1 if timestamp < 45 * 60 else 2              
            )
            
            self.session.add_frame(frame)

        if canonical_key_collisions > 0:
            print(
                " WARNING: canonical identity collisions detected during export "
                f"({canonical_key_collisions} duplicated frame entries preserved with suffixed keys)"
            )
        
        return self.session
    
    def _detect_game_state(self, players: Dict[str, PlayerData], ball: Optional[BallData]) -> GameState:
        """
        تحديد حالة اللعب - يمكن تحسينها لاحقًا
        """
                               
        if ball and ball.position:
            if not ball.position.is_valid(self.pitch_length, self.pitch_width, margin=0):
                return GameState.DEAD_BALL
        
                         
        if ball is None or ball.position is None:
            return GameState.DEAD_BALL
        
        return GameState.LIVE
