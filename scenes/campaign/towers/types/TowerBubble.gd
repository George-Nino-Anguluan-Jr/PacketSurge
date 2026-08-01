# TowerBubble.gd
# Bubble Tower — bubble sort swap pass. Fires pulse orbs at two adjacent
# enemies; on impact the targets SWAP places along the path (a bubble pass).

extends TowerBase

func get_type_id() -> String:
	return "tower_bubble"

func _perform_attack() -> void:
	if targets.is_empty():
		return
	current_target = targets[0]
	SoundManager.play_tower_attack(tower_id)
	_recoil = 1.0
	_flash_targets.clear()

	# Bubble sort: pick the two "adjacent" elements (by path progress) and swap.
	var sorted = _get_enemies_sorted_by_progress()
	if sorted.size() >= 2:
		var a: Node = sorted[0]
		var b: Node = sorted[1]
		_spawn_projectile("bubble_pulse", damage * 0.8, 280.0, a)
		_spawn_projectile("bubble_pulse", damage * 0.8, 280.0, b, {
			"on_hit": _bubble_swap,
			"swap_a": a,
			"swap_b": b,
		})
	else:
		_spawn_projectile("bubble_pulse", damage * 0.8, 280.0, current_target, {"on_hit": _bubble_pop})

func _bubble_swap(p: Dictionary) -> void:
	var a = p.get("swap_a")
	var b = p.get("swap_b")
	if is_instance_valid(a) and is_instance_valid(b) and not a.is_dead and not b.is_dead:
		var mid: Vector2 = (a.position + b.position) * 0.5
		_spawn_impact_explosion(mid, "bubble_pulse", null)
		a.swap_progress(b)

func _bubble_pop(p: Dictionary) -> void:
	var track: Node = p["target"] if is_instance_valid(p.get("target")) else null
	_spawn_impact_explosion(p["target_last_pos"], "bubble_pulse", track)

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
