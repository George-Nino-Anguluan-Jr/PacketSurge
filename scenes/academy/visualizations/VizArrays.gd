extends "res://scripts/academy/VizBase.gd"

var _values: Array = [72, 75, 68, 70, 73, 0, 0]
var _highlight: int = -1

func get_steps() -> Array:
	return [
		{ "code": "temps = [72, 75, 68, 70, 73, 0, 0]" },
		{ "code": "print(temps[2])  # 68 — O(1)" },
		{ "code": "temps[4] = 74   (update)" },
		{ "code": "print(temps[4])  # 74" },
	]

func get_concept_title() -> String:
	return "Concept: An array is a fixed-size sequence with O(1) index access"

func get_anim_title() -> String:
	return "Animation: Jump directly to any index"

func _set_step(idx: int) -> void:
	current_step = idx
	match idx:
		0: _values = [72, 75, 68, 70, 73, 0, 0]; _highlight = -1
		1: _values = [72, 75, 68, 70, 73, 0, 0]; _highlight = 2
		2: _values = [72, 75, 68, 70, 74, 0, 0]; _highlight = 4
		3: _values = [72, 75, 68, 70, 74, 0, 0]; _highlight = 4
	_anim_progress = 0.0
	_animating = true
	queue_redraw()

func _draw_diagram() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(_diagram_rect.position.x + 12, _diagram_rect.position.y + _diagram_rect.size.y * 0.5), "Fixed-size slots  •  O(1) instant access by index", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#FFB800"))

func _draw_anim() -> void:
	var n := _values.size()
	var cell_w: float = 60.0
	var cell_h: float = 70.0
	var gap: float = 6.0
	var total_w: float = cell_w * n + gap * (n - 1)
	var start_x: float = _anim_rect.position.x + (_anim_rect.size.x - total_w) * 0.5
	var cy: float = _anim_rect.position.y + _anim_rect.size.y * 0.35

	for i in n:
		var r := Rect2(start_x + i * (cell_w + gap), cy, cell_w, cell_h)
		var is_hl: bool = i == _highlight
		var alpha: float = 1.0
		if is_hl and _anim_progress < 1.0:
			alpha = 0.4 + 0.6 * (sin(_anim_progress * 12.0) * 0.5 + 0.5)
		var bg_col: Color = Color("#003D66") if is_hl else VizUtil.C_PANEL
		var border_col: Color = Color("#00FF88") if is_hl else Color("#2A4A6A")
		var label_col: Color = Color("#FFB800") if is_hl else VizUtil.C_MUTED
		var val_col: Color = Color("#00FF88") if is_hl else VizUtil.C_TEXT
		bg_col.a = alpha
		border_col.a = alpha
		label_col.a = alpha
		val_col.a = alpha
		draw_rect(r, bg_col, true)
		draw_rect(r, border_col, false, 2.5 if is_hl else 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 8, r.position.y - 5), "[" + str(i) + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, label_col)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 10, r.position.y + 46), str(_values[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, val_col)

	if _highlight >= 0:
		var hl_x: float = start_x + _highlight * (cell_w + gap) + cell_w * 0.5
		draw_string(ThemeDB.fallback_font, Vector2(hl_x - 22, cy + cell_h + 22), "→ instant", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#00FF88"))
		VizUtil.draw_pointer(self, Vector2(hl_x, cy - 6), "temps[" + str(_highlight) + "]", Color("#00FF88"), ThemeDB.fallback_font)
