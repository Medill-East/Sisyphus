extends SceneTree

const ReportBuilderScript = preload("res://scripts/Milestone2ReadinessReportBuilder.gd")

var failures: Array[String] = []


func _initialize() -> void:
	test_pivot_report_blocks_alpha_expansion()
	test_report_includes_latest_push_intent_diagnostic_summary()
	test_report_includes_current_handoff_status()
	test_report_includes_ready_to_submit_handoff_status()
	test_proceed_report_routes_to_review()
	if failures.is_empty():
		print("All Milestone 2 readiness report tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func test_pivot_report_blocks_alpha_expansion() -> void:
	var report := ReportBuilderScript.build_report({
		"gate": "PIVOT",
		"reason": "no filled human playtest report with Human Feel Gate",
		"valid_human_reports": 0,
		"invalid_or_automated_reports": 8,
		"invalid_human_reports": 1,
		"automated_baseline_reports": 7,
		"selected_report": "",
		"invalid_report_summaries": [
			{
				"filename": "playtest-manual-unfilled.md",
				"errors": ["unfilled field: Human Verdict"],
			},
		],
		"automated_report_summaries": [
			{
				"filename": "playtest-auto-route.md",
				"reason": "automated baseline; useful regression evidence but not filled representative human evidence",
			},
		],
	}, "2026-05-26T00:00:00")
	_expect_true(report.contains("# Milestone 2 Readiness Report"), "readiness report should have a stable heading")
	_expect_true(report.contains("- **Gate**: PIVOT"), "readiness report should include gate")
	_expect_true(report.contains("no filled human playtest report"), "readiness report should include gate reason")
	_expect_true(report.contains("- **Invalid Human Reports**: 1"), "readiness report should separate invalid human report count")
	_expect_true(report.contains("- **Automated Baseline Reports**: 7"), "readiness report should separate automated baseline count")
	_expect_true(report.contains("Milestone 2 remains open"), "PIVOT report should block milestone exit")
	_expect_true(report.contains("Do not expand toward Alpha content yet"), "PIVOT report should prevent content expansion")
	_expect_true(report.contains("complete / Chapter I End"), "readiness report should preserve first-loop chapter boundary")
	_expect_true(report.contains("placeholder for Chapter II"), "readiness report should not allow same-scene re-push as transition")
	_expect_true(report.contains("Push-Feel Retest Focus"), "readiness report should include push-feel retest as an exit criterion")
	_expect_true(report.contains("Reticle surface targeting"), "readiness report should explicitly include reticle surface targeting as a push-feel exit criterion")
	_expect_true(report.contains("Wrist/forearm silhouette"), "readiness report should explicitly include the latest first-person wrist/forearm silhouette retest")
	_expect_true(report.contains("Pressure angle mastery"), "readiness report should explicitly include pressure-angle mastery as a push-feel exit criterion")
	_expect_true(report.contains("Rollback honesty"), "readiness report should explicitly include rollback honesty as a push-feel exit criterion")
	_expect_true(report.contains("Visual cue clarity"), "readiness report should explicitly include visual cue clarity as a push-feel exit criterion")
	_expect_true(report.contains("all `Yes`"), "readiness report should require all push-feel retests to pass before milestone exit")
	_expect_true(report.contains("## Recommended Human Run"), "readiness report should include an executable human-run section")
	_expect_true(report.contains("tools/check_current_representative_handoff.sh"), "readiness report should recommend current handoff status check first")
	_expect_true(report.contains("tools/run_current_representative_playtest.sh"), "readiness report should recommend the current handoff run wrapper")
	_expect_true(report.contains("tools/submit_current_representative_playtest_report.sh"), "readiness report should recommend the current handoff submit wrapper")
	_expect_true(report.contains("Resolved fallback commands"), "readiness report should keep concrete fallback commands for reproducibility")
	_expect_true(report.contains("tools/run_representative_playtest.sh --preflight manual-01 2026-05-26"), "readiness report should include the preflight command")
	_expect_true(report.contains("tools/run_representative_playtest.sh manual-01 2026-05-26"), "readiness report should include the representative run command")
	_expect_true(report.contains("production/qa/playtests/playtest-2026-05-26-manual-01.md"), "readiness report should name the expected F9 report path")
	_expect_true(report.contains("tools/submit_representative_playtest_report.sh production/qa/playtests/playtest-2026-05-26-manual-01.md"), "readiness report should include the one-step submit command")
	_expect_true(report.contains("## Invalid Report Diagnostics"), "readiness report should explain why current reports do not count")
	_expect_true(report.contains("playtest-manual-unfilled.md"), "readiness report should include unfilled report filenames")
	_expect_true(report.contains("unfilled field: Human Verdict"), "readiness report should include concrete invalid human report reasons")
	_expect_true(report.contains("## Automated Baseline Reports"), "readiness report should list automated baselines separately")
	_expect_true(report.contains("playtest-auto-route.md"), "readiness report should include automated baseline filenames")
	_expect_true(report.contains("useful regression evidence"), "readiness report should explain automated baselines are not human evidence")


func test_report_includes_latest_push_intent_diagnostic_summary() -> void:
	var report := ReportBuilderScript.build_report({
		"gate": "PIVOT",
		"reason": "no filled human playtest report with Human Feel Gate",
		"valid_human_reports": 0,
		"invalid_or_automated_reports": 8,
		"selected_report": "",
	}, "2026-05-27T00:00:00", {
		"path": "production/qa/playtests/push-intent-diagnostic-preflight-2026-05-27-manual-02.md",
		"verdict": "PROCEED",
		"contact_delta": "0.80",
		"force_delta": "88.03",
		"drift_gap": "1.27",
	})
	_expect_true(report.contains("## Push Intent Diagnostic Preflight"), "readiness report should include the latest short intent diagnostic")
	_expect_true(report.contains("push-intent-diagnostic-preflight-2026-05-27-manual-02.md"), "readiness report should link the diagnostic report path")
	_expect_true(report.contains("- **Push Intent Verdict**: PROCEED"), "readiness report should include diagnostic verdict")
	_expect_true(report.contains("- **Contact Delta**: 0.80"), "readiness report should include contact delta")
	_expect_true(report.contains("- **Force Delta**: 88.03"), "readiness report should include force delta")
	_expect_true(report.contains("- **Drift Gap**: 1.27"), "readiness report should include real drift gap")
	_expect_true(report.contains("does not replace `Human Feel Gate`"), "readiness report should preserve the human-gate boundary")
	_expect_true(report.contains("tools/check_current_representative_handoff.sh"), "readiness report should recommend checking the current handoff")
	_expect_true(report.contains("tools/run_current_representative_playtest.sh"), "readiness report should recommend the current wrapper command")
	_expect_true(report.contains("tools/submit_current_representative_playtest_report.sh"), "readiness report should recommend the current submit wrapper")
	_expect_true(report.contains("tools/run_representative_playtest.sh --preflight manual-02 2026-05-27"), "readiness report should reuse the latest preflight tester in the recommended command")
	_expect_true(report.contains("tools/run_representative_playtest.sh manual-02 2026-05-27"), "readiness report should reuse the latest preflight tester in the human run command")
	_expect_true(report.contains("production/qa/playtests/playtest-2026-05-27-manual-02.md"), "readiness report should name the expected report for the latest preflight tester")


func test_report_includes_current_handoff_status() -> void:
	var report := ReportBuilderScript.build_report({
		"gate": "PIVOT",
		"reason": "no filled human playtest report with Human Feel Gate",
	}, "2026-05-27T00:00:00", {}, {
		"status": "READY_FOR_HUMAN_RUN",
		"reason": "preflight evidence is present; expected F9 report is not present yet",
		"packet": "production/qa/playtests/playtest-2026-05-27-manual-02.packet.md",
		"tester_id": "manual-02",
		"date": "2026-05-27",
		"expected_report": "production/qa/playtests/playtest-2026-05-27-manual-02.md",
		"next_command": "tools/run_current_representative_playtest.sh",
	})
	_expect_true(report.contains("## Current Handoff Status"), "readiness report should include the current handoff status section")
	_expect_true(report.contains("- **Handoff Status**: READY_FOR_HUMAN_RUN"), "readiness report should show ready-for-human-run status")
	_expect_true(report.contains("expected F9 report is not present yet"), "readiness report should name the missing F9 report reason")
	_expect_true(report.contains("playtest-2026-05-27-manual-02.packet.md"), "readiness report should link the active packet")
	_expect_true(report.contains("- **Tester**: manual-02"), "readiness report should show active tester")
	_expect_true(report.contains("- **Date**: 2026-05-27"), "readiness report should show active date")
	_expect_true(report.contains("- **Expected F9 Report**: `production/qa/playtests/playtest-2026-05-27-manual-02.md`"), "readiness report should show expected F9 report")
	_expect_true(report.contains("- **Next Command**: `tools/run_current_representative_playtest.sh`"), "readiness report should show current next command")


func test_report_includes_ready_to_submit_handoff_status() -> void:
	var report := ReportBuilderScript.build_report({
		"gate": "PIVOT",
		"reason": "human report exists but gate has not passed",
	}, "2026-05-27T00:00:00", {}, {
		"status": "READY_TO_SUBMIT",
		"reason": "F9 report and screenshot exist; submit after required human fields are filled",
		"expected_report": "production/qa/playtests/playtest-2026-05-27-manual-02.md",
		"next_command": "tools/submit_current_representative_playtest_report.sh",
	})
	_expect_true(report.contains("- **Handoff Status**: READY_TO_SUBMIT"), "readiness report should show ready-to-submit status")
	_expect_true(report.contains("submit after required human fields are filled"), "readiness report should preserve the manual field-fill boundary")
	_expect_true(report.contains("tools/submit_current_representative_playtest_report.sh"), "readiness report should route to the current submit wrapper")


func test_proceed_report_routes_to_review() -> void:
	var report := ReportBuilderScript.build_report({
		"gate": "PROCEED",
		"reason": "filled human report approves representative vertical slice",
		"valid_human_reports": 1,
		"invalid_or_automated_reports": 8,
		"selected_report": "/tmp/playtest.md",
	}, "2026-05-26T00:00:00")
	_expect_true(report.contains("**PROCEED**"), "PROCEED report should mark milestone review path")
	_expect_true(report.contains("Milestone 2 can proceed to user review"), "PROCEED report should route to user review")
	_expect_true(report.contains("/tmp/playtest.md"), "PROCEED report should name selected human evidence")
	_expect_true(report.contains("Human Feel Gate and Push-Feel Retest Focus"), "PROCEED report should name both human evidence gates")
	_expect_true(report.contains("Reticle surface targeting"), "PROCEED report should preserve reticle surface targeting as review evidence")


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
