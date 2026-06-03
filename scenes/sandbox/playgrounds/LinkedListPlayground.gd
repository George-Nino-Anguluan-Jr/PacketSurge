# LinkedListPlayground.gd
extends Control

@onready var back_btn: Button        = $TopBar/TopBarLayout/BackBtn
@onready var draw_surface: Control   = $ContentArea/MainLayout/VisualizationArea/DrawSurface
@onready var input_field: LineEdit   = $ContentArea/MainLayout/ControlsArea/InputField
@onready var insert_btn: Button      = $ContentArea/MainLayout/ControlsArea/AddBtn
@onready var remove_btn: Button      = $ContentArea/MainLayout/ControlsArea/RemoveBtn
@onready var clear_btn: Button       = $ContentArea/MainLayout/ControlsArea/ClearBtn
@onready var operation_label: Label  = $ContentArea/MainLayout/InfoArea/OperationLabel
@onready var complexity_label: Label = $ContentArea/MainLayout/InfoArea/ComplexityLabel

var list_data: Array[int]  = []
var highlight_head: bool   = false
const MAX_ELEMENTS: int    = 8

func _ready() -> void:
	back_btn.pressed.connect(func(): GameManager.go_to("sandbox"))
	insert_btn.pressed.connect(_on_insert_pressed)
	remove_btn.pressed.connect(_on_remove_pressed)
	clear_btn.pressed.connect(_on_clear_pressed)
	input_field.text_submitted.connect(func(_t): _on_insert_pressed())
	draw_surface.draw.connect(_draw_linked_list)
	_apply_styles()
	list_data = [10, 20, 30]
	_refresh()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to("sandbox")

func _on_insert_pressed() -> void:
	var text = input_field.text.strip_edges()
	if text == "" or not text.is_valid_int():
		operation_label.text = "▶ Enter a valid integer to insert."
		return
	if list_data.size() >= MAX_ELEMENTS:
		operation_label.text = "▶ List is full!"
		return
	var value             = text.to_int()
	list_data.push_front(value)
	highlight_head        = true
	input_field.text      = ""
	operation_label.text  = "▶ insert_head(" + str(value) + ") → New head node created"
	complexity_label.text = "Complexity: O(1)"
	_refresh()
	await get_tree().create_timer(1.0).timeout
	highlight_head = false
	_refresh()

func _on_remove_pressed() -> void:
	if list_data.is_empty():
		operation_label.text = "▶ List is empty."
		return
	var removed           = list_data[0]
	list_data.pop_front()
	operation_label.text  = "▶ remove_head() → Removed node " + str(removed)
	complexity_label.text = "Complexity: O(1)"
	_refresh()

func _on_clear_pressed() -> void:
	list_data.clear()
	operation_label.text  = "▶ List cleared."
	complexity_label.text = ""
	_refresh()

func _draw_linked_list() -> void:
	var size   = draw_surface.size
	if size.x == 0:
		return

	var count  = list_data.size()
	if count == 0:
		draw_surface.draw_string(
			ThemeDB.fallback_font,
			Vector2(size.x / 2 - 70, size.y / 2),
			"Linked list is empty",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
			Color("#4A7FA5")
		)
		return

	var node_w  = 70.0
	var node_h  = 50.0
	var arrow_w = 40.0
	var total_w = count * node_w + (count - 1) * arrow_w
	var start_x = (size.x - total_w) / 2.0
	var node_y  = (size.y - node_h) / 2.0

	for i in range(count):
		var x   = start_x + i * (node_w + arrow_w)
		var col = Color("#00FF88")
		if i == 0 and highlight_head:
			col = Color("#FFB800")

		# Node box
		var rect = Rect2(x, node_y, node_w, node_h)
		draw_surface.draw_rect(rect, Color(col, 0.15))
		draw_surface.draw_rect(rect, col, false, 2.0)

		# Value
		draw_surface.draw_string(
			ThemeDB.fallback_font,
			Vector2(x + node_w / 2 - 8, node_y + node_h / 2 + 6),
			str(list_data[i]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
			Color("#E8F4FD")
		)

		# HEAD label
		if i == 0:
			draw_surface.draw_string(
				ThemeDB.fallback_font,
				Vector2(x + node_w / 2 - 16, node_y - 16),
				"HEAD",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
				Color("#00FF88")
			)

		# Arrow to next node
		if i < count - 1:
			var arrow_start = Vector2(x + node_w, node_y + node_h / 2)
			var arrow_end   = Vector2(x + node_w + arrow_w, node_y + node_h / 2)
			draw_surface.draw_line(
				arrow_start, arrow_end, Color("#4A7FA5"), 2.0
			)
			draw_surface.draw_string(
				ThemeDB.fallback_font,
				Vector2(arrow_start.x + 4, arrow_start.y + 5),
				"→",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
				Color("#4A7FA5")
			)
		else:
			# NULL pointer at end
			draw_surface.draw_string(
				ThemeDB.fallback_font,
				Vector2(x + node_w + 8, node_y + node_h / 2 + 5),
				"→ NULL",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
				Color("#2A3A4A")
			)

func _refresh() -> void:
	draw_surface.queue_redraw()

func _apply_styles() -> void:
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color("#0A1628")
	top_style.border_color = Color("#00FF88")
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
