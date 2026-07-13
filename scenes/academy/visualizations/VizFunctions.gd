# VizFunctions.gd
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
	{"code": "def greet(name):  → define function", "phase": 0},
	{"code": "greet('Alice')  → call the function",  "phase": 1},
	{"code": "name = 'Alice' inside function",        "phase": 2},
	{"code": "return 'Hello, Alice!'",               "phase": 3},
	{"code": "result = 'Hello, Alice!' ✅",           "phase": 4},
]

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)

	var diag_title := Label.new()
	diag_title.text = "📊 How Functions Work"
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
		code_label.text = "✅ Function returned result!"
		return
	code_label.text = "▶  " + anim_steps[current_anim_step]["code"]
	current_anim_step += 1
	anim_area.queue_redraw()

func _draw_diagram() -> void:
	var font = ThemeDB.fallback_font
	var lines = [
		["def greet(name):",            COL_WARN],
		["    msg = 'Hello, ' + name",  COL_TEXT],
		["    return msg",              COL_LABEL],
		["",                            COL_MUTED],
		["result = greet('Alice')",     COL_VALUE],
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

	# Caller box
	var caller_col = COL_LABEL if phase >= 1 else Color("#1A3A5A")
	anim_area.draw_rect(Rect2(10, 20, 130, 40), Color(caller_col, 0.15))
	anim_area.draw_rect(Rect2(10, 20, 130, 40), caller_col, false, 1.5)
	anim_area.draw_string(font, Vector2(16, 36), "greet('Alice')", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COL_TEXT)
	anim_area.draw_string(font, Vector2(16, 52), "caller", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COL_MUTED)

	# Arrow to function
	if phase >= 1:
		anim_area.draw_line(Vector2(140, 40), Vector2(180, 40), COL_WARN, 2.0)
		anim_area.draw_line(Vector2(174, 34), Vector2(180, 40), COL_WARN, 2.0)
		anim_area.draw_line(Vector2(174, 46), Vector2(180, 40), COL_WARN, 2.0)

	# Function box
	var fn_col = COL_WARN if phase >= 0 else Color("#1A3A5A")
	anim_area.draw_rect(Rect2(180, 10, 160, 60), Color(fn_col, 0.15))
	anim_area.draw_rect(Rect2(180, 10, 160, 60), fn_col, false, 1.5)
	anim_area.draw_string(font, Vector2(186, 28), "def greet(name):", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COL_WARN)
	if phase >= 2:
		anim_area.draw_string(font, Vector2(186, 44), "name = 'Alice'", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COL_TEXT)
	if phase >= 3:
		anim_area.draw_string(font, Vector2(186, 60), "return msg", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COL_LABEL)

	# Return arrow
	if phase >= 3:
		anim_area.draw_line(Vector2(180, 90), Vector2(140, 90), COL_VALUE, 2.0)
		anim_area.draw_line(Vector2(146, 84), Vector2(140, 90), COL_VALUE, 2.0)
		anim_area.draw_line(Vector2(146, 96), Vector2(140, 90), COL_VALUE, 2.0)

	# Result box
	if phase >= 4:
		anim_area.draw_rect(Rect2(10, 80, 130, 36), Color(COL_VALUE, 0.15))
		anim_area.draw_rect(Rect2(10, 80, 130, 36), COL_VALUE, false, 1.5)
		anim_area.draw_string(font, Vector2(16, 98), "'Hello, Alice!'", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COL_TEXT)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if diagram_area: diagram_area.queue_redraw()
		if anim_area:    anim_area.queue_redraw()
