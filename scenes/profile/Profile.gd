extends Control

# ─── NODE REFERENCES ───────────────────────────────────
@onready var back_btn: Button       = $SafeArea/ContentHost/TopBar/TopBarLayout/BackBtn
@onready var analytics_btn: Button  = $SafeArea/ContentHost/TopBar/TopBarLayout/AnalyticsBtn
@onready var scroll_container: ScrollContainer = $SafeArea/ContentHost/ContentArea/ScrollContainer
@onready var content: VBoxContainer  = $SafeArea/ContentHost/ContentArea/ScrollContainer/Content

# ─── STATE ─────────────────────────────────────────────

# ─── HELPERS ───────────────────────────────────────────
func _min_dim() -> float:
	var vp := get_viewport().get_visible_rect().size
	return minf(maxf(vp.x, 320.0), maxf(vp.y, 240.0))

func _fs(ratio: float, floor_v: float, cap_v: float) -> int:
	return int(clampf(_min_dim() * ratio, floor_v, cap_v))

func _ready() -> void:
	_setup_buttons()
	_apply_styles()
	_build_content()
	_apply_responsive_layout()
	get_tree().root.size_changed.connect(_apply_responsive_layout)
	ScreenManager.make_scroll_touch_friendly(scroll_container)
	SupabaseManager.reset_completed.connect(_on_reset_completed)
	SupabaseManager.otp_verified.connect(_on_otp_verified)
	SupabaseManager.password_set_completed.connect(_on_password_set_completed)
	_maybe_show_tutorial()

func _setup_buttons() -> void:
	back_btn.pressed.connect(func(): GameManager.go_to("main_menu"))
	analytics_btn.pressed.connect(func(): GameManager.go_to("analytics"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _reset_dialog and _reset_dialog.visible:
			_hide_reset_dialog()
			get_viewport().set_input_as_handled()
		else:
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
	lbl.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 18.0))
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
	style.content_margin_left    = _fs(0.034, 12.0, 16.0)
	style.content_margin_right   = _fs(0.034, 12.0, 16.0)
	style.content_margin_top     = _fs(0.025, 10.0, 12.0)
	style.content_margin_bottom  = _fs(0.025, 10.0, 12.0)
	card.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(_fs(0.35, 110.0, 130.0), 0)
	lbl.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 18.0))
	lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	row.add_child(lbl)

	var val := Label.new()
	val.text = value
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 18.0))
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
	val_lbl.add_theme_font_size_override("font_size", _fs(0.055, 20.0, 30.0))
	val_lbl.add_theme_color_override("font_color", color)
	layout.add_child(val_lbl)

	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
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
	lbl.custom_minimum_size = Vector2(_fs(0.31, 100.0, 140.0), 0)
	lbl.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 18.0))
	lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	row.add_child(lbl)

	var val := Label.new()
	val.text = value
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 18.0))
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
		"📧 Send Password Reset Code",
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
	btn.custom_minimum_size = Vector2(0, _fs(0.13, 44.0, 52.0))
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.text = text
	btn.pressed.connect(callback)
	btn.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 18.0))

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
	# Send a 6-digit OTP to the account email and open the in-game wizard
	# so the user can enter the code and choose a new password here.
	_show_reset_dialog(email)
	SupabaseManager.reset_password(email)

func _on_reset_completed(success: bool, message: String) -> void:
	if _reset_dialog and _reset_dialog.visible:
		_set_reset_busy(false)
		if success:
			_reset_desc_label.text = "Code sent to " + _reset_email + ". Enter it below."
			_reset_code_field.grab_focus()
		else:
			_show_reset_error(message)
	else:
		SignalBus.hud_message_requested.emit(message, 4.0)

func _on_otp_verified(success: bool, session_token: String) -> void:
	if _reset_dialog and _reset_dialog.visible:
		_set_reset_busy(false)
		if success:
			_reset_session_token = session_token
			_go_to_reset_step(1)
		else:
			_show_reset_error(session_token)
	else:
		SignalBus.hud_message_requested.emit(session_token, 4.0)

func _on_password_set_completed(success: bool, message: String) -> void:
	if _reset_dialog and _reset_dialog.visible:
		_set_reset_busy(false)
		if success:
			_hide_reset_dialog()
			SignalBus.hud_message_requested.emit(message, 4.0)
		else:
			_show_reset_error(message)
	else:
		SignalBus.hud_message_requested.emit(message, 4.0)

# ─── RESET PASSWORD DIALOG (OTP WIZARD) ────────────────
# Step 0: enter code → Step 1: new password. The email is already known
# (the logged-in account), so unlike the login screen there's no email step.
var _reset_dialog: Control = null
var _reset_step: int = 0
var _reset_email: String = ""
var _reset_session_token: String = ""
var _reset_title_label: Label = null
var _reset_desc_label: Label = null
var _reset_code_field: LineEdit = null
var _reset_password_field: LineEdit = null
var _reset_confirm_field: LineEdit = null
var _reset_error_label: Label = null
var _reset_submit_btn: Button = null
var _reset_back_btn: Button = null

func _show_reset_dialog(email: String) -> void:
	if _reset_dialog == null:
		_build_reset_dialog()
	_reset_step = 0
	_reset_email = email
	_reset_session_token = ""
	_reset_code_field.text = ""
	_reset_password_field.text = ""
	_reset_confirm_field.text = ""
	_reset_error_label.text = ""
	_reset_dialog.visible = true
	_reset_dialog.move_to_front()
	_apply_reset_step()
	_reset_code_field.grab_focus()

func _hide_reset_dialog() -> void:
	if _reset_dialog:
		_reset_dialog.visible = false

func _build_reset_dialog() -> void:
	var dim := ColorRect.new()
	dim.color = Color("#050D1A", 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.visible = false
	_reset_dialog = dim
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(_fs(0.42, 320.0, 520.0), 0)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color               = Color("#0A1628")
	card_style.border_color           = Color("#00D4FF")
	card_style.border_width_left      = 1
	card_style.border_width_right     = 1
	card_style.border_width_top       = 1
	card_style.border_width_bottom    = 1
	card_style.corner_radius_top_left     = 8
	card_style.corner_radius_top_right    = 8
	card_style.corner_radius_bottom_left  = 8
	card_style.corner_radius_bottom_right = 8
	card_style.content_margin_left   = 24
	card_style.content_margin_right  = 24
	card_style.content_margin_top    = 20
	card_style.content_margin_bottom = 20
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	card.add_child(layout)

	_reset_title_label = Label.new()
	_reset_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reset_title_label.add_theme_font_size_override("font_size", _fs(0.048, 18.0, 22.0))
	_reset_title_label.add_theme_color_override("font_color", Color("#00D4FF"))
	layout.add_child(_reset_title_label)

	_reset_desc_label = Label.new()
	_reset_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reset_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reset_desc_label.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
	_reset_desc_label.add_theme_color_override("font_color", Color("#4A7FA5"))
	layout.add_child(_reset_desc_label)

	_reset_code_field = LineEdit.new()
	_reset_code_field.placeholder_text = "Verification code"
	_reset_code_field.custom_minimum_size = Vector2(0, _fs(0.13, 44.0, 48.0))
	_reset_code_field.max_length = 10
	_style_input_field(_reset_code_field)
	_reset_code_field.text_submitted.connect(func(_t): _submit_reset_step())
	layout.add_child(_reset_code_field)

	_reset_password_field = LineEdit.new()
	_reset_password_field.placeholder_text = "New Password"
	_reset_password_field.secret = true
	_reset_password_field.custom_minimum_size = Vector2(0, _fs(0.13, 44.0, 48.0))
	_style_input_field(_reset_password_field)
	layout.add_child(_reset_password_field)

	_reset_confirm_field = LineEdit.new()
	_reset_confirm_field.placeholder_text = "Confirm New Password"
	_reset_confirm_field.secret = true
	_reset_confirm_field.custom_minimum_size = Vector2(0, _fs(0.13, 44.0, 48.0))
	_style_input_field(_reset_confirm_field)
	_reset_confirm_field.text_submitted.connect(func(_t): _submit_reset_step())
	layout.add_child(_reset_confirm_field)

	_reset_error_label = Label.new()
	_reset_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reset_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reset_error_label.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
	layout.add_child(_reset_error_label)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	layout.add_child(btns)

	_reset_back_btn = Button.new()
	_reset_back_btn.text = "BACK"
	_reset_back_btn.custom_minimum_size = Vector2(0, _fs(0.13, 44.0, 52.0))
	_reset_back_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_dialog_btn(_reset_back_btn, Color("#4A7FA5"))
	_reset_back_btn.pressed.connect(_go_back_reset_step)
	btns.add_child(_reset_back_btn)

	_reset_submit_btn = Button.new()
	_reset_submit_btn.custom_minimum_size = Vector2(0, _fs(0.13, 44.0, 52.0))
	_reset_submit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_dialog_btn(_reset_submit_btn, Color("#00D4FF"))
	_reset_submit_btn.pressed.connect(_submit_reset_step)
	btns.add_child(_reset_submit_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "CANCEL"
	cancel_btn.custom_minimum_size = Vector2(0, _fs(0.13, 44.0, 52.0))
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_dialog_btn(cancel_btn, Color("#4A7FA5"))
	cancel_btn.pressed.connect(_hide_reset_dialog)
	btns.add_child(cancel_btn)

	var sfx = get_node_or_null("/root/SoundManager")
	if sfx:
		for b in [_reset_submit_btn, _reset_back_btn, cancel_btn]:
			b.mouse_entered.connect(sfx.play_hover)
			b.pressed.connect(sfx.play_click)

func _style_dialog_btn(btn: Button, color: Color) -> void:
	btn.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 18.0))
	btn.add_theme_color_override("font_color", color)
	var s := StyleBoxFlat.new()
	s.bg_color               = Color("#0A1628")
	s.border_color           = color
	s.border_width_left      = 1
	s.border_width_right     = 1
	s.border_width_top       = 1
	s.border_width_bottom    = 1
	s.corner_radius_top_left     = 4
	s.corner_radius_top_right    = 4
	s.corner_radius_bottom_left  = 4
	s.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", s)

func _style_input_field(field: LineEdit) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#080F1E")
	style.border_color           = Color("#1A3A5A")
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left   = 12
	style.content_margin_right  = 12
	style.content_margin_top    = 8
	style.content_margin_bottom = 8
	field.add_theme_stylebox_override("normal", style)

	var focus := StyleBoxFlat.new()
	focus.bg_color               = Color("#080F1E")
	focus.border_color           = Color("#00D4FF")
	focus.border_width_left      = 1
	focus.border_width_right     = 1
	focus.border_width_top       = 1
	focus.border_width_bottom    = 1
	focus.corner_radius_top_left     = 4
	focus.corner_radius_top_right    = 4
	focus.corner_radius_bottom_left  = 4
	focus.corner_radius_bottom_right = 4
	focus.content_margin_left   = 12
	focus.content_margin_right  = 12
	focus.content_margin_top    = 8
	focus.content_margin_bottom = 8
	field.add_theme_stylebox_override("focus", focus)
	field.add_theme_color_override("font_color",             Color("#E8F4FD"))
	field.add_theme_color_override("font_placeholder_color", Color("#4A7FA5"))
	field.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 20.0))

func _go_to_reset_step(step: int) -> void:
	_reset_step = step
	_apply_reset_step()

func _apply_reset_step() -> void:
	_reset_code_field.visible      = _reset_step == 0
	_reset_password_field.visible  = _reset_step == 1
	_reset_confirm_field.visible   = _reset_step == 1
	_reset_back_btn.visible        = _reset_step > 0
	_reset_error_label.text        = ""
	if _reset_step == 0:
		_reset_title_label.text = "ENTER CODE"
		_reset_desc_label.text  = "Enter the code we emailed to " + _reset_email
		_reset_submit_btn.text  = "VERIFY CODE"
		_reset_code_field.grab_focus()
	else:
		_reset_title_label.text = "NEW PASSWORD"
		_reset_desc_label.text  = "Choose a new password."
		_reset_submit_btn.text  = "SET PASSWORD"
		_reset_password_field.grab_focus()

func _go_back_reset_step() -> void:
	if _reset_step > 0:
		_go_to_reset_step(_reset_step - 1)

func _submit_reset_step() -> void:
	if _reset_step == 0:
		var code = _reset_code_field.text.strip_edges()
		if not code.is_valid_int() or code.length() < 6 or code.length() > 10:
			_show_reset_error("Enter the code from your email.")
			return
		_reset_error_label.text = ""
		_set_reset_busy(true)
		SupabaseManager.verify_reset_otp(_reset_email, code)
	else:
		var password = _reset_password_field.text
		var confirm  = _reset_confirm_field.text
		if password.length() < 6:
			_show_reset_error("Password must be at least 6 characters.")
			return
		if password != confirm:
			_show_reset_error("Passwords do not match.")
			return
		_reset_error_label.text = ""
		_set_reset_busy(true)
		SupabaseManager.set_new_password(_reset_session_token, password)

func _set_reset_busy(busy: bool) -> void:
	_reset_submit_btn.disabled = busy
	_reset_submit_btn.text = "WORKING..." if busy else ("VERIFY CODE" if _reset_step == 0 else "SET PASSWORD")

func _show_reset_error(message: String) -> void:
	_reset_error_label.text = message
	_reset_error_label.add_theme_color_override("font_color", Color("#FF3366"))

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
	warning_lbl.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
	warning_lbl.add_theme_color_override("font_color", Color("#FF6680"))
	layout.add_child(warning_lbl)

	var reset_btn := Button.new()
	reset_btn.custom_minimum_size = Vector2(0, _fs(0.13, 44.0, 52.0))
	reset_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_btn.text = "🗑 Reset All Progress"
	reset_btn.pressed.connect(_on_reset_progress_pressed)
	reset_btn.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 18.0))

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
	$SafeArea/ContentHost/TopBar.add_theme_stylebox_override("panel", top_style)

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
	analytics_btn.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 18.0))

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
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var w := maxf(vp.x, 320.0)
	var h := maxf(vp.y, 240.0)
	var min_dim := minf(w, h)

	# Fluid typography for top bar
	$SafeArea/ContentHost/TopBar/TopBarLayout/TitleLabel.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.030, 18.0, 28.0)))
	back_btn.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 20.0))
	analytics_btn.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 20.0))

	# Fluid button sizes
	var btn_h := clampf(h * 0.075, 44.0, 52.0)
	back_btn.custom_minimum_size = Vector2(clampf(w * 0.12, 80.0, 120.0), btn_h)
	analytics_btn.custom_minimum_size = Vector2(clampf(w * 0.22, 100.0, 150.0), btn_h)

	# Content area margins — fluid inset
	var content_area = $SafeArea/ContentHost/ContentArea
	var inset := clampf(min_dim * 0.020, 16.0, 24.0)
	content_area.add_theme_constant_override("margin_left", inset)
	content_area.add_theme_constant_override("margin_right", inset)
	content_area.add_theme_constant_override("margin_top", clampf(min_dim * 0.010, 8.0, 16.0))
	content_area.add_theme_constant_override("margin_bottom", inset)

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
