# VizArrays.gd
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
	{"code": "arr = [10, 20, 30, 40, 50]",  "highlight": -1},
	{"code": "arr[0] → 10  (O(1) access!)", "highlight":  0},
	{"code": "arr[2] → 30",                 "highlight":  2},
	{"code": "arr[4] → 50",                 "highlight":  4},
	{"code": "arr.append(60) → add to end", "highlight":  5},
	{"code": "arr[5] → 60 ✅",              "highlight":  5},
]

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)

	var diag_title := Label.new()
	diag_title.text = "📊 Array — Fixed Index Access"
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
	anim_area.custom_minimum_size   = Vector2(0, 100)
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
		code_label.text = "✅ Array operations complete!"
		return
	code_label.text = "▶  " + anim_steps[current_anim_step]["code"]
	current_anim_step += 1
	anim_area.queue_redraw()

func _draw_diagram() -> void:
	var w    = diagram_area.size.x
	var font = ThemeDB.fallback_font
	var vals = [10, 20, 30, 40, 50]
	var bw = 56.0; var bh = 44.0
	var total = vals.size() * (bw + 4) - 4
	var sx = (w - total) / 2.0
	var y  = 30.0
	diagram_area.draw_string(font, Vector2(sx - 14, y - 10), "arr =", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COL_MUTED)
	for i in range(vals.size()):
		var x = sx + i * (bw + 4)
		diagram_area.draw_rect(Rect2(x, y, bw, bh), Color("#0D2040"))
		diagram_area.draw_rect(Rect2(x, y, bw, bh), COL_LABEL, false, 1.5)
		diagram_area.draw_string(font, Vector2(x + 6, y - 8), "[" + str(i) + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COL_MUTED)
		diagram_area.draw_string(font, Vector2(x + 14, y + 28), str(vals[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COL_VALUE)

func _draw_animation() -> void:
	var w    = anim_area.size.x
	var font = ThemeDB.fallback_font
	var highlight = -1
	if current_anim_step > 0:
		highlight = anim_steps[current_anim_step - 1]["highlight"]

	var vals = [10, 20, 30, 40, 50]
	if current_anim_step >= 5:
		vals = [10, 20, 30, 40, 50, 60]

	var bw = 50.0; var bh = 44.0
	var total = vals.size() * (bw + 4) - 4
	var sx = (w - total) / 2.0
	var y  = 20.0

	for i in range(vals.size()):
		var x   = sx + i * (bw + 4)
		var col = COL_WARN if i == highlight else COL_LABEL
		var is_new = i == 5 and current_anim_step >= 5
		if is_new: col = COL_VALUE
		anim_area.draw_rect(Rect2(x, y, bw, bh), Color(col, 0.15))
		anim_area.draw_rect(Rect2(x, y, bw, bh), col, false, 1.5)
		anim_area.draw_string(font, Vector2(x + 4, y - 8), "[" + str(i) + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COL_MUTED)
		anim_area.draw_string(font, Vector2(x + 10, y + 28), str(vals[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COL_TEXT)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if diagram_area: diagram_area.queue_redraw()
		if anim_area:    anim_area.queue_redraw()
