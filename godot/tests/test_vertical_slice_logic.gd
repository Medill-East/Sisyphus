extends SceneTree

const LevelDefinitionScript = preload("res://scripts/LevelDefinition.gd")
const RunMetricsScript = preload("res://scripts/RunMetrics.gd")
const LevelManagerScript = preload("res://scripts/LevelManager.gd")
const WeatherControllerScript = preload("res://scripts/WeatherController.gd")
const TuningScript = preload("res://scripts/Tuning.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_run()
	if failures.is_empty():
		print("All vertical slice logic tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run() -> void:
	test_level_4_storm_definition()
	test_metrics_compute_daylight_and_hum_clarity()
	test_slow_run_still_completes_with_lower_reward()
	test_representative_pacing_profile_targets_vertical_slice_duration()
	test_release_to_descent_preserves_player_position()
	test_weather_uses_divine_pressure_without_changing_level_identity()


func test_level_4_storm_definition() -> void:
	var level = LevelDefinitionScript.create_storm_vertical_slice()
	_expect_true(level.level_id == 4, "vertical slice should target mid-game Level 4")
	_expect_true(level.divine_state == "anger", "Level 4 should express divine anger")
	_expect_true(level.weather_intensity >= 0.65, "storm level should have strong weather")
	_expect_true(level.stone_smoothness > 0.35 and level.stone_smoothness < 0.75, "stone should be worn but not final-polished")
	_expect_true(level.par_ascent_seconds > 0.0, "level should define a par ascent time")
	_expect_true(level.hum_phrase_id == "ode_motif_4", "level should bind to a hum phrase")


func test_metrics_compute_daylight_and_hum_clarity() -> void:
	var level = LevelDefinitionScript.create_storm_vertical_slice()
	var metrics = RunMetricsScript.new()
	metrics.ascent_seconds = level.par_ascent_seconds * 0.9
	metrics.contact_stability = 0.82
	metrics.rollback_count = 1
	metrics.recovery_count = 2
	metrics.finalize_level(level)
	_expect_true(metrics.daylight_reward > 0.75, "fast ascent should preserve daylight")
	_expect_true(metrics.hum_clarity > 0.65, "stable fast ascent should make hum clearer")


func test_slow_run_still_completes_with_lower_reward() -> void:
	var level = LevelDefinitionScript.create_storm_vertical_slice()
	var metrics = RunMetricsScript.new()
	metrics.ascent_seconds = level.par_ascent_seconds + level.daylight_grace_seconds * 1.4
	metrics.contact_stability = 0.45
	metrics.rollback_count = 4
	metrics.finalize_level(level)
	_expect_true(metrics.daylight_reward <= 0.05, "very slow ascent should lose daylight reward")
	_expect_true(metrics.hum_clarity < 0.45, "messy slow ascent should keep hum fragmented")


func test_representative_pacing_profile_targets_vertical_slice_duration() -> void:
	var tuning = TuningScript.new()
	_expect_true(tuning.has_method("apply_vertical_slice_pacing_profile"), "tuning should expose vertical-slice pacing profiles")
	_expect_true(tuning.has_method("estimated_loop_seconds_for_current_pacing"), "tuning should estimate loop duration for pacing profiles")
	if not tuning.has_method("apply_vertical_slice_pacing_profile") or not tuning.has_method("estimated_loop_seconds_for_current_pacing"):
		return
	tuning.apply_vertical_slice_pacing_profile("representative")
	_expect_true(tuning.get("burden_fast_average_speed") != null, "tuning should expose burden fast-speed gate")
	_expect_true(tuning.get("burden_min_slow_ratio") != null, "tuning should expose burden slow-ratio gate")
	if tuning.get("burden_fast_average_speed") == null or tuning.get("burden_min_slow_ratio") == null:
		return
	var representative_target_speed: float = tuning.burden_target_uphill_speed
	var representative_fast_speed: float = float(tuning.get("burden_fast_average_speed"))
	var representative_slow_ratio: float = float(tuning.get("burden_min_slow_ratio"))
	var representative_slow_threshold: float = float(tuning.get("burden_slow_speed_threshold") if tuning.get("burden_slow_speed_threshold") != null else 0.0)
	var front_distance: float = tuning.front_base_z - tuning.ridge_z
	var back_distance: float = tuning.ridge_z - tuning.back_base_z
	var estimated_seconds: float = tuning.estimated_loop_seconds_for_current_pacing()
	_expect_true(front_distance >= 220.0, "representative pacing should materially extend the ascent route")
	_expect_true(back_distance >= 520.0, "representative pacing should give descent real travel time")
	_expect_true(tuning.obstacle_density >= 80, "representative pacing should add enough obstacle pressure for the longer route")
	_expect_true(representative_target_speed <= 0.72, "representative pacing should lower target uphill speed for sustained burden")
	_expect_true(representative_fast_speed <= 0.96, "representative burden gate should reject smooth fast pushing")
	_expect_true(representative_slow_ratio >= 0.18, "representative burden gate should require visible slow labor")
	_expect_true(representative_slow_threshold >= 0.78, "representative pacing should count controlled sub-target movement as slow labor")
	_expect_true(estimated_seconds >= tuning.representative_slice_min_seconds, "representative pacing estimate should enter the slice timing window")
	_expect_true(estimated_seconds <= tuning.representative_slice_max_seconds, "representative pacing estimate should stay below the max slice target")


func test_release_to_descent_preserves_player_position() -> void:
	var manager = LevelManagerScript.new()
	manager.active_level = LevelDefinitionScript.create_storm_vertical_slice()
	manager.phase = "ascent"
	var before := Vector3(0.5, 4.0, -24.0)
	manager.player_position_at_release = before
	manager.mark_released(before)
	_expect_true(manager.phase == "release", "release should be its own transition phase")
	manager.mark_stone_entered_back_slope()
	_expect_true(manager.phase == "descent", "stone on back slope should enter descent")
	_expect_true(manager.player_position_at_release.distance_to(before) < 0.001, "release/descent must not teleport player")
	manager.free()


func test_weather_uses_divine_pressure_without_changing_level_identity() -> void:
	var level = LevelDefinitionScript.create_storm_vertical_slice()
	var weather = WeatherControllerScript.new()
	weather.apply_level(level, 0.25)
	_expect_true(weather.active_intensity > level.weather_intensity, "mastery should provoke stronger storm pressure")
	_expect_true(weather.active_intensity <= 1.0, "weather intensity should stay bounded")
	_expect_true(weather.active_wind >= level.wind_strength, "storm wind should not weaken below level baseline")
	weather.free()


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
