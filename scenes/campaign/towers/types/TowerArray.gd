# TowerArray.gd
# Array Tower — O(1) random access. Fires a volley of indexed bolts at the
# nearest N enemies simultaneously (direct index access, no search cost).
# Higher level = more indices fired at once.

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

	# O(1) indexed access: fire at N fixed slots (indices), N grows with level.
	var index_count: int = clamp(1 + current_level, 1, 5)
	var hit_list: Array = []
	var nearest = _get_nearest(index_count)
	for e in nearest:
		if is_instance_valid(e) and not hit_list.has(e):
			hit_list.append(e)
	for i in range(hit_list.size()):
		_spawn_projectile("index_bolt", damage * 0.4, 350.0, hit_list[i], {"index": i})

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.3, "speed": 1.15, "range": 1.1}

func _get_ability_targets() -> Array:
	if targets.is_empty():
		return []
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
