extends SceneTree

const ValidatorScript = preload("res://scripts/HumanPlaytestReportValidator.gd")

var report_path: String = ""


func _initialize() -> void:
	_parse_args()
	var result: Dictionary = ValidatorScript.validate_report_file(report_path)
	if bool(result.get("valid", false)):
		print("HUMAN_PLAYTEST_REPORT_VALID=yes")
		print("HUMAN_VERDICT=%s" % str(result.get("human_verdict", "")))
		quit(0)
	else:
		print("HUMAN_PLAYTEST_REPORT_VALID=no")
		for error in result.get("errors", []):
			push_error(str(error))
		quit(1)


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report-path="):
			report_path = arg.trim_prefix("--report-path=")
