extends "res://scripts/academy/VizBase.gd"

var _arr: Array = [2, 5, 8, 12, 16, 23, 38, 56]
var _target: int = 23
var _left: int = 0
var _right: int = 0
var _mid: int = -1
var _discarded: Array = []
var _found: bool = false

func get_steps() -> Array:
	return [
		{ "code": "arr=[2,5,8,12,16,23,38,56] target=23" },
		{ "code": "left=0,right=7->mid=3,arr[3]=12<23" },
		{ "code": "left=4,right=7->mid=5,arr[5]=23 v" },
		{ "code": "Found at index 5" },
	]

func get_concept_title() -> String:
	return "Concept: Halve the range each step â€” only works on sorted arrays"

func get_anim_title() -> String:
	return "Animation: Watch the search range shrink"

func _set_step(idx: int) -> void:
	current_step = idx
	match idx:
		0: _left = 0; _right = 7; _mid = -1; _discarded = []; _found = false
		1: _left = 0; _right = 7; _mid = 3; _discarded = [0, 1, 2, 3]; _found = false
		2: _left = 4; _right = 7; _mid = 5; _discarded = []; _found = true
		3: _left = 4; _right = 7; _mid = 5; _discarded = []; _found = true
	_anim_progress = 0.0
	_animating = true
	queue_redraw()

func _draw_diagram() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + 12, _diagram_rect.position.y + _diagram_rect.size.y * 0.5), "Sort once, then halve the range each step  â€¢  O(log n)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#FFB800"))

func _draw_anim() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(_anim_rect.position.x + 20, _anim_rect.position.y + 20), "target = " + str(_target), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#00FF88"))

	var n: int = _arr.size()
	var cell_w: float = 52.0
	var cell_h: float = 70.0
	var gap: float = 6.0
	var total_w: float = cell_w * n + gap * (n - 1)
	var start_x: float = _anim_rect.position.x + (_anim_rect.size.x - total_w) * 0.5
	var cy: float = _anim_rect.position.y + _anim_rect.size.y * 0.5
	for i in n:
		var r := Rect2(start_x + i * (cell_w + gap), cy, cell_w, cell_h)
		var in_range: bool = i >= _left and i <= _right
		var is_mid: bool = i == _mid
		var is_discarded: bool = i in _discarded
		var is_found: bool = is_mid and _found
		var color: Color
		if is_found: color = Color("#00FF88")
		elif is_mid: color = Color("#FFB800")
		elif is_discarded or not in_range: color = Color("#0A0F1A")
		elif in_range: color = Color("#003D66")
		else: color = Color("#0D2040")
		draw_rect(r, color, true)
		var border: Color = Color("#00FF88") if is_found else (Color("#FFB800") if is_mid else (Color("#2A4A6A") if in_range else Color("#1A2030")))
		draw_rect(r, border, false, 2.5 if (is_mid or is_found) else 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 8, r.position.y - 5), "[" + str(i) + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_MUTED)
		var text_color: Color = VizUtil.C_BG if (is_mid or is_found) else (Color("#445566") if not in_range else VizUtil.C_TEXT)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + cell_w * 0.5 - 4, r.position.y + 44), str(_arr[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, text_color)

	if _mid >= 0:
		var mid_x: float = start_x + _mid * (cell_w + gap) + cell_w * 0.5
		draw_string(ThemeDB.fallback_font, Vector2(mid_x - 18, cy + cell_h + 20), "^ mid", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#FFB800"))
		var left_x: float = start_x + _left * (cell_w + gap) + cell_w * 0.5
		var right_x: float = start_x + _right * (cell_w + gap) + cell_w * 0.5
		draw_line(Vector2(left_x, cy - 24), Vector2(left_x, cy - 12), Color("#00D4FF"), 2)
		draw_line(Vector2(left_x, cy - 12), Vector2(right_x, cy - 12), Color("#00D4FF"), 2)
		draw_line(Vector2(right_x, cy - 12), Vector2(right_x, cy - 24), Color("#00D4FF"), 2)
		draw_string(ThemeDB.fallback_font, Vector2((left_x + right_x) * 0.5 - 22, cy - 30), "range [" + str(_left) + ".." + str(_right) + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_HIGHLIGHT)