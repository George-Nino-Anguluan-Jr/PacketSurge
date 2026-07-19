extends RefCounted

const SZ := 64
const MID := 32

static func generate(tower_id: String, color: Color) -> ImageTexture:
	var img = Image.create(SZ, SZ, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	var dark := Color(0.04, 0.06, 0.12)
	var neon := Color(color.r, color.g, color.b, 1.0)
	var dim := Color(color.r * 0.4, color.g * 0.4, color.b * 0.4, 1.0)
	_draw_platform(img, dark, neon)
	match tower_id:
		"tower_array":
			_draw_array(img, dark, neon, dim)
		"tower_stack":
			_draw_stack(img, dark, neon, dim)
		"tower_queue":
			_draw_queue(img, dark, neon, dim)
		"tower_linked_list":
			_draw_linked(img, dark, neon, dim)
		"tower_bubble":
			_draw_bubble(img, dark, neon, dim)
		"tower_selection":
			_draw_selection(img, dark, neon, dim)
		"tower_insertion":
			_draw_insertion(img, dark, neon, dim)
		"tower_quick":
			_draw_quick(img, dark, neon, dim)
		"tower_merge":
			_draw_merge(img, dark, neon, dim)
		"tower_counting":
			_draw_counting(img, dark, neon, dim)
		"tower_radix":
			_draw_radix(img, dark, neon, dim)
		"tower_linear":
			_draw_linear(img, dark, neon, dim)
		"tower_binary":
			_draw_binary(img, dark, neon, dim)
		_:
			_draw_array(img, dark, neon, dim)
	return ImageTexture.create_from_image(img)

static func _pset(img: Image, x: int, y: int, c: Color):
	if x >= 0 and x < SZ and y >= 0 and y < SZ:
		img.set_pixel(x, y, c)

static func _fill_rect(img: Image, x1: int, y1: int, x2: int, y2: int, c: Color):
	for x in range(max(x1, 0), min(x2 + 1, SZ)):
		for y in range(max(y1, 0), min(y2 + 1, SZ)):
			img.set_pixel(x, y, c)

static func _draw_circle(img: Image, cx: int, cy: int, r: int, c: Color, filled: bool = true):
	for x in range(cx - r, cx + r + 1):
		for y in range(cy - r, cy + r + 1):
			if x >= 0 and x < SZ and y >= 0 and y < SZ:
				var dx = x - cx
				var dy = y - cy
				if dx * dx + dy * dy <= r * r:
					if filled or dx * dx + dy * dy > (r - 1) * (r - 1):
						img.set_pixel(x, y, c)

static func _draw_platform(img: Image, dark: Color, neon: Color):
	var plat = Color(0.06, 0.08, 0.16, 1.0)
	_draw_circle(img, MID, 56, 22, plat)
	_draw_circle(img, MID, 56, 22, Color(neon.r, neon.g, neon.b, 0.15), false)
	_draw_circle(img, MID, 56, 20, Color(neon.r, neon.g, neon.b, 0.08), false)

static func _draw_glow_dots(img: Image, positions: Array, color: Color, rad: int = 2):
	for p in positions:
		_draw_circle(img, p[0], p[1], rad, color)

# ─── PER-TYPE DRAWERS ────────────────────────────────────

static func _draw_array(img: Image, dark: Color, neon: Color, dim: Color):
	_fill_rect(img, 16, 18, 22, 52, dark)
	_fill_rect(img, 42, 18, 48, 52, dark)
	_fill_rect(img, 22, 18, 42, 24, dark)
	_fill_rect(img, 22, 46, 42, 52, dark)
	_fill_rect(img, 22, 18, 42, 52, Color(neon.r, neon.g, neon.b, 0.06))
	for y in range(26, 48, 6):
		for x in [24, 40]:
			_pset(img, x, y, neon)
		_pset(img, 25, y, dim)
		_pset(img, 39, y, dim)
	_fill_rect(img, 28, 28, 36, 44, Color(neon.r, neon.g, neon.b, 0.04))
	_pset(img, MID, 16, neon)

static func _draw_stack(img: Image, dark: Color, neon: Color, dim: Color):
	var bw = 10
	var bh = 7
	var gap = 2
	var base_y = 46
	for i in range(4):
		var y = base_y - i * (bh + gap)
		var x_off = i * 3
		_fill_rect(img, MID - bw - x_off, y, MID + bw + x_off, y + bh, dark)
		_fill_rect(img, MID - bw - x_off, y, MID + bw + x_off, y + 1, neon)
		_pset(img, MID - bw - x_off, y + 2, dim)
		_pset(img, MID + bw + x_off, y + 2, dim)
	_fill_rect(img, MID - 2, 14, MID + 2, base_y + bh, Color(neon.r, neon.g, neon.b, 0.06))
	_pset(img, MID, 12, neon)

static func _draw_queue(img: Image, dark: Color, neon: Color, dim: Color):
	var x_positions = [14, 24, 34, 44]
	for i in range(x_positions.size()):
		var x = x_positions[i]
		var y_off = i * -2
		_fill_rect(img, x, 36 + y_off, x + 6, 52 + y_off, dark)
		_fill_rect(img, x, 36 + y_off, x + 6, 37 + y_off, neon)
		var led = Color(neon.r * 0.7, neon.g * 0.7, neon.b * 0.7, 1.0) if i < x_positions.size() - 1 else neon
		_pset(img, x + 1, 40 + y_off, led)
	var line_y = 36
	_fill_rect(img, 14, line_y - 1, 50, line_y + 1, dim)
	# Arrow at front
	_fill_rect(img, 50, line_y - 4, 54, line_y + 4, Color(neon.r, neon.g, neon.b, 0.4))
	_pset(img, 55, line_y, neon)
	_pset(img, 52, line_y - 3, dim)
	_pset(img, 52, line_y + 3, dim)

static func _draw_linked(img: Image, dark: Color, neon: Color, dim: Color):
	var nodes_x = [12, MID, 52]
	for i in range(nodes_x.size()):
		var x = nodes_x[i]
		_draw_circle(img, x, 36, 8, dark)
		_draw_circle(img, x, 36, 8, Color(neon.r, neon.g, neon.b, 0.3), false)
		_draw_circle(img, x, 36, 4, dim)
		_pset(img, x, 36, neon)
		_pset(img, x - 2, 34, Color(neon.r, neon.g, neon.b, 0.5))
	if nodes_x.size() >= 2:
		for i in range(nodes_x.size() - 1):
			var x1 = nodes_x[i] + 8
			var x2 = nodes_x[i + 1] - 8
			_fill_rect(img, x1, 35, x2, 37, dark)
			_fill_rect(img, x1, 35, x2, 36, dim)
			_pset(img, x1 + 1, 36, dim)

static func _draw_bubble(img: Image, dark: Color, neon: Color, dim: Color):
	_draw_circle(img, MID, 34, 14, dark)
	_draw_circle(img, MID, 34, 14, Color(neon.r, neon.g, neon.b, 0.2), false)
	_draw_circle(img, MID, 34, 8, Color(neon.r, neon.g, neon.b, 0.08))
	for a in range(0, 360, 60):
		var rad = deg_to_rad(a)
		var bx = MID + int(cos(rad) * 20)
		var by = 34 + int(sin(rad) * 20)
		_draw_circle(img, bx, by, 3, Color(neon.r, neon.g, neon.b, 0.3))
	_draw_circle(img, MID, 34, 4, dim)
	_pset(img, MID, 34, neon)

static func _draw_selection(img: Image, dark: Color, neon: Color, dim: Color):
	var pts = PackedVector2Array([
		Vector2(MID, 14),
		Vector2(18, 46),
		Vector2(46, 46)
	])
	for y in range(14, 47):
		for x in range(18, 47):
			var inside = true
			for i in range(3):
				var j = (i + 1) % 3
				var v = pts[j] - pts[i]
				var w = Vector2(x, y) - pts[i]
				var cross = v.x * w.y - v.y * w.x
				if cross < 0:
					inside = false
					break
			if inside:
				img.set_pixel(x, y, dark)
	_fill_rect(img, 18, 44, 46, 46, Color(neon.r, neon.g, neon.b, 0.08))
	for y in range(14, 47):
		for x in [18, 46]:
			if y >= 14 and y <= 46:
				var on_edge = abs((x - MID) * (46 - 14) - (y - 14) * (46 - 18)) < 20
				if on_edge:
					_pset(img, x, y, neon if y < 44 else dim)
	_pset(img, MID, 30, neon)
	_fill_rect(img, MID - 6, 30, MID + 6, 32, dim)

static func _draw_insertion(img: Image, dark: Color, neon: Color, dim: Color):
	# Piston body
	_fill_rect(img, 20, 22, 44, 48, dark)
	_fill_rect(img, 20, 22, 44, 24, neon)
	_fill_rect(img, 20, 22, 22, 48, dim)
	_fill_rect(img, 42, 22, 44, 48, dim)
	# Slider bar
	_fill_rect(img, 26, 16, 38, 22, Color(neon.r, neon.g, neon.b, 0.15))
	_fill_rect(img, 26, 16, 38, 17, dim)
	_fill_rect(img, 26, 16, 27, 22, dim)
	_fill_rect(img, 37, 16, 38, 22, dim)
	# Arrow indicator
	_fill_rect(img, MID - 1, 28, MID + 1, 42, Color(neon.r, neon.g, neon.b, 0.2))
	for y in [30, 34, 38]:
		_pset(img, MID, y, neon)

static func _draw_quick(img: Image, dark: Color, neon: Color, dim: Color):
	# Split V shape
	for x in range(14, MID):
		var y_top = 18 + (MID - x) / 2
		var y_bot = 52 - (MID - x) / 2
		_fill_rect(img, x, y_top, x + 2, y_bot, dark)
		_pset(img, x, y_top, neon)
		_pset(img, x + 1, y_bot, dim)
	for x in range(MID, 50):
		var y_top = 18 + (x - MID) / 2
		var y_bot = 52 - (x - MID) / 2
		_fill_rect(img, x, y_top, x + 2, y_bot, dark)
		_pset(img, x, y_top, neon)
		_pset(img, x + 1, y_bot, dim)
	# Center pivot
	_draw_circle(img, MID, 34, 6, dark)
	_draw_circle(img, MID, 34, 6, Color(neon.r, neon.g, neon.b, 0.3), false)
	_pset(img, MID, 34, neon)
	_pset(img, MID - 2, 34, dim)
	_pset(img, MID + 2, 34, dim)

static func _draw_merge(img: Image, dark: Color, neon: Color, dim: Color):
	# Two pillars merging upward
	for x_off in [-8, 8]:
		var cx = MID + x_off
		_fill_rect(img, cx - 6, 28, cx + 6, 52, dark)
		_fill_rect(img, cx - 6, 28, cx + 6, 29, neon)
		_fill_rect(img, cx - 6, 28, cx - 5, 52, dim)
		_fill_rect(img, cx + 5, 28, cx + 6, 52, dim)
		for y in [34, 40, 46]:
			_pset(img, cx, y, neon)
	# Merge arch
	for x in range(MID - 8, MID + 9):
		var y = 18 + abs(8 - abs(x - MID))
		_pset(img, x, y, dim)
		_pset(img, x, y + 1, Color(neon.r, neon.g, neon.b, 0.08))
	# Top node
	_draw_circle(img, MID, 16, 5, dark)
	_draw_circle(img, MID, 16, 5, Color(neon.r, neon.g, neon.b, 0.3), false)
	_pset(img, MID, 16, neon)

static func _draw_counting(img: Image, dark: Color, neon: Color, dim: Color):
	# Tally grid
	var cols = 4
	var rows = 4
	var cell_sz = 6
	var gap = 3
	var start_x = MID - (cols * (cell_sz + gap)) / 2
	var start_y = 24
	for r in range(rows):
		for c in range(cols):
			var x = start_x + c * (cell_sz + gap)
			var y = start_y + r * (cell_sz + gap)
			_fill_rect(img, x, y, x + cell_sz, y + cell_sz, dark)
			_fill_rect(img, x, y, x + cell_sz, y + 1, neon)
			_pset(img, x + 1, y + 2, dim)
			_pset(img, x + cell_sz - 2, y + 2, dim)
	# Counter display
	_fill_rect(img, MID - 10, 46, MID + 10, 52, Color(neon.r, neon.g, neon.b, 0.15))
	for x in [MID - 6, MID, MID + 4]:
		_pset(img, x, 48, neon)
		_pset(img, x, 50, dim)

static func _draw_radix(img: Image, dark: Color, neon: Color, dim: Color):
	_draw_circle(img, MID, 34, 18, dark)
	_draw_circle(img, MID, 34, 18, Color(neon.r, neon.g, neon.b, 0.25), false)
	_draw_circle(img, MID, 34, 14, Color(neon.r, neon.g, neon.b, 0.08), false)
	for i in range(10):
		var a = i * 36
		var rad = deg_to_rad(a)
		var x = MID + int(cos(rad) * 16)
		var y = 34 + int(sin(rad) * 16)
		_pset(img, x, y, neon if i % 3 == 0 else dim)
	# Inner rings
	_draw_circle(img, MID, 34, 6, Color(neon.r, neon.g, neon.b, 0.12), false)
	_draw_circle(img, MID, 34, 4, dim)
	_pset(img, MID, 34, neon)

static func _draw_linear(img: Image, dark: Color, neon: Color, dim: Color):
	# Search beam - horizontal strip
	_fill_rect(img, 8, 30, 56, 38, Color(neon.r, neon.g, neon.b, 0.08))
	_fill_rect(img, 8, 30, 56, 31, dim)
	_fill_rect(img, 8, 37, 56, 38, dim)
	# Moving indicator
	_fill_rect(img, 24, 30, 26, 38, Color(neon.r, neon.g, neon.b, 0.25))
	_pset(img, 25, 34, neon)
	# Question mark / search symbol
	_draw_circle(img, 25, 34, 4, dark)
	_pset(img, 25, 34, neon)
	_pset(img, 25, 30, dim)
	_pset(img, 22, 32, dim)
	_pset(img, 28, 32, dim)
	# Antenna
	_fill_rect(img, MID - 1, 10, MID + 1, 30, dark)
	_pset(img, MID, 8, neon)
	_pset(img, MID, 10, dim)

static func _draw_binary(img: Image, dark: Color, neon: Color, dim: Color):
	# Binary search fork / sniper
	_fill_rect(img, 18, 26, 24, 50, dark)
	_fill_rect(img, 40, 26, 46, 50, dark)
	_fill_rect(img, 18, 26, 46, 28, Color(neon.r, neon.g, neon.b, 0.12))
	_fill_rect(img, 24, 26, 40, 27, neon)
	# Scope barrel
	_fill_rect(img, MID - 4, 14, MID + 4, 26, dark)
	_fill_rect(img, MID - 4, 14, MID + 4, 15, neon)
	_fill_rect(img, MID - 4, 14, MID - 3, 26, dim)
	_fill_rect(img, MID + 3, 14, MID + 4, 26, dim)
	# Scope lens
	_draw_circle(img, MID, 14, 6, Color(neon.r, neon.g, neon.b, 0.1))
	_draw_circle(img, MID, 14, 5, dark)
	_pset(img, MID, 14, neon)
	_pset(img, MID - 2, 13, dim)
	# Side markers
	for x in [20, 44]:
		for y in [32, 38, 44]:
			_pset(img, x, y, neon)

static func deg_to_rad(d: float) -> float:
	return d * PI / 180.0
