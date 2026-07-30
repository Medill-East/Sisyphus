class_name GameState
extends RefCounted

enum Phase { APPROACH, ASCENT, RELEASE, DESCENT, COMPLETE }

const TuningScript = preload("res://scripts/Tuning.gd")

var tuning = TuningScript.new()
var phase: Phase = Phase.APPROACH
var elapsed: float = 0.0
var ascent_seconds: float = 0.0
var rollback_count: int = 0
var stability_score: float = 1.0
var trail_points: Array[Vector3] = []

var _last_stone_z: float = INF


func reset() -> void:
	phase = Phase.APPROACH
	elapsed = 0.0
	ascent_seconds = 0.0
	rollback_count = 0
	stability_score = 1.0
	trail_points.clear()
	_last_stone_z = INF


func advance(delta: float, player_position: Vector3, stone_position: Vector3, stone_velocity: Vector3) -> Vector3:
	elapsed += delta

	match phase:
		Phase.APPROACH:
			if player_position.distance_to(stone_position) <= tuning.contact_distance:
				phase = Phase.ASCENT
				_last_stone_z = stone_position.z
		Phase.ASCENT:
			ascent_seconds += delta
			_track_rollback(stone_position)
			_record_trail(stone_position)
			if stone_position.z <= tuning.ridge_z - tuning.stone_radius * 0.75:
				phase = Phase.RELEASE
		Phase.RELEASE:
			if stone_position.z <= tuning.ridge_z - tuning.stone_radius * 1.05 and stone_velocity.z < -0.05:
				phase = Phase.DESCENT
		Phase.DESCENT:
			var near_stone: bool = player_position.distance_to(stone_position) <= tuning.contact_distance + 0.5
			var stone_low: bool = stone_position.y <= 2.2
			if stone_low and near_stone:
				phase = Phase.COMPLETE
		Phase.COMPLETE:
			pass

	return player_position


func label() -> String:
	match phase:
		Phase.APPROACH:
			return "approach"
		Phase.ASCENT:
			return "ascent"
		Phase.RELEASE:
			return "release"
		Phase.DESCENT:
			return "descent"
		Phase.COMPLETE:
			return "complete"
	return "unknown"


func _track_rollback(stone_position: Vector3) -> void:
	if _last_stone_z == INF:
		_last_stone_z = stone_position.z
		return

	if stone_position.z > _last_stone_z + 1.1:
		rollback_count += 1
		stability_score = maxf(0.0, stability_score - 0.16)
		_last_stone_z = stone_position.z
	elif stone_position.z < _last_stone_z:
		_last_stone_z = stone_position.z


func _record_trail(stone_position: Vector3) -> void:
	if not trail_points.is_empty() and trail_points.back().distance_to(stone_position) < 0.85:
		return

	trail_points.append(stone_position)
