# TowerCounting.gd
# Count Tower — counting sort. Fires 1..N numbered pellets, where N is the
# number of enemies counted in range (one pellet per enemy, capped at 6).
# BESPOKE DESIGN: The Rotary Tally Gatling
# Features a heavy industrial hexagonal base with an illuminated frequency tally display
# and an articulated 6-barrel rotary minigun drum that spins up to fire rapid counting volleys.
extends TowerBase

var _spin_angle: float = 0.0

func get_type_id() -> String:
	return "tower_counting"

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

	var tallied_enemies: int = _count_live_enemies()
	var spawn_origin = get_muzzle_position()
	# Base 5-pellet minigun volley; scales with swarm count
	var pellet_count: int = clamp(4 + clampi(tallied_enemies - 1, 0, 4), 4, 8)
	var pellet_damage = (damage * 0.28) * (1.0 + (tallied_enemies - 1) * bonus_per_enemy)

	if current_target.has_method("show_floating_tag"):
		current_target.show_floating_tag("TALLY x%d!" % max(1, tallied_enemies), Color("#00E5FF"))

	for i in range(pellet_count):
		var p = {
			"pos": spawn_origin,
			"start_pos": spawn_origin,
			"draw_pos": spawn_origin,
			"target": current_target,
			"target_last_pos": current_target.global_position,
			"speed": projectile_speed * (0.9 + i * 0.06),
			"damage": pellet_damage,
			"style": "counting_pellet",
			"elapsed_time": 0.0,
			"digit": i + 1,
			"delay": i * 0.04,
			"armor_pierce": armor_pierce,
		}
		_spawn_custom_projectile(p)
	queue_redraw()

func _count_live_enemies() -> int:
	var list: Array = []
	if is_inside_tree():
		list = get_tree().get_nodes_in_group("enemies")
	if list.is_empty():
		list = targets
	var n: int = 0
	for e in list:
		if is_instance_valid(e) and not e.is_dead:
			n += 1
	return n

func _get_custom_muzzle_position() -> Vector2:
	return global_position + Vector2(18.0, 0.0).rotated(_turret_angle)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.2, "speed": 1.25, "range": 1.0}

# ─── BESPOKE PROCEDURAL RENDERING ──────────────────────────────────────────

func _draw_custom_tower(color: Color) -> void:
	var t = _anim_time
	var is_firing = _recoil > 0.15
	var enemy_count = clamp(_count_live_enemies(), 0, max_targets)

	# Barrel spin animation (accelerates on fire)
	var spin_speed = 18.0 if is_firing else 2.5
	_spin_angle += get_process_delta_time() * spin_speed if is_inside_tree() else 0.0

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, 6), 25.0, 15.0, 0.35)

	# 2. Hexagonal Rotary Turntable Base
	CyberVectorCanvas.draw_iso_hexagon(
		self,
		Vector2.ZERO,
		19.0,
		6.0,
		Color("#0C1C18"),
		Color("#050F0D"),
		Color(color, 0.4),
		1.2
	)

	# 3. Illuminated Digital LED Frequency Tally Bar on Base Top
	for i in range(6):
		var tx = -11.0 + i * 4.4
		var is_tallied = i < enemy_count
		var slot_rect = Rect2(Vector2(tx - 1.5, 3.5 * SQUASH), Vector2(3.0, 4.0 * SQUASH))
		draw_rect(slot_rect, Color("#040B0A"), true)
		var led_col = color if is_tallied else Color(color, 0.15)
		draw_rect(slot_rect, led_col, false, 0.8)
		if is_tallied:
			draw_circle(Vector2(tx, 5.5 * SQUASH), 1.0, Color.WHITE)

	# 4. Swiveling Gatling Carriage & Feed Hopper
	var aim_dir = Vector2.RIGHT.rotated(_turret_angle)
	var perp_dir = Vector2(-aim_dir.y, aim_dir.x)
	var recoil_offset = -aim_dir * _recoil * 5.0
	var turret_center = Vector2(0, -9.0) + recoil_offset

	# Heavy Turret Trunnion
	CyberVectorCanvas.draw_iso_cylinder(
		self,
		turret_center,
		8.5,
		3.5,
		Color("#132A24"),
		Color("#091612"),
		Color(color, 0.5),
		1.0,
		16
	)

	# Ammo Drum Hopper on side
	var drum_pos = turret_center - perp_dir * 7.0
	draw_circle(drum_pos, 4.0, Color("#1A3830"))
	draw_circle(drum_pos, 3.2, Color(color, 0.6))
	draw_circle(drum_pos, 1.2, Color.WHITE)

	# 5. The 6-Barrel Rotary Minigun Drum
	var barrel_cluster_rad = 4.5
	var barrel_len = 16.0
	var barrel_count = 6

	# Center rotor axis
	var muzzle_center = turret_center + aim_dir * barrel_len
	draw_line(turret_center, muzzle_center, Color("#1E3F36"), 4.0)

	# 6 individual barrels positioned around rotating perimeter
	for b in range(barrel_count):
		var ba = _spin_angle + b * TAU / float(barrel_count)
		var b_offset = perp_dir * cos(ba) * barrel_cluster_rad + Vector2.UP * sin(ba) * barrel_cluster_rad * 0.6
		var b_start = turret_center + b_offset
		var b_end   = b_start + aim_dir * barrel_len

		# Barrel pipe
		draw_line(b_start, b_end, Color("#264F44"), 2.0)
		draw_line(b_start, b_end, Color(color, 0.7), 0.8)

		# Muzzle tip hole
		draw_circle(b_end, 1.2, Color.BLACK)
		if is_firing and b % 2 == 0:
			draw_circle(b_end, 2.0, Color(color, 0.8))

	# Front retaining clamp ring
	draw_circle(muzzle_center, barrel_cluster_rad + 1.5, Color(color, 0.3), false, 1.2)

	# 6. Rotary Muzzle Flash on Attack
	if is_firing:
		draw_circle(muzzle_center, 7.0 * _recoil, Color(color, 0.5))
		draw_circle(muzzle_center, 3.0 * _recoil, Color.WHITE)
		for sp in range(5):
			var sp_dir = aim_dir.rotated(randf_range(-0.4, 0.4))
			draw_line(muzzle_center, muzzle_center + sp_dir * 12.0 * _recoil, Color.WHITE, 1.2)
