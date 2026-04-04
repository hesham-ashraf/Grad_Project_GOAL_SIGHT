import cv2
import numpy as np


def draw_minimap(
    frame,
    tracks,
    frame_idx: int,
    pitch_length=105.0,
    pitch_width=68.0,
    map_size=(400, 260),
    position=None,
    show_voronoi=False
):

    if position is None:
        position = (frame.shape[1] - map_size[0] - 50, 50)
    
    w, h = map_size
    x0, y0 = position

                    
    minimap = np.zeros((h, w, 3), dtype=np.uint8)
    minimap[:] = (30, 80, 30)
    
            
    cv2.rectangle(minimap, (0, 0), (w-1, h-1), (255, 255, 255), 2)
    
              
    mx = w // 2
    cv2.line(minimap, (mx, 0), (mx, h), (255, 255, 255), 2)
    
                   
    circle_radius = int(9.15 / pitch_length * w)
    cv2.circle(minimap, (w//2, h//2), circle_radius, (200, 200, 200), 1)
    cv2.circle(minimap, (w//2, h//2), 2, (255, 255, 255), -1)
    
                   
    penalty_w = int(16.5 / pitch_length * w)
    penalty_h = int(40.32 / pitch_width * h)
    cv2.rectangle(minimap, (0, (h - penalty_h) // 2), 
                  (penalty_w, (h + penalty_h) // 2), (200, 200, 200), 1)
    cv2.rectangle(minimap, (w - penalty_w, (h - penalty_h) // 2), 
                  (w, (h + penalty_h) // 2), (200, 200, 200), 1)
    
                
    goal_w = int(5.5 / pitch_length * w)
    goal_h = int(18.32 / pitch_width * h)
    cv2.rectangle(minimap, (0, (h - goal_h) // 2), 
                  (goal_w, (h + goal_h) // 2), (200, 200, 200), 1)
    cv2.rectangle(minimap, (w - goal_w, (h - goal_h) // 2), 
                  (w, (h + goal_h) // 2), (200, 200, 200), 1)

    def to_map_xy(X, Y):
        u = int((X / pitch_length) * w)
        v = int((Y / pitch_width) * h)
        return np.clip(u, 0, w-1), np.clip(v, 0, h-1)

                                                       
    TEAM_COLORS = {
        1: (255, 0, 0),                         
        2: (0, 0, 255)                         
    }
    
                  
    if "players" in tracks and frame_idx < len(tracks["players"]):
        for pid, info in tracks["players"][frame_idx].items():
            p = info.get("position_transformed", None)
            if p is None or not isinstance(p, (list, tuple)) or len(p) < 2:
                continue
            
            X, Y = float(p[0]), float(p[1])
            if not (0 <= X <= pitch_length and 0 <= Y <= pitch_width):
                continue

                                                                       
            team = info.get("team", 1)
            team_color = info.get("team_color")
            
            u, v = to_map_xy(X, Y)
            
                                                      
            if team_color is not None:
                                                                             
                color = TEAM_COLORS.get(team, (255, 0, 0))
            else:
                color = TEAM_COLORS.get(team, (255, 0, 0))
            
                                           
            has_ball = info.get("has_ball", False)
            radius = 8 if has_ball else 6
            
            cv2.circle(minimap, (u, v), radius, color, -1)
            cv2.circle(minimap, (u, v), radius, (255, 255, 255), 1)
            
                                                
            if has_ball:
                cv2.circle(minimap, (u, v), 3, (0, 255, 0), -1)

               
    if "ball" in tracks and frame_idx < len(tracks["ball"]):
        ball_dict = tracks["ball"][frame_idx]
        ball_info = None
        
        if isinstance(ball_dict, dict):
            if 1 in ball_dict:
                ball_info = ball_dict[1]
            elif "position_transformed" in ball_dict:
                ball_info = ball_dict
        
        if ball_info is not None:
            p = ball_info.get("position_transformed", None)
            if p is not None and isinstance(p, (list, tuple)) and len(p) >= 2:
                X, Y = float(p[0]), float(p[1])
                
                if (0 <= X <= pitch_length and 0 <= Y <= pitch_width):
                    u, v = to_map_xy(X, Y)
                    cv2.circle(minimap, (u, v), 8, (0, 255, 255), -1)          
                    cv2.circle(minimap, (u, v), 8, (0, 0, 0), 2)

                      
    if y0 + h > frame.shape[0]:
        y0 = frame.shape[0] - h
    if x0 + w > frame.shape[1]:
        x0 = frame.shape[1] - w
    
    alpha = 0.95
    overlay = frame.copy()
    overlay[y0:y0+h, x0:x0+w] = minimap
    frame[y0:y0+h, x0:x0+w] = cv2.addWeighted(
        overlay[y0:y0+h, x0:x0+w], alpha,
        frame[y0:y0+h, x0:x0+w], 1-alpha, 0
    )

    return frame
