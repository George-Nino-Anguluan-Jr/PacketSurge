# TowerRadix.gd
# Radix Tower — closest targeting. Fires 3 digit orbs (1, 10, 100).
# Targets: closest enemy.

extends TowerBase

func get_type_id() -> String:
	return "tower_radix"

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
	var digits = [1, 10, 100]
	for i in range(3):
		var p = {
			"pos": spawn_origin,
			"start_pos": spawn_origin,
			"draw_pos": spawn_origin,
			"target": current_target,
			"target_last_pos": current_target.position,
			"speed": 320.0,
			"damage": damage * 0.4,
			"style": "radix_digit",
			"elapsed_time": 0.0,
			"digit": digits[i],
			"delay": i * 0.08
		}
		_spawn_custom_projectile(p)
	queue_redraw()

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.2, "speed": 1.3, "range": 1.0}

func _draw_base_geometry(color: Color, height: float) -> void:
	_draw_3d_cylinder(Vector2(0, 0), 18.0, height, Color("#101721"), color, 1.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 6.0
	_draw_3d_sphere(Vector2(0, 0), 4.5, color)
	for i in range(3):
		var pivot = turret_head.position if turret_head else Vector2(0, -14)
		draw_set_transform(Vector2(0, 0), i * 0.4, Vector2(1.0, SQUASH))
		draw_arc(Vector2(0, 0), 9.0 + i * 2.5, 0, PI * 1.7, 14, Color(color, 0.25 + i * 0.15), 2.0 - i * 0.3)
		draw_set_transform(pivot, _turret_angle, Vector2.ONE)
	_draw_3d_cylinder(Vector2(6 + recoil, 0), 2.5, 7.0, Color("#203040"), color, 1.0)
	draw_circle(Vector2(13 + recoil, 0), 1.8, Color.BLACK)
	for i in range(8):
		var da = i * TAU / 8.0
		draw_circle(Vector2(cos(da) * 7.5, sin(da) * 7.5 * SQUASH), 0.8, Color(color, 0.6))
