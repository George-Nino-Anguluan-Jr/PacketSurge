extends Control

var diag: Control; var anim: Control; var code_label: Label
var play_btn: Button; var step_btn: Button; var reset_btn: Button
var paused := false; var step_idx := 0; var progress := 0.0; var tween: Tween

var steps = [
	{"code": "arr = [1, 3, 5, 7, 9]; target = 7", "arr": [1,3,5,7,9], "lo": 0, "hi": 4, "mid": -1},
	{"code": "mid=(0+4)//2=2 ? arr[2]=5 < 7 ? lo=mid+1", "arr": [1,3,5,7,9], "lo": 3, "hi": 4, "mid": 2},
	{"code": "mid=(3+4)//2=3 ? arr[3]=7 == 7 ? FOUND!", "arr": [1,3,5,7,9], "lo": 3, "hi": 4, "mid": 3},
	{"code": "Found 7 at index 3!", "arr": [1,3,5,7,9], "lo": -1, "hi": -1, "mid": 3},
]

func _set_progress(v): progress = v; queue_redraw()

func _ready():
	var ui = VizUtil.standard_ui(self, " Binary Search — Divide & Conquer", 100, 400)
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
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "Found 7 at index 3!"; queue_redraw(); return
	code_label.text = "?  " + steps[step_idx].code; queue_redraw()
	if not paused: _start_tween()

func _do_step():
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "Found 7 at index 3!"; return
	code_label.text = "?  " + steps[step_idx].code; progress = 1.0; step_idx += 1; queue_redraw()

func _draw_diag():
	var f = ThemeDB.fallback_font
	diag.draw_string(f, Vector2(16, 20), "def binary_search(arr, target):", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_LABEL)
	diag.draw_string(f, Vector2(16, 40), "    lo, hi = 0, len(arr)-1", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)
	diag.draw_string(f, Vector2(16, 60), "    while lo <= hi:", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)
	diag.draw_string(f, Vector2(16, 80), "        mid = (lo+hi)//2", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_SWAP)
	diag.draw_string(f, Vector2(16, 98), "        if arr[mid] == target: return mid", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_VAL)

func _draw_anim():
	var f = ThemeDB.fallback_font; var w = anim.size.x; var p = progress
	if step_idx == 0 and p == 0.0: _draw_bars(steps[0].arr, -1, 0, 4); return
	var idx = min(step_idx, steps.size() - 1); var s = steps[idx]; var arr = s.arr
	var colors = []
	for i in range(arr.size()):
		var col = VizUtil.C_LABEL
		if i == s.mid and arr[i] == 7: col = VizUtil.lerp_color(VizUtil.C_LABEL, VizUtil.C_VAL, p)
		elif i == s.mid: col = VizUtil.lerp_color(VizUtil.C_LABEL, VizUtil.C_HIGHLIGHT, p)
		elif s.lo >= 0 and s.hi >= 0 and i >= s.lo and i <= s.hi: col = VizUtil.lerp_color(VizUtil.C_LABEL, VizUtil.C_MUTED, 0.4)
		colors.append(col)
	_draw_bars(arr, s.mid, s.lo, s.hi, colors)
	if s.mid >= 0 and s.lo >= 0 and s.hi >= 0:
		var bw = VizUtil.BAR_W; var gap = VizUtil.BAR_GAP; var n = arr.size()
		var total = n * (bw + gap) - gap; var sx = (w - total) * 0.5
		var lx = sx + s.lo * (bw + gap) + bw * 0.5
		var hx = sx + s.hi * (bw + gap) + bw * 0.5
		anim.draw_line(Vector2(lx, 20 + VizUtil.MAX_BAR_H + 10), Vector2(hx, 20 + VizUtil.MAX_BAR_H + 10), VizUtil.C_HIGHLIGHT, 2.0)
		anim.draw_string(f, Vector2((lx+hx)*0.5-30, 20 + VizUtil.MAX_BAR_H + 28), "search range", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_HIGHLIGHT)

func _draw_bars(arr, mid, lo, hi, colors = []):
	var f = ThemeDB.fallback_font; var w = anim.size.x
	var bw = VizUtil.BAR_W; var gap = VizUtil.BAR_GAP; var n = arr.size()
	var total = n * (bw + gap) - gap; var sx = (w - total) * 0.5; var y = 20.0
	var max_val = 0; for v in arr: if typeof(v) == TYPE_INT: max_val = max(max_val, abs(v))
	if max_val == 0: max_val = 1
	for i in range(n):
		var val = arr[i]; var bar_h = VizUtil.MIN_BAR_H + (VizUtil.MAX_BAR_H - VizUtil.MIN_BAR_H) * (float(abs(val)) / float(max_val))
		var x = sx + i * (bw + gap); var by = y + VizUtil.MAX_BAR_H - bar_h
		var col = colors[i] if colors.size() > i else VizUtil.C_LABEL
		anim.draw_rect(Rect2(x, by, bw, bar_h), Color(col, 0.18))
		anim.draw_rect(Rect2(x, by, bw, bar_h), col, false, 2.0)
		anim.draw_string(f, Vector2(x + 4, by - 6), "[" + str(i) + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VizUtil.C_MUTED)
		var label = str(val); var lw = label.length() * 8
		anim.draw_string(f, Vector2(x + bw * 0.5 - lw * 0.5, by + bar_h * 0.5 + 6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_TEXT)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		if diag: diag.queue_redraw()
		if anim: anim.queue_redraw()
