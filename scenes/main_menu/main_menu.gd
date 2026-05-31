# MainMenu.gd
extends Control

# ─── NODE REFERENCES ───────────────────────────────────
@onready var continue_button: Button  = $CenterContainer/MainLayout/ButtonSection/ContinueButton
@onready var new_game_button: Button  = $CenterContainer/MainLayout/ButtonSection/NewGameButton
@onready var academy_button: Button   = $CenterContainer/MainLayout/ButtonSection/AcademyButton
@onready var campaign_button: Button  = $CenterContainer/MainLayout/ButtonSection/CampaignButton
@onready var index_button: Button     = $CenterContainer/MainLayout/ButtonSection/IndexButton
@onready var sound_button: Button     = $BottomBar/SoundButton
@onready var title_label: Label       = $CenterContainer/MainLayout/TitleSection/TitleLabel

# ─── STATE ─────────────────────────────────────────────
var sound_enabled: bool = true
var _time: float = 0.0

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	_setup_buttons()
	_check_continue_button()
	_animate_title_in()
	_apply_responsive_layout()  # ← add this line
	# Listen for screen resize (user rotates phone)
	get_tree().root.size_changed.connect(_apply_responsive_layout)

# ─── RESPONSIVE LAYOUT ─────────────────────────────────
func _apply_responsive_layout() -> void:
	if ScreenManager.is_mobile():
		_apply_mobile_layout()
	elif ScreenManager.is_tablet():
		_apply_tablet_layout()
	else:
		_apply_desktop_layout()

func _apply_mobile_layout() -> void:
	# Smaller title on mobile
	title_label.add_theme_font_size_override("font_size", 38)
	# Narrower buttons — fill more of the screen width
	for button in [continue_button, new_game_button, academy_button,
				   campaign_button, index_button]:
		button.custom_minimum_size = Vector2(260, 52)

func _apply_tablet_layout() -> void:
	title_label.add_theme_font_size_override("font_size", 52)
	for button in [continue_button, new_game_button, academy_button,
				   campaign_button, index_button]:
		button.custom_minimum_size = Vector2(280, 52)

func _apply_desktop_layout() -> void:
	title_label.add_theme_font_size_override("font_size", 64)
	for button in [continue_button, new_game_button, academy_button,
				   campaign_button, index_button]:
		button.custom_minimum_size = Vector2(280, 52)

# ─── BUTTON SETUP ──────────────────────────────────────
func _setup_buttons() -> void:
	# Connect every button to its function
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	academy_button.pressed.connect(_on_academy_pressed)
	campaign_button.pressed.connect(_on_campaign_pressed)
	index_button.pressed.connect(_on_index_pressed)
	sound_button.pressed.connect(_on_sound_toggled)

	# Style buttons with cyber look
	for button in [continue_button, new_game_button, academy_button,
				   campaign_button, index_button]:
		_style_menu_button(button)

func _style_menu_button(button: Button) -> void:
	# Create a dark panel style for normal state
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color          = Color("#0A1628")
	normal_style.border_color      = Color("#00D4FF")
	normal_style.border_width_left   = 1
	normal_style.border_width_right  = 1
	normal_style.border_width_top    = 1
	normal_style.border_width_bottom = 1
	normal_style.corner_radius_top_left     = 4
	normal_style.corner_radius_top_right    = 4
	normal_style.corner_radius_bottom_left  = 4
	normal_style.corner_radius_bottom_right = 4

	# Hover state — brighter border + slight bg change
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color          = Color("#0D2040")
	hover_style.border_color      = Color("#00D4FF")
	hover_style.border_width_left   = 2
	hover_style.border_width_right  = 2
	hover_style.border_width_top    = 2
	hover_style.border_width_bottom = 2
	hover_style.corner_radius_top_left     = 4
	hover_style.corner_radius_top_right    = 4
	hover_style.corner_radius_bottom_left  = 4
	hover_style.corner_radius_bottom_right = 4

	# Pressed state — filled with accent color
	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color     = Color("#00D4FF")
	pressed_style.corner_radius_top_left     = 4
	pressed_style.corner_radius_top_right    = 4
	pressed_style.corner_radius_bottom_left  = 4
	pressed_style.corner_radius_bottom_right = 4

	button.add_theme_stylebox_override("normal",  normal_style)
	button.add_theme_stylebox_override("hover",   hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_color_override("font_color",          Color("#E8F4FD"))
	button.add_theme_color_override("font_hover_color",    Color("#00D4FF"))
	button.add_theme_color_override("font_pressed_color",  Color("#050D1A"))

# ─── CONTINUE BUTTON VISIBILITY ────────────────────────
func _check_continue_button() -> void:
	# Only show Continue if there's actual saved progress
	var has_progress := false
	for topic_id in ProgressManager.topic_states:
		if ProgressManager.topic_states[topic_id] == "mastered":
			has_progress = true
			break
	continue_button.visible = has_progress

# ─── TITLE ANIMATION ───────────────────────────────────
func _animate_title_in() -> void:
	# Fade + slide in from above using a Tween
	title_label.modulate.a = 0.0
	title_label.position.y -= 20

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.8)
	tween.parallel().tween_property(title_label, "position:y",
									title_label.position.y + 20, 0.8)

# ─── TITLE PULSE (runs every frame) ────────────────────
func _process(delta: float) -> void:
	_time += delta
	# Gentle cyan glow pulse on title
	var pulse = (sin(_time * 2.0) + 1.0) / 2.0  # 0.0 to 1.0
	var base_color  = Color("#00D4FF")
	var bright_color = Color("#80EAFF")
	title_label.add_theme_color_override("font_color",
										 base_color.lerp(bright_color, pulse * 0.4))

# ─── BUTTON HANDLERS ───────────────────────────────────
func _on_continue_pressed() -> void:
	print("[MainMenu] Continue pressed")
	GameManager.go_to("academy")  # Goes to last visited — improve later

func _on_new_game_pressed() -> void:
	print("[MainMenu] New Game pressed")
	ProgressManager.reset_all_progress()
	GameManager.go_to("academy")

func _on_academy_pressed() -> void:
	GameManager.go_to("academy")

func _on_campaign_pressed() -> void:
	GameManager.go_to("campaign")

func _on_index_pressed() -> void:
	GameManager.go_to("index")

func _on_sound_toggled() -> void:
	sound_enabled = !sound_enabled
	sound_button.text = "♪ Sound ON" if sound_enabled else "♪ Sound OFF"
	AudioServer.set_bus_mute(0, !sound_enabled)
