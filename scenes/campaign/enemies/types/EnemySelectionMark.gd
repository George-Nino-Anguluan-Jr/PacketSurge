# EnemySelectionMark.gd
# Selection Mark — 75% resistance unless it's the lowest-HP enemy in range.
# Targets are vulnerable only when marked as lowest HP.

extends Enemy

func get_type_id() -> String:
	return "selection_mark"

func _init_type_state() -> void:
	type_data["marked"] = false
	# Vulnerable to Selection tower (selection sort picks the minimum/marked)
	type_data["tower_multipliers"] = {"tower_selection": 2.0}
	type_data["default_tower_mult"] = 0.6

func _modify_damage(amount: float) -> float:
	if not type_data["marked"]:
		return amount * 0.25
	return amount

func _process_type_logic(delta: float) -> void:
	type_data["marked"] = _is_lowest_hp_enemy()

func _draw_type_body(col: Color, bob: float) -> void:
	var marked = type_data.get("marked", false)
	var outline_col = Color("#FFD700") if marked else col
	# Build octagonal top points
	var top_pts = PackedVector2Array()
	for i in range(8):
		var a = i * TAU / 8.0
		top_pts.append(Vector2(cos(a) * 12, sin(a) * 12 * SQUASH))
	draw_set_transform(Vector2(0, bob - 3), 0.0, Vector2.ONE)
	for i in range(8):
		var next_i = (i + 1) % 8
		var t1 = top_pts[i]
		var t2 = top_pts[next_i]
		var b1 = t1 + Vector2(0, 6)
		var b2 = t2 + Vector2(0, 6)
		draw_colored_polygon([t1, t2, b2, b1], Color("#0D141C"))
		draw_polyline(PackedVector2Array([t1, t2]), outline_col, 1.5)
		draw_polyline(PackedVector2Array([b1, b2]), outline_col, 1.5)
	draw_colored_polygon(top_pts, Color("#1E2C3D"))
	draw_polyline(PackedVector2Array([top_pts[0], top_pts[1], top_pts[2], top_pts[3],
		top_pts[4], top_pts[5], top_pts[6], top_pts[7], top_pts[0]]), outline_col, 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Crosshair target on top
	draw_line(Vector2(-5, 0), Vector2(5, 0), outline_col, 1.0)
	draw_line(Vector2(0, -5), Vector2(0, 5), outline_col, 1.0)
	draw_circle(Vector2.ZERO, 2.0, outline_col)
	# Drop shadow
	var s = ensure_style()
	draw_set_transform(Vector2(0, bob + 8), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 18, Color(0, 0, 0, s.shadow_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
