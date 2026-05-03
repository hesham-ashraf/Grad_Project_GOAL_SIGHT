"""
Football-aware constraints and validation
معايير كرة القدم الواقعية للتحقق من صحة البيانات
"""
import numpy as np


class FootballConstraints:
    """
     قيود كرة القدم الواقعية
    """
    
                  
    MAX_SPRINT_SPEED_KMH = 37.0                             
    AVG_RUNNING_SPEED_KMH = 20.0                      
    WALKING_SPEED_KMH = 5.0                    
    STANDING_THRESHOLD_KMH = 2.0                            
    
                 
    MAX_ACCELERATION_MPS2 = 4.0                              
    MAX_DECELERATION_MPS2 = 5.0                             
    
            
    MAX_DISTANCE_PER_FRAME_M = 0.6                                     
    MAX_DISTANCE_90MIN_M = 12000                                      
    AVG_DISTANCE_90MIN_M = 10000                                            
    
           
    GOALKEEPER_ZONE_M = 25.0                            
    PITCH_LENGTH_M = 105.0
    PITCH_WIDTH_M = 68.0
    
    @staticmethod
    def is_realistic_speed(speed_kmh, is_goalkeeper=False):
        """
        التحقق من أن السرعة واقعية
        """
        if speed_kmh < 0:
            return False
        
                               
        max_speed = FootballConstraints.MAX_SPRINT_SPEED_KMH * 0.85 if is_goalkeeper else FootballConstraints.MAX_SPRINT_SPEED_KMH
        
        return speed_kmh <= max_speed
    
    @staticmethod
    def is_realistic_acceleration(speed1_kmh, speed2_kmh, time_delta_s):
        """
        التحقق من أن التسارع واقعي
        """
        if time_delta_s <= 0:
            return False
        
        speed1_mps = speed1_kmh / 3.6
        speed2_mps = speed2_kmh / 3.6
        
        acceleration = abs(speed2_mps - speed1_mps) / time_delta_s
        
                                  
        if speed2_mps > speed1_mps:
                   
            return acceleration <= FootballConstraints.MAX_ACCELERATION_MPS2
        else:
                   
            return acceleration <= FootballConstraints.MAX_DECELERATION_MPS2
    
    @staticmethod
    def clamp_speed(speed_kmh, is_goalkeeper=False):
        """
        تحديد السرعة ضمن الحدود الواقعية
        """
        max_speed = FootballConstraints.MAX_SPRINT_SPEED_KMH * 0.85 if is_goalkeeper else FootballConstraints.MAX_SPRINT_SPEED_KMH
        return max(0, min(speed_kmh, max_speed))
    
    @staticmethod
    def is_realistic_distance_per_frame(distance_m, fps=24):
        """
        التحقق من أن المسافة في فريم واحد واقعية
        """
        max_distance = FootballConstraints.MAX_DISTANCE_PER_FRAME_M * (24 / fps)
        return distance_m <= max_distance
    
    @staticmethod
    def is_realistic_total_distance(distance_m, duration_minutes):
        """
        التحقق من أن المسافة الإجمالية واقعية
        """
                                          
        expected_max = FootballConstraints.MAX_DISTANCE_90MIN_M * (duration_minutes / 90.0)
        return distance_m <= expected_max * 1.2              
    
    @staticmethod
    def get_speed_category(speed_kmh):
        """
        تصنيف السرعة
        """
        if speed_kmh < FootballConstraints.STANDING_THRESHOLD_KMH:
            return "standing"
        elif speed_kmh < FootballConstraints.WALKING_SPEED_KMH:
            return "walking"
        elif speed_kmh < FootballConstraints.AVG_RUNNING_SPEED_KMH:
            return "jogging"
        else:
            return "sprinting"
    
    @staticmethod
    def is_goalkeeper_position(x, y=None, pitch_length=105.0, pitch_width=68.0):
        """
        التحقق من أن الموقع في منطقة حارس المرمى
        """
        if isinstance(x, (list, tuple)) and len(x) >= 2:
            x, y = x[0], x[1]
        
        if y is None:
            return False
        
                                     
        return x < FootballConstraints.GOALKEEPER_ZONE_M or x > (pitch_length - FootballConstraints.GOALKEEPER_ZONE_M)
    
    @staticmethod
    def clamp_position(x, y, pitch_length=105.0, pitch_width=68.0, margin=5.0):
        """
        تحديد الموقع ضمن حدود الملعب
        """
        x = max(-margin, min(x, pitch_length + margin))
        y = max(-margin, min(y, pitch_width + margin))
        return (x, y)


class SpeedValidator:
    """
     محقق السرعة - للتأكد من أن السرعات واقعية
    """
    
    def __init__(self):
        self.constraints = FootballConstraints()
        self.warnings_count = 0
        self.total_checks = 0
    
    def validate_speed(self, speed_kmh, is_goalkeeper=False):
        """
        التحقق من صحة السرعة
        """
        self.total_checks += 1
        
        if not self.constraints.is_realistic_speed(speed_kmh, is_goalkeeper):
            self.warnings_count += 1
            return False, f"Unrealistic speed: {speed_kmh:.1f} km/h"
        
        return True, None
    
    def validate_speed_change(self, speed1_kmh, speed2_kmh, time_delta_s):
        """
        التحقق من صحة تغيير السرعة
        """
        self.total_checks += 1
        
        if not self.constraints.is_realistic_acceleration(speed1_kmh, speed2_kmh, time_delta_s):
            self.warnings_count += 1
            acceleration = abs(speed2_kmh - speed1_kmh) / 3.6 / time_delta_s
            return False, f"Unrealistic acceleration: {acceleration:.1f} m/s²"
        
        return True, None
    
    def get_statistics(self):
        """
        إحصائيات التحقق
        """
        if self.total_checks == 0:
            return "No validations performed"
        
        warning_rate = (self.warnings_count / self.total_checks) * 100
        return f"Validation: {self.warnings_count}/{self.total_checks} warnings ({warning_rate:.1f}%)"
