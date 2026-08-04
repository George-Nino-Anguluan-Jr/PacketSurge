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

var _settle_frames := 240  # re-check for ~4s to catch late orientation changes

func _ready() -> void:
	# Force landscape orientation on mobile devices
	if OS.has_feature("mobile") or OS.has_feature("Android") or OS.has_feature("iOS"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)

	# Dynamically adjust content scale factor for mobile devices so texts and icons are legible
	update_content_scale()
	get_window().size_changed.connect(update_content_scale)

func _process(_delta: float) -> void:
	# Some Android devices report the window in portrait at startup, or never
	# fire size_changed after rotation. Keep correcting until it settles so
	# the scale factor never stays locked to the wrong aspect ratio.
	if _settle_frames > 0:
		_settle_frames -= 1
		update_content_scale()

func update_content_scale() -> void:
	var size := get_screen_size()

	if is_mobile() or is_tablet() or OS.has_feature("web"):
		# The game is landscape-locked, so a portrait-reported size is always
		# a startup/timing quirk. Normalize it before deriving the scale.
		if size.y > size.x:
			size = Vector2(size.y, size.x)

		# Godot's built-in canvas_items stretch (base 1280x720 in project.godot)
		# ALREADY self-normalizes per device via `stretch_scale`. Our manual
		# content_scale_factor stacks ON TOP of that, so we must divide by
		# `stretch_scale` — otherwise both scale systems multiply together and
		# the effective viewport shrinks on high-res devices (double-scaling).
		var stretch_scale := minf(size.x / BASE_WIDTH, size.y / BASE_HEIGHT)
		var target := minf(size.x / MOBILE_WIDTH, size.y / MOBILE_HEIGHT) / stretch_scale
		if not is_equal_approx(get_window().content_scale_factor, target):
			get_window().content_scale_factor = target
	else:
		# Desktop uses Godot's built-in stretch mode — no manual content scale needed
		return

# ─── SCREEN SIZE ───────────────────────────────────────
func get_screen_size() -> Vector2:
	return DisplayServer.window_get_size()

# Current global UI zoom (1.0 on desktop, derived on mobile). Exposed so
# debug overlays / helpers can read the same number the engine renders with.
func get_content_scale() -> float:
	return get_window().content_scale_factor

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
