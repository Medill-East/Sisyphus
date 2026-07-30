extends SceneTree

const TriageBuilderScript = preload("res://scripts/HumanPlaytestTriageBuilder.gd")

var report_path := ""
var triage_path := ""


func _initialize() -> void:
	_parse_args()
	if report_path.strip_edges().is_empty():
		push_error("Missing --report-path")
		quit(2)
		return
	if triage_path.strip_edges().is_empty():
		triage_path = "%s.triage.md" % report_path.trim_suffix(".md")
	if not FileAccess.file_exists(report_path):
		push_error("Report does not exist: %s" % report_path)
		quit(1)
		return
	var file := FileAccess.open(report_path, FileAccess.READ)
	if file == null:
		push_error("Report is not readable: %s" % report_path)
		quit(1)
		return
	var triage := TriageBuilderScript.build_triage(file.get_as_text(), report_path, Time.get_datetime_string_from_system(false, true))
	var error := _write_file(triage_path, triage)
	if error != OK:
		push_error("Failed to write triage to %s: %s" % [triage_path, error_string(error)])
		quit(1)
		return
	print("HUMAN_PLAYTEST_TRIAGE=%s" % triage_path)
	quit(0)


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report-path="):
			report_path = arg.trim_prefix("--report-path=")
		elif arg.begins_with("--triage-path="):
			triage_path = arg.trim_prefix("--triage-path=")


func _write_file(path: String, content: String) -> Error:
	var base_dir := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(base_dir):
		DirAccess.make_dir_recursive_absolute(base_dir)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(content)
	return OK
