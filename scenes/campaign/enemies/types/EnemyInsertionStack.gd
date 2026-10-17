# EnemyInsertionStack.gd
# Insertion Stack — Takes 1.5x DoT damage from Insertion Tower.
# Direct damage is normal.
# Bespoke Procedural Design: "The Track-Drill Wedge"
# An aggressive snowplow locomotive wedge with serrated front teeth that dig
# into the track, industrial side skirts, and twin rear exhaust stacks that flare with DoT fire.

extends Enemy

func get_type_id() -> String:
	return "insertion_stack"

func _init_type_state() -> void:
	pass

func _get_dot_scaling_on_apply() -> float:
	return 1.5

func _get_dot_damage_multiplier() -> float:
	return 1.5

func _draw_custom_enemy(col: Color, bob: float) -> void:
	var center = Vector2(0, bob - 2)
	var dir = get_travel_direction()
	var angle = dir.angle()

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, bob + 10), 16.0, 8.0, 0.35)

	# 2. Wedge Hull Points (Rotated toward movement direction)
	# Local forward is Vector2(1, 0)
	var forward = dir
	var perp = Vector2(-dir.y, dir.x)

	# Hull vertices
	var prow_tip = center + forward * 14.0
	var left_wing = center - forward * 9.0 + perp * 10.0
	var right_wing = center - forward * 9.0 - perp * 10.0
	var rear_center = center - forward * 8.0

	# 3D Base Thickness (Lower face)
	var extrude_h = Vector2(0, 7.0)
	var base_poly = PackedVector2Array([
		prow_tip + extrude_h,
		left_wing + extrude_h,
		rear_center + extrude_h,
		right_wing + extrude_h
	])
	draw_colored_polygon(base_poly, Color("#0B121C"))

	# Skirt side panels
	var skirt_l = PackedVector2Array([left_wing, left_wing + extrude_h, prow_tip + extrude_h, prow_tip])
	var skirt_r = PackedVector2Array([right_wing, right_wing + extrude_h, prow_tip + extrude_h, prow_tip])
	draw_colored_polygon(skirt_l, Color("#111A26"))
	draw_colored_polygon(skirt_r, Color("#192433"))
	draw_polyline(skirt_l, Color(col, 0.5), 1.2)
	draw_polyline(skirt_r, Color(col, 0.5), 1.2)

	# Top deck polygon
	var top_poly = PackedVector2Array([prow_tip, left_wing, rear_center, right_wing])
	draw_colored_polygon(top_poly, Color("#1E2D3E"))
	top_poly.append(prow_tip)
	draw_polyline(top_poly, col, 1.5)

	# 3. Serrated Front Cowcatcher / Track Teeth
	for i in range(-2, 3):
		var t_pos = prow_tip - forward * 3.0 + perp * (i * 2.5)
		draw_line(t_pos, t_pos + forward * 3.5, Color("#FFD700") if _dot_timer > 0 else Color.WHITE, 1.5)

	# 4. Rear Exhaust Stacks
	var ex_left = rear_center + perp * 5.0
	var ex_right = rear_center - perp * 5.0

	draw_circle(ex_left, 2.5, Color("#0D141F"))
	draw_circle(ex_left, 1.5, Color(col, 0.7))
	draw_circle(ex_right, 2.5, Color("#0D141F"))
	draw_circle(ex_right, 1.5, Color(col, 0.7))

	# 5. DoT Fire Eruption from Exhaust
	if _dot_timer > 0:
		var flame_len = 8.0 + 4.0 * sin(_bob_time * 12.0)
		var flame_col = Color("#00FF88")
		draw_line(ex_left, ex_left - forward * flame_len, flame_col, 2.5)
		draw_line(ex_left, ex_left - forward * (flame_len * 0.6), Color.WHITE, 1.2)
		draw_line(ex_right, ex_right - forward * flame_len, flame_col, 2.5)
		draw_line(ex_right, ex_right - forward * (flame_len * 0.6), Color.WHITE, 1.2)
