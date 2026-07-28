# GridTilemap.gd
# Replaces procedural grid _draw() with sprite-based tile grid.
class_name GridTilemap
extends Node2D

var grid_system
var tile_size: int = 64

var _dark_tex: ImageTexture
var _path_v_tex: ImageTexture
var _path_h_tex: ImageTexture
var _path_cross_tex: ImageTexture
var _platform_tex: ImageTexture
var _tower_tex: ImageTexture

# Decorative tile variants
var _circuit_tex: ImageTexture
var _data_tex: ImageTexture
var _junction_tex: ImageTexture
var _vent_tex: ImageTexture
var _server_tex: ImageTexture

var _seed: int = 0

func _blend_line(img: Image, x1: int, y1: int, x2: int, y2: int, color: Color):
	var dx = abs(x2 - x1)
	var dy = -abs(y2 - y1)
	var sx = 1 if x1 < x2 else -1
	var sy = 1 if y1 < y2 else -1
	var err = dx + dy
	var x = x1
	var y = y1
	while true:
		if x >= 0 and x < tile_size and y >= 0 and y < tile_size:
			var c = img.get_pixel(x, y)
			c = c.blend(color)
			img.set_pixel(x, y, c)
		if x == x2 and y == y2:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy

func _generate_base(bg: Color, line_color: Color, has_glow: bool, glow_color: Color):
	var img = Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
	img.fill(bg)
	for x in [0, 1, tile_size-2, tile_size-1]:
		for y in range(tile_size):
			var c = img.get_pixel(x, y)
			c = c.blend(Color(line_color.r, line_color.g, line_color.b, 0.10))
			img.set_pixel(x, y, c)
	for y in [0, 1, tile_size-2, tile_size-1]:
		for x in range(tile_size):
			var c = img.get_pixel(x, y)
			c = c.blend(Color(line_color.r, line_color.g, line_color.b, 0.10))
			img.set_pixel(x, y, c)
	if has_glow:
		var cx = tile_size / 2
		var cy = tile_size / 2
		var rmax = tile_size / 2 - 4
		for r in range(rmax, rmax - 6, -1):
			var alpha = float(rmax - r) / 6.0 * 0.35
			for a in range(36):
				var ang = a * 10.0 * PI / 180.0
				var px = int(cx + cos(ang) * r)
				var py = int(cy + sin(ang) * r)
				if px >= 0 and px < tile_size and py >= 0 and py < tile_size:
					var c = img.get_pixel(px, py)
					c = c.blend(Color(glow_color.r, glow_color.g, glow_color.b, alpha))
					img.set_pixel(px, py, c)
	return img

func _generate_tile(bg: Color, line_color: Color, has_glow: bool, glow_color: Color):
	return ImageTexture.create_from_image(_generate_base(bg, line_color, has_glow, glow_color))

func _generate_decoration_circuit():
	var img = _generate_base(Color(0.02, 0.04, 0.08, 1.0), Color(0.0, 0.5, 1.0, 1.0), false, Color())
	var cx = tile_size / 2
	var cy = tile_size / 2
	var trace = Color(0.0, 0.5, 1.0, 0.15)
	var node = Color(0.0, 0.8, 1.0, 0.4)
	var angles = [30, 150, 270]
	for a in angles:
		var rad = a * PI / 180.0
		var len = 12 + (a % 7)
		var ex = int(cx + cos(rad) * len)
		var ey = int(cy + sin(rad) * len)
		_blend_line(img, cx, cy, ex, ey, trace)
	for r in range(3, 0, -1):
		var alpha = float(4 - r) / 4.0 * 0.5
		for a in range(12):
			var ang = a * 30.0 * PI / 180.0
			var px = int(cx + cos(ang) * r)
			var py = int(cy + sin(ang) * r)
			if px >= 0 and px < tile_size and py >= 0 and py < tile_size:
				var c = img.get_pixel(px, py)
				c = c.blend(Color(node.r, node.g, node.b, alpha))
				img.set_pixel(px, py, c)
	return ImageTexture.create_from_image(img)

func _generate_decoration_data():
	var img = _generate_base(Color(0.02, 0.04, 0.08, 1.0), Color(0.0, 0.5, 1.0, 1.0), false, Color())
	var line = Color(0.0, 0.8, 0.5, 0.12)
	var dots = Color(0.0, 1.0, 0.6, 0.3)
	_blend_line(img, 4, 4, tile_size - 4, tile_size - 4, line)
	_blend_line(img, tile_size - 4, 4, 4, tile_size - 4, line)
	_blend_line(img, 4, tile_size / 2, tile_size - 4, tile_size / 2, line)
	for i in range(4):
		var t = float(i) / 3.0
		var px = int(4 + t * (tile_size - 8))
		var py = int(4 + t * (tile_size - 8))
		for r in [1, 2]:
			var alpha = 0.4 if r == 1 else 0.2
			for dx in [-r, r]:
				for dy in [-r, r]:
					var c = img.get_pixel(px + dx, py + dy)
					c = c.blend(Color(dots.r, dots.g, dots.b, alpha))
					img.set_pixel(px + dx, py + dy, c)
	return ImageTexture.create_from_image(img)

func _generate_decoration_junction():
	var img = _generate_base(Color(0.02, 0.04, 0.08, 1.0), Color(0.0, 0.5, 1.0, 1.0), false, Color())
	var cx = tile_size / 2
	var cy = tile_size / 2
	var cross = Color(0.0, 0.4, 0.8, 0.2)
	for off in [8, 12, 16]:
		for y in range(cy - 1, cy + 2):
			for x in range(cx - off, cx - off + 2):
				var c = img.get_pixel(x, y)
				c = c.blend(Color(cross.r, cross.g, cross.b, 0.15))
				img.set_pixel(x, y, c)
		for y in range(cy - 1, cy + 2):
			for x in range(cx + off - 1, cx + off + 1):
				var c = img.get_pixel(x, y)
				c = c.blend(Color(cross.r, cross.g, cross.b, 0.15))
				img.set_pixel(x, y, c)
		for x in range(cx - 1, cx + 2):
			for y in range(cy - off, cy - off + 2):
				var c = img.get_pixel(x, y)
				c = c.blend(Color(cross.r, cross.g, cross.b, 0.15))
				img.set_pixel(x, y, c)
		for x in range(cx - 1, cx + 2):
			for y in range(cy + off - 1, cy + off + 1):
				var c = img.get_pixel(x, y)
				c = c.blend(Color(cross.r, cross.g, cross.b, 0.15))
				img.set_pixel(x, y, c)
	var glow = Color(0.0, 0.6, 1.0, 0.35)
	for r in range(3, 0, -1):
		var alpha = float(4 - r) / 4.0 * 0.6
		for a in range(8):
			var ang = a * 45.0 * PI / 180.0
			var px = int(cx + cos(ang) * r)
			var py = int(cy + sin(ang) * r)
			if px >= 0 and px < tile_size and py >= 0 and py < tile_size:
				var c = img.get_pixel(px, py)
				c = c.blend(Color(glow.r, glow.g, glow.b, alpha))
				img.set_pixel(px, py, c)
	return ImageTexture.create_from_image(img)

func _generate_decoration_vent():
	var img = _generate_base(Color(0.02, 0.04, 0.08, 1.0), Color(0.0, 0.5, 1.0, 1.0), false, Color())
	var vent = Color(0.04, 0.07, 0.14, 1.0)
	var edge = Color(0.0, 0.4, 0.7, 0.15)
	for slat_y in range(8, tile_size - 8, 8):
		for y in range(slat_y, slat_y + 2):
			for x in range(6, tile_size - 6):
				img.set_pixel(x, y, vent)
		for x in range(6, tile_size - 6):
			img.set_pixel(x, slat_y - 1, Color(0.0, 0.6, 0.9, 0.06))
	for y in range(3, tile_size - 3):
		for x in [5, tile_size - 6]:
			img.set_pixel(x, y, edge)
	return ImageTexture.create_from_image(img)

func _generate_decoration_server():
	var img = _generate_base(Color(0.02, 0.04, 0.08, 1.0), Color(0.0, 0.5, 1.0, 1.0), false, Color())
	var body = Color(0.04, 0.06, 0.12, 1.0)
	var led_on = Color(0.0, 1.0, 0.3, 0.6)
	var led_off = Color(0.0, 0.3, 0.1, 0.3)
	for unit in range(3):
		var base_y = 4 + unit * 8
		for y in range(base_y, base_y + 6):
			for x in range(6, tile_size - 6):
				img.set_pixel(x, y, body)
		for y in range(base_y + 1, base_y + 5):
			for x in range(8, 14):
				img.set_pixel(x, y, Color(0.02, 0.03, 0.06, 1.0))
		var led_y = base_y + 3
		for led_x in [18, 24, 30, 36, 42]:
			var led = led_on if (unit + led_x) % 3 != 0 else led_off
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					img.set_pixel(led_x + dx, led_y + dy, led)
	return ImageTexture.create_from_image(img)

func _generate_path_v_image():
	var img = Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.03, 0.05, 0.10, 1.0))
	var mid = tile_size / 2
	var road = Color(0.05, 0.08, 0.15, 1.0)
	for x in range(8, tile_size - 8):
		for y in range(tile_size):
			img.set_pixel(x, y, road)
	var edge = Color(0.0, 1.0, 0.8, 0.5)
	for y in range(3, tile_size - 3):
		for x in [7, tile_size - 9]:
			img.set_pixel(x, y, edge)
			img.set_pixel(x + 1, y, edge.lightened(0.3))
	var dash = Color(0.0, 1.0, 1.0, 0.25)
	for y in range(0, tile_size, 8):
		for yy in range(y, min(y + 4, tile_size)):
			for x in [mid - 1, mid]:
				img.set_pixel(x, yy, dash)
	return img

func _generate_path_h_image():
	var img = Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.03, 0.05, 0.10, 1.0))
	var mid = tile_size / 2
	var road = Color(0.05, 0.08, 0.15, 1.0)
	for y in range(8, tile_size - 8):
		for x in range(tile_size):
			img.set_pixel(x, y, road)
	var edge = Color(0.0, 1.0, 0.8, 0.5)
	for x in range(3, tile_size - 3):
		for y in [7, tile_size - 9]:
			img.set_pixel(x, y, edge)
			img.set_pixel(x, y + 1, edge.lightened(0.3))
	var dash = Color(0.0, 1.0, 1.0, 0.25)
	for x in range(0, tile_size, 8):
		for xx in range(x, min(x + 4, tile_size)):
			for y in [mid - 1, mid]:
				img.set_pixel(xx, y, dash)
	return img

func _generate_path_cross_image():
	var img = Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.03, 0.05, 0.10, 1.0))
	var mid = tile_size / 2
	var road = Color(0.05, 0.08, 0.15, 1.0)
	# Horizontal road band
	for y in range(8, tile_size - 8):
		for x in range(tile_size):
			img.set_pixel(x, y, road)
	# Vertical road band
	for x in range(8, tile_size - 8):
		for y in range(tile_size):
			img.set_pixel(x, y, road)
	var edge = Color(0.0, 1.0, 0.8, 0.5)
	# Vertical edge strips (left / right)
	for y in range(3, tile_size - 3):
		for x in [7, tile_size - 9]:
			img.set_pixel(x, y, edge)
			img.set_pixel(x + 1, y, edge.lightened(0.3))
	# Horizontal edge strips (top / bottom)
	for x in range(3, tile_size - 3):
		for y in [7, tile_size - 9]:
			img.set_pixel(x, y, edge)
			img.set_pixel(x, y + 1, edge.lightened(0.3))
	var dash = Color(0.0, 1.0, 1.0, 0.25)
	# Vertical center dashes
	for y in range(0, tile_size, 8):
		for yy in range(y, min(y + 4, tile_size)):
			for x in [mid - 1, mid]:
				img.set_pixel(x, yy, dash)
	# Horizontal center dashes
	for x in range(0, tile_size, 8):
		for xx in range(x, min(x + 4, tile_size)):
			for y in [mid - 1, mid]:
				img.set_pixel(xx, y, dash)
	return img

func generate_tiles() -> void:
	_dark_tex = _generate_tile(
		Color(0.02, 0.04, 0.08, 1.0),
		Color(0.0, 0.5, 1.0, 1.0),
		false, Color()
	)
	_path_v_tex = ImageTexture.create_from_image(_generate_path_v_image())
	_path_h_tex = ImageTexture.create_from_image(_generate_path_h_image())
	_path_cross_tex = ImageTexture.create_from_image(_generate_path_cross_image())
	_platform_tex = _generate_tile(
		Color(0.02, 0.06, 0.12, 1.0),
		Color(0.0, 1.0, 0.5, 1.0),
		true, Color(0.0, 1.0, 0.5, 1.0)
	)
	_tower_tex = _generate_tile(
		Color(0.03, 0.08, 0.15, 1.0),
		Color(0.0, 0.8, 1.0, 1.0),
		true, Color(0.0, 0.8, 1.0, 1.0)
	)
	# Decorative variants (applied to ~40% of BLOCKED cells)
	_circuit_tex = _generate_decoration_circuit()
	_data_tex = _generate_decoration_data()
	_junction_tex = _generate_decoration_junction()
	_vent_tex = _generate_decoration_vent()
	_server_tex = _generate_decoration_server()

func _get_decoration_for(cell: Vector2i):
	var h = _seed + cell.x * 7 + cell.y * 31 + cell.x * cell.y * 13
	var r = (h % 20) + 1
	match r:
		1, 2:
			return _circuit_tex
		3, 4:
			return _data_tex
		5, 6:
			return _junction_tex
		7:
			return _vent_tex
		8:
			return _server_tex
		_:
			return _dark_tex

func _path_tex_for(cell: Vector2i) -> ImageTexture:
	var left = Vector2i(cell.x - 1, cell.y)
	var right = Vector2i(cell.x + 1, cell.y)
	var up = Vector2i(cell.x, cell.y - 1)
	var down = Vector2i(cell.x, cell.y + 1)
	var left_p = grid_system.cells.get(left, -1) == grid_system.CellState.PATH
	var right_p = grid_system.cells.get(right, -1) == grid_system.CellState.PATH
	var up_p = grid_system.cells.get(up, -1) == grid_system.CellState.PATH
	var down_p = grid_system.cells.get(down, -1) == grid_system.CellState.PATH
	var h = left_p or right_p
	var v = up_p or down_p
	if h and v:
		return _path_cross_tex
	if h:
		return _path_h_tex
	return _path_v_tex

func build_from_grid(grid, base_cell: Vector2i = Vector2i(-1, -1)) -> void:
	grid_system = grid
	_seed = GameManager.current_level * 7919
	generate_tiles()
	
	for cell_x in range(grid.GRID_COLS):
		for cell_y in range(grid.GRID_ROWS):
			var cell = Vector2i(cell_x, cell_y)
			var state = grid.cells.get(cell, grid.CellState.BLOCKED)
			var tex: ImageTexture
			match state:
				grid.CellState.BLOCKED:
					tex = _get_decoration_for(cell)
				grid.CellState.PATH:
					tex = _path_tex_for(cell)
				grid.CellState.TOWER_SPOT, grid.CellState.TOWER_PLACED:
					tex = _platform_tex
				_:
					tex = _dark_tex
			
			var spr = Sprite2D.new()
			spr.texture = tex
			spr.position = Vector2(
				cell_x * tile_size + tile_size / 2,
				cell_y * tile_size + tile_size / 2
			)
			add_child(spr)
	
	# Place base entity at endpoint
	if base_cell.x >= 0:
		_draw_base(base_cell)

func _draw_base(cell: Vector2i) -> void:
	var base := Node2D.new()
	base.position = Vector2(
		cell.x * tile_size + tile_size / 2,
		cell.y * tile_size + tile_size / 2
	)
	add_child(base)
	
	var rack := ColorRect.new()
	rack.color = Color(0.04, 0.06, 0.12, 1.0)
	rack.size = Vector2(48, 56)
	rack.position = Vector2(-24, -28)
	base.add_child(rack)
	
	var border := ColorRect.new()
	border.color = Color(0.0, 0.8, 1.0, 0.6)
	border.size = Vector2(50, 58)
	border.position = Vector2(-25, -29)
	base.add_child(border)
	
	for i in range(3):
		var led := ColorRect.new()
		led.color = Color(0.0, 1.0, 0.3, 0.9)
		led.size = Vector2(6, 4)
		led.position = Vector2(-12 + i * 12, -8)
		base.add_child(led)
		var t = create_tween().set_loops()
		t.tween_property(led, "color", Color(0.0, 0.3, 0.1, 0.9), 0.5 + i * 0.2)
		t.tween_property(led, "color", Color(0.0, 1.0, 0.3, 0.9), 0.5 + i * 0.2)
