class_name LevelManager
extends Node

const RunMetricsScript = preload("res://scripts/RunMetrics.gd")

var active_level
var phase: String = "approach"
var metrics = RunMetricsScript.new()
var player_position_at_release: Vector3 = Vector3.ZERO


func start_level(level) -> void:
	active_level = level
	phase = "approach"
	metrics = RunMetricsScript.new()


func mark_ascent_started() -> void:
	phase = "ascent"


func mark_released(player_position: Vector3) -> void:
	player_position_at_release = player_position
	phase = "release"


func mark_stone_entered_back_slope() -> void:
	if phase == "release":
		phase = "descent"


func mark_complete() -> void:
	if active_level != null:
		metrics.finalize_level(active_level)
	phase = "complete"
