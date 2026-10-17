# EnemyLinkedDrain.gd
# Linked Drain — Spawns as paired enemies. 50/50 damage split with partner.
# Bespoke Procedural Design: "The Umbilical Pair"
# A high-tech hexagonal biocircuit drone connected to its twin via a flexible,
# glowing umbilical data conduit that pulses with energy whenever damage is shared.

extends Enemy

func get_type_id() -> String:
	return "linked_drain"

func _init_type_state() -> void:
	type_data["link_color"] = Color("#00FF88")
	if not type_data.has("partner_id"):
		type_data["partner_id"] = 0

func _modify_damage(amount: float) -> float:
	var partner = get_partner()
	if partner and is_instance_valid(partner) and not partner.is_dead:
		var shared = amount * 0.5
		partner.take_damage_direct(shared)
		queue_redraw()
		return amount * 0.5
	return amount

func _process_type_logic(delta: float) -> void:
	_bob_time += delta * 1.5

func set_partner(p: Node) -> void:
	type_data["partner_id"] = p.get_instance_id() if p != null else 0

func get_partner() -> Node:
	var pid: int = int(type_data.get("partner_id", 0))
	if pid == 0:
		return null
	var p = instance_from_id(pid)
	if p == null or not is_instance_valid(p):
		type_data["partner_id"] = 0
		return null
	return p

func _draw_custom_enemy(col: Color, bob: float) -> void:
	var center = Vector2(0, bob - 2)

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, bob + 10), 15.0, 7.5, 0.35)

	# 2. Main Hexagonal Biocircuit Prism Chassis
	CyberVectorCanvas.draw_iso_hexagon(
		self,
		center,
		12.0,
		7.0,
		Color("#152433"),
		Color("#0B131C"),
		Color(col, 0.7),
		1.5
	)

	# 3. Pointer Nodes on Hexagon Vertices
	var top_c = center + Vector2(0, -7.0)
	for i in range(6):
		var a = i * (TAU / 6.0)
		var p_pos = top_c + Vector2(cos(a) * 8.0, sin(a) * 8.0 * 0.65)
		draw_circle(p_pos, 1.8, Color("#00FF88"))
		draw_circle(p_pos, 0.8, Color.WHITE)

	# 4. Central Pointer Hub & Arrow
	draw_circle(top_c, 3.5, Color("#091017"))
	draw_circle(top_c, 2.2, Color("#00FF88", 0.8))
	draw_circle(top_c, 1.0, Color.WHITE)

func _draw_status_effects(col: Color, bob: float) -> void:
	var partner = get_partner()
	if partner and is_instance_valid(partner) and not partner.is_dead:
		var link_col = type_data.get("link_color", Color("#00FF88"))
		var partner_local = to_local(partner.position)
		var my_hub = Vector2(0, bob - 9.0)
		var partner_hub = partner_local + Vector2(0, -9.0)

		# Draw dynamic sagging catenary curve for umbilical cable
		var mid_pt = (my_hub + partner_hub) * 0.5 + Vector2(0, 12.0 + sin(_bob_time * 3.0) * 3.0)
		var curve_pts = PackedVector2Array()
		var segs = 10
		for i in range(segs + 1):
			var t = float(i) / float(segs)
			var pt = my_hub.bezier_interpolate(mid_pt, mid_pt, partner_hub, t)
			curve_pts.append(pt)

		# Umbilical outer glow & core wire
		draw_polyline(curve_pts, Color(link_col, 0.35), 3.0)
		draw_polyline(curve_pts, link_col, 1.5)
		draw_polyline(curve_pts, Color.WHITE, 0.8)

		# Pulsing data packet traversing along umbilical
		var packet_t = fposmod(_bob_time * 0.8, 1.0)
		var pulse_pt = my_hub.bezier_interpolate(mid_pt, mid_pt, partner_hub, packet_t)
		draw_circle(pulse_pt, 3.0, Color(link_col, 0.6))
		draw_circle(pulse_pt, 1.5, Color.WHITE)
