class_name HummingController
extends Node

const SAMPLE_RATE: int = 22050
const BASE_FREQUENCY: float = 329.63
const ODE_INTERVALS: Array[int] = [0, 0, 1, 3, 3, 1, 0, -2]
const SEMITONE_RATIO: float = 1.0594630943592953
const TAU_VALUE: float = PI * 2.0

var active_phrase_id: String = ""
var clarity: float = 0.0
var storm_ducking: float = 0.0
var audio_stream: AudioStreamWAV = null
var external_audio_path: String = ""
var motif_note_count: int = 0
var generated_sample_count: int = 0
var last_peak_amplitude: float = 0.0


func apply_result(level, metrics) -> void:
	active_phrase_id = level.hum_phrase_id
	clarity = metrics.hum_clarity
	storm_ducking = clampf(clarity * 0.35, 0.0, 0.35)
	audio_stream = build_hum_stream()


func uses_external_audio() -> bool:
	return not external_audio_path.is_empty()


func chapter_end_mix_state(storm_pressure: float) -> Dictionary:
	var storm_audio_presence: float = clampf(
		maxf(0.72, storm_pressure - storm_ducking * 0.12),
		0.0,
		1.0
	)
	var hum_presence: float = clampf(0.18 + clarity * 0.62, 0.0, 0.78)
	if clarity < 0.35:
		hum_presence = clampf(0.12 + clarity * 0.85, 0.0, 0.44)
	return {
		"audio_beat": "storm remains; hum resists",
		"storm_audio_presence": storm_audio_presence,
		"hum_presence": hum_presence,
		"hum_not_overpowering_storm": hum_presence < storm_audio_presence,
		"storm_ducking": storm_ducking,
		"uses_external_audio": uses_external_audio(),
	}


func build_hum_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	var pcm := PackedByteArray()
	var note_count: int = _note_count_for_clarity(clarity)
	var note_seconds: float = lerpf(0.24, 0.34, clarity)
	var pause_seconds: float = lerpf(0.08, 0.025, clarity)
	var amplitude: float = lerpf(0.035, 0.16, clarity)

	motif_note_count = note_count
	generated_sample_count = 0
	last_peak_amplitude = 0.0

	for index in note_count:
		var frequency: float = BASE_FREQUENCY * pow(SEMITONE_RATIO, float(ODE_INTERVALS[index]))
		_append_hum_note(pcm, frequency, note_seconds, amplitude, clarity)
		_append_silence(pcm, pause_seconds)

	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm
	return stream


func _note_count_for_clarity(value: float) -> int:
	if value >= 0.66:
		return 6
	if value >= 0.42:
		return 4
	if value >= 0.18:
		return 2
	return 1


func _append_hum_note(pcm: PackedByteArray, frequency: float, seconds: float, amplitude: float, hum_clarity: float) -> void:
	var sample_count: int = maxi(1, int(seconds * SAMPLE_RATE))
	for sample_index in sample_count:
		var t: float = float(sample_index) / SAMPLE_RATE
		var progress: float = float(sample_index) / maxf(1.0, float(sample_count - 1))
		var envelope: float = _note_envelope(progress)
		var vibrato: float = sin(TAU_VALUE * 4.2 * t) * lerpf(0.006, 0.018, hum_clarity)
		var breath: float = sin(TAU_VALUE * 1.3 * t + 0.7) * lerpf(0.04, 0.015, hum_clarity)
		var sample: float = sin(TAU_VALUE * frequency * (1.0 + vibrato) * t)
		sample += 0.22 * sin(TAU_VALUE * frequency * 0.5 * t)
		sample = sample * amplitude * envelope * (1.0 + breath)
		_append_sample_16(pcm, sample)
		generated_sample_count += 1
		last_peak_amplitude = maxf(last_peak_amplitude, absf(sample))


func _append_silence(pcm: PackedByteArray, seconds: float) -> void:
	var sample_count: int = maxi(0, int(seconds * SAMPLE_RATE))
	for sample_index in sample_count:
		_append_sample_16(pcm, 0.0)
		generated_sample_count += 1


func _note_envelope(progress: float) -> float:
	var attack: float = smoothstep(0.0, 0.12, progress)
	var release: float = 1.0 - smoothstep(0.78, 1.0, progress)
	return clampf(attack * release, 0.0, 1.0)


func _append_sample_16(pcm: PackedByteArray, sample: float) -> void:
	var quantized: int = clampi(int(sample * 32767.0), -32768, 32767)
	pcm.append(quantized & 0xff)
	pcm.append((quantized >> 8) & 0xff)
