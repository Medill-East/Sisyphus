class_name RunMetrics
extends Resource

var ascent_seconds: float = 0.0
var contact_stability: float = 0.0
var rollback_count: int = 0
var recovery_count: int = 0
var daylight_reward: float = 0.0
var hum_clarity: float = 0.0


func finalize_level(level) -> void:
	var late_seconds: float = maxf(0.0, ascent_seconds - level.par_ascent_seconds)
	daylight_reward = clampf(1.0 - late_seconds / maxf(1.0, level.daylight_grace_seconds), 0.0, 1.0)
	var time_score: float = clampf(level.par_ascent_seconds / maxf(1.0, ascent_seconds), 0.0, 1.0)
	var recovery_score: float = clampf(float(recovery_count) / 3.0, 0.0, 1.0)
	var rollback_penalty: float = clampf(float(rollback_count) * 0.08, 0.0, 0.35)
	hum_clarity = clampf(
		time_score * 0.45
		+ contact_stability * 0.35
		+ recovery_score * 0.20
		- rollback_penalty,
		0.0,
		1.0
	)
