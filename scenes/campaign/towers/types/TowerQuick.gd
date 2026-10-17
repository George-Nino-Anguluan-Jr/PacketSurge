# TowerQuick.gd
# Quick Tower — quicksort pivot partitioning. Fires a split shot at a pivot
# enemy (the median), then partitions: damages enemies on both sides of it.
# BESPOKE DESIGN: The Bifurcated Pivot Fork
# Features a dual-pronged conductive tuning fork flanking a high-frequency
# pivot plasma sphere. Discharges a heavy pivot bolt that fractures into partition arcs.
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
	var p = _make_quick_bolt(current_target, spawn_origin, true, 1.25)
	_spawn_custom_projectile(p)

	var ahead_e = _get_next_along_path(current_target, [current_target], 120.0)
	var behind_e = _get_prev_along_path(current_target, [current_target], 120.0)
	if ahead_e:
		_spawn_custom_projectile(_make_quick_bolt(ahead_e, spawn_origin, false, 0.65))
	if behind_e:
		_spawn_custom_projectile(_make_quick_bolt(behind_e, spawn_origin, false, 0.65))

func _make_quick_bolt(target, spawn_origin: Vector2, is_pivot: bool, mult: float) -> Dictionary:
	return {
		"pos": spawn_origin,
		"start_pos": spawn_origin,
		"draw_pos": spawn_origin,
		"target": target,
		"target_last_pos": target.global_position if is_instance_valid(target) else spawn_origin,
		"speed": projectile_speed,
		"damage": damage * mult,
		"style": "quick_split",
		"elapsed_time": 0.0,
		"total_dist": (target.global_position - spawn_origin).length() if is_instance_valid(target) else 0.0,
		"is_pivot": is_pivot,
		"on_hit": _quick_partition if is_pivot else null,
		"armor_pierce": armor_pierce,
	}

func _quick_partition(p: Dictionary) -> void:
	var target = p.get("target")
	if not is_instance_valid(target) or target.is_dead:
		return
	if target.has_method("show_floating_tag"):
		target.show_floating_tag("🎯 PIVOT!", Color("#FFB800"))

	var sorted = _get_enemies_sorted_by_progress()
	if sorted.is_empty():
		return
	var pivot_prog: float = _get_path_progress_of(target)
	var part_dmg = p["damage"] * 0.45
	for e in sorted:
		if not is_instance_valid(e) or e.is_dead or e == target:
			continue
		var prog = e.get_path_progress() if e.has_method("get_path_progress") else 0.0
		if abs(prog - pivot_prog) < 100.0:
			e.take_damage(part_dmg, tower_id)
			var aim = e.get_aim_point() if e.has_method("get_aim_point") else e.global_position
			_spawn_impact_explosion(aim, "quick_split", e)
			if e.has_method("show_floating_tag"):
				if prog > pivot_prog:
					e.show_floating_tag("[>P] PARTITION", Color("#00E5FF"))
				else:
					e.show_floating_tag("[<P] PARTITION", Color("#E040FB"))

func _get_path_progress_of(e) -> float:
	return e.get_path_progress() if is_instance_valid(e) and not e.is_dead and e.has_method("get_path_progress") else 0.0

func _get_prev_along_path(anchor, exclude: Array, max_dist: float) -> Node:
	if not is_instance_valid(anchor):
		return null
	var anchor_prog: float = _get_path_progress_of(anchor)
	var best: Node = null
	var best_prog: float = -1.0
	var candidates: Array = []
	if is_inside_tree():
		candidates = get_tree().get_nodes_in_group("enemies")
	if candidates.is_empty():
		candidates = targets

	for e in candidates:
		if not is_instance_valid(e) or e.is_dead or exclude.has(e):
			continue
		if not e.has_method("get_path_progress"):
			continue
		var prog: float = e.get_path_progress()
		if prog >= anchor_prog:
			continue
		if anchor.global_position.distance_to(e.global_position) > max_dist:
			continue
		if prog > best_prog:
			best_prog = prog
			best = e
	return best

func _get_custom_muzzle_position() -> Vector2:
	return global_position + Vector2(18.0, 0.0).rotated(_turret_angle)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.25, "speed": 1.2, "range": 1.0}

# ─── BESPOKE PROCEDURAL RENDERING ──────────────────────────────────────────

func _draw_custom_tower(color: Color) -> void:
	var t = _anim_time
	var is_firing = _recoil > 0.2

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, 6), 25.0, 15.0, 0.35)

	# 2. Hexagonal Split-Partition Base
	CyberVectorCanvas.draw_iso_hexagon(
		self,
		Vector2.ZERO,
		19.0,
		6.0,
		Color("#1C0C14"),
		Color("#0E060A"),
		Color(color, 0.4),
		1.2
	)

	# Partition divide seam through center of base
	draw_line(Vector2(0, -12 * SQUASH), Vector2(0, 12 * SQUASH), Color(color, 0.5), 1.2)

	# 3. Rotating Pivot Core Turret Assembly
	var aim_dir = Vector2.RIGHT.rotated(_turret_angle)
	var perp_dir = Vector2(-aim_dir.y, aim_dir.x)
	var recoil_offset = -aim_dir * _recoil * 6.0
	var turret_center = Vector2(0, -9.0) + recoil_offset

	# Turret Hub Drum
	CyberVectorCanvas.draw_iso_cylinder(
		self,
		turret_center,
		8.5,
		3.0,
		Color("#2A121F"),
		Color("#13080E"),
		Color(color, 0.6),
		1.0,
		16
	)

	# 4. Central Glowing Pivot Sphere
	var pivot_pulse = 0.7 + sin(t * 8.0) * 0.3
	var core_pos = turret_center + aim_dir * 2.0
	draw_circle(core_pos, 5.0, Color(color, 0.4))
	draw_circle(core_pos, 3.8, Color(color, pivot_pulse))
	draw_circle(core_pos, 1.8, Color.WHITE)

	# 5. Dual Conductive Fork Prongs (Flanking the Pivot Core)
	var prong_spacing = 7.0
	var prong_len = 18.0
	var p1_base = turret_center + perp_dir * prong_spacing
	var p1_tip  = p1_base + aim_dir * prong_len
	var p2_base = turret_center - perp_dir * prong_spacing
	var p2_tip  = p2_base + aim_dir * prong_len

	# Left Prong
	draw_line(p1_base, p1_tip, Color("#3D1E30"), 2.5)
	draw_line(p1_base, p1_tip, Color(color, 0.7), 1.0)
	draw_circle(p1_tip, 2.0, Color.WHITE)

	# Right Prong
	draw_line(p2_base, p2_tip, Color("#3D1E30"), 2.5)
	draw_line(p2_base, p2_tip, Color(color, 0.7), 1.0)
	draw_circle(p2_tip, 2.0, Color.WHITE)

	# 6. High-Frequency Plasma Arc Bridging across the Fork
	CyberVectorCanvas.draw_plasma_arc(self, p1_tip, p2_tip, color, 3.0, 4, 1.2)

	# 7. Muzzle Discharge Flash on Attack
	if is_firing:
		var muzz_pt = turret_center + aim_dir * (prong_len + 2.0)
		draw_circle(muzz_pt, 7.0 * _recoil, Color(color, 0.5))
		draw_circle(muzz_pt, 3.0 * _recoil, Color.WHITE)
		draw_line(p1_tip, muzz_pt, Color.WHITE, 1.8)
		draw_line(p2_tip, muzz_pt, Color.WHITE, 1.8)
