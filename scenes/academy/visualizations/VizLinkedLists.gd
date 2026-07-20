extends Control

var diag: Control; var anim: Control; var code_label: Label
var play_btn: Button; var step_btn: Button; var reset_btn: Button
var paused := false; var step_idx := 0; var progress := 0.0; var tween: Tween

var steps = [
	{"code": "head ? [10|·] ? null", "arr": [10], "h": 0},
	{"code": "insert 20 at head ? [20|·] ? [10|/]", "arr": [20, 10], "h": 0},
	{"code": "insert 30 at head ? [30|·] ? [20|·] ? [10|/]", "arr": [30, 20, 10], "h": 0},
	{"code": "head ? [20|·] ? [10|/] (removed 30)", "arr": [20, 10], "h": 0},
	{"code": "head ? [10|/] (removed 20)", "arr": [10], "h": 0},
]

func _set_progress(v): progress = v; queue_redraw()

func _ready():
	var ui = VizUtil.standard_ui(self, " Linked List — Nodes with Pointers", 100, 400)
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
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "Linked list demo complete!"; queue_redraw(); return
	code_label.text = "?  " + steps[step_idx].code; queue_redraw()
	if not paused: _start_tween()

func _do_step():
	if step_idx >= steps.size(): paused = true; play_btn.text = "? Play"; code_label.text = "Linked list demo complete!"; return
	code_label.text = "?  " + steps[step_idx].code; progress = 1.0; step_idx += 1; queue_redraw()

func _draw_diag():
	var f = ThemeDB.fallback_font
	diag.draw_string(f, Vector2(16, 20), "class Node:", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_LABEL)
	diag.draw_string(f, Vector2(16, 40), "    def __init__(self, val):", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)
	diag.draw_string(f, Vector2(16, 60), "        self.val = val", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_TEXT)
	diag.draw_string(f, Vector2(16, 80), "        self.next = None", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_SWAP)

func _draw_anim():
	var f = ThemeDB.fallback_font; var w = anim.size.x; var p = progress
	if step_idx == 0 and p == 0.0: _draw_list([10], 0); return
	var idx = min(step_idx, steps.size() - 1); var s = steps[idx]
	_draw_list(s.arr, s.h)

func _draw_list(arr, head):
	var f = ThemeDB.fallback_font; var w = anim.size.x; var h = 400.0
	var bw = 80.0; var bh = 50.0; var gap = 30.0
	var total = arr.size() * (bw + gap) - gap; var sx = (w - total) * 0.5; var y = h * 0.5 - bh * 0.5
	if arr.size() == 0:
		anim.draw_string(f, Vector2(w * 0.5 - 20, y), "null", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_MUTED)
		return
	for i in range(arr.size()):
		var x = sx + i * (bw + gap); var col = VizUtil.C_LABEL
		if i == head: col = VizUtil.lerp_color(VizUtil.C_LABEL, VizUtil.C_HIGHLIGHT, progress)
		anim.draw_rect(Rect2(x, y, bw - 20, bh), Color(col, 0.2))
		anim.draw_rect(Rect2(x, y, bw - 20, bh), col, false, 2.0)
		anim.draw_rect(Rect2(x + bw - 20, y, 20, bh), Color(VizUtil.C_MUTED, 0.15))
		anim.draw_rect(Rect2(x + bw - 20, y, 20, bh), VizUtil.C_MUTED, false, 1.5)
		anim.draw_string(f, Vector2(x + 8, y + bh * 0.5 + 6), str(arr[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_TEXT)
		if i < arr.size() - 1:
			var arrow_from = Vector2(x + bw + 2, y + bh * 0.5)
			var arrow_to = Vector2(x + bw + gap - 8, y + bh * 0.5)
			VizUtil.draw_arrow(anim, arrow_from, arrow_to, VizUtil.C_MUTED)
			anim.draw_string(f, Vector2(x + bw + 6, y + bh * 0.5 - 10), "next", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, VizUtil.C_MUTED)
		else:
			anim.draw_string(f, Vector2(x + bw, y + bh * 0.5 + 6), "null", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, VizUtil.C_MUTED)
	anim.draw_string(f, Vector2(sx - 40, y + bh * 0.5 + 6), "head?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, VizUtil.C_HIGHLIGHT)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		if diag: diag.queue_redraw()
		if anim: anim.queue_redraw()
