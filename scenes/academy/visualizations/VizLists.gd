extends "res://scripts/academy/VizBase.gd"

var _items: Array = ["red", "green", "blue"]
var _highlight_index: int = -1
var _new_item_index: int = -1
var _removed_index: int = -1
var _anim_type: String = ""

func get_steps() -> Array:
	return [
		{ "code": "colors = [\"red\", \"green\", \"blue\"]" },
		{ "code": "print(colors[0])   # red" },
		{ "code": "colors.append(\"yellow\")" },
		{ "code": "colors.remove(\"green\")" },
	]

func get_concept_title() -> String:
	return "Concept: A list holds many items, each with a numbered index (starts at 0)"

func get_anim_title() -> String:
	return "Animation: Try accessing, appending, and removing"

func _set_step(idx: int) -> void:
	current_step = idx
	match idx:
		0:
			_highlight_index = -1; _removed_index = -1; _new_item_index = -1
			_animating = false; _anim_type = ""
		1:
			_highlight_index = 0; _removed_index = -1; _new_item_index = -1
			_animating = false; _anim_type = ""
		2:
			_highlight_index = -1; _removed_index = -1; _new_item_index = 3
			_items.append("yellow")
			_animating = true; _anim_type = "append"; _anim_progress = 0.0
		3:
			_highlight_index = 1; _removed_index = 1; _new_item_index = -1
			_animating = true; _anim_type = "remove"; _anim_progress = 0.0
	queue_redraw()

func _on_reset() -> void:
	_items = ["red", "green", "blue"]
	super._on_reset()

func _process(delta: float) -> void:
	if _animating:
		_anim_progress += delta * 1.4
		if _anim_progress >= 1.0:
			_anim_progress = 1.0
			_animating = false
			if _anim_type == "remove":
				_items.remove_at(_removed_index)
				_removed_index = -1
		queue_redraw()

func _draw_diagram() -> void:
	var items := ["0", "1", "2"]
	var vals := ["\"red\"", "\"green\"", "\"blue\""]
	var cell_w: float = 90.0
	var cell_h: float = 48.0
	var total_w: float = cell_w * 3 + 8 * 2
	var start_x: float = _diagram_rect.position.x + (_diagram_rect.size.x - total_w) * 0.5
	var cy: float = _diagram_rect.position.y + (_diagram_rect.size.y - cell_h) * 0.5
	for i in 3:
		var r := Rect2(start_x + i * (cell_w + 8), cy, cell_w, cell_h)
		draw_rect(r, VizUtil.C_PANEL, true)
		draw_rect(r, VizUtil.C_HIGHLIGHT, false, 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 6, r.position.y - 4), "[" + items[i] + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VizUtil.C_MUTED)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 10, r.position.y + 30), vals[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_TEXT)

func _draw_anim() -> void:
	var n := _items.size()
	if n == 0:
		return
	var cell_w: float = 80.0
	var cell_h: float = 70.0
	var gap: float = 6.0
	var total_w: float = cell_w * n + gap * (n - 1)
	var start_x: float = _anim_rect.position.x + (_anim_rect.size.x - total_w) * 0.5
	var cy: float = _anim_rect.position.y + _anim_rect.size.y * 0.5 - cell_h * 0.5

	for i in n:
		var pos_x: float = start_x + i * (cell_w + gap)
		var alpha: float = 1.0
		if _anim_type == "remove" and i == _removed_index:
			alpha = 1.0 - _anim_progress
		var r := Rect2(pos_x, cy, cell_w, cell_h)
		var color := VizUtil.C_HIGHLIGHT if i == _highlight_index else VizUtil.C_PANEL
		var border := VizUtil.C_HIGHLIGHT if i == _highlight_index else Color("#2A4A6A")
		var idx_col: Color = VizUtil.C_MUTED
		var val_col: Color = VizUtil.C_TEXT
		color.a = alpha
		border.a = alpha
		idx_col.a = alpha
		val_col.a = alpha
		draw_rect(r, color, true)
		draw_rect(r, border, false, 2)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 6, r.position.y - 5), "[" + str(i) + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, idx_col)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 8, r.position.y + 44), "\"" + _items[i] + "\"", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, val_col)

	if _highlight_index >= 0 and _highlight_index < n and _anim_type != "remove":
		var px: float = start_x + _highlight_index * (cell_w + gap) + cell_w * 0.5
		VizUtil.draw_pointer(self, Vector2(px, cy - 6), "colors[" + str(_highlight_index) + "]", VizUtil.C_LABEL, ThemeDB.fallback_font)
