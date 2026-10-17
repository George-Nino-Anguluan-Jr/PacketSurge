# EnemyBinaryMask.gd
# Binary Mask — Only vulnerable side takes full damage; 80% resistance on
# wrong side. Sides switch every 2-3 seconds with a 50/50 chance check.
# Bespoke Procedural Design: "The Dual-Phase Sentinel"
# A split humanoid cyber-shield with exposed pulsing circuit core on the
# vulnerable side and heavy hexagonal blast plating on the shielded side.

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
		queue_redraw()

func _draw_custom_enemy(col: Color, bob: float) -> void:
	var side = type_data.get("binary_side", false) # false: left vul, right shielded; true: right vul, left shielded
	var center = Vector2(0, bob - 2)

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, bob + 10), 16.0, 7.0, 0.35)

	# Colors
	var vul_col = Color("#00FF88")
	var shield_col = Color("#FF3366")

	# 2. Left & Right Chassis Halves (Split Shield Silhouette)
	var left_is_vul = not side
	var right_is_vul = side

	# Draw Left Half
	_draw_sentinel_half(center + Vector2(-8, 0), true, left_is_vul, vul_col, shield_col)

	# Draw Right Half
	_draw_sentinel_half(center + Vector2(8, 0), false, right_is_vul, vul_col, shield_col)

	# 3. Illuminated Center Division Seam
	var seam_pulse = 0.7 + 0.3 * sin(_bob_time * 6.0)
	var seam_col = Color("#FFFFFF", seam_pulse)
	draw_line(center + Vector2(0, -16), center + Vector2(0, 10), seam_col, 2.0)
	draw_line(center + Vector2(0, -16), center + Vector2(0, 10), Color("#00D4FF", 0.6), 4.0)

	# 4. Animated Scanning Spark along the seam
	var spark_y = center.y - 14 + fposmod(_bob_time * 24.0, 22.0)
	draw_circle(Vector2(0, spark_y), 2.5, Color.WHITE)
	draw_circle(Vector2(0, spark_y), 4.5, Color("#00D4FF", 0.5))

	# 5. Top Binary Node (0 / 1 Indicator)
	var top_pos = center + Vector2(0, -18)
	draw_circle(top_pos, 3.5, Color("#0D141F"))
	draw_circle(top_pos, 2.5, vul_col)
	draw_circle(top_pos, 1.2, Color.WHITE)

func _draw_sentinel_half(half_center: Vector2, is_left: bool, is_vul: bool, vul_col: Color, shield_col: Color) -> void:
	var h_sign = -1.0 if is_left else 1.0

	if is_vul:
		# VULNERABLE HALF: Exposed glowing cybernetic core with circuit traces
		CyberVectorCanvas.draw_iso_prism(
			self,
			half_center,
			Vector2(7.0, 12.0),
			7.0,
			Color("#122332"),
			Color("#09131C"),
			Color(vul_col, 0.8),
			1.5
		)
		# Circuit traces on top face
		var top_c = half_center + Vector2(0, -7.0)
		var trace = PackedVector2Array([
			top_c + Vector2(h_sign * 5, -4),
			top_c + Vector2(h_sign * 2, 0),
			top_c + Vector2(h_sign * 4, 4)
		])
		CyberVectorCanvas.draw_circuit_traces(self, trace, vul_col, 1.2, 1.5)
		# Internal glowing core diode
		draw_circle(top_c, 3.0, Color(vul_col, 0.4))
		draw_circle(top_c, 1.6, Color.WHITE)
	else:
		# SHIELDED HALF: Heavy titanium blast plating with deflecting scales
		CyberVectorCanvas.draw_iso_prism(
			self,
			half_center,
			Vector2(7.0, 12.0),
			8.5,
			Color("#222834"),
			Color("#10141D"),
			Color(shield_col, 0.4),
			1.5
		)
		# Heavy armor ridge lines
		var top_c = half_center + Vector2(0, -8.5)
		for r in range(3):
			var ry = top_c.y - 4 + r * 4
			draw_line(
				Vector2(half_center.x - 4, ry),
				Vector2(half_center.x + 4, ry),
				Color(shield_col, 0.6),
				1.5
			)
		# Deflection hex scale
		draw_circle(top_c, 2.5, Color("#3A475A"))
		draw_circle(top_c, 1.5, Color(shield_col, 0.5))

func _draw_status_effects(col: Color, bob: float) -> void:
	# Subtle ground bracket showing vulnerable side
	var side = type_data.get("binary_side", false)
	var ground_x = 8.0 if side else -8.0
	var ground_y = bob + 9.0
	draw_arc(Vector2(ground_x, ground_y), 9.0, 0, TAU, 12, Color("#00FF88", 0.4), 1.5)
