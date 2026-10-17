# CyberVectorCanvas.gd
# Procedural cybernetic vector drawing engine for PacketSurge.
# Provides high-performance 2D/pseudo-3D vector drawing primitives for towers,
# enemies, projectiles, and holographic visual effects without external sprites.
class_name CyberVectorCanvas
extends RefCounted

const DEFAULT_SQUASH: float = 0.65

# ─── PSEUDO-3D ISOMETRIC GEOMETRY ──────────────────────────────────────────

## Draws an isometric 3D extruded rectangular prism / box.
static func draw_iso_prism(
		canvas: CanvasItem,
		center: Vector2,
		half_extents: Vector2,
		height: float,
		top_color: Color,
		side_dark_color: Color,
		outline_color: Color = Color.TRANSPARENT,
		outline_width: float = 1.0,
		squash: float = DEFAULT_SQUASH) -> void:

	var hx = half_extents.x
	var hy = half_extents.y * squash
	var top_y = -height

	# Base vertices (bottom)
	var b_left   = center + Vector2(-hx, 0)
	var b_right  = center + Vector2(hx, 0)
	var b_front  = center + Vector2(0, hy)
	var b_back   = center + Vector2(0, -hy)

	# Top vertices
	var t_left   = b_left  + Vector2(0, top_y)
	var t_right  = b_right + Vector2(0, top_y)
	var t_front  = b_front + Vector2(0, top_y)
	var t_back   = b_back  + Vector2(0, top_y)

	if height > 0.5:
		# Left side face
		var left_side = PackedVector2Array([b_left, b_front, t_front, t_left])
		var left_color = side_dark_color.darkened(0.15)
		canvas.draw_colored_polygon(left_side, left_color)

		# Right side face
		var right_side = PackedVector2Array([b_right, b_front, t_front, t_right])
		var right_color = side_dark_color.lightened(0.08)
		canvas.draw_colored_polygon(right_side, right_color)

		# Side outlines
		if outline_color.a > 0.0:
			canvas.draw_line(b_left, t_left, outline_color, outline_width)
			canvas.draw_line(b_front, t_front, outline_color, outline_width)
			canvas.draw_line(b_right, t_right, outline_color, outline_width)
			canvas.draw_line(b_left, b_front, outline_color, outline_width)
			canvas.draw_line(b_front, b_right, outline_color, outline_width)

	# Top face
	var top_poly = PackedVector2Array([t_back, t_right, t_front, t_left])
	canvas.draw_colored_polygon(top_poly, top_color)

	if outline_color.a > 0.0:
		for i in range(4):
			canvas.draw_line(top_poly[i], top_poly[(i + 1) % 4], outline_color, outline_width)


## Draws an isometric 3D extruded cylinder / circular drum.
static func draw_iso_cylinder(
		canvas: CanvasItem,
		center: Vector2,
		radius: float,
		height: float,
		top_color: Color,
		side_dark_color: Color,
		outline_color: Color = Color.TRANSPARENT,
		outline_width: float = 1.0,
		segments: int = 24,
		squash: float = DEFAULT_SQUASH) -> void:

	var step = TAU / segments
	var top_pts = PackedVector2Array()
	var bot_pts = PackedVector2Array()

	for i in range(segments):
		var a = i * step
		var px = cos(a) * radius
		var py = sin(a) * radius * squash
		bot_pts.append(center + Vector2(px, py))
		top_pts.append(center + Vector2(px, py - height))

	# Front side skirt
	if height > 0.5:
		for i in range(segments):
			var a = i * step
			# Only draw front-facing segments
			if sin(a) >= -0.2:
				var next_i = (i + 1) % segments
				var quad = PackedVector2Array([
					bot_pts[i],
					bot_pts[next_i],
					top_pts[next_i],
					top_pts[i]
				])
				# Shading gradient along the curve
				var shade = 0.5 + 0.5 * cos(a)
				var seg_color = side_dark_color.lerp(top_color.darkened(0.4), shade * 0.4)
				canvas.draw_colored_polygon(quad, seg_color)

		if outline_color.a > 0.0:
			var left_idx = int(segments * 0.5)
			var right_idx = 0
			canvas.draw_line(bot_pts[left_idx], top_pts[left_idx], outline_color, outline_width)
			canvas.draw_line(bot_pts[right_idx], top_pts[right_idx], outline_color, outline_width)

	# Top face
	canvas.draw_colored_polygon(top_pts, top_color)
	if outline_color.a > 0.0:
		for i in range(segments):
			canvas.draw_line(top_pts[i], top_pts[(i + 1) % segments], outline_color, outline_width)


## Draws an isometric 3D extruded hexagon.
static func draw_iso_hexagon(
		canvas: CanvasItem,
		center: Vector2,
		radius: float,
		height: float,
		top_color: Color,
		side_dark_color: Color,
		outline_color: Color = Color.TRANSPARENT,
		outline_width: float = 1.0,
		squash: float = DEFAULT_SQUASH) -> void:

	var top_pts = PackedVector2Array()
	var bot_pts = PackedVector2Array()

	for i in range(6):
		var a = i * TAU / 6.0
		var px = cos(a) * radius
		var py = sin(a) * radius * squash
		bot_pts.append(center + Vector2(px, py))
		top_pts.append(center + Vector2(px, py - height))

	if height > 0.5:
		# Draw front-facing sides (indices 0, 1, 2)
		for i in [5, 0, 1, 2]:
			var next_i = (i + 1) % 6
			var quad = PackedVector2Array([
				bot_pts[i],
				bot_pts[next_i],
				top_pts[next_i],
				top_pts[i]
			])
			var shade = side_dark_color
			if i == 0: shade = side_dark_color.lightened(0.12)
			elif i == 1: shade = side_dark_color
			elif i == 2: shade = side_dark_color.darkened(0.12)
			elif i == 5: shade = side_dark_color.lightened(0.05)
			canvas.draw_colored_polygon(quad, shade)

			if outline_color.a > 0.0:
				canvas.draw_line(bot_pts[i], bot_pts[next_i], outline_color, outline_width)
				canvas.draw_line(bot_pts[i], top_pts[i], outline_color, outline_width)

	canvas.draw_colored_polygon(top_pts, top_color)
	if outline_color.a > 0.0:
		for i in range(6):
			canvas.draw_line(top_pts[i], top_pts[(i + 1) % 6], outline_color, outline_width)


## Draws a chamfered platform / motherboard base with clipped 45-degree corners.
static func draw_iso_chamfered_slab(
		canvas: CanvasItem,
		center: Vector2,
		half_extents: Vector2,
		chamfer: float,
		height: float,
		top_color: Color,
		side_dark_color: Color,
		outline_color: Color = Color.TRANSPARENT,
		outline_width: float = 1.0,
		squash: float = DEFAULT_SQUASH) -> void:

	var w = half_extents.x
	var h = half_extents.y
	var c = chamfer

	# 8 vertices of chamfered rectangle (clockwise from top-left chamfer)
	var local_pts = [
		Vector2(-w + c, -h),
		Vector2(w - c, -h),
		Vector2(w, -h + c),
		Vector2(w, h - c),
		Vector2(w - c, h),
		Vector2(-w + c, h),
		Vector2(-w, h - c),
		Vector2(-w, -h + c),
	]

	var bot_pts = PackedVector2Array()
	var top_pts = PackedVector2Array()

	for pt in local_pts:
		var bx = center.x + pt.x
		var by = center.y + pt.y * squash
		bot_pts.append(Vector2(bx, by))
		top_pts.append(Vector2(bx, by - height))

	if height > 0.5:
		for i in range(2, 6):
			var next_i = (i + 1) % 8
			var quad = PackedVector2Array([
				bot_pts[i],
				bot_pts[next_i],
				top_pts[next_i],
				top_pts[i]
			])
			var seg_col = side_dark_color
			if i == 2: seg_col = side_dark_color.lightened(0.12)
			elif i == 3: seg_col = side_dark_color.lightened(0.06)
			elif i == 4: seg_col = side_dark_color
			elif i == 5: seg_col = side_dark_color.darkened(0.12)
			canvas.draw_colored_polygon(quad, seg_col)

			if outline_color.a > 0.0:
				canvas.draw_line(bot_pts[i], top_pts[i], outline_color, outline_width)
				canvas.draw_line(bot_pts[i], bot_pts[next_i], outline_color, outline_width)

	canvas.draw_colored_polygon(top_pts, top_color)
	if outline_color.a > 0.0:
		for i in range(8):
			canvas.draw_line(top_pts[i], top_pts[(i + 1) % 8], outline_color, outline_width)


# ─── MECHANICAL & CYBERNETIC SUB-ELEMENTS ──────────────────────────────────

## Draws a vertical heatsink / register silo block (for Array / Radix / Stack).
static func draw_register_silo(
		canvas: CanvasItem,
		center: Vector2,
		width: float,
		height: float,
		extrude: float,
		active: bool,
		accent_color: Color,
		label: String = "") -> void:

	var base_col = Color("#0D1A2E") if not active else Color("#152C4A")
	var top_col  = Color("#152238") if not active else accent_color.darkened(0.35)
	var glow_col = Color(accent_color, 0.25) if not active else accent_color

	draw_iso_prism(canvas, center, Vector2(width * 0.5, width * 0.5), extrude, top_col, base_col, glow_col, 1.0)

	# Top face active diode / pin
	var top_pos = center + Vector2(0, -extrude)
	if active:
		canvas.draw_circle(top_pos, width * 0.25, Color.WHITE)
		canvas.draw_circle(top_pos, width * 0.45, Color(accent_color, 0.4))
	else:
		canvas.draw_circle(top_pos, width * 0.18, Color(accent_color, 0.35))

	if label != "":
		canvas.draw_string(
			ThemeDB.fallback_font,
			top_pos + Vector2(-width * 0.3, 3.5),
			label,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			8,
			Color.WHITE if active else Color(accent_color, 0.5)
		)


## Draws circular electromagnetic induction coils around a central axis (for Queue / Linear).
static func draw_induction_coil(
		canvas: CanvasItem,
		center: Vector2,
		radius: float,
		color: Color,
		energy_alpha: float = 0.8,
		width: float = 2.0,
		squash: float = DEFAULT_SQUASH) -> void:

	# Outer halo
	if energy_alpha > 0.3:
		canvas.draw_arc(center, radius + 2.0, 0, TAU, 24, Color(color, energy_alpha * 0.3), width + 2.0)
	# Main coil arc
	canvas.draw_arc(center, radius, 0, TAU, 24, Color(color, energy_alpha), width)
	# Coil core wire
	canvas.draw_arc(center, radius, 0, TAU, 24, Color(Color.WHITE, energy_alpha * 0.8), width * 0.5)


## Draws an articulated rotating gimbal / orbital ring (for Bubble / Linked).
static func draw_orbital_ring(
		canvas: CanvasItem,
		center: Vector2,
		radius_x: float,
		radius_y: float,
		rotation_rad: float,
		color: Color,
		width: float = 1.5) -> void:

	var pts = PackedVector2Array()
	var segs = 32
	var cos_r = cos(rotation_rad)
	var sin_r = sin(rotation_rad)

	for i in range(segs):
		var a = i * TAU / segs
		var lx = cos(a) * radius_x
		var ly = sin(a) * radius_y
		var rx = lx * cos_r - ly * sin_r
		var ry = lx * sin_r + ly * cos_r
		pts.append(center + Vector2(rx, ry))

	for i in range(segs):
		canvas.draw_line(pts[i], pts[(i + 1) % segs], color, width)


## Draws a high-tech glowing circuit trace with circular node vias.
static func draw_circuit_traces(
		canvas: CanvasItem,
		pts: PackedVector2Array,
		color: Color,
		width: float = 1.0,
		via_radius: float = 1.5) -> void:

	for i in range(pts.size() - 1):
		canvas.draw_line(pts[i], pts[i + 1], color, width)
		canvas.draw_circle(pts[i], via_radius, color)
	if pts.size() > 0:
		canvas.draw_circle(pts[-1], via_radius, color)


## Draws a ground drop-shadow ellipse.
static func draw_drop_shadow(
		canvas: CanvasItem,
		center: Vector2,
		radius_x: float,
		radius_y: float,
		alpha: float = 0.3) -> void:

	var segs = 20
	var pts = PackedVector2Array()
	for i in range(segs):
		var a = i * TAU / segs
		pts.append(center + Vector2(cos(a) * radius_x, sin(a) * radius_y))
	canvas.draw_colored_polygon(pts, Color(0, 0, 0, alpha))


## Draws a plasma arc with lightning jitter.
static func draw_plasma_arc(
		canvas: CanvasItem,
		from_pt: Vector2,
		to_pt: Vector2,
		color: Color,
		jitter: float = 3.0,
		segments: int = 5,
		width: float = 1.5) -> void:

	var dir = to_pt - from_pt
	var total_len = dir.length()
	if total_len < 1.0:
		return

	var perp = Vector2(-dir.y, dir.x).normalized()
	var prev = from_pt

	for i in range(1, segments):
		var t = float(i) / float(segments)
		var offset = (sin(t * PI * 2.0 + Time.get_ticks_msec() * 0.02) + randf_range(-0.5, 0.5)) * jitter
		var cur = from_pt + dir * t + perp * offset
		canvas.draw_line(prev, cur, color, width)
		canvas.draw_line(prev, cur, Color(Color.WHITE, 0.7), width * 0.5)
		prev = cur

	canvas.draw_line(prev, to_pt, color, width)
	canvas.draw_line(prev, to_pt, Color(Color.WHITE, 0.7), width * 0.5)
