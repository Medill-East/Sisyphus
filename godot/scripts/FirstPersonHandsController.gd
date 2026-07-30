class_name FirstPersonHandsController
extends Node3D

@onready var _left_forearm: MeshInstance3D = $LeftForearm
@onready var _right_forearm: MeshInstance3D = $RightForearm
@onready var _left_hand: MeshInstance3D = $LeftHand
@onready var _right_hand: MeshInstance3D = $RightHand
@onready var _chest: MeshInstance3D = get_node_or_null("Chest")
@onready var _left_upper_arm: MeshInstance3D = get_node_or_null("LeftUpperArm")
@onready var _right_upper_arm: MeshInstance3D = get_node_or_null("RightUpperArm")

const NEUTRAL_HAND_TINT := Color(0.52, 0.45, 0.32, 1.0)
const NEUTRAL_ARM_TINT := Color(0.42, 0.37, 0.27, 1.0)
const MAX_FOREARM_VISUAL_LENGTH := 1.02
const MIN_VISIBLE_PUSH_BLEND := 0.84
const BASE_HAND_SCALE := Vector3(1.32, 0.58, 0.88)

var _feedback_state: String = "idle"
var _feedback_intensity: float = 0.0
var _feedback_tint: Color = NEUTRAL_HAND_TINT
var _arm_tint: Color = NEUTRAL_ARM_TINT
var _hand_materials: Array[StandardMaterial3D] = []
var _arm_materials: Array[StandardMaterial3D] = []
var _takeover_ready: bool = true
var _palm_compression: float = 0.0
var _left_hand_load: float = 0.0
var _right_hand_load: float = 0.0


func _ready() -> void:
	_cache_feedback_materials()
	_apply_palm_shape(0.0)
	_apply_feedback_tint()


func set_push_blend(push_blend: float, visible_threshold: float = MIN_VISIBLE_PUSH_BLEND) -> void:
	visible = _takeover_ready and push_blend >= visible_threshold


func set_takeover_ready(is_ready: bool) -> void:
	_takeover_ready = is_ready


func set_motion_feedback(state: String, intensity: float = 1.0) -> void:
	_feedback_state = state
	_feedback_intensity = clampf(intensity, 0.0, 1.0)
	_feedback_tint = _tint_for_state(_feedback_state, _feedback_intensity)
	_arm_tint = NEUTRAL_ARM_TINT.lerp(_feedback_tint, 0.28)
	_apply_feedback_tint()


func feedback_state() -> String:
	return _feedback_state


func feedback_tint() -> Color:
	return _feedback_tint


func palm_compression() -> float:
	return _palm_compression


func set_hand_loads(left_load: float, right_load: float) -> void:
	_left_hand_load = clampf(left_load, 0.0, 1.0)
	_right_hand_load = clampf(right_load, 0.0, 1.0)
	var motion_compression: float = _target_palm_compression(_left_hand_load > 0.001 or _right_hand_load > 0.001)
	_apply_palm_shape(maxf(motion_compression, maxf(_left_hand_load, _right_hand_load) * 0.34))


func update_from_camera(
	push_blend: float,
	camera: Camera3D,
	camera_direction: Vector3,
	left_target: Vector3,
	right_target: Vector3,
	has_contact_targets: bool,
	stone_position: Vector3 = Vector3.ZERO,
	stone_radius: float = 0.0,
	visible_threshold: float = MIN_VISIBLE_PUSH_BLEND
) -> void:
	set_push_blend(push_blend, visible_threshold)
	if not visible or camera == null:
		_apply_palm_shape(0.0)
		return
	_apply_palm_shape(_target_palm_compression(has_contact_targets))

	var forward: Vector3 = (-camera.global_transform.basis.z).normalized()
	if forward.length_squared() < 0.001:
		forward = camera_direction.normalized()
	if forward.length_squared() < 0.001:
		forward = Vector3(0.0, 0.0, -1.0)
	var right: Vector3 = camera.global_transform.basis.x.normalized()
	if right.length_squared() < 0.001:
		right = Vector3.RIGHT
	var up: Vector3 = camera.global_transform.basis.y.normalized()
	if up.length_squared() < 0.001:
		up = Vector3.UP
	var flat_forward: Vector3 = Vector3(forward.x, 0.0, forward.z).normalized()
	if flat_forward.length_squared() < 0.001:
		flat_forward = Vector3(0.0, 0.0, -1.0)
	var camera_base: Vector3 = camera.global_position
	var left_start: Vector3 = camera_base - right * 0.34 - up * 0.24 + forward * 0.58
	var right_start: Vector3 = camera_base + right * 0.34 - up * 0.24 + forward * 0.58
	var left_shoulder: Vector3 = camera_base - right * 0.56 - up * 0.34 + forward * 0.22
	var right_shoulder: Vector3 = camera_base + right * 0.56 - up * 0.34 + forward * 0.22
	if _chest != null:
		_chest.global_transform = Transform3D(
			Basis(right, up, -forward).orthonormalized(),
			camera_base - up * 0.42 + forward * 0.32
		)
	if has_contact_targets and stone_radius > 0.0:
		var left_anchor_clearance: float = stone_radius + _hand_visual_radius(_left_hand) * 0.95 + 0.04
		var right_anchor_clearance: float = stone_radius + _hand_visual_radius(_right_hand) * 0.95 + 0.04
		left_start = _keep_anchor_outside_stone(left_start, camera_base, stone_position, left_anchor_clearance)
		right_start = _keep_anchor_outside_stone(right_start, camera_base, stone_position, right_anchor_clearance)
	if not has_contact_targets:
		left_target = camera_base + forward * 0.82 - right * 0.24 - up * 0.30
		right_target = camera_base + forward * 0.82 + right * 0.24 - up * 0.30
	else:
		var target_midpoint: Vector3 = (left_target + right_target) * 0.5
		var current_span: float = (right_target - left_target).dot(right)
		var minimum_span: float = 0.54
		if absf(current_span) < minimum_span:
			left_target = target_midpoint - right * minimum_span * 0.5
			right_target = target_midpoint + right * minimum_span * 0.5
		left_target -= up * 0.02
		right_target -= up * 0.02
	var target_side_shift: float = clampf(((left_target + right_target) * 0.5 - camera_base).dot(right), -0.24, 0.24)
	left_start += right * target_side_shift
	right_start += right * target_side_shift
	var feedback_targets: Array[Vector3] = _motion_feedback_targets(flat_forward, right, left_target, right_target)
	left_target = feedback_targets[0]
	right_target = feedback_targets[1]
	if has_contact_targets and stone_radius > 0.0:
		var left_hand_clearance: float = stone_radius + _hand_visual_radius(_left_hand) * 0.95 + 0.04
		var right_hand_clearance: float = stone_radius + _hand_visual_radius(_right_hand) * 0.95 + 0.04
		left_start = _keep_anchor_outside_stone(left_start, camera_base, stone_position, stone_radius + _forearm_visual_radius(_left_forearm) * 1.25 + 0.02)
		right_start = _keep_anchor_outside_stone(right_start, camera_base, stone_position, stone_radius + _forearm_visual_radius(_right_forearm) * 1.25 + 0.02)
		left_target = _project_outside_stone(left_target, stone_position, left_hand_clearance, left_start)
		right_target = _project_outside_stone(right_target, stone_position, right_hand_clearance, right_start)
	left_target = _limit_visual_reach(left_start, left_target)
	right_target = _limit_visual_reach(right_start, right_target)
	if has_contact_targets and stone_radius > 0.0:
		var left_final_clearance: float = stone_radius + _hand_visual_radius(_left_hand) * 0.95 + 0.04
		var right_final_clearance: float = stone_radius + _hand_visual_radius(_right_hand) * 0.95 + 0.04
		left_target = _project_outside_stone(left_target, stone_position, left_final_clearance, left_start)
		right_target = _project_outside_stone(right_target, stone_position, right_final_clearance, right_start)

	_place_global_segment(_left_upper_arm, left_shoulder, left_start)
	_place_global_segment(_right_upper_arm, right_shoulder, right_start)
	_place_global_segment(_left_forearm, left_start, left_target)
	_place_global_segment(_right_forearm, right_start, right_target)
	_left_hand.global_position = left_target
	_right_hand.global_position = right_target


func _target_palm_compression(has_contact_targets: bool) -> float:
	if not has_contact_targets:
		return 0.0
	match _feedback_state:
		"strain":
			return lerpf(0.20, 0.34, _feedback_intensity)
		"push":
			return lerpf(0.12, 0.24, _feedback_intensity)
		"weak":
			return lerpf(0.06, 0.15, _feedback_intensity)
		"rollback":
			return lerpf(0.10, 0.22, _feedback_intensity)
		"stall":
			return lerpf(0.05, 0.10, _feedback_intensity)
		"coast":
			return lerpf(0.04, 0.08, _feedback_intensity)
	return 0.0


func _apply_palm_shape(compression: float) -> void:
	_palm_compression = clampf(compression, 0.0, 1.0)
	var left_compression: float = _palm_compression * _left_hand_load
	var right_compression: float = _palm_compression * _right_hand_load
	if _left_hand != null:
		_left_hand.scale = _hand_scale_for_compression(left_compression)
	if _right_hand != null:
		_right_hand.scale = _hand_scale_for_compression(right_compression)


func _hand_scale_for_compression(compression: float) -> Vector3:
	return Vector3(
		BASE_HAND_SCALE.x * (1.0 + compression * 0.50),
		BASE_HAND_SCALE.y * (1.0 - compression * 0.36),
		BASE_HAND_SCALE.z * (1.0 + compression * 0.20)
	)


func _motion_feedback_targets(flat_forward: Vector3, right: Vector3, left_target: Vector3, right_target: Vector3) -> Array[Vector3]:
	var pull_back: float = 0.0
	var sink: float = 0.0
	var widen: float = 0.0
	match _feedback_state:
		"strain":
			pull_back = lerpf(0.03, 0.11, _feedback_intensity)
			sink = lerpf(0.01, 0.05, _feedback_intensity)
			widen = lerpf(0.01, 0.04, _feedback_intensity)
		"rollback":
			pull_back = lerpf(0.08, 0.26, _feedback_intensity)
			sink = lerpf(0.03, 0.11, _feedback_intensity)
			widen = lerpf(0.02, 0.08, _feedback_intensity)
		"weak":
			pull_back = lerpf(0.05, 0.16, _feedback_intensity)
			sink = lerpf(0.02, 0.08, _feedback_intensity)
			widen = lerpf(0.02, 0.06, _feedback_intensity)
		"stall":
			pull_back = lerpf(0.02, 0.08, _feedback_intensity)
			sink = lerpf(0.02, 0.07, _feedback_intensity)
		"coast":
			pull_back = lerpf(0.02, 0.10, _feedback_intensity)
	if pull_back <= 0.0 and sink <= 0.0 and widen <= 0.0:
		return [left_target, right_target]
	var offset: Vector3 = -flat_forward * pull_back - Vector3.UP * sink
	left_target += offset - right * widen
	right_target += offset + right * widen
	return [left_target, right_target]


func _limit_visual_reach(start: Vector3, target: Vector3) -> Vector3:
	var offset: Vector3 = target - start
	var distance: float = offset.length()
	if distance <= MAX_FOREARM_VISUAL_LENGTH or distance < 0.001:
		return target
	return start + offset.normalized() * MAX_FOREARM_VISUAL_LENGTH


func _keep_hand_outside_stone(start: Vector3, target: Vector3, stone_position: Vector3, stone_radius: float, hand_radius: float) -> Vector3:
	var minimum_distance: float = stone_radius + hand_radius * 0.95 + 0.04
	var safe_target: Vector3 = _project_outside_stone(target, stone_position, minimum_distance, start)
	var to_target: Vector3 = safe_target - start
	var distance: float = to_target.length()
	if distance < 0.001:
		return safe_target
	var direction: Vector3 = to_target / distance
	var limited_target: Vector3 = start + direction * minf(distance, MAX_FOREARM_VISUAL_LENGTH)
	if limited_target.distance_to(stone_position) >= minimum_distance:
		return limited_target
	for index in 8:
		limited_target = limited_target.lerp(start, 0.45)
		if limited_target.distance_to(stone_position) >= minimum_distance:
			return limited_target
	return start


func _project_outside_stone(point: Vector3, stone_position: Vector3, minimum_distance: float, fallback: Vector3) -> Vector3:
	var from_center: Vector3 = point - stone_position
	if from_center.length_squared() < 0.001:
		from_center = fallback - stone_position
	if from_center.length_squared() < 0.001:
		from_center = Vector3.UP
	if from_center.length() >= minimum_distance:
		return point
	return stone_position + from_center.normalized() * minimum_distance


func _keep_anchor_outside_stone(anchor: Vector3, camera_base: Vector3, stone_position: Vector3, minimum_distance: float) -> Vector3:
	if anchor.distance_to(stone_position) >= minimum_distance:
		return anchor
	var away: Vector3 = anchor - stone_position
	if away.length_squared() < 0.001:
		away = camera_base - stone_position
	if away.length_squared() < 0.001:
		away = Vector3.UP
	return stone_position + away.normalized() * minimum_distance


func _first_ray_sphere_distance(origin: Vector3, direction: Vector3, center: Vector3, radius: float) -> float:
	var from_center: Vector3 = origin - center
	var b: float = from_center.dot(direction)
	var c: float = from_center.length_squared() - radius * radius
	var discriminant: float = b * b - c
	if discriminant < 0.0:
		return -1.0
	var root: float = sqrt(discriminant)
	var near_t: float = -b - root
	if near_t >= 0.0:
		return near_t
	var far_t: float = -b + root
	return far_t if far_t >= 0.0 else -1.0


func _hand_visual_radius(hand: MeshInstance3D) -> float:
	if hand == null or hand.mesh == null:
		return 0.11
	if hand.mesh is SphereMesh:
		return hand.mesh.radius * maxf(hand.scale.x, maxf(hand.scale.y, hand.scale.z))
	return 0.11


func _forearm_visual_radius(forearm: MeshInstance3D) -> float:
	if forearm == null or forearm.mesh == null:
		return 0.05
	if forearm.mesh is CapsuleMesh:
		return forearm.mesh.radius * maxf(forearm.scale.x, forearm.scale.z)
	return 0.05


func _tint_for_state(state: String, intensity: float) -> Color:
	match state:
		"strain":
			return NEUTRAL_HAND_TINT.lerp(Color(0.61, 0.34, 0.18, 1.0), intensity * 0.82)
		"rollback":
			return NEUTRAL_HAND_TINT.lerp(Color(0.58, 0.30, 0.22, 1.0), intensity)
		"weak":
			return NEUTRAL_HAND_TINT.lerp(Color(0.54, 0.38, 0.20, 1.0), intensity * 0.85)
		"stall":
			return NEUTRAL_HAND_TINT.lerp(Color(0.43, 0.38, 0.23, 1.0), intensity * 0.75)
		"coast":
			return NEUTRAL_HAND_TINT.lerp(Color(0.25, 0.28, 0.28, 1.0), intensity * 0.55)
	return NEUTRAL_HAND_TINT


func _cache_feedback_materials() -> void:
	_hand_materials = []
	_arm_materials = []
	for hand in [_left_hand, _right_hand]:
		var material: StandardMaterial3D = _duplicated_standard_material(hand)
		if material != null:
			_hand_materials.append(material)
	for arm in [_chest, _left_upper_arm, _right_upper_arm, _left_forearm, _right_forearm]:
		var material: StandardMaterial3D = _duplicated_standard_material(arm)
		if material != null:
			_arm_materials.append(material)


func _duplicated_standard_material(instance: MeshInstance3D) -> StandardMaterial3D:
	if instance == null:
		return null
	var source: Material = instance.get_surface_override_material(0)
	if source == null and instance.mesh != null:
		source = instance.mesh.surface_get_material(0)
	if not (source is StandardMaterial3D):
		return null
	var copy: StandardMaterial3D = source.duplicate()
	instance.set_surface_override_material(0, copy)
	return copy


func _apply_feedback_tint() -> void:
	for material in _hand_materials:
		material.albedo_color = _feedback_tint
	for material in _arm_materials:
		material.albedo_color = _arm_tint


func _place_global_segment(segment: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	if segment == null:
		return
	var direction: Vector3 = end - start
	var length: float = direction.length()
	if length < 0.001:
		return
	segment.global_position = start + direction * 0.5
	segment.global_rotation = Quaternion(Vector3.UP, direction.normalized()).get_euler()
	var mesh_height: float = segment.mesh.height if segment.mesh != null else 1.0
	segment.scale = Vector3(1.0, maxf(0.2, length / maxf(mesh_height, 0.001)), 1.0)
