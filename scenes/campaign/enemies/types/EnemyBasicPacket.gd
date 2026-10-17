# EnemyBasicPacket.gd
# Basic Packet — The standard network packet.
# Bespoke Procedural Design: "The Standard Data Cube"
# A crisp 3D isometric cyber-crate with branching circuit traces,
# glowing data core diode, and orbiting bit particles.

extends Enemy

func get_type_id() -> String:
	return "basic_packet"

func _init_type_state() -> void:
	pass

func _draw_custom_enemy(col: Color, bob: float) -> void:
	var center = Vector2(0, bob - 2)
	var glow_col = col

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, bob + 10), 14.0, 7.0, 0.35)

	# 2. Main 3D Isometric Data Cube
	var base_dark = Color("#0D141F")
	var top_panel = Color("#172435")
	CyberVectorCanvas.draw_iso_prism(
		self,
		center,
		Vector2(12.0, 12.0),
		9.0,
		top_panel,
		base_dark,
		Color(glow_col, 0.7),
		1.5
	)

	# 3. Top Face Circuit Traces & Solder Vias
	var top_center = center + Vector2(0, -9.0)
	var trace_pts1 = PackedVector2Array([
		top_center + Vector2(-6.0, 0.0),
		top_center + Vector2(-2.0, -2.5),
		top_center + Vector2(0.0, -2.5)
	])
	var trace_pts2 = PackedVector2Array([
		top_center + Vector2(6.0, 0.0),
		top_center + Vector2(2.0, 2.5),
		top_center + Vector2(0.0, 2.5)
	])
	CyberVectorCanvas.draw_circuit_traces(self, trace_pts1, Color(glow_col, 0.7), 1.0, 1.2)
	CyberVectorCanvas.draw_circuit_traces(self, trace_pts2, Color(glow_col, 0.7), 1.0, 1.2)

	# 4. Central Glowing Core Diode
	var pulse = 0.8 + 0.2 * sin(_bob_time * 4.0)
	draw_circle(top_center, 3.0, Color(glow_col, 0.35 * pulse))
	draw_circle(top_center, 1.8, Color(glow_col, 0.9))
	draw_circle(top_center, 0.8, Color.WHITE)

	# 5. Floating Orbiting Bit Particles
	for i in range(4):
		var a = i * (PI * 0.5) + _bob_time * 1.5
		var orb_x = cos(a) * 16.0
		var orb_y = sin(a) * 9.0 + bob - 6.0
		var bit_alpha = 0.4 + 0.4 * sin(_bob_time * 3.0 + i)
		draw_rect(Rect2(orb_x - 1.2, orb_y - 1.2, 2.4, 2.4), Color(glow_col, bit_alpha))
		draw_rect(Rect2(orb_x - 0.6, orb_y - 0.6, 1.2, 1.2), Color.WHITE)
