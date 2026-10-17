# EnemyOverflowPacket.gd
# Overflow Packet — 30% damage resistance. Gains HP layers when enemies
# behind it die (LIFO concept). Grows stacked cubes as layers accumulate.
# Bespoke Procedural Design: "The Glitching Monolith"
# A heavy cyber-monolith that accumulates corrupted memory blocks stacked vertically
# with chromatic glitch scanlines and dripping digital distortion as layers overflow.

extends Enemy

func get_type_id() -> String:
	return "overflow_packet"

func _init_type_state() -> void:
	type_data["layers"] = 0
	type_data["base_max_hp"] = max_health

func _modify_damage(amount: float) -> float:
	return amount * 0.7

func _draw_custom_enemy(col: Color, bob: float) -> void:
	var layers = int(type_data.get("layers", 0))
	var center = Vector2(0, bob - 2)

	# 1. Ground Drop Shadow (Scales with stack height)
	var shadow_r = 16.0 + min(layers, 4) * 2.0
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, bob + 10), shadow_r, 8.0, 0.4)

	# 2. Base Tank Chassis Block
	CyberVectorCanvas.draw_iso_prism(
		self,
		center,
		Vector2(14.0, 14.0),
		8.0,
		Color("#172230"),
		Color("#0B111A"),
		Color(col, 0.7),
		1.5
	)

	# 3. Stacked Memory Layers (LIFO Stack)
	var max_visual_layers = min(layers, 4)
	for i in range(max_visual_layers):
		var y_off = center.y - 8.0 - (i + 1) * 7.5
		# Subtle wobble tilt per layer
		var tilt = sin(_bob_time * 4.0 + i) * 1.5
		var layer_center = Vector2(tilt, y_off)

		var layer_col = Color(col).lerp(Color("#FFB800"), float(i + 1) / 4.0)
		var half_w = 12.0 - i * 1.2

		CyberVectorCanvas.draw_iso_prism(
			self,
			layer_center,
			Vector2(half_w, half_w),
			6.5,
			Color("#1E2C3D"),
			Color("#0E1621"),
			Color(layer_col, 0.8),
			1.2
		)

		# Memory register pins on side
		draw_circle(layer_center + Vector2(-half_w + 2, -2), 1.2, layer_col)
		draw_circle(layer_center + Vector2(half_w - 2, -2), 1.2, layer_col)

	# 4. Overflow Glitch Scanlines & Jitter
	if layers > 0:
		var top_y = center.y - 8.0 - max_visual_layers * 7.5 - 6.5
		# Corruption spike at crown
		draw_line(Vector2(0, top_y), Vector2(0, top_y - 8.0), Color("#FFB800"), 2.0)
		draw_circle(Vector2(0, top_y - 9.0), 2.2, Color("#FF3366"))
		draw_circle(Vector2(0, top_y - 9.0), 1.0, Color.WHITE)

		# Horizontal chromatic glitch artifacts
		var glitch_phase = sin(_bob_time * 16.0)
		if abs(glitch_phase) > 0.6:
			var gy = center.y - randf_range(0.0, 25.0)
			var gx = randf_range(-12.0, 12.0)
			draw_line(Vector2(gx - 6, gy), Vector2(gx + 6, gy), Color("#00FF88", 0.7), 1.5)
			draw_line(Vector2(gx - 4, gy + 1), Vector2(gx + 8, gy + 1), Color("#FF0055", 0.7), 1.2)
