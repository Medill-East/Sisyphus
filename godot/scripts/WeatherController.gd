class_name WeatherController
extends Node3D

var active_intensity: float = 0.0
var active_wind: float = 0.0
var active_rain_slip: float = 0.0


func apply_level(level, mastery_pressure: float) -> void:
	active_intensity = clampf(level.weather_intensity + mastery_pressure, 0.0, 1.0)
	active_wind = clampf(level.wind_strength + mastery_pressure * 0.4, 0.0, 1.0)
	active_rain_slip = clampf(level.rain_slip + mastery_pressure * 0.2, 0.0, 0.65)
