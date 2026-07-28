extends Control
class_name TutorialOverlay

# ─── TUTORIAL DATA ─────────────────────────────────────
# Each step dictionary:
#   "title": String
#   "body":  String
#   "highlight": NodePath (optional) — node to spotlight
#   "highlight_padding": float (optional, default 8) — extra padding around the highlight
#   "force_center": bool (optional) — center the message card instead of positioning near the highlight
#   "show_next": bool (optional, default true) — show the Next button (auto-advance steps can hide it)
#   "advance_signal": String (optional) — documented name; callers should call tut.advance() when needed

signal tutorial_finished
signal step_shown(step_index: int)

# ─── STATE ─────────────────────────────────────────────
var _steps: Array = []
var _step_index: int = 0
var _dim: Control = null
var _card: PanelContainer = null
var _title_lbl: Label = null
var _body_lbl: Label = null
var _step_lbl: Label = null
var _next_btn: Button = null
var _skip_btn: Button = null
var _highlight_rect: Rect2 = Rect2()
var _highlight_padding: float = 8.0

# ─── PUBLIC API ────────────────────────────────────────
func start(steps: Array) -> void:
	_steps = steps
	_step_index = 0
	_build_ui()
	_show_step()

# ─── BUILD UI ──────────────────────────────────────────
func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Responsive sizing
	var screen_w: float = size.x
	var is_mobile: bool = screen_w < 600
	var card_target_w: float = min(420.0, screen_w - 32.0)
	var title_fs: int = 24 if is_mobile else 22
	var body_fs: int = 18 if is_mobile else 16
	var step_fs: int = 13 if is_mobile else 12
	var btn_fs: int = 18 if is_mobile else 16
	var btn_h: int = 50 if is_mobile else 46
	var btn_w: int = 200 if is_mobile else 180
	var side_margin: int = 22 if is_mobile else 24

	# Dim layer with custom drawing (handles spotlight cutout)
	_dim = Control.new()
	_dim.name = "Dim"
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.draw.connect(_draw_dim)
	add_child(_dim)

	# Skip button (top-right corner)
	_skip_btn = Button.new()
	_skip_btn.text = "Skip Tour"
	_skip_btn.custom_minimum_size = Vector2(90 if is_mobile else 80, 32 if is_mobile else 28)
	_skip_btn.position = Vector2(size.x - _skip_btn.custom_minimum_size.x - 16, 16)
	_skip_btn.add_theme_color_override("font_color", Color("#4A7FA5"))
	_skip_btn.add_theme_font_size_override("font_size", 11 if is_mobile else 10)
	_skip_btn.pressed.connect(_on_skip_pressed)
	add_child(_skip_btn)

	# Card container (positioned later)
	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(card_target_w, 0)
	_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	var st := StyleBoxFlat.new()
	st.bg_color = Color("#0A1628", 0.98)
	st.border_color = Color("#00D4FF")
	st.border_width_left = 2
	st.border_width_right = 2
	st.border_width_top = 2
	st.border_width_bottom = 2
	st.corner_radius_top_left = 14
	st.corner_radius_top_right = 14
	st.corner_radius_bottom_left = 14
	st.corner_radius_bottom_right = 14
	_card.add_theme_stylebox_override("panel", st)
	add_child(_card)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12 if is_mobile else 10)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("margin_left", side_margin)
	layout.add_theme_constant_override("margin_right", side_margin)
	layout.add_theme_constant_override("margin_top", 20 if is_mobile else 18)
	layout.add_theme_constant_override("margin_bottom", 20 if is_mobile else 18)
	_card.add_child(layout)

	# Title
	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_color_override("font_color", Color("#00D4FF"))
	_title_lbl.add_theme_font_size_override("font_size", title_fs)
	_layout_add(layout, _title_lbl)

	# Body
	_body_lbl = Label.new()
	_body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_lbl.add_theme_color_override("font_color", Color("#E8F4FD"))
	_body_lbl.add_theme_font_size_override("font_size", body_fs)
	_body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_layout_add(layout, _body_lbl)

	# Step counter
	_step_lbl = Label.new()
	_step_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_step_lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	_step_lbl.add_theme_font_size_override("font_size", step_fs)
	_layout_add(layout, _step_lbl)

	# Next button
	_next_btn = Button.new()
	_next_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	_next_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_next_btn.add_theme_font_size_override("font_size", btn_fs)
	_next_btn.pressed.connect(_on_next_pressed)
	_layout_add(layout, _next_btn)

func _layout_add(parent: Container, child: Control) -> void:
	parent.add_child(child)

# ─── SHOW STEP ─────────────────────────────────────────
func _show_step() -> void:
	if _step_index >= _steps.size():
		_finish()
		return

	var d: Dictionary = _steps[_step_index]
	_title_lbl.text = d.get("title", "")
	_body_lbl.text = d.get("body", "")
	_step_lbl.text = "Step " + str(_step_index + 1) + " of " + str(_steps.size())

	var show_next: bool = d.get("show_next", true)
	_next_btn.visible = show_next
	_next_btn.text = "Next →" if _step_index < _steps.size() - 1 else "Let's Go!"

	# Highlight area
	_highlight_rect = Rect2()
	_highlight_padding = d.get("highlight_padding", 8.0)
	var highlight_path: NodePath = d.get("highlight", NodePath())
	if not highlight_path.is_empty():
		var node = get_node_or_null(highlight_path)
		if node is Control:
			var ctrl: Control = node
			_highlight_rect = Rect2(ctrl.global_position - Vector2(_highlight_padding, _highlight_padding),
				ctrl.size + Vector2(_highlight_padding * 2.0, _highlight_padding * 2.0))
		elif node is CanvasItem:
			var ci: CanvasItem = node
			# For non-Control nodes (like Node2D), use their position/size if available
			if node.has_method("get_global_position"):
				var gp = node.get_global_position()
				_highlight_rect = Rect2(gp - Vector2(_highlight_padding, _highlight_padding),
					Vector2(64, 64) + Vector2(_highlight_padding * 2.0, _highlight_padding * 2.0))

	# Position card
	_position_card(d)

	# Redraw dim
	_dim.queue_redraw()

	step_shown.emit(_step_index)

# ─── POSITION CARD ─────────────────────────────────────
func _position_card(step_data: Dictionary) -> void:
	# Wait one frame for layout to settle
	await get_tree().process_frame

	var card_w: float = _card.size.x
	var card_h: float = _card.size.y
	if card_w <= 0:
		card_w = 340
	if card_h <= 0:
		card_h = 160

	var screen_w: float = size.x
	var screen_h: float = size.y
	var margin: float = 16.0

	if step_data.get("force_center", false) or _highlight_rect.size == Vector2.ZERO:
		# Centered
		_card.position = Vector2((screen_w - card_w) / 2.0, (screen_h - card_h) / 2.0)
		return

	# Position near the highlight
	var hl: Rect2 = _highlight_rect
	var above: bool = hl.position.y > card_h + margin + 24
	var left: bool = (hl.position.x + hl.size.x / 2.0) < screen_w / 2.0

	var pos := Vector2.ZERO
	if above:
		pos.y = hl.position.y - card_h - margin
		pos.y = max(pos.y, margin)
	else:
		pos.y = hl.position.y + hl.size.y + margin
		pos.y = min(pos.y, screen_h - card_h - margin)

	# Horizontal: center under the highlight, but clamp to screen
	var desired_x = hl.position.x + hl.size.x / 2.0 - card_w / 2.0
	pos.x = clamp(desired_x, margin, screen_w - card_w - margin)
	_card.position = pos

# ─── DIM DRAWING (SPOTLIGHT CUTOUT) ────────────────────
func _draw_dim() -> void:
	var dim_color = Color(0, 0, 0, 0.78)
	var view_size = _dim.size

	if _highlight_rect.size == Vector2.ZERO:
		_dim.draw_rect(Rect2(Vector2.ZERO, view_size), dim_color)
		return

	# Draw dim everywhere EXCEPT the highlight rect (punch a hole)
	# We do this by drawing 4 rectangles around the highlight
	var hl: Rect2 = _highlight_rect
	# Top
	_dim.draw_rect(Rect2(0, 0, view_size.x, hl.position.y), dim_color)
	# Bottom
	_dim.draw_rect(Rect2(0, hl.position.y + hl.size.y, view_size.x, view_size.y - (hl.position.y + hl.size.y)), dim_color)
	# Left
	_dim.draw_rect(Rect2(0, hl.position.y, hl.position.x, hl.size.y), dim_color)
	# Right
	_dim.draw_rect(Rect2(hl.position.x + hl.size.x, hl.position.y, view_size.x - (hl.position.x + hl.size.x), hl.size.y), dim_color)

	# Glowing border around the highlight
	var glow_color = Color("#00D4FF", 0.9)
	_dim.draw_rect(hl, glow_color, false, 3.0)

# ─── NEXT / SKIP ───────────────────────────────────────
func _on_next_pressed() -> void:
	_step_index += 1
	_show_step()

func _on_skip_pressed() -> void:
	_finish()

func advance() -> void:
	# Public method to advance the tutorial (used when advance_signal is provided)
	_step_index += 1
	_show_step()

func _finish() -> void:
	tutorial_finished.emit()
	queue_free()
