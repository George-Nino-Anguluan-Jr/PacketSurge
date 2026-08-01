# TowerQuick.gd
# Quick Tower — quicksort pivot partitioning. Fires a split shot at a pivot
# enemy (the median), then partitions: damages enemies on both sides of it.

extends TowerBase

func get_type_id() -> String:
	return "tower_quick"

func _select_target() -> Node:
	# Quicksort picks the pivot = median element of the sorted (path-ordered) list.
	_clean_targets()
	return _get_median_target()

func _perform_attack() -> void:
	if not current_target:
		return
	SoundManager.play_tower_attack(tower_id)
	_recoil = 1.0
	_flash_targets.clear()
	# Pivot shot: primary hit on the median enemy (the pivot).
	var spawn_origin = get_muzzle_position()
	var p = _make_quick_bolt(current_target, spawn_origin, true, 1.2)
	_spawn_custom_projectile(p)
	# Partition splits: one bolt to each side of the pivot along the path.
	var ahead_e = _get_next_along_path(current_target, [current_target], 80.0)
	var behind_e = _get_prev_along_path(current_target, [current_target], 80.0)
	if ahead_e:
		_spawn_custom_projectile(_make_quick_bolt(ahead_e, spawn_origin, false, 0.7))
	if behind_e:
		_spawn_custom_projectile(_make_quick_bolt(behind_e, spawn_origin, false, 0.7))

func _make_quick_bolt(target: Node, spawn_origin: Vector2, is_pivot: bool, mult: float) -> Dictionary:
	return {
		"pos": spawn_origin,
		"start_pos": spawn_origin,
		"draw_pos": spawn_origin,
		"target": target,
		"target_last_pos": target.position if is_instance_valid(target) else spawn_origin,
		"speed": 500.0,
		"damage": damage * mult,
		"style": "quick_split",
		"elapsed_time": 0.0,
		"total_dist": (target.position - spawn_origin).length() if is_instance_valid(target) else 0.0,
		"is_pivot": is_pivot,
		"on_hit": _quick_partition if is_pivot else null,
	}

func _quick_partition(p: Dictionary) -> void:
	# The pivot hit: partition the group into the two halves around it.
	var sorted = _get_enemies_sorted_by_progress()
	if sorted.is_empty():
		return
	var pivot_prog: float = _get_path_progress_of(p["target"]) if p["target"] and is_instance_valid(p["target"]) else 0.0
	var part_dmg = p["damage"] * 0.4
	for e in sorted:
		if not is_instance_valid(e) or e.is_dead or e == p["target"]:
			continue
		var prog = e.get_path_progress() if e.has_method("get_path_progress") else 0.0
		if abs(prog - pivot_prog) < 50.0:
			e.take_damage(part_dmg, tower_id)
			_spawn_chain_arc(p["target_last_pos"], e.get_aim_point() if e.has_method("get_aim_point") else e.position)

func _get_path_progress_of(e: Node) -> float:
	return e.get_path_progress() if is_instance_valid(e) and e.has_method("get_path_progress") else 0.0

func _get_prev_along_path(anchor: Node, exclude: Array[Node], max_dist: float) -> Node:
	# Quick partition: the enemy BEFORE the pivot along the path (the other half).
	var anchor_prog: float = _get_path_progress_of(anchor)
	var best: Node = null
	var best_prog: float = 0.0
	for e in targets:
		if not is_instance_valid(e) or e.is_dead or exclude.has(e):
			continue
		if not e.has_method("get_path_progress"):
			continue
		var prog: float = e.get_path_progress()
		if prog >= anchor_prog:
			continue
		if prog > best_prog:
			best_prog = prog
			best = e
	return best

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.25, "speed": 1.2, "range": 1.0}

func _draw_base_geometry(color: Color, height: float) -> void:
	_draw_3d_hexagon(Vector2(0, 0), 18.0, height, Color("#101721"), color, 1.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 8.0
	_draw_3d_cylinder(Vector2(0, 0), 3.0, 14.0, Color("#15202E"), color, 1.5)
	draw_circle(Vector2(8 + recoil, 0), 2.5, Color.BLACK)
	for i in range(3):
		draw_circle(Vector2(-4, -6 + i * 6), 1.0, Color(color, 0.3))
