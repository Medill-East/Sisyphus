class_name Milestone2ReadinessReportBuilder
extends RefCounted


static func build_report(gate_result: Dictionary, generated_at: String, push_intent_diagnostic: Dictionary = {}, current_handoff: Dictionary = {}) -> String:
	var gate := str(gate_result.get("gate", "PIVOT"))
	var reason := str(gate_result.get("reason", "unknown"))
	var valid_count := int(gate_result.get("valid_human_reports", 0))
	var invalid_count := int(gate_result.get("invalid_or_automated_reports", 0))
	var invalid_human_count := int(gate_result.get("invalid_human_reports", invalid_count))
	var automated_count := int(gate_result.get("automated_baseline_reports", 0))
	var selected_report := str(gate_result.get("selected_report", ""))
	var next_action := "Run representative human playtest and fill Human Feel Gate plus Push-Feel Retest Focus, including Reticle surface targeting." if gate != "PROCEED" else "Milestone 2 can proceed to user review after Human Feel Gate and Push-Feel Retest Focus, including Reticle surface targeting, are confirmed."
	var run_context := _recommended_run_context(generated_at, push_intent_diagnostic)
	var run_date := str(run_context.get("date", _date_from_generated_at(generated_at)))
	var tester_id := str(run_context.get("tester_id", "manual-01"))
	var report_path := "production/qa/playtests/playtest-%s-%s.md" % [run_date, tester_id]

	var lines: Array[String] = []
	lines.append("# Milestone 2 Readiness Report")
	lines.append("")
	lines.append("- **Generated At**: %s" % generated_at)
	lines.append("- **Milestone**: Milestone 2 - Vertical Slice Loop")
	lines.append("- **Gate**: %s" % gate)
	lines.append("- **Gate Reason**: %s" % reason)
	lines.append("- **Valid Human Reports**: %d" % valid_count)
	lines.append("- **Invalid Human Reports**: %d" % invalid_human_count)
	lines.append("- **Automated Baseline Reports**: %d" % automated_count)
	lines.append("- **Invalid Or Automated Reports**: %d" % invalid_count)
	lines.append("- **Selected Human Report**: %s" % ("None" if selected_report.is_empty() else selected_report))
	lines.append("")
	_append_invalid_report_diagnostics(lines, gate_result)
	lines.append("")
	_append_automated_baseline_diagnostics(lines, gate_result)
	lines.append("")
	lines.append("## Exit Criteria")
	lines.append("")
	lines.append("- Automated representative route must remain stable.")
	lines.append("- A filled representative human playtest report must pass `Human Feel Gate`.")
	lines.append("- `Push-Feel Retest Focus` rows must be filled and all `Yes` for any human `PROCEED`.")
	lines.append("- `Reticle surface targeting` must be `Yes`: the center reticle/pressure cue lets the player choose a specific boulder surface point without hands sinking into it.")
	lines.append("- `Wrist/forearm silhouette` must be `Yes`: first-person wrist/forearm shapes stay short and do not read as rods crossing through the boulder.")
	lines.append("- `Pressure angle mastery` must be `Yes`: correct pressure angles make progress while bad high/side pressure stalls, slips, or rolls back instead of motoring uphill.")
	lines.append("- `Rollback honesty` must be `Yes`: releasing W or losing contact lets the stone stall or roll downhill under weight.")
	lines.append("- `Visual cue clarity` must be `Yes`: pressure marks, route markers, and descent growth read as in-world feedback rather than unexplained debug clutter.")
	lines.append("- Human `PROCEED` must agree with objective telemetry: representative pacing, complete phase, Push/Burden/Slice gates all `PROCEED`.")
	lines.append("- `complete / Chapter I End` is the stop point for the first loop; do not use a same-scene re-push as a placeholder for Chapter II.")
	lines.append("- Strict gate command must exit successfully: `tools/check_vertical_slice_gate.sh --require-proceed production/qa/playtests`.")
	lines.append("")
	lines.append("## Push Intent Diagnostic Preflight")
	lines.append("")
	if push_intent_diagnostic.is_empty():
		lines.append("- **Push Intent Verdict**: Not run")
		lines.append("- Run `tools/run_representative_playtest.sh --preflight %s %s` before the human session to generate the short hand/contact/camera diagnostic." % [tester_id, run_date])
	else:
		lines.append("- **Report**: `%s`" % str(push_intent_diagnostic.get("path", "")))
		lines.append("- **Push Intent Verdict**: %s" % str(push_intent_diagnostic.get("verdict", "Unknown")))
		lines.append("- **Contact Delta**: %s" % str(push_intent_diagnostic.get("contact_delta", "Unknown")))
		lines.append("- **Force Delta**: %s" % str(push_intent_diagnostic.get("force_delta", "Unknown")))
		lines.append("- **Drift Gap**: %s" % str(push_intent_diagnostic.get("drift_gap", "Unknown")))
		lines.append("- This short diagnostic verifies hand/contact/camera intent; it does not replace `Human Feel Gate` evidence.")
	lines.append("")
	_append_current_handoff_status(lines, current_handoff)
	lines.append("")
	lines.append("## Current Decision")
	lines.append("")
	if gate == "PROCEED":
		lines.append("**PROCEED** - Human and objective evidence are aligned enough to review Milestone 2 exit.")
	elif gate == "KILL":
		lines.append("**KILL** - Content expansion is blocked until the reported issue is redesigned or fixed.")
	else:
		lines.append("**PIVOT** - Milestone 2 remains open. Do not expand toward Alpha content yet.")
	lines.append("")
	lines.append("## Next Action")
	lines.append("")
	lines.append("- %s" % next_action)
	lines.append("")
	lines.append("## Recommended Human Run")
	lines.append("")
	lines.append("Use the current-handoff wrappers so the tester/date and report path come from the active packet:")
	lines.append("")
	lines.append("```bash")
	lines.append("tools/check_current_representative_handoff.sh")
	lines.append("tools/run_current_representative_playtest.sh")
	lines.append("tools/submit_current_representative_playtest_report.sh")
	lines.append("tools/check_milestone2_ready.sh")
	lines.append("```")
	lines.append("")
	lines.append("Resolved fallback commands for the active tester/date:")
	lines.append("")
	lines.append("```bash")
	lines.append("tools/run_representative_playtest.sh --preflight %s %s" % [tester_id, run_date])
	lines.append("tools/run_representative_playtest.sh %s %s" % [tester_id, run_date])
	lines.append("tools/submit_representative_playtest_report.sh %s" % report_path)
	lines.append("tools/check_milestone2_ready.sh")
	lines.append("```")
	lines.append("")
	lines.append("Expected F9 report path: `%s`." % report_path)
	return "\n".join(lines)


static func _append_invalid_report_diagnostics(lines: Array[String], gate_result: Dictionary) -> void:
	var summaries: Array = gate_result.get("invalid_report_summaries", [])
	lines.append("## Invalid Report Diagnostics")
	lines.append("")
	if summaries.is_empty():
		lines.append("- No invalid report details are available.")
		return
	lines.append("These files do not currently count as filled representative human evidence:")
	var limit: int = mini(summaries.size(), 5)
	for index in limit:
		var summary: Dictionary = summaries[index]
		lines.append("- `%s`" % str(summary.get("filename", summary.get("path", ""))))
		var errors: Array = summary.get("errors", [])
		for error in errors:
			lines.append("  - %s" % str(error))
	if summaries.size() > limit:
		lines.append("- ... %d more invalid reports." % (summaries.size() - limit))


static func _append_automated_baseline_diagnostics(lines: Array[String], gate_result: Dictionary) -> void:
	var summaries: Array = gate_result.get("automated_report_summaries", [])
	lines.append("## Automated Baseline Reports")
	lines.append("")
	if summaries.is_empty():
		lines.append("- No automated baseline reports were classified separately.")
		return
	lines.append("These files are useful regression evidence, but they do not count as filled representative human evidence:")
	var limit: int = mini(summaries.size(), 5)
	for index in limit:
		var summary: Dictionary = summaries[index]
		lines.append("- `%s`" % str(summary.get("filename", summary.get("path", ""))))
		var reason := str(summary.get("reason", "automated baseline"))
		if not reason.is_empty():
			lines.append("  - %s" % reason)
	if summaries.size() > limit:
		lines.append("- ... %d more automated baseline reports." % (summaries.size() - limit))


static func _append_current_handoff_status(lines: Array[String], current_handoff: Dictionary) -> void:
	lines.append("## Current Handoff Status")
	lines.append("")
	if current_handoff.is_empty():
		lines.append("- **Handoff Status**: Not checked")
		lines.append("- Run `tools/check_current_representative_handoff.sh` before the human session.")
		return
	lines.append("- **Handoff Status**: %s" % str(current_handoff.get("status", "Unknown")))
	lines.append("- **Handoff Reason**: %s" % str(current_handoff.get("reason", "Unknown")))
	var packet_path := str(current_handoff.get("packet", ""))
	if not packet_path.is_empty():
		lines.append("- **Packet**: `%s`" % packet_path)
	var tester_id := str(current_handoff.get("tester_id", ""))
	if not tester_id.is_empty():
		lines.append("- **Tester**: %s" % tester_id)
	var report_date := str(current_handoff.get("date", ""))
	if not report_date.is_empty():
		lines.append("- **Date**: %s" % report_date)
	var expected_report := str(current_handoff.get("expected_report", ""))
	if not expected_report.is_empty():
		lines.append("- **Expected F9 Report**: `%s`" % expected_report)
	var next_command := str(current_handoff.get("next_command", ""))
	if not next_command.is_empty():
		lines.append("- **Next Command**: `%s`" % next_command)


static func _date_from_generated_at(generated_at: String) -> String:
	var trimmed := generated_at.strip_edges()
	if trimmed.length() >= 10:
		var candidate := trimmed.substr(0, 10)
		if candidate[4] == "-" and candidate[7] == "-":
			return candidate
	return "YYYY-MM-DD"


static func _recommended_run_context(generated_at: String, push_intent_diagnostic: Dictionary) -> Dictionary:
	var fallback_date := _date_from_generated_at(generated_at)
	var context := {
		"date": fallback_date,
		"tester_id": "manual-01",
	}
	var diagnostic_path := str(push_intent_diagnostic.get("path", ""))
	var file_name := diagnostic_path.get_file()
	var prefix := "push-intent-diagnostic-preflight-"
	var suffix := ".md"
	if not file_name.begins_with(prefix) or not file_name.ends_with(suffix):
		return context
	var tail := file_name.substr(prefix.length(), file_name.length() - prefix.length() - suffix.length())
	if tail.length() <= 11:
		return context
	var candidate_date := tail.substr(0, 10)
	if candidate_date[4] != "-" or candidate_date[7] != "-":
		return context
	var candidate_tester := tail.substr(11)
	if candidate_tester.is_empty():
		return context
	context["date"] = candidate_date
	context["tester_id"] = candidate_tester
	return context
