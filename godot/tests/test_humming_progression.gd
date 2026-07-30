extends SceneTree

const LevelDefinitionScript = preload("res://scripts/LevelDefinition.gd")
const RunMetricsScript = preload("res://scripts/RunMetrics.gd")
const HummingControllerScript = preload("res://scripts/HummingController.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_run()
	if failures.is_empty():
		print("All humming progression tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run() -> void:
	test_humming_phrase_clarity_tracks_metrics()
	test_fragmented_run_keeps_storm_prominent()
	test_clear_hum_generates_internal_audio_stream()
	test_fragmented_hum_generates_quieter_less_complete_stream()
	test_clear_chapter_end_mix_keeps_storm_present()
	test_fragmented_chapter_end_mix_keeps_hum_subordinate()


func test_humming_phrase_clarity_tracks_metrics() -> void:
	var level = LevelDefinitionScript.create_storm_vertical_slice()
	var metrics = RunMetricsScript.new()
	metrics.ascent_seconds = level.par_ascent_seconds * 0.95
	metrics.contact_stability = 0.9
	metrics.recovery_count = 1
	metrics.finalize_level(level)
	var hum = HummingControllerScript.new()
	hum.apply_result(level, metrics)
	_expect_true(hum.active_phrase_id == "ode_motif_4", "hum should use level phrase")
	_expect_true(hum.clarity > 0.65, "strong run should produce clearer hum")
	_expect_true(hum.storm_ducking > 0.15, "clear hum should push storm slightly behind it")
	hum.free()


func test_fragmented_run_keeps_storm_prominent() -> void:
	var level = LevelDefinitionScript.create_storm_vertical_slice()
	var metrics = RunMetricsScript.new()
	metrics.ascent_seconds = level.par_ascent_seconds * 1.8
	metrics.contact_stability = 0.25
	metrics.rollback_count = 5
	metrics.finalize_level(level)
	var hum = HummingControllerScript.new()
	hum.apply_result(level, metrics)
	_expect_true(hum.clarity < 0.35, "weak run should keep the hum fragmented")
	_expect_true(hum.storm_ducking < 0.12, "fragmented hum should not overpower the storm")
	hum.free()


func test_clear_hum_generates_internal_audio_stream() -> void:
	var level = LevelDefinitionScript.create_storm_vertical_slice()
	var metrics = RunMetricsScript.new()
	metrics.ascent_seconds = level.par_ascent_seconds * 0.9
	metrics.contact_stability = 0.92
	metrics.finalize_level(level)
	var hum = HummingControllerScript.new()
	hum.apply_result(level, metrics)
	var stream = hum.get("audio_stream")
	_expect_true(stream is AudioStreamWAV, "clear hum should generate a Godot AudioStreamWAV")
	_expect_true(hum.get("external_audio_path") == "", "hum should not point to an external audio asset")
	_expect_true(hum.has_method("uses_external_audio") and not hum.uses_external_audio(), "hum should report that it uses no external audio")
	_expect_true(_as_int(hum.get("motif_note_count")) >= 4, "clear hum should include the full opening motif")
	_expect_true(_as_int(hum.get("generated_sample_count")) > 16000, "clear hum should contain enough generated samples to hear a phrase")
	_expect_true(_as_float(hum.get("last_peak_amplitude")) > 0.08, "clear hum should be audible")
	if stream is AudioStreamWAV:
		_expect_true(stream.get("data").size() > 32000, "clear hum stream should contain PCM data")
		_expect_true(int(stream.get("mix_rate")) >= 16000, "clear hum should use an audible sample rate")
	hum.free()


func test_fragmented_hum_generates_quieter_less_complete_stream() -> void:
	var level = LevelDefinitionScript.create_storm_vertical_slice()
	var metrics = RunMetricsScript.new()
	metrics.ascent_seconds = level.par_ascent_seconds * 2.1
	metrics.contact_stability = 0.18
	metrics.rollback_count = 6
	metrics.finalize_level(level)
	var weak_hum = HummingControllerScript.new()
	weak_hum.apply_result(level, metrics)
	_expect_true(weak_hum.get("audio_stream") is AudioStreamWAV, "fragmented hum should still generate an internal stream")
	_expect_true(_as_int(weak_hum.get("motif_note_count")) > 0, "fragmented hum should keep at least one motif note")
	_expect_true(_as_int(weak_hum.get("motif_note_count")) < 4, "fragmented hum should withhold some motif notes")
	_expect_true(_as_float(weak_hum.get("last_peak_amplitude")) < 0.08, "fragmented hum should stay quieter than a clear reward")
	weak_hum.free()


func test_clear_chapter_end_mix_keeps_storm_present() -> void:
	var level = LevelDefinitionScript.create_storm_vertical_slice()
	var metrics = RunMetricsScript.new()
	metrics.ascent_seconds = level.par_ascent_seconds * 0.9
	metrics.contact_stability = 0.92
	metrics.finalize_level(level)
	var hum = HummingControllerScript.new()
	hum.apply_result(level, metrics)
	_expect_true(hum.has_method("chapter_end_mix_state"), "hum controller should expose chapter-end audio mix state")
	if hum.has_method("chapter_end_mix_state"):
		var mix: Dictionary = hum.chapter_end_mix_state(0.84)
		var storm_audio: float = _as_float(mix.get("storm_audio_presence", 0.0))
		var hum_presence: float = _as_float(mix.get("hum_presence", 0.0))
		_expect_true(storm_audio >= 0.78, "chapter end should keep the storm audibly present")
		_expect_true(hum_presence >= 0.55, "clear chapter end should still let the hum be heard")
		_expect_true(storm_audio > hum_presence, "the hum should resist the storm, not erase it")
		_expect_true(not bool(mix.get("uses_external_audio", true)), "chapter-end hum mix should still use generated audio only")
		_expect_true(str(mix.get("audio_beat", "")).contains("hum resists"), "chapter-end mix should name the unresolved audio beat")
	hum.free()


func test_fragmented_chapter_end_mix_keeps_hum_subordinate() -> void:
	var level = LevelDefinitionScript.create_storm_vertical_slice()
	var metrics = RunMetricsScript.new()
	metrics.ascent_seconds = level.par_ascent_seconds * 2.0
	metrics.contact_stability = 0.22
	metrics.rollback_count = 6
	metrics.finalize_level(level)
	var hum = HummingControllerScript.new()
	hum.apply_result(level, metrics)
	_expect_true(hum.has_method("chapter_end_mix_state"), "hum controller should expose chapter-end audio mix state")
	if hum.has_method("chapter_end_mix_state"):
		var mix: Dictionary = hum.chapter_end_mix_state(0.86)
		var storm_audio: float = _as_float(mix.get("storm_audio_presence", 0.0))
		var hum_presence: float = _as_float(mix.get("hum_presence", 0.0))
		_expect_true(storm_audio >= 0.82, "weak chapter end should keep storm pressure in front")
		_expect_true(hum_presence < 0.45, "fragmented chapter end should keep the hum incomplete")
		_expect_true(storm_audio - hum_presence > 0.35, "fragmented hum should stay clearly below the storm")
	hum.free()


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _as_int(value: Variant) -> int:
	if value is int:
		return value
	if value is float:
		return int(value)
	return 0


func _as_float(value: Variant) -> float:
	if value is float:
		return value
	if value is int:
		return float(value)
	return 0.0
