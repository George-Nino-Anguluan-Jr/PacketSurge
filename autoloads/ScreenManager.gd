# ScreenManager.gd
# Detects screen size and orientation for responsive layouts
extends Node

const MOBILE_WIDTH_THRESHOLD  := 600
const TABLET_WIDTH_THRESHOLD  := 1024

signal orientation_changed(is_portrait: bool)

var _last_size := Vector2.ZERO

func _ready() -> void:
	get_tree().root.size_changed.connect(_on_screen_resized)
	_last_size = get_viewport().get_visible_rect().size

func _on_screen_resized() -> void:
	var new_size = get_viewport().get_visible_rect().size
	var was_portrait = _last_size.x < _last_size.y
	var is_portrait  = new_size.x < new_size.y
	if was_portrait != is_portrait:
		orientation_changed.emit(is_portrait)
	_last_size = new_size

func get_screen_size() -> Vector2:
	return get_viewport().get_visible_rect().size

func is_mobile() -> bool:
	return get_screen_size().x < MOBILE_WIDTH_THRESHOLD

func is_tablet() -> bool:
	var w = get_screen_size().x
	return w >= MOBILE_WIDTH_THRESHOLD and w < TABLET_WIDTH_THRESHOLD

func is_desktop() -> bool:
	return get_screen_size().x >= TABLET_WIDTH_THRESHOLD

func is_portrait() -> bool:
	var size = get_screen_size()
	return size.x < size.y

func is_landscape() -> bool:
	return not is_portrait()
