extends "res://scripts/academy/VizBase.gd"

var _value: int = 0
var _active_branch: int = -1

func get_steps() -> Array:
	return [
		{ "code": "temp = 30" },
		{ "code": "if temp > 35: ..." },
		{ "code": "elif temp > 25: print(\"Warm\")" },
		{ "code": "temp = 40 â€” Very hot!" },
		{ "code": "temp = 10 â€” Cold" },
	]

func get_concept_title() -> String:
	return "Concept: Conditions run different code based on True/False"

func get_anim_title() -> String:
	return "Animation: Test different temperatures"

func _set_step(idx: int) -> void:
	current_step = idx
	match idx:
		0: _value = 30; _active_branch = -1
		1: _value = 30; _active_branch = 0
		2: _value = 30; _active_branch = 1
		3: _value = 40; _active_branch = 0
		4: _value = 10; _active_branch = 3
	_anim_progress = 0.0
	_animating = true
	queue_redraw()

func _draw_diagram() -> void:
	var cx: float = _diagram_rect.position.x + _diagram_rect.size.x * 0.2
	var cy: float = _diagram_rect.position.y + _diagram_rect.size.y * 0.5
	draw_string(ThemeDB.fallback_font, Vector2(cx - 30, cy + 5), "if/elif/else", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#FFB800"))
	draw_line(Vector2(cx + 50, cy), Vector2(_diagram_rect.position.x + _diagram_rect.size.x * 0.95, cy), VizUtil.C_HIGHLIGHT, 1.5)
	draw_line(Vector2(_diagram_rect.position.x + _diagram_rect.size.x * 0.6, cy), Vector2(_diagram_rect.position.x + _diagram_rect.size.x * 0.6, _diagram_rect.position.y + _diagram_rect.size.y * 0.2), VizUtil.C_HIGHLIGHT, 1.5)
	draw_line(Vector2(_diagram_rect.position.x + _diagram_rect.size.x * 0.6, cy), Vector2(_diagram_rect.position.x + _diagram_rect.size.x * 0.6, _diagram_rect.position.y + _diagram_rect.size.y * 0.8), VizUtil.C_HIGHLIGHT, 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + _diagram_rect.size.x * 0.62, _diagram_rect.position.y + _diagram_rect.size.y * 0.18), "True", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#00FF88"))
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + _diagram_rect.size.x * 0.62, _diagram_rect.position.y + _diagram_rect.size.y * 0.82), "False", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#FF3366"))

func _draw_anim() -> void:
	var cx: float = _anim_rect.position.x + _anim_rect.size.x * 0.18
	var cy: float = _anim_rect.position.y + _anim_rect.size.y * 0.4
	var dr := Rect2(cx - 60, cy - 40, 120, 80)
	draw_rect(dr, VizUtil.C_PANEL, true)
	draw_rect(dr, VizUtil.C_HIGHLIGHT, false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(dr.position.x + 14, dr.position.y + 26), "temp =", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_MUTED)
	draw_string(ThemeDB.fallback_font, Vector2(dr.position.x + 60, dr.position.y + 50), str(_value), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#00FF88"))

	var bx: float = _anim_rect.position.x + _anim_rect.size.x * 0.45
	var by: float = _anim_rect.position.y + _anim_rect.size.y * 0.08
	var bw: float = _anim_rect.size.x * 0.5
	var bh: float = 60.0
	var labels := ["temp > 35:  Very hot!", "temp > 25:  Warm", "temp > 15:  Cool", "else:        Cold"]
	var match_idx: int = -1
	if _value > 35: match_idx = 0
	elif _value > 25: match_idx = 1
	elif _value > 15: match_idx = 2
	else: match_idx = 3

	for i in 4:
		var r := Rect2(bx, by + i * (bh + 8), bw, bh)
		var is_match := i == match_idx and _active_branch >= 0
		var bg := Color("#0D2040") if is_match else VizUtil.C_PANEL
		var border := Color("#00FF88") if is_match else Color("#2A4A6A")
		draw_rect(r, bg, true)
		draw_rect(r, border, false, 2)
		draw_line(Vector2(cx + 60, cy), Vector2(r.position.x, r.position.y + r.size.y * 0.5), Color("#2A4A6A"), 1.5)
		var alpha: float = 1.0
		if is_match and _animating:
			alpha = _anim_progress
		var lbl_col: Color = Color("#00FF88") if is_match else VizUtil.C_TEXT
		lbl_col.a = alpha
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 12, r.position.y + 28), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, lbl_col)
		if is_match:
			var taken_col: Color = Color("#00FF88")
			taken_col.a = alpha
			draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 12, r.position.y + 50), "v  taken", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, taken_col)