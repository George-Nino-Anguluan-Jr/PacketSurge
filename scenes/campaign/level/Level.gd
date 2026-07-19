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
@onready var game_over_panel: PanelContainer = $HUD/HUDControl/GameOverPanel

@onready var pause_btn: Button               = $HUD/HUDControl/TopHUD/TopLayout/PauseBtn
@onready var pause_menu: PanelContainer      = $HUD/HUDControl/PauseMenu
@onready var resume_btn: Button              = $HUD/HUDControl/PauseMenu/PauseMenuLayout/ResumeBtn
@onready var retry_btn: Button               = $HUD/HUDControl/PauseMenu/PauseMenuLayout/RetryBtn
@onready var select_level_btn: Button        = $HUD/HUDControl/PauseMenu/PauseMenuLayout/SelectLevelBtn
@onready var main_menu_btn: Button           = $HUD/HUDControl/PauseMenu/PauseMenuLayout/MainMenuBtn

@onready var wave_progress_bar: ProgressBar = $HUD/HUDControl/TopHUD/TopLayout/WaveProgressTimeline/ProgressBar
@onready var timeline_flags: Control        = $HUD/HUDControl/TopHUD/TopLayout/WaveProgressTimeline/FlagsContainer
@onready var skip_wave_btn: Button           = $HUD/HUDControl/TopHUD/TopLayout/SkipWaveBtn
@onready var wave_splash: Control            = $HUD/HUDControl/WaveSplash
@onready var wave_splash_label: Label        = $HUD/HUDControl/WaveSplash/WaveSplashLabel

# ─── LEVEL STATE ───────────────────────────────────────
var level_number: int              = 1
var score: int                     = 0
var base_health: int               = 10
var selected_tower_data: TowerData = null
var grid_system: Node2D            = null
var level_start_time: float        = 0.0
var is_level_ended: bool           = false

const INTER_WAVE_DURATION: float  = 15.0
var wave_countdown: float          = INTER_WAVE_DURATION
var countdown_active: bool         = true

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
	
	# Dynamically handle auto-centering of the grid system on any viewport screen size
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	_create_overlay_menu()
	if level_number == 1:
		_show_tutorial()

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
	back_btn.visible       = false
	level_label.visible    = false
	skip_wave_btn.text = "⏩ Skip (20⚡)"
	_update_ram_label()
	_build_tower_selector()
	_setup_wave_timeline()

func _setup_wave_timeline() -> void:
	for child in timeline_flags.get_children():
		child.queue_free()

	var total_waves = wave_manager.total_waves
	var timeline_width = 200.0

	wave_progress_bar.max_value = float(total_waves)
	wave_progress_bar.value = 0.0

	for i in range(1, total_waves + 1):
		var fraction = float(i) / float(total_waves)
		var x_pos = fraction * timeline_width

		var flag := Label.new()
		flag.text = "🚩"
		flag.add_theme_font_size_override("font_size", 10)
		flag.add_theme_color_override("font_color", Color("#FF3366"))
		flag.custom_minimum_size = Vector2(16, 16)
		flag.position = Vector2(x_pos - 8, -4)
		timeline_flags.add_child(flag)

func _on_viewport_size_changed() -> void:
	var vp_width = get_viewport().get_visible_rect().size.x
	# Map/Grid is centered: GRID_COLS * CELL_SIZE = 18 * 64 = 1152 width. Centered X is 576.0.
	# Viewport center is vp_width / 2.0. Shift the camera so the grid (centered at 576) aligns with the viewport center.
	var visible_center = vp_width / 2.0
	var shift = (vp_width / 2.0) - visible_center
	$GameCamera.position.x = 576.0 + shift
	$GameCamera.position.y = 320.0 # 10 * 64 / 2 = 320.0

func _build_tower_selector() -> void:
	pass

func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	pause_btn.pressed.connect(_on_pause_pressed)
	resume_btn.pressed.connect(_on_resume_pressed)
	retry_btn.pressed.connect(_on_retry_pressed)
	select_level_btn.pressed.connect(_on_select_level_pressed)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	skip_wave_btn.pressed.connect(_on_skip_wave_pressed)

func _connect_signals() -> void:
	ram_manager.ram_changed.connect(_on_ram_changed)
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.all_waves_completed.connect(_on_all_waves_completed)
	SignalBus.enemy_reached_end.connect(_on_enemy_reached_end)
	SignalBus.enemy_defeated.connect(_on_enemy_defeated)

# ─── OVERLAY MENU FOR PLACEMENT (CIRCULAR MODE - SHOWS EQUIPPED TOWER MODELS) ───────
var overlay_menu: Control = null
var current_clicked_cell: Vector2i = Vector2i(-1, -1)
var _current_menu_cell: Vector2i = Vector2i(-1, -1)

var _tutorial_step: int = 0
var _tutorial_overlay: Control = null

func _show_tutorial() -> void:
	_tutorial_overlay = Control.new()
	_tutorial_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	$HUD/HUDControl.add_child(_tutorial_overlay)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	_tutorial_overlay.add_child(bg)

	_tutorial_step = 0
	_show_tutorial_step()

func _show_tutorial_step() -> void:
	for child in _tutorial_overlay.get_children():
		if child is ColorRect: continue
		child.queue_free()

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 220)
	card.set_anchors_preset(Control.PRESET_CENTER)
	var st := StyleBoxFlat.new()
	st.bg_color = Color("#0A1628")
	st.border_color = Color("#00D4FF")
	st.border_width_left = 2
	st.border_width_right = 2
	st.border_width_top = 2
	st.border_width_bottom = 2
	st.corner_radius_top_left = 12
	st.corner_radius_top_right = 12
	st.corner_radius_bottom_left = 12
	st.corner_radius_bottom_right = 12
	card.add_theme_stylebox_override("panel", st)
	_tutorial_overlay.add_child(card)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("margin_left", 20)
	layout.add_theme_constant_override("margin_right", 20)
	layout.add_theme_constant_override("margin_top", 20)
	layout.add_theme_constant_override("margin_bottom", 20)
	card.add_child(layout)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#00D4FF"))
	title.add_theme_font_size_override("font_size", 16)
	layout.add_child(title)

	var body := Label.new()
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", Color("#E8F4FD"))
	body.add_theme_font_size_override("font_size", 13)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)

	var steps_lbl := Label.new()
	steps_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	steps_lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	steps_lbl.add_theme_font_size_override("font_size", 10)
	layout.add_child(steps_lbl)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(160, 40)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 13)
	layout.add_child(btn)

	var tutorial_data = [
		{
			"title": "Welcome, Operator!",
			"body": "This is your first mission.\nPackets will flow along the path from left to right.\nYour job: place towers to destroy them before they reach the end."
		},
		{
			"title": "Placing Towers",
			"body": "Click on any highlighted grid cell to open the tower selector.\nChoose a tower to place it.\nEach tower costs RAM (shown on the button)."
		},
		{
			"title": "RAM & Waves",
			"body": "You earn RAM by destroying enemies and completing waves.\nUse RAM to place and upgrade towers.\nSurvive all waves with high base HP for a better grade!"
		},
		{
			"title": "Upgrading Towers",
			"body": "Click an existing tower to open its menu.\nUpgrade it to increase damage and range.\nUpgrades cost RAM — manage your budget wisely!"
		},
	]

	if _tutorial_step < tutorial_data.size():
		var d = tutorial_data[_tutorial_step]
		title.text = d["title"]
		body.text = d["body"]
		steps_lbl.text = "Step " + str(_tutorial_step + 1) + " of " + str(tutorial_data.size())
		btn.text = "Next →" if _tutorial_step < tutorial_data.size() - 1 else "Let's Go!"
		btn.pressed.connect(_on_tutorial_next)
	else:
		_tutorial_overlay.queue_free()
		_tutorial_overlay = null

func _on_tutorial_next() -> void:
	_tutorial_step += 1
	_show_tutorial_step()

func _create_overlay_menu() -> void:
	# Use Control instead of PanelContainer for custom radial layout
	overlay_menu = Control.new()
	overlay_menu.visible = false
	$HUD/HUDControl.add_child(overlay_menu)

func _on_overlay_tower_selected(tower_id: String) -> void:
	overlay_menu.visible = false
	var def = TOWER_DEFINITIONS[tower_id]
	if not ram_manager.can_afford(def["ram_cost"]):
		SignalBus.hud_message_requested.emit(
			"Not enough RAM! Need " + str(def["ram_cost"]) + " RAM.", 2.0
		)
		return
		
	selected_tower_data              = TowerData.new()
	selected_tower_data.tower_id     = def["tower_id"]
	selected_tower_data.tower_name   = def["tower_name"]
	selected_tower_data.ram_cost     = def["ram_cost"]
	selected_tower_data.damage       = def["damage"]
	selected_tower_data.attack_speed = def["attack_speed"]
	selected_tower_data.attack_range = def["attack_range"]
	selected_tower_data.color        = def["color"]
	selected_tower_data.icon_text    = def["icon_text"]
	
	_place_tower(current_clicked_cell)

# ─── GRID INTERACTION ──────────────────────────────────
func _on_cell_clicked(cell: Vector2i) -> void:
	if overlay_menu.visible and cell == _current_menu_cell:
		return
	_current_menu_cell = cell
	overlay_menu.visible = false
	for child in overlay_menu.get_children():
		child.queue_free()

	var existing = grid_system.get_tower_at(cell)
	if existing:
		_show_tower_menu(cell, existing)
		return

	if not grid_system.can_place_tower(cell):
		return

	current_clicked_cell = cell
	var cell_center = grid_system.get_cell_center(cell)
	var canvas_pos = get_canvas_transform() * cell_center
	overlay_menu.position = canvas_pos

	_show_placement_radial(cell)

func _show_tower_menu(cell: Vector2i, tower: Node) -> void:
	var cell_center = grid_system.get_cell_center(cell)
	var canvas_pos = get_canvas_transform() * cell_center
	overlay_menu.position = canvas_pos

	var margin := 10
	var btn_w := 140
	var btn_h := 26
	var sep := 4
	var title_h := 18
	var num_rows = 1 + (1 if tower.current_level < tower.max_level else 0) + 1 + 1 + 1
	var total_h = title_h + num_rows * btn_h + (num_rows + 1) * sep + margin * 2
	var total_w = btn_w + margin * 2

	var bg := Panel.new()
	bg.custom_minimum_size = Vector2(total_w, total_h)
	bg.size = Vector2(total_w, total_h)
	bg.position = Vector2(-total_w / 2, -total_h / 2)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color("#070F1E", 0.95)
	bg_style.border_color = Color("#00D4FF")
	bg_style.border_width_left = 1
	bg_style.border_width_right = 1
	bg_style.border_width_top = 1
	bg_style.border_width_bottom = 1
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	bg.add_theme_stylebox_override("panel", bg_style)
	overlay_menu.add_child(bg)

	var layout := VBoxContainer.new()
	layout.position = Vector2(margin, margin + title_h + sep)
	layout.size = Vector2(btn_w, total_h - margin * 2 - title_h - sep)
	layout.add_theme_constant_override("separation", sep)
	bg.add_child(layout)

	var lvl_lbl := Label.new()
	lvl_lbl.text = tower.tower_name + " Lv." + str(tower.current_level)
	lvl_lbl.add_theme_color_override("font_color", Color("#00D4FF"))
	lvl_lbl.add_theme_font_size_override("font_size", 11)
	lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl_lbl.position = Vector2(margin, margin)
	lvl_lbl.size = Vector2(btn_w, title_h)
	bg.add_child(lvl_lbl)

	if tower.current_level < tower.max_level:
		var cost = tower.ram_cost * tower.current_level
		var upg_btn := Button.new()
		upg_btn.text = "⬆ Upgrade (" + str(cost) + "⚡)"
		upg_btn.custom_minimum_size = Vector2(btn_w, btn_h)
		upg_btn.size = Vector2(btn_w, btn_h)
		upg_btn.add_theme_font_size_override("font_size", 10)
		if ram_manager.can_afford(cost):
			upg_btn.add_theme_color_override("font_color", Color("#00FF88"))
		else:
			upg_btn.add_theme_color_override("font_color", Color("#FF3366"))
		upg_btn.pressed.connect(_on_upgrade_tower.bind(tower, cost))
		layout.add_child(upg_btn)

	var abil_cost = tower.get_ability_cost()
	var abil_btn := Button.new()
	abil_btn.text = "⚡ " + tower.get_ability_name() + " (" + str(abil_cost) + "⚡)"
	abil_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	abil_btn.size = Vector2(btn_w, btn_h)
	abil_btn.add_theme_font_size_override("font_size", 9)
	if tower.is_ability_ready() and ram_manager.can_afford(abil_cost):
		abil_btn.add_theme_color_override("font_color", Color("#FFB800"))
	else:
		abil_btn.add_theme_color_override("font_color", Color("#4A3A1A"))
	abil_btn.pressed.connect(_on_ability_used.bind(tower, abil_cost))
	layout.add_child(abil_btn)

	var sell_value = tower.ram_cost * tower.current_level
	var sell_btn := Button.new()
	sell_btn.text = "💰 Sell (" + str(sell_value) + "⚡)"
	sell_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	sell_btn.size = Vector2(btn_w, btn_h)
	sell_btn.add_theme_font_size_override("font_size", 9)
	sell_btn.add_theme_color_override("font_color", Color("#FF8844"))
	sell_btn.pressed.connect(_on_sell_tower.bind(cell, tower, sell_value))
	layout.add_child(sell_btn)

	var close_btn := Button.new()
	close_btn.text = "✕ Close"
	close_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	close_btn.size = Vector2(btn_w, btn_h)
	close_btn.add_theme_font_size_override("font_size", 9)
	close_btn.add_theme_color_override("font_color", Color("#4A7FA5"))
	close_btn.pressed.connect(func(): overlay_menu.visible = false; _current_menu_cell = Vector2i(-1, -1))
	layout.add_child(close_btn)

	overlay_menu.visible = true

func _on_sell_tower(cell: Vector2i, tower: Node, value: int) -> void:
	ram_manager.earn(value)
	grid_system.remove_tower(cell)
	tower.queue_free()
	overlay_menu.visible = false
	SignalBus.hud_message_requested.emit("Sold! +" + str(value) + " RAM", 2.0)

func _on_upgrade_tower(tower: Node, cost: int) -> void:
	if not ram_manager.spend(cost):
		SignalBus.hud_message_requested.emit("Not enough RAM!", 2.0)
		return
	var new_lvl = tower.upgrade()
	overlay_menu.visible = false
	SignalBus.hud_message_requested.emit(tower.tower_name + " upgraded to Lv." + str(new_lvl) + "!", 2.0)

func _on_ability_used(tower: Node, cost: int) -> void:
	if not tower.is_ability_ready():
		SignalBus.hud_message_requested.emit("Ability on cooldown!", 2.0)
		return
	if not ram_manager.spend(cost):
		SignalBus.hud_message_requested.emit("Not enough RAM!", 2.0)
		return
	tower.activate_ability()
	overlay_menu.visible = false
	SignalBus.hud_message_requested.emit(tower.tower_name + " used " + tower.get_ability_name() + "!", 2.0)

func _show_placement_radial(cell: Vector2i) -> void:
	# Determine equipped towers (bring/equip from tower select)
	var equipped = GameManager.selected_towers
	if equipped.is_empty():
		equipped = _get_level_config().get("towers", [])
	if equipped.is_empty():
		# Fail-safe backup
		equipped = ["tower_array", "tower_stack", "tower_queue", "tower_linked_list", "tower_bubble"]
		
	# Build radial selection
	var num_options = equipped.size()
	var radius = 72.0
	var btn_size = 54.0
	
	for i in range(num_options):
		var tower_id = equipped[i]
		if not TOWER_DEFINITIONS.has(tower_id):
			continue
		var def = TOWER_DEFINITIONS[tower_id]
		
		# Compute angle position
		var angle = -PI/2 + (i * 2.0 * PI / num_options)
		var offset_pos = Vector2(cos(angle), sin(angle)) * radius
		
		# Generous touch target button (Works beautifully on mobile)
		var btn := TextureButton.new()
		btn.custom_minimum_size = Vector2(btn_size, btn_size)
		btn.size = Vector2(btn_size, btn_size)
		btn.position = offset_pos - Vector2(btn_size/2.0, btn_size/2.0)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_SCALE
		
		# Style circular icon container
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color("#070F1E", 0.9)
		normal_style.border_color = Color(def["color"])
		normal_style.border_width_left = 2
		normal_style.border_width_right = 2
		normal_style.border_width_top = 2
		normal_style.border_width_bottom = 2
		normal_style.corner_radius_top_left = int(btn_size / 2.0)
		normal_style.corner_radius_top_right = int(btn_size / 2.0)
		normal_style.corner_radius_bottom_left = int(btn_size / 2.0)
		normal_style.corner_radius_bottom_right = int(btn_size / 2.0)
		
		# Display StyleBox as backdrop on the button using a Panel
		var bg_panel := Panel.new()
		bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg_panel.add_theme_stylebox_override("panel", normal_style)
		btn.add_child(bg_panel)
		
		# Create a sub-viewport or small instanced tower that displays the actual model directly!
		# Since Godot 4 allows us to put Node2D inside Control using a Node2D container or directly,
		# let's instantiate the actual tower scene directly inside the button as a lightweight visual node.
		var tower_scene = load("res://scenes/campaign/towers/Tower.tscn")
		var visual_tower = tower_scene.instantiate()
		
		# Initialize visual tower node
		var dummy_data = TowerData.new()
		dummy_data.tower_id = def["tower_id"]
		dummy_data.tower_name = def["tower_name"]
		dummy_data.ram_cost = def["ram_cost"]
		dummy_data.damage = def["damage"]
		dummy_data.attack_speed = def["attack_speed"]
		dummy_data.attack_range = def["attack_range"]
		dummy_data.color = def["color"]
		dummy_data.icon_text = def["icon_text"]
		
		visual_tower.initialize(dummy_data, Vector2i(-1, -1), null)
		visual_tower.position = Vector2(btn_size / 2.0, btn_size / 2.0)
		
		# Scale down model nicely so it fits perfect in the circular button
		visual_tower.scale = Vector2(0.5, 0.5)
		
		# Strip game behaviors from visual preview model
		visual_tower.set_process(false)
		visual_tower.set_physics_process(false)
		visual_tower.set_process_input(false)
		
		btn.add_child(visual_tower)
		
		# Price Tag (small overlay at the bottom of the node)
		var price_lbl := Label.new()
		price_lbl.text = str(def["ram_cost"])
		price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_lbl.add_theme_font_size_override("font_size", 8)
		price_lbl.add_theme_color_override("font_color", Color("#00D4FF"))
		price_lbl.position = Vector2(0, btn_size - 8)
		price_lbl.custom_minimum_size = Vector2(btn_size, 10)
		price_lbl.size = Vector2(btn_size, 10)
		price_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(price_lbl)
		
		# Connect trigger action
		btn.pressed.connect(_on_overlay_tower_selected.bind(tower_id))
		overlay_menu.add_child(btn)
		
	# Small Central "Close" Button
	var center_close := Button.new()
	center_close.text = "X"
	center_close.custom_minimum_size = Vector2(24, 24)
	center_close.size = Vector2(24, 24)
	center_close.position = Vector2(-12, -12)
	center_close.add_theme_color_override("font_color", Color("#FF3366"))
	center_close.add_theme_font_size_override("font_size", 9)
	
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color("#12050E")
	close_style.border_color = Color("#FF3366")
	close_style.border_width_left = 1
	close_style.border_width_right = 1
	close_style.border_width_top = 1
	close_style.border_width_bottom = 1
	close_style.corner_radius_top_left = 12
	close_style.corner_radius_top_right = 12
	close_style.corner_radius_bottom_left = 12
	close_style.corner_radius_bottom_right = 12
	center_close.add_theme_stylebox_override("normal", close_style)
	
	center_close.pressed.connect(func(): overlay_menu.visible = false; _current_menu_cell = Vector2i(-1, -1))
	overlay_menu.add_child(center_close)
	
	# Clamp positions of buttons inside screen borders for mobile viewports
	var screen_size = get_viewport_rect().size
	var menu_offset_x = clamp(overlay_menu.position.x, 90.0, screen_size.x - 90.0) - overlay_menu.position.x
	var menu_offset_y = clamp(overlay_menu.position.y, 90.0, screen_size.y - 90.0) - overlay_menu.position.y
	overlay_menu.position += Vector2(menu_offset_x, menu_offset_y)
	
	overlay_menu.visible = true

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
	
	grid_system.first_tower_placed.emit(selected_tower_data.tower_id)

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

# ─── PROCESS ───────────────────────────────────────────
func _process(delta: float) -> void:
	if countdown_active and not is_level_ended:
		wave_countdown -= delta
		if wave_countdown <= 0.0:
			wave_countdown = 0.0
			countdown_active = false
			_trigger_wave_start()
	_update_wave_progress_bar()

func _trigger_wave_start() -> void:
	if wave_manager.wave_in_progress or is_level_ended:
		return
	wave_manager.start_next_wave()

func _update_wave_progress_bar() -> void:
	if is_level_ended:
		skip_wave_btn.disabled = true
		return

	var total_waves = wave_manager.total_waves
	var current_wave = wave_manager.current_wave

	if wave_manager.wave_in_progress:
		wave_progress_bar.value = float(current_wave)
		skip_wave_btn.disabled = true
	else:
		if current_wave >= total_waves:
			wave_progress_bar.value = float(total_waves)
			skip_wave_btn.disabled = true
		else:
			var progress_frac = 1.0 - (wave_countdown / INTER_WAVE_DURATION)
			wave_progress_bar.value = float(current_wave) + progress_frac
			skip_wave_btn.disabled = false

func _show_wave_splash_animation(wave_num: int) -> void:
	wave_splash_label.text = "WAVE %d" % wave_num
	wave_splash_label.modulate = Color("#00FF88")
	wave_splash_label.scale = Vector2(0.5, 0.5)
	wave_splash_label.pivot_offset = wave_splash_label.size / 2.0
	wave_splash.visible = true
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(wave_splash_label, "modulate:a", 1.0, 0.4).from(0.0)
	tween.tween_property(wave_splash_label, "scale", Vector2(1.2, 1.2), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var seq = create_tween()
	seq.tween_interval(1.2)
	seq.tween_property(wave_splash_label, "modulate:a", 0.0, 0.4)
	seq.tween_callback(func(): wave_splash.visible = false)

# ─── INPUT ─────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_pause_pressed()

# ─── PAUSE HANDLERS ────────────────────────────────────
func _on_pause_pressed() -> void:
	get_tree().paused = true
	pause_menu.visible = true

func _on_resume_pressed() -> void:
	get_tree().paused = false
	pause_menu.visible = false

func _on_select_level_pressed() -> void:
	get_tree().paused = false
	GameManager.go_to("campaign")

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	GameManager.go_to("main_menu")

func _on_skip_wave_pressed() -> void:
	if wave_manager.wave_in_progress or is_level_ended:
		return
	if ram_manager.spend(20):
		wave_countdown = 0.0
		countdown_active = false
		_trigger_wave_start()
	else:
		SignalBus.hud_message_requested.emit("Not enough RAM to skip! (costs 20)", 2.0)

# ─── SIGNAL HANDLERS ───────────────────────────────────
func _on_ram_changed(_current: int, _max_ram: int) -> void:
	_update_ram_label()

func _on_wave_started(wave_num: int, total: int) -> void:
	wave_label.text = "Wave: " + str(wave_num) + "/" + str(total)
	countdown_active = false
	_show_wave_splash_animation(wave_num)
	SignalBus.hud_message_requested.emit(
		"⚔️ Wave " + str(wave_num) + " incoming!", 2.0
	)

func _on_wave_completed(wave_num: int) -> void:
	score            += 100 * wave_num
	score_label.text  = "Score: " + str(score)
	ram_manager.earn(50)
	wave_countdown = INTER_WAVE_DURATION
	countdown_active = true
	SignalBus.hud_message_requested.emit(
		"✅ Wave " + str(wave_num) + " complete! +50 RAM", 3.0
	)

func _get_stars() -> int:
	if base_health >= 9:
		return 3
	elif base_health >= 6:
		return 2
	return 1

func _on_all_waves_completed() -> void:
	if is_level_ended:
		return
	is_level_ended = true
	var elapsed = (Time.get_ticks_msec() / 1000.0) - level_start_time
	var stars = _get_stars()
	ProgressManager.set_level_stars(level_number, stars)
	ProgressManager.on_level_completed(level_number)
	SupabaseManager.submit_campaign_score(level_number, elapsed, score)
	_show_result_panel(true)

func _on_enemy_reached_end(_enemy_id: String) -> void:
	if is_level_ended:
		return
	base_health -= 1
	_update_base_health_label()
	if base_health <= 0:
		is_level_ended = true
		AdaptiveAI.record_level_performance("F", 0, 0.0)
		_show_result_panel(false)

func _on_enemy_defeated(_enemy_id: String) -> void:
	ram_manager.earn(10)
	score            += 10
	score_label.text  = "Score: " + str(score)

# ─── BASE HEALTH ───────────────────────────────────────
func heal_base(amount: int) -> void:
	"""Heal the base by the given amount"""
	base_health = min(base_health + amount, 10)
	_update_base_health_label()
	SignalBus.hud_message_requested.emit("💚 Base healed! HP: " + str(base_health) + "/10", 2.0)

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
		var stars = _get_stars()
		var star_str = ""
		for s in range(3):
			star_str += "⭐" if s < stars else "☆"
		var star_lbl := Label.new()
		star_lbl.text = star_str
		star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_lbl.add_theme_font_size_override("font_size", 28)
		layout.add_child(star_lbl)
		SignalBus.level_complete.emit(level_number, score, stars)

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
	var top_style := StyleBoxEmpty.new()
	$HUD/HUDControl/TopHUD.add_theme_stylebox_override("panel", top_style)

	# Left panel styling removed

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

	var pause_menu_style := StyleBoxFlat.new()
	pause_menu_style.bg_color                    = Color("#050D1A")
	pause_menu_style.border_color                = Color("#00D4FF")
	pause_menu_style.border_width_left           = 1
	pause_menu_style.border_width_right          = 1
	pause_menu_style.border_width_top            = 1
	pause_menu_style.border_width_bottom         = 1
	pause_menu_style.corner_radius_top_left      = 8
	pause_menu_style.corner_radius_top_right     = 8
	pause_menu_style.corner_radius_bottom_left   = 8
	pause_menu_style.corner_radius_bottom_right  = 8
	pause_menu.add_theme_stylebox_override("panel", pause_menu_style)

	var pause_btn_style := StyleBoxFlat.new()
	pause_btn_style.bg_color                   = Color("#0A1628")
	pause_btn_style.border_color               = Color("#00D4FF")
	pause_btn_style.border_width_left          = 1
	pause_btn_style.border_width_right         = 1
	pause_btn_style.border_width_top           = 1
	pause_btn_style.border_width_bottom        = 1
	pause_btn_style.corner_radius_top_left     = 4
	pause_btn_style.corner_radius_top_right    = 4
	pause_btn_style.corner_radius_bottom_left  = 4
	pause_btn_style.corner_radius_bottom_right = 4
	pause_btn.add_theme_stylebox_override("normal", pause_btn_style)
	pause_btn.add_theme_color_override("font_color", Color("#00D4FF"))

	var skip_btn_style := StyleBoxFlat.new()
	skip_btn_style.bg_color                   = Color("#FFB800")
	skip_btn_style.corner_radius_top_left     = 4
	skip_btn_style.corner_radius_top_right    = 4
	skip_btn_style.corner_radius_bottom_left  = 4
	skip_btn_style.corner_radius_bottom_right = 4
	skip_wave_btn.add_theme_stylebox_override("normal", skip_btn_style)
	skip_wave_btn.add_theme_color_override("font_color", Color("#050D1A"))

	var bg_bar_style := StyleBoxFlat.new()
	bg_bar_style.bg_color = Color("#050D1A")
	bg_bar_style.corner_radius_top_left = 4
	bg_bar_style.corner_radius_top_right = 4
	bg_bar_style.corner_radius_bottom_left = 4
	bg_bar_style.corner_radius_bottom_right = 4
	wave_progress_bar.add_theme_stylebox_override("background", bg_bar_style)

	var fill_bar_style := StyleBoxFlat.new()
	fill_bar_style.bg_color = Color("#00FF88")
	fill_bar_style.corner_radius_top_left = 4
	fill_bar_style.corner_radius_top_right = 4
	fill_bar_style.corner_radius_bottom_left = 4
	fill_bar_style.corner_radius_bottom_right = 4
	wave_progress_bar.add_theme_stylebox_override("fill", fill_bar_style)

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
