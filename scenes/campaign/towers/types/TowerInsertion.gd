# TowerInsertion.gd
# Insertion Tower — insertion sort "shift". Fires a needle that on impact
# PUSHES the target backward along the path (shifting elements) + applies DoT.
# BESPOKE DESIGN: The Ratchet Harpoon Ballista
# Features a grooved mechanical launch track with an exposed side ratchet cog.
# The tension arm draws backward, releasing a barbed staking needle that shunts enemies.
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
	_spawn_projectile("insertion_needle", damage, projectile_speed, current_target, {"on_hit": _insert_shift})

func _insert_shift(p: Dictionary) -> void:
	var target = p["target"]
	if is_instance_valid(target) and not target.is_dead and target.has_method("push_back"):
		target.push_back(40.0)
		if target.has_method("show_floating_tag"):
			target.show_floating_tag("⏪ SHIFT -40px", Color("#00FF88"))
		var aim = target.get_aim_point() if target.has_method("get_aim_point") else target.position
		_spawn_impact_explosion(aim, "insertion_needle", target)

func _get_custom_muzzle_position() -> Vector2:
	return global_position + Vector2(18.0, -8.0).rotated(_turret_angle)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.3, "speed": 1.15, "range": 1.0}

# ─── BESPOKE PROCEDURAL RENDERING ──────────────────────────────────────────

func _draw_custom_tower(color: Color) -> void:
	var t = _anim_time
	var is_firing = _recoil > 0.2

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, 6), 25.0, 15.0, 0.35)

	# 2. Heavy Rectangular Ballista Chassis
	CyberVectorCanvas.draw_iso_prism(
		self,
		Vector2.ZERO,
		Vector2(21.0, 14.0),
		6.0,
		Color("#0C1C19"),
		Color("#050E0C"),
		Color(color, 0.4),
		1.2
	)

	# 3. Serrated Insertion Gear Tracks on Top Face
	for i in range(5):
		var track_x = -12.0 + i * 6.0
		var tooth_pts = PackedVector2Array([
			Vector2(track_x - 1.5, 4.0 * SQUASH),
			Vector2(track_x + 1.5, 2.0 * SQUASH),
			Vector2(track_x + 1.5, 6.0 * SQUASH)
		])
		draw_colored_polygon(tooth_pts, Color(color, 0.3))

	# 4. Swiveling Ballista Turret & Harpoon Rail
	var aim_dir = Vector2.RIGHT.rotated(_turret_angle)
	var perp_dir = Vector2(-aim_dir.y, aim_dir.x)
	var recoil_dist = -_recoil * 8.0
	var turret_center = Vector2(0, -9.0) + aim_dir * recoil_dist

	# Center Pivot Drum
	CyberVectorCanvas.draw_iso_cylinder(
		self,
		turret_center,
		8.0,
		3.5,
		Color("#142A25"),
		Color("#081411"),
		Color(color, 0.5),
		1.0,
		16
	)

	# 5. Side Ratchet Cog Wheel (Rotates when loading tension)
	var cog_center = turret_center - perp_dir * 8.0
	var cog_rot = t * 6.0 + _recoil * 3.0
	draw_circle(cog_center, 4.0, Color("#1C3832"))
	for c in range(6):
		var ca = cog_rot + c * TAU / 6.0
		draw_line(cog_center, cog_center + Vector2(cos(ca), sin(ca)) * 5.0, Color(color, 0.8), 1.2)
	draw_circle(cog_center, 1.5, Color.WHITE)

	# 6. Harpoon Bow Arms & Guide Rail
	var rail_len = 20.0
	var rail_start = turret_center - aim_dir * 8.0
	var rail_end   = turret_center + aim_dir * rail_len
	draw_line(rail_start, rail_end, Color("#264A42"), 3.0)
	draw_line(rail_start, rail_end, Color(color, 0.7), 1.0)

	# Flexed Bow Arms
	var arm_spread = 12.0 * (0.8 if is_firing else 1.0)
	var left_arm_tip  = turret_center + aim_dir * 6.0 + perp_dir * arm_spread
	var right_arm_tip = turret_center + aim_dir * 6.0 - perp_dir * arm_spread
	draw_line(turret_center - aim_dir * 4.0, left_arm_tip, Color("#2E5C52"), 2.0)
	draw_line(turret_center - aim_dir * 4.0, right_arm_tip, Color("#2E5C52"), 2.0)

	# 7. Loaded Needle Harpoon (Diamond Barb Tip)
	var harpoon_tip = rail_end + aim_dir * (2.0 if not is_firing else 6.0)
	var barb_pts = PackedVector2Array([
		harpoon_tip + aim_dir * 4.0,
		harpoon_tip + perp_dir * 2.5,
		harpoon_tip - aim_dir * 3.0,
		harpoon_tip - perp_dir * 2.5
	])
	draw_colored_polygon(barb_pts, Color.WHITE)
	draw_colored_polygon(barb_pts, Color(color, 0.85))

	# 8. Muzzle Flash & Venom Corrosive Embers on Attack
	if is_firing:
		draw_circle(harpoon_tip, 5.0 * _recoil, Color(color, 0.5))
		draw_circle(harpoon_tip, 2.0 * _recoil, Color.WHITE)
		for sp in range(4):
			var spark_offset = Vector2(randf_range(-6, 6), randf_range(-6, 6))
			draw_circle(harpoon_tip + spark_offset, 1.0, Color(color, 0.7))
