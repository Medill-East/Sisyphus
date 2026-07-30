extends Node3D

const TuningScript = preload("res://scripts/Tuning.gd")
const GameStateScript = preload("res://scripts/GameState.gd")
const DebugForceOverlayScript = preload("res://scripts/DebugForceOverlay.gd")
const PushControllerScript = preload("res://scripts/PushController.gd")

var tuning = TuningScript.new()
var game_state = GameStateScript.new()
var active_preset: String = "standard"

@onready var mountain = $Mountain
@onready var player = $Player
@onready var stone: RigidBody3D = $Stone
@onready var camera: Camera3D = $Camera3D
@onready var status_label: Label = $HUD/Status
@onready var controls_label: Label = $HUD/Controls

var _debug_overlay: Node3D
var _debug_visible: bool = false
var _auto_mode: String = ""
var _auto_debug: bool = false
var _auto_frame: int = 0
var _last_frame
var _last_camera_target: Vector3 = Vector3.ZERO


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_parse_args()
	game_state.tuning = tuning
	game_state.phase = GameStateScript.Phase.ASCENT
	tuning.apply_push_lab_preset(active_preset)
	_apply_short_skill_slope_geometry()
	mountain.tuning = tuning
	mountain.build()
	_debug_overlay = DebugForceOverlayScript.new()
	_debug_overlay.name = "DebugForceOverlay"
	_debug_overlay.visible = _debug_visible
	add_child(_debug_overlay)
	_reset_lab()
	player.setup(tuning, mountain, game_state, stone, camera)
	_apply_stone_physics()
	if _auto_mode != "":
		_debug_visible = _auto_debug
		_debug_overlay.visible = _debug_visible
		player.set_physics_process(false)
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_F3:
			_debug_visible = not _debug_visible
			_debug_overlay.visible = _debug_visible
		KEY_1:
			set_preset("heavy")
		KEY_2:
			set_preset("standard")
		KEY_3:
			set_preset("light")
		KEY_R:
			_reset_lab()


func _physics_process(delta: float) -> void:
	if _auto_mode != "":
		_apply_auto_mode(delta)
	_update_debug_overlay()
	_update_hud()


func set_preset(preset_name: String) -> void:
	if not TuningScript.push_lab_preset_names().has(preset_name):
		preset_name = "standard"
	active_preset = preset_name
	tuning.apply_push_lab_preset(active_preset)
	_apply_short_skill_slope_geometry()
	if mountain != null:
		mountain.tuning = tuning
		mountain.build()
	if player != null:
		player.tuning = tuning
	if stone != null:
		_apply_stone_physics()
		_reset_lab()


func _apply_short_skill_slope_geometry() -> void:
	tuning.front_base_z = 8.0
	tuning.ridge_z = -11.0
	tuning.back_base_z = -28.0
	tuning.ridge_height = 4.25
	tuning.path_width = 7.0
	tuning.route_camber_band_length = 5.8
	tuning.route_camber_strength = 0.0


func _reset_lab() -> void:
	var stone_z: float = tuning.front_base_z + 1.1
	stone.global_position = Vector3(0.0, mountain.height_at(stone_z) + tuning.stone_radius + 0.12, stone_z)
	stone.linear_velocity = Vector3.ZERO
	stone.angular_velocity = Vector3.ZERO
	stone.freeze = true
	stone.sleeping = false

	var downhill: Vector3 = mountain.downhill_tangent_at(stone.global_position.z)
	player.global_position = stone.global_position + downhill * tuning.stone_radius * 1.9
	player.global_position.y = mountain.height_at(player.global_position.z) + 0.05
	player.camera_yaw = 0.0
	player.camera_pitch = -0.06
	player.push_engaged = false
	player.camera_push_blend = 0.0
	_clear_player_brace()
	_auto_frame = 0
	_position_lab_camera(mountain.uphill_tangent_at(stone.global_position.z), stone.global_position + Vector3.UP * 0.55, 0.0)


func _apply_stone_physics() -> void:
	stone.mass = tuning.stone_mass
	stone.gravity_scale = tuning.stone_gravity_scale
	stone.linear_damp = tuning.stone_linear_damp
	stone.angular_damp = tuning.stone_angular_damp
	stone.continuous_cd = true
	stone.contact_monitor = true
	stone.max_contacts_reported = 8
	stone.can_sleep = false
	var material: PhysicsMaterial = PhysicsMaterial.new()
	material.friction = tuning.stone_friction
	material.bounce = 0.01
	stone.physics_material_override = material


func push_motion_state(frame = null) -> String:
	if stone == null or mountain == null:
		return "idle"
	if stone.freeze:
		return "idle"
	var resolved_frame = frame
	if resolved_frame == null:
		resolved_frame = player.push_frame if player != null and player.push_frame != null else _last_frame
	var uphill_velocity: float = _stone_uphill_velocity()
	if resolved_frame != null and resolved_frame.contact_valid:
		if resolved_frame.contact_quality < tuning.first_person_hands_min_contact_quality:
			return "weak"
		if resolved_frame.burden_recoil > 0.46:
			return "strain"
		return "push"
	if uphill_velocity < -0.08:
		return "rollback"
	if absf(uphill_velocity) <= 0.08:
		return "stall"
	return "coast"


func route_progress_status() -> Dictionary:
	if stone == null or tuning == null:
		return {
			"section": "unknown",
			"ascent_progress": 0.0,
			"distance_to_ridge": 0.0,
			"distance_to_back_foot": 0.0,
		}
	var route_start_z: float = tuning.front_base_z + 1.1
	var ascent_total: float = maxf(0.001, route_start_z - tuning.ridge_z)
	var ascent_progress: float = clampf((route_start_z - stone.global_position.z) / ascent_total, 0.0, 1.0)
	var distance_to_ridge: float = maxf(0.0, stone.global_position.z - tuning.ridge_z)
	var distance_to_back_foot: float = maxf(0.0, stone.global_position.z - tuning.back_base_z)
	var section: String = "front climb"
	if stone.global_position.z <= tuning.ridge_z - tuning.stone_radius * 0.75:
		section = "back slope"
	elif distance_to_ridge <= 3.0:
		section = "ridge"
	return {
		"section": section,
		"ascent_progress": ascent_progress,
		"distance_to_ridge": distance_to_ridge,
		"distance_to_back_foot": distance_to_back_foot,
	}


func evaluate_two_hand_topology() -> Dictionary:
	var stone_position: Vector3 = stone.global_position
	var uphill: Vector3 = mountain.uphill_tangent_at(stone_position.z)
	var side: Vector3 = Vector3(-uphill.z, 0.0, uphill.x).normalized()
	var downhill: Vector3 = mountain.downhill_tangent_at(stone_position.z)
	var player_position: Vector3 = stone_position + downhill * tuning.stone_radius * 1.55
	player_position.y = mountain.height_at(player_position.z) + 0.05
	var camera_left: Vector3 = (uphill + side * -1.6 + Vector3.UP * 0.4).normalized()
	var camera_right: Vector3 = (uphill + side * 1.6 + Vector3.DOWN * 0.3).normalized()
	var left_only = PushControllerScript.calculate_two_hand_push_frame(
		stone_position, player_position, uphill, uphill, 1.0, 0.0, tuning, mountain
	)
	var right_only = PushControllerScript.calculate_two_hand_push_frame(
		stone_position, player_position, uphill, uphill, 0.0, 1.0, tuning, mountain
	)
	var balanced = PushControllerScript.calculate_two_hand_push_frame(
		stone_position, player_position, uphill, camera_left, 1.0, 1.0, tuning, mountain
	)
	var swept = PushControllerScript.calculate_two_hand_push_frame(
		stone_position, player_position, uphill, camera_right, 1.0, 1.0, tuning, mountain
	)
	return {
		"success": (
			left_only.contact_force.dot(side) > 0.0
			and right_only.contact_force.dot(side) < 0.0
			and absf(balanced.contact_force.dot(side)) < 0.001
			and balanced.contact_force.distance_to(swept.contact_force) < 0.0001
		),
		"left_only_side_force": left_only.contact_force.dot(side),
		"right_only_side_force": right_only.contact_force.dot(side),
		"balanced_side_force": absf(balanced.contact_force.dot(side)),
		"left_only_torque": left_only.left_torque.length(),
		"right_only_torque": right_only.right_torque.length(),
		"camera_force_delta": balanced.contact_force.distance_to(swept.contact_force),
		"left_load": left_only.left_load,
		"right_load": right_only.right_load,
	}


func enter_first_person_push_observation(aim_bias: Vector3 = Vector3.ZERO) -> void:
	if stone == null or player == null or mountain == null:
		return
	if stone.freeze:
		stone.freeze = false
		stone.sleeping = false
	var uphill: Vector3 = mountain.uphill_tangent_at(stone.global_position.z)
	var downhill: Vector3 = mountain.downhill_tangent_at(stone.global_position.z)
	player.global_position = stone.global_position + downhill * tuning.stone_radius * 1.65
	player.global_position.y = mountain.height_at(player.global_position.z) + 0.05
	var camera_direction: Vector3 = (uphill + aim_bias).normalized()
	var camera_origin: Vector3 = _refined_reticle_camera_origin(camera_direction, true, aim_bias.x, 999.0, 1.0)
	var preview_frame = PushControllerScript.calculate_push_frame(
		stone.global_position,
		player.global_position,
		camera_direction,
		true,
		aim_bias.x,
		tuning,
		mountain,
		999.0,
		camera_origin
	)
	var frame = preview_frame
	_last_frame = frame
	player.push_frame = frame
	player.push_engaged = true
	player.push_brace = 1.0
	player.push_aim_speed = 0.0
	player._previous_push_aim = camera_direction
	player._near_stone = true
	player._is_walking = true
	player.push_contact_seconds = tuning.first_person_hands_min_contact_seconds + 0.05
	player.camera_push_blend = 1.0
	player.set_physics_process(false)
	player.update_push_visual_mode()
	_position_lab_camera(frame.aim_direction, frame.camera_contact_point, 1.0)
	player._update_arm_visual(1.0 / 60.0, frame.aim_direction)
	player._update_first_person_hands(frame.aim_direction)
	_update_debug_overlay()
	_update_hud()


func enter_approach_observation() -> void:
	if stone == null or player == null or mountain == null:
		return
	_reset_lab()
	_last_frame = null
	player.push_frame = null
	player.push_engaged = false
	_clear_player_brace()
	player._near_stone = false
	player._is_walking = false
	player.camera_push_blend = 0.0
	player.set_physics_process(false)
	player.update_push_visual_mode()
	var camera_direction: Vector3 = mountain.uphill_tangent_at(stone.global_position.z)
	player._update_arm_visual(1.0 / 60.0, camera_direction)
	player._update_first_person_hands(camera_direction)
	_position_lab_camera(camera_direction, stone.global_position + Vector3.UP * 0.82, 0.0)
	_update_hud()


func enter_release_rollback_observation() -> void:
	if stone == null or player == null or mountain == null:
		return
	var z: float = lerpf(tuning.front_base_z, tuning.ridge_z, 0.42)
	stone.global_position = Vector3(0.0, mountain.height_at(z) + tuning.stone_radius + 0.10, z)
	stone.freeze = false
	stone.sleeping = false
	stone.linear_velocity = mountain.downhill_tangent_at(z) * 1.15
	stone.angular_velocity = Vector3(0.9, 0.0, 0.15)
	var downhill: Vector3 = mountain.downhill_tangent_at(stone.global_position.z)
	player.global_position = stone.global_position + downhill * tuning.stone_radius * 2.15
	player.global_position.y = mountain.height_at(player.global_position.z) + 0.05
	_last_frame = null
	player.push_frame = null
	player.push_engaged = false
	_clear_player_brace()
	player._near_stone = false
	player._is_walking = false
	player.camera_push_blend = 0.0
	player.set_physics_process(false)
	player.update_push_visual_mode()
	var camera_direction: Vector3 = mountain.uphill_tangent_at(stone.global_position.z)
	player._update_arm_visual(1.0 / 60.0, camera_direction)
	player._update_first_person_hands(camera_direction)
	_position_lab_camera(camera_direction, stone.global_position + Vector3.UP * 0.82, 0.0)
	_update_debug_overlay()
	_update_hud()


func first_person_push_camera_status() -> Dictionary:
	var hands = player.get_node_or_null("FirstPersonHands") if player != null else null
	var body = player.get_node_or_null("Body") if player != null else null
	var resolved_frame = player.push_frame if player != null and player.push_frame != null else _last_frame
	var contact: Vector3 = resolved_frame.camera_contact_point if resolved_frame != null else stone.global_position + Vector3.UP * 0.55
	var left_local := Vector3.ZERO
	var right_local := Vector3.ZERO
	var left_forearm_local := Vector3.ZERO
	var right_forearm_local := Vector3.ZERO
	var nearest_hand_to_contact: float = 99.0
	var stone_local := Vector3.ZERO
	var contact_local := Vector3.ZERO
	var contact_side_offset: float = 0.0
	var force_side_component: float = 0.0
	var contact_quality: float = 0.0
	var burden_stride: float = 1.0
	var burden_recoil: float = 0.0
	var hand_radius: float = 0.0
	var forearm_radius: float = 0.0
	var palm_compression: float = 0.0
	var left_hand_scale := Vector3.ONE
	var right_hand_scale := Vector3.ONE
	var torso_visible: bool = false
	var torso_local := Vector3.ZERO
	var left_upper_local := Vector3.ZERO
	var right_upper_local := Vector3.ZERO
	var contact_cue_status: Dictionary = {
		"visible": false,
		"contact_distance": 99.0,
		"camera_x_ratio": 99.0,
		"force_length": 0.0,
		"quality_signal": 0.0,
		"patch_scale": 0.0,
		"saturation_hint": 0.0,
	}
	var route_visibility: Dictionary = _route_edge_visibility_status()
	var ridge_visibility: Dictionary = _ridge_visibility_status()
	if camera != null:
		camera.force_update_transform()
	if stone != null and mountain != null:
		var route_uphill: Vector3 = mountain.uphill_tangent_at(stone.global_position.z)
		var route_side: Vector3 = Vector3(-route_uphill.z, 0.0, route_uphill.x)
		if route_side.length_squared() < 0.001:
			route_side = Vector3.RIGHT
		else:
			route_side = route_side.normalized()
			if resolved_frame != null:
				contact_side_offset = (resolved_frame.camera_contact_point - stone.global_position).dot(route_side)
				force_side_component = resolved_frame.contact_force.dot(route_side)
				contact_quality = resolved_frame.contact_quality
				burden_stride = resolved_frame.burden_stride
				burden_recoil = resolved_frame.burden_recoil
	if camera != null:
		if stone != null:
			stone_local = camera.to_local(stone.global_position)
		contact_local = camera.to_local(contact)
	if camera != null and hands != null:
		if hands.has_method("palm_compression"):
			palm_compression = float(hands.call("palm_compression"))
		var chest: Node3D = hands.get_node_or_null("Chest")
		var left_upper_arm: Node3D = hands.get_node_or_null("LeftUpperArm")
		var right_upper_arm: Node3D = hands.get_node_or_null("RightUpperArm")
		var left_hand: Node3D = hands.get_node_or_null("LeftHand")
		var right_hand: Node3D = hands.get_node_or_null("RightHand")
		var left_forearm: Node3D = hands.get_node_or_null("LeftForearm")
		var right_forearm: Node3D = hands.get_node_or_null("RightForearm")
		if chest != null:
			torso_visible = hands.visible and chest.visible
			torso_local = camera.to_local(chest.global_position)
		if left_upper_arm != null:
			left_upper_local = camera.to_local(left_upper_arm.global_position)
		if right_upper_arm != null:
			right_upper_local = camera.to_local(right_upper_arm.global_position)
		if left_hand != null:
			left_hand_scale = left_hand.scale
			left_local = camera.to_local(left_hand.global_position)
			nearest_hand_to_contact = minf(nearest_hand_to_contact, left_hand.global_position.distance_to(contact))
			if left_hand is MeshInstance3D and left_hand.mesh is SphereMesh:
				hand_radius = left_hand.mesh.radius
		if right_hand != null:
			right_hand_scale = right_hand.scale
			right_local = camera.to_local(right_hand.global_position)
			nearest_hand_to_contact = minf(nearest_hand_to_contact, right_hand.global_position.distance_to(contact))
		if left_forearm != null:
			left_forearm_local = camera.to_local(left_forearm.global_position)
			if left_forearm is MeshInstance3D and left_forearm.mesh is CapsuleMesh:
				forearm_radius = left_forearm.mesh.radius
		if right_forearm != null:
			right_forearm_local = camera.to_local(right_forearm.global_position)
	var contact_cue = player.get_node_or_null("ContactCue") if player != null else null
	if contact_cue != null and contact_cue.has_method("status"):
		contact_cue_status = contact_cue.call("status", camera, contact)
	return {
		"push_blend": player.camera_push_blend if player != null else 0.0,
		"hands_visible": hands != null and hands.visible,
		"body_visible": body != null and body.visible,
		"camera_fov": camera.fov if camera != null else 0.0,
		"camera_to_contact": camera.global_position.distance_to(contact) if camera != null else 99.0,
		"camera_to_stone": camera.global_position.distance_to(stone.global_position) if camera != null and stone != null else 99.0,
		"left_hand_camera_x": left_local.x,
		"left_hand_camera_y": left_local.y,
		"left_hand_camera_depth": absf(left_local.z),
		"right_hand_camera_x": right_local.x,
		"right_hand_camera_y": right_local.y,
		"right_hand_camera_depth": absf(right_local.z),
		"hand_center_clearance": minf(absf(left_local.x), absf(right_local.x)),
		"hand_lateral_span": absf(right_local.x - left_local.x),
		"nearest_hand_to_contact": nearest_hand_to_contact,
		"palm_compression": palm_compression,
		"left_hand_scale_x": left_hand_scale.x,
		"left_hand_scale_y": left_hand_scale.y,
		"left_hand_scale_z": left_hand_scale.z,
		"right_hand_scale_x": right_hand_scale.x,
		"right_hand_scale_y": right_hand_scale.y,
		"right_hand_scale_z": right_hand_scale.z,
		"left_forearm_camera_x": left_forearm_local.x,
		"left_forearm_camera_y": left_forearm_local.y,
		"right_forearm_camera_x": right_forearm_local.x,
		"right_forearm_camera_y": right_forearm_local.y,
		"forearm_center_clearance": minf(absf(left_forearm_local.x), absf(right_forearm_local.x)),
		"forearm_lateral_span": absf(right_forearm_local.x - left_forearm_local.x),
		"torso_visible": torso_visible,
		"torso_camera_y": torso_local.y if torso_visible else 99.0,
		"upper_arm_center_clearance": minf(absf(left_upper_local.x), absf(right_upper_local.x)),
		"upper_arm_lateral_span": absf(right_upper_local.x - left_upper_local.x),
		"hand_radius": hand_radius,
		"forearm_radius": forearm_radius,
		"stone_camera_x": stone_local.x,
		"stone_camera_y": stone_local.y,
		"stone_camera_depth": absf(stone_local.z),
		"stone_camera_x_ratio": absf(stone_local.x) / maxf(0.001, absf(stone_local.z)),
		"contact_camera_x": contact_local.x,
		"contact_camera_y": contact_local.y,
		"contact_camera_depth": absf(contact_local.z),
		"contact_camera_x_ratio": absf(contact_local.x) / maxf(0.001, absf(contact_local.z)),
		"contact_height_offset": contact.y - stone.global_position.y if stone != null else 0.0,
		"contact_side_offset": contact_side_offset,
		"force_side_component": force_side_component,
		"contact_quality": contact_quality,
		"brace_amount": player.push_brace if player != null else 0.0,
		"breakaway_ratio": resolved_frame.breakaway_ratio if resolved_frame != null else 0.0,
		"aim_stability": resolved_frame.aim_stability if resolved_frame != null else 0.0,
		"burden_stride": burden_stride,
		"burden_recoil": burden_recoil,
		"contact_cue_visible": bool(contact_cue_status.get("visible", false)),
		"contact_cue_to_contact": float(contact_cue_status.get("contact_distance", 99.0)),
		"contact_cue_camera_x_ratio": float(contact_cue_status.get("camera_x_ratio", 99.0)),
		"contact_cue_force_length": float(contact_cue_status.get("force_length", 0.0)),
		"contact_cue_quality_signal": float(contact_cue_status.get("quality_signal", 0.0)),
		"contact_cue_patch_scale": float(contact_cue_status.get("patch_scale", 0.0)),
		"contact_cue_saturation_hint": float(contact_cue_status.get("saturation_hint", 0.0)),
		"contact_cue_visual_style": str(contact_cue_status.get("visual_style", "")),
		"contact_cue_debug_vector": bool(contact_cue_status.get("debug_vector", true)),
		"visible_left_route_markers": int(route_visibility.get("left", 0)),
		"visible_right_route_markers": int(route_visibility.get("right", 0)),
		"route_edge_camera_x_ratio": float(route_visibility.get("max_x_ratio", 99.0)),
		"visible_ridge_markers": int(ridge_visibility.get("count", 0)),
		"ridge_marker_camera_x_ratio": float(ridge_visibility.get("max_x_ratio", 99.0)),
	}


func _route_edge_visibility_status() -> Dictionary:
	var result: Dictionary = {
		"left": 0,
		"right": 0,
		"max_x_ratio": 99.0,
	}
	if camera == null:
		return result
	var marker_root = get_node_or_null("Mountain/RouteEdgeMarkers")
	if marker_root == null:
		return result
	var max_ratio: float = 0.0
	for child in marker_root.get_children():
		if not (child is Node3D):
			continue
		var marker: Node3D = child
		var local: Vector3 = camera.to_local(marker.global_position)
		if local.z >= -0.1:
			continue
		var depth: float = absf(local.z)
		var x_ratio: float = absf(local.x) / maxf(0.001, depth)
		var y_ratio: float = absf(local.y) / maxf(0.001, depth)
		if x_ratio > 1.15 or y_ratio > 0.82:
			continue
		max_ratio = maxf(max_ratio, x_ratio)
		if marker.global_position.x < 0.0:
			result["left"] = int(result["left"]) + 1
		else:
			result["right"] = int(result["right"]) + 1
	if int(result["left"]) > 0 or int(result["right"]) > 0:
		result["max_x_ratio"] = max_ratio
	return result


func _ridge_visibility_status() -> Dictionary:
	var result: Dictionary = {
		"count": 0,
		"max_x_ratio": 99.0,
	}
	if camera == null:
		return result
	var marker_root = get_node_or_null("Mountain/RidgeGateMarkers")
	if marker_root == null:
		return result
	var max_ratio: float = 0.0
	for child in marker_root.get_children():
		if not (child is Node3D):
			continue
		var marker: Node3D = child
		var local: Vector3 = camera.to_local(marker.global_position)
		if local.z >= -0.1:
			continue
		var depth: float = absf(local.z)
		var x_ratio: float = absf(local.x) / maxf(0.001, depth)
		var y_ratio: float = absf(local.y) / maxf(0.001, depth)
		if x_ratio > 1.05 or y_ratio > 0.92:
			continue
		result["count"] = int(result["count"]) + 1
		max_ratio = maxf(max_ratio, x_ratio)
	if int(result["count"]) > 0:
		result["max_x_ratio"] = max_ratio
	return result


func save_observation_snapshot(path: String = "/private/tmp/sisyphus-pushlab-observation.png") -> Dictionary:
	var evidence: Dictionary = first_person_push_camera_status()
	evidence["path"] = path
	evidence["error"] = _save_observation_png(path)
	evidence["motion_state"] = push_motion_state(player.push_frame if player != null else null)
	evidence["contact_valid"] = player != null and player.push_frame != null and player.push_frame.contact_valid
	evidence["uphill_velocity"] = _stone_uphill_velocity()
	return evidence


func save_core_evidence_sequence(base_path: String = "/private/tmp/sisyphus-pushlab-core-sequence") -> Array:
	var sequence: Array = []
	enter_approach_observation()
	await get_tree().process_frame
	sequence.append(_save_labeled_observation("approach", base_path))
	enter_first_person_push_observation()
	await get_tree().process_frame
	sequence.append(_save_labeled_observation("push", base_path))
	enter_first_person_push_observation(Vector3.LEFT * 0.9)
	await get_tree().process_frame
	sequence.append(_save_labeled_observation("left_bias", base_path))
	enter_first_person_push_observation(Vector3.RIGHT * 0.9)
	await get_tree().process_frame
	sequence.append(_save_labeled_observation("right_bias", base_path))
	enter_release_rollback_observation()
	await get_tree().process_frame
	sequence.append(_save_labeled_observation("release_rollback", base_path))
	return sequence


func run_push_intent_diagnostic(
	base_path: String = "/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/push-intent-diagnostic"
) -> Dictionary:
	var snapshots: Array = []
	enter_approach_observation()
	await get_tree().process_frame
	snapshots.append(_save_labeled_observation("approach", base_path))
	enter_first_person_push_observation()
	await get_tree().process_frame
	snapshots.append(_save_labeled_observation("center_push", base_path))
	enter_first_person_push_observation(Vector3.LEFT * 0.84 + Vector3.UP * 0.32)
	await get_tree().process_frame
	snapshots.append(_save_labeled_observation("left_high", base_path))
	enter_first_person_push_observation(Vector3.RIGHT * 0.84 + Vector3.UP * 0.32)
	await get_tree().process_frame
	snapshots.append(_save_labeled_observation("right_high", base_path))
	enter_first_person_push_observation(Vector3.DOWN * 0.52)
	await get_tree().process_frame
	snapshots.append(_save_labeled_observation("look_down", base_path))
	enter_release_rollback_observation()
	await get_tree().process_frame
	snapshots.append(_save_labeled_observation("disengage", base_path))

	var aim_drill: Dictionary = await evaluate_aim_control_drill()
	var aim_polarity: Dictionary = await evaluate_aim_polarity_drill()
	var angle_mastery: Dictionary = await evaluate_angle_mastery_drill()
	var left_status: Dictionary = _snapshot_by_label(snapshots, "left_high")
	var right_status: Dictionary = _snapshot_by_label(snapshots, "right_high")
	var look_down_status: Dictionary = _snapshot_by_label(snapshots, "look_down")
	var disengage_status: Dictionary = _snapshot_by_label(snapshots, "disengage")
	var contact_delta: float = float(right_status.get("contact_side_offset", 0.0)) - float(left_status.get("contact_side_offset", 0.0))
	var force_delta: float = float(right_status.get("force_side_component", 0.0)) - float(left_status.get("force_side_component", 0.0))
	var drift_gap: float = float(aim_drill.get("drift_gap", 0.0))
	var left_route_visible: bool = int(left_status.get("visible_left_route_markers", 0)) > 0 and int(left_status.get("visible_right_route_markers", 0)) > 0
	var right_route_visible: bool = int(right_status.get("visible_left_route_markers", 0)) > 0 and int(right_status.get("visible_right_route_markers", 0)) > 0
	var look_down_readable: bool = (
		float(look_down_status.get("contact_camera_x_ratio", 99.0)) < 0.48
		and bool(look_down_status.get("contact_cue_visible", false))
	)
	var disengaged_cleanly: bool = (
		not bool(disengage_status.get("contact_valid", true))
		and not bool(disengage_status.get("hands_visible", true))
		and bool(disengage_status.get("body_visible", false))
	)
	var hand_surface_clear: bool = (
		float(left_status.get("nearest_hand_to_contact", 99.0)) < 0.62
		and float(right_status.get("nearest_hand_to_contact", 99.0)) < 0.62
	)
	var success: bool = (
		contact_delta > 0.55
		and force_delta > 18.0
		and drift_gap > 0.28
		and left_route_visible
		and right_route_visible
		and look_down_readable
		and disengaged_cleanly
		and hand_surface_clear
		and bool(aim_drill.get("success", false))
		and bool(angle_mastery.get("success", false))
	)
	var result: Dictionary = {
		"success": success,
		"verdict": "PROCEED" if success else "PIVOT",
		"base_path": base_path,
		"report_path": "%s.md" % base_path,
		"snapshots": snapshots,
		"aim_drill": aim_drill,
		"aim_polarity": aim_polarity,
		"angle_mastery": angle_mastery,
		"contact_delta": contact_delta,
		"force_delta": force_delta,
		"drift_gap": drift_gap,
		"left_route_visible": left_route_visible,
		"right_route_visible": right_route_visible,
		"look_down_readable": look_down_readable,
		"disengaged_cleanly": disengaged_cleanly,
		"hand_surface_clear": hand_surface_clear,
	}
	result["write_error"] = _write_push_intent_diagnostic_report(str(result["report_path"]), result)
	return result


func evaluate_bias_recovery_route(side_sign: float = 1.0) -> Dictionary:
	if stone == null or player == null or mountain == null:
		return {"success": false, "status": "missing_nodes"}
	var signed_side: float = 1.0 if side_sign >= 0.0 else -1.0
	var obstacle: Dictionary = _near_channel_front_obstacle(signed_side)
	if obstacle.is_empty():
		return {"success": false, "status": "missing_obstacle"}

	_place_stone_for_obstacle_glance(obstacle)
	player.set_physics_process(false)
	var start_position: Vector3 = stone.global_position
	var max_air_gap: float = 0.0
	var min_speed_after_contact: float = INF
	var max_spin_ratio: float = 0.0
	var touched_obstacle: bool = false
	var aim_bias: Vector3 = Vector3.RIGHT * signed_side * 0.62

	for index in 170:
		_drive_lab_push(aim_bias, true, 1.0 / 60.0)
		await get_tree().physics_frame
		var metrics: Dictionary = _sample_bias_route_metrics(obstacle, touched_obstacle)
		max_air_gap = maxf(max_air_gap, float(metrics.get("air_gap", 0.0)))
		max_spin_ratio = maxf(max_spin_ratio, float(metrics.get("spin_ratio", 0.0)))
		if bool(metrics.get("touched", false)):
			touched_obstacle = true
		if touched_obstacle:
			min_speed_after_contact = minf(min_speed_after_contact, stone.linear_velocity.length())

	_drive_lab_push(Vector3.ZERO, false, 1.0 / 60.0)
	await get_tree().physics_frame
	var recover_start_z: float = stone.global_position.z
	for index in 220:
		_drive_lab_push(Vector3.ZERO, true, 1.0 / 60.0)
		await get_tree().physics_frame
		var recovery_metrics: Dictionary = _sample_bias_route_metrics(obstacle, touched_obstacle)
		max_air_gap = maxf(max_air_gap, float(recovery_metrics.get("air_gap", 0.0)))
		max_spin_ratio = maxf(max_spin_ratio, float(recovery_metrics.get("spin_ratio", 0.0)))
		if bool(recovery_metrics.get("touched", false)):
			touched_obstacle = true
			min_speed_after_contact = minf(min_speed_after_contact, stone.linear_velocity.length())

	_drive_lab_push(Vector3.ZERO, false, 1.0 / 60.0)
	var recovery_gain: float = recover_start_z - stone.global_position.z
	var total_distance: float = start_position.distance_to(stone.global_position)
	var clear_half: float = tuning.clear_path_width * 0.5
	var min_speed: float = min_speed_after_contact if min_speed_after_contact < INF else 999.0
	var success := (
		touched_obstacle
		and max_air_gap < 0.38
		and min_speed < 2.2
		and recovery_gain > 0.22
		and absf(stone.global_position.x) < clear_half + 0.55
		and total_distance > 0.4
		and max_spin_ratio < 12.0
	)
	return {
		"success": success,
		"status": "ok" if success else "failed",
		"touched_obstacle": touched_obstacle,
		"max_air_gap": max_air_gap,
		"min_speed_after_contact": min_speed,
		"recovery_gain": recovery_gain,
		"final_x": stone.global_position.x,
		"clear_path_half_width": clear_half,
		"total_distance": total_distance,
		"max_spin_to_translation_ratio": max_spin_ratio,
		"start_position": start_position,
		"end_position": stone.global_position,
	}


func evaluate_aim_control_drill() -> Dictionary:
	if stone == null or player == null or mountain == null:
		return {"success": false, "status": "missing_nodes"}
	var center: Dictionary = await _run_aim_control_trial("center", Vector3.ZERO)
	var left: Dictionary = await _run_aim_control_trial("left", Vector3.LEFT * 0.36 + Vector3.DOWN * 0.12)
	var right: Dictionary = await _run_aim_control_trial("right", Vector3.RIGHT * 0.36 + Vector3.DOWN * 0.12)
	var drift_gap: float = float(right.get("lateral_delta", 0.0)) - float(left.get("lateral_delta", 0.0))
	var success := (
		float(left.get("contact_side_offset", 0.0)) < -0.18
		and float(right.get("contact_side_offset", 0.0)) > 0.18
		and float(left.get("force_side_component", 0.0)) < -8.0
		and float(right.get("force_side_component", 0.0)) > 8.0
		and float(left.get("lateral_delta", 0.0)) < -0.08
		and float(right.get("lateral_delta", 0.0)) > 0.08
		and drift_gap > 0.28
		and absf(float(center.get("lateral_delta", 99.0))) < 0.16
		and float(left.get("uphill_gain", 0.0)) > 0.04
		and float(right.get("uphill_gain", 0.0)) > 0.04
		and float(left.get("contact_ratio", 0.0)) > 0.92
		and float(right.get("contact_ratio", 0.0)) > 0.92
		and float(left.get("max_spin_to_translation_ratio", 99.0)) < 12.0
		and float(right.get("max_spin_to_translation_ratio", 99.0)) < 12.0
	)
	return {
		"success": success,
		"status": "ok" if success else "failed",
		"center": center,
		"left": left,
		"right": right,
		"drift_gap": drift_gap,
	}


func evaluate_aim_polarity_drill() -> Dictionary:
	if stone == null or player == null or mountain == null:
		return {"success": false, "status": "missing_nodes"}
	var center: Dictionary = await _run_slow_aim_polarity_trial("center", Vector3.ZERO, 0)
	var left: Dictionary = await _run_slow_aim_polarity_trial("left", Vector3.LEFT * 0.46 + Vector3.DOWN * 0.10, -1)
	var right: Dictionary = await _run_slow_aim_polarity_trial("right", Vector3.RIGHT * 0.46 + Vector3.DOWN * 0.10, 1)
	var drift_gap: float = float(right.get("lateral_delta", 0.0)) - float(left.get("lateral_delta", 0.0))
	var success := (
		bool(left.get("polarity_consistent", false))
		and bool(right.get("polarity_consistent", false))
		and absf(float(center.get("lateral_delta", 99.0))) < 0.22
		and drift_gap > 0.24
	)
	return {
		"success": success,
		"status": "ok" if success else "failed",
		"center": center,
		"left": left,
		"right": right,
		"drift_gap": drift_gap,
	}


func evaluate_angle_mastery_drill() -> Dictionary:
	if stone == null or player == null or mountain == null:
		return {"success": false, "status": "missing_nodes"}
	var center: Dictionary = await _run_aim_control_trial("sweet_spot", Vector3.ZERO)
	var high_side: Dictionary = await _run_aim_control_trial("bad_high_side", Vector3.RIGHT * 0.72 + Vector3.UP * 0.78)
	var high_center: Dictionary = await _run_aim_control_trial("bad_high_center", Vector3.UP * 1.10)
	var center_gain: float = float(center.get("uphill_gain", 0.0))
	var high_side_gain: float = float(high_side.get("uphill_gain", 0.0))
	var high_center_gain: float = float(high_center.get("uphill_gain", 0.0))
	var center_quality: float = float(center.get("average_contact_quality", 0.0))
	var high_side_quality: float = float(high_side.get("average_contact_quality", 0.0))
	var high_center_quality: float = float(high_center.get("average_contact_quality", 0.0))
	var success := (
		center_gain > 0.34
		and high_side_gain < -0.08
		and high_center_gain < center_gain * 0.42
		and high_side_quality < center_quality * 0.72
		and high_center_quality < center_quality * 0.78
	)
	return {
		"success": success,
		"status": "ok" if success else "failed",
		"center": center,
		"high_side": high_side,
		"high_center": high_center,
		"center_gain": center_gain,
		"high_side_gain": high_side_gain,
		"high_center_gain": high_center_gain,
		"center_quality": center_quality,
		"high_side_quality": high_side_quality,
		"high_center_quality": high_center_quality,
	}


func evaluate_short_slope_angle_gate() -> Dictionary:
	if stone == null or player == null or mountain == null:
		return {"success": false, "status": "missing_nodes"}
	var near_miss: Dictionary = await _run_aim_control_trial("near_miss", Vector3.RIGHT * 0.58 + Vector3.UP * 0.58)
	var near_release_z: float = stone.global_position.z
	for index in 100:
		_drive_lab_push(Vector3.ZERO, false, 1.0 / 60.0)
		await get_tree().physics_frame
	var near_miss_rollback: float = stone.global_position.z - near_release_z
	var sweet: Dictionary = await _run_aim_control_trial("sweet_spot", Vector3.DOWN * 0.06)
	var sweet_gain: float = float(sweet.get("uphill_gain", 0.0))
	var near_miss_gain: float = float(near_miss.get("uphill_gain", 0.0))
	var sweet_quality: float = float(sweet.get("average_contact_quality", 0.0))
	var near_miss_quality: float = float(near_miss.get("average_contact_quality", 0.0))
	var quality_gap: float = sweet_quality - near_miss_quality
	var success := (
		sweet_gain > 0.42
		and near_miss_gain < sweet_gain * 0.25
		and near_miss_rollback > 0.18
		and quality_gap > 0.22
	)
	return {
		"success": success,
		"status": "ok" if success else "failed",
		"sweet": sweet,
		"near_miss": near_miss,
		"sweet_gain": sweet_gain,
		"near_miss_gain": near_miss_gain,
		"near_miss_rollback": near_miss_rollback,
		"sweet_quality": sweet_quality,
		"near_miss_quality": near_miss_quality,
		"quality_gap": quality_gap,
	}


func _run_slow_aim_polarity_trial(label: String, aim_bias: Vector3, intended_side: int) -> Dictionary:
	var z: float = tuning.front_base_z - 5.5
	stone.freeze = false
	stone.sleeping = false
	stone.global_position = Vector3(0.0, mountain.height_at(z) + tuning.stone_radius + 0.10, z)
	stone.linear_velocity = Vector3.ZERO
	stone.angular_velocity = Vector3.ZERO
	var downhill: Vector3 = mountain.downhill_tangent_at(z)
	player.set_physics_process(false)
	player.global_position = stone.global_position + downhill * tuning.stone_radius * 1.55
	player.global_position.y = mountain.height_at(player.global_position.z) + 0.05
	player.push_contact_seconds = 0.0
	player.push_engaged = false
	_clear_player_brace()
	player.push_frame = null
	player.camera_push_blend = 1.0
	player.update_push_visual_mode()
	var start_position: Vector3 = stone.global_position
	var samples: Array[Dictionary] = []
	var final_status: Dictionary = {}
	var frame_count: int = 120

	for index in frame_count:
		_drive_lab_push(aim_bias, true, 1.0 / 60.0)
		await get_tree().physics_frame
		if index % 20 == 0 or index == frame_count - 1:
			final_status = first_person_push_camera_status()
			var frame = _last_frame
			var route_side: Vector3 = _route_side_at_stone()
			samples.append({
				"frame": index,
				"contact_side_offset": float(final_status.get("contact_side_offset", 0.0)),
				"force_side_component": float(final_status.get("force_side_component", 0.0)),
				"stone_screen_x": float(final_status.get("stone_camera_x", 0.0)),
				"stone_x": stone.global_position.x,
				"lateral_delta": stone.global_position.x - start_position.x,
				"uphill_gain": start_position.z - stone.global_position.z,
				"velocity_side": stone.linear_velocity.dot(route_side),
				"contact_valid": frame != null and frame.contact_valid,
			})
	if final_status.is_empty():
		final_status = first_person_push_camera_status()
	_drive_lab_push(Vector3.ZERO, false, 1.0 / 60.0)
	var contact_side: float = float(final_status.get("contact_side_offset", 0.0))
	var force_side: float = float(final_status.get("force_side_component", 0.0))
	var lateral_delta: float = stone.global_position.x - start_position.x
	var stone_screen_x: float = float(final_status.get("stone_camera_x", 0.0))
	var polarity_consistent: bool = true
	if intended_side < 0:
		polarity_consistent = contact_side < -0.18 and force_side < -8.0 and lateral_delta < -0.06 and stone_screen_x > 0.08
	elif intended_side > 0:
		polarity_consistent = contact_side > 0.18 and force_side > 8.0 and lateral_delta > 0.06 and stone_screen_x < -0.08
	else:
		polarity_consistent = absf(contact_side) < 0.24 and absf(force_side) < 16.0 and absf(lateral_delta) < 0.22
	return {
		"label": label,
		"intended_side": intended_side,
		"polarity_consistent": polarity_consistent,
		"contact_side_offset": contact_side,
		"force_side_component": force_side,
		"lateral_delta": lateral_delta,
		"stone_screen_x": stone_screen_x,
		"uphill_gain": start_position.z - stone.global_position.z,
		"samples": samples,
	}


func _run_aim_control_trial(label: String, aim_bias: Vector3) -> Dictionary:
	var z: float = tuning.front_base_z - 5.5
	stone.freeze = false
	stone.sleeping = false
	stone.global_position = Vector3(0.0, mountain.height_at(z) + tuning.stone_radius + 0.10, z)
	stone.linear_velocity = Vector3.ZERO
	stone.angular_velocity = Vector3.ZERO
	var downhill: Vector3 = mountain.downhill_tangent_at(z)
	player.set_physics_process(false)
	player.global_position = stone.global_position + downhill * tuning.stone_radius * 1.55
	player.global_position.y = mountain.height_at(player.global_position.z) + 0.05
	player.push_contact_seconds = 0.0
	player.push_engaged = false
	_clear_player_brace()
	player.push_frame = null
	player.camera_push_blend = 1.0
	player.update_push_visual_mode()
	var start_position: Vector3 = stone.global_position
	var contact_frames: int = 0
	var frame_count: int = 90
	var max_spin_ratio: float = 0.0
	var contact_side_offset: float = 0.0
	var force_side_component: float = 0.0
	var quality_sum: float = 0.0
	var quality_samples: int = 0

	for index in frame_count:
		_drive_lab_push(aim_bias, true, 1.0 / 60.0)
		await get_tree().physics_frame
		var frame = _last_frame
		if frame != null and frame.contact_valid:
			contact_frames += 1
			var route_side: Vector3 = _route_side_at_stone()
			contact_side_offset = (frame.camera_contact_point - stone.global_position).dot(route_side)
			force_side_component = frame.contact_force.dot(route_side)
			max_spin_ratio = maxf(max_spin_ratio, frame.spin_to_translation_ratio)
			quality_sum += frame.contact_quality
			quality_samples += 1
		else:
			max_spin_ratio = maxf(max_spin_ratio, stone.angular_velocity.length() / maxf(stone.linear_velocity.length(), 0.05))

	_drive_lab_push(Vector3.ZERO, false, 1.0 / 60.0)
	var uphill_gain: float = start_position.z - stone.global_position.z
	var average_contact_quality: float = quality_sum / maxf(1.0, float(quality_samples))
	return {
		"label": label,
		"lateral_delta": stone.global_position.x - start_position.x,
		"uphill_gain": uphill_gain,
		"contact_ratio": float(contact_frames) / float(frame_count),
		"average_contact_quality": average_contact_quality,
		"max_spin_to_translation_ratio": max_spin_ratio,
		"contact_side_offset": contact_side_offset,
		"force_side_component": force_side_component,
		"start_position": start_position,
		"end_position": stone.global_position,
	}


func _save_labeled_observation(label: String, base_path: String) -> Dictionary:
	var evidence: Dictionary = save_observation_snapshot("%s-%s.png" % [base_path, label])
	evidence["label"] = label
	return evidence


func _snapshot_by_label(snapshots: Array, label: String) -> Dictionary:
	for entry in snapshots:
		if str(entry.get("label", "")) == label:
			return entry
	return {}


func _write_push_intent_diagnostic_report(path: String, result: Dictionary) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(_push_intent_diagnostic_report_text(result))
	file.close()
	return OK


func _push_intent_diagnostic_report_text(result: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("# Push Intent Diagnostic")
	lines.append("")
	lines.append("- **Purpose**: Short core-feel check for whether the player can intentionally choose hand contact and push direction.")
	lines.append("- **Verdict**: %s" % str(result.get("verdict", "PIVOT")))
	lines.append("- **Contact Delta**: %.2f" % float(result.get("contact_delta", 0.0)))
	lines.append("- **Force Delta**: %.2f" % float(result.get("force_delta", 0.0)))
	lines.append("- **Real Drift Gap**: %.2f" % float(result.get("drift_gap", 0.0)))
	lines.append("- **Left Route Visible**: %s" % ("Yes" if bool(result.get("left_route_visible", false)) else "No"))
	lines.append("- **Right Route Visible**: %s" % ("Yes" if bool(result.get("right_route_visible", false)) else "No"))
	lines.append("- **Look Down Readable**: %s" % ("Yes" if bool(result.get("look_down_readable", false)) else "No"))
	lines.append("- **Disengaged Cleanly**: %s" % ("Yes" if bool(result.get("disengaged_cleanly", false)) else "No"))
	lines.append("- **Hand Surface Clear**: %s" % ("Yes" if bool(result.get("hand_surface_clear", false)) else "No"))
	lines.append("")
	lines.append("## Snapshots")
	for entry in result.get("snapshots", []):
		lines.append("- **%s**: `%s`" % [str(entry.get("label", "")), str(entry.get("path", ""))])
	lines.append("")
	lines.append("## Aim Drill")
	var aim_drill: Dictionary = result.get("aim_drill", {})
	lines.append("- **Success**: %s" % ("Yes" if bool(aim_drill.get("success", false)) else "No"))
	lines.append("- **Status**: %s" % str(aim_drill.get("status", "")))
	lines.append("- **Drift Gap**: %.2f" % float(aim_drill.get("drift_gap", 0.0)))
	lines.append("")
	lines.append("## Angle Mastery Drill")
	var angle_mastery: Dictionary = result.get("angle_mastery", {})
	lines.append("- **Success**: %s" % ("Yes" if bool(angle_mastery.get("success", false)) else "No"))
	lines.append("- **Status**: %s" % str(angle_mastery.get("status", "")))
	lines.append("- **Sweet Spot Gain**: %.2f" % float(angle_mastery.get("center_gain", 0.0)))
	lines.append("- **Bad High-Side Gain**: %.2f" % float(angle_mastery.get("high_side_gain", 0.0)))
	lines.append("- **Bad High-Center Gain**: %.2f" % float(angle_mastery.get("high_center_gain", 0.0)))
	lines.append("- **Quality Gap**: %.2f -> %.2f / %.2f" % [
		float(angle_mastery.get("center_quality", 0.0)),
		float(angle_mastery.get("high_side_quality", 0.0)),
		float(angle_mastery.get("high_center_quality", 0.0)),
	])
	lines.append("")
	lines.append("## Aim Polarity Drill")
	var aim_polarity: Dictionary = result.get("aim_polarity", {})
	lines.append("- **Success**: %s" % ("Yes" if bool(aim_polarity.get("success", false)) else "No"))
	lines.append("- **Status**: %s" % str(aim_polarity.get("status", "")))
	lines.append("- **Drift Gap**: %.2f" % float(aim_polarity.get("drift_gap", 0.0)))
	for side_label in ["center", "left", "right"]:
		var side_result: Dictionary = aim_polarity.get(side_label, {})
		lines.append("- **%s**: contact %.2f, force %.2f, drift %.2f, screen stone x %.2f" % [
			side_label.capitalize(),
			float(side_result.get("contact_side_offset", 0.0)),
			float(side_result.get("force_side_component", 0.0)),
			float(side_result.get("lateral_delta", 0.0)),
			float(side_result.get("stone_screen_x", 0.0)),
		])
	lines.append("")
	lines.append("## Decision Use")
	lines.append("- `PROCEED`: use this as short evidence that the next representative human run is worth doing.")
	lines.append("- `PIVOT`: tune hand/contact/camera before spending time on a 5-10 minute representative playtest.")
	lines.append("- This diagnostic does not replace a filled `Human Feel Gate` report.")
	return "\n".join(lines) + "\n"


func _near_channel_front_obstacle(side_sign: float) -> Dictionary:
	var best: Dictionary = {}
	var best_inner_edge: float = INF
	for obstacle in mountain.obstacles:
		if signf(obstacle.position.x) != signf(side_sign):
			continue
		if obstacle.position.z < tuning.ridge_z + 4.0 or obstacle.position.z > tuning.front_base_z - 4.0:
			continue
		var inner_edge: float = absf(obstacle.position.x) - obstacle.radius * 0.78
		if inner_edge < best_inner_edge:
			best = obstacle
			best_inner_edge = inner_edge
	return best


func _route_side_at_stone() -> Vector3:
	var route_uphill: Vector3 = mountain.uphill_tangent_at(stone.global_position.z)
	var route_side := Vector3(-route_uphill.z, 0.0, route_uphill.x)
	if route_side.length_squared() < 0.001:
		return Vector3.RIGHT
	return route_side.normalized()


func _place_stone_for_obstacle_glance(obstacle: Dictionary) -> void:
	var side_sign: float = signf(obstacle.position.x)
	var collider_radius: float = obstacle.radius * 0.78
	var z: float = obstacle.position.z + 1.15
	var x: float = obstacle.position.x - side_sign * (tuning.stone_radius + collider_radius + 0.18)
	stone.freeze = false
	stone.sleeping = false
	stone.global_position = Vector3(x, mountain.height_at(z) + tuning.stone_radius + 0.08, z)
	stone.linear_velocity = Vector3.ZERO
	stone.angular_velocity = Vector3.ZERO
	var downhill: Vector3 = mountain.downhill_tangent_at(z)
	player.global_position = stone.global_position + downhill * tuning.stone_radius * 1.55
	player.global_position.y = mountain.height_at(player.global_position.z) + 0.05
	player.camera_yaw = 0.0
	player.camera_pitch = -0.06
	player.push_engaged = false
	player.push_frame = null
	player.push_contact_seconds = 0.0
	player.camera_push_blend = 0.0
	_clear_player_brace()


func _clear_player_brace() -> void:
	if player == null:
		return
	player.push_brace = 0.0
	player.push_aim_speed = 0.0
	player._previous_push_aim = Vector3.ZERO


func _update_lab_brace(
	camera_direction: Vector3,
	is_pushing: bool,
	lateral_axis: float,
	delta: float,
	camera_origin: Vector3
) -> void:
	var aim_speed: float = player.calculate_aim_speed(player._previous_push_aim, camera_direction, delta) if is_pushing else 0.0
	var target: float = 0.0
	if is_pushing:
		var preview = PushControllerScript.calculate_push_frame(
			stone.global_position,
			player.global_position,
			camera_direction,
			true,
			lateral_axis,
			tuning,
			mountain,
			player.push_contact_seconds,
			camera_origin,
			1.0
		)
		if preview.contact_valid:
			target = PushControllerScript.brace_target(preview.contact_quality, aim_speed, tuning)
	player.push_brace = PushControllerScript.update_brace(player.push_brace, target, is_pushing, delta, tuning)
	player.push_aim_speed = aim_speed
	player._previous_push_aim = camera_direction if is_pushing else Vector3.ZERO


func _drive_lab_push(aim_bias: Vector3, is_pushing: bool, delta: float) -> void:
	if is_pushing and stone.freeze:
		stone.freeze = false
		stone.sleeping = false
	var uphill: Vector3 = mountain.uphill_tangent_at(stone.global_position.z)
	var downhill: Vector3 = mountain.downhill_tangent_at(stone.global_position.z)
	player.global_position = stone.global_position + downhill * tuning.stone_radius * 1.55
	player.global_position.y = mountain.height_at(player.global_position.z) + 0.05
	if is_pushing:
		player.push_contact_seconds += delta
	else:
		player.push_contact_seconds = 0.0
	var camera_direction: Vector3 = (uphill + aim_bias).normalized()
	var camera_origin: Vector3 = _refined_reticle_camera_origin(
		camera_direction,
		is_pushing,
		aim_bias.x,
		player.push_contact_seconds,
		player.camera_push_blend
	)
	_update_lab_brace(camera_direction, is_pushing, aim_bias.x, delta, camera_origin)
	var frame = PushControllerScript.apply_push(
		stone,
		player.global_position,
		camera_direction,
		is_pushing,
		aim_bias.x,
		tuning,
		mountain,
		player.push_contact_seconds,
		camera_origin,
		player.push_brace
	)
	frame.aim_stability = PushControllerScript.aim_stability(player.push_aim_speed, tuning)
	_last_frame = frame
	player.push_frame = frame
	player.push_engaged = is_pushing and frame.contact_valid
	player._near_stone = player.global_position.distance_to(stone.global_position) <= tuning.contact_distance + 0.55
	player._is_walking = is_pushing
	player.camera_push_blend = player.calculate_camera_blend(player.camera_push_blend, player.push_engaged, delta, tuning)
	if player.push_engaged:
		player.camera_push_blend = maxf(player.camera_push_blend, 0.96)
	player.update_push_visual_mode()
	_position_lab_camera(frame.aim_direction, frame.camera_contact_point, player.camera_push_blend)
	player._update_arm_visual(delta, frame.aim_direction)
	player._update_first_person_hands(frame.aim_direction)
	_update_debug_overlay()
	_update_hud()


func _sample_bias_route_metrics(obstacle: Dictionary, already_touched: bool) -> Dictionary:
	var air_gap: float = stone.global_position.y - (mountain.height_at(stone.global_position.z) + tuning.stone_radius)
	var obstacle_distance: float = Vector2(
		stone.global_position.x - obstacle.position.x,
		stone.global_position.z - obstacle.position.z
	).length()
	var touched: bool = already_touched or obstacle_distance <= tuning.stone_radius + obstacle.radius * 0.88
	var spin_ratio: float = stone.angular_velocity.length() / maxf(stone.linear_velocity.length(), 0.05)
	if _last_frame != null and _last_frame.spin_to_translation_ratio > 0.0:
		spin_ratio = _last_frame.spin_to_translation_ratio
	return {
		"air_gap": air_gap,
		"touched": touched,
		"spin_ratio": spin_ratio,
	}


func _save_observation_png(path: String) -> Error:
	if DisplayServer.get_name() == "headless":
		return _save_headless_observation_placeholder(path)
	var texture: ViewportTexture = get_viewport().get_texture()
	if texture == null:
		return _save_headless_observation_placeholder(path)
	var image: Image = texture.get_image()
	if image == null or image.get_width() <= 0 or image.get_height() <= 0:
		return _save_headless_observation_placeholder(path)
	return image.save_png(path)


func _save_headless_observation_placeholder(path: String) -> Error:
	var status: Dictionary = first_person_push_camera_status()
	var width := 640
	var height := 360
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.08, 0.10, 0.10, 1.0))
	var center := Vector2i(width / 2, height / 2)
	var stone_screen := _headless_camera_space_to_screen(
		float(status.get("stone_camera_x", 0.0)),
		float(status.get("stone_camera_y", 0.0)),
		float(status.get("stone_camera_depth", 2.0)),
		center
	)
	var contact_screen := _headless_camera_space_to_screen(
		float(status.get("contact_camera_x", 0.0)),
		float(status.get("contact_camera_y", 0.0)),
		float(status.get("contact_camera_depth", 2.0)),
		center
	)
	var left_hand_screen := _headless_camera_space_to_screen(
		float(status.get("left_hand_camera_x", -0.45)),
		float(status.get("left_hand_camera_y", -0.40)),
		float(status.get("left_hand_camera_depth", 1.6)),
		center
	)
	var right_hand_screen := _headless_camera_space_to_screen(
		float(status.get("right_hand_camera_x", 0.45)),
		float(status.get("right_hand_camera_y", -0.40)),
		float(status.get("right_hand_camera_depth", 1.6)),
		center
	)
	var left_forearm_screen := _headless_camera_space_to_screen(
		float(status.get("left_forearm_camera_x", -0.45)),
		float(status.get("left_forearm_camera_y", -0.70)),
		float(status.get("left_hand_camera_depth", 1.6)),
		center
	)
	var right_forearm_screen := _headless_camera_space_to_screen(
		float(status.get("right_forearm_camera_x", 0.45)),
		float(status.get("right_forearm_camera_y", -0.70)),
		float(status.get("right_hand_camera_depth", 1.6)),
		center
	)
	_draw_route_hint(image, center, status)
	_draw_filled_circle(image, stone_screen, 82, Color(0.18, 0.20, 0.17, 1.0))
	_draw_filled_circle(image, stone_screen, 78, Color(0.29, 0.33, 0.27, 1.0))
	_draw_line(image, left_forearm_screen, left_hand_screen, 20, Color(0.16, 0.20, 0.18, 1.0))
	_draw_line(image, right_forearm_screen, right_hand_screen, 20, Color(0.16, 0.20, 0.18, 1.0))
	_draw_filled_circle(image, left_hand_screen, 24, Color(0.36, 0.33, 0.27, 1.0))
	_draw_filled_circle(image, right_hand_screen, 24, Color(0.36, 0.33, 0.27, 1.0))
	_draw_filled_circle(image, contact_screen, 9, Color(0.43, 0.35, 0.22, 0.88))
	var force_side: float = clampf(float(status.get("force_side_component", 0.0)) / 70.0, -1.0, 1.0)
	var force_end := contact_screen + Vector2i(int(force_side * 34.0), -26)
	_draw_line(image, contact_screen, force_end, 5, Color(0.38, 0.31, 0.20, 0.82))
	for x in range(0, width):
		image.set_pixel(x, 0, Color.WHITE)
		image.set_pixel(x, height - 1, Color.WHITE)
	for y in range(0, height):
		image.set_pixel(0, y, Color.WHITE)
		image.set_pixel(width - 1, y, Color.WHITE)
	return image.save_png(path)


func _headless_camera_space_to_screen(local_x: float, local_y: float, depth: float, center: Vector2i) -> Vector2i:
	var safe_depth: float = maxf(0.35, depth)
	var x_ratio: float = clampf(local_x / safe_depth, -1.22, 1.22)
	var y_ratio: float = clampf(local_y / safe_depth, -0.86, 0.86)
	return Vector2i(
		center.x + int(x_ratio * 185.0),
		center.y - int(y_ratio * 132.0)
	)


func _draw_route_hint(image: Image, center: Vector2i, status: Dictionary) -> void:
	if int(status.get("visible_left_route_markers", 0)) > 0:
		_draw_rect(image, Rect2i(center.x - 250, center.y + 108, 84, 7), Color(0.32, 0.42, 0.30, 1.0))
	if int(status.get("visible_right_route_markers", 0)) > 0:
		_draw_rect(image, Rect2i(center.x + 166, center.y + 108, 84, 7), Color(0.32, 0.42, 0.30, 1.0))


func _draw_filled_circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	var radius_squared := radius * radius
	for y in range(maxi(0, center.y - radius), mini(image.get_height(), center.y + radius + 1)):
		for x in range(maxi(0, center.x - radius), mini(image.get_width(), center.x + radius + 1)):
			var dx := x - center.x
			var dy := y - center.y
			if dx * dx + dy * dy <= radius_squared:
				image.set_pixel(x, y, color)


func _draw_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var x_start: int = maxi(0, rect.position.x)
	var y_start: int = maxi(0, rect.position.y)
	var x_end: int = mini(image.get_width(), rect.position.x + rect.size.x)
	var y_end: int = mini(image.get_height(), rect.position.y + rect.size.y)
	for y in range(y_start, y_end):
		for x in range(x_start, x_end):
			image.set_pixel(x, y, color)


func _draw_line(image: Image, start: Vector2i, end: Vector2i, thickness: int, color: Color) -> void:
	var delta: Vector2 = Vector2(end - start)
	var steps: int = maxi(1, int(delta.length()))
	for index in range(steps + 1):
		var t: float = float(index) / float(steps)
		var point := Vector2(start).lerp(Vector2(end), t)
		_draw_filled_circle(image, Vector2i(int(point.x), int(point.y)), maxi(1, thickness / 2), color)


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lab-preset="):
			active_preset = arg.trim_prefix("--lab-preset=")
		elif arg.begins_with("--lab-auto="):
			_auto_mode = arg.trim_prefix("--lab-auto=")
		elif arg == "--lab-debug":
			_auto_debug = true


func _apply_auto_mode(delta: float) -> void:
	_auto_frame += 1
	var uphill: Vector3 = mountain.uphill_tangent_at(stone.global_position.z)
	var downhill: Vector3 = mountain.downhill_tangent_at(stone.global_position.z)
	var player_distance: float = tuning.stone_radius * 1.65
	var is_pushing: bool = false
	var aim_bias: Vector3 = Vector3.ZERO
	match _auto_mode:
		"approach":
			player_distance = tuning.stone_radius * 2.45
		"left":
			is_pushing = true
			aim_bias = Vector3.LEFT * 0.9
		"right":
			is_pushing = true
			aim_bias = Vector3.RIGHT * 0.9
		"release":
			is_pushing = _auto_frame < 95
		_:
			is_pushing = true

	if is_pushing and stone.freeze:
		stone.freeze = false
		stone.sleeping = false
	if is_pushing:
		player.push_contact_seconds += delta
	else:
		player.push_contact_seconds = 0.0
	player.global_position = stone.global_position + downhill * player_distance
	player.global_position.y = mountain.height_at(player.global_position.z) + 0.05
	var reach_target: float = player.calculate_stone_reach_target(player.global_position.distance_to(stone.global_position), is_pushing, tuning)
	player._stone_reach_blend = player.calculate_reach_blend(player._stone_reach_blend, reach_target, delta, tuning)
	var camera_direction: Vector3 = (uphill + aim_bias).normalized()
	var camera_origin: Vector3 = _refined_reticle_camera_origin(camera_direction, is_pushing, aim_bias.x, player.push_contact_seconds, player.camera_push_blend)
	_update_lab_brace(camera_direction, is_pushing, aim_bias.x, delta, camera_origin)
	var frame = PushControllerScript.apply_push(
		stone,
		player.global_position,
		camera_direction,
		is_pushing,
		aim_bias.x,
		tuning,
		mountain,
		player.push_contact_seconds,
		camera_origin,
		player.push_brace
	)
	frame.aim_stability = PushControllerScript.aim_stability(player.push_aim_speed, tuning)
	_last_frame = frame
	player.push_frame = frame
	player.push_engaged = is_pushing
	player._near_stone = player.global_position.distance_to(stone.global_position) <= tuning.contact_distance + 0.55
	player._is_walking = is_pushing
	player.camera_push_blend = player.calculate_camera_blend(player.camera_push_blend, is_pushing, delta, tuning)
	if is_pushing:
		player.camera_push_blend = maxf(player.camera_push_blend, 0.96)
	player.update_push_visual_mode()
	_position_lab_camera(frame.aim_direction, frame.camera_contact_point, player.camera_push_blend)
	player._update_arm_visual(delta, frame.aim_direction)
	player._update_first_person_hands(frame.aim_direction)


func _position_lab_camera(camera_direction: Vector3, target: Vector3, push_blend: float) -> void:
	if camera == null:
		return
	camera.global_position = _push_camera_origin_for(camera_direction, target, push_blend)
	var effective_push_blend: float = smoothstep(0.0, 1.0, push_blend)
	camera.fov = lerpf(tuning.normal_camera_fov, tuning.push_camera_fov, effective_push_blend)
	var shoulder_target: Vector3 = stone.global_position + Vector3.UP * 0.75
	var aim_direction: Vector3 = camera_direction.normalized()
	if aim_direction.length_squared() < 0.001:
		aim_direction = mountain.uphill_tangent_at(stone.global_position.z)
	var pressure_target: Vector3 = target if effective_push_blend > 0.0 else camera.global_position + aim_direction * 6.0
	_last_camera_target = shoulder_target.lerp(pressure_target, effective_push_blend)
	camera.look_at(_last_camera_target, Vector3.UP)


func _refined_reticle_camera_origin(
	camera_direction: Vector3,
	is_pushing: bool,
	lateral_axis: float,
	push_hold_seconds: float,
	push_blend: float
) -> Vector3:
	var origin: Vector3 = _body_push_camera_origin_for(camera_direction, push_blend)
	for index in 2:
		var frame = PushControllerScript.calculate_push_frame(
			stone.global_position,
			player.global_position,
			camera_direction,
			is_pushing,
			lateral_axis,
			tuning,
			mountain,
			push_hold_seconds,
			origin
		)
		origin = _push_camera_origin_for(camera_direction, frame.camera_contact_point, push_blend)
	return origin


func _push_camera_origin_for(camera_direction: Vector3, target: Vector3, push_blend: float) -> Vector3:
	var forward: Vector3 = Vector3(camera_direction.x, 0.0, camera_direction.z).normalized()
	if forward.length_squared() < 0.001:
		forward = Vector3(0.0, 0.0, -1.0)
	var right: Vector3 = Vector3(-forward.z, 0.0, forward.x).normalized()
	var route_uphill: Vector3 = mountain.uphill_tangent_at(stone.global_position.z) if mountain != null and stone != null else forward
	var route_side: Vector3 = Vector3(-route_uphill.z, 0.0, route_uphill.x)
	if route_side.length_squared() < 0.001:
		route_side = right
	else:
		route_side = route_side.normalized()
	var bias_strength: float = 0.0
	var aim_direction: Vector3 = camera_direction.normalized()
	if aim_direction.length_squared() > 0.001:
		bias_strength = clampf(absf(aim_direction.dot(route_side)) * 1.15, 0.0, 1.0)
	var push_forward_distance: float = lerpf(tuning.push_camera_distance, tuning.push_camera_bias_back_distance, bias_strength)
	var push_height: float = tuning.push_camera_height + bias_strength * 0.10
	var shoulder_position: Vector3 = player.global_position - forward * tuning.shoulder_distance + right * tuning.shoulder_side_offset + Vector3.UP * tuning.shoulder_height
	var push_position: Vector3 = player.global_position + forward * push_forward_distance + right * tuning.push_camera_side_offset + Vector3.UP * push_height
	var contact_origin: Vector3 = target - aim_direction * tuning.push_camera_contact_distance
	push_position = push_position.lerp(contact_origin, clampf(tuning.push_camera_contact_origin_strength, 0.0, 1.0))
	var effective_push_blend: float = smoothstep(0.0, 1.0, push_blend)
	return shoulder_position.lerp(push_position, effective_push_blend)


func _body_push_camera_origin_for(camera_direction: Vector3, push_blend: float) -> Vector3:
	var forward: Vector3 = Vector3(camera_direction.x, 0.0, camera_direction.z).normalized()
	if forward.length_squared() < 0.001:
		forward = Vector3(0.0, 0.0, -1.0)
	var right: Vector3 = Vector3(-forward.z, 0.0, forward.x).normalized()
	var route_uphill: Vector3 = mountain.uphill_tangent_at(stone.global_position.z) if mountain != null and stone != null else forward
	var route_side: Vector3 = Vector3(-route_uphill.z, 0.0, route_uphill.x)
	if route_side.length_squared() < 0.001:
		route_side = right
	else:
		route_side = route_side.normalized()
	var bias_strength: float = 0.0
	var aim_direction: Vector3 = camera_direction.normalized()
	if aim_direction.length_squared() > 0.001:
		bias_strength = clampf(absf(aim_direction.dot(route_side)) * 1.15, 0.0, 1.0)
	var push_forward_distance: float = lerpf(tuning.push_camera_distance, tuning.push_camera_bias_back_distance, bias_strength)
	var push_height: float = tuning.push_camera_height + bias_strength * 0.10
	var shoulder_position: Vector3 = player.global_position - forward * tuning.shoulder_distance + right * tuning.shoulder_side_offset + Vector3.UP * tuning.shoulder_height
	var push_position: Vector3 = player.global_position + forward * push_forward_distance + right * tuning.push_camera_side_offset + Vector3.UP * push_height
	var effective_push_blend: float = smoothstep(0.0, 1.0, push_blend)
	return shoulder_position.lerp(push_position, effective_push_blend)


func _update_debug_overlay() -> void:
	var frame = player.push_frame if player.push_frame != null else _last_frame
	if _debug_overlay == null or frame == null:
		return
	_debug_overlay.update_debug(stone.global_position, frame, mountain.uphill_tangent_at(stone.global_position.z))


func _update_hud() -> void:
	var frame = player.push_frame if player.push_frame != null else _last_frame
	var force_uphill: float = 0.0
	var gravity_downhill: float = 0.0
	var spin_ratio: float = stone.angular_velocity.length() / maxf(stone.linear_velocity.length(), 0.05)
	var contact_valid: bool = false
	var contact_quality: float = 0.0
	var effort_recoil: float = 0.0
	var brace_amount: float = player.push_brace if player != null else 0.0
	var breakaway_ratio: float = 0.0
	var aim_side: float = 0.0
	if frame != null:
		force_uphill = frame.force_uphill_component
		gravity_downhill = frame.gravity_downhill_component
		spin_ratio = frame.spin_to_translation_ratio if frame.spin_to_translation_ratio > 0.0 else spin_ratio
		contact_valid = frame.contact_valid
		contact_quality = frame.contact_quality
		effort_recoil = frame.burden_recoil
		breakaway_ratio = frame.breakaway_ratio
		if mountain != null and stone != null:
			var route_uphill: Vector3 = mountain.uphill_tangent_at(stone.global_position.z)
			var route_side: Vector3 = Vector3(-route_uphill.z, 0.0, route_uphill.x).normalized()
			aim_side = (frame.camera_contact_point - stone.global_position).dot(route_side)
	var uphill_velocity: float = _stone_uphill_velocity()
	var aim_label: String = "C"
	if aim_side < -0.12:
		aim_label = "L"
	elif aim_side > 0.12:
		aim_label = "R"
	var route_status: Dictionary = route_progress_status()
	status_label.text = (
		"Preset: %s (%s) | State %s | Aim %s | Contact %s\n"
		+ "Angle %.0f%% | Brace %.0f%% | Effort %.0f%% | Breakaway %.2f\n"
		+ "Ridge %.1fm | Progress %.0f%%\n"
		+ "Push %.0f / Gravity %.0f | Uphill %.2f | Speed %.2f | Angular %.2f | Spin %.2f"
	) % [
		active_preset,
		TuningScript.push_lab_preset_label(active_preset),
		push_motion_state(frame),
		aim_label,
		"yes" if contact_valid else "no",
		contact_quality * 100.0,
		brace_amount * 100.0,
		effort_recoil * 100.0,
		breakaway_ratio,
		float(route_status.get("distance_to_ridge", 0.0)),
		float(route_status.get("ascent_progress", 0.0)) * 100.0,
		force_uphill,
		gravity_downhill,
		uphill_velocity,
		stone.linear_velocity.length(),
		stone.angular_velocity.length(),
		spin_ratio,
	]
	if _debug_visible:
		status_label.text += " | DEBUG VECTORS"
	controls_label.text = "LT/RT push each hand | mouse L/R = full fallback | S disengage | A/D footwork only | mouse/right stick look\nRidge posts mark the end of the climb. 1 heavy  2 standard  3 light  R reset  F3 debug-only colored vectors."


func _stone_uphill_velocity() -> float:
	if stone == null or mountain == null:
		return 0.0
	return stone.linear_velocity.dot(mountain.uphill_tangent_at(stone.global_position.z))
