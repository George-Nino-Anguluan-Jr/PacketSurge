# EnemyInsertionStack.gd
# Insertion Stack — Takes 1.5x DoT damage from Insertion Tower.
# Direct damage is normal.

extends Enemy

func get_type_id() -> String:
	return "insertion_stack"

func _init_type_state() -> void:
	# Vulnerable to Insertion tower (insertion sort inserts past the stack)
	type_data["tower_multipliers"] = {"tower_insertion": 2.0}
	type_data["default_tower_mult"] = 0.6

func _get_dot_scaling_on_apply() -> float:
	return 1.5

func _get_dot_damage_multiplier() -> float:
	return 1.5

func _draw_type_body(col: Color, bob: float) -> void:
	# 3D triangular wedge pointing right (insertion direction)
	var top_pts = PackedVector2Array([
		Vector2(13, 0),
		Vector2(-9, -11 * SQUASH),
		Vector2(-9, 11 * SQUASH)
	])
	draw_set_transform(Vector2(0, bob - 2), 0.0, Vector2.ONE)
	for i in range(3):
		var next_i = (i + 1) % 3
		var t1 = top_pts[i]
		var t2 = top_pts[next_i]
		var b1 = t1 + Vector2(0, 7)
		var b2 = t2 + Vector2(0, 7)
		var panel = PackedVector2Array([t1, t2, b2, b1])
		draw_colored_polygon(panel, Color("#0D141C"))
		draw_colored_polygon(panel, Color(col, 0.3))
		draw_polyline(PackedVector2Array([t1, t2, b2, b1]), col, 1.5)
	draw_colored_polygon(top_pts, Color("#1E2C3D"))
	var outline_loop = top_pts.duplicate()
	outline_loop.append(top_pts[0])
	draw_polyline(outline_loop, col, 1.5)
	# Insertion arrow indicator on top
	draw_line(Vector2(-7, -3 * SQUASH), Vector2(2, -3 * SQUASH), Color("#FFFFFF", 0.8), 1.5)
	draw_line(Vector2(2, -3 * SQUASH), Vector2(-1, -6 * SQUASH), Color("#FFFFFF", 0.8), 1.5)
	draw_line(Vector2(2, -3 * SQUASH), Vector2(-1, 0), Color("#FFFFFF", 0.8), 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Drop shadow
	var s = ensure_style()
	draw_set_transform(Vector2(0, bob + 6), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 12, Color(0, 0, 0, s.shadow_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
