# TowerSelect.gd
extends Control

# ─── NODE REFERENCES ───────────────────────────────────
@onready var back_btn: Button               = $TopBar/TopBarLayout/BackBtn
@onready var title_label: Label             = $TopBar/TopBarLayout/TitleLabel
@onready var level_name_label: Label        = $ContentArea/LeftMargin/LeftContent/LevelNameLabel
@onready var concept_content: VBoxContainer = $ContentArea/LeftMargin/LeftContent/ConceptPanel/ConceptMargin/ConceptContent
@onready var enemy_tip_content: VBoxContainer = $ContentArea/LeftMargin/LeftContent/EnemyTipPanel/EnemyTipMargin/EnemyTipContent
@onready var stats_content: VBoxContainer   = $ContentArea/LeftMargin/LeftContent/StatsPanel/StatsMargin/StatsContent
@onready var slot_label: Label              = $ContentArea/RightMargin/RightContent/SlotLabel
@onready var selected_row: HBoxContainer    = $ContentArea/RightMargin/RightContent/SelectedRow
@onready var available_grid: GridContainer  = $ContentArea/RightMargin/RightContent/AvailableGrid
@onready var start_btn: Button              = $ContentArea/RightMargin/RightContent/StartBtn

# ─── STATE ─────────────────────────────────────────────
var level_config: Dictionary = {}
var level_number: int        = 1
var max_slots: int           = 2
var selected_towers: Array   = []
var available_towers: Array  = []

# ─── TOWER DEFINITIONS ─────────────────────────────────
const TOWER_DEFINITIONS = {
	"tower_array": {
		"tower_name":  "Array Tower",
		"description": "Fast. O(1) access.",
		"ram_cost":    40,
		"color":       Color("#00D4FF"),
		"icon_text":   "[ ]",
	},
	"tower_stack": {
		"tower_name":  "Stack Tower",
		"description": "High damage. LIFO.",
		"ram_cost":    60,
		"color":       Color("#FF6B35"),
		"icon_text":   "↑↓",
	},
	"tower_queue": {
		"tower_name":  "Queue Tower",
		"description": "Pierces 2. FIFO.",
		"ram_cost":    60,
		"color":       Color("#9B59B6"),
		"icon_text":   "→",
	},
	"tower_linked_list": {
		"tower_name":  "Linked Tower",
		"description": "Chain hits 3.",
		"ram_cost":    80,
		"color":       Color("#00FF88"),
		"icon_text":   "→→",
	},
	"tower_bubble": {
		"tower_name":  "Bubble Tower",
		"description": "AoE all enemies.",
		"ram_cost":    70,
		"color":       Color("#FFB800"),
		"icon_text":   "↑↑",
	},
	"tower_selection": {
		"tower_name":  "Selection Tower",
		"description": "Targets lowest HP.",
		"ram_cost":    90,
		"color":       Color("#E74C3C"),
		"icon_text":   "→↓",
	},
	"tower_insertion": {
		"tower_name":  "Insertion Tower",
		"description": "Damage over time.",
		"ram_cost":    100,
		"color":       Color("#1ABC9C"),
		"icon_text":   "←↑",
	},
	"tower_quick": {
		"tower_name":  "Quick Tower",
		"description": "Splits shot to 2.",
		"ram_cost":    130,
		"color":       Color("#E91E63"),
		"icon_text":   "⚡",
	},
	"tower_merge": {
		"tower_name":  "Merge Tower",
		"description": "Guaranteed AoE.",
		"ram_cost":    140,
		"color":       Color("#3F51B5"),
		"icon_text":   "⊕",
	},
	"tower_counting": {
		"tower_name":  "Count Tower",
		"description": "Stronger in groups.",
		"ram_cost":    110,
		"color":       Color("#009688"),
		"icon_text":   "#",
	},
	"tower_radix": {
		"tower_name":  "Radix Tower",
		"description": "Rapid multi-pass.",
		"ram_cost":    150,
		"color":       Color("#FF5722"),
		"icon_text":   "0→9",
	},
	"tower_linear": {
		"tower_name":  "Linear Tower",
		"description": "Wide scan range.",
		"ram_cost":    80,
		"color":       Color("#607D8B"),
		"icon_text":   "→?",
	},
	"tower_binary": {
		"tower_name":  "Binary Tower",
		"description": "Precision sniper.",
		"ram_cost":    200,
		"color":       Color("#8BC34A"),
		"icon_text":   "½",
	},
}

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	level_number    = GameManager.current_level
	level_config    = _get_level_config()
	max_slots       = level_config.get("tower_slots", 2)
	selected_towers = []

	# Required towers pre-selected and locked in
	var required = level_config.get("required_towers", [])
	for t in required:
		if ProgressManager.is_tower_unlocked(t):
			selected_towers.append(t)

	_setup_buttons()
	_apply_styles()
	_build_left_panel()
	_build_available_list()
	_refresh_selected_row()
	_refresh_start_btn()

# ─── LEFT PANEL ────────────────────────────────────────
func _build_left_panel() -> void:
	level_name_label.text = "Level " + str(level_number) + \
		" — " + level_config.get("name", "")

	# Concept
	for child in concept_content.get_children():
		child.queue_free()

	var concept_title := Label.new()
	concept_title.text = "📚 " + level_config.get("concept", "")
	concept_title.add_theme_font_size_override("font_size", 14)
	concept_title.add_theme_color_override("font_color", Color("#00D4FF"))
	concept_content.add_child(concept_title)

	var concept_desc := Label.new()
	concept_desc.text = level_config.get("concept_desc", "")
	concept_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	concept_desc.add_theme_font_size_override("font_size", 12)
	concept_desc.add_theme_color_override("font_color", Color("#E8F4FD"))
	concept_content.add_child(concept_desc)

	# Enemy tip
	for child in enemy_tip_content.get_children():
		child.queue_free()

	var tip_title := Label.new()
	tip_title.text = "⚠️ Enemy Warning"
	tip_title.add_theme_font_size_override("font_size", 13)
	tip_title.add_theme_color_override("font_color", Color("#FFB800"))
	enemy_tip_content.add_child(tip_title)

	var tip_desc := Label.new()
	tip_desc.text = level_config.get("enemy_tip", "")
	tip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_desc.add_theme_font_size_override("font_size", 12)
	tip_desc.add_theme_color_override("font_color", Color("#E8F4FD"))
	enemy_tip_content.add_child(tip_desc)

	# Stats
	for child in stats_content.get_children():
		child.queue_free()

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 24)
	_add_stat(stats_row, "WAVES",
		str(level_config.get("waves", 3)), Color("#00D4FF"))
	_add_stat(stats_row, "START RAM",
		str(level_config.get("start_ram", 150)) + " RAM", Color("#FFB800"))
	_add_stat(stats_row, "TOWER SLOTS",
		str(max_slots), Color("#00FF88"))
	stats_content.add_child(stats_row)

func _add_stat(
		container: HBoxContainer,
		label: String,
		value: String,
		color: Color) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)

	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 20)
	val.add_theme_color_override("font_color", color)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(val)

	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(lbl)

	container.add_child(col)

# ─── AVAILABLE TOWERS GRID ─────────────────────────────
func _build_available_list() -> void:
	for child in available_grid.get_children():
		child.queue_free()

	var config_towers = level_config.get("towers", [])
	available_towers  = []

	for tower_id in config_towers:
		if not ProgressManager.is_tower_unlocked(tower_id):
			continue
		if not TOWER_DEFINITIONS.has(tower_id):
			continue
		available_towers.append(tower_id)

		var def          = TOWER_DEFINITIONS[tower_id]
		var btn          := Button.new()
		btn.custom_minimum_size = Vector2(90, 90)
		btn.name         = tower_id

		var is_required  = tower_id in level_config.get("required_towers", [])
		var is_selected  = selected_towers.has(tower_id)

		_style_tower_card(btn, def, is_selected, is_required)

		if is_required:
			btn.disabled     = true
			btn.tooltip_text = "Required for this level"
		else:
			btn.pressed.connect(_on_tower_card_pressed.bind(tower_id))

		available_grid.add_child(btn)

func _style_tower_card(
		btn: Button,
		def: Dictionary,
		is_selected: bool,
		is_required: bool) -> void:
	var color = Color(def["color"])
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.content_margin_left   = 8
	style.content_margin_right  = 8
	style.content_margin_top    = 8
	style.content_margin_bottom = 8

	if is_required:
		style.bg_color     = Color(color, 0.3)
		style.border_color = color
		btn.text = def["icon_text"] + "\n" + \
			def["tower_name"].replace(" Tower", "") + \
			"\n🔒 REQUIRED"
	elif is_selected:
		style.bg_color     = Color(color, 0.25)
		style.border_color = color
		btn.text = def["icon_text"] + "\n" + \
			def["tower_name"].replace(" Tower", "") + \
			"\n✅ SELECTED"
	else:
		style.bg_color     = Color("#0A1628")
		style.border_color = Color("#1A3A5A")
		btn.text = def["icon_text"] + "\n" + \
			def["tower_name"].replace(" Tower", "") + \
			"\n" + str(def["ram_cost"]) + " RAM"

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override(
		"font_color",
		color if (is_selected or is_required) else Color("#4A7FA5")
	)
	btn.add_theme_font_size_override("font_size", 11)

# ─── TOWER SELECTION LOGIC ─────────────────────────────
func _on_tower_card_pressed(tower_id: String) -> void:
	if selected_towers.has(tower_id):
		selected_towers.erase(tower_id)
	else:
		if selected_towers.size() >= max_slots:
			SignalBus.hud_message_requested.emit(
				"Only " + str(max_slots) + " tower slots for this level!", 2.0
			)
			return
		selected_towers.append(tower_id)

	_refresh_available_grid()
	_refresh_selected_row()
	_refresh_start_btn()

func _refresh_available_grid() -> void:
	for btn in available_grid.get_children():
		var tower_id = btn.name
		if not TOWER_DEFINITIONS.has(tower_id):
			continue
		var def      = TOWER_DEFINITIONS[tower_id]
		var is_req   = tower_id in level_config.get("required_towers", [])
		var is_sel   = selected_towers.has(tower_id)
		_style_tower_card(btn, def, is_sel, is_req)

func _refresh_selected_row() -> void:
	for child in selected_row.get_children():
		child.queue_free()

	slot_label.text = "SELECTED TOWERS (" + \
		str(selected_towers.size()) + "/" + str(max_slots) + ")"

	# Filled slots
	for tower_id in selected_towers:
		if not TOWER_DEFINITIONS.has(tower_id):
			continue
		var def   = TOWER_DEFINITIONS[tower_id]
		var color = Color(def["color"])
		var card  := PanelContainer.new()
		card.custom_minimum_size = Vector2(80, 80)

		var style := StyleBoxFlat.new()
		style.bg_color            = Color(color, 0.2)
		style.border_color        = color
		style.border_width_left   = 2
		style.border_width_right  = 2
		style.border_width_top    = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left     = 6
		style.corner_radius_top_right    = 6
		style.corner_radius_bottom_left  = 6
		style.corner_radius_bottom_right = 6
		card.add_theme_stylebox_override("panel", style)

		var lbl := Label.new()
		lbl.text = def["icon_text"] + "\n" + \
			def["tower_name"].replace(" Tower", "")
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", color)
		card.add_child(lbl)
		selected_row.add_child(card)

	# Empty slots
	for i in range(max_slots - selected_towers.size()):
		var empty := PanelContainer.new()
		empty.custom_minimum_size = Vector2(80, 80)

		var style := StyleBoxFlat.new()
		style.bg_color            = Color("#0A1628")
		style.border_color        = Color("#1A3A5A")
		style.border_width_left   = 2
		style.border_width_right  = 2
		style.border_width_top    = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left     = 6
		style.corner_radius_top_right    = 6
		style.corner_radius_bottom_left  = 6
		style.corner_radius_bottom_right = 6
		empty.add_theme_stylebox_override("panel", style)

		var lbl := Label.new()
		lbl.text = "+"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_color", Color("#1A3A5A"))
		empty.add_child(lbl)
		selected_row.add_child(empty)

func _refresh_start_btn() -> void:
	var required         = level_config.get("required_towers", [])
	var has_all_required = true

	for t in required:
		if not selected_towers.has(t):
			has_all_required = false
			break

	start_btn.disabled = not has_all_required

	if has_all_required:
		start_btn.text = "▶ START LEVEL"
	else:
		var missing = []
		for t in required:
			if not selected_towers.has(t):
				if TOWER_DEFINITIONS.has(t):
					missing.append(TOWER_DEFINITIONS[t]["tower_name"])
		start_btn.text = "⚠️ Add: " + ", ".join(missing)

# ─── BUTTONS ───────────────────────────────────────────
func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	start_btn.pressed.connect(_on_start_pressed)

func _on_back_pressed() -> void:
	GameManager.go_to("campaign")

func _on_start_pressed() -> void:
	if selected_towers.is_empty():
		SignalBus.hud_message_requested.emit(
			"Select at least one tower!", 2.0
		)
		return
	GameManager.selected_towers = selected_towers
	GameManager.go_to("level")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

# ─── LEVEL CONFIG ──────────────────────────────────────
func _get_level_config() -> Dictionary:
	if GameManager.LEVEL_CONFIGS.has(level_number):
		return GameManager.LEVEL_CONFIGS[level_number]
	return GameManager.LEVEL_CONFIGS[1]

# ─── STYLES ────────────────────────────────────────────
func _apply_styles() -> void:
	# TopBar
	var top_style := StyleBoxFlat.new()
	top_style.bg_color            = Color("#0A1628")
	top_style.border_color        = Color("#00D4FF")
	top_style.border_width_bottom = 1
	$TopBar.add_theme_stylebox_override("panel", top_style)

	# Back button
	var back_style := StyleBoxFlat.new()
	back_style.bg_color               = Color("#0A1628")
	back_style.border_color           = Color("#00D4FF")
	back_style.border_width_left      = 1
	back_style.border_width_right     = 1
	back_style.border_width_top       = 1
	back_style.border_width_bottom    = 1
	back_style.corner_radius_top_left     = 4
	back_style.corner_radius_top_right    = 4
	back_style.corner_radius_bottom_left  = 4
	back_style.corner_radius_bottom_right = 4
	back_btn.add_theme_stylebox_override("normal", back_style)
	back_btn.add_theme_color_override("font_color", Color("#00D4FF"))

	# Concept panel
	var concept_style := StyleBoxFlat.new()
	concept_style.bg_color               = Color("#0A1628")
	concept_style.border_color           = Color("#00D4FF")
	concept_style.border_width_left      = 1
	concept_style.border_width_right     = 1
	concept_style.border_width_top       = 1
	concept_style.border_width_bottom    = 1
	concept_style.corner_radius_top_left     = 6
	concept_style.corner_radius_top_right    = 6
	concept_style.corner_radius_bottom_left  = 6
	concept_style.corner_radius_bottom_right = 6
	$ContentArea/LeftMargin/LeftContent/ConceptPanel.add_theme_stylebox_override(
		"panel", concept_style
	)

	# Enemy tip panel
	var tip_style := StyleBoxFlat.new()
	tip_style.bg_color               = Color("#1A1000")
	tip_style.border_color           = Color("#FFB800")
	tip_style.border_width_left      = 1
	tip_style.border_width_right     = 1
	tip_style.border_width_top       = 1
	tip_style.border_width_bottom    = 1
	tip_style.corner_radius_top_left     = 6
	tip_style.corner_radius_top_right    = 6
	tip_style.corner_radius_bottom_left  = 6
	tip_style.corner_radius_bottom_right = 6
	$ContentArea/LeftMargin/LeftContent/EnemyTipPanel.add_theme_stylebox_override(
		"panel", tip_style
	)

	# Stats panel
	var stats_style := StyleBoxFlat.new()
	stats_style.bg_color               = Color("#0A1628")
	stats_style.border_color           = Color("#1A3A5A")
	stats_style.border_width_left      = 1
	stats_style.border_width_right     = 1
	stats_style.border_width_top       = 1
	stats_style.border_width_bottom    = 1
	stats_style.corner_radius_top_left     = 6
	stats_style.corner_radius_top_right    = 6
	stats_style.corner_radius_bottom_left  = 6
	stats_style.corner_radius_bottom_right = 6
	$ContentArea/LeftMargin/LeftContent/StatsPanel.add_theme_stylebox_override(
		"panel", stats_style
	)

	# Start button
	var start_style := StyleBoxFlat.new()
	start_style.bg_color                 = Color("#00D4FF")
	start_style.corner_radius_top_left     = 6
	start_style.corner_radius_top_right    = 6
	start_style.corner_radius_bottom_left  = 6
	start_style.corner_radius_bottom_right = 6
	start_btn.add_theme_stylebox_override("normal", start_style)
	start_btn.add_theme_color_override("font_color", Color("#050D1A"))
	start_btn.add_theme_font_size_override("font_size", 16)
