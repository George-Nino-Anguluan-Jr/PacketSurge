# Settings.gd
extends Control

# ─── NODE REFERENCES ───────────────────────────────────
@onready var back_btn: Button               = $TopBar/TopBarLayout/BackBtn
@onready var general_panel: ScrollContainer = $ContentArea/GeneralPanel
@onready var general_content: VBoxContainer = $ContentArea/GeneralPanel/GeneralContent

# ─── STATE ─────────────────────────────────────────────
var _last_device: String = ""

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	_setup_buttons()
	_apply_styles()
	_build_general()
	_apply_responsive_layout()
	ScreenManager.make_scroll_touch_friendly(general_panel)
	get_tree().root.size_changed.connect(_apply_responsive_layout)
	_maybe_show_tutorial()

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
		_make_slider_row(
			"Effects Volume",
			"Adjust sound effects volume",
			SoundManager.get_effects_volume(),
			_on_effects_volume_changed
		)
	)
	general_content.add_child(
		_make_slider_row(
			"Music Volume",
			"Adjust background music volume",
			SoundManager.get_music_volume(),
			_on_music_volume_changed
		)
	)

	general_content.add_child(_make_divider())
	general_content.add_child(_make_section_label("ABOUT"))
	general_content.add_child(_make_info_row("Version",   "v0.1.0"))
	general_content.add_child(_make_info_row("Engine",    "Godot 4"))
	general_content.add_child(_make_info_row("Backend",   "Supabase"))
	general_content.add_child(_make_info_row("Developer", "Packet Surge Team"))

# ─── GENERAL TOGGLE HANDLERS ───────────────────────────
func _on_effects_volume_changed(val: float) -> void:
	SoundManager.set_effects_volume(val)

func _on_music_volume_changed(val: float) -> void:
	SoundManager.set_music_volume(val)

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
	style.content_margin_left    = 12 if _is_compact() else 16
	style.content_margin_right   = 12 if _is_compact() else 16
	style.content_margin_top     = 8 if _is_compact() else 12
	style.content_margin_bottom  = 8 if _is_compact() else 12
	card.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)

	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 13 if _is_compact() else 14)
	lbl.add_theme_color_override("font_color", Color("#E8F4FD"))
	text_col.add_child(lbl)

	var desc := Label.new()
	desc.text          = description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 10 if _is_compact() else 11)
	desc.add_theme_color_override("font_color", Color("#4A7FA5"))
	text_col.add_child(desc)
	row.add_child(text_col)

	var toggle := Button.new()
	toggle.custom_minimum_size = Vector2(70 if _is_compact() else 80, 40 if _is_compact() else 36)
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

# ─── SLIDER ROW ────────────────────────────────────────
func _make_slider_row(
		label: String,
		description: String,
		current_value: float,
		on_changed: Callable) -> PanelContainer:

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
	style.content_margin_left    = 12 if _is_compact() else 16
	style.content_margin_right   = 12 if _is_compact() else 16
	style.content_margin_top     = 8 if _is_compact() else 12
	style.content_margin_bottom  = 8 if _is_compact() else 12
	card.add_theme_stylebox_override("panel", style)

	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 13 if _is_compact() else 14)
	lbl.add_theme_color_override("font_color", Color("#E8F4FD"))
	row.add_child(lbl)

	var desc := Label.new()
	desc.text          = description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 10 if _is_compact() else 11)
	desc.add_theme_color_override("font_color", Color("#4A7FA5"))
	row.add_child(desc)

	var slider_box := HBoxContainer.new()
	slider_box.add_theme_constant_override("separation", 12)

	var slider := HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(80 if _is_compact() else 100, 0)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = current_value
	slider.add_theme_color_override("grabber_color", Color("#00D4FF"))
	slider.add_theme_color_override("fill_color", Color("#00D4FF"))
	slider.add_theme_color_override("background_color", Color("#1A3A5A"))
	slider_box.add_child(slider)

	var pct_label := Label.new()
	pct_label.custom_minimum_size = Vector2(36 if _is_compact() else 40, 0)
	pct_label.text = str(int(current_value * 100)) + "%"
	pct_label.add_theme_font_size_override("font_size", 13 if _is_compact() else 14)
	pct_label.add_theme_color_override("font_color", Color("#00D4FF"))
	pct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	slider_box.add_child(pct_label)

	row.add_child(slider_box)
	card.add_child(row)

	slider.value_changed.connect(func(val: float):
		pct_label.text = str(int(val * 100)) + "%"
		on_changed.call(val)
	)

	return card

# ─── HELPERS ───────────────────────────────────────────
func _is_compact() -> bool:
	return ScreenManager.is_mobile() or ScreenManager.is_tablet()

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
	style.content_margin_left    = 12 if _is_compact() else 16
	style.content_margin_right   = 12 if _is_compact() else 16
	style.content_margin_top     = 8 if _is_compact() else 12
	style.content_margin_bottom  = 8 if _is_compact() else 12
	card.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()

	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(100 if _is_compact() else 120, 0)
	lbl.add_theme_font_size_override("font_size", 12 if _is_compact() else 13)
	lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	row.add_child(lbl)

	var val := Label.new()
	val.text = value if value != "" else "—"
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.add_theme_font_size_override("font_size", 12 if _is_compact() else 13)
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
	var current = "mobile" if ScreenManager.is_mobile() else "tablet" if ScreenManager.is_tablet() else "desktop"
	
	# Rebuild content if device category changed (widgets need different sizing)
	if current != _last_device:
		_last_device = current
		_build_general()
	
	# Adjust scene-level layout
	var top_bar = $TopBar
	var content_area = $ContentArea
	var title_label = $TopBar/TopBarLayout/TitleLabel
	
	if ScreenManager.is_mobile():
		ScreenManager.apply_panel_padding(top_bar, 20)
		content_area.add_theme_constant_override("margin_left", 20)
		content_area.add_theme_constant_override("margin_right", 20)
		content_area.add_theme_constant_override("margin_top", 20)
		content_area.add_theme_constant_override("margin_bottom", 20)
		back_btn.custom_minimum_size = Vector2(70, 44)
		title_label.add_theme_font_size_override("font_size", 14)
	elif ScreenManager.is_tablet():
		ScreenManager.apply_panel_padding(top_bar, 24)
		content_area.add_theme_constant_override("margin_left", 24)
		content_area.add_theme_constant_override("margin_right", 24)
		content_area.add_theme_constant_override("margin_top", 24)
		content_area.add_theme_constant_override("margin_bottom", 24)
		back_btn.custom_minimum_size = Vector2(80, 44)
		title_label.add_theme_font_size_override("font_size", 15)
	else:
		back_btn.custom_minimum_size = Vector2(90, 0)
		title_label.add_theme_font_size_override("font_size", 16)

# ─── TUTORIAL ──────────────────────────────────────────
const TutorialOverlay = preload("res://scenes/core/TutorialOverlay.gd")

func _maybe_show_tutorial() -> void:
	if ProgressManager.has_seen_tutorial("settings"):
		return
	await get_tree().process_frame
	var tut = TutorialOverlay.new()
	add_child(tut)
	tut.tutorial_finished.connect(func(): ProgressManager.mark_tutorial_seen("settings"))
	tut.start(_get_settings_tutorial_steps())

func _get_settings_tutorial_steps() -> Array:
	var steps: Array = []
	steps.append({
		"title": "Settings",
		"body": "Tweak audio, configure your account, and learn about the game from here.\n\nLet's take a quick tour.",
		"force_center": true,
	})
	steps.append({
		"title": "Audio Settings",
		"body": "Drag the sliders to adjust effects volume and background music.\nChanges apply instantly.",
		"highlight": general_content.get_path(),
	})
	steps.append({
		"title": "About",
		"body": "Scroll down to see the version info, engine, and developer credits.",
		"highlight": general_panel.get_path(),
	})
	steps.append({
		"title": "Back Button",
		"body": "Tap here anytime to return to the main menu.",
		"highlight": back_btn.get_path(),
	})
	steps.append({
		"title": "All Set!",
		"body": "Settings auto-save — no need to confirm. Have fun, operator!",
		"force_center": true,
	})
	return steps
