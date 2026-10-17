# TowerQueue.gd
# Queue Tower — FIFO targeting. Fires a piercing rail shot.
# BESPOKE DESIGN: The FIFO Maglev Accelerator Corridor
# An elongated linear electromagnetic railgun with 3 sequential circular induction coils
# mounted along twin maglev guide rails. Energy pulses sequentially through the coils
# (FIFO pipeline) before accelerating an armor-piercing supersonic rail slug.
extends TowerBase

func get_type_id() -> String:
	return "tower_queue"

func _select_target() -> Node:
	_clean_targets()
	var q = _get_queued_enemies(1)
	if not q.is_empty():
		return q[0]
	if not targets.is_empty():
		return targets[0]
	return null

func _get_queued_enemies(max_count: int) -> Array:
	_clean_targets()
	if targets.is_empty():
		return []

	# 1. Primary FIFO Head: oldest enemy in tower range (highest progress or first entered)
	var primary: Node = null
	var best_prog: float = -1.0
	for t in targets:
		if is_instance_valid(t) and not t.is_dead:
			var prog = t.get_path_progress() if t.has_method("get_path_progress") else 0.0
			if prog > best_prog:
				best_prog = prog
				primary = t
	if primary == null:
		primary = targets[0]

	var result: Array[Node] = [primary]

	# 2. Sequential queue corridor: find subsequent enemies marching behind primary along the path
	var curr: Node = primary
	while result.size() < max_count:
		var nxt = _get_next_along_path(curr, result, 240.0)
		if nxt != null:
			result.append(nxt)
			curr = nxt
		else:
			break

	# 3. Fallback: check any other live enemies in targets
	if result.size() < max_count:
		for t in targets:
			if result.size() >= max_count:
				break
			if is_instance_valid(t) and not t.is_dead and not result.has(t):
				result.append(t)

	# 4. Fallback 2: check any live enemy within attack range + 50.0
	if result.size() < max_count and is_inside_tree():
		var all_enemies = get_tree().get_nodes_in_group("enemies")
		for e in all_enemies:
			if result.size() >= max_count:
				break
			if is_instance_valid(e) and not e.is_dead and not result.has(e):
				if global_position.distance_to(e.global_position) <= attack_range + 50.0:
					result.append(e)

	return result

func _perform_attack() -> void:
	_clean_targets()
	var max_pierce = clamp(1 + current_level, 2, max_targets)
	var queue_targets = _get_queued_enemies(max_pierce)
	if queue_targets.is_empty():
		return
	current_target = queue_targets[0]
	SoundManager.play_tower_attack(tower_id)
	_recoil = 1.0
	_flash_targets.clear()

	var spawn_origin = get_muzzle_position()
	var primary_target = queue_targets[0]
	var dir = (primary_target.global_position - spawn_origin).normalized() if (primary_target.global_position - spawn_origin).length() > 0 else Vector2.RIGHT.rotated(_turret_angle)

	# Supersonic penetrating kinetic rail slug:
	# Punches through primary (FIFO [0]), continues through subsequent queue enemies (PIERCE [1], [2]),
	# and overshoots past the last target into the distance!
	var p = {
		"pos": spawn_origin,
		"start_pos": spawn_origin,
		"draw_pos": spawn_origin,
		"target": primary_target,
		"target_last_pos": primary_target.global_position,
		"heading": dir,
		"speed": projectile_speed * 1.35, # Fast supersonic rail slug
		"damage": damage,
		"style": "queue_rail",
		"elapsed_time": 0.0,
		"total_dist": (primary_target.global_position - spawn_origin).length(),
		"on_hit": _on_queue_rail_step,
		"armor_pierce": armor_pierce,
		"pierce_queue": queue_targets,
		"pierce_idx": 0,
		"hit_list": [],
		"max_hits": max_pierce,
	}
	_spawn_custom_projectile(p)
	queue_redraw()

func _on_queue_rail_step(p: Dictionary) -> void:
	var queue: Array = p.get("pierce_queue", [])
	var idx: int = p.get("pierce_idx", 0)
	var current_node = p.get("target")

	# 1. Leave persistent luminous maglev ionization beam rail tracer
	_spawn_chain_arc(p.get("start_pos", global_position), p["pos"])

	# 2. Tag and visual feedback on pierced enemy
	if is_instance_valid(current_node) and not current_node.is_dead:
		if current_node.has_method("show_floating_tag"):
			if idx == 0:
				current_node.show_floating_tag("⚡ FIFO [0]", Color("#BB86FC"))
			else:
				current_node.show_floating_tag("⚡ PIERCE [%d]" % idx, Color("#03DAC6"))

	# 3. Punch through to the next live enemy in the queue sequence!
	idx += 1
	p["pierce_idx"] = idx
	while idx < queue.size():
		var next_target = queue[idx]
		if is_instance_valid(next_target) and not next_target.is_dead:
			var next_pos: Vector2 = next_target.get_aim_point() if next_target.has_method("get_aim_point") else next_target.global_position
			var heading_next: Vector2 = (next_pos - p["pos"]).normalized()
			if heading_next.length() > 0:
				p["heading"] = heading_next
			p["start_pos"] = p["pos"]
			p["target"] = next_target
			p["target_last_pos"] = next_pos
			p["damage"] *= 0.85 # Slight falloff per pierce
			p["continue_pierce"] = true
			return
		idx += 1
		p["pierce_idx"] = idx

	# 4. If last enemy or single enemy: supersonic slug overshoots 90px through the backside!
	if not p.get("overshot", false):
		var heading: Vector2 = p.get("heading", Vector2.ZERO)
		if heading == Vector2.ZERO:
			heading = (p["pos"] - p.get("start_pos", global_position)).normalized()
		if heading.length() == 0:
			heading = Vector2.RIGHT.rotated(_turret_angle)
		p["start_pos"] = p["pos"]
		p["target"] = null
		p["target_last_pos"] = p["pos"] + heading * 90.0
		p["heading"] = heading
		p["overshot"] = true
		p["continue_pierce"] = true

func _get_custom_muzzle_position() -> Vector2:
	return global_position + Vector2(22.0, 0.0).rotated(_turret_angle)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.25, "speed": 1.2, "range": 1.1}

func _get_ability_damage_multiplier() -> float:
	return 0.6

# ─── BESPOKE PROCEDURAL RENDERING ──────────────────────────────────────────

func _draw_custom_tower(color: Color) -> void:
	var t = _anim_time
	var is_firing = _recoil > 0.15

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, 6), 28.0, 14.0, 0.35)

	# 2. Main Maglev Platform Slab
	CyberVectorCanvas.draw_iso_chamfered_slab(
		self,
		Vector2.ZERO,
		Vector2(25, 14),
		5.0,
		6.0,
		Color("#111625"),
		Color("#090C14"),
		Color(color, 0.35),
		1.2
	)

	# 3. Animated FIFO Conveyor Glyphs on Slab Top
	for i in range(4):
		var step_x = -14.0 + i * 9.0 + fmod(t * 12.0, 9.0)
		if step_x < 16.0:
			draw_line(Vector2(step_x - 3, 2 * SQUASH), Vector2(step_x + 3, 2 * SQUASH), Color(color, 0.25), 1.0)
			draw_line(Vector2(step_x + 3, 2 * SQUASH), Vector2(step_x + 1, 2 * SQUASH - 1.5), Color(color, 0.35), 1.0)
			draw_line(Vector2(step_x + 3, 2 * SQUASH), Vector2(step_x + 1, 2 * SQUASH + 1.5), Color(color, 0.35), 1.0)

	# 4. Central Rotating Maglev Turret Assembly (Aims along _turret_angle)
	var recoil_offset = Vector2(-_recoil * 7.0, 0).rotated(_turret_angle)
	var turret_center = Vector2(0, -10.0) + recoil_offset

	# Turret swivel turntable
	CyberVectorCanvas.draw_iso_cylinder(
		self,
		turret_center,
		10.0,
		3.0,
		Color("#1A2234"),
		Color("#0B0E17"),
		Color(color, 0.5),
		1.0,
		16
	)

	# 5. Twin Parallel Maglev Guide Rails (Extending in aiming direction)
	var aim_dir = Vector2.RIGHT.rotated(_turret_angle)
	var perp_dir = Vector2(-aim_dir.y, aim_dir.x)
	var rail_len = 24.0
	var rail_spacing = 4.5

	var r1_start = turret_center + perp_dir * rail_spacing - aim_dir * 6.0
	var r1_end   = turret_center + perp_dir * rail_spacing + aim_dir * rail_len
	var r2_start = turret_center - perp_dir * rail_spacing - aim_dir * 6.0
	var r2_end   = turret_center - perp_dir * rail_spacing + aim_dir * rail_len

	draw_line(r1_start, r1_end, Color("#2C3B52"), 2.5)
	draw_line(r1_start, r1_end, Color(color, 0.6), 1.0)
	draw_line(r2_start, r2_end, Color("#2C3B52"), 2.5)
	draw_line(r2_start, r2_end, Color(color, 0.6), 1.0)

	# 6. The 3 Sequential Induction Acceleration Coils (FIFO order)
	var coil_count = clamp(2 + (current_level - 1), 2, 4)
	for i in range(coil_count):
		var frac = float(i) / float(coil_count - 1)
		var coil_pos = turret_center + aim_dir * (frac * (rail_len - 4.0))

		# Sequential wave pulse along coils (FIFO pipeline)
		var wave = fmod(t * 5.0 - float(i) * 0.35, 1.0)
		var coil_alpha = 0.3 + (0.7 if wave > 0.6 else 0.0)
		if is_firing:
			coil_alpha = 0.95

		var coil_rad = 6.0 - frac * 0.8
		CyberVectorCanvas.draw_induction_coil(
			self,
			coil_pos,
			coil_rad,
			color,
			coil_alpha,
			2.0
		)

	# 7. Muzzle Discharge Flash on Attack
	if is_firing:
		var muzz_pt = turret_center + aim_dir * (rail_len + 2.0)
		draw_circle(muzz_pt, 6.0 * _recoil, Color(color, 0.4))
		draw_circle(muzz_pt, 2.5 * _recoil, Color.WHITE)
		# Linear pierce laser flare
		draw_line(muzz_pt, muzz_pt + aim_dir * 18.0 * _recoil, Color.WHITE, 2.0)
		draw_line(muzz_pt, muzz_pt + aim_dir * 28.0 * _recoil, Color(color, 0.6), 1.0)
