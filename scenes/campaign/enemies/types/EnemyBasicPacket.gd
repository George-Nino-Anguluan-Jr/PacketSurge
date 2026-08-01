# EnemyBasicPacket.gd
# Basic Packet — no special abilities. The standard network packet.

extends Enemy

func get_type_id() -> String:
	return "basic_packet"

func _init_type_state() -> void:
	pass

func _draw_type_body(col: Color, bob: float) -> void:
	# 3D data packet cube
	_draw_3d_box(Vector2(0, bob - 4), Vector2(13, 13), 8.0, Color("#15202E"), col, 1.5)
	# Top face circuit lines
	draw_line(Vector2(-7, bob - 4 - 8 * SQUASH + 2), Vector2(7, bob - 4 - 8 * SQUASH + 2), Color(col, 0.6), 1.0)
	draw_circle(Vector2(0, bob - 4 - 8 * SQUASH), 2.0, Color(col, 0.7))
	# Drop shadow
	var s = ensure_style()
	draw_set_transform(Vector2(0, bob + 4), 0.0, s.shadow_scale)
	draw_circle(Vector2.ZERO, 12, Color(0, 0, 0, s.shadow_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
