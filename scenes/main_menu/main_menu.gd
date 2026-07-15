# MainMenu.gd
extends Control

# ─── NODE REFERENCES ───────────────────────────────────
@onready var academy_button: Button     = $CenterContainer/MainLayout/ButtonSection/AcademyButton
@onready var campaign_button: Button    = $CenterContainer/MainLayout/ButtonSection/CampaignButton
@onready var index_button: Button       = $CenterContainer/MainLayout/ButtonSection/IndexButton
@onready var leaderboard_button: Button = $TopLeftContainer/LeaderboardButton
@onready var settings_button: Button    = $TopLeftContainer/SettingsButton
@onready var title_label: Label         = $CenterContainer/MainLayout/TitleSection/TitleLabel

# Profile UI Nodes
@onready var profile_card: PanelContainer   = $TopLeftContainer/ProfileCard
@onready var avatar_panel: PanelContainer   = $TopLeftContainer/ProfileCard/MarginContainer/ProfileLayout/AvatarPanel
@onready var avatar_label: Label           = $TopLeftContainer/ProfileCard/MarginContainer/ProfileLayout/AvatarPanel/AvatarLabel
@onready var username_label: Label         = $TopLeftContainer/ProfileCard/MarginContainer/ProfileLayout/TextLayout/UsernameLabel
@onready var class_label: Label            = $TopLeftContainer/ProfileCard/MarginContainer/ProfileLayout/TextLayout/ClassLabel
@onready var profile_popup: ColorRect       = $ProfilePopup

var _core_buttons: Array[Button]  = []
var _all_buttons: Array[Button]   = []
var _time: float = 0.0

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	_core_buttons = [
		campaign_button,
		academy_button,
		index_button,
	]
	_all_buttons = [
		campaign_button,
		academy_button,
		index_button,
	]
	_setup_buttons()
	_setup_profile_card()
	_animate_title_in()
	_apply_responsive_layout()
	get_tree().root.size_changed.connect(_apply_responsive_layout)
	_check_placement_quiz()
	
func _check_placement_quiz() -> void:
	var quiz_done = ProgressManager.campaign_progress.get(
		"placement_quiz_done", false
	)
	if not quiz_done:
		# First time — show placement quiz
		await get_tree().create_timer(0.5).timeout
		GameManager.go_to("placement_quiz")

# ─── BUTTON SETUP ──────────────────────────────────────
func _setup_buttons() -> void:
	academy_button.pressed.connect(func(): GameManager.go_to("academy"))
	campaign_button.pressed.connect(func(): GameManager.go_to("campaign"))
	index_button.pressed.connect(func(): GameManager.go_to("index"))
	leaderboard_button.pressed.connect(func(): GameManager.go_to("leaderboard"))
	settings_button.pressed.connect(func(): GameManager.go_to("settings"))

	# Style main buttons
	for btn in _all_buttons:
		_style_menu_button(btn)

	# Style icon buttons
	_style_icon_button(leaderboard_button)
	_style_icon_button(settings_button)

# ─── BUTTON STYLES ─────────────────────────────────────
func _style_menu_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color            = Color("#0A1628")
	normal.border_color        = Color("#00D4FF")
	normal.border_width_left   = 1
	normal.border_width_right  = 1
	normal.border_width_top    = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left     = 4
	normal.corner_radius_top_right    = 4
	normal.corner_radius_bottom_left  = 4
	normal.corner_radius_bottom_right = 4

	var hover := StyleBoxFlat.new()
	hover.bg_color             = Color("#0D2040")
	hover.border_color         = Color("#00D4FF")
	hover.border_width_left    = 2
	hover.border_width_right   = 2
	hover.border_width_top     = 2
	hover.border_width_bottom  = 2
	hover.corner_radius_top_left     = 4
	hover.corner_radius_top_right    = 4
	hover.corner_radius_bottom_left  = 4
	hover.corner_radius_bottom_right = 4

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color("#00D4FF")
	pressed.corner_radius_top_left     = 4
	pressed.corner_radius_top_right    = 4
	pressed.corner_radius_bottom_left  = 4
	pressed.corner_radius_bottom_right = 4

	button.add_theme_stylebox_override("normal",  normal)
	button.add_theme_stylebox_override("hover",   hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color",         Color("#E8F4FD"))
	button.add_theme_color_override("font_hover_color",   Color("#00D4FF"))
	button.add_theme_color_override("font_pressed_color", Color("#050D1A"))
	button.add_theme_font_size_override("font_size", 13)

func _style_icon_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color            = Color("#0A1628", 0.6)
	normal.border_color        = Color("#00D4FF", 0.4)
	normal.border_width_left   = 1
	normal.border_width_right  = 1
	normal.border_width_top    = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left     = 8
	normal.corner_radius_top_right    = 8
	normal.corner_radius_bottom_left  = 8
	normal.corner_radius_bottom_right = 8

	var hover := StyleBoxFlat.new()
	hover.bg_color             = Color("#0D2040", 0.8)
	hover.border_color         = Color("#00D4FF")
	hover.border_width_left    = 1.5
	hover.border_width_right   = 1.5
	hover.border_width_top     = 1.5
	hover.border_width_bottom  = 1.5
	hover.corner_radius_top_left     = 8
	hover.corner_radius_top_right    = 8
	hover.corner_radius_bottom_left  = 8
	hover.corner_radius_bottom_right = 8

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color("#00D4FF")
	pressed.corner_radius_top_left     = 8
	pressed.corner_radius_top_right    = 8
	pressed.corner_radius_bottom_left  = 8
	pressed.corner_radius_bottom_right = 8

	button.add_theme_stylebox_override("normal",  normal)
	button.add_theme_stylebox_override("hover",   hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color",         Color("#00D4FF"))
	button.add_theme_color_override("font_hover_color",   Color("#E8F4FD"))
	button.add_theme_color_override("font_pressed_color", Color("#050D1A"))
	button.add_theme_font_size_override("font_size", 22)

# ─── TITLE ANIMATION ───────────────────────────────────
func _animate_title_in() -> void:
	title_label.modulate.a  = 0.0
	title_label.position.y -= 20
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.8)
	tween.parallel().tween_property(
		title_label, "position:y",
		title_label.position.y + 20, 0.8
	)

func _process(delta: float) -> void:
	_time += delta
	var pulse        = (sin(_time * 2.0) + 1.0) / 2.0
	var base_color   = Color("#00D4FF")
	var bright_color = Color("#80EAFF")
	title_label.add_theme_color_override(
		"font_color", base_color.lerp(bright_color, pulse * 0.4)
	)

# ─── PROFILE CARD ──────────────────────────────────────
func _setup_profile_card() -> void:
	if not SupabaseManager.is_logged_in:
		profile_card.visible = false
		return
	
	profile_card.visible = true
	
	# Set user data
	var uname = SupabaseManager.username
	username_label.text = uname if uname != "" else "Student"
	avatar_label.text = uname.left(1).to_upper() if uname != "" else "S"
	
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
		
	# Connect click signal
	if not profile_card.gui_input.is_connected(_on_profile_card_gui_input):
		profile_card.gui_input.connect(_on_profile_card_gui_input)
		
	_style_profile_card()

func _on_profile_card_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if profile_popup.has_method("open"):
			profile_popup.open()

func _style_profile_card() -> void:
	# Card glass/tech style
	var card_style := StyleBoxFlat.new()
	card_style.bg_color               = Color("#0A1628", 0.85)
	card_style.border_color           = Color("#00D4FF")
	card_style.border_width_left      = 1
	card_style.border_width_right     = 1
	card_style.border_width_top       = 1
	card_style.border_width_bottom    = 1
	card_style.corner_radius_top_left     = 8
	card_style.corner_radius_top_right    = 8
	card_style.corner_radius_bottom_left  = 8
	card_style.corner_radius_bottom_right = 8
	profile_card.add_theme_stylebox_override("panel", card_style)

	# Avatar tech panel style
	var avatar_style := StyleBoxFlat.new()
	avatar_style.bg_color               = Color("#080F1E")
	avatar_style.border_color           = Color("#00D4FF", 0.5)
	avatar_style.border_width_left      = 1
	avatar_style.border_width_right     = 1
	avatar_style.border_width_top       = 1
	avatar_style.border_width_bottom    = 1
	avatar_style.corner_radius_top_left     = 4
	avatar_style.corner_radius_top_right    = 4
	avatar_style.corner_radius_bottom_left  = 4
	avatar_style.corner_radius_bottom_right = 4
	avatar_panel.add_theme_stylebox_override("panel", avatar_style)

# ─── RESPONSIVE ────────────────────────────────────────
func _apply_responsive_layout() -> void:
	if ScreenManager.is_mobile():
		title_label.add_theme_font_size_override("font_size", 38)
		for btn in _all_buttons:
			btn.custom_minimum_size = Vector2(260, 48)
	elif ScreenManager.is_tablet():
		title_label.add_theme_font_size_override("font_size", 52)
		for btn in _all_buttons:
			btn.custom_minimum_size = Vector2(300, 50)
	else:
		title_label.add_theme_font_size_override("font_size", 64)
		for btn in _all_buttons:
			btn.custom_minimum_size = Vector2(320, 52)
