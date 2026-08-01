extends "res://scripts/academy/VizBase.gd"

var _counter: int = 0
var _output_lines: Array = []

func get_steps() -> Array:
	return [
		{ "code": "i = 0  →  print(i)" },
		{ "code": "i = 1  →  print(i)" },
		{ "code": "i = 2  →  print(i)" },
		{ "code": "i = 3  →  print(i)" },
		{ "code": "i = 4  →  print(i)" },
		{ "code": "Loop finished." },
	]

func get_concept_title() -> String:
	return "Concept: A loop runs the same code multiple times"

func get_anim_title() -> String:
	return "Animation: Loop through 5 iterations"

func _set_step(idx: int) -> void:
	current_step = idx
	_counter = idx
	if idx < 5:
		_output_lines.append(str(idx))
		_anim_progress = 0.0
		_animating = true
	else:
		_animating = false
	queue_redraw()

func _on_reset() -> void:
	_output_lines.clear()
	super._on_reset()

func _draw_diagram() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + 12, _diagram_rect.position.y + 22), "for i in range(5):", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#FFB800"))
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + 28, _diagram_rect.position.y + 44), "print(i)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_TEXT)

func _draw_anim() -> void:
	var box_w: float = 140.0
	var box_h: float = 100.0
	var cx: float = _anim_rect.position.x + _anim_rect.size.x * 0.25
	var cy: float = _anim_rect.position.y + _anim_rect.size.y * 0.4
	var r := Rect2(cx - box_w * 0.5, cy - box_h * 0.5, box_w, box_h)
	draw_rect(r, VizUtil.C_PANEL, true)
	draw_rect(r, VizUtil.C_HIGHLIGHT, false, 2.5)
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 10, r.position.y + 22), "i =", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, VizUtil.C_MUTED)
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 50, r.position.y + 56), str(_counter), HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color("#00FF88"))

	var dot_x: float = _anim_rect.position.x + _anim_rect.size.x * 0.45
	var dot_y: float = _anim_rect.position.y + _anim_rect.size.y * 0.2
	draw_string(ThemeDB.fallback_font, Vector2(dot_x, dot_y - 6), "iterations", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_MUTED)
	for i in 5:
		var filled := i < _counter
		var dr := Rect2(dot_x + i * 26, dot_y + 6, 20, 20)
		draw_rect(dr, Color("#00FF88") if filled else VizUtil.C_PANEL, true)
		draw_rect(dr, Color("#00FF88") if filled else Color("#2A4A6A"), false, 1.5)

	var con_x: float = _anim_rect.position.x + _anim_rect.size.x * 0.55
	var con_y: float = _anim_rect.position.y + _anim_rect.size.y * 0.1
	var con_w: float = _anim_rect.size.x * 0.4
	var con_h: float = _anim_rect.size.y * 0.8
	var con_r := Rect2(con_x, con_y, con_w, con_h)
	draw_rect(con_r, VizUtil.C_PANEL, true)
	draw_rect(con_r, VizUtil.C_HIGHLIGHT, false, 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(con_r.position.x + 8, con_r.position.y + 16), "output", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_MUTED)
	for i in _output_lines.size():
		var line: String = _output_lines[i]
		var is_new := i == _output_lines.size() - 1 and _animating
		var alpha: float = 1.0
		if is_new:
			alpha = _anim_progress
		var line_col: Color = VizUtil.C_VAL
		line_col.a = alpha
		draw_string(ThemeDB.fallback_font, Vector2(con_r.position.x + 12, con_r.position.y + 38 + i * 22), "> " + line, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, line_col)
