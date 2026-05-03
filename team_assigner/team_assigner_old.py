import numpy as np
import cv2
from sklearn.cluster import KMeans
from collections import defaultdict


class TeamAssigner:

    
                                 
    REFEREE_COLORS = {
        'yellow': (25, 200, 200),         
        'black': (0, 0, 50),               
    }
    
    def __init__(self, confidence_threshold=0.6, confirm_frames=5, color_change_threshold=40):

        self.team_colors = {}                                           
        self.player_team_dict = {}                                                       
        self.player_team_votes = defaultdict(list)                                               
        self.player_color_history = {}                                                            
        self.kmeans = None
        self.cluster_to_team = None
        
                         
        self.confidence_threshold = confidence_threshold
        self.confirm_frames = confirm_frames
        self.color_change_threshold = color_change_threshold

                                                     
    
    def _clamp_bbox(self, bbox, w, h):
        x1, y1, x2, y2 = map(int, bbox)
        x1 = max(0, min(x1, w - 1))
        x2 = max(0, min(x2, w - 1))
        y1 = max(0, min(y1, h - 1))
        y2 = max(0, min(y2, h - 1))
        if x2 <= x1 or y2 <= y1:
            return None
        return [x1, y1, x2, y2]

    def _circular_hue_distance(self, h1, h2):
        d = abs(float(h1) - float(h2))
        return min(d, 180.0 - d)

    def _color_distance(self, c1, c2):
        h_dist = self._circular_hue_distance(c1[0], c2[0])
        s_dist = abs(c1[1] - c2[1])
        v_dist = abs(c1[2] - c2[2])
        return h_dist + s_dist * 0.5 + v_dist * 0.3

    def _is_grass_like(self, h, s, v):
        return (35 <= h <= 90) and (s >= 40) and (v >= 40)

    def _is_referee_color(self, hsv_color):

        h, s, v = hsv_color
        
                                           
        if 15 <= h <= 40 and s >= 80 and v >= 120:
            return True
        
                                                   
        if 40 <= h <= 80 and s >= 120 and v >= 100:
            return True
        
                              
        if (h <= 15 or h >= 165) and s >= 100 and v >= 120:
            return True
        
                                            
        if s <= 40 and v <= 70:
            return True
        
        return False

                                                          
    
    def _get_smart_crop(self, frame, bbox):

        H, W = frame.shape[:2]
        bbox = self._clamp_bbox(bbox, W, H)
        if bbox is None:
            return None, None

        x1, y1, x2, y2 = bbox
        height = y2 - y1
        width = x2 - x1
        
        if height < 20 or width < 10:
            return None, None
        
                                     
                                                              
                                                 
        crop_top = int(y1 + height * 0.15)
        crop_bottom = int(y1 + height * 0.50)
        
                                             
        margin_x = int(width * 0.15)
        crop_left = x1 + margin_x
        crop_right = x2 - margin_x
        
        if crop_right <= crop_left or crop_bottom <= crop_top:
                                               
            crop = frame[y1:y1 + height // 2, x1:x2]
        else:
            crop = frame[crop_top:crop_bottom, crop_left:crop_right]
        
        if crop.size == 0:
            return None, None
        
        return crop, bbox

    def _filter_jersey_pixels(self, hsv_img):
        """فلترة البيكسلات للتركيز على لون القميص"""
        h = hsv_img[..., 0]
        s = hsv_img[..., 1]
        v = hsv_img[..., 2]

                                                           
                                         
        good = (s >= 30) & (v >= 40)

                       
        grass = (h >= 35) & (h <= 90) & (s >= 40) & (v >= 40)
        good = good & (~grass)

        pixels = hsv_img[good]
        
        if pixels.shape[0] < 30:
                                           
            pixels = hsv_img.reshape(-1, 3)
        
        return pixels

                                                    
    
    def get_player_color(self, frame, bbox):
        """استخراج لون القميص مع confidence score"""
        crop, _ = self._get_smart_crop(frame, bbox)
        if crop is None:
            return None, 0.0

                   
        hsv = cv2.cvtColor(crop, cv2.COLOR_BGR2HSV)
        pixels = self._filter_jersey_pixels(hsv)

        if pixels.shape[0] < 30:
            return None, 0.0

                                        
        try:
            kmeans = KMeans(n_clusters=2, init="k-means++", n_init=5, random_state=42, max_iter=100)
            kmeans.fit(pixels.astype(np.float64))
        except:
            return None, 0.0

        centers = kmeans.cluster_centers_
        labels = kmeans.labels_

                                               
        sat_centers = centers[:, 1]
        jersey_cluster = int(np.argmax(sat_centers))
        
                                        
                                          
                                   
        cluster_ratio = np.sum(labels == jersey_cluster) / len(labels)
        sat_diff = abs(centers[0][1] - centers[1][1])
        
        confidence = min(1.0, cluster_ratio * 0.5 + (sat_diff / 100) * 0.5)
        
        jersey_color_hsv = centers[jersey_cluster]
        return jersey_color_hsv, confidence

    def assign_team_color(self, frame, player_detections):
        player_colors = []
        valid_ids = []

        for pid, det in player_detections.items():
            bbox = det["bbox"]
            color, confidence = self.get_player_color(frame, bbox)
            
            if color is None or confidence < 0.3:
                continue
            
                                              
            if self._is_referee_color(color):
                continue
                
            player_colors.append(color)
            valid_ids.append(pid)

        if len(player_colors) < 2:
            self.kmeans = None
            self.cluster_to_team = None
            return

        player_colors = np.array(player_colors, dtype=np.float64)

                            
        kmeans = KMeans(n_clusters=2, init="k-means++", n_init=20, random_state=42)
        kmeans.fit(player_colors)
        self.kmeans = kmeans

        centers = kmeans.cluster_centers_

                                                      
        target_blue_h = 120
        d0_blue = self._circular_hue_distance(centers[0][0], target_blue_h)
        d1_blue = self._circular_hue_distance(centers[1][0], target_blue_h)

        blue_cluster = 0 if d0_blue <= d1_blue else 1
        red_cluster = 1 - blue_cluster

        self.cluster_to_team = {
            blue_cluster: 1,
            red_cluster: 2
        }

        self.team_colors[1] = centers[blue_cluster]
        self.team_colors[2] = centers[red_cluster]

    def get_player_team(self, frame, player_bbox, player_id):

                                                  
        if player_id in self.player_team_dict:
            return self.player_team_dict[player_id]

        if self.kmeans is None or self.cluster_to_team is None:
            return 1           

                                     
        player_color, confidence = self.get_player_color(frame, player_bbox)
        
        if player_color is None:
            return self._get_current_vote(player_id) or 1

                                
        if confidence < self.confidence_threshold:
            previous = self._get_current_vote(player_id)
            if previous is not None:
                return previous
                                              
        
                                  
        if player_id in self.player_color_history:
            last_color = self.player_color_history[player_id]
            color_change = self._color_distance(player_color, last_color)
            
            if color_change > self.color_change_threshold:
                                                              
                                            
                return self._get_current_vote(player_id) or 1
        
                          
        self.player_color_history[player_id] = player_color

                             
        if self._is_referee_color(player_color):
                                          
            return self._get_current_vote(player_id) or 1

                                     
        player_color_64 = player_color.astype(np.float64)
        cluster_idx = int(self.kmeans.predict(player_color_64.reshape(1, -1))[0])
        team_id = self.cluster_to_team.get(cluster_idx, 1)

                                        
        self.player_team_votes[player_id].append(team_id)

                                             
        votes = self.player_team_votes[player_id]
        if len(votes) >= self.confirm_frames:
                           
            team_counts = {}
            for t in votes:
                team_counts[t] = team_counts.get(t, 0) + 1
            
            final_team = max(team_counts, key=team_counts.get)
            
                                         
            self.player_team_dict[player_id] = final_team
            return final_team

                                            
        return self._get_current_vote(player_id) or team_id

    def _get_current_vote(self, player_id):
        if player_id not in self.player_team_votes:
            return None
        
        votes = self.player_team_votes[player_id]
        if not votes:
            return None
        
        team_counts = {}
        for t in votes:
            team_counts[t] = team_counts.get(t, 0) + 1
        
        return max(team_counts, key=team_counts.get)

    def is_referee(self, frame, bbox):
 
        color, confidence = self.get_player_color(frame, bbox)
        if color is None or confidence < 0.4:
            return False
        
        is_ref_color = self._is_referee_color(color)
        
                                             
        if is_ref_color and self.team_colors:
                                             
            min_dist = float('inf')
            for team_id, team_color in self.team_colors.items():
                dist = self._color_distance(color, team_color)
                min_dist = min(min_dist, dist)
            
                                                 
            if min_dist < 30:
                return False
        
        return is_ref_color
