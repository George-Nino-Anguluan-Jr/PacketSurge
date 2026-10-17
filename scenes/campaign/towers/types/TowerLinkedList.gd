# TowerLinkedList.gd
# Linked List Tower — fires chain lightning that walks the enemy list in path order
# (one node to the next), following linked list pointers.
# BESPOKE DESIGN: The Tri-Node Pointer Pylon
# Features a triangular platform with 3 levitating crystal node pylons linked by
# visible glowing directional pointer beams. Discharges crackling chain lightning
# with animated pointer hops.
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
		"target_last_pos": current_target.global_position,
		"speed": projectile_speed,
		"damage": damage,
		"style": "chain_lightning",
		"elapsed_time": 0.0,
		"total_dist": (current_target.global_position - spawn_origin).length(),
		"chains_left": chain_count,
		"chained_targets": [],
		"chain_radius": chain_radius,
		"traverse_path": true,
	}
	_spawn_custom_projectile(p)

func _get_custom_muzzle_position() -> Vector2:
	return global_position + Vector2(16.0, -8.0).rotated(_turret_angle)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.3, "speed": 1.0, "range": 1.2}

func _get_ability_targets() -> Array:
	var all = super._get_ability_targets()
	var result: Array = []
	for i in range(min(3, all.size())):
		result.append(all[i])
	return result

# ─── BESPOKE PROCEDURAL RENDERING ──────────────────────────────────────────

func _draw_custom_tower(color: Color) -> void:
	var t = _anim_time
	var is_firing = _recoil > 0.15

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, 6), 26.0, 16.0, 0.35)

	# 2. Triangular Base Platform
	var tri_pts = PackedVector2Array([
		Vector2(0, -18.0 * SQUASH),
		Vector2(20.0, 14.0 * SQUASH),
		Vector2(-20.0, 14.0 * SQUASH)
	])
	CyberVectorCanvas.draw_iso_prism(
		self,
		Vector2.ZERO,
		Vector2(18.0, 14.0),
		6.0,
		Color("#0B1C16"),
		Color("#050F0B"),
		Color(color, 0.4),
		1.2
	)

	# 3. Central Transmitter Obelisk (Pyramid/Prism)
	var core_pulse = 0.6 + sin(t * 5.0) * 0.4
	CyberVectorCanvas.draw_iso_cylinder(
		self,
		Vector2(0, 0),
		6.0,
		14.0,
		Color("#143428"),
		Color("#081A12"),
		Color(color, core_pulse),
		1.2,
		16
	)
	draw_circle(Vector2(0, -14.0), 3.0, Color(color, core_pulse * 0.8))
	draw_circle(Vector2(0, -14.0), 1.4, Color.WHITE)

	# 4. Three Levitating Node Pylons Orbiting around the Base
	var node_count = 3
	var node_pts = []
	for i in range(node_count):
		# Orbiting angle with height bobbing
		var orbit_ang = t * 1.5 + float(i) * TAU / float(node_count)
		var orbit_r = 15.0
		var nx = cos(orbit_ang) * orbit_r
		var ny = sin(orbit_ang) * orbit_r * SQUASH - 10.0 + sin(t * 3.0 + i) * 2.0
		var node_pos = Vector2(nx, ny)
		node_pts.append(node_pos)

		# Node shadow
		draw_circle(Vector2(nx, sin(orbit_ang) * orbit_r * SQUASH), 2.5, Color(0, 0, 0, 0.25))

		# Crystal Node body (Diamond / Hexagon)
		draw_circle(node_pos, 4.0, Color("#0D241C"))
		draw_circle(node_pos, 3.2, Color(color, 0.7))
		draw_circle(node_pos, 1.5, Color.WHITE)

		# Node index label
		draw_string(
			ThemeDB.fallback_font,
			node_pos + Vector2(-2, 3),
			str(i),
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			7,
			Color.WHITE
		)

	# 5. Glowing Pointer Beams Connecting the Nodes (0 -> 1 -> 2 -> NULL)
	for i in range(node_pts.size()):
		var p1 = node_pts[i]
		var next_idx = (i + 1) % node_pts.size()
		var p2 = node_pts[next_idx]

		if i < node_pts.size() - 1 or current_level == 3: # Lv3 circular/doubly linked
			draw_line(p1, p2, Color(color, 0.6), 1.2)
			# Animated pointer arrow head along beam
			var arrow_t = fmod(t * 2.0 + float(i) * 0.33, 1.0)
			var arrow_pos = p1.lerp(p2, arrow_t)
			var beam_dir = (p2 - p1).normalized()
			var beam_perp = Vector2(-beam_dir.y, beam_dir.x)
			draw_line(arrow_pos, arrow_pos - beam_dir * 3.5 + beam_perp * 2.0, Color.WHITE, 1.0)
			draw_line(arrow_pos, arrow_pos - beam_dir * 3.5 - beam_perp * 2.0, Color.WHITE, 1.0)

	# 6. Muzzle Discharge Arcs when Firing
	if is_firing:
		var target_node = node_pts[0]
		CyberVectorCanvas.draw_plasma_arc(self, Vector2(0, -14.0), target_node, color, 4.0, 5, 2.0)
		draw_circle(target_node, 7.0 * _recoil, Color(color, 0.5))
		draw_circle(target_node, 3.0 * _recoil, Color.WHITE)
