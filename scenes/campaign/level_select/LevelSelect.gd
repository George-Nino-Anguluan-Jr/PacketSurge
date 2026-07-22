# LevelSelect.gd
extends Control

@onready var back_btn: Button         = $TopBar/TopBarLayout/BackBtn
@onready var ram_label: Label         = $TopBar/TopBarLayout/RAMLabel
@onready var map_scroll: ScrollContainer = %MapScroll
@onready var map_canvas: Control      = %MapCanvas
@onready var locked_label: Label      = $ContentArea/MainLayout/LockedLabel

# Visual zig-zag coordinates for main level groups on the 2100px wide canvas
const MAIN_LEVEL_POSITIONS = {
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
	
	# Responsive layout
	_apply_responsive_layout()
	ScreenManager.make_scroll_touch_friendly(map_scroll)
	get_tree().root.size_changed.connect(_apply_responsive_layout)
	
	# Smoothly auto-scroll to center on current/unlocked progress
	await get_tree().process_frame
	_auto_scroll_to_current()

var _map_redraw_counter: int = 0

func _process(_delta: float) -> void:
	# Redraw map canvas at ~10 FPS to reduce GPU draw-call overhead on mobile
	_map_redraw_counter += 1
	if is_inside_tree() and map_canvas.visible and _map_redraw_counter % 6 == 0:
		map_canvas.queue_redraw()

func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	_style_back_btn()

func _on_back_pressed() -> void:
	SoundManager.play_click()
	GameManager.go_to("main_menu")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

# ─── AUTO SCROLL TO CURRENT PROGRESS ───────────────────
func _auto_scroll_to_current() -> void:
	var highest_unlocked := 1
	for main_level in range(1, 14):
		if ProgressManager.is_level_unlocked(main_level):
			highest_unlocked = main_level

	var target_pos = MAIN_LEVEL_POSITIONS[highest_unlocked]
	# Center the scrollbar around target pos
	var center_offset = target_pos.x - (size.x / 2.0)
	center_offset = clamp(center_offset, 0.0, map_canvas.custom_minimum_size.x - size.x)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(map_scroll, "scroll_horizontal", int(center_offset), 0.8)

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
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_theme_constant_override("separation", 2)
	tooltip_panel.add_child(layout)
	
	var title := Label.new()
	title.name = "Title"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = "Level Info"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color.WHITE)
	layout.add_child(title)
	
	var ds := Label.new()
	ds.name = "DS"
	ds.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ds.text = "Arrays"
	ds.add_theme_font_size_override("font_size", 11)
	ds.add_theme_color_override("font_color", Color("#00D4FF"))
	layout.add_child(ds)
	
	var stats := Label.new()
	stats.name = "Stats"
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		var extra = ""
		if is_completed:
			var s = ProgressManager.get_level_stars(info["number"])
			extra = " ⭐" + str(s) + "/3"
		stats.text = str(info["waves"]) + " Waves" + (" (Completed" + extra + ")" if is_completed else "")
		tooltip_panel.get_theme_stylebox("panel").border_color = Color("#00FF88") if is_completed else Color("#00D4FF")
		ds.add_theme_color_override("font_color", Color("#00FF88") if is_completed else Color("#00D4FF"))
	else:
		title.text = "Locked System"
		ds.text = "Requires earlier systems"
		stats.text = "Unlock progress in Academy"
		tooltip_panel.get_theme_stylebox("panel").border_color = Color("#2A3A4A")
		ds.add_theme_color_override("font_color", Color("#2A3A4A"))
		
	# Adjust tooltip screen position — bounces to opposite side if off-screen
	var tooltip_size = tooltip_panel.custom_minimum_size
	var screen = DisplayServer.window_get_size()
	var pos = global_pos - Vector2(100, 110)
	if pos.x < 0:
		pos.x = global_pos.x + 20
	if pos.y < 52:
		pos.y = global_pos.y + 20
	if pos.x + tooltip_size.x > screen.x:
		pos.x = screen.x - tooltip_size.x
	if pos.y + tooltip_size.y > screen.y:
		pos.y = screen.y - tooltip_size.y
	tooltip_panel.global_position = pos
	
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

	for main_level in range(1, 14):
		var is_unlocked = ProgressManager.is_level_unlocked(main_level)
		var is_completed = ProgressManager.campaign_progress.get("waves_completed", 0) >= main_level

		if is_unlocked:
			unlocked_count += 1

		var pos = MAIN_LEVEL_POSITIONS[main_level]
		var info = {"number": main_level, "name": "Level " + str(main_level), "ds": "", "waves": 3}
		var btn = _create_node_button(info, is_unlocked, is_completed, pos)
		map_canvas.add_child(btn)
		active_nodes.append(btn)

		if is_completed:
			var star_count = ProgressManager.get_level_stars(main_level)
			if star_count > 0:
				var star_lbl := Label.new()
				var s = ""
				for i in range(3):
					s += "⭐" if i < star_count else "☆"
					if i < 2: s += " "
				star_lbl.text = s
				star_lbl.add_theme_font_size_override("font_size", 8)
				star_lbl.position = pos + Vector2(-26, 30)
				star_lbl.custom_minimum_size = Vector2(52, 12)
				map_canvas.add_child(star_lbl)
				active_nodes.append(star_lbl)

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
	
	var stars = ProgressManager.get_level_stars(info["number"]) if is_completed else 0

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
		SoundManager.play_hover()
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

# ─── PROCEDURAL LINKING & BACKGROUND DRAW LOGIC ───────
func _on_map_canvas_draw() -> void:
	# 1. Procedural Highly-Optimized Motherboard Background Assets (LOW VERTEX COST)
	_draw_bg_motherboard_tracks()
	_draw_bg_cpu_core()
	_draw_bg_memory_banks()
	_draw_bg_hex_gateway()
	_draw_system_readouts()
	_draw_traffic_oscillator()
	
	# 2. Level Trace connections as clean 45-degree copper lanes
	for i in range(1, 13):
		var pos_a = MAIN_LEVEL_POSITIONS[i]
		var pos_b = MAIN_LEVEL_POSITIONS[i + 1]
		
		var unlocked_b = ProgressManager.is_level_unlocked(i + 1)
		var completed_b = ProgressManager.campaign_progress.get("waves_completed", 0) >= (i + 1)
		
		var points = _get_trace_points(pos_a, pos_b)
		
		if completed_b:
			# Glowing Completed Green PCB trace
			map_canvas.draw_polyline(PackedVector2Array(points), Color("#00FF88", 0.75), 3.0)
			_draw_glowing_packet(points, Color("#00FF88"), 1.1)
		elif unlocked_b:
			# Glowing Active Cyan PCB trace
			map_canvas.draw_polyline(PackedVector2Array(points), Color("#00D4FF", 0.70), 3.0)
			_draw_glowing_packet(points, Color("#00D4FF"), 0.9)
		else:
			# Offline dim dashed track
			_draw_dashed_trace(points, Color("#1A2D3D", 0.4), 1.5, 8.0)
			
	# 3. Rotating HUD corner bracket outlines around level nodes (High-Performance L-brackets)
	for lvl in range(1, 14):
		var node_pos = MAIN_LEVEL_POSITIONS[lvl]
		_draw_node_hud_brackets(node_pos, lvl)
		
		# Draw horizontal hardware bus trace connecting the sub-levels
		var sub_unlocked = ProgressManager.is_level_unlocked(lvl)
		var bus_color = Color("#00D4FF", 0.25) if sub_unlocked else Color("#1A2D3D", 0.15)
		map_canvas.draw_line(node_pos + Vector2(-68, 0), node_pos + Vector2(68, 0), bus_color, 2.0)

# ─── 45-DEGREE PCB TRACE MATHEMATICS ──────────────────
func _get_trace_points(from: Vector2, to: Vector2) -> Array:
	var dx = to.x - from.x
	var dy = to.y - from.y
	var points = [from]
	
	if abs(dx) > abs(dy):
		var abs_dy = abs(dy)
		var sign_dx = sign(dx)
		var p1 = Vector2(from.x + (abs(dx) - abs_dy) * 0.5 * sign_dx, from.y)
		var p2 = Vector2(p1.x + abs_dy * sign_dx, to.y)
		points.append(p1)
		points.append(p2)
	else:
		var abs_dx = abs(dx)
		var sign_dy = sign(dy)
		var p1 = Vector2(from.x, from.y + (abs(dy) - abs_dx) * 0.5 * sign_dy)
		var p2 = Vector2(to.x, p1.y + abs_dx * sign_dy)
		points.append(p1)
		points.append(p2)
		
	points.append(to)
	return points

func _draw_dashed_trace(points: Array, color: Color, width: float, dash_len: float) -> void:
	for i in range(points.size() - 1):
		_draw_dashed_line(points[i], points[i+1], color, width, dash_len)

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

# ─── LIGHTWEIGHT SURGING NEON PACKET ──────────────────
func _draw_glowing_packet(points: Array, color: Color, speed_scale: float) -> void:
	if points.size() < 2:
		return
	var total_len = 0.0
	var seg_lens: Array[float] = []
	for i in range(points.size() - 1):
		var d = points[i].distance_to(points[i+1])
		seg_lens.append(d)
		total_len += d
		
	if total_len <= 0.0:
		return
		
	var time_offset = fmod(Time.get_ticks_msec() * 0.001 * speed_scale, 1.0)
	var target_dist = time_offset * total_len
	
	var cur_dist = 0.0
	var p_pos = points[0]
	for i in range(points.size() - 1):
		if target_dist <= cur_dist + seg_lens[i]:
			var r = (target_dist - cur_dist) / seg_lens[i]
			p_pos = points[i].lerp(points[i+1], r)
			break
		cur_dist += seg_lens[i]
		
	map_canvas.draw_circle(p_pos, 4.0, color)
	map_canvas.draw_circle(p_pos, 1.5, Color.WHITE)

# ─── OPTIMIZED ROTATING TARGET BRACKETS ───────────────
func _draw_node_hud_brackets(pos: Vector2, lvl: int) -> void:
	var is_unlocked = ProgressManager.is_level_unlocked(lvl)
	var is_completed = ProgressManager.campaign_progress.get("waves_completed", 0) >= lvl
	
	var hud_color = Color("#00FF88", 0.4) if is_completed else (Color("#00D4FF", 0.35) if is_unlocked else Color("#1A2D3D", 0.15))
	
	# Rotate the HUD corners at a highly optimized, uniform rate
	var angle = Time.get_ticks_msec() * 0.001 * (0.35 if lvl % 2 == 0 else -0.35)
	var size_offset = 35.0
	var arm_len = 8.0
	
	# Draw lightweight L-shaped brackets around node (Only 8 lines total per button!)
	for b in range(4):
		var base_angle = angle + b * (PI * 0.5)
		var corner_p = pos + Vector2(cos(base_angle), sin(base_angle)) * size_offset
		
		# Bracket arm vectors
		var dir_left = Vector2(cos(base_angle + PI * 0.75), sin(base_angle + PI * 0.75)) * arm_len
		var dir_right = Vector2(cos(base_angle - PI * 0.75), sin(base_angle - PI * 0.75)) * arm_len
		
		map_canvas.draw_line(corner_p, corner_p + dir_left, hud_color, 1.2)
		map_canvas.draw_line(corner_p, corner_p + dir_right, hud_color, 1.2)

# ─── HIGH-IMPACT HARDWARE AESTHETICS (OPTIMIZED) ──────
func _draw_system_readouts() -> void:
	var font = get_theme_font("font", "Label")
	var font_size = 11
	var color = Color("#4A7FA5", 0.45)
	
	# Draw technical status readout overlays on the board
	map_canvas.draw_string(font, Vector2(150, 310), "[DATA_BUS: SECURED // RX/TX_ACTIVE]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	map_canvas.draw_string(font, Vector2(750, 45), "[SYS_FREQ: 4.80_GHz // CORES: 13]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	map_canvas.draw_string(font, Vector2(1015, 260), "[CPU_TEMP: 32_C // STATUS: NOMINAL]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	map_canvas.draw_string(font, Vector2(1480, 310), "[FIREWALL_STATE: PROTECTED // AES_256]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	map_canvas.draw_string(font, Vector2(1850, 45), "[PACKET_LOSS: 0.00% // RETRIES: 0]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	
	# Draw hex addresses under each level node
	var hex_addresses = ["0x0F", "0x1A", "0x2C", "0x3F", "0x4B", "0x5A", "0x63", "0x7E", "0x8D", "0x9F", "0xA6", "0xB0", "0xCD"]
	for lvl in range(1, 14):
		var pos = MAIN_LEVEL_POSITIONS[lvl]
		var hex_addr = "[" + hex_addresses[lvl - 1] + "]"
		map_canvas.draw_string(font, pos + Vector2(-18, 52), hex_addr, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, color * 0.8)

func _draw_traffic_oscillator() -> void:
	# Subtle, beautiful rolling wave representing packet stream traffic (Highly optimized)
	var wave_color = Color("#00D4FF", 0.08)
	var wave_points: Array[Vector2] = []
	var time_offset = Time.get_ticks_msec() * 0.001 * 4.0
	
	for x in range(0, 2101, 30):
		var y = 300.0 + sin((x * 0.015) + time_offset) * 12.0
		wave_points.append(Vector2(x, y))
		
	map_canvas.draw_polyline(PackedVector2Array(wave_points), wave_color, 1.2)

func _draw_bg_motherboard_tracks() -> void:
	var track_color = Color("#00D4FF", 0.04)
	# A few aesthetic background PCB trace buses
	map_canvas.draw_polyline(PackedVector2Array([Vector2(50, 40), Vector2(300, 40), Vector2(400, 100), Vector2(700, 100)]), track_color, 1.0)
	map_canvas.draw_polyline(PackedVector2Array([Vector2(100, 320), Vector2(500, 320), Vector2(600, 260), Vector2(850, 260)]), track_color, 1.0)
	map_canvas.draw_polyline(PackedVector2Array([Vector2(950, 40), Vector2(1200, 40), Vector2(1300, 110), Vector2(1700, 110)]), track_color, 1.0)

func _draw_bg_cpu_core() -> void:
	# Large Central Microprocessor silhouette in Sector 2 (X: 1000, Y: 180)
	var center = Vector2(1000, 165)
	var color_inner = Color("#00D4FF", 0.03)
	var color_border = Color("#00D4FF", 0.12)
	
	# Base chip plate
	map_canvas.draw_rect(Rect2(center.x - 70, center.y - 70, 140, 140), color_inner, true)
	map_canvas.draw_rect(Rect2(center.x - 70, center.y - 70, 140, 140), color_border, false, 1.5)
	map_canvas.draw_rect(Rect2(center.x - 45, center.y - 45, 90, 90), Color("#00D4FF", 0.04), true)
	map_canvas.draw_rect(Rect2(center.x - 45, center.y - 45, 90, 90), color_border, false, 1.0)
	
	# Golden connection pin buses (Only 8 quick lines!)
	for offset in [-50, -25, 25, 50]:
		map_canvas.draw_line(Vector2(center.x + offset, center.y - 70), Vector2(center.x + offset, center.y - 85), color_border, 1.0)
		map_canvas.draw_line(Vector2(center.x + offset, center.y + 70), Vector2(center.x + offset, center.y + 85), color_border, 1.0)
		map_canvas.draw_line(Vector2(center.x - 70, center.y + offset), Vector2(center.x - 85, center.y + offset), color_border, 1.0)
		map_canvas.draw_line(Vector2(center.x + 70, center.y + offset), Vector2(center.x + 85, center.y + offset), color_border, 1.0)

func _draw_bg_memory_banks() -> void:
	# Vertical memory slots in Sector 1 (X: 200, Y: 60)
	var color_inner = Color("#00D4FF", 0.03)
	var color_border = Color("#00D4FF", 0.10)
	
	# Draw RAM modules
	for rx in [120, 380]:
		map_canvas.draw_rect(Rect2(rx, 20, 90, 30), color_inner, true)
		map_canvas.draw_rect(Rect2(rx, 20, 90, 30), color_border, false, 1.0)
		for px in range(rx + 8, rx + 82, 12):
			map_canvas.draw_line(Vector2(px, 20), Vector2(px, 25), color_border, 1.0)
			map_canvas.draw_line(Vector2(px, 50), Vector2(px, 45), color_border, 1.0)

func _draw_bg_hex_gateway() -> void:
	# Holographic Gateway Core in Sector 3 (X: 1800, Y: 180)
	var center = Vector2(1800, 165)
	var is_unlocked = ProgressManager.is_level_unlocked(13)
	
	var color_border = Color("#00FF88" if is_unlocked else "#00D4FF", 0.14)
	
	# Draw a crisp, lightweight Hexagonal mainframe shield
	var hex_radius = 80.0
	var hex_points: Array[Vector2] = []
	for h in range(6):
		var a = h * PI / 3.0
		hex_points.append(center + Vector2(cos(a), sin(a)) * hex_radius)
	hex_points.append(hex_points[0]) # Close path
	
	map_canvas.draw_polyline(PackedVector2Array(hex_points), color_border, 1.5)
	
	# Inner core hexagonal line
	var hex_inner: Array[Vector2] = []
	for h in range(6):
		var a = h * PI / 3.0
		hex_inner.append(center + Vector2(cos(a), sin(a)) * 50.0)
	hex_inner.append(hex_inner[0])
	map_canvas.draw_polyline(PackedVector2Array(hex_inner), color_border * 0.4, 1.0)

# ─── LEVEL SELECTED ────────────────────────────────────
func _on_level_selected(level_number: int) -> void:
	SoundManager.play_click()
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
	var content_area = $ContentArea
	var top_bar = $TopBar
	
	if ScreenManager.is_mobile():
		ScreenManager.apply_panel_padding(top_bar, 20)
		content_area.offset_top = 72
		content_area.add_theme_constant_override("margin_left", 20)
		content_area.add_theme_constant_override("margin_right", 20)
		content_area.add_theme_constant_override("margin_top", 0)
		content_area.add_theme_constant_override("margin_bottom", 20)
		back_btn.custom_minimum_size = Vector2(70, 44)
	elif ScreenManager.is_tablet():
		ScreenManager.apply_panel_padding(top_bar, 24)
		content_area.offset_top = 76
		content_area.add_theme_constant_override("margin_left", 24)
		content_area.add_theme_constant_override("margin_right", 24)
		content_area.add_theme_constant_override("margin_top", 0)
		content_area.add_theme_constant_override("margin_bottom", 24)
		back_btn.custom_minimum_size = Vector2(80, 44)
	else:
		back_btn.custom_minimum_size = Vector2(90, 0)
