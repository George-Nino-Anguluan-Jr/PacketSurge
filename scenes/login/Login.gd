 # Login.gd
extends Control

# ─── NODE REFERENCES ───────────────────────────────────
@onready var title_label: Label         = $CenterContainer/MainLayout/TitleSection/TitleLabel
@onready var login_tab: Button          = $CenterContainer/MainLayout/FormCard/CardLayout/TabBar/LoginTab
@onready var register_tab: Button       = $CenterContainer/MainLayout/FormCard/CardLayout/TabBar/RegisterTab
@onready var login_form: VBoxContainer  = $CenterContainer/MainLayout/FormCard/CardLayout/LoginForm
@onready var register_form: VBoxContainer = $CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm
@onready var status_label: Label        = $CenterContainer/MainLayout/StatusLabel
@onready var loading_overlay: ColorRect = $LoadingOverlay

# Login form fields
@onready var login_username_field: LineEdit = $CenterContainer/MainLayout/FormCard/CardLayout/LoginForm/LoginUsernameField
@onready var password_field: LineEdit   = $CenterContainer/MainLayout/FormCard/CardLayout/LoginForm/PasswordField
@onready var login_btn: Button          = $CenterContainer/MainLayout/FormCard/CardLayout/LoginForm/LoginBtn
@onready var forgot_label: Label        = $CenterContainer/MainLayout/FormCard/CardLayout/LoginForm/ForgotLabel

# Register form fields
@onready var first_name_field: LineEdit = $CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm/NameFieldsLayout/FirstNameField
@onready var last_name_field: LineEdit  = $CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm/NameFieldsLayout/LastNameField
@onready var username_field: LineEdit   = $CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm/UsernameField
@onready var reg_password_field: LineEdit = $CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm/RegPasswordField
@onready var confirm_field: LineEdit    = $CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm/ConfirmField
@onready var year_field: LineEdit       = $CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm/ClassFieldsLayout/YearField
@onready var section_option: OptionButton = $CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm/ClassFieldsLayout/SectionOptionButton
@onready var register_btn: Button       = $CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm/RegisterBtn

# ─── STATE ─────────────────────────────────────────────
var _time: float = 0.0
var _active_tab: String = "login"

var _final_title: String = "PACKET SURGE"
var _current_decoded_length: int = 0
var _decode_timer: float = 0.0
var _is_decoding: bool = true

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	# Apply minimal performance-friendly background shader
	var bg_material := ShaderMaterial.new()
	bg_material.shader = load("res://assets/themes/minimal_system_bg.gdshader")
	if has_node("Background"):
		$Background.material = bg_material

	# Sci-fi title outline/shadow styling
	title_label.add_theme_color_override("font_outline_color", Color("#004C66"))
	title_label.add_theme_constant_override("outline_size", 8)
	title_label.add_theme_color_override("font_shadow_color", Color("#000D1A", 0.8))
	title_label.add_theme_constant_override("shadow_offset_x", 4)
	title_label.add_theme_constant_override("shadow_offset_y", 4)

	_setup_section_options()
	_setup_buttons()
	_apply_styles()
	_show_login_tab()
	_animate_title()
	_apply_responsive_layout()
	get_tree().root.size_changed.connect(_apply_responsive_layout)

	# Listen for Supabase responses
	SupabaseManager.login_completed.connect(_on_login_completed)
	SupabaseManager.register_completed.connect(_on_register_completed)
	_connect_button_sounds(self)

func _connect_button_sounds(node: Node) -> void:
	var sfx = get_node_or_null("/root/SoundManager")
	if sfx and node is Button:
		if not node.mouse_entered.is_connected(sfx.play_hover):
			node.mouse_entered.connect(sfx.play_hover)
		if not node.pressed.is_connected(sfx.play_click):
			node.pressed.connect(sfx.play_click)
	
	for child in node.get_children():
		_connect_button_sounds(child)

# ─── SECTION OPTIONS ───────────────────────────────────
func _setup_section_options() -> void:
	section_option.add_item("Select Section")
	for letter in ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]:
		section_option.add_item(letter)
	section_option.select(0)

# ─── BUTTON SETUP ──────────────────────────────────────
func _setup_buttons() -> void:
	login_tab.pressed.connect(_show_login_tab)
	register_tab.pressed.connect(_show_register_tab)
	login_btn.pressed.connect(_on_login_pressed)
	register_btn.pressed.connect(_on_register_pressed)

	# Allow Enter key to submit
	login_username_field.text_submitted.connect(func(_t): _on_login_pressed())
	password_field.text_submitted.connect(func(_t): _on_login_pressed())

# ─── TAB SWITCHING ─────────────────────────────────────
func _show_login_tab() -> void:
	_active_tab         = "login"
	login_form.visible  = true
	register_form.visible = false
	status_label.text   = ""
	_style_active_tab(login_tab, true)
	_style_active_tab(register_tab, false)

func _show_register_tab() -> void:
	_active_tab           = "register"
	login_form.visible    = false
	register_form.visible = true
	status_label.text     = ""
	_style_active_tab(login_tab, false)
	_style_active_tab(register_tab, true)

# ─── LOGIN ─────────────────────────────────────────────
func _on_login_pressed() -> void:
	var uname    = login_username_field.text.strip_edges()
	var password = password_field.text

	if uname == "" or password == "":
		_show_status("Please fill in all fields.", false)
		return

	var email = uname.to_lower() + "@packetsurge.com"

	_show_loading(true)
	SupabaseManager.login_student(email, password)

func _on_login_completed(success: bool, message: String) -> void:
	_show_loading(false)
	if success:
		_show_status(message, true)
		# Don't navigate here — SupabaseManager navigates
		# after loading cloud progress
	else:
		_show_status(message, false)

func _on_register_completed(success: bool, message: String) -> void:
	_show_loading(false)
	if success:
		_show_status(message, true)
		# Navigation is now handled by SupabaseManager after loading progress from cloud
	else:
		_show_status(message, false)

# ─── REGISTER ──────────────────────────────────────────
func _on_register_pressed() -> void:
	var first_name = first_name_field.text.strip_edges()
	var last_name  = last_name_field.text.strip_edges()
	var uname      = username_field.text.strip_edges()
	var password   = reg_password_field.text
	var confirm    = confirm_field.text
	var year_text  = year_field.text.strip_edges()
	var sec_idx    = section_option.selected

	# Validation
	if first_name == "" or last_name == "" or uname == "" or \
	   password == "" or confirm == "":
		_show_status("Please fill in all fields.", false)
		return

	if sec_idx == 0:
		_show_status("Please select your section.", false)
		return

	var section_text = section_option.get_item_text(sec_idx)

	if uname.length() < 3:
		_show_status("Username must be at least 3 characters.", false)
		return

	if password.length() < 6:
		_show_status("Password must be at least 6 characters.", false)
		return

	if password != confirm:
		_show_status("Passwords do not match.", false)
		return

	var full_name = first_name + " " + last_name
	var email     = uname.to_lower() + "@packetsurge.com"

	_show_loading(true)
	SupabaseManager.register_student(
		full_name, uname, email, password, year_text, section_text
	)

# ─── VALIDATION ────────────────────────────────────────
func _is_valid_email(email: String) -> bool:
	return "@" in email and "." in email

# ─── UI HELPERS ────────────────────────────────────────
func _show_status(message: String, success: bool) -> void:
	status_label.text = message
	var color = Color("#00FF88") if success else Color("#FF3366")
	status_label.add_theme_color_override("font_color", color)

func _show_loading(show: bool) -> void:
	loading_overlay.visible = show
	login_btn.disabled      = show
	register_btn.disabled   = show

# ─── TITLE ANIMATION ───────────────────────────────────
func _animate_title() -> void:
	title_label.modulate.a = 0.0
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(title_label, "modulate:a", 1.0, 1.0)


# ─── STYLES ────────────────────────────────────────────
func _apply_styles() -> void:
	# Form card glass style
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
	$CenterContainer/MainLayout/FormCard.add_theme_stylebox_override(
		"panel", card_style
	)

	# Style all LineEdit fields
	for field in [
		login_username_field, password_field,
		first_name_field, last_name_field,
		username_field, reg_password_field,
		confirm_field, year_field
	]:
		_style_input_field(field)

	# Style OptionButton
	_style_option_button(section_option)

	# Style buttons
	_style_accent_button(login_btn)
	_style_accent_button(register_btn)
	_style_active_tab(login_tab, true)
	_style_active_tab(register_tab, false)

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
	field.add_theme_stylebox_override("focus",  _make_focused_style())
	field.add_theme_color_override("font_color",             Color("#E8F4FD"))
	field.add_theme_color_override("font_placeholder_color", Color("#4A7FA5"))
	field.add_theme_font_size_override("font_size", 16)

func _make_focused_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#080F1E")
	style.border_color           = Color("#00D4FF")
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
	return style

func _style_option_button(btn: OptionButton) -> void:
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
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color("#E8F4FD"))
	btn.add_theme_font_size_override("font_size", 16)

func _style_accent_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color               = Color("#00D4FF")
	normal.corner_radius_top_left     = 4
	normal.corner_radius_top_right    = 4
	normal.corner_radius_bottom_left  = 4
	normal.corner_radius_bottom_right = 4
	var hover := StyleBoxFlat.new()
	hover.bg_color                = Color("#33DDFF")
	hover.corner_radius_top_left      = 4
	hover.corner_radius_top_right     = 4
	hover.corner_radius_bottom_left   = 4
	hover.corner_radius_bottom_right  = 4
	btn.add_theme_stylebox_override("normal",  normal)
	btn.add_theme_stylebox_override("hover",   hover)
	btn.add_theme_color_override("font_color", Color("#050D1A"))
	btn.add_theme_font_size_override("font_size", 17)

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
	btn.add_theme_stylebox_override("normal",   style)
	btn.add_theme_stylebox_override("hover",    style)
	btn.add_theme_stylebox_override("pressed",  style)
	btn.add_theme_font_size_override("font_size", 16)

# ─── RESPONSIVE ────────────────────────────────────────
func _apply_responsive_layout() -> void:
	var card = $CenterContainer/MainLayout/FormCard
	var main_layout = $CenterContainer/MainLayout
	var login_form = $CenterContainer/MainLayout/FormCard/CardLayout/LoginForm
	var register_form = $CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm
	
	if ScreenManager.is_mobile():
		card.custom_minimum_size = Vector2(380, 0)
		title_label.add_theme_font_size_override("font_size", 34)
		main_layout.add_theme_constant_override("separation", 18)
		login_form.add_theme_constant_override("separation", 12)
		register_form.add_theme_constant_override("separation", 10)
		status_label.add_theme_font_size_override("font_size", 13)
	elif ScreenManager.is_tablet():
		card.custom_minimum_size = Vector2(460, 0)
		title_label.add_theme_font_size_override("font_size", 42)
		main_layout.add_theme_constant_override("separation", 22)
		login_form.add_theme_constant_override("separation", 14)
		register_form.add_theme_constant_override("separation", 12)
		status_label.add_theme_font_size_override("font_size", 14)
	else:
		card.custom_minimum_size = Vector2(520, 0)
		title_label.add_theme_font_size_override("font_size", 56)
		main_layout.add_theme_constant_override("separation", 26)
		login_form.add_theme_constant_override("separation", 14)
		register_form.add_theme_constant_override("separation", 12)
		status_label.add_theme_font_size_override("font_size", 15)
