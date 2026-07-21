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
var enemy_hit_sound: AudioStreamWAV
var enemy_death_sound: AudioStreamWAV
var enemy_reach_base_sound: AudioStreamWAV
var ram_spend_sound: AudioStreamWAV
var tower_attack_sounds: Dictionary = {}

var effects_volume: float = 0.2
var music_volume: float = 0.2

var _music_player: AudioStreamPlayer
var _current_music_level: int = -1

# Root frequencies for keys (C4=261.63, each step * 2^(1/12))
const _ROOT_FREQS: Dictionary = {
	1: 261.63, 2: 293.66, 3: 329.63, 4: 349.23, 5: 392.00,
	6: 440.00, 7: 493.88, 8: 523.25, 9: 587.33, 10: 659.25,
	11: 698.46, 12: 783.99
}

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	add_child(_music_player)
	_music_player.bus = "Master"
	_generate_all_sounds()
	_connect_signals()

func _connect_signals() -> void:
	SignalBus.wave_started.connect(func(_n): play_wave_alert())
	SignalBus.level_complete.connect(func(_a, _b, _c): play_level_complete())
	SignalBus.tower_unlocked.connect(func(_id): play_notify())
	SignalBus.lesson_unlocked.connect(func(_id): play_notify())
	SignalBus.campaign_level_unlocked.connect(func(_n): play_notify())
	SignalBus.lesson_completed.connect(func(_id): play_success())
	SignalBus.tower_placed.connect(func(_id, _pos): play_collect())
	SignalBus.enemy_reached_end.connect(func(_id): play_enemy_reach_base())

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
	enemy_hit_sound = _generate_noise_tick(0.04, 0.08)
	enemy_death_sound = _generate_sine_sweep(200.0, 50.0, 0.20, 0.10)
	enemy_reach_base_sound = _generate_sine_sweep(150.0, 80.0, 0.30, 0.12)
	ram_spend_sound = _generate_sine_sweep(1000.0, 500.0, 0.08, 0.10)
	_generate_tower_attack_sounds()

func _generate_tower_attack_sounds() -> void:
	tower_attack_sounds["tower_array"] = _generate_noise_tick(0.03, 0.06)
	tower_attack_sounds["tower_stack"] = _generate_sine_sweep(150.0, 80.0, 0.15, 0.10)
	tower_attack_sounds["tower_queue"] = _generate_sine_sweep(1200.0, 400.0, 0.06, 0.08)
	tower_attack_sounds["tower_linked_list"] = _generate_noise_tick(0.05, 0.08)
	tower_attack_sounds["tower_bubble"] = _generate_sine_sweep(600.0, 900.0, 0.05, 0.08)
	tower_attack_sounds["tower_selection"] = _generate_sine_sweep(500.0, 800.0, 0.10, 0.08)
	tower_attack_sounds["tower_insertion"] = _generate_sine_sweep(300.0, 100.0, 0.08, 0.10)
	tower_attack_sounds["tower_quick"] = _generate_sine_sweep(900.0, 600.0, 0.06, 0.08)
	tower_attack_sounds["tower_merge"] = _generate_sine_sweep(400.0, 700.0, 0.12, 0.06)
	tower_attack_sounds["tower_counting"] = _generate_noise_tick(0.02, 0.05)
	tower_attack_sounds["tower_radix"] = _generate_sine_sweep(800.0, 1200.0, 0.07, 0.08)
	tower_attack_sounds["tower_linear"] = _generate_sine_sweep(300.0, 1000.0, 0.10, 0.07)
	tower_attack_sounds["tower_binary"] = _generate_sine_sweep(2000.0, 500.0, 0.04, 0.10)

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

func set_music_volume(val: float) -> void:
	music_volume = clamp(val, 0.0, 1.0)
	if _music_player and _music_player.stream:
		var vol_scale = linear_to_db(music_volume) if music_volume > 0.0 else -80.0
		_music_player.volume_db = -16.0 + vol_scale

func get_music_volume() -> float:
	return music_volume

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

func play_enemy_hit() -> void:
	_play(enemy_hit_sound, -10.0)

func play_enemy_death() -> void:
	_play(enemy_death_sound, -8.0)

func play_enemy_reach_base() -> void:
	_play(enemy_reach_base_sound, -8.0)

func play_tower_attack(tower_id: String) -> void:
	var s = tower_attack_sounds.get(tower_id)
	if s:
		_play(s, -8.0)

func play_ram_spend() -> void:
	_play(ram_spend_sound, -8.0)

func play_level_music(level: int) -> void:
	if level == _current_music_level and _music_player.playing:
		return
	_current_music_level = level
	var track = _generate_music_track(level)
	if track:
		_music_player.stop()
		_music_player.stream = track
		_music_player.volume_db = -16.0
		var vol_scale = linear_to_db(music_volume) if music_volume > 0.0 else -80.0
		_music_player.volume_db += vol_scale
		_music_player.play()

func stop_music() -> void:
	_music_player.stop()
	_current_music_level = -1

func _generate_music_track(level: int) -> AudioStreamWAV:
	var key_idx = ((level - 1) % 12) + 1
	var root = _ROOT_FREQS[key_idx]
	var is_major = level % 2 == 1
	var bpm = 90.0
	var beats_per_loop = 8
	var loop_duration = beats_per_loop * (60.0 / bpm)
	var mix_rate = 22050
	var num_samples = int(mix_rate * loop_duration)

	var stream = AudioStreamWAV.new()
	stream.mix_rate = mix_rate
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = num_samples

	var bytes = PackedByteArray()
	bytes.resize(num_samples)

	var major_third = pow(2.0, 4.0 / 12.0)
	var minor_third = pow(2.0, 3.0 / 12.0)
	var fifth = pow(2.0, 7.0 / 12.0)
	var chord = [root]
	if is_major:
		chord.append(root * major_third)
		chord.append(root * fifth)
	else:
		chord.append(root * minor_third)
		chord.append(root * fifth)

	var amp_scale = 0.25

	for i in range(num_samples):
		var t = float(i) / mix_rate
		var beat = t * bpm / 60.0
		var sample = 0.0

		# Bass drone (root, 2 octaves down, very soft)
		var bass_pulse = 0.5 + 0.5 * sin(beat * PI / beats_per_loop)
		sample += sin(2.0 * PI * root * 0.25 * t) * bass_pulse * 0.20

		# Chord pad (soft, gentle fade)
		var pad_phase = fmod(t, loop_duration) / loop_duration
		var pad_env = 0.3 + 0.7 * sin(pad_phase * PI * 0.5)
		for f in chord:
			sample += sin(2.0 * PI * f * t * 0.5) * pad_env * 0.06

		sample *= amp_scale
		sample = clamp(sample, -1.0, 1.0)
		var val = int((sample * 0.5 + 0.5) * 255.0)
		bytes[i] = clamp(val, 0, 255)

	stream.data = bytes
	return stream

func _play(stream: AudioStreamWAV, vol_db: float) -> void:
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	var vol_scale = linear_to_db(effects_volume) if effects_volume > 0.0 else -80.0
	player.volume_db = vol_db + vol_scale
	player.play()
	player.finished.connect(player.queue_free)
