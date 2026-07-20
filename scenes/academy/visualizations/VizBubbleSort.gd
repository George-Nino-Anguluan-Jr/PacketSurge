extends Control

var diag: Control; var anim: Control; var code_label: Label
var play_btn: Button; var step_btn: Button; var reset_btn: Button
var paused := false; var step_idx := 0; var progress := 0.0; var tween: Tween

var steps = [
	{"code": "arr = [5,3,8,1,2]", "arr": [5,3,8,1,2], "cmp": [-1,-1], "swp": false},
	{"code": "Compare 5 and 3 â†’ 5>3 â†’ SWAP", "arr": [3,5,8,1,2], "cmp": [0,1], "swp": true},
	{"code": "Compare 5 and 8 â†’ 5<8 â†’ no swap", "arr": [3,5,8,1,2], "cmp": [1,2], "swp": false},
	{"code": "Compare 8 and 1 â†’ 8>1 â†’ SWAP", "arr": [3,5,1,8,2], "cmp": [2,3], "swp": true},
	{"code": "Compare 8 and 2 â†’ 8>2 â†’ SWAP", "arr": [3,5,1,2,8], "cmp": [3,4], "swp": true},
	{"code": "Pass 2: Compare 5 and 1 â†’ SWAP", "arr": [3,1,5,2,8], "cmp": [1,2], "swp": true},
	{"code": "Pass 2: Compare 5 and 2 â†’ SWAP", "arr": [3,1,2,5,8], "cmp": [2,3], "swp": true},
	{"code": "Pass 3: Compare 3 and 1 â†’ SWAP", "arr": [1,3,2,5,8], "cmp": [0,1], "swp": true},
	{"code": "Pass 3: Compare 3 and 2 â†’ SWAP", "arr": [1,2,3,5,8], "cmp": [1,2], "swp": true},
]

func _set_progress(v): progress = v; queue_redraw()

func _ready():
	var ui = VizUtil.standard_ui(self, " Bubble Sort â€” Compare & Swap Adjacent", 100, 400)
	diag = ui.diagram; anim = ui.anim; code_label = ui.code; var ctrl = ui.controls
	diag.draw.connect(_draw_diag); anim.draw.connect(_draw_anim)
	play_btn = VizUtil.make_btn("â–¶ Play", VizUtil.C_LABEL); step_btn = VizUtil.make_btn("â­ Step", VizUtil.C_LABEL)
	reset_btn = VizUtil.make_btn("â†º Reset", Color("#FF3366"))
	ctrl.add_child(play_btn); ctrl.add_child(step_btn); ctrl.add_child(reset_btn)
	play_btn.pressed.connect(_on_play); step_btn.pressed.connect(_on_step); reset_btn.pressed.connect(_on_reset)

func _on_play():
	if step_idx >= steps.size(): _on_reset(); return
	paused = not paused; play_btn.text = "â¸ Pause" if not paused else "â–¶ Play"
	if not paused: _start_tween()

func _on_step():
	paused = true; play_btn.text = "â–¶ Play"
	if tween and tween.is_running(): tween.kill(); _do_step()

func _on_reset():
	paused = true; play_btn.text = "â–¶ Play"
	if tween and tween.is_running(): tween.kill()
	step_idx = 0; progress = 0.0; code_label.text = "Press â–¶ Play or â­ Step to begin"; queue_redraw()

func _start_tween():
	if paused or step_idx >= steps.size(): return
	if tween and tween.is_running(): tween.kill()
	tween = create_tween(); tween.tween_method(_set_progress, 0.0, 1.0, 1.0).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_on_tween_done, CONNECT_ONE_SHOT)

func _on_tween_done():
	if step_idx >= steps.size(): return
	step_idx += 1; progress = 0.0
	if step_idx >= steps.size(): paused = true; play_btn.text = "â–¶ Play"; code_label.text = "âœ… Sorted: [1, 2, 3, 5, 8]"; queue_redraw(); return
	code_label.text = "â–¶  " + steps[step_idx].code; queue_redraw()
	if not paused: _start_tween()

func _do_step():
	if step_idx >= steps.size(): paused = true; play_btn.text = "â–¶ Play"; code_label.text = "âœ… Sorted: [1, 2, 3, 5, 8]"; return
	code_label.text = "â–¶  " + steps[step_idx].code; progress = 1.0; step_idx += 1; queue_redraw()

func _draw_diag():
	var f = ThemeDB.fallback_font
	diag.draw_string(f, Vector2(16, 20), "def bubble_sort(arr):", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_LABEL)
	diag.draw_string(f, Vector2(16, 40), "    for i in range(len(arr)-1):", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)
	diag.draw_string(f, Vector2(16, 60), "        for j in range(len(arr)-i-1):", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)
	diag.draw_string(f, Vector2(16, 80), "            if arr[j] > arr[j+1]: swap", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_SWAP)

func _draw_anim():
	var f = ThemeDB.fallback_font; var w = anim.size.x; var p = progress
	if step_idx == 0 and p == 0.0: _draw_bars(steps[0].arr, -1, -1, false, Color("#0D2040")); return
	var idx = min(step_idx, steps.size() - 1); var s = steps[idx]; var arr = s.arr; var is_last = (idx == steps.size() - 1)
	var colors = []
	for i in range(arr.size()):
		var col = VizUtil.C_LABEL
		if i == s.cmp[0] or i == s.cmp[1]:
			if s.swp: col = VizUtil.lerp_color(VizUtil.C_LABEL, VizUtil.C_SWAP, min(p * 2, 1.0))
			else: col = VizUtil.lerp_color(VizUtil.C_LABEL, VizUtil.C_HIGHLIGHT, p)
		elif is_last: col = VizUtil.lerp_color(VizUtil.C_LABEL, VizUtil.C_VAL, p)
		colors.append(col)
	_draw_bars(arr, s.cmp[0], s.cmp[1], s.swp, Color("#0D2040"), colors)
	if s.cmp[0] >= 0:
		var bw = VizUtil.BAR_W; var gap = VizUtil.BAR_GAP; var n = arr.size()
		var total = n * (bw + gap) - gap; var sx = (w - total) * 0.5; var y = 20.0
		var ax = sx + s.cmp[0] * (bw + gap) + bw * 0.5
		var bx = sx + s.cmp[1] * (bw + gap) + bw * 0.5
		var max_val = 0; for v in arr: if typeof(v) == TYPE_INT: max_val = max(max_val, abs(v))
		if max_val == 0: max_val = 1
		var bar_h0 = VizUtil.MIN_BAR_H + (VizUtil.MAX_BAR_H - VizUtil.MIN_BAR_H) * (float(abs(arr[s.cmp[0]])) / float(max_val))
		var bar_h1 = VizUtil.MIN_BAR_H + (VizUtil.MAX_BAR_H - VizUtil.MIN_BAR_H) * (float(abs(arr[s.cmp[1]])) / float(max_val))
		var top_y0 = y + VizUtil.MAX_BAR_H - bar_h0; var top_y1 = y + VizUtil.MAX_BAR_H - bar_h1
		var ay = top_y0 - 12; var by = top_y1 - 12
		if s.swp:
			VizUtil.draw_arrow(anim, Vector2(ax, ay), Vector2(bx, by), VizUtil.C_SWAP)
			if p < 0.7: anim.draw_string(f, Vector2((ax+bx)*0.5-18, ay-14), "SWAP!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(VizUtil.C_SWAP.r, VizUtil.C_SWAP.g, VizUtil.C_SWAP.b, p/0.7))
		else:
			VizUtil.draw_arrow(anim, Vector2(ax, ay), Vector2(bx, by), VizUtil.C_HIGHLIGHT)
			anim.draw_string(f, Vector2((ax+bx)*0.5-24, ay-14), "No swap", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(VizUtil.C_HIGHLIGHT.r, VizUtil.C_HIGHLIGHT.g, VizUtil.C_HIGHLIGHT.b, p))

func _draw_bars(arr, c0, c1, swp, bg_col, colors = []):
	var f = ThemeDB.fallback_font; var w = anim.size.x
	var bw = VizUtil.BAR_W; var gap = VizUtil.BAR_GAP; var n = arr.size()
	var total = n * (bw + gap) - gap; var sx = (w - total) * 0.5; var y = 20.0
	var max_val = 0; for v in arr: if typeof(v) == TYPE_INT: max_val = max(max_val, abs(v))
	if max_val == 0: max_val = 1
	for i in range(n):
		var val = arr[i]
		var bar_h = VizUtil.MIN_BAR_H + (VizUtil.MAX_BAR_H - VizUtil.MIN_BAR_H) * (float(abs(val)) / float(max_val))
		var x = sx + i * (bw + gap)
		var by = y + VizUtil.MAX_BAR_H - bar_h
		var col = colors[i] if colors.size() > i else VizUtil.C_LABEL
		var dx = x
		if swp and progress > 0.0 and progress < 1.0:
			if i == c0: dx += (bw + gap) * progress * 0.5
			elif i == c1: dx -= (bw + gap) * progress * 0.5
		anim.draw_rect(Rect2(dx, by, bw, bar_h), Color(col, 0.18))
		anim.draw_rect(Rect2(dx, by, bw, bar_h), col, false, 2.0)
		anim.draw_string(f, Vector2(dx + 4, by - 6), "[" + str(i) + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VizUtil.C_MUTED)
		var label = str(val); var lw = label.length() * 8
		anim.draw_string(f, Vector2(dx + bw * 0.5 - lw * 0.5, by + bar_h * 0.5 + 6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_TEXT)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		if diag: diag.queue_redraw()
		if anim: anim.queue_redraw()
