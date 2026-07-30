extends SceneTree

const DIAGNOSTIC_BASE_PATH := "/private/tmp/sisyphus-push-intent-diagnostic-test"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_async")


func _run_async() -> void:
	await test_push_intent_diagnostic_writes_report_and_snapshots()
	if failures.is_empty():
		print("All push intent diagnostic tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func test_push_intent_diagnostic_writes_report_and_snapshots() -> void:
	_expect_true(ResourceLoader.exists("res://scenes/PushLab.tscn"), "PushLab scene should exist")
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	_expect_true(lab.has_method("run_push_intent_diagnostic"), "PushLab should expose the short push-intent diagnostic")
	if not lab.has_method("run_push_intent_diagnostic"):
		lab.queue_free()
		await process_frame
		return
	var result: Dictionary = await lab.run_push_intent_diagnostic(DIAGNOSTIC_BASE_PATH)
	_expect_true(str(result.get("verdict", "")) == "PROCEED", "push intent diagnostic should proceed on the current tuned baseline: %s" % str(result))
	_expect_true(bool(result.get("success", false)), "push intent diagnostic success should be true")
	_expect_true(float(result.get("contact_delta", 0.0)) > 0.55, "left/right aim should move the contact point across the boulder")
	_expect_true(float(result.get("force_delta", 0.0)) > 18.0, "left/right aim should create opposite side force")
	_expect_true(float(result.get("drift_gap", 0.0)) > 0.28, "left/right aim should produce real physical stone drift")
	_expect_true(bool(result.get("left_route_visible", false)), "left-biased push should preserve route-edge peripheral read")
	_expect_true(bool(result.get("right_route_visible", false)), "right-biased push should preserve route-edge peripheral read")
	_expect_true(bool(result.get("look_down_readable", false)), "look-down diagnostic should keep hands/contact readable")
	_expect_true(bool(result.get("disengaged_cleanly", false)), "disengage diagnostic should hide push hands and restore body")
	_expect_true(bool(result.get("hand_surface_clear", false)), "diagnostic should require palms near contact without sinking into the boulder")
	var polarity: Dictionary = result.get("aim_polarity", {})
	_expect_true(bool(polarity.get("success", false)), "diagnostic should include a passing slow aim-polarity drill")
	var angle_mastery: Dictionary = result.get("angle_mastery", {})
	_expect_true(bool(angle_mastery.get("success", false)), "diagnostic should prove bad high/side angles fail instead of auto-climbing")
	_expect_true(
		float(angle_mastery.get("center_gain", 0.0)) > float(angle_mastery.get("high_side_gain", 99.0)) + 0.22,
		"sweet spot should gain materially more ground than bad high-side contact"
	)
	_expect_true(
		float(angle_mastery.get("high_side_quality", 99.0)) < float(angle_mastery.get("center_quality", 0.0)) * 0.72,
		"bad high-side quality should be visibly lower than sweet spot quality"
	)
	var report_path: String = str(result.get("report_path", ""))
	_expect_true(FileAccess.file_exists(report_path), "diagnostic markdown report should be written")
	if FileAccess.file_exists(report_path):
		var file := FileAccess.open(report_path, FileAccess.READ)
		var text: String = file.get_as_text() if file != null else ""
		_expect_true(text.contains("# Push Intent Diagnostic"), "diagnostic report should use the expected heading")
		_expect_true(text.contains("**Verdict**: PROCEED"), "diagnostic report should include its verdict")
		_expect_true(text.contains("## Angle Mastery Drill"), "diagnostic report should include wrong-angle failure evidence")
		_expect_true(text.contains("## Aim Polarity Drill"), "diagnostic report should include slow left/right polarity evidence")
		_expect_true(text.contains("This diagnostic does not replace a filled `Human Feel Gate` report."), "diagnostic report should preserve the human-gate boundary")
	var snapshots: Array = result.get("snapshots", [])
	_expect_true(snapshots.size() == 6, "diagnostic should save approach, center, left, right, look-down, and disengage snapshots")
	var labels: Dictionary = {}
	for entry in snapshots:
		var label: String = str(entry.get("label", ""))
		labels[label] = true
		var path: String = str(entry.get("path", ""))
		_expect_true(FileAccess.file_exists(path), "diagnostic snapshot should exist for %s" % label)
	_expect_true(labels.has("approach"), "diagnostic should include approach")
	_expect_true(labels.has("center_push"), "diagnostic should include center push")
	_expect_true(labels.has("left_high"), "diagnostic should include left-high aim")
	_expect_true(labels.has("right_high"), "diagnostic should include right-high aim")
	_expect_true(labels.has("look_down"), "diagnostic should include look-down aim")
	_expect_true(labels.has("disengage"), "diagnostic should include disengage")
	lab.queue_free()
	await process_frame


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
