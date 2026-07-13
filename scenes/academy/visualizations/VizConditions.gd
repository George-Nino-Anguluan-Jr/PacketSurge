# VizConditions.gd
extends Control

const COL_LABEL  := Color("#00D4FF")
const COL_VALUE  := Color("#00FF88")
const COL_TEXT   := Color("#E8F4FD")
const COL_MUTED  := Color("#4A7FA5")
const COL_WARN   := Color("#FFB800")

var diagram_area: Control
var anim_area: Control
var code_label: Label
var play_btn: Button
var step_btn: Button
var reset_btn: Button

var current_anim_step: int = 0
var is_playing: bool       = false
var play_timer: float      = 0.0
const PLAY_INTERVAL: float = 1.2

var anim_steps = [
	{"code": "x = 15",                       "phase": 0},
	{"code": "if x > 10: → is 15 > 10?",     "phase": 1},
	{"code": "YES → enter the if block",      "phase": 2},
	{"code": "print('x is greater than 10')", "phase": 3},
	{"code": "else block is skipped ✅",       "phase": 4},
]

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)

	var diag_title := Label.new()
	diag_title.text = "📊 How Conditions Work"
	diag_title.add_theme_color_override("font_color", COL_LABEL)
	diag_title.add_theme_font_size_override("font_size", 15)
	layout.add_child(diag_title)

	diagram_area = Control.new()
	diagram_area.custom_minimum_size   = Vector2(0, 110)
	diagram_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diagram_area.draw.connect(_draw_diagram)
	layout.add_child(diagram_area)

	layout.add_child(HSeparator.new())

	var anim_title := Label.new()
	anim_title.text = "🎬 Step-by-Step Animation"
	anim_title.add_theme_color_override("font_color", COL_LABEL)
	anim_title.add_theme_font_size_override("font_size", 15)
	layout.add_child(anim_title)

	code_label = Label.new()
	code_label.text = "Press Play or Step to begin"
	code_label.add_theme_color_override("font_color", COL_WARN)
	code_label.add_theme_font_size_override("font_size", 14)
	code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(code_label)

	anim_area = Control.new()
	anim_area.custom_minimum_size   = Vector2(0, 120)
	anim_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	anim_area.draw.connect(_draw_animation)
	layout.add_child(anim_area)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(controls)

	play_btn  = _make_btn("▶ Play",  COL_LABEL)
	step_btn  = _make_btn("⏭ Step",  COL_LABEL)
	reset_btn = _make_btn("↺ Reset", Color("#FF3366"))
	controls.add_child(play_btn)
	controls.add_child(step_btn)
	controls.add_child(reset_btn)
	play_btn.pressed.connect(_on_play)
	step_btn.pressed.connect(_on_step)
	reset_btn.pressed.connect(_on_reset)

func _make_btn(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(90, 36)
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#0A1628"); s.border_color = color
	s.border_width_left = 1; s.border_width_right = 1
	s.border_width_top  = 1; s.border_width_bottom = 1
	s.corner_radius_top_left = 4; s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4; s.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_font_size_override("font_size", 13)
	return btn

func _process(delta: float) -> void:
	if not is_playing: return
	play_timer += delta
	if play_timer >= PLAY_INTERVAL:
		play_timer = 0.0
		_advance_step()

func _on_play() -> void:
	is_playing = not is_playing
	play_btn.text = "⏸ Pause" if is_playing else "▶ Play"

func _on_step() -> void:
	is_playing = false
	play_btn.text = "▶ Play"
	_advance_step()

func _on_reset() -> void:
	is_playing = false
	play_btn.text = "▶ Play"
	current_anim_step = 0
	code_label.text = "Press Play or Step to begin"
	anim_area.queue_redraw()

func _advance_step() -> void:
	if current_anim_step >= anim_steps.size():
		is_playing = false
		play_btn.text = "▶ Play"
		code_label.text = "✅ Condition evaluated!"
		return
	code_label.text = "▶  " + anim_steps[current_anim_step]["code"]
	current_anim_step += 1
	anim_area.queue_redraw()

func _draw_diagram() -> void:
	var font = ThemeDB.fallback_font
	var lines = [
		["x = 15",                           COL_VALUE],
		["if x > 10:",                        COL_WARN],
		["    print('x is greater than 10')", COL_TEXT],
		["else:",                             COL_WARN],
		["    print('x is 10 or less')",      Color("#4A7FA5")],
	]
	var y = 16.0
	for line in lines:
		diagram_area.draw_string(ThemeDB.fallback_font, Vector2(16, y), line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, line[1])
		y += 20.0

func _draw_animation() -> void:
	var w    = anim_area.size.x
	var h    = anim_area.size.y
	var font = ThemeDB.fallback_font
	var phase = 0
	if current_anim_step > 0:
		phase = anim_steps[current_anim_step - 1]["phase"]

	# x box
	var x_col = COL_VALUE if phase >= 0 else Color("#1A3A5A")
	anim_area.draw_rect(Rect2(10, 10, 80, 36), Color(x_col, 0.2))
	anim_area.draw_rect(Rect2(10, 10, 80, 36), x_col, false, 1.5)
	anim_area.draw_string(font, Vector2(16, 32), "x = 15", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COL_TEXT)

	# Diamond
	var cx  = w / 2.0
	var cy  = 50.0
	var d_col = COL_WARN if phase >= 1 else Color("#1A3A5A")
	var pts = PackedVector2Array([Vector2(cx, cy - 22), Vector2(cx + 55, cy), Vector2(cx, cy + 22), Vector2(cx - 55, cy)])
	anim_area.draw_colored_polygon(pts, Color(d_col, 0.2))
	for i in range(4):
		anim_area.draw_line(pts[i], pts[(i+1)%4], d_col, 1.5)
	anim_area.draw_string(font, Vector2(cx - 24, cy + 6), "x > 10?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COL_TEXT)

	# YES path
	var yes_col = COL_VALUE if phase >= 2 else Color("#1A3A5A")
	anim_area.draw_line(Vector2(cx + 55, cy), Vector2(w - 20, cy), yes_col, 2.0)
	anim_area.draw_string(font, Vector2(cx + 58, cy - 6), "YES", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, yes_col)
	if phase >= 3:
		anim_area.draw_rect(Rect2(w - 130, cy - 20, 110, 36), Color(COL_VALUE, 0.15))
		anim_area.draw_rect(Rect2(w - 130, cy - 20, 110, 36), COL_VALUE, false, 1.5)
		anim_area.draw_string(font, Vector2(w - 126, cy + 2), "print('>10')", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COL_TEXT)

	# NO path
	var no_col = Color("#FF3366") if phase >= 4 else Color("#1A3A5A")
	anim_area.draw_line(Vector2(cx - 55, cy), Vector2(20, cy), no_col, 2.0)
	anim_area.draw_string(font, Vector2(22, cy - 6), "NO", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, no_col)
	anim_area.draw_rect(Rect2(20, cy + 10, 100, 36), Color(Color("#1A3A5A"), 0.2))
	anim_area.draw_rect(Rect2(20, cy + 10, 100, 36), Color("#1A3A5A"), false, 1.5)
	anim_area.draw_string(font, Vector2(24, cy + 32), "print('≤10')", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COL_MUTED)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if diagram_area: diagram_area.queue_redraw()
		if anim_area:    anim_area.queue_redraw()
