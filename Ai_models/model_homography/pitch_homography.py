import cv2
import numpy as np
from ultralytics import YOLO


class PitchHomography:


    def __init__(
        self,
        model_path: str,
        pitch_length: float = 105.0,          
        pitch_width: float = 68.0,            
        conf: float = 0.25,
        smooth_alpha: float = 0.7,                              
        refresh_every: int = 10,                                 
        ransac_thresh: float = 3.0,
        min_inliers: int = 4,
        manual_fallback_src=None,
        manual_fallback_dst=None
    ):
        self.model = YOLO(model_path)
        self.conf = conf

        self.L = float(pitch_length)
        self.W = float(pitch_width)

        self.refresh_every = int(refresh_every)
        self.ransac_thresh = float(ransac_thresh)
        self.min_inliers = int(min_inliers)

        self.smooth_alpha = float(smooth_alpha)
        self.H_last = None

                                                                             
                                                                 
                                                                            
                                              
         
                          
                                    
                                     
                                        
                                       
         
                                                   
                                        
        self.kpt_to_pitch = {
            0: (0.0, 0.0),
            1: (self.L, 0.0),
            2: (self.L, self.W),
            3: (0.0, self.W),
        }

                                  
        self.manual_fallback_src = None if manual_fallback_src is None else np.array(manual_fallback_src, np.float32)
        self.manual_fallback_dst = None if manual_fallback_dst is None else np.array(manual_fallback_dst, np.float32)

                                   
                          
                                   
    def _extract_pose_keypoints(self, frame):
        """
        Returns list of (x,y,conf) for one detected pitch instance if available.
        """
        res = self.model.predict(frame, conf=self.conf, verbose=False)
        if not res or len(res) == 0:
            return None

        r0 = res[0]

                                          
        if r0.keypoints is None:
            return None

                                                               
                                    
        kpts = r0.keypoints
        if hasattr(kpts, "data"):
            kpts = kpts.data                
        kpts = kpts.cpu().numpy()             

        if kpts.ndim != 3 or kpts.shape[0] < 1:
            return None

                               
        pts = kpts[0]         
        return pts

    def _build_correspondences(self, pose_pts):
        """
        pose_pts: (K,3) -> return src_pts, dst_pts arrays
        """
        src = []
        dst = []

        for kpt_idx, (X, Y) in self.kpt_to_pitch.items():
            if kpt_idx >= pose_pts.shape[0]:
                continue
            x, y, c = pose_pts[kpt_idx]
            if c <= 0.01:            
                continue
            src.append([x, y])
            dst.append([X, Y])

        if len(src) < 4:
            return None, None

        return np.array(src, np.float32), np.array(dst, np.float32)

                                   
                
                                   
    def compute_H(self, frame):
        pose_pts = self._extract_pose_keypoints(frame)
        if pose_pts is None:
            return self._fallback_H()

        src, dst = self._build_correspondences(pose_pts)
        if src is None:
            return self._fallback_H()

        H, mask = cv2.findHomography(
            src, dst,
            method=cv2.RANSAC,
            ransacReprojThreshold=self.ransac_thresh,
            maxIters=3000,
            confidence=0.999
        )

        if H is None or mask is None:
            return self._fallback_H()

        inliers = int(mask.sum())
        if inliers < self.min_inliers:
            return self._fallback_H()

                   
        if self.H_last is not None:
            H = self._smooth_H(self.H_last, H, self.smooth_alpha)

        self.H_last = H
        return H

    def _smooth_H(self, H_prev, H_new, alpha):
                                                
        H = alpha * H_prev + (1 - alpha) * H_new
        if abs(H[2, 2]) > 1e-9:
            H = H / H[2, 2]
        return H

    def _fallback_H(self):
                        
        if self.H_last is not None:
            return self.H_last

                                          
        if self.manual_fallback_src is not None and self.manual_fallback_dst is not None:
            H = cv2.getPerspectiveTransform(self.manual_fallback_src, self.manual_fallback_dst)
            self.H_last = H
            return H

        return None

                                   
                     
                                   
    def apply_to_tracks(self, tracks, frames):

        H = None

        for f_idx, frame in enumerate(frames):
            if f_idx == 0 or (f_idx % self.refresh_every == 0):
                H = self.compute_H(frame)

            if H is None:
                continue

            for obj_name, obj_tracks in tracks.items():
                if not isinstance(obj_tracks, list) or f_idx >= len(obj_tracks):
                    continue

                for tid, info in obj_tracks[f_idx].items():
                                                                            
                    pos = info.get("position_adjusted", None)
                    if pos is None:
                        pos = info.get("position", None)

                    if pos is None:
                        continue

                    pt = np.array([[pos]], dtype=np.float32)                 
                    out = cv2.perspectiveTransform(pt, H)
                    info["position_transformed"] = out[0, 0].tolist()

                                   
                  
                                   
    def debug_draw_keypoints(self, frame):
        """
        returns a copy with kpt indices drawn (to verify mapping)
        """
        out = frame.copy()
        pose_pts = self._extract_pose_keypoints(frame)
        if pose_pts is None:
            cv2.putText(out, "NO POSE KEYPOINTS", (30, 40), cv2.FONT_HERSHEY_SIMPLEX, 1, (0,0,255), 2)
            return out

        for i in range(pose_pts.shape[0]):
            x, y, c = pose_pts[i]
            if c <= 0.01:
                continue
            cv2.circle(out, (int(x), int(y)), 4, (0, 255, 255), -1)
            cv2.putText(out, str(i), (int(x)+6, int(y)-6), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0,255,255), 2)

        return out
