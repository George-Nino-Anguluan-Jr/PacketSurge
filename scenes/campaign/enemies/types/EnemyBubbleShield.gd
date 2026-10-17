# EnemyBubbleShield.gd
# Bubble Shield — First 3 hits are fully absorbed by a regenerating shield.
# After shield breaks, takes normal damage.
# Bespoke Procedural Design: "The Geodesic Cell"
# A high-tech geodesic forcefield encapsulating a fragile core sphere,
# with orbital energy nodes and dynamic structural fracture lines based on shield HP.

extends Enemy

func get_type_id() -> String:
	return "bubble_shield"

func _draw_custom_enemy(col: Color, bob: float) -> void:
	var center = Vector2(0, bob - 2)
	var shield_hp = int(type_data.get("shield_hp", 0))
	var shield_max = int(type_data.get("shield_max_hits", 3))

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, bob + 10), 16.0, 8.0, 0.35)

	# 2. Central Core Sphere
	# When shield is up: dim protected core. When broken: exposed pulsing hazard core.
	var core_col = col if shield_hp == 0 else col.darkened(0.2)
	CyberVectorCanvas.draw_drop_shadow(self, center, 10.0, 10.0, 0.2) # Core ambient occlusion
	draw_circle(center, 9.0, Color("#0D1622"))
	draw_circle(center, 8.0, core_col)
	# Core highlight
	draw_circle(center - Vector2(2.5, 2.5), 3.5, Color(Color.WHITE, 0.7 if shield_hp == 0 else 0.4))
	draw_circle(center - Vector2(2.5, 2.5), 1.5, Color.WHITE)

	# 3. Geodesic Forcefield (When shield_hp > 0)
	if shield_hp > 0:
		var shield_color = Color("#00D4FF")
		var pulse = 0.85 + 0.15 * sin(_bob_time * 5.0)

		# Outer geodesic perimeter
		var hex_pts = PackedVector2Array()
		for i in range(6):
			var a = i * (TAU / 6.0) + _bob_time * 0.4
			hex_pts.append(center + Vector2(cos(a) * 16.0, sin(a) * 14.0))

		# Translucent shield fill
		var fill_alpha = 0.12 * float(shield_hp) / float(shield_max)
		draw_colored_polygon(hex_pts, Color(shield_color, fill_alpha * pulse))

		# Geodesic facet lines
		for i in range(6):
			var next_i = (i + 1) % 6
			draw_line(hex_pts[i], hex_pts[next_i], Color(shield_color, 0.8 * pulse), 1.5)
			# Internal triangle strut to center
			draw_line(hex_pts[i], center, Color(shield_color, 0.35 * pulse), 1.0)

		# 4. Shield Degradation / Fracture Lines
		if shield_hp == 2:
			# Minor fracture lines
			draw_line(hex_pts[1], center + Vector2(3, -2), Color("#FFFFFF", 0.8), 1.2)
			draw_line(center + Vector2(3, -2), hex_pts[3], Color("#FFFFFF", 0.6), 1.0)
		elif shield_hp == 1:
			# Severe cracks & sparks
			draw_line(hex_pts[0], center + Vector2(-2, 3), Color("#FFFFFF", 0.9), 1.8)
			draw_line(center + Vector2(-2, 3), hex_pts[4], Color("#FFFFFF", 0.9), 1.5)
			draw_line(hex_pts[2], center + Vector2(4, -1), Color("#FF3366", 0.8), 1.5)
			# Micro spark points
			draw_circle(center + Vector2(-2, 3), 2.0, Color.WHITE)

		# 5. Orbiting Energy Node Satellites
		for i in range(shield_hp):
			var a = i * (TAU / float(shield_hp)) - _bob_time * 2.0
			var orb_pos = center + Vector2(cos(a) * 19.0, sin(a) * 12.0)
			# Node halo & core
			draw_circle(orb_pos, 3.5, Color(shield_color, 0.35))
			draw_circle(orb_pos, 2.0, shield_color)
			draw_circle(orb_pos, 1.0, Color.WHITE)
	else:
		# BROKEN SHIELD: Exposed warning ring
		var warn_pulse = 0.5 + 0.5 * sin(_bob_time * 8.0)
		draw_arc(center, 13.0, 0, TAU, 16, Color("#FF3366", 0.6 * warn_pulse), 1.5)
