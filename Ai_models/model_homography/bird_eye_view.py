

import cv2
import numpy as np
from typing import Dict, List, Tuple, Optional
from scipy.spatial import ConvexHull


class BirdEyeView:

    
                                            
    PITCH_LENGTH = 105.0              
    PITCH_WIDTH = 68.0                
    
                  
    PENALTY_AREA_LENGTH = 16.5
    PENALTY_AREA_WIDTH = 40.32
    GOAL_AREA_LENGTH = 5.5
    GOAL_AREA_WIDTH = 18.32
    CENTER_CIRCLE_RADIUS = 9.15
    PENALTY_SPOT_DISTANCE = 11.0
    CORNER_ARC_RADIUS = 1.0
    
                  
    GRASS_DARK = (34, 85, 34)                 
    GRASS_LIGHT = (45, 105, 45)               
    LINE_COLOR = (255, 255, 255)                
    
                 
    TEAM_COLORS = {
        1: (255, 70, 70),                        
        2: (70, 70, 255)                         
    }
    
    BALL_COLOR = (0, 255, 255)                 
    BALL_HOLDER_MARKER = (0, 255, 0)                         
    
    def __init__(
        self,
        map_width: int = 450,
        map_height: int = 290,
        margin: int = 15,
        show_player_ids: bool = False,
        show_trails: bool = True,
        trail_length: int = 10,
        style: str = "modern",                                    
                         
        show_velocity_arrows: bool = True,
        show_team_shape: bool = True,
        show_defensive_line: bool = True,
        show_midblock_line: bool = True,
        show_zones: bool = False
    ):

        self.map_width = map_width
        self.map_height = map_height
        self.margin = margin
        self.show_player_ids = show_player_ids
        self.show_trails = show_trails
        self.trail_length = trail_length
        self.style = style
        
                                  
        self.show_velocity_arrows = show_velocity_arrows
        self.show_team_shape = show_team_shape
        self.show_defensive_line = show_defensive_line
        self.show_midblock_line = show_midblock_line
        self.show_zones = show_zones
        
                                  
        self.pitch_area_width = map_width - 2 * margin
        self.pitch_area_height = map_height - 2 * margin
        
                     
        self.scale_x = self.pitch_area_width / self.PITCH_LENGTH
        self.scale_y = self.pitch_area_height / self.PITCH_WIDTH
        
                               
        self.player_trails: Dict[int, List[Tuple[int, int]]] = {}
        self.ball_trail: List[Tuple[int, int]] = []
        
                                            
        self.previous_positions: Dict[int, Tuple[float, float]] = {}
        
                                    
        self._create_base_pitch()
    
    def _create_base_pitch(self):
        """إنشاء صورة الملعب الأساسية"""
        self.base_pitch = np.zeros((self.map_height, self.map_width, 3), dtype=np.uint8)
        
        if self.style == "modern":
            self._draw_modern_pitch()
        elif self.style == "broadcast":
            self._draw_broadcast_pitch()
        else:
            self._draw_classic_pitch()
    
    def _draw_modern_pitch(self):
        """رسم ملعب بنمط حديث مع تدرجات"""
                      
        for i in range(self.map_height):
            ratio = i / self.map_height
            color = self._blend_colors(self.GRASS_DARK, self.GRASS_LIGHT, ratio * 0.3)
            cv2.line(self.base_pitch, (0, i), (self.map_width, i), color, 1)
        
                     
        stripe_width = self.pitch_area_width // 10
        for i in range(10):
            if i % 2 == 0:
                x1 = self.margin + i * stripe_width
                x2 = self.margin + (i + 1) * stripe_width
                overlay = self.base_pitch.copy()
                cv2.rectangle(overlay, (x1, self.margin), (x2, self.map_height - self.margin),
                            self.GRASS_LIGHT, -1)
                cv2.addWeighted(overlay, 0.15, self.base_pitch, 0.85, 0, self.base_pitch)
        
        self._draw_pitch_lines()
        self._add_shadow_effects()
    
    def _draw_broadcast_pitch(self):
        """رسم ملعب بنمط البث التلفزيوني"""
                           
        self.base_pitch[:] = (40, 95, 40)
        
                    
        cv2.rectangle(self.base_pitch, (0, 0), 
                     (self.map_width - 1, self.map_height - 1), 
                     (20, 50, 20), 2)
        
                                  
        center_x = self.map_width // 2
        center_y = self.map_height // 2
        for r in range(max(self.map_width, self.map_height), 0, -5):
            alpha = 0.02
            overlay = self.base_pitch.copy()
            cv2.circle(overlay, (center_x, center_y), r, (60, 120, 60), -1)
            cv2.addWeighted(overlay, alpha, self.base_pitch, 1 - alpha, 0, self.base_pitch)
        
        self._draw_pitch_lines(line_thickness=2)
    
    def _draw_classic_pitch(self):
        """رسم ملعب كلاسيكي بسيط"""
        self.base_pitch[:] = self.GRASS_DARK
        self._draw_pitch_lines()
    
    def _draw_pitch_lines(self, line_thickness: int = 2):
        """رسم خطوط الملعب"""
        m = self.margin
        w = self.pitch_area_width
        h = self.pitch_area_height
        
                         
        cv2.rectangle(self.base_pitch, (m, m), (m + w, m + h), self.LINE_COLOR, line_thickness)
        
                    
        mid_x = m + w // 2
        cv2.line(self.base_pitch, (mid_x, m), (mid_x, m + h), self.LINE_COLOR, line_thickness)
        
                       
        circle_radius = int(self.CENTER_CIRCLE_RADIUS * self.scale_x)
        cv2.circle(self.base_pitch, (mid_x, m + h // 2), circle_radius, self.LINE_COLOR, line_thickness)
        
                      
        cv2.circle(self.base_pitch, (mid_x, m + h // 2), 3, self.LINE_COLOR, -1)
        
                             
        penalty_w = int(self.PENALTY_AREA_LENGTH * self.scale_x)
        penalty_h = int(self.PENALTY_AREA_WIDTH * self.scale_y)
        penalty_y = m + (h - penalty_h) // 2
        cv2.rectangle(self.base_pitch, (m, penalty_y), 
                     (m + penalty_w, penalty_y + penalty_h), self.LINE_COLOR, line_thickness)
        
                             
        cv2.rectangle(self.base_pitch, (m + w - penalty_w, penalty_y),
                     (m + w, penalty_y + penalty_h), self.LINE_COLOR, line_thickness)
        
                                  
        goal_w = int(self.GOAL_AREA_LENGTH * self.scale_x)
        goal_h = int(self.GOAL_AREA_WIDTH * self.scale_y)
        goal_y = m + (h - goal_h) // 2
        cv2.rectangle(self.base_pitch, (m, goal_y),
                     (m + goal_w, goal_y + goal_h), self.LINE_COLOR, line_thickness)
        
                                  
        cv2.rectangle(self.base_pitch, (m + w - goal_w, goal_y),
                     (m + w, goal_y + goal_h), self.LINE_COLOR, line_thickness)
        
                     
        penalty_spot_x_left = m + int(self.PENALTY_SPOT_DISTANCE * self.scale_x)
        penalty_spot_x_right = m + w - int(self.PENALTY_SPOT_DISTANCE * self.scale_x)
        cv2.circle(self.base_pitch, (penalty_spot_x_left, m + h // 2), 3, self.LINE_COLOR, -1)
        cv2.circle(self.base_pitch, (penalty_spot_x_right, m + h // 2), 3, self.LINE_COLOR, -1)
        
                                 
        arc_center_x_left = penalty_spot_x_left
        arc_center_y = m + h // 2
        cv2.ellipse(self.base_pitch, (arc_center_x_left, arc_center_y),
                   (circle_radius, circle_radius), 0, -53, 53, self.LINE_COLOR, line_thickness)
        
                                 
        arc_center_x_right = penalty_spot_x_right
        cv2.ellipse(self.base_pitch, (arc_center_x_right, arc_center_y),
                   (circle_radius, circle_radius), 0, 127, 233, self.LINE_COLOR, line_thickness)
        
                                 
        corner_radius = int(self.CORNER_ARC_RADIUS * self.scale_x)
        cv2.ellipse(self.base_pitch, (m, m), (corner_radius, corner_radius), 
                   0, 0, 90, self.LINE_COLOR, line_thickness)
        cv2.ellipse(self.base_pitch, (m + w, m), (corner_radius, corner_radius),
                   0, 90, 180, self.LINE_COLOR, line_thickness)
        cv2.ellipse(self.base_pitch, (m, m + h), (corner_radius, corner_radius),
                   0, 270, 360, self.LINE_COLOR, line_thickness)
        cv2.ellipse(self.base_pitch, (m + w, m + h), (corner_radius, corner_radius),
                   0, 180, 270, self.LINE_COLOR, line_thickness)
        
                                      
        goal_width = int(7.32 * self.scale_y)                       
        goal_depth = 4
        goal_y_start = m + (h - goal_width) // 2
        
                       
        cv2.rectangle(self.base_pitch, (m - goal_depth, goal_y_start),
                     (m, goal_y_start + goal_width), self.LINE_COLOR, -1)
        
                       
        cv2.rectangle(self.base_pitch, (m + w, goal_y_start),
                     (m + w + goal_depth, goal_y_start + goal_width), self.LINE_COLOR, -1)
    
    def _add_shadow_effects(self):
        """إضافة تأثيرات الظل"""
                            
        for i in range(5):
            alpha = 0.03 * (5 - i)
            cv2.rectangle(self.base_pitch, (i, i), 
                         (self.map_width - i - 1, self.map_height - i - 1),
                         (0, 0, 0), 1)
    
    def _blend_colors(self, color1: Tuple, color2: Tuple, ratio: float) -> Tuple:
        """مزج لونين"""
        return tuple(int(c1 * (1 - ratio) + c2 * ratio) for c1, c2 in zip(color1, color2))
    
    def _pitch_to_map(self, x: float, y: float) -> Tuple[int, int]:
        """
        تحويل إحداثيات الملعب (بالمتر) إلى إحداثيات الخريطة (بالبيكسل)
        map_x = int(x / 105 * MAP_WIDTH)
        map_y = int(y / 68 * MAP_HEIGHT)
        """
        map_x = self.margin + int(x / self.PITCH_LENGTH * self.pitch_area_width)
        map_y = self.margin + int(y / self.PITCH_WIDTH * self.pitch_area_height)
        
                                               
        map_x = np.clip(map_x, self.margin, self.margin + self.pitch_area_width - 1)
        map_y = np.clip(map_y, self.margin, self.margin + self.pitch_area_height - 1)
        
        return map_x, map_y
    
                                                               
    
    def _draw_zones(self, minimap: np.ndarray):
        """رسم شبكة المناطق (Pitch Grid)"""
                                                      
        cols = 6
        rows = 3
        
        zone_width = self.pitch_area_width // cols
        zone_height = self.pitch_area_height // rows
        
        overlay = minimap.copy()
        
                          
        for i in range(1, cols):
            x = self.margin + i * zone_width
            cv2.line(overlay, (x, self.margin), 
                    (x, self.margin + self.pitch_area_height), 
                    (100, 100, 100), 1, cv2.LINE_AA)
        
        for j in range(1, rows):
            y = self.margin + j * zone_height
            cv2.line(overlay, (self.margin, y), 
                    (self.margin + self.pitch_area_width, y), 
                    (100, 100, 100), 1, cv2.LINE_AA)
        
        cv2.addWeighted(overlay, 0.5, minimap, 0.5, 0, minimap)
    
    def _draw_velocity_arrow(self, minimap: np.ndarray, x: int, y: int, 
                            vx: float, vy: float, color: Tuple[int, int, int]):
        """رسم سهم الاتجاه (Velocity Vector)"""
                            
        arrow_scale = 3.0
        
        end_x = int(x + vx * arrow_scale)
        end_y = int(y + vy * arrow_scale)
        
                                
        arrow_length = np.sqrt((end_x - x)**2 + (end_y - y)**2)
        if arrow_length < 3:
            return
        
                   
        cv2.arrowedLine(minimap, (x, y), (end_x, end_y), 
                       color, 2, cv2.LINE_AA, tipLength=0.4)
    
    def _draw_team_shape(self, minimap: np.ndarray, team_positions: List[Tuple[int, int]], 
                         team: int):
        """رسم شكل الفريق (Convex Hull)"""
        if len(team_positions) < 3:
            return
        
        try:
            points = np.array(team_positions)
            hull = ConvexHull(points)
            hull_points = points[hull.vertices]
            
                             
            color = self.TEAM_COLORS.get(team, (150, 150, 150))
            
                        
            overlay = minimap.copy()
            cv2.fillPoly(overlay, [hull_points], color)
            cv2.addWeighted(overlay, 0.15, minimap, 0.85, 0, minimap)
            
                             
            cv2.polylines(minimap, [hull_points], True, color, 2, cv2.LINE_AA)
        except Exception:
                                                
            pass
    
    def _draw_defensive_line(self, minimap: np.ndarray, team_positions: List[Tuple[int, int, float]], 
                             team: int, is_defending_left: bool = True):
        """
        رسم خط الدفاع (Defensive Line)
        - يرسم خط أفقي عند أقصى لاعبين للخلف
        """
        if len(team_positions) < 2:
            return
        
                                                  
        sorted_positions = sorted(team_positions, key=lambda p: p[2])                      
        
                                   
        if is_defending_left:
                                                  
            defenders = sorted_positions[:4]
        else:
                                                   
            defenders = sorted_positions[-4:]
        
        if len(defenders) < 2:
            return
        
                                   
        avg_x = sum(p[0] for p in defenders) / len(defenders)
        
                          
        color = self.TEAM_COLORS.get(team, (150, 150, 150))
        y1 = self.margin
        y2 = self.margin + self.pitch_area_height
        
                  
        dash_length = 8
        for i in range(y1, y2, dash_length * 2):
            cv2.line(minimap, (int(avg_x), i), 
                    (int(avg_x), min(i + dash_length, y2)), 
                    color, 2, cv2.LINE_AA)
    
    def _draw_midblock_line(self, minimap: np.ndarray, team_positions: List[Tuple[int, int, float]], 
                            team: int):
        """
        رسم خط الوسط (Mid Block Line)
        - يرسم خط عند متوسط مواقع لاعبي الوسط
        """
        if len(team_positions) < 3:
            return
        
                              
        sorted_positions = sorted(team_positions, key=lambda p: p[2])
        
                                                      
        midfielders = sorted_positions[2:-2] if len(sorted_positions) > 4 else sorted_positions[1:-1]
        
        if len(midfielders) < 2:
            return
        
                                
        avg_x = sum(p[0] for p in midfielders) / len(midfielders)
        
                  
        color = self.TEAM_COLORS.get(team, (150, 150, 150))
                            
        light_color = tuple(min(255, c + 50) for c in color)
        
        y1 = self.margin + 20
        y2 = self.margin + self.pitch_area_height - 20
        
                 
        for i in range(y1, y2, 6):
            cv2.circle(minimap, (int(avg_x), i), 2, light_color, -1)
    
    def _draw_player(self, minimap: np.ndarray, x: int, y: int, 
                     team: int, has_ball: bool = False, 
                     player_id: Optional[int] = None):
        """رسم لاعب على الخريطة"""
        color = self.TEAM_COLORS.get(team, (200, 200, 200))
        
                    
        radius = 7 if has_ball else 5
        
                  
        cv2.circle(minimap, (x + 2, y + 2), radius, (20, 40, 20), -1)
        
                    
        cv2.circle(minimap, (x, y), radius, color, -1)
        
                     
        border_color = (255, 255, 255) if not has_ball else self.BALL_HOLDER_MARKER
        cv2.circle(minimap, (x, y), radius, border_color, 2)
        
                          
        if has_ball:
                                
            cv2.circle(minimap, (x, y), radius + 4, self.BALL_HOLDER_MARKER, 2)
                             
            cv2.circle(minimap, (x, y), 2, (255, 255, 255), -1)
        
                    
        if self.show_player_ids and player_id is not None:
            text = str(player_id % 100)                      
            font = cv2.FONT_HERSHEY_SIMPLEX
            font_scale = 0.3
            thickness = 1
            (text_w, text_h), _ = cv2.getTextSize(text, font, font_scale, thickness)
            text_x = x - text_w // 2
            text_y = y - radius - 3
            cv2.putText(minimap, text, (text_x, text_y), font, font_scale, 
                       (255, 255, 255), thickness, cv2.LINE_AA)
    
    def _draw_ball(self, minimap: np.ndarray, x: int, y: int):
        """رسم الكرة على الخريطة"""
                  
        cv2.circle(minimap, (x + 2, y + 2), 6, (20, 40, 20), -1)
        
               
        cv2.circle(minimap, (x, y), 6, self.BALL_COLOR, -1)
        cv2.circle(minimap, (x, y), 6, (0, 0, 0), 2)
        
                     
        cv2.circle(minimap, (x - 2, y - 2), 2, (255, 255, 200), -1)
    
    def _draw_trail(self, minimap: np.ndarray, trail: List[Tuple[int, int]], 
                    color: Tuple[int, int, int], is_ball: bool = False):
        """رسم مسار الحركة"""
        if len(trail) < 2:
            return
        
        for i in range(len(trail) - 1):
            alpha = (i + 1) / len(trail)
            thickness = max(1, int(3 * alpha))
            
                        
            trail_color = tuple(int(c * alpha) for c in color)
            
            pt1 = trail[i]
            pt2 = trail[i + 1]
            
            if is_ball:
                cv2.line(minimap, pt1, pt2, trail_color, thickness, cv2.LINE_AA)
            else:
                                     
                if i % 2 == 0:
                    cv2.circle(minimap, pt1, thickness, trail_color, -1)
    
    def _update_trail(self, trail_dict: Dict, player_id: int, position: Tuple[int, int]):
        """تحديث مسار اللاعب"""
        if player_id not in trail_dict:
            trail_dict[player_id] = []
        
        trail_dict[player_id].append(position)
        
                                  
        if len(trail_dict[player_id]) > self.trail_length:
            trail_dict[player_id] = trail_dict[player_id][-self.trail_length:]
    
    def draw(self, frame: np.ndarray, tracks: Dict, frame_idx: int,
             position: Optional[Tuple[int, int]] = None) -> np.ndarray:

                                
        minimap = self.base_pitch.copy()
        
                                          
        if self.show_zones:
            self._draw_zones(minimap)
        
                                               
        team1_positions = []                            
        team2_positions = []
        team1_map_positions = []                                      
        team2_map_positions = []
        
                                            
        if self.show_trails:
            for player_id, trail in self.player_trails.items():
                                                   
                team = 1           
                if "players" in tracks and frame_idx < len(tracks["players"]):
                    player_info = tracks["players"][frame_idx].get(player_id, {})
                    team = player_info.get("team", 1)
                trail_color = self.TEAM_COLORS.get(team, (150, 150, 150))
                self._draw_trail(minimap, trail, trail_color)
            
                        
            if self.ball_trail:
                self._draw_trail(minimap, self.ball_trail, self.BALL_COLOR, is_ball=True)
        
                                  
        player_data = []                                                                        
        
        if "players" in tracks and frame_idx < len(tracks["players"]):
            for player_id, info in tracks["players"][frame_idx].items():
                pos = info.get("position_transformed")
                if pos is None or not isinstance(pos, (list, tuple)) or len(pos) < 2:
                    continue
                
                x, y = float(pos[0]), float(pos[1])
                
                                               
                if not (0 <= x <= self.PITCH_LENGTH and 0 <= y <= self.PITCH_WIDTH):
                    continue
                
                map_x, map_y = self._pitch_to_map(x, y)
                team = info.get("team", 1)
                has_ball = info.get("has_ball", False)
                
                player_data.append((player_id, map_x, map_y, x, y, team, has_ball))
                
                                   
                if team == 1:
                    team1_positions.append((map_x, map_y, x))
                    team1_map_positions.append((map_x, map_y))
                else:
                    team2_positions.append((map_x, map_y, x))
                    team2_map_positions.append((map_x, map_y))
        
                                                     
        if self.show_team_shape:
            self._draw_team_shape(minimap, team1_map_positions, 1)
            self._draw_team_shape(minimap, team2_map_positions, 2)
        
                            
        if self.show_defensive_line:
                                                                
            self._draw_defensive_line(minimap, team1_positions, 1, is_defending_left=True)
            self._draw_defensive_line(minimap, team2_positions, 2, is_defending_left=False)
        
                            
        if self.show_midblock_line:
            self._draw_midblock_line(minimap, team1_positions, 1)
            self._draw_midblock_line(minimap, team2_positions, 2)
        
                              
        for player_id, map_x, map_y, x, y, team, has_ball in player_data:
                          
            if self.show_trails:
                self._update_trail(self.player_trails, player_id, (map_x, map_y))
            
                                               
            if self.show_velocity_arrows and player_id in self.previous_positions:
                prev_x, prev_y = self.previous_positions[player_id]
                vx = (x - prev_x) * self.scale_x
                vy = (y - prev_y) * self.scale_y
                color = self.TEAM_COLORS.get(team, (150, 150, 150))
                self._draw_velocity_arrow(minimap, map_x, map_y, vx, vy, color)
            
                                 
            self.previous_positions[player_id] = (x, y)
            
                        
            self._draw_player(minimap, map_x, map_y, team, has_ball, 
                             player_id if self.show_player_ids else None)
        
                   
        if "ball" in tracks and frame_idx < len(tracks["ball"]):
            ball_dict = tracks["ball"][frame_idx]
            ball_info = None
            
            if isinstance(ball_dict, dict):
                if 1 in ball_dict:
                    ball_info = ball_dict[1]
                elif "position_transformed" in ball_dict:
                    ball_info = ball_dict
            
            if ball_info is not None:
                pos = ball_info.get("position_transformed")
                if pos is not None and isinstance(pos, (list, tuple)) and len(pos) >= 2:
                    x, y = float(pos[0]), float(pos[1])
                    
                    if 0 <= x <= self.PITCH_LENGTH and 0 <= y <= self.PITCH_WIDTH:
                        map_x, map_y = self._pitch_to_map(x, y)
                        
                                          
                        if self.show_trails:
                            self.ball_trail.append((map_x, map_y))
                            if len(self.ball_trail) > self.trail_length:
                                self.ball_trail = self.ball_trail[-self.trail_length:]
                        
                        self._draw_ball(minimap, map_x, map_y)
        
                                       
        if position is None:
            x0 = frame.shape[1] - self.map_width - 30
            y0 = 30
        else:
            x0, y0 = position
        
                                               
        if y0 + self.map_height > frame.shape[0]:
            y0 = frame.shape[0] - self.map_height - 10
        if x0 + self.map_width > frame.shape[1]:
            x0 = frame.shape[1] - self.map_width - 10
        
        x0 = max(10, x0)
        y0 = max(10, y0)
        
                                  
        border_size = 3
        frame_with_border = frame.copy()
        
                  
        cv2.rectangle(frame_with_border, 
                     (x0 - border_size + 4, y0 - border_size + 4),
                     (x0 + self.map_width + border_size + 4, y0 + self.map_height + border_size + 4),
                     (30, 30, 30), -1)
        
                    
        cv2.rectangle(frame_with_border,
                     (x0 - border_size, y0 - border_size),
                     (x0 + self.map_width + border_size, y0 + self.map_height + border_size),
                     (50, 50, 50), -1)
        
                               
        alpha = 0.95
        roi = frame_with_border[y0:y0 + self.map_height, x0:x0 + self.map_width]
        blended = cv2.addWeighted(minimap, alpha, roi, 1 - alpha, 0)
        frame_with_border[y0:y0 + self.map_height, x0:x0 + self.map_width] = blended
        
        return frame_with_border
    
    def reset_trails(self):
        """مسح جميع المسارات"""
        self.player_trails.clear()
        self.ball_trail.clear()


def draw_bird_eye_view(
    frame: np.ndarray,
    tracks: Dict,
    frame_idx: int,
    bird_eye_view: Optional[BirdEyeView] = None,
    **kwargs
) -> np.ndarray:
    global _bird_eye_view_instance
    
    if bird_eye_view is None:
                                 
        if '_bird_eye_view_instance' not in globals() or _bird_eye_view_instance is None:
            _bird_eye_view_instance = BirdEyeView(**kwargs)
        bird_eye_view = _bird_eye_view_instance
    
    return bird_eye_view.draw(frame, tracks, frame_idx)


                            
_bird_eye_view_instance = None
