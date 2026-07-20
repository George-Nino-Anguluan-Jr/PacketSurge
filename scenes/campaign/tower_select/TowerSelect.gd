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
@onready var available_grid: GridContainer  = $ContentArea/RightMargin/RightContent/ScrollContainer/AvailableGrid
@onready var start_btn: Button              = $ContentArea/RightMargin/RightContent/StartBtn
@onready var card_layer: Control            = $CardLayer

# ─── STATE ─────────────────────────────────────────────
var level_config: Dictionary = {}
var level_number: int        = 1
var max_slots: int           = 5 # ALWAYS 5 SELECTED SLOTS FOR ANY LEVEL
var selected_towers: Array   = []
var available_towers: Array  = [] # Holds all unlocked towers

# Floating Card instances
var active_cards: Array = []

# Intro popup
var _intro_popup: Control = null

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
	max_slots       = 5 # Fixed 5 tower slots for any level
	selected_towers = []

	_setup_buttons()
	_apply_styles()
	_build_left_panel()
	
	# Determine unlocked towers first to build placeholders correctly
	_determine_unlocked_towers()
	_build_placeholders()
	
	# Wait one frame so that container layouts solve and positions are valid
	await get_tree().process_frame
	_build_tower_cards()
	_refresh_slots()
	_refresh_start_btn()
	_setup_intro_popup()

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

# ─── DETERMINE UNLOCKED TOWERS ─────────────────────────
func _determine_unlocked_towers() -> void:
	available_towers = []
	for t in TOWER_DEFINITIONS.keys():
		if ProgressManager.is_tower_unlocked(t):
			available_towers.append(t)

# ─── PLACEHOLDERS ──────────────────────────────────────
func _build_placeholders() -> void:
	# Clear layout rows
	for child in selected_row.get_children():
		child.queue_free()
	for child in available_grid.get_children():
		child.queue_free()
		
	# 1. Selected Slot Placeholders (Exactly 5 slots)
	for i in range(max_slots):
		var p_slot := PanelContainer.new()
		p_slot.custom_minimum_size = Vector2(96, 130)
		p_slot.name = "SelectedSlot_" + str(i)
		
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#0A1628", 0.3)
		style.border_color = Color("#1A3A5A")
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		p_slot.add_theme_stylebox_override("panel", style)
		
		var lbl := Label.new()
		lbl.text = "+"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_color", Color("#1A3A5A"))
		p_slot.add_child(lbl)
		
		selected_row.add_child(p_slot)
		
	# 2. Available Slot Placeholders (Matching number of unlocked towers)
	for i in range(available_towers.size()):
		var p_slot := PanelContainer.new()
		p_slot.custom_minimum_size = Vector2(96, 130)
		p_slot.name = "AvailableSlot_" + str(i)
		
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#030A14", 0.5)
		style.border_color = Color("#0F2238")
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		p_slot.add_theme_stylebox_override("panel", style)
		
		available_grid.add_child(p_slot)

# ─── TOWER CARD PREPARATION ────────────────────────────
func _build_tower_cards() -> void:
	for c in active_cards:
		if is_instance_valid(c):
			c.queue_free()
	active_cards.clear()

	var required = level_config.get("required_towers", [])
	var new_towers = ProgressManager.get_new_unlocked_towers()

	selected_towers = []
	for t in required:
		if available_towers.has(t):
			selected_towers.append(t)

	var card_scene = preload("res://scenes/campaign/tower_select/TowerCard.tscn")

	for i in range(available_towers.size()):
		var tower_id = available_towers[i]
		var def = TOWER_DEFINITIONS[tower_id]
		var is_req = tower_id in required

		var card = card_scene.instantiate()
		card_layer.add_child(card)
		card.setup(tower_id, def, is_req)
		card.set_new(tower_id in new_towers)

		card.clicked.connect(_on_card_clicked)
		card.drag_started.connect(_on_card_drag_started)
		card.drag_ended.connect(_on_card_drag_ended)
		card.info_requested.connect(_on_card_info_requested)

		var anchor = available_grid.get_child(i)
		card.home_position = anchor.global_position

		if is_req:
			var slot_idx = selected_towers.find(tower_id)
			if slot_idx != -1 and slot_idx < max_slots:
				card.current_slot_idx = slot_idx
				card.set_selected(true)
				card.global_position = selected_row.get_child(slot_idx).global_position
			else:
				card.global_position = card.home_position
		else:
			card.global_position = card.home_position

		active_cards.append(card)

# ─── SELECTION LOGIC ───────────────────────────────────
func _on_card_clicked(tower_id: String) -> void:
	var card = _get_card_by_id(tower_id)
	if not card or card.is_required:
		return
		
	if card.is_selected:
		# Deselect: return home
		selected_towers.erase(tower_id)
		card.current_slot_idx = -1
		card.set_selected(false)
		card.animate_to(card.home_position)
	else:
		# Select: find first open selected placeholder slot
		var open_idx = _get_first_empty_slot_idx()
		if open_idx == -1:
			SignalBus.hud_message_requested.emit(
				"Only " + str(max_slots) + " tower slots allowed!", 2.0
			)
			return
			
		selected_towers.append(tower_id)
		card.current_slot_idx = open_idx
		card.set_selected(true)
		
		var target_pos = selected_row.get_child(open_idx).global_position
		card.animate_to(target_pos)
		
	_refresh_slots()
	_refresh_start_btn()

# ─── DRAG & DROP RESOLUTION ─────────────────────────────
func _on_card_drag_started(card) -> void:
	# Temporarily lift card from any previous slot calculations to avoid double assignments
	if card.is_selected:
		selected_towers.erase(card.tower_id)
		card.current_slot_idx = -1
		card.set_selected(false)
		_refresh_slots()
		_refresh_start_btn()

func _on_card_drag_ended(card, _release_pos: Vector2) -> void:
	# Find closest selected slot placeholder within snapping distance
	var closest_slot_idx = -1
	var min_dist = 64.0 # Maximum drop-snapping radius in pixels
	
	for i in range(max_slots):
		var placeholder = selected_row.get_child(i)
		var dist = card.global_position.distance_to(placeholder.global_position)
		if dist < min_dist:
			min_dist = dist
			closest_slot_idx = i
			
	if closest_slot_idx != -1:
		# We dropped it near a slot! Let's check if another card is already occupying this slot
		var existing_card = _get_card_in_slot(closest_slot_idx)
		if existing_card:
			# Displace/kick back the existing card home to keep it super clean!
			selected_towers.erase(existing_card.tower_id)
			existing_card.current_slot_idx = -1
			existing_card.set_selected(false)
			existing_card.animate_to(existing_card.home_position)
			
		# Snap this card to the slot!
		selected_towers.append(card.tower_id)
		card.current_slot_idx = closest_slot_idx
		card.set_selected(true)
		card.animate_to(selected_row.get_child(closest_slot_idx).global_position, 0.2)
	else:
		# Return home safely
		card.animate_to(card.home_position, 0.3)
		
	_refresh_slots()
	_refresh_start_btn()

# ─── TOWER INTRO POPUP ────────────────────────────────
func _setup_intro_popup() -> void:
	var scene = preload("res://scenes/campaign/tower_intro/TowerIntroPopup.tscn")
	_intro_popup = scene.instantiate()
	add_child(_intro_popup)
	_intro_popup.hide()
	_intro_popup.closed.connect(_on_intro_closed)

func _on_card_info_requested(tower_id: String) -> void:
	if _intro_popup:
		_intro_popup.show_for(tower_id)
		_intro_popup.set_meta("viewing_tower", tower_id)

func _on_intro_closed() -> void:
	var viewed = _intro_popup.get_meta("viewing_tower", "")
	if viewed == "":
		return
	for c in active_cards:
		if is_instance_valid(c) and c.tower_id == viewed and c._is_new:
			c.set_new(false)
			ProgressManager.mark_tower_seen(viewed)
			break

# ─── HELPER METHODS ────────────────────────────────────
func _get_card_by_id(tower_id: String):
	for c in active_cards:
		if c.tower_id == tower_id:
			return c
	return null

func _get_card_in_slot(slot_idx: int):
	for c in active_cards:
		if c.current_slot_idx == slot_idx:
			return c
	return null

func _get_first_empty_slot_idx() -> int:
	for i in range(max_slots):
		if _get_card_in_slot(i) == null:
			return i
	return -1

func _refresh_slots() -> void:
	slot_label.text = "SELECTED TOWERS (" + \
		str(selected_towers.size()) + "/" + str(max_slots) + ")"

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
