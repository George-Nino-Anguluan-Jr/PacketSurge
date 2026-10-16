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
var enemy_death_sound: AudioStreamWAV
var enemy_reach_base_sound: AudioStreamWAV
var ram_spend_sound: AudioStreamWAV
var upgrade_sound: AudioStreamWAV
var sell_sound: AudioStreamWAV
var low_ram_sound: AudioStreamWAV
var lesson_start_sound: AudioStreamWAV
var topic_mastered_sound: AudioStreamWAV
var wave_complete_sound: AudioStreamWAV
var enemy_spawn_sound: AudioStreamWAV
var tower_attack_sounds: Dictionary = {}

var effects_volume: float = 1.0
var music_volume: float = 1.0

var _music_player: AudioStreamPlayer
var _current_music_level: int = -1

# ─── SCENE MUSIC ─────────────────────────────────────────
const MENU_MUSIC_PATH: String       = "res://assets/music/menu_music.wav"
const LEVEL_SELECT_MUSIC_PATH: String = "res://assets/music/level_select.ogg"
const ACADEMY_MUSIC_PATH: String    = "res://assets/music/academy_music.wav"

# Gameplay music folder — random track chosen per level from here.
# Populate this folder with your DavidKDB synthwave tracks.
const GAMEPLAY_MUSIC_DIR: String    = "res://assets/music/gameplay"
var _gameplay_tracks: Array[String] = []
var _current_music_scene: String    = ""
var _current_music_path: String     = ""

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	add_child(_music_player)
	_music_player.bus = "Master"
	_generate_all_sounds()
	_connect_signals()
	_scan_gameplay_music()
	_music_player.finished.connect(func(): _music_player.play())

func _scan_gameplay_music() -> void:
	_gameplay_tracks.clear()
	var dir = DirAccess.open(GAMEPLAY_MUSIC_DIR)
	if not dir:
		push_warning("SoundManager: gameplay music dir not found: " + GAMEPLAY_MUSIC_DIR)
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if not dir.current_is_dir() and (f.ends_with(".mp3") or f.ends_with(".ogg") or f.ends_with(".wav")):
			_gameplay_tracks.append(GAMEPLAY_MUSIC_DIR.path_join(f))
		f = dir.get_next()
	if _gameplay_tracks.is_empty():
		push_warning("SoundManager: no gameplay music tracks found in " + GAMEPLAY_MUSIC_DIR)

func _connect_signals() -> void:
	SignalBus.wave_started.connect(func(_n): play_wave_alert())
	SignalBus.level_complete.connect(func(_a, _b, _c): play_level_complete())
	SignalBus.tower_unlocked.connect(func(_id): play_notify())
	SignalBus.lesson_unlocked.connect(func(_id): play_notify())
	SignalBus.campaign_level_unlocked.connect(func(_n): play_notify())
	SignalBus.lesson_completed.connect(func(_id): play_success())
	SignalBus.tower_placed.connect(func(_id, _pos): play_collect())
	SignalBus.enemy_reached_end.connect(func(_id): play_enemy_reach_base())
	SignalBus.tower_sold.connect(func(_id): play_tower_sell())
	SignalBus.tower_upgraded.connect(func(_id, _lvl): play_tower_upgrade())
	SignalBus.low_ram.connect(func(_cur, _max): play_low_ram())
	SignalBus.wave_completed.connect(func(_n): play_wave_complete())
	SignalBus.lesson_started.connect(func(_id): play_lesson_start())
	SignalBus.topic_mastered.connect(func(_id): play_topic_mastered())
	SignalBus.main_level_completed.connect(func(_lvl): play_level_complete())
	SignalBus.scene_change_requested.connect(func(_path): play_transition())

func _generate_all_sounds() -> void:
	# ── UI (digital blips) ─────────────────────────
	hover_sound = _generate_digital_blip(500.0, 0.05, 0.08)      # Soft digital hover
	click_sound = _generate_digital_tap(0.03, 0.12)              # Clean digital tap (no noise burst)
	tick_sound  = _generate_digital_tick(0.010, 0.07)            # Tiny tech tick
	
	# ── Feedback (correct / wrong) ─────────────────
	success_sound = _generate_digital_arpeggio([523.0, 659.0, 784.0, 1047.0], 0.09, 0.17)  # Ascending "correct"
	error_sound   = _generate_digital_buzz(100.0, 0.26, 0.12)     # Low digital error
	notify_sound  = _generate_digital_chime(880.0, 1175.0, 0.11, 0.10)  # Soft notification ping
	
	# ── Gameplay (network / packet theme) ──────────
	transition_sound     = _generate_digital_sweep(180.0, 700.0, 0.20, 0.06)
	collect_sound        = _generate_digital_arpeggio([600.0, 800.0, 1000.0, 1200.0], 0.05, 0.12)  # Packet collect
	wave_alert_sound     = _generate_digital_wave_start(0.45, 0.11)   # Packet transmission alert
	level_complete_sound = _generate_digital_fanfare([523.0, 659.0, 784.0, 1047.0, 1318.0], 0.11, 0.18)  # Level cleared
	game_over_sound      = _generate_digital_powerdown([523.0, 440.0, 349.0, 293.0, 261.0, 220.0], 0.16, 0.14)  # System down
	enemy_death_sound    = _generate_digital_explosion(0.20, 0.14)          # Packet deleted
	enemy_reach_base_sound = _generate_digital_alarm(160.0, 0.35, 0.13)     # Base breach
	ram_spend_sound      = _generate_digital_cash(0.08, 0.11)               # RAM spend
	upgrade_sound        = _generate_digital_upgrade(0.25, 0.14)            # Tower upgraded
	sell_sound           = _generate_digital_sell(0.20, 0.12)               # Tower sold
	low_ram_sound        = _generate_digital_buzz(60.0, 0.35, 0.15)         # Low RAM warning
	lesson_start_sound   = _generate_digital_chime(700.0, 1000.0, 0.10, 0.12)  # Lesson start
	topic_mastered_sound = _generate_digital_fanfare([523.0, 659.0, 784.0], 0.12, 0.16)  # Topic mastered
	wave_complete_sound  = _generate_digital_chime(600.0, 900.0, 0.10, 0.12)    # Wave completed
	enemy_spawn_sound    = _generate_digital_spawn(0.15, 0.10)                  # Enemy spawns
	
	_generate_tower_attack_sounds()

var _default_attack_sound: AudioStreamWAV

func _generate_tower_attack_sounds() -> void:
	_default_attack_sound = _generate_digital_tick(0.04, 0.08)

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

# ── DIGITAL SFX GENERATORS (cyberpunk / network theme) ──────────────────────

func _generate_digital_blip(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	var num_samples = int(stream.mix_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / stream.mix_rate
		var env = exp(-t * 22.0)
		var sample = sin(2.0 * PI * freq * t) * env
		sample += sin(2.0 * PI * freq * 3.0 * t) * env * 0.15
		var val = int(clamp((sample * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
	stream.data = bytes
	return stream

func _generate_digital_click(duration: float, volume: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	var num_samples = int(stream.mix_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / stream.mix_rate
		var env = exp(-t * 50.0)
		var noise = (randf() * 2.0 - 1.0) * env * 0.5
		var tone = sin(2.0 * PI * 1100.0 * t) * env * 0.25
		var sample = noise + tone
		var val = int(clamp((sample * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
	stream.data = bytes
	return stream

func _generate_digital_tap(duration: float, volume: float) -> AudioStreamWAV:
	# Clean digital tap — short sine pop with fast decay, no noise
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	var num_samples = int(stream.mix_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / stream.mix_rate
		var env = exp(-t * 60.0)
		var sample = sin(2.0 * PI * 800.0 * t) * env * 0.8
		sample += sin(2.0 * PI * 1600.0 * t) * env * 0.2
		var val = int(clamp((sample * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
	stream.data = bytes
	return stream

func _generate_digital_tick(duration: float, volume: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	var num_samples = int(stream.mix_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / stream.mix_rate
		var env = exp(-t * 80.0)
		var sample = sin(2.0 * PI * 1500.0 * t) * env * 0.6
		var val = int(clamp((sample * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
	stream.data = bytes
	return stream

func _generate_digital_buzz(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	var num_samples = int(stream.mix_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / stream.mix_rate
		var env = 0.9 - (float(i) / num_samples) * 0.3
		var vib = sin(2.0 * PI * 5.0 * t) * 8.0
		var sample = sin(2.0 * PI * (freq + vib) * t) * env
		sample += sin(2.0 * PI * freq * 2.0 * t) * env * 0.35
		var val = int(clamp((sample * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
	stream.data = bytes
	return stream

func _generate_digital_chime(freq1: float, freq2: float, duration: float, volume: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	var num_samples = int(stream.mix_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / stream.mix_rate
		var env = exp(-t * 10.0)
		var sample = (sin(2.0 * PI * freq1 * t) + sin(2.0 * PI * freq2 * t)) * 0.5 * env
		var val = int(clamp((sample * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
	stream.data = bytes
	return stream

func _generate_digital_sweep(start_freq: float, end_freq: float, duration: float, volume: float) -> AudioStreamWAV:
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
		var sample = sin(phase) * 0.7
		sample += sin(2.0 * PI * freq * 2.0 * t) * 0.2
		var envelope = 1.0 - (float(i) / num_samples) * 0.5
		var val = int(clamp((sample * envelope * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
	stream.data = bytes
	return stream

func _generate_digital_arpeggio(freqs: Array, note_duration: float, volume: float) -> AudioStreamWAV:
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
		var envelope = 1.0 - note_t * 0.4
		var sample = sin(2.0 * PI * freqs[note_idx] * t) * envelope
		sample += sin(2.0 * PI * freqs[note_idx] * 2.0 * t) * envelope * 0.2
		var val = int(clamp((sample * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
	stream.data = bytes
	return stream

func _generate_digital_wave_start(duration: float, volume: float) -> AudioStreamWAV:
	# Packet transmission alert — quick rising digital tone, not a siren
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	var num_samples = int(stream.mix_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / stream.mix_rate
		var progress = t / duration
		var freq = lerp(400.0, 900.0, progress)
		var env = 0.85
		var sample = sin(2.0 * PI * freq * t) * env
		sample += sin(2.0 * PI * freq * 2.0 * t) * env * 0.15
		var val = int(clamp((sample * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
	stream.data = bytes
	return stream

func _generate_digital_siren(low: float, high: float, duration: float, volume: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	var num_samples = int(stream.mix_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples)
	var cycle := 0.0
	for i in range(num_samples):
		var t = float(i) / stream.mix_rate
		cycle += 0.018
		if cycle > 1.0:
			cycle = 0.0
		var f = lerp(low, high, cycle)
		var env = 0.8 + 0.2 * sin(2.0 * PI * 5.0 * t)
		var sample = sin(2.0 * PI * f * t) * env
		var val = int(clamp((sample * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
	stream.data = bytes
	return stream

func _generate_digital_fanfare(freqs: Array, note_duration: float, volume: float) -> AudioStreamWAV:
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
		var envelope = 1.0 - note_t * 0.3
		var sample = sin(2.0 * PI * freqs[note_idx] * t) * envelope
		sample += sin(2.0 * PI * freqs[note_idx] * 2.0 * t) * envelope * 0.3
		var val = int(clamp((sample * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
	stream.data = bytes
	return stream

func _generate_digital_powerdown(freqs: Array, note_duration: float, volume: float) -> AudioStreamWAV:
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
		var envelope = 1.0 - note_t * 0.2
		var sample = sin(2.0 * PI * freqs[note_idx] * t) * envelope
		var val = int(clamp((sample * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
	stream.data = bytes
	return stream

func _generate_digital_explosion(duration: float, volume: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	var num_samples = int(stream.mix_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / stream.mix_rate
		var env = exp(-t * 9.0)
		var noise = (randf() * 2.0 - 1.0) * env * 0.85
		var low = sin(2.0 * PI * 45.0 * t) * env * 0.35
		var sample = noise + low
		var val = int(clamp((sample * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
	stream.data = bytes
	return stream

func _generate_digital_alarm(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	var num_samples = int(stream.mix_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / stream.mix_rate
		var beep = sin(2.0 * PI * 4.5 * t) > 0
		var env = 0.88 if beep else 0.08
		var sample = sin(2.0 * PI * freq * t) * env
		var val = int(clamp((sample * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
	stream.data = bytes
	return stream

func _generate_digital_cash(duration: float, volume: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	var num_samples = int(stream.mix_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples)
	var notes := [600.0, 800.0, 1000.0, 1200.0]
	var note_dur = duration / notes.size()
	for i in range(num_samples):
		var t = float(i) / stream.mix_rate
		var note_idx = int(t / note_dur)
		if note_idx >= notes.size():
			note_idx = notes.size() - 1
		var note_t = t - note_idx * note_dur
		var env = exp(-note_t * 28.0)
		var sample = sin(2.0 * PI * notes[note_idx] * t) * env
		var val = int(clamp((sample * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
	stream.data = bytes
	return stream

func _generate_digital_upgrade(duration: float, volume: float) -> AudioStreamWAV:
	# Tower upgraded — ascending digital notes
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	var num_samples = int(stream.mix_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples)
	var notes := [500.0, 700.0, 900.0, 1100.0]
	var note_dur = duration / notes.size()
	for i in range(num_samples):
		var t = float(i) / stream.mix_rate
		var note_idx = int(t / note_dur)
		if note_idx >= notes.size():
			note_idx = notes.size() - 1
		var note_t = t - note_idx * note_dur
		var env = exp(-note_t * 20.0)
		var sample = sin(2.0 * PI * notes[note_idx] * t) * env
		var val = int(clamp((sample * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
	stream.data = bytes
	return stream

func _generate_digital_sell(duration: float, volume: float) -> AudioStreamWAV:
	# Tower sold — descending digital notes
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	var num_samples = int(stream.mix_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples)
	var notes := [900.0, 700.0, 500.0]
	var note_dur = duration / notes.size()
	for i in range(num_samples):
		var t = float(i) / stream.mix_rate
		var note_idx = int(t / note_dur)
		if note_idx >= notes.size():
			note_idx = notes.size() - 1
		var note_t = t - note_idx * note_dur
		var env = exp(-note_t * 20.0)
		var sample = sin(2.0 * PI * notes[note_idx] * t) * env
		var val = int(clamp((sample * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
	stream.data = bytes
	return stream

func _generate_digital_spawn(duration: float, volume: float) -> AudioStreamWAV:
	# Enemy spawns — quick digital packet materialize sound
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	var num_samples = int(stream.mix_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / stream.mix_rate
		var env = exp(-t * 30.0)
		var freq = 400.0 + sin(2.0 * PI * t * 10.0) * 50.0
		var sample = sin(2.0 * PI * freq * t) * env * 0.7
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
		_music_player.volume_db = -8.0 + vol_scale

func get_music_volume() -> float:
	return music_volume

func play_hover() -> void:
	_play(hover_sound, -12.0)

func play_click() -> void:
	_play(click_sound, -10.0)

func play_tick() -> void:
	_play(tick_sound, -15.0)

func play_success() -> void:
	_play(success_sound, -10.0)

func play_error() -> void:
	_play(error_sound, -10.0)

func play_notify() -> void:
	_play(notify_sound, -10.0)

func play_transition() -> void:
	_play(transition_sound, -10.0)

func play_collect() -> void:
	_play(collect_sound, -10.0)

func play_wave_alert() -> void:
	_play(wave_alert_sound, -10.0)

func play_level_complete() -> void:
	_play(level_complete_sound, -10.0)

func play_game_over() -> void:
	_play(game_over_sound, -10.0)

func play_enemy_death() -> void:
	_play(enemy_death_sound, -10.0)

func play_enemy_reach_base() -> void:
	_play(enemy_reach_base_sound, -10.0)

func play_tower_attack(tower_id: String) -> void:
	var s = tower_attack_sounds.get(tower_id, _default_attack_sound)
	if s:
		_play(s, -10.0)

func play_ram_spend() -> void:
	_play(ram_spend_sound, -10.0)

func play_tower_upgrade() -> void:
	_play(upgrade_sound, -10.0)

func play_tower_sell() -> void:
	_play(sell_sound, -10.0)

func play_low_ram() -> void:
	_play(low_ram_sound, -10.0)

func play_lesson_start() -> void:
	_play(lesson_start_sound, -10.0)

func play_topic_mastered() -> void:
	_play(topic_mastered_sound, -10.0)

func play_wave_complete() -> void:
	_play(wave_complete_sound, -10.0)

func play_enemy_spawn() -> void:
	_play(enemy_spawn_sound, -14.0)

func play_menu_music() -> void:
	_play_music_file(MENU_MUSIC_PATH, "menu")

func play_level_select_music() -> void:
	_play_music_file(LEVEL_SELECT_MUSIC_PATH, "level_select", -4.0)

func play_academy_music() -> void:
	_play_music_file(ACADEMY_MUSIC_PATH, "academy")

func play_gameplay_music() -> void:
	if _gameplay_tracks.is_empty():
		return
	var idx = randi() % _gameplay_tracks.size()
	_play_music_file(_gameplay_tracks[idx], "gameplay")

func play_level_music(level: int) -> void:
	# Deprecated — use play_gameplay_music() for random per-level track.
	play_gameplay_music()

func _play_music_file(path: String, scene_label: String, volume_db: float = -8.0) -> void:
	if _current_music_scene == scene_label and _music_player.playing:
		return
	var stream = _load_music(path)
	if not stream:
		push_warning("SoundManager: could not load music: ", path)
		return
	_current_music_scene = scene_label
	_current_music_path = path
	_music_player.stop()
	_music_player.stream = stream
	_music_player.volume_db = volume_db
	var vol_scale = linear_to_db(music_volume) if music_volume > 0.0 else -80.0
	_music_player.volume_db += vol_scale
	_music_player.play()

func _load_music(path: String) -> AudioStream:
	var stream = ResourceLoader.load(path)
	if not stream or not (stream is AudioStream):
		return null
	return stream

func stop_music() -> void:
	_music_player.stop()
	_current_music_scene = ""
	_current_music_path = ""

func _play(stream: AudioStreamWAV, vol_db: float) -> void:
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	var vol_scale = linear_to_db(effects_volume) if effects_volume > 0.0 else -80.0
	player.volume_db = vol_db + vol_scale
	player.play()
	player.finished.connect(player.queue_free)
