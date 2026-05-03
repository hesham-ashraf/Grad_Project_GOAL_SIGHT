import numpy as np
import cv2
from collections import deque


class ViewTransformer():
    def __init__(self, smoothing_window=5, pixel_vertices=None, pitch_length=105.0, pitch_width=68.0):

                                        
        court_width = pitch_width            
        court_length = pitch_length          

                                     
                                            
        if pixel_vertices is not None:
            self.pixel_vertices = np.array(pixel_vertices)
        else:
                                                                  
            self.pixel_vertices = np.array([
                [140, 985],                                
                [280, 265],                            
                [1640, 265],                            
                [1780, 985]                                 
            ])

        self.target_vertices = np.array([
            [0, court_width],                                  
            [0, 0],                                         
            [court_length, 0],                               
            [court_length, court_width]                         
        ])

        self.pixel_vertices = self.pixel_vertices.astype(np.float32)
        self.target_vertices = self.target_vertices.astype(np.float32)

        self.persepctive_trasnformer = cv2.getPerspectiveTransform(
            self.pixel_vertices, self.target_vertices)
        
                   
        self.smoothing_window = smoothing_window
        self.M_history = deque(maxlen=smoothing_window)
        self.M_history.append(self.persepctive_trasnformer)
        
                                                   
        self.position_history = {}                                            
    
    def _clamp_point_to_polygon(self, point):
        """
         FIX: Clamp point to nearest polygon edge instead of returning None
        This prevents players from disappearing on minimap
        """
        p = (int(point[0]), int(point[1]))
        dist = cv2.pointPolygonTest(self.pixel_vertices, p, True)
        
                                                               
                                                         
        if dist >= -30:
            return point
        
                                                            
        min_dist = float('inf')
        nearest_point = point
        
                                                
        for i in range(len(self.pixel_vertices)):
            p1 = self.pixel_vertices[i]
            p2 = self.pixel_vertices[(i + 1) % len(self.pixel_vertices)]
            
                                             
            line_vec = p2 - p1
            point_vec = point - p1
            line_len = np.linalg.norm(line_vec)
            
            if line_len == 0:
                continue
            
            line_unitvec = line_vec / line_len
            proj_length = np.dot(point_vec, line_unitvec)
            proj_length = max(0, min(line_len, proj_length))                    
            
            nearest_on_edge = p1 + line_unitvec * proj_length
            dist_to_edge = np.linalg.norm(point - nearest_on_edge)
            
            if dist_to_edge < min_dist:
                min_dist = dist_to_edge
                nearest_point = nearest_on_edge
        
        return nearest_point

    def transform_point(self, point):
        """
         FIX: Use clamp instead of returning None for out-of-bounds points
         FIX: Use current transformer directly (no mean of matrices)
        """
                                           
        clamped_point = self._clamp_point_to_polygon(point)
        
        reshaped_point = clamped_point.reshape(-1, 1, 2).astype(np.float32)
        
                                                                                      
        tranform_point = cv2.perspectiveTransform(reshaped_point, self.persepctive_trasnformer)
        return tranform_point.reshape(-1, 2)
    
    def update_transformer(self, pixel_vertices, target_vertices):
        """
        تحديث الـ transformer (بدون smoothing للمصفوفات)
        Smoothing happens on positions after transformation instead
        """
        pixel_vertices = pixel_vertices.astype(np.float32)
        target_vertices = target_vertices.astype(np.float32)
        
        new_transformer = cv2.getPerspectiveTransform(pixel_vertices, target_vertices)
        
                                                                               
        self.M_history.append(new_transformer)
        self.persepctive_trasnformer = new_transformer
    
    def diagnose_transformation_issues(self, tracks, sample_frames=5):
        """
         Diagnostic tool to identify transformation problems
        Computes transformations directly and reports statistics
        """
        print("\n ViewTransformer Diagnostics:")
        
        none_count = 0
        total_count = 0
        jump_count = 0
        prev_positions = {}
        clamped_count = 0
        
        for object, object_tracks in tracks.items():
            for frame_num, track in enumerate(object_tracks[:sample_frames]):
                for track_id, track_info in track.items():
                    position = track_info.get('position')
                    if position is None:
                        continue
                    
                    total_count += 1
                    
                                                  
                    position_np = np.array(position)
                    
                                               
                    p = (int(position[0]), int(position[1]))
                    dist = cv2.pointPolygonTest(self.pixel_vertices, p, True)
                    if dist < -30:
                        clamped_count += 1
                    
                                       
                    pos_transformed = self.transform_point(position_np)
                    
                    if pos_transformed is None:
                        none_count += 1
                    else:
                        pos_transformed = pos_transformed.squeeze()
                        key = (object, track_id)
                        if key in prev_positions:
                            dist = np.linalg.norm(pos_transformed - prev_positions[key])
                            if dist > 10:                    
                                jump_count += 1
                                print(f"      Jump detected: {object} ID={track_id} frame {frame_num}: {dist:.1f}m")
                        prev_positions[key] = pos_transformed
        
        print(f"  Total positions: {total_count}")
        if total_count > 0:
            print(f"  None values: {none_count} ({none_count/total_count*100:.1f}%)")
            print(f"  Clamped points: {clamped_count} ({clamped_count/total_count*100:.1f}%)")
        print(f"  Large jumps (>10m): {jump_count}")
        print()

    def add_transformed_position_to_tracks(self, tracks):
        for object, object_tracks in tracks.items():
            for frame_num, track in enumerate(object_tracks):
                for track_id, track_info in track.items():
                                                                                                        
                    position = track_info.get('position')
                    if position is None:
                        continue
                    
                    position = np.array(position)
                    position_trasnformed = self.transform_point(position)
                    
                    if position_trasnformed is not None:
                        position_trasnformed = position_trasnformed.squeeze()
                        
                                                                              
                        key = (object, track_id)
                        if key not in self.position_history:
                            self.position_history[key] = deque(maxlen=3)                     
                        
                        self.position_history[key].append(position_trasnformed)
                        
                                                  
                        if len(self.position_history[key]) >= 2:
                            smoothed = np.mean(self.position_history[key], axis=0)
                            position_trasnformed = smoothed
                        
                        position_trasnformed = position_trasnformed.tolist()
                    
                    tracks[object][frame_num][track_id]['position_transformed'] = position_trasnformed
