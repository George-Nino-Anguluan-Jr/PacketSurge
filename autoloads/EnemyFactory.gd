# EnemyFactory.gd
# Autoload singleton. Maps enemy_type → PackedScene.
# Replaces direct preload("res://scenes/campaign/enemies/Enemy.tscn") + manual type setting.
#
# Usage:
#   var enemy = EnemyFactory.create(enemy_type, waypoints, health, speed, type_data)
#   var preview = EnemyFactory.create_preview_enemy(enemy_id, color)

extends Node

const TYPES_DIR = "res://scenes/campaign/enemies/types/"
const DEFAULT_ENEMY_SCENE = preload("res://scenes/campaign/enemies/types/EnemyBasicPacket.tscn")

var _scene_map: Dictionary = {}   # enemy_type -> PackedScene
var _initialized: bool = false

func _ready() -> void:
	_initialize_scenes()

func _initialize_scenes() -> void:
	if _initialized:
		return
	var dir = DirAccess.get_files_at(TYPES_DIR)
	for f in dir:
		if f.ends_with(".tscn"):
			var full_path = TYPES_DIR + f
			var scene = load(full_path) as PackedScene
			if scene:
				var inst = scene.instantiate()
				if inst.has_method("get_type_id"):
					var type_id = inst.get_type_id()
					_scene_map[type_id] = scene
				inst.queue_free()
	_initialized = true

func get_scene(enemy_type: String) -> PackedScene:
	if not _initialized:
		_initialize_scenes()
	return _scene_map.get(enemy_type, null)

func create(enemy_type: String, waypoints: Array[Vector2], health: float,
		speed: float, type_data: Dictionary = {}, difficulty: float = 1.0) -> Enemy:
	if not _initialized:
		_initialize_scenes()
	var scene = _scene_map.get(enemy_type, null)
	if scene == null:
		push_warning("[EnemyFactory] No scene found for enemy_type: ", enemy_type)
		# Fall back to creating base enemy with type set manually
		return null
	var enemy = scene.instantiate() as Enemy
	if enemy:
		enemy.initialize(waypoints, health, speed, enemy_type, type_data)
	return enemy

func create_preview_enemy(enemy_id: String, color: Color) -> Enemy:
	if not _initialized:
		_initialize_scenes()
	var scene = _scene_map.get(enemy_id, null)
	if scene == null:
		return null
	var e = scene.instantiate() as Enemy
	e.enemy_type = enemy_id
	e.preview_mode = true
	e.max_health = 1.0
	e.current_health = 1.0
	e.move_speed = 0.0
	e.damage_to_base = 0
	e.ram_reward = 0
	e.waypoints = [] as Array[Vector2]
	e._setup_type()
	e.enemy_color = color
	return e

func get_all_types() -> Array[String]:
	if not _initialized:
		_initialize_scenes()
	var result: Array[String] = []
	for type_id in _scene_map.keys():
		result.append(type_id)
	return result
