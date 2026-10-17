# EnemyQueueJumper.gd
# Queue Jumper — Speed scales with enemies ahead on the path.
# More enemies ahead = slower; fewer ahead = faster (up to 1.5x base).
# Bespoke Procedural Design: "The Afterburner Dart"
# A supersonic variable-geometry dart craft oriented along the path. Deploys forward-swept
# wings and ignites blazing afterburners when the queue ahead clears!

extends Enemy

func get_type_id() -> String:
	return "queue_jumper"

func _init_type_state() -> void:
	type_data["base_speed"] = move_speed

func _process_type_logic(delta: float) -> void:
	var ahead_count = _count_enemies_ahead()
	var speed_scale = 0.5 + (1.0 - float(ahead_count) / 10.0) * 1.0
	move_speed = type_data["base_speed"] * clamp(speed_scale, 0.5, 1.5)

func _draw_custom_enemy(col: Color, bob: float) -> void:
	var center = Vector2(0, bob - 2)
	var ahead = _count_enemies_ahead()
	var dir = get_travel_direction()
	var forward = dir
	var perp = Vector2(-dir.y, dir.x)

	# Queue speed factor: 1.0 = clear, 0.0 = clogged
	var sprint_factor = clamp(1.0 - float(ahead) / 6.0, 0.0, 1.0)

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, bob + 10), 16.0, 7.0, 0.35)

	# 2. Variable Geometry Wings
	# Sprinting: wings flare out wide; Clogged: wings tucked against body
	var wing_sweep = lerp(4.0, 12.0, sprint_factor)
	var wing_back = lerp(8.0, 4.0, sprint_factor)

	var nose = center + forward * 14.0
	var tail = center - forward * 9.0
	var wing_l = center - forward * wing_back + perp * wing_sweep
	var wing_r = center - forward * wing_back - perp * wing_sweep

	# Wing poly (delta wing chassis)
	var wing_poly = PackedVector2Array([nose, wing_l, tail, wing_r])
	draw_colored_polygon(wing_poly, Color("#152233"))
	wing_poly.append(nose)
	draw_polyline(wing_poly, Color(col, 0.7), 1.2)

	# Fuselage centerline spine
	CyberVectorCanvas.draw_iso_prism(
		self,
		center,
		Vector2(4.0, 8.0),
		6.0,
		Color("#1F344D"),
		Color("#0C1521"),
		col,
		1.5
	)

	# Cockpit canopy diode
	var canopy_pos = center + forward * 4.0 - Vector2(0, 6.0)
	draw_circle(canopy_pos, 2.0, Color("#00FF88") if sprint_factor > 0.5 else Color("#00D4FF"))
	draw_circle(canopy_pos, 1.0, Color.WHITE)

	# 3. Dual Rear Afterburner Thrusters
	var thruster_l = tail + perp * 3.5
	var thruster_r = tail - perp * 3.5

	draw_circle(thruster_l, 2.0, Color("#0B121C"))
	draw_circle(thruster_r, 2.0, Color("#0B121C"))

	# Exhaust flame plumes
	var base_flame_len = lerp(3.0, 14.0, sprint_factor)
	var flame_len = base_flame_len + sin(_bob_time * 15.0) * (3.0 * sprint_factor)
	var flame_col = Color("#FF3300") if sprint_factor > 0.4 else Color("#00D4FF")

	draw_line(thruster_l, thruster_l - forward * flame_len, flame_col, 2.2)
	draw_line(thruster_l, thruster_l - forward * (flame_len * 0.5), Color("#FFD700"), 1.2)
	draw_line(thruster_r, thruster_r - forward * flame_len, flame_col, 2.2)
	draw_line(thruster_r, thruster_r - forward * (flame_len * 0.5), Color("#FFD700"), 1.2)

	# Supersonic shock diamond cones when sprinting
	if sprint_factor > 0.6:
		var diamond_pos = tail - forward * (flame_len * 0.7)
		draw_line(diamond_pos + perp * 2.0, diamond_pos - perp * 2.0, Color.WHITE, 1.0)

func _draw_type_overlay(bob: float) -> void:
	var ahead = _count_enemies_ahead()
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-10, 14 + bob),
		"#" + str(ahead) + " FIFO",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		8,
		Color("#FFFFFF", 0.75)
	)
