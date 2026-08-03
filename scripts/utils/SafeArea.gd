# SafeArea.gd
# Root-of-UI helper: keeps children inside the device safe area
# (notches, cutouts, rounded corners, gesture bars).
#
# Usage: attach to a full-rect MarginContainer at the root of a UI tree.
# Keep the background OUTSIDE this container so it still spans the full
# screen behind the safe area. Safe-area math runs on iOS/Android only.
extends MarginContainer

## Extra padding added on every side on top of the reported safe area inset.
@export var buffer_margin: int = 0

var _is_mobile := false

func _ready() -> void:
	var os := OS.get_name()
	_is_mobile = os == "iOS" or os == "Android"
	if _is_mobile:
		update()
		get_viewport().size_changed.connect(_update_safe_area)

func _exit_tree() -> void:
	var vp := get_viewport()
	if vp and vp.size_changed.is_connected(_update_safe_area):
		vp.size_changed.disconnect(_update_safe_area)

func _update_safe_area() -> void:
	update()

func update() -> void:
	if not _is_mobile or not get_viewport():
		return
	var screen_safe_rect := Rect2(DisplayServer.get_display_safe_area())
	var viewport_transform := get_viewport().get_final_transform()
	var viewport_safe_rect := screen_safe_rect * viewport_transform.affine_inverse()
	var viewport_full_rect := get_viewport().get_visible_rect()
	var left := viewport_safe_rect.position.x - viewport_full_rect.position.x
	var top := viewport_safe_rect.position.y - viewport_full_rect.position.y
	var right := viewport_full_rect.end.x - viewport_safe_rect.end.x
	var bottom := viewport_full_rect.end.y - viewport_safe_rect.end.y
	begin_bulk_theme_override()
	add_theme_constant_override("margin_left", roundi(left) + buffer_margin)
	add_theme_constant_override("margin_top", roundi(top) + buffer_margin)
	add_theme_constant_override("margin_right", roundi(right) + buffer_margin)
	add_theme_constant_override("margin_bottom", roundi(bottom) + buffer_margin)
	end_bulk_theme_override()
