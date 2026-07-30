class_name PushController
extends Node

class PushFrame:
	var contact_point: Vector3
	var force: Vector3
	var player_anchor: Vector3
	var uphill_direction: Vector3
	var aim_direction: Vector3
	var camera_contact_point: Vector3
	var left_hand_target: Vector3
	var right_hand_target: Vector3
	var active_hand: String
	var roll_direction: Vector3
	var central_force: Vector3
	var roll_torque: Vector3
	var contact_offset: Vector3
	var force_application_offset: Vector3 = Vector3.ZERO
	var contact_valid: bool
	var contact_force: Vector3
	var contact_normal: Vector3
	var spin_to_translation_ratio: float
	var contact_loss_frames: int
	var contact_quality: float
	var brace_amount: float = 1.0
	var aim_stability: float = 1.0
	var breakaway_ratio: float = 0.0
	var burden_stride: float
	var burden_recoil: float
	var force_uphill_component: float
	var gravity_downhill_component: float
	var left_contact_point: Vector3 = Vector3.ZERO
	var right_contact_point: Vector3 = Vector3.ZERO
	var left_contact_offset: Vector3 = Vector3.ZERO
	var right_contact_offset: Vector3 = Vector3.ZERO
	var left_force: Vector3 = Vector3.ZERO
	var right_force: Vector3 = Vector3.ZERO
	var left_torque: Vector3 = Vector3.ZERO
	var right_torque: Vector3 = Vector3.ZERO
	var left_strength: float = 0.0
	var right_strength: float = 0.0
	var left_load: float = 0.0
	var right_load: float = 0.0
	var left_scrape_level: float = 0.0
	var right_scrape_level: float = 0.0
	var left_haptic_level: float = 0.0
	var right_haptic_level: float = 0.0

	func _init(
		next_contact_point: Vector3,
		next_force: Vector3,
		next_player_anchor: Vector3,
		next_uphill_direction: Vector3,
		next_aim_direction: Vector3,
		next_camera_contact_point: Vector3,
		next_left_hand_target: Vector3,
		next_right_hand_target: Vector3,
		next_active_hand: String,
		next_roll_direction: Vector3,
		next_central_force: Vector3,
		next_roll_torque: Vector3,
		next_contact_offset: Vector3,
		next_contact_valid: bool,
		next_contact_force: Vector3,
		next_contact_normal: Vector3,
		next_spin_to_translation_ratio: float,
		next_contact_loss_frames: int,
		next_contact_quality: float,
		next_burden_stride: float,
		next_burden_recoil: float,
		next_force_uphill_component: float,
		next_gravity_downhill_component: float
	) -> void:
		contact_point = next_contact_point
		force = next_force
		player_anchor = next_player_anchor
		uphill_direction = next_uphill_direction
		aim_direction = next_aim_direction
		camera_contact_point = next_camera_contact_point
		left_hand_target = next_left_hand_target
		right_hand_target = next_right_hand_target
		active_hand = next_active_hand
		roll_direction = next_roll_direction
		central_force = next_central_force
		roll_torque = next_roll_torque
		contact_offset = next_contact_offset
		contact_valid = next_contact_valid
		contact_force = next_contact_force
		contact_normal = next_contact_normal
		spin_to_translation_ratio = next_spin_to_translation_ratio
		contact_loss_frames = next_contact_loss_frames
		contact_quality = next_contact_quality
		burden_stride = next_burden_stride
		burden_recoil = next_burden_recoil
		force_uphill_component = next_force_uphill_component
		gravity_downhill_component = next_gravity_downhill_component


static func calculate_push_frame(
	stone_position: Vector3,
	player_position: Vector3,
	camera_direction: Vector3,
	is_pushing: bool,
	lateral_axis: float,
	tuning,
	mountain = null,
	push_hold_seconds: float = 999.0,
	camera_origin: Variant = null,
	brace_amount: float = 1.0
) -> PushFrame:
	var body_direction: Vector3 = stone_position - player_position
	body_direction.y = 0.0
	var uphill: Vector3 = _uphill_at(stone_position.z, tuning, mountain)
	if body_direction.length_squared() < 0.001:
		body_direction = uphill
	else:
		body_direction = body_direction.normalized()
		body_direction = (body_direction + Vector3.UP * uphill.y).normalized()
	var strength: float = 1.0 if is_pushing else 0.0
	return calculate_two_hand_push_frame(
		stone_position,
		player_position,
		body_direction,
		camera_direction,
		strength,
		strength,
		tuning,
		mountain,
		push_hold_seconds,
		brace_amount
	)


static func calculate_two_hand_push_frame(
	stone_position: Vector3,
	player_position: Vector3,
	body_direction: Vector3,
	camera_direction: Vector3,
	left_strength: float,
	right_strength: float,
	tuning,
	mountain = null,
	push_hold_seconds: float = 999.0,
	brace_amount: float = 1.0
) -> PushFrame:
	var uphill: Vector3 = _uphill_at(stone_position.z, tuning, mountain)
	var downhill: Vector3 = -uphill
	var normal: Vector3 = Vector3.UP
	if mountain != null and mountain.has_method("normal_at_position"):
		normal = mountain.normal_at_position(stone_position).normalized()
	elif mountain != null and mountain.has_method("normal_at"):
		normal = mountain.normal_at(stone_position.z).normalized()
	var side: Vector3 = _side_from_uphill(uphill)
	var resolved_body_direction: Vector3 = body_direction.normalized()
	if resolved_body_direction.length_squared() < 0.001:
		resolved_body_direction = uphill
	if resolved_body_direction.dot(uphill) < 0.35:
		resolved_body_direction = uphill
	resolved_body_direction = (resolved_body_direction - normal * resolved_body_direction.dot(normal) + normal * uphill.dot(normal)).normalized()
	var aim: Vector3 = camera_direction.normalized()
	if aim.length_squared() < 0.001:
		aim = resolved_body_direction
	var resolved_left_strength: float = clampf(left_strength, 0.0, 1.0)
	var resolved_right_strength: float = clampf(right_strength, 0.0, 1.0)
	var combined_strength: float = resolved_left_strength + resolved_right_strength

	var base_surface_direction: Vector3 = (downhill * 0.72 + normal * 0.24).normalized()
	var hand_surface_spread: float = 0.34
	var left_surface_direction: Vector3 = (base_surface_direction - side * hand_surface_spread).normalized()
	var right_surface_direction: Vector3 = (base_surface_direction + side * hand_surface_spread).normalized()
	var left_contact_point: Vector3 = stone_position + left_surface_direction * tuning.stone_radius
	var right_contact_point: Vector3 = stone_position + right_surface_direction * tuning.stone_radius
	var left_contact_offset: Vector3 = left_contact_point - stone_position
	var right_contact_offset: Vector3 = right_contact_point - stone_position
	var palm_outward_offset: float = tuning.first_person_hand_surface_offset
	var left_hand_target: Vector3 = left_contact_point + left_surface_direction * palm_outward_offset
	var right_hand_target: Vector3 = right_contact_point + right_surface_direction * palm_outward_offset
	var camera_contact_point: Vector3 = (left_contact_point + right_contact_point) * 0.5
	if combined_strength > 0.001:
		camera_contact_point = (
			left_contact_point * resolved_left_strength
			+ right_contact_point * resolved_right_strength
		) / combined_strength
	var active_hand: String = "both"
	if resolved_left_strength > resolved_right_strength + 0.001:
		active_hand = "left"
	elif resolved_right_strength > resolved_left_strength + 0.001:
		active_hand = "right"
	elif combined_strength <= 0.001:
		active_hand = "none"

	# Each hand pushes uphill and inward from its own side of the spherical contact.
	# The inward component creates the away-from-hand drift while the tangential
	# component, applied at the offset below, produces genuine rigid-body torque.
	var lateral_force_ratio: float = hand_surface_spread / 0.72
	var left_force_direction: Vector3 = (resolved_body_direction + side * lateral_force_ratio).normalized()
	var right_force_direction: Vector3 = (resolved_body_direction - side * lateral_force_ratio).normalized()
	var to_player: Vector3 = player_position - stone_position
	var player_distance: float = to_player.length()
	var rear_dot: float = 0.0
	if player_distance > 0.001:
		rear_dot = to_player.normalized().dot(downhill)
	var desired_distance: float = tuning.stone_radius * 1.55
	var reach_error: float = absf(player_distance - desired_distance)
	var reach_strength: float = clampf(1.0 - reach_error / maxf(0.001, tuning.contact_distance), 0.0, 1.0)
	reach_strength = smoothstep(0.0, 1.0, reach_strength)
	var contact_valid: bool = (
		combined_strength > 0.001
		and player_distance <= tuning.push_disengage_distance
		and player_distance > tuning.stone_radius * 0.55
		and rear_dot >= tuning.rear_contact_dot_min
		and reach_strength > 0.05
	)
	var contact_quality: float = _contact_quality(base_surface_direction, downhill, normal, side)
	var left_force: Vector3 = Vector3.ZERO
	var right_force: Vector3 = Vector3.ZERO
	if contact_valid:
		var quality_multiplier: float = _quality_force_multiplier(contact_quality, tuning)
		var brace_multiplier: float = brace_force_multiplier(brace_amount, tuning)
		var ramp_alpha: float = 1.0
		if tuning.push_force_ramp_seconds > 0.001:
			ramp_alpha = clampf(push_hold_seconds / tuning.push_force_ramp_seconds, 0.0, 1.0)
			ramp_alpha = smoothstep(0.0, 1.0, ramp_alpha)
		var ramp_multiplier: float = lerpf(0.65, 1.0, ramp_alpha)
		var total_magnitude: float = minf(
			minf(tuning.max_contact_push_force, tuning.max_push_force_per_frame),
			maxf(tuning.push_force, tuning.push_contact_spring) * reach_strength
		) * ramp_multiplier * quality_multiplier * brace_multiplier
		var hand_scale: float = 1.0 / maxf(1.0, combined_strength)
		left_force = left_force_direction * total_magnitude * resolved_left_strength * hand_scale
		right_force = right_force_direction * total_magnitude * resolved_right_strength * hand_scale
	var contact_force: Vector3 = left_force + right_force
	var force_direction: Vector3 = contact_force.normalized()
	if force_direction.length_squared() < 0.001:
		force_direction = resolved_body_direction
	var left_torque: Vector3 = left_contact_offset.cross(left_force)
	var right_torque: Vector3 = right_contact_offset.cross(right_force)
	var roll_torque: Vector3 = left_torque + right_torque
	var contact_offset: Vector3 = (left_contact_offset + right_contact_offset) * 0.5
	if combined_strength > 0.001:
		contact_offset = (
			left_contact_offset * resolved_left_strength
			+ right_contact_offset * resolved_right_strength
		) / combined_strength
	var central_force: Vector3 = Vector3.ZERO

	var player_anchor: Vector3 = stone_position
	player_anchor += downhill * (tuning.stone_radius * 1.65)
	if mountain != null and mountain.has_method("height_at"):
		player_anchor.y = mountain.height_at(player_anchor.z) + 0.05
	else:
		player_anchor.y = player_position.y

	var force_uphill_component: float = contact_force.dot(uphill)
	var gravity_scale: float = float(tuning.get("stone_gravity_scale") if tuning.get("stone_gravity_scale") != null else 1.0)
	var gravity_downhill_component: float = tuning.stone_mass * 9.8 * gravity_scale * maxf(0.0, -Vector3.DOWN.dot(uphill))
	var burden_stride: float = burden_stride_multiplier(push_hold_seconds, tuning) if contact_valid else 1.0
	var burden_recoil: float = burden_recoil_from_stride(burden_stride, tuning) if contact_valid else 0.0
	var frame := PushFrame.new(
		camera_contact_point,
		contact_force,
		player_anchor,
		uphill,
		aim,
		camera_contact_point,
		left_hand_target,
		right_hand_target,
		active_hand,
		force_direction,
		central_force,
		roll_torque,
		contact_offset,
		contact_valid,
		contact_force,
		normal,
		0.0,
		0 if contact_valid else 1,
		contact_quality,
		burden_stride,
		burden_recoil,
		force_uphill_component,
		gravity_downhill_component
	)
	frame.brace_amount = clampf(brace_amount, 0.0, 1.0)
	frame.force_application_offset = contact_offset * clampf(float(tuning.push_effective_lever_arm), 0.05, 1.0)
	frame.breakaway_ratio = force_uphill_component / maxf(1.0, gravity_downhill_component)
	frame.left_contact_point = left_contact_point
	frame.right_contact_point = right_contact_point
	frame.left_contact_offset = left_contact_offset * clampf(float(tuning.push_effective_lever_arm), 0.05, 1.0)
	frame.right_contact_offset = right_contact_offset * clampf(float(tuning.push_effective_lever_arm), 0.05, 1.0)
	frame.left_force = left_force
	frame.right_force = right_force
	frame.left_torque = frame.left_contact_offset.cross(left_force)
	frame.right_torque = frame.right_contact_offset.cross(right_force)
	frame.left_strength = resolved_left_strength
	frame.right_strength = resolved_right_strength
	var per_hand_capacity: float = maxf(1.0, minf(tuning.max_contact_push_force, tuning.max_push_force_per_frame) * 0.5)
	frame.left_load = clampf(left_force.length() / per_hand_capacity, 0.0, 1.0)
	frame.right_load = clampf(right_force.length() / per_hand_capacity, 0.0, 1.0)
	frame.left_scrape_level = frame.left_load
	frame.right_scrape_level = frame.right_load
	frame.left_haptic_level = frame.left_load
	frame.right_haptic_level = frame.right_load
	return frame


static func apply_push(
	stone: RigidBody3D,
	player_position: Vector3,
	camera_direction: Vector3,
	is_pushing: bool,
	lateral_axis: float,
	tuning,
	mountain = null,
	push_hold_seconds: float = 999.0,
	camera_origin: Variant = null,
	brace_amount: float = 1.0
) -> PushFrame:
	var body_direction: Vector3 = stone.global_position - player_position
	body_direction.y = 0.0
	var uphill: Vector3 = _uphill_at(stone.global_position.z, tuning, mountain)
	if body_direction.length_squared() < 0.001:
		body_direction = uphill
	else:
		body_direction = (body_direction.normalized() + Vector3.UP * uphill.y).normalized()
	var strength: float = 1.0 if is_pushing else 0.0
	return apply_two_hand_push(
		stone,
		player_position,
		body_direction,
		camera_direction,
		strength,
		strength,
		tuning,
		mountain,
		push_hold_seconds,
		brace_amount
	)


static func apply_two_hand_push(
	stone: RigidBody3D,
	player_position: Vector3,
	body_direction: Vector3,
	camera_direction: Vector3,
	left_strength: float,
	right_strength: float,
	tuning,
	mountain = null,
	push_hold_seconds: float = 999.0,
	brace_amount: float = 1.0
) -> PushFrame:
	var frame: PushFrame = calculate_two_hand_push_frame(
		stone.global_position,
		player_position,
		body_direction,
		camera_direction,
		left_strength,
		right_strength,
		tuning,
		mountain,
		push_hold_seconds,
		brace_amount
	)
	if frame.central_force.length_squared() > 0.0:
		stone.apply_central_force(frame.central_force)
	if frame.contact_valid and frame.contact_force.length_squared() > 0.0:
		frame.burden_stride = burden_stride_multiplier(push_hold_seconds, tuning)
		frame.burden_recoil = burden_recoil_from_stride(frame.burden_stride, tuning)
		var speed_along_push: float = maxf(0.0, stone.linear_velocity.dot(frame.roll_direction))
		var shaped_force: Vector3 = shape_contact_force_for_burden(
			frame.contact_force,
			frame.roll_direction,
			speed_along_push,
			push_hold_seconds,
			tuning
		)
		var damped_force: Vector3 = shaped_force - frame.roll_direction * speed_along_push * tuning.push_contact_damping
		var ramped_minimum_force: float = frame.contact_force.dot(frame.roll_direction) * _burden_minimum_force_scale(tuning)
		if damped_force.dot(frame.roll_direction) < ramped_minimum_force:
			damped_force = frame.roll_direction * ramped_minimum_force
		var original_force_length: float = frame.contact_force.length()
		frame.contact_force = damped_force.limit_length(minf(tuning.max_contact_push_force, tuning.max_push_force_per_frame))
		var hand_force_scale: float = frame.contact_force.length() / maxf(0.001, original_force_length)
		frame.left_force *= hand_force_scale
		frame.right_force *= hand_force_scale
		frame.contact_force = frame.left_force + frame.right_force
		frame.force = frame.contact_force
		frame.force_uphill_component = frame.contact_force.dot(frame.uphill_direction)
		frame.breakaway_ratio = frame.force_uphill_component / maxf(1.0, frame.gravity_downhill_component)
		frame.left_torque = frame.left_contact_offset.cross(frame.left_force)
		frame.right_torque = frame.right_contact_offset.cross(frame.right_force)
		frame.roll_torque = frame.left_torque + frame.right_torque
		if frame.left_force.length_squared() > 0.0:
			stone.apply_force(frame.left_force, frame.left_contact_offset)
		if frame.right_force.length_squared() > 0.0:
			stone.apply_force(frame.right_force, frame.right_contact_offset)
		_damp_non_roll_spin(stone, frame, tuning)
	else:
		frame.burden_stride = 1.0
		frame.burden_recoil = 0.0
		_apply_release_rolling_resistance(stone, tuning, frame.uphill_direction)
	var linear_speed: float = stone.linear_velocity.length()
	frame.spin_to_translation_ratio = stone.angular_velocity.length() / maxf(linear_speed, 0.05)
	var rim_speed: float = stone.angular_velocity.length() * tuning.stone_radius
	var slip_ratio: float = clampf(
		absf(rim_speed - linear_speed) / maxf(0.2, maxf(rim_speed, linear_speed)),
		0.0,
		1.0
	)
	frame.left_scrape_level = frame.left_load * lerpf(0.35, 1.0, slip_ratio)
	frame.right_scrape_level = frame.right_load * lerpf(0.35, 1.0, slip_ratio)
	frame.left_haptic_level = maxf(frame.left_load * 0.55, frame.left_scrape_level)
	frame.right_haptic_level = maxf(frame.right_load * 0.55, frame.right_scrape_level)
	return frame


static func brace_target(contact_quality: float, aim_speed: float, tuning) -> float:
	var quality: float = smoothstep(
		float(tuning.brace_quality_min),
		maxf(float(tuning.brace_quality_min) + 0.001, float(tuning.brace_quality_full)),
		clampf(contact_quality, 0.0, 1.0)
	)
	return quality * aim_stability(aim_speed, tuning)


static func aim_stability(aim_speed: float, tuning) -> float:
	var instability: float = smoothstep(
		float(tuning.brace_aim_speed_soft),
		maxf(float(tuning.brace_aim_speed_soft) + 0.001, float(tuning.brace_aim_speed_hard)),
		maxf(0.0, aim_speed)
	)
	return 1.0 - instability


static func update_brace(current: float, target: float, is_pushing: bool, delta: float, tuning) -> float:
	var resolved_target: float = clampf(target, 0.0, 1.0) if is_pushing else 0.0
	var speed: float = float(tuning.brace_build_speed)
	if resolved_target < current:
		speed = float(tuning.brace_decay_speed) if is_pushing else float(tuning.brace_release_speed)
	var weight: float = 1.0 - exp(-maxf(0.01, speed) * maxf(0.0, delta))
	return clampf(lerpf(current, resolved_target, weight), 0.0, 1.0)


static func brace_force_multiplier(brace_amount: float, tuning) -> float:
	var shaped: float = pow(clampf(brace_amount, 0.0, 1.0), maxf(0.2, float(tuning.brace_force_curve)))
	return lerpf(clampf(float(tuning.brace_force_floor), 0.0, 0.65), 1.0, shaped)


static func shape_contact_force_for_burden(
	base_force: Vector3,
	roll_direction: Vector3,
	speed_along_push: float,
	push_hold_seconds: float,
	tuning
) -> Vector3:
	if base_force.length_squared() < 0.001:
		return Vector3.ZERO
	var direction: Vector3 = roll_direction.normalized()
	if direction.length_squared() < 0.001:
		direction = base_force.normalized()
	var stride_multiplier: float = burden_stride_multiplier(push_hold_seconds, tuning)
	var shaped_force: Vector3 = base_force * stride_multiplier
	var speed_overshoot: float = maxf(0.0, speed_along_push - _burden_target_uphill_speed(tuning))
	if speed_overshoot > 0.0:
		shaped_force -= direction * speed_overshoot * _burden_speed_governor_strength(tuning)
	var minimum_component: float = base_force.dot(direction) * _burden_minimum_force_scale(tuning)
	if shaped_force.dot(direction) < minimum_component:
		shaped_force = direction * minimum_component
	return shaped_force


static func _apply_release_rolling_resistance(stone: RigidBody3D, tuning, uphill_direction: Vector3) -> void:
	var horizontal_velocity := Vector3(stone.linear_velocity.x, 0.0, stone.linear_velocity.z)
	if horizontal_velocity.length_squared() < 0.0004:
		return
	var flat_uphill := Vector3(uphill_direction.x, 0.0, uphill_direction.z)
	var resistance_scale: float = 1.0
	if flat_uphill.length_squared() > 0.001:
		flat_uphill = flat_uphill.normalized()
		if horizontal_velocity.dot(flat_uphill) < 0.0:
			resistance_scale = tuning.downhill_release_resistance_scale
	var resistance: Vector3 = -horizontal_velocity.normalized() * tuning.release_rolling_resistance * resistance_scale
	stone.apply_central_force(resistance)


static func _damp_non_roll_spin(stone: RigidBody3D, frame: PushFrame, tuning) -> void:
	var roll_axis: Vector3 = frame.contact_normal.cross(frame.roll_direction)
	if roll_axis.length_squared() < 0.001:
		return
	roll_axis = roll_axis.normalized()
	var roll_spin: Vector3 = roll_axis * stone.angular_velocity.dot(roll_axis)
	var stray_spin: Vector3 = stone.angular_velocity - roll_spin
	stone.angular_velocity = roll_spin + stray_spin * (1.0 - clampf(tuning.spin_damping_strength, 0.0, 0.85))


static func burden_stride_multiplier(push_hold_seconds: float, tuning) -> float:
	if push_hold_seconds >= 900.0:
		return 1.0
	var depth: float = clampf(_burden_stride_force_depth(tuning), 0.0, 0.85)
	if depth <= 0.001:
		return 1.0
	var hz: float = maxf(0.01, float(tuning.push_hand_cycle_hz) if tuning != null and tuning.get("push_hand_cycle_hz") != null else 1.6)
	var wave: float = (sin(push_hold_seconds * TAU * hz - PI * 0.5) + 1.0) * 0.5
	wave = smoothstep(0.0, 1.0, wave)
	return lerpf(1.0 - depth, 1.0, wave)


static func burden_recoil_from_stride(stride_multiplier: float, tuning) -> float:
	var depth: float = clampf(_burden_stride_force_depth(tuning), 0.0, 0.85)
	if depth <= 0.001:
		return 0.0
	return clampf((1.0 - stride_multiplier) / depth, 0.0, 1.0)


static func _burden_stride_multiplier(push_hold_seconds: float, tuning) -> float:
	return burden_stride_multiplier(push_hold_seconds, tuning)


static func _burden_target_uphill_speed(tuning) -> float:
	if tuning != null and tuning.get("burden_target_uphill_speed") != null:
		return maxf(0.05, float(tuning.get("burden_target_uphill_speed")))
	return 0.94


static func _burden_speed_governor_strength(tuning) -> float:
	if tuning != null and tuning.get("burden_speed_governor_strength") != null:
		return maxf(0.0, float(tuning.get("burden_speed_governor_strength")))
	return 44.0


static func _burden_stride_force_depth(tuning) -> float:
	if tuning != null and tuning.get("burden_stride_force_depth") != null:
		return clampf(float(tuning.get("burden_stride_force_depth")), 0.0, 0.85)
	return 0.34


static func _burden_minimum_force_scale(tuning) -> float:
	if tuning != null and tuning.get("burden_minimum_force_scale") != null:
		return clampf(float(tuning.get("burden_minimum_force_scale")), 0.08, 0.65)
	return 0.34


static func _reticle_surface_direction(
	stone_position: Vector3,
	camera_direction: Vector3,
	camera_origin: Variant,
	fallback_surface_direction: Vector3,
	downhill: Vector3,
	normal: Vector3,
	tuning
) -> Vector3:
	if not (camera_origin is Vector3):
		return fallback_surface_direction
	var ray_origin: Vector3 = camera_origin
	var ray_direction: Vector3 = camera_direction.normalized()
	if ray_direction.length_squared() < 0.001:
		return fallback_surface_direction

	var to_origin: Vector3 = ray_origin - stone_position
	var b: float = 2.0 * ray_direction.dot(to_origin)
	var c: float = to_origin.length_squared() - tuning.stone_radius * tuning.stone_radius
	var discriminant: float = b * b - 4.0 * c
	var surface_direction: Vector3 = fallback_surface_direction
	if discriminant >= 0.0:
		var root: float = sqrt(discriminant)
		var t_near: float = (-b - root) * 0.5
		var t_far: float = (-b + root) * 0.5
		var t: float = t_near if t_near > 0.0 else t_far
		if t_near > 0.0 and t_far > 0.0:
			var near_direction: Vector3 = (ray_origin + ray_direction * t_near - stone_position).normalized()
			var far_direction: Vector3 = (ray_origin + ray_direction * t_far - stone_position).normalized()
			if far_direction.dot(fallback_surface_direction) > near_direction.dot(fallback_surface_direction):
				t = t_far
		if t > 0.0:
			surface_direction = (ray_origin + ray_direction * t - stone_position).normalized()
	else:
		var closest_t: float = maxf(0.0, -(to_origin.dot(ray_direction)))
		var closest_point: Vector3 = ray_origin + ray_direction * closest_t
		if closest_point.distance_squared_to(stone_position) < tuning.stone_radius * tuning.stone_radius * 1.15:
			surface_direction = (closest_point - stone_position).normalized()

	if surface_direction.length_squared() < 0.001:
		return fallback_surface_direction
	var rear_component: float = surface_direction.dot(downhill.normalized())
	if rear_component < 0.20:
		surface_direction = (surface_direction + downhill.normalized() * (0.20 - rear_component) * 1.65).normalized()
	var lower_component: float = surface_direction.dot(normal.normalized())
	if lower_component < -0.36:
		surface_direction = (surface_direction + normal.normalized() * (-0.36 - lower_component) * 1.25).normalized()
	return surface_direction


static func _contact_quality(
	surface_direction: Vector3,
	downhill: Vector3,
	normal: Vector3,
	side: Vector3,
	relative_vertical_aim: float = 0.0
) -> float:
	var rear: float = surface_direction.dot(downhill.normalized())
	var height: float = surface_direction.dot(normal.normalized())
	var side_amount: float = absf(surface_direction.dot(side.normalized()))
	var rear_quality: float = smoothstep(0.22, 0.72, rear)
	var height_quality: float = 1.0 - clampf(absf(height - 0.24) / 1.05, 0.0, 1.0)
	height_quality = smoothstep(0.0, 1.0, height_quality)
	var lateral_penalty: float = smoothstep(0.46, 0.86, side_amount) * 0.18
	var high_corner_penalty: float = smoothstep(0.50, 0.86, side_amount) * smoothstep(0.40, 0.82, height) * 0.86
	var aim_high_penalty: float = smoothstep(0.12, 0.62, relative_vertical_aim) * 0.50
	var aim_high_side_penalty: float = (
		smoothstep(0.08, 0.48, relative_vertical_aim)
		* smoothstep(0.22, 0.58, side_amount)
		* 0.995
	)
	return clampf(
		rear_quality
		* height_quality
		* (1.0 - lateral_penalty)
		* (1.0 - high_corner_penalty)
		* (1.0 - aim_high_penalty)
		* (1.0 - aim_high_side_penalty),
		0.0,
		1.0
	)


static func _quality_force_multiplier(contact_quality: float, tuning) -> float:
	var dead_zone: float = clampf(float(tuning.push_quality_dead_zone), 0.0, 0.92)
	if contact_quality <= dead_zone:
		return 0.0
	var normalized: float = clampf((contact_quality - dead_zone) / maxf(0.001, 1.0 - dead_zone), 0.0, 1.0)
	return contact_quality * pow(normalized, maxf(0.2, float(tuning.push_quality_curve)))


static func _uphill_at(z: float, tuning, mountain) -> Vector3:
	if mountain != null and mountain.has_method("uphill_tangent_at"):
		return mountain.uphill_tangent_at(z).normalized()
	var grade: float = tuning.front_slope_grade() if tuning.has_method("front_slope_grade") else 0.25
	return Vector3(0.0, grade, -1.0).normalized()


static func _side_from_uphill(uphill: Vector3) -> Vector3:
	var side: Vector3 = Vector3(-uphill.z, 0.0, uphill.x)
	if side.length_squared() < 0.001:
		return Vector3.RIGHT
	return side.normalized()
