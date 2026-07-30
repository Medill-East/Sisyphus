extends SceneTree

const PlaytestReportBuilderScript = preload("res://scripts/PlaytestReportBuilder.gd")
const RouteTelemetryScript = preload("res://scripts/RouteTelemetry.gd")
const TuningScript = preload("res://scripts/Tuning.gd")
const ValidatorScript = preload("res://scripts/HumanPlaytestReportValidator.gd")

var failures: Array[String] = []


class FakePushFrame:
	var contact_valid: bool = true
	var spin_to_translation_ratio: float = 1.2
	var uphill_direction: Vector3 = Vector3(0.0, 0.0, -1.0)


func _initialize() -> void:
	_run()
	if failures.is_empty():
		print("All human playtest report validator tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run() -> void:
	test_generated_manual_report_requires_human_gate_answers()
	test_generated_manual_report_requires_push_feel_retest_answers()
	test_report_missing_reticle_surface_retest_is_rejected()
	test_report_missing_wrist_forearm_retest_is_rejected()
	test_report_missing_pressure_angle_mastery_retest_is_rejected()
	test_filled_human_gate_report_validates()
	test_invalid_human_verdict_is_rejected()
	test_human_proceed_requires_objective_gates()
	test_human_proceed_requires_all_push_feel_retests_yes()


func test_generated_manual_report_requires_human_gate_answers() -> void:
	var report := _base_report()
	var result: Dictionary = ValidatorScript.validate_report_text(report)
	_expect_true(not bool(result.get("valid", true)), "generated template should not validate until the human gate is filled")
	var errors: Array = result.get("errors", [])
	_expect_true(_contains_error(errors, "unfilled field: Human Verdict"), "validator should reject placeholder human verdict")


func test_generated_manual_report_requires_push_feel_retest_answers() -> void:
	var report := _filled_report("PIVOT")
	report = report.replace("| Transition sanity: approaching and entering push view does not show long or detached arms. | Yes | The arms stayed natural. |", "| Transition sanity: approaching and entering push view does not show long or detached arms. | [Yes/No] | [Notes] |")
	var result: Dictionary = ValidatorScript.validate_report_text(report)
	_expect_true(not bool(result.get("valid", true)), "human report should not validate while push-feel retest fields are placeholders")
	_expect_true(_contains_error(result.get("errors", []), "unfilled push-feel retest: Transition sanity"), "validator should name the unfilled push-feel retest row")


func test_report_missing_reticle_surface_retest_is_rejected() -> void:
	var report := _filled_report("PIVOT")
	report = report.replace("| Reticle surface targeting: the center reticle/pressure cue lets the player choose a specific boulder surface point without the hands sinking into it. | Yes | Reticle pressure point was intentional. |\n", "")
	var result: Dictionary = ValidatorScript.validate_report_text(report)
	_expect_true(not bool(result.get("valid", true)), "human report should not validate without the reticle surface targeting row")
	_expect_true(_contains_error(result.get("errors", []), "missing push-feel retest: Reticle surface targeting"), "validator should name missing reticle surface targeting row")


func test_report_missing_wrist_forearm_retest_is_rejected() -> void:
	var report := _filled_report("PIVOT")
	report = report.replace("| Wrist/forearm silhouette: first-person wrist/forearm shapes stay short and do not read as rods crossing through the boulder. | Yes | Wrist shapes stayed short. |\n", "")
	var result: Dictionary = ValidatorScript.validate_report_text(report)
	_expect_true(not bool(result.get("valid", true)), "human report should not validate without the wrist/forearm silhouette row")
	_expect_true(_contains_error(result.get("errors", []), "missing push-feel retest: Wrist/forearm silhouette"), "validator should name missing wrist/forearm silhouette row")


func test_report_missing_pressure_angle_mastery_retest_is_rejected() -> void:
	var report := _filled_report("PIVOT")
	report = report.replace("| Pressure angle mastery: a centered/sweet pressure angle makes slow progress, while bad high/side pressure stalls, slips, or rolls back instead of motoring uphill. | Yes | Sweet pressure mattered and bad pressure failed. |\n", "")
	var result: Dictionary = ValidatorScript.validate_report_text(report)
	_expect_true(not bool(result.get("valid", true)), "human report should not validate without the pressure-angle mastery row")
	_expect_true(_contains_error(result.get("errors", []), "missing push-feel retest: Pressure angle mastery"), "validator should name missing pressure-angle mastery row")


func test_filled_human_gate_report_validates() -> void:
	var report := _filled_report("PROCEED")
	var result: Dictionary = ValidatorScript.validate_report_text(report)
	_expect_true(bool(result.get("valid", false)), "filled human gate should validate")
	_expect_eq(str(result.get("human_verdict", "")), "PROCEED", "validator should return the human verdict")


func test_invalid_human_verdict_is_rejected() -> void:
	var report := _filled_report("MAYBE")
	var result: Dictionary = ValidatorScript.validate_report_text(report)
	_expect_true(not bool(result.get("valid", true)), "invalid verdict should fail validation")
	_expect_true(_contains_error(result.get("errors", []), "invalid Human Verdict"), "validator should explain invalid verdict")


func test_human_proceed_requires_objective_gates() -> void:
	var report := _filled_report("PROCEED")
	report = report.replace("- **Slice Gate**: PROCEED", "- **Slice Gate**: PIVOT")
	var result: Dictionary = ValidatorScript.validate_report_text(report)
	_expect_true(not bool(result.get("valid", true)), "human proceed should fail if objective telemetry gate disagrees")
	_expect_true(_contains_error(result.get("errors", []), "Human Verdict PROCEED requires Slice Gate PROCEED"), "validator should name the contradictory slice gate")


func test_human_proceed_requires_all_push_feel_retests_yes() -> void:
	var report := _filled_report("PROCEED")
	report = report.replace("| Peripheral read: while biased left/right, the player can still judge route edges and nearby obstacles from the push view. | Yes | Route edges stayed readable. |", "| Peripheral read: while biased left/right, the player can still judge route edges and nearby obstacles from the push view. | No | Player could not judge the route edges. |")
	var result: Dictionary = ValidatorScript.validate_report_text(report)
	_expect_true(not bool(result.get("valid", true)), "human proceed should fail if any push-feel retest is No")
	_expect_true(_contains_error(result.get("errors", []), "Human Verdict PROCEED requires push-feel retest Peripheral read Yes"), "validator should name the contradictory push-feel retest")


func _base_report() -> String:
	return "\n".join([
		"# Playtest Report",
		"",
		"## Session Info",
		"- **Pacing Profile**: representative",
		"",
		"## Quantitative Data",
		"- **Push Gate**: PROCEED",
		"- **Burden Gate**: PROCEED",
		"- **Slice Gate**: PROCEED",
		"- **Phase At End**: complete",
		"",
		"## Push-Feel Retest Focus",
			"| Check | Pass? | Notes |",
			"|-------|-------|-------|",
			"| Transition sanity: approaching and entering push view does not show long or detached arms. | [Yes/No] | [Notes] |",
			"| Embodied approach: approaching the boulder feels like a body leaning in and placing hands before the camera closes, not an instant cut to floating hands. | [Yes/No] | [Notes] |",
			"| Hand surface: palms stay visually outside the boulder while the contact cue sits on the pressure point. | [Yes/No] | [Notes] |",
		"| Wrist/forearm silhouette: first-person wrist/forearm shapes stay short and do not read as rods crossing through the boulder. | [Yes/No] | [Notes] |",
		"| Look-down check: while pushing, the player can look down enough to inspect hands/contact and then recover forward view. | [Yes/No] | [Notes] |",
		"| Peripheral read: while biased left/right, the player can still judge route edges and nearby obstacles from the push view. | [Yes/No] | [Notes] |",
			"| Reticle surface targeting: the center reticle/pressure cue lets the player choose a specific boulder surface point without the hands sinking into it. | [Yes/No] | [Notes] |",
			"| Aim bias retest: looking left/right changes hand contact and the stone's rolling direction in a way the player can intentionally use. | [Yes/No] | [Notes] |",
			"| Pressure angle mastery: a centered/sweet pressure angle makes slow progress, while bad high/side pressure stalls, slips, or rolls back instead of motoring uphill. | [Yes/No] | [Notes] |",
			"| Rollback honesty: releasing W or losing contact lets the stone stall or roll downhill under weight instead of sticking or continuing uphill. | [Yes/No] | [Notes] |",
			"| Visual cue clarity: pressure marks, route markers, and descent growth read as in-world feedback rather than unexplained yellow/blue debug clutter. | [Yes/No] | [Notes] |",
			"| Disengage/re-engage: releasing W or backing away returns camera/arms cleanly, and the player can approach the stone again. | [Yes/No] | [Notes] |",
		"",
		"## Human Feel Gate",
			"- **Burden reads as physical labor?**: [Yes/No/Partially]",
			"- **Camera pressure is intense but playable?**: [Yes/No/Partially]",
			"- **Aim changes hand contact and push direction?**: [Yes/No/Partially]",
			"- **Pressure angle mastery feels learnable?**: [Yes/No/Partially]",
			"- **Stone releases or rolls back when force is wrong?**: [Yes/No/Partially]",
			"- **Release/descent contrast is clear?**: [Yes/No/Partially]",
			"- **Visual cues read as world/pressure, not debug clutter?**: [Yes/No/Partially]",
			"- **Chapter I End reads as intentional, not unfinished?**: [Yes/No/Partially]",
		"- **Human Verdict**: [PROCEED/PIVOT/KILL]",
		"- **Verdict Reason**: [One sentence]",
	])


func _filled_report(verdict: String) -> String:
	var report := _base_report()
	report = report.replace("| Transition sanity: approaching and entering push view does not show long or detached arms. | [Yes/No] | [Notes] |", "| Transition sanity: approaching and entering push view does not show long or detached arms. | Yes | The arms stayed natural. |")
	report = report.replace("| Embodied approach: approaching the boulder feels like a body leaning in and placing hands before the camera closes, not an instant cut to floating hands. | [Yes/No] | [Notes] |", "| Embodied approach: approaching the boulder feels like a body leaning in and placing hands before the camera closes, not an instant cut to floating hands. | Yes | Approach read as a body leaning in. |")
	report = report.replace("| Hand surface: palms stay visually outside the boulder while the contact cue sits on the pressure point. | [Yes/No] | [Notes] |", "| Hand surface: palms stay visually outside the boulder while the contact cue sits on the pressure point. | Yes | Palms stayed outside the boulder. |")
	report = report.replace("| Wrist/forearm silhouette: first-person wrist/forearm shapes stay short and do not read as rods crossing through the boulder. | [Yes/No] | [Notes] |", "| Wrist/forearm silhouette: first-person wrist/forearm shapes stay short and do not read as rods crossing through the boulder. | Yes | Wrist shapes stayed short. |")
	report = report.replace("| Look-down check: while pushing, the player can look down enough to inspect hands/contact and then recover forward view. | [Yes/No] | [Notes] |", "| Look-down check: while pushing, the player can look down enough to inspect hands/contact and then recover forward view. | Yes | Look-down control was readable. |")
	report = report.replace("| Peripheral read: while biased left/right, the player can still judge route edges and nearby obstacles from the push view. | [Yes/No] | [Notes] |", "| Peripheral read: while biased left/right, the player can still judge route edges and nearby obstacles from the push view. | Yes | Route edges stayed readable. |")
	report = report.replace("| Reticle surface targeting: the center reticle/pressure cue lets the player choose a specific boulder surface point without the hands sinking into it. | [Yes/No] | [Notes] |", "| Reticle surface targeting: the center reticle/pressure cue lets the player choose a specific boulder surface point without the hands sinking into it. | Yes | Reticle pressure point was intentional. |")
	report = report.replace("| Aim bias retest: looking left/right changes hand contact and the stone's rolling direction in a way the player can intentionally use. | [Yes/No] | [Notes] |", "| Aim bias retest: looking left/right changes hand contact and the stone's rolling direction in a way the player can intentionally use. | Yes | Aim bias was intentional. |")
	report = report.replace("| Pressure angle mastery: a centered/sweet pressure angle makes slow progress, while bad high/side pressure stalls, slips, or rolls back instead of motoring uphill. | [Yes/No] | [Notes] |", "| Pressure angle mastery: a centered/sweet pressure angle makes slow progress, while bad high/side pressure stalls, slips, or rolls back instead of motoring uphill. | Yes | Sweet pressure mattered and bad pressure failed. |")
	report = report.replace("| Rollback honesty: releasing W or losing contact lets the stone stall or roll downhill under weight instead of sticking or continuing uphill. | [Yes/No] | [Notes] |", "| Rollback honesty: releasing W or losing contact lets the stone stall or roll downhill under weight instead of sticking or continuing uphill. | Yes | Release made the stone stall or roll back. |")
	report = report.replace("| Visual cue clarity: pressure marks, route markers, and descent growth read as in-world feedback rather than unexplained yellow/blue debug clutter. | [Yes/No] | [Notes] |", "| Visual cue clarity: pressure marks, route markers, and descent growth read as in-world feedback rather than unexplained yellow/blue debug clutter. | Yes | Cues read as in-world feedback. |")
	report = report.replace("| Disengage/re-engage: releasing W or backing away returns camera/arms cleanly, and the player can approach the stone again. | [Yes/No] | [Notes] |", "| Disengage/re-engage: releasing W or backing away returns camera/arms cleanly, and the player can approach the stone again. | Yes | Exit and re-entry felt controlled. |")
	report = report.replace("[Yes/No/Partially]", "Yes")
	report = report.replace("[PROCEED/PIVOT/KILL]", verdict)
	report = report.replace("[One sentence]", "The route reads as intentional and physically legible.")
	return report


func _contains_error(errors: Array, needle: String) -> bool:
	for error in errors:
		if str(error).contains(needle):
			return true
	return false


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _expect_eq(actual, expected, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])
