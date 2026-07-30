extends SceneTree

const VerticalSliceScene = preload("res://scenes/VerticalSlice.tscn")
const PushLabScene = preload("res://scenes/PushLab.tscn")
const GameStateScript = preload("res://scripts/GameState.gd")
const PlaytestReportBuilderScript = preload("res://scripts/PlaytestReportBuilder.gd")

const DEFAULT_REPORT_PATH := "/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/playtest-2026-05-24-auto-route.md"

var report_path: String = DEFAULT_REPORT_PATH
var report_date: String = "2026-05-24"
var tester_id: String = "auto-route"
var pacing_profile: String = "smoke"
var route_checkpoint: String = "front"
var exit_code: int = 0
var max_auto_route_frames_override: int = 0
var skip_push_lab_gate: bool = false
var route_frames_run: int = 0
var route_status: Dictionary = {}


func _initialize() -> void:
	_parse_args()
	call_deferred("_run_async")


func _run_async() -> void:
	var slice = VerticalSliceScene.instantiate()
	root.add_child(slice)
	await physics_frame
	apply_pacing_profile_to_slice(slice)
	slice.apply_visual_mode("route")
	apply_route_checkpoint_to_slice(slice)
	var route_frame_budget: int = max_auto_route_frames_for_slice(slice)
	route_frames_run = 0
	for index in route_frame_budget:
		await physics_frame
		route_frames_run = index + 1
		if should_stop_auto_route_report(slice.game_state.phase):
			break
	route_status = route_run_status(slice.game_state.phase, route_frames_run, route_frame_budget, route_checkpoint)

	prepare_slice_for_external_gates(slice)
	var push_lab_gate: Dictionary = push_lab_skipped_gate("bounded representative diagnostic") if skip_push_lab_gate else await _run_push_lab_gate()
	var report := _build_report(slice, push_lab_gate)
	var error := _write_report(report_path, report)
	if error != OK:
		push_error("Failed to write auto route playtest report to %s: %s" % [report_path, error_string(error)])
		exit_code = 1
	else:
		print("AUTO_ROUTE_REPORT=%s" % report_path)
		print("AUTO_ROUTE_PUSH_GATE=%s" % slice.route_telemetry.playtest_verdict(slice.tuning))
		print("AUTO_ROUTE_BURDEN_GATE=%s" % slice.route_telemetry.burden_verdict(slice.tuning))
		print("AUTO_ROUTE_SLICE_GATE=%s" % slice.route_telemetry.slice_verdict(slice.tuning))
		print("AUTO_ROUTE_PUSH_LAB_GATE=%s" % str(push_lab_gate.get("verdict", "NOT_RUN")))
		print("AUTO_ROUTE_PHASE=%s" % slice.game_state.label())
		print("AUTO_ROUTE_COMPLETE=%s" % ("yes" if bool(route_status.get("complete", false)) else "no"))
		print("AUTO_ROUTE_STATUS_REASON=%s" % str(route_status.get("reason", "unknown")))
	slice.queue_free()
	await process_frame
	quit(exit_code)


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report-path="):
			report_path = arg.trim_prefix("--report-path=")
		elif arg.begins_with("--report-date="):
			report_date = arg.trim_prefix("--report-date=")
		elif arg.begins_with("--tester-id="):
			tester_id = arg.trim_prefix("--tester-id=")
		elif arg.begins_with("--slice-pacing="):
			pacing_profile = arg.trim_prefix("--slice-pacing=")
		elif arg.begins_with("--route-checkpoint="):
			route_checkpoint = arg.trim_prefix("--route-checkpoint=")
		elif arg.begins_with("--max-auto-route-frames="):
			max_auto_route_frames_override = max(1, int(arg.trim_prefix("--max-auto-route-frames=")))
		elif arg == "--skip-push-lab-gate":
			skip_push_lab_gate = true


func should_stop_auto_route_report(phase: int) -> bool:
	return phase == GameStateScript.Phase.COMPLETE


func prepare_slice_for_external_gates(slice: Node) -> void:
	if slice == null:
		return
	slice.set_physics_process(false)


func apply_pacing_profile_to_slice(slice: Node) -> void:
	if slice == null:
		return
	if slice.has_method("apply_pacing_profile"):
		slice.apply_pacing_profile(pacing_profile)


func apply_route_checkpoint_to_slice(slice: Node) -> void:
	if slice == null:
		return
	if route_checkpoint == "" or route_checkpoint == "front":
		return
	if slice.has_method("apply_route_checkpoint"):
		slice.apply_route_checkpoint(route_checkpoint)


func max_auto_route_frames_for_slice(slice: Node) -> int:
	if max_auto_route_frames_override > 0:
		return max_auto_route_frames_override
	if slice == null or slice.get("tuning") == null:
		return 7200
	var next_tuning = slice.get("tuning")
	var estimated_seconds: float = 120.0
	if next_tuning.has_method("estimated_loop_seconds_for_current_pacing"):
		estimated_seconds = maxf(120.0, float(next_tuning.estimated_loop_seconds_for_current_pacing()))
	if str(next_tuning.get("pacing_profile_name") if next_tuning.get("pacing_profile_name") != null else pacing_profile) == "representative":
		return int(ceil((estimated_seconds + 90.0) * 60.0))
	return min(9000, int(ceil((estimated_seconds + 35.0) * 60.0)))


func route_run_status(phase: int, frames_run: int, frame_budget: int, checkpoint_name: String = "front") -> Dictionary:
	var is_complete: bool = phase == GameStateScript.Phase.COMPLETE
	var checkpoint_target: String = checkpoint_target_for(checkpoint_name)
	var checkpoint_complete: bool = checkpoint_phase_reached(phase, checkpoint_name)
	var reason := "complete" if is_complete else "frame budget exhausted before complete"
	if not is_complete and checkpoint_complete:
		reason = "checkpoint target reached before full completion"
	return {
		"complete": is_complete,
		"checkpoint_complete": checkpoint_complete,
		"checkpoint_target": checkpoint_target,
		"reason": reason,
		"frames_run": frames_run,
		"frame_budget": frame_budget,
	}


func checkpoint_target_for(checkpoint_name: String) -> String:
	match checkpoint_name:
		"mid":
			return "descent"
		"ridge":
			return "descent"
		"descent":
			return "complete"
		_:
			return "complete"


func checkpoint_phase_reached(phase: int, checkpoint_name: String) -> bool:
	match checkpoint_name:
		"mid", "ridge":
			return phase == GameStateScript.Phase.DESCENT or phase == GameStateScript.Phase.COMPLETE
		"descent":
			return phase == GameStateScript.Phase.COMPLETE
		_:
			return phase == GameStateScript.Phase.COMPLETE


func push_lab_skipped_gate(reason: String) -> Dictionary:
	return {
		"verdict": "SKIPPED",
		"reason": reason,
	}


func _build_report(slice, push_lab_gate: Dictionary = {}) -> String:
	var session := {
		"date": report_date,
		"build": "local-godot-auto-route",
		"tester": tester_id,
		"platform": OS.get_name(),
		"input_method": "Automated route driver",
		"session_type": "Automated baseline",
		"push_lab_gate": push_lab_gate,
		"environment_response_counts": _environment_response_counts(slice),
	}
	var report: String = PlaytestReportBuilderScript.build_vertical_slice_report(session, slice.route_telemetry, slice.tuning)
	var lines := report.split("\n")
	lines.append("")
	lines.append("## Automated Evidence")
	lines.append("- **Final Phase**: %s" % slice.game_state.label())
	lines.append("- **Pacing Profile**: %s" % str(slice.tuning.get("pacing_profile_name") if slice.tuning.get("pacing_profile_name") != null else "unknown"))
	lines.append("- **Route Checkpoint**: %s" % str(slice.get("route_checkpoint") if slice.get("route_checkpoint") != null else route_checkpoint))
	lines.append("- **Estimated Pacing Loop**: %.1fs" % float(slice.tuning.estimated_loop_seconds_for_current_pacing() if slice.tuning.has_method("estimated_loop_seconds_for_current_pacing") else 0.0))
	lines.append("- **Route Complete**: %s" % ("Yes" if bool(route_status.get("complete", false)) else "No"))
	lines.append("- **Checkpoint Complete**: %s" % ("Yes" if bool(route_status.get("checkpoint_complete", false)) else "No"))
	lines.append("- **Checkpoint Target**: %s" % str(route_status.get("checkpoint_target", "complete")))
	lines.append("- **Route Status Reason**: %s" % str(route_status.get("reason", "unknown")))
	lines.append("- **Route Frames Run**: %d / %d" % [int(route_status.get("frames_run", 0)), int(route_status.get("frame_budget", 0))])
	lines.append("- **Telemetry HUD**: %s" % slice.route_telemetry.hud_summary(slice.tuning))
	lines.append("- **Trail Points**: %d" % slice.trail_recorder.points.size())
	lines.append("- **Response Points**: %d" % slice.environment_response.response_points.size())
	lines.append("- **Response Layer Counts**: %s" % str(_environment_response_counts(slice)))
	lines.append("- **Hum Clarity**: %.2f" % slice.humming_controller.clarity)
	lines.append("- **Generated Hum Stream**: %s" % ("Yes" if slice.humming_controller.audio_stream is AudioStreamWAV else "No"))
	lines.append("- **Route Smoke Teleports After Start**: %d" % int(slice.get("route_smoke_teleport_count")))
	lines.append("- **Route Smoke Max Lateral Offset**: %.2f" % float(slice.get("route_smoke_max_lateral_offset")))
	lines.append("- **Route Smoke Bias Recovered**: %s" % ("Yes" if bool(slice.get("route_smoke_bias_recovered")) else "No"))
	lines.append("- **Push Lab Bias Gate**: %s" % str(push_lab_gate.get("verdict", "NOT_RUN")))
	lines.append("- **Push Lab Bias Gate Reason**: %s" % str(push_lab_gate.get("reason", "not run")))
	lines.append("")
	lines.append("## Scope Note")
	lines.append("This is an automated baseline for the first loop ending at `complete`, not a substitute for a human 5-10 minute feel test. The next chapter transition is intentionally unresolved and should not be simulated by looping another same-scene push.")
	return "\n".join(lines)


func _environment_response_counts(slice) -> Dictionary:
	if slice != null and slice.environment_response != null and slice.environment_response.has_method("kind_counts"):
		return slice.environment_response.kind_counts()
	return {}


func _run_push_lab_gate() -> Dictionary:
	var lab = PushLabScene.instantiate()
	root.add_child(lab)
	await physics_frame
	var left: Dictionary = await lab.evaluate_bias_recovery_route(-1.0)
	var right: Dictionary = await lab.evaluate_bias_recovery_route(1.0)
	var summary: Dictionary = push_lab_gate_summary(left, right)
	lab.queue_free()
	await process_frame
	return summary


func push_lab_gate_summary(left: Dictionary, right: Dictionary) -> Dictionary:
	var left_ok: bool = bool(left.get("success", false))
	var right_ok: bool = bool(right.get("success", false))
	var verdict := "PROCEED" if left_ok and right_ok else "PIVOT"
	var reason := "left/right bias recovery passed" if left_ok and right_ok else "left/right bias recovery needs tuning"
	return {
		"verdict": verdict,
		"reason": reason,
		"left": left,
		"right": right,
	}


func _write_report(path: String, content: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(content)
	file.close()
	return OK
