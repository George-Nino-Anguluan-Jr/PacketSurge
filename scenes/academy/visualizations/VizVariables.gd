# VizVariables.gd
# Visualization for the Variables lesson
# Shows: diagram of name = value, then animated fill sequence
extends Control

# ─── COLORS ────────────────────────────────────────────
const COL_BG        := Color("#050D1A")
const COL_BOX       := Color("#0D2040")
const COL_BORDER    := Color("#00D4FF")
const COL_LABEL     := Color("#00D4FF")
const COL_VALUE     := Color("#00FF88")
const COL_ARROW     := Color("#4A7FA5")
const COL_TEXT      := Color("#E8F4FD")
const COL_MUTED     := Color("#4A7FA5")

# ─── DIAGRAM DATA ──────────────────────────────────────
# Shows 3 variable boxes side by side as a static diagram
var diagram_vars := [
	{"name": "student_name", "value": '"Maria"',  "type": "str"},
	{"name": "year_level",   "value": "1",        "type": "int"},
	{"name": "grade",        "value": "88.5",     "type": "float"},
]

# ─── ANIMATION DATA ────────────────────────────────────
# Step by step animation showing variable assignment
var anim_steps := [
	{"code": 'student_name = "Maria"', "var_index": 0, "filled": false},
	{"code": 'student_name = "Maria"', "var_index": 0, "filled": true},
	{"code": "year_level = 1",         "var_index": 1, "filled": true},
	{"code": "grade = 88.5",           "var_index": 2, "filled": true},
]

var current_anim_step: int = 0
var filled_vars: Array[bool] = [false, false, false]
var is_playing: bool = false
var play_timer: float = 0.0
const PLAY_INTERVAL: float = 1.2

# ─── UI NODES ──────────────────────────────────────────
var diagram_area: Control
var anim_area: Control
var code_label: Label
var play_btn: Button
var step_btn: Button
var reset_btn: Button

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)

	# ── DIAGRAM SECTION ──
	var diag_title := Label.new()
	diag_title.text = "📊 How Variables Work"
	diag_title.add_theme_color_override("font_color", Color("#00D4FF"))
	diag_title.add_theme_font_size_override("font_size", 15)
	layout.add_child(diag_title)

	diagram_area = Control.new()
	diagram_area.custom_minimum_size = Vector2(0, 140)
	diagram_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diagram_area.draw.connect(_draw_diagram)
	layout.add_child(diagram_area)

	# ── SEPARATOR ──
	var sep := HSeparator.new()
	layout.add_child(sep)

	# ── ANIMATION SECTION ──
	var anim_title := Label.new()
	anim_title.text = "🎬 Step-by-Step Animation"
	anim_title.add_theme_color_override("font_color", Color("#00D4FF"))
	anim_title.add_theme_font_size_override("font_size", 15)
	layout.add_child(anim_title)

	# Code line display
	code_label = Label.new()
	code_label.text = "Press Play or Step to begin"
	code_label.add_theme_color_override("font_color", Color("#FFB800"))
	code_label.add_theme_font_size_override("font_size", 14)
	code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(code_label)

	anim_area = Control.new()
	anim_area.custom_minimum_size = Vector2(0, 120)
	anim_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	anim_area.draw.connect(_draw_animation)
	layout.add_child(anim_area)

	# Controls
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(controls)

	play_btn  = _make_ctrl_btn("▶ Play",   Color("#00D4FF"))
	step_btn  = _make_ctrl_btn("⏭ Step",   Color("#00D4FF"))
	reset_btn = _make_ctrl_btn("↺ Reset",  Color("#FF3366"))

	controls.add_child(play_btn)
	controls.add_child(step_btn)
	controls.add_child(reset_btn)

	play_btn.pressed.connect(_on_play_pressed)
	step_btn.pressed.connect(_on_step_pressed)
	reset_btn.pressed.connect(_on_reset_pressed)

func _make_ctrl_btn(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(90, 36)
	var style := StyleBoxFlat.new()
	style.bg_color            = Color("#0A1628")
	style.border_color        = color
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_font_size_override("font_size", 13)
	return btn

# ─── DRAWING ───────────────────────────────────────────
func _draw_diagram() -> void:
	var area_size = diagram_area.size
	if area_size.x == 0:
		return

	var box_w    := 140.0
	var box_h    := 80.0
	var spacing  := 20.0
	var total_w  := (box_w * 3) + (spacing * 2)
	var start_x: float = (area_size.x - total_w) / 2.0
	var box_y: float   = (area_size.y - box_h) / 2.0

	for i in range(diagram_vars.size()):
		var v    = diagram_vars[i]
		var bx   = start_x + i * (box_w + spacing)

		# Box background
		diagram_area.draw_rect(
			Rect2(bx, box_y, box_w, box_h),
			COL_BOX
		)
		# Box border
		diagram_area.draw_rect(
			Rect2(bx, box_y, box_w, box_h),
			COL_BORDER, false, 1.5
		)

		# Variable name label above box
		var name_pos = Vector2(bx + box_w / 2, box_y - 20)
		diagram_area.draw_string(
			ThemeDB.fallback_font,
			name_pos - Vector2(v["name"].length() * 4, 0),
			v["name"],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1, 12,
			COL_LABEL
		)

		# Arrow pointing down into box
		diagram_area.draw_line(
			Vector2(bx + box_w / 2, box_y - 8),
			Vector2(bx + box_w / 2, box_y),
			COL_ARROW, 1.5
		)

		# Value inside box
		diagram_area.draw_string(
			ThemeDB.fallback_font,
			Vector2(bx + box_w / 2, box_y + box_h / 2 + 6)
				- Vector2(v["value"].length() * 5, 0),
			v["value"],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1, 16,
			COL_VALUE
		)

		# Type label bottom of box
		diagram_area.draw_string(
			ThemeDB.fallback_font,
			Vector2(bx + box_w / 2 - 10, box_y + box_h - 8),
			v["type"],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1, 10,
			COL_MUTED
		)

func _draw_animation() -> void:
	var area_size = anim_area.size
	if area_size.x == 0:
		return

	var box_w   := 140.0
	var box_h   := 70.0
	var spacing := 20.0
	var total_w := (box_w * 3) + (spacing * 2)
	var start_x: float = (area_size.x - total_w) / 2.0
	var box_y: float   = (area_size.y - box_h) / 2.0

	for i in range(diagram_vars.size()):
		var v  = diagram_vars[i]
		var bx = start_x + i * (box_w + spacing)

		# Highlight currently active box
		var is_active = (
			current_anim_step < anim_steps.size() and
			anim_steps[current_anim_step]["var_index"] == i
		)
		var border_col = Color("#FFB800") if is_active else COL_BORDER
		var box_col    = Color("#1A2A10") if (filled_vars.size() > i and filled_vars[i]) \
						 else COL_BOX

		anim_area.draw_rect(Rect2(bx, box_y, box_w, box_h), box_col)
		anim_area.draw_rect(Rect2(bx, box_y, box_w, box_h), border_col, false, 1.5)

		# Name label
		anim_area.draw_string(
			ThemeDB.fallback_font,
			Vector2(bx + box_w / 2, box_y - 18)
				- Vector2(v["name"].length() * 4, 0),
			v["name"],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1, 12,
			COL_LABEL
		)

		# Value — only show if filled
		if filled_vars.size() > i and filled_vars[i]:
			anim_area.draw_string(
				ThemeDB.fallback_font,
				Vector2(bx + box_w / 2, box_y + box_h / 2 + 6)
					- Vector2(v["value"].length() * 5, 0),
				v["value"],
				HORIZONTAL_ALIGNMENT_LEFT,
				-1, 16,
				COL_VALUE
			)
		else:
			# Empty indicator
			anim_area.draw_string(
				ThemeDB.fallback_font,
				Vector2(bx + box_w / 2 - 6, box_y + box_h / 2 + 6),
				"?",
				HORIZONTAL_ALIGNMENT_LEFT,
				-1, 20,
				COL_MUTED
			)

# ─── ANIMATION CONTROLS ────────────────────────────────
func _on_play_pressed() -> void:
	is_playing = !is_playing
	play_btn.text = "⏸ Pause" if is_playing else "▶ Play"

func _on_step_pressed() -> void:
	is_playing = false
	play_btn.text = "▶ Play"
	_advance_step()

func _on_reset_pressed() -> void:
	is_playing        = false
	play_btn.text     = "▶ Play"
	current_anim_step = 0
	filled_vars       = [false, false, false]
	code_label.text   = "Press Play or Step to begin"
	anim_area.queue_redraw()

func _advance_step() -> void:
	if current_anim_step >= anim_steps.size():
		is_playing    = false
		play_btn.text = "▶ Play"
		code_label.text = "✅ All variables assigned!"
		return

	var step = anim_steps[current_anim_step]
	code_label.text = "▶  " + step["code"]

	if step["filled"]:
		filled_vars[step["var_index"]] = true

	current_anim_step += 1
	anim_area.queue_redraw()

# ─── PROCESS (auto play) ───────────────────────────────
func _process(delta: float) -> void:
	if not is_playing:
		return
	play_timer += delta
	if play_timer >= PLAY_INTERVAL:
		play_timer = 0.0
		_advance_step()

# ─── FORCE REDRAW ON RESIZE ────────────────────────────
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if diagram_area:
			diagram_area.queue_redraw()
		if anim_area:
			anim_area.queue_redraw()
