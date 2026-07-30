extends SceneTree

var base_path: String = "/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/push-intent-diagnostic"


func _initialize() -> void:
	call_deferred("_run_async")


func _run_async() -> void:
	_parse_args()
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	if scene == null:
		push_error("PushLab scene is missing")
		quit(1)
		return
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	var result: Dictionary = await lab.run_push_intent_diagnostic(base_path)
	print("PUSH_INTENT_DIAGNOSTIC_VERDICT=%s" % str(result.get("verdict", "")))
	print("PUSH_INTENT_DIAGNOSTIC_REPORT=%s" % str(result.get("report_path", "")))
	print("PUSH_INTENT_CONTACT_DELTA=%.2f" % float(result.get("contact_delta", 0.0)))
	print("PUSH_INTENT_FORCE_DELTA=%.2f" % float(result.get("force_delta", 0.0)))
	print("PUSH_INTENT_DRIFT_GAP=%.2f" % float(result.get("drift_gap", 0.0)))
	lab.queue_free()
	quit(0 if bool(result.get("success", false)) else 1)


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--base-path="):
			base_path = arg.trim_prefix("--base-path=")
