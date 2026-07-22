# ScreenManager.gd
extends Node

# ─── REFERENCE RESOLUTION ──────────────────────────────
# Everything is designed at this base resolution
const BASE_WIDTH: float  = 1152.0
const BASE_HEIGHT: float = 648.0

func _ready() -> void:
	# Force landscape orientation on mobile devices
	if OS.has_feature("mobile") or OS.has_feature("Android") or OS.has_feature("iOS"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	
	# Dynamically adjust content scale factor for mobile devices so texts and icons are legible
	update_content_scale()
	get_window().size_changed.connect(update_content_scale)

func update_content_scale() -> void:
	# Calculate dynamic base scale relative to base designed resolution
	var size = get_screen_size()
	var scale_x = size.x / BASE_WIDTH
	var scale_y = size.y / BASE_HEIGHT
	var base_scale = min(scale_x, scale_y)
	
	var scale_factor: float = base_scale
	
	if is_mobile():
		# On mobile devices, ensure extra upscale factor so texts and buttons are comfortably tap-able and readable
		scale_factor = max(base_scale, 1.4)
	elif is_tablet():
		scale_factor = max(base_scale, 1.15)
	elif OS.has_feature("web"):
		if size.x < 1000 or size.y < 600:
			scale_factor = max(base_scale, 1.25)
	else:
		# Desktop uses Godot's built-in stretch mode — no manual content scale needed
		return
			
	get_window().content_scale_factor = scale_factor

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
