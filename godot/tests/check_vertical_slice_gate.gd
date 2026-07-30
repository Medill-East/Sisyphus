extends SceneTree

const GateCheckerScript = preload("res://scripts/VerticalSliceGateChecker.gd")

var playtests_dir := "/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests"
var require_proceed := false


func _initialize() -> void:
	_parse_args()
	var result: Dictionary = GateCheckerScript.check_playtest_directory(playtests_dir)
	print("VERTICAL_SLICE_GATE=%s" % str(result.get("gate", "PIVOT")))
	print("VERTICAL_SLICE_GATE_REASON=%s" % str(result.get("reason", "")))
	print("VALID_HUMAN_REPORTS=%d" % int(result.get("valid_human_reports", 0)))
	print("INVALID_HUMAN_REPORTS=%d" % int(result.get("invalid_human_reports", 0)))
	print("AUTOMATED_BASELINE_REPORTS=%d" % int(result.get("automated_baseline_reports", 0)))
	print("INVALID_OR_AUTOMATED_REPORTS=%d" % int(result.get("invalid_or_automated_reports", 0)))
	print("SELECTED_REPORT=%s" % str(result.get("selected_report", "")))
	_print_invalid_summaries(result.get("invalid_report_summaries", []))
	_print_automated_summaries(result.get("automated_report_summaries", []))
	quit(GateCheckerScript.exit_code_for_gate(result, require_proceed))


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--playtests-dir="):
			playtests_dir = arg.trim_prefix("--playtests-dir=")
		elif arg == "--require-proceed":
			require_proceed = true


func _print_invalid_summaries(summaries: Array) -> void:
	if summaries.is_empty():
		return
	print("INVALID_REPORT_SUMMARIES:")
	var limit: int = mini(summaries.size(), 5)
	for index in limit:
		var summary: Dictionary = summaries[index]
		var errors: Array = summary.get("errors", [])
		print("- %s" % str(summary.get("filename", "")))
		for error in errors:
			print("  - %s" % str(error))
	if summaries.size() > limit:
		print("- ... %d more invalid reports" % (summaries.size() - limit))


func _print_automated_summaries(summaries: Array) -> void:
	if summaries.is_empty():
		return
	print("AUTOMATED_BASELINE_SUMMARIES:")
	var limit: int = mini(summaries.size(), 5)
	for index in limit:
		var summary: Dictionary = summaries[index]
		print("- %s" % str(summary.get("filename", "")))
		print("  - %s" % str(summary.get("reason", "")))
	if summaries.size() > limit:
		print("- ... %d more automated baseline reports" % (summaries.size() - limit))
