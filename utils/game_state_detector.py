"""
Game State Detector
===================
تحديد حالة اللعب لاستبعاد المسافات في أوقات التوقف

Game States:
- LIVE: الكرة في اللعب
- DEAD_BALL: كرة ميتة (خارج الحدود، فاول، إلخ)
- STOPPAGE: توقف اللعب (إصابة، VAR)
- SUBSTITUTION: تبديل
- HALFTIME: استراحة

Detection Methods:
1. Ball position (outside pitch = dead ball)
2. Ball speed (very high → potential shot/out)
3. Player movement patterns (all standing = possible stoppage)
4. Ball visibility (no ball detected = possible stoppage)
"""

import numpy as np
from collections import deque
from typing import Dict, List, Optional, Tuple
from enum import Enum


class GameState(Enum):
    """حالات اللعب"""
    LIVE = "live"
    DEAD_BALL = "dead_ball"
    STOPPAGE = "stoppage"
    SUBSTITUTION = "substitution"
    HALFTIME = "halftime"
    GOAL_KICK = "goal_kick"
    CORNER = "corner"
    FREE_KICK = "free_kick"
    PENALTY = "penalty"
    KICKOFF = "kickoff"


class GameStateDetector:
    """
    كاشف حالة اللعب
    """
    
    def __init__(self, 
                 fps: float = 24.0,
                 pitch_length: float = 105.0,
                 pitch_width: float = 68.0):
        """
        تهيئة الكاشف
        
        Args:
            fps: معدل الإطارات
            pitch_length: طول الملعب بالمتر
            pitch_width: عرض الملعب بالمتر
        """
        self.fps = fps
        self.pitch_length = pitch_length
        self.pitch_width = pitch_width
        
                     
        self.ball_history: deque = deque(maxlen=30)
        self.ball_missing_count = 0
        
                        
        self.player_movement_history: deque = deque(maxlen=30)
        
                        
        self.current_state = GameState.LIVE
        self.state_history: List[GameState] = []
        
                
        self.consecutive_dead_frames = 0
        self.consecutive_live_frames = 0
        
                 
        self.ball_out_margin = 2.0                        
        self.min_dead_frames = 5                                      
        self.min_live_frames = 3                                       
        self.standing_threshold = 2.0                           
    
    def detect_state(self,
                     ball_position: Optional[Tuple[float, float]],
                     ball_speed: float,
                     player_positions: Dict[int, Tuple[float, float]],
                     player_speeds: Dict[int, float]) -> GameState:
        """
        تحديد حالة اللعب الحالية
        
        Args:
            ball_position: موقع الكرة (x, y) بالمتر، أو None إذا غير مرئية
            ball_speed: سرعة الكرة km/h
            player_positions: مواقع اللاعبين
            player_speeds: سرعات اللاعبين
        
        Returns:
            GameState: حالة اللعب المحددة
        """
                           
        if ball_position:
            self.ball_history.append(ball_position)
            self.ball_missing_count = 0
        else:
            self.ball_missing_count += 1
        
                            
        avg_speed = np.mean(list(player_speeds.values())) if player_speeds else 0
        self.player_movement_history.append(avg_speed)
        
                      
        is_dead = self._check_dead_ball(ball_position, ball_speed, player_speeds)
        
                       
        if is_dead:
            self.consecutive_dead_frames += 1
            self.consecutive_live_frames = 0
            
            if self.consecutive_dead_frames >= self.min_dead_frames:
                new_state = self._classify_dead_ball_type(ball_position, player_positions)
            else:
                new_state = self.current_state
        else:
            self.consecutive_live_frames += 1
            self.consecutive_dead_frames = 0
            
            if self.consecutive_live_frames >= self.min_live_frames:
                new_state = GameState.LIVE
            else:
                new_state = self.current_state
        
        self.current_state = new_state
        self.state_history.append(new_state)
        
        return new_state
    
    def _check_dead_ball(self,
                         ball_position: Optional[Tuple[float, float]],
                         ball_speed: float,
                         player_speeds: Dict[int, float]) -> bool:
        """
        التحقق من أن الكرة ميتة
        """
                                  
        if self.ball_missing_count > 10:
            return True
        
                              
        if ball_position:
            x, y = ball_position
            if (x < -self.ball_out_margin or 
                x > self.pitch_length + self.ball_out_margin or
                y < -self.ball_out_margin or 
                y > self.pitch_width + self.ball_out_margin):
                return True
        
                                         
        if player_speeds:
            standing_count = sum(1 for s in player_speeds.values() 
                               if s < self.standing_threshold)
            standing_ratio = standing_count / len(player_speeds)
            
            if standing_ratio > 0.8:                          
                return True
        
                               
        if ball_speed < 0.5 and len(self.ball_history) >= 10:
                                       
            recent_positions = list(self.ball_history)[-10:]
            if all(pos is not None for pos in recent_positions):
                positions_array = np.array(recent_positions)
                movement = np.std(positions_array, axis=0)
                if np.all(movement < 0.5):                          
                    return True
        
        return False
    
    def _classify_dead_ball_type(self,
                                  ball_position: Optional[Tuple[float, float]],
                                  player_positions: Dict[int, Tuple[float, float]]) -> GameState:
        """
        تصنيف نوع الكرة الميتة
        """
        if ball_position is None:
            return GameState.DEAD_BALL
        
        x, y = ball_position
        
                                       
        corner_zone = 3.0
        if ((x < corner_zone or x > self.pitch_length - corner_zone) and
            (y < corner_zone or y > self.pitch_width - corner_zone)):
            return GameState.CORNER
        
                                              
        if x < 5.0 or x > self.pitch_length - 5.0:
            return GameState.GOAL_KICK
        
                                          
        penalty_spot_x1 = 11.0
        penalty_spot_x2 = self.pitch_length - 11.0
        if (abs(x - penalty_spot_x1) < 1.0 or abs(x - penalty_spot_x2) < 1.0):
            if abs(y - self.pitch_width / 2) < 5.0:
                return GameState.PENALTY
        
                                       
        if (abs(x - self.pitch_length / 2) < 2.0 and 
            abs(y - self.pitch_width / 2) < 2.0):
            return GameState.KICKOFF
        
        return GameState.FREE_KICK
    
    def get_game_states_for_tracks(self, tracks: dict) -> List[str]:
        """
        الحصول على حالات اللعب لكل الفريمات
        
        Args:
            tracks: dictionary التتبع
        
        Returns:
            قائمة حالات اللعب لكل فريم
        """
        num_frames = len(tracks.get('players', []))
        game_states = []
        
        for frame_num in range(num_frames):
                                  
            ball_pos = None
            ball_speed = 0
            
            if 'ball' in tracks and frame_num < len(tracks['ball']):
                ball_info = tracks['ball'][frame_num].get(1, {})
                pos = ball_info.get('position_transformed')
                if pos and isinstance(pos, (list, tuple)) and len(pos) >= 2:
                    ball_pos = (float(pos[0]), float(pos[1]))
                ball_speed = ball_info.get('speed', 0)
            
                                     
            player_positions = {}
            player_speeds = {}
            
            for track_id, player_info in tracks['players'][frame_num].items():
                pos = player_info.get('position_transformed')
                if pos and isinstance(pos, (list, tuple)) and len(pos) >= 2:
                    player_positions[track_id] = (float(pos[0]), float(pos[1]))
                player_speeds[track_id] = player_info.get('speed', 0)
            
                          
            state = self.detect_state(ball_pos, ball_speed, player_positions, player_speeds)
            game_states.append(state.value)
        
        return game_states
    
    def get_statistics(self) -> dict:
        """إحصائيات حالات اللعب"""
        if not self.state_history:
            return {}
        
        total = len(self.state_history)
        state_counts = {}
        
        for state in GameState:
            count = sum(1 for s in self.state_history if s == state)
            state_counts[state.value] = {
                'count': count,
                'percentage': round(count / total * 100, 1)
            }
        
        return {
            'total_frames': total,
            'states': state_counts,
            'live_percentage': state_counts.get('live', {}).get('percentage', 0)
        }


class DistanceExclusionManager:
    """
    مدير استبعاد المسافات
    يتتبع الفترات التي يجب استبعاد المسافة فيها
    """
    
    def __init__(self):
        self.exclusion_periods: List[Tuple[int, int, str]] = []                        
        self.excluded_distance: Dict[int, float] = {}                                 
    
    def add_exclusion_period(self, start_frame: int, end_frame: int, reason: str):
        """إضافة فترة استبعاد"""
        self.exclusion_periods.append((start_frame, end_frame, reason))
    
    def should_exclude(self, frame_num: int) -> Tuple[bool, str]:
        """التحقق من استبعاد فريم معين"""
        for start, end, reason in self.exclusion_periods:
            if start <= frame_num <= end:
                return True, reason
        return False, ""
    
    def add_excluded_distance(self, track_id: int, distance: float):
        """إضافة مسافة مستبعدة"""
        if track_id not in self.excluded_distance:
            self.excluded_distance[track_id] = 0
        self.excluded_distance[track_id] += distance
    
    def get_excluded_distance(self, track_id: int) -> float:
        """الحصول على المسافة المستبعدة للاعب"""
        return self.excluded_distance.get(track_id, 0)
    
    def get_statistics(self) -> dict:
        """إحصائيات الاستبعاد"""
        total_excluded_frames = sum(end - start + 1 
                                   for start, end, _ in self.exclusion_periods)
        
        reasons_count = {}
        for _, _, reason in self.exclusion_periods:
            reasons_count[reason] = reasons_count.get(reason, 0) + 1
        
        return {
            'total_exclusion_periods': len(self.exclusion_periods),
            'total_excluded_frames': total_excluded_frames,
            'reasons': reasons_count,
            'total_excluded_distance': sum(self.excluded_distance.values())
        }
