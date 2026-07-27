extends "res://scripts/academy/VizBase.gd"

var _current_name: String = ""
var _current_value: String = ""
var _current_value_color: Color = VizUtil.C_VAL
var _printed_output: String = ""
var _anim_from_value: String = ""
var _anim_to_value: String = ""

func get_steps() -> Array:
	return [
		{ "code": "name = \"Alex\"" },
		{ "code": "print(name)" },
		{ "code": "name = \"Jordan\"" },
		{ "code": "print(name)" },
	]

func get_concept_title() -> String:
	return "Concept: A variable is a labeled box that holds a value"

func get_anim_title() -> String:
	return "Animation: Watch the variable change"

func _set_step(idx: int) -> void:
	current_step = idx
	match idx:
		0:
			_current_name = "name"; _current_value = "Alex"; _current_value_color = Color("#FFB800"); _printed_output = ""
			_anim_from_value = "Alex"; _anim_to_value = "Alex"; _anim_progress = 1.0; _animating = false
		1:
			_current_name = "name"; _current_value = "Alex"; _current_value_color = Color("#FFB800"); _printed_output = "Alex"
			_anim_from_value = "Alex"; _anim_to_value = "Alex"; _anim_progress = 1.0; _animating = false
		2:
			_current_name = "name"; _current_value = "Jordan"; _current_value_color = Color("#00FF88"); _printed_output = ""
			_anim_from_value = "Alex"; _anim_to_value = "Jordan"; _anim_progress = 0.0; _animating = true
		3:
			_current_name = "name"; _current_value = "Jordan"; _current_value_color = Color("#00FF88"); _printed_output = "Jordan"
			_anim_from_value = "Jordan"; _anim_to_value = "Jordan"; _anim_progress = 1.0; _animating = false
	queue_redraw()

func _draw_diagram() -> void:
	var labels := ["name", "score", "ready"]
	var vals := ["\"Alex\"", "100", "True"]
	var colors := [Color("#FFB800"), Color("#00D4FF"), Color("#00FF88")]
	var box_w: float = 110.0
	var box_h: float = 60.0
	var total_w: float = box_w * 3 + 20 * 2
	var start_x: float = _diagram_rect.position.x + (_diagram_rect.size.x - total_w) * 0.5
	var cy: float = _diagram_rect.position.y + (_diagram_rect.size.y - box_h) * 0.5
	for i in 3:
		var r := Rect2(start_x + i * (box_w + 20), cy, box_w, box_h)
		draw_rect(r, VizUtil.C_PANEL, true)
		draw_rect(r, colors[i], false, 2)
		var name_bg := Rect2(r.position, Vector2(r.size.x, 22))
		draw_rect(name_bg, colors[i], true)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 10, r.position.y + 16), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, VizUtil.C_BG)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 10, r.position.y + 46), vals[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, colors[i])

func _draw_anim() -> void:
	var box_w: float = 180.0
	var box_h: float = 110.0
	var cx: float = _anim_rect.position.x + _anim_rect.size.x * 0.32
	var cy: float = _anim_rect.position.y + _anim_rect.size.y * 0.5
	var rect := Rect2(cx - box_w * 0.5, cy - box_h * 0.5, box_w, box_h)
	draw_rect(rect, VizUtil.C_PANEL, true)
	draw_rect(rect, _current_value_color, false, 2.5)
	var name_bg := Rect2(rect.position, Vector2(rect.size.x, 28))
	draw_rect(name_bg, _current_value_color, true)
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 12, rect.position.y + 20), _current_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, VizUtil.C_BG)

	var show_value: String = _current_value
	var alpha: float = 1.0
	if _animating and _anim_progress < 1.0:
		if _anim_progress < 0.5:
			show_value = _anim_from_value
			alpha = 1.0 - _anim_progress * 2.0
		else:
			show_value = _anim_to_value
			alpha = (_anim_progress - 0.5) * 2.0
	var val_col := _current_value_color
	val_col.a = clamp(alpha, 0.0, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + rect.size.x * 0.5 - 36, rect.position.y + rect.size.y * 0.5 + 22), show_value, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, val_col)

	var arr_from := Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y * 0.5)
	var arr_to := Vector2(_anim_rect.position.x + _anim_rect.size.x * 0.68, rect.position.y + rect.size.y * 0.5)
	VizUtil.draw_arrow(self, arr_from, arr_to, VizUtil.C_HIGHLIGHT, 8)

	var con_rect := Rect2(_anim_rect.position.x + _anim_rect.size.x * 0.68, rect.position.y - 20, 200, rect.size.y + 40)
	draw_rect(con_rect, VizUtil.C_PANEL, true)
	draw_rect(con_rect, VizUtil.C_HIGHLIGHT, false, 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(con_rect.position.x + 10, con_rect.position.y + 16), "console", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_MUTED)
	if _printed_output != "":
		draw_string(ThemeDB.fallback_font, Vector2(con_rect.position.x + 10, con_rect.position.y + 60), "> " + _printed_output, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, VizUtil.C_VAL)
	else:
		draw_string(ThemeDB.fallback_font, Vector2(con_rect.position.x + 10, con_rect.position.y + 60), "> _", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, VizUtil.C_MUTED)
