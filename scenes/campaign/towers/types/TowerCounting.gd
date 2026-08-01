# TowerCounting.gd
# Count Tower — counting sort. Fires 1..N numbered pellets, where N is the
# number of enemies counted in range (one pellet per enemy, capped at 5).

extends TowerBase

func get_type_id() -> String:
	return "tower_counting"

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

	# Counting sort counts occurrences: one pellet per enemy in range.
	var count: int = clamp(_count_live_enemies(), 1, 5)
	var spawn_origin = get_muzzle_position()
	for i in range(count):
		var p = {
			"pos": spawn_origin,
			"start_pos": spawn_origin,
			"draw_pos": spawn_origin,
			"target": current_target,
			"target_last_pos": current_target.position,
			"speed": 200.0 + i * 40.0,
			"damage": damage * 0.25,
			"style": "counting_pellet",
			"elapsed_time": 0.0,
			"digit": i + 1,
			"delay": i * 0.05
		}
		_spawn_custom_projectile(p)
	queue_redraw()

func _count_live_enemies() -> int:
	var n: int = 0
	for e in targets:
		if is_instance_valid(e) and not e.is_dead:
			n += 1
	return n

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.2, "speed": 1.25, "range": 1.0}

func _draw_base_geometry(color: Color, height: float) -> void:
	_draw_3d_box(Vector2(0, 0), Vector2(18, 18), height, Color("#101721"), color, 1.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 6.0
	_draw_3d_cylinder(Vector2(0, 0), 3.0, 14.0, Color("#15202E"), color, 1.5)
	draw_circle(Vector2(9 + recoil, 0), 2.5, Color.BLACK)
	for i in range(8):
		var da = i * TAU / 8.0
		draw_circle(Vector2(cos(da) * 7.5, sin(da) * 7.5 * SQUASH), 0.8, Color(color, 0.6))
