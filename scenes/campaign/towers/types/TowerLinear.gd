# TowerLinear.gd
# Linear Tower — closest targeting. Fires a straight scan-line projectile.
# REDESIGN: Radar sweep tower — cylindrical dish base with sweeping scan bar
# + energy emitter. Mechanic = pierce beam hits all in line (O(n) scan).

extends TowerBase

func get_type_id() -> String:
	return "tower_linear"

func _select_target() -> Node:
	_clean_targets()
	if targets.is_empty():
		return null
	return _get_closest(targets)

func _perform_attack() -> void:
	if targets.is_empty():
		return
	current_target = _get_closest(targets)
	if not current_target:
		return
	SoundManager.play_tower_attack(tower_id)
	_recoil = 1.0
	_flash_targets.clear()
	var spawn_origin = get_muzzle_position()
	var dir = (current_target.global_position - global_position).normalized()
	var p = {
		"pos": spawn_origin,
		"start_pos": spawn_origin,
		"draw_pos": spawn_origin,
		"beam_dir": dir,
		"speed": 520.0,
		"damage": damage * 0.7,
		"style": "linear_beam",
		"elapsed_time": 0.0,
		"traveled": 0.0,
		"max_range": attack_range,
		"hit_list": [],
		"falloff": 1.0,
		"decay": 0.8,
	}
	_spawn_custom_projectile(p)
	queue_redraw()

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.25, "speed": 1.0, "range": 1.2}

func _draw_base_geometry(color: Color, height: float) -> void:
	# Linear base: circular radar dish with scan lines and O(n) label
	var is_shadow = color.a < 0.5
	var dish_col = Color("#0D1A2E") if not is_shadow else Color("#0D131A")
	_draw_3d_cylinder(Vector2(0, 0), 16.0, height, dish_col, color, 1.5)
	if not is_shadow:
		# Concentric scan rings (radar)
		for ri in range(3):
			var rr = 5.0 + ri * 3.5
			var pts = PackedVector2Array()
			for i in range(24):
				var a = i * TAU / 24.0
				pts.append(Vector2(cos(a) * rr, sin(a) * rr * SQUASH))
			draw_polyline(pts, Color(color, 0.25 - ri * 0.06), 0.7)
		# Sweep line (rotates with anim_time)
		var sweep_a = fmod(_anim_time * 1.6, TAU)
		var r = 13.0
		var sx = cos(sweep_a) * r
		var sy = sin(sweep_a) * r * SQUASH
		draw_line(Vector2.ZERO, Vector2(sx, sy), Color(color, 0.5), 1.1)
		# Center hub
		draw_circle(Vector2.ZERO, 2.5, Color("#08111F"))
		draw_circle(Vector2.ZERO, 2.5, Color(color, 0.35), false, 0.8)
		draw_circle(Vector2.ZERO, 1.0, Color(color, 0.85))
		draw_circle(Vector2(-0.5, -0.3), 0.4, Color.WHITE)
		# O(n) label
		draw_string(ThemeDB.fallback_font, Vector2(-7, 5), "O(n)", HORIZONTAL_ALIGNMENT_CENTER, -1, 5, Color(color, 0.4))
	# Dish outline
	draw_arc(Vector2.ZERO, 16.0, 0, TAU, 26, color, 1.0 if not is_shadow else 0.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 9.0
	# Turret housing
	_draw_3d_box(Vector2(0, 0), Vector2(20, 2.5), 3.0, Color("#0A1426"), Color(color, 0.25), 1.0)
	# Emitter head with lens
	_draw_3d_box(Vector2(recoil, -1.5), Vector2(5.0, 2.8), 3.0, Color("#0F1F33"), color, 1.1)
	var lens = Vector2(4.5 + recoil, -1.5 * SQUASH)
	draw_circle(lens, 2.0, Color("#08111F"))
	draw_circle(lens, 2.0, Color(color, 0.4), false, 0.9)
	draw_circle(lens, 1.2, Color(color, 0.55))
	draw_circle(lens + Vector2(-0.4, -0.3), 0.5, Color.WHITE)
	# Barrel
	_draw_3d_cylinder(Vector2(4 + recoil, -1.5), 1.2, 6.5, Color("#1A2E4A"), Color(color, 0.25), 1.0)
	draw_circle(Vector2(10.5 + recoil, -1.5 * SQUASH), 0.8, Color.BLACK)
