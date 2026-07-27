extends "res://scripts/academy/VizBase.gd"

var _arr: Array = [9, 2, 7, 4, 1]
var _target: int = 7
var _i: int = -1
var _found: bool = false
var _scanned: Array = []

func get_steps() -> Array:
	return [
		{ "code": "arr = [9,2,7,4,1], target = 7" },
		{ "code": "i=0: 9 != 7" },
		{ "code": "i=1: 2 != 7" },
		{ "code": "i=2: 7 == 7 v" },
		{ "code": "Found at index 2" },
	]

func get_concept_title() -> String:
	return "Concept: Check each item one by one until found (O(n))"

func get_anim_title() -> String:
	return "Animation: Scan left to right"

func _set_step(idx: int) -> void:
	current_step = idx
	match idx:
		0: _i = -1; _found = false; _scanned = []
		1: _i = 0; _found = false; _scanned = [0]
		2: _i = 1; _found = false; _scanned = [0, 1]
		3: _i = 2; _found = true; _scanned = [0, 1, 2]
		4: _i = 2; _found = true; _scanned = [0, 1, 2, 3, 4]
	_anim_progress = 0.0
	_animating = true
	queue_redraw()

func _draw_diagram() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + 12, _diagram_rect.position.y + _diagram_rect.size.y * 0.5), "Check each item one by one until you find the target", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#FFB800"))

func _draw_anim() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(_anim_rect.position.x + 20, _anim_rect.position.y + 20), "target = " + str(_target), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#00FF88"))

	var n: int = _arr.size()
	var cell_w: float = 56.0
	var cell_h: float = 70.0
	var gap: float = 6.0
	var total_w: float = cell_w * n + gap * (n - 1)
	var start_x: float = _anim_rect.position.x + (_anim_rect.size.x - total_w) * 0.5
	var cy: float = _anim_rect.position.y + _anim_rect.size.y * 0.5
	for i in n:
		var r := Rect2(start_x + i * (cell_w + gap), cy, cell_w, cell_h)
		var is_current: bool = i == _i
		var is_scanned: bool = i in _scanned
		var is_found: bool = is_current and _found
		var beam_alpha: float = 0.0
		if is_current and _anim_progress < 1.0:
			beam_alpha = (sin(_anim_progress * 8.0) * 0.5 + 0.5) * 0.4 + 0.3
		var color: Color
		if is_found: color = Color("#00FF88")
		elif is_current: color = Color("#FFB800")
		elif is_scanned: color = Color("#1A4A6A")
		else: color = Color("#0D2040")
		draw_rect(r, color, true)
		var border: Color = Color("#00FF88") if is_found else (Color("#FFB800") if is_current else Color("#2A4A6A"))
		draw_rect(r, border, false, 2.5 if is_current or is_found else 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 8, r.position.y - 5), "[" + str(i) + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_MUTED)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + cell_w * 0.5 - 4, r.position.y + 44), str(_arr[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, VizUtil.C_BG if (is_current or is_found) else VizUtil.C_TEXT)
		if is_current and not _found:
			draw_string(ThemeDB.fallback_font, Vector2(r.position.x + cell_w * 0.5 - 12, r.position.y + cell_h + 20), "^ check", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#FFB800"))

	if _found and current_step == get_steps().size() - 1:
		draw_string(ThemeDB.fallback_font, Vector2(_anim_rect.position.x + _anim_rect.size.x * 0.5 - 60, _anim_rect.position.y + _anim_rect.size.y * 0.92), "Found at index " + str(_i), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#00FF88"))