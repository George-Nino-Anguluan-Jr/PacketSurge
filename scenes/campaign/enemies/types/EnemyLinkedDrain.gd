# EnemyLinkedDrain.gd
# Linked Drain — Spawns as paired enemies. 50/50 damage split with partner.

extends Enemy

func get_type_id() -> String:
	return "linked_drain"

func _init_type_state() -> void:
	type_data["link_color"] = Color("#00FF88")
	if not type_data.has("partner"):
		type_data["partner"] = null

func _modify_damage(amount: float) -> float:
	var partner = get_partner()
	if partner and is_instance_valid(partner) and not partner.is_dead:
		var shared = amount * 0.5
		partner.take_damage_direct(shared)
		return amount * 0.5
	return amount

func _process_type_logic(delta: float) -> void:
	_bob_time += delta * 1.5

func set_partner(p: Node) -> void:
	type_data["partner"] = p

func get_partner() -> Node:
	return type_data.get("partner")

func _draw_type_body(col: Color, bob: float) -> void:
	# 3D hexagonal prism (linked list node)
	_draw_3d_hexagon(Vector2(0, bob - 2), 12.0, 7.0, Color("#15202E"), col, 1.5)
	# Top face connector dots
	for i in range(6):
		var a = i * PI / 3.0
		var px = cos(a) * 8
		var py = bob - 2 + sin(a) * 8 * SQUASH
		draw_circle(Vector2(px, py - 7 * SQUASH), 1.2, Color("#00FF88", 0.8))
	# Drop shadow
	var s = ensure_style()
	draw_set_transform(Vector2(0, bob + 5), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 12, Color(0, 0, 0, s.shadow_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_status_effects(col: Color, bob: float) -> void:
	var partner = get_partner()
	if partner and is_instance_valid(partner) and not partner.is_dead:
		var link_col = type_data.get("link_color", Color("#00FF88"))
		var pulse = (sin(_bob_time * 2.0) + 1.0) * 0.3
		draw_line(Vector2(0, 0), to_local(partner.position),
			Color(link_col, 0.4 + pulse), 1.5)
		draw_circle(Vector2(0, -16 + bob), 2.0, Color(link_col, 0.6))
