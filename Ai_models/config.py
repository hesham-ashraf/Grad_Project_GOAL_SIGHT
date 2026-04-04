"""
Configuration file for GOAL_SIGHT project.
Edit these values to configure the pipeline for different videos/cameras.

Team Color Detection:
- The system automatically detects jersey colors
- Team 1 = Players with BLUE jerseys
- Team 2 = Players with RED jerseys
- You can specify team names when running the program
"""

                                                          
VIDEO_PATH = '08fd33_4.mp4'
OUTPUT_PATH = 'output_videos/output_video.avi'

                                                       
TRACKER_MODEL_PATH = 'models/best.pt'
HOMOGRAPHY_MODEL_PATH = 'model_homography/best (4).pt'                                       

                                                         
USE_STUBS = True                                              
TRACK_STUB_PATH = 'stubs/track_stubs.pkl'
CAMERA_MOVEMENT_STUB_PATH = 'stubs/camera_movement_stub.pkl'

                                                              
                                                                                                
TRANSFORM_METHOD = 'view_transformer'                                                            

                                                                                   
                                                         
PIXEL_VERTICES = [
    [140, 985],                                
    [280, 265],                            
    [1640, 265],                            
    [1780, 985]                                 
]

                                                                             
HOMOGRAPHY_CONF = 0.25
HOMOGRAPHY_SMOOTH_ALPHA = 0.7
HOMOGRAPHY_REFRESH_EVERY = 10                              

                           
PITCH_LENGTH = 105.0
PITCH_WIDTH = 68.0

                                                                    
TEAM_ASSIGNER_CONFIDENCE_THRESHOLD = 0.6
TEAM_ASSIGNER_CONFIRM_FRAMES = 5
TEAM_ASSIGNER_COLOR_CHANGE_THRESHOLD = 40
TEAM_ASSIGNER_COLOR_CACHE_INTERVAL = 5                                
TEAM_ASSIGNER_CROP_MAX_SIZE = 50                                     

                                        
                                             
TEAM_1_NAME = "Team 1"                
TEAM_2_NAME = "Team 2"               
ASK_FOR_TEAM_NAMES = True                                   

                                                                   
FRAME_RATE = 24
MAX_SPEED_KMH = 20.0                                  
MAX_ACCELERATION = 5.0
MIN_FRAMES_FOR_PLAYER = 30                                                     

                                                                      
REFEREE_FRAMES_TO_ANALYZE = 30
REFEREE_MIN_APPEARANCE_RATIO = 0.3                                           

                                                                  
BIRD_EYE_MAP_WIDTH = 450
BIRD_EYE_MAP_HEIGHT = 290
BIRD_EYE_MARGIN = 15
BIRD_EYE_SHOW_IDS = False
BIRD_EYE_SHOW_TRAILS = True
BIRD_EYE_TRAIL_LENGTH = 15
BIRD_EYE_STYLE = "modern"                                       
