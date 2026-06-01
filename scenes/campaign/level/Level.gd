# Level.gd
extends Node2D

# ─── NODE REFERENCES ───────────────────────────────────
@onready var grid_visual: Node2D        = $GridLayer/GridVisual
@onready var tower_layer: Node2D        = $TowerLayer
@onready var enemy_layer: Node2D        = $EnemyLayer
@onready var wave_manager: Node         = $Managers/WaveManager
@onready var ram_manager: Node          = $Managers/RAMManager
@onready var back_btn: Button           = $HUD/HUDControl/TopHUD/TopLayout/BackBtn
@onready var level_label: Label         = $HUD/HUDControl/TopHUD/TopLayout/LevelLabel
@onready var ram_label: Label           = $HUD/HUDControl/TopHUD/TopLayout/RAMLabel
@onready var wave_label: Label          = $HUD/HUDControl/TopHUD/TopLayout/WaveLabel
@onready var score_label: Label         = $HUD/HUDControl/TopHUD/TopLayout/ScoreLabel
@onready var tower_buttons: HBoxContainer = $HUD/HUDControl/TowerSelector/SelectorLayout/TowerButtons
@onready var start_wave_btn: Button = $HUD/HUDControl/TowerSelector/SelectorLayout/StartWaveBtn
@onready var micro_panel: PanelContainer  = $HUD/HUDControl/MicroCodingPanel
@onready var game_over_panel: PanelContainer = $HUD/HUDControl/GameOverPanel

# ─── LEVEL STATE ───────────────────────────────────────
var level_number: int        = 1
var score: int               = 0
var base_health: int         = 10
var selected_tower_data: TowerData = null
var grid_system: Node2D      = null
var level_start_time: float  = 0.0

# ─── LEVEL DEFINITIONS ─────────────────────────────────
const LEVEL_CONFIGS = {
	1: {
		"name":      "Initialization",
		"waves":     3,
		"start_ram": 150,
		"waypoints": [
			Vector2(0, 320), Vector2(1152, 320)
		],
		"towers": ["tower_array"],
	},
	2: {
		"name":      "Stack Overflow",
		"waves":     4,
		"start_ram": 175,
		"waypoints": [
			Vector2(0, 160),
			Vector2(576, 160),
			Vector2(576, 480),
			Vector2(1152, 480),
		],
		"towers": ["tower_array", "tower_stack"],
	},
	3: {
		"name":      "Queue Protocol",
		"waves":     4,
		"start_ram": 200,
		"waypoints": [
			Vector2(0, 96),
			Vector2(384, 96),
			Vector2(384, 480),
			Vector2(768, 480),
			Vector2(768, 224),
			Vector2(1152, 224),
		],
		"towers": ["tower_array", "tower_stack", "tower_queue"],
	},
}

# Tower data definitions
const TOWER_DEFINITIONS = {
	"tower_array": {
		"tower_id":    "tower_array",
		"tower_name":  "Array Tower",
		"description": "Fast attack. O(1) access speed.",
		"data_structure": "Array",
		"ram_cost":    50,
		"damage":      8.0,
		"attack_speed":1.5,
		"attack_range":130.0,
		"time_complexity": "O(1)",
		"color":       Color("#00D4FF"),
		"icon_text":   "[ ]",
	},
	"tower_stack": {
		"tower_id":    "tower_stack",
		"tower_name":  "Stack Tower",
		"description": "High damage. LIFO targeting.",
		"data_structure": "Stack",
		"ram_cost":    75,
		"damage":      15.0,
		"attack_speed":0.8,
		"attack_range":120.0,
		"time_complexity": "O(1)",
		"color":       Color("#FF6B35"),
		"icon_text":   "↑↓",
	},
	"tower_queue": {
		"tower_id":    "tower_queue",
		"tower_name":  "Queue Tower",
		"description": "Targets first enemy. FIFO.",
		"data_structure": "Queue",
		"ram_cost":    75,
		"damage":      12.0,
		"attack_speed":1.2,
		"attack_range":150.0,
		"time_complexity": "O(1)",
		"color":       Color("#9B59B6"),
		"icon_text":   "→",
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
	grid_system = GridSystem.new()
	grid_system.name = "GridSystem"
	grid_visual.add_child(grid_system)

	var config     = _get_level_config()
	var waypoints: Array[Vector2] = []
	for wp in config["waypoints"]:
		waypoints.append(wp)
	grid_system.initialize(waypoints)
	grid_system.cell_clicked.connect(_on_cell_clicked)

func _setup_level() -> void:
	var config = _get_level_config()

	# Initialize RAM
	ram_manager.initialize(config["start_ram"])

	# Initialize Wave Manager
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
	var config = _get_level_config()
	level_label.text = "Level " + str(level_number) + \
					   " — " + config["name"]
	wave_label.text  = "Wave: 0/" + str(config["waves"])
	_update_ram_label()
	_build_tower_selector()

func _build_tower_selector() -> void:
	for child in tower_buttons.get_children():
		child.queue_free()

	var config           = _get_level_config()
	var available_towers = config["towers"]

	for tower_id in available_towers:
		if not ProgressManager.is_tower_unlocked(tower_id):
			continue
		if not TOWER_DEFINITIONS.has(tower_id):
			continue
		var def  = TOWER_DEFINITIONS[tower_id]
		var btn  := Button.new()
		btn.text = def["tower_name"] + \
				   "\n" + str(def["ram_cost"]) + " RAM"
		btn.custom_minimum_size = Vector2(110, 60)
		_style_tower_btn(btn, Color(def["color"]))
		btn.pressed.connect(
			_on_tower_selected.bind(tower_id)
		)
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
	grid_system.place_tower(cell)

	var tower_scene = preload(
		"res://scenes/campaign/towers/Tower.tscn"
	)
	var tower = tower_scene.instantiate()
	tower_layer.add_child(tower)
	tower.position = grid_system.get_cell_center(cell)
	tower.initialize(selected_tower_data, cell, enemy_layer)

	SignalBus.tower_placed.emit(
		selected_tower_data.tower_id,
		cell
	)
	print("[Level] Tower placed at: ", cell)

# ─── TOWER SELECTION ───────────────────────────────────
func _on_tower_selected(tower_id: String) -> void:
	var def = TOWER_DEFINITIONS[tower_id]
	selected_tower_data          = TowerData.new()
	selected_tower_data.tower_id    = def["tower_id"]
	selected_tower_data.tower_name  = def["tower_name"]
	selected_tower_data.ram_cost    = def["ram_cost"]
	selected_tower_data.damage      = def["damage"]
	selected_tower_data.attack_speed = def["attack_speed"]
	selected_tower_data.attack_range = def["attack_range"]
	selected_tower_data.color       = def["color"]
	selected_tower_data.icon_text   = def["icon_text"]
	grid_system.is_placing_tower    = true
	SignalBus.hud_message_requested.emit(
		"Click a cell to place " + def["tower_name"], 2.0
	)

# ─── WAVE CONTROL ──────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
	# Press Space to start next wave
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_SPACE:
			wave_manager.start_next_wave()

# ─── SIGNAL HANDLERS ───────────────────────────────────
func _on_ram_changed(current: int, max_ram: int) -> void:
	_update_ram_label()

func _on_wave_started(wave_num: int, total: int) -> void:
	wave_label.text = "Wave: " + str(wave_num) + "/" + str(total)

func _on_wave_completed(wave_num: int) -> void:
	score += 100 * wave_num
	score_label.text = "Score: " + str(score)
	# Earn RAM on wave complete
	ram_manager.earn(50)
	SignalBus.hud_message_requested.emit(
		"Wave " + str(wave_num) + " complete! +50 RAM", 3.0
	)

func _on_all_waves_completed() -> void:
	var elapsed = (Time.get_ticks_msec() / 1000.0) - level_start_time
	ProgressManager.on_level_completed(level_number)
	SupabaseManager.submit_campaign_score(
		level_number, elapsed, score
	)
	_show_victory()

func _on_enemy_reached_end(_enemy_id: String) -> void:
	base_health -= 1
	SignalBus.hud_message_requested.emit(
		"⚠️ Base hit! Health: " + str(base_health), 2.0
	)
	if base_health <= 0:
		_show_game_over()

func _on_enemy_defeated(_enemy_id: String) -> void:
	ram_manager.earn(ram_manager.get_current() + 10)
	score += 10
	score_label.text = "Score: " + str(score)

# ─── WIN / LOSE ────────────────────────────────────────
func _show_victory() -> void:
	_build_result_panel(true)
	game_over_panel.visible = true

func _show_game_over() -> void:
	_build_result_panel(false)
	game_over_panel.visible = true

func _build_result_panel(victory: bool) -> void:
	for child in game_over_panel.get_children():
		child.queue_free()

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	layout.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	if victory:
		title.text = "🎉 VICTORY!"
		title.add_theme_color_override(
			"font_color", Color("#00FF88")
		)
	else:
		title.text = "💀 GAME OVER"
		title.add_theme_color_override(
			"font_color", Color("#FF3366")
		)
	layout.add_child(title)

	var score_lbl := Label.new()
	score_lbl.text = "Score: " + str(score)
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.add_theme_color_override(
		"font_color", Color("#E8F4FD")
	)
	score_lbl.add_theme_font_size_override("font_size", 18)
	layout.add_child(score_lbl)

	if victory:
		var unlock_lbl := Label.new()
		if LEVEL_CONFIGS.has(level_number):
			var next = LEVEL_UNLOCKS_LESSON(level_number)
			unlock_lbl.text = "🔓 " + next + " Unlocked!"
		unlock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unlock_lbl.add_theme_color_override(
			"font_color", Color("#00D4FF")
		)
		unlock_lbl.add_theme_font_size_override("font_size", 14)
		layout.add_child(unlock_lbl)

	# Buttons
	var btn_layout := HBoxContainer.new()
	btn_layout.add_theme_constant_override("separation", 12)
	btn_layout.alignment = BoxContainer.ALIGNMENT_CENTER

	var retry_btn  := Button.new()
	retry_btn.text = "↺ Retry"
	retry_btn.custom_minimum_size = Vector2(120, 44)
	retry_btn.pressed.connect(
		func(): get_tree().reload_current_scene()
	)

	var menu_btn   := Button.new()
	menu_btn.text  = "🏠 Menu"
	menu_btn.custom_minimum_size = Vector2(120, 44)
	menu_btn.pressed.connect(
		func(): GameManager.go_to("campaign")
	)

	btn_layout.add_child(retry_btn)
	btn_layout.add_child(menu_btn)
	layout.add_child(btn_layout)

	game_over_panel.add_child(layout)

func LEVEL_UNLOCKS_LESSON(level: int) -> String:
	return ProgressManager.LEVEL_UNLOCKS_LESSON.get(
		level, ""
	)

# ─── BACK ──────────────────────────────────────────────
func _on_back_pressed() -> void:
	GameManager.go_to("campaign")

# ─── HUD HELPERS ───────────────────────────────────────
func _update_ram_label() -> void:
	ram_label.text = "💾 RAM: " + str(ram_manager.get_current())

func _get_level_config() -> Dictionary:
	if LEVEL_CONFIGS.has(level_number):
		return LEVEL_CONFIGS[level_number]
	return LEVEL_CONFIGS[1]

# ─── STYLES ────────────────────────────────────────────
func _apply_hud_styles() -> void:
	var top_style := StyleBoxFlat.new()
	top_style.bg_color          = Color("#0A1628")
	top_style.border_color      = Color("#00D4FF")
	top_style.border_width_bottom = 1
	$HUD/HUDControl/TopHUD.add_theme_stylebox_override(
		"panel", top_style
	)

	var sel_style := StyleBoxFlat.new()
	sel_style.bg_color          = Color("#0A1628")
	sel_style.border_color      = Color("#00D4FF")
	sel_style.border_width_top  = 1
	$HUD/HUDControl/TowerSelector.add_theme_stylebox_override(
		"panel", sel_style
	)

	var go_style  := StyleBoxFlat.new()
	go_style.bg_color           = Color("#050D1A")
	go_style.border_color       = Color("#00D4FF")
	go_style.border_width_left  = 1
	go_style.border_width_right = 1
	go_style.border_width_top   = 1
	go_style.border_width_bottom = 1
	go_style.corner_radius_top_left     = 8
	go_style.corner_radius_top_right    = 8
	go_style.corner_radius_bottom_left  = 8
	go_style.corner_radius_bottom_right = 8
	$HUD/HUDControl/GameOverPanel.add_theme_stylebox_override(
		"panel", go_style
	)

	# Back button style
	var back_style := StyleBoxFlat.new()
	back_style.bg_color               = Color("#0A1628")
	back_style.border_color           = Color("#FF3366")
	back_style.border_width_left      = 1
	back_style.border_width_right     = 1
	back_style.border_width_top       = 1
	back_style.border_width_bottom    = 1
	back_style.corner_radius_top_left     = 4
	back_style.corner_radius_top_right    = 4
	back_style.corner_radius_bottom_left  = 4
	back_style.corner_radius_bottom_right = 4
	back_btn.add_theme_stylebox_override("normal", back_style)
	back_btn.add_theme_color_override("font_color", Color("#FF3366"))
	
	var wave_style := StyleBoxFlat.new()
	wave_style.bg_color               = Color("#FFB800")
	wave_style.corner_radius_top_left     = 4
	wave_style.corner_radius_top_right    = 4
	wave_style.corner_radius_bottom_left  = 4
	wave_style.corner_radius_bottom_right = 4
	start_wave_btn.add_theme_stylebox_override("normal", wave_style)
	start_wave_btn.add_theme_color_override("font_color", Color("#050D1A"))
	start_wave_btn.add_theme_font_size_override("font_size", 13)

func _style_tower_btn(btn: Button, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = color
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_font_size_override("font_size", 11)
