class_name DebugForceOverlay
extends Node3D

var _mesh_instance: MeshInstance3D
var _mesh: ImmediateMesh
var _material: StandardMaterial3D


func _ready() -> void:
	_mesh = ImmediateMesh.new()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _mesh
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.vertex_color_use_as_albedo = true
	_material.no_depth_test = true
	_mesh_instance.material_override = _material
	add_child(_mesh_instance)


func update_debug(stone_position: Vector3, frame, uphill: Vector3) -> void:
	if _mesh == null:
		return

	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_add_vector(stone_position + Vector3.UP * 1.8, uphill.normalized() * 2.0, Color(0.2, 1.0, 0.2, 1.0))
	_add_vector(stone_position + Vector3.UP * 1.45, frame.aim_direction.normalized() * 1.5, Color(0.65, 0.35, 1.0, 1.0))
	var force_application_point: Vector3 = stone_position + frame.force_application_offset
	_add_vector(force_application_point, frame.contact_force.normalized() * minf(3.0, frame.contact_force.length() * 0.025), Color(1.0, 0.15, 0.1, 1.0))
	_add_vector(frame.camera_contact_point + Vector3.UP * 0.18, frame.roll_direction.normalized() * 1.0, Color(1.0, 0.55, 0.1, 1.0))
	_add_cross(frame.camera_contact_point, 0.18, Color(1.0, 0.88, 0.1, 1.0))
	_add_cross(force_application_point, 0.10, Color(1.0, 0.32, 0.18, 1.0))
	_add_cross(frame.player_anchor + Vector3.UP * 1.2, 0.16, Color(0.2, 0.55, 1.0, 1.0))
	_mesh.surface_end()


func _add_vector(start: Vector3, vector: Vector3, color: Color) -> void:
	_mesh.surface_set_color(color)
	_mesh.surface_add_vertex(start)
	_mesh.surface_set_color(color)
	_mesh.surface_add_vertex(start + vector)


func _add_cross(center: Vector3, size: float, color: Color) -> void:
	for axis in [Vector3.RIGHT, Vector3.UP, Vector3.FORWARD]:
		_mesh.surface_set_color(color)
		_mesh.surface_add_vertex(center - axis * size)
		_mesh.surface_set_color(color)
		_mesh.surface_add_vertex(center + axis * size)
