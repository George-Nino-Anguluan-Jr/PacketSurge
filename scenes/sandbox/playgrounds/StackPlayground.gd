# StackPlayground.gd
extends Control

@onready var back_btn: Button        = $TopBar/TopBarLayout/BackBtn
@onready var draw_surface: Control   = $ContentArea/MainLayout/VisualizationArea/DrawSurface
@onready var input_field: LineEdit   = $ContentArea/MainLayout/ControlsArea/InputField
@onready var push_btn: Button        = $ContentArea/MainLayout/ControlsArea/AddBtn
@onready var pop_btn: Button         = $ContentArea/MainLayout/ControlsArea/RemoveBtn
@onready var clear_btn: Button       = $ContentArea/MainLayout/ControlsArea/ClearBtn
@onready var operation_label: Label  = $ContentArea/MainLayout/InfoArea/OperationLabel
@onready var complexity_label: Label = $ContentArea/MainLayout/InfoArea/ComplexityLabel

var stack_data: Array[int] = []
var highlighted_index: int = -1
const MAX_ELEMENTS: int    = 8

func _ready() -> void:
	back_btn.pressed.connect(func(): GameManager.go_to("sandbox"))
	push_btn.pressed.connect(_on_push_pressed)
	pop_btn.pressed.connect(_on_pop_pressed)
	clear_btn.pressed.connect(_on_clear_pressed)
	input_field.text_submitted.connect(func(_t): _on_push_pressed())
	draw_surface.draw.connect(_draw_stack)
	_apply_styles()
	stack_data = [3, 7, 12, 5]
	_refresh()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to("sandbox")

func _on_push_pressed() -> void:
	var text = input_field.text.strip_edges()
	if text == "" or not text.is_valid_int():
		operation_label.text = "▶ Enter a valid integer to push."
		return
	if stack_data.size() >= MAX_ELEMENTS:
		operation_label.text = "▶ Stack overflow! Max " + str(MAX_ELEMENTS) + " elements."
		return
	var value = text.to_int()
	stack_data.append(value)
	highlighted_index    = stack_data.size() - 1
	input_field.text     = ""
	operation_label.text = "▶ push(" + str(value) + ") → Added to top of stack"
	complexity_label.text = "Complexity: O(1)"
	_refresh()
	await get_tree().create_timer(1.0).timeout
	highlighted_index = -1
	_refresh()

func _on_pop_pressed() -> void:
	if stack_data.is_empty():
		operation_label.text = "▶ Stack underflow! Stack is empty."
		return
	var removed           = stack_data[-1]
	stack_data.pop_back()
	operation_label.text  = "▶ pop() → Removed " + str(removed) + " from top"
	complexity_label.text = "Complexity: O(1)"
	_refresh()

func _on_clear_pressed() -> void:
	stack_data.clear()
	operation_label.text  = "▶ Stack cleared."
	complexity_label.text = ""
	_refresh()

func _draw_stack() -> void:
	var size   = draw_surface.size
	if size.x == 0:
		return

	var cell_w = 120.0
	var cell_h = 44.0
	var gap    = 4.0
	var start_x = (size.x - cell_w) / 2.0

	if stack_data.is_empty():
		draw_surface.draw_string(
			ThemeDB.fallback_font,
			Vector2(size.x / 2 - 60, size.y / 2),
			"Stack is empty",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
			Color("#4A7FA5")
		)
		return

	# Draw from bottom to top
	for i in range(stack_data.size()):
		var y   = size.y - 40 - (i + 1) * (cell_h + gap)
		var col = Color("#FFB800") if i == highlighted_index \
				  else Color("#FF6B35")
		var rect = Rect2(start_x, y, cell_w, cell_h)
		draw_surface.draw_rect(rect, Color(col, 0.15))
		draw_surface.draw_rect(rect, col, false, 2.0)

		# Value
		draw_surface.draw_string(
			ThemeDB.fallback_font,
			Vector2(start_x + cell_w / 2 - 10, y + cell_h / 2 + 6),
			str(stack_data[i]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
			Color("#E8F4FD")
		)

		# TOP label on last item
		if i == stack_data.size() - 1:
			draw_surface.draw_string(
				ThemeDB.fallback_font,
				Vector2(start_x + cell_w + 8, y + cell_h / 2 + 5),
				"← TOP",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
				Color("#FFB800")
			)

	# Bottom label
	draw_surface.draw_string(
		ThemeDB.fallback_font,
		Vector2(start_x, size.y - 24),
		"BOTTOM",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
		Color("#4A7FA5")
	)

func _refresh() -> void:
	draw_surface.queue_redraw()

func _apply_styles() -> void:
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color("#0A1628")
	top_style.border_color = Color("#FF6B35")
	top_style.border_width_bottom = 1
	$TopBar.add_theme_stylebox_override("panel", top_style)

	var viz_style := StyleBoxFlat.new()
	viz_style.bg_color     = Color("#080F1E")
	viz_style.border_color = Color("#0D2040")
	viz_style.border_width_left = 1
	viz_style.border_width_right = 1
	viz_style.border_width_top = 1
	viz_style.border_width_bottom = 1
	viz_style.corner_radius_top_left     = 6
	viz_style.corner_radius_top_right    = 6
	viz_style.corner_radius_bottom_left  = 6
	viz_style.corner_radius_bottom_right = 6
	$ContentArea/MainLayout/VisualizationArea.add_theme_stylebox_override(
		"panel", viz_style
	)
