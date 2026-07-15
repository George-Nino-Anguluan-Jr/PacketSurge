# ProfilePopup.gd
extends ColorRect

@onready var popup_card: PanelContainer     = $CenterContainer/PopupCard
@onready var close_btn: Button             = $CenterContainer/PopupCard/MarginContainer/ContentLayout/Header/CloseButton
@onready var fullname_label: Label         = $CenterContainer/PopupCard/MarginContainer/ContentLayout/DetailsSection/FullNameRow/Value
@onready var username_label: Label         = $CenterContainer/PopupCard/MarginContainer/ContentLayout/DetailsSection/UsernameRow/Value
@onready var class_label: Label            = $CenterContainer/PopupCard/MarginContainer/ContentLayout/DetailsSection/ClassRow/Value
@onready var stats_row: HBoxContainer      = $CenterContainer/PopupCard/MarginContainer/ContentLayout/StatsSection/StatsRow
@onready var reset_pass_btn: Button        = $CenterContainer/PopupCard/MarginContainer/ContentLayout/ActionSection/ResetPasswordButton
@onready var logout_btn: Button            = $CenterContainer/PopupCard/MarginContainer/ContentLayout/ActionSection/LogoutButton
@onready var analytics_btn: Button         = $CenterContainer/PopupCard/MarginContainer/ContentLayout/ActionSection/AnalyticsButton

var analytics_scene = preload("res://scenes/analytics/Analytics.tscn")
var analytics_instance: Control = null

func _ready() -> void:
	# Hide by default
	visible = false
	
	# Connect close button
	close_btn.pressed.connect(close)
	analytics_btn.pressed.connect(_on_analytics_pressed)
	reset_pass_btn.pressed.connect(_on_reset_password_pressed)
	logout_btn.pressed.connect(_on_logout_pressed)
	
	_style_popup()

func open() -> void:
	# Load User Data
	fullname_label.text = SupabaseManager.full_name if SupabaseManager.full_name != "" else "Student Player"
	username_label.text = SupabaseManager.username if SupabaseManager.username != "" else "student"
	
	var y_level = SupabaseManager.year_level
	var sect = SupabaseManager.section
	if y_level != "" and sect != "":
		class_label.text = y_level + " — " + sect
	elif y_level != "":
		class_label.text = y_level
	elif sect != "":
		class_label.text = sect
	else:
		class_label.text = "Registered Student"
		
	# Build Stats Row
	_build_stats_row()
	
	# Reset views so we start on ProfilePopup view
	popup_card.visible = true
	if analytics_instance:
		analytics_instance.visible = false
	
	# Show Popup
	visible = true

func open_with_no_reset() -> void:
	# Load User Data
	fullname_label.text = SupabaseManager.full_name if SupabaseManager.full_name != "" else "Student Player"
	username_label.text = SupabaseManager.username if SupabaseManager.username != "" else "student"
	
	var y_level = SupabaseManager.year_level
	var sect = SupabaseManager.section
	if y_level != "" and sect != "":
		class_label.text = y_level + " — " + sect
	elif y_level != "":
		class_label.text = y_level
	elif sect != "":
		class_label.text = sect
	else:
		class_label.text = "Registered Student"
		
	# Build Stats Row
	_build_stats_row()
	
	# Show Popup
	visible = true

func close() -> void:
	visible = false

func _build_stats_row() -> void:
	# Clear old stats
	for child in stats_row.get_children():
		child.queue_free()
		
	var mastered := 0
	for t in ProgressManager.topic_states:
		if ProgressManager.topic_states[t] == "mastered":
			mastered += 1
	var levels = ProgressManager.campaign_progress.get("waves_completed", 0)
	var towers = ProgressManager.unlocked_towers.size()

	stats_row.add_child(
		_make_mini_stat("Lessons\nMastered", str(mastered) + "/12", Color("#00FF88"))
	)
	stats_row.add_child(
		_make_mini_stat("Campaign\nLevels", str(levels) + "/11", Color("#FFB800"))
	)
	stats_row.add_child(
		_make_mini_stat("Towers\nUnlocked", str(towers), Color("#00D4FF"))
	)

func _make_mini_stat(label: String, value: String, color: Color) -> PanelContainer:
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
	val_lbl.add_theme_font_size_override("font_size", 22)
	val_lbl.add_theme_color_override("font_color", color)
	layout.add_child(val_lbl)

	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	layout.add_child(lbl)

	card.add_child(layout)
	return card

func _style_popup() -> void:
	# Dialog flat style (cyberpunk glass card)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color               = Color("#0A1628", 0.95) # Dark high contrast blue
	card_style.border_color           = Color("#00D4FF") # Neon cyan glow border
	card_style.border_width_left      = 2
	card_style.border_width_right     = 2
	card_style.border_width_top       = 2
	card_style.border_width_bottom    = 2
	card_style.corner_radius_top_left     = 8
	card_style.corner_radius_top_right    = 8
	card_style.corner_radius_bottom_left  = 8
	card_style.corner_radius_bottom_right = 8
	popup_card.add_theme_stylebox_override("panel", card_style)

	# Style Close button
	var close_normal := StyleBoxFlat.new()
	close_normal.bg_color               = Color("#1A3A5A")
	close_normal.corner_radius_top_left     = 4
	close_normal.corner_radius_top_right    = 4
	close_normal.corner_radius_bottom_left  = 4
	close_normal.corner_radius_bottom_right = 4
	
	var close_hover := StyleBoxFlat.new()
	close_hover.bg_color                = Color("#00D4FF")
	close_hover.corner_radius_top_left      = 4
	close_hover.corner_radius_top_right     = 4
	close_hover.corner_radius_bottom_left   = 4
	close_hover.corner_radius_bottom_right  = 4
	
	close_btn.add_theme_stylebox_override("normal", close_normal)
	close_btn.add_theme_stylebox_override("hover",  close_hover)
	close_btn.add_theme_color_override("font_color",         Color("#E8F4FD"))
	close_btn.add_theme_color_override("font_hover_color",   Color("#050D1A"))

	# Style Analytics button
	var analytics_normal := StyleBoxFlat.new()
	analytics_normal.bg_color               = Color("#0A1628")
	analytics_normal.border_color           = Color("#00D4FF")
	analytics_normal.border_width_left      = 1
	analytics_normal.border_width_right     = 1
	analytics_normal.border_width_top       = 1
	analytics_normal.border_width_bottom    = 1
	analytics_normal.corner_radius_top_left     = 4
	analytics_normal.corner_radius_top_right    = 4
	analytics_normal.corner_radius_bottom_left  = 4
	analytics_normal.corner_radius_bottom_right = 4
	
	var analytics_hover := StyleBoxFlat.new()
	analytics_hover.bg_color                = Color("#00D4FF", 0.1)
	analytics_hover.border_color            = Color("#00D4FF")
	analytics_hover.border_width_left       = 1
	analytics_hover.border_width_right      = 1
	analytics_hover.border_width_top        = 1
	analytics_hover.border_width_bottom     = 1
	analytics_hover.corner_radius_top_left      = 4
	analytics_hover.corner_radius_top_right     = 4
	analytics_hover.corner_radius_bottom_left   = 4
	analytics_hover.corner_radius_bottom_right  = 4
	
	analytics_btn.add_theme_stylebox_override("normal", analytics_normal)
	analytics_btn.add_theme_stylebox_override("hover",  analytics_hover)
	analytics_btn.add_theme_color_override("font_color",       Color("#00D4FF"))
	analytics_btn.add_theme_color_override("font_hover_color", Color("#E8F4FD"))

	# Style Password Reset button
	var reset_normal := StyleBoxFlat.new()
	reset_normal.bg_color               = Color("#0A1628")
	reset_normal.border_color           = Color("#00D4FF")
	reset_normal.border_width_left      = 1
	reset_normal.border_width_right     = 1
	reset_normal.border_width_top       = 1
	reset_normal.border_width_bottom    = 1
	reset_normal.corner_radius_top_left     = 4
	reset_normal.corner_radius_top_right    = 4
	reset_normal.corner_radius_bottom_left  = 4
	reset_normal.corner_radius_bottom_right = 4
	
	var reset_hover := StyleBoxFlat.new()
	reset_hover.bg_color                = Color("#00D4FF", 0.1)
	reset_hover.border_color            = Color("#00D4FF")
	reset_hover.border_width_left       = 1
	reset_hover.border_width_right      = 1
	reset_hover.border_width_top        = 1
	reset_hover.border_width_bottom     = 1
	reset_hover.corner_radius_top_left      = 4
	reset_hover.corner_radius_top_right     = 4
	reset_hover.corner_radius_bottom_left   = 4
	reset_hover.corner_radius_bottom_right  = 4
	
	reset_pass_btn.add_theme_stylebox_override("normal", reset_normal)
	reset_pass_btn.add_theme_stylebox_override("hover",  reset_hover)
	reset_pass_btn.add_theme_color_override("font_color",       Color("#00D4FF"))
	reset_pass_btn.add_theme_color_override("font_hover_color", Color("#E8F4FD"))

	# Style Logout button
	var logout_normal := StyleBoxFlat.new()
	logout_normal.bg_color            = Color("#FF3366", 0.15)
	logout_normal.border_color        = Color("#FF3366")
	logout_normal.border_width_left   = 1
	logout_normal.border_width_right  = 1
	logout_normal.border_width_top    = 1
	logout_normal.border_width_bottom = 1
	logout_normal.corner_radius_top_left     = 4
	logout_normal.corner_radius_top_right    = 4
	logout_normal.corner_radius_bottom_left  = 4
	logout_normal.corner_radius_bottom_right = 4

	var logout_hover := StyleBoxFlat.new()
	logout_hover.bg_color             = Color("#FF3366", 0.3)
	logout_hover.border_color         = Color("#FF3366")
	logout_hover.border_width_left    = 1
	logout_hover.border_width_right   = 1
	logout_hover.border_width_top     = 1
	logout_hover.border_width_bottom  = 1
	logout_hover.corner_radius_top_left     = 4
	logout_hover.corner_radius_top_right    = 4
	logout_hover.corner_radius_bottom_left  = 4
	logout_hover.corner_radius_bottom_right = 4

	logout_btn.add_theme_stylebox_override("normal", logout_normal)
	logout_btn.add_theme_stylebox_override("hover",  logout_hover)
	logout_btn.add_theme_color_override("font_color",       Color("#FF3366"))
	logout_btn.add_theme_color_override("font_hover_color", Color("#E8F4FD"))

func _on_reset_password_pressed() -> void:
	SignalBus.hud_message_requested.emit(
		"Password reset email sent! Check your inbox.", 4.0
	)
	print("[ProfilePopup] Password reset requested.")
	close()

func _on_logout_pressed() -> void:
	close()
	SupabaseManager.logout()

func _on_analytics_pressed() -> void:
	popup_card.visible = false
	if not analytics_instance:
		analytics_instance = analytics_scene.instantiate()
		analytics_instance.is_popup_mode = true
		analytics_instance.back_requested.connect(_on_analytics_back)
		add_child(analytics_instance)
		analytics_instance.set_anchors_preset(Control.PRESET_FULL_RECT)
	else:
		analytics_instance.visible = true
		# Refresh/trigger the statistics building if applicable (or ready handles it)
		if analytics_instance.has_method("_build_my_stats"):
			analytics_instance._build_my_stats()

func _on_analytics_back() -> void:
	if analytics_instance:
		analytics_instance.visible = false
	popup_card.visible = true
