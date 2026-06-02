# QueuePlayground.gd
extends Control

@onready var back_btn: Button        = $TopBar/TopBarLayout/BackBtn
@onready var draw_surface: Control   = $ContentArea/MainLayout/VisualizationArea/DrawSurface
@onready var input_field: LineEdit   = $ContentArea/MainLayout/ControlsArea/InputField
@onready var enqueue_btn: Button     = $ContentArea/MainLayout/ControlsArea/AddBtn
@onready var dequeue_btn: Button     = $ContentArea/MainLayout/ControlsArea/RemoveBtn
@onready var clear_btn: Button       = $ContentArea/MainLayout/ControlsArea/ClearBtn
@onready var operation_label: Label  = $ContentArea/MainLayout/InfoArea/OperationLabel
@onready var complexity_label: Label = $ContentArea/MainLayout/InfoArea/ComplexityLabel

var queue_data: Array[int] = []
var highlighted_front: bool = false
const MAX_ELEMENTS: int     = 8

func _ready() -> void:
	back_btn.pressed.connect(func(): GameManager.go_to("sandbox"))
	enqueue_btn.pressed.connect(_on_enqueue_pressed)
	dequeue_btn.pressed.connect(_on_dequeue_pressed)
	clear_btn.pressed.connect(_on_clear_pressed)
	input_field.text_submitted.connect(func(_t): _on_enqueue_pressed())
	draw_surface.draw.connect(_draw_queue)
	_apply_styles()
	queue_data = [10, 20, 30, 40]
	_refresh()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to("sandbox")

func _on_enqueue_pressed() -> void:
	var text = input_field.text.strip_edges()
	if text == "" or not text.is_valid_int():
		operation_label.text = "▶ Enter a valid integer to enqueue."
		return
	if queue_data.size() >= MAX_ELEMENTS:
		operation_label.text = "▶ Queue is full! Max " + str(MAX_ELEMENTS) + " elements."
		return
	var value             = text.to_int()
	queue_data.append(value)
	input_field.text      = ""
	operation_label.text  = "▶ enqueue(" + str(value) + ") → Added to back of queue"
	complexity_label.text = "Complexity: O(1)"
	_refresh()

func _on_dequeue_pressed() -> void:
	if queue_data.is_empty():
		operation_label.text = "▶ Queue is empty — nothing to dequeue."
		return
	var removed           = queue_data[0]
	queue_data.pop_front()
	highlighted_front     = true
	operation_label.text  = "▶ dequeue() → Removed " + str(removed) + " from front"
	complexity_label.text = "Complexity: O(1)"
	_refresh()
	await get_tree().create_timer(0.5).timeout
	highlighted_front = false
	_refresh()

func _on_clear_pressed() -> void:
	queue_data.clear()
	operation_label.text  = "▶ Queue cleared."
	complexity_label.text = ""
	_refresh()

func _draw_queue() -> void:
	var size   = draw_surface.size
	if size.x == 0:
		return

	var count  = queue_data.size()
	if count == 0:
		draw_surface.draw_string(
			ThemeDB.fallback_font,
			Vector2(size.x / 2 - 60, size.y / 2),
			"Queue is empty",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
			Color("#4A7FA5")
		)
		return

	var cell_w = min((size.x - 80) / count, 90.0)
	var cell_h = 56.0
	var start_x = (size.x - cell_w * count) / 2.0
	var cell_y  = (size.y - cell_h) / 2.0

	for i in range(count):
		var x    = start_x + i * cell_w
		var rect = Rect2(x + 2, cell_y, cell_w - 4, cell_h)
		var col  = Color("#9B59B6")
		if i == 0:
			col = Color("#00D4FF") if not highlighted_front else Color("#FFB800")

		draw_surface.draw_rect(rect, Color(col, 0.15))
		draw_surface.draw_rect(rect, col, false, 2.0)

		draw_surface.draw_string(
			ThemeDB.fallback_font,
			Vector2(x + (cell_w - 4) / 2 - 8, cell_y + cell_h / 2 + 6),
			str(queue_data[i]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
			Color("#E8F4FD")
		)

		# Arrow between cells
		if i < count - 1:
			draw_surface.draw_string(
				ThemeDB.fallback_font,
				Vector2(x + cell_w - 8, cell_y + cell_h / 2 + 5),
				"→",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
				Color("#4A7FA5")
			)

	# FRONT and BACK labels
	draw_surface.draw_string(
		ThemeDB.fallback_font,
		Vector2(start_x, cell_y - 20),
		"FRONT",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
		Color("#00D4FF")
	)
	draw_surface.draw_string(
		ThemeDB.fallback_font,
		Vector2(start_x + cell_w * (count - 1), cell_y - 20),
		"BACK",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
		Color("#9B59B6")
	)

func _refresh() -> void:
	draw_surface.queue_redraw()

func _apply_styles() -> void:
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color("#0A1628")
	top_style.border_color = Color("#9B59B6")
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
