extends Control

var diag: Control; var anim: Control; var code_label: Label
var play_btn: Button; var step_btn: Button; var reset_btn: Button
var paused := false; var step_idx := 0; var progress := 0.0; var tween: Tween

var steps = [
	{"code": "fruits = ['apple', 'banana', 'cherry']", "h": -1, "vals": ["apple","banana","cherry"]},
	{"code": "fruits[0] = 'apple'", "h": 0, "vals": ["apple","banana","cherry"]},
	{"code": "fruits[1] = 'banana'", "h": 1, "vals": ["apple","banana","cherry"]},
	{"code": "fruits[2] = 'cherry'", "h": 2, "vals": ["apple","banana","cherry"]},
	{"code": "fruits.append('date')", "h": 3, "vals": ["apple","banana","cherry","date"]},
	{"code": "len(fruits) = 4", "h": -1, "vals": ["apple","banana","cherry","date"]},
]

func _set_progress(v): progress = v; queue_redraw()

func _ready():
	var ui = VizUtil.standard_ui(self, " Python Lists — Ordered & Mutable", 100, 400)
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
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "List demo complete!"; queue_redraw(); return
	code_label.text = "?  " + steps[step_idx].code; queue_redraw()
	if not paused: _start_tween()

func _do_step():
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "List demo complete!"; return
	code_label.text = "?  " + steps[step_idx].code; progress = 1.0; step_idx += 1; queue_redraw()

func _draw_diag():
	var f = ThemeDB.fallback_font
	diag.draw_string(f, Vector2(16, 20), "fruits = ['apple', 'banana', 'cherry']", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_LABEL)
	diag.draw_string(f, Vector2(16, 40), "fruits[0]  # = 'apple'  (index access)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)
	diag.draw_string(f, Vector2(16, 60), "fruits.append('date')  # add to end", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_SWAP)
	diag.draw_string(f, Vector2(16, 80), "len(fruits)  # = 4  (dynamic size)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_VAL)

func _draw_anim():
	var f = ThemeDB.fallback_font; var w = anim.size.x; var p = progress
	if step_idx == 0 and p == 0.0: _draw_items(["apple","banana","cherry"], -1); return
	var idx = min(step_idx, steps.size() - 1); var s = steps[idx]; var vals = s.vals
	_draw_items(vals, s.h)
	if s.h >= 0 and s.h < vals.size():
		var bw = 90.0; var gap = 6.0; var total = vals.size() * (bw + gap) - gap
		var sx = (w - total) * 0.5; var y = 60.0
		var ax = sx + s.h * (bw + gap) + bw * 0.5
		VizUtil.draw_pointer(anim, Vector2(ax, y + 44 + 4), "fruits[" + str(s.h) + "]", VizUtil.C_HIGHLIGHT, f)

func _draw_items(vals, highlight):
	var f = ThemeDB.fallback_font; var w = anim.size.x
	var bw = 90.0; var bh = 44.0; var gap = 6.0
	var total = vals.size() * (bw + gap) - gap; var sx = (w - total) * 0.5; var y = 60.0
	var p = progress
	for i in range(vals.size()):
		var x = sx + i * (bw + gap); var col = VizUtil.C_LABEL
		if i == highlight: col = VizUtil.lerp_color(VizUtil.C_LABEL, VizUtil.C_HIGHLIGHT, p)
		anim.draw_rect(Rect2(x, y, bw, bh), Color(col, 0.15))
		anim.draw_rect(Rect2(x, y, bw, bh), col, false, 1.5)
		anim.draw_string(f, Vector2(x + 4, y - 8), "[" + str(i) + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VizUtil.C_MUTED)
		var label = str(vals[i])
		anim.draw_string(f, Vector2(x + 6, y + bh * 0.5 + 6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		if diag: diag.queue_redraw()
		if anim: anim.queue_redraw()
