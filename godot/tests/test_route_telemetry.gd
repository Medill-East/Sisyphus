extends SceneTree

const RouteTelemetryScript = preload("res://scripts/RouteTelemetry.gd")
const TuningScript = preload("res://scripts/Tuning.gd")

var failures: Array[String] = []


class FakePushFrame:
	var contact_valid: bool
	var spin_to_translation_ratio: float
	var uphill_direction: Vector3

	func _init(next_contact_valid: bool, next_spin_ratio: float, next_uphill_direction: Vector3 = Vector3(0.0, 0.0, -1.0)) -> void:
		contact_valid = next_contact_valid
		spin_to_translation_ratio = next_spin_ratio
		uphill_direction = next_uphill_direction.normalized()


func _initialize() -> void:
	_run()
	if failures.is_empty():
		print("All route telemetry tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run() -> void:
	test_contact_ratio_and_loss_edges()
	test_hud_summary_reports_route_playtest_numbers()
	test_hud_summary_uses_tuning_for_burden_gate()
	test_push_effort_metrics_track_slow_uphill_work()
	test_push_effort_metrics_count_burden_speed_not_only_stall()
	test_push_effort_uses_tuned_slow_speed_threshold()
	test_burden_gate_returns_kill_when_no_uphill_work()
	test_burden_gate_returns_pivot_for_too_smooth_push()
	test_burden_gate_returns_proceed_for_measurable_labor()
	test_playtest_gate_returns_proceed_for_stable_route()
	test_slice_pacing_gate_returns_pivot_for_compressed_auto_route()
	test_slice_pacing_gate_returns_proceed_for_representative_vertical_slice()
	test_slice_pacing_gate_uses_tuning_duration_window()
	test_non_push_descent_distance_does_not_break_stable_push_gate()
	test_playtest_gate_returns_pivot_for_contact_problems()
	test_playtest_gate_returns_kill_for_broken_push()


func test_contact_ratio_and_loss_edges() -> void:
	var telemetry = RouteTelemetryScript.new()
	var tuning = TuningScript.new()
	telemetry.sample(0.5, "ascent", true, FakePushFrame.new(true, 2.2), Vector3.ZERO, Vector3(0.0, 0.0, 2.0), tuning)
	telemetry.sample(0.5, "ascent", true, FakePushFrame.new(false, 9.5), Vector3.ZERO, Vector3(0.0, 0.0, 4.1), tuning)
	telemetry.sample(0.5, "ascent", true, FakePushFrame.new(false, 8.0), Vector3.ZERO, Vector3(0.0, 0.0, 4.2), tuning)
	telemetry.sample(0.5, "ascent", true, FakePushFrame.new(true, 3.0), Vector3.ZERO, Vector3(0.0, 0.0, 2.1), tuning)
	_expect_near(telemetry.push_held_seconds, 2.0, 0.001, "telemetry should count held push time")
	_expect_near(telemetry.valid_contact_seconds, 1.0, 0.001, "telemetry should count valid contact time")
	_expect_near(telemetry.contact_ratio(), 0.5, 0.001, "contact ratio should be valid contact over held push")
	_expect_eq(telemetry.contact_loss_count, 1, "continuous contact loss should count as one loss event")
	_expect_true(telemetry.max_contact_distance > 4.0, "telemetry should track max player-stone distance")
	_expect_true(telemetry.max_spin_ratio >= 9.5, "telemetry should track worst spin ratio")


func test_hud_summary_reports_route_playtest_numbers() -> void:
	var telemetry = RouteTelemetryScript.new()
	var tuning = TuningScript.new()
	telemetry.sample(1.0, "approach", false, null, Vector3.ZERO, Vector3(0.0, 0.0, 5.0), tuning)
	telemetry.sample(1.0, "ascent", true, FakePushFrame.new(true, 1.4), Vector3.ZERO, Vector3(0.0, 0.0, 2.0), tuning)
	telemetry.sample(1.0, "descent", false, null, Vector3.ZERO, Vector3(0.0, 0.0, 7.0), tuning)
	var summary: String = telemetry.hud_summary()
	_expect_true(summary.contains("Contact"), "HUD summary should include contact ratio")
	_expect_true(summary.contains("Loss"), "HUD summary should include contact loss count")
	_expect_true(summary.contains("Dist"), "HUD summary should include distance")
	_expect_true(summary.contains("Spin"), "HUD summary should include spin ratio")
	_expect_true(summary.contains("descent"), "HUD summary should include latest phase")
	_expect_true(summary.contains("Push"), "HUD summary should include push-contact gate verdict")
	_expect_true(summary.contains("Slice"), "HUD summary should include vertical-slice pacing gate verdict")
	_expect_true(summary.contains("Effort"), "HUD summary should include push effort evidence")
	_expect_true(summary.contains("Burden"), "HUD summary should include burden-feel gate verdict")


func test_hud_summary_uses_tuning_for_burden_gate() -> void:
	var telemetry = RouteTelemetryScript.new()
	var tuning = TuningScript.new()
	tuning.set("burden_fast_average_speed", 0.96)
	tuning.set("burden_min_slow_ratio", 0.30)
	tuning.set("burden_slow_speed_threshold", 0.65)
	var frame := FakePushFrame.new(true, 1.0, Vector3(0.0, 0.0, -1.0))
	telemetry.sample(1.0, "ascent", true, frame, Vector3(0.0, 0.0, 2.0), Vector3(0.0, 0.0, 0.0), tuning)
	for index in 4:
		var stone_position := Vector3(0.0, 0.0, -0.90 * float(index + 1))
		telemetry.sample(1.0, "ascent", true, frame, stone_position + Vector3(0.0, 0.0, 2.0), stone_position, tuning)
	var tuned_summary: String = telemetry.hud_summary(tuning)
	_expect_true(tuned_summary.contains("Burden PIVOT"), "HUD summary should use the same tuning-specific burden gate as the report")


func test_push_effort_metrics_track_slow_uphill_work() -> void:
	var telemetry = RouteTelemetryScript.new()
	var tuning = TuningScript.new()
	var frame := FakePushFrame.new(true, 1.1, Vector3(0.0, 0.0, -1.0))
	telemetry.sample(1.0, "ascent", true, frame, Vector3.ZERO, Vector3(0.0, 0.0, 0.0), tuning)
	telemetry.sample(1.0, "ascent", true, frame, Vector3.ZERO, Vector3(0.0, 0.0, -0.15), tuning)
	telemetry.sample(1.0, "ascent", true, frame, Vector3.ZERO, Vector3(0.0, 0.0, -0.45), tuning)
	_expect_true(telemetry.get("push_motion_sample_seconds") != null, "telemetry should expose push motion sample duration")
	_expect_true(telemetry.get("uphill_push_distance") != null, "telemetry should expose uphill push distance")
	_expect_true(telemetry.get("average_push_uphill_speed") != null, "telemetry should expose average uphill push speed")
	_expect_true(telemetry.get("min_push_uphill_speed") != null, "telemetry should expose minimum uphill push speed")
	_expect_true(telemetry.get("slow_push_seconds") != null, "telemetry should expose low-speed effort duration")
	if telemetry.get("uphill_push_distance") == null:
		return
	_expect_near(telemetry.uphill_push_distance, 0.45, 0.001, "uphill distance should accumulate stone displacement along push uphill")
	_expect_near(telemetry.push_motion_sample_seconds, 2.0, 0.001, "first sample should seed motion without adding fake velocity")
	_expect_near(telemetry.average_push_uphill_speed, 0.225, 0.001, "average uphill speed should be distance over sampled push motion time")
	_expect_near(telemetry.min_push_uphill_speed, 0.15, 0.001, "minimum uphill speed should capture the slowest real push frame")
	_expect_near(telemetry.slow_push_seconds, 2.0, 0.001, "slow push seconds should count frames that read as labor")


func test_push_effort_metrics_count_burden_speed_not_only_stall() -> void:
	var telemetry = RouteTelemetryScript.new()
	var tuning = TuningScript.new()
	var frame := FakePushFrame.new(true, 1.1, Vector3(0.0, 0.0, -1.0))
	telemetry.sample(1.0, "ascent", true, frame, Vector3(0.0, 0.0, 2.0), Vector3(0.0, 0.0, 0.0), tuning)
	telemetry.sample(1.0, "ascent", true, frame, Vector3(0.0, 0.0, 1.40), Vector3(0.0, 0.0, -0.60), tuning)
	telemetry.sample(1.0, "ascent", true, frame, Vector3(0.0, 0.0, 0.60), Vector3(0.0, 0.0, -1.40), tuning)
	_expect_true(telemetry.slow_push_seconds >= 1.0, "burden telemetry should count controlled low-speed labor, not only near-stall frames")


func test_push_effort_uses_tuned_slow_speed_threshold() -> void:
	var telemetry = RouteTelemetryScript.new()
	var tuning = TuningScript.new()
	_expect_true(tuning.get("burden_slow_speed_threshold") != null, "tuning should expose slow-push speed threshold")
	if tuning.get("burden_slow_speed_threshold") == null:
		return
	tuning.set("burden_slow_speed_threshold", 0.90)
	var frame := FakePushFrame.new(true, 1.0, Vector3(0.0, 0.0, -1.0))
	telemetry.sample(1.0, "ascent", true, frame, Vector3(0.0, 0.0, 2.0), Vector3(0.0, 0.0, 0.0), tuning)
	telemetry.sample(1.0, "ascent", true, frame, Vector3(0.0, 0.0, 1.20), Vector3(0.0, 0.0, -0.80), tuning)
	_expect_true(telemetry.slow_push_seconds >= 1.0, "tuned threshold should count controlled sub-threshold push as slow labor")


func test_burden_gate_returns_kill_when_no_uphill_work() -> void:
	var telemetry = RouteTelemetryScript.new()
	var tuning = TuningScript.new()
	var frame := FakePushFrame.new(true, 1.0, Vector3(0.0, 0.0, -1.0))
	for index in 6:
		telemetry.sample(1.0, "ascent", true, frame, Vector3.ZERO, Vector3(0.0, 0.0, 0.0), tuning)
	_expect_true(telemetry.has_method("burden_verdict"), "telemetry should expose a separate burden gate")
	_expect_true(telemetry.has_method("burden_reason"), "telemetry should explain the burden gate")
	if not telemetry.has_method("burden_verdict") or not telemetry.has_method("burden_reason"):
		return
	_expect_eq(telemetry.burden_verdict(tuning), "KILL", "valid contact without uphill work should fail the burden gate")
	_expect_true(telemetry.burden_reason(tuning).contains("no measurable uphill work"), "kill reason should name missing uphill work")


func test_burden_gate_returns_pivot_for_too_smooth_push() -> void:
	var telemetry = RouteTelemetryScript.new()
	var tuning = TuningScript.new()
	var frame := FakePushFrame.new(true, 1.0, Vector3(0.0, 0.0, -1.0))
	telemetry.sample(1.0, "ascent", true, frame, Vector3.ZERO, Vector3(0.0, 0.0, 0.0), tuning)
	for index in 8:
		var stone_position := Vector3(0.0, 0.0, -1.35 * float(index + 1))
		var player_position := stone_position + Vector3(0.0, 0.0, 2.0)
		telemetry.sample(1.0, "ascent", true, frame, player_position, stone_position, tuning)
	_expect_eq(telemetry.playtest_verdict(tuning), "PROCEED", "smooth push can still pass contact stability")
	if not telemetry.has_method("burden_verdict"):
		failures.append("telemetry should expose burden_verdict")
		return
	_expect_eq(telemetry.burden_verdict(tuning), "PIVOT", "too-fast smooth transport should not pass burden feel")
	_expect_true(telemetry.burden_reason(tuning).contains("too smooth"), "pivot reason should name the smooth/fast burden problem")


func test_burden_gate_returns_proceed_for_measurable_labor() -> void:
	var telemetry = RouteTelemetryScript.new()
	var tuning = TuningScript.new()
	var frame := FakePushFrame.new(true, 1.0, Vector3(0.0, 0.0, -1.0))
	var z := 0.0
	telemetry.sample(1.0, "ascent", true, frame, Vector3(0.0, 0.0, 2.0), Vector3(0.0, 0.0, z), tuning)
	for displacement in [0.18, 0.20, 0.60, 0.62, 0.19, 0.58, 0.21, 0.55, 0.20, 0.52]:
		z -= float(displacement)
		var stone_position := Vector3(0.0, 0.0, z)
		var player_position := stone_position + Vector3(0.0, 0.0, 2.0)
		telemetry.sample(1.0, "ascent", true, frame, player_position, stone_position, tuning)
	_expect_eq(telemetry.playtest_verdict(tuning), "PROCEED", "labor-heavy stable route should still pass contact stability")
	if not telemetry.has_method("burden_verdict"):
		failures.append("telemetry should expose burden_verdict")
		return
	_expect_eq(telemetry.burden_verdict(tuning), "PROCEED", "mixed slow and controlled movement should pass burden gate")
	_expect_true(telemetry.burden_reason(tuning).contains("measurable labor"), "proceed reason should name measurable labor")


func test_playtest_gate_returns_proceed_for_stable_route() -> void:
	var telemetry = RouteTelemetryScript.new()
	var tuning = TuningScript.new()
	for index in 20:
		telemetry.sample(1.0, "ascent", true, FakePushFrame.new(true, 2.0), Vector3.ZERO, Vector3(0.0, 0.0, 2.0), tuning)
	telemetry.sample(1.0, "descent", false, null, Vector3.ZERO, Vector3(0.0, 0.0, 3.0), tuning)
	_expect_eq(telemetry.playtest_verdict(tuning), "PROCEED", "stable full route should pass gate")
	_expect_true(telemetry.playtest_reason(tuning).contains("stable"), "proceed reason should mention stable contact")


func test_slice_pacing_gate_returns_pivot_for_compressed_auto_route() -> void:
	var telemetry = RouteTelemetryScript.new()
	var tuning = TuningScript.new()
	for index in 20:
		telemetry.sample(1.0, "ascent", true, FakePushFrame.new(true, 1.2), Vector3.ZERO, Vector3(0.0, 0.0, 2.0), tuning)
	for phase in ["release", "descent", "complete"]:
		telemetry.sample(2.0, phase, false, null, Vector3.ZERO, Vector3(0.0, 0.0, 4.0), tuning)
	_expect_eq(telemetry.playtest_verdict(tuning), "PROCEED", "stable compressed route can still pass the push-contact gate")
	_expect_true(telemetry.has_method("slice_verdict"), "telemetry should expose a separate vertical-slice pacing gate")
	_expect_true(telemetry.has_method("slice_reason"), "telemetry should explain the vertical-slice pacing gate")
	if not telemetry.has_method("slice_verdict") or not telemetry.has_method("slice_reason"):
		return
	_expect_eq(telemetry.slice_verdict(tuning), "PIVOT", "compressed route should not be treated as a representative vertical slice")
	_expect_true(telemetry.slice_reason(tuning).contains("too short"), "compressed route reason should name pacing")


func test_slice_pacing_gate_returns_proceed_for_representative_vertical_slice() -> void:
	var telemetry = RouteTelemetryScript.new()
	var tuning = TuningScript.new()
	for index in 360:
		telemetry.sample(1.0, "ascent", true, FakePushFrame.new(true, 1.6), Vector3.ZERO, Vector3(0.0, 0.0, 2.0), tuning)
	for index in 45:
		telemetry.sample(1.0, "release", false, null, Vector3.ZERO, Vector3(0.0, 0.0, 4.0), tuning)
	for index in 180:
		telemetry.sample(1.0, "descent", false, null, Vector3.ZERO, Vector3(0.0, 0.0, 6.0), tuning)
	telemetry.sample(1.0, "complete", false, null, Vector3.ZERO, Vector3(0.0, 0.0, 6.0), tuning)
	_expect_eq(telemetry.playtest_verdict(tuning), "PROCEED", "representative loop should keep passing the push-contact gate")
	_expect_true(telemetry.has_method("slice_verdict"), "telemetry should expose a separate vertical-slice pacing gate")
	_expect_true(telemetry.has_method("slice_reason"), "telemetry should explain the vertical-slice pacing gate")
	if not telemetry.has_method("slice_verdict") or not telemetry.has_method("slice_reason"):
		return
	_expect_eq(telemetry.slice_verdict(tuning), "PROCEED", "5-10 minute complete loop should pass the vertical-slice pacing gate")
	_expect_true(telemetry.slice_reason(tuning).contains("representative"), "proceed reason should identify representative loop pacing")


func test_slice_pacing_gate_uses_tuning_duration_window() -> void:
	var tuning = TuningScript.new()
	_expect_true(tuning.get("representative_slice_min_seconds") != null, "tuning should expose representative slice minimum duration")
	_expect_true(tuning.get("representative_slice_max_seconds") != null, "tuning should expose representative slice maximum duration")
	if tuning.get("representative_slice_min_seconds") == null or tuning.get("representative_slice_max_seconds") == null:
		return
	tuning.set("representative_slice_min_seconds", 10.0)
	tuning.set("representative_slice_max_seconds", 20.0)

	var telemetry = RouteTelemetryScript.new()
	for index in 12:
		telemetry.sample(1.0, "ascent", true, FakePushFrame.new(true, 1.0), Vector3.ZERO, Vector3(0.0, 0.0, 2.0), tuning)
	telemetry.sample(1.0, "complete", false, null, Vector3.ZERO, Vector3(0.0, 0.0, 3.0), tuning)
	_expect_eq(telemetry.slice_verdict(tuning), "PROCEED", "slice gate should use the configured minimum/maximum representative duration")

	var overlong = RouteTelemetryScript.new()
	for index in 21:
		overlong.sample(1.0, "ascent", true, FakePushFrame.new(true, 1.0), Vector3.ZERO, Vector3(0.0, 0.0, 2.0), tuning)
	overlong.sample(1.0, "complete", false, null, Vector3.ZERO, Vector3(0.0, 0.0, 3.0), tuning)
	_expect_eq(overlong.slice_verdict(tuning), "PIVOT", "slice gate should reject loops longer than the configured representative window")


func test_non_push_descent_distance_does_not_break_stable_push_gate() -> void:
	var telemetry = RouteTelemetryScript.new()
	var tuning = TuningScript.new()
	for index in 20:
		telemetry.sample(1.0, "ascent", true, FakePushFrame.new(true, 1.2), Vector3.ZERO, Vector3(0.0, 0.0, 2.0), tuning)
	for index in 20:
		telemetry.sample(1.0, "descent", false, null, Vector3.ZERO, Vector3(0.0, 0.0, 12.0), tuning)
	telemetry.sample(1.0, "complete", false, null, Vector3.ZERO, Vector3(0.0, 0.0, 16.0), tuning)
	_expect_eq(telemetry.playtest_verdict(tuning), "PROCEED", "descent/free-walk distance should not invalidate prior stable push contact")
	_expect_true(telemetry.max_contact_distance <= tuning.push_disengage_distance + 0.18, "contact distance metric should only track attempted push contact")


func test_playtest_gate_returns_pivot_for_contact_problems() -> void:
	var telemetry = RouteTelemetryScript.new()
	var tuning = TuningScript.new()
	for index in 8:
		telemetry.sample(1.0, "ascent", true, FakePushFrame.new(index % 3 == 0, 5.0), Vector3.ZERO, Vector3(0.0, 0.0, 3.4), tuning)
	telemetry.sample(1.0, "ascent", true, FakePushFrame.new(false, 8.5), Vector3.ZERO, Vector3(0.0, 0.0, 4.3), tuning)
	_expect_eq(telemetry.playtest_verdict(tuning), "PIVOT", "messy but not broken push should request tuning pivot")
	_expect_true(telemetry.playtest_reason(tuning).contains("contact"), "pivot reason should name the contact issue")


func test_playtest_gate_returns_kill_for_broken_push() -> void:
	var telemetry = RouteTelemetryScript.new()
	var tuning = TuningScript.new()
	for index in 10:
		telemetry.sample(1.0, "ascent", true, FakePushFrame.new(false, 16.0), Vector3.ZERO, Vector3(0.0, 0.0, 6.0), tuning)
	_expect_eq(telemetry.playtest_verdict(tuning), "KILL", "broken push should fail the prototype gate")
	_expect_true(telemetry.playtest_reason(tuning).contains("broken"), "kill reason should name broken push")


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _expect_near(actual: float, expected: float, tolerance: float, message: String) -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s: expected %.4f, got %.4f" % [message, expected, actual])
