extends Control

var diag: Control; var anim: Control; var code_label: Label
var play_btn: Button; var step_btn: Button; var reset_btn: Button
var paused := false; var step_idx := 0; var progress := 0.0; var tween: Tween

var steps = [
	{"code": "for i in range(3):", "i": -1},
	{"code": "i = 0 ? print(i) ? 0", "i": 0},
	{"code": "i = 1 ? print(i) ? 1", "i": 1},
	{"code": "i = 2 ? print(i) ? 2", "i": 2},
	{"code": "Loop complete! 0, 1, 2 printed.", "i": -2},
]

func _set_progress(v): progress = v; queue_redraw()

func _ready():
	var ui = VizUtil.standard_ui(self, " For Loop — Iterate Over Range", 100, 400)
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
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "Loop complete! 0, 1, 2 printed."; queue_redraw(); return
	code_label.text = "?  " + steps[step_idx].code; queue_redraw()
	if not paused: _start_tween()

func _do_step():
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "Loop complete! 0, 1, 2 printed."; return
	code_label.text = "?  " + steps[step_idx].code; progress = 1.0; step_idx += 1; queue_redraw()

func _draw_diag():
	var f = ThemeDB.fallback_font
	diag.draw_string(f, Vector2(16, 20), "for i in range(3):", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_LABEL)
	diag.draw_string(f, Vector2(16, 40), "    print(i)  # 0, 1, 2", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)
	diag.draw_string(f, Vector2(16, 60), "for fruit in fruits:", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_SWAP)
	diag.draw_string(f, Vector2(16, 80), "    print(fruit)  # iterate elements", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)

func _draw_anim():
	var f = ThemeDB.fallback_font; var w = anim.size.x; var p = progress
	if step_idx == 0 and p == 0.0: _draw_loop(-1); return
	var idx = min(step_idx, steps.size() - 1); var i_val = steps[idx].i
	_draw_loop(i_val)

func _draw_loop(i_val):
	var f = ThemeDB.fallback_font; var w = anim.size.x; var h = 400.0
	var bw = 70.0; var bh = 50.0; var gap = 6.0
	var vals = [0, 1, 2]
	var total = vals.size() * (bw + gap) - gap; var sx = (w - total) * 0.5; var y = h * 0.5 - bh * 0.5
	for i in range(vals.size()):
		var x = sx + i * (bw + gap); var col = VizUtil.C_LABEL
		if i == i_val: col = VizUtil.lerp_color(VizUtil.C_LABEL, VizUtil.C_HIGHLIGHT, progress)
		elif i < i_val: col = VizUtil.C_VAL
		anim.draw_rect(Rect2(x, y, bw, bh), Color(col, 0.15))
		anim.draw_rect(Rect2(x, y, bw, bh), col, false, 2.0)
		anim.draw_string(f, Vector2(x + bw * 0.5 - 12, y + bh * 0.5 + 6), "i=" + str(vals[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_TEXT)
	if i_val >= 0:
		var ax = sx + i_val * (bw + gap) + bw * 0.5
		VizUtil.draw_arrow(anim, Vector2(ax, y + bh + 16), Vector2(ax, y + bh + 6), VizUtil.C_HIGHLIGHT)
		anim.draw_string(f, Vector2(ax - 20, y + bh + 28), "current", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_HIGHLIGHT)
	if i_val == -2:
		anim.draw_string(f, Vector2(w * 0.5 - 60, y - 20), "Output: 0 1 2", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, VizUtil.C_VAL)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		if diag: diag.queue_redraw()
		if anim: anim.queue_redraw()
