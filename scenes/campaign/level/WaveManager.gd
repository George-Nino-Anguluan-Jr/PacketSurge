# WaveManager.gd
# Manages enemy waves for a level
extends Node

signal wave_started(wave_number: int, total_waves: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()
signal enemy_spawned(enemy: Node)

var current_wave: int    = 0
var total_waves: int     = 3
var enemies_alive: int   = 0
var wave_in_progress: bool = false
var level_completed: bool  = false

# Enemy scene to spawn
var enemy_scene: PackedScene = null
var enemy_layer: Node2D      = null
var path_waypoints: Array[Vector2] = []
var difficulty_modifier: float = 1.0

func initialize(
		waves: int,
		e_scene: PackedScene,
		e_layer: Node2D,
		waypoints: Array[Vector2],
		modifier: float) -> void:
	total_waves         = waves
	enemy_scene         = e_scene
	enemy_layer         = e_layer
	path_waypoints      = waypoints
	difficulty_modifier = modifier
	current_wave        = 0

func start_next_wave() -> void:
	if wave_in_progress or level_completed:
		return
	if current_wave >= total_waves:
		return
	current_wave      += 1
	wave_in_progress   = true
	wave_started.emit(current_wave, total_waves)
	SignalBus.wave_started.emit(current_wave)
	print("[WaveManager] Starting wave: ", current_wave)
	_spawn_wave(current_wave)

func _spawn_wave(wave_num: int) -> void:
	var enemy_count = 3 + (wave_num * 2)
	var spawn_delay = 0.8 / difficulty_modifier
	enemies_alive   = 0

	for i in range(enemy_count):
		await get_tree().create_timer(
			spawn_delay * i
		).timeout
		_spawn_enemy(wave_num)

func _spawn_enemy(wave_num: int) -> void:
	if enemy_scene == null or enemy_layer == null:
		return
	var enemy = enemy_scene.instantiate()
	enemy_layer.add_child(enemy)

	# Set enemy properties
	if enemy.has_method("initialize"):
		var health = 100.0 * difficulty_modifier * (1.0 + wave_num * 0.3)
		var speed  = 80.0  * difficulty_modifier
		enemy.initialize(path_waypoints, health, speed)

	enemy.connect("enemy_defeated",  _on_enemy_defeated)
	enemy.connect("enemy_reached_end", _on_enemy_reached_end)
	enemies_alive += 1
	enemy_spawned.emit(enemy)

func _on_enemy_defeated(enemy: Node) -> void:
	enemies_alive -= 1
	_check_wave_complete()

func _on_enemy_reached_end(enemy: Node) -> void:
	enemies_alive -= 1
	_check_wave_complete()

func _check_wave_complete() -> void:
	if enemies_alive <= 0 and wave_in_progress:
		wave_in_progress = false
		wave_completed.emit(current_wave)
		SignalBus.wave_completed.emit(current_wave)
		print("[WaveManager] Wave complete: ", current_wave)

		if current_wave >= total_waves:
			level_completed = true
			all_waves_completed.emit()
