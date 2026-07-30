class_name TrailRecorder
extends Node

class TrailPoint:
	var position: Vector3
	var pressure: float
	var stability: float

	func _init(next_position: Vector3, next_pressure: float, next_stability: float) -> void:
		position = next_position
		pressure = next_pressure
		stability = next_stability


var min_spacing: float = 0.45
var points: Array[TrailPoint] = []


func clear() -> void:
	points.clear()


func record(position: Vector3, pressure: float, stability: float) -> void:
	if not points.is_empty() and points[-1].position.distance_to(position) < min_spacing:
		return
	points.append(TrailPoint.new(position, pressure, stability))
