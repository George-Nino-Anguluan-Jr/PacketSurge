extends "res://scripts/academy/VizBase.gd"

var _arr: Array = [3, 1, 2, 1]
var _counts: Array = [0, 0, 0, 0]
var _highlight_input: int = -1
var _highlight_count: int = -1
var _output: Array = []

func get_steps() -> Array:
	return [
		{ "code": "arr = [3,1,2,1], count = [0,0,0,0]" },
		{ "code": "arr[0]=3 -> count[3]++" },
		{ "code": "arr[1]=1 -> count[1]++" },
		{ "code": "arr[2]=2 -> count[2]++" },
		{ "code": "arr[3]=1 -> count[1]++" },
		{ "code": "result: [1, 1, 2, 3] v" },
	]

func get_concept_title() -> String:
	return "Concept: Count occurrences of each value, rebuild sorted output"

func get_anim_title() -> String:
	return "Animation: Tally then place"

func _set_step(idx: int) -> void:
	current_step = idx
	match idx:
		0: _highlight_input = -1; _highlight_count = -1; _counts = [0, 0, 0, 0]; _output = []
		1: _highlight_input = 0; _highlight_count = 3; _counts = [0, 0, 0, 1]; _output = []
		2: _highlight_input = 1; _highlight_count = 1; _counts = [0, 1, 0, 1]; _output = []
		3: _highlight_input = 2; _highlight_count = 2; _counts = [0, 1, 1, 1]; _output = []
		4: _highlight_input = 3; _highlight_count = 1; _counts = [0, 2, 1, 1]; _output = []
		5: _highlight_input = -1; _highlight_count = -1; _counts = [0, 2, 1, 1]; _output = [1, 1, 2, 3]
	_anim_progress = 0.0
	_animating = true
	queue_redraw()

func _draw_diagram() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + 12, _diagram_rect.position.y + _diagram_rect.size.y * 0.5), "Count occurrences, then rebuild sorted output", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#FFB800"))

func _draw_anim() -> void:
	var in_y: float = _anim_rect.position.y + _anim_rect.size.y * 0.1
	draw_string(ThemeDB.fallback_font, Vector2(_anim_rect.position.x + 12, in_y), "input:", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_MUTED)
	var cell_w: float = 48.0
	var gap: float = 6.0
	var in_x: float = _anim_rect.position.x + 80.0
	for i in _arr.size():
		var r := Rect2(in_x + i * (cell_w + gap), in_y, cell_w, 46)
		var is_hl: bool = i == _highlight_input
		draw_rect(r, Color("#FFB800") if is_hl else Color("#0D4A6A"), true)
		draw_rect(r, Color("#FFB800") if is_hl else Color("#2A4A6A"), false, 2)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + cell_w * 0.5 - 4, r.position.y + 30), str(_arr[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, VizUtil.C_BG if is_hl else VizUtil.C_TEXT)

	var c_y: float = _anim_rect.position.y + _anim_rect.size.y * 0.42
	draw_string(ThemeDB.fallback_font, Vector2(_anim_rect.position.x + 12, c_y - 6), "count:", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#00D4FF"))
	var c_count: int = _counts.size()
	var total_c_w: float = c_count * cell_w + (c_count - 1) * gap
	var c_x: float = _anim_rect.position.x + (_anim_rect.size.x - total_c_w) * 0.5
	for i in c_count:
		var r := Rect2(c_x + i * (cell_w + gap), c_y, cell_w, 50)
		var is_hl: bool = i == _highlight_count
		draw_rect(r, Color("#003D66") if is_hl else Color("#0D2040"), true)
		draw_rect(r, Color("#FFB800") if is_hl else VizUtil.C_HIGHLIGHT, false, 2.5 if is_hl else 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + cell_w * 0.5 - 4, r.position.y - 4), "[" + str(i) + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VizUtil.C_MUTED)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + cell_w * 0.5 - 4, r.position.y + 32), str(_counts[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#00FF88") if is_hl else VizUtil.C_TEXT)

	var o_y: float = _anim_rect.position.y + _anim_rect.size.y * 0.78
	draw_string(ThemeDB.fallback_font, Vector2(_anim_rect.position.x + 12, o_y), "output:", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#00FF88"))
	var o_x: float = _anim_rect.position.x + 90.0
	for i in _output.size():
		var r := Rect2(o_x + i * (cell_w + gap), o_y, cell_w, 46)
		draw_rect(r, Color("#003322"), true)
		draw_rect(r, Color("#00FF88"), false, 2)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + cell_w * 0.5 - 4, o_y + 30), str(_output[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#00FF88"))