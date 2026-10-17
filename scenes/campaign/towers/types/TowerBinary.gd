# TowerBinary.gd
# Binary Tower — divide & conquer. Fires a high-damage sniper shot at the
# median enemy, then the bolt splits, damaging both halves of the group.
# BESPOKE DESIGN: The Quantum Divide Rail Cannon
# An ultra-long monolithic sniper cannon mounted on a divided 0/1 platform.
# Features telescoping magnetic acceleration shrouds and a digital focal ring.
extends TowerBase

func get_type_id() -> String:
	return "tower_binary"

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
	var p = {
		"pos": spawn_origin,
		"start_pos": spawn_origin,
		"draw_pos": spawn_origin,
		"target": current_target,
		"target_last_pos": current_target.global_position,
		"speed": projectile_speed,
		"damage": damage * 2.2,
		"style": "binary_sniper",
		"elapsed_time": 0.0,
		"total_dist": (current_target.global_position - spawn_origin).length(),
		"on_hit": _binary_split,
		"armor_pierce": armor_pierce,
	}
	_spawn_custom_projectile(p)
	queue_redraw()

func _binary_split(p: Dictionary) -> void:
	var target = p.get("target")
	if is_instance_valid(target) and not target.is_dead and target.has_method("show_floating_tag"):
		target.show_floating_tag("🎯 MEDIAN!", Color("#00FF88"))
	var sorted = _get_enemies_sorted_by_progress()
	if sorted.is_empty():
		return
	var mid_idx = int(sorted.size() / 2)
	var split_dmg = p["damage"] * 0.35
	for i in range(sorted.size()):
		var e = sorted[i]
		if not is_instance_valid(e) or e.is_dead or e == p["target"]:
			continue
		if i < mid_idx or i > mid_idx:
			e.take_damage(split_dmg, tower_id, p.get("armor_pierce", false))
			var aim = e.get_aim_point() if e.has_method("get_aim_point") else e.global_position
			_spawn_impact_explosion(aim, "binary_sniper", e)

func _get_custom_muzzle_position() -> Vector2:
	return global_position + Vector2(28.0, 0.0).rotated(_turret_angle)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.4, "speed": 1.0, "range": 1.1}

# ─── BESPOKE PROCEDURAL RENDERING ──────────────────────────────────────────

func _draw_custom_tower(color: Color) -> void:
	var t = _anim_time
	var is_firing = _recoil > 0.15

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, 6), 28.0, 15.0, 0.4)

	# 2. Divided 0/1 Platform Slab (Chamfered)
	CyberVectorCanvas.draw_iso_chamfered_slab(
		self,
		Vector2.ZERO,
		Vector2(26, 15),
		6.0,
		7.0,
		Color("#111A0E"),
		Color("#070E05"),
		Color(color, 0.4),
		1.3
	)

	# High-tech divide seam down the center
	draw_line(Vector2(0, -12 * SQUASH), Vector2(0, 12 * SQUASH), Color(color, 0.6), 1.2)
	# Digital "0" on left half, "1" on right half
	draw_string(ThemeDB.fallback_font, Vector2(-12, 3), "0", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(color, 0.4))
	draw_string(ThemeDB.fallback_font, Vector2(6, 3), "1", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(color, 0.4))

	# 3. Rotating Turret Carriage (Aims along _turret_angle)
	var aim_dir = Vector2.RIGHT.rotated(_turret_angle)
	var perp_dir = Vector2(-aim_dir.y, aim_dir.x)
	var recoil_dist = -aim_dir * _recoil * 10.0 # Heavy sniper kickback
	var turret_center = Vector2(0, -9.0) + recoil_dist

	# Heavy Turret Hub Drum
	CyberVectorCanvas.draw_iso_cylinder(
		self,
		turret_center,
		9.0,
		4.0,
		Color("#1E2C18"),
		Color("#0C140A"),
		Color(color, 0.6),
		1.0,
		18
	)

	# 4. Long Anti-Materiel Rail Barrel (Telescoping)
	var barrel_len = 26.0
	var barrel_start = turret_center - aim_dir * 8.0
	var barrel_end   = turret_center + aim_dir * barrel_len

	# Main Gun Tube
	draw_line(barrel_start, barrel_end, Color("#2B3D22"), 4.0)
	draw_line(barrel_start, barrel_end, Color(color, 0.8), 1.2)

	# 5. Segmented Magnetic Acceleration Shrouds (Clamps)
	for i in range(3):
		var frac = 0.25 + float(i) * 0.28
		var clamp_pos = turret_center + aim_dir * (frac * barrel_len)
		var clamp_w = 7.0 - float(i) * 0.8

		# Left/Right Shroud Fins
		draw_line(clamp_pos - perp_dir * clamp_w, clamp_pos + perp_dir * clamp_w, Color("#3B5430"), 2.5)
		draw_line(clamp_pos - perp_dir * clamp_w, clamp_pos + perp_dir * clamp_w, Color(color, 0.9), 1.0)
		# Status LED on each clamp
		draw_circle(clamp_pos - perp_dir * clamp_w, 1.0, Color.WHITE)
		draw_circle(clamp_pos + perp_dir * clamp_w, 1.0, Color.WHITE)

	# 6. Digital Muzzle Brake / Focal Ring
	var muzzle_pos = barrel_end
	draw_circle(muzzle_pos, 3.5, Color.BLACK)
	draw_circle(muzzle_pos, 3.5, Color(color, 0.5), false, 1.2)
	draw_circle(muzzle_pos, 1.8, Color(color, 0.9))
	draw_circle(muzzle_pos, 0.8, Color.WHITE)

	# 7. Muzzle Blast & Kinetic Penetrator Flash on Attack
	if is_firing:
		draw_circle(muzzle_pos, 8.0 * _recoil, Color(color, 0.5))
		draw_circle(muzzle_pos, 3.5 * _recoil, Color.WHITE)
		# Kinetic Shock Cone
		var cone_len = 35.0 * _recoil
		var cone_w = 8.0 * _recoil
		var cone_poly = PackedVector2Array([
			muzzle_pos,
			muzzle_pos + aim_dir * cone_len + perp_dir * cone_w,
			muzzle_pos + aim_dir * cone_len - perp_dir * cone_w
		])
		draw_colored_polygon(cone_poly, Color(color, 0.25))
		draw_line(muzzle_pos, muzzle_pos + aim_dir * (cone_len + 15.0), Color.WHITE, 2.5)
