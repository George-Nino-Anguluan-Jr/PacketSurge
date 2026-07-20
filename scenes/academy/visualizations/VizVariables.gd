extends Control

var diag: Control; var anim: Control; var code_label: Label
var play_btn: Button; var step_btn: Button; var reset_btn: Button
var paused := false; var step_idx := 0; var progress := 0.0; var tween: Tween

var vars_data = [{"n":"name","v":"Alice","t":"str"},{"n":"age","v":25,"t":"int"},{"n":"score","v":92.5,"t":"float"}]
var steps = [
	{"code": "name = 'Alice'  (str)", "h": 0},
	{"code": "age = 25  (int)", "h": 1},
	{"code": "score = 92.5  (float)", "h": 2},
	{"code": "print(name, age, score)", "h": -1},
]

func _set_progress(v): progress = v; queue_redraw()

func _ready():
	var ui = VizUtil.standard_ui(self, " Python Variables — Dynamic Typing", 100, 400)
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
	tween = create_tween(); tween.tween_method(_set_progress, 0.0, 1.0, 0.7).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_on_tween_done, CONNECT_ONE_SHOT)

func _on_tween_done():
	if step_idx >= steps.size(): return
	step_idx += 1; progress = 0.0
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "Variables demo complete!"; queue_redraw(); return
	code_label.text = "?  " + steps[step_idx].code; queue_redraw()
	if not paused: _start_tween()

func _do_step():
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "Variables demo complete!"; return
	code_label.text = "?  " + steps[step_idx].code; progress = 1.0; step_idx += 1; queue_redraw()

func _draw_diag():
	var f = ThemeDB.fallback_font
	diag.draw_string(f, Vector2(16, 20), "name = 'Alice'    # str", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_LABEL)
	diag.draw_string(f, Vector2(16, 40), "age  = 25         # int", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)
	diag.draw_string(f, Vector2(16, 60), "score = 92.5      # float", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)
	diag.draw_string(f, Vector2(16, 80), "no type decl needed (dynamic typing)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_VAL)

func _draw_anim():
	var f = ThemeDB.fallback_font; var w = anim.size.x; var p = progress
	if step_idx == 0 and p == 0.0: _draw_vars(-1); return
	var idx = min(step_idx, steps.size() - 1); var h = steps[idx].h
	_draw_vars(h)

func _draw_vars(highlight):
	var f = ThemeDB.fallback_font; var w = anim.size.x; var h = 400.0
	var bw = 130.0; var bh = 70.0; var sp = 20.0; var tw = vars_data.size() * (bw + sp) - sp
	var sx = (w - tw) * 0.5; var y = h * 0.5 - bh * 0.5
	var p = progress
	for i in range(vars_data.size()):
		var x = sx + i * (bw + sp); var v = vars_data[i]; var col = VizUtil.C_LABEL
		if i == highlight: col = VizUtil.lerp_color(VizUtil.C_LABEL, VizUtil.C_HIGHLIGHT, p)
		anim.draw_rect(Rect2(x, y, bw, bh), Color(col, 0.15))
		anim.draw_rect(Rect2(x, y, bw, bh), col, false, 1.5)
		anim.draw_string(f, Vector2(x + 8, y + 16), v.n, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
		var val_str = str(v.v)
		anim.draw_string(f, Vector2(x + 8, y + bh - 10), "= " + val_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_TEXT)
		anim.draw_string(f, Vector2(x + bw - 40, y + bh - 10), "(" + v.t + ")", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VizUtil.C_MUTED)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		if diag: diag.queue_redraw()
		if anim: anim.queue_redraw()
