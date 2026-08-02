# Leaderboard.gd
extends Control

# ─── NODE REFERENCES ───────────────────────────────────
@onready var back_btn: Button           = $TopBar/TopBarLayout/BackBtn
@onready var my_rank_label: Label       = $TopBar/TopBarLayout/MyRankLabel
@onready var global_tab: Button         = $TabBar/GlobalTab
@onready var section_tab: Button        = $TabBar/SectionTab
@onready var global_panel: VBoxContainer  = $ContentArea/ScrollArea/GlobalPanel
@onready var section_panel: VBoxContainer = $ContentArea/ScrollArea/SectionPanel
@onready var global_list: VBoxContainer   = $ContentArea/ScrollArea/GlobalPanel/GlobalList
@onready var section_list: VBoxContainer  = $ContentArea/ScrollArea/SectionPanel/SectionList
@onready var refresh_btn: Button          = $ContentArea/ScrollArea/GlobalPanel/RefreshBtn
@onready var section_refresh_btn: Button  = $ContentArea/ScrollArea/SectionPanel/SectionRefreshBtn

# ─── STATE ─────────────────────────────────────────────
var active_tab: String   = "global"
var global_data: Array   = []
var section_data: Array  = []
var my_rank: int         = -1

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	_setup_buttons()
	_apply_styles()
	_show_global_tab()
	_fetch_global()
	_apply_responsive_layout()
	ScreenManager.make_scroll_touch_friendly($ContentArea/ScrollArea)
	get_tree().root.size_changed.connect(_apply_responsive_layout)
	SupabaseManager.leaderboard_loaded.connect(_on_leaderboard_loaded)
	_maybe_show_tutorial()

# ─── BUTTON SETUP ──────────────────────────────────────
func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	global_tab.pressed.connect(_show_global_tab)
	section_tab.pressed.connect(_show_section_tab)
	refresh_btn.pressed.connect(_fetch_global)
	section_refresh_btn.pressed.connect(_fetch_section)

func _on_back_pressed() -> void:
	GameManager.go_to("main_menu")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to("main_menu")

# ─── TAB SWITCHING ─────────────────────────────────────
func _show_global_tab() -> void:
	active_tab             = "global"
	global_panel.visible   = true
	section_panel.visible  = false
	var tab_font := int(clampf(_current_min_dim() * 0.024, 18.0, 24.0))
	_style_active_tab(global_tab,  true, tab_font)
	_style_active_tab(section_tab, false, tab_font)
	if global_data.is_empty():
		_fetch_global()

func _show_section_tab() -> void:
	active_tab             = "section"
	global_panel.visible   = false
	section_panel.visible  = true
	var tab_font := int(clampf(_current_min_dim() * 0.024, 18.0, 24.0))
	_style_active_tab(global_tab,  false, tab_font)
	_style_active_tab(section_tab, true, tab_font)
	if section_data.is_empty():
		_fetch_section()

# ─── FETCH DATA ────────────────────────────────────────
func _fetch_global() -> void:
	_show_loading(global_list)
	SupabaseManager.fetch_leaderboard("")

func _fetch_section() -> void:
	_show_loading(section_list)
	var my_section = SupabaseManager.section
	if my_section == "":
		_show_error(section_list, "No section found. Please log in.")
		return
	SupabaseManager.fetch_leaderboard(my_section)

func _show_loading(list: VBoxContainer) -> void:
	for child in list.get_children():
		child.queue_free()
	var loading := Label.new()
	loading.text = "Loading..."
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading.add_theme_color_override("font_color", Color("#4A7FA5"))
	loading.add_theme_font_size_override("font_size", int(clampf(_current_min_dim() * 0.018, 16.0, 18.0)))
	list.add_child(loading)

func _show_error(list: VBoxContainer, message: String) -> void:
	for child in list.get_children():
		child.queue_free()
	var error := Label.new()
	error.text = message
	error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error.add_theme_color_override("font_color", Color("#FF3366"))
	error.add_theme_font_size_override("font_size", int(clampf(_current_min_dim() * 0.018, 16.0, 18.0)))
	list.add_child(error)

# ─── DATA RECEIVED ─────────────────────────────────────
func _on_leaderboard_loaded(data: Array) -> void:
	if active_tab == "global":
		global_data = data
		_build_list(global_list, data)
	else:
		section_data = data
		_build_list(section_list, data)
	_find_my_rank(data)

func _find_my_rank(data: Array) -> void:
	var my_id = SupabaseManager.student_id
	for i in range(data.size()):
		if data[i].get("student_id", "") == my_id:
			my_rank = i + 1
			my_rank_label.text = "Your Rank: #" + str(my_rank)
			return
	my_rank_label.text = "Your Rank: —"

# ─── BUILD LIST ────────────────────────────────────────
func _build_list(list: VBoxContainer, data: Array) -> void:
	for child in list.get_children():
		child.queue_free()

	if data.is_empty():
		var empty := Label.new()
		empty.text = "No data yet. Complete lessons to appear here!"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", Color("#4A7FA5"))
		empty.add_theme_font_size_override("font_size", int(clampf(_current_min_dim() * 0.018, 16.0, 18.0)))
		list.add_child(empty)
		return

	for i in range(data.size()):
		var entry = data[i]
		var is_me = entry.get("student_id", "") == SupabaseManager.student_id
		var card  = _make_entry_card(i + 1, entry, is_me)
		list.add_child(card)

func _make_entry_card(
		rank: int,
		entry: Dictionary,
		is_me: bool) -> PanelContainer:

	var compact = _is_layout_compact(get_viewport().get_visible_rect().size.x)
	var min_dim = _current_min_dim()
	var card  := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Card style
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	if compact:
		style.content_margin_left    = 8
		style.content_margin_right   = 8
		style.content_margin_top     = 6
		style.content_margin_bottom  = 6
	else:
		style.content_margin_left    = clampf(min_dim * 0.012, 12.0, 16.0)
		style.content_margin_right   = style.content_margin_left
		style.content_margin_top     = clampf(min_dim * 0.010, 8.0, 12.0)
		style.content_margin_bottom  = style.content_margin_top

	if is_me:
		style.bg_color     = Color("#0D2A1A")
		style.border_color = Color("#00FF88")
	elif rank == 1:
		style.bg_color     = Color("#1A1500")
		style.border_color = Color("#FFD700")
	elif rank == 2:
		style.bg_color     = Color("#141414")
		style.border_color = Color("#C0C0C0")
	elif rank == 3:
		style.bg_color     = Color("#1A0E00")
		style.border_color = Color("#CD7F32")
	else:
		style.bg_color     = Color("#0A1628")
		style.border_color = Color("#1A3A5A")

	card.add_theme_stylebox_override("panel", style)

	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", clampf(min_dim * 0.009, 6.0, 16.0))

	# ── Rank ──
	var rank_label := Label.new()
	rank_label.custom_minimum_size = Vector2(clampf(min_dim * 0.045, 30.0, 40.0), 0)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.022, 16.0, 22.0)))

	match rank:
		1: rank_label.text = "🥇"
		2: rank_label.text = "🥈"
		3: rank_label.text = "🥉"
		_: rank_label.text = "#" + str(rank)

	if rank > 3:
		rank_label.add_theme_color_override(
				"font_color",
				Color("#00FF88") if is_me else Color("#4A7FA5")
		)
	layout.add_child(rank_label)

	# ── Name + Section ──
	var name_section := VBoxContainer.new()
	name_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_section.add_theme_constant_override("separation", 2)

	var name_label := Label.new()
	name_label.text = entry.get("username", "Unknown")
	if is_me:
		name_label.text += " (You)"
	name_label.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.021, 16.0, 19.0)))
	name_label.add_theme_color_override(
		"font_color",
		Color("#00FF88") if is_me else Color("#E8F4FD")
	)
	name_section.add_child(name_label)

	var section_label := Label.new()
	section_label.text = entry.get("section", "")
	section_label.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.014, 16.0, 15.0)))
	section_label.add_theme_color_override("font_color", Color("#4A7FA5"))
	name_section.add_child(section_label)

	layout.add_child(name_section)

	# ── Stats ──
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", clampf(min_dim * 0.013, 8.0, 20.0))

	_add_stat_column(
	stats, "TOPICS",
	str(int(entry.get("topics_mastered", 0))) + "/" + str(DataRegistry.get_lesson_count()),
	Color("#00D4FF"), min_dim, compact
	)
	_add_stat_column(
		stats, "STARS",
		str(int(entry.get("total_stars", 0))) + "/" + str(DataRegistry.get_total_stars_possible()),
		Color("#FFB800"), min_dim, compact
	)

	# Score — most prominent
	_add_stat_column(
	stats, "SCORE",
	str(int(entry.get("score", 0))),
	Color("#00FF88") if is_me else Color("#FFD700") if rank == 1 else Color("#E8F4FD"),
	min_dim, compact
	)

	layout.add_child(stats)
	card.add_child(layout)
	return card

func _add_stat_column(
		container: HBoxContainer,
		label: String,
		value: String,
		color: Color,
		min_dim: float,
		compact: bool) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.custom_minimum_size = Vector2(clampf(min_dim * 0.045, 40.0, 70.0), 0)

	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.014, 16.0, 15.0)))
	lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(lbl)

	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.019, 16.0, 19.0)))
	val.add_theme_color_override("font_color", color)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(val)

	container.add_child(col)

func _format_time(seconds: float) -> String:
	if seconds <= 0:
		return "0m"
	var mins = int(seconds / 60)
	var hrs  = int(mins / 60)
	mins     = mins % 60
	if hrs > 0:
		return str(hrs) + "h " + str(mins) + "m"
	return str(mins) + "m"

# ─── STYLES ────────────────────────────────────────────
func _apply_styles() -> void:
	# TopBar
	var top_style := StyleBoxFlat.new()
	top_style.bg_color          = Color("#0A1628")
	top_style.border_color      = Color("#00D4FF")
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
	# font_size set dynamically in _apply_responsive_layout()

	# Refresh buttons
	for btn in [refresh_btn, section_refresh_btn]:
		var r_style := StyleBoxFlat.new()
		r_style.bg_color               = Color("#0A1628")
		r_style.border_color           = Color("#4A7FA5")
		r_style.border_width_left      = 1
		r_style.border_width_right     = 1
		r_style.border_width_top       = 1
		r_style.border_width_bottom    = 1
		r_style.corner_radius_top_left     = 4
		r_style.corner_radius_top_right    = 4
		r_style.corner_radius_bottom_left  = 4
		r_style.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override("normal", r_style)
		btn.add_theme_color_override("font_color", Color("#4A7FA5"))

func _style_active_tab(btn: Button, active: bool, font_size: int) -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left     = 0
	style.corner_radius_top_right    = 0
	style.corner_radius_bottom_left  = 0
	style.corner_radius_bottom_right = 0
	if active:
		style.bg_color            = Color("#0D2040")
		style.border_color        = Color("#00D4FF")
		style.border_width_bottom = 2
		btn.add_theme_color_override("font_color", Color("#00D4FF"))
	else:
		style.bg_color            = Color("#080F1E")
		style.border_color        = Color("#080F1E")
		style.border_width_bottom = 2
		btn.add_theme_color_override("font_color", Color("#4A7FA5"))
	btn.add_theme_stylebox_override("normal",  style)
	btn.add_theme_stylebox_override("hover",   style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_font_size_override("font_size", font_size)

# ─── RESPONSIVE ────────────────────────────────────────
func _apply_responsive_layout() -> void:
	var vp := get_viewport().get_visible_rect().size
	var w := maxf(vp.x, 320.0)
	var h := maxf(vp.y, 240.0)
	var min_dim := minf(w, h)

	# Continuous typography
	$TopBar/TopBarLayout/TitleLabel.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.032, 20.0, 28.0)))
	back_btn.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.025, 16.0, 20.0)))
	my_rank_label.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.022, 16.0, 20.0)))
	back_btn.custom_minimum_size = Vector2(clampf(w * 0.12, 80.0, 120.0), clampf(h * 0.07, 44.0, 56.0))

	# Tab bar sizing
	var tab_bar = $TabBar
	tab_bar.add_theme_constant_override("separation", clampf(min_dim * 0.010, 6.0, 12.0))
	for btn in [global_tab, section_tab]:
		btn.custom_minimum_size = Vector2(0, clampf(min_dim * 0.065, 44.0, 52.0))

	# Content area margins — fluid inset
	var inset := clampf(min_dim * 0.020, 16.0, 24.0)
	$ContentArea.add_theme_constant_override("margin_left", inset)
	$ContentArea.add_theme_constant_override("margin_right", inset)
	$ContentArea.add_theme_constant_override("margin_top", clampf(min_dim * 0.010, 8.0, 16.0))
	$ContentArea.add_theme_constant_override("margin_bottom", inset)

	# Tab button font sizes
	var tab_font := int(clampf(min_dim * 0.024, 18.0, 24.0))
	_style_active_tab(global_tab, active_tab == "global", tab_font)
	_style_active_tab(section_tab, active_tab == "section", tab_font)

	# Refresh button sizing
	var refresh_font := int(clampf(min_dim * 0.022, 16.0, 20.0))
	for btn in [refresh_btn, section_refresh_btn]:
		btn.add_theme_font_size_override("font_size", refresh_font)
		btn.custom_minimum_size = Vector2(clampf(w * 0.15, 100.0, 130.0), clampf(h * 0.08, 42.0, 52.0))

	# Rebuild cards if compact mode changed
	var new_compact = _is_layout_compact(w)
	if new_compact != _last_compact:
		_last_compact = new_compact
		var list = global_list if active_tab == "global" else section_list
		if not list.get_children().is_empty():
			_rebuild_current_list()

var _last_compact: bool = false

func _is_layout_compact(viewport_w: float) -> bool:
	return viewport_w < 600.0

func _rebuild_current_list() -> void:
	if active_tab == "global":
		_build_list(global_list, global_data)
	else:
		_build_list(section_list, section_data)

func _current_min_dim() -> float:
	var vp := get_viewport().get_visible_rect().size
	return minf(maxf(vp.x, 320.0), maxf(vp.y, 240.0))

# ─── TUTORIAL ──────────────────────────────────────────
const TutorialOverlay = preload("res://scenes/core/TutorialOverlay.gd")

func _maybe_show_tutorial() -> void:
	if ProgressManager.has_seen_tutorial("leaderboard"):
		return
	await get_tree().process_frame
	var tut = TutorialOverlay.new()
	add_child(tut)
	tut.tutorial_finished.connect(func(): ProgressManager.mark_tutorial_seen("leaderboard"))
	tut.start(_get_leaderboard_tutorial_steps())

func _get_leaderboard_tutorial_steps() -> Array:
	var steps: Array = []
	steps.append({
		"title": "Leaderboard",
		"body": "See how you stack up against other operators on the network.\n\nClimb the ranks by mastering topics and earning stars.",
		"force_center": true,
	})
	steps.append({
		"title": "Your Rank",
		"body": "Your current global rank is shown here. Complete more lessons to rank up!",
		"highlight": my_rank_label.get_path(),
	})
	steps.append({
		"title": "Global Tab",
		"body": "See the top players across the entire network.",
		"highlight": global_tab.get_path(),
	})
	steps.append({
		"title": "Section Tab",
		"body": "Compare yourself with classmates in your section only.",
		"highlight": section_tab.get_path(),
	})
	steps.append({
		"title": "Leaderboard Cards",
		"body": "Cards show rank, name, section, topics mastered, stars, and score.\nYour own card is highlighted in green.",
		"highlight": global_list.get_path(),
	})
	steps.append({
		"title": "Refresh",
		"body": "Tap this button to reload the latest rankings.",
		"highlight": refresh_btn.get_path(),
	})
	steps.append({
		"title": "Back",
		"body": "Tap here anytime to return to the main menu.",
		"highlight": back_btn.get_path(),
	})
	steps.append({
		"title": "Ready to Compete!",
		"body": "Top tip: mastering topics in the Academy boosts your score fast.\nGood luck, operator!",
		"force_center": true,
	})
	return steps
