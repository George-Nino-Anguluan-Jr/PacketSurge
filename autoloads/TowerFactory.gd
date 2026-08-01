# TowerFactory.gd
# Autoload singleton. Maps tower_id → PackedScene.
# Replaces direct preload("res://scenes/campaign/towers/Tower.tscn") calls.
#
# Usage:
#   var tower = TowerFactory.create_tower(data, cell, enemy_layer)
#   var preview = TowerFactory.create_preview_tower(data)

extends Node

const TYPES_DIR = "res://scenes/campaign/towers/types/"
const DEFAULT_TOWER_SCENE = preload("res://scenes/campaign/towers/types/TowerArray.tscn")

var _scene_map: Dictionary = {}   # tower_id -> PackedScene
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
				# Temporarily instantiate to read the type_id
				var inst = scene.instantiate()
				if inst.has_method("get_type_id"):
					var type_id = inst.get_type_id()
					_scene_map[type_id] = scene
				inst.queue_free()
	_initialized = true

func get_scene(tower_id: String) -> PackedScene:
	if not _initialized:
		_initialize_scenes()
	return _scene_map.get(tower_id, null)

func get_scene_path(tower_id: String) -> String:
	if not _initialized:
		_initialize_scenes()
	if _scene_map.has(tower_id):
		return TYPES_DIR + tower_id.replace("tower_", "Tower").capitalize().replace(" ", "") + ".tscn"
	return ""

func create_tower(data: TowerData, cell: Vector2i, e_layer: Node2D) -> Node2D:
	if not _initialized:
		_initialize_scenes()
	_ensure_data_style(data)
	var scene = _scene_map.get(data.tower_id, null)
	if scene == null:
		push_warning("[TowerFactory] No scene found for tower_id: ", data.tower_id)
		return null
	var tower = scene.instantiate()
	if tower.has_method("initialize"):
		tower.initialize(data, cell, e_layer)
	return tower

func create_preview_tower(data: TowerData) -> Node2D:
	if not _initialized:
		_initialize_scenes()
	_ensure_data_style(data)
	var scene = _scene_map.get(data.tower_id, null)
	if scene == null:
		push_warning("[TowerFactory] No scene found for tower_id: ", data.tower_id)
		return null
	var tower = scene.instantiate()
	tower.preview_mode = true
	if tower.has_method("initialize"):
		tower.initialize(data, Vector2i.ZERO, null)
	# Hide range detector in preview
	var ra = tower.get_node_or_null("RangeDetector")
	if ra:
		ra.queue_free()
	return tower

func create_tower_by_id(tower_id: String, cell: Vector2i, e_layer: Node2D) -> Node2D:
	var scene = get_scene(tower_id)
	if scene == null:
		return null
	var tower = scene.instantiate()
	var data: TowerData = DataRegistry.get_tower(tower_id)
	if data and tower.has_method("initialize"):
		_ensure_data_style(data)
		tower.initialize(data, cell, e_layer)
	return tower

func _ensure_data_style(data: TowerData) -> void:
	if data == null or data.style != null:
		return
	var canonical: TowerData = DataRegistry.get_tower(data.tower_id)
	if canonical and canonical.style:
		data.style = canonical.style
