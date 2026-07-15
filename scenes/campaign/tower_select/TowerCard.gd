# TowerCard.gd
extends PanelContainer

signal clicked(tower_id)
signal drag_started(card)
signal drag_ended(card, release_pos)

@onready var name_label: Label = $CardLayout/NameLabel
@onready var cost_label: Label = $CardLayout/CostLabel
@onready var tower_container: Node2D = $CardLayout/TowerViewport/TowerContainer

var tower_id: String = ""
var tower_name: String = ""
var ram_cost: int = 50
var tower_color: Color = Color("#00D4FF")
var icon_text: String = "[ ]"

var is_required: bool = false
var is_selected: bool = false
var home_position: Vector2 = Vector2.ZERO # The available anchor's global_pos
var current_slot_idx: int = -1 # -1 if not in a slot

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var drag_start_global: Vector2 = Vector2.ZERO
var _is_hovered: bool = false

var tower_instance: Node2D = null

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pivot_offset = size / 2

func setup(p_tower_id: String, def: Dictionary, req: bool) -> void:
	tower_id = p_tower_id
	tower_name = def["tower_name"]
	ram_cost = def.get("ram_cost", 50)
	tower_color = Color(def["color"])
	icon_text = def.get("icon_text", "[ ]")
	is_required = req
	
	name_label.text = tower_name.replace(" Tower", "")
	cost_label.text = str(ram_cost) + " RAM"
	if is_required:
		cost_label.text = "🔒 REQUIRED"
	
	_apply_styles()
	_instantiate_tower_model(def)

func _instantiate_tower_model(def: Dictionary) -> void:
	if tower_instance:
		tower_instance.queue_free()
		tower_instance = null
		
	var tower_scene = load("res://scenes/campaign/towers/Tower.tscn")
	if tower_scene:
		tower_instance = tower_scene.instantiate()
		tower_container.add_child(tower_instance)
		
		var data = TowerData.new()
		data.tower_id = tower_id
		data.tower_name = tower_name
		data.ram_cost = ram_cost
		data.damage = def.get("damage", 10.0)
		data.attack_speed = def.get("attack_speed", 1.0)
		data.attack_range = def.get("attack_range", 150.0)
		data.color = tower_color
		data.icon_text = icon_text
		
		# Initialize without cell and enemy layer
		tower_instance.initialize(data, Vector2i.ZERO, null)
		
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
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	
	if is_required:
		style.bg_color = Color(tower_color, 0.2)
		style.border_color = tower_color
		name_label.add_theme_color_override("font_color", tower_color)
		cost_label.add_theme_color_override("font_color", tower_color)
	elif is_selected:
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

func set_selected(sel: bool) -> void:
	is_selected = sel
	_apply_styles()

func _on_mouse_entered() -> void:
	if is_required:
		return
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
	if is_required:
		return # Required towers are locked
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start potential drag
				is_dragging = false
				drag_start_global = global_position
				drag_offset = global_position - event.global_position
				pivot_offset = size / 2
			else:
				if is_dragging:
					is_dragging = false
					drag_ended.emit(self, event.global_position)
				else:
					# Just a click!
					clicked.emit(tower_id)
					
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		if not is_dragging:
			var dist = (global_position - drag_start_global).length()
			if dist > 8: # Drag threshold
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
