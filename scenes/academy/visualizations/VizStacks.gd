extends Control

var diag: Control; var anim: Control; var code_label: Label
var play_btn: Button; var step_btn: Button; var reset_btn: Button
var paused := false; var step_idx := 0; var progress := 0.0; var tween: Tween

var items = [10, 20, 30, 40, 50]; var pop_idx := 0
var steps = [
	{"code": "stack = [] (empty)", "action": "init", "val": -1},
	{"code": "push(10) ? stack: [10]", "action": "push", "val": 10},
	{"code": "push(20) ? stack: [10, 20]", "action": "push", "val": 20},
	{"code": "push(30) ? stack: [10, 20, 30]", "action": "push", "val": 30},
	{"code": "pop() ? returns 30", "action": "pop", "val": 30},
	{"code": "pop() ? returns 20", "action": "pop", "val": 20},
	{"code": "push(40) ? stack: [10, 40]", "action": "push", "val": 40},
]

func _set_progress(v): progress = v; queue_redraw()

func _ready():
	var ui = VizUtil.standard_ui(self, " Stack — LIFO (Last In, First Out)", 100, 400)
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
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "Stack demo complete!"; queue_redraw(); return
	code_label.text = "?  " + steps[step_idx].code; queue_redraw()
	if not paused: _start_tween()

func _do_step():
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "Stack demo complete!"; return
	code_label.text = "?  " + steps[step_idx].code; progress = 1.0; step_idx += 1; queue_redraw()

func _draw_diag():
	var f = ThemeDB.fallback_font
	diag.draw_string(f, Vector2(16, 20), "stack = []", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_LABEL)
	diag.draw_string(f, Vector2(16, 40), "stack.append(val)  # push", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)
	diag.draw_string(f, Vector2(16, 60), "val = stack.pop()  # pop", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_SWAP)
	diag.draw_string(f, Vector2(16, 80), "LIFO: Last In, First Out", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_VAL)

func _draw_anim():
	var f = ThemeDB.fallback_font; var w = anim.size.x; var p = progress
	if step_idx == 0 and p == 0.0: _draw_stack([]); return
	var idx = min(step_idx, steps.size() - 1); var s = steps[idx]
	var stack = []
	for j in range(1, idx + 1):
		var sj = steps[j]
		if sj.action == "push": stack.append(sj.val)
		elif sj.action == "pop": stack.pop_back()
	_draw_stack(stack)
	if s.action == "push":
		anim.draw_string(f, Vector2(20, 20), "push(" + str(s.val) + ") ?", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_VAL)
	elif s.action == "pop":
		anim.draw_string(f, Vector2(20, 20), "pop() ? " + str(s.val) + " ?", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_SWAP)

func _draw_stack(stack):
	var f = ThemeDB.fallback_font; var w = anim.size.x; var h = 400.0
	var bw = 100.0; var bh = 40.0; var sx = w * 0.5 - bw * 0.5
	for i in range(stack.size()):
		var by = h - 60 - (i + 1) * (bh + 6)
		var col = VizUtil.C_LABEL
		if i == stack.size() - 1: col = VizUtil.lerp_color(VizUtil.C_LABEL, VizUtil.C_HIGHLIGHT, progress)
		anim.draw_rect(Rect2(sx, by, bw, bh), Color(col, 0.2))
		anim.draw_rect(Rect2(sx, by, bw, bh), col, false, 2.0)
		anim.draw_string(f, Vector2(sx + bw * 0.5 - 12, by + bh * 0.5 + 6), str(stack[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_TEXT)
	anim.draw_string(f, Vector2(sx - 30, h - 60 - (stack.size() + 1) * (bh + 6) - 10), "TOP ?", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_HIGHLIGHT)
	anim.draw_line(Vector2(sx - 20, h - 28), Vector2(sx + bw + 20, h - 28), VizUtil.C_MUTED, 2.0)
	anim.draw_string(f, Vector2(sx + bw * 0.5 - 16, h - 16), "BOTTOM", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VizUtil.C_MUTED)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		if diag: diag.queue_redraw()
		if anim: anim.queue_redraw()
