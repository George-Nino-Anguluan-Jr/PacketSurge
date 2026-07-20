extends Control

var diag: Control; var anim: Control; var code_label: Label
var play_btn: Button; var step_btn: Button; var reset_btn: Button
var paused := false; var step_idx := 0; var progress := 0.0; var tween: Tween

var steps = [
	{"code": "def double(n): return n * 2", "caller": "", "func": "", "ret": "", "phase": 0},
	{"code": "result = double(5)", "caller": "result =", "func": "n=5", "ret": "", "phase": 1},
	{"code": "? inside double: n=5 ? 5*2=10", "caller": "double(5)", "func": "n=5", "ret": "", "phase": 2},
	{"code": "? return 10", "caller": "double(5)", "func": "", "ret": "10", "phase": 3},
	{"code": "result = 10", "caller": "result=10", "func": "", "ret": "", "phase": 4},
]

func _set_progress(v): progress = v; queue_redraw()

func _ready():
	var ui = VizUtil.standard_ui(self, " Functions — Reusable Code Blocks", 100, 400)
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
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "Functions demo complete!"; queue_redraw(); return
	code_label.text = "?  " + steps[step_idx].code; queue_redraw()
	if not paused: _start_tween()

func _do_step():
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "Functions demo complete!"; return
	code_label.text = "?  " + steps[step_idx].code; progress = 1.0; step_idx += 1; queue_redraw()

func _draw_diag():
	var f = ThemeDB.fallback_font
	diag.draw_string(f, Vector2(16, 20), "def double(n):", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_LABEL)
	diag.draw_string(f, Vector2(16, 40), "    return n * 2", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)
	diag.draw_string(f, Vector2(16, 60), "result = double(5)  # = 10", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_SWAP)
	diag.draw_string(f, Vector2(16, 80), "print(result)  # reusability!", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_VAL)

func _draw_anim():
	var f = ThemeDB.fallback_font; var w = anim.size.x; var h = 400.0; var p = progress
	if step_idx == 0 and p == 0.0: _draw_func("", "", "", 0); return
	var idx = min(step_idx, steps.size() - 1); var s = steps[idx]
	_draw_func(s.caller, s.func, s.ret, s.phase)

func _draw_func(caller, func_val, ret, phase):
	var f = ThemeDB.fallback_font; var w = anim.size.x; var h = 400.0
	var bw = 140.0; var bh = 50.0; var cx1 = w * 0.5 - bw - 30; var cx2 = w * 0.5 + 30
	var cy = h * 0.5 - bh * 0.5
	var caller_p = VizUtil.C_LABEL; var func_p = VizUtil.C_LABEL; var ret_p = VizUtil.C_HIGHLIGHT
	if phase >= 1: caller_p = VizUtil.C_HIGHLIGHT
	if phase >= 2: func_p = VizUtil.C_SWAP
	if phase >= 3: caller_p = VizUtil.C_VAL; ret_p = VizUtil.C_VAL
	anim.draw_rect(Rect2(cx1, cy, bw, bh), Color(caller_p, 0.15))
	anim.draw_rect(Rect2(cx1, cy, bw, bh), caller_p, false, 2.0)
	anim.draw_string(f, Vector2(cx1 + 10, cy + 18), "caller", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_MUTED)
	anim.draw_string(f, Vector2(cx1 + 10, cy + bh - 10), caller, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)
	anim.draw_rect(Rect2(cx2, cy, bw, bh), Color(func_p, 0.15))
	anim.draw_rect(Rect2(cx2, cy, bw, bh), func_p, false, 2.0)
	anim.draw_string(f, Vector2(cx2 + 10, cy + 18), "double(n)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_MUTED)
	anim.draw_string(f, Vector2(cx2 + 10, cy + bh - 10), func_val, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)
	if not ret.is_empty():
		anim.draw_rect(Rect2(cx2, cy + bh + 20, bw, bh * 0.6), Color(ret_p, 0.15))
		anim.draw_rect(Rect2(cx2, cy + bh + 20, bw, bh * 0.6), ret_p, false, 2.0)
		anim.draw_string(f, Vector2(cx2 + 10, cy + bh + 38), "return " + ret, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_VAL)
		VizUtil.draw_arrow(anim, Vector2(cx2, cy + bh + 28), Vector2(cx1 + bw, cy + bh + 28), VizUtil.C_VAL)
	if phase >= 1 and phase < 3:
		VizUtil.draw_arrow(anim, Vector2(cx1 + bw, cy + bh * 0.5), Vector2(cx2, cy + bh * 0.5), VizUtil.C_HIGHLIGHT)
		anim.draw_string(f, Vector2((cx1+bw+cx2)*0.5 - 14, cy + bh * 0.5 - 14), "call", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_HIGHLIGHT)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		if diag: diag.queue_redraw()
		if anim: anim.queue_redraw()
