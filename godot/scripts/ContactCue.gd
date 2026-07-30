class_name ContactCue
extends Node3D

var _contact_point: MeshInstance3D
var _pressure_smear: MeshInstance3D
var _last_contact_position: Vector3 = Vector3.ZERO
var _last_force_length: float = 0.0
var _last_quality_signal: float = 0.0
var _last_patch_scale: float = 0.0
var _last_saturation_hint: float = 0.0
var _patch_material: StandardMaterial3D
var _smear_material: StandardMaterial3D


func _ready() -> void:
	_contact_point = MeshInstance3D.new()
	_contact_point.name = "PressurePatch"
	var contact_mesh := CylinderMesh.new()
	contact_mesh.top_radius = 0.14
	contact_mesh.bottom_radius = 0.14
	contact_mesh.height = 0.012
	contact_mesh.radial_segments = 14
	contact_mesh.rings = 1
	_contact_point.mesh = contact_mesh
	_patch_material = _cue_material(Color(0.16, 0.12, 0.08, 0.42), 0.0)
	_contact_point.material_override = _patch_material
	add_child(_contact_point)

	_pressure_smear = MeshInstance3D.new()
	_pressure_smear.name = "PressureSmear"
	var force_mesh := BoxMesh.new()
	force_mesh.size = Vector3(0.10, 1.0, 0.010)
	_pressure_smear.mesh = force_mesh
	_smear_material = _cue_material(Color(0.13, 0.09, 0.06, 0.34), 0.0)
	_pressure_smear.material_override = _smear_material
	add_child(_pressure_smear)
	hide_cue()


func update_from_push_frame(frame, push_blend: float) -> void:
	if frame == null or not frame.contact_valid or push_blend < 0.18:
		hide_cue()
		return
	visible = true
	var normal: Vector3 = frame.contact_normal.normalized()
	if normal.length_squared() < 0.001:
		normal = Vector3.UP
	var contact_position: Vector3 = frame.camera_contact_point + normal * 0.022
	var force_direction: Vector3 = frame.contact_force.normalized()
	if force_direction.length_squared() < 0.001:
		force_direction = frame.roll_direction.normalized()
	if force_direction.length_squared() < 0.001:
		force_direction = Vector3.FORWARD
	var tangent_force: Vector3 = (force_direction - normal * force_direction.dot(normal))
	if tangent_force.length_squared() < 0.001:
		tangent_force = frame.roll_direction - normal * frame.roll_direction.dot(normal)
	if tangent_force.length_squared() < 0.001:
		tangent_force = normal.cross(Vector3.RIGHT)
	if tangent_force.length_squared() < 0.001:
		tangent_force = normal.cross(Vector3.FORWARD)
	tangent_force = tangent_force.normalized()
	var force_length: float = clampf(frame.contact_force.length() * 0.0012, 0.07, 0.16)
	var quality_signal: float = smoothstep(0.0, 1.0, clampf(frame.contact_quality, 0.0, 1.0))
	_last_contact_position = contact_position
	_last_force_length = force_length
	_last_quality_signal = quality_signal
	_place_pressure_patch(contact_position, normal, tangent_force, force_length, quality_signal)
	_update_pressure_materials(quality_signal)


func hide_cue() -> void:
	visible = false
	_last_force_length = 0.0
	_last_quality_signal = 0.0
	_last_patch_scale = 0.0
	_last_saturation_hint = 0.0


func status(camera: Camera3D, contact_point: Vector3) -> Dictionary:
	var cue_local := Vector3.ZERO
	var x_ratio: float = 99.0
	if camera != null and visible:
		cue_local = camera.to_local(_last_contact_position)
		x_ratio = absf(cue_local.x) / maxf(0.001, absf(cue_local.z))
	return {
		"visible": visible,
		"contact_distance": _last_contact_position.distance_to(contact_point) if visible else 99.0,
		"camera_x_ratio": x_ratio,
		"force_length": _last_force_length,
		"quality_signal": _last_quality_signal,
		"patch_scale": _last_patch_scale,
		"saturation_hint": _last_saturation_hint,
		"visual_style": "pressure_patch",
		"debug_vector": false,
	}


func _place_pressure_patch(center: Vector3, normal: Vector3, tangent: Vector3, length: float, quality_signal: float) -> void:
	var bitangent: Vector3 = normal.cross(tangent)
	if bitangent.length_squared() < 0.001:
		bitangent = Vector3.RIGHT
	else:
		bitangent = bitangent.normalized()
	var patch_basis := Basis(tangent, normal, bitangent).orthonormalized()
	_contact_point.global_transform = Transform3D(patch_basis, center)
	var quality_width: float = lerpf(0.58, 1.18, quality_signal)
	var quality_depth: float = lerpf(0.42, 0.76, quality_signal)
	_last_patch_scale = quality_width
	_contact_point.scale = Vector3(quality_width + length * 1.15, 1.0, quality_depth)

	var smear_basis := Basis(bitangent, tangent, normal).orthonormalized()
	_pressure_smear.global_transform = Transform3D(smear_basis, center + tangent * length * 0.36 + normal * 0.004)
	_pressure_smear.scale = Vector3(lerpf(0.72, 1.0, quality_signal), length * lerpf(0.72, 1.15, quality_signal), 1.0)


func _update_pressure_materials(quality_signal: float) -> void:
	var weak_patch := Color(0.21, 0.16, 0.12, 0.36)
	var good_patch := Color(0.13, 0.11, 0.08, 0.50)
	var weak_smear := Color(0.18, 0.13, 0.10, 0.28)
	var good_smear := Color(0.10, 0.08, 0.06, 0.42)
	var patch_color: Color = weak_patch.lerp(good_patch, quality_signal)
	var smear_color: Color = weak_smear.lerp(good_smear, quality_signal)
	_last_saturation_hint = _saturation_hint(patch_color)
	if _patch_material != null:
		_patch_material.albedo_color = patch_color
	if _smear_material != null:
		_smear_material.albedo_color = smear_color


func _saturation_hint(color: Color) -> float:
	return maxf(color.r, maxf(color.g, color.b)) - minf(color.r, minf(color.g, color.b))


func _cue_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.emission_enabled = emission_energy > 0.0
	if material.emission_enabled:
		material.emission = Color(color.r, color.g, color.b, 1.0)
		material.emission_energy_multiplier = emission_energy
	material.no_depth_test = false
	return material
