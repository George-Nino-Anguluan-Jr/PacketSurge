# ArrayPlayground.gd
extends Control

@onready var back_btn: Button          = $TopBar/TopBarLayout/BackBtn
@onready var title_label: Label        = $TopBar/TopBarLayout/TitleLabel
@onready var draw_surface: Control     = $ContentArea/MainLayout/VisualizationArea/DrawSurface
@onready var input_field: LineEdit     = $ContentArea/MainLayout/ControlsArea/InputField
@onready var add_btn: Button           = $ContentArea/MainLayout/ControlsArea/AddBtn
@onready var remove_btn: Button        = $ContentArea/MainLayout/ControlsArea/RemoveBtn
@onready var clear_btn: Button         = $ContentArea/MainLayout/ControlsArea/ClearBtn
@onready var operation_label: Label    = $ContentArea/MainLayout/InfoArea/OperationLabel
@onready var complexity_label: Label   = $ContentArea/MainLayout/InfoArea/ComplexityLabel

# ─── DATA ──────────────────────────────────────────────
var array_data: Array[int]    = []
var highlighted_index: int    = -1
var _last_operation: String   = ""

const MAX_ELEMENTS: int = 12
const COLORS = {
	"normal":      Color("#00D4FF"),
	"highlight":   Color("#FFB800"),
	"new":         Color("#00FF88"),
	"removing":    Color("#FF3366"),
}

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	_setup_buttons()
	_apply_styles()
	draw_surface.draw.connect(_draw_array)
	# Start with some default values
	array_data = [4, 8, 15, 16, 23, 42]
	_refresh()

func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	add_btn.pressed.connect(_on_add_pressed)
	remove_btn.pressed.connect(_on_remove_pressed)
	clear_btn.pressed.connect(_on_clear_pressed)
	input_field.text_submitted.connect(func(_t): _on_add_pressed())

func _on_back_pressed() -> void:
	GameManager.go_to("sandbox")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to("sandbox")

# ─── OPERATIONS ────────────────────────────────────────
func _on_add_pressed() -> void:
	var text = input_field.text.strip_edges()
	if text == "":
		_show_operation("Enter a number first.", "")
		return
	if not text.is_valid_int():
		_show_operation("Please enter a valid integer.", "")
		return
	if array_data.size() >= MAX_ELEMENTS:
		_show_operation(
			"Array is full! Max " + str(MAX_ELEMENTS) + " elements.", ""
		)
		return
	var value = text.to_int()
	array_data.append(value)
	highlighted_index = array_data.size() - 1
	input_field.text  = ""
	_show_operation(
		"append(" + str(value) + ") → Added at index " + \
		str(array_data.size() - 1),
		"O(1) amortized"
	)
	_refresh()
	# Clear highlight after a moment
	await get_tree().create_timer(1.0).timeout
	highlighted_index = -1
	_refresh()

func _on_remove_pressed() -> void:
	if array_data.is_empty():
		_show_operation("Array is empty — nothing to remove.", "")
		return
	var removed = array_data[-1]
	array_data.pop_back()
	highlighted_index = -1
	_show_operation(
		"pop() → Removed " + str(removed) + \
		" from index " + str(array_data.size()),
		"O(1)"
	)
	_refresh()

func _on_clear_pressed() -> void:
	array_data.clear()
	highlighted_index = -1
	_show_operation("Array cleared. Size: 0", "O(1)")
	_refresh()

func _show_operation(op: String, complexity: String) -> void:
	operation_label.text  = "▶ " + op
	if complexity != "":
		complexity_label.text = "Complexity: " + complexity
	else:
		complexity_label.text = ""

# ─── DRAWING ───────────────────────────────────────────
func _draw_array() -> void:
	var size      = draw_surface.size
	if size.x == 0 or size.y == 0:
		return

	var count     = array_data.size()
	if count == 0:
		# Draw empty array message
		draw_surface.draw_string(
			ThemeDB.fallback_font,
			Vector2(size.x / 2 - 80, size.y / 2),
			"Array is empty",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
			Color("#4A7FA5")
		)
		return

	var cell_w    = min((size.x - 40) / count, 80.0)
	var cell_h    = 60.0
	var start_x   = (size.x - cell_w * count) / 2.0
	var cell_y    = (size.y - cell_h) / 2.0

	for i in range(count):
		var x     = start_x + i * cell_w
		var rect  = Rect2(x, cell_y, cell_w - 4, cell_h)

		# Cell color
		var col: Color
		if i == highlighted_index:
			col = COLORS["highlight"]
		else:
			col = COLORS["normal"]

		# Cell background
		draw_surface.draw_rect(rect, Color(col, 0.15))
		# Cell border
		draw_surface.draw_rect(rect, col, false, 2.0)

		# Value text
		var val_str = str(array_data[i])
		var text_x  = x + (cell_w - 4) / 2.0 - val_str.length() * 6
		draw_surface.draw_string(
			ThemeDB.fallback_font,
			Vector2(text_x, cell_y + cell_h / 2.0 + 6),
			val_str,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18,
			Color("#E8F4FD")
		)

		# Index label below cell
		draw_surface.draw_string(
			ThemeDB.fallback_font,
			Vector2(x + (cell_w - 4) / 2.0 - 4, cell_y + cell_h + 20),
			str(i),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
			Color("#4A7FA5")
		)

	# Array size label
	draw_surface.draw_string(
		ThemeDB.fallback_font,
		Vector2(start_x, cell_y - 16),
		"size = " + str(count),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
		Color("#4A7FA5")
	)

func _refresh() -> void:
	draw_surface.queue_redraw()

# ─── STYLES ────────────────────────────────────────────
func _apply_styles() -> void:
	var top_style := StyleBoxFlat.new()
	top_style.bg_color          = Color("#0A1628")
	top_style.border_color      = Color("#00D4FF")
	top_style.border_width_bottom = 1
	$TopBar.add_theme_stylebox_override("panel", top_style)

	var viz_style := StyleBoxFlat.new()
	viz_style.bg_color               = Color("#080F1E")
	viz_style.border_color           = Color("#0D2040")
	viz_style.border_width_left      = 1
	viz_style.border_width_right     = 1
	viz_style.border_width_top       = 1
	viz_style.border_width_bottom    = 1
	viz_style.corner_radius_top_left     = 6
	viz_style.corner_radius_top_right    = 6
	viz_style.corner_radius_bottom_left  = 6
	viz_style.corner_radius_bottom_right = 6
	$ContentArea/MainLayout/VisualizationArea.add_theme_stylebox_override(
		"panel", viz_style
	)

	var back_style := StyleBoxFlat.new()
	back_style.bg_color               = Color("#0A1628")
	back_style.border_color           = Color("#00D4FF")
	back_style.border_width_left      = 1
	back_style.border_width_right     = 1
	back_style.border_width_top       = 1
	back_style.border_width_bottom    = 1
	back_style.corner_radius_top_left     = 4
	back_style.corner_radius_top_right    = 4
	back_style.corner_radius_bottom_left  = 4
	back_style.corner_radius_bottom_right = 4
	back_btn.add_theme_stylebox_override("normal", back_style)
	back_btn.add_theme_color_override("font_color", Color("#00D4FF"))

	for btn in [add_btn, remove_btn, clear_btn]:
		_style_control_btn(btn)

	var field_style := StyleBoxFlat.new()
	field_style.bg_color               = Color("#080F1E")
	field_style.border_color           = Color("#1A3A5A")
	field_style.border_width_left      = 1
	field_style.border_width_right     = 1
	field_style.border_width_top       = 1
	field_style.border_width_bottom    = 1
	field_style.corner_radius_top_left     = 4
	field_style.corner_radius_top_right    = 4
	field_style.corner_radius_bottom_left  = 4
	field_style.corner_radius_bottom_right = 4
	field_style.content_margin_left    = 12
	field_style.content_margin_right   = 12
	input_field.add_theme_stylebox_override("normal", field_style)
	input_field.add_theme_color_override("font_color", Color("#E8F4FD"))
	input_field.add_theme_color_override(
		"font_placeholder_color", Color("#4A7FA5")
	)

func _style_control_btn(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = Color("#00D4FF")
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color("#00D4FF"))
	btn.add_theme_font_size_override("font_size", 13)
