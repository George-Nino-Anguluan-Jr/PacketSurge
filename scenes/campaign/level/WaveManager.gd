# WaveManager.gd
extends Node

signal wave_started(wave_number: int, total_waves: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()
signal enemy_spawned(enemy: Node)

var current_wave: int      = 0
var total_waves: int       = 3
var enemies_alive: int     = 0
var wave_in_progress: bool = false
var level_completed: bool  = false

var enemy_scene: PackedScene        = null
var enemy_layer: Node2D             = null
var path_waypoints: Array[Vector2]  = []
var difficulty_modifier: float      = 1.0
var enemy_pool: Array          = []

var _spawn_index: int = 0

func initialize(
		waves: int,
		e_scene: PackedScene,
		e_layer: Node2D,
		waypoints: Array[Vector2],
		modifier: float,
		pool: Array = []) -> void:
	total_waves         = waves
	enemy_scene         = e_scene
	enemy_layer         = e_layer
	path_waypoints      = waypoints
	difficulty_modifier = modifier
	enemy_pool          = pool
	current_wave        = 0
	_spawn_index        = 0

func start_next_wave() -> void:
	if wave_in_progress or level_completed:
		return
	if current_wave >= total_waves:
		return
	current_wave     += 1
	wave_in_progress  = true
	wave_started.emit(current_wave, total_waves)
	SignalBus.wave_started.emit(current_wave)
	print("[WaveManager] Starting wave: ", current_wave)
	_spawn_wave(current_wave)

func _spawn_wave(wave_num: int) -> void:
	var enemy_count = 3 + (wave_num * 2)
	var spawn_delay = 0.8 / difficulty_modifier
	enemies_alive   = 0

	for i in range(enemy_count):
		await get_tree().create_timer(spawn_delay * i).timeout
		_spawn_enemy(wave_num, i)

func _get_enemy_type(wave_num: int, index: int) -> String:
	if enemy_pool.size() == 0:
		return "basic_packet"

	# First wave is always basic
	if wave_num == 1:
		return "basic_packet"

	# Last wave special — pivot_splitter boss type
	var boss_type = "pivot_splitter"
	if wave_num == total_waves and boss_type in enemy_pool:
		if index == 0:
			return boss_type

	# Weighted selection from pool
	var weights: Array[float] = []
	var last_idx = enemy_pool.size() - 1

	for j in range(enemy_pool.size()):
		var etype = enemy_pool[j]
		if etype == "basic_packet":
			# Basic becomes less common in later waves
			weights.append(max(0.0, 0.6 - wave_num * 0.06))
		elif j == last_idx:
			# New concept enemy appears more in later waves
			weights.append(0.05 + wave_num * 0.04)
		else:
			# Mid enemies stay consistent
			weights.append(0.2)

	var total = 0.0
	for w in weights:
		total += w
	if total <= 0.0:
		return enemy_pool[0]

	var roll = randf() * total
	var cumulative = 0.0
	for j in range(enemy_pool.size()):
		cumulative += weights[j]
		if roll < cumulative:
			return enemy_pool[j]

	return enemy_pool[0]

func _spawn_enemy(wave_num: int, index: int) -> void:
	if enemy_scene == null or enemy_layer == null:
		return
	var enemy      = enemy_scene.instantiate()
	enemy_layer.add_child(enemy)

	var enemy_type = _get_enemy_type(wave_num, index)

	if enemy.has_method("initialize"):
		var health = 100.0 * difficulty_modifier * (1.0 + wave_num * 0.3)
		var speed  = 80.0 * difficulty_modifier
		enemy.initialize(path_waypoints, health, speed, enemy_type)

	# Spread enemies perpendicular to the path direction at spawn
	# so they don't stack on top of each other and get stuck
	if path_waypoints.size() >= 2:
		var spawn_dir = (path_waypoints[1] - path_waypoints[0]).normalized()
		var perp = Vector2(-spawn_dir.y, spawn_dir.x)
		var spawn_offset = (_spawn_index % 5 - 2) * 24.0
		_spawn_index += 1
		enemy.position += perp * spawn_offset

	enemy.connect("enemy_defeated",    _on_enemy_defeated)
	enemy.connect("enemy_reached_end", _on_enemy_reached_end)
	enemies_alive += 1
	enemy_spawned.emit(enemy)

	# Handle paired enemy types
	if enemy_type == "linked_drain":
		_spawn_linked_partner(enemy, wave_num)
	elif enemy_type == "merge_twin":
		_spawn_merge_twin(enemy, wave_num)

func _get_spawn_perp() -> Vector2:
	if path_waypoints.size() >= 2:
		var dir = (path_waypoints[1] - path_waypoints[0]).normalized()
		return Vector2(-dir.y, dir.x)
	return Vector2.RIGHT

func _spawn_linked_partner(enemy: Node, wave_num: int) -> void:
	var partner = enemy_scene.instantiate()
	enemy_layer.add_child(partner)

	var health = 100.0 * difficulty_modifier * (1.0 + wave_num * 0.3)
	var speed  = 80.0 * difficulty_modifier
	var part_data = {"partner": enemy}
	partner.initialize(path_waypoints, health * 0.8, speed, "linked_drain", part_data)
	enemy.type_data["partner"] = partner

	# Place partner on the path and skip waypoints[0] so it doesn't converge
	# on the same point as the enemy — prevents collision overlap
	partner.current_waypoint = 1 if path_waypoints.size() > 1 else 0

	partner.connect("enemy_defeated", _on_enemy_defeated)
	partner.connect("enemy_reached_end", _on_enemy_reached_end)
	enemies_alive += 1
	enemy_spawned.emit(partner)

func _spawn_merge_twin(enemy: Node, wave_num: int) -> void:
	var partner = enemy_scene.instantiate()
	enemy_layer.add_child(partner)

	var health = 100.0 * difficulty_modifier * (1.0 + wave_num * 0.3)
	var speed  = 80.0 * difficulty_modifier
	var part_data = {"partner": enemy}
	partner.initialize(path_waypoints, health, speed, "merge_twin", part_data)
	enemy.type_data["partner"] = partner

	# Place partner on the path and skip waypoints[0]
	partner.current_waypoint = 1 if path_waypoints.size() > 1 else 0

	partner.connect("enemy_defeated", _on_enemy_defeated)
	partner.connect("enemy_reached_end", _on_enemy_reached_end)
	enemies_alive += 1
	enemy_spawned.emit(partner)

func _on_enemy_defeated(_enemy: Node) -> void:
	enemies_alive -= 1
	_check_wave_complete()

func _on_enemy_reached_end(_enemy: Node) -> void:
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
