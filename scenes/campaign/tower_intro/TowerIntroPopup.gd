extends Control

signal closed

var tower_id: String = ""

@onready var panel: PanelContainer = $Backdrop/Margin/Panel
@onready var icon_label: Label = $Backdrop/Margin/Panel/Content/Header/IconLabel
@onready var title_label: Label = $Backdrop/Margin/Panel/Content/Header/TitleLabel
@onready var tagline_label: Label = $Backdrop/Margin/Panel/Content/Header/TaglineLabel
@onready var mechanic_label: Label = $Backdrop/Margin/Panel/Content/Body/BodyContent/MechanicLabel
@onready var targeting_label: Label = $Backdrop/Margin/Panel/Content/Body/BodyContent/TargetingLabel
@onready var shooting_label: Label = $Backdrop/Margin/Panel/Content/Body/BodyContent/ShootingLabel
@onready var ability_label: Label = $Backdrop/Margin/Panel/Content/Body/BodyContent/AbilityLabel
@onready var strong_container: VBoxContainer = $Backdrop/Margin/Panel/Content/Body/BodyContent/StrongBox/StrongContainer
@onready var weak_container: VBoxContainer = $Backdrop/Margin/Panel/Content/Body/BodyContent/WeakBox/WeakContainer
@onready var close_btn: Button = $Backdrop/Margin/Panel/Content/Footer/CloseBtn
@onready var preview: Control = $Backdrop/Margin/Panel/Content/PreviewWrap/Preview

func _ready() -> void:
	close_btn.pressed.connect(_on_close)
	close_btn.mouse_entered.connect(_close_btn_hover)
	close_btn.mouse_exited.connect(_close_btn_unhover)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0, 0, 0, 0)
	close_btn.add_theme_stylebox_override("normal", btn_style)

	var sfx = get_node_or_null("/root/SoundManager")
	if sfx:
		close_btn.mouse_entered.connect(sfx.play_hover)
		close_btn.pressed.connect(sfx.play_click)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color("#0A1628")
	panel_style.border_color = Color("#00D4FF")
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", panel_style)

	var backdrop = $Backdrop
	backdrop.gui_input.connect(_on_backdrop_input)

func show_for(t_id: String) -> void:
	tower_id = t_id
	var data = TowerIntroData.get_intro(t_id)
	if data.is_empty():
		return

	icon_label.text = data.get("icon", "")
	title_label.text = data.get("title", t_id)
	tagline_label.text = data.get("tagline", "")

	var col: Color = data.get("color", Color("#00D4FF"))
	title_label.add_theme_color_override("font_color", col)
	tagline_label.add_theme_color_override("font_color", col)

	mechanic_label.text = "?  " + data.get("mechanic", "")
	targeting_label.text = "?  " + data.get("targeting", "")
	shooting_label.text = "?  " + data.get("shooting", "")
	ability_label.text = "?  " + data.get("ability", "")

	_populate_enemy_list(strong_container, data.get("strong", []), "Strong Against", Color("#00FF88"))
	_populate_enemy_list(weak_container, data.get("weak", []), "Weak Against", Color("#FF3366"))

	if preview and preview.has_method("setup"):
		preview.setup(t_id)

	show()
	_panel_enter()

func _populate_enemy_list(container: VBoxContainer, enemies: Array, label: String, color: Color) -> void:
	for child in container.get_children():
		child.queue_free()

	var header = Label.new()
	header.text = label
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", color)
	container.add_child(header)

	for e in enemies:
		var lbl = Label.new()
		# Convert enemy_id to display name
		var display = e.replace("_", " ").capitalize()
		lbl.text = "- " + display
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color("#C0D8E8"))
		container.add_child(lbl)

func _panel_enter() -> void:
	panel.modulate = Color(1, 1, 1, 0)
	panel.scale = Vector2(0.85, 0.85)
	var tween = create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.25)
	tween.tween_property(panel, "scale", Vector2(1, 1), 0.35)

func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_close()

func _close_btn_hover() -> void:
	var s = StyleBoxFlat.new()
	s.bg_color = Color("#00D4FF", 0.15)
	s.border_color = Color("#00D4FF")
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	close_btn.add_theme_stylebox_override("normal", s)

func _close_btn_unhover() -> void:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	close_btn.add_theme_stylebox_override("normal", s)

func _on_close() -> void:
	if preview and preview.has_method("stop"):
		preview.stop()
	var tween = create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.15)
	tween.tween_property(panel, "scale", Vector2(0.9, 0.9), 0.12)
	await tween.finished
	hide()
	panel.scale = Vector2(1, 1)
	closed.emit()
