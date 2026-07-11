# GridSystem.gd
class_name GridSystem
extends Node2D

signal cell_clicked(cell: Vector2i)

# ─── GRID SETTINGS ─────────────────────────────────────
const CELL_SIZE: int = 64
const GRID_COLS: int = 18
const GRID_ROWS: int = 10

# ─── CELL STATES ───────────────────────────────────────
enum CellState {
	BLOCKED,       # can't interact
	PATH,          # enemy walks here
	TOWER_SPOT,    # player can place tower here
	TOWER_PLACED,  # tower already placed
}

# ─── STATE ─────────────────────────────────────────────
var cells: Dictionary          = {}  # Vector2i → CellState
var tower_spots: Array[Vector2i] = []
var path_cells: Array[Vector2i]  = []
var placed_towers: Dictionary  = {}  # Vector2i → tower node
var is_placing_tower: bool     = false
var _hovered_cell: Vector2i    = Vector2i(-1, -1)

# ─── INIT ──────────────────────────────────────────────
func initialize(
		p_path_waypoints: Array[Vector2],
		p_tower_spots: Array[Vector2i]) -> void:

	cells       = {}
	tower_spots = []
	path_cells  = []
	placed_towers = {}

	# Mark all cells as blocked by default
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			cells[Vector2i(col, row)] = CellState.BLOCKED

	# Mark path cells
	_mark_path_cells(p_path_waypoints)

	# Mark tower spots
	for spot in p_tower_spots:
		if cells.get(spot, CellState.BLOCKED) != CellState.PATH:
			cells[spot] = CellState.TOWER_SPOT
			tower_spots.append(spot)

	set_process_input(true)
	queue_redraw()

func _mark_path_cells(waypoints: Array[Vector2]) -> void:
	for i in range(waypoints.size() - 1):
		var from = world_to_cell(waypoints[i])
		var to   = world_to_cell(waypoints[i + 1])
		_mark_line(from, to)

func _mark_line(from: Vector2i, to: Vector2i) -> void:
	var diff = to - from
	var steps = max(abs(diff.x), abs(diff.y))
	if steps == 0:
		return
	for i in range(steps + 1):
		var t    = float(i) / float(steps)
		var cell = Vector2i(
			int(round(from.x + diff.x * t)),
			int(round(from.y + diff.y * t))
		)
		cells[cell] = CellState.PATH
		if not path_cells.has(cell):
			path_cells.append(cell)

# ─── COORDINATE HELPERS ────────────────────────────────
func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x / CELL_SIZE),
		int(world_pos.y / CELL_SIZE)
	)

func get_cell_center(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * CELL_SIZE + CELL_SIZE / 2.0,
		cell.y * CELL_SIZE + CELL_SIZE / 2.0
	)

# ─── PLACEMENT ─────────────────────────────────────────
func can_place_tower(cell: Vector2i) -> bool:
	return cells.get(cell, CellState.BLOCKED) == CellState.TOWER_SPOT

func place_tower(cell: Vector2i, tower_node: Node = null) -> void:
	cells[cell] = CellState.TOWER_PLACED
	if tower_node:
		placed_towers[cell] = tower_node
	queue_redraw()

func remove_tower(cell: Vector2i) -> void:
	if cells.get(cell) == CellState.TOWER_PLACED:
		cells[cell] = CellState.TOWER_SPOT
		placed_towers.erase(cell)
		queue_redraw()

# ─── INPUT ─────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not is_placing_tower:
		return
	if event is InputEventMouseMotion:
		var cell = world_to_cell(
			get_global_mouse_position() - global_position
		)
		if cell != _hovered_cell:
			_hovered_cell = cell
			queue_redraw()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var cell = world_to_cell(
				get_global_mouse_position() - global_position
			)
			if can_place_tower(cell):
				cell_clicked.emit(cell)
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			is_placing_tower = false
			_hovered_cell    = Vector2i(-1, -1)
			queue_redraw()

# ─── DRAW ──────────────────────────────────────────────
func _draw() -> void:
	_draw_background()
	_draw_path()
	_draw_tower_spots()
	_draw_hover()

func _draw_background() -> void:
	# Dark grid background
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var cell  = Vector2i(col, row)
			var state = cells.get(cell, CellState.BLOCKED)
			var rect  = Rect2(
				col * CELL_SIZE, row * CELL_SIZE,
				CELL_SIZE, CELL_SIZE
			)
			if state == CellState.BLOCKED:
				draw_rect(rect, Color("#050D1A"))
				draw_rect(rect, Color("#0A1628", 0.5), false, 0.5)

func _draw_path() -> void:
	for cell in path_cells:
		var rect = Rect2(
			cell.x * CELL_SIZE + 1,
			cell.y * CELL_SIZE + 1,
			CELL_SIZE - 2,
			CELL_SIZE - 2
		)
		# Path base color
		draw_rect(rect, Color("#0D1F0D"))
		# Subtle path glow
		draw_rect(rect, Color("#00FF88", 0.08))
		# Path border
		draw_rect(rect, Color("#00FF88", 0.25), false, 1.0)

func _draw_tower_spots() -> void:
	for cell in tower_spots:
		var state = cells.get(cell, CellState.BLOCKED)
		var rect  = Rect2(
			cell.x * CELL_SIZE + 2,
			cell.y * CELL_SIZE + 2,
			CELL_SIZE - 4,
			CELL_SIZE - 4
		)

		if state == CellState.TOWER_SPOT:
			# Empty tower platform — glowing cyan
			draw_rect(rect, Color("#001A2A"))
			draw_rect(rect, Color("#00D4FF", 0.12))
			draw_rect(rect, Color("#00D4FF", 0.5), false, 1.5)
			# Corner accent dots
			var corners = [
				Vector2(cell.x * CELL_SIZE + 6,  cell.y * CELL_SIZE + 6),
				Vector2(cell.x * CELL_SIZE + CELL_SIZE - 6, cell.y * CELL_SIZE + 6),
				Vector2(cell.x * CELL_SIZE + 6,  cell.y * CELL_SIZE + CELL_SIZE - 6),
				Vector2(cell.x * CELL_SIZE + CELL_SIZE - 6, cell.y * CELL_SIZE + CELL_SIZE - 6),
			]
			for corner in corners:
				draw_circle(corner, 2.0, Color("#00D4FF", 0.8))

		elif state == CellState.TOWER_PLACED:
			# Occupied platform — darker, no glow
			draw_rect(rect, Color("#001A2A"))
			draw_rect(rect, Color("#00D4FF", 0.15), false, 1.0)

func _draw_hover() -> void:
	if not is_placing_tower:
		return
	if _hovered_cell == Vector2i(-1, -1):
		return
	var state = cells.get(_hovered_cell, CellState.BLOCKED)
	var rect  = Rect2(
		_hovered_cell.x * CELL_SIZE,
		_hovered_cell.y * CELL_SIZE,
		CELL_SIZE, CELL_SIZE
	)
	if state == CellState.TOWER_SPOT:
		# Valid placement — green highlight
		draw_rect(rect, Color("#00FF88", 0.2))
		draw_rect(rect, Color("#00FF88", 0.8), false, 2.0)
	else:
		# Invalid placement — red highlight
		draw_rect(rect, Color("#FF3366", 0.15))
		draw_rect(rect, Color("#FF3366", 0.6), false, 2.0)
