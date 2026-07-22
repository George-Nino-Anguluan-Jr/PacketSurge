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
	get_tree().root.size_changed.connect(_apply_responsive_layout)
	SupabaseManager.leaderboard_loaded.connect(_on_leaderboard_loaded)

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
	_style_active_tab(global_tab,  true)
	_style_active_tab(section_tab, false)
	if global_data.is_empty():
		_fetch_global()

func _show_section_tab() -> void:
	active_tab             = "section"
	global_panel.visible   = false
	section_panel.visible  = true
	_style_active_tab(global_tab,  false)
	_style_active_tab(section_tab, true)
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
	loading.add_theme_font_size_override("font_size", 14)
	list.add_child(loading)

func _show_error(list: VBoxContainer, message: String) -> void:
	for child in list.get_children():
		child.queue_free()
	var error := Label.new()
	error.text = message
	error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error.add_theme_color_override("font_color", Color("#FF3366"))
	error.add_theme_font_size_override("font_size", 14)
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
		empty.add_theme_font_size_override("font_size", 14)
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

	var compact = ScreenManager.is_mobile()
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
		style.content_margin_left    = 10
		style.content_margin_right   = 10
		style.content_margin_top     = 8
		style.content_margin_bottom  = 8
	else:
		style.content_margin_left    = 16
		style.content_margin_right   = 16
		style.content_margin_top     = 12
		style.content_margin_bottom  = 12

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
	layout.add_theme_constant_override("separation", 8 if compact else 16)

	# ── Rank ──
	var rank_label := Label.new()
	rank_label.custom_minimum_size = Vector2(32 if compact else 40, 0)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.add_theme_font_size_override("font_size", 16 if compact else 20)

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
	name_label.add_theme_font_size_override("font_size", 13 if compact else 15)
	name_label.add_theme_color_override(
		"font_color",
		Color("#00FF88") if is_me else Color("#E8F4FD")
	)
	name_section.add_child(name_label)

	var section_label := Label.new()
	section_label.text = entry.get("section", "")
	section_label.add_theme_font_size_override("font_size", 10 if compact else 11)
	section_label.add_theme_color_override("font_color", Color("#4A7FA5"))
	name_section.add_child(section_label)

	layout.add_child(name_section)

	# ── Stats ──
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 12 if compact else 20)

	_add_stat_column(
	stats, "TOPICS",
	str(int(entry.get("topics_mastered", 0))) + "/18",
	Color("#00D4FF")
	)
	_add_stat_column(
		stats, "STARS",
		str(int(entry.get("total_stars", 0))) + "/39",
		Color("#FFB800")
	)

	# Score — most prominent
	_add_stat_column(
	stats, "SCORE",
	str(int(entry.get("score", 0))),
	Color("#00FF88") if is_me else Color("#FFD700") if rank == 1 else Color("#E8F4FD")
	)

	layout.add_child(stats)
	card.add_child(layout)
	return card

func _add_stat_column(
		container: HBoxContainer,
		label: String,
		value: String,
		color: Color) -> void:
	var compact = ScreenManager.is_mobile()
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.custom_minimum_size = Vector2(50 if compact else 60, 0)

	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 9 if compact else 10)
	lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(lbl)

	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 12 if compact else 14)
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
		btn.add_theme_font_size_override("font_size", 12)

func _style_active_tab(btn: Button, active: bool) -> void:
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
	btn.add_theme_font_size_override("font_size", 14)

# ─── RESPONSIVE ────────────────────────────────────────
func _apply_responsive_layout() -> void:
	var content_area = $ContentArea
	var title_label = $TopBar/TopBarLayout/TitleLabel
	
	if ScreenManager.is_mobile():
		my_rank_label.visible = false
		content_area.add_theme_constant_override("margin_left", 8)
		content_area.add_theme_constant_override("margin_right", 8)
		content_area.add_theme_constant_override("margin_top", 8)
		content_area.add_theme_constant_override("margin_bottom", 8)
		title_label.add_theme_font_size_override("font_size", 14)
		back_btn.custom_minimum_size = Vector2(70, 44)
	elif ScreenManager.is_tablet():
		my_rank_label.visible = true
		content_area.add_theme_constant_override("margin_left", 12)
		content_area.add_theme_constant_override("margin_right", 12)
		content_area.add_theme_constant_override("margin_top", 12)
		content_area.add_theme_constant_override("margin_bottom", 12)
		title_label.add_theme_font_size_override("font_size", 15)
		back_btn.custom_minimum_size = Vector2(80, 44)
	else:
		my_rank_label.visible = true
		content_area.add_theme_constant_override("margin_left", 16)
		content_area.add_theme_constant_override("margin_right", 16)
		content_area.add_theme_constant_override("margin_top", 16)
		content_area.add_theme_constant_override("margin_bottom", 16)
		title_label.add_theme_font_size_override("font_size", 16)
		back_btn.custom_minimum_size = Vector2(90, 0)
