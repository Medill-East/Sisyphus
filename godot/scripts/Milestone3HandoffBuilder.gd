class_name Milestone3HandoffBuilder
extends RefCounted


static func build_report(gate_result: Dictionary, generated_at: String) -> String:
	var gate := str(gate_result.get("gate", "PIVOT"))
	var reason := str(gate_result.get("reason", "unknown"))
	var selected_report := str(gate_result.get("selected_report", ""))
	var valid_count := int(gate_result.get("valid_human_reports", 0))
	var invalid_count := int(gate_result.get("invalid_or_automated_reports", 0))
	var unlocked := gate == "PROCEED"

	var lines: Array[String] = []
	lines.append("# Milestone 3 Alpha Handoff")
	lines.append("")
	lines.append("- **Generated At**: %s" % generated_at)
	lines.append("- **Source Gate**: Milestone 2 - Vertical Slice Loop")
	lines.append("- **Gate**: %s" % gate)
	lines.append("- **Gate Reason**: %s" % reason)
	lines.append("- **Valid Human Reports**: %d" % valid_count)
	lines.append("- **Invalid Or Automated Reports**: %d" % invalid_count)
	lines.append("- **Selected Human Report**: %s" % ("None" if selected_report.is_empty() else selected_report))
	lines.append("")
	lines.append("## Decision")
	lines.append("")
	if unlocked:
		lines.append("**UNLOCKED** - Milestone 3 Alpha Campaign Skeleton may begin after user review confirms the selected human report.")
	elif gate == "KILL":
		lines.append("**BLOCKED** - Do not enter Alpha. Redesign or kill the core loop before further Steam production.")
	else:
		lines.append("**LOCKED** - Do not enter Alpha. Milestone 2 still needs a filled representative human `PROCEED` report with Human Feel Gate and Push-Feel Retest Focus aligned.")
	lines.append("")
	lines.append("## Entry Conditions")
	lines.append("")
	lines.append("- `tools/check_milestone2_ready.sh` must exit successfully.")
	lines.append("- Selected human report must be representative, complete, and aligned with Push/Burden/Slice `PROCEED` gates.")
	lines.append("- Selected human report must include Human Feel Gate and Push-Feel Retest Focus evidence; any `No` retest keeps Alpha locked.")
	lines.append("- `Reticle surface targeting` must remain `Yes`; Alpha work cannot start if the center reticle cannot choose a readable boulder pressure point.")
	lines.append("- `Wrist/forearm silhouette` must remain `Yes`; Alpha work cannot start if first-person wrist/forearm shapes read as rods crossing through the boulder.")
	lines.append("- `Pressure angle mastery` and `Rollback honesty` must remain `Yes`; Alpha work cannot start if pushing feels like motor transport instead of learnable pressure and physical rollback.")
	lines.append("- `Visual cue clarity` must remain `Yes`; Alpha work cannot start if pressure/route/descent markers read as unexplained debug clutter.")
	lines.append("- `complete / Chapter I End` remains the first-loop stop point; Chapter II transition is still separate design work.")
	lines.append("- Push/contact baseline must remain protected by PushLab and VerticalSlice route tests before any campaign expansion.")
	lines.append("")
	lines.append("## Allowed Work If Unlocked")
	lines.append("")
	if unlocked:
		for item in _unlocked_work_items():
			lines.append("- %s" % item)
	else:
		lines.append("- None. Keep work focused on representative human playtest, triage, and the single core-loop issue named by the report.")
	lines.append("")
	lines.append("## Explicitly Deferred")
	lines.append("")
	lines.append("- Store page, trailer, capsule art, SteamPipe/depot work, localization tables, and Windows/Linux release claims.")
	lines.append("- Full campaign polish, final art, final audio mix, save migration, achievements, analytics, and non-desktop platforms.")
	lines.append("- Any same-scene re-push placeholder for Chapter II.")
	lines.append("")
	lines.append("## First Verification After Unlock")
	lines.append("")
	lines.append("- Run `tools/check_milestone2_ready.sh` first; if it fails, this handoff is not active.")
	lines.append("- Run PushLab and VerticalSlice route regressions after any push/camera/level-route change.")
	lines.append("- Capture at least one human/visual check for the first Alpha skeleton route before adding more levels.")
	return "\n".join(lines)


static func _unlocked_work_items() -> Array[String]:
	return [
		"Create the Milestone 3 Alpha Campaign Skeleton plan before writing new level content.",
		"Define data-driven Level 1-7 route profiles using the existing ascent-release-descent loop; do not rewrite the push controller.",
		"Implement placeholder level selection and progression only after Level 1 and the vertical-slice level both preserve the current push feel.",
		"Add save/profile tracking for unlocked levels, ratings, stone evolution, and hum fragments as Alpha infrastructure.",
		"Keep all new campaign work behind tests that prove the Milestone 2 push/contact baseline still passes.",
	]
