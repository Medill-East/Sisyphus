class_name Tuning
extends Resource

@export var front_base_z: float = 10.0
@export var ridge_z: float = -24.0
@export var back_base_z: float = -54.0
@export var path_width: float = 7.5
@export var ridge_height: float = 8.6
@export var pacing_profile_name: String = "smoke"

@export var stone_radius: float = 1.05
@export var stone_mass: float = 36.0
@export var stone_gravity_scale: float = 1.38
@export var stone_friction: float = 0.58
@export var stone_linear_damp: float = 0.52
@export var stone_angular_damp: float = 0.18
@export var push_force: float = 158.0
@export var max_push_force_per_frame: float = 190.0
@export var push_contact_spring: float = 176.0
@export var push_contact_damping: float = 24.0
@export var push_force_ramp_seconds: float = 0.35
@export var max_contact_push_force: float = 190.0
@export var push_quality_dead_zone: float = 0.34
@export var push_quality_curve: float = 1.25
@export var brace_quality_min: float = 0.48
@export var brace_quality_full: float = 0.78
@export var brace_aim_speed_soft: float = 0.35
@export var brace_aim_speed_hard: float = 1.35
@export var brace_build_speed: float = 1.55
@export var brace_decay_speed: float = 5.0
@export var brace_release_speed: float = 12.0
@export var brace_force_floor: float = 0.42
@export var brace_force_curve: float = 1.35
@export var push_effective_lever_arm: float = 0.28
@export var spin_damping_strength: float = 0.16
@export var burden_target_uphill_speed: float = 0.58
@export var burden_speed_governor_strength: float = 96.0
@export var burden_stride_force_depth: float = 0.56
@export var burden_minimum_force_scale: float = 0.16
@export var burden_min_sample_seconds: float = 1.0
@export var burden_min_uphill_distance: float = 0.15
@export var burden_slow_speed_threshold: float = 0.65
@export var burden_min_slow_ratio: float = 0.08
@export var burden_fast_average_speed: float = 1.15
@export var release_rolling_resistance: float = 44.0
@export var downhill_release_resistance_scale: float = 0.02
@export var contact_distance: float = 2.65
@export var push_disengage_distance: float = 3.35
@export var push_reacquire_distance: float = 5.2
@export var push_reacquire_aim_dot_min: float = 0.68
@export var rear_contact_dot_min: float = 0.25
@export var hand_follow_strength: float = 7.5
@export var approach_hand_start_margin: float = 0.92
@export var approach_hand_full_margin: float = 0.42
@export var approach_hand_follow_speed: float = 4.4

@export var walk_speed: float = 4.2
@export var push_walk_speed: float = 1.05
@export var gravity: float = 18.0
@export var player_body_radius: float = 0.24
@export var player_stone_clearance: float = 0.12

@export var shoulder_distance: float = 3.0
@export var shoulder_height: float = 1.55
@export var shoulder_side_offset: float = 0.82
@export var push_camera_distance: float = -0.10
@export var push_camera_bias_back_distance: float = -0.34
@export var push_camera_height: float = 1.55
@export var push_camera_side_offset: float = 0.0
@export var push_camera_contact_distance: float = 1.48
@export var push_camera_contact_origin_strength: float = 1.0
@export var first_person_hands_takeover_max_contact_distance: float = 2.05
@export var push_look_limit: float = 1.55
@export var push_look_down_limit: float = 1.70
@export var push_look_up_limit: float = 0.82
@export var normal_camera_fov: float = 74.0
@export var push_camera_fov: float = 108.0
@export var camera_blend_speed: float = 0.82
@export var push_camera_entry_min_contact_seconds: float = 0.75
@export var mouse_sensitivity: float = 0.0026
@export var keyboard_turn_speed: float = 1.6
@export var keyboard_pitch_speed: float = 1.35
@export var aim_contact_strength: float = 0.95
@export var aim_force_strength: float = 0.58
@export var push_hand_cycle_hz: float = 1.6
@export var push_central_force: float = 122.0
@export var push_roll_torque: float = 24.0
@export var aim_roll_strength: float = 0.40
@export var arm_upper_length: float = 0.34
@export var arm_forearm_length: float = 0.36
@export var first_person_hand_surface_offset: float = 0.22
@export var first_person_forearm_max_length: float = 1.02
@export var first_person_hands_visible_blend: float = 0.95
@export var first_person_hands_min_contact_seconds: float = 1.65
@export var first_person_hands_min_contact_quality: float = 0.36
@export var third_person_arms_hidden_blend: float = 0.95
@export var third_person_push_transition_arm_hide_blend: float = 0.95
@export var player_ground_snap_strength: float = 1.0

@export var obstacle_density: int = 18
@export var obstacle_max_radius: float = 0.95
@export var clear_path_width: float = 3.0
@export var route_camber_strength: float = 0.26
@export var route_camber_band_length: float = 8.5

@export var representative_slice_min_seconds: float = 300.0
@export var representative_slice_max_seconds: float = 600.0


func apply_vertical_slice_pacing_profile(profile_name: String) -> void:
	match profile_name:
		"representative":
			pacing_profile_name = "representative"
			front_base_z = 54.0
			ridge_z = -190.0
			back_base_z = -780.0
			path_width = 8.4
			obstacle_density = 96
			clear_path_width = 3.35
			route_camber_strength = 0.34
			route_camber_band_length = 12.0
			stone_mass = 48.0
			stone_gravity_scale = 1.42
			stone_friction = 0.58
			stone_linear_damp = 0.58
			stone_angular_damp = 0.22
			push_force = 138.0
			max_push_force_per_frame = 158.0
			push_contact_spring = 150.0
			push_contact_damping = 22.0
			max_contact_push_force = 158.0
			push_quality_dead_zone = 0.38
			push_quality_curve = 1.55
			burden_target_uphill_speed = 0.50
			burden_speed_governor_strength = 112.0
			burden_stride_force_depth = 0.62
			burden_minimum_force_scale = 0.12
			burden_slow_speed_threshold = 0.86
			burden_min_slow_ratio = 0.18
			burden_fast_average_speed = 0.96
			push_walk_speed = 0.86
			aim_force_strength = 0.44
			push_camera_contact_distance = 1.48
			push_camera_contact_origin_strength = 1.0
			push_camera_distance = -0.10
			push_camera_bias_back_distance = -0.34
			push_camera_fov = 108.0
			release_rolling_resistance = 48.0
			downhill_release_resistance_scale = 0.02
			camera_blend_speed = 0.82
			push_camera_entry_min_contact_seconds = 0.75
			first_person_hands_visible_blend = 0.95
			first_person_hands_min_contact_seconds = 1.65
			first_person_hands_min_contact_quality = 0.40
			third_person_arms_hidden_blend = 0.95
			third_person_push_transition_arm_hide_blend = 0.95
		_:
			pacing_profile_name = "smoke"
			front_base_z = 10.0
			ridge_z = -24.0
			back_base_z = -54.0
			path_width = 7.5
			obstacle_density = 18
			clear_path_width = 3.0
			route_camber_strength = 0.26
			route_camber_band_length = 8.5
			stone_mass = 36.0
			stone_gravity_scale = 1.38
			stone_friction = 0.58
			stone_linear_damp = 0.52
			stone_angular_damp = 0.18
			push_force = 158.0
			max_push_force_per_frame = 190.0
			push_contact_spring = 176.0
			push_contact_damping = 20.0
			max_contact_push_force = 190.0
			push_quality_dead_zone = 0.34
			push_quality_curve = 1.25
			burden_target_uphill_speed = 0.58
			burden_speed_governor_strength = 96.0
			burden_stride_force_depth = 0.56
			burden_minimum_force_scale = 0.16
			burden_slow_speed_threshold = 0.65
			burden_min_slow_ratio = 0.08
			burden_fast_average_speed = 1.15
			push_walk_speed = 1.05
			aim_force_strength = 0.58
			push_camera_contact_distance = 1.48
			push_camera_contact_origin_strength = 1.0
			push_camera_distance = -0.10
			push_camera_bias_back_distance = -0.34
			push_camera_fov = 108.0
			release_rolling_resistance = 44.0
			downhill_release_resistance_scale = 0.02
			camera_blend_speed = 0.82
			push_camera_entry_min_contact_seconds = 0.75
			first_person_hands_visible_blend = 0.95
			first_person_hands_min_contact_seconds = 1.65
			first_person_hands_min_contact_quality = 0.36
			third_person_arms_hidden_blend = 0.95
			third_person_push_transition_arm_hide_blend = 0.95


func estimated_loop_seconds_for_current_pacing() -> float:
	var ascent_distance: float = maxf(0.0, front_base_z - ridge_z)
	var descent_distance: float = maxf(0.0, ridge_z - back_base_z)
	var ascent_seconds: float = ascent_distance / maxf(0.05, burden_target_uphill_speed)
	var descent_seconds: float = descent_distance / maxf(0.05, walk_speed)
	return ascent_seconds + descent_seconds + 45.0


static func push_lab_preset_names() -> Array[String]:
	return ["heavy", "standard", "light"]


static func push_lab_preset_label(preset_name: String) -> String:
	match preset_name:
		"heavy":
			return "沉重"
		"light":
			return "轻量"
		_:
			return "标准"


func apply_push_lab_preset(preset_name: String) -> void:
	match preset_name:
		"heavy":
			stone_mass = 44.0
			stone_gravity_scale = 1.42
			stone_friction = 0.66
			stone_linear_damp = 0.62
			stone_angular_damp = 0.24
			push_force = 224.0
			max_push_force_per_frame = 260.0
			push_contact_spring = 246.0
			push_contact_damping = 23.0
			max_contact_push_force = 260.0
			push_quality_dead_zone = 0.34
			push_quality_curve = 1.28
			spin_damping_strength = 0.20
			burden_target_uphill_speed = 0.52
			burden_speed_governor_strength = 104.0
			burden_stride_force_depth = 0.60
			burden_minimum_force_scale = 0.14
			release_rolling_resistance = 50.0
			downhill_release_resistance_scale = 0.02
			push_walk_speed = 0.78
			aim_force_strength = 0.54
			obstacle_density = 20
			obstacle_max_radius = 1.05
			clear_path_width = 3.25
			route_camber_strength = 0.34
			route_camber_band_length = 8.5
		"light":
			stone_mass = 28.0
			stone_gravity_scale = 1.20
			stone_friction = 0.50
			stone_linear_damp = 0.52
			stone_angular_damp = 0.18
			push_force = 124.0
			max_push_force_per_frame = 150.0
			push_contact_spring = 138.0
			push_contact_damping = 14.0
			max_contact_push_force = 150.0
			push_quality_dead_zone = 0.24
			push_quality_curve = 0.95
			spin_damping_strength = 0.12
			burden_target_uphill_speed = 0.86
			burden_speed_governor_strength = 30.0
			burden_stride_force_depth = 0.22
			burden_minimum_force_scale = 0.42
			release_rolling_resistance = 34.0
			downhill_release_resistance_scale = 0.06
			push_walk_speed = 1.72
			aim_force_strength = 0.56
			obstacle_density = 14
			obstacle_max_radius = 0.74
			clear_path_width = 2.75
			route_camber_strength = 0.18
			route_camber_band_length = 8.5
		_:
			stone_mass = 36.0
			stone_gravity_scale = 1.34
			stone_friction = 0.58
			stone_linear_damp = 0.56
			stone_angular_damp = 0.18
			push_force = 208.0
			max_push_force_per_frame = 240.0
			push_contact_spring = 240.0
			push_contact_damping = 20.0
			max_contact_push_force = 240.0
			push_quality_dead_zone = 0.30
			push_quality_curve = 1.05
			spin_damping_strength = 0.16
			burden_target_uphill_speed = 0.64
			burden_speed_governor_strength = 82.0
			burden_stride_force_depth = 0.50
			burden_minimum_force_scale = 0.18
			release_rolling_resistance = 44.0
			downhill_release_resistance_scale = 0.02
			push_walk_speed = 1.05
			aim_force_strength = 0.58
			obstacle_density = 18
			obstacle_max_radius = 0.95
			clear_path_width = 3.0
			route_camber_strength = 0.18
			route_camber_band_length = 8.5


func front_slope_grade() -> float:
	return ridge_height / maxf(0.001, front_base_z - ridge_z)


func back_slope_grade() -> float:
	return ridge_height / maxf(0.001, ridge_z - back_base_z)
