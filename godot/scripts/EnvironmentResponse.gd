class_name EnvironmentResponse
extends Node3D

class ResponsePoint:
	var position: Vector3
	var kind: String

	func _init(next_position: Vector3, next_kind: String) -> void:
		position = next_position
		kind = next_kind


var response_points: Array[ResponsePoint] = []


func visual_style() -> String:
	return "embedded_low_saturation"


func build_from_trail(points: Array, daylight_reward: float) -> void:
	clear_response()
	for index in points.size():
		var trail_point = points[index]
		_add_response_point(trail_point.position, "scar")
		if trail_point.stability < 0.45:
			_add_response_point(trail_point.position + Vector3(0.08, 0.0, 0.02), "water")
		elif daylight_reward > 0.7 and index % 2 == 0:
			_add_response_point(trail_point.position + Vector3(0.16, 0.0, 0.0), "flower")
		else:
			_add_response_point(trail_point.position + Vector3(-0.14, 0.0, 0.02), "grass")


func kind_counts() -> Dictionary:
	var counts: Dictionary = {}
	for point in response_points:
		counts[point.kind] = int(counts.get(point.kind, 0)) + 1
	return counts


func clear_response() -> void:
	response_points.clear()
	for child in get_children():
		child.queue_free()


func _add_marker(position: Vector3, kind: String) -> void:
	var marker := MeshInstance3D.new()
	var mesh: Mesh
	var material := StandardMaterial3D.new()
	var lift: float = 0.018
	match kind:
		"scar":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.38
			cylinder.bottom_radius = 0.38
			cylinder.height = 0.010
			cylinder.radial_segments = 7
			mesh = cylinder
			material.albedo_color = Color(0.32, 0.29, 0.22, 0.58)
			lift = 0.012
		"flower":
			var flower_mesh := CylinderMesh.new()
			flower_mesh.top_radius = 0.12
			flower_mesh.bottom_radius = 0.16
			flower_mesh.height = 0.035
			flower_mesh.radial_segments = 5
			mesh = flower_mesh
			material.albedo_color = Color(0.39, 0.42, 0.30, 0.72)
			lift = 0.020
		"water":
			var water_mesh := BoxMesh.new()
			water_mesh.size = Vector3(0.50, 0.012, 0.64)
			mesh = water_mesh
			material.albedo_color = Color(0.20, 0.25, 0.25, 0.54)
			lift = 0.010
		_:
			var grass_mesh := BoxMesh.new()
			grass_mesh.size = Vector3(0.28, 0.030, 0.14)
			mesh = grass_mesh
			material.albedo_color = Color(0.27, 0.36, 0.22, 0.68)
			lift = 0.018
	material.roughness = 0.82
	marker.mesh = mesh
	marker.material_override = material
	marker.position = position + Vector3.UP * lift
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(marker)


func _add_response_point(position: Vector3, kind: String) -> void:
	response_points.append(ResponsePoint.new(position, kind))
	_add_marker(position, kind)
