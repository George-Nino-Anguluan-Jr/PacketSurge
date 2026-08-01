extends "res://scripts/academy/VizBase.gd"

var _stack: Array = []
var _anim_type: String = ""
var _anim_val: String = ""
var _pop_val: String = ""

func get_steps() -> Array:
	return [
		{ "code": "stack = []" },
		{ "code": "stack.append(\"jump\")" },
		{ "code": "stack.append(\"shoot\")" },
		{ "code": "stack.append(\"dodge\")" },
		{ "code": "print(stack.pop())   # dodge" },
	]

func get_concept_title() -> String:
	return "Concept: Last In, First Out — like a stack of plates"

func get_anim_title() -> String:
	return "Animation: Push items, then pop"

func _set_step(idx: int) -> void:
	current_step = idx
	match idx:
		0: _stack.clear(); _anim_type = "init"; _animating = false
		1: _anim_type = "push"; _anim_val = "jump"; _anim_progress = 0.0; _animating = true
		2: _anim_type = "push"; _anim_val = "shoot"; _anim_progress = 0.0; _animating = true
		3: _anim_type = "push"; _anim_val = "dodge"; _anim_progress = 0.0; _animating = true
		4: _anim_type = "pop"; _pop_val = "dodge"; _stack.pop_back(); _anim_progress = 0.0; _animating = true
	queue_redraw()

func _on_reset() -> void:
	_stack.clear()
	super._on_reset()

func _process(delta: float) -> void:
	if _animating:
		_anim_progress += delta * 0.6
		if _anim_progress >= 1.0:
			_anim_progress = 1.0
			_animating = false
			if _anim_type == "push":
				_stack.push_back(_anim_val)
				_anim_val = ""
		queue_redraw()

func _draw_diagram() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + 12, _diagram_rect.position.y + 16), "Last In, First Out (LIFO)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#FFB800"))
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + 12, _diagram_rect.position.y + 36), "think: stack of plates", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_MUTED)
	for i in 3:
		var r := Rect2(_diagram_rect.position.x + 220, _diagram_rect.position.y + 24 + i * 14, 60, 12)
		draw_rect(r, Color("#00D4FF"), true)
		draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + 290, _diagram_rect.position.y + 34 + i * 14), "→ " + str(["jump", "shoot", "dodge"][i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_TEXT)

func _draw_anim() -> void:
	var cx: float = _anim_rect.position.x + _anim_rect.size.x * 0.4
	var plate_w: float = 130.0
	var plate_h: float = 36.0
	var display: Array = _stack.duplicate() as Array
	if _anim_type == "push" and _anim_progress < 1.0:
		display.push_back(_anim_val)

	var ground_y: float = _anim_rect.position.y + _anim_rect.size.y * 0.88
	draw_line(Vector2(cx - plate_w * 0.6, ground_y), Vector2(cx + plate_w * 0.6, ground_y), Color("#2A4A6A"), 2)
	draw_string(ThemeDB.fallback_font, Vector2(cx - 16, _anim_rect.position.y + _anim_rect.size.y * 0.08), "↑ TOP", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#00FF88"))

	var n: int = display.size()
	for i in n:
		var is_top: bool = i == n - 1
		var y: float = ground_y - (i + 1) * plate_h
		var alpha: float = 1.0
		var offset_y: float = 0.0
		if _anim_type == "push" and i == n - 1:
			offset_y = -plate_h * (1.0 - _anim_progress) * 1.5
			alpha = _anim_progress
		var a: float = clamp(alpha, 0.0, 1.0)
		var p_bg: Color = Color("#00D4FF") if is_top else Color("#0D4A6A")
		var p_brd: Color = Color("#00FF88") if is_top else Color("#2A6A8A")
		var p_col: Color = VizUtil.C_BG if is_top else VizUtil.C_TEXT
		p_bg.a = a
		p_brd.a = a
		p_col.a = a
		var r := Rect2(cx - plate_w * 0.5, y + offset_y, plate_w, plate_h)
		draw_rect(r, p_bg, true)
		draw_rect(r, p_brd, false, 2)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 12, r.position.y + 24), str(display[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, p_col)

	if _anim_type == "pop":
		var out_r := Rect2(_anim_rect.position.x + _anim_rect.size.x * 0.7, _anim_rect.position.y + _anim_rect.size.y * 0.4, 180, 70)
		var oa := _anim_progress
		var o_bg: Color = VizUtil.C_PANEL
		var o_brd: Color = Color("#00FF88")
		var o_lbl: Color = VizUtil.C_MUTED
		var o_col: Color = Color("#00FF88")
		o_bg.a = oa
		o_brd.a = oa
		o_lbl.a = oa
		o_col.a = oa
		draw_rect(out_r, o_bg, true)
		draw_rect(out_r, o_brd, false, 2)
		draw_string(ThemeDB.fallback_font, Vector2(out_r.position.x + 12, out_r.position.y + 20), "popped:", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, o_lbl)
		draw_string(ThemeDB.fallback_font, Vector2(out_r.position.x + 12, out_r.position.y + 50), "→ " + _pop_val, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, o_col)
