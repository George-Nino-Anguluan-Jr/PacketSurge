# TowerStack.gd
# Stack Tower — LIFO targeting. Fires a lobbing mortar with arc trajectory.
# Targets: last enemy entered (LIFO / pop semantics).

extends TowerBase

func get_type_id() -> String:
	return "tower_stack"

func _select_target() -> Node:
	_clean_targets()
	if targets.is_empty():
		return null
	return targets[-1]

func _perform_attack() -> void:
	if targets.is_empty():
		return
	current_target = targets[-1]
	SoundManager.play_tower_attack(tower_id)
	_recoil = 1.0
	_flash_targets.clear()
	_spawn_projectile("stack_mortar", damage * 1.4, 300.0, current_target)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.4, "speed": 1.0, "range": 1.15}

func _get_ability_targets() -> Array:
	var all = super._get_ability_targets()
	if all.is_empty():
		return []
	return [all[-1]]

func _draw_base_geometry(color: Color, height: float) -> void:
	_draw_3d_hexagon(Vector2(0, 0), 19.0, height, Color("#101721"), color, 1.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 8.0
	for i in range(4):
		var sy = 5 - i * 3.5
		_draw_3d_cylinder(Vector2(0, sy), 4.5 - i * 0.4, 2.5, Color("#15202E"), Color(color, 0.3 + i * 0.12), 1.0)
	_draw_3d_cylinder(Vector2(recoil, -7), 4.0, 9.0, Color("#223344"), color, 1.5)
	draw_circle(Vector2(recoil + 9.0, -7 * SQUASH), 2.5, Color.BLACK)
