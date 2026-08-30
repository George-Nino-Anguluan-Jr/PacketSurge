# TowerRadix.gd
# Radix Tower — radix sort buckets. Fires 3 digit orbs (1, 10, 100) each
# sorted into a different "bucket" = each orb targets a different enemy,
# distributing damage place-value style across the group.
# REDESIGN: Digit sorter drum — cylindrical base with 3 bucket levels + orbital
# digit rings. Mechanic = place-value bucket distribution (1s/10s/100s).

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
			"target_last_pos": t.position if is_instance_valid(t) else spawn_origin,
			"speed": 320.0,
			"damage": damage * 0.4,
			"style": "radix_digit",
			"elapsed_time": 0.0,
			"digit": digits[i],
			"delay": i * 0.08
		}
		_spawn_custom_projectile(p)
	queue_redraw()

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.2, "speed": 1.3, "range": 1.0}

func _draw_base_geometry(color: Color, height: float) -> void:
	# Radix base: circular drum with 3 concentric bucket rings labeled 1, 10, 100
	var is_shadow = color.a < 0.5
	var drum_col = Color("#0D1A2E") if not is_shadow else Color("#0D131A")
	_draw_3d_cylinder(Vector2(0, 0), 18.0, height, drum_col, color, 1.5)
	if not is_shadow:
		# 3 bucket rings — concentric with labels
		var bucket_cols = [Color("#00D4FF"), Color("#FFB800"), Color("#FF4D8D")]
		var labels = ["1", "10", "100"]
		for ri in range(3):
			var rr = 6.0 + ri * 3.5
			var pts = PackedVector2Array()
			for i in range(22):
				var a = i * TAU / 22.0
				pts.append(Vector2(cos(a) * rr, sin(a) * rr * SQUASH))
			draw_polyline(pts, Color(bucket_cols[ri], 0.25), 0.9)
			# Label at top
			var ly = -rr * SQUASH
			var off = -2 if ri < 2 else -5
			draw_string(ThemeDB.fallback_font, Vector2(off, ly - 1), labels[ri], HORIZONTAL_ALIGNMENT_CENTER, -1, 5, Color(bucket_cols[ri], 0.6))
		# Center hub
		draw_circle(Vector2.ZERO, 2.5, Color("#08111F"))
		draw_circle(Vector2.ZERO, 2.5, Color(color, 0.3), false, 0.8)
		draw_circle(Vector2.ZERO, 1.0, Color(color, 0.8))
		draw_circle(Vector2(-0.4, -0.3), 0.4, Color.WHITE)
	# Drum outline
	draw_arc(Vector2.ZERO, 18.0, 0, TAU, 28, color, 1.0 if not is_shadow else 0.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 6.0
	var t = _anim_time
	# Central digit core
	draw_circle(Vector2.ZERO, 4.5, Color(color, 0.15))
	_draw_3d_sphere(Vector2(0, 0), 3.8, color)
	# 3 orbital digit rings with colored beads
	var bucket_cols = [Color("#00D4FF"), Color("#FFB800"), Color("#FF4D8D")]
	var labels = ["1", "10", "100"]
	for ri in range(3):
		var rr = 7.5 + ri * 2.2
		var rot = t * (0.7 + ri * 0.35) + ri * 1.2
		# Ring
		var pts = PackedVector2Array()
		for i in range(18):
			var a = i * TAU / 18.0 + rot
			pts.append(Vector2(cos(a) * rr, sin(a) * rr * SQUASH))
		draw_polyline(pts, Color(bucket_cols[ri], 0.2), 0.9)
		# Orbiting bead
		var bx = cos(rot) * rr
		var by = sin(rot) * rr * SQUASH
		draw_circle(Vector2(bx, by), 1.5, Color(bucket_cols[ri], 0.85))
		draw_circle(Vector2(bx, by), 0.6, Color.WHITE)
	# Emitter barrel
	_draw_3d_cylinder(Vector2(5 + recoil, 0), 2.0, 7.0, Color("#1A2E4A"), color, 1.0)
	var muzz = Vector2(12.0 + recoil, 0)
	draw_circle(muzz, 1.6, Color.BLACK)
	draw_circle(muzz, 0.7, Color(color, 0.9))
	if _recoil > 0.3:
		draw_circle(muzz, 3.5, Color(color, 0.2))
