extends Control

@onready var back_btn: Button       = $TopBar/TopBarLayout/BackBtn
@onready var analytics_btn: Button  = $TopBar/TopBarLayout/AnalyticsBtn
@onready var scroll_container: ScrollContainer = $ContentArea/ScrollContainer
@onready var content: VBoxContainer  = $ContentArea/ScrollContainer/Content

var _last_device: String = ""

func _ready() -> void:
	_setup_buttons()
	_apply_styles()
	_build_content()
	_apply_responsive_layout()
	get_tree().root.size_changed.connect(_apply_responsive_layout)
	ScreenManager.make_scroll_touch_friendly(scroll_container)
	SupabaseManager.reset_completed.connect(_on_reset_completed)
	_maybe_show_tutorial()

func _is_compact() -> bool:
	return ScreenManager.is_mobile() or ScreenManager.is_tablet()

func _setup_buttons() -> void:
	back_btn.pressed.connect(func(): GameManager.go_to("main_menu"))
	analytics_btn.pressed.connect(func(): GameManager.go_to("analytics"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to("main_menu")

func _build_content() -> void:
	for child in content.get_children():
		child.queue_free()

	content.add_child(_make_section_title("DETAILS"))
	content.add_child(_make_details_section())

	content.add_child(_make_divider())

	content.add_child(_make_section_title("SESSION"))
	content.add_child(_make_session_section())

	content.add_child(_make_divider())

	content.add_child(_make_section_title("PROGRESS SUMMARY"))
	content.add_child(_make_stats_row())

	content.add_child(_make_divider())

	content.add_child(_make_section_title("ACCOUNT ACTIONS"))
	content.add_child(_make_account_actions())

	content.add_child(_make_divider())

	content.add_child(_make_section_title("DANGER ZONE", Color("#FF3366")))
	content.add_child(_make_danger_zone())

func _make_section_title(text: String, color: Color = Color("#00D4FF")) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16 if _is_compact() else 17)
	lbl.add_theme_color_override("font_color", color)
	return lbl

func _make_divider() -> HSeparator:
	var sep := HSeparator.new()
	return sep

func _make_details_section() -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = Color("#0D2040")
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

	layout.add_child(_make_info_row("Full Name", SupabaseManager.full_name if SupabaseManager.full_name != "" else "Student Player"))
	layout.add_child(_make_info_row("Username", SupabaseManager.username if SupabaseManager.username != "" else "student"))

	var y_level = SupabaseManager.year_level
	var sect = SupabaseManager.section
	var class_text = ""
	if y_level != "" and sect != "":
		class_text = y_level + " — " + sect
	elif y_level != "":
		class_text = y_level
	elif sect != "":
		class_text = sect
	else:
		class_text = "Registered Student"
	layout.add_child(_make_info_row("Year & Section", class_text))

	card.add_child(layout)
	return card

func _make_info_row(label: String, value: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#080F1E")
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left    = 12 if _is_compact() else 16
	style.content_margin_right   = 12 if _is_compact() else 16
	style.content_margin_top     = 8 if _is_compact() else 12
	style.content_margin_bottom  = 8 if _is_compact() else 12
	card.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(110 if _is_compact() else 130, 0)
	lbl.add_theme_font_size_override("font_size", 16 if _is_compact() else 17)
	lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	row.add_child(lbl)

	var val := Label.new()
	val.text = value
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.add_theme_font_size_override("font_size", 16 if _is_compact() else 17)
	val.add_theme_color_override("font_color", Color("#E8F4FD"))
	row.add_child(val)

	card.add_child(row)
	return card

func _make_stats_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var mastered := 0
	for t in ProgressManager.topic_states:
		if ProgressManager.topic_states[t] == "mastered":
			mastered += 1
	var levels = ProgressManager.campaign_progress.get("waves_completed", 0)
	var towers = ProgressManager.unlocked_towers.size()

	row.add_child(_make_stat_card("Lessons\nMastered", str(mastered) + "/" + str(DataRegistry.get_lesson_count()), Color("#00FF88")))
	row.add_child(_make_stat_card("Campaign\nLevels", str(levels) + "/" + str(DataRegistry.get_level_count()), Color("#FFB800")))
	row.add_child(_make_stat_card("Towers\nUnlocked", str(towers), Color("#00D4FF")))

	return row

func _make_stat_card(label: String, value: String, color: Color) -> PanelContainer:
	var card := PanelContainer.new()
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
	style.content_margin_left    = 12
	style.content_margin_right   = 12
	style.content_margin_top     = 12
	style.content_margin_bottom  = 12
	card.add_theme_stylebox_override("panel", style)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 4)

	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.add_theme_font_size_override("font_size", 24)
	val_lbl.add_theme_color_override("font_color", color)
	layout.add_child(val_lbl)

	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	layout.add_child(lbl)

	card.add_child(layout)
	return card

func _make_session_section() -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = Color("#9B59B6")
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

	var last_login_str = SupabaseManager.last_login
	if last_login_str == "":
		layout.add_child(_make_session_row("Status", "New account — first login"))
	else:
		layout.add_child(_make_session_row(
			"Last Login",
			_format_last_login(last_login_str)
		))

	card.add_child(layout)
	return card

func _make_session_row(label: String, value: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(100 if _is_compact() else 120, 0)
	lbl.add_theme_font_size_override("font_size", 16 if _is_compact() else 17)
	lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	row.add_child(lbl)

	var val := Label.new()
	val.text = value
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.add_theme_font_size_override("font_size", 16 if _is_compact() else 17)
	val.add_theme_color_override("font_color", Color("#E8F4FD"))
	row.add_child(val)

	return row

func _format_last_login(iso_string: String) -> String:
	if iso_string == "":
		return "Never"
	var parts = iso_string.split("T")
	if parts.size() < 1:
		return iso_string
	var date_part = parts[0]
	var time_part = parts[1].split(".")[0] if parts.size() > 1 else ""

	var date_parts = date_part.split("-")
	if date_parts.size() != 3:
		return iso_string

	var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
				  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	var month_idx = int(date_parts[1]) - 1
	var month_str = months[month_idx] if month_idx >= 0 and month_idx < 12 else date_parts[1]
	var day = date_parts[2].trim_prefix("0")
	var year = date_parts[0]

	if time_part == "":
		return month_str + " " + day + ", " + year

	var time_parts = time_part.split(":")
	if time_parts.size() < 2:
		return month_str + " " + day + ", " + year

	var hour = int(time_parts[0])
	var min = time_parts[1]
	var am_pm = "AM"
	if hour >= 12:
		am_pm = "PM"
		if hour > 12:
			hour -= 12
	if hour == 0:
		hour = 12

	return month_str + " " + day + ", " + year + ", " + str(hour) + ":" + min + " " + am_pm

func _make_account_actions() -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = Color("#00D4FF")
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
	layout.add_theme_constant_override("separation", 10)

	layout.add_child(_make_action_btn(
		"📧 Send Password Reset Email",
		_on_reset_password_pressed
	))
	layout.add_child(_make_action_btn(
		"🚪 Logout",
		_on_logout_pressed
	))

	card.add_child(layout)
	return card

func _make_action_btn(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 46)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.text = text
	btn.pressed.connect(callback)
	btn.add_theme_font_size_override("font_size", 16 if _is_compact() else 17)

	var normal := StyleBoxFlat.new()
	normal.bg_color               = Color("#0A1628")
	normal.border_color           = Color("#00D4FF")
	normal.border_width_left      = 1
	normal.border_width_right     = 1
	normal.border_width_top       = 1
	normal.border_width_bottom    = 1
	normal.corner_radius_top_left     = 4
	normal.corner_radius_top_right    = 4
	normal.corner_radius_bottom_left  = 4
	normal.corner_radius_bottom_right = 4

	var hover := StyleBoxFlat.new()
	hover.bg_color                = Color("#00D4FF", 0.1)
	hover.border_color            = Color("#00D4FF")
	hover.border_width_left       = 1
	hover.border_width_right      = 1
	hover.border_width_top        = 1
	hover.border_width_bottom     = 1
	hover.corner_radius_top_left      = 4
	hover.corner_radius_top_right     = 4
	hover.corner_radius_bottom_left   = 4
	hover.corner_radius_bottom_right  = 4

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover",  hover)
	btn.add_theme_color_override("font_color",       Color("#00D4FF"))
	btn.add_theme_color_override("font_hover_color", Color("#E8F4FD"))

	var sfx = get_node_or_null("/root/SoundManager")
	if sfx:
		btn.mouse_entered.connect(sfx.play_hover)
		btn.pressed.connect(sfx.play_click)

	return btn

func _on_reset_password_pressed() -> void:
	var email = SupabaseManager.email.strip_edges()
	if email == "":
		SignalBus.hud_message_requested.emit(
			"No email on file. Contact support to reset your password.", 4.0
		)
		return
	SupabaseManager.reset_password(email)

func _on_reset_completed(success: bool, message: String) -> void:
	SignalBus.hud_message_requested.emit(message, 4.0)

func _on_logout_pressed() -> void:
	SupabaseManager.logout()

func _make_danger_zone() -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#1A0A0A")
	style.border_color           = Color("#FF3366")
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
	layout.add_theme_constant_override("separation", 12)

	var warning_lbl := Label.new()
	warning_lbl.text = "These actions are destructive and cannot be undone."
	warning_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_lbl.add_theme_font_size_override("font_size", 14)
	warning_lbl.add_theme_color_override("font_color", Color("#FF6680"))
	layout.add_child(warning_lbl)

	var reset_btn := Button.new()
	reset_btn.custom_minimum_size = Vector2(0, 46)
	reset_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_btn.text = "🗑 Reset All Progress"
	reset_btn.pressed.connect(_on_reset_progress_pressed)
	reset_btn.add_theme_font_size_override("font_size", 16 if _is_compact() else 17)

	var reset_normal := StyleBoxFlat.new()
	reset_normal.bg_color            = Color("#FF3366", 0.15)
	reset_normal.border_color        = Color("#FF3366")
	reset_normal.border_width_left   = 1
	reset_normal.border_width_right  = 1
	reset_normal.border_width_top    = 1
	reset_normal.border_width_bottom = 1
	reset_normal.corner_radius_top_left     = 4
	reset_normal.corner_radius_top_right    = 4
	reset_normal.corner_radius_bottom_left  = 4
	reset_normal.corner_radius_bottom_right = 4

	var reset_hover := StyleBoxFlat.new()
	reset_hover.bg_color             = Color("#FF3366", 0.3)
	reset_hover.border_color         = Color("#FF3366")
	reset_hover.border_width_left    = 1
	reset_hover.border_width_right   = 1
	reset_hover.border_width_top     = 1
	reset_hover.border_width_bottom  = 1
	reset_hover.corner_radius_top_left     = 4
	reset_hover.corner_radius_top_right    = 4
	reset_hover.corner_radius_bottom_left  = 4
	reset_hover.corner_radius_bottom_right = 4

	reset_btn.add_theme_stylebox_override("normal", reset_normal)
	reset_btn.add_theme_stylebox_override("hover",  reset_hover)
	reset_btn.add_theme_color_override("font_color",       Color("#FF3366"))
	reset_btn.add_theme_color_override("font_hover_color", Color("#E8F4FD"))

	var sfx = get_node_or_null("/root/SoundManager")
	if sfx:
		reset_btn.mouse_entered.connect(sfx.play_hover)
		reset_btn.pressed.connect(sfx.play_click)

	layout.add_child(reset_btn)

	card.add_child(layout)
	return card

func _on_reset_progress_pressed() -> void:
	var confirm := AcceptDialog.new()
	confirm.dialog_text = "Are you sure you want to reset ALL progress?\n\nThis will clear all lessons, campaign levels, and tower unlocks.\nThis action cannot be undone."
	confirm.confirmed.connect(_do_reset_progress)
	confirm.ok_button_text = "Yes, Reset Everything"
	confirm.add_cancel_button("Cancel")
	add_child(confirm)
	confirm.popup_centered()

func _do_reset_progress() -> void:
	ProgressManager.reset_all_progress()
	SignalBus.hud_message_requested.emit("Progress has been reset.", 4.0)
	_build_content()

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
	back_btn.add_theme_font_size_override("font_size", 16 if _is_compact() else 17)

	var analytics_style := StyleBoxFlat.new()
	analytics_style.bg_color               = Color("#0A1628")
	analytics_style.border_color           = Color("#00FF88")
	analytics_style.border_width_left      = 1
	analytics_style.border_width_right     = 1
	analytics_style.border_width_top       = 1
	analytics_style.border_width_bottom    = 1
	analytics_style.corner_radius_top_left     = 4
	analytics_style.corner_radius_top_right    = 4
	analytics_style.corner_radius_bottom_left  = 4
	analytics_style.corner_radius_bottom_right = 4
	analytics_btn.add_theme_stylebox_override("normal", analytics_style)
	analytics_btn.add_theme_color_override("font_color", Color("#00FF88"))
	analytics_btn.add_theme_font_size_override("font_size", 16 if _is_compact() else 17)

	var analytics_hover := StyleBoxFlat.new()
	analytics_hover.bg_color                = Color("#00FF88", 0.1)
	analytics_hover.border_color            = Color("#00FF88")
	analytics_hover.border_width_left       = 1
	analytics_hover.border_width_right      = 1
	analytics_hover.border_width_top        = 1
	analytics_hover.border_width_bottom     = 1
	analytics_hover.corner_radius_top_left      = 4
	analytics_hover.corner_radius_top_right     = 4
	analytics_hover.corner_radius_bottom_left   = 4
	analytics_hover.corner_radius_bottom_right  = 4
	analytics_btn.add_theme_stylebox_override("hover", analytics_hover)
	analytics_btn.add_theme_color_override("font_hover_color", Color("#E8F4FD"))

func _apply_responsive_layout() -> void:
	var current = "mobile" if ScreenManager.is_mobile() else "tablet" if ScreenManager.is_tablet() else "desktop"
	if current != _last_device:
		_last_device = current
		_build_content()

	var top_bar = $TopBar
	var content_area = $ContentArea
	var title_label = $TopBar/TopBarLayout/TitleLabel

	if ScreenManager.is_mobile():
		ScreenManager.apply_panel_padding(top_bar, 20)
		content_area.add_theme_constant_override("margin_left", 20)
		content_area.add_theme_constant_override("margin_right", 20)
		content_area.add_theme_constant_override("margin_top", 20)
		content_area.add_theme_constant_override("margin_bottom", 20)
		back_btn.custom_minimum_size = Vector2(85, 52)
		title_label.add_theme_font_size_override("font_size", 20)
		analytics_btn.custom_minimum_size = Vector2(120, 44)
	elif ScreenManager.is_tablet():
		ScreenManager.apply_panel_padding(top_bar, 24)
		content_area.add_theme_constant_override("margin_left", 24)
		content_area.add_theme_constant_override("margin_right", 24)
		content_area.add_theme_constant_override("margin_top", 24)
		content_area.add_theme_constant_override("margin_bottom", 24)
		back_btn.custom_minimum_size = Vector2(95, 52)
		title_label.add_theme_font_size_override("font_size", 22)
		analytics_btn.custom_minimum_size = Vector2(130, 44)
	else:
		back_btn.custom_minimum_size = Vector2(110, 52)
		title_label.add_theme_font_size_override("font_size", 24)
		analytics_btn.custom_minimum_size = Vector2(150, 44)

# ─── TUTORIAL ──────────────────────────────────────────
const TutorialOverlay = preload("res://scenes/core/TutorialOverlay.gd")

func _maybe_show_tutorial() -> void:
	if ProgressManager.has_seen_tutorial("profile"):
		return
	await get_tree().process_frame
	var tut = TutorialOverlay.new()
	add_child(tut)
	tut.tutorial_finished.connect(func(): ProgressManager.mark_tutorial_seen("profile"))
	tut.start(_get_profile_tutorial_steps())

func _get_profile_tutorial_steps() -> Array:
	var steps: Array = []
	steps.append({
		"title": "Your Profile",
		"body": "This is your operator profile.\nTrack your progress, manage your account, and view your stats here.",
		"force_center": true,
	})
	steps.append({
		"title": "Progress Summary",
		"body": "See how many lessons you've mastered, campaign levels completed, and towers unlocked.\nScroll down to view all sections.",
		"highlight": scroll_container.get_path(),
	})
	steps.append({
		"title": "Analytics",
		"body": "Tap here to view detailed analytics on your learning patterns and strengths.",
		"highlight": analytics_btn.get_path(),
	})
	steps.append({
		"title": "Back Button",
		"body": "Tap here to return to the main menu.",
		"highlight": back_btn.get_path(),
	})
	steps.append({
		"title": "Account Actions",
		"body": "Scroll down to find password reset, logout, and danger zone options (reset progress).",
		"force_center": true,
	})
	return steps
