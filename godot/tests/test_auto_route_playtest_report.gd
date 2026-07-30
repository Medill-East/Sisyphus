extends SceneTree

const GameStateScript = preload("res://scripts/GameState.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_run()
	if failures.is_empty():
		print("All auto route playtest report tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run() -> void:
	test_generator_script_exists()
	test_generator_waits_for_complete_loop()
	test_generator_exposes_push_lab_bias_gate_summary()
	test_generator_freezes_route_slice_before_external_gates()
	test_generator_exposes_pacing_profile_application()
	test_generator_scales_frame_budget_with_pacing_profile()
	test_generator_supports_bounded_diagnostic_runs()
	test_generator_reports_environment_response_layer_counts()
	await test_generator_applies_route_checkpoints()
	test_generator_reports_checkpoint_completion_separately()


func test_generator_script_exists() -> void:
	var path := "res://tests/generate_auto_route_playtest_report.gd"
	_expect_true(ResourceLoader.exists(path), "auto route playtest report generator script should exist")
	if ResourceLoader.exists(path):
		var script = load(path)
		_expect_true(script != null, "auto route playtest report generator script should load")


func test_generator_waits_for_complete_loop() -> void:
	var path := "res://tests/generate_auto_route_playtest_report.gd"
	if not ResourceLoader.exists(path):
		return
	var script = load(path)
	_expect_true(script != null, "auto route playtest report generator script should load")
	if script == null:
		return
	var generator = script.new()
	_expect_true(generator.has_method("should_stop_auto_route_report"), "auto route generator should expose its stop condition")
	if not generator.has_method("should_stop_auto_route_report"):
		return
	_expect_true(
		not generator.should_stop_auto_route_report(GameStateScript.Phase.DESCENT),
		"auto route report should not stop at descent because the first loop ends at complete"
	)
	_expect_true(
		generator.should_stop_auto_route_report(GameStateScript.Phase.COMPLETE),
		"auto route report should stop once the first loop reaches complete"
	)
	generator.free()


func test_generator_exposes_push_lab_bias_gate_summary() -> void:
	var path := "res://tests/generate_auto_route_playtest_report.gd"
	if not ResourceLoader.exists(path):
		return
	var script = load(path)
	var generator = script.new()
	_expect_true(generator.has_method("push_lab_gate_summary"), "auto route generator should summarize push-lab bias recovery gate")
	if generator.has_method("push_lab_gate_summary"):
		var summary: Dictionary = generator.push_lab_gate_summary({
			"success": true,
			"max_air_gap": 0.08,
			"recovery_gain": 0.42,
			"max_spin_to_translation_ratio": 2.2,
		}, {
			"success": true,
			"max_air_gap": 0.10,
			"recovery_gain": 0.37,
			"max_spin_to_translation_ratio": 2.5,
		})
		_expect_eq(str(summary.get("verdict", "")), "PROCEED", "left/right lab recovery should proceed")
		_expect_true(str(summary.get("reason", "")).contains("left/right"), "lab gate reason should name two-sided bias recovery")
		_expect_true(summary.has("left") and summary.has("right"), "lab gate summary should preserve per-side evidence")
	generator.free()


func test_generator_freezes_route_slice_before_external_gates() -> void:
	var path := "res://tests/generate_auto_route_playtest_report.gd"
	if not ResourceLoader.exists(path):
		return
	var script = load(path)
	var generator = script.new()
	var route_slice := Node.new()
	route_slice.set_physics_process(true)
	_expect_true(generator.has_method("prepare_slice_for_external_gates"), "auto route generator should freeze the route slice before running PushLab gate")
	if generator.has_method("prepare_slice_for_external_gates"):
		generator.prepare_slice_for_external_gates(route_slice)
		_expect_true(not route_slice.is_physics_processing(), "external PushLab gate should not keep route telemetry ticking")
	route_slice.free()
	generator.free()


func test_generator_exposes_pacing_profile_application() -> void:
	var path := "res://tests/generate_auto_route_playtest_report.gd"
	if not ResourceLoader.exists(path):
		return
	var script = load(path)
	var generator = script.new()
	var route_slice = load("res://scenes/VerticalSlice.tscn").instantiate()
	root.add_child(route_slice)
	await process_frame
	_expect_true(generator.has_method("apply_pacing_profile_to_slice"), "auto route generator should expose pacing profile application")
	if generator.has_method("apply_pacing_profile_to_slice"):
		generator.pacing_profile = "representative"
		generator.apply_pacing_profile_to_slice(route_slice)
		_expect_true(route_slice.tuning.pacing_profile_name == "representative", "generator should apply representative pacing before route automation")
		_expect_true(route_slice.tuning.estimated_loop_seconds_for_current_pacing() >= route_slice.tuning.representative_slice_min_seconds, "representative generator pacing should estimate inside the slice timing window")
	route_slice.queue_free()
	generator.free()


func test_generator_scales_frame_budget_with_pacing_profile() -> void:
	var path := "res://tests/generate_auto_route_playtest_report.gd"
	if not ResourceLoader.exists(path):
		return
	var script = load(path)
	var generator = script.new()
	_expect_true(generator.has_method("max_auto_route_frames_for_slice"), "auto route generator should expose pacing-aware frame budget")
	if generator.has_method("max_auto_route_frames_for_slice"):
		var route_slice = load("res://scenes/VerticalSlice.tscn").instantiate()
		root.add_child(route_slice)
		await process_frame
		generator.pacing_profile = "smoke"
		generator.apply_pacing_profile_to_slice(route_slice)
		var smoke_frames: int = generator.max_auto_route_frames_for_slice(route_slice)
		generator.pacing_profile = "representative"
		generator.apply_pacing_profile_to_slice(route_slice)
		var representative_frames: int = generator.max_auto_route_frames_for_slice(route_slice)
		_expect_true(smoke_frames <= 9000, "smoke route budget should stay short for routine regressions")
		_expect_true(representative_frames >= 24000, "representative route budget should allow a real 5-10 minute loop")
		_expect_true(representative_frames > smoke_frames * 3, "representative route budget should materially exceed smoke budget")
		route_slice.queue_free()
	generator.free()


func test_generator_supports_bounded_diagnostic_runs() -> void:
	var path := "res://tests/generate_auto_route_playtest_report.gd"
	if not ResourceLoader.exists(path):
		return
	var script = load(path)
	var generator = script.new()
	_expect_true(generator.has_method("route_run_status"), "auto route generator should expose bounded run diagnostics")
	_expect_true(generator.has_method("push_lab_skipped_gate"), "auto route generator should expose a skipped PushLab gate result")
	if generator.has_method("route_run_status"):
		var complete_status: Dictionary = generator.route_run_status(GameStateScript.Phase.COMPLETE, 120, 240)
		_expect_true(bool(complete_status.get("complete", false)), "complete phase should report a completed route")
		_expect_eq(str(complete_status.get("reason", "")), "complete", "completed route should say complete")
		var bounded_status: Dictionary = generator.route_run_status(GameStateScript.Phase.ASCENT, 120, 120)
		_expect_true(not bool(bounded_status.get("complete", true)), "bounded ascent run should report incomplete")
		_expect_true(str(bounded_status.get("reason", "")).contains("frame budget"), "bounded run reason should identify frame budget exhaustion")
		_expect_eq(int(bounded_status.get("frames_run", 0)), 120, "bounded run should preserve frames run")
	if generator.has_method("push_lab_skipped_gate"):
		var skipped: Dictionary = generator.push_lab_skipped_gate("bounded representative diagnostic")
		_expect_eq(str(skipped.get("verdict", "")), "SKIPPED", "skipped PushLab gate should not be reported as proceed")
		_expect_true(str(skipped.get("reason", "")).contains("bounded"), "skipped PushLab reason should preserve the reason")
	generator.free()


func test_generator_applies_route_checkpoints() -> void:
	var path := "res://tests/generate_auto_route_playtest_report.gd"
	if not ResourceLoader.exists(path):
		return
	var script = load(path)
	var generator = script.new()
	_expect_true(generator.has_method("apply_route_checkpoint_to_slice"), "auto route generator should expose route checkpoint application")
	if generator.has_method("apply_route_checkpoint_to_slice"):
		var route_slice = load("res://scenes/VerticalSlice.tscn").instantiate()
		root.add_child(route_slice)
		await process_frame
		generator.pacing_profile = "representative"
		generator.apply_pacing_profile_to_slice(route_slice)
		route_slice.apply_visual_mode("route")
		generator.route_checkpoint = "ridge"
		generator.apply_route_checkpoint_to_slice(route_slice)
		_expect_eq(str(route_slice.get("route_checkpoint")), "ridge", "checkpoint should be recorded on the slice")
		_expect_eq(route_slice.game_state.phase, GameStateScript.Phase.ASCENT, "ridge checkpoint should remain an ascent push checkpoint")
		_expect_true(route_slice.stone.global_position.z <= route_slice.tuning.ridge_z + 4.0, "ridge checkpoint should place stone near the representative ridge")
		route_slice.queue_free()
	generator.free()


func test_generator_reports_checkpoint_completion_separately() -> void:
	var path := "res://tests/generate_auto_route_playtest_report.gd"
	if not ResourceLoader.exists(path):
		return
	var script = load(path)
	var generator = script.new()
	_expect_true(generator.has_method("route_run_status"), "auto route generator should expose route status")
	if generator.has_method("route_run_status"):
		var ridge_status: Dictionary = generator.route_run_status(GameStateScript.Phase.DESCENT, 600, 1800, "ridge")
		_expect_true(bool(ridge_status.get("checkpoint_complete", false)), "ridge checkpoint should complete when it reaches descent")
		_expect_true(not bool(ridge_status.get("complete", true)), "ridge checkpoint reaching descent is not a full first-loop completion")
		_expect_true(str(ridge_status.get("checkpoint_target", "")).contains("descent"), "ridge checkpoint should name descent as its diagnostic target")
		var descent_status: Dictionary = generator.route_run_status(GameStateScript.Phase.COMPLETE, 153, 1200, "descent")
		_expect_true(bool(descent_status.get("checkpoint_complete", false)), "descent checkpoint should complete when it reaches chapter complete")
		_expect_true(bool(descent_status.get("complete", false)), "descent checkpoint at complete is also complete phase")
	generator.free()


func test_generator_reports_environment_response_layer_counts() -> void:
	var path := "res://tests/generate_auto_route_playtest_report.gd"
	if not ResourceLoader.exists(path):
		return
	var content := FileAccess.get_file_as_string(ProjectSettings.globalize_path(path))
	_expect_true(content.contains("environment_response_counts"), "auto route report should pass layered environment response counts into the report builder")
	_expect_true(content.contains("Response Layer Counts"), "auto route evidence should print response layer counts")


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])
