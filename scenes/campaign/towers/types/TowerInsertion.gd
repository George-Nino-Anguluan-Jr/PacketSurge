# TowerInsertion.gd
# Insertion Tower — closest targeting. Fires a needle projectile + applies DoT.
# Targets: closest enemy.

extends TowerBase

func get_type_id() -> String:
	return "tower_insertion"

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
	_spawn_projectile("insertion_needle", damage, 350.0, current_target)
	if current_target.has_method("apply_dot"):
		current_target.apply_dot(damage * 0.3, 3.0)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.3, "speed": 1.15, "range": 1.0}

func _draw_base_geometry(color: Color, height: float) -> void:
	_draw_3d_box(Vector2(0, 0), Vector2(19, 15), height, Color("#101721"), color, 1.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 5.0
	_draw_3d_box(Vector2(0, 0), Vector2(20, 3), 3.0, Color("#15202E"), color, 1.2)
	_draw_3d_cylinder(Vector2(6 + recoil, 0), 2.5, 7.0, Color("#203040"), color, 1.0)
	draw_circle(Vector2(13 + recoil, 0), 1.8, Color.BLACK)
	draw_line(Vector2(-8, 5), Vector2(4, 0), Color(color, 0.4), 1.0)
	draw_line(Vector2(-8, 5), Vector2(4, 4), Color(color, 0.4), 1.0)
