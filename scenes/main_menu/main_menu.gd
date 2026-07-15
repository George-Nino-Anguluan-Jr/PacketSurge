# MainMenu.gd
extends Control

# ─── NODE REFERENCES ───────────────────────────────────
@onready var continue_button: Button    = $CenterContainer/MainLayout/ButtonSection/ContinueButton
@onready var academy_button: Button     = $CenterContainer/MainLayout/ButtonSection/CoreGrid/AcademyButton
@onready var campaign_button: Button    = $CenterContainer/MainLayout/ButtonSection/CoreGrid/CampaignButton
@onready var sandbox_button: Button     = $CenterContainer/MainLayout/ButtonSection/CoreGrid/SandboxButton
@onready var index_button: Button       = $CenterContainer/MainLayout/ButtonSection/CoreGrid/IndexButton
@onready var leaderboard_button: Button = $CenterContainer/MainLayout/ButtonSection/ExtraGrid/LeaderboardButton
@onready var settings_button: Button    = $CenterContainer/MainLayout/ButtonSection/SettingsButton
@onready var title_label: Label         = $CenterContainer/MainLayout/TitleSection/TitleLabel

# Profile UI Nodes
@onready var profile_card: PanelContainer   = $ProfileCard
@onready var avatar_panel: PanelContainer   = $ProfileCard/MarginContainer/ProfileLayout/AvatarPanel
@onready var avatar_label: Label           = $ProfileCard/MarginContainer/ProfileLayout/AvatarPanel/AvatarLabel
@onready var username_label: Label         = $ProfileCard/MarginContainer/ProfileLayout/TextLayout/UsernameLabel
@onready var class_label: Label            = $ProfileCard/MarginContainer/ProfileLayout/TextLayout/ClassLabel
@onready var profile_popup: ColorRect       = $ProfilePopup

var _core_buttons: Array[Button]  = []
var _all_buttons: Array[Button]   = []
var _time: float = 0.0

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	_core_buttons = [
		academy_button, campaign_button,
		sandbox_button, index_button,
		leaderboard_button,
	]
	_all_buttons = [
		continue_button,
		academy_button, campaign_button,
		sandbox_button, index_button,
		leaderboard_button,
		settings_button,
	]
	_setup_buttons()
	_setup_profile_card()
	_check_continue_button()
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
	continue_button.pressed.connect(_on_continue_pressed)
	academy_button.pressed.connect(func(): GameManager.go_to("academy"))
	campaign_button.pressed.connect(func(): GameManager.go_to("campaign"))
	sandbox_button.pressed.connect(func(): GameManager.go_to("sandbox"))
	index_button.pressed.connect(func(): GameManager.go_to("index"))
	leaderboard_button.pressed.connect(func(): GameManager.go_to("leaderboard"))
	settings_button.pressed.connect(func(): GameManager.go_to("settings"))

	# Style main buttons
	for btn in _all_buttons:
		_style_menu_button(btn)

	# Continue gets accent style
	_style_continue_button(continue_button)

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

func _style_continue_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color            = Color("#00D4FF", 0.15)
	normal.border_color        = Color("#00D4FF")
	normal.border_width_left   = 2
	normal.border_width_right  = 2
	normal.border_width_top    = 2
	normal.border_width_bottom = 2
	normal.corner_radius_top_left     = 4
	normal.corner_radius_top_right    = 4
	normal.corner_radius_bottom_left  = 4
	normal.corner_radius_bottom_right = 4

	var hover := StyleBoxFlat.new()
	hover.bg_color             = Color("#00D4FF", 0.25)
	hover.border_color         = Color("#00D4FF")
	hover.border_width_left    = 2
	hover.border_width_right   = 2
	hover.border_width_top     = 2
	hover.border_width_bottom  = 2
	hover.corner_radius_top_left     = 4
	hover.corner_radius_top_right    = 4
	hover.corner_radius_bottom_left  = 4
	hover.corner_radius_bottom_right = 4

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover",  hover)
	button.add_theme_color_override("font_color",       Color("#00D4FF"))
	button.add_theme_color_override("font_hover_color", Color("#E8F4FD"))
	button.add_theme_font_size_override("font_size", 14)

func _style_settings_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color            = Color("#080F1E")
	normal.border_color        = Color("#2A3A4A")
	normal.border_width_left   = 1
	normal.border_width_right  = 1
	normal.border_width_top    = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left     = 4
	normal.corner_radius_top_right    = 4
	normal.corner_radius_bottom_left  = 4
	normal.corner_radius_bottom_right = 4

	var hover := StyleBoxFlat.new()
	hover.bg_color             = Color("#0A1628")
	hover.border_color         = Color("#4A7FA5")
	hover.border_width_left    = 1
	hover.border_width_right   = 1
	hover.border_width_top     = 1
	hover.border_width_bottom  = 1
	hover.corner_radius_top_left     = 4
	hover.corner_radius_top_right    = 4
	hover.corner_radius_bottom_left  = 4
	hover.corner_radius_bottom_right = 4

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover",  hover)
	button.add_theme_color_override("font_color",       Color("#4A7FA5"))
	button.add_theme_color_override("font_hover_color", Color("#E8F4FD"))
	button.add_theme_font_size_override("font_size", 12)

# ─── CONTINUE ──────────────────────────────────────────
func _check_continue_button() -> void:
	var has_progress := false
	for topic_id in ProgressManager.topic_states:
		if ProgressManager.topic_states[topic_id] == "mastered":
			has_progress = true
			break
	continue_button.visible = has_progress

func _on_continue_pressed() -> void:
	if SupabaseManager.is_logged_in:
		SupabaseManager.load_progress_from_cloud()
	GameManager.go_to("academy")

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
	var core_grid = $CenterContainer/MainLayout/ButtonSection/CoreGrid
	var extra_grid = $CenterContainer/MainLayout/ButtonSection/ExtraGrid

	if ScreenManager.is_mobile():
		title_label.add_theme_font_size_override("font_size", 38)
		core_grid.columns  = 1
		extra_grid.columns = 1
		for btn in _all_buttons:
			btn.custom_minimum_size = Vector2(260, 48)
	elif ScreenManager.is_tablet():
		title_label.add_theme_font_size_override("font_size", 52)
		core_grid.columns  = 2
		extra_grid.columns = 1
		for btn in _all_buttons:
			btn.custom_minimum_size = Vector2(160, 50)
	else:
		title_label.add_theme_font_size_override("font_size", 64)
		core_grid.columns  = 2
		extra_grid.columns = 1
		for btn in _all_buttons:
			btn.custom_minimum_size = Vector2(180, 52)
