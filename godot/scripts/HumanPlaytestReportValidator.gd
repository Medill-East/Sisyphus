class_name HumanPlaytestReportValidator
extends RefCounted


const REQUIRED_FEEL_FIELDS: Array[String] = [
	"Burden reads as physical labor?",
	"Camera pressure is intense but playable?",
	"Aim changes hand contact and push direction?",
	"Pressure angle mastery feels learnable?",
	"Stone releases or rolls back when force is wrong?",
	"Release/descent contrast is clear?",
	"Visual cues read as world/pressure, not debug clutter?",
	"Chapter I End reads as intentional, not unfinished?",
]

const REQUIRED_PUSH_FEEL_RETESTS: Array[String] = [
	"Transition sanity",
	"Embodied approach",
	"Hand surface",
	"Wrist/forearm silhouette",
	"Look-down check",
	"Peripheral read",
	"Reticle surface targeting",
	"Aim bias retest",
	"Pressure angle mastery",
	"Rollback honesty",
	"Visual cue clarity",
	"Disengage/re-engage",
]

const VALID_FEEL_ANSWERS: Array[String] = ["Yes", "No", "Partially"]
const VALID_RETEST_ANSWERS: Array[String] = ["Yes", "No"]
const VALID_VERDICTS: Array[String] = ["PROCEED", "PIVOT", "KILL"]


static func validate_report_text(text: String) -> Dictionary:
	var errors: Array[String] = []
	if text.strip_edges().is_empty():
		errors.append("report is empty")
	if not text.contains("# Playtest Report"):
		errors.append("missing playtest report heading")
	if not text.contains("## Human Feel Gate"):
		errors.append("missing Human Feel Gate section")
	_validate_push_feel_retest(text, errors)

	for field in REQUIRED_FEEL_FIELDS:
		var answer := _field_value(text, field)
		if answer.is_empty():
			errors.append("missing field: %s" % field)
		elif _is_placeholder(answer):
			errors.append("unfilled field: %s" % field)
		elif not VALID_FEEL_ANSWERS.has(answer):
			errors.append("invalid answer for %s: %s" % [field, answer])

	var human_verdict := _field_value(text, "Human Verdict")
	if human_verdict.is_empty():
		errors.append("missing field: Human Verdict")
	elif _is_placeholder(human_verdict):
		errors.append("unfilled field: Human Verdict")
	elif not VALID_VERDICTS.has(human_verdict):
		errors.append("invalid Human Verdict: %s" % human_verdict)

	var reason := _field_value(text, "Verdict Reason")
	if reason.is_empty():
		errors.append("missing field: Verdict Reason")
	elif _is_placeholder(reason):
		errors.append("unfilled field: Verdict Reason")
	elif reason.length() < 8:
		errors.append("Verdict Reason is too short")

	_validate_objective_gate_alignment(text, human_verdict, errors)
	_validate_push_feel_gate_alignment(text, human_verdict, errors)

	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"human_verdict": human_verdict,
		"verdict_reason": reason,
	}


static func validate_report_file(path: String) -> Dictionary:
	if path.strip_edges().is_empty():
		return {
			"valid": false,
			"errors": ["missing --report-path"],
			"human_verdict": "",
			"verdict_reason": "",
		}
	if not FileAccess.file_exists(path):
		return {
			"valid": false,
			"errors": ["report does not exist: %s" % path],
			"human_verdict": "",
			"verdict_reason": "",
		}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"valid": false,
			"errors": ["report is not readable: %s" % path],
			"human_verdict": "",
			"verdict_reason": "",
		}
	return validate_report_text(file.get_as_text())


static func _field_value(text: String, label: String) -> String:
	var prefix := "- **%s**:" % label
	for raw_line in text.split("\n"):
		var line := str(raw_line).strip_edges()
		if line.begins_with(prefix):
			return line.substr(prefix.length()).strip_edges()
	return ""


static func _validate_push_feel_retest(text: String, errors: Array[String]) -> void:
	if not text.contains("## Push-Feel Retest Focus"):
		errors.append("missing Push-Feel Retest Focus section")
		return
	for label in REQUIRED_PUSH_FEEL_RETESTS:
		var answer := _table_answer(text, label)
		if answer.is_empty():
			errors.append("missing push-feel retest: %s" % label)
		elif _is_placeholder(answer):
			errors.append("unfilled push-feel retest: %s" % label)
		elif not VALID_RETEST_ANSWERS.has(answer):
			errors.append("invalid push-feel retest answer for %s: %s" % [label, answer])


static func _table_answer(text: String, label: String) -> String:
	for raw_line in text.split("\n"):
		var line := str(raw_line).strip_edges()
		if not line.begins_with("| %s:" % label):
			continue
		var cells := line.split("|")
		if cells.size() < 4:
			return ""
		return str(cells[2]).strip_edges()
	return ""


static func _validate_objective_gate_alignment(text: String, human_verdict: String, errors: Array[String]) -> void:
	if human_verdict != "PROCEED":
		return
	var pacing_profile := _field_value(text, "Pacing Profile")
	if pacing_profile != "representative":
		errors.append("Human Verdict PROCEED requires Pacing Profile representative")
	var phase := _field_value(text, "Phase At End")
	if phase != "complete":
		errors.append("Human Verdict PROCEED requires Phase At End complete")
	for gate in ["Push Gate", "Burden Gate", "Slice Gate"]:
		var value := _field_value(text, gate)
		if value != "PROCEED":
			errors.append("Human Verdict PROCEED requires %s PROCEED" % gate)


static func _validate_push_feel_gate_alignment(text: String, human_verdict: String, errors: Array[String]) -> void:
	if human_verdict != "PROCEED":
		return
	for label in REQUIRED_PUSH_FEEL_RETESTS:
		var answer := _table_answer(text, label)
		if answer != "Yes":
			errors.append("Human Verdict PROCEED requires push-feel retest %s Yes" % label)


static func _is_placeholder(value: String) -> bool:
	var trimmed := value.strip_edges()
	return trimmed.is_empty() or (trimmed.begins_with("[") and trimmed.ends_with("]"))
