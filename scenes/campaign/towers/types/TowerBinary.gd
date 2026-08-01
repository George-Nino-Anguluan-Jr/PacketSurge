# TowerBinary.gd
# Binary Tower — divide & conquer. Fires a high-damage sniper shot at the
# median enemy, then the bolt splits, damaging both halves of the group.

extends TowerBase

func get_type_id() -> String:
	return "tower_binary"

func _select_target() -> Node:
	# Binary search picks the middle element of the sorted (path-ordered) list.
	_clean_targets()
	return _get_median_target()

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
		"speed": 450.0,
		"damage": damage * 2.2,
		"style": "binary_sniper",
		"elapsed_time": 0.0,
		"total_dist": (current_target.position - spawn_origin).length(),
		"on_hit": _binary_split,
	}
	_spawn_custom_projectile(p)
	queue_redraw()

func _binary_split(p: Dictionary) -> void:
	# Divide & conquer: damage the two halves of the enemy group (ahead & behind).
	var sorted = _get_enemies_sorted_by_progress()
	if sorted.is_empty():
		return
	var mid_idx = int(sorted.size() / 2)
	var split_dmg = p["damage"] * 0.35
	for i in range(sorted.size()):
		var e = sorted[i]
		if not is_instance_valid(e) or e.is_dead or e == p["target"]:
			continue
		# Front half (behind the pivot) and back half (ahead of the pivot)
		if i < mid_idx or i > mid_idx:
			e.take_damage(split_dmg, tower_id)
			var aim = e.get_aim_point() if e.has_method("get_aim_point") else e.position
			_spawn_impact_explosion(aim, "binary_sniper", e)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.4, "speed": 1.0, "range": 1.1}

func _draw_base_geometry(color: Color, height: float) -> void:
	_draw_3d_box(Vector2(0, 0), Vector2(25, 17), height, Color("#101721"), color, 1.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 12.0
	_draw_3d_box(Vector2(-4, 0), Vector2(10, 8), 9.0, Color("#15202E"), color, 1.8)
	_draw_3d_cylinder(Vector2(6 + recoil, 0), 3.5, 18.0, Color("#203040"), color, 1.2)
	draw_circle(Vector2(24 + recoil, 0), 2.5, Color.BLACK)
	_draw_3d_cylinder(Vector2(4 + recoil, 0), 6.0, 3.0, Color("#101721"), color, 1.2)
	_draw_3d_cylinder(Vector2(16 + recoil, 0), 5.0, 3.0, Color("#101721"), color, 1.2)
	var ch = 3.5
	draw_line(Vector2(4 + recoil, -ch), Vector2(4 + recoil, ch), Color(color, 0.8), 1.5)
	draw_line(Vector2(4 + recoil - ch, 0), Vector2(4 + recoil + ch, 0), Color(color, 0.8), 1.5)
