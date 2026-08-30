# EnemyOverflowPacket.gd
# Overflow Packet — 30% damage resistance. Gains HP layers when enemies
# behind it die (LIFO concept). Grows stacked cubes as layers accumulate.

extends Enemy

func get_type_id() -> String:
	return "overflow_packet"

func _init_type_state() -> void:
	type_data["layers"] = 0
	type_data["base_max_hp"] = max_health

func _modify_damage(amount: float) -> float:
	return amount * 0.7

func _draw_type_body(col: Color, bob: float) -> void:
	var layers = type_data.get("layers", 0)
	var stack_height = min(layers, 4) * 4.0
	# Bottom base layer
	_draw_3d_box(Vector2(0, bob - 2), Vector2(13, 13), 7.0, Color("#15202E"), col, 1.5)
	# Stacked layers above
	for i in range(min(layers, 4)):
		var y_offset = bob - 10 - i * 8.0
		var layer_col = Color(col).lerp(Color("#FFB800"), float(i) / 4.0)
		_draw_3d_box(Vector2(0, y_offset), Vector2(10 - i * 0.8, 10 - i * 0.8), 6.0,
			Color("#15202E"), layer_col, 1.3)
	# Top crown spike
	if layers > 0:
		var top_y = bob - 10 - stack_height
		draw_line(Vector2(0, top_y - 8 * SQUASH), Vector2(0, top_y - 18), Color("#FFB800"), 2.0)
	# Drop shadow
	var s = ensure_style()
	draw_set_transform(Vector2(0, bob + 8), 0.0, s.shadow_scale)
	draw_circle(Vector2.ZERO, 22, Color(0, 0, 0, s.shadow_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
