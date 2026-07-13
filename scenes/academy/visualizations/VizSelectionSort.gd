# VizSelectionSort.gd
extends Control

const COL_LABEL  := Color("#E74C3C")
const COL_VALUE  := Color("#00FF88")
const COL_TEXT   := Color("#E8F4FD")
const COL_MUTED  := Color("#4A7FA5")
const COL_MIN    := Color("#FFB800")

var diagram_area: Control
var anim_area: Control
var code_label: Label
var play_btn: Button
var step_btn: Button
var reset_btn: Button

var current_anim_step: int = 0
var is_playing: bool       = false
var play_timer: float      = 0.0
const PLAY_INTERVAL: float = 1.1

var arr_states = [
	[5, 3, 8, 1, 2],
	[1, 3, 8, 5, 2],
	[1, 2, 8, 5, 3],
	[1, 2, 3, 5, 8],
	[1, 2, 3, 5, 8],
]

var step_codes = [
	"arr = [5,3,8,1,2] → find min=1 at index 3",
	"Swap 5 and 1 → [1,3,8,5,2] → find min=2",
	"Swap 3 and 2 → [1,2,8,5,3] → find min=3",
	"Swap 8 and 3 → [1,2,3,5,8] → find min=5",
	"5 already in place → [1,2,3,5,8] ✅",
]

var min_indices = [3, 4, 4, 2, 3]
var sorted_up_to = [0, 1, 2, 3, 4]

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)

	var diag_title := Label.new()
	diag_title.text = "📊 Selection Sort — Find Minimum Each Pass"
	diag_title.add_theme_color_override("font_color", COL_LABEL)
	diag_title.add_theme_font_size_override("font_size", 15)
	layout.add_child(diag_title)

	diagram_area = Control.new()
	diagram_area.custom_minimum_size   = Vector2(0, 100)
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
	code_label.add_theme_color_override("font_color", COL_MIN)
	code_label.add_theme_font_size_override("font_size", 13)
	code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(code_label)

	anim_area = Control.new()
	anim_area.custom_minimum_size   = Vector2(0, 90)
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
	if current_anim_step >= arr_states.size():
		is_playing = false
		play_btn.text = "▶ Play"
		code_label.text = "✅ Sorted: [1, 2, 3, 5, 8]"
		return
	code_label.text = "▶  " + step_codes[current_anim_step]
	current_anim_step += 1
	anim_area.queue_redraw()

func _draw_diagram() -> void:
	var font = ThemeDB.fallback_font
	diagram_area.draw_string(font, Vector2(16, 20), "def selection_sort(arr):", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COL_LABEL)
	diagram_area.draw_string(font, Vector2(16, 40), "    for i in range(len(arr)):", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COL_TEXT)
	diagram_area.draw_string(font, Vector2(16, 60), "        min_idx = find minimum in arr[i:]", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COL_MIN)
	diagram_area.draw_string(font, Vector2(16, 80), "        swap arr[i] with arr[min_idx]", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#FF3366"))

func _draw_animation() -> void:
	var w    = anim_area.size.x
	var font = ThemeDB.fallback_font
	var idx  = min(current_anim_step, arr_states.size() - 1)
	var arr  = arr_states[idx]
	var mi   = min_indices[idx] if idx < min_indices.size() else -1
	var su   = sorted_up_to[idx] if idx < sorted_up_to.size() else arr.size()
	var bw   = 48.0; var bh = 48.0
	var total = arr.size() * (bw + 6) - 6
	var sx    = (w - total) / 2.0
	var y     = 16.0

	for i in range(arr.size()):
		var x   = sx + i * (bw + 6)
		var col: Color
		if i < su:
			col = COL_VALUE
		elif i == mi:
			col = COL_MIN
		else:
			col = COL_LABEL
		anim_area.draw_rect(Rect2(x, y, bw, bh), Color(col, 0.2))
		anim_area.draw_rect(Rect2(x, y, bw, bh), col, false, 1.5)
		anim_area.draw_string(font, Vector2(x + 14, y + 30), str(arr[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, COL_TEXT)
		if i == mi:
			anim_area.draw_string(font, Vector2(x + 8, y + bh + 10), "MIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COL_MIN)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if diagram_area: diagram_area.queue_redraw()
		if anim_area:    anim_area.queue_redraw()
