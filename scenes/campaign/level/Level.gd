# Level.gd
extends Node2D

# ─── NODE REFERENCES ───────────────────────────────────
@onready var grid_visual: Node2D             = $GridLayer/GridVisual
@onready var tower_layer: Node2D             = $TowerLayer
@onready var enemy_layer: Node2D             = $EnemyLayer
@onready var wave_manager: Node              = $Managers/WaveManager
@onready var ram_manager: Node               = $Managers/RAMManager
@onready var back_btn: Button                = $HUD/HUDControl/TopHUD/TopLayout/BackBtn
@onready var level_label: Label              = $HUD/HUDControl/TopHUD/TopLayout/LevelLabel
@onready var ram_label: Label                = $HUD/HUDControl/TopHUD/TopLayout/RAMLabel
@onready var wave_label: Label               = $HUD/HUDControl/TopHUD/TopLayout/WaveLabel
@onready var base_health_label: Label        = $HUD/HUDControl/TopHUD/TopLayout/BaseHealthLabel
@onready var score_label: Label              = $HUD/HUDControl/TopHUD/TopLayout/ScoreLabel
@onready var tower_buttons: HBoxContainer    = $HUD/HUDControl/TowerSelector/SelectorLayout/TowerButtons
@onready var start_wave_btn: Button          = $HUD/HUDControl/TowerSelector/SelectorLayout/StartWaveBtn
@onready var game_over_panel: PanelContainer = $HUD/HUDControl/GameOverPanel

# ─── LEVEL STATE ───────────────────────────────────────
var level_number: int              = 1
var score: int                     = 0
var base_health: int               = 10
var selected_tower_data: TowerData = null
var grid_system: Node2D            = null
var level_start_time: float        = 0.0

# ─── TOWER DEFINITIONS ─────────────────────────────────
const TOWER_DEFINITIONS = {
	"tower_array": {
		"tower_id":       "tower_array",
		"tower_name":     "Array Tower",
		"description":    "Fast attack. O(1) access speed.",
		"data_structure": "Array",
		"ram_cost":       40,
		"damage":         18.0,
		"attack_speed":   2.0,
		"attack_range":   140.0,
		"time_complexity":"O(1)",
		"color":          Color("#00D4FF"),
		"icon_text":      "[ ]",
	},
	"tower_stack": {
		"tower_id":       "tower_stack",
		"tower_name":     "Stack Tower",
		"description":    "Hits most recent enemy. LIFO.",
		"data_structure": "Stack",
		"ram_cost":       60,
		"damage":         28.0,
		"attack_speed":   1.2,
		"attack_range":   130.0,
		"time_complexity":"O(1)",
		"color":          Color("#FF6B35"),
		"icon_text":      "↑↓",
	},
	"tower_queue": {
		"tower_id":       "tower_queue",
		"tower_name":     "Queue Tower",
		"description":    "Pierces 2 enemies. FIFO.",
		"data_structure": "Queue",
		"ram_cost":       60,
		"damage":         22.0,
		"attack_speed":   1.6,
		"attack_range":   160.0,
		"time_complexity":"O(1)",
		"color":          Color("#9B59B6"),
		"icon_text":      "→",
	},
	"tower_linked_list": {
		"tower_id":       "tower_linked_list",
		"tower_name":     "Linked Tower",
		"description":    "Chain damage 3 enemies.",
		"data_structure": "Linked List",
		"ram_cost":       80,
		"damage":         20.0,
		"attack_speed":   1.3,
		"attack_range":   150.0,
		"time_complexity":"O(n)",
		"color":          Color("#00FF88"),
		"icon_text":      "→→",
	},
	"tower_bubble": {
		"tower_id":       "tower_bubble",
		"tower_name":     "Bubble Tower",
		"description":    "AoE — hits all in range.",
		"data_structure": "Bubble Sort",
		"ram_cost":       70,
		"damage":         16.0,
		"attack_speed":   1.5,
		"attack_range":   130.0,
		"time_complexity":"O(n²)",
		"color":          Color("#FFB800"),
		"icon_text":      "↑↑",
	},
	"tower_selection": {
		"tower_id":       "tower_selection",
		"tower_name":     "Selection Tower",
		"description":    "Targets lowest HP enemy.",
		"data_structure": "Selection Sort",
		"ram_cost":       90,
		"damage":         24.0,
		"attack_speed":   1.0,
		"attack_range":   170.0,
		"time_complexity":"O(n²)",
		"color":          Color("#E74C3C"),
		"icon_text":      "→↓",
	},
	"tower_insertion": {
		"tower_id":       "tower_insertion",
		"tower_name":     "Insertion Tower",
		"description":    "Damage over time stacking.",
		"data_structure": "Insertion Sort",
		"ram_cost":       100,
		"damage":         18.0,
		"attack_speed":   1.4,
		"attack_range":   140.0,
		"time_complexity":"O(n)",
		"color":          Color("#1ABC9C"),
		"icon_text":      "←↑",
	},
	"tower_quick": {
		"tower_id":       "tower_quick",
		"tower_name":     "Quick Tower",
		"description":    "Splits shot hits 2 enemies.",
		"data_structure": "Quick Sort",
		"ram_cost":       130,
		"damage":         22.0,
		"attack_speed":   1.8,
		"attack_range":   155.0,
		"time_complexity":"O(n log n)",
		"color":          Color("#E91E63"),
		"icon_text":      "⚡",
	},
	"tower_merge": {
		"tower_id":       "tower_merge",
		"tower_name":     "Merge Tower",
		"description":    "Guaranteed AoE damage.",
		"data_structure": "Merge Sort",
		"ram_cost":       140,
		"damage":         20.0,
		"attack_speed":   1.4,
		"attack_range":   160.0,
		"time_complexity":"O(n log n)",
		"color":          Color("#3F51B5"),
		"icon_text":      "⊕",
	},
	"tower_counting": {
		"tower_id":       "tower_counting",
		"tower_name":     "Count Tower",
		"description":    "Stronger vs groups.",
		"data_structure": "Counting Sort",
		"ram_cost":       110,
		"damage":         14.0,
		"attack_speed":   2.2,
		"attack_range":   130.0,
		"time_complexity":"O(n+k)",
		"color":          Color("#009688"),
		"icon_text":      "#",
	},
	"tower_radix": {
		"tower_id":       "tower_radix",
		"tower_name":     "Radix Tower",
		"description":    "Rapid multi-pass bursts.",
		"data_structure": "Radix Sort",
		"ram_cost":       150,
		"damage":         12.0,
		"attack_speed":   3.0,
		"attack_range":   145.0,
		"time_complexity":"O(d×n)",
		"color":          Color("#FF5722"),
		"icon_text":      "0→9",
	},
	"tower_linear": {
		"tower_id":       "tower_linear",
		"tower_name":     "Linear Tower",
		"description":    "Wide scan, guaranteed hit.",
		"data_structure": "Linear Search",
		"ram_cost":       80,
		"damage":         16.0,
		"attack_speed":   1.0,
		"attack_range":   200.0,
		"time_complexity":"O(n)",
		"color":          Color("#607D8B"),
		"icon_text":      "→?",
	},
	"tower_binary": {
		"tower_id":       "tower_binary",
		"tower_name":     "Binary Tower",
		"description":    "Precision sniper. O(log n).",
		"data_structure": "Binary Search",
		"ram_cost":       200,
		"damage":         80.0,
		"attack_speed":   0.5,
		"attack_range":   250.0,
		"time_complexity":"O(log n)",
		"color":          Color("#8BC34A"),
		"icon_text":      "½",
	},
}

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	level_number     = GameManager.current_level
	level_start_time = Time.get_ticks_msec() / 1000.0
	_setup_grid()
	_setup_level()
	_setup_hud()
	_setup_buttons()
	_connect_signals()
	_apply_hud_styles()

# ─── SETUP ─────────────────────────────────────────────
func _setup_grid() -> void:
	grid_system      = GridSystem.new()
	grid_system.name = "GridSystem"
	grid_visual.add_child(grid_system)

	var config = _get_level_config()

	var waypoints: Array[Vector2] = []
	for wp in config["waypoints"]:
		waypoints.append(wp)

	var spots: Array[Vector2i] = []
	for sp in config["tower_spots"]:
		spots.append(sp)

	grid_system.initialize(waypoints, spots)
	grid_system.cell_clicked.connect(_on_cell_clicked)

func _setup_level() -> void:
	var config = _get_level_config()
	ram_manager.initialize(config["start_ram"])

	var enemy_scene = preload(
		"res://scenes/campaign/enemies/Enemy.tscn"
	)
	var waypoints: Array[Vector2] = []
	for wp in config["waypoints"]:
		waypoints.append(wp)

	wave_manager.initialize(
		config["waves"],
		enemy_scene,
		enemy_layer,
		waypoints,
		AdaptiveAI.get_wave_modifier()
	)

func _setup_hud() -> void:
	var config             = _get_level_config()
	level_label.text       = "Level " + str(level_number) + \
		" — " + config["name"]
	wave_label.text        = "Wave: 0/" + str(config["waves"])
	base_health_label.text = "❤️ " + str(base_health)
	score_label.text       = "Score: 0"
	_update_ram_label()
	_build_tower_selector()

func _build_tower_selector() -> void:
	for child in tower_buttons.get_children():
		child.queue_free()

	var selected = GameManager.selected_towers
	if selected.is_empty():
		selected = _get_level_config().get("towers", [])

	for tower_id in selected:
		if not TOWER_DEFINITIONS.has(tower_id):
			continue
		var def  = TOWER_DEFINITIONS[tower_id]
		var btn  := Button.new()
		btn.text = def["tower_name"] + "\n" + \
			str(def["ram_cost"]) + " RAM"
		btn.custom_minimum_size = Vector2(110, 60)
		_style_tower_btn(btn, Color(def["color"]))
		btn.pressed.connect(_on_tower_selected.bind(tower_id))
		tower_buttons.add_child(btn)

func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	start_wave_btn.pressed.connect(wave_manager.start_next_wave)

func _connect_signals() -> void:
	ram_manager.ram_changed.connect(_on_ram_changed)
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.all_waves_completed.connect(_on_all_waves_completed)
	SignalBus.enemy_reached_end.connect(_on_enemy_reached_end)
	SignalBus.enemy_defeated.connect(_on_enemy_defeated)

# ─── GRID INTERACTION ──────────────────────────────────
func _on_cell_clicked(cell: Vector2i) -> void:
	if selected_tower_data == null:
		SignalBus.hud_message_requested.emit(
			"Select a tower from the bottom bar first.", 2.0
		)
		return
	if not grid_system.can_place_tower(cell):
		SignalBus.hud_message_requested.emit(
			"Can't place tower here.", 2.0
		)
		return
	if not ram_manager.can_afford(selected_tower_data.ram_cost):
		SignalBus.hud_message_requested.emit(
			"Not enough RAM! Need " + \
			str(selected_tower_data.ram_cost) + " RAM.", 2.0
		)
		return
	_place_tower(cell)

func _place_tower(cell: Vector2i) -> void:
	ram_manager.spend(selected_tower_data.ram_cost)

	var tower_scene = preload(
		"res://scenes/campaign/towers/Tower.tscn"
	)
	var tower = tower_scene.instantiate()
	tower_layer.add_child(tower)
	tower.position = grid_system.get_cell_center(cell)
	tower.initialize(selected_tower_data, cell, enemy_layer)
	grid_system.place_tower(cell, tower)

	SignalBus.tower_placed.emit(selected_tower_data.tower_id, cell)
	print("[Level] Tower placed at: ", cell)

# ─── TOWER SELECTION ───────────────────────────────────
func _on_tower_selected(tower_id: String) -> void:
	var def = TOWER_DEFINITIONS[tower_id]
	selected_tower_data              = TowerData.new()
	selected_tower_data.tower_id     = def["tower_id"]
	selected_tower_data.tower_name   = def["tower_name"]
	selected_tower_data.ram_cost     = def["ram_cost"]
	selected_tower_data.damage       = def["damage"]
	selected_tower_data.attack_speed = def["attack_speed"]
	selected_tower_data.attack_range = def["attack_range"]
	selected_tower_data.color        = def["color"]
	selected_tower_data.icon_text    = def["icon_text"]
	grid_system.is_placing_tower     = true
	SignalBus.hud_message_requested.emit(
		"Click a spot to place " + def["tower_name"] + \
		" (" + str(def["ram_cost"]) + " RAM)", 2.0
	)

# ─── INPUT ─────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

# ─── SIGNAL HANDLERS ───────────────────────────────────
func _on_ram_changed(_current: int, _max_ram: int) -> void:
	_update_ram_label()

func _on_wave_started(wave_num: int, total: int) -> void:
	wave_label.text = "Wave: " + str(wave_num) + "/" + str(total)
	start_wave_btn.disabled = true
	SignalBus.hud_message_requested.emit(
		"⚔️ Wave " + str(wave_num) + " incoming!", 2.0
	)

func _on_wave_completed(wave_num: int) -> void:
	score            += 100 * wave_num
	score_label.text  = "Score: " + str(score)
	ram_manager.earn(50)
	start_wave_btn.disabled = false
	SignalBus.hud_message_requested.emit(
		"✅ Wave " + str(wave_num) + " complete! +50 RAM", 3.0
	)

func _on_all_waves_completed() -> void:
	var elapsed = (Time.get_ticks_msec() / 1000.0) - level_start_time
	ProgressManager.on_level_completed(level_number)
	SupabaseManager.submit_campaign_score(level_number, elapsed, score)
	AdaptiveAI.record_level_performance(
		_get_grade()["letter"], base_health, elapsed
	)
	_show_result_panel(true)

func _on_enemy_reached_end(_enemy_id: String) -> void:
	base_health -= 1
	_update_base_health_label()
	if base_health <= 0:
		AdaptiveAI.record_level_performance("F", 0, 0.0)
		_show_result_panel(false)

func _on_enemy_defeated(_enemy_id: String) -> void:
	ram_manager.earn(10)
	score            += 10
	score_label.text  = "Score: " + str(score)

# ─── BASE HEALTH ───────────────────────────────────────
func _update_base_health_label() -> void:
	base_health_label.text = "❤️ " + str(base_health)
	var tween = create_tween()
	tween.tween_property(
		base_health_label, "modulate", Color("#FF0000"), 0.1
	)
	tween.tween_property(
		base_health_label, "modulate", Color("#FFFFFF"), 0.3
	)
	if base_health <= 3:
		SignalBus.hud_message_requested.emit(
			"⚠️ Base critical! " + str(base_health) + " HP left!", 2.0
		)

# ─── RESULT PANEL ──────────────────────────────────────
func _show_result_panel(victory: bool) -> void:
	for child in game_over_panel.get_children():
		child.queue_free()

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	if victory:
		title.text = "🎉 VICTORY!"
		title.add_theme_color_override("font_color", Color("#00FF88"))
	else:
		title.text = "💀 GAME OVER"
		title.add_theme_color_override("font_color", Color("#FF3366"))
	layout.add_child(title)

	var score_lbl := Label.new()
	score_lbl.text = "Score: " + str(score)
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.add_theme_color_override("font_color", Color("#E8F4FD"))
	score_lbl.add_theme_font_size_override("font_size", 20)
	layout.add_child(score_lbl)

	var grade     = _get_grade()
	var grade_lbl := Label.new()
	grade_lbl.text = "Grade: " + grade["letter"]
	grade_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_lbl.add_theme_font_size_override("font_size", 48)
	grade_lbl.add_theme_color_override("font_color", grade["color"])
	layout.add_child(grade_lbl)

	if victory:
		var unlock_lbl := Label.new()
		unlock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unlock_lbl.add_theme_color_override("font_color", Color("#00D4FF"))
		unlock_lbl.add_theme_font_size_override("font_size", 14)
		if ProgressManager.LEVEL_UNLOCKS_LESSON.has(level_number):
			var next_lesson = ProgressManager.LEVEL_UNLOCKS_LESSON[level_number]
			unlock_lbl.text = "🔓 New lesson unlocked: " + next_lesson
		layout.add_child(unlock_lbl)

	var stats_row := HBoxContainer.new()
	stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_row.add_theme_constant_override("separation", 24)
	_add_result_stat(stats_row, "BASE HP",  str(base_health) + "/10")
	_add_result_stat(stats_row, "WAVES",
		str(wave_manager.current_wave) + "/" + str(wave_manager.total_waves))
	var elapsed = int((Time.get_ticks_msec() / 1000.0) - level_start_time)
	_add_result_stat(stats_row, "TIME", str(elapsed) + "s")
	layout.add_child(stats_row)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)

	var retry_btn := Button.new()
	retry_btn.text = "↺ Retry"
	retry_btn.custom_minimum_size = Vector2(120, 44)
	retry_btn.pressed.connect(_on_retry_pressed)
	btn_row.add_child(retry_btn)

	var menu_btn := Button.new()
	menu_btn.text = "🏠 Level Select"
	menu_btn.custom_minimum_size = Vector2(140, 44)
	menu_btn.pressed.connect(_on_menu_pressed)
	btn_row.add_child(menu_btn)

	layout.add_child(btn_row)
	game_over_panel.add_child(layout)
	game_over_panel.visible = true

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	GameManager.go_to("campaign")

func _get_grade() -> Dictionary:
	var hp_ratio = float(base_health) / 10.0
	if hp_ratio >= 0.9:
		return {"letter": "S", "color": Color("#FFD700")}
	elif hp_ratio >= 0.7:
		return {"letter": "A", "color": Color("#00FF88")}
	elif hp_ratio >= 0.5:
		return {"letter": "B", "color": Color("#00D4FF")}
	elif hp_ratio >= 0.3:
		return {"letter": "C", "color": Color("#FFB800")}
	else:
		return {"letter": "F", "color": Color("#FF3366")}

func _add_result_stat(
		container: HBoxContainer,
		label: String,
		value: String) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)

	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	col.add_child(lbl)

	var val := Label.new()
	val.text = value
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val.add_theme_font_size_override("font_size", 16)
	val.add_theme_color_override("font_color", Color("#E8F4FD"))
	col.add_child(val)

	container.add_child(col)

# ─── NAVIGATION ────────────────────────────────────────
func _on_back_pressed() -> void:
	GameManager.go_to("campaign")

# ─── HUD HELPERS ───────────────────────────────────────
func _update_ram_label() -> void:
	ram_label.text = "💾 " + str(ram_manager.get_current()) + " RAM"

func _get_level_config() -> Dictionary:
	if GameManager.LEVEL_CONFIGS.has(level_number):
		return GameManager.LEVEL_CONFIGS[level_number]
	return GameManager.LEVEL_CONFIGS[1]

# ─── HUD STYLES ────────────────────────────────────────
func _apply_hud_styles() -> void:
	var top_style := StyleBoxFlat.new()
	top_style.bg_color            = Color("#0A1628")
	top_style.border_color        = Color("#00D4FF")
	top_style.border_width_bottom = 1
	$HUD/HUDControl/TopHUD.add_theme_stylebox_override("panel", top_style)

	var sel_style := StyleBoxFlat.new()
	sel_style.bg_color         = Color("#0A1628")
	sel_style.border_color     = Color("#00D4FF")
	sel_style.border_width_top = 1
	$HUD/HUDControl/TowerSelector.add_theme_stylebox_override(
		"panel", sel_style
	)

	var go_style := StyleBoxFlat.new()
	go_style.bg_color                    = Color("#050D1A")
	go_style.border_color                = Color("#00D4FF")
	go_style.border_width_left           = 1
	go_style.border_width_right          = 1
	go_style.border_width_top            = 1
	go_style.border_width_bottom         = 1
	go_style.corner_radius_top_left      = 8
	go_style.corner_radius_top_right     = 8
	go_style.corner_radius_bottom_left   = 8
	go_style.corner_radius_bottom_right  = 8
	$HUD/HUDControl/GameOverPanel.add_theme_stylebox_override(
		"panel", go_style
	)

	var back_style := StyleBoxFlat.new()
	back_style.bg_color                   = Color("#0A1628")
	back_style.border_color               = Color("#FF3366")
	back_style.border_width_left          = 1
	back_style.border_width_right         = 1
	back_style.border_width_top           = 1
	back_style.border_width_bottom        = 1
	back_style.corner_radius_top_left     = 4
	back_style.corner_radius_top_right    = 4
	back_style.corner_radius_bottom_left  = 4
	back_style.corner_radius_bottom_right = 4
	back_btn.add_theme_stylebox_override("normal", back_style)
	back_btn.add_theme_color_override("font_color", Color("#FF3366"))

	var wave_style := StyleBoxFlat.new()
	wave_style.bg_color                   = Color("#FFB800")
	wave_style.corner_radius_top_left     = 4
	wave_style.corner_radius_top_right    = 4
	wave_style.corner_radius_bottom_left  = 4
	wave_style.corner_radius_bottom_right = 4
	start_wave_btn.add_theme_stylebox_override("normal", wave_style)
	start_wave_btn.add_theme_color_override("font_color", Color("#050D1A"))
	start_wave_btn.add_theme_font_size_override("font_size", 13)

func _style_tower_btn(btn: Button, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color                    = Color("#0A1628")
	style.border_color                = color
	style.border_width_left           = 1
	style.border_width_right          = 1
	style.border_width_top            = 1
	style.border_width_bottom         = 1
	style.corner_radius_top_left      = 4
	style.corner_radius_top_right     = 4
	style.corner_radius_bottom_left   = 4
	style.corner_radius_bottom_right  = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_font_size_override("font_size", 11)
