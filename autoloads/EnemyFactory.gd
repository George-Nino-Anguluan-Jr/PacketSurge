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

# Static manifest: enemy_type → scene path.
# DirAccess cannot enumerate packed PCK folders in exported builds,
# so we ship a hardcoded manifest. Editor auto-discovery still works
# via DirAccess.get_files_at() as a verification step.
const ENEMY_SCENES = {
	"basic_packet":     "res://scenes/campaign/enemies/types/EnemyBasicPacket.tscn",
	"bubble_shield":    "res://scenes/campaign/enemies/types/EnemyBubbleShield.tscn",
	"binary_mask":      "res://scenes/campaign/enemies/types/EnemyBinaryMask.tscn",
	"indexed_packet":   "res://scenes/campaign/enemies/types/EnemyIndexedPacket.tscn",
	"count_meter":      "res://scenes/campaign/enemies/types/EnemyCountMeter.tscn",
	"insertion_stack":  "res://scenes/campaign/enemies/types/EnemyInsertionStack.tscn",
	"linked_drain":     "res://scenes/campaign/enemies/types/EnemyLinkedDrain.tscn",
	"merge_twin":       "res://scenes/campaign/enemies/types/EnemyMergeTwin.tscn",
	"overflow_packet":  "res://scenes/campaign/enemies/types/EnemyOverflowPacket.tscn",
	"pivot_splitter":   "res://scenes/campaign/enemies/types/EnemyPivotSplitter.tscn",
	"queue_jumper":     "res://scenes/campaign/enemies/types/EnemyQueueJumper.tscn",
	"radix_digit":      "res://scenes/campaign/enemies/types/EnemyRadixDigit.tscn",
	"scan_wave":        "res://scenes/campaign/enemies/types/EnemyScanWave.tscn",
	"selection_mark":   "res://scenes/campaign/enemies/types/EnemySelectionMark.tscn",
}

var _scene_map: Dictionary = {}   # enemy_type -> PackedScene
var _initialized: bool = false

func _ready() -> void:
	_initialize_scenes()

func _initialize_scenes() -> void:
	if _initialized:
		return
	# Editor builds: use DirAccess to verify manifest matches filesystem.
	# Exported builds: DirAccess returns empty array on packed PCK, so we
	# fall back to the static manifest for actual loading.
	var discovered := _discover_scenes()
	if discovered.is_empty():
		# Use static manifest
		for enemy_type in ENEMY_SCENES:
			var scene = load(ENEMY_SCENES[enemy_type]) as PackedScene
			if scene:
				_scene_map[enemy_type] = scene
	else:
		# Editor path: use discovered, optionally enriched by manifest
		for enemy_type in discovered:
			var scene = load(discovered[enemy_type]) as PackedScene
			if scene:
				_scene_map[enemy_type] = scene
		# Pick up any scene in manifest but not discovered
		for enemy_type in ENEMY_SCENES:
			if not _scene_map.has(enemy_type):
				var scene = load(ENEMY_SCENES[enemy_type]) as PackedScene
				if scene:
					_scene_map[enemy_type] = scene
	_initialized = true

func _discover_scenes() -> Dictionary:
	var scenes: Dictionary = {}
	var dir = DirAccess.get_files_at(TYPES_DIR)
	for f in dir:
		if f.ends_with(".tscn"):
			var full_path = TYPES_DIR + f
			var scene = load(full_path) as PackedScene
			if scene:
				var inst = scene.instantiate()
				if inst.has_method("get_type_id"):
					var type_id = inst.get_type_id()
					if type_id != "":
						scenes[type_id] = full_path
				inst.queue_free()
	return scenes

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
		_apply_enemy_style(enemy, enemy_type)
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
	_apply_enemy_style(e, enemy_id)
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

func _apply_enemy_style(enemy: Enemy, enemy_type: String) -> void:
	if enemy == null or enemy.style != null:
		return
	var canonical: EnemyData = DataRegistry.get_enemy(enemy_type)
	if canonical and canonical.style:
		enemy.style = canonical.style
