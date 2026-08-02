extends Control

# ─── NODE REFERENCES ───────────────────────────────────
@onready var back_btn: Button         = $TopBar/TopBarLayout/BackBtn
@onready var my_stats_tab: Button     = $TabBar/MyStatsTab
@onready var class_tab: Button        = $TabBar/ClassTab
@onready var my_stats_panel: ScrollContainer = $ContentArea/MyStatsPanel
@onready var class_panel: ScrollContainer    = $ContentArea/ClassPanel
@onready var my_stats_content: VBoxContainer = $ContentArea/MyStatsPanel/MyStatsContent
@onready var class_content: VBoxContainer    = $ContentArea/ClassPanel/ClassContent

# ─── STATE ─────────────────────────────────────────────
var active_tab: String  = "my_stats"
var class_data: Array   = []

# ─── HELPERS ───────────────────────────────────────────
func _min_dim() -> float:
	var vp := get_viewport().get_visible_rect().size
	return minf(maxf(vp.x, 320.0), maxf(vp.y, 240.0))

func _fs(ratio: float, floor_v: float, cap_v: float) -> int:
	return int(clampf(_min_dim() * ratio, floor_v, cap_v))

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	_setup_buttons()
	_apply_styles()
	_show_my_stats_tab()
	_apply_responsive_layout()
	ScreenManager.make_scroll_touch_friendly(my_stats_panel)
	ScreenManager.make_scroll_touch_friendly(class_panel)
	get_tree().root.size_changed.connect(_apply_responsive_layout)
	SupabaseManager.leaderboard_loaded.connect(_on_class_data_loaded)
	_maybe_show_tutorial()

# ─── BUTTON SETUP ──────────────────────────────────────
func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	my_stats_tab.pressed.connect(_show_my_stats_tab)
	class_tab.pressed.connect(_show_class_tab)

func _on_back_pressed() -> void:
	GameManager.go_to("main_menu")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to("main_menu")

# ─── TAB SWITCHING ─────────────────────────────────────
func _show_my_stats_tab() -> void:
	active_tab              = "my_stats"
	my_stats_panel.visible  = true
	class_panel.visible     = false
	_style_active_tab(my_stats_tab, true)
	_style_active_tab(class_tab,    false)
	_build_my_stats()

func _show_class_tab() -> void:
	active_tab              = "class"
	my_stats_panel.visible  = false
	class_panel.visible     = true
	_style_active_tab(my_stats_tab, false)
	_style_active_tab(class_tab,    true)
	_fetch_class_data()

# ─── MY STATS ──────────────────────────────────────────
func _build_my_stats() -> void:
	for child in my_stats_content.get_children():
		child.queue_free()

	# ── Overview Cards ──
	my_stats_content.add_child(_make_section_title("OVERVIEW"))
	my_stats_content.add_child(_make_overview_cards())

	# ── Progress Chart ──
	my_stats_content.add_child(_make_section_title("LESSON PROGRESS"))
	my_stats_content.add_child(_make_progress_chart())

	# ── Accuracy Chart ──
	my_stats_content.add_child(_make_section_title("CHALLENGE ACCURACY"))
	my_stats_content.add_child(_make_accuracy_chart())

	# ── Time Spent ──
	my_stats_content.add_child(_make_section_title("TIME PER LESSON"))
	my_stats_content.add_child(_make_time_chart())

	# ── Lesson Breakdown ──
	my_stats_content.add_child(_make_section_title("LESSON BREAKDOWN"))
	my_stats_content.add_child(_make_lesson_breakdown())

	# ── Campaign Time ──
	my_stats_content.add_child(_make_section_title("CAMPAIGN LEVELS"))
	my_stats_content.add_child(_make_campaign_breakdown())

func _make_overview_cards() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Count mastered
	var mastered := 0
	for t in ProgressManager.topic_states:
		if ProgressManager.topic_states[t] == "mastered":
			mastered += 1

	# Count unlocked
	var unlocked := 0
	for t in ProgressManager.topic_states:
		if ProgressManager.topic_states[t] in ["unlocked", "mastered"]:
			unlocked += 1

	# Total time
	var total_time: float = 0.0
	for t in ProgressManager.time_spent:
		total_time += float(ProgressManager.time_spent[t])
	for t in ProgressManager.campaign_time:
		total_time += float(ProgressManager.campaign_time[t])

	# Campaign levels
	var levels = ProgressManager.campaign_progress.get(
		"waves_completed", 0
	)

	row.add_child(_make_stat_card(
		"LESSONS\nMASTERED", str(mastered) + "/" + str(DataRegistry.get_lesson_count()),
		Color("#00FF88")
	))
	row.add_child(_make_stat_card(
		"CAMPAIGN\nLEVELS", str(levels) + "/" + str(DataRegistry.get_level_count()),
		Color("#FFB800")
	))
	row.add_child(_make_stat_card(
		"TOTAL\nTIME", _format_time(total_time),
		Color("#9B59B6")
	))
	return row

func _make_stat_card(
		label: String,
		value: String,
		color: Color) -> PanelContainer:
	var card  := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size   = Vector2(0, _fs(0.21, 80.0, 100.0))

	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = color
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left    = 12
	style.content_margin_right   = 12
	style.content_margin_top     = 12
	style.content_margin_bottom  = 12
	card.add_theme_stylebox_override("panel", style)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 4)

	var val_label := Label.new()
	val_label.text = value
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_label.add_theme_font_size_override("font_size", _fs(0.055, 22.0, 32.0))
	val_label.add_theme_color_override("font_color", color)
	layout.add_child(val_label)

	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
	lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	layout.add_child(lbl)

	card.add_child(layout)
	return card

# ─── PROGRESS CHART ────────────────────────────────────
func _make_progress_chart() -> Control:
	var chart := Control.new()
	chart.custom_minimum_size   = Vector2(0, _fs(0.45, 180.0, 240.0))
	chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#080F1E")
	style.border_color           = Color("#0D2040")
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6

	var topics = DataRegistry.get_lesson_ids()

	chart.draw.connect(func():
		var size    = chart.size
		if size.x == 0:
			return
		var count   = topics.size()
		var bar_w   = (size.x - 40) / count
		var max_h   = size.y - 40

		for i in range(count):
			var topic   = topics[i]
			var state   = ProgressManager.topic_states.get(topic, "locked")
			var x       = 20 + i * bar_w
			var bar_col: Color

			match state:
				"mastered":  bar_col = Color("#00FF88")
				"unlocked":  bar_col = Color("#00D4FF")
				_:           bar_col = Color("#1A3A5A")

			var bar_h   = max_h if state == "mastered" \
						  else max_h * 0.5 if state == "unlocked" \
						  else max_h * 0.1
			var rect    = Rect2(
				x + 2, size.y - 20 - bar_h,
				bar_w - 4, bar_h
			)
			chart.draw_rect(rect, Color(bar_col, 0.3))
			chart.draw_rect(rect, bar_col, false, 1.5)

		# Legend
		chart.draw_string(
			ThemeDB.fallback_font,
			Vector2(20, size.y - 4),
			"■ Mastered  ■ Unlocked  ■ Locked",
			HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(0.032, 16.0, 16.0),
			Color("#4A7FA5")
		)
	)
	chart.queue_redraw()
	return chart

# ─── ACCURACY CHART ────────────────────────────────────
func _make_accuracy_chart() -> Control:
	var chart := Control.new()
	chart.custom_minimum_size   = Vector2(0, _fs(0.40, 160.0, 220.0))
	chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var topics = DataRegistry.get_lesson_ids()

	chart.draw.connect(func():
		var size   = chart.size
		if size.x == 0:
			return
		var count  = topics.size()
		var bar_w  = (size.x - 40) / count
		var max_h  = size.y - 40

		for i in range(count):
			var topic   = topics[i]
			var mastered = ProgressManager.topic_states.get(topic, "locked") == "mastered"
			var x       = 20 + i * bar_w
			var bar_h   = max_h * (1.0 if mastered else 0.3)
			var bar_col = Color("#00FF88") if mastered else Color("#4A7FA5")

			if mastered:
				var rect = Rect2(
					x + 2, size.y - 20 - bar_h,
					bar_w - 4, bar_h
				)
				chart.draw_rect(rect, Color(bar_col, 0.3))
				chart.draw_rect(rect, bar_col, false, 1.5)
			else:
				# Empty bar placeholder
				var rect = Rect2(
					x + 2, size.y - 20 - max_h * 0.05,
					bar_w - 4, max_h * 0.05
				)
				chart.draw_rect(rect, Color("#1A3A5A"))

		# Baseline
		chart.draw_line(
			Vector2(20, size.y - 20),
			Vector2(size.x - 20, size.y - 20),
			Color("#1A3A5A"), 1.0
		)
	)
	chart.queue_redraw()
	return chart

# ─── TIME CHART ────────────────────────────────────────
func _make_time_chart() -> Control:
	var chart := Control.new()
	chart.custom_minimum_size   = Vector2(0, _fs(0.40, 160.0, 220.0))
	chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var topics = DataRegistry.get_lesson_ids()

	chart.draw.connect(func():
		var size    = chart.size
		if size.x == 0:
			return

		# Find max time for scaling
		var max_time: float = 1.0
		for t in topics:
			var time = float(ProgressManager.time_spent.get(t, 0.0))
			if time > max_time:
				max_time = time

		var count  = topics.size()
		var bar_w  = (size.x - 40) / count
		var max_h  = size.y - 40

		for i in range(count):
			var topic  = topics[i]
			var time   = float(ProgressManager.time_spent.get(topic, 0.0))
			var x      = 20 + i * bar_w
			var bar_h  = (time / max_time) * max_h if max_time > 0 else 0

			if time > 0:
				var rect = Rect2(
					x + 2, size.y - 20 - bar_h,
					bar_w - 4, bar_h
				)
				chart.draw_rect(rect, Color("#9B59B6", 0.3))
				chart.draw_rect(rect, Color("#9B59B6"), false, 1.5)

				# Time label
				var mins = int(time / 60)
				var secs = int(time) % 60
				if mins > 0:
					chart.draw_string(
						ThemeDB.fallback_font,
						Vector2(x + 2, size.y - 22 - bar_h),
						str(mins) + "m " + str(secs) + "s",
					HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(0.030, 16.0, 16.0),
						Color("#9B59B6")
					)
				else:
					chart.draw_string(
						ThemeDB.fallback_font,
						Vector2(x + 2, size.y - 22 - bar_h),
						str(secs) + "s",
					HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(0.030, 16.0, 16.0),
						Color("#9B59B6")
					)
			else:
				var rect = Rect2(
					x + 2, size.y - 20 - max_h * 0.05,
					bar_w - 4, max_h * 0.05
				)
				chart.draw_rect(rect, Color("#1A3A5A"))

		chart.draw_line(
			Vector2(20, size.y - 20),
			Vector2(size.x - 20, size.y - 20),
			Color("#1A3A5A"), 1.0
		)
	)
	chart.queue_redraw()
	return chart

# ─── LESSON BREAKDOWN ──────────────────────────────────
func _make_lesson_breakdown() -> VBoxContainer:
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 8)

	var topic_ids = DataRegistry.get_lesson_ids()

	for topic_id in topic_ids:
		var state    = ProgressManager.topic_states.get(topic_id, "locked")
		var time     = float(ProgressManager.time_spent.get(topic_id, 0.0))
		var row      = _make_lesson_row(
			GameManager.LESSON_NAMES.get(topic_id, topic_id), state, time
		)
		layout.add_child(row)

	return layout

func _make_lesson_row(
		name: String,
		state: String,
		time: float) -> PanelContainer:

	var card  := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.content_margin_left    = 12
	style.content_margin_right   = 12
	style.content_margin_top     = 8
	style.content_margin_bottom  = 8

	match state:
		"mastered": style.border_color = Color("#00FF88")
		"unlocked": style.border_color = Color("#00D4FF")
		_:          style.border_color = Color("#1A3A5A")
	card.add_theme_stylebox_override("panel", style)

	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)

	# State icon
	var icon := Label.new()
	icon.custom_minimum_size = Vector2(_fs(0.06, 20.0, 28.0), 0)
	match state:
		"mastered": icon.text = "✅"
		"unlocked": icon.text = "🔓"
		_:          icon.text = "🔒"
	icon.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 18.0))
	layout.add_child(icon)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = name
	name_lbl.custom_minimum_size    = Vector2(_fs(0.35, 110.0, 130.0), 0)
	name_lbl.add_theme_font_size_override("font_size", _fs(0.038, 16.0, 18.0))
	match state:
		"mastered": name_lbl.add_theme_color_override("font_color", Color("#00FF88"))
		"unlocked": name_lbl.add_theme_color_override("font_color", Color("#E8F4FD"))
		_:          name_lbl.add_theme_color_override("font_color", Color("#2A3A4A"))
	layout.add_child(name_lbl)

	if state in ["unlocked", "mastered"]:
		# Time
		var time_lbl := Label.new()
		time_lbl.text = _format_time(time)
		time_lbl.custom_minimum_size = Vector2(_fs(0.10, 50.0, 60.0), 0)
		time_lbl.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
		time_lbl.add_theme_color_override("font_color", Color("#9B59B6"))
		time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		layout.add_child(time_lbl)

	card.add_child(layout)
	return card

# ─── CAMPAIGN BREAKDOWN ────────────────────────────────
func _make_campaign_breakdown() -> VBoxContainer:
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 8)

	for level_num in DataRegistry.get_level_numbers():
		var time = float(ProgressManager.campaign_time.get(str(level_num), 0.0))
		var stars = ProgressManager.get_level_stars(level_num)
		var cfg = GameManager.LEVEL_CONFIGS.get(level_num, {})
		var name = cfg.get("name", "Level " + str(level_num))
		layout.add_child(_make_campaign_row(level_num, name, time, stars))

	return layout

func _make_campaign_row(
		level_num: int,
		name: String,
		time: float,
		stars: int) -> PanelContainer:

	var card  := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.content_margin_left    = 12
	style.content_margin_right   = 12
	style.content_margin_top     = 8
	style.content_margin_bottom  = 8

	match stars:
		0: style.border_color = Color("#1A3A5A")
		1: style.border_color = Color("#FFB800")
		2: style.border_color = Color("#B8960F")
		3: style.border_color = Color("#00FF88")
	card.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)

	var level_lbl := Label.new()
	level_lbl.text = "Level " + str(level_num)
	level_lbl.custom_minimum_size = Vector2(_fs(0.18, 70.0, 90.0), 0)
	level_lbl.add_theme_font_size_override("font_size", _fs(0.038, 16.0, 18.0))
	level_lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	hbox.add_child(level_lbl)

	var name_lbl := Label.new()
	name_lbl.text = name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", _fs(0.038, 16.0, 18.0))
	var unlocked = stars > 0
	if stars == 0:
		name_lbl.add_theme_color_override("font_color", Color("#2A3A4A"))
	else:
		name_lbl.add_theme_color_override("font_color", Color("#E8F4FD"))
	hbox.add_child(name_lbl)

	var stars_lbl := Label.new()
	stars_lbl.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	stars_lbl.custom_minimum_size = Vector2(_fs(0.10, 42.0, 56.0), 0)
	stars_lbl.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
	stars_lbl.add_theme_color_override("font_color", Color("#FFB800"))
	stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(stars_lbl)

	var time_lbl := Label.new()
	time_lbl.text = _format_time(time) if stars > 0 else "--"
	time_lbl.custom_minimum_size = Vector2(_fs(0.14, 60.0, 70.0), 0)
	time_lbl.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
	time_lbl.add_theme_color_override("font_color", Color("#9B59B6"))
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(time_lbl)

	card.add_child(hbox)
	return card

# ─── CLASS COMPARISON ──────────────────────────────────
func _fetch_class_data() -> void:
	for child in class_content.get_children():
		child.queue_free()
	var loading := Label.new()
	loading.text = "Loading class data..."
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading.add_theme_color_override("font_color", Color("#4A7FA5"))
	loading.add_theme_font_size_override("font_size", _fs(0.028, 16.0, 18.0))
	class_content.add_child(loading)
	SupabaseManager.fetch_leaderboard(SupabaseManager.section)

func _on_class_data_loaded(data: Array) -> void:
	if active_tab != "class":
		return
	class_data = data
	_build_class_comparison()

func _build_class_comparison() -> void:
	for child in class_content.get_children():
		child.queue_free()

	if class_data.is_empty():
		var empty := Label.new()
		empty.text = "No class data available yet."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", Color("#4A7FA5"))
		empty.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
		class_content.add_child(empty)
		return

	# Calculate class averages
	var total_mastered: float   = 0.0
	var total_stars: float    = 0.0
	var total_score: float    = 0.0
	var count = class_data.size()

	for entry in class_data:
		total_mastered += float(entry.get("topics_mastered",           0))
		total_stars    += float(entry.get("total_stars",             0))
		total_score    += float(entry.get("score",                     0))

	var avg_mastered = total_mastered / count
	var avg_stars    = total_stars    / count
	var avg_score    = total_score    / count

	# My stats
	var my_mastered: float = 0.0
	for t in ProgressManager.topic_states:
		if ProgressManager.topic_states[t] == "mastered":
			my_mastered += 1.0
	var my_stars: float = 0.0
	var star_map = ProgressManager.campaign_progress.get("level_stars", {})
	for level_num in star_map:
		my_stars += float(star_map[level_num])

	# Section title
	class_content.add_child(
		_make_section_title(
			"SECTION: " + SupabaseManager.section.to_upper() + \
			"  (" + str(count) + " students)"
		)
	)

	# Comparison cards
	class_content.add_child(_make_comparison_row(
		"Topics Mastered",
		my_mastered, avg_mastered, float(DataRegistry.get_lesson_count()),
		Color("#00D4FF")
	))
	class_content.add_child(_make_comparison_row(
		"Total Stars",
		my_stars, avg_stars, float(DataRegistry.get_total_stars_possible()),
		Color("#FFB800")
	))
	class_content.add_child(_make_comparison_row(
		"Score",
		0.0, avg_score, 2850.0,
		Color("#00FF88"),
		true
	))

	# Class leaderboard mini
	class_content.add_child(
		_make_section_title("CLASS RANKING")
	)
	class_content.add_child(_make_mini_leaderboard())

func _make_comparison_row(
		label: String,
		my_val: float,
		avg_val: float,
		max_val: float,
		color: Color,
		score_mode: bool = false) -> PanelContainer:

	var card  := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = color
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left    = 16
	style.content_margin_right   = 16
	style.content_margin_top     = 12
	style.content_margin_bottom  = 12
	card.add_theme_stylebox_override("panel", style)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)

	# Label row
	var title_row := HBoxContainer.new()
	var title_lbl := Label.new()
	title_lbl.text = label
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", _fs(0.038, 16.0, 18.0))
	title_lbl.add_theme_color_override("font_color", Color("#E8F4FD"))
	title_row.add_child(title_lbl)

	# vs label
	if not score_mode:
		var vs_lbl := Label.new()
		var diff   = my_val - avg_val
		vs_lbl.text = ("▲ +" if diff > 0 else "▼ ") + \
					  str(snappedf(diff, 0.1)) + " vs avg"
		vs_lbl.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
		vs_lbl.add_theme_color_override(
			"font_color",
			Color("#00FF88") if diff >= 0 else Color("#FF3366")
		)
		title_row.add_child(vs_lbl)
	layout.add_child(title_row)

	if not score_mode:
		# My bar
		layout.add_child(_make_bar_row(
			"You", my_val, max_val, color
		))
		# Class average bar
		layout.add_child(_make_bar_row(
			"Class Avg", avg_val, max_val, Color("#4A7FA5")
		))
	else:
		# Just show class average score
		layout.add_child(_make_bar_row(
			"Class Avg", avg_val, max_val, Color("#4A7FA5")
		))

	card.add_child(layout)
	return card

func _make_bar_row(
		label: String,
		value: float,
		max_val: float,
		color: Color) -> HBoxContainer:

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(_fs(0.22, 80.0, 100.0), 0)
	lbl.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
	lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	row.add_child(lbl)

	# Bar background
	var bar_container := Control.new()
	bar_container.custom_minimum_size   = Vector2(0, _fs(0.055, 18.0, 24.0))
	bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var ratio = clamp(value / max_val, 0.0, 1.0) if max_val > 0 else 0.0
	bar_container.draw.connect(func():
		var w = bar_container.size.x
		var h = bar_container.size.y
		# Background
		bar_container.draw_rect(
			Rect2(0, 0, w, h), Color("#1A3A5A")
		)
		# Fill
		bar_container.draw_rect(
			Rect2(0, 0, w * ratio, h), Color(color, 0.8)
		)
	)
	bar_container.queue_redraw()
	row.add_child(bar_container)

	var val_lbl := Label.new()
	val_lbl.text = str(int(value))
	val_lbl.custom_minimum_size = Vector2(_fs(0.08, 30.0, 40.0), 0)
	val_lbl.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
	val_lbl.add_theme_color_override("font_color", color)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_lbl)

	return row

func _make_mini_leaderboard() -> VBoxContainer:
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 6)

	var my_id = SupabaseManager.student_id
	for i in range(min(class_data.size(), 5)):
		var entry  = class_data[i]
		var is_me  = entry.get("student_id", "") == my_id
		var row    := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		# Rank
		var rank_lbl := Label.new()
		rank_lbl.text = "#" + str(i + 1)
		rank_lbl.custom_minimum_size = Vector2(_fs(0.08, 32.0, 40.0), 0)
		rank_lbl.add_theme_font_size_override("font_size", _fs(0.038, 16.0, 18.0))
		rank_lbl.add_theme_color_override(
			"font_color",
			Color("#00FF88") if is_me else Color("#4A7FA5")
		)
		row.add_child(rank_lbl)

		# Name
		var name_lbl := Label.new()
		name_lbl.text = entry.get("username", "?")
		if is_me:
			name_lbl.text += " ← You"
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", _fs(0.038, 16.0, 18.0))
		name_lbl.add_theme_color_override(
			"font_color",
			Color("#00FF88") if is_me else Color("#E8F4FD")
		)
		row.add_child(name_lbl)

		# Score
		var score_lbl := Label.new()
		score_lbl.text = str(int(entry.get("score", 0))) + " pts"
		score_lbl.add_theme_font_size_override("font_size", _fs(0.038, 16.0, 18.0))
		score_lbl.add_theme_color_override(
			"font_color",
			Color("#00FF88") if is_me else Color("#FFB800")
		)
		row.add_child(score_lbl)

		layout.add_child(row)

	return layout

# ─── HELPERS ───────────────────────────────────────────
func _make_section_title(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 18.0))
	lbl.add_theme_color_override("font_color", Color("#00D4FF"))
	return lbl

func _format_time(seconds: float) -> String:
	if seconds <= 0:
		return "0s"
	var hrs  = int(seconds / 3600)
	var mins = int(seconds / 60) % 60
	var secs = int(seconds) % 60
	if hrs > 0:
		return str(hrs) + "h " + str(mins) + "m"
	if mins > 0:
		return str(mins) + "m " + str(secs) + "s"
	return str(secs) + "s"

# ─── STYLES ────────────────────────────────────────────
func _apply_styles() -> void:
	var top_style := StyleBoxFlat.new()
	top_style.bg_color          = Color("#0A1628")
	top_style.border_color      = Color("#00D4FF")
	top_style.border_width_bottom = 1
	$TopBar.add_theme_stylebox_override("panel", top_style)

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
	btn.add_theme_font_size_override("font_size", _fs(0.048, 18.0, 22.0))

# ─── RESPONSIVE ────────────────────────────────────────
func _apply_responsive_layout() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var w := maxf(vp.x, 320.0)
	var h := maxf(vp.y, 240.0)
	var min_dim := minf(w, h)

	# Fluid typography
	$TopBar/TopBarLayout/TitleLabel.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.030, 18.0, 28.0)))
	back_btn.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 20.0))

	# Fluid button sizes
	var btn_h := clampf(h * 0.075, 44.0, 52.0)
	back_btn.custom_minimum_size = Vector2(clampf(w * 0.12, 80.0, 120.0), btn_h)

	# Tab bar sizing
	var tab_bar = $TabBar
	var inset := clampf(min_dim * 0.020, 16.0, 24.0)
	tab_bar.offset_left = inset
	tab_bar.offset_right = -inset
	tab_bar.add_theme_constant_override("separation", clampf(min_dim * 0.010, 6.0, 12.0))
	for btn in [my_stats_tab, class_tab]:
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
	if ProgressManager.has_seen_tutorial("analytics"):
		return
	await get_tree().process_frame
	var tut = TutorialOverlay.new()
	add_child(tut)
	tut.tutorial_finished.connect(func(): ProgressManager.mark_tutorial_seen("analytics"))
	tut.start(_get_analytics_tutorial_steps())

func _get_analytics_tutorial_steps() -> Array:
	var steps: Array = []
	steps.append({
		"title": "Analytics",
		"body": "Dive deep into your learning patterns.\n\nView stats, charts, and compare yourself with classmates.",
		"force_center": true,
	})
	steps.append({
		"title": "My Stats Tab",
		"body": "See your personal stats — lessons mastered, time spent, and campaign progress.",
		"highlight": my_stats_tab.get_path(),
	})
	steps.append({
		"title": "Class Tab",
		"body": "Compare your performance against the class average and see where you rank.",
		"highlight": class_tab.get_path(),
	})
	steps.append({
		"title": "Scroll & Explore",
		"body": "Scroll down to see progress charts, accuracy breakdowns, time per lesson, and per-level statistics.",
		"highlight": my_stats_panel.get_path(),
	})
	steps.append({
		"title": "Back Button",
		"body": "Tap here to return to your profile.",
		"highlight": back_btn.get_path(),
	})
	steps.append({
		"title": "Track Your Growth!",
		"body": "Use these insights to spot weak topics and focus your practice.\nGood luck, operator!",
		"force_center": true,
	})
	return steps
