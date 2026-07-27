extends "res://scripts/academy/VizBase.gd"

var _queue: Array = []
var _anim_type: String = ""
var _anim_val: String = ""
var _dequeue_val: String = ""

func get_steps() -> Array:
	return [
		{ "code": "from collections import deque; q = deque()" },
		{ "code": "q.append(\"Alice\")" },
		{ "code": "q.append(\"Bob\")" },
		{ "code": "q.append(\"Charlie\")" },
		{ "code": "print(q.popleft()) # Alice" },
	]

func get_concept_title() -> String:
	return "Concept: First In, First Out â€” like a line at a store"

func get_anim_title() -> String:
	return "Animation: Enqueue customers, then dequeue"

func _set_step(idx: int) -> void:
	current_step = idx
	match idx:
		0: _queue.clear(); _anim_type = "init"; _animating = false
		1: _anim_type = "enq"; _anim_val = "Alice"; _anim_progress = 0.0; _animating = true
		2: _anim_type = "enq"; _anim_val = "Bob"; _anim_progress = 0.0; _animating = true
		3: _anim_type = "enq"; _anim_val = "Charlie"; _anim_progress = 0.0; _animating = true
		4: _anim_type = "deq"; _dequeue_val = "Alice"; _queue.pop_front(); _anim_progress = 0.0; _animating = true
	queue_redraw()

func _on_reset() -> void:
	_queue.clear()
	super._on_reset()

func _process(delta: float) -> void:
	if _animating:
		_anim_progress += delta * 0.6
		if _anim_progress >= 1.0:
			_anim_progress = 1.0
			_animating = false
			if _anim_type == "enq":
				_queue.push_back(_anim_val)
				_anim_val = ""
		queue_redraw()

func _draw_diagram() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + 12, _diagram_rect.position.y + 16), "First In, First Out (FIFO)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#FFB800"))
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + 12, _diagram_rect.position.y + 36), "think: line at a store", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_MUTED)
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + 12, _diagram_rect.position.y + 56), "served first", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#00FF88"))

func _draw_anim() -> void:
	var cy: float = _anim_rect.position.y + _anim_rect.size.y * 0.5
	var cell_w: float = 90.0
	var cell_h: float = 60.0
	var gap: float = 6.0

	var display: Array = _queue.duplicate() as Array
	var incoming_val: String = ""
	var incoming_progress: float = 0.0
	if _anim_type == "enq" and _anim_progress < 1.0:
		incoming_val = _anim_val
		incoming_progress = _anim_progress

	var outgoing_val: String = ""
	var outgoing_progress: float = 0.0
	if _anim_type == "deq" and _anim_progress < 1.0:
		outgoing_val = _dequeue_val
		outgoing_progress = _anim_progress

	var n: int = display.size() + (1 if incoming_val != "" else 0)
	if n == 0 and outgoing_val == "":
		draw_string(ThemeDB.fallback_font, Vector2(_anim_rect.position.x + _anim_rect.size.x * 0.5 - 60, cy + 6), "(empty queue)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_MUTED)

	var total_w: float = max(0.0, n * (cell_w + gap) - gap)
	var start_x: float = _anim_rect.position.x + (_anim_rect.size.x - total_w) * 0.5
	draw_string(ThemeDB.fallback_font, Vector2(start_x - 70, cy - 8), "<- FRONT", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#FF3366"))
	draw_string(ThemeDB.fallback_font, Vector2(start_x + total_w + 8, cy - 8), "BACK ->", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#00FF88"))

	for i in n:
		var is_front: bool = i == 0
		var r := Rect2(start_x + i * (cell_w + gap), cy - cell_h * 0.5, cell_w, cell_h)
		var val: String
		var alpha: float = 1.0
		var offset_x: float = 0.0
		if incoming_val != "" and i == n - 1:
			val = incoming_val
			offset_x = cell_w * (1.0 - incoming_progress) * 1.3
			alpha = incoming_progress
		else:
			val = display[i]
		var bg_col: Color = Color("#0D4A6A") if not is_front else Color("#00D4FF")
		var brd_col: Color = Color("#FF3366") if is_front else Color("#2A6A8A")
		var val_col: Color = VizUtil.C_BG if is_front else VizUtil.C_TEXT
		bg_col.a = clamp(alpha, 0.0, 1.0)
		brd_col.a = clamp(alpha, 0.0, 1.0)
		val_col.a = clamp(alpha, 0.0, 1.0)
		draw_rect(r, bg_col, true)
		draw_rect(r, brd_col, false, 2)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + offset_x + 8, r.position.y + 38), val, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, val_col)

	if outgoing_val != "":
		var o_r := Rect2(start_x - cell_w * (1.0 - outgoing_progress) - cell_w, cy - cell_h * 0.5, cell_w, cell_h)
		var o_alpha: float = 1.0 - outgoing_progress
		var o_bg: Color = Color("#FF3366")
		var o_col: Color = VizUtil.C_BG
		o_bg.a = o_alpha
		o_col.a = o_alpha
		draw_rect(o_r, o_bg, true)
		draw_string(ThemeDB.fallback_font, Vector2(o_r.position.x + 8, o_r.position.y + 38), outgoing_val, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, o_col)