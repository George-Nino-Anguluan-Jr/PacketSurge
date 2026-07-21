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
	
	# Global UI adaptive layer for ALL platforms to ensure general responsive behavior
	get_tree().node_added.connect(_on_node_added)
	# Process existing nodes once ready is complete
	call_deferred("_optimize_node_recursively", get_tree().root)

func _on_node_added(node: Node) -> void:
	# Small defer to let ready/properties populate first
	call_deferred("_optimize_node_recursively", node)

func _optimize_node_recursively(node: Node) -> void:
	if not node or not is_instance_valid(node):
		return
	
	if node is Control:
		_optimize_control(node)
	
	for child in node.get_children():
		_optimize_node_recursively(child)

func _optimize_control(control: Control) -> void:
	if control.has_meta("responsive_optimized"):
		return
	control.set_meta("responsive_optimized", true)
	
	# Force any root-level control directly under the viewport to stretch and fill the viewport perfectly
	if control.get_parent() == get_tree().root:
		control.set_anchors_preset(Control.PRESET_FULL_RECT)
		control.anchor_right = 1.0
		control.anchor_bottom = 1.0
		control.offset_left = 0
		control.offset_right = 0
		control.offset_top = 0
		control.offset_bottom = 0

	# Apply platform-specific mobile/tablet optimizations
	if is_mobile() or is_tablet():
		# ─── BUTTONS ──────────────────────────────────────────
		if control is Button:
			# Exclude tabs or tiny internal components if they have no text/icon
			if control.text != "" or control.custom_minimum_size.y > 0:
				control.custom_minimum_size.y = max(control.custom_minimum_size.y, 44.0)
			
			# Optimise button text size
			if control.has_theme_font_size_override("font_size"):
				var fs = control.get_theme_font_size("font_size")
				if fs > 24:
					control.add_theme_font_size_override("font_size", 18)
				elif fs < 13:
					control.add_theme_font_size_override("font_size", 14)
			else:
				control.add_theme_font_size_override("font_size", 14)
				
		# ─── LABELS & RICH TEXT ───────────────────────────────
		elif control is Label:
			if control.has_theme_font_size_override("font_size"):
				var fs = control.get_theme_font_size("font_size")
				# Scale down large titles that would overflow or wrap badly on phones
				if fs > 36:
					control.add_theme_font_size_override("font_size", int(fs * 0.65))
				elif fs > 24:
					control.add_theme_font_size_override("font_size", int(fs * 0.75))
				elif fs < 12 and fs > 0:
					control.add_theme_font_size_override("font_size", 13)
			# Force smart word wrapping for labels that might overflow the screen width
			if control.autowrap_mode == TextServer.AUTOWRAP_OFF and control.text.length() > 30:
				control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				
		elif control is RichTextLabel:
			# Enable word wrapping
			control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			
		# ─── LINE EDITS & OPTION BUTTONS ──────────────────────
		elif control is LineEdit or control is OptionButton:
			control.custom_minimum_size.y = max(control.custom_minimum_size.y, 44.0)
			if control.has_theme_font_size_override("font_size"):
				var fs = control.get_theme_font_size("font_size")
				if fs < 13:
					control.add_theme_font_size_override("font_size", 14)
			else:
				control.add_theme_font_size_override("font_size", 14)
				
		# ─── MARGIN CONTAINERS ────────────────────────────────
		elif control is MarginContainer:
			# Desktop margins are typically too wide for mobile. Let's make them narrower.
			for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
				if control.has_theme_constant_override(side):
					var margin_val = control.get_theme_constant(side)
					if margin_val > 40:
						control.add_theme_constant_override(side, int(margin_val * 0.4))
					elif margin_val > 20:
						control.add_theme_constant_override(side, int(margin_val * 0.6))
						
		# ─── GENERAL LAYOUT/SIZE CONSTRAINTS ──────────────────
		# If a control has a hardcoded custom minimum width designed for desktop (e.g. >= 1000px)
		# we scale or remove it to prevent overflow on mobile.
		if control.custom_minimum_size.x >= 1000.0:
			control.custom_minimum_size.x = 0 # Let it shrink and wrap!
		elif control.custom_minimum_size.x > 600.0:
			control.custom_minimum_size.x = max(320.0, control.custom_minimum_size.x * 0.6)

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