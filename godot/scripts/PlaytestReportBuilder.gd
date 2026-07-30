class_name PlaytestReportBuilder
extends RefCounted


static func build_vertical_slice_report(session: Dictionary, telemetry, tuning) -> String:
	var push_verdict: String = telemetry.playtest_verdict(tuning)
	var push_reason: String = telemetry.playtest_reason(tuning)
	var burden_verdict: String = telemetry.burden_verdict(tuning) if telemetry.has_method("burden_verdict") else "NOT_RUN"
	var burden_reason: String = telemetry.burden_reason(tuning) if telemetry.has_method("burden_reason") else "not run"
	var slice_verdict: String = telemetry.slice_verdict(tuning) if telemetry.has_method("slice_verdict") else push_verdict
	var slice_reason: String = telemetry.slice_reason(tuning) if telemetry.has_method("slice_reason") else push_reason
	var contact_percent: float = telemetry.contact_ratio() * 100.0
	var lines: Array[String] = []
	lines.append("# Playtest Report")
	lines.append("")
	lines.append("## Session Info")
	lines.append("- **Date**: %s" % _value(session, "date", "[Date]"))
	lines.append("- **Build**: %s" % _value(session, "build", "[Version/Commit]"))
	lines.append("- **Duration**: %.1fs" % telemetry.elapsed_seconds)
	lines.append("- **Tester**: %s" % _value(session, "tester", "[Name/ID]"))
	lines.append("- **Platform**: %s" % _value(session, "platform", "[Platform]"))
	lines.append("- **Input Method**: %s" % _value(session, "input_method", "[Input]"))
	lines.append("- **Session Type**: %s" % _value(session, "session_type", "Targeted test"))
	lines.append("- **Pacing Profile**: %s" % _pacing_profile(tuning))
	lines.append("- **Estimated Pacing Loop**: %.1fs" % _estimated_pacing_loop(tuning))
	lines.append("")
	lines.append("## Test Focus")
	lines.append("Sisyphus Downhill Vertical Slice: front-base push route, ridge release, back-slope descent, return to the stone, first-loop ending, and telemetry gate.")
	lines.append("")
	lines.append("## First Impressions (First 5 minutes)")
	lines.append("- **Understood the goal?** [Yes/No/Partially]")
	lines.append("- **Understood the controls?** [Yes/No/Partially]")
	lines.append("- **Emotional response**: [Engaged/Confused/Bored/Frustrated/Excited]")
	lines.append("- **Notes**: [Observations]")
	lines.append("")
	lines.append("## Quantitative Data")
	lines.append("Push Gate: %s | Burden Gate: %s | Slice Gate: %s | Contact: %.0f%% | Loss: %d | Dist: %.2f | Spin: %.1f" % [
		push_verdict,
		burden_verdict,
		slice_verdict,
		contact_percent,
		telemetry.contact_loss_count,
		telemetry.max_contact_distance,
		telemetry.max_spin_ratio,
	])
	lines.append("- **Push Gate**: %s" % push_verdict)
	lines.append("- **Push Gate Reason**: %s" % push_reason)
	lines.append("- **Burden Gate**: %s" % burden_verdict)
	lines.append("- **Burden Gate Reason**: %s" % burden_reason)
	lines.append("- **Slice Gate**: %s" % slice_verdict)
	lines.append("- **Slice Gate Reason**: %s" % slice_reason)
	lines.append("- **Contact**: %.0f%%" % contact_percent)
	lines.append("- **Contact Losses**: %d" % telemetry.contact_loss_count)
	lines.append("- **Max Player-Stone Distance**: %.2f" % telemetry.max_contact_distance)
	lines.append("- **Max Spin Ratio**: %.1f" % telemetry.max_spin_ratio)
	lines.append("- **Phase At End**: %s" % telemetry.current_phase)
	lines.append("- **Uphill Push Distance**: %.2fm" % float(telemetry.get("uphill_push_distance") if telemetry.get("uphill_push_distance") != null else 0.0))
	lines.append("- **Average Push Uphill Speed**: %.2fm/s" % float(telemetry.get("average_push_uphill_speed") if telemetry.get("average_push_uphill_speed") != null else 0.0))
	lines.append("- **Minimum Push Uphill Speed**: %.2fm/s" % float(telemetry.get("min_push_uphill_speed") if telemetry.get("min_push_uphill_speed") != null else 0.0))
	lines.append("- **Slow Push Duration**: %.1fs" % float(telemetry.get("slow_push_seconds") if telemetry.get("slow_push_seconds") != null else 0.0))
	_append_environment_response_counts(lines, session)
	_append_push_lab_gate(lines, session)
	lines.append("- **Approach Duration**: %.1fs" % _phase_seconds(telemetry, "approach"))
	lines.append("- **Ascent Duration**: %.1fs" % _phase_seconds(telemetry, "ascent"))
	lines.append("- **Release Duration**: %.1fs" % _phase_seconds(telemetry, "release"))
	lines.append("- **Descent Duration**: %.1fs" % _phase_seconds(telemetry, "descent"))
	lines.append("- **Complete Duration**: %.1fs" % _phase_seconds(telemetry, "complete"))
	lines.append("")
	lines.append("## Gameplay Flow")
	lines.append("### What worked well")
	lines.append("- [Observation 1]")
	lines.append("")
	lines.append("### Pain points")
	lines.append("- [Issue 1 -- Severity: High/Medium/Low]")
	lines.append("")
	lines.append("### Confusion points")
	lines.append("- [Where the player was confused and why]")
	lines.append("")
	lines.append("### Moments of delight")
	lines.append("- [What surprised or pleased the player]")
	lines.append("")
	lines.append("## Push-Feel Retest Focus")
	lines.append("| Check | Pass? | Notes |")
	lines.append("|-------|-------|-------|")
	lines.append("| Transition sanity: approaching and entering push view does not show long or detached arms. | [Yes/No] | [Notes] |")
	lines.append("| Embodied approach: approaching the boulder feels like a body leaning in and placing hands before the camera closes, not an instant cut to floating hands. | [Yes/No] | [Notes] |")
	lines.append("| Hand surface: palms stay visually outside the boulder while the contact cue sits on the pressure point. | [Yes/No] | [Notes] |")
	lines.append("| Wrist/forearm silhouette: first-person wrist/forearm shapes stay short and do not read as rods crossing through the boulder. | [Yes/No] | [Notes] |")
	lines.append("| Look-down check: while pushing, the player can look down enough to inspect hands/contact and then recover forward view. | [Yes/No] | [Notes] |")
	lines.append("| Peripheral read: while biased left/right, the player can still judge route edges and nearby obstacles from the push view. | [Yes/No] | [Notes] |")
	lines.append("| Reticle surface targeting: the center reticle/pressure cue lets the player choose a specific boulder surface point without the hands sinking into it. | [Yes/No] | [Notes] |")
	lines.append("| Aim bias retest: looking left/right changes hand contact and the stone's rolling direction in a way the player can intentionally use. | [Yes/No] | [Notes] |")
	lines.append("| Pressure angle mastery: a centered/sweet pressure angle makes slow progress, while bad high/side pressure stalls, slips, or rolls back instead of motoring uphill. | [Yes/No] | [Notes] |")
	lines.append("| Rollback honesty: releasing W or losing contact lets the stone stall or roll downhill under weight instead of sticking or continuing uphill. | [Yes/No] | [Notes] |")
	lines.append("| Visual cue clarity: pressure marks, route markers, and descent growth read as in-world feedback rather than unexplained yellow/blue debug clutter. | [Yes/No] | [Notes] |")
	lines.append("| Disengage/re-engage: releasing W or backing away returns camera/arms cleanly, and the player can approach the stone again. | [Yes/No] | [Notes] |")
	lines.append("")
	lines.append("## Human Feel Gate")
	lines.append("- **Burden reads as physical labor?**: [Yes/No/Partially]")
	lines.append("- **Camera pressure is intense but playable?**: [Yes/No/Partially]")
	lines.append("- **Aim changes hand contact and push direction?**: [Yes/No/Partially]")
	lines.append("- **Pressure angle mastery feels learnable?**: [Yes/No/Partially]")
	lines.append("- **Stone releases or rolls back when force is wrong?**: [Yes/No/Partially]")
	lines.append("- **Release/descent contrast is clear?**: [Yes/No/Partially]")
	lines.append("- **Visual cues read as world/pressure, not debug clutter?**: [Yes/No/Partially]")
	lines.append("- **Chapter I End reads as intentional, not unfinished?**: [Yes/No/Partially]")
	lines.append("- **Human Verdict**: [PROCEED/PIVOT/KILL]")
	lines.append("- **Verdict Reason**: [One sentence]")
	lines.append("")
	lines.append("## Bugs Encountered")
	lines.append("| # | Description | Severity | Reproducible |")
	lines.append("|---|-------------|----------|--------------|")
	lines.append("")
	lines.append("## Action Routing")
	lines.append("### Design changes needed")
	lines.append("- %s" % _design_action(push_verdict, push_reason, burden_verdict, burden_reason, slice_verdict, slice_reason))
	lines.append("")
	lines.append("### Balance adjustments")
	lines.append("- %s" % _balance_action(push_verdict, push_reason, burden_verdict, burden_reason, slice_verdict, slice_reason))
	lines.append("")
	lines.append("### Bug reports")
	lines.append("- Log reproducible collision, camera, or phase-transition failures observed during the run.")
	lines.append("")
	lines.append("### Polish items")
	lines.append("- Record readability, animation, HUD, audio, and environment-response friction after core route gate is stable.")
	lines.append("")
	lines.append("## Overall Assessment")
	lines.append("- **Would play again?** [Yes/No/Maybe]")
	lines.append("- **Difficulty**: [Too Easy / Just Right / Too Hard]")
	lines.append("- **Pacing**: [Too Slow / Good / Too Fast]")
	lines.append("- **Session length preference**: [Shorter / Good / Longer]")
	lines.append("")
	lines.append("## Top 3 Priorities")
	for item in _top_priorities(push_verdict, push_reason, burden_verdict, burden_reason, slice_verdict, slice_reason):
		lines.append(item)
	return "\n".join(lines)


static func _value(source: Dictionary, key: String, fallback: String) -> String:
	return str(source.get(key, fallback))


static func _phase_seconds(telemetry, phase_label: String) -> float:
	if telemetry == null or telemetry.get("phase_seconds") == null:
		return 0.0
	return float(telemetry.phase_seconds.get(phase_label, 0.0))


static func _pacing_profile(tuning) -> String:
	if tuning != null and tuning.get("pacing_profile_name") != null:
		return str(tuning.get("pacing_profile_name"))
	return "unknown"


static func _estimated_pacing_loop(tuning) -> float:
	if tuning != null and tuning.has_method("estimated_loop_seconds_for_current_pacing"):
		return float(tuning.estimated_loop_seconds_for_current_pacing())
	return 0.0


static func _append_push_lab_gate(lines: Array[String], session: Dictionary) -> void:
	var gate: Dictionary = session.get("push_lab_gate", {})
	if gate.is_empty():
		return
	lines.append("- **Push Lab Bias Gate**: %s" % _value(gate, "verdict", "NOT_RUN"))
	lines.append("- **Push Lab Bias Gate Reason**: %s" % _value(gate, "reason", "not run"))
	if gate.has("left"):
		lines.append("- **Push Lab Left Bias**: %s" % _push_lab_side_summary(gate["left"]))
	if gate.has("right"):
		lines.append("- **Push Lab Right Bias**: %s" % _push_lab_side_summary(gate["right"]))


static func _append_environment_response_counts(lines: Array[String], session: Dictionary) -> void:
	var counts: Dictionary = session.get("environment_response_counts", {})
	if counts.is_empty():
		return
	lines.append("- **Environment Response Layers**: Scar %d | Water %d | Flower %d | Grass %d" % [
		int(counts.get("scar", 0)),
		int(counts.get("water", 0)),
		int(counts.get("flower", 0)),
		int(counts.get("grass", 0)),
	])
	lines.append("- **Descent World Change Signal**: pushed trail changed the world through layered scar/water/flower/grass response.")


static func _push_lab_side_summary(result: Dictionary) -> String:
	var status := "pass" if bool(result.get("success", false)) else "fail"
	return "%s | Air %.2f | Recovery %.2f | Spin %.1f" % [
		status,
		float(result.get("max_air_gap", 0.0)),
		float(result.get("recovery_gain", 0.0)),
		float(result.get("max_spin_to_translation_ratio", 0.0)),
	]


static func _design_action(push_verdict: String, push_reason: String, burden_verdict: String, burden_reason: String, slice_verdict: String, slice_reason: String) -> String:
	if push_verdict == "KILL":
		return "Revisit the core push premise before expanding content: %s." % push_reason
	if burden_verdict != "PROCEED":
		return "Keep the contact model, but do not expand content until the push reads as burden instead of smooth transport: %s." % burden_reason
	if slice_verdict != "PROCEED":
		return "Do not treat this as a full vertical slice yet; build or validate a representative 5-10 minute loop: %s." % slice_reason
	if push_verdict == "PROCEED":
		return "No blocking design change from push telemetry; validate emotional intent with human notes."
	return "Review whether the current push loop creates the intended burden without breaking control: %s." % push_reason


static func _balance_action(push_verdict: String, push_reason: String, burden_verdict: String, burden_reason: String, slice_verdict: String, slice_reason: String) -> String:
	if push_verdict == "PROCEED" and slice_verdict == "PROCEED":
		if burden_verdict == "PROCEED":
			return "Keep current baseline; tune only after human fatigue/confusion notes."
		return "Tune sustained labor before content expansion: %s." % burden_reason
	if push_verdict == "PROCEED" and burden_verdict != "PROCEED":
		return "Increase sustained labor or route pressure before content expansion: %s." % burden_reason
	if push_verdict == "PROCEED":
		return "Keep push baseline for now; next tune route length, descent pacing, and emotional contrast: %s." % slice_reason
	return "Tune push contact, slope, friction, camera distance, or obstacle pressure before the next playtest: %s." % push_reason


static func _top_priorities(push_verdict: String, push_reason: String, burden_verdict: String, burden_reason: String, slice_verdict: String, slice_reason: String) -> Array[String]:
	if push_verdict == "PROCEED" and burden_verdict == "PROCEED" and slice_verdict == "PROCEED":
		return [
			"1. Run a human 5-10 minute playtest using this report.",
			"2. Compare subjective burden, camera comfort, and route clarity against telemetry.",
			"3. Validate whether the generated hum improves the descent contrast or needs audio direction.",
		]
	if push_verdict == "PROCEED" and burden_verdict != "PROCEED":
		return [
			"1. Tune sustained burden before adding more chapter content: %s." % burden_reason,
			"2. Re-run PushLab and route telemetry to confirm the stone still avoids launch and in-place spin.",
			"3. Keep the first-loop ending at complete and defer generated hum validation until burden reads correctly.",
		]
	if push_verdict == "PROCEED":
		return [
			"1. Build or validate a representative 5-10 minute loop before calling this vertical slice ready.",
			"2. Preserve current push-contact baseline while extending route/descent pacing: %s." % slice_reason,
			"3. Validate whether the generated hum improves the descent contrast or needs audio direction.",
		]
	if push_verdict == "KILL":
		return [
			"1. Stop content expansion until push mechanics are redesigned.",
			"2. Re-test the core contact model against the burden fantasy.",
			"3. Decide whether to pivot technology, scope, or premise.",
		]
	return [
		"1. Tune push contact and route stability before adding content.",
		"2. Re-run the route telemetry gate after tuning.",
		"3. Capture human notes for why the gate failed: %s." % push_reason,
	]
