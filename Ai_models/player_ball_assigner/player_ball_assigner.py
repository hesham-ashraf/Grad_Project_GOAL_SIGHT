import sys 
import numpy as np
sys.path.append('../')
from utils import get_center_of_bbox, measure_distance

class PlayerBallAssigner():
    def __init__(self):
        self.max_player_ball_distance = 50                         
        self.ball_possession_history = []                   
        self.history_length = 5                                          
        self.last_assigned_player = -1                            
    
    def assign_ball_to_player(self, players, ball_bbox):

        if ball_bbox is None or len(ball_bbox) < 4:
            return self.last_assigned_player
        
        ball_position = get_center_of_bbox(ball_bbox)
        
        if ball_position is None:
            return self.last_assigned_player

        minimum_distance = float('inf')
        assigned_player = -1

        for player_id, player in players.items():
            player_bbox = player.get('bbox')
            if player_bbox is None or len(player_bbox) < 4:
                continue
            
                                                
            foot_left = (player_bbox[0], player_bbox[3])              
            foot_right = (player_bbox[2], player_bbox[3])             
            foot_center = ((player_bbox[0] + player_bbox[2]) / 2, player_bbox[3])
            
            distance_left = measure_distance(foot_left, ball_position)
            distance_right = measure_distance(foot_right, ball_position)
            distance_center = measure_distance(foot_center, ball_position)
            
            distance = min(distance_left, distance_right, distance_center)

            if distance < self.max_player_ball_distance:
                if distance < minimum_distance:
                    minimum_distance = distance
                    assigned_player = player_id

                                                               
        if assigned_player == -1 and self.last_assigned_player != -1:
                                                              
            if self.last_assigned_player in players:
                last_player_bbox = players[self.last_assigned_player].get('bbox')
                if last_player_bbox is not None:
                    foot_center = ((last_player_bbox[0] + last_player_bbox[2]) / 2, last_player_bbox[3])
                    dist_to_last = measure_distance(foot_center, ball_position)
                                                               
                    if dist_to_last < self.max_player_ball_distance * 1.5:
                        assigned_player = self.last_assigned_player
        
        if assigned_player != -1:
            self.last_assigned_player = assigned_player
        
        return assigned_player