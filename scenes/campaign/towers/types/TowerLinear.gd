# TowerLinear.gd
# Linear Tower — closest targeting. Fires a straight scan-line projectile.
# BESPOKE DESIGN: The Phased-Array Radar Scanner
# An articulated wide parabolic antenna dish mounted on a command pedestal.
# Features a 7-diode emitter bar that ripples sequentially before unleashing
# a sweeping planar fan beam across the entire forward sector.
extends TowerBase

func get_type_id() -> String:
	return "tower_linear"

func _select_target() -> Node:
	_clean_targets()
	if not targets.is_empty():
		return _get_closest(targets)
	var candidates: Array = []
	if is_inside_tree():
		candidates = get_tree().get_nodes_in_group("enemies")
	for e in candidates:
		if is_instance_valid(e) and not e.is_dead and global_position.distance_to(e.global_position) <= attack_range + 40.0:
			return e
	return null

func _perform_attack() -> void:
	_clean_targets()
	current_target = _select_target()
	if not current_target:
		return
	SoundManager.play_tower_attack(tower_id)
	_recoil = 1.0
	_flash_targets.clear()

	var spawn_origin = get_muzzle_position()
	var dir = (current_target.global_position - spawn_origin).normalized() if (current_target.global_position - spawn_origin).length() > 0 else Vector2.RIGHT.rotated(_turret_angle)
	var p = {
		"pos": spawn_origin,
		"start_pos": spawn_origin,
		"draw_pos": spawn_origin,
		"target": current_target,
		"target_last_pos": current_target.global_position,
		"beam_dir": dir,
		"speed": projectile_speed,
		"damage": damage * 0.85,
		"style": "linear_beam",
		"elapsed_time": 0.0,
		"traveled": 0.0,
		"max_range": attack_range + 60.0,
		"beam_width": 22.0, # 44px wide crisp radar scan bar matching road width
		"hit_list": [],
		"falloff": 1.0,
		"decay": 0.88,
		"armor_pierce": armor_pierce,
		"max_hits": 999, # Pierces all enemies along the sweeping scan line
	}
	_spawn_custom_projectile(p)
	queue_redraw()

func _get_custom_muzzle_position() -> Vector2:
	return global_position + Vector2(18.0, 0.0).rotated(_turret_angle)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.25, "speed": 1.0, "range": 1.2}

# ─── BESPOKE PROCEDURAL RENDERING ──────────────────────────────────────────

func _draw_custom_tower(color: Color) -> void:
	var t = _anim_time
	var is_firing = _recoil > 0.2

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, 6), 26.0, 15.0, 0.35)

	# 2. Command Station Pedestal Base
	CyberVectorCanvas.draw_iso_cylinder(
		self,
		Vector2.ZERO,
		18.0,
		6.0,
		Color("#111920"),
		Color("#090E13"),
		Color(color, 0.4),
		1.2,
		24
	)

	# 3. Concentric Radar Rings on Pedestal Top
	for r in [6.0, 11.0, 15.0]:
		draw_arc(Vector2(0, -6.0), r, 0, TAU, 24, Color(color, 0.18), 1.0)

	# Rotating radar sweep line on base
	var sweep_ang = fmod(t * 2.0, TAU)
	draw_line(Vector2(0, -6.0), Vector2(cos(sweep_ang) * 14.0, sin(sweep_ang) * 14.0 * SQUASH - 6.0), Color(color, 0.4), 1.0)

	# 4. Swiveling Radar Mast & Parabolic Dish (Tracks Target)
	var aim_dir = Vector2.RIGHT.rotated(_turret_angle)
	var perp_dir = Vector2(-aim_dir.y, aim_dir.x)
	var recoil_offset = -aim_dir * _recoil * 6.0
	var turret_center = Vector2(0, -10.0) + recoil_offset

	# Central Radar Hub
	CyberVectorCanvas.draw_iso_cylinder(
		self,
		turret_center,
		7.0,
		4.0,
		Color("#1A242E"),
		Color("#0C1319"),
		Color(color, 0.5),
		1.0,
		16
	)

	# 5. Wide Curved Parabolic Antenna Dish
	var dish_width = 24.0
	var dish_depth = 8.0
	var dish_pts = PackedVector2Array()
	var segs = 12

	# Arc of curved dish facing aim_dir
	for i in range(segs + 1):
		var frac = float(i) / float(segs) - 0.5 # -0.5 to 0.5
		var along_perp = frac * dish_width
		var along_aim  = (1.0 - (frac * 2.0) * (frac * 2.0)) * dish_depth
		dish_pts.append(turret_center + perp_dir * along_perp + aim_dir * along_aim)

	# Draw parabolic antenna reflector mesh
	draw_polyline(dish_pts, Color("#263748"), 4.0)
	draw_polyline(dish_pts, Color(color, 0.8), 1.5)

	# 6. Emitter Diodes on Dish Rim (Ripple sequentially like linear search)
	for i in range(7):
		var frac = float(i) / 6.0 - 0.5
		var along_perp = frac * dish_width * 0.9
		var along_aim  = (1.0 - (frac * 2.0) * (frac * 2.0)) * dish_depth
		var diode_pos = turret_center + perp_dir * along_perp + aim_dir * along_aim

		# Sequential diode lighting
		var diode_step = int(fmod(t * 10.0, 7.0))
		var is_diode_lit = (i == diode_step) or is_firing
		draw_circle(diode_pos, 1.8, Color.WHITE if is_diode_lit else Color(color, 0.4))
		if is_diode_lit:
			draw_circle(diode_pos, 3.0, Color(color, 0.6))

	# 7. Feed Horn Transmitter (Forward of the Dish)
	var horn_pos = turret_center + aim_dir * 14.0
	draw_line(turret_center, horn_pos, Color("#1A2836"), 2.0)
	draw_circle(horn_pos, 2.5, Color.WHITE)
	draw_circle(horn_pos, 4.0, Color(color, 0.5))

	# 8. Muzzle Laser Fan Flare on Attack
	if is_firing:
		# Wide forward fan flash
		var fan_left  = horn_pos + aim_dir * 25.0 + perp_dir * 15.0
		var fan_right = horn_pos + aim_dir * 25.0 - perp_dir * 15.0
		var fan_poly = PackedVector2Array([horn_pos, fan_left, fan_right])
		draw_colored_polygon(fan_poly, Color(color, 0.3 * _recoil))
		draw_line(horn_pos, horn_pos + aim_dir * 35.0, Color.WHITE, 2.0)
