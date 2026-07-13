# VizQueues.gd
extends Control

const COL_LABEL  := Color("#9B59B6")
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

var queue_items: Array = []

var anim_steps = [
	{"code": "from collections import deque",       "action": "none",     "value": ""},
	{"code": "queue = deque()  → empty queue",      "action": "none",     "value": ""},
	{"code": "queue.append('A')  → enqueue A",      "action": "enqueue",  "value": "A"},
	{"code": "queue.append('B')  → enqueue B",      "action": "enqueue",  "value": "B"},
	{"code": "queue.append('C')  → enqueue C",      "action": "enqueue",  "value": "C"},
	{"code": "queue.popleft() → dequeue A (FIFO)",  "action": "dequeue",  "value": ""},
	{"code": "queue.popleft() → dequeue B",         "action": "dequeue",  "value": ""},
	{"code": "queue = deque(['C']) ✅",             "action": "none",     "value": ""},
]

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)

	var diag_title := Label.new()
	diag_title.text = "📊 Queue — First In First Out (FIFO)"
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
	queue_items = []
	code_label.text = "Press Play or Step to begin"
	anim_area.queue_redraw()

func _advance_step() -> void:
	if current_anim_step >= anim_steps.size():
		is_playing = false
		play_btn.text = "▶ Play"
		code_label.text = "✅ Queue operations complete!"
		return
	var step = anim_steps[current_anim_step]
	code_label.text = "▶  " + step["code"]
	if step["action"] == "enqueue":
		queue_items.append(step["value"])
	elif step["action"] == "dequeue" and queue_items.size() > 0:
		queue_items.pop_front()
	current_anim_step += 1
	anim_area.queue_redraw()

func _draw_diagram() -> void:
	var font = ThemeDB.fallback_font
	var lines = [
		["from collections import deque",  COL_MUTED],
		["queue.append(x)  → enqueue",     COL_VALUE],
		["queue.popleft()  → dequeue",     Color("#FF3366")],
		["First In, First Out (FIFO)",     COL_MUTED],
	]
	var y = 16.0
	for line in lines:
		diagram_area.draw_string(ThemeDB.fallback_font, Vector2(16, y), line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, line[1])
		y += 22.0

func _draw_animation() -> void:
	var w    = anim_area.size.x
	var h    = anim_area.size.y
	var font = ThemeDB.fallback_font
	var bw   = 52.0; var bh = 44.0
	var sy   = h / 2.0 - bh / 2.0

	# Front label
	anim_area.draw_string(font, Vector2(10, sy - 12), "FRONT →", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#FF3366"))
	# Back label
	anim_area.draw_string(font, Vector2(w - 60, sy - 12), "← BACK", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COL_VALUE)

	if queue_items.is_empty():
		anim_area.draw_string(font, Vector2(w/2 - 30, sy + 22), "empty", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COL_MUTED)
		return

	var sx = 10.0
	for i in range(queue_items.size()):
		var x   = sx + i * (bw + 4)
		var col = Color("#FF3366") if i == 0 else COL_LABEL
		anim_area.draw_rect(Rect2(x, sy, bw, bh), Color(col, 0.2))
		anim_area.draw_rect(Rect2(x, sy, bw, bh), col, false, 1.5)
		anim_area.draw_string(font, Vector2(x + 16, sy + 28), queue_items[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COL_TEXT)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if diagram_area: diagram_area.queue_redraw()
		if anim_area:    anim_area.queue_redraw()
