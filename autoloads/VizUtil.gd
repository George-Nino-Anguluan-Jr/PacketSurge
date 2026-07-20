extends Node

const C_LABEL := Color("#FFB800")
const C_VAL := Color("#00FF88")
const C_TEXT := Color("#E8F4FD")
const C_MUTED := Color("#4A7FA5")
const C_SWAP := Color("#FF3366")
const C_HIGHLIGHT := Color("#00D4FF")
const C_WARN := Color("#FF8844")

const C_BG := Color("#080F1E")
const C_PANEL := Color("#0D2040")

const MAX_BAR_H := 300.0
const MIN_BAR_H := 30.0
const BAR_W := 54.0
const BAR_GAP := 6.0

static func make_btn(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(90, 36)
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#0A1628"); s.border_color = color
	s.border_width_left = 1; s.border_width_right = 1
	s.border_width_top = 1; s.border_width_bottom = 1
	s.corner_radius_top_left = 6; s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6; s.corner_radius_bottom_right = 6
	s.bg_color = Color("#0D2040")
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_font_size_override("font_size", 13)
	return btn

static func standard_ui(parent: Control, title: String, diag_h: float, anim_h: float) -> Dictionary:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(layout)

	var dt := Label.new()
	dt.text = title
	dt.add_theme_color_override("font_color", C_LABEL)
	dt.add_theme_font_size_override("font_size", 15)
	layout.add_child(dt)

	var da := Control.new()
	da.custom_minimum_size = Vector2(0, diag_h)
	da.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(da)
	layout.add_child(HSeparator.new())

	var at := Label.new()
	at.text = "Step-by-Step Animation"
	at.add_theme_color_override("font_color", C_LABEL)
	at.add_theme_font_size_override("font_size", 14)
	layout.add_child(at)

	var cl := Label.new()
	cl.text = "Press ▶ Play or ⏭ Step to begin"
	cl.add_theme_color_override("font_color", C_LABEL)
	cl.add_theme_font_size_override("font_size", 13)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(cl)

	var aa := Control.new()
	aa.custom_minimum_size = Vector2(0, anim_h)
	aa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(aa)

	var ctrl := HBoxContainer.new()
	ctrl.add_theme_constant_override("separation", 8)
	ctrl.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(ctrl)

	return { "diagram": da, "anim": aa, "code": cl, "controls": ctrl }

static func draw_arr_box(canvas: Control, r: Rect2, val, index: int, border: Color, fill: Color, font: Font):
	canvas.draw_rect(r, fill)
	canvas.draw_rect(r, border, false, 1.5)
	canvas.draw_string(font, Vector2(r.position.x + 4, r.position.y - 6), "[" + str(index) + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, C_MUTED)
	canvas.draw_string(font, Vector2(r.position.x + r.size.x * 0.5 - 8, r.position.y + r.size.y * 0.5 + 6), str(val), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, C_TEXT)

static func draw_arrow(canvas: Control, from: Vector2, to: Vector2, color: Color, head: float = 10.0):
	canvas.draw_line(from, to, color, 2.0)
	var dir = (to - from).normalized()
	var perp = Vector2(-dir.y, dir.x)
	var tip = to
	var p1 = tip - dir * head + perp * head * 0.4
	var p2 = tip - dir * head - perp * head * 0.4
	canvas.draw_line(tip, p1, color, 2.0)
	canvas.draw_line(tip, p2, color, 2.0)

static func draw_pointer(canvas: Control, tip: Vector2, label: String, color: Color, font: Font):
	draw_arrow(canvas, tip + Vector2(0, 28), tip, color, 6)
	canvas.draw_string(font, Vector2(tip.x - 16, tip.y + 44), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)

static func draw_labeled_box(canvas: Control, r: Rect2, label: String, val: String, border: Color, font: Font):
	canvas.draw_rect(r, Color(border, 0.1))
	canvas.draw_rect(r, border, false, 1.5)
	canvas.draw_string(font, Vector2(r.position.x + 6, r.position.y + 14), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, C_MUTED)
	canvas.draw_string(font, Vector2(r.position.x + 6, r.position.y + r.size.y - 8), val, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, C_TEXT)

static func lerp_color(a: Color, b: Color, t: float) -> Color:
	return Color(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t)
