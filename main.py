from utils import read_video, save_video
from trackers import Tracker
import cv2
import numpy as np
from pathlib import Path
from team_assigner import TeamAssigner
from player_ball_assigner import PlayerBallAssigner
from camera_movement_estimator import CameraMovementEstimator
from view_transformer import ViewTransformer
from speed_and_distance_estimator import SpeedAndDistance_Estimator
from model_homography.bird_eye_view import BirdEyeView
from identity_mapper import IdentityMapper
from tracking_data import TrackingDataBuilder
from tqdm import tqdm                
import config
def get_team_names():
    """
    Get team names from user input.
    Team 1 = Blue jerseys, Team 2 = Red jerseys
    """
    if not config.ASK_FOR_TEAM_NAMES:
        return config.TEAM_1_NAME, config.TEAM_2_NAME
    
    print("\n" + "="*60)
    print(" TEAM IDENTIFICATION")
    print("="*60)
    print("\nNote: Team colors are automatically detected based on jersey colors.")
    print("- Team 1 = BLUE jerseys")
    print("- Team 2 = RED jerseys")
    print()
    
    try:
        team_1_name = input("Enter name for Team 1 (Blue jerseys) [default: Team 1]: ").strip()
        if not team_1_name:
            team_1_name = "Team 1"
        
        team_2_name = input("Enter name for Team 2 (Red jerseys) [default: Team 2]: ").strip()
        if not team_2_name:
            team_2_name = "Team 2"
        
        print(f"\n Teams configured:")
        print(f"    Team 1 (Blue): {team_1_name}")
        print(f"    Team 2 (Red): {team_2_name}")
        print("="*60 + "\n")
        
                       
        config.TEAM_1_NAME = team_1_name
        config.TEAM_2_NAME = team_2_name
        
        return team_1_name, team_2_name
    except (KeyboardInterrupt, EOFError):
        print("\n Using default team names...")
        return "Team 1", "Team 2"


def apply_manual_object_types_to_tracks(tracks):
    """
    Respect semantic object labels coming from manual annotations.

    - player: stays in tracks['players'] and participates in analytics
    - referee: moved to tracks['referees'] and excluded from player analytics
    - ignore: removed from tracks['players']
    """
    moved_to_referees = 0
    ignored_tracks = 0

    if 'referees' not in tracks:
        tracks['referees'] = [{} for _ in range(len(tracks.get('players', [])))]

    for frame_num, player_tracks in enumerate(tracks.get('players', [])):
        while len(tracks['referees']) <= frame_num:
            tracks['referees'].append({})
        referee_tracks = tracks['referees'][frame_num]

        to_referees = []
        to_ignore = []
        for track_id, track_info in list(player_tracks.items()):
            object_type = str(track_info.get('object_type', 'player')).strip().lower()
            if object_type == 'referee':
                to_referees.append(track_id)
            elif object_type == 'ignore':
                to_ignore.append(track_id)

        for track_id in to_referees:
            referee_payload = dict(player_tracks[track_id])
            referee_payload['object_type'] = 'referee'
            referee_payload['include_in_player_analytics'] = False
            referee_tracks[track_id] = referee_payload
            del player_tracks[track_id]
            moved_to_referees += 1

        for track_id in to_ignore:
            del player_tracks[track_id]
            ignored_tracks += 1

    return moved_to_referees, ignored_tracks


def main():
                              
    team_1_name, team_2_name = get_team_names()
    
                
    print(f" Reading video: {config.VIDEO_PATH}")
    video_frames = read_video(config.VIDEO_PATH)
    
                        
    print(" Initializing Tracker...")
    tracker = Tracker(
        config.TRACKER_MODEL_PATH
    )
    
                       
    print(" Tracking objects...")
    tracks = tracker.get_object_tracks(
        video_frames,
        read_from_stub=config.USE_STUBS,
        stub_path=config.TRACK_STUB_PATH
    )
    
                                                            
    print("\n" + "="*60)
    print(" BALL DETECTION DIAGNOSTIC (First 100 frames)")
    print("="*60)
    empty_frames = 0
    detected_frames = 0
    max_check = min(100, len(tracks["ball"]))
    for f in range(max_check):
        if len(tracks["ball"][f]) == 0:
            empty_frames += 1
        else:
            detected_frames += 1
    print(f" Frames with ball detected: {detected_frames}/{max_check}")
    print(f" Frames with NO ball detected: {empty_frames}/{max_check}")
    print(f"Detection rate: {(detected_frames/max_check)*100:.1f}%")
    if empty_frames > max_check * 0.3:
        print("  WARNING: High detection failure rate (>30%)")
        print("   -> Try lowering confidence threshold or check YOLO model")
    print("="*60 + "\n")
    
                             
    tracker.add_position_to_tracks(tracks)
    
                                                         
    print("\n" + "="*60)
    print(" BALL BBOX/POSITION DIAGNOSTIC (First 100 frames)")
    print("="*60)
    none_bbox = 0
    none_position = 0
    valid_balls = 0
    max_check = min(100, len(tracks["ball"]))
    for f in range(max_check):
        ball_data = tracks["ball"][f].get(1, {})
        bbox = ball_data.get('bbox')
        position = ball_data.get('position')
        
        if bbox is None or (isinstance(bbox, list) and len(bbox) == 0):
            none_bbox += 1
        if position is None:
            none_position += 1
        if bbox is not None and position is not None:
            valid_balls += 1
    
    print(f" Valid ball data (bbox + position): {valid_balls}/{max_check}")
    print(f" None/empty bbox: {none_bbox}/{max_check}")
    print(f" None position: {none_position}/{max_check}")
    if none_bbox > max_check * 0.2:
        print("  WARNING: High None bbox rate (>20%)")
        print("   -> Detection issue or bbox extraction problem")
    print("="*60 + "\n")

                               
    camera_movement_estimator = CameraMovementEstimator(video_frames[0])
    camera_movement_per_frame = camera_movement_estimator.get_camera_movement(
        video_frames,
        read_from_stub=config.USE_STUBS,
        stub_path=config.CAMERA_MOVEMENT_STUB_PATH
    )
    camera_movement_estimator.add_adjust_positions_to_tracks(tracks, camera_movement_per_frame)

                                        
    view_transformer = ViewTransformer(
        pixel_vertices=config.PIXEL_VERTICES,
        pitch_length=config.PITCH_LENGTH,
        pitch_width=config.PITCH_WIDTH
    )
    view_transformer.add_transformed_position_to_tracks(tracks)
    
                                                     
    print("\n" + "="*60)
    print(" BALL TRANSFORMATION DIAGNOSTIC (First 100 frames)")
    print("="*60)
    none_transformed = 0
    valid_transformed = 0
                                                                    
    clamped_x = 0
    clamped_y = 0
    max_check = min(100, len(tracks["ball"]))
    for f in range(max_check):
        ball_data = tracks["ball"][f].get(1, {})
        pos_transformed = ball_data.get('position_transformed')
        
        if pos_transformed is None:
            none_transformed += 1
        else:
            valid_transformed += 1
            x, y = pos_transformed
                                                               
            if x <= config.PITCH_LENGTH * 0.01 or x >= config.PITCH_LENGTH * 0.99:
                clamped_x += 1
            if y <= config.PITCH_WIDTH * 0.01 or y >= config.PITCH_WIDTH * 0.99:
                clamped_y += 1
    
    print(f" Valid transformed positions: {valid_transformed}/{max_check}")
    print(f" None transformed positions: {none_transformed}/{max_check}")
    print(f"  Clamped to X boundaries: {clamped_x}/{valid_transformed if valid_transformed > 0 else 1} ({(clamped_x/(valid_transformed or 1))*100:.1f}%)")
    print(f"  Clamped to Y boundaries: {clamped_y}/{valid_transformed if valid_transformed > 0 else 1} ({(clamped_y/(valid_transformed or 1))*100:.1f}%)")
    total_clamped = max(clamped_x, clamped_y)
    if total_clamped > valid_transformed * 0.2:
        print("  WARNING: High clamping rate (>20%)")
        print("   -> Homography/ViewTransformer may be incorrect")
        print("   -> Check PIXEL_VERTICES in config.py")
    print("="*60 + "\n")

                                
    tracks["ball"] = tracker.interpolate_ball_positions(tracks["ball"])
    
                                                  
    print("\n" + "="*60)
    print(" BALL AFTER INTERPOLATION (First 100 frames)")
    print("="*60)
    none_bbox_after = 0
    valid_bbox_after = 0
    max_check = min(100, len(tracks["ball"]))
    for f in range(max_check):
        ball_data = tracks["ball"][f].get(1, {})
        bbox = ball_data.get('bbox')
        if bbox is None or (isinstance(bbox, list) and len(bbox) == 0):
            none_bbox_after += 1
        else:
            valid_bbox_after += 1
    
    print(f" Valid ball bbox after interpolation: {valid_bbox_after}/{max_check}")
    print(f" None/empty bbox after interpolation: {none_bbox_after}/{max_check}")
    if none_bbox_after > 0:
        print("  WARNING: Interpolation did not fill all gaps")
        print("   -> Check interpolate_ball_positions() function")
    print("="*60 + "\n")

    print(" Building canonical player identities...")
    identity_mapper = IdentityMapper(video_path=config.VIDEO_PATH)
    identity_mapper.set_team_labels({"1": team_1_name, "2": team_2_name})
    identity_mapper.attach_appearance_features(video_frames, tracks)
    identity_mapper.bootstrap_from_tracks(tracks)

    corrections_path = Path(config.IDENTITY_CORRECTIONS_PATH)
    loaded_corrections = identity_mapper.load_corrections(str(corrections_path))
    if loaded_corrections:
        semantic_counts = {"player": 0, "referee": 0, "ignore": 0}
        for assignment in identity_mapper.manual_assignments:
            object_type = str(assignment.get("object_type", "player")).strip().lower()
            semantic_counts[object_type] = semantic_counts.get(object_type, 0) + 1
        print(f" Loaded identity corrections: {corrections_path}")
        print(f"   Manual assignments: {len(identity_mapper.manual_assignments)}")
        print(
            "   Semantic labels: "
            f"players={semantic_counts.get('player', 0)}, "
            f"referees={semantic_counts.get('referee', 0)}, "
            f"ignored={semantic_counts.get('ignore', 0)}"
        )
    else:
        print(" No identity corrections found - default canonical mapping mirrors transient track groups")

    # Canonical identity is attached directly to each player track without changing
    # the existing tracks['players'][frame_num][track_id] structure.
    identity_mapper.apply_to_tracks(tracks)

    moved_refs, ignored = apply_manual_object_types_to_tracks(tracks)
    if moved_refs or ignored:
        print(
            " Applied semantic labels: "
            f"moved_to_referees={moved_refs}, ignored_tracks={ignored}"
        )

    print(" Assigning teams...")
    team_assigner = TeamAssigner()

    all_player_colors = {}
    sample_frames = min(10, len(video_frames))

    for frame_idx in range(sample_frames):
        frame = video_frames[frame_idx]
        player_track = tracks['players'][frame_idx]

        for player_id, track in player_track.items():
            bbox = track.get('bbox')
            if bbox is None:
                continue

            color = team_assigner.get_player_color(frame, bbox)
            if color is not None:
                identity_key = track.get('canonical_id', player_id)
                if identity_key not in all_player_colors:
                    all_player_colors[identity_key] = []
                all_player_colors[identity_key].append(color)

    avg_colors = {}
    for pid, colors in all_player_colors.items():
        avg_colors[pid] = np.mean(colors, axis=0)

    print(f" Collected colors from {len(avg_colors)} stable player identities across {sample_frames} frames")

    team_assigner.assign_team_color_from_colors(avg_colors)

    for frame_num, player_track in enumerate(tracks['players']):
        for player_id, track in player_track.items():
            locked_team = track.get('team') if track.get('identity_locked') else None
            if locked_team in (1, 2):
                team = locked_team
            else:
                team = team_assigner.get_player_team(
                    video_frames[frame_num],
                    track['bbox'],
                    player_id,
                    track_info=track
                )

            if team is None:
                team = track.get('team') or 1

            tracks['players'][frame_num][player_id]['team'] = team

            if team == 1:
                tracks['players'][frame_num][player_id]['team_color'] = (255, 0, 0)
            else:
                tracks['players'][frame_num][player_id]['team_color'] = (0, 0, 255)

    identity_mapper.sync_registry_from_tracks(tracks)
    reconciliation = identity_mapper.reconcile_fragments(tracks)
    print(
        " Identity reconciliation: "
        f"active_players={reconciliation.get('active_canonical_players', 0)}, "
        f"merged_fragments={reconciliation.get('merged_fragment_count', 0)}, "
        f"unresolved_fragments={reconciliation.get('unresolved_fragment_count', 0)}"
    )
    identity_mapper.apply_to_tracks(tracks)

    moved_refs, ignored = apply_manual_object_types_to_tracks(tracks)
    if moved_refs or ignored:
        print(
            " Re-applied semantic labels after team update: "
            f"moved_to_referees={moved_refs}, ignored_tracks={ignored}"
        )

    suspicious_events = identity_mapper.detect_suspicious_events(tracks)
    current_conflicts = identity_mapper.detect_conflicts(tracks)

    print(f" Identity review: {len(suspicious_events)} suspicious events, {len(current_conflicts)} unresolved conflicts")
    if current_conflicts:
        print("  WARNING: unresolved canonical identity conflicts detected before analytics replay")

    team_assigner.print_team_info()
    team_assigner.print_locking_stats()

    speed_and_distance_estimator = SpeedAndDistance_Estimator(
        frame_rate=config.FRAME_RATE,
        min_frames_for_player=config.MIN_FRAMES_FOR_PLAYER,
        max_players_for_report=config.MAX_PLAYERS_FOR_REPORT,
    )
    speed_and_distance_estimator.add_speed_and_distance_to_tracks(tracks)

    print(" Assigning ball possession...")
    player_assigner = PlayerBallAssigner()
    team_ball_control = []
    last_valid_ball_bbox = None

    for frame_num, player_track in enumerate(tracks['players']):
        ball_data = tracks['ball'][frame_num].get(1, {})
        ball_bbox = ball_data.get('bbox', None)

        if ball_bbox is not None and len(ball_bbox) == 4:
            if any(isinstance(v, float) and np.isnan(v) for v in ball_bbox):
                ball_bbox = last_valid_ball_bbox
            elif any(isinstance(v, (np.floating, np.integer)) and np.isnan(v) for v in ball_bbox):
                ball_bbox = last_valid_ball_bbox
            else:
                last_valid_ball_bbox = ball_bbox
        else:
            ball_bbox = last_valid_ball_bbox

        if ball_bbox is None:
            if len(team_ball_control) > 0:
                team_ball_control.append(team_ball_control[-1])
            else:
                team_ball_control.append(1)
            continue

        assigned_player = player_assigner.assign_ball_to_player(player_track, ball_bbox)

        if assigned_player != -1 and assigned_player is not None:
            assigned_player_info = tracks['players'][frame_num][assigned_player]
            assigned_canonical_id = assigned_player_info.get('canonical_id', assigned_player)
            assigned_player_info['has_ball'] = True
            assigned_player_info['ball_owner_canonical_id'] = assigned_canonical_id
            tracks['ball'][frame_num].setdefault(1, {})['ball_owner_canonical_id'] = assigned_canonical_id

            assigned_team = assigned_player_info.get('team')
            if assigned_team in (1, 2):
                team_ball_control.append(assigned_team)
            elif len(team_ball_control) > 0:
                team_ball_control.append(team_ball_control[-1])
            else:
                team_ball_control.append(1)
        else:
            if len(team_ball_control) > 0:
                team_ball_control.append(team_ball_control[-1])
            else:
                team_ball_control.append(1)

    team_ball_control = np.array(team_ball_control)

                                                          
    print(" Saving player insights with Line Height analysis...")
    speed_and_distance_estimator.save_player_insights(tracks, "output_videos/videos_insights.txt")

    identity_summary = identity_mapper.generate_summary(
        tracks,
        corrections_path=str(corrections_path)
    )
    identity_summary_path = identity_mapper.write_summary_report(
        config.IDENTITY_SUMMARY_REPORT_PATH,
        tracks,
        corrections_path=str(corrections_path)
    )
    print(f" Identity summary saved to {identity_summary_path}")

    suspicious_switch_count = identity_summary.get('suspicious_switch_count', 0)
    resolved_switch_count = identity_summary.get('resolved_switch_count', 0)
    unresolved_conflict_count = identity_summary.get('unresolved_conflict_count', 0)
    active_canonical_players = identity_summary.get('active_canonical_players', 0)
    raw_active_canonical_players = identity_summary.get('raw_active_canonical_players', active_canonical_players)
    merged_fragment_count = identity_summary.get('merged_fragment_count', 0)
    unresolved_fragment_count = identity_summary.get('unresolved_fragment_count', 0)
    print(
        " Identity summary: "
        f"suspected switches={suspicious_switch_count}, "
        f"resolved switches={resolved_switch_count}, "
        f"unresolved conflicts={unresolved_conflict_count}, "
        f"active players={active_canonical_players} (raw={raw_active_canonical_players}), "
        f"merged fragments={merged_fragment_count}, "
        f"unresolved fragments={unresolved_fragment_count}"
    )

    if unresolved_conflict_count > 0 and not config.IDENTITY_EXPORT_STRICT_CONFLICTS:
        print(
            " WARNING: unresolved identity conflicts remain; "
            "continuing export because IDENTITY_EXPORT_STRICT_CONFLICTS is disabled"
        )

    export_blocked = (
        config.IDENTITY_EXPORT_STRICT_CONFLICTS and
        unresolved_conflict_count > 0
    )

    if export_blocked:
        print(" WARNING: Blocking corrected tracking export because unresolved identity conflicts remain")
    else:
        tracking_builder = TrackingDataBuilder(
            fps=config.FRAME_RATE,
            pitch_length=config.PITCH_LENGTH,
            pitch_width=config.PITCH_WIDTH,
            identity_metadata=identity_summary,
        )
        tracking_session = tracking_builder.build_from_tracks(tracks)
        tracking_session.video_path = config.VIDEO_PATH
        tracking_session.home_team = config.TEAM_1_NAME
        tracking_session.away_team = config.TEAM_2_NAME
        tracking_session.corrections_file_path = str(corrections_path)
        tracking_session.suspicious_switch_count = suspicious_switch_count
        tracking_session.resolved_switch_count = resolved_switch_count
        tracking_session.unresolved_conflict_count = unresolved_conflict_count
        tracking_session.active_canonical_players = identity_summary.get('active_canonical_players', 0)
        tracking_session.merged_fragment_count = identity_summary.get('merged_fragment_count', 0)
        tracking_session.unresolved_fragment_count = identity_summary.get('unresolved_fragment_count', 0)
        tracking_session.to_json(config.CORRECTED_TRACKING_JSON_PATH)

                      
    print(" Drawing annotations...")
    output_video_frames = tracker.draw_annotations(video_frames, tracks, team_ball_control)

                             
    output_video_frames = speed_and_distance_estimator.draw_speed_and_distance(output_video_frames, tracks)

                                                   
    bird_eye_view = BirdEyeView(
        map_width=450,
        map_height=290,
        margin=15,
        show_player_ids=False,
        show_trails=True,
        trail_length=15,
        style="modern",
                         
        show_velocity_arrows=True,                                      
        show_team_shape=True,                                     
        show_defensive_line=True,                  
        show_midblock_line=True,                  
        show_zones=False                                        
    )
    
    print(" Drawing bird eye view...")
    for frame_idx, frame in enumerate(tqdm(output_video_frames, desc="Bird Eye View")):
        output_video_frames[frame_idx] = bird_eye_view.draw(frame, tracks, frame_idx)

                
    print(" Saving video...")
    save_video(output_video_frames, 'output_videos/output_video.avi')
    print(" Done! Video saved to output_videos/output_video.avi")


if __name__ == '__main__':
    main()
