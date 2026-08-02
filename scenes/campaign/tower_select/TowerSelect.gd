# TowerSelect.gd
extends Control

# ─── NODE REFERENCES ───────────────────────────────────
@onready var back_btn: Button               = $TopBar/TopBarLayout/BackBtn
@onready var title_label: Label             = $TopBar/TopBarLayout/TitleLabel
@onready var level_name_label: Label        = $OuterScroll/ContentArea/LeftMargin/LeftContent/LevelNameLabel
@onready var concept_content: VBoxContainer = $OuterScroll/ContentArea/LeftMargin/LeftContent/ConceptPanel/ConceptMargin/ConceptContent
@onready var enemy_tip_content: VBoxContainer = $OuterScroll/ContentArea/LeftMargin/LeftContent/EnemyTipPanel/EnemyTipMargin/EnemyTipContent
@onready var stats_content: VBoxContainer   = $OuterScroll/ContentArea/LeftMargin/LeftContent/StatsPanel/StatsMargin/StatsContent
@onready var slot_label: Label              = $OuterScroll/ContentArea/RightMargin/RightContent/SlotLabel
@onready var selected_row: HBoxContainer    = $OuterScroll/ContentArea/RightMargin/RightContent/SelectedRow
@onready var available_grid: GridContainer  = $OuterScroll/ContentArea/RightMargin/RightContent/AvailableGrid
@onready var start_btn: Button              = get_node("OuterScroll/ContentArea/RightMargin/RightContent/StartBtn")
@onready var scroll_container: ScrollContainer = $OuterScroll
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

# ─── HELPERS ───────────────────────────────────────────
func _min_dim() -> float:
	var vp := get_viewport().get_visible_rect().size
	return minf(maxf(vp.x, 320.0), maxf(vp.y, 240.0))

func _fs(ratio: float, floor_v: float, cap_v: float) -> int:
	return int(clampf(_min_dim() * ratio, floor_v, cap_v))

func _process(_delta: float) -> void:
	for card in active_cards:
		if card.is_selected and is_instance_valid(card):
			var slot = selected_row.get_child(card.current_slot_idx)
			if slot:
				var target_size: Vector2 = card.custom_minimum_size
				if card.size != target_size:
					card.size = target_size
				card.global_position = slot.global_position

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	level_number    = GameManager.current_level
	level_config    = _get_level_config()
	max_slots       = 5 # Fixed 5 tower slots for any level
	selected_towers = []

	_setup_buttons()
	_apply_styles()
	_apply_responsive_layout()
	_build_left_panel()
	
	# Determine unlocked towers first to build placeholders correctly
	_determine_unlocked_towers()
	_build_placeholders()
	
	# Wait one frame so that container layouts solve and positions are valid
	await get_tree().process_frame
	ScreenManager.make_scroll_touch_friendly(scroll_container)
	_build_tower_cards()
	_refresh_slots()
	_refresh_start_btn()
	_setup_intro_popup()
	
	get_tree().root.size_changed.connect(_apply_responsive_layout)
	_maybe_show_tutorial()

# ─── LEFT PANEL ────────────────────────────────────────
func _build_left_panel() -> void:
	level_name_label.text = "Level " + str(level_number) + \
		" — " + level_config.get("name", "")

	# Concept
	for child in concept_content.get_children():
		child.queue_free()

	var concept_title := Label.new()
	concept_title.text = "📚 " + level_config.get("concept", "")
	concept_title.add_theme_font_size_override("font_size", _fs(0.042, 16.0, 18.0))
	concept_title.add_theme_color_override("font_color", Color("#00D4FF"))
	concept_content.add_child(concept_title)

	var concept_desc := Label.new()
	concept_desc.text = level_config.get("concept_desc", "")
	concept_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	concept_desc.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
	concept_desc.add_theme_color_override("font_color", Color("#E8F4FD"))
	concept_content.add_child(concept_desc)

	# Enemy tip
	for child in enemy_tip_content.get_children():
		child.queue_free()

	var tip_title := Label.new()
	tip_title.text = "⚠️ Enemy Warning"
	tip_title.add_theme_font_size_override("font_size", _fs(0.040, 16.0, 18.0))
	tip_title.add_theme_color_override("font_color", Color("#FFB800"))
	enemy_tip_content.add_child(tip_title)

	var tip_desc := Label.new()
	tip_desc.text = level_config.get("enemy_tip", "")
	tip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_desc.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
	tip_desc.add_theme_color_override("font_color", Color("#E8F4FD"))
	enemy_tip_content.add_child(tip_desc)

	# 3D enemy previews — one live, paused model per enemy type
	# that spawns in this level.
	var enemy_types: Array = level_config.get("enemy_types", [])
	if not enemy_types.is_empty():
		enemy_tip_content.add_child(_make_enemy_preview_row(enemy_types))

	# Stats
	for child in stats_content.get_children():
		child.queue_free()

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", _fs(0.045, 16.0, 24.0))
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
	col.add_theme_constant_override("separation", _fs(0.008, 2.0, 4.0))

	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", _fs(0.048, 18.0, 22.0))
	val.add_theme_color_override("font_color", color)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(val)

	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
	lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(lbl)

	container.add_child(col)

# ─── DETERMINE UNLOCKED TOWERS ─────────────────────────
func _determine_unlocked_towers() -> void:
	available_towers = []
	for t in GameManager.TOWER_DEFINITIONS.keys():
		if ProgressManager.is_tower_unlocked(t):
			available_towers.append(t)

# ─── PLACEHOLDERS ──────────────────────────────────────
func _build_placeholders() -> void:
	# Clear layout rows
	for child in selected_row.get_children():
		child.queue_free()
	for child in available_grid.get_children():
		child.queue_free()
		
	# Selected Slot Placeholders (Exactly 5 slots)
	for i in range(max_slots):
		var p_slot := PanelContainer.new()
		var slot_w = _fs(0.22, 110.0, 160.0)
		var slot_h = _fs(0.27, 130.0, 180.0)
		p_slot.custom_minimum_size = Vector2(slot_w, slot_h)
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
		lbl.add_theme_font_size_override("font_size", _fs(0.048, 18.0, 22.0))
		lbl.add_theme_color_override("font_color", Color("#1A3A5A"))
		p_slot.add_child(lbl)
		
		selected_row.add_child(p_slot)

# ─── TOWER CARD PREPARATION ────────────────────────────
func _build_tower_cards() -> void:
	for c in active_cards:
		if is_instance_valid(c):
			c.queue_free()
	active_cards.clear()

	var required = level_config.get("required_towers", [])
	var new_towers = ProgressManager.get_new_unlocked_towers()

	selected_towers = []

	var card_scene = preload("res://scenes/campaign/tower_select/TowerCard.tscn")

	for i in range(available_towers.size()):
		var tower_id = available_towers[i]
		var def = GameManager.TOWER_DEFINITIONS[tower_id]
		var is_req = tower_id in required

		var card = card_scene.instantiate()
		available_grid.add_child(card)
		card.setup(tower_id, def, is_req)
		card.set_new(tower_id in new_towers)

		card.clicked.connect(_on_card_clicked)
		card.drag_started.connect(_on_card_drag_started)
		card.drag_ended.connect(_on_card_drag_ended)
		card.info_requested.connect(_on_card_info_requested)

		active_cards.append(card)

	call_deferred("_save_home_positions")

func _save_home_positions() -> void:
	for card in active_cards:
		if is_instance_valid(card) and not card.is_selected:
			card.home_position = card.global_position

func _reparent_card(card: Node, new_parent: Node) -> void:
	var pos = card.global_position
	if card.get_parent():
		card.get_parent().remove_child(card)
	new_parent.add_child(card)
	if new_parent == available_grid:
		var idx = available_towers.find(card.tower_id)
		if idx >= 0 and idx < new_parent.get_child_count():
			new_parent.move_child(card, idx)
	card.global_position = pos

# ─── SELECTION LOGIC ───────────────────────────────────
func _on_card_clicked(tower_id: String) -> void:
	var card = _get_card_by_id(tower_id)
	if not card:
		return

	if card.is_selected:
		selected_towers.erase(tower_id)
		card.current_slot_idx = -1
		card.set_selected(false)
		_reparent_card(card, available_grid)
	else:
		var open_idx = _get_first_empty_slot_idx()
		if open_idx == -1:
			SignalBus.hud_message_requested.emit(
				"Only " + str(max_slots) + " tower slots allowed!", 2.0
			)
			return

		selected_towers.append(tower_id)
		card.current_slot_idx = open_idx
		card.set_selected(true)
		_reparent_card(card, card_layer)
		var target_pos = selected_row.get_child(open_idx).global_position
		card.animate_to(target_pos)

	_refresh_slots()
	_refresh_start_btn()

# ─── DRAG & DROP RESOLUTION ─────────────────────────────
func _on_card_drag_started(card) -> void:
	if card.is_selected:
		selected_towers.erase(card.tower_id)
		card.current_slot_idx = -1
		card.set_selected(false)
		_refresh_slots()
		_refresh_start_btn()
	_reparent_card(card, card_layer)

func _on_card_drag_ended(card, _release_pos: Vector2) -> void:
	var closest_slot_idx = -1
	var min_dist = _fs(0.12, 48.0, 80.0)
	
	for i in range(max_slots):
		var placeholder = selected_row.get_child(i)
		var dist = card.global_position.distance_to(placeholder.global_position)
		if dist < min_dist:
			min_dist = dist
			closest_slot_idx = i
			
	if closest_slot_idx != -1:
		var existing_card = _get_card_in_slot(closest_slot_idx)
		if existing_card:
			selected_towers.erase(existing_card.tower_id)
			existing_card.current_slot_idx = -1
			existing_card.set_selected(false)
			_reparent_card(existing_card, available_grid)

		selected_towers.append(card.tower_id)
		card.current_slot_idx = closest_slot_idx
		card.set_selected(true)
		card.animate_to(selected_row.get_child(closest_slot_idx).global_position, 0.2)
	else:
		_reparent_card(card, available_grid)
		
	_refresh_slots()
	_refresh_start_btn()

# ─── TOWER INTRO POPUP ────────────────────────────────
func _setup_intro_popup() -> void:
	var scene = preload("res://scenes/campaign/tower_intro/TowerIntroPopup.tscn")
	_intro_popup = scene.instantiate()
	_intro_popup.z_index = 1000
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
	# Free-pick: the start button is enabled whenever at least one
	# tower is selected. "Required" towers (defined per level) remain
	# available as informational hints but are no longer enforced.
	var has_any = selected_towers.size() > 0
	start_btn.disabled = not has_any
	start_btn.text = "▶ START LEVEL"

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
	back_btn.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 18.0))

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
	$OuterScroll/ContentArea/LeftMargin/LeftContent/ConceptPanel.add_theme_stylebox_override(
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
	$OuterScroll/ContentArea/LeftMargin/LeftContent/EnemyTipPanel.add_theme_stylebox_override(
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
	$OuterScroll/ContentArea/LeftMargin/LeftContent/StatsPanel.add_theme_stylebox_override(
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
	start_btn.add_theme_font_size_override("font_size", _fs(0.042, 16.0, 18.0))

# ─── ENEMY 3D PREVIEW ROW ──────────────────────────────
# Builds an HBoxContainer that hosts a live, frozen 3D model of
# each enemy that spawns on this level. Each model is the real
# Enemy.tscn set to preview_mode (no pathing, no DoT).
func _make_enemy_preview_row(enemy_types: Array) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _fs(0.015, 6.0, 10.0))
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	for enemy_id in enemy_types:
		var intro = EnemyIntroData.get_intro(enemy_id)
		var edef = GameManager.ENEMY_DEFINITIONS.get(enemy_id, {})
		var tint: Color = edef.get("color", Color("#FF3366"))
		row.add_child(_make_enemy_preview_cell(enemy_id, tint, intro))

	return row

func _make_enemy_preview_cell(enemy_id: String, tint: Color, intro: Dictionary) -> Control:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", _fs(0.008, 2.0, 4.0))
	var cell_size = _fs(0.19, 72.0, 96.0)
	cell.custom_minimum_size = Vector2(cell_size, 0)

	# Frame around the SubViewport
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(cell_size, cell_size)
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color("#080F1E")
	fs.border_color = Color(tint, 0.4)
	fs.border_width_left   = 1
	fs.border_width_right  = 1
	fs.border_width_top    = 1
	fs.border_width_bottom = 1
	fs.corner_radius_top_left     = 6
	fs.corner_radius_top_right    = 6
	fs.corner_radius_bottom_left  = 6
	fs.corner_radius_bottom_right = 6
	frame.add_theme_stylebox_override("panel", fs)

	var sub_vp := SubViewport.new()
	sub_vp.size = Vector2i(int(cell_size), int(cell_size))
	sub_vp.transparent_bg = true
	sub_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_vp.handle_input_locally = false
	sub_vp.disable_3d = false

	var container := SubViewportContainer.new()
	container.custom_minimum_size = Vector2(cell_size, cell_size)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	container.material = mat
	container.add_child(sub_vp)
	frame.add_child(container)

	# Live, frozen 3D enemy
	var e = EnemyFactory.create_preview_enemy(enemy_id, tint)
	if e == null:
		return cell
	e.position = Vector2(sub_vp.size) * 0.5 + Vector2(0, _fs(0.015, 6.0, 10.0))
	sub_vp.add_child(e)

	cell.add_child(frame)

	# Name label below
	var lbl := Label.new()
	lbl.text = intro.get("title", enemy_id).replace(" Packet", "").replace(" Tower", "")
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", _fs(0.028, 16.0, 16.0))
	lbl.add_theme_color_override("font_color", tint)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cell.add_child(lbl)

	return cell

# ─── RESPONSIVE ────────────────────────────────────────
func _apply_responsive_layout() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var w := maxf(vp.x, 320.0)
	var h := maxf(vp.y, 240.0)
	var min_dim := minf(w, h)
	var inset := clampf(min_dim * 0.025, 16.0, 24.0)

	var top_bar = $TopBar
	var left_margin = $OuterScroll/ContentArea/LeftMargin
	var right_margin = $OuterScroll/ContentArea/RightMargin

	# Fluid TopBar height
	var top_h := clampf(h * 0.065, 52.0, 64.0)
	top_bar.custom_minimum_size = Vector2(0, top_h)
	$OuterScroll.offset_top = top_h

	# Fluid typography
	title_label.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.032, 18.0, 28.0)))
	level_name_label.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.042, 18.0, 24.0)))
	slot_label.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
	back_btn.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 18.0))

	# Fluid button sizes
	var btn_h := clampf(h * 0.075, 44.0, 52.0)
	back_btn.custom_minimum_size = Vector2(clampf(w * 0.12, 80.0, 100.0), btn_h)
	start_btn.custom_minimum_size = Vector2(0, btn_h)

	# Fluid column count based on min dimension
	var col_count := 2
	if min_dim > 600:
		col_count = 3
	if min_dim > 800:
		col_count = 4
	available_grid.columns = col_count

	# Fluid selected row separation (smaller gap for cramped mobile rows)
	var slot_sep := clampf(min_dim * 0.025, 8.0, 16.0)
	selected_row.add_theme_constant_override("separation", slot_sep)

	# Fluid available grid separation
	var grid_sep := clampf(min_dim * 0.025, 10.0, 16.0)
	available_grid.add_theme_constant_override("h_separation", grid_sep)
	available_grid.add_theme_constant_override("v_separation", grid_sep)

	# Fluid margins
	left_margin.add_theme_constant_override("margin_left", inset)
	left_margin.add_theme_constant_override("margin_right", inset)
	left_margin.add_theme_constant_override("margin_top", clampf(min_dim * 0.010, 8.0, 16.0))
	left_margin.add_theme_constant_override("margin_bottom", inset)
	right_margin.add_theme_constant_override("margin_left", inset)
	right_margin.add_theme_constant_override("margin_right", inset)
	right_margin.add_theme_constant_override("margin_top", clampf(min_dim * 0.010, 8.0, 16.0))
	right_margin.add_theme_constant_override("margin_bottom", inset)

	# Fluid left margin width
	left_margin.custom_minimum_size = Vector2(clampf(min_dim * 0.32, 180.0, 380.0), 0)


# ─── TUTORIAL ──────────────────────────────────────────
const TutorialOverlay = preload("res://scenes/core/TutorialOverlay.gd")

func _maybe_show_tutorial() -> void:
	if ProgressManager.has_seen_tutorial("tower_select"):
		return
	await get_tree().process_frame
	var tut = TutorialOverlay.new()
	add_child(tut)
	tut.tutorial_finished.connect(func(): ProgressManager.mark_tutorial_seen("tower_select"))
	tut.start(_get_tower_select_tutorial_steps())

func _get_tower_select_tutorial_steps() -> Array:
	var steps: Array = []
	steps.append({
		"title": "Select Your Towers",
		"body": "Choose up to 5 towers to deploy into this level.\n\nEach tower has unique abilities — pick wisely based on the enemy intel on the left.",
		"force_center": true,
	})
	steps.append({
		"title": "Mission Intel",
		"body": "Read the mission briefing here: level concept, enemy warnings, and key stats like wave count and starting RAM.",
		"highlight": $OuterScroll/ContentArea/LeftMargin.get_path(),
	})
	steps.append({
		"title": "Tower Slots",
		"body": "Drag or tap towers to place them in these 5 deployment slots.\n\nFill at least one slot to enable the Start button.",
		"highlight": selected_row.get_path(),
	})
	steps.append({
		"title": "Available Towers",
		"body": "Browse your unlocked towers here. Tap a card for detailed stats, or drag it into a slot above.\n\nNewly unlocked towers appear highlighted.",
		"highlight": available_grid.get_path(),
	})
	steps.append({
		"title": "Start Level",
		"body": "Ready to deploy? Tap START LEVEL to begin defending against incoming packet waves.",
		"highlight": start_btn.get_path(),
	})
	steps.append({
		"title": "Good Luck!",
		"body": "Choose your towers, fill the slots, and clear every wave. Good luck, operator!",
		"force_center": true,
	})
	return steps
