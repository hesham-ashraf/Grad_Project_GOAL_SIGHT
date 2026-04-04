from ultralytics import YOLO
import supervision as sv
import pickle
import os
import numpy as np
import pandas as pd
import cv2
import sys 
sys.path.append('../')
from utils import get_center_of_bbox, get_bbox_width, get_foot_position, is_valid_bbox
from tqdm import tqdm


class Tracker:
    def __init__(self, model_path, use_hybrid_tracking=False, fps=30, use_appearance=False):
        """
        Args:
            model_path: Path to YOLO model
            fps: Frame rate
        """
        self.model = YOLO(model_path)
        
                                                               
        self.tracker = sv.ByteTrack(
            track_activation_threshold=0.20,                              
            lost_track_buffer=180,                                              
            minimum_matching_threshold=0.80,                                
            minimum_consecutive_frames=2,                                 
            frame_rate=fps
        )
        
                                     
        self.track_history = {}                                                                        
        self.referee_ids = set()                      
        
        print(" Using ByteTrack Tracker (Optimized for ID stability + Anti-switching)")

    def add_position_to_tracks(self, tracks):
        for object, object_tracks in tracks.items():
            for frame_num, track in enumerate(object_tracks):
                for track_id, track_info in track.items():
                    bbox = track_info.get('bbox')
                    if bbox is None:
                        tracks[object][frame_num][track_id]['position'] = None
                        continue
                    
                    if object == 'ball':
                        position = get_center_of_bbox(bbox)
                    else:
                        position = get_foot_position(bbox)
                    tracks[object][frame_num][track_id]['position'] = position

    def interpolate_ball_positions(self, ball_positions):
        ball_positions = [x.get(1,{}).get('bbox',[]) for x in ball_positions]
                                                                        
        ball_positions = [pos if len(pos) == 4 else [None, None, None, None] for pos in ball_positions]
        df_ball_positions = pd.DataFrame(ball_positions, columns=['x1','y1','x2','y2'])
        
                                                  
        df_ball_positions = df_ball_positions.astype(float)

                                    
        df_ball_positions = df_ball_positions.interpolate()
        df_ball_positions = df_ball_positions.bfill()

        ball_positions = [{1: {"bbox":x}} for x in df_ball_positions.to_numpy().tolist()]

        return ball_positions

    def detect_frames(self, frames, conf=0.35, batch_size=20):
        """
        Detect objects in frames using YOLO.
        Returns dict keyed by frame_num.
        """
        detections = []
        
        print(f" Detecting objects in {len(frames)} frames...")
        for i in tqdm(range(0, len(frames), batch_size), desc="Detection"):
            batch_frames = frames[i:i + batch_size]
                                                     
            detections_batch = self.model.predict(batch_frames, conf=0.15, verbose=False)
            detections.extend(detections_batch)
        
                       
        return self._track_with_bytetrack(detections)

    def get_object_tracks(self, frames, read_from_stub=False, stub_path=None, view_transformer=None):
        """
        Get object tracks from video frames using ByteTrack.
        """
        if read_from_stub and stub_path is not None and os.path.exists(stub_path):
            with open(stub_path, 'rb') as f:
                tracks = pickle.load(f)
            return tracks
        
                          
        detections = self.detect_frames(frames)
        
                                     
        tracks_dict = {
            "players": [],
            "referees": [],
            "ball": []
        }
        
        for frame_num, frame_detections in detections.items():
            player_dict = {}
            referee_dict = {}
            ball_dict = {}
            
                               
            if 2 in frame_detections:
                for track_id, track_data in frame_detections[2].items():
                    player_dict[track_id] = track_data
            
                                
            if 3 in frame_detections:
                for track_id, track_data in frame_detections[3].items():
                    referee_dict[track_id] = track_data
            
                            
            if 0 in frame_detections:
                for track_id, track_data in frame_detections[0].items():
                    ball_dict[track_id] = track_data
            
            tracks_dict["players"].append(player_dict)
            tracks_dict["referees"].append(referee_dict)
            tracks_dict["ball"].append(ball_dict)
        
                                
        if stub_path is not None:
            with open(stub_path, 'wb') as f:
                pickle.dump(tracks_dict, f)
        
        return tracks_dict

    def _track_with_bytetrack(self, detections):
        """Track using ByteTrack for players/referees, simple detection for ball
        
        مع حماية ضد:
        - تحول الحكم للاعب
        - ID switches
        """
        tracks = {}
        
                                                         
        track_class_history = {}                                                   
        confirmed_referees = set()                      
        confirmed_players = set()                        
        CLASS_CONFIRM_THRESHOLD = 10                                 
        
        for frame_num, detection in enumerate(tqdm(detections, desc="ByteTrack")):
            cls_names = detection.names
            cls_names_inv = {v: k for k, v in cls_names.items()}
            
                                           
            detection_supervision = sv.Detections.from_ultralytics(detection)
            
                                                            
            ball_mask = detection_supervision.class_id == cls_names_inv.get("ball", 0)
            player_referee_mask = ~ball_mask
            
                                                       
            if player_referee_mask.any():
                player_referee_detections = detection_supervision[player_referee_mask]
                
                                              
                for object_ind, class_id in enumerate(player_referee_detections.class_id):
                    if cls_names[class_id] == "goalkeeper":
                        player_referee_detections.class_id[object_ind] = cls_names_inv["player"]
                
                                
                detection_with_tracks = self.tracker.update_with_detections(player_referee_detections)
            else:
                detection_with_tracks = sv.Detections.empty()
            
                                   
            tracks[frame_num] = {}
            
                                                                    
            if len(detection_with_tracks) > 0 and detection_with_tracks.tracker_id is not None:
                for i in range(len(detection_with_tracks.xyxy)):
                    if i >= len(detection_with_tracks.tracker_id):
                        break
                    
                    bbox = detection_with_tracks.xyxy[i].tolist()
                    detected_cls_id = detection_with_tracks.class_id[i]
                    track_id = detection_with_tracks.tracker_id[i]
                    
                                          
                    detected_class_name = cls_names.get(detected_cls_id, "player")
                    
                                                     
                                                 
                    if track_id not in track_class_history:
                        track_class_history[track_id] = {'player': 0, 'referee': 0}
                    
                                                    
                    if detected_class_name == 'referee':
                        track_class_history[track_id]['referee'] += 1
                    else:
                        track_class_history[track_id]['player'] += 1
                    
                                             
                    final_cls_id = detected_cls_id
                    
                                                          
                    if track_id in confirmed_referees:
                        final_cls_id = cls_names_inv.get("referee", 3)
                                                            
                    elif track_id in confirmed_players:
                        final_cls_id = cls_names_inv.get("player", 2)
                    else:
                                                           
                        history = track_class_history[track_id]
                        total = history['player'] + history['referee']
                        
                        if total >= CLASS_CONFIRM_THRESHOLD:
                            if history['referee'] > history['player'] * 1.5:
                                                           
                                confirmed_referees.add(track_id)
                                final_cls_id = cls_names_inv.get("referee", 3)
                            elif history['player'] > history['referee'] * 1.5:
                                             
                                confirmed_players.add(track_id)
                                final_cls_id = cls_names_inv.get("player", 2)
                    
                                      
                    if final_cls_id not in tracks[frame_num]:
                        tracks[frame_num][final_cls_id] = {}
                    
                    tracks[frame_num][final_cls_id][track_id] = {"bbox": bbox}
            
                                                               
            if ball_mask.any():
                ball_detections = detection_supervision[ball_mask]
                ball_class_id = cls_names_inv.get("ball", 0)
                
                if ball_class_id not in tracks[frame_num]:
                    tracks[frame_num][ball_class_id] = {}
                
                                                            
                if len(ball_detections) > 0:
                    best_ball_idx = 0
                    if hasattr(ball_detections, 'confidence') and ball_detections.confidence is not None:
                        best_ball_idx = ball_detections.confidence.argmax()
                    
                    bbox = ball_detections.xyxy[best_ball_idx].tolist()
                                                               
                    tracks[frame_num][ball_class_id][1] = {"bbox": bbox}
        
                        
        print(f"\n Tracking Statistics:")
        print(f"   Confirmed Players: {len(confirmed_players)}")
        print(f"   Confirmed Referees: {len(confirmed_referees)}")
        
        return tracks
    
    def draw_ellipse(self, frame, bbox, color, track_id=None):
                                
        if not is_valid_bbox(bbox):
            return frame
        
        center = get_center_of_bbox(bbox)
        if center is None:
            return frame
        
        y2 = int(bbox[3])
        x_center, _ = center
        width = get_bbox_width(bbox)

        cv2.ellipse(
            frame,
            center=(x_center, y2),
            axes=(int(width), int(0.35*width)),
            angle=0.0,
            startAngle=-45,
            endAngle=235,
            color=color,
            thickness=2,
            lineType=cv2.LINE_4
        )

        rectangle_width = 40
        rectangle_height = 20
        x1_rect = x_center - rectangle_width//2
        x2_rect = x_center + rectangle_width//2
        y1_rect = (y2 - rectangle_height//2) + 15
        y2_rect = (y2 + rectangle_height//2) + 15

        if track_id is not None:
            cv2.rectangle(frame,
                          (int(x1_rect), int(y1_rect)),
                          (int(x2_rect), int(y2_rect)),
                          color,
                          cv2.FILLED)
            
            x1_text = x1_rect + 12
            if track_id > 99:
                x1_text -= 10
            
            cv2.putText(
                frame,
                f"{track_id}",
                (int(x1_text), int(y1_rect+15)),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.6,
                (0, 0, 0),
                2
            )

        return frame

    def draw_traingle(self, frame, bbox, color):
                                
        if not is_valid_bbox(bbox):
            return frame
        
        center = get_center_of_bbox(bbox)
        if center is None:
            return frame
        
        y = int(bbox[1])
        x, _ = center

        triangle_points = np.array([
            [x, y],
            [x-10, y-20],
            [x+10, y-20],
        ])
        cv2.drawContours(frame, [triangle_points], 0, color, cv2.FILLED)
        cv2.drawContours(frame, [triangle_points], 0, (0, 0, 0), 2)

        return frame

    def draw_team_ball_control(self, frame, frame_num, team_ball_control):
                                            
        overlay = frame.copy()
        cv2.rectangle(overlay, (1350, 850), (1900, 970), (255, 255, 255), -1)
        alpha = 0.4
        cv2.addWeighted(overlay, alpha, frame, 1 - alpha, 0, frame)

        team_ball_control_till_frame = team_ball_control[:frame_num+1]
                                                           
        team_1_num_frames = team_ball_control_till_frame[team_ball_control_till_frame==1].shape[0]
        team_2_num_frames = team_ball_control_till_frame[team_ball_control_till_frame==2].shape[0]
        total = team_1_num_frames + team_2_num_frames
        if total == 0:
            team_1 = 0.5
            team_2 = 0.5
        else:
            team_1 = team_1_num_frames / total
            team_2 = team_2_num_frames / total

                                     
        cv2.putText(frame, f"Team Blue: {team_1*100:.2f}%", (1400, 900), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 3)
        cv2.putText(frame, f"Team Red: {team_2*100:.2f}%", (1400, 950), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 3)

        return frame

    def draw_annotations(self, video_frames, tracks, team_ball_control):
        output_video_frames = []
        last_valid_ball_bbox = None                           
        
        for frame_num, frame in enumerate(video_frames):
            frame = frame.copy()

            player_dict = tracks["players"][frame_num]
            ball_dict = tracks["ball"][frame_num]
            referee_dict = tracks["referees"][frame_num]

                          
            for track_id, player in player_dict.items():
                player_bbox = player.get("bbox")
                if not is_valid_bbox(player_bbox):
                    continue
                
                                                                 
                team = player.get("team", 1)
                if team == 1:
                    color = (255, 0, 0)        
                else:
                    color = (0, 0, 255)       
                
                frame = self.draw_ellipse(frame, player_bbox, color, track_id)

                if player.get('has_ball', False):
                    frame = self.draw_traingle(frame, player_bbox, (0, 0, 255))

                          
            for _, referee in referee_dict.items():
                referee_bbox = referee.get("bbox")
                if is_valid_bbox(referee_bbox):
                    frame = self.draw_ellipse(frame, referee_bbox, (0, 255, 255))
            
                                                    
            for track_id, ball in ball_dict.items():
                ball_bbox = ball.get("bbox")
                
                                  
                if is_valid_bbox(ball_bbox):
                    last_valid_ball_bbox = ball_bbox
                else:
                                          
                    ball_bbox = last_valid_ball_bbox
                
                                                 
                if ball_bbox is not None:
                    frame = self.draw_traingle(frame, ball_bbox, (0, 255, 0))

                                    
            frame = self.draw_team_ball_control(frame, frame_num, team_ball_control)

            output_video_frames.append(frame)

        return output_video_frames
