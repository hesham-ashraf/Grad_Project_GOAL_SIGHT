import numpy as np
import cv2
from sklearn.cluster import KMeans

class TeamAssigner:

    def __init__(self):
        self.team_colors = {}                                 
        self.player_team_dict = {}                                             
        self.player_color_history = {}                                        
        self.kmeans = None
        self.cluster_to_team = None                              
        self.assigned_initialized = False                      

                                 
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

    def _is_grass_like(self, hsv_pixel):
                                                                      
        h, s, v = hsv_pixel
        return (35 <= h <= 90) and (s >= 40) and (v >= 40)
    
    def print_team_info(self):
        """Print detected team colors for debugging"""
        if not self.team_colors:
            print("  No team colors detected yet")
            return
        
        print("\n Team Colors Detected:")
        for team_id, hsv_color in self.team_colors.items():
            h, s, v = hsv_color
            is_white = (s < 35) and (v > 140)
            
                                       
            if is_white:
                color_name = "WHITE/LIGHT"
            elif h < 15 or h > 165:
                color_name = "RED"
            elif 15 <= h < 35:
                color_name = "ORANGE/YELLOW"
            elif 35 <= h < 85:
                color_name = "GREEN"
            elif 85 <= h < 130:
                color_name = "BLUE/CYAN"
            else:
                color_name = "PURPLE/PINK"
            
            print(f"  Team {team_id}: {color_name} (H:{h:.0f}, S:{s:.0f}, V:{v:.0f})")
        
        print(f"  Cluster to Team mapping: {self.cluster_to_team}")
        print()

    def _filter_pixels_for_jersey(self, hsv_img):
        """
        Remove likely grass pixels but KEEP white jerseys AND fluorescent green jerseys.
        Returns pixels Nx3
        """
        h = hsv_img[..., 0]
        s = hsv_img[..., 1]
        v = hsv_img[..., 2]

                                                                 
                                                                                  
        good = ((s >= 35) & (v >= 35)) | ((s < 35) & (v > 160))

                                                                 
                                                                            
                                                                                   
        
                                                                        
        grass = (h >= 35) & (h <= 90) & (s >= 40) & (s < 150) & (v >= 40) & (v < 200)
        
                                                                
        fluorescent_green = (h >= 35) & (h <= 90) & ((s >= 150) | (v >= 200))
        
                                                                  
        good = (good & (~grass)) | fluorescent_green

        pixels = hsv_img[good]
        if pixels.shape[0] < 50:
                                                                  
            pixels = hsv_img.reshape(-1, 3)
        return pixels

                                
    def get_player_color(self, frame, bbox):
        H, W = frame.shape[:2]
        bbox = self._clamp_bbox(bbox, W, H)
        if bbox is None:
            return None

        x1, y1, x2, y2 = bbox
        crop = frame[y1:y2, x1:x2]
        if crop.size == 0:
            return None

                                    
        top = crop[: max(1, crop.shape[0] // 2), :]

                    
        hsv = cv2.cvtColor(top, cv2.COLOR_BGR2HSV)

                                                
        pixels = self._filter_pixels_for_jersey(hsv)

                                                                
                                      
        kmeans = KMeans(n_clusters=2, init="k-means++", n_init=10, random_state=42)
        kmeans.fit(pixels)

        centers = kmeans.cluster_centers_               
        labels = kmeans.labels_

                                                                      
                                                                        
        counts = np.bincount(labels)
        jersey_cluster = int(np.argmax(counts))

        jersey_color_hsv = centers[jersey_cluster]
        return jersey_color_hsv

    def assign_team_color_from_colors(self, player_colors_dict):
        """
        Determine 2 team clusters from pre-computed player colors.
        
        Args:
            player_colors_dict: {player_id: avg_hsv_color}
        """
        if len(player_colors_dict) < 2:
            print("  Not enough players to cluster teams!")
            self.kmeans = None
            self.cluster_to_team = None
            return
        
        player_colors = list(player_colors_dict.values())
        player_colors = np.array(player_colors, dtype=np.float64)
        
        print(f"\n Team Assignment Debug:")
        print(f"   Players detected: {len(player_colors)}")
        print(f"   Sample colors (HSV): {player_colors[:5]}")

                                      
        kmeans = KMeans(n_clusters=2, init="k-means++", n_init=20, random_state=42)
        kmeans.fit(player_colors)
        self.kmeans = kmeans

        centers = kmeans.cluster_centers_                                 
        
        print(f"   Cluster 0 center (HSV): H={centers[0][0]:.1f}, S={centers[0][1]:.1f}, V={centers[0][2]:.1f}")
        print(f"   Cluster 1 center (HSV): H={centers[1][0]:.1f}, S={centers[1][1]:.1f}, V={centers[1][2]:.1f}")

                                                         
        def is_white_like(c):
            h, s, v = c
            return (s < 50) and (v > 120)
        
        c0, c1 = centers[0], centers[1]
        
        print(f"   Cluster 0 is white-like: {is_white_like(c0)}")
        print(f"   Cluster 1 is white-like: {is_white_like(c1)}")
        
        if is_white_like(c0):
            white_cluster = 0
            colored_cluster = 1
        elif is_white_like(c1):
            white_cluster = 1
            colored_cluster = 0
        else:
                                                                
            colored_cluster = 0 if c0[1] >= c1[1] else 1
            white_cluster = 1 - colored_cluster
            print(f"    Neither cluster is white - using saturation")
        
        self.cluster_to_team = {
            white_cluster: 1,                            
            colored_cluster: 2                            
        }
        
        print(f"   Final mapping: Cluster {white_cluster} → Team 1 (Blue), Cluster {colored_cluster} → Team 2 (Red)")

                                
        self.team_colors[1] = centers[white_cluster]
        self.team_colors[2] = centers[colored_cluster]

    def assign_team_color(self, frame, player_detections):
        """
        Determine 2 team clusters from multiple players,
        then map cluster -> (BLUE team_id=1) and (RED team_id=2).
        """
        player_colors = []
        valid_ids = []

        for pid, det in player_detections.items():
            bbox = det["bbox"]
            c = self.get_player_color(frame, bbox)
            if c is None:
                continue
            player_colors.append(c)
            valid_ids.append(pid)

        if len(player_colors) < 2:
                                        
            self.kmeans = None
            self.cluster_to_team = None
            print("  Not enough players to cluster teams!")
            return

                                                        
        player_colors = np.array(player_colors, dtype=np.float64)
        
        print(f"\n Team Assignment Debug:")
        print(f"   Players detected: {len(player_colors)}")
        print(f"   Sample colors (HSV): {player_colors[:5]}")

                                      
        kmeans = KMeans(n_clusters=2, init="k-means++", n_init=20, random_state=42)
        kmeans.fit(player_colors)
        self.kmeans = kmeans

        centers = kmeans.cluster_centers_                                 
        
        print(f"   Cluster 0 center (HSV): H={centers[0][0]:.1f}, S={centers[0][1]:.1f}, V={centers[0][2]:.1f}")
        print(f"   Cluster 1 center (HSV): H={centers[1][0]:.1f}, S={centers[1][1]:.1f}, V={centers[1][2]:.1f}")

                                                         
                                                                         
        def is_white_like(c):
            h, s, v = c
            return (s < 50) and (v > 120)                          
        
        c0, c1 = centers[0], centers[1]
        
        print(f"   Cluster 0 is white-like: {is_white_like(c0)}")
        print(f"   Cluster 1 is white-like: {is_white_like(c1)}")
        
        if is_white_like(c0):
            white_cluster = 0
            colored_cluster = 1
        elif is_white_like(c1):
            white_cluster = 1
            colored_cluster = 0
        else:
                                                                
                                                   
            colored_cluster = 0 if c0[1] >= c1[1] else 1
            white_cluster = 1 - colored_cluster
            print(f"    Neither cluster is white - using saturation")
        
        self.cluster_to_team = {
            white_cluster: 1,                            
            colored_cluster: 2                            
        }
        
        print(f"   Final mapping: Cluster {white_cluster} → Team 1 (Blue), Cluster {colored_cluster} → Team 2 (Red)")

                                
        self.team_colors[1] = centers[white_cluster]
        self.team_colors[2] = centers[colored_cluster]

    def get_player_team(self, frame, player_bbox, player_id, confirm_threshold=8):
        """
        تحديد فريق اللاعب مع نظام LOCKING محسن لضمان الثبات
        
        المبدأ: بمجرد تأكيد الفريق، لا يتغير أبداً!
        
        confirm_threshold: عدد الفريمات المطلوبة لتأكيد الفريق (خفضناه لتأكيد أسرع)
        """
                                                               
        if player_id in self.player_team_dict:
            return self.player_team_dict[player_id]

        if self.kmeans is None or self.cluster_to_team is None:
            return None

        player_color = self.get_player_color(frame, player_bbox)
        if player_color is None:
                                                     
            if player_id in self.player_color_history and self.player_color_history[player_id]:
                return self.player_color_history[player_id][-1]
            return None

                                             
        player_color = player_color.astype(np.float64)
        cluster_idx = int(self.kmeans.predict(player_color.reshape(1, -1))[0])
        team_id = self.cluster_to_team.get(cluster_idx, None)
        
        if team_id is None:
            return None

                                                             
        if player_id not in self.player_color_history:
            self.player_color_history[player_id] = []
        
        self.player_color_history[player_id].append(team_id)
        
                                                   
        if len(self.player_color_history[player_id]) > 30:
            self.player_color_history[player_id] = self.player_color_history[player_id][-30:]
        
                                                            
        if len(self.player_color_history[player_id]) >= confirm_threshold:
            team_counts = {1: 0, 2: 0}
            for t in self.player_color_history[player_id]:
                if t in team_counts:
                    team_counts[t] += 1
            
                                        
            final_team = 1 if team_counts[1] >= team_counts[2] else 2
            total = team_counts[1] + team_counts[2]
            confidence = team_counts[final_team] / max(1, total)
            
                                                      
            if confidence >= 0.55:
                self.player_team_dict[player_id] = final_team                    
                return final_team
        
                                                         
        if self.player_color_history[player_id]:
            team_counts = {1: 0, 2: 0}
            for t in self.player_color_history[player_id]:
                if t in team_counts:
                    team_counts[t] += 1
            return 1 if team_counts[1] >= team_counts[2] else 2
        
        return team_id
    
    def print_locking_stats(self):
        """طباعة إحصائيات تثبيت الفرق"""
        if not self.player_team_dict:
            print(" No players locked yet")
            return
        
        team1_count = sum(1 for t in self.player_team_dict.values() if t == 1)
        team2_count = sum(1 for t in self.player_team_dict.values() if t == 2)
        total_locked = len(self.player_team_dict)
        
        print(f"\n Team Locking Statistics:")
        print(f"   Total Players Locked: {total_locked}")
        print(f"   Team 1 (Blue): {team1_count} players")
        print(f"   Team 2 (Red): {team2_count} players")
        print(f"   Locked IDs: {list(self.player_team_dict.keys())[:10]}..." if total_locked > 10 else f"   Locked IDs: {list(self.player_team_dict.keys())}")
