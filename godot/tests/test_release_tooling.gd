extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	test_desktop_export_script_contract()
	test_macos_build_smoke_script_contract()
	test_representative_playtest_script_contract()
	test_human_playtest_report_validator_script_contract()
	test_vertical_slice_gate_script_contract()
	test_milestone2_readiness_script_contract()
	test_milestone2_readiness_report_script_contract()
	test_human_playtest_triage_script_contract()
	test_submit_representative_playtest_report_script_contract()
	test_representative_playtest_packet_script_contract()
	test_current_representative_playtest_script_contract()
	test_submit_current_representative_playtest_script_contract()
	test_check_current_representative_handoff_script_contract()
	test_representative_human_playtest_worksheet_contract()
	test_playtest_protocol_readme_contract()
	test_godot_readme_playtest_handoff_contract()
	test_milestone3_handoff_report_script_contract()
	if failures.is_empty():
		print("All release tooling tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func test_desktop_export_script_contract() -> void:
	var path := "../tools/export_desktop.sh"
	_expect_true(FileAccess.file_exists(path), "desktop export script should exist")
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_expect_true(file != null, "desktop export script should be readable")
	if file == null:
		return
	var content := file.get_as_text()
	_expect_true(content.contains("--check-templates"), "desktop export script should support template-only checks")
	_expect_true(content.contains("GODOT_EXPORT_TEMPLATES_DIR"), "desktop export script should allow overriding the export template directory")
	_expect_true(content.contains("local target=\"${1:-macos}\""), "desktop export script should default to the locally verifiable macOS build")
	_expect_true(not content.contains("export_target windows\n      export_target linux"), "desktop export script should not encourage unverified multi-platform exports by default")
	_expect_true(content.contains("macos.zip"), "desktop export script should check for the macOS template")
	_expect_true(content.contains("windows_release_x86_64.exe"), "desktop export script should check for the Windows release template")
	_expect_true(content.contains("linux_release.x86_64"), "desktop export script should check for the Linux release template")
	_expect_true(content.contains("--recovery-mode"), "desktop export script should disable editor plugins during release export")
	_expect_true(content.contains("--export-release"), "desktop export script should call Godot release export")


func test_macos_build_smoke_script_contract() -> void:
	var path := "../tools/smoke_macos_build.sh"
	_expect_true(FileAccess.file_exists(path), "macOS build smoke script should exist")
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_expect_true(file != null, "macOS build smoke script should be readable")
	if file == null:
		return
	var content := file.get_as_text()
	_expect_true(content.contains("SisyphusDownhill.zip"), "macOS smoke should verify the exported zip")
	_expect_true(content.contains("mktemp"), "macOS smoke should unpack into a temporary directory")
	_expect_true(content.contains("--headless"), "macOS smoke should run the exported app headlessly")
	_expect_true(content.contains("--log-file"), "macOS smoke should provide a writable log path")
	_expect_true(content.contains("--quit-after"), "macOS smoke should exit automatically")


func test_representative_playtest_script_contract() -> void:
	var path := "../tools/run_representative_playtest.sh"
	_expect_true(FileAccess.file_exists(path), "representative playtest script should exist")
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_expect_true(file != null, "representative playtest script should be readable")
	if file == null:
		return
	var content := file.get_as_text()
	_expect_true(content.contains("GODOT_BIN"), "representative playtest script should allow overriding Godot binary")
	_expect_true(content.contains("--scene res://scenes/VerticalSlice.tscn"), "representative playtest should launch the vertical slice scene")
	_expect_true(content.contains("--slice-pacing=representative"), "representative playtest should use the long pacing profile")
	_expect_true(content.contains("--preflight"), "representative playtest should support a non-UI preflight")
	_expect_true(content.contains("test_vertical_slice_playtest_capture.gd"), "representative playtest preflight should verify F9 capture")
	_expect_true(content.contains("test_human_playtest_report_validator.gd"), "representative playtest preflight should verify the human report validator")
	_expect_true(content.contains("run_push_intent_diagnostic.sh"), "representative playtest preflight should run the short push-intent diagnostic before a human session")
	_expect_true(content.contains("push-intent-diagnostic"), "representative playtest preflight should print where the push-intent diagnostic evidence is written")
	_expect_true(content.contains("does not replace the filled Human Feel Gate"), "representative playtest preflight should keep the diagnostic separate from the human gate")
	_expect_true(content.contains("write_milestone2_readiness_report.sh"), "representative playtest preflight should refresh readiness status")
	_expect_true(content.contains("--playtest-tester-id="), "representative playtest should pass a tester id")
	_expect_true(content.contains("--playtest-report-path="), "representative playtest should pass an F9 report path")
	_expect_true(content.contains("production/qa/playtests"), "representative playtest reports should save under QA playtests")
	_expect_true(content.contains("Press F9"), "representative playtest script should remind testers to save evidence")
	_expect_true(content.contains("print_push_feel_retest_focus"), "representative playtest script should print the core push-feel retest checklist")
	_expect_true(content.contains("Transition sanity"), "representative playtest script should remind testers to watch arm transition")
	_expect_true(content.contains("Embodied approach"), "representative playtest script should remind testers to watch embodied approach")
	_expect_true(content.contains("Wrist/forearm silhouette"), "representative playtest script should remind testers to watch for rod-like first-person wrists")
	_expect_true(content.contains("Look-down check"), "representative playtest script should remind testers to verify downward push view")
	_expect_true(content.contains("Peripheral read"), "representative playtest script should remind testers to verify biased-view route readability")
	_expect_true(content.contains("Reticle surface targeting"), "representative playtest script should remind testers to verify center reticle surface targeting")
	_expect_true(content.contains("Aim bias retest"), "representative playtest script should remind testers to verify deliberate aim bias")
	_expect_true(content.contains("Pressure angle mastery"), "representative playtest script should remind testers to verify sweet pressure angle mastery")
	_expect_true(content.contains("Rollback honesty"), "representative playtest script should remind testers to verify release and rollback honesty")
	_expect_true(content.contains("Visual cue clarity"), "representative playtest script should remind testers to verify non-debug visual cue clarity")
	_expect_true(content.contains("Disengage/re-engage"), "representative playtest script should remind testers to verify push exit and return")
	_expect_true(content.contains("validate_human_playtest_report.sh"), "representative playtest should validate the saved report after exit")
	_expect_true(content.contains("triage_human_playtest_report.sh"), "representative playtest should write triage after a report exists")
	_expect_true(content.contains("check_vertical_slice_gate.sh"), "representative playtest should run the milestone gate after exit")
	_expect_true(content.contains("--require-proceed"), "representative playtest should use strict milestone gate mode")
	_expect_true(content.contains("fill Push-Feel Retest Focus and Human Feel Gate fields"), "representative playtest should remind testers to fill both human evidence sections")
	_expect_true(content.contains("Representative playtest report missing"), "representative playtest should explain missing F9 report failure")
	_expect_true(content.contains("Press F9 at `complete / Chapter I End`"), "missing report guidance should tell the tester when to press F9")
	_expect_true(content.contains("Expected report path"), "missing report guidance should repeat the expected report path")
	_expect_true(not content.contains("exec \"$GODOT_BIN\""), "representative playtest should continue after Godot exits instead of exec replacement")


func test_human_playtest_report_validator_script_contract() -> void:
	var path := "../tools/validate_human_playtest_report.sh"
	_expect_true(FileAccess.file_exists(path), "human playtest report validator script should exist")
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_expect_true(file != null, "human playtest report validator script should be readable")
	if file == null:
		return
	var content := file.get_as_text()
	_expect_true(content.contains("GODOT_BIN"), "human report validator should allow overriding Godot binary")
	_expect_true(content.contains("--headless"), "human report validator should run headless")
	_expect_true(content.contains("--log-file"), "human report validator should use an explicit writable log path")
	_expect_true(content.contains("tests/validate_human_playtest_report.gd"), "human report validator should call the Godot validation script")
	_expect_true(content.contains("--report-path="), "human report validator should pass the report path")


func test_vertical_slice_gate_script_contract() -> void:
	var path := "../tools/check_vertical_slice_gate.sh"
	_expect_true(FileAccess.file_exists(path), "vertical slice gate script should exist")
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_expect_true(file != null, "vertical slice gate script should be readable")
	if file == null:
		return
	var content := file.get_as_text()
	_expect_true(content.contains("GODOT_BIN"), "vertical slice gate should allow overriding Godot binary")
	_expect_true(content.contains("--headless"), "vertical slice gate should run headless")
	_expect_true(content.contains("--log-file"), "vertical slice gate should use an explicit writable log path")
	_expect_true(content.contains("tests/check_vertical_slice_gate.gd"), "vertical slice gate should call the Godot gate script")
	_expect_true(content.contains("--playtests-dir="), "vertical slice gate should pass the playtest directory")
	_expect_true(content.contains("--require-proceed"), "vertical slice gate should support a strict milestone mode")


func test_milestone2_readiness_script_contract() -> void:
	var path := "../tools/check_milestone2_ready.sh"
	_expect_true(FileAccess.file_exists(path), "milestone 2 readiness script should exist")
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_expect_true(file != null, "milestone 2 readiness script should be readable")
	if file == null:
		return
	var content := file.get_as_text()
	_expect_true(content.contains("test_human_playtest_report_validator.gd"), "milestone 2 gate should verify human report validator")
	_expect_true(content.contains("test_vertical_slice_gate_checker.gd"), "milestone 2 gate should verify vertical-slice gate checker")
	_expect_true(content.contains("test_playtest_report_builder.gd"), "milestone 2 gate should verify report generation")
	_expect_true(content.contains("test_milestone2_readiness_report.gd"), "milestone 2 gate should verify readiness report generation")
	_expect_true(content.contains("test_release_tooling.gd"), "milestone 2 gate should verify release tooling contracts")
	_expect_true(content.contains("test_push_intent_diagnostic.gd"), "milestone 2 gate should verify the short push-intent diagnostic contract")
	_expect_true(content.contains("--quit-after 120"), "milestone 2 gate should include a headless startup check")
	_expect_true(content.contains("--log-file"), "milestone 2 gate should use explicit writable Godot log paths")
	_expect_true(content.contains("check_vertical_slice_gate.sh"), "milestone 2 gate should call the strict vertical-slice gate")
	_expect_true(content.contains("--require-proceed"), "milestone 2 gate should require a human PROCEED report")
	_expect_true(content.contains("--skip-tests"), "milestone 2 gate should allow status-only strict gate rechecks")
	_expect_true(content.contains("check_current_representative_handoff.sh"), "milestone 2 gate should print current handoff status when strict gate fails")
	_expect_true(content.contains("Current representative handoff"), "milestone 2 gate output should label the handoff status section")
	_expect_true(content.contains("return \"$gate_status\""), "milestone 2 gate should preserve the strict gate exit status")


func test_milestone2_readiness_report_script_contract() -> void:
	var path := "../tools/write_milestone2_readiness_report.sh"
	_expect_true(FileAccess.file_exists(path), "milestone 2 readiness report script should exist")
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_expect_true(file != null, "milestone 2 readiness report script should be readable")
	if file == null:
		return
	var content := file.get_as_text()
	_expect_true(content.contains("tests/write_milestone2_readiness_report.gd"), "milestone 2 readiness report script should call the Godot writer")
	_expect_true(content.contains("production/qa/playtests"), "milestone 2 readiness report should scan playtest reports")
	_expect_true(content.contains("production/qa/milestone2-readiness.md"), "milestone 2 readiness report should default to QA report path")
	_expect_true(content.contains("--log-file"), "milestone 2 readiness report should use explicit writable Godot log path")


func test_human_playtest_triage_script_contract() -> void:
	var path := "../tools/triage_human_playtest_report.sh"
	_expect_true(FileAccess.file_exists(path), "human playtest triage script should exist")
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_expect_true(file != null, "human playtest triage script should be readable")
	if file == null:
		return
	var content := file.get_as_text()
	_expect_true(content.contains("GODOT_BIN"), "human playtest triage should allow overriding Godot binary")
	_expect_true(content.contains("--headless"), "human playtest triage should run headless")
	_expect_true(content.contains("--log-file"), "human playtest triage should use explicit writable Godot log path")
	_expect_true(content.contains("tests/write_human_playtest_triage.gd"), "human playtest triage should call the Godot writer")
	_expect_true(content.contains("--report-path="), "human playtest triage should pass the report path")
	_expect_true(content.contains("--triage-path="), "human playtest triage should pass the output path")


func test_submit_representative_playtest_report_script_contract() -> void:
	var path := "../tools/submit_representative_playtest_report.sh"
	_expect_true(FileAccess.file_exists(path), "representative playtest report submit script should exist")
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_expect_true(file != null, "representative playtest report submit script should be readable")
	if file == null:
		return
	var content := file.get_as_text()
	_expect_true(content.contains("validate_human_playtest_report.sh"), "submit script should validate the filled human report")
	_expect_true(content.contains("triage_human_playtest_report.sh"), "submit script should write focused triage for the report")
	_expect_true(content.contains("check_vertical_slice_gate.sh"), "submit script should run the strict vertical-slice gate")
	_expect_true(content.contains("--require-proceed"), "submit script should use strict milestone gate mode")
	_expect_true(content.contains("write_milestone2_readiness_report.sh"), "submit script should refresh Milestone 2 readiness")
	_expect_true(content.contains("write_milestone3_handoff_report.sh"), "submit script should refresh Milestone 3 handoff lock/unlock state")
	_expect_true(content.contains("validation_status"), "submit script should preserve validation status")
	_expect_true(content.contains("gate_status"), "submit script should preserve strict gate status")
	_expect_true(content.contains("return \"$validation_status\""), "submit script should return validation failure before gate status")
	_expect_true(content.contains("return \"$gate_status\""), "submit script should return strict gate status after valid reports")


func test_representative_playtest_packet_script_contract() -> void:
	var path := "../tools/prepare_representative_playtest_packet.sh"
	_expect_true(FileAccess.file_exists(path), "representative playtest packet script should exist")
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_expect_true(file != null, "representative playtest packet script should be readable")
	if file == null:
		return
	var content := file.get_as_text()
	_expect_true(content.contains("run_representative_playtest.sh\" --preflight"), "packet script should run preflight before writing the packet")
	_expect_true(content.contains("playtest-${report_date}-${tester_id}.packet.md"), "packet script should write a per-tester packet path")
	_expect_true(content.contains("push-intent-diagnostic-preflight-${report_date}-${tester_id}"), "packet should link the preflight push-intent diagnostic")
	_expect_true(content.contains("production/qa/milestone2-readiness.md"), "packet should link the current readiness report")
	_expect_true(content.contains("playtest-${report_date}-${tester_id}.md"), "packet should name the expected F9 report")
	_expect_true(content.contains("tools/run_current_representative_playtest.sh"), "packet should prefer the current-handoff human run wrapper")
	_expect_true(content.contains("tools/run_representative_playtest.sh %s %s"), "packet should include the human run command")
	_expect_true(content.contains("tools/submit_current_representative_playtest_report.sh"), "packet should prefer the current-handoff submit wrapper")
	_expect_true(content.contains("tools/submit_representative_playtest_report.sh"), "packet should include one-step post-run submit command")
	_expect_true(content.contains("Resolved fallback command"), "packet should keep concrete fallback commands for reproducibility")
	_expect_true(content.contains("tools/check_milestone2_ready.sh"), "packet should include final milestone check")
	_expect_true(content.contains("does not replace Human Feel Gate"), "packet should preserve the diagnostic/human-gate boundary")
	_expect_true(content.contains("Embodied approach"), "packet should include embodied approach retest row")
	_expect_true(content.contains("Wrist/forearm silhouette"), "packet should include the latest first-person wrist/forearm retest row")
	_expect_true(content.contains("Pressure angle mastery"), "packet should include pressure-angle mastery retest row")
	_expect_true(content.contains("Rollback honesty"), "packet should include rollback honesty retest row")
	_expect_true(content.contains("Visual cue clarity"), "packet should include visual cue clarity retest row")


func test_current_representative_playtest_script_contract() -> void:
	var path := "../tools/run_current_representative_playtest.sh"
	_expect_true(FileAccess.file_exists(path), "current representative playtest wrapper should exist")
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_expect_true(file != null, "current representative playtest wrapper should be readable")
	if file == null:
		return
	var content := file.get_as_text()
	_expect_true(content.contains("latest_packet_path"), "current wrapper should discover the latest packet")
	_expect_true(content.contains("playtest-*.packet.md"), "current wrapper should scan representative packet files")
	_expect_true(content.contains("packet_field"), "current wrapper should parse packet fields as data")
	_expect_true(content.contains("Tester ID"), "current wrapper should read tester id from the packet")
	_expect_true(content.contains("Date"), "current wrapper should read date from the packet")
	_expect_true(content.contains("--show"), "current wrapper should support previewing the resolved command")
	_expect_true(content.contains("--preflight"), "current wrapper should support refreshing the current handoff preflight")
	_expect_true(content.contains("prepare_representative_playtest_packet.sh"), "current wrapper should delegate preflight packet refresh")
	_expect_true(content.contains("run_representative_playtest.sh"), "current wrapper should delegate the actual human run")
	_expect_true(not content.contains("eval "), "current wrapper should not eval commands from the packet")


func test_submit_current_representative_playtest_script_contract() -> void:
	var path := "../tools/submit_current_representative_playtest_report.sh"
	_expect_true(FileAccess.file_exists(path), "current representative report submit wrapper should exist")
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_expect_true(file != null, "current representative report submit wrapper should be readable")
	if file == null:
		return
	var content := file.get_as_text()
	_expect_true(content.contains("latest_packet_path"), "submit-current wrapper should discover the latest packet")
	_expect_true(content.contains("playtest-*.packet.md"), "submit-current wrapper should scan representative packet files")
	_expect_true(content.contains("packet_field"), "submit-current wrapper should parse packet fields as data")
	_expect_true(content.contains("Expected F9 Report"), "submit-current wrapper should read the expected report path from the packet")
	_expect_true(content.contains("--show"), "submit-current wrapper should support previewing the resolved report")
	_expect_true(content.contains("submit_representative_playtest_report.sh"), "submit-current wrapper should delegate to the existing submit script")
	_expect_true(content.contains("run_current_representative_playtest.sh"), "submit-current wrapper should point back to the current run helper if the report is missing")
	_expect_true(content.contains("press F9"), "submit-current wrapper should explain how to create the missing report")
	_expect_true(not content.contains("eval "), "submit-current wrapper should not eval commands from the packet")


func test_check_current_representative_handoff_script_contract() -> void:
	var path := "../tools/check_current_representative_handoff.sh"
	_expect_true(FileAccess.file_exists(path), "current representative handoff check script should exist")
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_expect_true(file != null, "current representative handoff check script should be readable")
	if file == null:
		return
	var content := file.get_as_text()
	_expect_true(content.contains("latest_packet_path"), "handoff check should discover the latest packet")
	_expect_true(content.contains("playtest-*.packet.md"), "handoff check should scan representative packet files")
	_expect_true(content.contains("Expected F9 Report"), "handoff check should read the expected report path")
	_expect_true(content.contains("Expected F9 Screenshot"), "handoff check should read the expected screenshot path")
	_expect_true(content.contains("Push Intent Diagnostic"), "handoff check should verify push-intent diagnostic evidence")
	_expect_true(content.contains("HANDOFF_STATUS=READY_FOR_HUMAN_RUN"), "handoff check should expose ready-for-run status")
	_expect_true(content.contains("HANDOFF_STATUS=READY_TO_SUBMIT"), "handoff check should expose ready-to-submit status")
	_expect_true(content.contains("NEXT_COMMAND=tools/run_current_representative_playtest.sh"), "handoff check should print the next human-run command")
	_expect_true(content.contains("NEXT_COMMAND=tools/submit_current_representative_playtest_report.sh"), "handoff check should print the next submit command")
	_expect_true(not content.contains("eval "), "handoff check should not eval commands from the packet")


func test_representative_human_playtest_worksheet_contract() -> void:
	var path := "../production/qa/playtests/representative-human-playtest-worksheet.md"
	_expect_true(FileAccess.file_exists(path), "representative human playtest worksheet should exist")
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_expect_true(file != null, "representative human playtest worksheet should be readable")
	if file == null:
		return
	var content := file.get_as_text()
	_expect_true(content.contains("run_representative_playtest.sh --preflight"), "worksheet should start with preflight")
	_expect_true(content.contains("push-intent diagnostic"), "worksheet should mention that preflight runs the short push-intent diagnostic")
	_expect_true(content.contains("does not replace the Human Feel Gate"), "worksheet should keep the diagnostic separate from human feel evidence")
	_expect_true(content.contains("run_representative_playtest.sh tester-id YYYY-MM-DD"), "worksheet should include the representative run command")
	_expect_true(content.contains("complete / Chapter I End"), "worksheet should capture at the first-loop ending")
	_expect_true(content.contains("F9"), "worksheet should require F9 evidence capture")
	_expect_true(content.contains("Push-Feel Retest Focus"), "worksheet should include the latest core push-feel retest block")
	_expect_true(content.contains("Transition sanity"), "worksheet should retest the third-person to first-person arm transition")
	_expect_true(content.contains("Embodied approach"), "worksheet should retest embodied approach before first-person hand takeover")
	_expect_true(content.contains("Wrist/forearm silhouette"), "worksheet should retest first-person wrist/forearm silhouette after the latest fix")
	_expect_true(content.contains("Look-down check"), "worksheet should retest downward push-view control")
	_expect_true(content.contains("Peripheral read"), "worksheet should retest route readability during biased push")
	_expect_true(content.contains("Reticle surface targeting"), "worksheet should retest center reticle pressure-point control")
	_expect_true(content.contains("Aim bias retest"), "worksheet should retest deliberate aim-to-contact control")
	_expect_true(content.contains("Pressure angle mastery"), "worksheet should retest whether correct push angle matters")
	_expect_true(content.contains("Rollback honesty"), "worksheet should retest whether release and mistakes roll back honestly")
	_expect_true(content.contains("Visual cue clarity"), "worksheet should retest non-debug visual cue readability")
	_expect_true(content.contains("Disengage/re-engage"), "worksheet should retest push exit and return control")
	_expect_true(content.contains("Burden reads as physical labor?"), "worksheet should include burden feel gate field")
	_expect_true(content.contains("Aim changes hand contact and push direction?"), "worksheet should include aim/contact feel gate field")
	_expect_true(content.contains("Pressure angle mastery feels learnable?"), "worksheet should include pressure-angle human gate field")
	_expect_true(content.contains("Stone releases or rolls back when force is wrong?"), "worksheet should include rollback honesty human gate field")
	_expect_true(content.contains("Visual cues read as world/pressure, not debug clutter?"), "worksheet should include visual cue clarity human gate field")
	_expect_true(content.contains("Human Verdict"), "worksheet should include human verdict")
	_expect_true(content.contains("triage_human_playtest_report.sh"), "worksheet should route filled reports through triage")
	_expect_true(content.contains("check_milestone2_ready.sh"), "worksheet should finish with the strict milestone gate")
	_expect_true(content.contains("write_milestone3_handoff_report.sh"), "worksheet should write the gated Alpha handoff")


func test_playtest_protocol_readme_contract() -> void:
	var path := "../production/qa/playtests/README.md"
	_expect_true(FileAccess.file_exists(path), "playtest protocol README should exist")
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_expect_true(file != null, "playtest protocol README should be readable")
	if file == null:
		return
	var content := file.get_as_text()
	_expect_true(content.contains("production/qa/milestone2-readiness.md"), "playtest README should route testers through the current readiness report")
	_expect_true(content.contains("playtest-YYYY-MM-DD-tester-id.packet.md"), "playtest README should route testers through the per-tester packet")
	_expect_true(content.contains("tools/run_current_representative_playtest.sh"), "playtest README should name the current-handoff wrapper")
	_expect_true(content.contains("run_current_representative_playtest.sh --show"), "playtest README should show how to preview the resolved handoff")
	_expect_true(content.contains("tools/check_current_representative_handoff.sh"), "playtest README should name the current handoff status check")
	_expect_true(content.contains("tools/submit_current_representative_playtest_report.sh"), "playtest README should name the current report submit wrapper")
	_expect_true(content.contains("submit_current_representative_playtest_report.sh --show"), "playtest README should show how to preview the resolved report submit path")
	_expect_true(content.contains("prepare_representative_playtest_packet.sh tester-id YYYY-MM-DD"), "playtest README should show how to create a fresh handoff packet")
	_expect_true(content.contains("--playtest-tester-id=tester-id"), "playtest README should use a placeholder tester id for direct Godot launches")
	_expect_true(not content.contains("run_representative_playtest.sh manual-01 \"$(date +%F)\""), "playtest README should not present stale manual-01 as the active handoff")


func test_godot_readme_playtest_handoff_contract() -> void:
	var path := "../godot/README.md"
	_expect_true(FileAccess.file_exists(path), "Godot README should exist")
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_expect_true(file != null, "Godot README should be readable")
	if file == null:
		return
	var content := file.get_as_text()
	_expect_true(content.contains("tools/run_current_representative_playtest.sh"), "Godot README should point to the current representative handoff wrapper")
	_expect_true(content.contains("tools/check_current_representative_handoff.sh"), "Godot README should point to the current handoff status check")
	_expect_true(content.contains("tools/submit_current_representative_playtest_report.sh"), "Godot README should point to the current report submit wrapper")
	_expect_true(content.contains("Use the current packet/readiness report"), "Godot README should tell testers to follow packet/readiness handoff")
	_expect_true(not content.contains("playtest-2026-05-24-manual-01.md"), "Godot README should not keep the stale 2026-05-24 manual-01 snapshot path")


func test_milestone3_handoff_report_script_contract() -> void:
	var path := "../tools/write_milestone3_handoff_report.sh"
	_expect_true(FileAccess.file_exists(path), "milestone 3 handoff report script should exist")
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_expect_true(file != null, "milestone 3 handoff report script should be readable")
	if file == null:
		return
	var content := file.get_as_text()
	_expect_true(content.contains("tests/write_milestone3_handoff_report.gd"), "milestone 3 handoff script should call the Godot writer")
	_expect_true(content.contains("production/qa/playtests"), "milestone 3 handoff should scan playtest reports")
	_expect_true(content.contains("production/milestones/milestone3-alpha-handoff.md"), "milestone 3 handoff should default to production milestone path")
	_expect_true(content.contains("--log-file"), "milestone 3 handoff should use explicit writable Godot log path")


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
