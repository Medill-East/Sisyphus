extends SceneTree

const TrailRecorderScript = preload("res://scripts/TrailRecorder.gd")
const EnvironmentResponseScript = preload("res://scripts/EnvironmentResponse.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_run()
	if failures.is_empty():
		print("All trail environment response tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run() -> void:
	test_trail_records_spaced_points_only()
	test_environment_response_spawns_growth_from_trail()
	test_environment_response_layers_scar_growth_and_water()
	test_unstable_trail_can_become_water_response()
	test_environment_response_reads_as_embedded_marks_not_debug_props()


func test_trail_records_spaced_points_only() -> void:
	var recorder = TrailRecorderScript.new()
	recorder.min_spacing = 0.5
	recorder.record(Vector3(0, 0, 0), 1.0, 0.8)
	recorder.record(Vector3(0.1, 0, 0.1), 1.0, 0.8)
	recorder.record(Vector3(0.0, 0, -0.7), 1.0, 0.8)
	_expect_true(recorder.points.size() == 2, "trail should avoid dense duplicate points")
	_expect_true(recorder.points[0].pressure > 0.9, "trail should retain pressure")
	recorder.free()


func test_environment_response_spawns_growth_from_trail() -> void:
	var recorder = TrailRecorderScript.new()
	for index in 6:
		recorder.record(Vector3(0, 0, -float(index)), 1.0, 0.8)
	var response = EnvironmentResponseScript.new()
	response.build_from_trail(recorder.points, 0.9)
	_expect_true(response.response_points.size() >= 4, "descent should have visible response markers")
	_expect_true(response.response_points[0].kind in ["scar", "grass", "flower", "water"], "response kind should be concrete")
	_expect_true(response.has_method("visual_style") and response.visual_style() == "embedded_low_saturation", "response visuals should read as embedded world marks, not colored debug props")
	_expect_true(response.get_child_count() == response.response_points.size(), "response should create one visible marker per response point")
	var first_marker = response.get_child(0)
	_expect_true(first_marker is MeshInstance3D and first_marker.material_override != null, "response markers should have readable visual material")
	recorder.free()
	response.free()


func test_environment_response_layers_scar_growth_and_water() -> void:
	var recorder = TrailRecorderScript.new()
	recorder.record(Vector3(0, 0, 0), 1.0, 0.25)
	recorder.record(Vector3(0, 0, -0.7), 1.0, 0.82)
	recorder.record(Vector3(0, 0, -1.4), 1.0, 0.86)
	recorder.record(Vector3(0, 0, -2.1), 1.0, 0.30)
	recorder.record(Vector3(0, 0, -2.8), 1.0, 0.88)
	var response = EnvironmentResponseScript.new()
	response.build_from_trail(recorder.points, 0.9)
	_expect_true(response.has_method("kind_counts"), "environment response should expose response kind counts for reports/tests")
	var counts: Dictionary = response.kind_counts() if response.has_method("kind_counts") else {}
	_expect_true(int(counts.get("scar", 0)) >= recorder.points.size(), "every pushed trail point should leave a visible scar layer")
	_expect_true(int(counts.get("water", 0)) >= 2, "unstable trail sections should become readable water scars")
	_expect_true(int(counts.get("flower", 0)) >= 2, "clear daylight descent should add flower rewards along stable trail")
	_expect_true(response.response_points.size() > recorder.points.size(), "descent response should layer multiple environment changes, not one marker per point")
	recorder.free()
	response.free()


func test_unstable_trail_can_become_water_response() -> void:
	var recorder = TrailRecorderScript.new()
	recorder.record(Vector3(0, 0, 0), 1.0, 0.2)
	recorder.record(Vector3(0, 0, -1.0), 1.0, 0.2)
	var response = EnvironmentResponseScript.new()
	response.build_from_trail(recorder.points, 0.3)
	var counts: Dictionary = response.kind_counts() if response.has_method("kind_counts") else {}
	_expect_true(int(counts.get("water", 0)) >= 1, "unstable low-daylight trail should become a water scar")
	recorder.free()
	response.free()


func test_environment_response_reads_as_embedded_marks_not_debug_props() -> void:
	var recorder = TrailRecorderScript.new()
	for index in 8:
		var stability: float = 0.25 if index % 3 == 0 else 0.86
		recorder.record(Vector3(0, 0, -float(index) * 0.7), 1.0, stability)
	var response = EnvironmentResponseScript.new()
	response.build_from_trail(recorder.points, 0.9)
	_expect_true(response.get_child_count() == response.response_points.size(), "embedded response should still create one marker per response point")
	for index in response.get_child_count():
		var marker = response.get_child(index)
		var point = response.response_points[index]
		if marker is MeshInstance3D:
			_expect_true(
				marker.position.y - point.position.y <= 0.05,
				"response marker should stay embedded near the terrain, not float above it"
			)
			var material = marker.material_override
			if material is StandardMaterial3D:
				var color: Color = material.albedo_color
				var saturation_hint: float = maxf(color.r, maxf(color.g, color.b)) - minf(color.r, minf(color.g, color.b))
				_expect_true(saturation_hint < 0.24, "response marker colors should be low-saturation terrain feedback, not yellow/blue debug colors")
				_expect_true(color.a <= 0.75, "response marker should be subtle enough to read as residue, not UI")
	recorder.free()
	response.free()


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
