# TowerSelection.gd
# Selection Tower — targets lowest HP enemy. Fires high-damage seeker.
# Targets: enemy with lowest current health.

extends TowerBase

func get_type_id() -> String:
	return "tower_selection"

func _select_target() -> Node:
	_clean_targets()
	if targets.is_empty():
		return null
	return _get_lowest_hp(targets)

func _perform_attack() -> void:
	if targets.is_empty():
		return
	current_target = _get_lowest_hp(targets)
	if not current_target:
		return
	SoundManager.play_tower_attack(tower_id)
	_recoil = 1.0
	_flash_targets.clear()
	_spawn_projectile("selection_sniper", damage * 1.8, 500.0, current_target)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.35, "speed": 1.0, "range": 1.15}

func _draw_base_geometry(color: Color, height: float) -> void:
	_draw_3d_hexagon(Vector2(0, 0), 21.0, height, Color("#101721"), color, 1.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 7.0
	_draw_3d_cylinder(Vector2(-6, -7), 2.5, 5.0, Color("#15202E"), color, 1.0)
	_draw_3d_cylinder(Vector2(-6, 7), 2.5, 5.0, Color("#15202E"), color, 1.0)
	draw_line(Vector2(-4, -5), Vector2(0, 0), color, 1.5)
	draw_line(Vector2(-4, 5), Vector2(0, 0), color, 1.5)
	_draw_3d_sphere(Vector2(0, 0), 4.5, Color(color, 0.6))
	_draw_3d_cylinder(Vector2(5 + recoil, 0), 3.5, 9.0, Color("#223344"), color, 1.5)
	draw_circle(Vector2(14 + recoil, 0), 2.5, Color.BLACK)
