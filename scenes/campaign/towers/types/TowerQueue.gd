# TowerQueue.gd
# Queue Tower — FIFO targeting. Fires a piercing rail shot.
# Targets: first enemy entered (FIFO / dequeue semantics).

extends TowerBase

func get_type_id() -> String:
	return "tower_queue"

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
	var spawn_origin = get_muzzle_position()
	var dir = (current_target.global_position - global_position).normalized()
	var p = {
		"pos": spawn_origin,
		"start_pos": spawn_origin,
		"draw_pos": spawn_origin,
		"beam_dir": dir,
		"speed": 500.0,
		"damage": damage,
		"style": "queue_pierce",
		"elapsed_time": 0.0,
		"traveled": 0.0,
		"max_range": attack_range,
		"hit_list": [],
		"falloff": 1.0,
		"decay": 0.7,
		"beam_width": 10.0,
	}
	_spawn_custom_projectile(p)
	queue_redraw()

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.25, "speed": 1.2, "range": 1.1}

func _get_ability_damage_multiplier() -> float:
	return 0.6

func _draw_base_geometry(color: Color, height: float) -> void:
	_draw_3d_box(Vector2(0, 0), Vector2(23, 13), height, Color("#101721"), color, 1.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 9.0
	_draw_3d_box(Vector2(0, 0), Vector2(20, 3), 4.0, Color("#15202E"), color, 1.2)
	for i in range(4):
		var qx = -8 + i * 4.5
		_draw_3d_box(Vector2(qx, -2), Vector2(3, 2), 4.0, Color("#203040"), Color(color, 0.25 + i * 0.12), 1.0)
	_draw_3d_box(Vector2(9 + recoil, 0), Vector2(3, 6), 6.0, Color("#223344"), color, 1.2)
	draw_circle(Vector2(12 + recoil, 0), 2.0, Color.BLACK)
	draw_line(Vector2(-12, 4), Vector2(-14, 1), Color(color, 0.4), 1.0)
	draw_line(Vector2(-12, 4), Vector2(-14, 7), Color(color, 0.4), 1.0)
