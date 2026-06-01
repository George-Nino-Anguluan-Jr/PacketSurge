# GridSystem.gd
# Manages the gameplay grid
class_name GridSystem
extends Node2D

# ─── GRID SETTINGS ─────────────────────────────────────
const CELL_SIZE    := 64
const GRID_COLS    := 18
const GRID_ROWS    := 10
const GRID_OFFSET  := Vector2(0, 52)  # offset below TopHUD

# ─── CELL STATES ───────────────────────────────────────
enum CellState { EMPTY, PATH, TOWER, BLOCKED }

var grid: Array = []   # 2D array of CellState
var path_cells: Array[Vector2i] = []   # cells that are part of the path

# ─── COLORS ────────────────────────────────────────────
const COLOR_EMPTY    := Color("#080F1E")
const COLOR_PATH     := Color("#0A1A30")
const COLOR_TOWER    := Color("#0D2040")
const COLOR_HOVER    := Color("#00D4FF", 0.2)
const COLOR_GRID_LINE := Color("#0D2040")
const COLOR_BLOCKED  := Color("#1A0A0A")

# Hovered cell for preview
var hovered_cell: Vector2i = Vector2i(-1, -1)
var is_placing_tower: bool = false

signal cell_clicked(cell: Vector2i)
signal cell_hovered(cell: Vector2i)

# ─── INIT ──────────────────────────────────────────────
func initialize(waypoints: Array[Vector2]) -> void:
	_init_grid()
	_mark_path_from_waypoints(waypoints)
	queue_redraw()

func _init_grid() -> void:
	grid.clear()
	for row in range(GRID_ROWS):
		var row_data = []
		for col in range(GRID_COLS):
			row_data.append(CellState.EMPTY)
		grid.append(row_data)

func _mark_path_from_waypoints(waypoints: Array[Vector2]) -> void:
	path_cells.clear()
	if waypoints.size() < 2:
		return
	# Mark cells between each pair of waypoints
	for i in range(waypoints.size() - 1):
		var from = world_to_cell(waypoints[i])
		var to   = world_to_cell(waypoints[i + 1])
		_mark_line(from, to)

func _mark_line(from: Vector2i, to: Vector2i) -> void:
	var current = from
	while current != to:
		_mark_path_cell(current)
		var diff = to - current
		if abs(diff.x) > abs(diff.y):
			current.x += sign(diff.x)
		else:
			current.y += sign(diff.y)
	_mark_path_cell(to)

func _mark_path_cell(cell: Vector2i) -> void:
	if _is_valid_cell(cell):
		grid[cell.y][cell.x] = CellState.PATH
		if cell not in path_cells:
			path_cells.append(cell)

# ─── DRAWING ───────────────────────────────────────────
func _draw() -> void:
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var cell  = Vector2i(col, row)
			var rect  = get_cell_rect(cell)
			var state = grid[row][col]

			# Fill color based on state
			var fill_color: Color
			match state:
				CellState.PATH:    fill_color = COLOR_PATH
				CellState.TOWER:   fill_color = COLOR_TOWER
				CellState.BLOCKED: fill_color = COLOR_BLOCKED
				_:                 fill_color = COLOR_EMPTY

			draw_rect(rect, fill_color)

			# Hover highlight
			if cell == hovered_cell and is_placing_tower \
			   and state == CellState.EMPTY:
				draw_rect(rect, COLOR_HOVER)

			# Grid lines
			draw_rect(rect, COLOR_GRID_LINE, false, 0.5)

	# Draw path arrows
	_draw_path_arrows()

func _draw_path_arrows() -> void:
	if path_cells.size() < 2:
		return
	for i in range(path_cells.size() - 1):
		var from = get_cell_center(path_cells[i])
		var to   = get_cell_center(path_cells[i + 1])
		var mid  = (from + to) / 2.0
		draw_circle(mid, 3.0, Color("#00D4FF", 0.4))

# ─── INPUT ─────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var cell = world_to_cell(event.position - GRID_OFFSET)
		if cell != hovered_cell:
			hovered_cell = cell
			cell_hovered.emit(cell)
			queue_redraw()

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var cell = world_to_cell(
				event.position - GRID_OFFSET
			)
			if _is_valid_cell(cell):
				cell_clicked.emit(cell)

# ─── CELL HELPERS ──────────────────────────────────────
func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x / CELL_SIZE),
		int(world_pos.y / CELL_SIZE)
	)

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * CELL_SIZE,
		cell.y * CELL_SIZE
	) + GRID_OFFSET

func get_cell_center(cell: Vector2i) -> Vector2:
	return cell_to_world(cell) + Vector2(CELL_SIZE, CELL_SIZE) / 2.0

func get_cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(cell_to_world(cell), Vector2(CELL_SIZE, CELL_SIZE))

func _is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_COLS \
		and cell.y >= 0 and cell.y < GRID_ROWS

func can_place_tower(cell: Vector2i) -> bool:
	if not _is_valid_cell(cell):
		return false
	return grid[cell.y][cell.x] == CellState.EMPTY

func place_tower(cell: Vector2i) -> void:
	if _is_valid_cell(cell):
		grid[cell.y][cell.x] = CellState.TOWER
		queue_redraw()

func remove_tower(cell: Vector2i) -> void:
	if _is_valid_cell(cell):
		grid[cell.y][cell.x] = CellState.EMPTY
		queue_redraw()
