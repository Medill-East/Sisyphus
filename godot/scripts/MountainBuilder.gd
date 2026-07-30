class_name MountainBuilder
extends Node3D

const TuningScript = preload("res://scripts/Tuning.gd")

var tuning = TuningScript.new()
var obstacles: Array[Dictionary] = []
var route_markers: Array[Dictionary] = []
var pressure_markers: Array[Dictionary] = []

var _mesh_instance: MeshInstance3D
var _body: StaticBody3D
var _obstacle_root: Node3D
var _route_marker_root: Node3D
var _pressure_marker_root: Node3D
var _ridge_marker_root: Node3D


func _ready() -> void:
	build()


func build() -> void:
	_clear_children()
	obstacles = generate_obstacle_layout()
	route_markers = generate_route_marker_layout()
	pressure_markers = generate_route_pressure_marker_layout()
	_build_mountain_mesh()
	_build_route_markers()
	_build_route_pressure_markers()
	_build_ridge_gate_markers()
	_build_obstacles()


func height_at(z: float) -> float:
	if z >= tuning.front_base_z:
		return 0.0
	if z >= tuning.ridge_z:
		var front_t: float = (tuning.front_base_z - z) / maxf(0.001, tuning.front_base_z - tuning.ridge_z)
		return tuning.ridge_height * smoothstep(0.0, 1.0, front_t)
	if z >= tuning.back_base_z:
		var back_t: float = (z - tuning.back_base_z) / maxf(0.001, tuning.ridge_z - tuning.back_base_z)
		return tuning.ridge_height * smoothstep(0.0, 1.0, back_t)
	return 0.0


func height_at_position(x: float, z: float) -> float:
	return height_at(z) + route_camber_height_offset(x, z)


func route_camber_at(z: float) -> float:
	if z > tuning.front_base_z - 1.8 or z < tuning.ridge_z + 2.4:
		return 0.0
	var distance: float = tuning.front_base_z - z
	var band_length: float = maxf(1.0, tuning.route_camber_band_length)
	var band: int = int(floor(distance / band_length))
	var phase: float = fposmod(distance, band_length) / band_length
	var fade: float = smoothstep(0.0, 0.22, phase) * (1.0 - smoothstep(0.78, 1.0, phase))
	var side_sign: float = 1.0 if band % 2 == 0 else -1.0
	return side_sign * fade


func route_camber_height_offset(x: float, z: float) -> float:
	var half_width: float = maxf(0.001, tuning.path_width * 0.5)
	var lateral: float = clampf(x / half_width, -1.0, 1.0)
	var edge_fade: float = smoothstep(0.0, 0.18, absf(lateral))
	return lateral * route_camber_at(z) * tuning.route_camber_strength * edge_fade


func tangent_at(z: float) -> Vector3:
	return uphill_tangent_at(z)


func uphill_tangent_at(z: float) -> Vector3:
	var dz: float = 0.15
	var y0: float = height_at(z + dz)
	var y1: float = height_at(z - dz)
	return Vector3(0.0, y1 - y0, -dz * 2.0).normalized()


func downhill_tangent_at(z: float) -> Vector3:
	return -uphill_tangent_at(z)


func normal_at(z: float) -> Vector3:
	var tangent: Vector3 = tangent_at(z)
	return Vector3(0.0, -tangent.z, tangent.y).normalized()


func normal_at_position(position: Vector3) -> Vector3:
	var sample: float = 0.20
	var dh_dx: float = (
		height_at_position(position.x + sample, position.z)
		- height_at_position(position.x - sample, position.z)
	) / (sample * 2.0)
	var dh_dz: float = (
		height_at_position(position.x, position.z + sample)
		- height_at_position(position.x, position.z - sample)
	) / (sample * 2.0)
	return Vector3(-dh_dx, 1.0, -dh_dz).normalized()


func generate_obstacle_layout() -> Array[Dictionary]:
	var generated: Array[Dictionary] = []
	var count: int = max(0, tuning.obstacle_density)
	for index in count:
		var row: float = 0.0 if count <= 1 else float(index) / float(count - 1)
		var side: float = -1.0 if index % 2 == 0 else 1.0
		var radius: float = 0.34 + _noise(index * 17 + 3) * maxf(0.2, tuning.obstacle_max_radius - 0.34)
		var lane_gap: float = 0.1 + _noise(index * 19 + 9) * 0.4
		if index % 3 != 0:
			lane_gap = 0.7 + _noise(index * 19 + 9) * 1.35
		var x: float = side * (tuning.clear_path_width * 0.5 + radius + lane_gap)
		var z: float = lerpf(tuning.front_base_z - 3.5, tuning.ridge_z + 2.2, row)
		z += (_noise(index * 23 + 11) - 0.5) * 1.55
		generated.append({
			"position": Vector3(x, height_at_position(x, z), z),
			"radius": radius,
			"height": radius * (0.8 + _noise(index * 29 + 15) * 0.75),
			"rotation": _noise(index * 31 + 5) * TAU,
		})

	var back_count: int = max(4, int(tuning.obstacle_density * 0.45))
	for index in back_count:
		var row: float = 0.0 if back_count <= 1 else float(index) / float(back_count - 1)
		var side: float = -1.0 if index % 2 == 0 else 1.0
		var radius: float = 0.28 + _noise(index * 37 + 21) * maxf(0.2, tuning.obstacle_max_radius * 0.75 - 0.28)
		var x: float = side * (tuning.clear_path_width * 0.65 + radius + 0.45 + _noise(index * 41 + 2) * 2.1)
		var z: float = lerpf(tuning.ridge_z - 4.0, tuning.back_base_z + 5.0, row)
		generated.append({
			"position": Vector3(x, height_at_position(x, z), z),
			"radius": radius,
			"height": radius * (0.7 + _noise(index * 43 + 10) * 0.7),
			"rotation": _noise(index * 47 + 6) * TAU,
		})

	return generated


func generate_route_marker_layout() -> Array[Dictionary]:
	var generated: Array[Dictionary] = []
	var route_depth: float = tuning.front_base_z - tuning.back_base_z
	var count: int = maxi(10, int(ceil(route_depth / 6.5)))
	var edge_x: float = minf(tuning.path_width * 0.5 + 0.42, tuning.clear_path_width * 0.5 + tuning.stone_radius * 0.55 + 0.32)
	for index in count:
		var row: float = 0.0 if count <= 1 else float(index) / float(count - 1)
		var z: float = lerpf(tuning.front_base_z - 2.8, tuning.back_base_z + 4.2, row)
		for side in [-1.0, 1.0]:
			var stagger: float = (_noise(index * 53 + int(side * 7.0)) - 0.5) * 0.22
			var x: float = side * (edge_x + stagger)
			var height: float = 0.48 + _noise(index * 59 + int(side * 11.0)) * 0.30
			generated.append({
				"position": Vector3(x, height_at_position(x, z), z),
				"height": height,
				"radius": 0.070 + _noise(index * 61 + int(side * 13.0)) * 0.040,
				"side": side,
				"rotation": _noise(index * 67 + int(side * 17.0)) * TAU,
			})
	return generated


func generate_route_pressure_marker_layout() -> Array[Dictionary]:
	var generated: Array[Dictionary] = []
	var band_length: float = maxf(1.0, tuning.route_camber_band_length)
	var usable_depth: float = maxf(0.0, tuning.front_base_z - tuning.ridge_z - 4.2)
	var band_count: int = maxi(1, int(floor(usable_depth / band_length)))
	for band in band_count:
		var center_z: float = tuning.front_base_z - band_length * (float(band) + 0.5)
		var camber: float = route_camber_at(center_z)
		if absf(camber) < 0.20:
			continue
		var low_side: float = -signf(camber)
		for stripe in 3:
			var z_offset: float = (float(stripe) - 1.0) * band_length * 0.18
			var z: float = center_z + z_offset
			var lateral_offset: float = 0.20 + _noise(band * 71 + stripe * 13) * 0.18
			var x: float = low_side * (tuning.clear_path_width * 0.5 + tuning.stone_radius * 0.20 + lateral_offset)
			generated.append({
				"position": Vector3(x, height_at_position(x, z), z),
				"side": low_side,
				"camber": camber,
				"length": 1.08 + _noise(band * 73 + stripe * 17) * 0.44,
				"width": 0.14 + _noise(band * 79 + stripe * 19) * 0.08,
				"rotation": low_side * (0.36 + _noise(band * 83 + stripe * 23) * 0.18),
			})
	return generated


func _build_mountain_mesh() -> void:
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half_width: float = tuning.path_width * 0.5
	var side_width: float = 12.0
	var route_depth: float = tuning.front_base_z - tuning.back_base_z + 16.0
	var z_steps: int = max(56, int(ceil(route_depth / 6.0)))
	var x_values: Array[float] = [
		-side_width,
		-half_width,
		0.0,
		half_width,
		side_width,
	]
	for zi in z_steps:
		var z0: float = lerpf(tuning.back_base_z - 8.0, tuning.front_base_z + 8.0, float(zi) / float(z_steps))
		var z1: float = lerpf(tuning.back_base_z - 8.0, tuning.front_base_z + 8.0, float(zi + 1) / float(z_steps))
		for xi in x_values.size() - 1:
			var x0: float = x_values[xi]
			var x1: float = x_values[xi + 1]
			_add_quad(surface, _terrain_point(x0, z0), _terrain_point(x1, z0), _terrain_point(x1, z1), _terrain_point(x0, z1))

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "LowPolyDoubleSidedMountain"
	_mesh_instance.mesh = surface.commit()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.43, 0.49, 0.38)
	material.roughness = 0.92
	_mesh_instance.material_override = material
	add_child(_mesh_instance)

	_body = StaticBody3D.new()
	_body.name = "MountainCollider"
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = _mesh_instance.mesh.create_trimesh_shape()
	_body.add_child(collision)
	add_child(_body)


func _build_route_markers() -> void:
	_route_marker_root = Node3D.new()
	_route_marker_root.name = "RouteEdgeMarkers"
	add_child(_route_marker_root)
	for marker in route_markers:
		var position: Vector3 = marker.position
		var height: float = marker.height
		var radius: float = marker.radius
		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.name = "RouteEdgeMarker"
		mesh.position = position + Vector3.UP * (height * 0.5 + 0.015)
		mesh.rotation = Vector3(0.0, marker.rotation, 0.0)
		var cylinder: CylinderMesh = CylinderMesh.new()
		cylinder.top_radius = radius * 0.72
		cylinder.bottom_radius = radius
		cylinder.height = height
		cylinder.radial_segments = 5
		mesh.mesh = cylinder
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.31, 0.36, 0.28)
		material.roughness = 0.94
		mesh.material_override = material
		_route_marker_root.add_child(mesh)


func _build_route_pressure_markers() -> void:
	_pressure_marker_root = Node3D.new()
	_pressure_marker_root.name = "RoutePressureMarkers"
	add_child(_pressure_marker_root)
	for marker in pressure_markers:
		var position: Vector3 = marker.position
		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.name = "RoutePressureMarker"
		mesh.position = position + Vector3.UP * 0.026
		mesh.rotation = Vector3(0.0, marker.rotation, 0.0)
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(marker.width, 0.028, marker.length)
		mesh.mesh = box
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.32, 0.37, 0.25)
		material.roughness = 0.96
		mesh.material_override = material
		_pressure_marker_root.add_child(mesh)


func _build_ridge_gate_markers() -> void:
	_ridge_marker_root = Node3D.new()
	_ridge_marker_root.name = "RidgeGateMarkers"
	add_child(_ridge_marker_root)
	var marker_x: float = tuning.path_width * 0.5 + 0.82
	for side in [-1.0, 1.0]:
		var marker := MeshInstance3D.new()
		marker.name = "RidgePost"
		var height: float = 1.95
		var radius: float = 0.16
		var z: float = tuning.ridge_z + 0.35
		var x: float = side * marker_x
		marker.set_meta("read_height", height)
		marker.position = Vector3(x, height_at_position(x, z) + height * 0.5 + 0.015, z)
		marker.rotation = Vector3(0.0, side * 0.18, 0.0)
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = radius * 0.72
		cylinder.bottom_radius = radius
		cylinder.height = height
		cylinder.radial_segments = 5
		marker.mesh = cylinder
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.24, 0.26, 0.22)
		material.roughness = 0.96
		marker.material_override = material
		_ridge_marker_root.add_child(marker)

	var crest_line := MeshInstance3D.new()
	crest_line.name = "CrestLine"
	var box := BoxMesh.new()
	box.size = Vector3(tuning.path_width + 1.4, 0.070, 0.24)
	crest_line.mesh = box
	var crest_z: float = tuning.ridge_z + 0.28
	crest_line.position = Vector3(0.0, height_at_position(0.0, crest_z) + 0.055, crest_z)
	var crest_material := StandardMaterial3D.new()
	crest_material.albedo_color = Color(0.30, 0.33, 0.27)
	crest_material.roughness = 0.98
	crest_line.material_override = crest_material
	_ridge_marker_root.add_child(crest_line)


func _build_obstacles() -> void:
	_obstacle_root = Node3D.new()
	_obstacle_root.name = "ObstacleStones"
	add_child(_obstacle_root)
	for obstacle in obstacles:
		var position: Vector3 = obstacle.position
		var radius: float = obstacle.radius
		var body: StaticBody3D = StaticBody3D.new()
		body.name = "ObstacleStone"
		body.position = position + Vector3(0, radius * 0.28, 0)
		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.name = "Mesh"
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = radius
		sphere.height = radius * 2.0
		sphere.radial_segments = 7
		sphere.rings = 4
		mesh.mesh = sphere
		mesh.scale = Vector3(1.0, obstacle.height / maxf(0.001, radius), 1.0)
		mesh.rotation = Vector3(0.15, obstacle.rotation, 0.05)
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.38, 0.39, 0.35)
		material.roughness = 0.95
		mesh.material_override = material
		body.add_child(mesh)
		var collider: CollisionShape3D = CollisionShape3D.new()
		collider.name = "CollisionShape3D"
		var shape: SphereShape3D = SphereShape3D.new()
		shape.radius = radius * 0.78
		collider.shape = shape
		body.add_child(collider)
		_obstacle_root.add_child(body)


func _terrain_point(x: float, z: float) -> Vector3:
	var crown: float = maxf(0.0, 1.0 - absf(x) / 12.0)
	var shoulder_drop: float = maxf(0.0, absf(x) - tuning.path_width * 0.5) * 0.18
	var low_poly_noise: float = (_noise(int((x + 16.0) * 7.0) + int((z + 80.0) * 5.0)) - 0.5) * 0.12 * crown
	return Vector3(x, height_at_position(x, z) - shoulder_drop + low_poly_noise, z)


func _add_quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var normal: Vector3 = Plane(a, b, c).normal
	for vertex in [a, b, c, a, c, d]:
		surface.set_normal(normal)
		surface.add_vertex(vertex)


func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.free()


func _noise(seed: int) -> float:
	return fposmod(sin(float(seed) * 12.9898) * 43758.5453, 1.0)
