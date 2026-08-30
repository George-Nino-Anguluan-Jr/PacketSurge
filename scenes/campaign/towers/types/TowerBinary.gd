# TowerBinary.gd
# Binary Tower — divide & conquer. Fires a high-damage sniper shot at the
# median enemy, then the bolt splits, damaging both halves of the group.
# REDESIGN: Long-range divide-and-conquer observatory — sniper deck with
# rangefinder trench, binary 0/1 scope. 3D isometric intact.

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
		"target_last_pos": current_target.position,
		"speed": 450.0,
		"damage": damage * 2.2,
		"style": "binary_sniper",
		"elapsed_time": 0.0,
		"total_dist": (current_target.position - spawn_origin).length(),
		"on_hit": _binary_split,
	}
	_spawn_custom_projectile(p)
	queue_redraw()

func _binary_split(p: Dictionary) -> void:
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
			e.take_damage(split_dmg, tower_id)
			var aim = e.get_aim_point() if e.has_method("get_aim_point") else e.position
			_spawn_impact_explosion(aim, "binary_sniper", e)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.4, "speed": 1.0, "range": 1.1}

func _draw_base_geometry(color: Color, height: float) -> void:
	# Binary base: clean platform with a divide line and 0/1 labels
	var is_shadow = color.a < 0.5
	var deck_col = Color("#0D1A2E") if not is_shadow else Color("#0D131A")
	_draw_3d_box(Vector2(0, 0), Vector2(24, 14), height, deck_col, color, 1.5)
	if not is_shadow:
		# Divide line down the center
		draw_line(Vector2(0, -11 * SQUASH), Vector2(0, 11 * SQUASH), Color(color, 0.35), 1.0)
		# Left half label "0", right half label "1"
		draw_string(ThemeDB.fallback_font, Vector2(-8, -2), "0", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(color, 0.35))
		draw_string(ThemeDB.fallback_font, Vector2(4, -2), "1", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(color, 0.35))
		# Binary tick marks along top
		for i in range(7):
			var tx = -15 + i * 5.0
			var bit = "0" if i % 2 == 0 else "1"
			draw_string(ThemeDB.fallback_font, Vector2(tx - 1, -8 * SQUASH), bit, HORIZONTAL_ALIGNMENT_CENTER, -1, 5, Color(color, 0.3))
		# Corner markers
		for corner in [Vector2(-24, -14 * SQUASH), Vector2(24, -14 * SQUASH), Vector2(-24, 14 * SQUASH), Vector2(24, 14 * SQUASH)]:
			draw_circle(corner, 1.0, Color(color, 0.25))
	# Slab outline
	draw_polyline(PackedVector2Array([
		Vector2(-24, -14 * SQUASH), Vector2(24, -14 * SQUASH),
		Vector2(24, 14 * SQUASH), Vector2(-24, 14 * SQUASH),
		Vector2(-24, -14 * SQUASH)
	]), color, 1.0 if not is_shadow else 0.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 12.0
	var is_firing = _recoil > 0.3
	# Rear housing
	_draw_3d_box(Vector2(-5, 0), Vector2(8, 6.0), 7.0, Color("#0F1F33"), color, 1.3)
	# Long sniper barrel
	_draw_3d_cylinder(Vector2(6 + recoil, 0), 2.8, 18.0, Color("#1A2E4A"), color, 1.1)
	# Focus ring
	_draw_3d_cylinder(Vector2(2 + recoil, 0), 4.0, 2.0, Color("#0D1A2E"), color, 0.9)
	# Muzzle brake slots
	var muzzle = Vector2(24.0 + recoil, 0)
	draw_circle(muzzle, 2.5, Color.BLACK)
	draw_circle(muzzle, 3.2, Color(color, 0.3), false, 0.9)
	draw_circle(muzzle, 1.0, Color(color, 0.9))
	if is_firing:
		draw_circle(muzzle, 4.0, Color(color, 0.3))
		draw_circle(muzzle, 1.5, Color.WHITE)
	# Crosshair reticle
	var ch = 3.5
	var cx = 0 + recoil
	draw_line(Vector2(cx, -ch), Vector2(cx, ch), Color(color, 0.8), 1.2)
	draw_line(Vector2(cx - ch, 0), Vector2(cx + ch, 0), Color(color, 0.8), 1.2)
	draw_circle(Vector2(cx, 0), 1.0, Color(color, 0.85))
	draw_circle(Vector2(cx, 0), ch + 1.0, Color(color, 0.2), false, 0.6)
