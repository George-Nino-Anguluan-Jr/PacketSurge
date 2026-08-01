# TowerArray.gd
# Array Tower — fires up to 5 index bolts at nearest enemies simultaneously.
# Targets: 5 closest enemies. O(1) access.

extends TowerBase

func get_type_id() -> String:
	return "tower_array"

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

	var hit_list = [current_target]
	var nearby = _get_nearby(2)
	for e in nearby:
		if e != current_target and not hit_list.has(e):
			hit_list.append(e)
			if hit_list.size() >= 3:
				break
	for t in hit_list:
		_spawn_projectile("index_bolt", damage * 0.4, 350.0, t, {"index": _array_bolt_index()})

func _array_bolt_index() -> int:
	# Incremental index for visual labeling
	return randi() % 5

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.3, "speed": 1.15, "range": 1.1}

func _get_ability_targets() -> Array:
	if targets.is_empty():
		return []
	# Single target, double damage
	return [targets[0]]

func _draw_base_geometry(color: Color, height: float) -> void:
	_draw_3d_box(Vector2(0, 0), Vector2(17, 17), height, Color("#101721"), color, 1.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 6.0
	_draw_3d_box(Vector2(0, 0), Vector2(22, 5), 7.0, Color("#15202E"), color, 1.5)
	for i in range(5):
		var bx = -9 + i * 4.5
		_draw_3d_cylinder(Vector2(bx + recoil, -2), 1.8, 8.0, Color("#1C2C3D"), color, 1.0)
		draw_circle(Vector2(bx + recoil + 8.0, -2 * SQUASH), 1.2, Color.BLACK)
	for i in range(5):
		draw_circle(Vector2(-9 + i * 4.5, 5), 1.0, Color(color, 0.5))
