# TowerQuick.gd
# Quick Tower — quicksort pivot partitioning. Fires a split shot at a pivot
# enemy (the median), then partitions: damages enemies on both sides of it.
# REDESIGN: Pivot splitter — hexagonal base with partition gate, triple-prong
# pivot barrel. Mechanic = pivot + partition (fork into 3).

extends TowerBase

func get_type_id() -> String:
	return "tower_quick"

func _select_target() -> Node:
	_clean_targets()
	return _get_median_target()

func _perform_attack() -> void:
	if not current_target:
		return
	SoundManager.play_tower_attack(tower_id)
	_recoil = 1.0
	_flash_targets.clear()
	var spawn_origin = get_muzzle_position()
	var p = _make_quick_bolt(current_target, spawn_origin, true, 1.2)
	_spawn_custom_projectile(p)
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
	# Quick base: hexagonal platform with partition divide line and pivot hub
	var is_shadow = color.a < 0.5
	var hex_col = Color("#0D1A2E") if not is_shadow else Color("#0D131A")
	_draw_3d_hexagon(Vector2(0, 0), 18.0, height, hex_col, color, 1.5)
	if not is_shadow:
		# Partition divide line through center
		var part_a = Vector2(0, -14 * SQUASH)
		var part_b = Vector2(0, 14 * SQUASH)
		draw_line(part_a, part_b, Color(color, 0.3), 1.0)
		# Pivot hub at center
		draw_circle(Vector2.ZERO, 3.5, Color("#08111F"))
		draw_circle(Vector2.ZERO, 3.5, Color(color, 0.4), false, 0.9)
		draw_circle(Vector2.ZERO, 1.5, Color(color, 0.85))
		draw_circle(Vector2(-0.5, -0.3), 0.5, Color.WHITE)
		# Left/right partition labels
		draw_string(ThemeDB.fallback_font, Vector2(-8, -1), "<", HORIZONTAL_ALIGNMENT_CENTER, -1, 7, Color(color, 0.3))
		draw_string(ThemeDB.fallback_font, Vector2(4, -1), ">", HORIZONTAL_ALIGNMENT_CENTER, -1, 7, Color(color, 0.3))
		# Hex vertex dots
		for i in range(6):
			var a = i * TAU / 6.0
			var vx = cos(a) * 13.5
			var vy = sin(a) * 13.5 * SQUASH
			draw_circle(Vector2(vx, vy), 0.8, Color(color, 0.2))
	# Hex outline
	var hex_pts = PackedVector2Array()
	for i in range(6):
		var a = -PI / 2.0 + i * (TAU / 6.0)
		hex_pts.append(Vector2(cos(a) * 18.0, sin(a) * 18.0 * SQUASH))
	hex_pts.append(hex_pts[0])
	draw_polyline(hex_pts, color, 1.0 if not is_shadow else 0.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 8.0
	# Central pivot column
	_draw_3d_cylinder(Vector2(recoil * 0.3, 0), 2.5, 12.0, Color("#0F1F33"), color, 1.2)
	# Triple-prong fork emitter (partition gate)
	var muzz = Vector2(7.5 + recoil, 0)
	# Central prong (pivot)
	draw_line(muzz - Vector2(5, 0), muzz, Color(color, 0.8), 2.2)
	draw_circle(muzz, 1.8, Color.WHITE)
	draw_circle(muzz, 2.5, Color(color, 0.2))
	# Upper/lower prongs (partition halves)
	for side in [-1, 1]:
		var prong_tip = muzz + Vector2(1.5, side * 4.5)
		draw_line(muzz, prong_tip, Color(color, 0.6), 1.3)
		draw_circle(prong_tip, 1.3, Color(color, 0.4), false, 0.7)
		draw_circle(prong_tip, 0.5, color)
	# Rear stabilizer fins
	for side in [-1, 1]:
		draw_line(Vector2(-3, side * 3.0), Vector2(1, side * 1.5), Color(color, 0.28), 0.8)
