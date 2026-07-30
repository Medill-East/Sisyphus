class_name LevelDefinition
extends Resource

var level_id: int = 0
var divine_state: String = ""
var weather_intensity: float = 0.0
var wind_strength: float = 0.0
var rain_slip: float = 0.0
var stone_smoothness: float = 0.0
var par_ascent_seconds: float = 0.0
var daylight_grace_seconds: float = 0.0
var hum_phrase_id: String = ""


static func create_storm_vertical_slice():
	var level = load("res://scripts/LevelDefinition.gd").new()
	level.level_id = 4
	level.divine_state = "anger"
	level.weather_intensity = 0.72
	level.wind_strength = 0.38
	level.rain_slip = 0.30
	level.stone_smoothness = 0.52
	level.par_ascent_seconds = 420.0
	level.daylight_grace_seconds = 240.0
	level.hum_phrase_id = "ode_motif_4"
	return level
