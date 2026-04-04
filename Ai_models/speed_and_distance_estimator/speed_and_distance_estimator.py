import cv2
import sys
import numpy as np
from scipy.signal import savgol_filter
from scipy.spatial import ConvexHull
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from utils import measure_distance, get_foot_position
import config


class SpeedAndDistance_Estimator():
    """
    Opta-style Speed & Distance Computation:
    
     Speed:
        speed = distance(pt, pt-1) × fps
        
     Smoothing:
        - EMA (Exponential Moving Average)
        - Savitzky-Golay Filter
        
     Constraints:
        - max_speed = 37 km/h
        - max_acceleration = 4.5 m/s²
        - min_movement = 0.25 m
        
     Final Speed:
        v_t = α · v_t + (1 - α) · v_{t-1}
        
     Distance:
        total_distance += ||pt - pt-1||
        
    Exclude:
        - Dead ball
        - Substituted time
        - Stoppages
    """

    def __init__(self, frame_rate=24, min_frames_for_player=30):
        self.frame_rate = frame_rate
        self.dt = 1.0 / frame_rate                                  
        self.min_frames_for_player = min_frames_for_player
        
                          
        self.pitch_length = 105.0
        self.pitch_width = 68.0
        
                                                                    
        self.max_speed_kmh = config.MAX_SPEED_KMH                    
        self.max_speed_mps = self.max_speed_kmh / 3.6
        self.max_acceleration = config.MAX_ACCELERATION
        self.min_movement = 0.25                                               
        
                                                                        
        self.ema_alpha = 0.3                                         
        self.savgol_window = 5                                                     
        self.savgol_order = 2                                                
        
                                                           
        self.previous_positions = {}                          
        self.previous_speeds = {}                                                
        self.total_distance = {}                                                
        self.speed_history = {}                                                      
        self.speed_values = {}                                                                  
        self.average_speed = {}                                              
        self.frame_count = {}                                                           
        self.excluded_frames = set()                                                
        
    def set_excluded_frames(self, excluded_frames):
        """
        Set frames to exclude from distance calculation.
        Used for: Dead ball, Substituted time, Stoppages
        """
        self.excluded_frames = set(excluded_frames)
    
    def _is_valid_position(self, pos):
        """التحقق من صحة الموقع"""
        if pos is None:
            return False
        if not isinstance(pos, (list, tuple, np.ndarray)) or len(pos) < 2:
            return False
        x, y = float(pos[0]), float(pos[1])
        margin = 10.0
        return (-margin <= x <= self.pitch_length + margin and 
                -margin <= y <= self.pitch_width + margin)
    
    def _apply_ema_smoothing(self, track_id, raw_speed_mps):
        """
        Apply EMA (Exponential Moving Average) smoothing:
        v_t = α · v_raw + (1 - α) · v_{t-1}
        """
        if track_id not in self.previous_speeds:
                                         
            self.previous_speeds[track_id] = raw_speed_mps
            return raw_speed_mps
        
        prev_speed = self.previous_speeds[track_id]
        smoothed_speed = self.ema_alpha * raw_speed_mps + (1 - self.ema_alpha) * prev_speed
        self.previous_speeds[track_id] = smoothed_speed
        
        return smoothed_speed
    
    def _apply_savgol_smoothing(self, track_id, raw_speed_mps):
        """
        Apply Savitzky-Golay filter for smoothing.
        Stores speed history and applies filter when enough data is available.
        """
        if track_id not in self.speed_history:
            self.speed_history[track_id] = []
        
        self.speed_history[track_id].append(raw_speed_mps)
        
                                 
        max_history = 20
        if len(self.speed_history[track_id]) > max_history:
            self.speed_history[track_id] = self.speed_history[track_id][-max_history:]
        
                                                    
        history = self.speed_history[track_id]
        if len(history) >= self.savgol_window:
            try:
                smoothed = savgol_filter(history, self.savgol_window, self.savgol_order)
                return smoothed[-1]                                    
            except Exception:
                return raw_speed_mps
        
        return raw_speed_mps
    
    def _apply_constraints(self, track_id, raw_speed_mps):
        """
        Apply Opta constraints:
        - max_speed = 37 km/h (10.28 m/s)
        - max_acceleration = 4.5 m/s²
        """
                                     
        if raw_speed_mps > self.max_speed_mps:
            raw_speed_mps = self.max_speed_mps
        
                                            
        if track_id in self.previous_speeds:
            prev_speed = self.previous_speeds[track_id]
            acceleration = (raw_speed_mps - prev_speed) / self.dt
            
            if abs(acceleration) > self.max_acceleration:
                                                                  
                max_speed_change = self.max_acceleration * self.dt
                if acceleration > 0:
                    raw_speed_mps = min(raw_speed_mps, prev_speed + max_speed_change)
                else:
                    raw_speed_mps = max(raw_speed_mps, prev_speed - max_speed_change)
        
        return max(0, raw_speed_mps)                           
    
    def add_speed_and_distance_to_tracks(self, tracks):
        """
        Opta-style Speed & Distance Computation:
        
        1. Calculate raw speed: distance(pt, pt-1) × fps
        2. Apply min_movement threshold
        3. Apply constraints (max_speed, max_acceleration)
        4. Apply smoothing (EMA + Savgol)
        5. Accumulate distance (excluding dead ball frames)
        """
                       
        self.previous_positions = {}
        self.previous_speeds = {}
        self.total_distance = {}
        self.speed_history = {}
        self.speed_values = {}                                     
        self.average_speed = {}
        self.frame_count = {}                                
        
        for object_type, object_tracks in tracks.items():
            if object_type == "ball" or object_type == "referees":
                continue
            
            number_of_frames = len(object_tracks)
            
            for frame_num in range(number_of_frames):
                                                                              
                is_excluded = frame_num in self.excluded_frames
                
                for track_id, track_info in object_tracks[frame_num].items():
                    
                                             
                    if track_id not in self.frame_count:
                        self.frame_count[track_id] = 0
                    self.frame_count[track_id] += 1
                    
                                                          
                    current_pos = track_info.get('position_transformed')
                    
                                       
                    if not self._is_valid_position(current_pos):
                        tracks[object_type][frame_num][track_id]['speed'] = 0.0
                        tracks[object_type][frame_num][track_id]['distance'] = self.total_distance.get(track_id, 0.0)
                        continue
                    
                    current_pos = (float(current_pos[0]), float(current_pos[1]))
                    
                                                 
                    if track_id not in self.previous_positions:
                        self.previous_positions[track_id] = current_pos
                        self.total_distance[track_id] = 0.0
                        tracks[object_type][frame_num][track_id]['speed'] = 0.0
                        tracks[object_type][frame_num][track_id]['distance'] = 0.0
                        continue
                    
                                           
                    prev_pos = self.previous_positions[track_id]
                    
                                                             
                    frame_distance = measure_distance(current_pos, prev_pos)
                    
                                                                                        
                    if frame_distance < self.min_movement:
                                                                                       
                        if track_id in self.previous_speeds:
                                                   
                            decayed_speed = self.previous_speeds[track_id] * 0.8
                            self.previous_speeds[track_id] = decayed_speed
                            speed_kmh = decayed_speed * 3.6
                        else:
                            speed_kmh = 0.0
                        
                        tracks[object_type][frame_num][track_id]['speed'] = speed_kmh
                        tracks[object_type][frame_num][track_id]['distance'] = self.total_distance.get(track_id, 0.0)
                                                                     
                        continue
                    
                                                                                   
                                                      
                    raw_speed_mps = frame_distance * self.frame_rate
                    
                                                                                 
                    constrained_speed = self._apply_constraints(track_id, raw_speed_mps)
                    
                                                                               
                                                   
                    savgol_smoothed = self._apply_savgol_smoothing(track_id, constrained_speed)
                    
                                                                              
                    final_speed_mps = self._apply_ema_smoothing(track_id, savgol_smoothed)
                    
                                     
                    speed_kmh = final_speed_mps * 3.6
                    
                                                                                   
                                                                    
                    if not is_excluded:
                        self.total_distance[track_id] += frame_distance
                    
                                                     
                    if track_id not in self.speed_values:
                        self.speed_values[track_id] = []
                    self.speed_values[track_id].append(speed_kmh)
                    
                                            
                    tracks[object_type][frame_num][track_id]['speed'] = speed_kmh
                    tracks[object_type][frame_num][track_id]['distance'] = self.total_distance[track_id]
                    
                                              
                    self.previous_positions[track_id] = current_pos
        
                                                 
        for track_id, speeds in self.speed_values.items():
            if len(speeds) > 0:
                self.average_speed[track_id] = sum(speeds) / len(speeds)
            else:
                self.average_speed[track_id] = 0.0
        
                                                            
        total_players_before = len(self.average_speed)
        valid_player_ids = set()
        
        for track_id in list(self.average_speed.keys()):
            frames_appeared = self.frame_count.get(track_id, 0)
            if frames_appeared >= self.min_frames_for_player:
                valid_player_ids.add(track_id)
            else:
                                       
                del self.average_speed[track_id]
                if track_id in self.total_distance:
                    del self.total_distance[track_id]
                if track_id in self.speed_values:
                    del self.speed_values[track_id]
        
        total_players_after = len(self.average_speed)
        
        print(f"[Player Filter] Before: {total_players_before} players | After: {total_players_after} players (min {self.min_frames_for_player} frames)")
        
                                                                  
        for object_type, object_tracks in tracks.items():
            if object_type == "ball" or object_type == "referees":
                continue
            
            for frame_num in range(len(object_tracks)):
                for track_id in object_tracks[frame_num].keys():
                    if track_id in valid_player_ids and track_id in self.average_speed:
                        tracks[object_type][frame_num][track_id]['avg_speed'] = self.average_speed[track_id]
        
                          
        if self.total_distance:
            print(f"[Opta Speed/Distance] Players tracked: {len(self.total_distance)}")
            sample = list(self.total_distance.items())[:5]
            print(f"[Opta Speed/Distance] Sample distances: {[(id, f'{d:.1f}m') for id, d in sample]}")
            if self.average_speed:
                avg_sample = list(self.average_speed.items())[:5]
                print(f"[Opta Speed/Distance] Sample avg speeds: {[(id, f'{s:.1f}km/h') for id, s in avg_sample]}")
            if self.excluded_frames:
                print(f"[Opta Speed/Distance] Excluded frames: {len(self.excluded_frames)}")

    def draw_speed_and_distance(self, frames, tracks):
        """رسم السرعة والمسافة على الفريمات"""
        output_frames = []
        
        for frame_num, frame in enumerate(frames):
            for object_type, object_tracks in tracks.items():
                if object_type == "ball" or object_type == "referees":
                    continue
                
                for track_id, track_info in object_tracks[frame_num].items():
                    speed = track_info.get('speed')
                    distance = track_info.get('distance')
                    avg_speed = track_info.get('avg_speed')
                    
                    if speed is None or distance is None:
                        continue
                    
                    bbox = track_info.get('bbox')
                    if bbox is None:
                        continue
                    
                    position = get_foot_position(bbox)
                    position = (int(position[0]), int(position[1]) + 40)
                    
                                             
                    speed = min(speed, self.max_speed_kmh)
                    
                                                                      
                    if avg_speed is not None:
                        text = f"Avg:{avg_speed:.1f} | {distance:.0f}m"
                    else:
                        text = f"{speed:.1f}km/h | {distance:.0f}m"
                    
                                     
                    (text_w, text_h), _ = cv2.getTextSize(text, cv2.FONT_HERSHEY_SIMPLEX, 0.4, 1)
                    cv2.rectangle(frame,
                                 (position[0] - 2, position[1] - text_h - 2),
                                 (position[0] + text_w + 2, position[1] + 2),
                                 (255, 255, 255), -1)
                    
                    cv2.putText(frame, text, position,
                               cv2.FONT_HERSHEY_SIMPLEX, 0.4, (0, 0, 0), 1)
            
            output_frames.append(frame)
        
        return output_frames
    
    def save_player_insights(self, tracks, output_path="videos_insights.txt"):
        """
        Save player insights (average speed, distance, and line height) to a text file.
        
        Args:
            tracks: Player tracking data
            output_path: Path to save the insights file
        """
        if not self.average_speed or not self.total_distance:
            print("[Warning] No player data available to save")
            return
        
                                    
        print(" Calculating tactical metrics...")
        line_heights = self.calculate_line_height(tracks)
        convex_hull_areas = self.calculate_convex_hull_area(tracks)
        
        print(f"   Line Heights: {len(line_heights)} teams")
        print(f"   Convex Hull Areas: {len(convex_hull_areas)} teams")
        
                                      
        player_data = []
        for track_id in self.average_speed.keys():
            avg_speed = self.average_speed.get(track_id, 0.0)
            distance = self.total_distance.get(track_id, 0.0)
            player_data.append({
                'player_id': track_id,
                'avg_speed_kmh': avg_speed,
                'total_distance_m': distance
            })
        
                           
        player_data.sort(key=lambda x: x['player_id'])
        
                       
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write("=" * 60 + "\n")
            f.write("VIDEO INSIGHTS - PLAYER STATISTICS\n")
            f.write("=" * 60 + "\n\n")
            
            f.write(f"Total Players Tracked: {len(player_data)}\n")
            f.write(f"Frame Rate: {self.frame_rate} fps\n")
            f.write(f"Pitch Length: {self.pitch_length} m\n\n")
            
            f.write("-" * 60 + "\n")
            f.write(f"{'Player ID':<12} | {'Avg Speed (km/h)':<18} | {'Distance (m)':<15}\n")
            f.write("-" * 60 + "\n")
            
            for player in player_data:
                f.write(f"{player['player_id']:<12} | "
                       f"{player['avg_speed_kmh']:>16.2f}  | "
                       f"{player['total_distance_m']:>13.2f}\n")
            
            f.write("-" * 60 + "\n\n")
            
                                
            if player_data:
                avg_speeds = [p['avg_speed_kmh'] for p in player_data]
                distances = [p['total_distance_m'] for p in player_data]
                
                f.write("SUMMARY STATISTICS:\n")
                f.write("-" * 60 + "\n")
                f.write(f"Average Speed (All Players): {sum(avg_speeds)/len(avg_speeds):.2f} km/h\n")
                f.write(f"Max Speed: {max(avg_speeds):.2f} km/h (Player {player_data[avg_speeds.index(max(avg_speeds))]['player_id']})\n")
                f.write(f"Min Speed: {min(avg_speeds):.2f} km/h (Player {player_data[avg_speeds.index(min(avg_speeds))]['player_id']})\n\n")
                
                f.write(f"Average Distance (All Players): {sum(distances)/len(distances):.2f} m\n")
                f.write(f"Max Distance: {max(distances):.2f} m (Player {player_data[distances.index(max(distances))]['player_id']})\n")
                f.write(f"Min Distance: {min(distances):.2f} m (Player {player_data[distances.index(min(distances))]['player_id']})\n")
            
                                  
            if line_heights:
                f.write("\n" + "=" * 60 + "\n")
                f.write("TACTICAL ANALYSIS - DEFENSIVE LINE HEIGHT\n")
                f.write("=" * 60 + "\n\n")
                
                f.write("Line Height: Average position of defenders on the pitch.\n")
                f.write("- Higher value = More advanced/aggressive defensive line\n")
                f.write("- Lower value = Deeper/conservative defensive line\n\n")
                
                                            
                team_names = {
                    'team_1': f"{config.TEAM_1_NAME} (Blue - Team 1)",
                    'team_2': f"{config.TEAM_2_NAME} (Red - Team 2)"
                }
                
                for team_key in ['team_1', 'team_2']:
                    if team_key in line_heights:
                        team_data = line_heights[team_key]
                        team_display_name = team_names.get(team_key, team_key)
                        line_height = team_data['line_height']
                        num_defenders = team_data['num_defenders']
                        
                                                       
                        line_height_pct = (line_height / self.pitch_length) * 100
                        
                        f.write(f"{team_display_name}:\n")
                        f.write(f"  Line Height: {line_height:.2f} m ({line_height_pct:.1f}% of pitch)\n")
                        f.write(f"  Number of Defenders: {num_defenders}\n")
                        f.write(f"  Defender IDs: {team_data['defenders']}\n")
                        
                                        
                        if line_height_pct > 60:
                            style = "Very High Press (Aggressive)"
                        elif line_height_pct > 50:
                            style = "High Press"
                        elif line_height_pct > 40:
                            style = "Medium Block"
                        else:
                            style = "Low Block (Defensive)"
                        
                        f.write(f"  Defensive Style: {style}\n\n")
                
                               
                if 'team_1' in line_heights and 'team_2' in line_heights:
                    diff = abs(line_heights['team_1']['line_height'] - line_heights['team_2']['line_height'])
                    f.write(f"Line Height Difference: {diff:.2f} m\n")
                    
                    if line_heights['team_1']['line_height'] > line_heights['team_2']['line_height']:
                        f.write(f"→ {config.TEAM_1_NAME} plays with a more advanced defensive line\n")
                    else:
                        f.write(f"→ {config.TEAM_2_NAME} plays with a more advanced defensive line\n")
            
                                       
            if convex_hull_areas:
                f.write("\n" + "=" * 60 + "\n")
                f.write("TACTICAL ANALYSIS - CONVEX HULL AREA (COMPACTNESS)\n")
                f.write("=" * 60 + "\n\n")
                
                f.write("Convex Hull Area: The area covered by the team on the pitch.\n")
                f.write("- Smaller area = More compact/defensive formation\n")
                f.write("- Larger area = More spread out/attacking formation\n\n")
                
                                            
                team_names = {
                    'team_1': f"{config.TEAM_1_NAME} (Blue - Team 1)",
                    'team_2': f"{config.TEAM_2_NAME} (Red - Team 2)"
                }
                
                                                          
                total_pitch_area = self.pitch_length * self.pitch_width                      
                
                for team_key in ['team_1', 'team_2']:
                    if team_key in convex_hull_areas:
                        team_data = convex_hull_areas[team_key]
                        team_display_name = team_names.get(team_key, team_key)
                        
                        avg_area = team_data['avg_area']
                        min_area = team_data['min_area']
                        max_area = team_data['max_area']
                        median_area = team_data['median_area']
                        
                                                       
                        avg_area_pct = (avg_area / total_pitch_area) * 100
                        
                        f.write(f"{team_display_name}:\n")
                        f.write(f"  Average Area: {avg_area:.2f} m² ({avg_area_pct:.1f}% of pitch)\n")
                        f.write(f"  Median Area: {median_area:.2f} m²\n")
                        f.write(f"  Min Area (Most Compact): {min_area:.2f} m²\n")
                        f.write(f"  Max Area (Most Spread): {max_area:.2f} m²\n")
                        
                                        
                        if avg_area_pct < 20:
                            compactness = "Very Compact (Defensive)"
                        elif avg_area_pct < 30:
                            compactness = "Compact (Organized)"
                        elif avg_area_pct < 40:
                            compactness = "Moderate Spread"
                        else:
                            compactness = "Very Spread Out (Attacking)"
                        
                        f.write(f"  Formation Style: {compactness}\n\n")
                
                               
                if 'team_1' in convex_hull_areas and 'team_2' in convex_hull_areas:
                    area_diff = abs(convex_hull_areas['team_1']['avg_area'] - convex_hull_areas['team_2']['avg_area'])
                    area_diff_pct = (area_diff / total_pitch_area) * 100
                    
                    f.write(f"Area Difference: {area_diff:.2f} m² ({area_diff_pct:.1f}% of pitch)\n")
                    
                    if convex_hull_areas['team_1']['avg_area'] > convex_hull_areas['team_2']['avg_area']:
                        f.write(f"→ {config.TEAM_1_NAME} plays with a more spread out formation\n")
                        f.write(f"→ {config.TEAM_2_NAME} plays with a more compact formation\n")
                    else:
                        f.write(f"→ {config.TEAM_2_NAME} plays with a more spread out formation\n")
                        f.write(f"→ {config.TEAM_1_NAME} plays with a more compact formation\n")
            
            f.write("\n" + "=" * 60 + "\n")
        
        print(f" Player insights saved to: {output_path}")
        return output_path
    
    def calculate_line_height(self, tracks):
        """
        Calculate defensive line height for each team.
        
        Line Height = Average position of defenders (players closest to their own goal).
        Higher value = more advanced defensive line.
        
        Returns:
            dict: {'team_1': line_height, 'team_2': line_height}
        """
                                                   
        player_avg_positions = {}                             
        player_teams = {}                    
        
        for frame_num, player_track in enumerate(tracks.get('players', [])):
            for player_id, track_info in player_track.items():
                pos = track_info.get('position_transformed')
                team = track_info.get('team')
                
                if pos is not None and team is not None:
                    if player_id not in player_avg_positions:
                        player_avg_positions[player_id] = {'x_values': [], 'team': team}
                        player_teams[player_id] = team
                    
                    player_avg_positions[player_id]['x_values'].append(float(pos[0]))
        
                                                      
        for player_id in player_avg_positions:
            x_values = player_avg_positions[player_id]['x_values']
            if len(x_values) > 0:
                player_avg_positions[player_id]['avg_x'] = sum(x_values) / len(x_values)
            else:
                player_avg_positions[player_id]['avg_x'] = 0.0
        
                                  
        team_1_players = []
        team_2_players = []
        
        for player_id, data in player_avg_positions.items():
            if data['team'] == 1:
                team_1_players.append((player_id, data['avg_x']))
            elif data['team'] == 2:
                team_2_players.append((player_id, data['avg_x']))
        
                                                     
                                                                                
                                                         
        
        line_heights = {}
        
                                                
        if len(team_1_players) >= 3:
            team_1_players.sort(key=lambda x: x[1])                      
            num_defenders = max(3, len(team_1_players) // 3)                          
            defenders_x = [p[1] for p in team_1_players[:num_defenders]]
            line_heights['team_1'] = {
                'line_height': sum(defenders_x) / len(defenders_x),
                'defenders': [p[0] for p in team_1_players[:num_defenders]],
                'num_defenders': num_defenders
            }
        
                                                 
        if len(team_2_players) >= 3:
            team_2_players.sort(key=lambda x: x[1], reverse=True)                                   
            num_defenders = max(3, len(team_2_players) // 3)                          
            defenders_x = [p[1] for p in team_2_players[:num_defenders]]
            line_heights['team_2'] = {
                'line_height': sum(defenders_x) / len(defenders_x),
                'defenders': [p[0] for p in team_2_players[:num_defenders]],
                'num_defenders': num_defenders
            }
        
        return line_heights
    
    def calculate_convex_hull_area(self, tracks):
        """
        Calculate the average Convex Hull Area for each team.
        
        Convex Hull Area = The area covered by the team on the pitch.
        - Smaller area = More compact/defensive team
        - Larger area = More spread out/attacking team
        
        Returns:
            dict: {
                'team_1': {'avg_area': float, 'min_area': float, 'max_area': float},
                'team_2': {'avg_area': float, 'min_area': float, 'max_area': float}
            }
        """
        team_1_areas = []
        team_2_areas = []
        
        for frame_num, player_track in enumerate(tracks.get('players', [])):
            team_1_positions = []
            team_2_positions = []
            
            for player_id, track_info in player_track.items():
                pos = track_info.get('position_transformed')
                team = track_info.get('team')
                
                if pos is not None and team is not None:
                    if team == 1:
                        team_1_positions.append([float(pos[0]), float(pos[1])])
                    elif team == 2:
                        team_2_positions.append([float(pos[0]), float(pos[1])])
            
                                              
            if len(team_1_positions) >= 3:                                     
                try:
                    hull = ConvexHull(np.array(team_1_positions))
                    team_1_areas.append(hull.volume)                        
                except:
                    pass                                  
            
                                              
            if len(team_2_positions) >= 3:
                try:
                    hull = ConvexHull(np.array(team_2_positions))
                    team_2_areas.append(hull.volume)
                except:
                    pass
        
        results = {}
        
        if team_1_areas:
            results['team_1'] = {
                'avg_area': sum(team_1_areas) / len(team_1_areas),
                'min_area': min(team_1_areas),
                'max_area': max(team_1_areas),
                'median_area': sorted(team_1_areas)[len(team_1_areas)//2]
            }
        
        if team_2_areas:
            results['team_2'] = {
                'avg_area': sum(team_2_areas) / len(team_2_areas),
                'min_area': min(team_2_areas),
                'max_area': max(team_2_areas),
                'median_area': sorted(team_2_areas)[len(team_2_areas)//2]
            }
        
        return results
    
    def calculate_pressing_index(self, tracks, pressing_radius=7.0, closing_speed_threshold=2.0):
        """
        Calculate Pressing Index - a quantitative measure of how aggressively 
        a team pressures the ball carrier.
        
        This is a REAL pressing metric, not inferred from line height.
        
        Algorithm:
        1. For each frame, calculate distance between each defending player and the ball
        2. Count defenders within pressing radius (5-7m)
        3. Calculate closing speed (speed of approach to ball)
        4. Pressing = Σ(1 - distance_i/R) for distance < R
        5. Add weight for players closing down quickly
        
        Args:
            tracks: Player and ball tracking data
            pressing_radius: Radius in meters to consider pressing (default 7m)
            closing_speed_threshold: Speed threshold for aggressive closing (m/s)
            
        Returns:
            dict: {
                'team_1': {'avg_pressing': float, 'high_press_frames': int, ...},
                'team_2': {'avg_pressing': float, 'high_press_frames': int, ...}
            }
        """
        team_1_pressing_values = []
        team_2_pressing_values = []
        
        team_1_high_press_count = 0
        team_2_high_press_count = 0
        
                                                                
        prev_distances_to_ball = {}                                  
        
        for frame_num, player_track in enumerate(tracks.get('players', [])):
                               
            ball_data = tracks.get('ball', [])[frame_num].get(1, {})
            ball_pos = ball_data.get('position_transformed')
            
                                                                       
            if ball_pos is None:
                ball_pos = ball_data.get('position')
            
            if ball_pos is None:
                continue
            
            ball_pos = (float(ball_pos[0]), float(ball_pos[1]))
            
            team_1_pressing = 0.0
            team_2_pressing = 0.0
            team_1_count = 0
            team_2_count = 0
            
            for player_id, track_info in player_track.items():
                pos = track_info.get('position_transformed')
                team = track_info.get('team')
                
                if pos is None or team is None:
                    continue
                
                pos = (float(pos[0]), float(pos[1]))
                
                                            
                distance_to_ball = measure_distance(pos, ball_pos)
                
                                                                          
                closing_speed = 0.0
                if frame_num > 0:
                    prev_key = (frame_num - 1, player_id)
                    if prev_key in prev_distances_to_ball:
                        prev_distance = prev_distances_to_ball[prev_key]
                                                                      
                        closing_speed = (prev_distance - distance_to_ball) * self.frame_rate
                
                                                       
                prev_distances_to_ball[(frame_num, player_id)] = distance_to_ball
                
                                                                  
                if distance_to_ball < pressing_radius:
                                                           
                    base_pressing = 1.0 - (distance_to_ball / pressing_radius)
                    
                                                  
                    speed_weight = 0.0
                    if closing_speed > closing_speed_threshold:
                                                              
                        speed_weight = min(closing_speed / 10.0, 0.5)              
                    
                    pressing_value = base_pressing + speed_weight
                    
                    if team == 1:
                        team_1_pressing += pressing_value
                        team_1_count += 1
                    elif team == 2:
                        team_2_pressing += pressing_value
                        team_2_count += 1
            
                                         
            if team_1_count > 0:
                team_1_pressing_values.append(team_1_pressing)
                                                                  
                if team_1_count >= 3:
                    team_1_high_press_count += 1
            
            if team_2_count > 0:
                team_2_pressing_values.append(team_2_pressing)
                if team_2_count >= 3:
                    team_2_high_press_count += 1
        
        results = {}
        total_frames = len(tracks.get('players', []))
        
        if team_1_pressing_values:
            results['team_1'] = {
                'avg_pressing': sum(team_1_pressing_values) / len(team_1_pressing_values),
                'max_pressing': max(team_1_pressing_values),
                'min_pressing': min(team_1_pressing_values),
                'high_press_frames': team_1_high_press_count,
                'high_press_percentage': (team_1_high_press_count / total_frames) * 100 if total_frames > 0 else 0
            }
        
        if team_2_pressing_values:
            results['team_2'] = {
                'avg_pressing': sum(team_2_pressing_values) / len(team_2_pressing_values),
                'max_pressing': max(team_2_pressing_values),
                'min_pressing': min(team_2_pressing_values),
                'high_press_frames': team_2_high_press_count,
                'high_press_percentage': (team_2_high_press_count / total_frames) * 100 if total_frames > 0 else 0
            }
        
                    
        if results:
            print(f"[Pressing Index] Calculated for {len(results)} teams")
            for team_key, data in results.items():
                print(f"  {team_key}: avg={data['avg_pressing']:.2f}, high_press={data['high_press_percentage']:.1f}%")
        else:
            print("[Warning] No pressing data calculated - check ball positions")
        
        return results