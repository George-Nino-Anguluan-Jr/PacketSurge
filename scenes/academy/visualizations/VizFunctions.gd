extends "res://scripts/academy/VizBase.gd"

var _input_val: int = 0
var _output_val: int = 0
var _show_output: bool = false

func get_steps() -> Array:
	return [
		{ "code": "def double(n): return n * 2" },
		{ "code": "print(double(4))" },
		{ "code": "print(double(10))" },
		{ "code": "print(double(0))" },
	]

func get_concept_title() -> String:
	return "Concept: A function takes input, does work, returns output"

func get_anim_title() -> String:
	return "Animation: Pass different inputs to double()"

func _set_step(idx: int) -> void:
	current_step = idx
	match idx:
		0: _input_val = 0; _output_val = 0; _show_output = false
		1: _input_val = 4; _output_val = 8; _show_output = true
		2: _input_val = 10; _output_val = 20; _show_output = true
		3: _input_val = 0; _output_val = 0; _show_output = true
	_anim_progress = 0.0
	_animating = true
	queue_redraw()

func _draw_diagram() -> void:
	var cy: float = _diagram_rect.position.y + _diagram_rect.size.y * 0.5
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + 20, cy + 5), "input ->", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_MUTED)
	var r := Rect2(_diagram_rect.position.x + 120, cy - 25, 180, 50)
	draw_rect(r, Color("#00D4FF"), true)
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 18, r.position.y + 32), "def double(n):", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_BG)
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + r.size.x + 14, cy + 5), "-> output", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_MUTED)

func _draw_anim() -> void:
	var in_r := Rect2(_anim_rect.position.x + _anim_rect.size.x * 0.04, _anim_rect.position.y + _anim_rect.size.y * 0.3, 110, 70)
	draw_rect(in_r, VizUtil.C_PANEL, true)
	draw_rect(in_r, Color("#FFB800"), false, 2.5)
	draw_string(ThemeDB.fallback_font, Vector2(in_r.position.x + 10, in_r.position.y + 18), "input", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_MUTED)
	draw_string(ThemeDB.fallback_font, Vector2(in_r.position.x + 10, in_r.position.y + 52), str(_input_val), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#FFB800"))

	var ball_t: float = _anim_progress if _animating else 1.0
	var a_from := Vector2(in_r.position.x + in_r.size.x, in_r.position.y + in_r.size.y * 0.5)
	var a_to := Vector2(_anim_rect.position.x + _anim_rect.size.x * 0.4, _anim_rect.position.y + _anim_rect.size.y * 0.5)
	draw_line(a_from, a_to, VizUtil.C_HIGHLIGHT, 2)
	if _anim_progress < 0.5 and _show_output:
		var p = a_from.lerp(a_to, ball_t * 2.0)
		draw_circle(p, 6, Color("#FFB800"))
	VizUtil.draw_arrow(self, a_from, a_to, VizUtil.C_HIGHLIGHT, 8)

	var fn_r := Rect2(_anim_rect.position.x + _anim_rect.size.x * 0.4, _anim_rect.position.y + _anim_rect.size.y * 0.4, _anim_rect.size.x * 0.2, _anim_rect.size.y * 0.2)
	draw_rect(fn_r, Color("#00D4FF"), true)
	draw_string(ThemeDB.fallback_font, Vector2(fn_r.position.x + 12, fn_r.position.y + 30), "def", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_BG)
	draw_string(ThemeDB.fallback_font, Vector2(fn_r.position.x + 12, fn_r.position.y + 55), "double(n)", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, VizUtil.C_BG)
	draw_string(ThemeDB.fallback_font, Vector2(fn_r.position.x + 12, fn_r.position.y + 80), "return n*2", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, VizUtil.C_BG)

	var b_from := Vector2(fn_r.position.x + fn_r.size.x, fn_r.position.y + fn_r.size.y * 0.5)
	var b_to := Vector2(_anim_rect.position.x + _anim_rect.size.x * 0.7, _anim_rect.position.y + _anim_rect.size.y * 0.5)
	draw_line(b_from, b_to, VizUtil.C_HIGHLIGHT, 2)
	if _anim_progress >= 0.5 and _show_output:
		var p2 = b_from.lerp(b_to, (ball_t - 0.5) * 2.0)
		draw_circle(p2, 6, Color("#00FF88"))
	VizUtil.draw_arrow(self, b_from, b_to, VizUtil.C_HIGHLIGHT, 8)

	var out_r := Rect2(_anim_rect.position.x + _anim_rect.size.x * 0.7, _anim_rect.position.y + _anim_rect.size.y * 0.3, 130, 70)
	draw_rect(out_r, VizUtil.C_PANEL, true)
	draw_rect(out_r, Color("#00FF88"), false, 2.5)
	draw_string(ThemeDB.fallback_font, Vector2(out_r.position.x + 10, out_r.position.y + 18), "return", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_MUTED)
	var output_alpha: float = 1.0
	if _show_output and _anim_progress < 1.0:
		output_alpha = max(0.0, (_anim_progress - 0.5) * 2.0)
	var out_col: Color = Color("#00FF88")
	out_col.a = output_alpha
	draw_string(ThemeDB.fallback_font, Vector2(out_r.position.x + 10, out_r.position.y + 52), str(_output_val), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, out_col)