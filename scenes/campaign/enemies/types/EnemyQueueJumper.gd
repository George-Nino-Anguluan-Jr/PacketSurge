# EnemyQueueJumper.gd
# Queue Jumper — Speed scales with enemies ahead on the path.
# More enemies ahead = slower; fewer ahead = faster (up to 1.5x base).

extends Enemy

func get_type_id() -> String:
	return "queue_jumper"

func _init_type_state() -> void:
	type_data["base_speed"] = move_speed

func _process_type_logic(delta: float) -> void:
	var ahead_count = _count_enemies_ahead()
	var speed_scale = 0.5 + (1.0 - float(ahead_count) / 10.0) * 1.0
	move_speed = type_data["base_speed"] * clamp(speed_scale, 0.5, 1.5)

func _draw_type_body(col: Color, bob: float) -> void:
	var ahead = _count_enemies_ahead()
	var scale = 0.85 + (1.0 - float(ahead) / 10.0) * 0.3
	var w = 12.0 * scale
	var h = 8.0 * scale
	# Body: 3D extruded arrow shape
	_draw_3d_box(Vector2(0, bob - 1), Vector2(w, h), 7.0, Color("#15202E"), col, 1.5)
	# Tip cone
	_draw_3d_hexagon(Vector2(w + 4, bob), 6.0, 5.0, Color("#15202E"), col, 1.3)
	# Speed lines
	var trail_count = max(1, 5 - int(ahead / 2))
	for i in range(trail_count):
		var tx = -w * 0.9 - 6 - i * 4
		draw_line(Vector2(tx, bob - 3), Vector2(tx - 4, bob), Color(col, 0.5 - i * 0.07), 1.5)
		draw_line(Vector2(tx - 4, bob), Vector2(tx, bob + 3), Color(col, 0.5 - i * 0.07), 1.5)
	# Drop shadow
	var s = ensure_style()
	draw_set_transform(Vector2(0, bob + 8), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 14, Color(0, 0, 0, s.shadow_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_type_overlay(bob: float) -> void:
	var ahead = _count_enemies_ahead()
	draw_string(ThemeDB.fallback_font, Vector2(-6, 14 + bob), "#" + str(ahead),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#FFFFFF", 0.7))
