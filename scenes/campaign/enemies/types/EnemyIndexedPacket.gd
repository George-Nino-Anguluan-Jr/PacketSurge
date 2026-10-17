# EnemyIndexedPacket.gd
# Indexed Packet — 50% damage reduction always. Has an index number tile.
# Bespoke Procedural Design: "The Register Vault"
# A heavy armored memory cassette partitioned into 5 discrete index slots [0]..[4]
# with an active illuminated bracket cursor highlighting its stored index.

extends Enemy

func get_type_id() -> String:
	return "indexed_packet"

func _init_type_state() -> void:
	type_data["index"] = randi() % 5

func _modify_damage(amount: float) -> float:
	return amount * 0.5

func _draw_custom_enemy(col: Color, bob: float) -> void:
	var center = Vector2(0, bob - 2)
	var active_idx = int(type_data.get("index", 0))

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, bob + 10), 16.0, 8.0, 0.35)

	# 2. Main Cassette Chassis (Elongated 3D Prism)
	CyberVectorCanvas.draw_iso_prism(
		self,
		center,
		Vector2(14.0, 11.0),
		8.0,
		Color("#172435"),
		Color("#0B121C"),
		Color(col, 0.5),
		1.5
	)

	# 3. 5 Partitioned Memory Slot Partitions [0]..[4]
	var top_c = center + Vector2(0, -8.0)
	var slot_w = 4.5
	for i in range(5):
		var slot_x = -9.0 + i * slot_w
		var is_active = (i == active_idx)
		var slot_color = col if is_active else Color("#223348")

		# Slot cell plate
		var cell_rect = Rect2(slot_x - 1.8, top_c.y - 2.5, 3.6, 5.0)
		draw_rect(cell_rect, Color("#0D1520"))
		draw_rect(cell_rect, slot_color, false, 1.2 if is_active else 0.8)

		if is_active:
			# Active glowing memory core in the selected slot
			draw_circle(Vector2(slot_x, top_c.y), 1.8, Color(col, 0.4))
			draw_circle(Vector2(slot_x, top_c.y), 1.0, Color.WHITE)

	# 4. Bracket Cursor Framing the Active Index
	var active_x = -9.0 + active_idx * slot_w
	var bracket_pulse = 0.8 + 0.2 * sin(_bob_time * 5.0)
	var b_col = Color(col, bracket_pulse)
	# Upper bracket corners
	draw_line(Vector2(active_x - 3.2, top_c.y - 4.5), Vector2(active_x - 3.2, top_c.y - 2.0), b_col, 1.5)
	draw_line(Vector2(active_x - 3.2, top_c.y - 4.5), Vector2(active_x - 1.5, top_c.y - 4.5), b_col, 1.5)
	draw_line(Vector2(active_x + 3.2, top_c.y - 4.5), Vector2(active_x + 3.2, top_c.y - 2.0), b_col, 1.5)
	draw_line(Vector2(active_x + 3.2, top_c.y - 4.5), Vector2(active_x + 1.5, top_c.y - 4.5), b_col, 1.5)

	# 5. Top Address Flag: [i]
	var flag_pos = top_c + Vector2(0, -7.0)
	draw_string(
		ThemeDB.fallback_font,
		flag_pos + Vector2(-6.0, 2.0),
		"[" + str(active_idx) + "]",
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		8,
		Color.WHITE
	)
