# VizLinkedLists.gd
extends Control

const COL_LABEL  := Color("#00FF88")
const COL_VALUE  := Color("#00D4FF")
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
const PLAY_INTERVAL: float = 1.3

var anim_steps = [
	{"code": "head = Node(1)  → first node",       "nodes": 1, "highlight": 0},
	{"code": "head.next = Node(2)  → link to 2",   "nodes": 2, "highlight": 1},
	{"code": "→ next = Node(3)  → link to 3",      "nodes": 3, "highlight": 2},
	{"code": "Traverse: head → 1 → 2 → 3 → None", "nodes": 3, "highlight": -1},
	{"code": "Access node 2: follow pointers O(n)","nodes": 3, "highlight": 1},
]

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)

	var diag_title := Label.new()
	diag_title.text = "📊 Linked List — Nodes with Pointers"
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
	anim_area.custom_minimum_size   = Vector2(0, 110)
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
		code_label.text = "✅ Linked List built!"
		return
	code_label.text = "▶  " + anim_steps[current_anim_step]["code"]
	current_anim_step += 1
	anim_area.queue_redraw()

func _draw_diagram() -> void:
	var w    = diagram_area.size.x
	var font = ThemeDB.fallback_font
	var node_w = 60.0; var node_h = 36.0; var ptr_w = 28.0
	var total  = 3 * (node_w + ptr_w + 4) + 40
	var sx     = (w - total) / 2.0
	var y      = 36.0
	var labels = ["1", "2", "3"]
	diagram_area.draw_string(font, Vector2(sx - 30, y + 22), "HEAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COL_WARN)
	diagram_area.draw_line(Vector2(sx - 6, y + 18), Vector2(sx, y + 18), COL_WARN, 1.5)
	for i in range(3):
		var x = sx + i * (node_w + ptr_w + 4)
		diagram_area.draw_rect(Rect2(x, y, node_w, node_h), Color("#0D2040"))
		diagram_area.draw_rect(Rect2(x, y, node_w, node_h), COL_LABEL, false, 1.5)
		diagram_area.draw_string(font, Vector2(x + 6, y - 6), "data|next", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, COL_MUTED)
		diagram_area.draw_string(font, Vector2(x + 20, y + 24), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COL_VALUE)
		diagram_area.draw_line(Vector2(x + node_w, y + 18), Vector2(x + 2, y + 18), COL_MUTED, 1.0)
		if i < 2:
			diagram_area.draw_rect(Rect2(x + node_w, y, ptr_w, node_h), Color("#1A3A5A"))
			diagram_area.draw_rect(Rect2(x + node_w, y, ptr_w, node_h), COL_MUTED, false, 1.0)
			diagram_area.draw_line(Vector2(x + node_w + ptr_w, y + 18), Vector2(x + node_w + ptr_w + 4, y + 18), COL_VALUE, 1.5)
			diagram_area.draw_line(Vector2(x + node_w + ptr_w, y + 12), Vector2(x + node_w + ptr_w + 4, y + 18), COL_VALUE, 1.5)
			diagram_area.draw_line(Vector2(x + node_w + ptr_w), Vector2(x + node_w + ptr_w + 4, y + 18), COL_VALUE, 1.5)
		else:
			diagram_area.draw_rect(Rect2(x + node_w, y, ptr_w, node_h), Color("#1A0A0A"))
			diagram_area.draw_rect(Rect2(x + node_w, y, ptr_w, node_h), Color("#FF3366"), false, 1.0)
			diagram_area.draw_string(font, Vector2(x + node_w + 2, y + 22), "None", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#FF3366"))

func _draw_animation() -> void:
	var w    = anim_area.size.x
	var h    = anim_area.size.y
	var font = ThemeDB.fallback_font
	var step = anim_steps[max(0, current_anim_step - 1)] if current_anim_step > 0 else {"nodes": 0, "highlight": -1}
	var node_count = step["nodes"]
	var highlight  = step["highlight"]

	var node_w = 56.0; var arr_w = 30.0; var node_h = 36.0
	var total  = node_count * (node_w + arr_w) - arr_w
	var sx     = (w - total) / 2.0
	var y      = h / 2.0 - node_h / 2.0

	for i in range(node_count):
		var x   = sx + i * (node_w + arr_w)
		var col = COL_WARN if i == highlight else COL_LABEL
		anim_area.draw_rect(Rect2(x, y, node_w, node_h), Color(col, 0.2))
		anim_area.draw_rect(Rect2(x, y, node_w, node_h), col, false, 1.5)
		anim_area.draw_string(font, Vector2(x + 18, y + 24), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COL_TEXT)
		if i < node_count - 1:
			var ax = x + node_w
			anim_area.draw_line(Vector2(ax, y + 18), Vector2(ax + arr_w - 2, y + 18), COL_VALUE, 2.0)
			anim_area.draw_line(Vector2(ax + arr_w - 8, y + 12), Vector2(ax + arr_w - 2, y + 18), COL_VALUE, 2.0)
			anim_area.draw_line(Vector2(ax + arr_w - 8, y + 24), Vector2(ax + arr_w - 2, y + 18), COL_VALUE, 2.0)
		else:
			anim_area.draw_string(font, Vector2(x + node_w + 4, y + 22), "None", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#FF3366"))

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if diagram_area: diagram_area.queue_redraw()
		if anim_area:    anim_area.queue_redraw()
