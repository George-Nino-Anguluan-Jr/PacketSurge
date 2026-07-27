extends "res://scripts/academy/VizBase.gd"

var _groups: Array = []
var _phase: String = ""

func get_steps() -> Array:
	return [
		{ "code": "arr = [38, 27, 43, 3]" },
		{ "code": "split -> [38, 27]  |  [43, 3]" },
		{ "code": "split -> [38] [27]  |  [43] [3]" },
		{ "code": "merge -> [27, 38]" },
		{ "code": "merge -> [3, 27, 38, 43] v" },
	]

func get_concept_title() -> String:
	return "Concept: Divide-and-conquer â€” split, recurse, merge"

func get_anim_title() -> String:
	return "Animation: Split then merge"

func _set_step(idx: int) -> void:
	current_step = idx
	match idx:
		0: _groups = [[38, 27, 43, 3]]; _phase = "init"
		1: _groups = [[38, 27], [43, 3]]; _phase = "split"
		2: _groups = [[38], [27], [43], [3]]; _phase = "split"
		3: _groups = [[27, 38], [3, 43]]; _phase = "merge"
		4: _groups = [[3, 27, 38, 43]]; _phase = "merge"
	_anim_progress = 0.0
	_animating = true
	queue_redraw()

func _draw_diagram() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + 12, _diagram_rect.position.y + _diagram_rect.size.y * 0.5), "Split in half -> split in half -> merge sorted halves", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#FFB800"))

func _draw_anim() -> void:
	var n_groups: int = _groups.size()
	var cell_w: float = 40.0
	var gap: float = 4.0
	var group_gap: float = 16.0
	var total_items: int = 0
	for g in _groups: total_items += g.size()
	if total_items == 0: return
	var total_w: float = total_items * cell_w + (total_items - 1) * gap + (n_groups - 1) * group_gap
	var start_x: float = _anim_rect.position.x + (_anim_rect.size.x - total_w) * 0.5
	var cy: float = _anim_rect.position.y + _anim_rect.size.y * 0.4
	var x: float = start_x
	for gi in n_groups:
		var g: Array = _groups[gi]
		for j in g.size():
			var v: int = g[j]
			var r := Rect2(x, cy, cell_w, 56)
			var is_merge: bool = _phase == "merge"
			var color: Color = Color("#00D4FF") if is_merge else Color("#0D4A6A")
			var border: Color = Color("#00FF88") if is_merge else VizUtil.C_HIGHLIGHT
			draw_rect(r, color, true)
			draw_rect(r, border, false, 2)
			draw_string(ThemeDB.fallback_font, Vector2(r.position.x + cell_w * 0.5 - 4, r.position.y + 34), str(v), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_BG if is_merge else VizUtil.C_TEXT)
			x += cell_w + gap
		x += group_gap - gap
	var label: String = "SPLIT" if _phase == "split" else ("MERGE" if _phase == "merge" else "INIT")
	var label_color: Color = VizUtil.C_HIGHLIGHT if _phase == "split" else Color("#00FF88")
	draw_string(ThemeDB.fallback_font, Vector2(_anim_rect.position.x + 8, cy - 22), "v " + label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, label_color)