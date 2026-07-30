extends SceneTree

const GateCheckerScript = preload("res://scripts/VerticalSliceGateChecker.gd")

const TMP_DIR := "/tmp/sisyphus-vertical-slice-gate-test"

var failures: Array[String] = []


func _initialize() -> void:
	_run()
	if failures.is_empty():
		print("All vertical slice gate checker tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run() -> void:
	_prepare_tmp()
	test_missing_human_report_keeps_gate_at_pivot()
	test_invalid_report_summaries_explain_why_reports_do_not_count()
	test_automated_baselines_are_classified_separately_from_invalid_human_reports()
	test_ignores_protocol_and_triage_markdown()
	test_filled_proceed_human_report_allows_proceed()
	test_kill_human_report_blocks_gate()
	test_require_proceed_exit_code_fails_pivot()
	_cleanup_tmp()


func test_missing_human_report_keeps_gate_at_pivot() -> void:
	_write_report("playtest-auto.md", "# Playtest Report\n\n## Quantitative Data\n- **Push Gate**: PROCEED\n")
	var result: Dictionary = GateCheckerScript.check_playtest_directory(TMP_DIR)
	_expect_eq(str(result.get("gate", "")), "PIVOT", "automated reports without human gate should not advance the slice")
	_expect_eq(int(result.get("valid_human_reports", -1)), 0, "automated reports should not count as valid human reports")


func test_invalid_report_summaries_explain_why_reports_do_not_count() -> void:
	_prepare_tmp()
	_write_report("playtest-unfilled.md", "\n".join([
		"# Playtest Report",
		"",
		"## Push-Feel Retest Focus",
		"| Check | Pass? | Notes |",
		"|-------|-------|-------|",
		"| Transition sanity: approaching and entering push view does not show long or detached arms. | [Yes/No] | |",
		"",
		"## Human Feel Gate",
		"- **Burden reads as physical labor?**: [Yes/No/Partially]",
		"- **Human Verdict**: [PROCEED/PIVOT/KILL]",
		"- **Verdict Reason**: [Reason]",
	]))
	var result: Dictionary = GateCheckerScript.check_playtest_directory(TMP_DIR)
	var summaries: Array = result.get("invalid_report_summaries", [])
	_expect_true(summaries.size() >= 1, "gate should return invalid report summaries for diagnosis")
	var joined := str(summaries)
	_expect_true(joined.contains("playtest-unfilled.md"), "invalid summary should include unfilled manual report filename")
	_expect_true(joined.contains("unfilled"), "invalid summary should identify unfilled fields or retest rows")


func test_automated_baselines_are_classified_separately_from_invalid_human_reports() -> void:
	_prepare_tmp()
	_write_report("playtest-2026-05-27-auto-route.md", _automated_report("auto-route-current", "Automated baseline"))
	_write_report("playtest-2026-05-27-codex-visual.md", _automated_report("codex-visual", "Automated visual snapshot"))
	_write_report("playtest-2026-05-27-manual-unfilled.md", "\n".join([
		"# Playtest Report",
		"",
		"## Human Feel Gate",
		"- **Burden reads as physical labor?**: [Yes/No/Partially]",
	]))
	var result: Dictionary = GateCheckerScript.check_playtest_directory(TMP_DIR)
	_expect_eq(int(result.get("automated_baseline_reports", -1)), 2, "automated baselines should be counted separately")
	_expect_eq(int(result.get("invalid_human_reports", -1)), 1, "only non-automated invalid reports should count as invalid human reports")
	_expect_eq(int(result.get("invalid_or_automated_reports", -1)), 3, "legacy invalid-or-automated count should remain available")
	var invalid_summaries: Array = result.get("invalid_report_summaries", [])
	var automated_summaries: Array = result.get("automated_report_summaries", [])
	_expect_true(str(invalid_summaries).contains("manual-unfilled"), "invalid summaries should keep manual report errors")
	_expect_true(not str(invalid_summaries).contains("auto-route"), "invalid summaries should not bury automated baselines as missing human gates")
	_expect_true(str(automated_summaries).contains("auto-route"), "automated summaries should list automated baseline filenames")
	_expect_true(str(automated_summaries).contains("codex-visual"), "automated summaries should list automated visual filenames")


func test_ignores_protocol_and_triage_markdown() -> void:
	_prepare_tmp()
	_write_report("README.md", "# Protocol\n")
	_write_report("representative-human-playtest-worksheet.md", "# Worksheet\n")
	_write_report("playtest-manual-01.triage.md", "# Human Playtest Triage\n")
	_write_report("playtest-manual-01.packet.md", "# Representative Human Playtest Packet\n")
	_write_report("notes.md", "# Loose notes\n")
	_write_report("playtest-auto.md", "# Playtest Report\n\n## Quantitative Data\n- **Push Gate**: PROCEED\n")
	var result: Dictionary = GateCheckerScript.check_playtest_directory(TMP_DIR)
	_expect_eq(int(result.get("invalid_or_automated_reports", -1)), 1, "gate should count only actual playtest reports, not protocol docs or triage notes")


func test_filled_proceed_human_report_allows_proceed() -> void:
	_prepare_tmp()
	_write_report("playtest-manual-proceed.md", _human_report("PROCEED", "The loop is heavy, legible, and ready for next slice work."))
	var result: Dictionary = GateCheckerScript.check_playtest_directory(TMP_DIR)
	_expect_eq(str(result.get("gate", "")), "PROCEED", "valid PROCEED human verdict should advance the gate")
	_expect_eq(int(result.get("valid_human_reports", 0)), 1, "valid human report should be counted")


func test_kill_human_report_blocks_gate() -> void:
	_prepare_tmp()
	_write_report("playtest-manual-proceed.md", _human_report("PROCEED", "The route is good enough to continue."))
	_write_report("playtest-manual-kill.md", _human_report("KILL", "The push still feels fake and should block expansion."))
	var result: Dictionary = GateCheckerScript.check_playtest_directory(TMP_DIR)
	_expect_eq(str(result.get("gate", "")), "KILL", "any valid KILL human verdict should block content expansion")
	_expect_true(str(result.get("reason", "")).contains("blocks content expansion"), "kill reason should be explicit")


func test_require_proceed_exit_code_fails_pivot() -> void:
	var pivot_result := {
		"gate": "PIVOT",
	}
	var proceed_result := {
		"gate": "PROCEED",
	}
	_expect_eq(GateCheckerScript.exit_code_for_gate(pivot_result, false), 0, "non-strict gate should allow PIVOT for status reporting")
	_expect_eq(GateCheckerScript.exit_code_for_gate(pivot_result, true), 1, "strict gate should fail PIVOT so milestones cannot advance")
	_expect_eq(GateCheckerScript.exit_code_for_gate(proceed_result, true), 0, "strict gate should pass only PROCEED")


func _human_report(verdict: String, reason: String) -> String:
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
		"| Hand surface: palms stay visually outside the boulder while the contact cue sits on the pressure point. | Yes | Hand surface was readable. |",
		"| Wrist/forearm silhouette: first-person wrist/forearm shapes stay short and do not read as rods crossing through the boulder. | Yes | Wrist shapes stayed short. |",
		"| Look-down check: while pushing, the player can look down enough to inspect hands/contact and then recover forward view. | Yes | Look-down control worked. |",
		"| Peripheral read: while biased left/right, the player can still judge route edges and nearby obstacles from the push view. | Yes | Route edges remained readable. |",
		"| Reticle surface targeting: the center reticle/pressure cue lets the player choose a specific boulder surface point without the hands sinking into it. | Yes | Reticle targeting worked. |",
		"| Aim bias retest: looking left/right changes hand contact and the stone's rolling direction in a way the player can intentionally use. | Yes | Bias felt intentional. |",
		"| Disengage/re-engage: releasing W or backing away returns camera/arms cleanly, and the player can approach the stone again. | Yes | Exit and return worked. |",
		"",
		"## Human Feel Gate",
		"- **Burden reads as physical labor?**: Yes",
		"- **Camera pressure is intense but playable?**: Yes",
		"- **Aim changes hand contact and push direction?**: Yes",
		"- **Release/descent contrast is clear?**: Yes",
		"- **Chapter I End reads as intentional, not unfinished?**: Yes",
		"- **Human Verdict**: %s" % verdict,
		"- **Verdict Reason**: %s" % reason,
	])


func _automated_report(tester: String, session_type: String) -> String:
	return "\n".join([
		"# Playtest Report",
		"",
		"## Session Info",
		"- **Tester**: %s" % tester,
		"- **Input Method**: Automated route driver",
		"- **Session Type**: %s" % session_type,
		"",
		"## Quantitative Data",
		"- **Push Gate**: PROCEED",
		"- **Burden Gate**: PROCEED",
		"- **Slice Gate**: PIVOT",
	])


func _prepare_tmp() -> void:
	_cleanup_tmp()
	DirAccess.make_dir_recursive_absolute(TMP_DIR)


func _cleanup_tmp() -> void:
	if not DirAccess.dir_exists_absolute(TMP_DIR):
		return
	var dir := DirAccess.open(TMP_DIR)
	if dir != null:
		dir.list_dir_begin()
		while true:
			var name := dir.get_next()
			if name.is_empty():
				break
			if not dir.current_is_dir():
				DirAccess.remove_absolute(TMP_DIR.path_join(name))
		dir.list_dir_end()
	DirAccess.remove_absolute(TMP_DIR)


func _write_report(name: String, content: String) -> void:
	var file := FileAccess.open(TMP_DIR.path_join(name), FileAccess.WRITE)
	if file == null:
		failures.append("failed to write test report %s" % name)
		return
	file.store_string(content)


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _expect_eq(actual, expected, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])
