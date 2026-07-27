extends "res://scripts/academy/VizBase.gd"

var _display: Array = []
var _pivot: int = 0
var _pivot_idx: int = -1
var _left: Array = []
var _right: Array = []
var _phase: String = ""
var _highlight: int = -1

func get_steps() -> Array:
	return [
		{ "code": "arr = [3, 6, 8, 10, 1, 2, 1]" },
		{ "code": "pivot = arr[3] = 10" },
		{ "code": "partition: left=[3,6,8,1,2,1] right=[]" },
		{ "code": "sort left: pivot = 8" },
		{ "code": "partition: left=[3,6,1,2,1] right=[]" },
		{ "code": "sort: pivot = 1" },
		{ "code": "partition: left=[] right=[3,6,2]" },
		{ "code": "v sorted: [1, 1, 2, 3, 6, 8, 10]" },
	]

func get_concept_title() -> String:
	return "Concept: Pick pivot, partition smaller/larger, recurse"

func get_anim_title() -> String:
	return "Animation: Watch the recursive partition"

func _set_step(idx: int) -> void:
	current_step = idx
	match idx:
		0: _display = [3, 6, 8, 10, 1, 2, 1]; _pivot = 0; _pivot_idx = -1; _left = []; _right = []; _phase = "init"; _highlight = -1
		1: _display = [3, 6, 8, 10, 1, 2, 1]; _pivot = 10; _pivot_idx = 3; _left = []; _right = []; _phase = "pick"; _highlight = 3
		2: _display = [3, 6, 8, 1, 2, 1, 10]; _pivot = 10; _pivot_idx = 6; _left = [3, 6, 8, 1, 2, 1]; _right = []; _phase = "partition"; _highlight = -1
		3: _display = [3, 6, 8, 1, 2, 1]; _pivot = 8; _pivot_idx = 2; _left = []; _right = []; _phase = "pick"; _highlight = 2
		4: _display = [3, 6, 1, 2, 1, 8]; _pivot = 8; _pivot_idx = 5; _left = [3, 6, 1, 2, 1]; _right = []; _phase = "partition"; _highlight = -1
		5: _display = [3, 6, 1, 2, 1]; _pivot = 1; _pivot_idx = 2; _left = []; _right = []; _phase = "pick"; _highlight = 2
		6: _display = [1, 3, 6, 2]; _pivot = 1; _pivot_idx = 0; _left = []; _right = [3, 6, 2]; _phase = "partition"; _highlight = -1
		7: _display = [1, 1, 2, 3, 6, 8, 10]; _pivot = 0; _pivot_idx = -1; _left = []; _right = []; _phase = "done"; _highlight = -1
	_anim_progress = 0.0
	_animating = true
	queue_redraw()

func _draw_diagram() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + 12, _diagram_rect.position.y + _diagram_rect.size.y * 0.5), "Pick pivot  â€¢  partition smaller/larger  â€¢  recurse", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#FFB800"))

func _draw_anim() -> void:
	if _phase == "partition":
		var ln: int = _left.size()
		var rn: int = _right.size()
		var total: int = ln + 1 + rn
		if total == 0: return
		var cell_w: float = 44.0
		var gap: float = 6.0
		var total_w: float = cell_w * total + gap * (total - 1)
		var start_x: float = _anim_rect.position.x + (_anim_rect.size.x - total_w) * 0.5
		var cy: float = _anim_rect.position.y + _anim_rect.size.y * 0.4
		draw_string(ThemeDB.fallback_font, Vector2(start_x - 50, cy + 30), "< pivot", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, VizUtil.C_HIGHLIGHT)
		draw_string(ThemeDB.fallback_font, Vector2(start_x + total_w - 50, cy + 30), "> pivot", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#FFB800"))
		for i in total:
			var v: int
			var is_pivot: bool = i == ln
			if i < ln: v = _left[i]
			elif is_pivot: v = _pivot
			else: v = _right[i - ln - 1]
			var r := Rect2(start_x + i * (cell_w + gap), cy, cell_w, 56)
			var color: Color = Color("#FFB800") if is_pivot else (VizUtil.C_HIGHLIGHT if i < ln else Color("#00D4FF"))
			draw_rect(r, color, true)
			draw_rect(r, Color("#FFB800") if is_pivot else Color("#2A4A6A"), false, 2.5 if is_pivot else 1.5)
			draw_string(ThemeDB.fallback_font, Vector2(r.position.x + cell_w * 0.5 - 4, r.position.y + 34), str(v), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, VizUtil.C_BG if is_pivot else VizUtil.C_TEXT)
			if is_pivot:
				draw_string(ThemeDB.fallback_font, Vector2(r.position.x + cell_w * 0.5 - 16, r.position.y - 6), "PIVOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#FFB800"))
	else:
		var n: int = _display.size()
		if n == 0: return
		var cell_w: float = 44.0
		var gap: float = 6.0
		var total_w: float = cell_w * n + gap * (n - 1)
		var start_x: float = _anim_rect.position.x + (_anim_rect.size.x - total_w) * 0.5
		var cy: float = _anim_rect.position.y + _anim_rect.size.y * 0.4
		for i in n:
			var v: int = _display[i]
			var r := Rect2(start_x + i * (cell_w + gap), cy, cell_w, 56)
			var is_pivot: bool = i == _pivot_idx and _phase == "pick"
			var is_hl: bool = i == _highlight
			var color: Color = Color("#FFB800") if is_pivot else (VizUtil.C_HIGHLIGHT if is_hl else Color("#0D4A6A"))
			draw_rect(r, color, true)
			draw_rect(r, Color("#FFB800") if is_pivot else Color("#2A4A6A"), false, 2.5 if is_pivot else 1.5)
			draw_string(ThemeDB.fallback_font, Vector2(r.position.x + cell_w * 0.5 - 4, r.position.y + 34), str(v), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, VizUtil.C_BG if is_pivot else VizUtil.C_TEXT)
			if is_pivot:
				draw_string(ThemeDB.fallback_font, Vector2(r.position.x + cell_w * 0.5 - 16, r.position.y - 6), "PIVOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#FFB800"))