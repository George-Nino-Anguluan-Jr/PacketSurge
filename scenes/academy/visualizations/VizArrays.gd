extends Control

var diag: Control; var anim: Control; var code_label: Label
var play_btn: Button; var step_btn: Button; var reset_btn: Button
var paused := false; var step_idx := 0; var progress := 0.0; var tween: Tween
var expanded := false

var steps = [
	{"code": "arr = [10, 20, 30, 40, 50]", "h": -1},
	{"code": "arr[0] = 10 (O(1) access!)", "h": 0},
	{"code": "arr[2] = 30", "h": 2},
	{"code": "arr[4] = 50", "h": 4},
	{"code": "arr.append(60) ? add to end", "h": 5},
	{"code": "arr[5] = 60 ?", "h": 5},
]

func _set_progress(v): progress = v; queue_redraw()

func _ready():
	var ui = VizUtil.standard_ui(self, " Array — Index Access (O(1))", 100, 400)
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
	step_idx = 0; progress = 0.0; expanded = false; code_label.text = "Press ? Play or ? Step to begin"; queue_redraw()

func _start_tween():
	if paused or step_idx >= steps.size(): return
	if tween and tween.is_running(): tween.kill()
	tween = create_tween(); tween.tween_method(_set_progress, 0.0, 1.0, 0.7).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_on_tween_done, CONNECT_ONE_SHOT)

func _on_tween_done():
	if step_idx >= steps.size(): return
	if step_idx == 4: expanded = true
	step_idx += 1; progress = 0.0
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "Array operations complete!"; queue_redraw(); return
	code_label.text = "?  " + steps[step_idx].code; queue_redraw()
	if not paused: _start_tween()

func _do_step():
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "Array operations complete!"; return
	if step_idx == 4: expanded = true
	code_label.text = "?  " + steps[step_idx].code; progress = 1.0; step_idx += 1; queue_redraw()

func _draw_diag():
	var f = ThemeDB.fallback_font; var w = diag.size.x
	var vals = [10, 20, 30, 40, 50]; var bw = 56.0; var total = vals.size() * (bw + 4) - 4
	var sx = (w - total) * 0.5; var y = 20.0
	diag.draw_string(f, Vector2(sx - 14, y - 10), "arr =", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, VizUtil.C_MUTED)
	for i in range(vals.size()):
		var x = sx + i * (bw + 4)
		diag.draw_rect(Rect2(x, y, bw, 44), Color("#0D2040"))
		diag.draw_rect(Rect2(x, y, bw, 44), VizUtil.C_MUTED, false, 1.5)
		diag.draw_string(f, Vector2(x + 6, y - 8), "[" + str(i) + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VizUtil.C_MUTED)
		diag.draw_string(f, Vector2(x + 14, y + 18), str(vals[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_VAL)

func _draw_anim():
	var f = ThemeDB.fallback_font; var w = anim.size.x; var p = progress
	if step_idx == 0 and p == 0.0: _draw_array([10, 20, 30, 40, 50], -1, 44); return
	var idx = min(step_idx, steps.size() - 1); var h = steps[idx].h
	var vals = [10, 20, 30, 40, 50]; if expanded: vals = [10, 20, 30, 40, 50, 60]
	var bh = max(44.0, min(120.0, VizUtil.MAX_BAR_H * float(60) / 60.0))
	_draw_array(vals, h, bh)
	if h >= 0:
		var bw = 56.0; var gap = 6.0; var total = vals.size() * (bw + gap) - gap
		var sx = (w - total) * 0.5; var y = 60.0
		var ax = sx + min(h, vals.size()-1) * (bw + gap) + bw * 0.5
		var arrow_y = y + bh + 4
		VizUtil.draw_arrow(anim, Vector2(ax, arrow_y + 20), Vector2(ax, arrow_y), VizUtil.C_HIGHLIGHT)
		anim.draw_string(f, Vector2(ax - 20, arrow_y + 38), "arr[" + str(h) + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, VizUtil.C_HIGHLIGHT)

func _draw_array(vals, highlight, bh):
	var f = ThemeDB.fallback_font; var w = anim.size.x
	var bw = 56.0; var gap = 6.0
	var total = vals.size() * (bw + gap) - gap; var sx = (w - total) * 0.5; var y = 60.0
	var p = progress
	for i in range(vals.size()):
		var x = sx + i * (bw + gap); var col = VizUtil.C_LABEL
		if i == highlight: col = VizUtil.lerp_color(VizUtil.C_LABEL, VizUtil.C_HIGHLIGHT, p)
		if i == 5 and expanded: col = VizUtil.lerp_color(VizUtil.C_MUTED, VizUtil.C_VAL, p)
		anim.draw_rect(Rect2(x, y, bw, bh), Color(col, 0.15))
		anim.draw_rect(Rect2(x, y, bw, bh), col, false, 1.5)
		anim.draw_string(f, Vector2(x + 4, y - 8), "[" + str(i) + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VizUtil.C_MUTED)
		anim.draw_string(f, Vector2(x + 14, y + bh * 0.5 + 5), str(vals[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_TEXT)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		if diag: diag.queue_redraw()
		if anim: anim.queue_redraw()
