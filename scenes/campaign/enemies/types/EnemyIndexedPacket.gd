# EnemyIndexedPacket.gd
# Indexed Packet — 50% damage reduction always. Has an index number tile.

extends Enemy

func get_type_id() -> String:
	return "indexed_packet"

func _init_type_state() -> void:
	type_data["index"] = randi() % 5

func _modify_damage(amount: float) -> float:
	return amount * 0.5

func _draw_type_body(col: Color, bob: float) -> void:
	# 3D data packet with bracket frame and number tile on top
	_draw_3d_box(Vector2(0, bob - 2), Vector2(13, 13), 8.0, Color("#15202E"), col, 1.5)
	# Index number tile on top
	var tile_y = bob - 2 - 8 * SQUASH - 4
	_draw_3d_box(Vector2(0, tile_y), Vector2(7, 7), 3.0, Color("#0F1A2E"), Color("#FFFFFF", 0.9), 1.2)
	# Bracket corners
	var corners = [Vector2(-11, -11), Vector2(11, -11), Vector2(-11, 11), Vector2(11, 11)]
	for c in corners:
		draw_line(Vector2(c.x * 0.4, bob - 2 + c.y * 0.4 - 8 * SQUASH),
			Vector2(c.x * 0.4 + c.x * 0.3, bob - 2 + c.y * 0.4 - 8 * SQUASH),
			col, 1.5)
	# Drop shadow
	var s = ensure_style()
	draw_set_transform(Vector2(0, bob + 6), 0.0, s.shadow_scale)
	draw_circle(Vector2.ZERO, 14, Color(0, 0, 0, s.shadow_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_type_overlay(bob: float) -> void:
	var idx = type_data.get("index", 0)
	draw_string(ThemeDB.fallback_font, Vector2(-4, 6 + bob), str(idx),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#FFFFFF"))
