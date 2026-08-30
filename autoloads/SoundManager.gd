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

const MUSIC_TRACKS: Array[String] = [
	"res://assets/music/lvl_0_the_tutorial.mp3",
	"res://assets/music/lvl_1_the_royal_palace.mp3",
	"res://assets/music/lvl_2_the_village.mp3",
	"res://assets/music/lvl_3_the_grassland.mp3",
	"res://assets/music/lvl_4_the_desert.mp3",
	"res://assets/music/lvl_5_the_oasis_or_resting_place.mp3",
	"res://assets/music/lvl_6_the_beach.mp3",
	"res://assets/music/lvl_7_the_raft_on_the_ocean.mp3",
	"res://assets/music/lvl_8_the_volcanic_sea_shore.mp3",
	"res://assets/music/lvl_9_the_volcanic_ascent.mp3",
]

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

var _default_attack_sound: AudioStreamWAV

func _generate_tower_attack_sounds() -> void:
	_default_attack_sound = _generate_noise_tick(0.04, 0.08)

	var profiles: Dictionary = {
		"tower_array": {"start": 180.0, "end": 980.0, "duration": 0.065, "volume": 0.14, "mod": 20.0, "noise": 0.07, "harmonics": 2, "pulse": 4},
		"tower_stack": {"start": 160.0, "end": 60.0, "duration": 0.18, "volume": 0.13, "mod": 10.0, "noise": 0.04, "harmonics": 1, "pulse": 1},
		"tower_queue": {"start": 900.0, "end": 260.0, "duration": 0.08, "volume": 0.12, "mod": 40.0, "noise": 0.03, "harmonics": 3, "pulse": 2},
		"tower_linked_list": {"start": 240.0, "end": 760.0, "duration": 0.11, "volume": 0.12, "mod": 22.0, "noise": 0.10, "harmonics": 2, "pulse": 3},
		"tower_bubble": {"start": 420.0, "end": 960.0, "duration": 0.07, "volume": 0.13, "mod": 28.0, "noise": 0.05, "harmonics": 3, "pulse": 5},
		"tower_selection": {"start": 520.0, "end": 1420.0, "duration": 0.10, "volume": 0.12, "mod": 18.0, "noise": 0.04, "harmonics": 2, "pulse": 2},
		"tower_insertion": {"start": 300.0, "end": 100.0, "duration": 0.12, "volume": 0.14, "mod": 16.0, "noise": 0.06, "harmonics": 2, "pulse": 1},
		"tower_quick": {"start": 1100.0, "end": 1800.0, "duration": 0.05, "volume": 0.12, "mod": 80.0, "noise": 0.02, "harmonics": 3, "pulse": 6},
		"tower_merge": {"start": 290.0, "end": 820.0, "duration": 0.13, "volume": 0.15, "mod": 18.0, "noise": 0.08, "harmonics": 4, "pulse": 2},
		"tower_counting": {"start": 760.0, "end": 1200.0, "duration": 0.08, "volume": 0.11, "mod": 30.0, "noise": 0.12, "harmonics": 2, "pulse": 5},
		"tower_radix": {"start": 680.0, "end": 1750.0, "duration": 0.09, "volume": 0.13, "mod": 24.0, "noise": 0.03, "harmonics": 3, "pulse": 3},
		"tower_linear": {"start": 280.0, "end": 1180.0, "duration": 0.10, "volume": 0.14, "mod": 22.0, "noise": 0.05, "harmonics": 2, "pulse": 4},
		"tower_binary": {"start": 2100.0, "end": 360.0, "duration": 0.07, "volume": 0.14, "mod": 65.0, "noise": 0.04, "harmonics": 4, "pulse": 3},
	}

	for tower_id in DataRegistry.get_tower_ids_ordered():
		if profiles.has(tower_id):
			tower_attack_sounds[tower_id] = _generate_custom_tower_sound(profiles[tower_id])
		else:
			tower_attack_sounds[tower_id] = _default_attack_sound

func _generate_custom_tower_sound(profile: Dictionary) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false

	var duration: float = profile.get("duration", 0.08)
	var num_samples = int(stream.mix_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples)

	var start_freq: float = profile.get("start", 440.0)
	var end_freq: float = profile.get("end", 880.0)
	var volume: float = profile.get("volume", 0.12)
	var mod_depth: float = profile.get("mod", 0.0)
	var noise_level: float = profile.get("noise", 0.0)
	var harmonics: int = int(profile.get("harmonics", 1))
	var pulse_count: float = profile.get("pulse", 1.0)

	for i in range(num_samples):
		var t = float(i) / stream.mix_rate
		var sweep = clamp(t / duration, 0.0, 1.0)
		var freq = start_freq + (end_freq - start_freq) * sweep
		var flutter = sin(2.0 * PI * 12.0 * t) * mod_depth
		var sample = 0.0
		for h in range(1, harmonics + 1):
			var harm_amp = 1.0 / float(h)
			var phase = 2.0 * PI * freq * float(h) * t + flutter * float(h) * 0.25
			sample += sin(phase) * harm_amp
		if noise_level > 0.0:
			sample += (randf() * 2.0 - 1.0) * noise_level * (1.0 - sweep)
		if pulse_count > 1.0:
			sample *= 0.45 + maxf(0.0, sin(2.0 * PI * pulse_count * t)) * 0.55
		var envelope = 1.0 - sweep
		envelope = clamp(envelope, 0.0, 1.0)
		var val = int(clamp((sample * envelope * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val

	stream.data = bytes
	return stream

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
	var s = tower_attack_sounds.get(tower_id, _default_attack_sound)
	if s:
		_play(s, -8.0)

func play_ram_spend() -> void:
	_play(ram_spend_sound, -8.0)

func play_level_music(level: int) -> void:
	if level == _current_music_level and _music_player.playing:
		return
	var idx = (level - 1) % MUSIC_TRACKS.size()
	var path = MUSIC_TRACKS[idx]
	_current_music_level = level
	var stream = _load_music(path)
	if not stream:
		return
	_music_player.stop()
	_music_player.stream = stream
	_music_player.volume_db = -16.0
	var vol_scale = linear_to_db(music_volume) if music_volume > 0.0 else -80.0
	_music_player.volume_db += vol_scale
	_music_player.play()

func _load_music(path: String) -> AudioStreamMP3:
	var stream = ResourceLoader.load(path)
	if not stream or not stream is AudioStreamMP3:
		return null
	stream.loop = true
	stream.loop_offset = 0.0
	return stream

func stop_music() -> void:
	_music_player.stop()
	_current_music_level = -1

func _play(stream: AudioStreamWAV, vol_db: float) -> void:
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	var vol_scale = linear_to_db(effects_volume) if effects_volume > 0.0 else -80.0
	player.volume_db = vol_db + vol_scale
	player.play()
	player.finished.connect(player.queue_free)
