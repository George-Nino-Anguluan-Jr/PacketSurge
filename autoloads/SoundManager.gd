# SoundManager.gd
extends Node

var hover_sound: AudioStreamWAV
var click_sound: AudioStreamWAV
var tick_sound: AudioStreamWAV
var success_sound: AudioStreamWAV
var error_sound: AudioStreamWAV
var notify_sound: AudioStreamWAV
var transition_sound: AudioStreamWAV
var collect_sound: AudioStreamWAV
var wave_alert_sound: AudioStreamWAV
var level_complete_sound: AudioStreamWAV
var game_over_sound: AudioStreamWAV

var effects_volume: float = 1.0

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_generate_all_sounds()
	_connect_signals()

func _connect_signals() -> void:
	SignalBus.wave_started.connect(func(_n): play_wave_alert())
	SignalBus.level_complete.connect(func(_a, _b, _c): play_level_complete())
	SignalBus.tower_unlocked.connect(func(_id): play_notify())
	SignalBus.lesson_unlocked.connect(func(_id): play_notify())
	SignalBus.campaign_level_unlocked.connect(func(_n): play_notify())
	SignalBus.lesson_completed.connect(func(_id): play_success())
	SignalBus.scene_change_requested.connect(func(_p): play_transition())
	SignalBus.tower_placed.connect(func(_id, _pos): play_collect())

func _generate_all_sounds() -> void:
	hover_sound = _generate_sine_sweep(700.0, 1100.0, 0.05, 0.06)
	click_sound = _generate_sine_sweep(400.0, 320.0, 0.08, 0.18)
	tick_sound = _generate_noise_tick(0.006, 0.08)
	success_sound = _generate_chord([523.0, 659.0, 784.0], 0.35, 0.15)
	error_sound = _generate_sine_sweep(200.0, 100.0, 0.25, 0.12)
	notify_sound = _generate_sine_sweep(880.0, 1320.0, 0.12, 0.10)
	transition_sound = _generate_sine_sweep(200.0, 600.0, 0.30, 0.08)
	collect_sound = _generate_arpeggio([440.0, 554.0, 659.0, 880.0], 0.06, 0.10)
	wave_alert_sound = _generate_sine_sweep(300.0, 900.0, 0.18, 0.12)
	level_complete_sound = _generate_arpeggio([523.0, 659.0, 784.0, 1047.0], 0.12, 0.15)
	game_over_sound = _generate_sine_sweep(300.0, 60.0, 0.60, 0.12)

func _generate_sine_sweep(start_freq: float, end_freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	
	var num_samples = int(stream.mix_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples)
	
	for i in range(num_samples):
		var t = float(i) / stream.mix_rate
		var freq = start_freq + (end_freq - start_freq) * (t / duration)
		var phase = 2.0 * PI * freq * t
		var sample = sin(phase)
		var envelope = 1.0 - (float(i) / num_samples)
		var val = int(clamp((sample * envelope * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
		
	stream.data = bytes
	return stream

func _generate_noise_tick(duration: float, volume: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	
	var num_samples = int(stream.mix_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples)
	
	for i in range(num_samples):
		var noise = randf() * 2.0 - 1.0
		var envelope = pow(1.0 - (float(i) / num_samples), 2.0)
		var val = int(clamp((noise * envelope * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
		
	stream.data = bytes
	return stream

func _generate_chord(freqs: Array, duration: float, volume: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	
	var num_samples = int(stream.mix_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples)
	
	for i in range(num_samples):
		var t = float(i) / stream.mix_rate
		var sample = 0.0
		for f in freqs:
			sample += sin(2.0 * PI * f * t)
		sample /= freqs.size()
		var envelope = 1.0 - (float(i) / num_samples)
		var val = int(clamp((sample * envelope * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
		
	stream.data = bytes
	return stream

func _generate_arpeggio(freqs: Array, note_duration: float, volume: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	
	var total_duration = note_duration * freqs.size()
	var num_samples = int(stream.mix_rate * total_duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples)
	
	for i in range(num_samples):
		var t = float(i) / stream.mix_rate
		var note_idx = int(t / note_duration)
		note_idx = clamp(note_idx, 0, freqs.size() - 1)
		var note_t = (t - note_idx * note_duration) / note_duration
		var envelope = 1.0 - note_t
		var sample = sin(2.0 * PI * freqs[note_idx] * t) * envelope
		var val = int(clamp((sample * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
		
	stream.data = bytes
	return stream

func set_effects_volume(val: float) -> void:
	effects_volume = clamp(val, 0.0, 1.0)

func get_effects_volume() -> float:
	return effects_volume

func play_hover() -> void:
	_play(hover_sound, -12.0)

func play_click() -> void:
	_play(click_sound, -6.0)

func play_tick() -> void:
	_play(tick_sound, -15.0)

func play_success() -> void:
	_play(success_sound, -8.0)

func play_error() -> void:
	_play(error_sound, -8.0)

func play_notify() -> void:
	_play(notify_sound, -10.0)

func play_transition() -> void:
	_play(transition_sound, -10.0)

func play_collect() -> void:
	_play(collect_sound, -8.0)

func play_wave_alert() -> void:
	_play(wave_alert_sound, -8.0)

func play_level_complete() -> void:
	_play(level_complete_sound, -8.0)

func play_game_over() -> void:
	_play(game_over_sound, -8.0)

func _play(stream: AudioStreamWAV, vol_db: float) -> void:
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	var vol_scale = linear_to_db(effects_volume) if effects_volume > 0.0 else -80.0
	player.volume_db = vol_db + vol_scale
	player.play()
	player.finished.connect(player.queue_free)
