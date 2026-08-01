# TowerQuick.gd
# Quick Tower — FIFO targeting. Fires splitting projectiles that hit 2 targets.
# Targets: first enemy entered.

extends TowerBase

func get_type_id() -> String:
	return "tower_quick"

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
	_spawn_projectile("quick_split", damage * 0.8, 450.0, current_target)
	var nearby = _get_nearby(1)
	if nearby.size() >= 2:
		_spawn_projectile("quick_split", damage * 0.8, 450.0, nearby[1])

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.25, "speed": 1.2, "range": 1.0}

func _draw_base_geometry(color: Color, height: float) -> void:
	_draw_3d_hexagon(Vector2(0, 0), 18.0, height, Color("#101721"), color, 1.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 8.0
	_draw_3d_cylinder(Vector2(0, 0), 3.0, 14.0, Color("#15202E"), color, 1.5)
	draw_circle(Vector2(8 + recoil, 0 * SQUASH), 2.5, Color.BLACK)
	for i in range(3):
		draw_circle(Vector2(-4, -6 + i * 6), 1.0, Color(color, 0.3))
