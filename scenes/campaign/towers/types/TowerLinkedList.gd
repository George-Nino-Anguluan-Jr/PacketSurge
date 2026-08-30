# TowerLinkedList.gd
# Linked List Tower — fires chain lightning that walks the enemy list in path
# order (one node to the next), like following linked list pointers.
# REDESIGN: Node-chain relay — triangular prism base with 3 node pods,
# central hub + linked energy tethers. Mechanic = path-order chaining.

extends TowerBase

func get_type_id() -> String:
	return "tower_linked_list"

func _select_target() -> Node:
	_clean_targets()
	if targets.is_empty():
		return null
	return _get_closest(targets)

func _perform_attack() -> void:
	if not current_target:
		return
	SoundManager.play_tower_attack(tower_id)
	_recoil = 1.0
	_flash_targets.clear()
	var spawn_origin = get_muzzle_position()
	var p = {
		"pos": spawn_origin,
		"start_pos": spawn_origin,
		"draw_pos": spawn_origin,
		"target": current_target,
		"target_last_pos": current_target.position,
		"speed": 350.0,
		"damage": damage,
		"style": "chain_lightning",
		"elapsed_time": 0.0,
		"total_dist": (current_target.position - spawn_origin).length(),
		"chains_left": 3,
		"chained_targets": [],
		"chain_radius": 60.0,
		"traverse_path": true,
	}
	_spawn_custom_projectile(p)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.3, "speed": 1.0, "range": 1.2}

func _get_ability_targets() -> Array:
	var all = super._get_ability_targets()
	var result: Array = []
	for i in range(min(3, all.size())):
		result.append(all[i])
	return result

func _draw_base_geometry(color: Color, height: float) -> void:
	# Linked list base: chain of 3 node-circles with arrows, on a simple slab
	var is_shadow = color.a < 0.5
	var slab_col = Color("#0C1A14") if not is_shadow else Color("#0D131A")
	# Simple rectangular slab
	_draw_3d_box(Vector2(0, 0), Vector2(20, 16), height, slab_col, color, 1.5)
	if not is_shadow:
		# 3 linked nodes in a horizontal chain
		var node_positions = [Vector2(-10, 0), Vector2(0, 0), Vector2(10, 0)]
		for i in range(3):
			var np = node_positions[i]
			# Node circle
			draw_circle(np, 3.5, Color("#0A1520"))
			draw_circle(np, 3.5, Color(color, 0.4), false, 0.9)
			# Node label (A, B, C or 0, 1, 2)
			draw_string(ThemeDB.fallback_font, np + Vector2(-1.5, 1.5), str(i), HORIZONTAL_ALIGNMENT_CENTER, -1, 7, Color(color, 0.8))
			# Pointer arrow to next node
			if i < 2:
				var next = node_positions[i + 1]
				var arrow_start = np + Vector2(4.0, 0)
				var arrow_end = next - Vector2(4.0, 0)
				# Arrow shaft
				draw_line(arrow_start, arrow_end, Color(color, 0.5), 1.2)
				# Arrow head
				var tip = arrow_end
				var back = arrow_end - Vector2(2.5, 0)
				draw_line(tip, back + Vector2(0, 1.5), Color(color, 0.6), 1.0)
				draw_line(tip, back - Vector2(0, 1.5), Color(color, 0.6), 1.0)
		# NULL terminator after last node
		var null_pos = node_positions[2] + Vector2(7.0, 0)
		draw_line(node_positions[2] + Vector2(4.0, 0), null_pos, Color(color, 0.3), 0.8)
		draw_string(ThemeDB.fallback_font, null_pos + Vector2(-1.5, 1.5), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 6, Color(color, 0.4))
	# Slab outline
	draw_polyline(PackedVector2Array([
		Vector2(-20, -16 * SQUASH), Vector2(20, -16 * SQUASH),
		Vector2(20, 16 * SQUASH), Vector2(-20, 16 * SQUASH),
		Vector2(-20, -16 * SQUASH)
	]), color, 1.0 if not is_shadow else 0.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 5.0
	var t = _anim_time
	# Central relay hub — clean sphere
	_draw_3d_sphere(Vector2.ZERO, 4.5, color)
	# Pulsing ring around hub
	draw_arc(Vector2.ZERO, 6.0 + sin(t * 3.0) * 0.5, 0, TAU, 16, Color(color, 0.3), 0.8)
	# Emitter nozzle pointing right
	_draw_3d_cylinder(Vector2(5.0 + recoil, 0), 1.5, 8.0, Color("#1A2E4A"), color, 1.0)
	# Muzzle bore
	var bore = Vector2(13.0 + recoil, 0)
	draw_circle(bore, 1.2, Color.BLACK)
	draw_circle(bore, 2.0, Color(color, 0.2 if _recoil > 0.3 else 0.08))
	draw_circle(bore, 0.6, Color(color, 0.9))
	# Chain lightning arcs from hub to sides (static decorative arcs)
	for side in [-1.0, 1.0]:
		var arc_end = Vector2(0, side * 5.0)
		var mid = Vector2(3.0, side * 2.5)
		draw_line(Vector2.ZERO, mid, Color(color, 0.25), 0.7)
		draw_line(mid, arc_end, Color(color, 0.18), 0.6)
	# Flow dots along arcs
	for side in [-1.0, 1.0]:
		var flow_t = fmod(t * 2.0 + side * 0.5, 1.0)
		var p1 = Vector2.ZERO.lerp(Vector2(3.0, side * 2.5), flow_t)
		draw_circle(p1, 0.8, Color(1, 1, 1, 0.7))
