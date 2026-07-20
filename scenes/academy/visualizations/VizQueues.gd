extends Control

var diag: Control; var anim: Control; var code_label: Label
var play_btn: Button; var step_btn: Button; var reset_btn: Button
var paused := false; var step_idx := 0; var progress := 0.0; var tween: Tween

var steps = [
	{"code": "queue = [] (empty)", "action": "init", "val": -1},
	{"code": "enqueue(10) ? queue: [10]", "action": "enq", "val": 10},
	{"code": "enqueue(20) ? queue: [10, 20]", "action": "enq", "val": 20},
	{"code": "enqueue(30) ? queue: [10, 20, 30]", "action": "enq", "val": 30},
	{"code": "dequeue() ? returns 10", "action": "deq", "val": 10},
	{"code": "dequeue() ? returns 20", "action": "deq", "val": 20},
	{"code": "enqueue(40) ? queue: [30, 40]", "action": "enq", "val": 40},
]

func _set_progress(v): progress = v; queue_redraw()

func _ready():
	var ui = VizUtil.standard_ui(self, " Queue — FIFO (First In, First Out)", 100, 400)
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
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "Queue demo complete!"; queue_redraw(); return
	code_label.text = "?  " + steps[step_idx].code; queue_redraw()
	if not paused: _start_tween()

func _do_step():
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "Queue demo complete!"; return
	code_label.text = "?  " + steps[step_idx].code; progress = 1.0; step_idx += 1; queue_redraw()

func _draw_diag():
	var f = ThemeDB.fallback_font
	diag.draw_string(f, Vector2(16, 20), "queue = []", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_LABEL)
	diag.draw_string(f, Vector2(16, 40), "queue.append(val)   # enqueue (back)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)
	diag.draw_string(f, Vector2(16, 60), "val = queue.pop(0)  # dequeue (front)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_SWAP)
	diag.draw_string(f, Vector2(16, 80), "FIFO: First In, First Out", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_VAL)

func _draw_anim():
	var f = ThemeDB.fallback_font; var w = anim.size.x; var p = progress
	if step_idx == 0 and p == 0.0: _draw_queue([]); return
	var idx = min(step_idx, steps.size() - 1); var s = steps[idx]
	var q = []
	for j in range(1, idx + 1):
		var sj = steps[j]
		if sj.action == "enq": q.append(sj.val)
		elif sj.action == "deq": q.pop_front()
	_draw_queue(q)
	if s.action == "enq":
		anim.draw_string(f, Vector2(20, 20), "enqueue(" + str(s.val) + ") ? rear", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_VAL)
	elif s.action == "deq":
		anim.draw_string(f, Vector2(20, 20), "dequeue() ? " + str(s.val) + " from front", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_SWAP)

func _draw_queue(q):
	var f = ThemeDB.fallback_font; var w = anim.size.x; var h = 400.0
	var bw = 80.0; var bh = 50.0; var gap = 6.0
	var total = max(q.size(), 1) * (bw + gap) - gap
	var sx = (w - total) * 0.5; var y = h * 0.5 - bh * 0.5
	if q.size() == 0:
		anim.draw_rect(Rect2(sx, y, bw, bh), Color(VizUtil.C_MUTED, 0.15))
		anim.draw_rect(Rect2(sx, y, bw, bh), VizUtil.C_MUTED, false, 1.5)
		anim.draw_string(f, Vector2(sx + 8, y + bh * 0.5 + 6), "empty", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_MUTED)
		return
	for i in range(q.size()):
		var x = sx + i * (bw + gap); var col = VizUtil.C_LABEL
		if i == 0: col = VizUtil.lerp_color(VizUtil.C_LABEL, VizUtil.C_SWAP, progress)
		if i == q.size() - 1: col = VizUtil.lerp_color(col, VizUtil.C_VAL, progress)
		anim.draw_rect(Rect2(x, y, bw, bh), Color(col, 0.2))
		anim.draw_rect(Rect2(x, y, bw, bh), col, false, 2.0)
		anim.draw_string(f, Vector2(x + bw * 0.5 - 12, y + bh * 0.5 + 6), str(q[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_TEXT)
	if q.size() > 0:
		VizUtil.draw_arrow(anim, Vector2(sx - 10, y + bh + 24), Vector2(sx - 20, y + bh + 24), VizUtil.C_SWAP)
		anim.draw_string(f, Vector2(sx - 22, y + bh + 36), "FRONT", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VizUtil.C_SWAP)
		var lx = sx + (q.size() - 1) * (bw + gap) + bw
		VizUtil.draw_arrow(anim, Vector2(lx + 10, y + bh + 24), Vector2(lx + 20, y + bh + 24), VizUtil.C_VAL)
		anim.draw_string(f, Vector2(lx + 14, y + bh + 36), "REAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VizUtil.C_VAL)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		if diag: diag.queue_redraw()
		if anim: anim.queue_redraw()
