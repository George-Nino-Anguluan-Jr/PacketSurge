extends Control

var diag: Control; var anim: Control; var code_label: Label
var play_btn: Button; var step_btn: Button; var reset_btn: Button
var paused := false; var step_idx := 0; var progress := 0.0; var tween: Tween

var steps = [
	{"code": "arr = [8,3,5,1,2]", "arr": [8,3,5,1,2], "min": 0, "cmp": -1, "swp": -1},
	{"code": "Scan: min=0(8), compare 3<8 ? min=1", "arr": [8,3,5,1,2], "min": 1, "cmp": 1, "swp": -1},
	{"code": "Scan: compare 5>3 ? min stays 1", "arr": [8,3,5,1,2], "min": 1, "cmp": 2, "swp": -1},
	{"code": "Scan: compare 1<3 ? min=3", "arr": [8,3,5,1,2], "min": 3, "cmp": 3, "swp": -1},
	{"code": "Scan: compare 2>1 ? min stays 3", "arr": [8,3,5,1,2], "min": 3, "cmp": 4, "swp": -1},
	{"code": "Swap arr[0]=8 with arr[3]=1", "arr": [1,3,5,8,2], "min": 0, "cmp": -1, "swp": 3},
	{"code": "Pass 2: min=1(3), compare 3<5 ? min stays 1", "arr": [1,3,5,8,2], "min": 1, "cmp": 2, "swp": -1},
	{"code": "Pass 2: compare 3<8 ? min stays 1", "arr": [1,3,5,8,2], "min": 1, "cmp": 3, "swp": -1},
	{"code": "Pass 2: compare 2<3 ? min=4", "arr": [1,3,5,8,2], "min": 4, "cmp": 4, "swp": -1},
	{"code": "Swap arr[1]=3 with arr[4]=2", "arr": [1,2,5,8,3], "min": 1, "cmp": -1, "swp": 4},
	{"code": "Pass 3: min=2(5), compare 5<8 ? min stays 2", "arr": [1,2,5,8,3], "min": 2, "cmp": 3, "swp": -1},
	{"code": "Pass 3: compare 3<5 ? min=4", "arr": [1,2,5,8,3], "min": 4, "cmp": 4, "swp": -1},
	{"code": "Swap arr[2]=5 with arr[4]=3", "arr": [1,2,3,8,5], "min": 2, "cmp": -1, "swp": 4},
	{"code": "Pass 4: compare 8>5 ? min=4", "arr": [1,2,3,8,5], "min": 4, "cmp": 4, "swp": -1},
	{"code": "Swap arr[3]=8 with arr[4]=5", "arr": [1,2,3,5,8], "min": 3, "cmp": -1, "swp": 4},
]

func _set_progress(v): progress = v; queue_redraw()

func _ready():
	var ui = VizUtil.standard_ui(self, " Selection Sort — Find Minimum & Swap", 100, 400)
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
	tween = create_tween(); tween.tween_method(_set_progress, 0.0, 1.0, 1.0).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_on_tween_done, CONNECT_ONE_SHOT)

func _on_tween_done():
	if step_idx >= steps.size(): return
	step_idx += 1; progress = 0.0
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "? Sorted: [1, 2, 3, 5, 8]"; queue_redraw(); return
	code_label.text = "?  " + steps[step_idx].code; queue_redraw()
	if not paused: _start_tween()

func _do_step():
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "? Sorted: [1, 2, 3, 5, 8]"; return
	code_label.text = "?  " + steps[step_idx].code; progress = 1.0; step_idx += 1; queue_redraw()

func _draw_diag():
	var f = ThemeDB.fallback_font
	diag.draw_string(f, Vector2(16, 20), "def selection_sort(arr):", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_LABEL)
	diag.draw_string(f, Vector2(16, 40), "    for i in range(len(arr)):", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)
	diag.draw_string(f, Vector2(16, 60), "        min_idx = i", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)
	diag.draw_string(f, Vector2(16, 80), "        for j in range(i+1, len(arr)):", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)
	diag.draw_string(f, Vector2(16, 98), "            if arr[j] < arr[min_idx]: min_idx = j", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, VizUtil.C_SWAP)

func _draw_anim():
	var f = ThemeDB.fallback_font; var w = anim.size.x; var p = progress
	if step_idx == 0 and p == 0.0: _draw_bars(steps[0].arr, -1, -1, -1); return
	var idx = min(step_idx, steps.size() - 1); var s = steps[idx]; var arr = s.arr; var is_last = (idx == steps.size() - 1)
	var colors = []
	for i in range(arr.size()):
		var col = VizUtil.C_LABEL
		if i == s.cmp: col = VizUtil.lerp_color(VizUtil.C_LABEL, VizUtil.C_HIGHLIGHT, p)
		elif i == s.min: col = VizUtil.lerp_color(VizUtil.C_LABEL, VizUtil.C_VAL, p)
		elif is_last: col = VizUtil.lerp_color(VizUtil.C_LABEL, VizUtil.C_VAL, p)
		colors.append(col)
	_draw_bars(arr, s.min, s.swp, s.cmp, colors)
	if s.cmp >= 0:
		var bw = VizUtil.BAR_W; var gap = VizUtil.BAR_GAP; var n = arr.size()
		var total = n * (bw + gap) - gap; var sx = (w - total) * 0.5
		var cx = sx + s.cmp * (bw + gap) + bw * 0.5
		VizUtil.draw_pointer(anim, Vector2(cx, 20 + VizUtil.MAX_BAR_H + 8), "checking", VizUtil.C_HIGHLIGHT, f)
	if s.min >= 0 and s.cmp == -1:
		var bw = VizUtil.BAR_W; var gap = VizUtil.BAR_GAP; var n = arr.size()
		var total = n * (bw + gap) - gap; var sx = (w - total) * 0.5
		var mx = sx + s.min * (bw + gap) + bw * 0.5
		VizUtil.draw_pointer(anim, Vector2(mx, 20 + VizUtil.MAX_BAR_H + 8), "min", VizUtil.C_VAL, f)

func _draw_bars(arr, min_idx, swp_idx, cmp_idx, colors = []):
	var f = ThemeDB.fallback_font; var w = anim.size.x
	var bw = VizUtil.BAR_W; var gap = VizUtil.BAR_GAP; var n = arr.size()
	var total = n * (bw + gap) - gap; var sx = (w - total) * 0.5; var y = 20.0
	var max_val = 0; for v in arr: if typeof(v) == TYPE_INT: max_val = max(max_val, abs(v))
	if max_val == 0: max_val = 1
	for i in range(n):
		var val = arr[i]; var bar_h = VizUtil.MIN_BAR_H + (VizUtil.MAX_BAR_H - VizUtil.MIN_BAR_H) * (float(abs(val)) / float(max_val))
		var x = sx + i * (bw + gap); var by = y + VizUtil.MAX_BAR_H - bar_h
		var col = colors[i] if colors.size() > i else VizUtil.C_LABEL
		var dx = x
		if swp_idx >= 0 and progress > 0.0 and progress < 1.0:
			if i == min_idx: dx += (bw + gap) * progress * 0.5
			elif i == swp_idx: dx -= (bw + gap) * progress * 0.5
		anim.draw_rect(Rect2(dx, by, bw, bar_h), Color(col, 0.18))
		anim.draw_rect(Rect2(dx, by, bw, bar_h), col, false, 2.0)
		anim.draw_string(f, Vector2(dx + 4, by - 6), "[" + str(i) + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VizUtil.C_MUTED)
		var label = str(val); var lw = label.length() * 8
		anim.draw_string(f, Vector2(dx + bw * 0.5 - lw * 0.5, by + bar_h * 0.5 + 6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_TEXT)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		if diag: diag.queue_redraw()
		if anim: anim.queue_redraw()
