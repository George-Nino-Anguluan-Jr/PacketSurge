extends "res://scripts/academy/VizBase.gd"

var _values: Array = []
var _buckets: Array = []
var _pass: int = 0
var _active_digit: String = ""

func get_steps() -> Array:
	return [
		{ "code": "arr = [170, 45, 75, 90, 2, 24]" },
		{ "code": "Pass 1: sort by ones digit" },
		{ "code": "Pass 2: sort by tens digit" },
		{ "code": "Pass 3: sort by hundreds digit" },
		{ "code": "v sorted: [2, 24, 45, 75, 90, 170]" },
	]

func get_concept_title() -> String:
	return "Concept: Sort digit by digit using 10 buckets (0-9)"

func get_anim_title() -> String:
	return "Animation: Watch digits get distributed into buckets"

func _set_step(idx: int) -> void:
	current_step = idx
	match idx:
		0: _values = [170, 45, 75, 90, 2, 24]; _buckets = [[], [], [], [], [], [], [], [], [], []]; _pass = 0; _active_digit = ""
		1: _values = [170, 90, 2, 24, 45, 75]; _buckets = [[170, 90], [], [2], [24], [], [45, 75], [], [], [], []]; _pass = 1; _active_digit = "ones"
		2: _values = [2, 24, 45, 75, 170, 90]; _buckets = [[2], [], [24], [], [45], [], [], [75, 170], [], [90]]; _pass = 2; _active_digit = "tens"
		3: _values = [2, 24, 45, 75, 90, 170]; _buckets = [[2, 24, 45, 75, 90], [], [], [], [], [], [], [], [], [170]]; _pass = 3; _active_digit = "hundreds"
		4: _values = [2, 24, 45, 75, 90, 170]; _buckets = [[2, 24, 45, 75, 90, 170], [], [], [], [], [], [], [], [], []]; _pass = 4; _active_digit = "done"
	_anim_progress = 0.0
	_animating = true
	queue_redraw()

func _draw_diagram() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + 12, _diagram_rect.position.y + _diagram_rect.size.y * 0.5), "Sort by ones -> tens -> hundreds using buckets 0-9", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#FFB800"))

func _draw_anim() -> void:
	var pass_label: String = ""
	if _active_digit == "": pass_label = "Init"
	elif _active_digit == "done": pass_label = "Done!"
	else: pass_label = "Pass %d - %s digit" % [_pass, _active_digit]
	draw_string(ThemeDB.fallback_font, Vector2(_anim_rect.position.x + 20, _anim_rect.position.y + 18), pass_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#00D4FF") if _active_digit != "done" else Color("#00FF88"))

	var v_y: float = _anim_rect.position.y + _anim_rect.size.y * 0.18
	draw_string(ThemeDB.fallback_font, Vector2(_anim_rect.position.x + 20, v_y - 4), "array:", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_MUTED)
	var cell_w: float = 46.0
	var gap: float = 4.0
	var v_x: float = _anim_rect.position.x + 80.0
	for i in _values.size():
		var r := Rect2(v_x + i * (cell_w + gap), v_y, cell_w, 34)
		draw_rect(r, Color("#0D4A6A"), true)
		draw_rect(r, Color("#2A4A6A"), false, 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + cell_w * 0.5 - 8, r.position.y + 22), str(_values[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)

	var b_top: float = _anim_rect.position.y + _anim_rect.size.y * 0.4
	var b_bottom: float = _anim_rect.position.y + _anim_rect.size.y * 0.88
	var b_count: int = 10
	var b_w: float = (_anim_rect.size.x - 40) / b_count
	for d in b_count:
		var b_x: float = _anim_rect.position.x + 20 + d * b_w
		draw_rect(Rect2(b_x, b_top, b_w - 4, 20), Color("#1A2A3A"), true)
		draw_string(ThemeDB.fallback_font, Vector2(b_x + b_w * 0.5 - 3, b_top + 14), str(d), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#FFB800"))
		draw_rect(Rect2(b_x, b_top + 22, b_w - 4, b_bottom - b_top - 22), Color("#080F1E"), true)
		draw_rect(Rect2(b_x, b_top + 22, b_w - 4, b_bottom - b_top - 22), Color("#2A4A6A"), false, 1)
		var items: Array = _buckets[d]
		for j in items.size():
			var item_y: float = b_bottom - 24 - j * 14
			draw_string(ThemeDB.fallback_font, Vector2(b_x + 4, item_y), str(items[j]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#00FF88") if _pass == 3 else VizUtil.C_HIGHLIGHT)