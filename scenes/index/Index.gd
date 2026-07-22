# Index.gd
extends Control

# ─── NODE REFERENCES ───────────────────────────────────
@onready var back_btn: Button           = $TopBar/TopBarLayout/BackBtn
@onready var search_field: LineEdit     = $TopBar/TopBarLayout/SearchField
@onready var towers_tab: Button         = $TabBar/TowersTab
@onready var enemies_tab: Button        = $TabBar/EnemiesTab
@onready var towers_panel: ScrollContainer  = $ContentArea/TowersPanel
@onready var enemies_panel: ScrollContainer = $ContentArea/EnemiesPanel
@onready var towers_content: VBoxContainer  = $ContentArea/TowersPanel/TowersContent
@onready var enemies_content: VBoxContainer = $ContentArea/EnemiesPanel/EnemiesContent

var path_tab: Button        = null
var path_panel: ScrollContainer = null

# ─── STATE ──────────────────────────────────────────────
var active_tab: String   = "towers"
var search_query: String = ""
var _last_device: String = ""

# ─── CACHED SCENES (preloaded once) ─────────────────────
const TOWER_SCENE  = preload("res://scenes/campaign/towers/Tower.tscn")
const ENEMY_SCENE  = preload("res://scenes/campaign/enemies/Enemy.tscn")

# ─── THEME COLORS ──────────────────────────────────────
const C_BG          := Color("#0A1628")
const C_BG_DARK     := Color("#080F1E")
const C_TEXT        := Color("#E8F4FD")
const C_MUTED       := Color("#4A7FA5")
const C_DIM         := Color("#2A3A4A")
const C_ACCENT      := Color("#00D4FF")
const C_GREEN       := Color("#00FF88")
const C_RED         := Color("#FF3366")
const C_GOLD        := Color("#FFB800")
const C_PANEL       := Color("#0D2040")

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	_setup_buttons()
	_apply_styles()
	_build_towers_tab()
	_build_enemies_tab()
	_build_path_tab()
	_show_towers_tab()
	_apply_responsive_layout()
	get_tree().root.size_changed.connect(_apply_responsive_layout)

# ─── BUTTON SETUP ──────────────────────────────────────
func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	towers_tab.pressed.connect(_show_towers_tab)
	enemies_tab.pressed.connect(_show_enemies_tab)
	search_field.text_changed.connect(_on_search_changed)

	path_tab = Button.new()
	path_tab.text = "📊 Path"
	path_tab.custom_minimum_size = Vector2(80, 32)
	path_tab.pressed.connect(_show_path_tab)
	path_tab.add_theme_font_size_override("font_size", 12)
	$TabBar.add_child(path_tab)

	path_panel = ScrollContainer.new()
	path_panel.name = "PathPanel"
	path_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_panel.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	path_panel.visible = false
	$ContentArea.add_child(path_panel)

func _on_back_pressed() -> void:
	GameManager.go_to("main_menu")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to("main_menu")

# ─── TAB SWITCHING ─────────────────────────────────────
func _show_towers_tab() -> void:
	active_tab            = "towers"
	towers_panel.visible  = true
	enemies_panel.visible = false
	path_panel.visible    = false
	_style_active_tab(towers_tab,  true)
	_style_active_tab(enemies_tab, false)
	if path_tab: _style_active_tab(path_tab, false)

func _show_enemies_tab() -> void:
	active_tab            = "enemies"
	towers_panel.visible  = false
	enemies_panel.visible = true
	path_panel.visible    = false
	_style_active_tab(towers_tab,  false)
	_style_active_tab(enemies_tab, true)
	if path_tab: _style_active_tab(path_tab, false)

func _show_path_tab() -> void:
	active_tab            = "path"
	towers_panel.visible  = false
	enemies_panel.visible = false
	path_panel.visible    = true
	_style_active_tab(towers_tab,  false)
	_style_active_tab(enemies_tab, false)
	if path_tab: _style_active_tab(path_tab, true)
	path_panel.queue_redraw()

# ─── TOWER DATA (built from PROGRESSION_CHAIN) ─────────
# Returns an Array of Dictionaries, one per tower, in unlock order.
func _collect_towers() -> Array:
	var result: Array = []
	for lesson_id in ProgressManager.PROGRESSION_CHAIN:
		var chain = ProgressManager.PROGRESSION_CHAIN[lesson_id]
		if chain.get("type") not in ["both", "tower"]:
			continue
		var tower_id: String = chain["id"]
		var intro  = TowerIntroData.get_intro(tower_id)
		# Stats come from GameManager.TOWER_DEFINITIONS (already in the project)
		var def    = GameManager.TOWER_DEFINITIONS.get(tower_id, {})
		result.append({
			"id":               tower_id,
			"unlocked_by":      lesson_id,
			"name":             intro.get("title", def.get("tower_name", tower_id)),
			"tagline":          intro.get("tagline", ""),
			"mechanic":         intro.get("mechanic", ""),
			"description":      def.get("description", intro.get("mechanic", "")),
			"ds":               def.get("data_structure", ""),
			"cost":             int(def.get("ram_cost", 0)),
			"damage":           float(def.get("damage", 0.0)),
			"speed":            float(def.get("attack_speed", 0.0)),
			"range":            float(def.get("attack_range", 0.0)),
			"time_complexity":  def.get("time_complexity", ""),
			"color":            intro.get("color", def.get("color", C_ACCENT)),
			"icon":             intro.get("icon", def.get("icon_text", "")),
			"ability":          intro.get("ability", ""),
			"strong":           intro.get("strong", []),
			"weak":             intro.get("weak", []),
			"targeting":        intro.get("targeting", ""),
		})
	return result

# ─── ENEMY DATA (built from EnemyIntroData) ────────────
func _collect_enemies() -> Array:
	var result: Array = []
	for enemy_id in EnemyIntroData.all_ids():
		var intro = EnemyIntroData.get_intro(enemy_id)
		# Real runtime stats come from Enemy.gd defaults; we expose
		# a small health/speed/reward from the intro registry for display.
		var defaults = _enemy_default_stats(enemy_id)
		result.append({
			"id":          enemy_id,
			"name":        intro.get("title", enemy_id),
			"tagline":     intro.get("tagline", ""),
			"description": intro.get("special", ""),
			"special":     intro.get("special", ""),
			"lesson":      intro.get("lesson", ""),
			"threat":      intro.get("threat", "Medium"),
			"color":       intro.get("color", C_RED),
			"icon":        intro.get("icon", ""),
			"health":      defaults.health,
			"speed":       defaults.speed,
			"reward":      defaults.reward,
		})
	return result

# Mirror of the canonical stat values set in Enemy.gd._setup_type().
# We keep them here for display only — Enemy.gd is the source of truth
# for actual gameplay values.
func _enemy_default_stats(enemy_id: String) -> Dictionary:
	var presets: Dictionary = {
		"basic_packet":    {"health": 100.0, "speed": 80.0,  "reward": 10},
		"indexed_packet":  {"health": 100.0, "speed": 72.0,  "reward": 15},
		"overflow_packet": {"health": 300.0, "speed": 40.0,  "reward": 30},
		"queue_jumper":    {"health":  80.0, "speed": 40.0,  "reward": 15},
		"linked_drain":    {"health": 100.0, "speed": 80.0,  "reward": 20},
		"bubble_shield":   {"health": 100.0, "speed": 96.0,  "reward": 25},
		"pivot_splitter":  {"health": 500.0, "speed": 40.0,  "reward": 100},
		"selection_mark":  {"health": 200.0, "speed": 80.0,  "reward": 20},
		"insertion_stack": {"health": 150.0, "speed": 64.0,  "reward": 25},
		"merge_twin":      {"health": 150.0, "speed": 80.0,  "reward": 25},
		"count_meter":     {"health": 200.0, "speed": 80.0,  "reward": 20},
		"radix_digit":     {"health": 250.0, "speed": 56.0,  "reward": 35},
		"scan_wave":       {"health": 150.0, "speed": 72.0,  "reward": 20},
		"binary_mask":     {"health": 200.0, "speed": 64.0,  "reward": 40},
	}
	return presets.get(enemy_id, {"health": 100.0, "speed": 80.0, "reward": 10})

# ─── BUILD TOWERS TAB ──────────────────────────────────
func _build_towers_tab() -> void:
	for child in towers_content.get_children():
		child.queue_free()

	for data in _collect_towers():
		if _matches_search(data["name"], data["ds"]):
			towers_content.add_child(_make_tower_card(data))

func _preview_size() -> Vector2:
	if ScreenManager.is_mobile():
		return Vector2(80, 80)
	return Vector2(120, 120)

func _make_tower_card(data: Dictionary) -> Control:
	var is_unlocked = ProgressManager.is_tower_unlocked(data["id"])
	var color       = data["color"]

	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_card_style(color, is_unlocked))

	var layout = HBoxContainer.new()
	layout.add_theme_constant_override("separation", _card_separation())

	# ── LEFT: live 3D preview ──
	layout.add_child(_make_preview_panel(
		data["id"], true, color, _preview_size()
	))

	# ── MIDDLE: identity + description + stats ──
	var middle = VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 6)

	var name_label = Label.new()
	name_label.text = data["name"]
	name_label.add_theme_font_size_override("font_size", _card_font_size())
	name_label.add_theme_color_override(
		"font_color", C_TEXT if is_unlocked else C_DIM
	)
	middle.add_child(name_label)

	var ds_label = Label.new()
	ds_label.text = "%s   •   💾 %d RAM" % [data["ds"], data["cost"]]
	ds_label.add_theme_font_size_override("font_size", 11 if ScreenManager.is_mobile() else 12)
	ds_label.add_theme_color_override("font_color", color if is_unlocked else C_DIM)
	middle.add_child(ds_label)

	var tagline = Label.new()
	tagline.text = data["tagline"]
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tagline.add_theme_font_size_override("font_size", 12)
	tagline.add_theme_color_override("font_color", C_MUTED)
	middle.add_child(tagline)

	if is_unlocked:
		# Stats row
		var stats = HBoxContainer.new()
		stats.add_theme_constant_override("separation", 16)
		_add_stat(stats, "DMG",   str(data["damage"]))
		_add_stat(stats, "SPD",   "%s/s" % data["speed"])
		_add_stat(stats, "RNG",   "%s px" % str(int(data["range"])))
		_add_stat(stats, "TIME",  data["time_complexity"])
		middle.add_child(stats)

		# Ability row
		if data["ability"] != "":
			var abil = Label.new()
			abil.text = "⚡ " + data["ability"]
			abil.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			abil.add_theme_font_size_override("font_size", 12)
			abil.add_theme_color_override("font_color", C_GOLD)
			middle.add_child(abil)

		# Mechanic row
		if data["mechanic"] != "":
			var mech = Label.new()
			mech.text = data["mechanic"]
			mech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			mech.add_theme_font_size_override("font_size", 12)
			mech.add_theme_color_override("font_color", C_TEXT)
			middle.add_child(mech)

		# Matchups row
		if data["strong"].size() > 0 or data["weak"].size() > 0:
			var matchups = HBoxContainer.new()
			matchups.add_theme_constant_override("separation", 24)
			_add_matchup_list(matchups, "STRONG", data["strong"], C_GREEN)
			_add_matchup_list(matchups, "WEAK",   data["weak"],   C_RED)
			middle.add_child(matchups)
	else:
		var lock = Label.new()
		lock.text = "🔒  Complete the “%s” lesson to unlock." % _lesson_display_name(data["unlocked_by"])
		lock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lock.add_theme_font_size_override("font_size", 13)
		lock.add_theme_color_override("font_color", C_MUTED)
		middle.add_child(lock)

	layout.add_child(middle)
	card.add_child(layout)
	return card

# ─── BUILD ENEMIES TAB ─────────────────────────────────
func _build_enemies_tab() -> void:
	for child in enemies_content.get_children():
		child.queue_free()

	for data in _collect_enemies():
		if _matches_search(data["name"], ""):
			enemies_content.add_child(_make_enemy_card(data))

func _card_separation() -> int:
	return 8 if ScreenManager.is_mobile() else 16

func _card_font_size() -> int:
	return 14 if ScreenManager.is_mobile() else 18

func _make_enemy_card(data: Dictionary) -> Control:
	var color = data["color"]

	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_card_style(color, true))

	var layout = HBoxContainer.new()
	layout.add_theme_constant_override("separation", _card_separation())

	# ── LEFT: live 3D preview ──
	layout.add_child(_make_preview_panel(
		data["id"], false, color, _preview_size()
	))

	# ── MIDDLE: identity + description + stats ──
	var middle = VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 6)

	var name_label = Label.new()
	name_label.text = data["name"]
	name_label.add_theme_font_size_override("font_size", _card_font_size())
	name_label.add_theme_color_override("font_color", C_TEXT)
	middle.add_child(name_label)

	var meta = Label.new()
	meta.text = "%s Threat   •   💾 +%d RAM" % [data["threat"], data["reward"]]
	meta.add_theme_font_size_override("font_size", 11 if ScreenManager.is_mobile() else 12)
	meta.add_theme_color_override("font_color", _threat_color(data["threat"]))
	middle.add_child(meta)

	var tagline = Label.new()
	tagline.text = data["tagline"]
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tagline.add_theme_font_size_override("font_size", 12)
	tagline.add_theme_color_override("font_color", C_MUTED)
	middle.add_child(tagline)

	var stats = HBoxContainer.new()
	stats.add_theme_constant_override("separation", 16)
	_add_stat(stats, "HP",  str(int(data["health"])))
	_add_stat(stats, "SPD", "%d px/s" % int(data["speed"]))
	middle.add_child(stats)

	var special = Label.new()
	special.text = "⚡ " + data["special"]
	special.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	special.add_theme_font_size_override("font_size", 12)
	special.add_theme_color_override("font_color", C_GOLD)
	middle.add_child(special)

	if data["lesson"] != "":
		var lesson = Label.new()
		lesson.text = "📘 " + data["lesson"]
		lesson.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lesson.add_theme_font_size_override("font_size", 12)
		lesson.add_theme_color_override("font_color", C_TEXT)
		middle.add_child(lesson)

	layout.add_child(middle)
	card.add_child(layout)
	return card

# ─── PATH TAB (unchanged behavior, refactored) ─────────
func _build_path_tab() -> void:
	for child in path_panel.get_children():
		child.queue_free()
	var content = VBoxContainer.new()
	content.name = "PathContent"
	content.add_theme_constant_override("separation", 4)
	path_panel.add_child(content)

	var title = Label.new()
	title.text = "YOUR LEARNING PATH"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", C_ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	var groups = [
		["Python",         ["py_variables", "py_lists", "py_loops", "py_conditions", "py_functions"]],
		["Data Structures",["ds_arrays", "ds_stacks", "ds_queues", "ds_linked_lists"]],
		["Sorting",        ["sort_bubble", "sort_selection", "sort_insertion",
		                    "sort_quick", "sort_merge", "sort_counting", "sort_radix"]],
		["Search",         ["search_linear", "search_binary"]],
	]

	for group in groups:
		var section = VBoxContainer.new()
		section.add_theme_constant_override("separation", 2)
		section.add_theme_constant_override("margin_left", 16)
		section.add_theme_constant_override("margin_right", 16)
		content.add_child(section)

		var hdr = Label.new()
		hdr.text = "── " + group[0] + " ──"
		hdr.add_theme_font_size_override("font_size", 11)
		hdr.add_theme_color_override("font_color", C_MUTED)
		hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		section.add_child(hdr)

		for lesson_id in group[1]:
			section.add_child(_make_path_row(lesson_id))

		var sep = HSeparator.new()
		sep.add_theme_color_override("color", Color("#1A2D3D"))
		content.add_child(sep)

func _make_path_row(lesson_id: String) -> Control:
	var state = ProgressManager.get_topic_state(lesson_id)
	var row   = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var dot = Label.new()
	dot.custom_minimum_size = Vector2(20, 20)
	dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	match state:
		"mastered": dot.text = "✅"
		"unlocked": dot.text = "🔓"
		_:          dot.text = "🔒"
	row.add_child(dot)

	var lbl = Label.new()
	lbl.text = _lesson_display_name(lesson_id)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color",
		C_GREEN if state == "mastered" else
		C_ACCENT if state == "unlocked" else C_DIM)
	lbl.add_theme_font_size_override("font_size", 11)
	row.add_child(lbl)

	var chain = ProgressManager.PROGRESSION_CHAIN.get(lesson_id, {})
	if chain.get("type") in ["both", "tower"]:
		var tower_id: String = chain["id"]
		var unlocked = ProgressManager.is_tower_unlocked(tower_id)
		var tlabel = Label.new()
		tlabel.text = "→ " + TowerIntroData.get_tower_name(tower_id)
		tlabel.add_theme_font_size_override("font_size", 9)
		tlabel.add_theme_color_override("font_color", C_GREEN if unlocked else C_DIM)
		row.add_child(tlabel)

	var lid = int(chain.get("level_id", 0))
	if lid > 0:
		var unlocked_lvl = ProgressManager.is_level_unlocked(lid)
		var llbl = Label.new()
		llbl.text = "Lv." + str(lid)
		llbl.add_theme_font_size_override("font_size", 9)
		llbl.add_theme_color_override("font_color", C_GOLD if unlocked_lvl else C_DIM)
		row.add_child(llbl)

	return row

# ─── SEARCH ────────────────────────────────────────────
func _on_search_changed(new_text: String) -> void:
	search_query = new_text.to_lower().strip_edges()
	match active_tab:
		"towers":  _build_towers_tab()
		"enemies": _build_enemies_tab()

func _matches_search(name: String, ds: String) -> bool:
	if search_query == "":
		return true
	var q = search_query
	return name.to_lower().contains(q) or ds.to_lower().contains(q)

# ─── 3D PREVIEW WIDGET ─────────────────────────────────
# Builds a SubViewportContainer hosting the actual Tower.tscn
# or Enemy.tscn instance in preview mode (frozen, no game logic).
func _make_preview_panel(
		entity_id: String,
		is_tower: bool,
		tint: Color,
		size: Vector2) -> Control:

	var wrapper = PanelContainer.new()
	wrapper.custom_minimum_size = size
	var frame := StyleBoxFlat.new()
	frame.bg_color = C_BG_DARK
	frame.border_color = Color(tint, 0.4)
	frame.border_width_left   = 1
	frame.border_width_right  = 1
	frame.border_width_top    = 1
	frame.border_width_bottom = 1
	frame.corner_radius_top_left     = 6
	frame.corner_radius_top_right    = 6
	frame.corner_radius_bottom_left  = 6
	frame.corner_radius_bottom_right = 6
	wrapper.add_theme_stylebox_override("panel", frame)

	var sub_vp = SubViewport.new()
	sub_vp.size = Vector2i(int(size.x), int(size.y))
	sub_vp.transparent_bg = true
	sub_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_vp.handle_input_locally = false
	sub_vp.disable_3d = false

	var container = SubViewportContainer.new()
	container.custom_minimum_size = size
	container.stretch = true
	container.add_child(sub_vp)
	wrapper.add_child(container)

	if is_tower:
		_instantiate_tower_preview(sub_vp, entity_id, tint)
	else:
		_instantiate_enemy_preview(sub_vp, entity_id, tint)

	return wrapper

func _instantiate_tower_preview(vp: SubViewport, tower_id: String, color: Color) -> void:
	var t = TOWER_SCENE.instantiate()
	t.tower_id    = tower_id
	t.tower_color = color
	t.tower_name  = TowerIntroData.get_tower_name(tower_id)
	t.damage      = 0.0
	t.attack_speed = 0.0
	t.attack_range = 0.0
	t.current_target = null
	t.enemy_layer = null
	t.preview_mode = true
	# Hide the placeholder sprite (matches Tower._ready behavior)
	if t.has_node("TowerSprite"):
		t.get_node("TowerSprite").visible = false
	# Center the tower in the preview viewport
	t.position = Vector2(vp.size) * 0.5
	vp.add_child(t)

func _instantiate_enemy_preview(vp: SubViewport, enemy_id: String, color: Color) -> void:
	var e = ENEMY_SCENE.instantiate()
	e.enemy_type    = enemy_id
	e.preview_mode  = true
	e.max_health    = 1.0
	e.current_health = 1.0
	e.move_speed    = 0.0
	e.damage_to_base = 0
	e.ram_reward    = 0
	e.waypoints     = [] as Array[Vector2]
	# Populate type_data so the draw routine doesn't crash on missing keys.
	e._setup_type()
	# Override the hardcoded color set by _setup_type with the intro-data tint.
	e.enemy_color = color
	# Center the enemy in the preview viewport
	e.position = Vector2(vp.size) * 0.5 + Vector2(0, 12)  # slight downward bias
	vp.add_child(e)

# ─── STYLES & HELPERS ──────────────────────────────────
func _make_card_style(color: Color, is_active: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = C_BG
	s.border_color = color if is_active else C_DIM
	s.border_width_left   = 1
	s.border_width_right  = 1
	s.border_width_top    = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left     = 6
	s.corner_radius_top_right    = 6
	s.corner_radius_bottom_left  = 6
	s.corner_radius_bottom_right = 6
	if ScreenManager.is_mobile():
		s.content_margin_left   = 10
		s.content_margin_right  = 10
		s.content_margin_top    = 8
		s.content_margin_bottom = 8
	else:
		s.content_margin_left   = 16
		s.content_margin_right  = 16
		s.content_margin_top    = 12
		s.content_margin_bottom = 12
	return s

func _add_stat(container: HBoxContainer, label: String, value: String) -> void:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var lbl = Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", C_MUTED)
	vbox.add_child(lbl)

	var val = Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 13)
	val.add_theme_color_override("font_color", C_TEXT)
	vbox.add_child(val)

	container.add_child(vbox)

func _add_matchup_list(container: HBoxContainer, title: String, ids: Array, color: Color) -> void:
	if ids.is_empty():
		return
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)

	var hdr = Label.new()
	hdr.text = title
	hdr.add_theme_font_size_override("font_size", 9)
	hdr.add_theme_color_override("font_color", color)
	box.add_child(hdr)

	for enemy_id in ids:
		var item = Label.new()
		item.text = "• " + EnemyIntroData.get_enemy_name(enemy_id)
		item.add_theme_font_size_override("font_size", 11)
		item.add_theme_color_override("font_color", C_TEXT)
		box.add_child(item)

	container.add_child(box)

func _threat_color(threat: String) -> Color:
	match threat:
		"Low":     return C_GREEN
		"Medium":  return C_GOLD
		"High":    return Color("#FF6B35")
		"Extreme": return C_RED
		_:         return C_TEXT

func _lesson_display_name(lesson_id: String) -> String:
	var names: Dictionary = {
		"py_variables":    "Variables",
		"py_lists":        "Lists",
		"py_loops":        "Loops",
		"py_conditions":   "Conditions",
		"py_functions":    "Functions",
		"ds_arrays":       "Arrays",
		"ds_stacks":       "Stacks",
		"ds_queues":       "Queues",
		"ds_linked_lists": "Linked Lists",
		"sort_bubble":     "Bubble Sort",
		"sort_selection":  "Selection Sort",
		"sort_insertion":  "Insertion Sort",
		"sort_quick":      "Quick Sort",
		"sort_merge":      "Merge Sort",
		"sort_counting":   "Counting Sort",
		"sort_radix":      "Radix Sort",
		"search_linear":   "Linear Search",
		"search_binary":   "Binary Search",
	}
	return names.get(lesson_id, lesson_id)

# ─── TOP-LEVEL STYLES ──────────────────────────────────
func _apply_styles() -> void:
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = C_BG_DARK
	top_style.border_color = C_ACCENT
	top_style.border_width_bottom = 1
	$TopBar.add_theme_stylebox_override("panel", top_style)

	var back_style := StyleBoxFlat.new()
	back_style.bg_color = C_BG
	back_style.border_color = C_ACCENT
	back_style.border_width_left   = 1
	back_style.border_width_right  = 1
	back_style.border_width_top    = 1
	back_style.border_width_bottom = 1
	back_style.corner_radius_top_left     = 4
	back_style.corner_radius_top_right    = 4
	back_style.corner_radius_bottom_left  = 4
	back_style.corner_radius_bottom_right = 4
	back_btn.add_theme_stylebox_override("normal", back_style)
	back_btn.add_theme_color_override("font_color", C_ACCENT)

	var search_style := StyleBoxFlat.new()
	search_style.bg_color = C_BG_DARK
	search_style.border_color = Color("#1A3A5A")
	search_style.border_width_left   = 1
	search_style.border_width_right  = 1
	search_style.border_width_top    = 1
	search_style.border_width_bottom = 1
	search_style.corner_radius_top_left     = 4
	search_style.corner_radius_top_right    = 4
	search_style.corner_radius_bottom_left  = 4
	search_style.corner_radius_bottom_right = 4
	search_style.content_margin_left  = 12
	search_style.content_margin_right = 12
	search_field.add_theme_stylebox_override("normal", search_style)
	search_field.add_theme_color_override("font_color", C_TEXT)
	search_field.add_theme_color_override("font_placeholder_color", C_MUTED)

	var tab_bg := StyleBoxFlat.new()
	tab_bg.bg_color = C_BG_DARK
	$TabBar.add_theme_stylebox_override("panel", tab_bg)

func _style_active_tab(btn: Button, active: bool) -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left     = 0
	style.corner_radius_top_right    = 0
	style.corner_radius_bottom_left  = 0
	style.corner_radius_bottom_right = 0
	if active:
		style.bg_color            = C_PANEL
		style.border_color        = C_ACCENT
		style.border_width_bottom = 2
		btn.add_theme_color_override("font_color", C_ACCENT)
	else:
		style.bg_color            = C_BG_DARK
		style.border_color        = C_BG_DARK
		style.border_width_bottom = 2
		btn.add_theme_color_override("font_color", C_MUTED)
	btn.add_theme_stylebox_override("normal",  style)
	btn.add_theme_stylebox_override("hover",   style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_font_size_override("font_size", 14)

# ─── RESPONSIVE ────────────────────────────────────────
func _apply_responsive_layout() -> void:
	var current = "mobile" if ScreenManager.is_mobile() else "tablet" if ScreenManager.is_tablet() else "desktop"
	var device_changed = current != _last_device
	_last_device = current
	
	var top_bar = $TopBar
	var content_area = $ContentArea
	var title_label = $TopBar/TopBarLayout/TitleLabel
	var tab_bar = $TabBar
	
	if ScreenManager.is_mobile():
		search_field.visible = false
		ScreenManager.apply_panel_padding(top_bar, 20)
		tab_bar.offset_left = 20
		tab_bar.offset_right = -20
		content_area.add_theme_constant_override("margin_left", 20)
		content_area.add_theme_constant_override("margin_right", 20)
		content_area.add_theme_constant_override("margin_top", 20)
		content_area.add_theme_constant_override("margin_bottom", 20)
		title_label.add_theme_font_size_override("font_size", 14)
		back_btn.custom_minimum_size = Vector2(70, 44)
	elif ScreenManager.is_tablet():
		search_field.visible = true
		ScreenManager.apply_panel_padding(top_bar, 24)
		tab_bar.offset_left = 24
		tab_bar.offset_right = -24
		content_area.add_theme_constant_override("margin_left", 24)
		content_area.add_theme_constant_override("margin_right", 24)
		content_area.add_theme_constant_override("margin_top", 24)
		content_area.add_theme_constant_override("margin_bottom", 24)
		title_label.add_theme_font_size_override("font_size", 15)
		back_btn.custom_minimum_size = Vector2(80, 44)
	else:
		search_field.visible = true
		title_label.add_theme_font_size_override("font_size", 16)
		back_btn.custom_minimum_size = Vector2(90, 0)
	
	# Rebuild current tab if device changed (card sizes differ)
	if device_changed:
		match active_tab:
			"towers": _build_towers_tab()
			"enemies": _build_enemies_tab()
			"path": _build_path_tab()
