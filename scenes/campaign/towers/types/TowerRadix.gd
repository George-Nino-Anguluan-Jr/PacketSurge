# TowerRadix.gd
# Radix Tower — radix sort buckets. Fires 3 digit orbs (1, 10, 100) each
# sorted into a different "bucket" place-value style across the group.
# BESPOKE DESIGN: The Three-Tier Decimal Pagoda
# A three-tiered stepped cylindrical pagoda tower representing 1s (Base), 10s (Mid),
# and 100s (Crown) place values. The tiers counter-rotate at different gear ratios,
# each discharging its dedicated digit pass in rapid succession.
extends TowerBase

func get_type_id() -> String:
	return "tower_radix"

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

	var digits = [1, 10, 100]
	var spawn_origin = get_muzzle_position()
	var bucket_targets = _get_nearest(digits.size())
	if bucket_targets.is_empty():
		bucket_targets.append(current_target)

	for i in range(digits.size()):
		var t: Node = current_target
		if i < bucket_targets.size():
			t = bucket_targets[i]
		var p = {
			"pos": spawn_origin,
			"start_pos": spawn_origin,
			"draw_pos": spawn_origin,
			"target": t,
			"target_last_pos": t.global_position if is_instance_valid(t) else spawn_origin,
			"speed": projectile_speed,
			"damage": damage * 0.4,
			"style": "radix_digit",
			"elapsed_time": 0.0,
			"digit": digits[i],
			"delay": i * 0.08,
			"armor_pierce": armor_pierce,
		}
		_spawn_custom_projectile(p)
	queue_redraw()

func _get_custom_muzzle_position() -> Vector2:
	return global_position + Vector2(0, -20.0) + Vector2(12.0, 0).rotated(_turret_angle)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.2, "speed": 1.3, "range": 1.0}

# ─── BESPOKE PROCEDURAL RENDERING ──────────────────────────────────────────

func _draw_custom_tower(color: Color) -> void:
	var t = _anim_time
	var is_firing = _recoil > 0.15

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, 6), 26.0, 15.0, 0.35)

	# 2. Tier 1 (Base Cylinder — The "1s" Place Bucket, Fast Rotation)
	var col_1s = Color("#00D4FF")
	CyberVectorCanvas.draw_iso_cylinder(
		self,
		Vector2.ZERO,
		18.0,
		6.0,
		Color("#1A1208"),
		Color("#0C0904"),
		Color(col_1s, 0.4),
		1.2,
		24
	)
	# 1s digit markings around perimeter
	var t1_rot = t * 2.5
	for i in range(4):
		var a = t1_rot + i * TAU / 4.0
		var pos_1s = Vector2(cos(a) * 15.0, sin(a) * 15.0 * SQUASH - 3.0)
		draw_circle(pos_1s, 1.2, Color(col_1s, 0.7))

	# 3. Tier 2 (Mid Cylinder — The "10s" Place Bucket, Medium Counter-Rotation)
	var col_10s = Color("#FFB800")
	var t2_y = -6.0
	CyberVectorCanvas.draw_iso_cylinder(
		self,
		Vector2(0, t2_y),
		13.0,
		6.0,
		Color("#25190C"),
		Color("#120C06"),
		Color(col_10s, 0.5),
		1.1,
		20
	)
	var t2_rot = -t * 1.5
	for i in range(3):
		var a = t2_rot + i * TAU / 3.0
		var pos_10s = Vector2(cos(a) * 10.5, sin(a) * 10.5 * SQUASH + t2_y - 3.0)
		draw_circle(pos_10s, 1.4, Color(col_10s, 0.8))

	# 4. Tier 3 (Crown Cylinder — The "100s" Place Bucket, Slow Rotation)
	var col_100s = Color("#FF5722")
	var t3_y = -12.0
	CyberVectorCanvas.draw_iso_cylinder(
		self,
		Vector2(0, t3_y),
		8.5,
		6.0,
		Color("#301E10"),
		Color("#170E08"),
		Color(col_100s, 0.6),
		1.0,
		16
	)
	var t3_rot = t * 0.8
	var pos_100s = Vector2(cos(t3_rot) * 6.5, sin(t3_rot) * 6.5 * SQUASH + t3_y - 3.0)
	draw_circle(pos_100s, 1.8, Color(col_100s, 0.9))

	# 5. Crown Pagoda Finial (Aperture Pointer)
	var aim_dir = Vector2.RIGHT.rotated(_turret_angle)
	var crown_center = Vector2(0, t3_y - 6.0)

	draw_circle(crown_center, 4.0, Color("#1A0E06"))
	draw_circle(crown_center, 3.0, Color(color, 0.8))
	draw_circle(crown_center, 1.2, Color.WHITE)

	# Emitter Pointer Horn
	var horn_tip = crown_center + aim_dir * 10.0
	draw_line(crown_center, horn_tip, Color("#4A2810"), 3.0)
	draw_line(crown_center, horn_tip, Color(color, 0.9), 1.2)
	draw_circle(horn_tip, 2.0, Color.WHITE)

	# 6. Multi-Pass Digit Orbitals when Firing
	if is_firing:
		draw_circle(horn_tip, 6.0 * _recoil, Color(color, 0.5))
		draw_circle(horn_tip, 2.5 * _recoil, Color.WHITE)
		# 3 color-coded concentric flash rings
		draw_arc(crown_center, 14.0 * _recoil, 0, TAU, 18, Color(col_1s, 0.6), 1.0)
		draw_arc(crown_center, 18.0 * _recoil, 0, TAU, 20, Color(col_10s, 0.6), 1.2)
		draw_arc(crown_center, 22.0 * _recoil, 0, TAU, 22, Color(col_100s, 0.6), 1.4)
