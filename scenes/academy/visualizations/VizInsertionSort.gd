extends "res://scripts/academy/VizBase.gd"

var _values_initial: Array = [12, 11, 13, 5, 6]
var _display: Array = [12, 11, 13, 5, 6]
var _key: int = 0
var _key_index: int = -1
var _compare_idx: int = -1
var _phase: String = ""
var _sorted_to: int = 1

func get_steps() -> Array:
	return [
		{ "code": "arr = [12, 11, 13, 5, 6]" },
		{ "code": "key = arr[1] = 11" },
		{ "code": "shift arr[0] right" },
		{ "code": "insert key at 0" },
		{ "code": "key = arr[2] = 13 (no shift)" },
		{ "code": "key = arr[3] = 5" },
		{ "code": "shift 13, 12, 11 right" },
		{ "code": "insert key at 0" },
		{ "code": "key = arr[4] = 6, shift 13,12,11" },
		{ "code": "insert key at 1 -> sorted" },
	]

func get_concept_title() -> String:
	return "Concept: Insert each new element into its correct sorted position"

func get_anim_title() -> String:
	return "Animation: Pick key, shift, insert"

func _set_step(idx: int) -> void:
	current_step = idx
	match idx:
		0: _display = [12, 11, 13, 5, 6]; _key = 0; _key_index = -1; _compare_idx = -1; _phase = "init"; _sorted_to = 1
		1: _display = [12, 11, 13, 5, 6]; _key = 11; _key_index = 1; _compare_idx = -1; _phase = "pick"; _sorted_to = 1
		2: _display = [12, 11, 13, 5, 6]; _key = 11; _key_index = 1; _compare_idx = 0; _phase = "shift"; _sorted_to = 2
		3: _display = [11, 12, 13, 5, 6]; _key = 11; _key_index = 0; _compare_idx = -1; _phase = "insert"; _sorted_to = 2
		4: _display = [11, 12, 13, 5, 6]; _key = 13; _key_index = 2; _compare_idx = -1; _phase = "pick"; _sorted_to = 3
		5: _display = [11, 12, 13, 5, 6]; _key = 5; _key_index = 3; _compare_idx = -1; _phase = "pick"; _sorted_to = 3
		6: _display = [11, 12, 13, 5, 6]; _key = 5; _key_index = 3; _compare_idx = 2; _phase = "shift"; _sorted_to = 4
		7: _display = [5, 11, 12, 13, 6]; _key = 5; _key_index = 0; _compare_idx = -1; _phase = "insert"; _sorted_to = 4
		8: _display = [5, 11, 12, 13, 6]; _key = 6; _key_index = 4; _compare_idx = 3; _phase = "shift"; _sorted_to = 5
		9: _display = [5, 6, 11, 12, 13]; _key = 6; _key_index = 1; _compare_idx = -1; _phase = "insert"; _sorted_to = 5
	_anim_progress = 0.0
	_animating = true
	queue_redraw()

func _on_reset() -> void:
	_display = _values_initial.duplicate()
	super._on_reset()

func _draw_diagram() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + 12, _diagram_rect.position.y + _diagram_rect.size.y * 0.5), "Pick key  â€¢  shift larger right  â€¢  insert in place", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#FFB800"))

func _draw_anim() -> void:
	var n: int = _display.size()
	var max_val: int = 20
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
		var is_key: bool = i == _key_index and _phase != "done"
		var is_cmp: bool = i == _compare_idx
		var color: Color = Color("#00FF88") if is_sorted else (Color("#FFB800") if is_key else (VizUtil.C_HIGHLIGHT if is_cmp else Color("#0D4A6A")))
		var border: Color = Color("#00FF88") if is_sorted else (Color("#FFB800") if (is_key or is_cmp) else Color("#2A4A6A"))
		var y_offset: float = 0.0
		if is_key and _phase in ["pick", "shift"] and _anim_progress < 1.0:
			y_offset = -25.0
		var r := Rect2(x, base_y - h + y_offset, bar_w, h)
		draw_rect(r, color, true)
		draw_rect(r, border, false, 2)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + bar_w * 0.5 - 4, r.position.y - 6), str(v), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#00FF88") if is_sorted else Color("#FFB800") if is_key else VizUtil.C_TEXT)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + bar_w * 0.5 - 2, base_y + 16), "[" + str(i) + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VizUtil.C_MUTED)

	if _key_index >= 0 and _phase in ["pick", "shift"]:
		var kx: float = start_x + _key_index * (bar_w + gap) + bar_w * 0.5
		draw_string(ThemeDB.fallback_font, Vector2(kx - 20, base_y - max_h - 30), "key = " + str(_key), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#FFB800"))