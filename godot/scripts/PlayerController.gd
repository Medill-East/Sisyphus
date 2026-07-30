class_name PlayerController
extends CharacterBody3D

class ArmPose:
	var swing: float
	var reach: float
	var contact_offset: Vector3

	func _init(next_swing: float, next_reach: float, next_contact_offset: Vector3) -> void:
		swing = next_swing
		reach = next_reach
		contact_offset = next_contact_offset


class ArmRigPose:
	var swing: float
	var reach: float
	var active_hand: String
	var left_shoulder: Vector3
	var left_elbow: Vector3
	var left_hand: Vector3
	var right_shoulder: Vector3
	var right_elbow: Vector3
	var right_hand: Vector3

	func _init(
		next_swing: float,
		next_reach: float,
		next_active_hand: String,
		next_left_shoulder: Vector3,
		next_left_elbow: Vector3,
		next_left_hand: Vector3,
		next_right_shoulder: Vector3,
		next_right_elbow: Vector3,
		next_right_hand: Vector3
	) -> void:
		swing = next_swing
		reach = next_reach
		active_hand = next_active_hand
		left_shoulder = next_left_shoulder
		left_elbow = next_left_elbow
		left_hand = next_left_hand
		right_shoulder = next_right_shoulder
		right_elbow = next_right_elbow
		right_hand = next_right_hand

const TuningScript = preload("res://scripts/Tuning.gd")
const PushControllerScript = preload("res://scripts/PushController.gd")
const GameStateScript = preload("res://scripts/GameState.gd")

var tuning = TuningScript.new()
var mountain
var game_state
var stone: RigidBody3D
var camera: Camera3D
var camera_yaw: float = 0.0
var camera_pitch: float = -0.08
var push_frame

@onready var _body: Node3D = $Body
@onready var _left_arm: Node3D = $Body/LeftArm
@onready var _right_arm: Node3D = $Body/RightArm
@onready var _left_upper: MeshInstance3D = $Body/LeftArm/UpperArm
@onready var _left_forearm: MeshInstance3D = $Body/LeftArm/Forearm
@onready var _left_hand: MeshInstance3D = $Body/LeftArm/Hand
@onready var _right_upper: MeshInstance3D = $Body/RightArm/UpperArm
@onready var _right_forearm: MeshInstance3D = $Body/RightArm/Forearm
@onready var _right_hand: MeshInstance3D = $Body/RightArm/Hand
@onready var _first_person_hands: Node3D = $FirstPersonHands
@onready var _contact_cue: Node3D = $ContactCue
@onready var _left_scrape_audio: AudioStreamPlayer3D = $LeftScrapeAudio
@onready var _right_scrape_audio: AudioStreamPlayer3D = $RightScrapeAudio

var _walk_time: float = 0.0
var _is_walking: bool = false
var _near_stone: bool = false
var _stone_reach_blend: float = 0.0
var _push_contact_offset: Vector3 = Vector3.ZERO
var push_engaged: bool = false
var camera_push_blend: float = 0.0
var push_contact_seconds: float = 0.0
var push_brace: float = 0.0
var push_aim_speed: float = 0.0
var _previous_push_aim: Vector3 = Vector3.ZERO
var push_left_strength: float = 0.0
var push_right_strength: float = 0.0
var left_haptic_level: float = 0.0
var right_haptic_level: float = 0.0

const SCRAPE_SAMPLE_RATE := 11025
const SCRAPE_SAMPLE_COUNT := 2048


static func calculate_arm_pose(time: float, is_walking: bool, near_stone: bool, aim_direction: Vector3, tuning) -> ArmPose:
	var swing := 0.0
	if is_walking:
		swing = sin(time * 6.2) * 0.32
	var reach := 1.0 if near_stone else 0.0
	var aim := aim_direction.normalized() if aim_direction.length_squared() > 0.001 else Vector3(0, 0, -1)
	var offset := Vector3(
		clampf(aim.x, -0.85, 0.85) * tuning.stone_radius * 0.58,
		maxf(0.0, clampf(aim.y + 0.1, 0.0, 0.85)) * tuning.stone_radius * 0.45,
		-tuning.stone_radius * 0.5
	) * reach
	return ArmPose.new(swing, reach, offset)


static func should_engage_push(
	currently_engaged: bool,
	wants_push: bool,
	wants_back: bool,
	player_position: Vector3,
	stone_position: Vector3,
	uphill_direction: Vector3,
	tuning
) -> bool:
	if wants_back or not wants_push:
		return false
	var to_player: Vector3 = player_position - stone_position
	var distance_limit: float = tuning.push_disengage_distance if currently_engaged else tuning.contact_distance + 0.55
	if to_player.length() > distance_limit:
		return false
	var downhill: Vector3 = -uphill_direction.normalized()
	if to_player.length_squared() < 0.001:
		return false
	return to_player.normalized().dot(downhill) >= tuning.rear_contact_dot_min


static func calculate_camera_blend(current_blend: float, is_push_engaged: bool, delta: float, tuning) -> float:
	var target: float = 1.0 if is_push_engaged else 0.0
	var blend_speed: float = tuning.camera_blend_speed if is_push_engaged else maxf(tuning.camera_blend_speed, 2.65)
	var weight: float = 1.0 - exp(-blend_speed * delta)
	return clampf(lerpf(current_blend, target, weight), 0.0, 1.0)


static func calculate_stone_reach_target(distance_to_stone: float, is_push_engaged: bool, tuning) -> float:
	if is_push_engaged:
		return 1.0
	var start_distance: float = tuning.contact_distance + tuning.approach_hand_start_margin
	var full_distance: float = tuning.contact_distance - tuning.approach_hand_full_margin
	var raw: float = clampf(
		(start_distance - distance_to_stone) / maxf(0.001, start_distance - full_distance),
		0.0,
		1.0
	)
	return smoothstep(0.0, 1.0, raw)


static func calculate_reach_blend(current_blend: float, target_blend: float, delta: float, tuning) -> float:
	var speed: float = maxf(0.1, tuning.approach_hand_follow_speed)
	var weight: float = 1.0 - exp(-speed * delta)
	return clampf(lerpf(current_blend, clampf(target_blend, 0.0, 1.0), weight), 0.0, 1.0)


static func shape_body_move_input(raw_input: Vector3, preserve_strength: bool) -> Vector3:
	if raw_input.length_squared() <= 0.001:
		return Vector3.ZERO
	if preserve_strength:
		return raw_input.limit_length(1.0)
	return raw_input.normalized()


static func calculate_aim_speed(previous: Vector3, current: Vector3, delta: float) -> float:
	if previous.length_squared() < 0.001 or current.length_squared() < 0.001 or delta <= 0.0:
		return 0.0
	var alignment: float = clampf(previous.normalized().dot(current.normalized()), -1.0, 1.0)
	return acos(alignment) / delta


static func calculate_two_segment_arm_pose(
	time: float,
	is_walking: bool,
	reach_input: Variant,
	is_push_engaged: bool,
	left_contact_target: Vector3,
	right_contact_target: Vector3,
	aim_direction: Vector3,
	tuning
) -> ArmRigPose:
	var swing := 0.0
	if is_walking:
		swing = sin(time * 6.2) * 0.08
	var reach: float = 0.0
	if reach_input is bool:
		reach = 1.0 if bool(reach_input) else 0.0
	else:
		reach = clampf(float(reach_input), 0.0, 1.0)
	var active_hand: String = "right" if sin(time * TAU * tuning.push_hand_cycle_hz) >= 0.0 else "left"
	if not is_push_engaged:
		active_hand = "none"

	var left_shoulder := Vector3(-0.28, 0.95, 0.0)
	var right_shoulder := Vector3(0.28, 0.95, 0.0)
	var left_idle := Vector3(-0.34, 0.56, swing)
	var right_idle := Vector3(0.34, 0.56, -swing)
	var aim := aim_direction.normalized() if aim_direction.length_squared() > 0.001 else Vector3(0.0, 0.0, -1.0)
	var active_nudge: Vector3 = aim * 0.08
	var left_target: Vector3 = left_idle.lerp(left_contact_target, reach)
	var right_target: Vector3 = right_idle.lerp(right_contact_target, reach)
	if active_hand == "left":
		left_target += active_nudge
	elif active_hand == "right":
		right_target += active_nudge

	var left_chain: Array[Vector3] = _solve_arm_chain(left_shoulder, left_target, -1.0, tuning)
	var right_chain: Array[Vector3] = _solve_arm_chain(right_shoulder, right_target, 1.0, tuning)
	return ArmRigPose.new(
		swing,
		reach,
		active_hand,
		left_shoulder,
		left_chain[0],
		left_chain[1],
		right_shoulder,
		right_chain[0],
		right_chain[1]
	)


static func _solve_arm_chain(shoulder: Vector3, desired_hand: Vector3, side_sign: float, tuning) -> Array[Vector3]:
	var to_hand: Vector3 = desired_hand - shoulder
	if to_hand.length_squared() < 0.001:
		to_hand = Vector3(side_sign * 0.05, -1.0, 0.0)
	var direction: Vector3 = to_hand.normalized()
	var max_reach: float = tuning.arm_upper_length + tuning.arm_forearm_length - 0.03
	var hand: Vector3 = shoulder + direction * minf(to_hand.length(), max_reach)
	var elbow: Vector3 = shoulder + direction * minf(tuning.arm_upper_length, shoulder.distance_to(hand) * 0.52)
	elbow += Vector3(side_sign * 0.08, -0.03, 0.03)
	if shoulder.distance_to(elbow) > tuning.arm_upper_length:
		elbow = shoulder + (elbow - shoulder).normalized() * tuning.arm_upper_length
	if elbow.distance_to(hand) > tuning.arm_forearm_length:
		hand = elbow + (hand - elbow).normalized() * tuning.arm_forearm_length
	return [elbow, hand]


func _ready() -> void:
	var scrape_stream: AudioStreamWAV = _build_scrape_stream()
	_left_scrape_audio.stream = scrape_stream
	_right_scrape_audio.stream = scrape_stream
	_left_scrape_audio.play()
	_right_scrape_audio.play()
	apply_per_hand_feedback_levels(0.0, 0.0)


func setup(next_tuning, next_mountain, next_state, next_stone: RigidBody3D, next_camera: Camera3D) -> void:
	tuning = next_tuning
	mountain = next_mountain
	game_state = next_state
	stone = next_stone
	camera = next_camera
	update_push_visual_mode()


func _build_scrape_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	var pcm := PackedByteArray()
	pcm.resize(SCRAPE_SAMPLE_COUNT * 2)
	for index in SCRAPE_SAMPLE_COUNT:
		var grain: float = sin(float(index) * 0.73) * 0.55
		grain += sin(float(index) * 1.91) * 0.30
		grain += sin(float(index) * 0.17) * 0.15
		pcm.encode_s16(index * 2, int(clampf(grain, -1.0, 1.0) * 5200.0))
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SCRAPE_SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = SCRAPE_SAMPLE_COUNT
	stream.data = pcm
	return stream


func apply_per_hand_feedback_levels(left_level: float, right_level: float) -> void:
	left_haptic_level = clampf(left_level, 0.0, 1.0)
	right_haptic_level = clampf(right_level, 0.0, 1.0)
	if _left_scrape_audio != null:
		_left_scrape_audio.volume_db = lerpf(-60.0, -12.0, left_haptic_level)
	if _right_scrape_audio != null:
		_right_scrape_audio.volume_db = lerpf(-60.0, -12.0, right_haptic_level)
	if not Input.get_connected_joypads().is_empty():
		Input.start_joy_vibration(0, left_haptic_level, right_haptic_level, 0.08)


func _update_per_hand_feedback() -> void:
	var left_level: float = 0.0
	var right_level: float = 0.0
	if push_frame != null and push_frame.contact_valid:
		left_level = push_frame.left_scrape_level
		right_level = push_frame.right_scrape_level
	apply_per_hand_feedback_levels(left_level, right_level)
	if _first_person_hands != null and _first_person_hands.has_method("set_hand_loads"):
		_first_person_hands.call(
			"set_hand_loads",
			push_frame.left_load if push_frame != null and push_frame.contact_valid else 0.0,
			push_frame.right_load if push_frame != null and push_frame.contact_valid else 0.0
		)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event is InputEventMouseMotion:
		apply_look_delta(event.relative)


func apply_look_delta(relative: Vector2) -> void:
	camera_yaw += relative.x * tuning.mouse_sensitivity
	var min_pitch: float = -tuning.push_look_down_limit if push_engaged or camera_push_blend > 0.12 else -0.42
	var max_pitch: float = tuning.push_look_up_limit if push_engaged or camera_push_blend > 0.12 else 0.36
	camera_pitch = clampf(camera_pitch - relative.y * tuning.mouse_sensitivity, min_pitch, max_pitch)


func _physics_process(delta: float) -> void:
	if mountain == null or game_state == null:
		return

	if game_state.phase == GameStateScript.Phase.COMPLETE:
		_hold_complete_pose(delta)
		return

	_handle_keyboard_look(delta)
	var stone_position: Vector3 = stone.global_position if stone != null else global_position + Vector3(0, 0, -2)
	var stone_distance: float = global_position.distance_to(stone_position)
	_near_stone = stone_distance <= tuning.contact_distance + 0.55
	var pushing_phase: bool = game_state.phase == GameStateScript.Phase.ASCENT
	push_left_strength = Input.get_action_strength("push_left")
	push_right_strength = Input.get_action_strength("push_right")
	var wants_push: bool = maxf(push_left_strength, push_right_strength) > 0.001
	var wants_back: bool = Input.is_action_pressed("move_backward")

	if pushing_phase and stone != null:
		push_engaged = should_engage_push(
			push_engaged,
			wants_push,
			wants_back,
			global_position,
			stone_position,
			mountain.uphill_tangent_at(stone_position.z),
			tuning
		)
	else:
		push_engaged = false
	var push_input: bool = push_engaged and wants_push and pushing_phase
	if push_input:
		push_contact_seconds += delta
	else:
		push_contact_seconds = 0.0
	var reach_target: float = calculate_stone_reach_target(stone_distance, push_engaged, tuning) if stone != null else 0.0
	_stone_reach_blend = calculate_reach_blend(_stone_reach_blend, reach_target, delta, tuning)

	if push_engaged:
		_constrain_push_look(stone_position)
	var camera_direction: Vector3 = _camera_forward()
	push_aim_speed = 0.0
	var brace_target_value: float = 0.0
	if push_input and stone != null:
		var brace_preview = calculate_two_hand_push_frame(
			camera_direction,
			push_left_strength,
			push_right_strength,
			push_contact_seconds,
			1.0
		)
		if brace_preview != null and brace_preview.contact_valid:
			brace_target_value = PushControllerScript.brace_target(brace_preview.contact_quality, 0.0, tuning)
	push_brace = PushControllerScript.update_brace(push_brace, brace_target_value, push_input, delta, tuning)
	_previous_push_aim = Vector3.ZERO
	var camera_should_close: bool = push_engaged and push_contact_seconds >= tuning.push_camera_entry_min_contact_seconds
	camera_push_blend = calculate_camera_blend(camera_push_blend, camera_should_close, delta, tuning)

	_move(delta, push_input, pushing_phase, push_engaged)

	if stone != null and pushing_phase:
		if push_input and stone.freeze:
			stone.freeze = false
			stone.sleeping = false
		push_frame = apply_two_hand_push(
			camera_direction,
			push_left_strength if push_input else 0.0,
			push_right_strength if push_input else 0.0,
			push_contact_seconds,
			push_brace
		)
		push_frame.aim_stability = 1.0
		if not push_frame.contact_valid:
			push_contact_seconds = 0.0
			push_brace = PushControllerScript.update_brace(push_brace, 0.0, push_input, delta, tuning)
		_push_contact_offset = push_frame.camera_contact_point - stone.global_position

	var visual_camera_direction: Vector3 = camera_direction
	_update_arm_visual(delta, visual_camera_direction)
	_update_camera(delta, stone_position, visual_camera_direction, push_engaged)
	_update_first_person_hands(visual_camera_direction)
	_update_per_hand_feedback()


func _hold_complete_pose(delta: float) -> void:
	push_engaged = false
	push_frame = null
	push_contact_seconds = 0.0
	push_brace = 0.0
	push_aim_speed = 0.0
	_previous_push_aim = Vector3.ZERO
	_is_walking = false
	velocity = Vector3.ZERO
	camera_push_blend = calculate_camera_blend(camera_push_blend, false, delta, tuning)
	var camera_direction: Vector3 = _camera_forward()
	_update_arm_visual(delta, camera_direction)
	if stone != null:
		_update_camera(delta, stone.global_position, camera_direction, false)
	_update_first_person_hands(camera_direction)
	_update_per_hand_feedback()


func _move(delta: float, push_input: bool, pushing_phase: bool, is_push_engaged: bool) -> void:
	var forward: Vector3 = Vector3(sin(camera_yaw), 0, -cos(camera_yaw)).normalized()
	var right: Vector3 = Vector3(cos(camera_yaw), 0, sin(camera_yaw)).normalized()
	var input: Vector3 = Vector3.ZERO
	var preserve_input_strength: bool = false
	if pushing_phase and is_push_engaged:
		preserve_input_strength = true
		var uphill: Vector3 = mountain.uphill_tangent_at(global_position.z)
		forward = Vector3(uphill.x, 0.0, uphill.z).normalized()
		right = Vector3(-forward.z, 0.0, forward.x).normalized()
		input += right * Input.get_axis("move_left", "move_right") * 0.45
		if Input.is_action_pressed("move_backward"):
			input -= forward * 0.75
		if push_input:
			var stride: float = PushControllerScript.burden_stride_multiplier(push_contact_seconds, tuning)
			var body_commit: float = lerpf(0.58, 1.0, push_brace)
			input += forward * lerpf(0.26, 0.54, stride) * body_commit
			var contact_correction: Vector3 = _push_reacquire_input()
			if contact_correction.length_squared() > 0.001 and global_position.distance_to(stone.global_position) > tuning.stone_radius * 2.35:
				input += contact_correction * 0.12
	elif pushing_phase and maxf(
		Input.get_action_strength("push_left"),
		Input.get_action_strength("push_right")
	) > 0.001 and stone != null:
		var reacquire_input: Vector3 = _push_reacquire_input()
		if reacquire_input.length_squared() > 0.001:
			input += reacquire_input
			var uphill_for_side: Vector3 = mountain.uphill_tangent_at(stone.global_position.z)
			var flat_uphill := Vector3(uphill_for_side.x, 0.0, uphill_for_side.z).normalized()
			var push_side := Vector3(-flat_uphill.z, 0.0, flat_uphill.x).normalized()
			input += push_side * Input.get_axis("move_left", "move_right") * 0.22
		else:
			input += forward * Input.get_axis("move_backward", "move_forward")
			input += right * Input.get_axis("move_left", "move_right")
	else:
		input += forward * Input.get_axis("move_backward", "move_forward")
		input += right * Input.get_axis("move_left", "move_right")

	_is_walking = input.length_squared() > 0.001
	if _is_walking:
		input = shape_body_move_input(input, preserve_input_strength)
		_walk_time += delta

	var speed: float = tuning.push_walk_speed if pushing_phase else tuning.walk_speed
	if pushing_phase and not is_push_engaged:
		speed = tuning.walk_speed
	var position_before_move: Vector3 = global_position
	_apply_grounded_move(input, speed, delta)
	if stone != null and (pushing_phase or _near_stone):
		_enforce_stone_body_standoff()
		velocity = (global_position - position_before_move) / maxf(delta, 0.001)

	var look_target: Vector3 = global_position + forward
	if is_push_engaged and stone != null:
		look_target = stone.global_position
	look_at(Vector3(look_target.x, global_position.y, look_target.z), Vector3.UP)


func _handle_keyboard_look(delta: float) -> void:
	var turn: float = Input.get_axis("turn_left", "turn_right")
	camera_yaw += turn * tuning.keyboard_turn_speed * delta
	var pitch_axis: float = Input.get_axis("look_up", "look_down") if InputMap.has_action("look_up") and InputMap.has_action("look_down") else 0.0
	if absf(pitch_axis) > 0.001:
		var min_pitch: float = -tuning.push_look_down_limit if push_engaged or camera_push_blend > 0.12 else -0.42
		var max_pitch: float = tuning.push_look_up_limit if push_engaged or camera_push_blend > 0.12 else 0.36
		camera_pitch = clampf(camera_pitch - pitch_axis * tuning.keyboard_pitch_speed * delta, min_pitch, max_pitch)


func _constrain_push_look(stone_position: Vector3) -> void:
	var uphill: Vector3 = mountain.uphill_tangent_at(stone_position.z)
	var horizontal_uphill: Vector3 = Vector3(uphill.x, 0.0, uphill.z).normalized()
	var anchor: float = atan2(horizontal_uphill.x, -horizontal_uphill.z)
	camera_yaw = clampf(camera_yaw, anchor - tuning.push_look_limit, anchor + tuning.push_look_limit)
	camera_pitch = clampf(camera_pitch, -tuning.push_look_down_limit, tuning.push_look_up_limit)


func _camera_forward() -> Vector3:
	return Vector3(
		sin(camera_yaw) * cos(camera_pitch),
		sin(camera_pitch),
		-cos(camera_yaw) * cos(camera_pitch)
	).normalized()


func _update_camera(delta: float, stone_position: Vector3, camera_direction: Vector3, pushing_phase: bool) -> void:
	if camera == null:
		return
	var effective_push_blend: float = smoothstep(0.0, 1.0, camera_push_blend)
	var pressure_target: Vector3 = push_frame.camera_contact_point if push_frame != null else stone_position + Vector3.UP * 0.58
	var desired: Vector3 = push_camera_origin_for(camera_direction, pressure_target, stone_position, camera_push_blend)
	var shoulder_target: Vector3 = global_position + camera_direction * 5.0 + Vector3(0, 1.0, 0)
	var push_target: Vector3 = camera.global_position + camera_direction.normalized() * 6.0
	var target: Vector3 = shoulder_target.lerp(push_target, effective_push_blend)
	camera.global_position = camera.global_position.lerp(desired, 1.0 - exp(-7.5 * delta))
	camera.fov = lerpf(tuning.normal_camera_fov, tuning.push_camera_fov, effective_push_blend)
	if camera_push_blend > 0.001:
		target = shoulder_target.lerp(pressure_target, effective_push_blend)
	camera.look_at(target, Vector3.UP)


func push_camera_origin_for(camera_direction: Vector3, contact_target: Vector3, stone_position: Vector3, push_blend: float) -> Vector3:
	var shoulder_position: Vector3 = _shoulder_camera_position_for(camera_direction)
	var push_position: Vector3 = _direct_push_camera_position(camera_direction, stone_position)
	var aim_direction: Vector3 = camera_direction.normalized()
	if aim_direction.length_squared() < 0.001:
		aim_direction = Vector3(camera_direction.x, 0.0, camera_direction.z).normalized()
	if aim_direction.length_squared() < 0.001:
		aim_direction = Vector3(0.0, 0.0, -1.0)
	var contact_origin: Vector3 = contact_target - aim_direction * tuning.push_camera_contact_distance
	push_position = push_position.lerp(contact_origin, clampf(tuning.push_camera_contact_origin_strength, 0.0, 1.0))
	var effective_push_blend: float = smoothstep(0.0, 1.0, push_blend)
	return shoulder_position.lerp(push_position, effective_push_blend)


func body_push_camera_origin_for(camera_direction: Vector3, stone_position: Vector3, push_blend: float) -> Vector3:
	var shoulder_position: Vector3 = _shoulder_camera_position_for(camera_direction)
	var push_position: Vector3 = _direct_push_camera_position(camera_direction, stone_position)
	var effective_push_blend: float = smoothstep(0.0, 1.0, push_blend)
	return shoulder_position.lerp(push_position, effective_push_blend)


func _shoulder_camera_position_for(camera_direction: Vector3) -> Vector3:
	var forward: Vector3 = Vector3(camera_direction.x, 0.0, camera_direction.z).normalized()
	if forward.length_squared() < 0.001:
		forward = Vector3(0.0, 0.0, -1.0)
	var right: Vector3 = Vector3(-forward.z, 0.0, forward.x).normalized()
	return global_position - forward * tuning.shoulder_distance + right * tuning.shoulder_side_offset + Vector3.UP * tuning.shoulder_height


func _direct_push_camera_position(camera_direction: Vector3, stone_position: Vector3) -> Vector3:
	var forward: Vector3 = Vector3(camera_direction.x, 0.0, camera_direction.z).normalized()
	if forward.length_squared() < 0.001:
		forward = Vector3(0.0, 0.0, -1.0)
	var right: Vector3 = Vector3(-forward.z, 0.0, forward.x).normalized()
	var route_side: Vector3 = right
	if mountain != null:
		var route_uphill: Vector3 = mountain.uphill_tangent_at(stone_position.z)
		route_side = Vector3(-route_uphill.z, 0.0, route_uphill.x)
		if route_side.length_squared() < 0.001:
			route_side = right
		else:
			route_side = route_side.normalized()
	var aim_direction: Vector3 = camera_direction.normalized()
	var bias_strength: float = 0.0
	if aim_direction.length_squared() > 0.001:
		bias_strength = clampf(absf(aim_direction.dot(route_side)) * 1.15, 0.0, 1.0)
	var push_forward_distance: float = lerpf(tuning.push_camera_distance, tuning.push_camera_bias_back_distance, bias_strength)
	var push_height: float = tuning.push_camera_height + bias_strength * 0.10
	return global_position + forward * push_forward_distance + right * tuning.push_camera_side_offset + Vector3.UP * push_height


func calculate_reticle_aligned_push_frame(
	camera_direction: Vector3,
	is_pushing: bool,
	lateral_axis: float,
	push_hold_seconds: float,
	brace_amount: float = 1.0
):
	if stone == null:
		return null
	var camera_origin: Vector3 = _refined_reticle_camera_origin(camera_direction, is_pushing, lateral_axis, push_hold_seconds)
	return PushControllerScript.calculate_push_frame(
		stone.global_position,
		global_position,
		camera_direction,
		is_pushing,
		lateral_axis,
		tuning,
		mountain,
		push_hold_seconds,
		camera_origin,
		brace_amount
	)


func apply_reticle_aligned_push(
	camera_direction: Vector3,
	is_pushing: bool,
	lateral_axis: float,
	push_hold_seconds: float,
	brace_amount: float = 1.0
):
	if stone == null:
		return null
	var camera_origin: Vector3 = _refined_reticle_camera_origin(camera_direction, is_pushing, lateral_axis, push_hold_seconds)
	return PushControllerScript.apply_push(
		stone,
		global_position,
		camera_direction,
		is_pushing,
		lateral_axis,
		tuning,
		mountain,
		push_hold_seconds,
		camera_origin,
		brace_amount
	)


func calculate_two_hand_push_frame(
	camera_direction: Vector3,
	left_strength: float,
	right_strength: float,
	push_hold_seconds: float,
	brace_amount: float = 1.0
):
	if stone == null:
		return null
	return PushControllerScript.calculate_two_hand_push_frame(
		stone.global_position,
		global_position,
		_body_push_direction(),
		camera_direction,
		left_strength,
		right_strength,
		tuning,
		mountain,
		push_hold_seconds,
		brace_amount
	)


func apply_two_hand_push(
	camera_direction: Vector3,
	left_strength: float,
	right_strength: float,
	push_hold_seconds: float,
	brace_amount: float = 1.0
):
	if stone == null:
		return null
	return PushControllerScript.apply_two_hand_push(
		stone,
		global_position,
		_body_push_direction(),
		camera_direction,
		left_strength,
		right_strength,
		tuning,
		mountain,
		push_hold_seconds,
		brace_amount
	)


func _body_push_direction() -> Vector3:
	if stone == null:
		return Vector3(0.0, 0.0, -1.0)
	var body_to_stone := Vector3(
		stone.global_position.x - global_position.x,
		0.0,
		stone.global_position.z - global_position.z
	)
	var uphill: Vector3 = mountain.uphill_tangent_at(stone.global_position.z) if mountain != null else Vector3(0.0, 0.0, -1.0)
	if body_to_stone.length_squared() < 0.001:
		return uphill
	return (body_to_stone.normalized() + Vector3.UP * uphill.y).normalized()


func _refined_reticle_camera_origin(
	camera_direction: Vector3,
	is_pushing: bool,
	lateral_axis: float,
	push_hold_seconds: float
) -> Vector3:
	# Hand pressure is solved from the centered push eye line. The rendered camera
	# can still blend from over-shoulder without turning that parallax into force.
	var origin: Vector3 = body_push_camera_origin_for(camera_direction, stone.global_position, 1.0)
	for index in 2:
		var frame = PushControllerScript.calculate_push_frame(
			stone.global_position,
			global_position,
			camera_direction,
			is_pushing,
			lateral_axis,
			tuning,
			mountain,
			push_hold_seconds,
			origin
		)
		origin = push_camera_origin_for(
			camera_direction,
			frame.camera_contact_point,
			stone.global_position,
			1.0
		)
	return origin


func _update_arm_visual(delta: float, camera_direction: Vector3) -> void:
	var reach_speed: float = 1.0 - exp(-7.0 * delta)
	var left_contact: Vector3 = Vector3(-0.24, 1.02, -0.50)
	var right_contact: Vector3 = Vector3(0.24, 1.02, -0.50)
	if push_frame != null and push_engaged and camera_push_blend < tuning.third_person_arms_hidden_blend:
		var local_contact_offset: Vector3 = calculate_arm_pose(_walk_time, false, true, camera_direction, tuning).contact_offset
		left_contact += local_contact_offset * 0.35
		right_contact += local_contact_offset * 0.35
	var pose: ArmRigPose = calculate_two_segment_arm_pose(
		_walk_time,
		_is_walking,
		_stone_reach_blend,
		push_engaged,
		left_contact,
		right_contact,
		camera_direction,
		tuning
	)
	_apply_arm_chain(_left_arm, _left_upper, _left_forearm, _left_hand, pose.left_shoulder, pose.left_elbow, pose.left_hand, reach_speed)
	_apply_arm_chain(_right_arm, _right_upper, _right_forearm, _right_hand, pose.right_shoulder, pose.right_elbow, pose.right_hand, reach_speed)


func update_push_visual_mode() -> void:
	var first_person_active: bool = push_engaged and _first_person_hands_ready_for_takeover()
	var show_third_person_arms: bool = not first_person_active
	if _body != null:
		_body.visible = not first_person_active
	if _left_arm != null:
		_left_arm.visible = show_third_person_arms
	if _right_arm != null:
		_right_arm.visible = show_third_person_arms
	if _first_person_hands != null:
		if _first_person_hands.has_method("set_takeover_ready"):
			_first_person_hands.call("set_takeover_ready", first_person_active)
		if _first_person_hands.has_method("set_push_blend"):
			_first_person_hands.call("set_push_blend", camera_push_blend, tuning.first_person_hands_visible_blend)


func _first_person_hands_ready_for_takeover() -> bool:
	if camera_push_blend < tuning.first_person_hands_visible_blend:
		return false
	if push_contact_seconds < tuning.first_person_hands_min_contact_seconds:
		return false
	if camera == null or push_frame == null:
		return false
	var takeover_quality_floor: float = minf(tuning.first_person_hands_min_contact_quality, maxf(0.12, tuning.push_quality_dead_zone * 0.50))
	if not push_frame.contact_valid or push_frame.contact_quality < takeover_quality_floor:
		return false
	var contact_distance: float = camera.global_position.distance_to(push_frame.camera_contact_point)
	return contact_distance <= tuning.first_person_hands_takeover_max_contact_distance


func reset_to_third_person_idle_pose() -> void:
	push_engaged = false
	push_frame = null
	_push_contact_offset = Vector3.ZERO
	camera_push_blend = 0.0
	push_contact_seconds = 0.0
	push_brace = 0.0
	push_aim_speed = 0.0
	_previous_push_aim = Vector3.ZERO
	push_left_strength = 0.0
	push_right_strength = 0.0
	_near_stone = false
	_stone_reach_blend = 0.0
	_is_walking = false
	update_push_visual_mode()
	var camera_direction: Vector3 = _camera_forward()
	_update_arm_visual(1.0, camera_direction)
	_update_first_person_hands(camera_direction)


func _update_first_person_hands(camera_direction: Vector3) -> void:
	update_push_visual_mode()
	if _first_person_hands == null or camera == null:
		_update_contact_cue()
		return
	var left_target: Vector3 = Vector3.ZERO
	var right_target: Vector3 = Vector3.ZERO
	var has_contact_targets: bool = false
	if push_frame != null:
		left_target = push_frame.left_hand_target
		right_target = push_frame.right_hand_target
		has_contact_targets = true
	if not _first_person_hands.has_method("update_from_camera"):
		return
	if _first_person_hands.has_method("set_motion_feedback"):
		var feedback_state: String = _current_push_motion_state()
		_first_person_hands.call("set_motion_feedback", feedback_state, _current_push_motion_intensity(feedback_state))
	_first_person_hands.call(
		"update_from_camera",
		camera_push_blend,
		camera,
		camera_direction,
		left_target,
		right_target,
		has_contact_targets,
		stone.global_position if stone != null else Vector3.ZERO,
		tuning.stone_radius,
		tuning.first_person_hands_visible_blend
	)
	_update_contact_cue()


func _update_contact_cue() -> void:
	if _contact_cue == null or not _contact_cue.has_method("update_from_push_frame"):
		return
	_contact_cue.call("update_from_push_frame", push_frame, camera_push_blend)


func _current_push_motion_state() -> String:
	if stone == null or mountain == null:
		return "idle"
	if push_frame != null and push_frame.contact_valid:
		if push_frame.contact_quality < tuning.first_person_hands_min_contact_quality:
			return "weak"
		if push_brace < 0.58:
			return "strain"
		if push_frame.burden_recoil > 0.46:
			return "strain"
		return "push"
	var uphill_velocity: float = stone.linear_velocity.dot(mountain.uphill_tangent_at(stone.global_position.z))
	if uphill_velocity < -0.08:
		return "rollback"
	if absf(uphill_velocity) <= 0.08:
		return "stall"
	return "coast"


func _current_push_motion_intensity(state: String) -> float:
	if stone == null or mountain == null:
		return 0.0
	var uphill_velocity: float = stone.linear_velocity.dot(mountain.uphill_tangent_at(stone.global_position.z))
	match state:
		"strain":
			if push_frame != null:
				return clampf(push_frame.burden_recoil, 0.25, 1.0)
			return 0.45
		"push":
			if push_frame != null:
				return clampf(push_frame.force_uphill_component / maxf(1.0, tuning.max_contact_push_force), 0.2, 1.0)
			return 0.35
		"weak":
			if push_frame != null:
				return clampf(1.0 - push_frame.contact_quality, 0.25, 1.0)
			return 0.55
		"rollback":
			return clampf(absf(uphill_velocity) / 1.15, 0.25, 1.0)
		"stall":
			return 0.45
		"coast":
			return clampf(absf(uphill_velocity) / 1.6, 0.15, 0.7)
	return 0.0


func _apply_arm_chain(
	arm_root: Node3D,
	upper: MeshInstance3D,
	forearm: MeshInstance3D,
	hand: MeshInstance3D,
	shoulder: Vector3,
	elbow: Vector3,
	hand_position: Vector3,
	weight: float
) -> void:
	arm_root.position = arm_root.position.lerp(shoulder, weight)
	arm_root.rotation = Vector3.ZERO
	var root_offset: Vector3 = arm_root.position
	_place_segment(upper, Vector3.ZERO, elbow - root_offset)
	_place_segment(forearm, elbow - root_offset, hand_position - root_offset)
	hand.position = hand.position.lerp(hand_position - root_offset, weight)


func _place_segment(segment: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	var direction: Vector3 = end - start
	var length: float = direction.length()
	if length < 0.001:
		return
	segment.position = start + direction * 0.5
	segment.rotation = Quaternion(Vector3.UP, direction.normalized()).get_euler()
	var mesh_height: float = segment.mesh.height if segment.mesh != null else 1.0
	segment.scale = Vector3(1.0, maxf(0.2, length / maxf(mesh_height, 0.001)), 1.0)


func _apply_grounded_move(input: Vector3, speed: float, delta: float) -> void:
	var previous_position: Vector3 = global_position
	global_position += input * speed * delta
	global_position.x = clampf(global_position.x, -tuning.path_width * 0.55, tuning.path_width * 0.55)
	global_position.z = clampf(global_position.z, tuning.back_base_z - 6.0, tuning.front_base_z + 8.0)
	var ground_y: float = mountain.height_at(global_position.z) + 0.05
	global_position.y = lerpf(global_position.y, ground_y, tuning.player_ground_snap_strength)
	velocity = (global_position - previous_position) / maxf(delta, 0.001)


func _push_reacquire_input() -> Vector3:
	if stone == null or mountain == null:
		return Vector3.ZERO
	var downhill: Vector3 = mountain.downhill_tangent_at(stone.global_position.z)
	var target: Vector3 = stone.global_position + downhill * tuning.stone_radius * 1.55
	var to_target := Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
	if to_target.length() > tuning.push_reacquire_distance:
		return Vector3.ZERO
	if to_target.length_squared() <= 0.001:
		return Vector3.ZERO
	var target_direction: Vector3 = to_target.normalized()
	var facing := Vector3(_camera_forward().x, 0.0, _camera_forward().z)
	if facing.length_squared() > 0.001:
		facing = facing.normalized()
		if facing.dot(target_direction) < tuning.push_reacquire_aim_dot_min:
			return Vector3.ZERO
	return target_direction


func _enforce_stone_body_standoff() -> void:
	if stone == null or mountain == null:
		return
	var stone_position: Vector3 = stone.global_position
	var offset := Vector3(global_position.x - stone_position.x, 0.0, global_position.z - stone_position.z)
	var distance: float = offset.length()
	var min_distance: float = tuning.stone_radius + tuning.player_body_radius + tuning.player_stone_clearance
	if distance >= min_distance:
		return
	var direction: Vector3 = offset / distance if distance > 0.001 else Vector3.ZERO
	if direction.length_squared() < 0.001:
		var downhill: Vector3 = mountain.downhill_tangent_at(stone_position.z)
		direction = Vector3(downhill.x, 0.0, downhill.z).normalized()
	global_position.x = stone_position.x + direction.x * min_distance
	global_position.z = stone_position.z + direction.z * min_distance
	global_position.x = clampf(global_position.x, -tuning.path_width * 0.55, tuning.path_width * 0.55)
	global_position.z = clampf(global_position.z, tuning.back_base_z - 6.0, tuning.front_base_z + 8.0)
	global_position.y = mountain.height_at(global_position.z) + 0.05


func apply_test_move(axis: Vector2, duration: float) -> void:
	if mountain == null:
		return
	var forward: Vector3 = Vector3(sin(camera_yaw), 0, -cos(camera_yaw)).normalized()
	var right: Vector3 = Vector3(cos(camera_yaw), 0, sin(camera_yaw)).normalized()
	var input: Vector3 = (right * axis.x) + (forward * axis.y)
	if input.length_squared() > 0.001:
		input = input.normalized()
	_apply_grounded_move(input, tuning.walk_speed, duration)
