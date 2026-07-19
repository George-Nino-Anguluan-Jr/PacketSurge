# GridSystem.gd
class_name GridSystem
extends Node2D

signal cell_clicked(cell: Vector2i)
signal first_tower_placed(tower_id: String)

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

# ─── CYBERPUNK ANIMATION & THEME STATE ─────────────────
var _time: float = 0.0
var _theme: Dictionary = {}
var _decorations: Array = []  # Array of dictionaries: { "cell": Vector2i, "type": String, "rotation_speed": float, "color_offset": float, "pulse_speed": float }
var _binary_particles: Array = []  # Array of dictionaries: { "pos": Vector2, "vel": Vector2, "char": String, "life": float }

const SECTOR_THEMES = {
	"copper": {
		"bg_color": Color("#050D1A"),
		"grid_line": Color("#00FF88", 0.06),
		"grid_glow": Color("#00FF88", 0.25),
		"path_base": Color("#0E2A14"),
		"path_glow": Color("#00FF88", 0.12),
		"path_border": Color("#00FF88", 0.45),
		"laser_color": Color("#00FF88"),
		"circuit_color": Color("#FFB800", 0.2),
		"accent": Color("#FFB800"),
		"name": "Copper Core"
	},
	"optical": {
		"bg_color": Color("#050A1A"),
		"grid_line": Color("#00D4FF", 0.06),
		"grid_glow": Color("#00D4FF", 0.25),
		"path_base": Color("#0A1C30"),
		"path_glow": Color("#00D4FF", 0.15),
		"path_border": Color("#00D4FF", 0.5),
		"laser_color": Color("#00D4FF"),
		"circuit_color": Color("#FF00AA", 0.2),
		"accent": Color("#FF00AA"),
		"name": "Optical Mainframe"
	},
	"firewall": {
		"bg_color": Color("#0F050A"),
		"grid_line": Color("#FF3366", 0.06),
		"grid_glow": Color("#FF3366", 0.25),
		"path_base": Color("#300A15"),
		"path_glow": Color("#FF3366", 0.12),
		"path_border": Color("#FF3366", 0.45),
		"laser_color": Color("#FF3366"),
		"circuit_color": Color("#9B59B6", 0.2),
		"accent": Color("#9B59B6"),
		"name": "Void Firewall"
	}
}

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

	# Dynamic auto-correction pass to ensure all tower spots are positioned immediately adjacent to the path!
	var corrected_tower_spots: Array[Vector2i] = []
	for spot in p_tower_spots:
		if cells.get(spot, CellState.BLOCKED) == CellState.PATH:
			continue
			
		# If the spot is already next to the enemy path, keep it!
		if _is_adjacent_to_path(spot):
			corrected_tower_spots.append(spot)
		else:
			# Otherwise, find the nearest cell to this spot that is adjacent to the path
			var corrected_spot = _find_nearest_path_adjacent_cell(spot, corrected_tower_spots)
			if corrected_spot != Vector2i(-1, -1):
				corrected_tower_spots.append(corrected_spot)
			else:
				corrected_tower_spots.append(spot) # fallback

	# Mark tower spots
	for spot in corrected_tower_spots:
		cells[spot] = CellState.TOWER_SPOT
		tower_spots.append(spot)

	# Setup theme & deterministic motherboard decorations
	_theme = _get_current_theme()
	_generate_decorations()

	set_process_input(true)
	set_process(true)
	queue_redraw()

func _is_adjacent_to_path(cell: Vector2i) -> bool:
	var neighbors = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)
	]
	for offset in neighbors:
		var check_cell = cell + offset
		if cells.get(check_cell, CellState.BLOCKED) == CellState.PATH:
			return true
	return false

func _find_nearest_path_adjacent_cell(origin: Vector2i, occupied: Array[Vector2i]) -> Vector2i:
	var best_cell = Vector2i(-1, -1)
	var best_dist = 999999.0
	
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var cell = Vector2i(col, row)
			# Spot must not be path, nor already taken
			if cells.get(cell, CellState.BLOCKED) == CellState.PATH:
				continue
			if cell in occupied:
				continue
				
			if _is_adjacent_to_path(cell):
				var dist = origin.distance_to(cell)
				if dist < best_dist:
					best_dist = dist
					best_cell = cell
					
	return best_cell

func _get_current_theme() -> Dictionary:
	var lvl = GameManager.current_level
	if lvl <= 4:
		return SECTOR_THEMES["copper"]
	elif lvl <= 9:
		return SECTOR_THEMES["optical"]
	else:
		return SECTOR_THEMES["firewall"]

func _process(delta: float) -> void:
	_time += delta
	_update_binary_particles(delta)
	queue_redraw()

func _generate_decorations() -> void:
	_decorations.clear()
	var rng = RandomNumberGenerator.new()
	# Ensure deterministic motherboard layouts for each level number
	rng.seed = GameManager.current_level * 1234
	
	var blocked_cells: Array[Vector2i] = []
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var cell = Vector2i(col, row)
			if cells.get(cell, CellState.BLOCKED) == CellState.BLOCKED:
				blocked_cells.append(cell)
				
	# Seed-based shuffle of blocked cells
	for i in range(blocked_cells.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = blocked_cells[i]
		blocked_cells[i] = blocked_cells[j]
		blocked_cells[j] = temp
		
	# Select 22% of empty cells to house physical microcontrollers and visual gears
	var num_decorations = int(blocked_cells.size() * 0.22)
	for i in range(min(num_decorations, blocked_cells.size())):
		var cell = blocked_cells[i]
		var type_roll = rng.randf()
		var type = "microchip"
		if type_roll < 0.35:
			type = "microchip"
		elif type_roll < 0.65:
			type = "capacitor"
		elif type_roll < 0.85:
			type = "cooling_fan"
		else:
			type = "server_tower"
			
		_decorations.append({
			"cell": cell,
			"type": type,
			"rotation_speed": rng.randf_range(1.5, 3.5) * (1 if rng.randf() > 0.5 else -1),
			"color_offset": rng.randf(),
			"pulse_speed": rng.randf_range(2.0, 5.0)
		})

func _update_binary_particles(delta: float) -> void:
	# Occasional spawn from server columns & chips
	if _decorations.size() > 0 and randf() < 0.12:
		var dec = _decorations[randi() % _decorations.size()]
		if dec["type"] in ["microchip", "server_tower"]:
			var cell = dec["cell"]
			var center = get_cell_center(cell)
			_binary_particles.append({
				"pos": center + Vector2(randf_range(-15, 15), randf_range(-15, 15)),
				"vel": Vector2(0, -randf_range(20, 50)),
				"char": "1" if randf() > 0.5 else "0",
				"life": 1.0
			})
			
	# Update lifetime and move
	var active: Array = []
	for p in _binary_particles:
		p["pos"] += p["vel"] * delta
		p["life"] -= delta
		if p["life"] > 0:
			active.append(p)
	_binary_particles = active

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

func get_tower_at(cell: Vector2i):
	return placed_towers.get(cell, null)

func remove_tower(cell: Vector2i) -> void:
	if cells.get(cell) == CellState.TOWER_PLACED:
		cells[cell] = CellState.TOWER_SPOT
		placed_towers.erase(cell)
		queue_redraw()

# ─── INPUT ─────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not is_placing_tower:
		# If we are not placing a tower, we should still allow cell clicking!
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var cell = world_to_cell(
				get_global_mouse_position() - global_position
			)
			if cell.x >= 0 and cell.x < GRID_COLS and cell.y >= 0 and cell.y < GRID_ROWS:
				var state = cells.get(cell, CellState.BLOCKED)
				if state == CellState.TOWER_SPOT or state == CellState.TOWER_PLACED:
					cell_clicked.emit(cell)
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
	_draw_circuit_board_decorations()
	_draw_path()
	_draw_tower_spots()
	_draw_binary_particles()
	_draw_hover()

func _draw_background() -> void:
	# Core background backdrop - cover the entire viewport screen to eliminate gray margins
	var rect_full = Rect2(-2000, -2000, 5000, 4000)
	draw_rect(rect_full, _theme.get("bg_color", Color("#050D1A")))

	# Grid cells overlay
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var rect = Rect2(col * CELL_SIZE, row * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			draw_rect(rect, _theme.get("grid_line", Color("#00FF88", 0.05)), false, 0.5)
			
			# Mini junction points
			if col > 0 and row > 0:
				draw_circle(Vector2(col * CELL_SIZE, row * CELL_SIZE), 1.2, _theme.get("grid_glow", Color("#00FF88", 0.2)))

func _draw_circuit_board_decorations() -> void:
	_draw_circuit_traces()

	# Draw main physical component shapes over traces
	for dec in _decorations:
		var cell = dec["cell"]
		var center = get_cell_center(cell)
		
		match dec["type"]:
			"microchip":
				var rect = Rect2(center - Vector2(18, 18), Vector2(36, 36))
				draw_rect(rect, Color("#0B0F19"))
				draw_rect(rect, _theme["accent"], false, 1.5)
				# Golden copper pins
				for j in range(4):
					var offset = -12 + j * 8
					draw_line(rect.position + Vector2(18 + offset, 0), rect.position + Vector2(18 + offset, -5), Color("#FFD700", 0.65), 1.5)
					draw_line(rect.position + Vector2(18 + offset, 36), rect.position + Vector2(18 + offset, 41), Color("#FFD700", 0.65), 1.5)
					draw_line(rect.position + Vector2(0, 18 + offset), rect.position + Vector2(-5, 18 + offset), Color("#FFD700", 0.65), 1.5)
					draw_line(rect.position + Vector2(36, 18 + offset), rect.position + Vector2(41, 18 + offset), Color("#FFD700", 0.65), 1.5)

			"capacitor":
				# Cylindrical micro-condenser top
				draw_circle(center, 13.0, Color("#131A26"))
				draw_circle(center, 13.0, _theme["laser_color"], false, 1.5)
				# Polar negative stripe
				draw_line(center - Vector2(13, 0), center + Vector2(13, 0), Color.BLACK, 3.5)
				draw_line(center - Vector2(11, 0), center + Vector2(11, 0), Color.WHITE, 1.5)

			"cooling_fan":
				# Outer frame and circular hub
				draw_circle(center, 15.0, Color("#070B12"))
				draw_circle(center, 15.0, _theme["accent"], false, 1.2)
				# Spinning rotor blades
				var angle_base = _time * dec["rotation_speed"]
				for b in range(4):
					var blade_angle = angle_base + b * (PI / 2.0)
					var end_pos = center + Vector2(11, 0).rotated(blade_angle)
					draw_line(center, end_pos, _theme["accent"], 2.2)

			"server_tower":
				var rect = Rect2(center - Vector2(12, 18), Vector2(24, 36))
				draw_rect(rect, Color("#0D1321"))
				draw_rect(rect, _theme["laser_color"], false, 1.5)
				# Horizontal system bays
				for s in range(3):
					var y_offset = -10 + s * 9
					draw_line(center + Vector2(-8, y_offset), center + Vector2(8, y_offset + 3), _theme["laser_color"] * 0.35, 1.8)
				# Blinking diagnostic array lights
				var pulse = sin(_time * dec["pulse_speed"] + dec["color_offset"] * 8.0) > 0.0
				var primary_led = Color("#00FF88") if pulse else Color("#FF3366")
				var secondary_led = Color("#00D4FF") if not pulse else Color("#FFD700")
				draw_circle(center + Vector2(-5, 11), 1.8, primary_led)
				draw_circle(center + Vector2(5, 11), 1.8, secondary_led)

func _draw_circuit_traces() -> void:
	var trace_col = _theme.get("circuit_color", Color("#FFB800", 0.2))
	for dec in _decorations:
		var cell = dec["cell"]
		var start = get_cell_center(cell)
		
		# Trace branching out using deterministic cell seeds
		var seed_val = cell.x * 37 + cell.y * 73
		var angle1 = (seed_val % 8) * (PI / 4.0)
		var angle2 = ((seed_val + 3) % 8) * (PI / 4.0)
		
		var mid_point = start + Vector2(28, 0).rotated(angle1)
		var end_point = mid_point + Vector2(18, 18).rotated(angle2)
		
		# Render glowing circuits and nodes
		draw_line(start, mid_point, trace_col, 1.2)
		draw_line(mid_point, end_point, trace_col, 1.2)
		draw_circle(end_point, 2.0, trace_col)

func _draw_path() -> void:
	for cell in path_cells:
		var rect = Rect2(
			cell.x * CELL_SIZE + 1,
			cell.y * CELL_SIZE + 1,
			CELL_SIZE - 2,
			CELL_SIZE - 2
		)
		# Theme-aware path styling
		draw_rect(rect, _theme.get("path_base", Color("#0E2A14")))
		# Pulse glow rate
		var pulse = 0.8 + 0.25 * sin(_time * 3.5)
		draw_rect(rect, _theme.get("path_glow", Color("#00FF88", 0.12)) * pulse)
		draw_rect(rect, _theme.get("path_border", Color("#00FF88", 0.45)), false, 1.0)

	_draw_path_flow_pulses()

func _draw_path_flow_pulses() -> void:
	if path_cells.is_empty():
		return
		
	# High-speed data flow indicators matching enemy movement direction
	var spacing = 5
	var step_offset = int(_time * 10.0) % spacing
	
	for i in range(path_cells.size()):
		if (i - step_offset) % spacing == 0:
			var cell = path_cells[i]
			var center = get_cell_center(cell)
			
			var dir = Vector2.ZERO
			if i < path_cells.size() - 1:
				dir = Vector2(path_cells[i + 1] - path_cells[i]).normalized()
			else:
				dir = Vector2(path_cells[i] - path_cells[i - 1]).normalized()
				
			var color = _theme.get("laser_color", Color("#00FF88"))
			color.a = 0.75
			
			# Arrow shape drawing
			var arrow_head = center + dir * 8.0
			var wing_left = center - dir * 4.0 + Vector2(-dir.y, dir.x) * 4.5
			var wing_right = center - dir * 4.0 - Vector2(-dir.y, dir.x) * 4.5
			
			draw_line(center - dir * 8.0, arrow_head, color, 2.2)
			draw_line(arrow_head, wing_left, color, 1.8)
			draw_line(arrow_head, wing_right, color, 1.8)

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
			# Holographic empty slot — neon blue or cyan
			draw_rect(rect, Color("#030F1A"))
			var pulse = 0.08 + 0.06 * sin(_time * 4.0)
			draw_rect(rect, _theme.get("laser_color", Color("#00D4FF")) * pulse)
			
			# Draw cyberpunk frame brackets
			var cs = CELL_SIZE
			var cx = cell.x * cs
			var cy = cell.y * cs
			var bracket_col = _theme.get("laser_color", Color("#00D4FF"))
			bracket_col.a = 0.7
			var bl = 9.0  # Bracket line length
			
			# Top-Left Bracket
			draw_line(Vector2(cx + 4, cy + 4), Vector2(cx + 4 + bl, cy + 4), bracket_col, 1.8)
			draw_line(Vector2(cx + 4, cy + 4), Vector2(cx + 4, cy + 4 + bl), bracket_col, 1.8)
			
			# Top-Right Bracket
			draw_line(Vector2(cx + cs - 4, cy + 4), Vector2(cx + cs - 4 - bl, cy + 4), bracket_col, 1.8)
			draw_line(Vector2(cx + cs - 4, cy + 4), Vector2(cx + cs - 4, cy + 4 + bl), bracket_col, 1.8)
			
			# Bottom-Left Bracket
			draw_line(Vector2(cx + 4, cy + cs - 4), Vector2(cx + 4 + bl, cy + cs - 4), bracket_col, 1.8)
			draw_line(Vector2(cx + 4, cy + cs - 4), Vector2(cx + 4, cy + cs - 4 - bl), bracket_col, 1.8)
			
			# Bottom-Right Bracket
			draw_line(Vector2(cx + cs - 4, cy + cs - 4), Vector2(cx + cs - 4 - bl, cy + cs - 4), bracket_col, 1.8)
			draw_line(Vector2(cx + cs - 4, cy + cs - 4), Vector2(cx + cs - 4, cy + cs - 4 - bl), bracket_col, 1.8)
			
			# Center anchor point
			draw_circle(get_cell_center(cell), 2.5, bracket_col)

		elif state == CellState.TOWER_PLACED:
			# Placed state — sleek nested panel
			draw_rect(rect, Color("#010912"))
			draw_rect(rect, _theme.get("laser_color", Color("#00D4FF")) * 0.3, false, 1.0)

func _draw_binary_particles() -> void:
	for p in _binary_particles:
		var alpha = p["life"]
		var color = _theme.get("accent", Color("#FFB800"))
		color.a = alpha * 0.4
		
		# Draw zero as a micro hollow circle, one as a vertical micro bar
		if p["char"] == "0":
			draw_circle(p["pos"], 3.0, color, false, 1.0)
		else:
			draw_line(p["pos"] + Vector2(0, -3), p["pos"] + Vector2(0, 3), color, 1.5)

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
