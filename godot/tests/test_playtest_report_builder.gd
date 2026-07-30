extends SceneTree

const PlaytestReportBuilderScript = preload("res://scripts/PlaytestReportBuilder.gd")
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
		print("All playtest report builder tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run() -> void:
	test_report_contains_ccgs_sections_and_telemetry_gate()
	test_report_contains_push_effort_metrics()
	test_report_contains_burden_gate()
	test_report_contains_environment_response_layer_counts()
	test_report_routes_smooth_burden_pivot_to_action_items()
	test_report_contains_push_lab_bias_gate_when_available()
	test_report_routes_pivot_gate_to_balance_and_design_actions()


func test_report_contains_ccgs_sections_and_telemetry_gate() -> void:
	var tuning = TuningScript.new()
	var telemetry = RouteTelemetryScript.new()
	for index in 12:
		telemetry.sample(1.0, "ascent", true, FakePushFrame.new(true, 2.0), Vector3.ZERO, Vector3(0.0, 0.0, 2.0), tuning)
	telemetry.sample(1.0, "descent", false, null, Vector3.ZERO, Vector3(0.0, 0.0, 3.0), tuning)
	var report: String = PlaytestReportBuilderScript.build_vertical_slice_report({
		"date": "2026-05-24",
		"build": "local-godot",
		"tester": "manual",
		"platform": "macOS",
		"input_method": "KB+M",
		"session_type": "Targeted test",
	}, telemetry, tuning)
	_expect_true(report.contains("# Playtest Report"), "report should use CCGS playtest heading")
	_expect_true(report.contains("Sisyphus Downhill Vertical Slice"), "report should name the test focus")
	_expect_true(report.contains("- **Pacing Profile**: smoke"), "report should include current route pacing profile")
	_expect_true(report.contains("- **Estimated Pacing Loop**:"), "report should include estimated pacing duration")
	_expect_true(report.contains("Push Gate: PROCEED"), "report should include push-contact gate")
	_expect_true(report.contains("Burden Gate:"), "report should include burden-feel gate")
	_expect_true(report.contains("Slice Gate: PIVOT"), "compressed telemetry should not be reported as full vertical-slice proceed")
	_expect_true(report.contains("too short"), "report should explain compressed slice pacing")
	_expect_true(report.contains("- **Ascent Duration**: 12.0s"), "report should include ascent phase duration for pacing diagnosis")
	_expect_true(report.contains("- **Descent Duration**: 1.0s"), "report should include descent phase duration for pacing diagnosis")
	_expect_true(report.contains("Contact: 100%"), "report should include contact ratio")
	_expect_true(report.contains("## Push-Feel Retest Focus"), "report should include the latest push-feel retest checklist")
	_expect_true(report.contains("Transition sanity"), "report should ask whether arms stay natural during camera transition")
	_expect_true(report.contains("Embodied approach"), "report should ask whether approach reads as a body leaning into the boulder")
	_expect_true(report.contains("Hand surface"), "report should ask whether palms stay outside the boulder")
	_expect_true(report.contains("Wrist/forearm silhouette"), "report should ask whether first-person wrist/forearm shapes avoid rod-like boulder crossing")
	_expect_true(report.contains("Look-down check"), "report should ask whether push view allows looking at hands/contact")
	_expect_true(report.contains("Peripheral read"), "report should ask whether biased push preserves route readability")
	_expect_true(report.contains("Reticle surface targeting"), "report should ask whether the center reticle selects the intended boulder surface")
	_expect_true(report.contains("Aim bias retest"), "report should ask whether aiming changes contact and stone direction")
	_expect_true(report.contains("Pressure angle mastery"), "report should ask whether correct pressure angles matter")
	_expect_true(report.contains("Rollback honesty"), "report should ask whether release/mistake rollback reads physically")
	_expect_true(report.contains("Visual cue clarity"), "report should ask whether non-HUD feedback avoids debug clutter")
	_expect_true(report.contains("Disengage/re-engage"), "report should ask whether push exit and return feel controllable")
	_expect_true(report.contains("## Human Feel Gate"), "report should include a human feel gate before milestone approval")
	_expect_true(report.contains("Burden reads as physical labor?"), "human gate should force subjective burden assessment")
	_expect_true(report.contains("Camera pressure is intense but playable?"), "human gate should force camera comfort assessment")
	_expect_true(report.contains("Aim changes hand contact and push direction?"), "human gate should force aim/contact assessment")
	_expect_true(report.contains("Pressure angle mastery feels learnable?"), "human gate should force pressure-angle mastery assessment")
	_expect_true(report.contains("Stone releases or rolls back when force is wrong?"), "human gate should force rollback honesty assessment")
	_expect_true(report.contains("Release/descent contrast is clear?"), "human gate should force descent contrast assessment")
	_expect_true(report.contains("Visual cues read as world/pressure, not debug clutter?"), "human gate should force visual cue clarity assessment")
	_expect_true(report.contains("Chapter I End reads as intentional"), "human gate should force chapter-end transition assessment")
	_expect_true(report.contains("Human Verdict"), "human gate should collect PROCEED/PIVOT/KILL")
	_expect_true(report.contains("Design changes needed"), "report should include action routing")
	_expect_true(report.contains("Balance adjustments"), "report should include balance routing")
	_expect_true(report.contains("Bug reports"), "report should include bug routing")
	_expect_true(report.contains("Polish items"), "report should include polish routing")
	_expect_true(report.contains("Top 3 Priorities"), "report should include top priorities")
	_expect_true(report.contains("representative 5-10 minute loop"), "compressed slice report should route to representative loop validation")
	_expect_true(report.contains("generated hum"), "report should still route to hum validation now that first-pass audio exists")
	_expect_true(not report.contains("Add first-pass hum audio"), "proceed report should not preserve stale first-pass hum todo")


func test_report_contains_push_effort_metrics() -> void:
	var tuning = TuningScript.new()
	var telemetry = RouteTelemetryScript.new()
	var frame := FakePushFrame.new(true, 1.2, Vector3(0.0, 0.0, -1.0))
	telemetry.sample(1.0, "ascent", true, frame, Vector3.ZERO, Vector3(0.0, 0.0, 0.0), tuning)
	telemetry.sample(1.0, "ascent", true, frame, Vector3.ZERO, Vector3(0.0, 0.0, -0.15), tuning)
	telemetry.sample(1.0, "ascent", true, frame, Vector3.ZERO, Vector3(0.0, 0.0, -0.45), tuning)
	var report: String = PlaytestReportBuilderScript.build_vertical_slice_report({
		"date": "2026-05-24",
		"build": "local-godot",
		"tester": "auto",
		"platform": "macOS",
		"input_method": "Automated route driver",
		"session_type": "Automated baseline",
	}, telemetry, tuning)
	_expect_true(report.contains("- **Uphill Push Distance**: 0.45"), "report should include uphill push distance as effort evidence")
	_expect_true(report.contains("- **Average Push Uphill Speed**: 0.22"), "report should include average push speed")
	_expect_true(report.contains("- **Minimum Push Uphill Speed**: 0.15"), "report should include minimum push speed")
	_expect_true(report.contains("- **Slow Push Duration**: 2.0s"), "report should include slow push duration")


func test_report_contains_burden_gate() -> void:
	var tuning = TuningScript.new()
	var telemetry = RouteTelemetryScript.new()
	var frame := FakePushFrame.new(true, 1.2, Vector3(0.0, 0.0, -1.0))
	var z := 0.0
	telemetry.sample(1.0, "ascent", true, frame, Vector3(0.0, 0.0, 2.0), Vector3(0.0, 0.0, z), tuning)
	for displacement in [0.18, 0.20, 0.60, 0.62, 0.19, 0.58, 0.21, 0.55]:
		z -= float(displacement)
		var stone_position := Vector3(0.0, 0.0, z)
		var player_position := stone_position + Vector3(0.0, 0.0, 2.0)
		telemetry.sample(1.0, "ascent", true, frame, player_position, stone_position, tuning)
	var report: String = PlaytestReportBuilderScript.build_vertical_slice_report({
		"date": "2026-05-24",
		"build": "local-godot",
		"tester": "auto",
		"platform": "macOS",
		"input_method": "Automated route driver",
		"session_type": "Automated baseline",
	}, telemetry, tuning)
	_expect_true(report.contains("- **Burden Gate**: PROCEED"), "report should include burden gate verdict")
	_expect_true(report.contains("- **Burden Gate Reason**: measurable labor"), "report should include burden gate reason")


func test_report_contains_environment_response_layer_counts() -> void:
	var tuning = TuningScript.new()
	var telemetry = RouteTelemetryScript.new()
	var report: String = PlaytestReportBuilderScript.build_vertical_slice_report({
		"date": "2026-05-27",
		"build": "local-godot",
		"tester": "auto",
		"platform": "macOS",
		"input_method": "Automated route driver",
		"session_type": "Automated baseline",
		"environment_response_counts": {
			"scar": 12,
			"water": 3,
			"flower": 4,
			"grass": 5,
		},
	}, telemetry, tuning)
	_expect_true(report.contains("- **Environment Response Layers**: Scar 12 | Water 3 | Flower 4 | Grass 5"), "report should include layered descent world-change counts")
	_expect_true(report.contains("changed the world"), "report should explicitly tie environment response layers to the descent contrast promise")


func test_report_routes_smooth_burden_pivot_to_action_items() -> void:
	var tuning = TuningScript.new()
	var telemetry = RouteTelemetryScript.new()
	var frame := FakePushFrame.new(true, 1.2, Vector3(0.0, 0.0, -1.0))
	telemetry.sample(1.0, "ascent", true, frame, Vector3(0.0, 0.0, 2.0), Vector3.ZERO, tuning)
	for index in 8:
		var stone_position := Vector3(0.0, 0.0, -1.35 * float(index + 1))
		var player_position := stone_position + Vector3(0.0, 0.0, 2.0)
		telemetry.sample(1.0, "ascent", true, frame, player_position, stone_position, tuning)
	var report: String = PlaytestReportBuilderScript.build_vertical_slice_report({
		"date": "2026-05-24",
		"build": "local-godot",
		"tester": "auto",
		"platform": "macOS",
		"input_method": "Automated route driver",
		"session_type": "Automated baseline",
	}, telemetry, tuning)
	_expect_true(report.contains("Push Gate: PROCEED | Burden Gate: PIVOT"), "report should separate stable contact from burden failure")
	_expect_true(report.contains("too smooth/fast"), "report should preserve burden reason")
	_expect_true(report.contains("burden"), "smooth-burden pivot should route action items to burden tuning")


func test_report_contains_push_lab_bias_gate_when_available() -> void:
	var tuning = TuningScript.new()
	var telemetry = RouteTelemetryScript.new()
	for index in 12:
		telemetry.sample(1.0, "ascent", true, FakePushFrame.new(true, 1.4), Vector3.ZERO, Vector3(0.0, 0.0, 2.0), tuning)
	var report: String = PlaytestReportBuilderScript.build_vertical_slice_report({
		"date": "2026-05-24",
		"build": "local-godot",
		"tester": "auto",
		"platform": "macOS",
		"input_method": "Automated route driver",
		"session_type": "Automated baseline",
		"push_lab_gate": {
			"verdict": "PROCEED",
			"reason": "left/right bias recovery passed",
			"left": {
				"success": true,
				"max_air_gap": 0.08,
				"recovery_gain": 0.42,
				"max_spin_to_translation_ratio": 2.6,
			},
			"right": {
				"success": true,
				"max_air_gap": 0.10,
				"recovery_gain": 0.38,
				"max_spin_to_translation_ratio": 2.8,
			},
		},
	}, telemetry, tuning)
	_expect_true(report.contains("- **Push Lab Bias Gate**: PROCEED"), "report should include push-lab bias gate verdict")
	_expect_true(report.contains("left/right bias recovery passed"), "report should include push-lab bias gate reason")
	_expect_true(report.contains("- **Push Lab Left Bias**: pass"), "report should summarize left bias recovery")
	_expect_true(report.contains("- **Push Lab Right Bias**: pass"), "report should summarize right bias recovery")
	_expect_true(report.contains("Recovery 0.42"), "report should include left recovery metric")
	_expect_true(report.contains("Spin 2.8"), "report should include right spin metric")


func test_report_routes_pivot_gate_to_balance_and_design_actions() -> void:
	var tuning = TuningScript.new()
	var telemetry = RouteTelemetryScript.new()
	for index in 6:
		telemetry.sample(1.0, "ascent", true, FakePushFrame.new(index % 2 == 0, 7.0), Vector3.ZERO, Vector3(0.0, 0.0, 3.0), tuning)
	var report: String = PlaytestReportBuilderScript.build_vertical_slice_report({
		"date": "2026-05-24",
		"build": "local-godot",
		"tester": "manual",
		"platform": "macOS",
		"input_method": "KB+M",
		"session_type": "Targeted test",
	}, telemetry, tuning)
	_expect_true(report.contains("Push Gate: PIVOT"), "pivot report should include push gate")
	_expect_true(report.contains("contact"), "pivot report should preserve telemetry reason")
	_expect_true(report.contains("Tune push contact"), "pivot report should route to balance tuning")


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
