extends SceneTree

const GateCheckerScript = preload("res://scripts/VerticalSliceGateChecker.gd")
const HandoffBuilderScript = preload("res://scripts/Milestone3HandoffBuilder.gd")

var playtests_dir := "/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests"
var report_path := "/Users/haodong/Documents/GitHub/Sisyphus/production/milestones/milestone3-alpha-handoff.md"


func _initialize() -> void:
	_parse_args()
	var result: Dictionary = GateCheckerScript.check_playtest_directory(playtests_dir)
	var report := HandoffBuilderScript.build_report(result, Time.get_datetime_string_from_system(false, true))
	var error := _write_report(report_path, report)
	if error == OK:
		print("MILESTONE3_HANDOFF_REPORT=%s" % report_path)
		print("MILESTONE3_HANDOFF_GATE=%s" % str(result.get("gate", "PIVOT")))
		print("MILESTONE3_HANDOFF_REASON=%s" % str(result.get("reason", "")))
		quit(0)
	else:
		push_error("Failed to write Milestone 3 handoff report to %s: %s" % [report_path, error_string(error)])
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
