"""
Opta-Style Speed and Distance Estimator
========================================
Professional tracking with advanced smoothing and physical constraints

Features:
- EMA (Exponential Moving Average) smoothing
- Savitzky-Golay filter for noise reduction
- Physical constraints (max speed, acceleration)
- Game state awareness (exclude dead ball time)
- Minimum movement threshold

Opta Constraints:
- max_speed = 37 km/h (أقصى سرعة لاعب محترف)
- max_acceleration = 4.5 m/s²
- min_movement = 0.25 m (حد أدنى للحركة)

Formula:
v_t = α * v_t + (1-α) * v_{t-1}  (EMA smoothing)
"""

import numpy as np
from scipy.signal import savgol_filter
from scipy.ndimage import uniform_filter1d
from collections import defaultdict
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
from enum import Enum


class SpeedCategory(Enum):
    """تصنيف السرعة حسب Opta"""
    STANDING = "standing"                
    WALKING = "walking"                  
    JOGGING = "jogging"                   
    RUNNING = "running"                    
    HIGH_SPEED = "high_speed"              
    SPRINTING = "sprinting"               


@dataclass
class OptaConstraints:
    """
    قيود Opta للتتبع الاحترافي
    """
           
    MAX_SPRINT_SPEED_KMH: float = 37.0                                                   
    MAX_BALL_SPEED_KMH: float = 120.0                         
    
           
    MAX_ACCELERATION_MPS2: float = 4.5                   
    MAX_DECELERATION_MPS2: float = 5.5                   
    
          
    MIN_MOVEMENT_M: float = 0.25                             
    MAX_DISTANCE_PER_FRAME_M: float = 0.45                               
    
          
    PITCH_LENGTH_M: float = 105.0
    PITCH_WIDTH_M: float = 68.0
    
           
    EMA_ALPHA: float = 0.3                              
    SAVGOL_WINDOW: int = 7                                         
    SAVGOL_POLY: int = 2                                        
    
                 
    SPEED_THRESHOLDS = {
        'standing': 2.0,
        'walking': 7.0,
        'jogging': 14.0,
        'running': 21.0,
        'high_speed': 25.0
    }


class OptaSpeedDistanceEstimator:
    """
    محلل السرعة والمسافة بمعايير Opta
    """
    
    def __init__(self, 
                 frame_rate: float = 24.0,
                 constraints: OptaConstraints = None):
        """
        Initialize the estimator
        
        Args:
            frame_rate: معدل الإطارات في الثانية
            constraints: قيود Opta (اختياري)
        """
        self.frame_rate = frame_rate
        self.dt = 1.0 / frame_rate                              
        self.constraints = constraints or OptaConstraints()
        
                        
        self.position_history: Dict[int, List[Tuple[float, float, int]]] = defaultdict(list)
        self.speed_history: Dict[int, List[float]] = defaultdict(list)
        self.raw_speed_history: Dict[int, List[float]] = defaultdict(list)
        self.distance_accumulated: Dict[int, float] = defaultdict(float)
        
                    
        self.game_states: List[str] = []                                   
        
                  
        self.stats = {
            'clamped_speeds': 0,
            'clamped_accelerations': 0,
            'invalid_positions': 0,
            'excluded_distances': 0
        }
    
                                                                   
    
    def _is_valid_position(self, pos) -> bool:
        """التحقق من صحة الموقع"""
        if pos is None:
            return False
        if not isinstance(pos, (list, tuple, np.ndarray)) or len(pos) < 2:
            return False
        
        try:
            x, y = float(pos[0]), float(pos[1])
            
                                  
            if np.isnan(x) or np.isnan(y) or np.isinf(x) or np.isinf(y):
                return False
            
                                                                              
            margin = 20.0
            
            return (-margin <= x <= self.constraints.PITCH_LENGTH_M + margin and 
                    -margin <= y <= self.constraints.PITCH_WIDTH_M + margin)
        except (ValueError, TypeError):
            return False
    
    def _clamp_position(self, pos) -> Tuple[float, float]:
        """تحديد الموقع ضمن حدود الملعب"""
        if pos is None:
            return None
        try:
            x = max(0, min(float(pos[0]), self.constraints.PITCH_LENGTH_M))
            y = max(0, min(float(pos[1]), self.constraints.PITCH_WIDTH_M))
            return (x, y)
        except (ValueError, TypeError):
            return None
    
                                                                    
    
    @staticmethod
    def _measure_distance(pos1: Tuple[float, float], pos2: Tuple[float, float]) -> float:
        """حساب المسافة بين نقطتين"""
        return np.sqrt((pos1[0] - pos2[0])**2 + (pos1[1] - pos2[1])**2)
    
                                                                 
    
    def _calculate_raw_speed(self, 
                             current_pos: Tuple[float, float], 
                             prev_pos: Tuple[float, float],
                             time_delta: float) -> float:
        """
        حساب السرعة الخام
        speed = distance / time (m/s) -> km/h
        """
        if time_delta <= 0:
            return 0.0
        
        distance = self._measure_distance(current_pos, prev_pos)
        speed_mps = distance / time_delta
        speed_kmh = speed_mps * 3.6
        
        return speed_kmh
    
    def _apply_ema_smoothing(self, track_id: int, speed: float) -> float:
        """
        تطبيق EMA smoothing
        v_t = α * v_t + (1-α) * v_{t-1}
        """
        history = self.speed_history.get(track_id, [])
        
        if not history:
            return speed
        
        prev_speed = history[-1]
        alpha = self.constraints.EMA_ALPHA
        
        smoothed = alpha * speed + (1 - alpha) * prev_speed
        return smoothed
    
    def _apply_savgol_filter(self, speeds: List[float]) -> List[float]:
        """
        تطبيق Savitzky-Golay filter لتنعيم السلسلة الكاملة
        """
        if len(speeds) < self.constraints.SAVGOL_WINDOW:
            return speeds
        
                               
        window = min(self.constraints.SAVGOL_WINDOW, len(speeds))
        if window % 2 == 0:
            window -= 1
        
        if window < 3:
            return speeds
        
        try:
            smoothed = savgol_filter(
                speeds, 
                window_length=window, 
                polyorder=min(self.constraints.SAVGOL_POLY, window - 1)
            )
            return smoothed.tolist()
        except Exception:
            return speeds
    
    def _validate_acceleration(self, 
                               track_id: int, 
                               current_speed: float,
                               time_delta: float) -> float:
        """
        التحقق من التسارع وتصحيحه
        """
        history = self.speed_history.get(track_id, [])
        
        if not history or time_delta <= 0:
            return current_speed
        
        prev_speed = history[-1]
        
                      
        prev_speed_mps = prev_speed / 3.6
        current_speed_mps = current_speed / 3.6
        
                      
        acceleration = (current_speed_mps - prev_speed_mps) / time_delta
        
                          
        if acceleration > self.constraints.MAX_ACCELERATION_MPS2:
                                          
            max_speed_change = self.constraints.MAX_ACCELERATION_MPS2 * time_delta
            current_speed_mps = prev_speed_mps + max_speed_change
            self.stats['clamped_accelerations'] += 1
            
        elif acceleration < -self.constraints.MAX_DECELERATION_MPS2:
                              
            max_speed_change = self.constraints.MAX_DECELERATION_MPS2 * time_delta
            current_speed_mps = prev_speed_mps - max_speed_change
            self.stats['clamped_accelerations'] += 1
        
        return current_speed_mps * 3.6
    
    def _clamp_speed(self, speed: float, is_goalkeeper: bool = False) -> float:
        """تحديد السرعة ضمن الحدود"""
        max_speed = self.constraints.MAX_SPRINT_SPEED_KMH
        if is_goalkeeper:
            max_speed *= 0.85                         
        
        if speed > max_speed:
            self.stats['clamped_speeds'] += 1
            return max_speed
        
        return max(0, speed)
    
                                                                    
    
    def _should_count_distance(self, 
                               distance: float, 
                               game_state: str = 'live') -> bool:
        """
        تحديد ما إذا كانت المسافة تُحسب
        
        Exclude:
        - Dead ball time
        - Stoppages
        - Very small movements (noise)
        """
                                                        
        if game_state in ['stoppage', 'substitution', 'halftime']:
            self.stats['excluded_distances'] += 1
            return False
        
                                                   
                                                                        
        return True
    
                                                               
    
    def process_frame(self,
                      frame_num: int,
                      players: Dict[int, dict],
                      game_state: str = 'live') -> Dict[int, dict]:
        """
        معالجة فريم واحد وحساب السرعة والمسافة
        
        Args:
            frame_num: رقم الإطار
            players: {track_id: {'position_transformed': [x, y], ...}}
            game_state: حالة اللعب
        
        Returns:
            {track_id: {'speed': km/h, 'distance': m, ...}}
        """
        results = {}
        
        for track_id, player_info in players.items():
                                          
            pos = player_info.get('position_transformed')
            if pos is None:
                pos = player_info.get('position_adjusted')
            if pos is None:
                pos = player_info.get('position')
            
                              
            if not self._is_valid_position(pos):
                self.stats['invalid_positions'] += 1
                continue
            
            pos = self._clamp_position(pos)
            if pos is None:
                self.stats['invalid_positions'] += 1
                continue
                
            current_pos = (pos[0], pos[1])
            
                                      
            history = self.position_history.get(track_id, [])
            
            if history:
                prev_pos = (history[-1][0], history[-1][1])
                prev_frame = history[-1][2]
                time_delta = (frame_num - prev_frame) * self.dt
                
                              
                distance = self._measure_distance(current_pos, prev_pos)
                
                                   
                raw_speed = self._calculate_raw_speed(current_pos, prev_pos, time_delta)
                self.raw_speed_history[track_id].append(raw_speed)
                
                                     
                smoothed_speed = self._apply_ema_smoothing(track_id, raw_speed)
                
                                   
                is_goalkeeper = player_info.get('is_goalkeeper', False)
                validated_speed = self._validate_acceleration(track_id, smoothed_speed, time_delta)
                
                                         
                final_speed = self._clamp_speed(validated_speed, is_goalkeeper)
                
                                     
                if self._should_count_distance(distance, game_state):
                    self.distance_accumulated[track_id] += distance
                
            else:
                                
                distance = 0
                final_speed = 0
                raw_speed = 0
            
                            
            self.position_history[track_id].append((current_pos[0], current_pos[1], frame_num))
            self.speed_history[track_id].append(final_speed)
            
                                       
            if len(self.position_history[track_id]) > 50:
                self.position_history[track_id] = self.position_history[track_id][-50:]
            if len(self.speed_history[track_id]) > 50:
                self.speed_history[track_id] = self.speed_history[track_id][-50:]
            if len(self.raw_speed_history[track_id]) > 50:
                self.raw_speed_history[track_id] = self.raw_speed_history[track_id][-50:]
            
            results[track_id] = {
                'speed': round(final_speed, 2),
                'speed_raw': round(raw_speed, 2) if history else 0,
                'distance': round(self.distance_accumulated[track_id], 1),
                'speed_category': self._categorize_speed(final_speed)
            }
        
        return results
    
    def add_speed_and_distance_to_tracks(self, 
                                         tracks: dict,
                                         game_states: List[str] = None):
        """
        إضافة السرعة والمسافة لكل الـ tracks
        
        Args:
            tracks: dictionary التتبع
            game_states: قائمة حالات اللعب لكل فريم (اختياري)
        """
        print(" Processing speed and distance (Opta Style)...")
        
        num_frames = len(tracks.get('players', []))
        
                                                 
        sample_frame = tracks['players'][min(10, num_frames-1)] if num_frames > 0 else {}
        found_key = None
        sample_pos = None
        for track_id, info in sample_frame.items():
            for key in ['position_transformed', 'position_adjusted', 'position']:
                pos = info.get(key)
                if pos is not None:
                    found_key = key
                    sample_pos = pos
                    print(f"    Using '{key}': Player {track_id} at {pos}")
                    
                                                                
                    if isinstance(pos, (list, tuple)) and len(pos) >= 2:
                        x, y = float(pos[0]), float(pos[1])
                        if x > 200 or y > 200:
                            print(f"    WARNING: Position {pos} looks like PIXELS, not METERS!")
                            print(f"      Expected: x in [0-105], y in [0-68] for a football pitch")
                    break
            if found_key:
                break
        
        if not found_key:
            keys_available = []
            for track_id, info in sample_frame.items():
                keys_available = list(info.keys())
                break
            print(f"    WARNING: No position data found! Available keys: {keys_available}")
        
                           
        if game_states is None:
            game_states = ['live'] * num_frames
        
                                   
        for frame_num in range(num_frames):
            game_state = game_states[frame_num] if frame_num < len(game_states) else 'live'
            
            results = self.process_frame(
                frame_num=frame_num,
                players=tracks['players'][frame_num],
                game_state=game_state
            )
            
                              
            for track_id, data in results.items():
                if track_id in tracks['players'][frame_num]:
                    tracks['players'][frame_num][track_id]['speed'] = data['speed']
                    tracks['players'][frame_num][track_id]['speed_raw'] = data['speed_raw']
                    tracks['players'][frame_num][track_id]['distance'] = data['distance']
                    tracks['players'][frame_num][track_id]['speed_category'] = data['speed_category']
        
                                                           
        self._apply_post_smoothing(tracks)
        
                          
        self._print_stats()
    
    def _apply_post_smoothing(self, tracks: dict):
        """
        تطبيق التنعيم النهائي على كل السرعات
        """
                                
        player_speeds = defaultdict(list)
        player_frames = defaultdict(list)
        
        for frame_num, frame_data in enumerate(tracks['players']):
            for track_id, player_info in frame_data.items():
                if 'speed' in player_info:
                    player_speeds[track_id].append(player_info['speed'])
                    player_frames[track_id].append(frame_num)
        
                              
        for track_id, speeds in player_speeds.items():
            if len(speeds) >= self.constraints.SAVGOL_WINDOW:
                smoothed = self._apply_savgol_filter(speeds)
                
                                     
                for i, frame_num in enumerate(player_frames[track_id]):
                    tracks['players'][frame_num][track_id]['speed'] = round(smoothed[i], 2)
                    tracks['players'][frame_num][track_id]['speed_category'] =\
                        self._categorize_speed(smoothed[i])
    
    def _categorize_speed(self, speed_kmh: float) -> str:
        """تصنيف السرعة"""
        thresholds = self.constraints.SPEED_THRESHOLDS
        
        if speed_kmh < thresholds['standing']:
            return SpeedCategory.STANDING.value
        elif speed_kmh < thresholds['walking']:
            return SpeedCategory.WALKING.value
        elif speed_kmh < thresholds['jogging']:
            return SpeedCategory.JOGGING.value
        elif speed_kmh < thresholds['running']:
            return SpeedCategory.RUNNING.value
        elif speed_kmh < thresholds['high_speed']:
            return SpeedCategory.HIGH_SPEED.value
        else:
            return SpeedCategory.SPRINTING.value
    
    def _print_stats(self):
        """طباعة إحصائيات المعالجة"""
        print(f"\n Speed/Distance Processing Stats:")
        print(f"   - Clamped speeds: {self.stats['clamped_speeds']}")
        print(f"   - Clamped accelerations: {self.stats['clamped_accelerations']}")
        print(f"   - Invalid positions: {self.stats['invalid_positions']}")
        print(f"   - Excluded distances (stoppages): {self.stats['excluded_distances']}")
        
                       
        if self.distance_accumulated:
            sorted_distances = sorted(
                self.distance_accumulated.items(), 
                key=lambda x: x[1], 
                reverse=True
            )[:5]
            print(f"   - Top 5 distances:")
            for track_id, dist in sorted_distances:
                print(f"     Player {track_id}: {dist:.1f}m")
        else:
            print(f"    No distances accumulated! Check position_transformed data.")
    
    def get_player_statistics(self, track_id: int) -> dict:
        """الحصول على إحصائيات لاعب محدد"""
        speeds = self.speed_history.get(track_id, [])
        
        if not speeds:
            return {}
        
        return {
            'track_id': track_id,
            'total_distance_m': round(self.distance_accumulated.get(track_id, 0), 1),
            'max_speed_kmh': round(max(speeds), 2),
            'avg_speed_kmh': round(np.mean(speeds), 2),
            'time_standing': sum(1 for s in speeds if s < 2) / len(speeds) * 100,
            'time_sprinting': sum(1 for s in speeds if s > 25) / len(speeds) * 100
        }
    
    def draw_speed_and_distance(self, frames: list, tracks: dict) -> list:
        """رسم السرعة والمسافة على الفريمات"""
        import cv2
        
        output_frames = []
        
        for frame_num, frame in enumerate(frames):
            for track_id, track_info in tracks['players'][frame_num].items():
                speed = track_info.get('speed')
                distance = track_info.get('distance')
                speed_cat = track_info.get('speed_category', '')
                
                if speed is None or distance is None:
                    continue
                
                bbox = track_info.get('bbox')
                if bbox is None:
                    continue
                
                           
                x1, y1, x2, y2 = bbox
                position = (int((x1 + x2) / 2) - 30, int(y2) + 25)
                
                                
                color = self._get_speed_color(speed_cat)
                
                      
                text = f"{speed:.1f}km/h"
                text2 = f"{distance:.0f}m"
                
                       
                (tw, th), _ = cv2.getTextSize(text, cv2.FONT_HERSHEY_SIMPLEX, 0.4, 1)
                cv2.rectangle(frame, 
                             (position[0] - 2, position[1] - th - 2),
                             (position[0] + tw + 2, position[1] + 20),
                             (255, 255, 255), -1)
                
                cv2.putText(frame, text, position,
                           cv2.FONT_HERSHEY_SIMPLEX, 0.4, color, 1)
                cv2.putText(frame, text2, (position[0], position[1] + 15),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.35, (0, 0, 0), 1)
            
            output_frames.append(frame)
        
        return output_frames
    
    def _get_speed_color(self, speed_category: str) -> Tuple[int, int, int]:
        """لون حسب تصنيف السرعة (BGR)"""
        colors = {
            'standing': (128, 128, 128),           
            'walking': (0, 200, 0),                     
            'jogging': (0, 255, 0),                
            'running': (0, 165, 255),                 
            'high_speed': (0, 0, 255),                  
            'sprinting': (0, 0, 200)               
        }
        return colors.get(speed_category, (0, 0, 0))
