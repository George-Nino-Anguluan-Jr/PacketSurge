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

# Static manifest: tower_id → scene path.
# DirAccess cannot enumerate packed PCK folders in exported builds,
# so we ship a hardcoded manifest. Editor auto-discovery still works
# via DirAccess.get_files_at() as a verification step.
const TOWER_SCENES = {
	"tower_array":         "res://scenes/campaign/towers/types/TowerArray.tscn",
	"tower_stack":         "res://scenes/campaign/towers/types/TowerStack.tscn",
	"tower_queue":         "res://scenes/campaign/towers/types/TowerQueue.tscn",
	"tower_linked_list":   "res://scenes/campaign/towers/types/TowerLinkedList.tscn",
	"tower_bubble":        "res://scenes/campaign/towers/types/TowerBubble.tscn",
	"tower_selection":     "res://scenes/campaign/towers/types/TowerSelection.tscn",
	"tower_insertion":     "res://scenes/campaign/towers/types/TowerInsertion.tscn",
	"tower_quick":         "res://scenes/campaign/towers/types/TowerQuick.tscn",
	"tower_merge":         "res://scenes/campaign/towers/types/TowerMerge.tscn",
	"tower_counting":      "res://scenes/campaign/towers/types/TowerCounting.tscn",
	"tower_radix":         "res://scenes/campaign/towers/types/TowerRadix.tscn",
	"tower_linear":        "res://scenes/campaign/towers/types/TowerLinear.tscn",
	"tower_binary":        "res://scenes/campaign/towers/types/TowerBinary.tscn",
}

var _scene_map: Dictionary = {}   # tower_id -> PackedScene
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
		for type_id in TOWER_SCENES:
			var scene = load(TOWER_SCENES[type_id]) as PackedScene
			if scene:
				_scene_map[type_id] = scene
	else:
		# Editor path: use discovered, optionally enriched by manifest
		for type_id in discovered:
			var scene = load(discovered[type_id]) as PackedScene
			if scene:
				_scene_map[type_id] = scene
		# Pick up any scene in manifest but not discovered
		for type_id in TOWER_SCENES:
			if not _scene_map.has(type_id):
				var scene = load(TOWER_SCENES[type_id]) as PackedScene
				if scene:
					_scene_map[type_id] = scene
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

func get_scene(tower_id: String) -> PackedScene:
	if not _initialized:
		_initialize_scenes()
	return _scene_map.get(tower_id, null)

func get_scene_path(tower_id: String) -> String:
	if not _initialized:
		_initialize_scenes()
	if _scene_map.has(tower_id):
		return TOWER_SCENES.get(tower_id, "")
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
