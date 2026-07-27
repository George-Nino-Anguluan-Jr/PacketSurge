extends "res://scripts/academy/VizBase.gd"

var _values: Array = [5, 10, 25, 42]
var _current_index: int = -1

func get_steps() -> Array:
	return [
		{ "code": "current = node1" },
		{ "code": "current = node2" },
		{ "code": "current = node3" },
		{ "code": "current = node4" },
		{ "code": "current = None -> done" },
	]

func get_concept_title() -> String:
	return "Concept: Nodes connected by next-pointers (chain of clues)"

func get_anim_title() -> String:
	return "Animation: Walk the chain from head to tail"

func _set_step(idx: int) -> void:
	current_step = idx
	_current_index = idx if idx < 4 else -1
	_anim_progress = 0.0
	_animating = true
	queue_redraw()

func _draw_diagram() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + 12, _diagram_rect.position.y + 16), "Node = [ value | next ]  ->", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#FFB800"))
	var cy: float = _diagram_rect.position.y + _diagram_rect.size.y * 0.7
	var x: float = _diagram_rect.position.x + 60.0
	for i in 3:
		var r := Rect2(x, cy, 80, 30)
		draw_rect(r, Color("#0D4A6A"), true)
		draw_rect(r, Color("#00D4FF"), false, 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 8, r.position.y + 20), str(5 + i * 10), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, VizUtil.C_TEXT)
		x += 90

func _draw_anim() -> void:
	var n: int = _values.size()
	var node_w: float = 110.0
	var node_h: float = 70.0
	var gap: float = 60.0
	var total_w: float = node_w * n + gap * (n - 1)
	var start_x: float = _anim_rect.position.x + (_anim_rect.size.x - total_w) * 0.5
	var cy: float = _anim_rect.position.y + _anim_rect.size.y * 0.4

	draw_string(ThemeDB.fallback_font, Vector2(start_x - 60, cy + 8), "HEAD ->", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#00FF88"))
	draw_string(ThemeDB.fallback_font, Vector2(start_x + total_w - 20, cy + 8), "-> None", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#FF3366"))

	for i in n - 1:
		var a_from := Vector2(start_x + (i + 1) * node_w + i * gap, cy + node_h * 0.5)
		var a_to := Vector2(start_x + (i + 1) * (node_w + gap), cy + node_h * 0.5)
		var a_color: Color = Color("#2A4A6A")
		if i < _current_index:
			a_color = Color("#00FF88")
		elif i == _current_index:
			a_color = VizUtil.C_HIGHLIGHT
		draw_line(a_from, a_to, a_color, 2.5)
		VizUtil.draw_arrow(self, a_from, a_to, a_color, 8)

	for i in n:
		var r := Rect2(start_x + i * (node_w + gap), cy, node_w, node_h)
		var is_current: bool = i == _current_index
		var is_visited: bool = i < _current_index
		var alpha: float = 1.0
		if is_current and _anim_progress < 1.0:
			alpha = 0.4 + 0.6 * (sin(_anim_progress * 12.0) * 0.5 + 0.5)
		var bg: Color = Color("#003D66") if is_visited or is_current else VizUtil.C_PANEL
		var border: Color = Color("#00FF88") if is_visited or is_current else Color("#2A4A6A")
		bg.a = alpha
		border.a = alpha
		var val_col: Color = Color("#00FF88") if (is_current or is_visited) else VizUtil.C_TEXT
		val_col.a = alpha
		var next_col: Color = Color("#00FF88") if (is_current or is_visited) else VizUtil.C_TEXT
		next_col.a = alpha
		draw_rect(r, bg, true)
		draw_rect(r, border, false, 2.5 if is_current or is_visited else 1.5)
		var val_r := Rect2(r.position.x, r.position.y, node_w * 0.55, node_h)
		var val_bg: Color = Color(border, 0.3)
		val_bg.a = alpha
		draw_rect(val_r, val_bg, true)
		draw_string(ThemeDB.fallback_font, Vector2(val_r.position.x + 12, val_r.position.y + 28), "val", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VizUtil.C_MUTED)
		draw_string(ThemeDB.fallback_font, Vector2(val_r.position.x + 12, val_r.position.y + 56), str(_values[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, val_col)
		draw_line(Vector2(r.position.x + node_w * 0.55, r.position.y), Vector2(r.position.x + node_w * 0.55, r.position.y + node_h), border, 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + node_w * 0.6, r.position.y + 18), "next", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VizUtil.C_MUTED)
		var next_text: String
		if i < n - 1:
			next_text = "-> n" + str(i + 2)
		else:
			next_text = "None"
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + node_w * 0.6, r.position.y + 50), next_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, next_col)