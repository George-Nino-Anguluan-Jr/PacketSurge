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
	var dir = (current_target.global_position - spawn_origin).normalized() if (current_target.global_position - spawn_origin).length() > 0 else Vector2.RIGHT.rotated(_turret_angle)
	var p = {
		"pos": spawn_origin,
		"start_pos": spawn_origin,
		"draw_pos": spawn_origin,
		"beam_dir": dir,
		"target_last_pos": current_target.position if is_instance_valid(current_target) else spawn_origin,
		"speed": projectile_speed,
		"damage": damage,
		"style": "queue_pierce",
		"elapsed_time": 0.0,
		"traveled": 0.0,
		"max_range": attack_range + 160.0,
		"hit_list": [],
		"falloff": 1.0,
		"decay": 0.8,
		"beam_width": 18.0,
		"armor_pierce": armor_pierce,
		"max_hits": max_targets,
	}
	_spawn_custom_projectile(p)
	queue_redraw()

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
