# EnemyBinaryMask.gd
# Binary Mask — Only vulnerable side takes full damage; 80% resistance on
# wrong side. Sides switch every 2-3 seconds with a 50/50 chance check.

extends Enemy

func get_type_id() -> String:
	return "binary_mask"

func _init_type_state() -> void:
	type_data["binary_side"] = false  # false=left vulnerable, true=right
	type_data["switch_timer"] = 2.0

func _modify_damage(amount: float) -> float:
	# Binary search concept: 50/50 chance of hitting vulnerable side
	var hit_correct = randi() % 2 == 0
	if type_data["binary_side"]:
		hit_correct = not hit_correct
	if not hit_correct:
		return amount * 0.2
	return amount

func _process_type_logic(delta: float) -> void:
	type_data["switch_timer"] -= delta
	if type_data["switch_timer"] <= 0:
		type_data["binary_side"] = not type_data["binary_side"]
		type_data["switch_timer"] = 2.0 + randf() * 1.0

func _draw_type_body(col: Color, bob: float) -> void:
	var side = type_data.get("binary_side", false)
	var v_col = Color("#00FF88") if side else Color("#FF3366")
	var nv_col = Color("#FF3366", 0.4) if side else Color("#00FF88", 0.4)
	# Left half
	_draw_3d_box(Vector2(-7, bob - 2), Vector2(6, 12), 7.0, Color("#15202E"), v_col if not side else nv_col, 1.5)
	# Right half
	_draw_3d_box(Vector2(7, bob - 2), Vector2(6, 12), 7.0, Color("#15202E"), v_col if side else nv_col, 1.5)
	# Gap line
	draw_line(Vector2(0, bob - 14), Vector2(0, bob + 5), Color("#FFFFFF", 0.6), 1.5)
	# Top marker
	draw_line(Vector2(0, bob - 16), Vector2(0, bob - 12), v_col, 2.0)
	draw_circle(Vector2(0, bob - 17), 2.0, v_col)
	# Drop shadow
	var s = ensure_style()
	draw_set_transform(Vector2(0, bob + 5), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 14, Color(0, 0, 0, s.shadow_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_status_effects(col: Color, bob: float) -> void:
	var side = type_data.get("binary_side", false)
	# Draw half-highlight to indicate vulnerable side
	if side:
		draw_rect(Rect2(0, -14 + bob, 14, 28), Color("#FFFFFF", 0.15))
	else:
		draw_rect(Rect2(-14, -14 + bob, 14, 28), Color("#FFFFFF", 0.15))
	# Divider line
	draw_line(Vector2(0, -14 + bob), Vector2(0, 14 + bob), Color("#FFFFFF", 0.4), 1.0)
