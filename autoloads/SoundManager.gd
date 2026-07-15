# SoundManager.gd
extends Node

var hover_sound: AudioStreamWAV
var click_sound: AudioStreamWAV
var tick_sound: AudioStreamWAV

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS # Keep playing even if paused
	# Generate our clean synth sounds on startup in memory!
	hover_sound = _generate_sine_sweep(700.0, 1100.0, 0.05, 0.06)
	click_sound = _generate_sine_sweep(400.0, 320.0, 0.08, 0.18)
	tick_sound = _generate_noise_tick(0.006, 0.08)

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
		# Linear frequency sweep
		var freq = start_freq + (end_freq - start_freq) * (t / duration)
		var phase = 2.0 * PI * freq * t
		var sample = sin(phase)
		
		# Linear envelope fade out
		var envelope = 1.0 - (float(i) / num_samples)
		# 8-bit unsigned PCM is from 0 to 255, with 128 as silence center
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
		# Fast exponential envelope fade out for crisp transient tick
		var envelope = pow(1.0 - (float(i) / num_samples), 2.0)
		var val = int(clamp((noise * envelope * volume * 127.0) + 128.0, 0.0, 255.0))
		bytes[i] = val
		
	stream.data = bytes
	return stream

func play_hover() -> void:
	_play(hover_sound, -12.0)

func play_click() -> void:
	_play(click_sound, -6.0)

func play_tick() -> void:
	_play(tick_sound, -15.0)

func _play(stream: AudioStreamWAV, vol_db: float) -> void:
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.volume_db = vol_db
	player.play()
	player.finished.connect(player.queue_free)
