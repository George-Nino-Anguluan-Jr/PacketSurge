# TowerLinear.gd
# Linear Tower — closest targeting. Fires a straight scan-line projectile.
# Targets: closest enemy. Long range (200).

extends TowerBase

func get_type_id() -> String:
	return "tower_linear"

func _select_target() -> Node:
	_clean_targets()
	if targets.is_empty():
		return null
	return _get_closest(targets)

func _perform_attack() -> void:
	if targets.is_empty():
		return
	current_target = _get_closest(targets)
	if not current_target:
		return
	SoundManager.play_tower_attack(tower_id)
	_recoil = 1.0
	_flash_targets.clear()

	var spawn_origin = get_muzzle_position()
	var dir = (current_target.global_position - global_position).normalized()
	var p = {
		"pos": spawn_origin,
		"start_pos": spawn_origin,
		"draw_pos": spawn_origin,
		"beam_dir": dir,
		"speed": 520.0,
		"damage": damage * 0.7,
		"style": "linear_beam",
		"elapsed_time": 0.0,
		"traveled": 0.0,
		"max_range": attack_range,
		"hit_list": [],
		"falloff": 1.0,
		"decay": 0.8,
	}
	_spawn_custom_projectile(p)
	queue_redraw()

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.25, "speed": 1.0, "range": 1.2}

func _draw_base_geometry(color: Color, height: float) -> void:
	_draw_3d_cylinder(Vector2(0, 0), 17.0, height, Color("#101721"), color, 1.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 9.0
	_draw_3d_box(Vector2(0, 0), Vector2(24, 2), 2.0, Color("#101721"), Color(color, 0.25), 1.0)
	_draw_3d_box(Vector2(recoil, -2), Vector2(5, 3), 3.0, Color("#15202E"), color, 1.2)
	_draw_3d_cylinder(Vector2(4 + recoil, -2), 2.5, 8.0, Color("#203040"), color, 1.0)
	draw_circle(Vector2(12 + recoil, -2 * SQUASH), 1.5, Color.BLACK)
	for i in range(7):
		draw_circle(Vector2(-12 + i * 4, 3), 0.6, Color(color, 0.3))
