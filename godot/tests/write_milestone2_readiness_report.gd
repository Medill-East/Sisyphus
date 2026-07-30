extends SceneTree

const GateCheckerScript = preload("res://scripts/VerticalSliceGateChecker.gd")
const ReportBuilderScript = preload("res://scripts/Milestone2ReadinessReportBuilder.gd")

var playtests_dir := "/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests"
var report_path := "/Users/haodong/Documents/GitHub/Sisyphus/production/qa/milestone2-readiness.md"


func _initialize() -> void:
	_parse_args()
	var result: Dictionary = GateCheckerScript.check_playtest_directory(playtests_dir)
	var push_intent_diagnostic := _latest_push_intent_diagnostic(playtests_dir)
	var current_handoff := _current_handoff_status(playtests_dir)
	var report := ReportBuilderScript.build_report(result, Time.get_datetime_string_from_system(false, true), push_intent_diagnostic, current_handoff)
	var error := _write_report(report_path, report)
	if error == OK:
		print("MILESTONE2_READINESS_REPORT=%s" % report_path)
		print("MILESTONE2_GATE=%s" % str(result.get("gate", "PIVOT")))
		print("MILESTONE2_GATE_REASON=%s" % str(result.get("reason", "")))
		quit(0)
	else:
		push_error("Failed to write Milestone 2 readiness report to %s: %s" % [report_path, error_string(error)])
		quit(1)


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--playtests-dir="):
			playtests_dir = arg.trim_prefix("--playtests-dir=")
		elif arg.begins_with("--report-path="):
			report_path = arg.trim_prefix("--report-path=")


func _write_report(path: String, content: String) -> Error:
	var base_dir := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(base_dir):
		DirAccess.make_dir_recursive_absolute(base_dir)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(content)
	return OK


func _latest_push_intent_diagnostic(directory_path: String) -> Dictionary:
	var dir := DirAccess.open(directory_path)
	if dir == null:
		return {}
	var latest_name := ""
	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name.is_empty():
			break
		if dir.current_is_dir():
			continue
		if file_name.begins_with("push-intent-diagnostic-") and file_name.ends_with(".md"):
			if latest_name.is_empty() or file_name > latest_name:
				latest_name = file_name
	dir.list_dir_end()
	if latest_name.is_empty():
		return {}
	var full_path := directory_path.path_join(latest_name)
	var file := FileAccess.open(full_path, FileAccess.READ)
	if file == null:
		return {"path": full_path}
	var text := file.get_as_text()
	return {
		"path": full_path,
		"verdict": _markdown_field(text, "Verdict"),
		"contact_delta": _markdown_field(text, "Contact Delta"),
		"force_delta": _markdown_field(text, "Force Delta"),
		"drift_gap": _markdown_field(text, "Real Drift Gap"),
	}


func _markdown_field(text: String, field_name: String) -> String:
	var marker := "- **%s**:" % field_name
	for line in text.split("\n"):
		if line.begins_with(marker):
			return line.trim_prefix(marker).strip_edges()
	return "Unknown"


func _current_handoff_status(directory_path: String) -> Dictionary:
	var packet_path := _latest_packet_path(directory_path)
	if packet_path.is_empty():
		return {
			"status": "NOT_READY",
			"reason": "no representative playtest packet found",
			"next_command": "tools/prepare_representative_playtest_packet.sh tester-id YYYY-MM-DD",
		}
	var packet_text := _read_text(packet_path)
	var tester_id := _strip_markdown_code(_markdown_field(packet_text, "Tester ID"))
	var report_date := _strip_markdown_code(_markdown_field(packet_text, "Date"))
	var expected_report := _strip_markdown_code(_markdown_field(packet_text, "Expected F9 Report"))
	var expected_screenshot := _strip_markdown_code(_markdown_field(packet_text, "Expected F9 Screenshot"))
	var diagnostic_report := _strip_markdown_code(_markdown_field(packet_text, "Push Intent Diagnostic"))
	var missing_required := tester_id == "Unknown" or report_date == "Unknown" or expected_report == "Unknown" or expected_screenshot == "Unknown" or diagnostic_report == "Unknown"
	if missing_required:
		return {
			"status": "NOT_READY",
			"reason": "packet is missing required fields",
			"packet": packet_path,
			"next_command": "tools/prepare_representative_playtest_packet.sh tester-id YYYY-MM-DD",
		}
	if not _preflight_evidence_exists(diagnostic_report):
		return {
			"status": "NOT_READY",
			"reason": "preflight evidence missing",
			"packet": packet_path,
			"tester_id": tester_id,
			"date": report_date,
			"expected_report": expected_report,
			"next_command": "tools/run_current_representative_playtest.sh --preflight",
		}
	if not FileAccess.file_exists(expected_report):
		return {
			"status": "READY_FOR_HUMAN_RUN",
			"reason": "preflight evidence is present; expected F9 report is not present yet",
			"packet": packet_path,
			"tester_id": tester_id,
			"date": report_date,
			"expected_report": expected_report,
			"next_command": "tools/run_current_representative_playtest.sh",
		}
	if not FileAccess.file_exists(expected_screenshot):
		return {
			"status": "REPORT_INCOMPLETE",
			"reason": "F9 report exists but expected screenshot is missing",
			"packet": packet_path,
			"tester_id": tester_id,
			"date": report_date,
			"expected_report": expected_report,
			"next_command": "tools/run_current_representative_playtest.sh",
		}
	return {
		"status": "READY_TO_SUBMIT",
		"reason": "F9 report and screenshot exist; submit after required human fields are filled",
		"packet": packet_path,
		"tester_id": tester_id,
		"date": report_date,
		"expected_report": expected_report,
		"next_command": "tools/submit_current_representative_playtest_report.sh",
	}


func _latest_packet_path(directory_path: String) -> String:
	var dir := DirAccess.open(directory_path)
	if dir == null:
		return ""
	var latest_name := ""
	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name.is_empty():
			break
		if dir.current_is_dir():
			continue
		if file_name.begins_with("playtest-") and file_name.ends_with(".packet.md"):
			if latest_name.is_empty() or file_name > latest_name:
				latest_name = file_name
	dir.list_dir_end()
	if latest_name.is_empty():
		return ""
	return directory_path.path_join(latest_name)


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _preflight_evidence_exists(diagnostic_report: String) -> bool:
	if not FileAccess.file_exists(diagnostic_report):
		return false
	var base := diagnostic_report.trim_suffix(".md")
	for suffix in ["approach", "center_push", "left_high", "right_high", "look_down", "disengage"]:
		if not FileAccess.file_exists("%s-%s.png" % [base, suffix]):
			return false
	return true


func _strip_markdown_code(value: String) -> String:
	var trimmed := value.strip_edges()
	if trimmed.begins_with("`") and trimmed.ends_with("`") and trimmed.length() >= 2:
		return trimmed.substr(1, trimmed.length() - 2)
	return trimmed
