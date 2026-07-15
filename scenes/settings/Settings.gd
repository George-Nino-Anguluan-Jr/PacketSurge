# Settings.gd
extends Control

# ─── NODE REFERENCES ───────────────────────────────────
@onready var back_btn: Button               = $TopBar/TopBarLayout/BackBtn
@onready var general_panel: ScrollContainer = $ContentArea/GeneralPanel
@onready var general_content: VBoxContainer = $ContentArea/GeneralPanel/GeneralContent

# ─── STATE ─────────────────────────────────────────────
var sound_enabled: bool = true
var music_enabled: bool = true
var shake_enabled: bool = true

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	_setup_buttons()
	_apply_styles()
	_build_general()
	_apply_responsive_layout()
	get_tree().root.size_changed.connect(_apply_responsive_layout)

# ─── BUTTON SETUP ──────────────────────────────────────
func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	GameManager.go_to("main_menu")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to("main_menu")

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
