extends SceneTree

const TriageBuilderScript = preload("res://scripts/HumanPlaytestTriageBuilder.gd")

var failures: Array[String] = []


func _initialize() -> void:
	test_invalid_report_routes_to_no_decision()
	test_pivot_burden_report_routes_to_burden_tuning()
	test_pivot_retest_report_routes_to_push_camera_readability()
	test_pivot_reticle_report_routes_to_aim_control()
	test_kill_report_blocks_content_expansion()
	test_proceed_report_routes_to_milestone_review()
	if failures.is_empty():
		print("All human playtest triage tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func test_invalid_report_routes_to_no_decision() -> void:
	var report := _base_report("PROCEED")
	var triage := TriageBuilderScript.build_triage(report, "/tmp/report.md", "2026-05-26T00:00:00")
	_expect_true(triage.contains("**Validation**: FAIL"), "unfilled template should fail triage validation")
	_expect_true(triage.contains("**NO DECISION**"), "invalid report should not create a milestone decision")
	_expect_true(triage.contains("Fill every Human Feel Gate field"), "invalid report should route to filling human fields")
	_expect_true(triage.contains("Fill every Push-Feel Retest Focus row"), "invalid report should route to filling push-feel retest rows")


func test_pivot_burden_report_routes_to_burden_tuning() -> void:
	var report := _filled_report("PIVOT", "Partially", "Yes", "Yes", "Yes", "Yes")
	var triage := TriageBuilderScript.build_triage(report, "/tmp/report.md", "2026-05-26T00:00:00")
	_expect_true(triage.contains("**Human Verdict**: PIVOT"), "triage should preserve human pivot verdict")
	_expect_true(triage.contains("Sustained burden and stone weight"), "burden concern should become primary focus")
	_expect_true(triage.contains("Create one focused tuning task"), "pivot report should route to one focused tuning task")


func test_pivot_retest_report_routes_to_push_camera_readability() -> void:
	var report := _filled_report("PIVOT", "Yes", "Yes", "Yes", "Yes", "Yes")
	report = report.replace("| Peripheral read: while biased left/right, the player can still judge route edges and nearby obstacles from the push view. | Yes | Route edges remained readable. |", "| Peripheral read: while biased left/right, the player can still judge route edges and nearby obstacles from the push view. | No | Route edges were hard to judge. |")
	var triage := TriageBuilderScript.build_triage(report, "/tmp/report.md", "2026-05-26T00:00:00")
	_expect_true(triage.contains("**Human Verdict**: PIVOT"), "triage should preserve human pivot verdict")
	_expect_true(triage.contains("Push camera peripheral readability"), "peripheral-read retest failure should become primary focus")
	_expect_true(triage.contains("Peripheral read: No"), "triage should list failed push-feel retest rows as feel risks")


func test_pivot_reticle_report_routes_to_aim_control() -> void:
	var report := _filled_report("PIVOT", "Yes", "Yes", "Yes", "Yes", "Yes")
	report = report.replace("| Reticle surface targeting: the center reticle/pressure cue lets the player choose a specific boulder surface point without the hands sinking into it. | Yes | Reticle targeting worked. |", "| Reticle surface targeting: the center reticle/pressure cue lets the player choose a specific boulder surface point without the hands sinking into it. | No | Could not choose a pressure point. |")
	var triage := TriageBuilderScript.build_triage(report, "/tmp/report.md", "2026-05-26T00:00:00")
	_expect_true(triage.contains("Push contact and reticle aim-control feel"), "reticle targeting failure should become primary focus")
	_expect_true(triage.contains("Reticle surface targeting: No"), "triage should list failed reticle row as a feel risk")


func test_kill_report_blocks_content_expansion() -> void:
	var report := _filled_report("KILL", "No", "Yes", "Partially", "Yes", "Yes")
	var triage := TriageBuilderScript.build_triage(report, "/tmp/report.md", "2026-05-26T00:00:00")
	_expect_true(triage.contains("**KILL**"), "kill report should surface kill decision")
	_expect_true(triage.contains("Do not add levels"), "kill report should block content expansion")


func test_proceed_report_routes_to_milestone_review() -> void:
	var report := _filled_report("PROCEED", "Yes", "Yes", "Yes", "Yes", "Yes")
	var triage := TriageBuilderScript.build_triage(report, "/tmp/report.md", "2026-05-26T00:00:00")
	_expect_true(triage.contains("**Validation**: PASS"), "valid proceed report should pass validation")
	_expect_true(triage.contains("PROCEED CANDIDATE"), "proceed report should route to milestone review")
	_expect_true(triage.contains("tools/check_milestone2_ready.sh"), "proceed report should name the strict gate command")


func _base_report(verdict: String) -> String:
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
		"- **Human Verdict**: %s" % verdict,
		"- **Verdict Reason**: The report is being checked for milestone routing.",
	])


func _filled_report(verdict: String, burden: String, camera: String, aim: String, descent: String, chapter_end: String) -> String:
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
			"| Transition sanity: approaching and entering push view does not show long or detached arms. | Yes | Arms stayed connected. |",
			"| Embodied approach: approaching the boulder feels like a body leaning in and placing hands before the camera closes, not an instant cut to floating hands. | Yes | Approach read as a body leaning in. |",
			"| Hand surface: palms stay visually outside the boulder while the contact cue sits on the pressure point. | Yes | Hand surface was readable. |",
		"| Wrist/forearm silhouette: first-person wrist/forearm shapes stay short and do not read as rods crossing through the boulder. | Yes | Wrist shapes stayed short. |",
		"| Look-down check: while pushing, the player can look down enough to inspect hands/contact and then recover forward view. | Yes | Look-down control worked. |",
		"| Peripheral read: while biased left/right, the player can still judge route edges and nearby obstacles from the push view. | Yes | Route edges remained readable. |",
			"| Reticle surface targeting: the center reticle/pressure cue lets the player choose a specific boulder surface point without the hands sinking into it. | Yes | Reticle targeting worked. |",
			"| Aim bias retest: looking left/right changes hand contact and the stone's rolling direction in a way the player can intentionally use. | Yes | Bias felt intentional. |",
			"| Pressure angle mastery: a centered/sweet pressure angle makes slow progress, while bad high/side pressure stalls, slips, or rolls back instead of motoring uphill. | Yes | Sweet pressure mattered and bad pressure failed. |",
			"| Rollback honesty: releasing W or losing contact lets the stone stall or roll downhill under weight instead of sticking or continuing uphill. | Yes | Release made the stone stall or roll back. |",
			"| Visual cue clarity: pressure marks, route markers, and descent growth read as in-world feedback rather than unexplained yellow/blue debug clutter. | Yes | Cues read as in-world feedback. |",
			"| Disengage/re-engage: releasing W or backing away returns camera/arms cleanly, and the player can approach the stone again. | Yes | Exit and return worked. |",
		"",
		"## Human Feel Gate",
			"- **Burden reads as physical labor?**: %s" % burden,
			"- **Camera pressure is intense but playable?**: %s" % camera,
			"- **Aim changes hand contact and push direction?**: %s" % aim,
			"- **Pressure angle mastery feels learnable?**: Yes",
			"- **Stone releases or rolls back when force is wrong?**: Yes",
			"- **Release/descent contrast is clear?**: %s" % descent,
			"- **Visual cues read as world/pressure, not debug clutter?**: Yes",
		"- **Chapter I End reads as intentional, not unfinished?**: %s" % chapter_end,
		"- **Human Verdict**: %s" % verdict,
		"- **Verdict Reason**: The run gives a clear next step for the core loop.",
	])


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
