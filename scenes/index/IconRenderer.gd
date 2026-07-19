extends Node2D

var draw_color: Color = Color.WHITE
var enemy_type: String = "basic_packet"
const SQUASH: float = 0.65

func _draw() -> void:
	_draw_icon()

func _draw_icon() -> void:
	match enemy_type:
		"basic_packet":
			_draw_3d_box_icon(Vector2(0, -4), Vector2(13, 13), 8.0, draw_color)
		"indexed_packet":
			_draw_3d_box_icon(Vector2(0, -4), Vector2(13, 13), 8.0, draw_color)
		"overflow_packet":
			_draw_overflow_icon(draw_color)
		"queue_jumper":
			_draw_queue_jumper_icon(draw_color)
		"linked_drain":
			_draw_3d_hexagon_icon(Vector2(0, -2), 12.0, 7.0, draw_color)
		"bubble_shield":
			_draw_3d_sphere_icon(Vector2(0, -2), 11.0, draw_color)
		"pivot_splitter":
			_draw_3d_box_icon(Vector2(0, -4), Vector2(20, 12), 12.0, draw_color)
		"selection_mark":
			_draw_selection_icon(draw_color)
		"insertion_stack":
			_draw_insertion_icon(draw_color)
		"merge_twin":
			_draw_merge_icon(draw_color)
		"count_meter":
			_draw_count_icon(draw_color)
		"radix_digit":
			_draw_radix_icon(draw_color)
		"scan_wave":
			_draw_scan_icon(draw_color)
		"binary_mask":
			_draw_binary_icon(draw_color)
		_:
			_draw_3d_box_icon(Vector2(0, -4), Vector2(13, 13), 8.0, draw_color)

func _draw_3d_box_icon(center: Vector2, extents: Vector2, height: float, color: Color, outline_color: Color = Color.WHITE) -> void:
	var t_tl = center + Vector2(-extents.x, -extents.y * SQUASH)
	var t_tr = center + Vector2(extents.x, -extents.y * SQUASH)
	var t_br = center + Vector2(extents.x, extents.y * SQUASH)
	var t_bl = center + Vector2(-extents.x, extents.y * SQUASH)
	var b_tl = t_tl + Vector2(0, height)
	var b_tr = t_tr + Vector2(0, height)
	var b_br = t_br + Vector2(0, height)
	var b_bl = t_bl + Vector2(0, height)
	
	var r_panel = PackedVector2Array([t_tr, b_br, b_br, t_tr])
	draw_colored_polygon(r_panel, Color("#0D141C"))
	draw_polyline(PackedVector2Array([t_tr, b_br, b_br, t_tr]), color, 1.0)
	
	var f_panel = PackedVector2Array([t_bl, b_br, b_br, t_bl])
	draw_colored_polygon(f_panel, Color("#141D29"))
	draw_colored_polygon(f_panel, Color(color, 0.15))
	draw_polyline(PackedVector2Array([t_bl, b_br, b_br, t_bl]), color, 1.0)
	
	var l_panel = PackedVector2Array([t_tl, b_bl, b_bl, t_tl])
	draw_colored_polygon(l_panel, Color("#101720"))
	draw_polyline(PackedVector2Array([t_tl, b_bl, b_bl, t_tl]), Color(color, 0.4), 1.0)
	
	var top_face = PackedVector2Array([t_tl, t_tr, b_tr, b_tl])
	draw_colored_polygon(top_face, Color("#1E2C3D"))
	draw_polyline(PackedVector2Array([t_tl, t_tr, b_tr, b_tl, t_tl]), color, 1.0)

func _draw_3d_cylinder_icon(center: Vector2, radius: float, height: float, color: Color) -> void:
	var left_x = center.x - radius
	var right_x = center.x + radius
	var wall_rect = Rect2(left_x, center.y, radius * 2.0, height)
	draw_rect(wall_rect, Color("#0F1720"), true)
	draw_rect(Rect2(left_x, center.y, radius, height), Color(color, 0.15), true)
	draw_rect(Rect2(center.x, center.y, radius, height), Color(0, 0, 0, 0.25), true)
	draw_line(center + Vector2(-radius, 0), center + Vector2(-radius, height), color, 1.0)
	draw_line(center + Vector2(radius, 0), center + Vector2(radius, height), color, 1.0)
	draw_set_transform(center, 0.0, Vector2(1.0, SQUASH))
	draw_circle(Vector2.ZERO, radius, Color("#15202E"))
	draw_circle(Vector2.ZERO, radius, color, false, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_3d_hexagon_icon(center: Vector2, radius: float, height: float, color: Color) -> void:
	var top_pts = PackedVector2Array()
	for i in range(6):
		var angle = i * (PI / 3.0)
		top_pts.append(center + Vector2(cos(angle) * radius, sin(angle) * radius * SQUASH))
	
	for i in range(6):
		var next_i = (i + 1) % 6
		var t1 = top_pts[i]
		var t2 = top_pts[next_i]
		var b1 = t1 + Vector2(0, height)
		var b2 = t2 + Vector2(0, height)
		var mid_angle = i * (PI / 3.0) + (PI / 6.0)
		var l_dot = cos(mid_angle - 2.2)
		var shade_mix = lerp(0.05, 0.5, (l_dot + 1.0) / 2.0)
		var panel = PackedVector2Array([t1, t2, b2, b1])
		draw_colored_polygon(panel, Color("#0D131A"))
		draw_colored_polygon(panel, Color(color, shade_mix * 0.4))
		draw_polyline(PackedVector2Array([t1, t2, b2, b1]), Color(color, 0.4), 1.0)
	
	draw_colored_polygon(top_pts, Color("#1B2A3A"))
	var outline_loop = top_pts
	outline_loop.append(top_pts[0])
	draw_polyline(outline_loop, color, 1.0)

func _draw_3d_sphere_icon(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(center, radius, Color("#0F1721"))
	draw_circle(center, radius, Color(color, 0.25))
	var highlight_c = center - Vector2(radius * 0.25, radius * 0.25)
	draw_circle(highlight_c, radius * 0.6, Color(color, 0.4))
	draw_circle(highlight_c, radius * 0.2, Color.WHITE)

func _draw_overflow_icon(color: Color) -> void:
	_draw_3d_box_icon(Vector2(0, -2), Vector2(13, 13), 7.0, Color("#15202E"))
	for i in range(4):
		var y_offset = -10 - i * 8.0
		var layer_col = Color(color).lerp(Color("#FFB800"), float(i) / 4.0)
		_draw_3d_box_icon(Vector2(0, y_offset), Vector2(10 - i * 0.8, 10 - i * 0.8), 6.0, Color("#15202E"), layer_col)

func _draw_queue_jumper_icon(color: Color) -> void:
	var w = 12.0
	var h = 8.0
	var bob = 0.0
	var t_tl = Vector2(-w * 0.6, bob - h)
	var t_tr = Vector2(w * 0.6, bob - h)
	var t_br = Vector2(w, bob)
	var t_bl = Vector2(-w * 0.6, bob)
	var b_tl = t_tl + Vector2(0, 7)
	var b_tr = t_tr + Vector2(0, 7)
	var b_br = t_br + Vector2(0, 7)
	var b_bl = t_bl + Vector2(0, 7)
	
	var r_panel = PackedVector2Array([t_tr, b_br, b_br, t_tr])
	draw_colored_polygon(r_panel, Color("#0D141C"))
	draw_polyline(PackedVector2Array([t_tr, b_br, b_br, t_tr]), color, 1.0)
	
	var f_panel = PackedVector2Array([t_bl, b_br, b_br, t_bl])
	draw_colored_polygon(f_panel, Color("#141D29"))
	draw_colored_polygon(f_panel, Color(color, 0.15))
	draw_polyline(PackedVector2Array([t_bl, b_br, b_br, t_bl]), color, 1.0)
	
	var l_panel = PackedVector2Array([t_tl, b_bl, b_bl, t_tl])
	draw_colored_polygon(l_panel, Color("#101720"))
	draw_polyline(PackedVector2Array([t_tl, b_bl, b_bl, t_tl]), Color(color, 0.4), 1.0)
	
	var top_face = PackedVector2Array([t_tl, t_tr, b_tr, b_tl])
	draw_colored_polygon(top_face, Color("#1E2C3D"))
	draw_polyline(PackedVector2Array([t_tl, t_tr, b_tr, b_tl, t_tl]), color, 1.0)

func _draw_selection_icon(color: Color) -> void:
	var top_pts = PackedVector2Array()
	for i in range(8):
		var a = i * TAU / 8.0
		top_pts.append(Vector2(cos(a) * 12, sin(a) * 12 * SQUASH))
	
	var center = Vector2(0, -3)
	for i in range(8):
		var next_i = (i + 1) % 8
		var t1 = top_pts[i]
		var t2 = top_pts[next_i]
		var b1 = t1 + Vector2(0, 7)
		var b2 = t2 + Vector2(0, 7)
		var mid_angle = i * TAU / 8.0 + (TAU / 16.0)
		var l_dot = cos(mid_angle - 2.2)
		var shade_mix = lerp(0.1, 0.5, (l_dot + 1.0) / 2.0)
		var panel = PackedVector2Array([t1, t2, b2, b1])
		draw_colored_polygon(panel, Color("#0D131A"))
		draw_colored_polygon(panel, Color(color, shade_mix * 0.4))
		draw_polyline(PackedVector2Array([t1, t2, b2, b1]), Color(color, 0.4), 1.0)
	
	draw_colored_polygon(top_pts, Color("#1B2A3A"))
	var outline_loop = top_pts
	outline_loop.append(top_pts[0])
	draw_polyline(outline_loop, color, 1.5)
	draw_line(Vector2(-6, 0), Vector2(6, 0), color, 1.5)
	draw_line(Vector2(0, -6 * SQUASH), Vector2(0, 6 * SQUASH), color, 1.5)
	draw_circle(Vector2.ZERO, 2.5, color, 0.9)

func _draw_insertion_icon(color: Color) -> void:
	var top_pts = PackedVector2Array([
		Vector2(13, 0),
		Vector2(-9, -11 * SQUASH),
		Vector2(-9, 11 * SQUASH)
	])
	var center = Vector2(0, -2)
	for i in range(3):
		var next_i = (i + 1) % 3
		var t1 = top_pts[i]
		var t2 = top_pts[next_i]
		var b1 = t1 + Vector2(0, 7)
		var b2 = t2 + Vector2(0, 7)
		var panel = PackedVector2Array([t1, t2, b2, b1])
		draw_colored_polygon(panel, Color("#0D141C"))
		draw_colored_polygon(panel, Color(color, 0.3))
		draw_polyline(PackedVector2Array([t1, t2, b2, b1]), color, 1.5)
	
	draw_colored_polygon(top_pts, Color("#1E2C3D"))
	var outline_loop = top_pts
	outline_loop.append(top_pts[0])
	draw_polyline(outline_loop, color, 1.5)
	draw_line(Vector2(-7, -3 * SQUASH), Vector2(2, -3 * SQUASH), Color("#FFFFFF", 0.8), 1.5)
	draw_line(Vector2(2, -3 * SQUASH), Vector2(-1, -6 * SQUASH), Color("#FFFFFF", 0.8), 1.5)
	draw_line(Vector2(2, -3 * SQUASH), Vector2(-1, 0), Color("#FFFFFF", 0.8), 1.5)

func _draw_merge_icon(color: Color) -> void:
	_draw_3d_sphere_icon(Vector2(-8, -2), 7.0, color)
	_draw_3d_sphere_icon(Vector2(8, -2), 7.0, color)
	var center = Vector2(0, -1)
	draw_line(center + Vector2(-3, 0), center + Vector2(3, 0), color, 1.2)
	draw_line(center + Vector2(-3, 0), center + Vector2(3, 0), Color(color, 0.7), 1.2)

func _draw_count_icon(color: Color) -> void:
	_draw_3d_box_icon(Vector2(0, -2), Vector2(11, 11), 6.0, Color("#15202E"))
	var hash_y = -2 - 11 * SQUASH
	draw_line(Vector2(-5, hash_y), Vector2(-5, hash_y - 3), color, 2.0)
	draw_line(Vector2(0, hash_y), Vector2(0, hash_y - 3), color, 2.0)
	draw_line(Vector2(5, hash_y), Vector2(5, hash_y - 3), color, 2.0)
	draw_line(Vector2(-6, hash_y - 1.5), Vector2(6, hash_y - 1.5), color, 2.0)

func _draw_radix_icon(color: Color) -> void:
	for i in range(3):
		var x_off = (i - 1) * 9.0
		_draw_3d_box_icon(Vector2(x_off, -2), Vector2(7, 8), 6.0, color)

func _draw_scan_icon(color: Color) -> void:
	var top_pts = PackedVector2Array()
	for i in range(6):
		var a = i * PI / 3.0
		var rx = 16.0 if i % 2 == 0 else 8.0
		var ry = 7.0
		top_pts.append(Vector2(cos(a) * rx, sin(a) * ry * SQUASH))
	
	var center = Vector2(0, -2)
	for i in range(6):
		var next_i = (i + 1) % 6
		var t1 = top_pts[i]
		var t2 = top_pts[next_i]
		var b1 = t1 + Vector2(0, 5)
		var b2 = t2 + Vector2(0, 5)
		var mid_angle = i * PI / 3.0 + (PI / 6.0)
		var l_dot = cos(mid_angle - 2.2)
		var shade_mix = lerp(0.1, 0.4, (l_dot + 1.0) / 2.0)
		var panel = PackedVector2Array([t1, t2, b2, b1])
		draw_colored_polygon(panel, Color("#0D131A"))
		draw_colored_polygon(panel, Color(color, shade_mix * 0.4))
		draw_polyline(PackedVector2Array([t1, t2, b2, b1]), Color(color, 0.4), 1.0)
	
	draw_colored_polygon(top_pts, Color("#1B2A3A"))
	var outline_loop = top_pts
	outline_loop.append(top_pts[0])
	draw_polyline(outline_loop, color, 1.5)

func _draw_binary_icon(color: Color) -> void:
	var side = false
	var v_col = Color("#00FF88") if side else Color("#FF3366")
	var nv_col = Color("#FF3366", 0.4) if side else Color("#00FF88", 0.4)
	_draw_3d_box_icon(Vector2(-7, -2), Vector2(6, 12), 7.0, v_col if not side else nv_col)
	_draw_3d_box_icon(Vector2(7, -2), Vector2(6, 12), 7.0, v_col if side else nv_col)
	draw_line(Vector2(0, -14), Vector2(0, 5), Color("#FFFFFF", 0.6), 1.5)
	draw_line(Vector2(0, -16), Vector2(0, -12), v_col, 2.0)
	draw_circle(Vector2(0, -17), 2.0, v_col)