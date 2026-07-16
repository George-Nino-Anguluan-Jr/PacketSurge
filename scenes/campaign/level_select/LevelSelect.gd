# LevelSelect.gd
extends Control

@onready var back_btn: Button         = $TopBar/TopBarLayout/BackBtn
@onready var ram_label: Label         = $TopBar/TopBarLayout/RAMLabel
@onready var map_scroll: ScrollContainer = %MapScroll
@onready var map_canvas: Control      = %MapCanvas
@onready var locked_label: Label      = $ContentArea/MainLayout/LockedLabel

# Level definitions
const LEVEL_INFO = [
	{"number": 1,  "name": "Initialization",    "ds": "Arrays",       "waves": 3},
	{"number": 2,  "name": "Stack Overflow",     "ds": "Stacks",       "waves": 4},
	{"number": 3,  "name": "Queue Protocol",     "ds": "Queues",       "waves": 4},
	{"number": 4,  "name": "Linked Assault",     "ds": "Linked Lists", "waves": 5},
	{"number": 5,  "name": "Bubble Protocol",    "ds": "Bubble Sort",  "waves": 5},
	{"number": 6,  "name": "Selection Strike",   "ds": "Select Sort",  "waves": 5},
	{"number": 7,  "name": "Stack Defense",      "ds": "Insert Sort",  "waves": 6},
	{"number": 8,  "name": "Quick Strike",       "ds": "Quick Sort",   "waves": 6},
	{"number": 9,  "name": "Merge Protocol",     "ds": "Merge Sort",   "waves": 6},
	{"number": 10, "name": "Count Down",         "ds": "Counting Sort","waves": 7},
	{"number": 11, "name": "Radix Rush",         "ds": "Radix Sort",   "waves": 7},
	{"number": 12, "name": "Linear Sweep",       "ds": "Linear Search","waves": 7},
	{"number": 13, "name": "Binary Endgame",     "ds": "Binary Search","waves": 8},
]

# Visual zig-zag coordinates for our nodes on the 2100px wide canvas
const LEVEL_POSITIONS = {
	1: Vector2(100, 180),
	2: Vector2(250, 90),
	3: Vector2(400, 240),
	4: Vector2(550, 140),
	5: Vector2(700, 240),
	6: Vector2(850, 90),
	7: Vector2(1000, 180),
	8: Vector2(1150, 90),
	9: Vector2(1300, 240),
	10: Vector2(1450, 140),
	11: Vector2(1600, 240),
	12: Vector2(1750, 90),
	13: Vector2(1900, 180),
}

var tooltip_panel: PanelContainer = null
var active_nodes: Array = []

func _ready() -> void:
	_setup_buttons()
	_apply_styles()
	
	# Connect procedural map drawing
	map_canvas.draw.connect(_on_map_canvas_draw)
	
	# Build the node map layout
	_build_level_nodes()
	
	SignalBus.campaign_level_unlocked.connect(_on_level_unlocked)
	
	# Create hover tooltip card at screen level (so it doesn't get clipped by scrolling)
	_setup_floating_tooltip()
	
	# Smoothly auto-scroll to center on current/unlocked progress
	await get_tree().process_frame
	_auto_scroll_to_current()

func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	_style_back_btn()

func _on_back_pressed() -> void:
	GameManager.go_to("main_menu")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to("main_menu")

# ─── AUTO SCROLL TO CURRENT PROGRESS ───────────────────
func _auto_scroll_to_current() -> void:
	var highest_unlocked := 1
	for info in LEVEL_INFO:
		var lvl = info["number"]
		if ProgressManager.is_level_unlocked(lvl):
			highest_unlocked = lvl
			
	var target_pos = LEVEL_POSITIONS[highest_unlocked]
	# Center the scrollbar around target pos
	var center_offset = target_pos.x - (size.x / 2.0)
	center_offset = clamp(center_offset, 0.0, map_canvas.custom_minimum_size.x - size.x)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(map_scroll, "h_scroll", int(center_offset), 0.8)

# ─── floating tooltip CARD setup ───────────────────────
func _setup_floating_tooltip() -> void:
	tooltip_panel = PanelContainer.new()
	tooltip_panel.custom_minimum_size = Vector2(200, 100)
	tooltip_panel.modulate.a = 0.0
	tooltip_panel.scale = Vector2(0.8, 0.8)
	tooltip_panel.pivot_offset = Vector2(100, 50)
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tooltip_panel)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0A1628", 0.95)
	style.border_color = Color("#00D4FF")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 8
	tooltip_panel.add_theme_stylebox_override("panel", style)
	
	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override("separation", 2)
	tooltip_panel.add_child(layout)
	
	var title := Label.new()
	title.name = "Title"
	title.text = "Level Info"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color.WHITE)
	layout.add_child(title)
	
	var ds := Label.new()
	ds.name = "DS"
	ds.text = "Arrays"
	ds.add_theme_font_size_override("font_size", 11)
	ds.add_theme_color_override("font_color", Color("#00D4FF"))
	layout.add_child(ds)
	
	var stats := Label.new()
	stats.name = "Stats"
	stats.text = "Waves: 3"
	stats.add_theme_font_size_override("font_size", 11)
	stats.add_theme_color_override("font_color", Color("#4A7FA5"))
	layout.add_child(stats)

func _show_tooltip(global_pos: Vector2, info: Dictionary, is_unlocked: bool, is_completed: bool) -> void:
	var layout = tooltip_panel.get_node("Layout")
	var title = layout.get_node("Title")
	var ds = layout.get_node("DS")
	var stats = layout.get_node("Stats")
	
	if is_unlocked:
		title.text = info["name"]
		ds.text = "Structure: " + info["ds"]
		stats.text = str(info["waves"]) + " Waves" + (" (Completed)" if is_completed else "")
		tooltip_panel.get_theme_stylebox("panel").border_color = Color("#00FF88") if is_completed else Color("#00D4FF")
		ds.add_theme_color_override("font_color", Color("#00FF88") if is_completed else Color("#00D4FF"))
	else:
		title.text = "Locked System"
		ds.text = "Requires earlier systems"
		stats.text = "Unlock progress in Academy"
		tooltip_panel.get_theme_stylebox("panel").border_color = Color("#2A3A4A")
		ds.add_theme_color_override("font_color", Color("#2A3A4A"))
		
	# Adjust tooltip screen position above hovered node
	tooltip_panel.global_position = global_pos - Vector2(100, 110)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(tooltip_panel, "modulate:a", 1.0, 0.15)
	tween.tween_property(tooltip_panel, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK)

func _hide_tooltip() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(tooltip_panel, "modulate:a", 0.0, 0.1)
	tween.tween_property(tooltip_panel, "scale", Vector2(0.8, 0.8), 0.1)

# ─── BUILD LEVEL NODES ──────────────────────────────────
func _build_level_nodes() -> void:
	for child in map_canvas.get_children():
		child.queue_free()
	active_nodes.clear()
	
	var unlocked_count := 0
	
	for info in LEVEL_INFO:
		var level_num = info["number"]
		var is_unlocked = ProgressManager.is_level_unlocked(level_num)
		var is_completed = ProgressManager.campaign_progress.get("waves_completed", 0) >= level_num
		
		if is_unlocked:
			unlocked_count += 1
			
		var node_pos = LEVEL_POSITIONS[level_num]
		var node_btn = _create_node_button(info, is_unlocked, is_completed, node_pos)
		map_canvas.add_child(node_btn)
		active_nodes.append(node_btn)
		
	ram_label.text = str(unlocked_count) + " / 13 Unlocked"
	locked_label.visible = unlocked_count < 13
	map_canvas.queue_redraw()

func _create_node_button(info: Dictionary, is_unlocked: bool, is_completed: bool, pos: Vector2) -> Button:
	var btn := Button.new()
	# Compact circular size
	btn.custom_minimum_size = Vector2(56, 56)
	btn.size = Vector2(56, 56)
	btn.pivot_offset = Vector2(28, 28)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if is_unlocked else Control.CURSOR_ARROW
	
	# Center position on target vector coordinate
	btn.position = pos - Vector2(28, 28)
	
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 99
	style.corner_radius_top_right = 99
	style.corner_radius_bottom_left = 99
	style.corner_radius_bottom_right = 99
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	
	# Styling themes based on complete/unlock progress
	if is_completed:
		style.bg_color = Color("#0D2A1A")
		style.border_color = Color("#00FF88")
		btn.text = "✓"
		btn.add_theme_color_override("font_color", Color("#00FF88"))
	elif is_unlocked:
		style.bg_color = Color("#0D2040")
		style.border_color = Color("#00D4FF")
		btn.text = str(info["number"])
		btn.add_theme_color_override("font_color", Color("#00D4FF"))
	else:
		style.bg_color = Color("#0A1628")
		style.border_color = Color("#1A2D3D")
		btn.text = "🔒"
		btn.add_theme_color_override("font_color", Color("#1A2D3D"))
		
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_font_size_override("font_size", 14)
	
	# Hover and click logic
	if is_unlocked:
		btn.pressed.connect(_on_level_selected.bind(info["number"]))
		
	btn.mouse_entered.connect(func():
		_show_tooltip(btn.global_position, info, is_unlocked, is_completed)
		var t = create_tween()
		t.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if is_unlocked:
			var s_dup = style.duplicate()
			s_dup.border_color = Color.WHITE
			btn.add_theme_stylebox_override("normal", s_dup)
	)
	
	btn.mouse_exited.connect(func():
		_hide_tooltip()
		var t = create_tween()
		t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		btn.add_theme_stylebox_override("normal", style)
	)
	
	return btn

# ─── PROCEDURAL LINKING DRAW LOGIC ─────────────────────
func _on_map_canvas_draw() -> void:
	for i in range(1, 13):
		var pos_a = LEVEL_POSITIONS[i]
		var pos_b = LEVEL_POSITIONS[i + 1]
		
		var unlocked_b = ProgressManager.is_level_unlocked(i + 1)
		var completed_b = ProgressManager.campaign_progress.get("waves_completed", 0) >= (i + 1)
		
		if completed_b:
			# Fully completed neon connection
			map_canvas.draw_line(pos_a, pos_b, Color("#00FF88"), 4.0)
		elif unlocked_b:
			# Unlocked path connection
			map_canvas.draw_line(pos_a, pos_b, Color("#00D4FF"), 4.0)
		else:
			# Dim dashed locked line
			_draw_dashed_line(pos_a, pos_b, Color("#1A2D3D"), 2.0, 8.0)

func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float, dash_len: float) -> void:
	var dir = (to - from).normalized()
	var dist = (to - from).length()
	var curr = 0.0
	var draw_seg = true
	
	while curr < dist:
		var step = min(dash_len, dist - curr)
		if draw_seg:
			map_canvas.draw_line(from + dir * curr, from + dir * (curr + step), color, width)
		curr += step
		draw_seg = !draw_seg

# ─── LEVEL SELECTED ────────────────────────────────────
func _on_level_selected(level_number: int) -> void:
	GameManager.current_level = level_number
	GameManager.go_to("tower_select")

# ─── SIGNAL HANDLERS ───────────────────────────────────
func _on_level_unlocked(_level: int) -> void:
	_build_level_nodes()

# ─── STYLES ────────────────────────────────────────────
func _apply_styles() -> void:
	var top_style := StyleBoxFlat.new()
	top_style.bg_color          = Color("#0A1628")
	top_style.border_color      = Color("#00D4FF")
	top_style.border_width_bottom = 1
	$TopBar.add_theme_stylebox_override("panel", top_style)

func _style_back_btn() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = Color("#00D4FF")
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	back_btn.add_theme_stylebox_override("normal", style)
	back_btn.add_theme_color_override("font_color", Color("#00D4FF"))

func _apply_responsive_layout() -> void:
	# Since we are using an absolute MapCanvas horizontally scrollable system, plain responsive layouts of Grid columns are not required!
	pass
