# TowerMerge.gd
# Merge Tower — closest targeting. Fires two converging beams from left/right.
# Targets: closest enemy.

extends TowerBase

func get_type_id() -> String:
	return "tower_merge"

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
	var offset_l = Vector2(-6, -6).rotated(_turret_angle)
	var offset_r = Vector2(-6, 6).rotated(_turret_angle)
	for offset in [offset_l, offset_r]:
		var p = {
			"pos": spawn_origin + offset,
			"start_pos": spawn_origin + offset,
			"draw_pos": spawn_origin + offset,
			"target": current_target,
			"target_last_pos": current_target.position,
			"speed": 260.0,
			"damage": damage * 0.6,
			"style": "merge_beam",
			"elapsed_time": 0.0,
			"total_dist": (current_target.position - spawn_origin).length(),
			"merge_side": "left" if offset == offset_l else "right"
		}
		_spawn_custom_projectile(p)
	queue_redraw()

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.3, "speed": 1.0, "range": 1.15}

func _draw_base_geometry(color: Color, height: float) -> void:
	_draw_3d_cylinder(Vector2(0, 0), 20.0, height, Color("#101721"), color, 1.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 7.0
	_draw_3d_cylinder(Vector2(-6, -7), 2.5, 5.0, Color("#15202E"), color, 1.0)
	_draw_3d_cylinder(Vector2(-6, 7), 2.5, 5.0, Color("#15202E"), color, 1.0)
	draw_line(Vector2(-4, -5), Vector2(0, 0), color, 1.5)
	draw_line(Vector2(-4, 5), Vector2(0, 0), color, 1.5)
	_draw_3d_sphere(Vector2(0, 0), 4.5, Color(color, 0.6))
	_draw_3d_cylinder(Vector2(5 + recoil, 0), 3.5, 9.0, Color("#223344"), color, 1.5)
	draw_circle(Vector2(14 + recoil, 0), 2.5, Color.BLACK)
