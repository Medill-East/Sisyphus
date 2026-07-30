class_name HumanPlaytestTriageBuilder
extends RefCounted

const ValidatorScript = preload("res://scripts/HumanPlaytestReportValidator.gd")


static func build_triage(report_text: String, source_path: String, generated_at: String) -> String:
	var validation: Dictionary = ValidatorScript.validate_report_text(report_text)
	var human_verdict := str(validation.get("human_verdict", ""))
	var verdict_reason := str(validation.get("verdict_reason", ""))
	var valid := bool(validation.get("valid", false))
	var push_gate := _field_value(report_text, "Push Gate")
	var burden_gate := _field_value(report_text, "Burden Gate")
	var slice_gate := _field_value(report_text, "Slice Gate")
	var phase := _field_value(report_text, "Phase At End")
	var pacing := _field_value(report_text, "Pacing Profile")
	var focus := _primary_focus(report_text, valid, human_verdict, push_gate, burden_gate, slice_gate)

	var lines: Array[String] = []
	lines.append("# Human Playtest Triage")
	lines.append("")
	lines.append("- **Generated At**: %s" % generated_at)
	lines.append("- **Source Report**: %s" % source_path)
	lines.append("- **Validation**: %s" % ("PASS" if valid else "FAIL"))
	lines.append("- **Human Verdict**: %s" % ("None" if human_verdict.is_empty() else human_verdict))
	lines.append("- **Verdict Reason**: %s" % ("None" if verdict_reason.is_empty() else verdict_reason))
	lines.append("- **Primary Focus**: %s" % focus)
	lines.append("")
	lines.append("## Objective Gates")
	lines.append("")
	lines.append("- **Pacing Profile**: %s" % _fallback(pacing, "Unknown"))
	lines.append("- **Phase At End**: %s" % _fallback(phase, "Unknown"))
	lines.append("- **Push Gate**: %s" % _fallback(push_gate, "Unknown"))
	lines.append("- **Burden Gate**: %s" % _fallback(burden_gate, "Unknown"))
	lines.append("- **Slice Gate**: %s" % _fallback(slice_gate, "Unknown"))
	lines.append("")
	lines.append("## Feel Risks")
	lines.append("")
	var risks := _feel_risks(report_text)
	if risks.is_empty():
		lines.append("- None reported in filled Human Feel Gate.")
	else:
		for risk in risks:
			lines.append("- %s" % risk)
	lines.append("")
	lines.append("## Decision")
	lines.append("")
	lines.append(_decision_text(valid, human_verdict, focus))
	lines.append("")
	lines.append("## Next Actions")
	lines.append("")
	for action in _next_actions(valid, human_verdict, focus):
		lines.append("- %s" % action)
	if not valid:
		lines.append("")
		lines.append("## Validation Errors")
		lines.append("")
		for error in validation.get("errors", []):
			lines.append("- %s" % str(error))
	return "\n".join(lines)


static func _primary_focus(report_text: String, valid: bool, human_verdict: String, push_gate: String, burden_gate: String, slice_gate: String) -> String:
	if not valid:
		return "Collect a valid filled human report before deciding milestone direction."
	if human_verdict == "KILL":
		return "Core loop redesign before content expansion."
	var retest_focus := _push_feel_retest_focus(report_text)
	if not retest_focus.is_empty():
		return retest_focus
	if push_gate == "KILL" or push_gate == "PIVOT" or _feel_answer(report_text, "Aim changes hand contact and push direction?") != "Yes":
		return "Push contact and aim-control feel."
	if _feel_answer(report_text, "Pressure angle mastery feels learnable?") != "Yes":
		return "Pressure-angle mastery and sweet-spot legibility."
	if _feel_answer(report_text, "Stone releases or rolls back when force is wrong?") != "Yes":
		return "Rollback honesty and release physics."
	if burden_gate != "PROCEED" or _feel_answer(report_text, "Burden reads as physical labor?") != "Yes":
		return "Sustained burden and stone weight."
	if _feel_answer(report_text, "Camera pressure is intense but playable?") != "Yes":
		return "Push camera pressure and comfort."
	if _feel_answer(report_text, "Release/descent contrast is clear?") != "Yes":
		return "Release, descent, and emotional contrast."
	if _feel_answer(report_text, "Visual cues read as world/pressure, not debug clutter?") != "Yes":
		return "In-world visual cue readability."
	if _feel_answer(report_text, "Chapter I End reads as intentional, not unfinished?") != "Yes":
		return "Chapter I ending readability."
	if slice_gate != "PROCEED":
		return "Representative pacing and route duration."
	if human_verdict == "PROCEED":
		return "Milestone 2 exit review."
	return "Narrow PIVOT follow-up from human notes."


static func _feel_risks(report_text: String) -> Array[String]:
	var risks: Array[String] = []
	for field in ValidatorScript.REQUIRED_FEEL_FIELDS:
		var answer := _feel_answer(report_text, field)
		if answer != "Yes":
			risks.append("%s: %s" % [field, _fallback(answer, "Missing")])
	for label in ValidatorScript.REQUIRED_PUSH_FEEL_RETESTS:
		var answer := _push_feel_retest_answer(report_text, label)
		if answer != "Yes":
			risks.append("%s: %s" % [label, _fallback(answer, "Missing")])
	return risks


static func _decision_text(valid: bool, human_verdict: String, focus: String) -> String:
	if not valid:
		return "**NO DECISION** - This report cannot move Milestone 2. Fix the report fields or collect a new run."
	if human_verdict == "PROCEED":
		return "**PROCEED CANDIDATE** - Human and objective gates can be reviewed for Milestone 2 exit. Do not expand Alpha content until the strict gate passes."
	if human_verdict == "KILL":
		return "**KILL** - Stop content expansion and redesign the core loop area named by Primary Focus: %s" % focus
	return "**PIVOT** - Keep the concept, but tune the Primary Focus before expanding content: %s" % focus


static func _next_actions(valid: bool, human_verdict: String, focus: String) -> Array[String]:
	if not valid:
		return [
			"Fill every Human Feel Gate field with Yes/No/Partially.",
			"Fill every Push-Feel Retest Focus row with Yes/No, including Reticle surface targeting.",
			"Use PROCEED/PIVOT/KILL for Human Verdict and provide a concrete reason.",
			"Re-run `tools/validate_human_playtest_report.sh <report>` before milestone review.",
		]
	if human_verdict == "PROCEED":
		return [
			"Run `tools/check_milestone2_ready.sh` and inspect the strict gate result.",
			"If the strict gate passes, review Milestone 2 with the user before starting Alpha campaign work.",
			"Preserve the current push/contact baseline until the review decision is explicit.",
		]
	if human_verdict == "KILL":
		return [
			"Do not add levels, store work, or menu polish.",
			"Write a focused redesign note for: %s" % focus,
			"Return to PushLab or VerticalSlice physics tests before another representative playtest.",
		]
	return [
		"Create one focused tuning task for: %s" % focus,
		"Run the smallest relevant PushLab/VerticalSlice regression after tuning.",
		"Collect a new representative human report before Milestone 2 exit.",
	]


static func _feel_answer(text: String, label: String) -> String:
	var value := _field_value(text, label)
	if value.begins_with("["):
		return ""
	return value


static func _push_feel_retest_focus(report_text: String) -> String:
	for label in ValidatorScript.REQUIRED_PUSH_FEEL_RETESTS:
		if _push_feel_retest_answer(report_text, label) == "Yes":
			continue
		match label:
			"Transition sanity", "Embodied approach", "Hand surface", "Wrist/forearm silhouette", "Disengage/re-engage":
				return "Push hands, arm transition, and contact readability."
			"Look-down check":
				return "Push camera look-down control."
			"Peripheral read":
				return "Push camera peripheral readability."
			"Reticle surface targeting":
				return "Push contact and reticle aim-control feel."
			"Aim bias retest":
				return "Push contact and aim-control feel."
			"Pressure angle mastery":
				return "Pressure-angle mastery and sweet-spot legibility."
			"Rollback honesty":
				return "Rollback honesty and release physics."
			"Visual cue clarity":
				return "In-world visual cue readability."
	return ""


static func _push_feel_retest_answer(text: String, label: String) -> String:
	for raw_line in text.split("\n"):
		var line := str(raw_line).strip_edges()
		if not line.begins_with("| %s:" % label):
			continue
		var cells := line.split("|")
		if cells.size() < 4:
			return ""
		var value := str(cells[2]).strip_edges()
		if value.begins_with("["):
			return ""
		return value
	return ""


static func _field_value(text: String, label: String) -> String:
	var prefix := "- **%s**:" % label
	for raw_line in text.split("\n"):
		var line := str(raw_line).strip_edges()
		if line.begins_with(prefix):
			return line.substr(prefix.length()).strip_edges()
	return ""


static func _fallback(value: String, fallback: String) -> String:
	return fallback if value.strip_edges().is_empty() else value
