class_name VerticalSliceGateChecker
extends RefCounted

const HumanReportValidatorScript = preload("res://scripts/HumanPlaytestReportValidator.gd")


static func check_playtest_directory(path: String) -> Dictionary:
	var report_paths := _report_paths(path)
	var valid_reports: Array[Dictionary] = []
	var invalid_count := 0
	var invalid_human_count := 0
	var automated_count := 0
	var invalid_summaries: Array[Dictionary] = []
	var automated_summaries: Array[Dictionary] = []

	for report_path in report_paths:
		if _is_automated_baseline_report(report_path):
			automated_count += 1
			automated_summaries.append(_automated_summary(report_path))
			invalid_count += 1
			continue
		var result: Dictionary = HumanReportValidatorScript.validate_report_file(report_path)
		if bool(result.get("valid", false)):
			result["path"] = report_path
			valid_reports.append(result)
		else:
			invalid_count += 1
			invalid_human_count += 1
			invalid_summaries.append(_invalid_summary(report_path, result))

	if valid_reports.is_empty():
		return {
			"gate": "PIVOT",
			"reason": "no filled human playtest report with Human Feel Gate",
			"valid_human_reports": 0,
			"invalid_human_reports": invalid_human_count,
			"automated_baseline_reports": automated_count,
			"invalid_or_automated_reports": invalid_count,
			"invalid_report_summaries": invalid_summaries,
			"automated_report_summaries": automated_summaries,
			"selected_report": "",
			"human_verdict": "",
		}

	var selected := _select_report(valid_reports)
	var verdict := str(selected.get("human_verdict", "PIVOT"))
	return {
		"gate": verdict,
		"reason": _gate_reason(verdict, selected),
		"valid_human_reports": valid_reports.size(),
		"invalid_human_reports": invalid_human_count,
		"automated_baseline_reports": automated_count,
		"invalid_or_automated_reports": invalid_count,
		"invalid_report_summaries": invalid_summaries,
		"automated_report_summaries": automated_summaries,
		"selected_report": str(selected.get("path", "")),
		"human_verdict": verdict,
	}


static func exit_code_for_gate(result: Dictionary, require_proceed: bool) -> int:
	var gate := str(result.get("gate", "PIVOT"))
	if gate == "KILL":
		return 1
	if require_proceed and gate != "PROCEED":
		return 1
	return 0


static func _report_paths(path: String) -> Array[String]:
	var results: Array[String] = []
	var dir := DirAccess.open(path)
	if dir == null:
		return results
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name.is_empty():
			break
		if dir.current_is_dir():
			continue
		if not name.begins_with("playtest-"):
			continue
		if name.ends_with(".triage.md"):
			continue
		if name.ends_with(".packet.md"):
			continue
		if name.ends_with(".md"):
			results.append(path.path_join(name))
	dir.list_dir_end()
	results.sort()
	return results


static func _select_report(valid_reports: Array[Dictionary]) -> Dictionary:
	for report in valid_reports:
		if str(report.get("human_verdict", "")) == "KILL":
			return report
	for report in valid_reports:
		if str(report.get("human_verdict", "")) == "PROCEED":
			return report
	return valid_reports[valid_reports.size() - 1]


static func _invalid_summary(report_path: String, validation_result: Dictionary) -> Dictionary:
	var errors: Array = validation_result.get("errors", [])
	var clipped_errors: Array[String] = []
	for index in mini(errors.size(), 4):
		clipped_errors.append(str(errors[index]))
	return {
		"path": report_path,
		"filename": report_path.get_file(),
		"errors": clipped_errors,
	}


static func _automated_summary(report_path: String) -> Dictionary:
	return {
		"path": report_path,
		"filename": report_path.get_file(),
		"reason": "automated baseline; useful regression evidence but not filled representative human evidence",
	}


static func _is_automated_baseline_report(report_path: String) -> bool:
	var file_name := report_path.get_file()
	if file_name.contains("-auto-route") or file_name.contains("-codex-visual"):
		return true
	var file := FileAccess.open(report_path, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	return (
		text.contains("- **Session Type**: Automated")
		or text.contains("- **Input Method**: Automated")
		or text.contains("- **Tester**: auto-")
	)


static func _gate_reason(verdict: String, report: Dictionary) -> String:
	match verdict:
		"PROCEED":
			return "filled human report approves representative vertical slice"
		"PIVOT":
			return "filled human report requests a tunable pivot: %s" % str(report.get("verdict_reason", ""))
		"KILL":
			return "filled human report blocks content expansion: %s" % str(report.get("verdict_reason", ""))
		_:
			return "unknown human verdict"
