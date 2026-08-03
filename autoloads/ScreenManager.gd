# ScreenManager.gd
extends Node

# ─── REFERENCE RESOLUTIONS ─────────────────────────────
# Desktop design matches the project viewport (project.godot:
# window/size/viewport_width x height).
const BASE_WIDTH: float  = 1280.0
const BASE_HEIGHT: float = 720.0

# Mobile/tablet render against a smaller, fixed design size so the UI reads
# larger on phones than on desktop, while staying pixel-identical on every
# device (the scale factor self-normalizes to this size).
# Lower these to make phone UI bigger:
#   1152x648 = +11%   1024x576 = +25%   960x540 = +33%   854x480 = +50%
const MOBILE_WIDTH: float  = 1024.0
const MOBILE_HEIGHT: float = 576.0

func _ready() -> void:
	# Force landscape orientation on mobile devices
	if OS.has_feature("mobile") or OS.has_feature("Android") or OS.has_feature("iOS"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	
	# Dynamically adjust content scale factor for mobile devices so texts and icons are legible
	update_content_scale()
	get_window().size_changed.connect(update_content_scale)

func update_content_scale() -> void:
	var size = get_screen_size()

	if is_mobile() or is_tablet() or OS.has_feature("web"):
		# Self-normalize to the fixed mobile design size. For any window this
		# yields the SAME effective canvas on every phone (no floors, no
		# per-device drift), and because it is smaller than the desktop design
		# the UI renders larger on phones.
		var scale_x = size.x / MOBILE_WIDTH
		var scale_y = size.y / MOBILE_HEIGHT
		get_window().content_scale_factor = min(scale_x, scale_y)
	else:
		# Desktop uses Godot's built-in stretch mode — no manual content scale needed
		return

# ─── SCREEN SIZE ───────────────────────────────────────
func get_screen_size() -> Vector2:
	return DisplayServer.window_get_size()

func get_scale() -> float:
	var size = get_screen_size()
	# Use the smaller axis so nothing gets clipped
	var scale_x = size.x / BASE_WIDTH
	var scale_y = size.y / BASE_HEIGHT
	return min(scale_x, scale_y)

func make_scroll_touch_friendly(scroll: ScrollContainer) -> void:
	scroll.set_script(preload("res://scripts/utils/TouchScrollContainer.gd"))
	scroll.set_process_input(true)

func apply_panel_padding(panel: PanelContainer, padding: int) -> void:
	var style = panel.get_theme_stylebox("panel")
	if style and style is StyleBoxFlat:
		style.content_margin_left = padding
		style.content_margin_right = padding

# ─── SCALE HELPERS ─────────────────────────────────────
# Call these everywhere instead of hardcoding pixel values

func s(value: float) -> float:
	# Scale any pixel value to the current screen
	return max(1.0, value * get_scale())

func si(value: float) -> int:
	# Same but returns int (for font sizes)
	return max(1, int(value * get_scale()))

func sv(v: Vector2) -> Vector2:
	# Scale a Vector2 (for minimum sizes, margins, etc.)
	var sc = get_scale()
	return Vector2(max(1.0, v.x * sc), max(1.0, v.y * sc))

# ─── BREAKPOINTS ───────────────────────────────────────
func is_mobile() -> bool:
	if OS.has_feature("mobile") or OS.has_feature("Android") or OS.has_feature("iOS"):
		var dpi = DisplayServer.screen_get_dpi()
		if dpi > 0:
			var size = get_screen_size()
			var inches = size.length() / dpi
			return inches < 7.0
		return true
	var size = get_screen_size()
	return size.x < 960 or size.y < 540

func is_tablet() -> bool:
	if OS.has_feature("mobile") or OS.has_feature("Android") or OS.has_feature("iOS"):
		var dpi = DisplayServer.screen_get_dpi()
		if dpi > 0:
			var size = get_screen_size()
			var inches = size.length() / dpi
			return inches >= 7.0 and inches < 11.0
		return false
	var size = get_screen_size()
	return (size.x >= 960 and size.x < 1280) or (size.y >= 540 and size.y < 720)

func is_desktop() -> bool:
	return not is_mobile() and not is_tablet()

func get_columns() -> int:
	if is_mobile():
		return 1
	elif is_tablet():
		return 2
	return 2	
