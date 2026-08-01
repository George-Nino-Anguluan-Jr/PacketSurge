# TowerBubble.gd
# Bubble Tower — FIFO targeting. Fires oscillating pulse orbs to 2 nearby enemies.
# Targets: first enemy entered.

extends TowerBase

func get_type_id() -> String:
	return "tower_bubble"

func _select_target() -> Node:
	_clean_targets()
	if targets.is_empty():
		return null
	return targets[0]

func _perform_attack() -> void:
	if targets.is_empty():
		return
	current_target = targets[0]
	SoundManager.play_tower_attack(tower_id)
	_recoil = 1.0
	_flash_targets.clear()

	var nearby = _get_nearby(1)
	if nearby.size() >= 2:
		_spawn_projectile("bubble_pulse", damage * 0.8, 280.0, current_target)
		_spawn_projectile("bubble_pulse", damage * 0.8, 280.0, nearby[1])
	else:
		_spawn_projectile("bubble_pulse", damage * 0.6, 280.0, current_target)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.25, "speed": 1.0, "range": 1.2}

func _draw_base_geometry(color: Color, height: float) -> void:
	_draw_3d_box(Vector2(0, 0), Vector2(18, 18), height, Color("#101721"), color, 1.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 4.0
	_draw_3d_box(Vector2(0, 0), Vector2(24, 3), 4.0, Color("#15202E"), color, 1.2)
	for i in range(6):
		var bx = -11 + i * 4.5
		var bh = 3.0 + i * 2.0
		_draw_3d_cylinder(Vector2(bx + recoil, -bh/2 - 1), 1.8, bh, Color("#1C2C3D"), Color(color, 0.3 + i * 0.1), 1.0)
		draw_circle(Vector2(bx + recoil + bh, (-bh/2 - 1) * SQUASH), 1.0, Color.BLACK)
	_draw_3d_box(Vector2(0, -10), Vector2(14, 2), 2.0, Color("#203040"), Color(color, 0.5), 1.0)
