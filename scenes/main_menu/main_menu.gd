# MainMenu.gd
extends Control

# ─── NODE REFERENCES ───────────────────────────────────
@onready var continue_button: Button    = $CenterContainer/MainLayout/ButtonSection/ContinueButton
@onready var academy_button: Button     = $CenterContainer/MainLayout/ButtonSection/CoreGrid/AcademyButton
@onready var campaign_button: Button    = $CenterContainer/MainLayout/ButtonSection/CoreGrid/CampaignButton
@onready var sandbox_button: Button     = $CenterContainer/MainLayout/ButtonSection/CoreGrid/SandboxButton
@onready var index_button: Button       = $CenterContainer/MainLayout/ButtonSection/CoreGrid/IndexButton
@onready var leaderboard_button: Button = $CenterContainer/MainLayout/ButtonSection/ExtraGrid/LeaderboardButton
@onready var analytics_button: Button   = $CenterContainer/MainLayout/ButtonSection/ExtraGrid/AnalyticsButton
@onready var settings_button: Button    = $CenterContainer/MainLayout/ButtonSection/SettingsButton
@onready var title_label: Label         = $CenterContainer/MainLayout/TitleSection/TitleLabel

var _core_buttons: Array[Button]  = []
var _all_buttons: Array[Button]   = []
var _time: float = 0.0

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	_core_buttons = [
		academy_button, campaign_button,
		sandbox_button, index_button,
		leaderboard_button, analytics_button,
	]
	_all_buttons = [
		continue_button,
		academy_button, campaign_button,
		sandbox_button, index_button,
		leaderboard_button, analytics_button,
		settings_button,
	]
	_setup_buttons()
	_check_continue_button()
	_animate_title_in()
	_apply_responsive_layout()
	get_tree().root.size_changed.connect(_apply_responsive_layout)

# ─── BUTTON SETUP ──────────────────────────────────────
func _setup_buttons() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	academy_button.pressed.connect(func(): GameManager.go_to("academy"))
	campaign_button.pressed.connect(func(): GameManager.go_to("campaign"))
	sandbox_button.pressed.connect(func(): GameManager.go_to("sandbox"))
	index_button.pressed.connect(func(): GameManager.go_to("index"))
	leaderboard_button.pressed.connect(func(): GameManager.go_to("leaderboard"))
	analytics_button.pressed.connect(func(): GameManager.go_to("analytics"))
	settings_button.pressed.connect(func(): GameManager.go_to("settings"))

	# Style main buttons
	for btn in _all_buttons:
		_style_menu_button(btn)

	# Override settings with muted style
	_style_settings_button(settings_button)

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
		extra_grid.columns = 2
		for btn in _all_buttons:
			btn.custom_minimum_size = Vector2(160, 50)
	else:
		title_label.add_theme_font_size_override("font_size", 64)
		core_grid.columns  = 2
		extra_grid.columns = 2
		for btn in _all_buttons:
			btn.custom_minimum_size = Vector2(180, 52)
