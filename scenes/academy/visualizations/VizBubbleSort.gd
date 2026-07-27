extends "res://scripts/academy/VizBase.gd"

var _values_initial: Array = [5, 3, 8, 1]
var _display: Array = [5, 3, 8, 1]
var _j: int = -1
var _swap: bool = false
var _sorted_from: int = 4

func get_steps() -> Array:
	return [
		{ "code": "arr = [5, 3, 8, 1]" },
		{ "code": "j=0: 5 > 3? -> swap -> [3, 5, 8, 1]" },
		{ "code": "j=1: 5 > 8? no swap" },
		{ "code": "j=2: 8 > 1? -> swap -> [3, 5, 1, 8]" },
		{ "code": "Pass 2: j=0: 3 > 5? no" },
		{ "code": "j=1: 5 > 1? -> swap -> [3, 1, 5, 8]" },
		{ "code": "Pass 3: j=0: 3 > 1? -> swap -> [1, 3, 5, 8]" },
		{ "code": "v sorted: [1, 3, 5, 8]" },
	]

func get_concept_title() -> String:
	return "Concept: Compare adjacent pairs â€” largest bubbles to the end each pass"

func get_anim_title() -> String:
	return "Animation: Watch comparisons and swaps"

func _set_step(idx: int) -> void:
	current_step = idx
	match idx:
		0: _display = [5, 3, 8, 1]; _j = -1; _swap = false; _sorted_from = 4
		1: _display = [3, 5, 8, 1]; _j = 0; _swap = true; _sorted_from = 4
		2: _display = [3, 5, 8, 1]; _j = 1; _swap = false; _sorted_from = 4
		3: _display = [3, 5, 1, 8]; _j = 2; _swap = true; _sorted_from = 4
		4: _display = [3, 5, 1, 8]; _j = 0; _swap = false; _sorted_from = 3
		5: _display = [3, 1, 5, 8]; _j = 1; _swap = true; _sorted_from = 3
		6: _display = [1, 3, 5, 8]; _j = 0; _swap = true; _sorted_from = 2
		7: _display = [1, 3, 5, 8]; _j = -1; _swap = false; _sorted_from = 0
	_anim_progress = 0.0
	_animating = true
	queue_redraw()

func _on_reset() -> void:
	_display = _values_initial.duplicate()
	super._on_reset()

func _draw_diagram() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + 12, _diagram_rect.position.y + _diagram_rect.size.y * 0.5), "Compare adjacent bars  â€¢  swap if left > right", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#FFB800"))

func _draw_anim() -> void:
	var n: int = _display.size()
	var max_val: int = 10
	var bar_w: float = 50.0
	var gap: float = 8.0
	var total_w: float = bar_w * n + gap * (n - 1)
	var start_x: float = _anim_rect.position.x + (_anim_rect.size.x - total_w) * 0.5
	var base_y: float = _anim_rect.position.y + _anim_rect.size.y * 0.85
	var max_h: float = _anim_rect.size.y * 0.6

	for i in n:
		var v: int = _display[i]
		var h: float = (float(v) / float(max_val)) * max_h
		var x: float = start_x + i * (bar_w + gap)
		var is_j: bool = i == _j
		var is_j1: bool = i == _j + 1
		var is_sorted: bool = i >= _sorted_from

		var y_offset: float = 0.0
		if is_j and _swap and _anim_progress < 1.0:
			y_offset = -8.0 * sin(_anim_progress * PI)
		elif is_j1 and _swap and _anim_progress < 1.0:
			y_offset = 8.0 * sin(_anim_progress * PI)

		var r := Rect2(x, base_y - h + y_offset, bar_w, h)
		var color: Color = Color("#00FF88") if is_sorted else (VizUtil.C_HIGHLIGHT if (is_j or is_j1) else Color("#0D4A6A"))
		var border: Color = Color("#00FF88") if is_sorted else (Color("#FFB800") if (is_j or is_j1) else Color("#2A4A6A"))
		draw_rect(r, color, true)
		draw_rect(r, border, false, 2)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + bar_w * 0.5 - 4, r.position.y - 6), str(v), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#00FF88") if (is_j or is_j1 or is_sorted) else VizUtil.C_TEXT)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + bar_w * 0.5 - 4, base_y + 16), "[" + str(i) + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_MUTED)

	if _j >= 0 and _anim_progress < 1.0 and not _swap:
		var j_x: float = start_x + _j * (bar_w + gap) + bar_w * 0.5
		var j1_x: float = start_x + (_j + 1) * (bar_w + gap) + bar_w * 0.5
		draw_line(Vector2(j_x, base_y - max_h - 30), Vector2(j1_x, base_y - max_h - 30), VizUtil.C_WARN, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2((j_x + j1_x) * 0.5 - 22, base_y - max_h - 36), "compare", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, VizUtil.C_WARN)