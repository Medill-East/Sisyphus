class_name RouteTelemetry
extends Resource

var elapsed_seconds: float = 0.0
var push_held_seconds: float = 0.0
var valid_contact_seconds: float = 0.0
var contact_loss_count: int = 0
var max_contact_distance: float = 0.0
var max_spin_ratio: float = 0.0
var uphill_push_distance: float = 0.0
var push_motion_sample_seconds: float = 0.0
var average_push_uphill_speed: float = 0.0
var min_push_uphill_speed: float = 0.0
var slow_push_seconds: float = 0.0
var current_phase: String = "approach"
var phase_seconds: Dictionary = {}

const SLOW_PUSH_SPEED_THRESHOLD := 0.65
const DEFAULT_BURDEN_MIN_SAMPLE_SECONDS := 1.0
const DEFAULT_BURDEN_MIN_UPHILL_DISTANCE := 0.15
const DEFAULT_BURDEN_MIN_SLOW_RATIO := 0.08
const DEFAULT_BURDEN_FAST_AVERAGE_SPEED := 1.15

var _was_contact_lost: bool = false
var _has_last_push_motion_sample: bool = false
var _last_push_stone_position: Vector3 = Vector3.ZERO

func reset() -> void:
	elapsed_seconds = 0.0
	push_held_seconds = 0.0
	valid_contact_seconds = 0.0
	contact_loss_count = 0
	max_contact_distance = 0.0
	max_spin_ratio = 0.0
	uphill_push_distance = 0.0
	push_motion_sample_seconds = 0.0
	average_push_uphill_speed = 0.0
	min_push_uphill_speed = 0.0
	slow_push_seconds = 0.0
	current_phase = "approach"
	phase_seconds.clear()
	_was_contact_lost = false
	_has_last_push_motion_sample = false
	_last_push_stone_position = Vector3.ZERO


func sample(
	delta: float,
	phase_label: String,
	wants_push: bool,
	push_frame,
	player_position: Vector3,
	stone_position: Vector3,
	tuning
) -> void:
	elapsed_seconds += delta
	current_phase = phase_label
	phase_seconds[phase_label] = float(phase_seconds.get(phase_label, 0.0)) + delta

	if not wants_push:
		_was_contact_lost = false
		_has_last_push_motion_sample = false
		return

	push_held_seconds += delta
	var distance: float = player_position.distance_to(stone_position)
	max_contact_distance = maxf(max_contact_distance, distance)
	if push_frame != null and push_frame.get("spin_to_translation_ratio") != null:
		max_spin_ratio = maxf(max_spin_ratio, float(push_frame.get("spin_to_translation_ratio")))

	var valid_contact: bool = false
	if push_frame != null and push_frame.get("contact_valid") != null:
		valid_contact = bool(push_frame.get("contact_valid"))
	valid_contact = valid_contact and distance <= tuning.push_disengage_distance + 0.18

	if valid_contact:
		valid_contact_seconds += delta
		_was_contact_lost = false
		_sample_push_motion(delta, push_frame, stone_position, tuning)
	elif not _was_contact_lost:
		contact_loss_count += 1
		_was_contact_lost = true
		_has_last_push_motion_sample = false
	else:
		_has_last_push_motion_sample = false


func contact_ratio() -> float:
	if push_held_seconds <= 0.001:
		return 0.0
	return clampf(valid_contact_seconds / push_held_seconds, 0.0, 1.0)


func playtest_verdict(tuning = null) -> String:
	var disengage_distance: float = _push_disengage_distance(tuning)
	if push_held_seconds < 1.0:
		return "PIVOT"
	if contact_ratio() < 0.25 or max_contact_distance > disengage_distance + 2.0 or max_spin_ratio > 14.0:
		return "KILL"
	if contact_ratio() < 0.78 or contact_loss_count > 4 or max_contact_distance > disengage_distance + 0.65 or max_spin_ratio > 8.0:
		return "PIVOT"
	return "PROCEED"


func playtest_reason(tuning = null) -> String:
	var disengage_distance: float = _push_disengage_distance(tuning)
	var verdict: String = playtest_verdict(tuning)
	if verdict == "PROCEED":
		return "stable contact and coupled rolling"
	if verdict == "KILL":
		return "broken push: contact/translation failed"
	if contact_ratio() < 0.78:
		return "contact ratio below hand-play target"
	if contact_loss_count > 4:
		return "contact loss too frequent"
	if max_contact_distance > disengage_distance + 0.65:
		return "contact distance too unstable"
	if max_spin_ratio > 8.0:
		return "stone spin too detached from translation"
	return "route needs tuning"


func burden_ratio() -> float:
	if push_motion_sample_seconds <= 0.001:
		return 0.0
	return clampf(slow_push_seconds / push_motion_sample_seconds, 0.0, 1.0)


func burden_verdict(tuning = null) -> String:
	if playtest_verdict(tuning) == "KILL":
		return "KILL"
	if push_motion_sample_seconds < _burden_min_sample_seconds(tuning) or uphill_push_distance < _burden_min_uphill_distance(tuning):
		return "KILL"
	if average_push_uphill_speed > _burden_fast_average_speed(tuning) or burden_ratio() < _burden_min_slow_ratio(tuning):
		return "PIVOT"
	return "PROCEED"


func burden_reason(tuning = null) -> String:
	if playtest_verdict(tuning) == "KILL":
		return "push contact is not stable enough to judge burden: %s" % playtest_reason(tuning)
	if push_motion_sample_seconds < _burden_min_sample_seconds(tuning) or uphill_push_distance < _burden_min_uphill_distance(tuning):
		return "no measurable uphill work"
	if average_push_uphill_speed > _burden_fast_average_speed(tuning) or burden_ratio() < _burden_min_slow_ratio(tuning):
		return "push is too smooth/fast for burden: average %.2fm/s, slow ratio %.0f%%" % [
			average_push_uphill_speed,
			burden_ratio() * 100.0,
		]
	return "measurable labor and controlled uphill work"


func slice_verdict(tuning = null) -> String:
	var push_verdict: String = playtest_verdict(tuning)
	if push_verdict == "KILL":
		return "KILL"
	var min_seconds: float = _representative_min_seconds(tuning)
	var max_seconds: float = _representative_max_seconds(tuning)
	if elapsed_seconds < min_seconds:
		return "PIVOT"
	if current_phase != "complete":
		return "PIVOT"
	if elapsed_seconds > max_seconds:
		return "PIVOT"
	if push_verdict != "PROCEED":
		return "PIVOT"
	return "PROCEED"


func slice_reason(tuning = null) -> String:
	var push_verdict: String = playtest_verdict(tuning)
	if push_verdict == "KILL":
		return "push gate failed: %s" % playtest_reason(tuning)
	var min_seconds: float = _representative_min_seconds(tuning)
	var max_seconds: float = _representative_max_seconds(tuning)
	if elapsed_seconds < min_seconds:
		return "too short for representative %.0f-%.0f minute loop" % [min_seconds / 60.0, max_seconds / 60.0]
	if current_phase != "complete":
		return "loop did not reach complete"
	if elapsed_seconds > max_seconds:
		return "too long for current representative slice target"
	if push_verdict != "PROCEED":
		return "push gate still needs tuning: %s" % playtest_reason(tuning)
	return "representative %.0f-%.0f minute complete loop" % [min_seconds / 60.0, max_seconds / 60.0]


func _push_disengage_distance(tuning) -> float:
	if tuning != null and tuning.get("push_disengage_distance") != null:
		return float(tuning.get("push_disengage_distance"))
	return 3.35


func _representative_min_seconds(tuning) -> float:
	if tuning != null and tuning.get("representative_slice_min_seconds") != null:
		return maxf(1.0, float(tuning.get("representative_slice_min_seconds")))
	return 300.0


func _representative_max_seconds(tuning) -> float:
	var min_seconds: float = _representative_min_seconds(tuning)
	if tuning != null and tuning.get("representative_slice_max_seconds") != null:
		return maxf(min_seconds, float(tuning.get("representative_slice_max_seconds")))
	return 600.0


func _burden_min_sample_seconds(tuning) -> float:
	if tuning != null and tuning.get("burden_min_sample_seconds") != null:
		return maxf(0.1, float(tuning.get("burden_min_sample_seconds")))
	return DEFAULT_BURDEN_MIN_SAMPLE_SECONDS


func _burden_min_uphill_distance(tuning) -> float:
	if tuning != null and tuning.get("burden_min_uphill_distance") != null:
		return maxf(0.0, float(tuning.get("burden_min_uphill_distance")))
	return DEFAULT_BURDEN_MIN_UPHILL_DISTANCE


func _burden_min_slow_ratio(tuning) -> float:
	if tuning != null and tuning.get("burden_min_slow_ratio") != null:
		return clampf(float(tuning.get("burden_min_slow_ratio")), 0.0, 1.0)
	return DEFAULT_BURDEN_MIN_SLOW_RATIO


func _burden_fast_average_speed(tuning) -> float:
	if tuning != null and tuning.get("burden_fast_average_speed") != null:
		return maxf(0.01, float(tuning.get("burden_fast_average_speed")))
	return DEFAULT_BURDEN_FAST_AVERAGE_SPEED


func _sample_push_motion(delta: float, push_frame, stone_position: Vector3, tuning) -> void:
	var uphill_direction := Vector3(0.0, 0.0, -1.0)
	if push_frame != null and push_frame.get("uphill_direction") != null:
		uphill_direction = Vector3(push_frame.get("uphill_direction")).normalized()
	if uphill_direction.length_squared() < 0.001:
		uphill_direction = Vector3(0.0, 0.0, -1.0)
	if not _has_last_push_motion_sample:
		_last_push_stone_position = stone_position
		_has_last_push_motion_sample = true
		return

	var uphill_displacement: float = (stone_position - _last_push_stone_position).dot(uphill_direction)
	var uphill_speed: float = uphill_displacement / maxf(0.001, delta)
	uphill_push_distance += maxf(0.0, uphill_displacement)
	push_motion_sample_seconds += delta
	average_push_uphill_speed = uphill_push_distance / maxf(0.001, push_motion_sample_seconds)
	if push_motion_sample_seconds <= delta + 0.0001:
		min_push_uphill_speed = uphill_speed
	else:
		min_push_uphill_speed = minf(min_push_uphill_speed, uphill_speed)
	if uphill_speed <= _burden_slow_speed_threshold(tuning):
		slow_push_seconds += delta
	_last_push_stone_position = stone_position


func hud_summary(tuning = null) -> String:
	return "Telemetry: %s %.1fs | Contact %.0f%% | Loss %d | Dist %.2f | Spin %.1f | Effort %.2fm %.1fs | Push %s | Burden %s | Slice %s" % [
		current_phase,
		elapsed_seconds,
		contact_ratio() * 100.0,
		contact_loss_count,
		max_contact_distance,
		max_spin_ratio,
		uphill_push_distance,
		slow_push_seconds,
		playtest_verdict(tuning),
		burden_verdict(tuning),
		slice_verdict(tuning),
	]


func _burden_slow_speed_threshold(tuning) -> float:
	if tuning != null and tuning.get("burden_slow_speed_threshold") != null:
		return maxf(0.01, float(tuning.get("burden_slow_speed_threshold")))
	return SLOW_PUSH_SPEED_THRESHOLD
