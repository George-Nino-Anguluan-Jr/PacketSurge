 # Login.gd
extends Control

# ─── NODE REFERENCES ───────────────────────────────────
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var title_label: Label         = $ScrollContainer/CenterContainer/MainLayout/TitleSection/TitleLabel
@onready var login_tab: Button          = $ScrollContainer/CenterContainer/MainLayout/FormCard/CardLayout/TabBar/LoginTab
@onready var register_tab: Button       = $ScrollContainer/CenterContainer/MainLayout/FormCard/CardLayout/TabBar/RegisterTab
@onready var login_form: VBoxContainer  = $ScrollContainer/CenterContainer/MainLayout/FormCard/CardLayout/LoginForm
@onready var register_form: VBoxContainer = $ScrollContainer/CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm
@onready var status_label: Label        = $ScrollContainer/CenterContainer/MainLayout/StatusLabel
@onready var loading_overlay: ColorRect = $LoadingOverlay
@onready var loading_label: Label       = $LoadingOverlay/LoadingLabel

# Login form fields
@onready var login_username_field: LineEdit = $ScrollContainer/CenterContainer/MainLayout/FormCard/CardLayout/LoginForm/LoginUsernameField
@onready var password_field: LineEdit   = $ScrollContainer/CenterContainer/MainLayout/FormCard/CardLayout/LoginForm/PasswordField
@onready var login_btn: Button          = $ScrollContainer/CenterContainer/MainLayout/FormCard/CardLayout/LoginForm/LoginBtn
@onready var forgot_btn: Button         = $ScrollContainer/CenterContainer/MainLayout/FormCard/CardLayout/LoginForm/ForgotBtn
# Register form fields
@onready var first_name_field: LineEdit = $ScrollContainer/CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm/NameFieldsLayout/FirstNameField
@onready var last_name_field: LineEdit  = $ScrollContainer/CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm/NameFieldsLayout/LastNameField
@onready var username_field: LineEdit   = $ScrollContainer/CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm/UsernameField
@onready var email_field: LineEdit      = $ScrollContainer/CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm/EmailField
@onready var reg_password_field: LineEdit = $ScrollContainer/CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm/RegPasswordField
@onready var confirm_field: LineEdit    = $ScrollContainer/CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm/ConfirmField
@onready var year_field: LineEdit       = $ScrollContainer/CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm/ClassFieldsLayout/YearField
@onready var section_option: OptionButton = $ScrollContainer/CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm/ClassFieldsLayout/SectionOptionButton
@onready var register_btn: Button       = $ScrollContainer/CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm/RegisterBtn

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
	ScreenManager.make_scroll_touch_friendly(scroll_container)

	# Listen for Supabase responses
	SupabaseManager.login_completed.connect(_on_login_completed)
	SupabaseManager.register_completed.connect(_on_register_completed)
	SupabaseManager.reset_completed.connect(_on_reset_completed)
	SupabaseManager.otp_verified.connect(_on_otp_verified)
	SupabaseManager.password_set_completed.connect(_on_password_set_completed)
	SupabaseManager.signup_verified.connect(_on_signup_verified)
	SupabaseManager.session_restore_failed.connect(_on_session_restore_failed)
	_connect_button_sounds(self)

	# If a session was saved last time, skip the login form entirely.
	if SupabaseManager.restore_session():
		_show_loading(true)
		loading_label.text = "Restoring session..."

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
	forgot_btn.pressed.connect(_on_forgot_pressed)

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
	var identifier = login_username_field.text.strip_edges()
	var password   = password_field.text

	if identifier == "" or password == "":
		_show_status("Please fill in all fields.", false)
		return

	_show_loading(true)
	if _is_valid_email(identifier):
		# User entered an email address directly
		SupabaseManager.login_student(identifier.to_lower(), password)
	else:
		# User entered a username — resolve it to an email first
		SupabaseManager.login_with_username(identifier, password)

func _on_login_completed(success: bool, message: String) -> void:
	_show_loading(false)
	if success:
		_show_status(message, true)
		# Don't navigate here — SupabaseManager navigates
		# after loading cloud progress
	elif message == "Please verify your email before logging in.":
		var identifier = login_username_field.text.strip_edges()
		if _is_valid_email(identifier):
			# Unconfirmed account — let them enter the code in-game.
			_show_confirm_dialog(identifier.to_lower())
		else:
			_show_status(message, false)
	else:
		_show_status(message, false)

func _on_register_completed(success: bool, message: String) -> void:
	_show_loading(false)
	if success:
		if SupabaseManager.awaiting_email_confirmation:
			# Email confirmation is enabled — show the in-game code entry
			# so the user confirms without touching a browser.
			_show_confirm_dialog(email_field.text.strip_edges().to_lower())
		else:
			_show_status(message, true)
	else:
		_show_status(message, false)

func _on_forgot_pressed() -> void:
	_show_reset_dialog()

func _on_reset_completed(success: bool, message: String) -> void:
	_show_loading(false)
	if _reset_dialog and _reset_dialog.visible:
		if success:
			_go_to_reset_step(1)
		else:
			_reset_error_label.text = message
			_reset_error_label.add_theme_color_override("font_color", Color("#FF3366"))
	else:
		_show_status(message, success)

func _on_otp_verified(success: bool, session_token: String) -> void:
	_show_loading(false)
	if _reset_dialog and _reset_dialog.visible:
		if success:
			_reset_session_token = session_token
			_go_to_reset_step(2)
		else:
			# On failure the second arg carries the error message.
			_reset_error_label.text = session_token
			_reset_error_label.add_theme_color_override("font_color", Color("#FF3366"))

# ─── FORGOT PASSWORD DIALOG (OTP WIZARD) ────────────────
# Step 0: email → Step 1: 6-digit code → Step 2: new password.
var _reset_dialog: Control = null
var _reset_step: int = 0
var _reset_email: String = ""
var _reset_session_token: String = ""
var _reset_title_label: Label = null
var _reset_desc_label: Label = null
var _reset_email_field: LineEdit = null
var _reset_code_field: LineEdit = null
var _reset_password_field: LineEdit = null
var _reset_confirm_field: LineEdit = null
var _reset_error_label: Label = null
var _reset_submit_btn: Button = null
var _reset_back_btn: Button = null

func _show_reset_dialog() -> void:
	if _reset_dialog == null:
		_build_reset_dialog()
	_reset_step = 0
	_reset_email = ""
	_reset_session_token = ""
	_reset_email_field.text = ""
	_reset_code_field.text = ""
	_reset_password_field.text = ""
	_reset_confirm_field.text = ""
	_reset_error_label.text = ""
	_reset_dialog.visible = true
	_apply_reset_step()
	_reset_email_field.grab_focus()

func _hide_reset_dialog() -> void:
	if _reset_dialog:
		_reset_dialog.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _reset_dialog and _reset_dialog.visible:
			_hide_reset_dialog()
			get_viewport().set_input_as_handled()
		elif _confirm_dialog and _confirm_dialog.visible:
			_hide_confirm_dialog()
			get_viewport().set_input_as_handled()

func _build_reset_dialog() -> void:
	# Full-screen dim + centered card
	var dim := ColorRect.new()
	dim.color = Color("#050D1A", 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.visible = false
	_reset_dialog = dim
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(_fs(0.42, 320.0, 520.0), 0)
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
	card_style.content_margin_left   = 24
	card_style.content_margin_right  = 24
	card_style.content_margin_top    = 20
	card_style.content_margin_bottom = 20
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	card.add_child(layout)

	_reset_title_label = Label.new()
	_reset_title_label.text = "RESET PASSWORD"
	_reset_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reset_title_label.add_theme_font_size_override("font_size", _fs(0.048, 18.0, 22.0))
	_reset_title_label.add_theme_color_override("font_color", Color("#00D4FF"))
	layout.add_child(_reset_title_label)

	_reset_desc_label = Label.new()
	_reset_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reset_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reset_desc_label.add_theme_font_size_override("font_size", _fs(0.032, 13.0, 16.0))
	_reset_desc_label.add_theme_color_override("font_color", Color("#4A7FA5"))
	layout.add_child(_reset_desc_label)

	_reset_email_field = LineEdit.new()
	_reset_email_field.placeholder_text = "Email"
	_reset_email_field.custom_minimum_size = Vector2(0, 44)
	_style_input_field(_reset_email_field)
	_reset_email_field.text_submitted.connect(func(_t): _submit_reset_step())
	layout.add_child(_reset_email_field)

	_reset_code_field = LineEdit.new()
	_reset_code_field.placeholder_text = "Verification code"
	_reset_code_field.custom_minimum_size = Vector2(0, 44)
	_reset_code_field.max_length = 10
	_style_input_field(_reset_code_field)
	_reset_code_field.text_submitted.connect(func(_t): _submit_reset_step())
	layout.add_child(_reset_code_field)

	_reset_password_field = LineEdit.new()
	_reset_password_field.placeholder_text = "New Password"
	_reset_password_field.secret = true
	_reset_password_field.custom_minimum_size = Vector2(0, 44)
	_style_input_field(_reset_password_field)
	layout.add_child(_reset_password_field)

	_reset_confirm_field = LineEdit.new()
	_reset_confirm_field.placeholder_text = "Confirm New Password"
	_reset_confirm_field.secret = true
	_reset_confirm_field.custom_minimum_size = Vector2(0, 44)
	_style_input_field(_reset_confirm_field)
	_reset_confirm_field.text_submitted.connect(func(_t): _submit_reset_step())
	layout.add_child(_reset_confirm_field)

	_reset_error_label = Label.new()
	_reset_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reset_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reset_error_label.add_theme_font_size_override("font_size", _fs(0.032, 13.0, 16.0))
	layout.add_child(_reset_error_label)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	layout.add_child(btns)

	_reset_back_btn = Button.new()
	_reset_back_btn.text = "BACK"
	_reset_back_btn.custom_minimum_size = Vector2(0, 46)
	_reset_back_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_ghost_button(_reset_back_btn)
	_reset_back_btn.pressed.connect(_go_back_reset_step)
	btns.add_child(_reset_back_btn)

	_reset_submit_btn = Button.new()
	_reset_submit_btn.text = "SEND CODE"
	_reset_submit_btn.custom_minimum_size = Vector2(0, 46)
	_reset_submit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_accent_button(_reset_submit_btn)
	_reset_submit_btn.pressed.connect(_submit_reset_step)
	btns.add_child(_reset_submit_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "CANCEL"
	cancel_btn.custom_minimum_size = Vector2(0, 46)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_ghost_button(cancel_btn)
	cancel_btn.pressed.connect(_hide_reset_dialog)
	btns.add_child(cancel_btn)

	var sfx = get_node_or_null("/root/SoundManager")
	if sfx:
		for b in [_reset_submit_btn, _reset_back_btn, cancel_btn]:
			b.mouse_entered.connect(sfx.play_hover)
			b.pressed.connect(sfx.play_click)

func _go_to_reset_step(step: int) -> void:
	_reset_step = step
	_apply_reset_step()

func _apply_reset_step() -> void:
	_reset_email_field.visible    = _reset_step == 0
	_reset_code_field.visible     = _reset_step == 1
	_reset_password_field.visible = _reset_step == 2
	_reset_confirm_field.visible  = _reset_step == 2
	_reset_back_btn.visible       = _reset_step > 0
	_reset_error_label.text       = ""
	match _reset_step:
		0:
			_reset_title_label.text = "RESET PASSWORD"
			_reset_desc_label.text  = "Enter your email. If it's registered, we'll send a code."
			_reset_submit_btn.text  = "SEND CODE"
			_reset_email_field.grab_focus()
		1:
			_reset_title_label.text = "ENTER CODE"
			_reset_desc_label.text  = "Enter the code we emailed to " + _reset_email
			_reset_submit_btn.text  = "VERIFY CODE"
			_reset_code_field.grab_focus()
		2:
			_reset_title_label.text = "NEW PASSWORD"
			_reset_desc_label.text  = "Choose a new password."
			_reset_submit_btn.text  = "SET PASSWORD"
			_reset_password_field.grab_focus()

func _go_back_reset_step() -> void:
	if _reset_step > 0:
		_go_to_reset_step(_reset_step - 1)

func _submit_reset_step() -> void:
	if _reset_step == 0:
		var email = _reset_email_field.text.strip_edges()
		if not _is_valid_email(email):
			_reset_error_label.text = "Please enter a valid email address."
			_reset_error_label.add_theme_color_override("font_color", Color("#FF3366"))
			return
		_reset_email = email.to_lower()
		_reset_error_label.text = ""
		_show_loading(true)
		SupabaseManager.reset_password(_reset_email)
	elif _reset_step == 1:
		var code = _reset_code_field.text.strip_edges()
		if not code.is_valid_int() or code.length() < 6 or code.length() > 10:
			_reset_error_label.text = "Enter the code from your email."
			_reset_error_label.add_theme_color_override("font_color", Color("#FF3366"))
			return
		_reset_error_label.text = ""
		_show_loading(true)
		SupabaseManager.verify_reset_otp(_reset_email, code)
	elif _reset_step == 2:
		var password = _reset_password_field.text
		var confirm  = _reset_confirm_field.text
		if password.length() < 6:
			_reset_error_label.text = "Password must be at least 6 characters."
			_reset_error_label.add_theme_color_override("font_color", Color("#FF3366"))
			return
		if password != confirm:
			_reset_error_label.text = "Passwords do not match."
			_reset_error_label.add_theme_color_override("font_color", Color("#FF3366"))
			return
		_reset_error_label.text = ""
		_show_loading(true)
		SupabaseManager.set_new_password(_reset_session_token, password)

func _on_password_set_completed(success: bool, message: String) -> void:
	_show_loading(false)
	if _reset_dialog and _reset_dialog.visible:
		if success:
			_hide_reset_dialog()
			_show_status(message, true)
			_show_login_tab()
		else:
			_reset_error_label.text = message
			_reset_error_label.add_theme_color_override("font_color", Color("#FF3366"))
	else:
		_show_status(message, success)

# ─── CONFIRM EMAIL DIALOG (signup code) ────────────────
var _confirm_dialog: Control = null
var _confirm_code_field: LineEdit = null
var _confirm_error_label: Label = null
var _confirm_email: String = ""

func _show_confirm_dialog(email: String) -> void:
	if _confirm_dialog == null:
		_build_confirm_dialog()
	_confirm_email = email
	_confirm_code_field.text = ""
	_confirm_error_label.text = ""
	_confirm_dialog.visible = true
	_confirm_code_field.grab_focus()

func _hide_confirm_dialog() -> void:
	if _confirm_dialog:
		_confirm_dialog.visible = false

func _build_confirm_dialog() -> void:
	var dim := ColorRect.new()
	dim.color = Color("#050D1A", 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.visible = false
	_confirm_dialog = dim
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(_fs(0.42, 320.0, 520.0), 0)
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
	card_style.content_margin_left   = 24
	card_style.content_margin_right  = 24
	card_style.content_margin_top    = 20
	card_style.content_margin_bottom = 20
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	card.add_child(layout)

	var title := Label.new()
	title.text = "CONFIRM EMAIL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", _fs(0.048, 18.0, 22.0))
	title.add_theme_color_override("font_color", Color("#00D4FF"))
	layout.add_child(title)

	var desc := Label.new()
	desc.text = "Enter the 6-digit code we emailed you to confirm your account."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", _fs(0.032, 13.0, 16.0))
	desc.add_theme_color_override("font_color", Color("#4A7FA5"))
	layout.add_child(desc)

	_confirm_code_field = LineEdit.new()
	_confirm_code_field.placeholder_text = "Verification code"
	_confirm_code_field.custom_minimum_size = Vector2(0, 44)
	_confirm_code_field.max_length = 10
	_style_input_field(_confirm_code_field)
	_confirm_code_field.text_submitted.connect(func(_t): _submit_confirm_code())
	layout.add_child(_confirm_code_field)

	_confirm_error_label = Label.new()
	_confirm_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_error_label.add_theme_font_size_override("font_size", _fs(0.032, 13.0, 16.0))
	layout.add_child(_confirm_error_label)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	layout.add_child(btns)

	var verify_btn := Button.new()
	verify_btn.text = "CONFIRM"
	verify_btn.custom_minimum_size = Vector2(0, 46)
	verify_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_accent_button(verify_btn)
	verify_btn.pressed.connect(_submit_confirm_code)
	btns.add_child(verify_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "CANCEL"
	cancel_btn.custom_minimum_size = Vector2(0, 46)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_ghost_button(cancel_btn)
	cancel_btn.pressed.connect(_hide_confirm_dialog)
	btns.add_child(cancel_btn)

	var sfx = get_node_or_null("/root/SoundManager")
	if sfx:
		for b in [verify_btn, cancel_btn]:
			b.mouse_entered.connect(sfx.play_hover)
			b.pressed.connect(sfx.play_click)

func _submit_confirm_code() -> void:
	var code = _confirm_code_field.text.strip_edges()
	if not code.is_valid_int() or code.length() < 6 or code.length() > 10:
		_confirm_error_label.text = "Enter the code from your email."
		_confirm_error_label.add_theme_color_override("font_color", Color("#FF3366"))
		return
	_confirm_error_label.text = ""
	_show_loading(true)
	SupabaseManager.verify_signup(code, _confirm_email)

func _on_signup_verified(success: bool, message: String) -> void:
	_show_loading(false)
	if _confirm_dialog and _confirm_dialog.visible:
		if success:
			_hide_confirm_dialog()
			_show_status(message, true)
			_show_login_tab()
		else:
			_confirm_error_label.text = message
			_confirm_error_label.add_theme_color_override("font_color", Color("#FF3366"))
	else:
		_show_status(message, success)

# ─── REGISTER ──────────────────────────────────────────
func _on_register_pressed() -> void:
	var first_name = first_name_field.text.strip_edges()
	var last_name  = last_name_field.text.strip_edges()
	var uname      = username_field.text.strip_edges()
	var email      = email_field.text.strip_edges()
	var password   = reg_password_field.text
	var confirm    = confirm_field.text
	var year_text  = year_field.text.strip_edges()
	var sec_idx    = section_option.selected

	# Validation
	if first_name == "" or last_name == "" or uname == "" or email == "" or \
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

	if not _is_valid_email(email):
		_show_status("Please enter a valid email address.", false)
		return

	if password.length() < 6:
		_show_status("Password must be at least 6 characters.", false)
		return

	if password != confirm:
		_show_status("Passwords do not match.", false)
		return

	var full_name = first_name + " " + last_name

	_show_loading(true)
	SupabaseManager.register_student(
		full_name, uname, email.to_lower(), password, year_text, section_text
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
	if show:
		# Dialog windows are added at runtime and end up above the
		# LoadingOverlay in draw order, so pull the overlay to the front
		# to keep "Connecting..." visible on top of any dialog.
		loading_overlay.move_to_front()
	else:
		loading_label.text = "Connecting..."
	login_btn.disabled      = show
	register_btn.disabled   = show
	forgot_btn.disabled     = show

func _on_session_restore_failed(message: String) -> void:
	_show_loading(false)
	_show_status(message, false)

# ─── TITLE ANIMATION ───────────────────────────────────
func _animate_title() -> void:
	title_label.modulate.a = 0.0
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(title_label, "modulate:a", 1.0, 1.0)


# ─── STYLES ────────────────────────────────────────────
func _min_dim() -> float:
	var vp := get_viewport().get_visible_rect().size
	return minf(maxf(vp.x, 320.0), maxf(vp.y, 240.0))

func _fs(ratio: float, floor_v: float, cap_v: float) -> int:
	return int(clampf(_min_dim() * ratio, floor_v, cap_v))
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
	$ScrollContainer/CenterContainer/MainLayout/FormCard.add_theme_stylebox_override(
		"panel", card_style
	)

	# Style all LineEdit fields
	for field in [
		login_username_field, password_field,
		first_name_field, last_name_field,
		username_field, email_field, reg_password_field,
		confirm_field, year_field
	]:
		_style_input_field(field)

	# Style OptionButton
	_style_option_button(section_option)

	# Style buttons
	_style_accent_button(login_btn)
	_style_accent_button(register_btn)
	_style_ghost_button(forgot_btn)
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
	field.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 20.0))

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
	btn.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 20.0))

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
	btn.add_theme_font_size_override("font_size", _fs(0.048, 17.0, 20.0))

func _style_ghost_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color          = Color(0, 0, 0, 0)
	normal.border_color      = Color("#1A3A5A")
	normal.border_width_left   = 1
	normal.border_width_right  = 1
	normal.border_width_top    = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left     = 4
	normal.corner_radius_top_right    = 4
	normal.corner_radius_bottom_left  = 4
	normal.corner_radius_bottom_right = 4
	var hover := StyleBoxFlat.new()
	hover.bg_color           = Color("#00D4FF", 0.1)
	hover.border_color       = Color("#00D4FF")
	hover.border_width_left   = 1
	hover.border_width_right  = 1
	hover.border_width_top    = 1
	hover.border_width_bottom = 1
	hover.corner_radius_top_left     = 4
	hover.corner_radius_top_right    = 4
	hover.corner_radius_bottom_left  = 4
	hover.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover",  hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_color", Color("#4A7FA5"))
	btn.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 18.0))

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
	btn.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 20.0))

# ─── RESPONSIVE ────────────────────────────────────────
func _apply_responsive_layout() -> void:
	var card = $ScrollContainer/CenterContainer/MainLayout/FormCard
	var main_layout = $ScrollContainer/CenterContainer/MainLayout
	var login_form = $ScrollContainer/CenterContainer/MainLayout/FormCard/CardLayout/LoginForm
	var register_form = $ScrollContainer/CenterContainer/MainLayout/FormCard/CardLayout/RegisterForm

	# Canvas size in design coordinates (works under stretch mode + expand).
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var w := maxf(vp.x, 320.0)
	var h := maxf(vp.y, 240.0)
	var min_dim := minf(w, h)

	# Fluid card width — grows with the screen but never overflows it.
	# The ScrollContainer handles vertical overflow, so nothing gets cut off.
	var card_w := clampf(w * 0.42, 360.0, 560.0)
	card_w = minf(card_w, w - 40.0)
	card.custom_minimum_size = Vector2(maxf(card_w, 280.0), 0)
	title_label.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.050, 36.0, 56.0)))
	main_layout.add_theme_constant_override("separation", clampf(min_dim * 0.024, 18.0, 26.0))
	login_form.add_theme_constant_override("separation", clampf(min_dim * 0.013, 12.0, 16.0))
	register_form.add_theme_constant_override("separation", clampf(min_dim * 0.011, 10.0, 14.0))
	status_label.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.018, 16.0, 18.0)))

	# Fluid input heights so fields stay tappable on touch devices
	var field_h := clampf(h * 0.068, 40.0, 48.0)
	var btn_h := clampf(h * 0.075, 44.0, 52.0)
	for field in [
		login_username_field, password_field,
		first_name_field, last_name_field,
		username_field, email_field, reg_password_field,
		confirm_field, year_field
	]:
		field.custom_minimum_size.y = field_h
	login_btn.custom_minimum_size.y = btn_h
	register_btn.custom_minimum_size.y = btn_h

	# Keep dialog cards sized correctly after viewport changes.
	_apply_dialog_responsive()

func _apply_dialog_responsive() -> void:
	if _reset_dialog and _reset_dialog.visible:
		var cards := _reset_dialog.find_children("*", "PanelContainer", true, false)
		for c in cards:
			if c is PanelContainer:
				c.custom_minimum_size.x = clampf(_min_dim() * 0.42, 320.0, 520.0)
	if _confirm_dialog and _confirm_dialog.visible:
		var cards := _confirm_dialog.find_children("*", "PanelContainer", true, false)
		for c in cards:
			if c is PanelContainer:
				c.custom_minimum_size.x = clampf(_min_dim() * 0.42, 320.0, 520.0)
