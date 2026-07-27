extends "res://scripts/academy/VizBase.gd"

var _values_initial: Array = [29, 10, 14, 37, 13]
var _display: Array = [29, 10, 14, 37, 13]
var _i: int = -1
var _j: int = -1
var _min_idx: int = -1
var _phase: String = "scan"
var _sorted_to: int = 0

func get_steps() -> Array:
	return [
		{ "code": "arr = [29, 10, 14, 37, 13]" },
		{ "code": "Pass 1: min_idx = 0" },
		{ "code": "j=1: 10 < 29 -> new min!" },
		{ "code": "j=2: 14 < 10? no" },
		{ "code": "swap arr[0] <-> arr[1]" },
		{ "code": "Pass 2: min_idx = 1" },
		{ "code": "j=4: 13 < 14 -> new min!" },
		{ "code": "swap arr[1] <-> arr[4]" },
		{ "code": "Pass 4: swap arr[3] <-> arr[4]" },
		{ "code": "v sorted: [10, 13, 14, 29, 37]" },
	]

func get_concept_title() -> String:
	return "Concept: Select the minimum and swap it to the front"

func get_anim_title() -> String:
	return "Animation: One swap per pass"

func _set_step(idx: int) -> void:
	current_step = idx
	match idx:
		0: _display = [29, 10, 14, 37, 13]; _i = -1; _j = -1; _min_idx = -1; _phase = "init"; _sorted_to = 0
		1: _display = [29, 10, 14, 37, 13]; _i = 0; _j = 0; _min_idx = 0; _phase = "init_min"; _sorted_to = 0
		2: _display = [29, 10, 14, 37, 13]; _i = 0; _j = 1; _min_idx = 1; _phase = "new_min"; _sorted_to = 0
		3: _display = [29, 10, 14, 37, 13]; _i = 0; _j = 2; _min_idx = 1; _phase = "scan"; _sorted_to = 0
		4: _display = [10, 29, 14, 37, 13]; _i = 0; _j = -1; _min_idx = -1; _phase = "swap"; _sorted_to = 1
		5: _display = [10, 29, 14, 37, 13]; _i = 1; _j = 1; _min_idx = 1; _phase = "init_min"; _sorted_to = 1
		6: _display = [10, 29, 14, 37, 13]; _i = 1; _j = 4; _min_idx = 4; _phase = "new_min"; _sorted_to = 1
		7: _display = [10, 13, 14, 37, 29]; _i = 1; _j = -1; _min_idx = -1; _phase = "swap"; _sorted_to = 2
		8: _display = [10, 13, 14, 29, 37]; _i = 3; _j = -1; _min_idx = -1; _phase = "swap"; _sorted_to = 4
		9: _display = [10, 13, 14, 29, 37]; _i = -1; _j = -1; _min_idx = -1; _phase = "done"; _sorted_to = 5
	_anim_progress = 0.0
	_animating = true
	queue_redraw()

func _on_reset() -> void:
	_display = _values_initial.duplicate()
	super._on_reset()

func _draw_diagram() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + 12, _diagram_rect.position.y + _diagram_rect.size.y * 0.5), "Find min in unsorted part  â€¢  swap to front", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#FFB800"))

func _draw_anim() -> void:
	var n: int = _display.size()
	var max_val: int = 50
	var bar_w: float = 44.0
	var gap: float = 6.0
	var total_w: float = bar_w * n + gap * (n - 1)
	var start_x: float = _anim_rect.position.x + (_anim_rect.size.x - total_w) * 0.5
	var base_y: float = _anim_rect.position.y + _anim_rect.size.y * 0.85
	var max_h: float = _anim_rect.size.y * 0.55

	for i in n:
		var v: int = _display[i]
		var h: float = (float(v) / float(max_val)) * max_h
		var x: float = start_x + i * (bar_w + gap)
		var is_sorted: bool = i < _sorted_to
		var is_i: bool = i == _i
		var is_j: bool = i == _j
		var is_min: bool = i == _min_idx
		var color: Color = Color("#00FF88") if is_sorted else (Color("#FFB800") if is_min else (VizUtil.C_HIGHLIGHT if (is_i or is_j) else Color("#0D4A6A")))
		var border: Color = Color("#00FF88") if is_sorted else (Color("#FFB800") if (is_min or is_i or is_j) else Color("#2A4A6A"))
		var y_offset: float = 0.0
		if _phase == "swap" and (i == _i or i == _min_idx) and _anim_progress < 1.0:
			y_offset = -10.0 * sin(_anim_progress * PI)
		var r := Rect2(x, base_y - h + y_offset, bar_w, h)
		draw_rect(r, color, true)
		draw_rect(r, border, false, 2)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + bar_w * 0.5 - 4, r.position.y - 6), str(v), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#00FF88") if (is_sorted or is_min) else VizUtil.C_TEXT)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + bar_w * 0.5 - 2, base_y + 16), "[" + str(i) + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VizUtil.C_MUTED)

	if _min_idx >= 0 and _min_idx < n and _phase != "done":
		var mx: float = start_x + _min_idx * (bar_w + gap) + bar_w * 0.5
		draw_string(ThemeDB.fallback_font, Vector2(mx - 18, base_y - max_h - 18), "^ min", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#FFB800"))

	if _sorted_to > 0:
		draw_line(Vector2(start_x - 4, base_y - max_h - 30), Vector2(start_x + _sorted_to * (bar_w + gap) - gap, base_y - max_h - 30), Color("#00FF88"), 2)
		draw_string(ThemeDB.fallback_font, Vector2(start_x - 4, base_y - max_h - 36), "sorted", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#00FF88"))