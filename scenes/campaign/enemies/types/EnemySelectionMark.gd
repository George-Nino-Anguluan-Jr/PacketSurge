# EnemySelectionMark.gd
# Selection Mark — 75% resistance unless it's the lowest-HP enemy in range.
# Targets are vulnerable only when marked as lowest HP.
# Bespoke Procedural Design: "The Prism Drone"
# A floating octagonal prism core protected by three rotating deflection mirror shields.
# When it becomes the lowest-HP target, its mirrors blossom outward, exposing the core
# and projecting a golden target lock reticle on the ground.

extends Enemy

func get_type_id() -> String:
	return "selection_mark"

func _init_type_state() -> void:
	type_data["marked"] = false

func _modify_damage(amount: float) -> float:
	if not type_data["marked"]:
		return amount * 0.25
	return amount

func _process_type_logic(delta: float) -> void:
	type_data["marked"] = _is_lowest_hp_enemy()

func _draw_custom_enemy(col: Color, bob: float) -> void:
	var marked = type_data.get("marked", false)
	var center = Vector2(0, bob - 2)

	# 1. Ground Drop Shadow & Selection Target Lock Reticle
	if marked:
		# EXPOSED LOWEST-HP: Golden ground lock crosshairs
		var reticle_pulse = 0.7 + 0.3 * sin(_bob_time * 6.0)
		var ret_col = Color("#FFD700", reticle_pulse)
		draw_arc(Vector2(0, bob + 10), 16.0, 0, TAU, 20, ret_col, 1.8)
		# Reticle crosshair brackets
		draw_line(Vector2(-19, bob + 10), Vector2(-13, bob + 10), ret_col, 1.5)
		draw_line(Vector2(13, bob + 10), Vector2(19, bob + 10), ret_col, 1.5)
		draw_line(Vector2(0, bob + 4), Vector2(0, bob - 2), ret_col, 1.5)
		draw_line(Vector2(0, bob + 16), Vector2(0, bob + 22), ret_col, 1.5)
	else:
		CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, bob + 10), 15.0, 7.5, 0.35)

	# 2. Central Octagonal Prism Core
	var core_col = Color("#FFD700") if marked else col
	CyberVectorCanvas.draw_iso_cylinder(
		self,
		center,
		7.5,
		6.5,
		core_col.darkened(0.15) if marked else Color("#172435"),
		Color("#0B131D"),
		core_col,
		1.5,
		8
	)

	# 3. 3 Rotating Deflection Mirror Shields
	# When marked: blossom outward to radius 17; when shielded: tight defense at radius 11
	var mirror_rad = 17.0 if marked else 11.5
	var mirror_rot = _bob_time * (1.2 if marked else 2.5)

	for i in range(3):
		var a = i * (TAU / 3.0) + mirror_rot
		var m_pos = center + Vector2(cos(a) * mirror_rad, sin(a) * mirror_rad * 0.65 - 3.0)

		# Deflector mirror plate
		var m_tangent = Vector2(-sin(a), cos(a) * 0.65).normalized()
		var p1 = m_pos - m_tangent * 4.5
		var p2 = m_pos + m_tangent * 4.5

		# Mirror plate
		var m_col = Color("#FFD700") if marked else Color("#3A6588")
		draw_line(p1, p2, m_col, 2.5)
		draw_line(p1, p2, Color.WHITE, 1.0)

		# Mirror anchor strut to core
		draw_line(m_pos, center + Vector2(0, -3.0), Color(m_col, 0.35), 1.0)

	# 4. Top Core Diode
	var top_y = center.y - 6.5
	draw_circle(Vector2(0, top_y), 3.0, Color("#091017"))
	draw_circle(Vector2(0, top_y), 1.8, Color("#FFD700") if marked else col)
	draw_circle(Vector2(0, top_y), 0.8, Color.WHITE)
