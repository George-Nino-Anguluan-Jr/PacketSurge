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

# ─── STATE ──────────────────────────────────────────────
var active_tab: String   = "towers"
var search_query: String = ""

# ─── HELPERS ───────────────────────────────────────────
func _min_dim() -> float:
	var vp := get_viewport().get_visible_rect().size
	return minf(maxf(vp.x, 320.0), maxf(vp.y, 240.0))

func _fs(ratio: float, floor_v: float, cap_v: float) -> int:
	return int(clampf(_min_dim() * ratio, floor_v, cap_v))

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
	_show_towers_tab()
	ScreenManager.make_scroll_touch_friendly(towers_panel)
	ScreenManager.make_scroll_touch_friendly(enemies_panel)
	_apply_responsive_layout()
	get_tree().root.size_changed.connect(_apply_responsive_layout)
	_maybe_show_tutorial()

# ─── BUTTON SETUP ──────────────────────────────────────
func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	towers_tab.pressed.connect(_show_towers_tab)
	enemies_tab.pressed.connect(_show_enemies_tab)
	search_field.text_changed.connect(_on_search_changed)

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
	_style_active_tab(towers_tab,  true)
	_style_active_tab(enemies_tab, false)

func _show_enemies_tab() -> void:
	active_tab            = "enemies"
	towers_panel.visible  = false
	enemies_panel.visible = true
	_style_active_tab(towers_tab,  false)
	_style_active_tab(enemies_tab, true)

# ─── TOWER DATA (built from DataRegistry, ordered) ─────
# Returns an Array of Dictionaries, one per tower, in data order.
func _collect_towers() -> Array:
	var tower_to_lesson: Dictionary = {}
	for lesson_id in ProgressManager.PROGRESSION_CHAIN:
		var chain = ProgressManager.PROGRESSION_CHAIN[lesson_id]
		if chain.get("type") in ["both", "tower"]:
			tower_to_lesson[chain["id"]] = lesson_id

	var result: Array = []
	for tower_id in DataRegistry.get_tower_ids_ordered():
		var intro  = TowerIntroData.get_intro(tower_id)
		# Stats come from GameManager.TOWER_DEFINITIONS (already in the project)
		var def    = GameManager.TOWER_DEFINITIONS.get(tower_id, {})
		result.append({
			"id":               tower_id,
			"unlocked_by":      tower_to_lesson.get(tower_id, ""),
			"name":             def.get("tower_name", tower_id),
			"tagline":          intro.get("tagline", ""),
			"mechanic":         intro.get("mechanic", ""),
			"description":      def.get("description", intro.get("mechanic", "")),
			"ds":               def.get("data_structure", ""),
			"cost":             int(def.get("ram_cost", 0)),
			"damage":           float(def.get("damage", 0.0)),
			"speed":            float(def.get("attack_speed", 0.0)),
			"range":            float(def.get("attack_range", 0.0)),
			"time_complexity":  def.get("time_complexity", ""),
			"color":            def.get("color", C_ACCENT),
			"icon":             def.get("icon_text", ""),
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
		var edef = GameManager.ENEMY_DEFINITIONS.get(enemy_id, {})
		result.append({
			"id":          enemy_id,
			"name":        intro.get("title", enemy_id),
			"tagline":     intro.get("tagline", ""),
			"description": intro.get("special", ""),
			"special":     intro.get("special", ""),
			"lesson":      intro.get("lesson", ""),
			"threat":      intro.get("threat", "Medium"),
			"color":       edef.get("color", C_RED),
			"icon":        intro.get("icon", ""),
			"health":      float(edef.get("max_health", 100.0)),
			"speed":       float(edef.get("speed", 80.0)),
			"reward":      int(edef.get("ram_reward", 10)),
		})
	return result

# ─── BUILD TOWERS TAB ──────────────────────────────────
func _build_towers_tab() -> void:
	for child in towers_content.get_children():
		child.queue_free()

	for data in _collect_towers():
		if _matches_search(data["name"], data["ds"]):
			towers_content.add_child(_make_tower_card(data))

func _preview_size() -> Vector2:
	var s := _fs(0.32, 100.0, 140.0)
	return Vector2(s, s)

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
	ds_label.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
	ds_label.add_theme_color_override("font_color", color if is_unlocked else C_DIM)
	middle.add_child(ds_label)

	var tagline = Label.new()
	tagline.text = data["tagline"]
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tagline.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
	tagline.add_theme_color_override("font_color", C_MUTED)
	middle.add_child(tagline)

	if is_unlocked:
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
			abil.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
			abil.add_theme_color_override("font_color", C_GOLD)
			middle.add_child(abil)

		# Mechanic row
		if data["mechanic"] != "":
			var mech = Label.new()
			mech.text = data["mechanic"]
			mech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			mech.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
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
		lock.text = "🔒  Complete the \"%s\" lesson to unlock." % _lesson_display_name(data["unlocked_by"])
		lock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lock.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 18.0))
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
	return _fs(0.030, 10.0, 16.0)

func _card_font_size() -> int:
	return _fs(0.050, 18.0, 24.0)

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
	meta.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
	meta.add_theme_color_override("font_color", _threat_color(data["threat"]))
	middle.add_child(meta)

	var tagline = Label.new()
	tagline.text = data["tagline"]
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tagline.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
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
	special.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
	special.add_theme_color_override("font_color", C_GOLD)
	middle.add_child(special)

	if data["lesson"] != "":
		var lesson = Label.new()
		lesson.text = "📘 " + data["lesson"]
		lesson.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lesson.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
		lesson.add_theme_color_override("font_color", C_TEXT)
		middle.add_child(lesson)

	layout.add_child(middle)
	card.add_child(layout)
	return card



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
# Builds a SubViewportContainer hosting the actual tower or enemy
# instance in preview mode (frozen, no game logic).
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
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	container.material = mat
	container.add_child(sub_vp)
	wrapper.add_child(container)

	if is_tower:
		_instantiate_tower_preview(sub_vp, entity_id, tint)
	else:
		_instantiate_enemy_preview(sub_vp, entity_id, tint)

	return wrapper

func _instantiate_tower_preview(vp: SubViewport, tower_id: String, color: Color) -> void:
	var def = GameManager.TOWER_DEFINITIONS.get(tower_id, {})
	var td = TowerData.new()
	td.tower_id = tower_id
	td.tower_name = def.get("tower_name", tower_id)
	td.damage = 0.0
	td.attack_speed = 0.0
	td.attack_range = 0.0
	td.color = color
	td.icon_text = def.get("icon_text", "[ ]")
	if "style" in def:
		td.style = def["style"]
	var t = TowerFactory.create_preview_tower(td)
	if t == null:
		return
	t.position = Vector2(vp.size) * 0.5
	vp.add_child(t)

func _instantiate_enemy_preview(vp: SubViewport, enemy_id: String, color: Color) -> void:
	var e = EnemyFactory.create_preview_enemy(enemy_id, color)
	if e == null:
		return
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
	s.content_margin_left   = _fs(0.034, 10.0, 16.0)
	s.content_margin_right  = _fs(0.034, 10.0, 16.0)
	s.content_margin_top    = _fs(0.025, 8.0, 12.0)
	s.content_margin_bottom = _fs(0.025, 8.0, 12.0)
	return s

func _add_stat(container: HBoxContainer, label: String, value: String) -> void:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var lbl = Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", _fs(0.030, 16.0, 16.0))
	lbl.add_theme_color_override("font_color", C_MUTED)
	vbox.add_child(lbl)

	var val = Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", _fs(0.038, 16.0, 18.0))
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
	hdr.add_theme_font_size_override("font_size", _fs(0.030, 16.0, 16.0))
	hdr.add_theme_color_override("font_color", color)
	box.add_child(hdr)

	for enemy_id in ids:
		var item = Label.new()
		item.text = "• " + EnemyIntroData.get_enemy_name(enemy_id)
		item.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
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
	return GameManager.LESSON_NAMES.get(lesson_id, lesson_id)

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
	back_btn.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 18.0))

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
	search_field.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 18.0))

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
	btn.add_theme_font_size_override("font_size", _fs(0.048, 18.0, 22.0))

# ─── RESPONSIVE ────────────────────────────────────────
func _apply_responsive_layout() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var w := maxf(vp.x, 320.0)
	var h := maxf(vp.y, 240.0)
	var min_dim := minf(w, h)

	# Fluid typography
	$TopBar/TopBarLayout/TitleLabel.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.032, 18.0, 28.0)))
	back_btn.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 18.0))

	# Fluid button sizes
	var btn_h := clampf(h * 0.075, 44.0, 52.0)
	back_btn.custom_minimum_size = Vector2(clampf(w * 0.12, 80.0, 120.0), btn_h)

	# Tab bar sizing
	var tab_bar = $TabBar
	var inset := clampf(min_dim * 0.020, 16.0, 24.0)
	tab_bar.offset_left = inset
	tab_bar.offset_right = -inset
	tab_bar.add_theme_constant_override("separation", clampf(min_dim * 0.010, 6.0, 12.0))
	for btn in [towers_tab, enemies_tab]:
		btn.custom_minimum_size = Vector2(0, clampf(min_dim * 0.065, 44.0, 52.0))

	# Content area margins — fluid inset
	var content_area = $ContentArea
	content_area.add_theme_constant_override("margin_left", inset)
	content_area.add_theme_constant_override("margin_right", inset)
	content_area.add_theme_constant_override("margin_top", clampf(min_dim * 0.010, 8.0, 16.0))
	content_area.add_theme_constant_override("margin_bottom", inset)

# ─── TUTORIAL ──────────────────────────────────────────
const TutorialOverlay = preload("res://scenes/core/TutorialOverlay.gd")

func _maybe_show_tutorial() -> void:
	if ProgressManager.has_seen_tutorial("index"):
		return
	await get_tree().process_frame
	var tut = TutorialOverlay.new()
	add_child(tut)
	tut.tutorial_finished.connect(func(): ProgressManager.mark_tutorial_seen("index"))
	tut.start(_get_index_tutorial_steps())

func _get_index_tutorial_steps() -> Array:
	var steps: Array = []
	steps.append({
		"title": "Welcome to the Index",
		"body": "This is your complete catalog of every tower and enemy on the network.\n\nBrowse stats, abilities, and matchups so you know what to deploy.",
		"force_center": true,
	})
	steps.append({
		"title": "Towers & Enemies",
		"body": "Switch between Towers and Enemies using these tabs.\nTap each to explore the full catalog.",
		"highlight": towers_tab.get_path(),
	})
	steps.append({
		"title": "Search",
		"body": "Looking for something specific?\nType here to filter by name or data structure.",
		"highlight": search_field.get_path(),
	})
	steps.append({
		"title": "Tower Cards",
		"body": "Scroll through tower cards to see damage, speed, range, RAM costs, and matchups.\n\nUnlock towers by completing Academy lessons.",
		"highlight": towers_panel.get_path(),
	})
	steps.append({
		"title": "Back Button",
		"body": "Tap here anytime to return to the main menu.",
		"highlight": back_btn.get_path(),
	})
	steps.append({
		"title": "Ready to Explore!",
		"body": "Study the Index to become a stronger operator.\nGood luck out there!",
		"force_center": true,
	})
	return steps
