extends Control

var tower_color: Color = Color("#00D4FF")
var tower_icon: String = "[ ]"
var tower_name: String = "Tower"
var tower_id: String = ""

var strong_enemies: Array[String] = []
var weak_enemies: Array[String] = []

var _bg: ColorRect
var _world: Control
var _enemy_layer: Node2D
var _tower_instance: Node2D
var _info_label: Label

var enemy_queue: Array[Dictionary] = []
var spawn_timer: float = 0.0
var cycle_done: bool = false
var _initialized: bool = false

const ENEMY_SCENE = preload("res://scenes/campaign/enemies/Enemy.tscn")
const TOWER_SCENE = preload("res://scenes/campaign/towers/Tower.tscn")

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE

	_bg = ColorRect.new()
	_bg.color = Color("#050D1A")
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	_world = Control.new()
	_world.mouse_filter = MOUSE_FILTER_IGNORE
	_world.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_world)

	_enemy_layer = Node2D.new()
	_world.add_child(_enemy_layer)

	_info_label = Label.new()
	_info_label.add_theme_font_size_override("font_size", 10)
	_info_label.add_theme_color_override("font_color", Color("#4A7FA5"))
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_info_label.offset_top = -18
	_info_label.offset_bottom = 0
	add_child(_info_label)

	_initialized = true

func setup(t_id: String) -> void:
	if not _initialized:
		_ready()
	tower_id = t_id
	var data = TowerIntroData.get_intro(t_id)
	var def = GameManager.TOWER_DEFINITIONS.get(t_id, {})
	tower_color = def.get("color", Color("#00D4FF"))
	tower_icon = def.get("icon_text", "[ ]")
	tower_name = def.get("tower_name", "Tower")

	var raw_strong = data.get("strong", [])
	var raw_weak = data.get("weak", [])
	strong_enemies.clear()
	weak_enemies.clear()
	for e in raw_strong: strong_enemies.append(str(e))
	for e in raw_weak: weak_enemies.append(str(e))

	_clear_enemies()
	_build_tower()
	_build_enemy_queue()
	spawn_timer = 0.8
	cycle_done = false
	_info_label.text = ""

func _build_tower() -> void:
	if _tower_instance:
		_tower_instance.queue_free()
	_tower_instance = TOWER_SCENE.instantiate()
	var td = TowerData.new()
	td.tower_id = tower_id
	td.tower_name = tower_name
	td.damage = 40.0
	td.attack_speed = 2.8
	td.attack_range = 600.0
	td.color = tower_color
	td.icon_text = tower_icon
	_tower_instance.initialize(td, Vector2i.ZERO, _enemy_layer)
	_world.add_child(_tower_instance)
	var sw = max(size.x, 300.0)
	var sh = max(size.y, 100.0)
	_tower_instance.position = Vector2(sw * 0.5, sh * 0.55)

func _build_enemy_queue() -> void:
	enemy_queue.clear()
	var all_types: Array[String] = []
	for e in strong_enemies:
		if not all_types.has(e): all_types.append(e)
	for e in weak_enemies:
		if not all_types.has(e): all_types.append(e)
	if all_types.is_empty():
		all_types = ["basic_packet"]
	all_types.shuffle()
	for etype in all_types:
		var is_strong = strong_enemies.has(etype)
		enemy_queue.append({"type": etype, "strong": is_strong, "hp": 60 if is_strong else 800, "speed": 60.0})

func stop() -> void:
	set_process(false)
	if _tower_instance:
		_tower_instance.set_process(false)
	for c in _enemy_layer.get_children():
		c.queue_free()

func _clear_enemies() -> void:
	for c in _enemy_layer.get_children():
		c.queue_free()

func _spawn_enemy(data: Dictionary) -> void:
	var enemy = ENEMY_SCENE.instantiate()
	var sw = max(size.x, 300.0)
	var sh = max(size.y, 100.0)
	var cx = sw * 0.5
	var cy = sh * 0.55
	var start_x = sw + 20
	var end_x = -20
	var waypoints: Array[Vector2] = [
		Vector2(start_x, cy),
		Vector2(end_x, cy),
	]
	enemy.initialize(waypoints, data.hp, data.speed, data.type, {})
	enemy.position = Vector2(start_x, cy)
	_enemy_layer.add_child(enemy)
	enemy.set_meta("preview_strong", data.strong)
	var display = data.type.replace("_", " ").capitalize()
	var tag = " ? STRONG" if data.strong else " ? WEAK"
	var col = Color("#00FF88") if data.strong else Color("#FF3366")
	_info_label.text = display + tag
	_info_label.add_theme_color_override("font_color", col)

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	spawn_timer -= delta
	if not cycle_done:
		if spawn_timer <= 0 and enemy_queue.size() > 0:
			var next = enemy_queue.pop_front()
			_spawn_enemy(next)
			spawn_timer = 2.5
			if next.strong:
				spawn_timer = 1.8
		if enemy_queue.is_empty():
			var alive = false
			for c in _enemy_layer.get_children():
				if is_instance_valid(c):
					alive = true; break
			if not alive:
				cycle_done = true
				_info_label.text = ""
				spawn_timer = 2.0
	else:
		if spawn_timer <= 0:
			cycle_done = false
			setup(tower_id)
