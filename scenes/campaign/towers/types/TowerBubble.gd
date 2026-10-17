# TowerBubble.gd
# Bubble Tower — bubble sort swap pass. Fires pulse orbs at two adjacent
# enemies; on impact the targets SWAP places along the path (a bubble pass).
# BESPOKE DESIGN: The Dual-Rotor Gyro Centrifuge
# Features twin counter-rotating gyroscopic brass rings around a spherical
# plasma containment chamber. Locks horizontally to fire double-helix swapping pulses.
extends TowerBase

func get_type_id() -> String:
	return "tower_bubble"

func _perform_attack() -> void:
	if targets.is_empty():
		return
	current_target = targets[0]
	SoundManager.play_tower_attack(tower_id)
	_recoil = 1.0
	_flash_targets.clear()

	var sorted = _get_enemies_sorted_by_progress()
	if sorted.size() >= 2:
		var a: Node = sorted[0]
		var b: Node = sorted[1]
		_spawn_projectile("bubble_pulse", damage * 0.8, projectile_speed, a)
		_spawn_projectile("bubble_pulse", damage * 0.8, projectile_speed, b, {
			"on_hit": _bubble_swap,
			"swap_a": a,
			"swap_b": b,
		})
	else:
		_spawn_projectile("bubble_pulse", damage * 0.8, projectile_speed, current_target, {"on_hit": _bubble_pop})

func _bubble_swap(p: Dictionary) -> void:
	var a = p.get("swap_a")
	var b = p.get("swap_b")
	if is_instance_valid(a) and is_instance_valid(b) and not a.is_dead and not b.is_dead:
		var mid: Vector2 = (a.position + b.position) * 0.5
		_spawn_impact_explosion(mid, "bubble_pulse", null)
		if a.has_method("show_floating_tag"):
			a.show_floating_tag("🔄 SWAP!", Color("#FFB800"))
		if b.has_method("show_floating_tag"):
			b.show_floating_tag("🔄 SWAP!", Color("#FFB800"))
		a.swap_progress(b)

func _bubble_pop(p: Dictionary) -> void:
	var track: Node = p["target"] if is_instance_valid(p.get("target")) else null
	_spawn_impact_explosion(p["target_last_pos"], "bubble_pulse", track)

func _get_custom_muzzle_position() -> Vector2:
	return global_position + Vector2(0, -16.0)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.25, "speed": 1.0, "range": 1.2}

# ─── BESPOKE PROCEDURAL RENDERING ──────────────────────────────────────────

func _draw_custom_tower(color: Color) -> void:
	var t = _anim_time
	var is_firing = _recoil > 0.2

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, 6), 25.0, 15.0, 0.35)

	# 2. Circular Brass Platform Drum
	CyberVectorCanvas.draw_iso_cylinder(
		self,
		Vector2.ZERO,
		18.0,
		6.0,
		Color("#1C1608"),
		Color("#0F0C04"),
		Color(color, 0.4),
		1.2,
		24
	)

	# 3. Outer Static Gimbal Base Ring
	draw_arc(Vector2(0, -6.0), 16.0, 0, TAU, 32, Color(color, 0.25), 1.5)

	# 4. Twin Counter-Rotating Gyroscope Rings (Centrifuge)
	var gyro_rot_1 = t * 2.0 if not is_firing else 0.0
	var gyro_rot_2 = -t * 2.0 if not is_firing else PI * 0.5

	# Outer Ring
	CyberVectorCanvas.draw_orbital_ring(
		self,
		Vector2(0, -14.0),
		14.0,
		6.0,
		gyro_rot_1,
		Color(color, 0.8),
		1.8
	)

	# Inner Ring
	CyberVectorCanvas.draw_orbital_ring(
		self,
		Vector2(0, -14.0),
		10.0,
		4.5,
		gyro_rot_2,
		Color(color.lightened(0.2), 0.7),
		1.2
	)

	# 5. Central Plasma Bubble Core (Translucent Shifting Sphere)
	var bubble_pulse = 0.8 + sin(t * 6.0) * 0.2
	var core_rad = 5.5 * (1.2 if is_firing else 1.0)
	var core_col = Color(color, bubble_pulse * 0.6)

	draw_circle(Vector2(0, -14.0), core_rad + 3.0, Color(color, 0.2))
	draw_circle(Vector2(0, -14.0), core_rad, core_col)
	draw_circle(Vector2(-1.5, -15.5), 1.8, Color.WHITE)

	# 6. Twin Orbital Bubble Chambers on Outer Ring
	var b1_pos = Vector2(cos(gyro_rot_1) * 14.0, sin(gyro_rot_1) * 6.0 - 14.0)
	var b2_pos = Vector2(-cos(gyro_rot_1) * 14.0, -sin(gyro_rot_1) * 6.0 - 14.0)

	draw_circle(b1_pos, 3.2, Color("#2A200A"))
	draw_circle(b1_pos, 2.5, color)
	draw_circle(b1_pos, 1.0, Color.WHITE)

	draw_circle(b2_pos, 3.2, Color("#2A200A"))
	draw_circle(b2_pos, 2.5, color)
	draw_circle(b2_pos, 1.0, Color.WHITE)

	# 7. Muzzle Swap Discharge Flash
	if is_firing:
		draw_arc(Vector2(0, -14.0), 18.0 * _recoil, 0, TAU, 24, Color(color, 0.7), 2.0)
		draw_line(b1_pos, b2_pos, Color.WHITE, 1.5)
