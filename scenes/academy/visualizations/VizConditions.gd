extends Control

var diag: Control; var anim: Control; var code_label: Label
var play_btn: Button; var step_btn: Button; var reset_btn: Button
var paused := false; var step_idx := 0; var progress := 0.0; var tween: Tween

var steps = [
	{"code": "x = 10", "x": 10, "phase": 0},
	{"code": "if x > 5: ? True (10>5)", "x": 10, "phase": 1},
	{"code": "print('Big!') ? 'Big!'", "x": 10, "phase": 2},
	{"code": "(Try x=3: x<5 ? False ? else)", "x": 3, "phase": 3},
	{"code": "print('Small!')", "x": 3, "phase": 4},
]

func _set_progress(v): progress = v; queue_redraw()

func _ready():
	var ui = VizUtil.standard_ui(self, " If/Else — Conditional Logic", 100, 400)
	diag = ui.diagram; anim = ui.anim; code_label = ui.code; var ctrl = ui.controls
	diag.draw.connect(_draw_diag); anim.draw.connect(_draw_anim)
	play_btn = VizUtil.make_btn("? Play", VizUtil.C_LABEL); step_btn = VizUtil.make_btn("? Step", VizUtil.C_LABEL)
	reset_btn = VizUtil.make_btn("? Reset", Color("#FF3366"))
	ctrl.add_child(play_btn); ctrl.add_child(step_btn); ctrl.add_child(reset_btn)
	play_btn.pressed.connect(_on_play); step_btn.pressed.connect(_on_step); reset_btn.pressed.connect(_on_reset)

func _on_play():
	if step_idx >= steps.size(): _on_reset(); return
	paused = not paused; play_btn.text = "? Pause" if not paused else "? Play"
	if not paused: _start_tween()

func _on_step():
	paused = true; play_btn.text = "? Play"
	if tween and tween.is_running(): tween.kill(); _do_step()

func _on_reset():
	paused = true; play_btn.text = "? Play"
	if tween and tween.is_running(): tween.kill()
	step_idx = 0; progress = 0.0; code_label.text = "Press ? Play or ? Step to begin"; queue_redraw()

func _start_tween():
	if paused or step_idx >= steps.size(): return
	if tween and tween.is_running(): tween.kill()
	tween = create_tween(); tween.tween_method(_set_progress, 0.0, 1.0, 0.6).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_on_tween_done, CONNECT_ONE_SHOT)

func _on_tween_done():
	if step_idx >= steps.size(): return
	step_idx += 1; progress = 0.0
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "If/else demo complete!"; queue_redraw(); return
	code_label.text = "?  " + steps[step_idx].code; queue_redraw()
	if not paused: _start_tween()

func _do_step():
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "If/else demo complete!"; return
	code_label.text = "?  " + steps[step_idx].code; progress = 1.0; step_idx += 1; queue_redraw()

func _draw_diag():
	var f = ThemeDB.fallback_font
	diag.draw_string(f, Vector2(16, 20), "x = 10", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_LABEL)
	diag.draw_string(f, Vector2(16, 40), "if x > 5:", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)
	diag.draw_string(f, Vector2(16, 60), "    print('Big!')  # True branch", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_SWAP)
	diag.draw_string(f, Vector2(16, 80), "else:", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)
	diag.draw_string(f, Vector2(16, 98), "    print('Small!')  # False branch", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_MUTED)

func _draw_anim():
	var f = ThemeDB.fallback_font; var w = anim.size.x; var h = 400.0; var p = progress
	if step_idx == 0 and p == 0.0: _draw_condition(10, 0); return
	var idx = min(step_idx, steps.size() - 1); var s = steps[idx]
	_draw_condition(s.x, s.phase)

func _draw_condition(x_val, phase):
	var f = ThemeDB.fallback_font; var w = anim.size.x; var h = 400.0
	var cx = w * 0.5; var cy = h * 0.5 - 20; var r = 40.0
	var ph_colors = [VizUtil.C_LABEL, VizUtil.C_HIGHLIGHT, VizUtil.C_VAL, VizUtil.C_SWAP, VizUtil.C_VAL]
	var ph_labels = ["x = " + str(x_val), "x > 5? " + str(x_val > 5).to_upper(), "Big!", "x > 5? false", "Small!"]
	var col = ph_colors[phase]
	var dia = [Vector2(cx, cy - r), Vector2(cx + r * 1.5, cy), Vector2(cx, cy + r), Vector2(cx - r * 1.5, cy)]
	anim.draw_colored_polygon(PackedVector2Array(dia), Color(col, 0.1))
	for i in range(4):
		anim.draw_line(dia[i], dia[(i + 1) % 4], col, 2.0)
	anim.draw_string(f, Vector2(cx - 6, cy + 5), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
	anim.draw_string(f, Vector2(cx - 50, cy + r + 20), ph_labels[phase], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
	if phase == 1 or phase == 3:
		var arrow_col = VizUtil.C_VAL if phase == 1 else VizUtil.C_MUTED
		if x_val > 5:
			VizUtil.draw_arrow(anim, Vector2(cx, cy + r), Vector2(cx, cy + r + 60), arrow_col)
			anim.draw_string(f, Vector2(cx + 8, cy + r + 24), "True", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, arrow_col)
		else:
			VizUtil.draw_arrow(anim, Vector2(cx, cy - r), Vector2(cx, cy - r - 60), arrow_col)
			anim.draw_string(f, Vector2(cx + 8, cy - r - 38), "False", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, arrow_col)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		if diag: diag.queue_redraw()
		if anim: anim.queue_redraw()
