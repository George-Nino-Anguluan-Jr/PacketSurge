# TowerCard.gd
extends PanelContainer

signal clicked(tower_id)
signal drag_started(card)
signal drag_ended(card, release_pos)
signal info_requested(tower_id)

@onready var name_label: Label = $CardLayout/NameLabel
@onready var cost_label: Label = $CardLayout/CostLabel
@onready var tower_viewport: Control = $CardLayout/TowerViewport
@onready var tower_container: Node2D = $CardLayout/TowerViewport/TowerContainer

var tower_id: String = ""
var tower_name: String = ""
var ram_cost: int = 50
var tower_color: Color = Color("#00D4FF")
var icon_text: String = "[ ]"

var is_required: bool = false
var is_selected: bool = false
var home_position: Vector2 = Vector2.ZERO
var current_slot_idx: int = -1

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var drag_start_global: Vector2 = Vector2.ZERO
var _is_hovered: bool = false
var _is_new: bool = false

var tower_instance: Node2D = null

var _info_btn: Label
var _new_badge: Label

# ─── HELPERS ───────────────────────────────────────────
func _min_dim() -> float:
	var vp := get_viewport().get_visible_rect().size
	return minf(maxf(vp.x, 320.0), maxf(vp.y, 240.0))

func _fs(ratio: float, floor_v: float, cap_v: float) -> int:
	return int(clampf(_min_dim() * ratio, floor_v, cap_v))

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pivot_offset = size / 2
	_build_info_button()
	_build_new_badge()

func _build_info_button() -> void:
	_info_btn = Label.new()
	_info_btn.text = "?"
	_info_btn.add_theme_font_size_override("font_size", _fs(0.040, 16.0, 18.0))
	_info_btn.add_theme_color_override("font_color", Color("#4A7FA5"))
	_info_btn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_btn.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_info_btn.custom_minimum_size = Vector2(_fs(0.075, 28.0, 32.0), _fs(0.075, 28.0, 32.0))
	_info_btn.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_info_btn)
	_info_btn.position = Vector2(_fs(0.008, 2.0, 4.0), _fs(0.008, 2.0, 4.0))

func _build_new_badge() -> void:
	_new_badge = Label.new()
	_new_badge.text = "NEW!"
	_new_badge.add_theme_font_size_override("font_size", _fs(0.028, 16.0, 16.0))
	_new_badge.add_theme_color_override("font_color", Color("#FFD700"))
	_new_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_new_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_new_badge.custom_minimum_size = Vector2(_fs(0.085, 36.0, 44.0), _fs(0.038, 16.0, 20.0))
	_new_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color("#FFD700", 0.2)
	bg.border_color = Color("#FFD700")
	bg.border_width_left = 1
	bg.border_width_right = 1
	bg.border_width_top = 1
	bg.border_width_bottom = 1
	bg.corner_radius_top_left = 3
	bg.corner_radius_top_right = 3
	bg.corner_radius_bottom_left = 3
	bg.corner_radius_bottom_right = 3
	_new_badge.add_theme_stylebox_override("normal", bg)
	_new_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_new_badge.offset_left = -_fs(0.094, 36.0, 48.0)
	_new_badge.offset_right = -_fs(0.008, 2.0, 4.0)
	_new_badge.offset_top = _fs(0.008, 2.0, 4.0)
	_new_badge.offset_bottom = _fs(0.045, 18.0, 24.0)
	add_child(_new_badge)

func setup(p_tower_id: String, def: Dictionary, req: bool) -> void:
	tower_id = p_tower_id
	tower_name = def["tower_name"]
	ram_cost = def.get("ram_cost", 50)
	tower_color = Color(def["color"])
	icon_text = def.get("icon_text", "[ ]")
	is_required = req

	name_label.text = tower_name.replace(" Tower", "")
	cost_label.text = str(ram_cost) + " RAM"

	# Lock card size — dynamic via _fs() — prevents stretching in any container
	var card_w = _fs(0.22, 110.0, 160.0)
	var card_h = _fs(0.27, 130.0, 180.0)
	custom_minimum_size = Vector2(card_w, card_h)
	size = Vector2(card_w, card_h)
	size_flags_horizontal = 8  # SIZE_SHRINK_END
	size_flags_vertical = 8    # SIZE_SHRINK_END
	pivot_offset = Vector2(card_w * 0.5, card_h * 0.5)

	# Resize TowerViewport to fit new card dims
	var viewport_h = _fs(0.18, 64.0, 96.0)
	tower_viewport.custom_minimum_size = Vector2(0, viewport_h)
	tower_container.position = Vector2(card_w * 0.5, viewport_h * 0.5)

	_apply_styles()
	_instantiate_tower_model(def)
	_refresh_badges()

func _instantiate_tower_model(def: Dictionary) -> void:
	if tower_instance:
		tower_instance.queue_free()
		tower_instance = null

	var data = TowerData.new()
	data.tower_id = tower_id
	data.tower_name = tower_name
	data.ram_cost = ram_cost
	data.damage = def.get("damage", 10.0)
	data.attack_speed = def.get("attack_speed", 1.0)
	data.attack_range = def.get("attack_range", 150.0)
	data.color = tower_color
	data.icon_text = icon_text

	tower_instance = TowerFactory.create_preview_tower(data)
	if tower_instance:
		tower_container.add_child(tower_instance)
		tower_instance.preview_mode = true
		tower_instance.set_process(false)
		tower_instance.set_physics_process(false)
		# Set custom scale to fit nicely in our viewport area
		tower_instance.scale = Vector2(0.65, 0.65)

func _apply_styles() -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	var c_mgn := _fs(0.018, 6.0, 8.0)
	style.content_margin_left = c_mgn
	style.content_margin_right = c_mgn
	style.content_margin_top = c_mgn
	style.content_margin_bottom = c_mgn

	# Required is no longer treated specially — all cards share the
	# same selected / unselected look.
	if is_selected:
		style.bg_color = Color(tower_color, 0.15)
		style.border_color = tower_color
		name_label.add_theme_color_override("font_color", tower_color)
		cost_label.add_theme_color_override("font_color", tower_color)
	else:
		style.bg_color = Color("#0A1628")
		style.border_color = Color("#1A3A5A")
		name_label.add_theme_color_override("font_color", Color("#A0C0E0"))
		cost_label.add_theme_color_override("font_color", Color("#4A7FA5"))

	add_theme_stylebox_override("panel", style)

func set_new(val: bool) -> void:
	_is_new = val
	_refresh_badges()

func _refresh_badges() -> void:
	if _new_badge:
		_new_badge.visible = _is_new
	if _info_btn:
		# Info button always visible now — required towers can be inspected too.
		_info_btn.visible = true

func set_selected(sel: bool) -> void:
	is_selected = sel
	_apply_styles()

func _on_mouse_entered() -> void:
	_is_hovered = true
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Slight glow border shift if not selected
	if not is_selected:
		var style = get_theme_stylebox("panel").duplicate()
		style.border_color = tower_color.lerp(Color.WHITE, 0.2)
		add_theme_stylebox_override("panel", style)

func _on_mouse_exited() -> void:
	_is_hovered = false
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_apply_styles()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _info_btn and _info_btn.get_global_rect().has_point(event.global_position):
					info_requested.emit(tower_id)
					accept_event()
					return
				is_dragging = false
				drag_start_global = global_position
				drag_offset = global_position - event.global_position
				pivot_offset = size / 2
			else:
				if is_dragging:
					is_dragging = false
					drag_ended.emit(self, event.global_position)
				else:
					clicked.emit(tower_id)
					
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		if not is_dragging:
			var dist = (global_position - drag_start_global).length()
			if dist > _fs(0.018, 6.0, 10.0): # Drag threshold
				is_dragging = true
				z_index = 100 # Put on top during drag
				drag_started.emit(self)
		
		if is_dragging:
			global_position = event.global_position + drag_offset

func animate_to(target_pos: Vector2, duration: float = 0.35) -> void:
	z_index = 50 # Fly above static UI
	var tween = create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "global_position", target_pos, duration)
	
	# Rotate slightly during the fly animation for a gorgeous arc feel!
	var target_rot = -0.15 if target_pos.x < global_position.x else 0.15
	if abs(target_pos.x - global_position.x) < 20:
		target_rot = 0.0
		
	var rot_tween = create_tween()
	rot_tween.set_ease(Tween.EASE_OUT)
	rot_tween.set_trans(Tween.TRANS_QUAD)
	rot_tween.tween_property(self, "rotation", target_rot, duration * 0.4)
	rot_tween.tween_property(self, "rotation", 0.0, duration * 0.6)
	
	await tween.finished
	z_index = 0
