import math
import numpy as np

def is_valid_bbox(bbox):
    """Check if bbox is valid (not None, has 4 values, no NaN/Inf)"""
    if bbox is None or len(bbox) != 4:
        return False
    
    x1, y1, x2, y2 = bbox
    vals = [x1, y1, x2, y2]
    
                    
    if any(v is None for v in vals):
        return False
    
                                        
    for v in vals:
        if isinstance(v, (float, np.floating)) and (math.isnan(v) or math.isinf(v)):
            return False
    
    return True

def get_center_of_bbox(bbox):
    if not is_valid_bbox(bbox):
        return None

    x1, y1, x2, y2 = bbox
    return int((x1 + x2) / 2), int((y1 + y2) / 2)

def get_bbox_width(bbox):
    if not is_valid_bbox(bbox):
        return 0
    return bbox[2] - bbox[0]

def measure_distance(p1,p2):
    return ((p1[0]-p2[0])**2 + (p1[1]-p2[1])**2)**0.5

def measure_xy_distance(p1,p2):
    return p1[0]-p2[0],p1[1]-p2[1]

def get_foot_position(bbox):
    if not is_valid_bbox(bbox):
        return None

    x1, y1, x2, y2 = bbox
    return int((x1 + x2) / 2), int(y2)