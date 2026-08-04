# SafeZoneDebug.gd
# Debug-only UI safe-zone overlay. Draws the critical 16:9 core band (the
# area visible on every supported phone) so layouts can be verified at
# different aspect ratios. Toggle with F3. Add as an autoload.
#
# On a 16:9 phone the band fills the whole canvas; on 19.5:9 / 20:9 phones
# the sides outside the band are extra "wide-screen only" space. Content
# should stay inside the band to survive every device.
extends Node

const DEBUG_KEY := KEY_F3

var _overlay: Control

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	var overlay := SafeZoneOverlay.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)
	get_tree().root.add_child(layer)
	_overlay = overlay

func _input(event: InputEvent) -> void:
	if _overlay == null:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == DEBUG_KEY:
		_overlay.visible = not _overlay.visible
		_overlay.queue_redraw()

class SafeZoneOverlay extends Control:
	func _draw() -> void:
		if not visible:
			return
		var vp := get_viewport_rect()
		# 16:9 core — the width visible on the narrowest supported aspect.
		var safe_w := minf(vp.size.x, vp.size.y * 16.0 / 9.0)
		var safe_x := (vp.size.x - safe_w) / 2.0
		draw_rect(Rect2(safe_x, 0, safe_w, vp.size.y), Color(1, 0.2, 0.2, 0.35), false, 2.0)
		# Screen bounds reference
		draw_rect(Rect2(0, 0, vp.size.x, vp.size.y), Color(0.2, 0.8, 1, 0.3), false, 1.0)
