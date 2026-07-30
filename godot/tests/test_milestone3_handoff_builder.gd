extends SceneTree

const HandoffBuilderScript = preload("res://scripts/Milestone3HandoffBuilder.gd")

var failures: Array[String] = []


func _initialize() -> void:
	test_pivot_gate_keeps_alpha_locked()
	test_proceed_gate_creates_alpha_skeleton_handoff()
	test_kill_gate_blocks_steam_production()
	if failures.is_empty():
		print("All Milestone 3 handoff tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func test_pivot_gate_keeps_alpha_locked() -> void:
	var report := HandoffBuilderScript.build_report({
		"gate": "PIVOT",
		"reason": "no filled human playtest report with Human Feel Gate",
		"valid_human_reports": 0,
		"invalid_or_automated_reports": 8,
		"selected_report": "",
	}, "2026-05-26T00:00:00")
	_expect_true(report.contains("**LOCKED**"), "pivot should keep Alpha locked")
	_expect_true(report.contains("Do not enter Alpha"), "pivot handoff should explicitly block Alpha")
	_expect_true(report.contains("None. Keep work focused"), "pivot handoff should have no allowed Alpha work")
	_expect_true(report.contains("representative human `PROCEED` report"), "pivot should name the missing evidence")
	_expect_true(report.contains("Push-Feel Retest Focus"), "pivot handoff should name the required push-feel retest gate")
	_expect_true(report.contains("Reticle surface targeting"), "pivot handoff should explicitly preserve reticle surface targeting before Alpha")
	_expect_true(report.contains("Wrist/forearm silhouette"), "pivot handoff should explicitly preserve first-person wrist/forearm silhouette before Alpha")
	_expect_true(report.contains("Pressure angle mastery"), "pivot handoff should explicitly preserve pressure-angle mastery before Alpha")
	_expect_true(report.contains("Rollback honesty"), "pivot handoff should explicitly preserve rollback honesty before Alpha")
	_expect_true(report.contains("Visual cue clarity"), "pivot handoff should explicitly preserve visual cue clarity before Alpha")


func test_proceed_gate_creates_alpha_skeleton_handoff() -> void:
	var report := HandoffBuilderScript.build_report({
		"gate": "PROCEED",
		"reason": "filled human report approves representative vertical slice",
		"valid_human_reports": 1,
		"invalid_or_automated_reports": 8,
		"selected_report": "/tmp/playtest-manual.md",
	}, "2026-05-26T00:00:00")
	_expect_true(report.contains("**UNLOCKED**"), "proceed should unlock Alpha handoff after review")
	_expect_true(report.contains("/tmp/playtest-manual.md"), "proceed handoff should cite selected human report")
	_expect_true(report.contains("Level 1-7 route profiles"), "proceed handoff should route to campaign skeleton only")
	_expect_true(report.contains("do not rewrite the push controller"), "proceed handoff should preserve push baseline")
	_expect_true(report.contains("save/profile tracking"), "proceed handoff should include Alpha infrastructure")
	_expect_true(report.contains("Push-Feel Retest Focus"), "proceed handoff should preserve the push-feel retest evidence boundary")
	_expect_true(report.contains("Reticle surface targeting"), "proceed handoff should keep reticle surface targeting as protected evidence")
	_expect_true(report.contains("Wrist/forearm silhouette"), "proceed handoff should keep first-person wrist/forearm silhouette as protected evidence")
	_expect_true(report.contains("Pressure angle mastery"), "proceed handoff should keep pressure-angle mastery as protected evidence")
	_expect_true(report.contains("Rollback honesty"), "proceed handoff should keep rollback honesty as protected evidence")
	_expect_true(report.contains("Visual cue clarity"), "proceed handoff should keep visual cue clarity as protected evidence")


func test_kill_gate_blocks_steam_production() -> void:
	var report := HandoffBuilderScript.build_report({
		"gate": "KILL",
		"reason": "filled human report blocks content expansion",
	}, "2026-05-26T00:00:00")
	_expect_true(report.contains("**BLOCKED**"), "kill should block handoff")
	_expect_true(report.contains("Redesign or kill the core loop"), "kill handoff should name redesign/stop path")
	_expect_true(report.contains("Do not enter Alpha"), "kill should not allow Alpha work")


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
