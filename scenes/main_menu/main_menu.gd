# MainMenu.gd
extends Control

# ─── NODE REFERENCES ───────────────────────────────────
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var academy_button: Button     = $ScrollContainer/CenterContainer/MainLayout/ButtonSection/AcademyButton
@onready var campaign_button: Button    = $ScrollContainer/CenterContainer/MainLayout/ButtonSection/CampaignButton
@onready var index_button: Button       = $ScrollContainer/CenterContainer/MainLayout/ButtonSection/IndexButton
@onready var leaderboard_button: Button = $TopLeftContainer/LeaderboardButton
@onready var settings_button: Button    = $TopLeftContainer/SettingsButton
@onready var title_label: Label         = $ScrollContainer/CenterContainer/MainLayout/TitleSection/TitleLabel
@onready var version_label: Label       = $BottomBar/VersionLabel

# Profile UI Nodes
@onready var profile_card: PanelContainer   = $TopLeftContainer/ProfileCard
@onready var avatar_panel: PanelContainer   = $TopLeftContainer/ProfileCard/MarginContainer/ProfileLayout/AvatarPanel
@onready var avatar_label: Label           = $TopLeftContainer/ProfileCard/MarginContainer/ProfileLayout/AvatarPanel/AvatarLabel
@onready var username_label: Label         = $TopLeftContainer/ProfileCard/MarginContainer/ProfileLayout/TextLayout/UsernameLabel
@onready var class_label: Label            = $TopLeftContainer/ProfileCard/MarginContainer/ProfileLayout/TextLayout/ClassLabel
var _core_buttons: Array[Button]  = []
var _all_buttons: Array[Button]   = []
var _continue_btn: Button = null
var _time: float = 0.0

var _final_title: String = "PACKET SURGE"
var _current_decoded_length: int = 0
var _decode_timer: float = 0.0
var _is_decoding: bool = true

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	# Hide or blend GridOverlay to let our shader shine
	if has_node("GridOverlay"):
		$GridOverlay.visible = false
		
	# Apply minimal performance-friendly background shader
	var bg_material := ShaderMaterial.new()
	bg_material.shader = load("res://assets/themes/minimal_system_bg.gdshader")
	if has_node("Background"):
		$Background.material = bg_material

	# Sci-fi title outline/shadow styling
	title_label.add_theme_color_override("font_outline_color", Color("#004C66"))
	title_label.add_theme_constant_override("outline_size", 10)
	title_label.add_theme_color_override("font_shadow_color", Color("#000D1A", 0.8))
	title_label.add_theme_constant_override("shadow_offset_x", 5)
	title_label.add_theme_constant_override("shadow_offset_y", 5)

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
	_build_continue_button()
	_apply_responsive_layout()
	get_tree().root.size_changed.connect(_apply_responsive_layout)
	ScreenManager.make_scroll_touch_friendly(scroll_container)
	_check_placement_quiz()
	_connect_button_sounds(self)
	_maybe_show_tutorial()

func _build_continue_button() -> void:
	var section = $ScrollContainer/CenterContainer/MainLayout/ButtonSection
	_continue_btn = Button.new()
	_continue_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var action = _get_next_action()
	_continue_btn.text = action["text"]
	var st := StyleBoxFlat.new()
	st.bg_color = Color("#00D4FF", 0.15)
	st.border_color = Color("#00D4FF")
	st.border_width_left = 2
	st.border_width_right = 2
	st.border_width_top = 2
	st.border_width_bottom = 2
	st.corner_radius_top_left = 6
	st.corner_radius_top_right = 6
	st.corner_radius_bottom_left = 6
	st.corner_radius_bottom_right = 6
	_continue_btn.add_theme_stylebox_override("normal", st)
	_continue_btn.add_theme_color_override("font_color", Color("#00D4FF"))
	_continue_btn.pressed.connect(action["callback"])
	section.add_child(_continue_btn)
	section.move_child(_continue_btn, 0)
	_all_buttons.append(_continue_btn)

func _get_next_action() -> Dictionary:
	# 1. Placement quiz not done
	if not ProgressManager.campaign_progress.get("placement_quiz_done", false):
		return {
			"text": "▶ Start Placement Quiz",
			"callback": func(): GameManager.go_to("placement_quiz")
		}
	# 2. Find first unlocked, not-mastered lesson
	for lesson_id in ProgressManager.ALL_LESSONS:
		var state = ProgressManager.get_topic_state(lesson_id)
		if state == "unlocked":
			var name = lesson_id
			return {
				"text": "📘 Continue: " + name,
				"callback": func(): GameManager.go_to("academy")
			}
	# 3. Find next uncompleted unlocked campaign level
	for lvl in DataRegistry.get_level_numbers():
		if ProgressManager.is_level_unlocked(lvl):
			var completed = ProgressManager.campaign_progress.get("waves_completed", 0) >= lvl
			if not completed:
				return {
					"text": "⚔️ Play Level " + str(lvl),
					"callback": func():
						GameManager.current_level = lvl
						GameManager.go_to("campaign")
				}
	# 4. Fallback — all done
	return {
		"text": "🏆 All Complete! Explore",
		"callback": func(): GameManager.go_to("academy")
	}

func _check_placement_quiz() -> void:
	var quiz_done = ProgressManager.campaign_progress.get(
		"placement_quiz_done", false
	)
	if not quiz_done:
		await get_tree().create_timer(0.5).timeout
		GameManager.go_to("placement_quiz")

func _connect_button_sounds(node: Node) -> void:
	var sfx = get_node_or_null("/root/SoundManager")
	if sfx and node is Button:
		if not node.mouse_entered.is_connected(sfx.play_hover):
			node.mouse_entered.connect(sfx.play_hover)
		if not node.pressed.is_connected(sfx.play_click):
			node.pressed.connect(sfx.play_click)
	
	for child in node.get_children():
		_connect_button_sounds(child)
	
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
	# font_size set dynamically in _apply_responsive_layout()

func _style_icon_button(button: Button) -> void:
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.expand_icon = false

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
	button.add_theme_color_override("icon_normal_color",  Color("#00D4FF"))
	button.add_theme_color_override("icon_hover_color",   Color("#E8F4FD"))
	button.add_theme_color_override("icon_pressed_color", Color("#050D1A"))
	# font_size set dynamically in _apply_responsive_layout()

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
		GameManager.go_to("profile")

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
	var top_left_container: HBoxContainer = $TopLeftContainer
	# Read the canvas size directly — works under stretch mode for any
	# window/screen and adapts on every resize. No device-class guessing.
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var w := maxf(vp.x, 320.0)
	var h := maxf(vp.y, 240.0)
	var min_dim := minf(w, h)

	# Continuous (fluid) typography — interpolates smoothly, no tiers
	# Floors ensure readability on tiny screens; caps prevent absurd sizes on huge displays
	title_label.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.060, 42.0, 68.0)))
	_continue_btn.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.017, 16.0, 19.0)))
	for btn in _all_buttons:
		btn.custom_minimum_size = Vector2(clampf(w * 0.30, 300.0, 420.0), clampf(h * 0.085, 50.0, 60.0))
	for btn in _core_buttons:
		btn.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.016, 17.0, 18.0)))

	# Profile card typography
	username_label.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.020, 16.0, 22.0)))
	class_label.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.016, 16.0, 18.0)))
	avatar_label.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.025, 22.0, 28.0)))
	var icon_font := int(clampf(min_dim * 0.022, 20.0, 26.0))
	leaderboard_button.add_theme_font_size_override("font_size", icon_font)
	settings_button.add_theme_font_size_override("font_size", icon_font)

	# Version label (bottom bar)
	version_label.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.011, 16.0, 18.0)))

	# Fluid corner positioning + spacing
	var inset := clampf(min_dim * 0.022, 10.0, 24.0)
	top_left_container.offset_left = inset
	top_left_container.offset_top = inset
	top_left_container.offset_right = clampf(w * 0.45, 320.0, 500.0)
	top_left_container.add_theme_constant_override("separation", clampf(min_dim * 0.012, 8.0, 12.0))
	var icon_size := clampf(min_dim * 0.046, 44.0, 52.0)
	leaderboard_button.custom_minimum_size = Vector2(icon_size, icon_size)
	settings_button.custom_minimum_size = Vector2(icon_size, icon_size)

	# Bottom bar — keep it inset from the edges by the same fluid margin
	var bottom_bar := $BottomBar
	bottom_bar.offset_left = inset
	bottom_bar.offset_bottom = -inset

	# Continue button dynamic size (already in _all_buttons loop above)

# ─── TUTORIAL ──────────────────────────────────────────
const TutorialOverlay = preload("res://scenes/core/TutorialOverlay.gd")

func _maybe_show_tutorial() -> void:
	if ProgressManager.has_seen_tutorial("main_menu"):
		return
	# Wait for layout/buttons to settle
	await get_tree().process_frame
	var tut = TutorialOverlay.new()
	add_child(tut)
	tut.tutorial_finished.connect(func(): ProgressManager.mark_tutorial_seen("main_menu"))
	tut.start(_get_main_menu_tutorial_steps())

func _get_main_menu_tutorial_steps() -> Array:
	var steps: Array = []
	steps.append({
		"title": "Welcome, Operator!",
		"body": "You're now in the PacketSurge network.\nThis quick tour will walk you through every module of the game.",
		"force_center": true,
	})
	if _continue_btn:
		steps.append({
			"title": "Continue Button",
			"body": "This button takes you to where you left off — your next lesson, level, or activity.",
			"highlight": _continue_btn.get_path(),
		})
	steps.append({
		"title": "Academy",
		"body": "Learn Python and data structures with interactive lessons. Unlock towers and levels as you master topics.",
		"highlight": academy_button.get_path(),
	})
	steps.append({
		"title": "Campaign",
		"body": "Defend the network with the towers you've unlocked. Each level is a Tower Defense puzzle.",
		"highlight": campaign_button.get_path(),
	})
	steps.append({
		"title": "Index",
		"body": "Browse every concept, algorithm, and tower you've encountered so far.",
		"highlight": index_button.get_path(),
	})
	if profile_card.visible:
		steps.append({
			"title": "Your Profile",
			"body": "Tap your avatar to view your profile, mastery stats, and earned achievements.",
			"highlight": profile_card.get_path(),
		})
	steps.append({
		"title": "Leaderboard",
		"body": "Track your progress against classmates on the global leaderboard.",
		"highlight": leaderboard_button.get_path(),
	})
	steps.append({
		"title": "Settings",
		"body": "Tweak audio, display, and account preferences from the settings menu.",
		"highlight": settings_button.get_path(),
	})
	steps.append({
		"title": "You're Ready!",
		"body": "Hit the Continue button above to start your training. Good luck, operator!",
		"force_center": true,
	})
	return steps
