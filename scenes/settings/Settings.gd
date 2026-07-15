# Settings.gd
extends Control

# ─── NODE REFERENCES ───────────────────────────────────
@onready var back_btn: Button               = $TopBar/TopBarLayout/BackBtn
@onready var general_tab: Button            = $TabBar/GeneralTab
@onready var account_tab: Button            = $TabBar/AccountTab
@onready var general_panel: ScrollContainer = $ContentArea/GeneralPanel
@onready var account_panel: ScrollContainer = $ContentArea/AccountPanel
@onready var general_content: VBoxContainer = $ContentArea/GeneralPanel/GeneralContent
@onready var account_content: VBoxContainer = $ContentArea/AccountPanel/AccountContent

# ─── STATE ─────────────────────────────────────────────
var sound_enabled: bool = true
var music_enabled: bool = true
var shake_enabled: bool = true
var active_tab: String  = "general"

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	_setup_buttons()
	_apply_styles()
	_show_general_tab()
	_apply_responsive_layout()
	get_tree().root.size_changed.connect(_apply_responsive_layout)

# ─── BUTTON SETUP ──────────────────────────────────────
func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	general_tab.pressed.connect(_show_general_tab)
	account_tab.pressed.connect(_show_account_tab)

func _on_back_pressed() -> void:
	GameManager.go_to("main_menu")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to("main_menu")

# ─── TAB SWITCHING ─────────────────────────────────────
func _show_general_tab() -> void:
	active_tab            = "general"
	general_panel.visible = true
	account_panel.visible = false
	_style_active_tab(general_tab, true)
	_style_active_tab(account_tab, false)
	_build_general()

func _show_account_tab() -> void:
	active_tab            = "account"
	general_panel.visible = false
	account_panel.visible = true
	_style_active_tab(general_tab, false)
	_style_active_tab(account_tab, true)
	_build_account()

# ─── GENERAL TAB ───────────────────────────────────────
func _build_general() -> void:
	for child in general_content.get_children():
		child.queue_free()

	general_content.add_child(_make_section_label("AUDIO"))
	general_content.add_child(
		_make_toggle_row(
			"Sound Effects",
			"Enable or disable all sound effects",
			sound_enabled,
			_on_sound_toggled
		)
	)
	general_content.add_child(
		_make_toggle_row(
			"Music",
			"Enable or disable background music",
			music_enabled,
			_on_music_toggled
		)
	)

	general_content.add_child(_make_divider())
	general_content.add_child(_make_section_label("GAMEPLAY"))
	general_content.add_child(
		_make_toggle_row(
			"Screen Shake",
			"Shake screen when base takes damage",
			shake_enabled,
			_on_shake_toggled
		)
	)

	general_content.add_child(_make_divider())
	general_content.add_child(_make_section_label("ABOUT"))
	general_content.add_child(_make_info_row("Version",   "v0.1.0"))
	general_content.add_child(_make_info_row("Engine",    "Godot 4"))
	general_content.add_child(_make_info_row("Backend",   "Supabase"))
	general_content.add_child(_make_info_row("Developer", "Packet Surge Team"))

# ─── GENERAL TOGGLE HANDLERS ───────────────────────────
func _on_sound_toggled(val: bool) -> void:
	sound_enabled = val
	AudioServer.set_bus_mute(0, not val)
	SignalBus.hud_message_requested.emit(
		"Sound " + ("ON" if val else "OFF"), 2.0
	)

func _on_music_toggled(val: bool) -> void:
	music_enabled = val
	SignalBus.hud_message_requested.emit(
		"Music " + ("ON" if val else "OFF"), 2.0
	)

func _on_shake_toggled(val: bool) -> void:
	shake_enabled = val
	SignalBus.hud_message_requested.emit(
		"Screen Shake " + ("ON" if val else "OFF"), 2.0
	)

# ─── TOGGLE ROW ────────────────────────────────────────
func _make_toggle_row(
		label: String,
		description: String,
		current_value: bool,
		on_toggle: Callable) -> PanelContainer:

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = Color("#1A3A5A")
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left    = 16
	style.content_margin_right   = 16
	style.content_margin_top     = 12
	style.content_margin_bottom  = 12
	card.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)

	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color("#E8F4FD"))
	text_col.add_child(lbl)

	var desc := Label.new()
	desc.text          = description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color("#4A7FA5"))
	text_col.add_child(desc)
	row.add_child(text_col)

	var toggle := Button.new()
	toggle.custom_minimum_size = Vector2(80, 36)
	toggle.text = "ON" if current_value else "OFF"
	_style_toggle_button(toggle, current_value)
	toggle.pressed.connect(_on_toggle_pressed.bind(toggle, on_toggle))
	row.add_child(toggle)

	card.add_child(row)
	return card

func _on_toggle_pressed(toggle: Button, on_toggle: Callable) -> void:
	var new_val = toggle.text == "OFF"
	toggle.text = "ON" if new_val else "OFF"
	_style_toggle_button(toggle, new_val)
	on_toggle.call(new_val)

# ─── ACCOUNT TAB ───────────────────────────────────────
func _build_account() -> void:
	for child in account_content.get_children():
		child.queue_free()

	account_content.add_child(_make_section_label("SESSION"))
	account_content.add_child(
		_make_info_row(
			"Logged in as",
			SupabaseManager.username + " (" + SupabaseManager.full_name + ")"
		)
	)

	var logout_btn := Button.new()
	logout_btn.text = "🚪 Logout"
	logout_btn.custom_minimum_size = Vector2(0, 48)
	_style_secondary_button(logout_btn)
	logout_btn.pressed.connect(_on_logout_pressed)
	account_content.add_child(logout_btn)

	account_content.add_child(_make_divider())
	account_content.add_child(_make_section_label("DANGER ZONE"))

	var warning := Label.new()
	warning.text = "⚠️ These actions cannot be undone. Proceed with caution."
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.add_theme_font_size_override("font_size", 12)
	warning.add_theme_color_override("font_color", Color("#FFB800"))
	account_content.add_child(warning)

	var reset_btn := Button.new()
	reset_btn.text = "🔄 Reset All Progress"
	reset_btn.custom_minimum_size = Vector2(0, 48)
	_style_danger_button(reset_btn, false)
	reset_btn.pressed.connect(_on_reset_pressed)
	account_content.add_child(reset_btn)

	var confirm_panel := _make_confirm_panel()
	confirm_panel.name    = "ConfirmPanel"
	confirm_panel.visible = false
	account_content.add_child(confirm_panel)

func _make_confirm_panel() -> PanelContainer:
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
	style.content_margin_top     = 16
	style.content_margin_bottom  = 16
	card.add_theme_stylebox_override("panel", style)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)

	var title := Label.new()
	title.text = "⚠️ Are you sure?"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("#FF3366"))
	layout.add_child(title)

	var msg := Label.new()
	msg.text = "This will permanently delete all your progress.\nYour account will remain but all lessons, towers and campaign data will be reset."
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.add_theme_font_size_override("font_size", 13)
	msg.add_theme_color_override("font_color", Color("#E8F4FD"))
	layout.add_child(msg)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.custom_minimum_size   = Vector2(0, 44)
	_style_secondary_button(cancel_btn)
	cancel_btn.pressed.connect(_on_cancel_reset)
	btn_row.add_child(cancel_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = "Yes, Reset Everything"
	confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_btn.custom_minimum_size   = Vector2(0, 44)
	_style_danger_button(confirm_btn, true)
	confirm_btn.pressed.connect(_on_confirm_reset)
	btn_row.add_child(confirm_btn)

	layout.add_child(btn_row)
	card.add_child(layout)
	return card

# ─── ACCOUNT ACTIONS ───────────────────────────────────
func _on_logout_pressed() -> void:
	SupabaseManager.logout()

func _on_reset_pressed() -> void:
	var confirm = account_content.get_node_or_null("ConfirmPanel")
	if confirm:
		confirm.visible = true

func _on_cancel_reset() -> void:
	var confirm = account_content.get_node_or_null("ConfirmPanel")
	if confirm:
		confirm.visible = false

func _on_confirm_reset() -> void:
	ProgressManager.reset_all_progress()
	SupabaseManager.save_progress_to_cloud()
	var confirm = account_content.get_node_or_null("ConfirmPanel")
	if confirm:
		confirm.visible = false
	SignalBus.hud_message_requested.emit(
		"Progress reset. Starting fresh!", 3.0
	)
	await get_tree().create_timer(1.5).timeout
	GameManager.go_to("main_menu")

# ─── HELPERS ───────────────────────────────────────────
func _make_section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color("#00D4FF"))
	return lbl

func _make_divider() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color("#1A3A5A"))
	return sep

func _make_info_row(label: String, value: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = Color("#1A3A5A")
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left    = 16
	style.content_margin_right   = 16
	style.content_margin_top     = 12
	style.content_margin_bottom  = 12
	card.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()

	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(120, 0)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	row.add_child(lbl)

	var val := Label.new()
	val.text = value if value != "" else "—"
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.add_theme_font_size_override("font_size", 13)
	val.add_theme_color_override("font_color", Color("#E8F4FD"))
	row.add_child(val)

	card.add_child(row)
	return card

func _make_mini_stat(
		label: String,
		value: String,
		color: Color) -> PanelContainer:
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

# ─── STYLES ────────────────────────────────────────────
func _apply_styles() -> void:
	var top_style := StyleBoxFlat.new()
	top_style.bg_color            = Color("#0A1628")
	top_style.border_color        = Color("#00D4FF")
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
	btn.add_theme_font_size_override("font_size", 13)

func _style_secondary_button(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = Color("#4A7FA5")
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color("#E8F4FD"))
	btn.add_theme_font_size_override("font_size", 13)

func _style_danger_button(btn: Button, filled: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#FF3366") if filled else Color("#0A1628")
	style.border_color           = Color("#FF3366")
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override(
		"font_color",
		Color("#FFFFFF") if filled else Color("#FF3366")
	)
	btn.add_theme_font_size_override("font_size", 13)

func _style_toggle_button(btn: Button, is_on: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#00D4FF") if is_on else Color("#0A1628")
	style.border_color           = Color("#00D4FF") if is_on else Color("#2A3A4A")
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override(
		"font_color",
		Color("#050D1A") if is_on else Color("#4A7FA5")
	)
	btn.add_theme_font_size_override("font_size", 13)

# ─── RESPONSIVE ────────────────────────────────────────
func _apply_responsive_layout() -> void:
	pass
