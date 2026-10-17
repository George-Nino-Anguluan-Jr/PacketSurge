# TowerSelection.gd
# Selection Tower — selection sort. Repeatedly selects the lowest-HP enemy
# and fires a seeker that grows in damage with each consecutive kill it lands.
# BESPOKE DESIGN: The Orbital Min-Seeker Monolith
# A slender obsidian triangular obelisk crowned by a levitating mechanical
# eye with articulated targeting calipers. Ramps kill-streak chevrons along the spire.
extends TowerBase

var _kill_streak: int = 0
var _streak_target: Node = null

func get_type_id() -> String:
	return "tower_selection"

func _select_target() -> Node:
	_clean_targets()
	if targets.is_empty():
		return null
	return _get_lowest_hp(targets)

func _perform_attack() -> void:
	if targets.is_empty():
		return
	current_target = _get_lowest_hp(targets)
	if not current_target:
		return
	SoundManager.play_tower_attack(tower_id)
	_recoil = 1.0
	_flash_targets.clear()

	if _streak_target != current_target:
		_kill_streak = 0
	_streak_target = current_target
	var mult: float = 1.8 + _kill_streak * ramp_per_kill
	_spawn_projectile("selection_sniper", damage * mult, projectile_speed, current_target, {"on_hit": _on_selection_hit})

func _on_selection_hit(p: Dictionary) -> void:
	var t = p.get("target")
	if is_instance_valid(t) and t.is_dead:
		_kill_streak = mini(_kill_streak + 1, ramp_max)
		if t.has_method("show_floating_tag"):
			t.show_floating_tag("💀 EXECUTE!", Color("#FFD700"))
	else:
		_kill_streak = 0

func _get_custom_muzzle_position() -> Vector2:
	return global_position + Vector2(0, -18.0) + Vector2(16.0, 0).rotated(_turret_angle)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.35, "speed": 1.0, "range": 1.15}

# ─── BESPOKE PROCEDURAL RENDERING ──────────────────────────────────────────

func _draw_custom_tower(color: Color) -> void:
	var t = _anim_time
	var is_firing = _recoil > 0.2

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, 6), 24.0, 14.0, 0.4)

	# 2. Triangular Obsidian Platform Base
	CyberVectorCanvas.draw_iso_prism(
		self,
		Vector2.ZERO,
		Vector2(19.0, 14.0),
		7.0,
		Color("#1C0A0A"),
		Color("#0F0505"),
		Color(color, 0.4),
		1.3
	)

	# 3. Triangular Spire Body tapering upward
	var spire_h = 16.0
	var spire_pts_top = PackedVector2Array([
		Vector2(0, -spire_h - 10.0 * SQUASH),
		Vector2(7.0, -spire_h + 6.0 * SQUASH),
		Vector2(-7.0, -spire_h + 6.0 * SQUASH)
	])
	CyberVectorCanvas.draw_iso_prism(
		self,
		Vector2(0, -3.0),
		Vector2(10.0, 8.0),
		spire_h,
		Color("#280F0F"),
		Color("#140707"),
		Color(color, 0.5),
		1.0
	)

	# 4. Kill-Streak Notches (0..5) on Spire Face
	for i in range(ramp_max):
		var ny = -4.0 - i * 3.0
		var is_streak_active = i < _kill_streak
		var notch_col = Color("#FFB800") if is_streak_active else Color(color, 0.2)
		draw_line(Vector2(-4.0, ny), Vector2(4.0, ny), notch_col, 1.2)
		if is_streak_active:
			draw_circle(Vector2(5.5, ny), 1.0, Color.WHITE)

	# 5. Floating Omniscient Targeting Eye (Turns toward target)
	var eye_center = Vector2(0, -spire_h - 4.0)
	var aim_dir = Vector2.RIGHT.rotated(_turret_angle)

	# Eye housing sphere
	draw_circle(eye_center, 6.0, Color("#1A0808"))
	draw_circle(eye_center, 5.0, Color(color, 0.8))
	# Pupil tracking aim direction
	var pupil_pos = eye_center + aim_dir * 2.2
	draw_circle(pupil_pos, 2.8, Color("#4A0000"))
	draw_circle(pupil_pos, 1.4, Color.WHITE)

	# 6. Articulated Calipers (Targeting Claws)
	var claw_angle = _turret_angle
	var claw_rad = 9.0 + (3.0 * _recoil if is_firing else 0.0)
	for side in [-1, 1]:
		var ca = claw_angle + side * PI * 0.35
		var claw_tip = eye_center + Vector2(cos(ca), sin(ca)) * claw_rad
		draw_line(eye_center, claw_tip, Color(color, 0.7), 1.5)
		draw_line(claw_tip, claw_tip + aim_dir * 4.0, Color.WHITE, 1.2)

	# 7. Laser Muzzle Flare on Fire
	if is_firing:
		var flare_pos = eye_center + aim_dir * claw_rad
		draw_circle(flare_pos, 6.0 * _recoil, Color(color, 0.5))
		draw_circle(flare_pos, 2.5 * _recoil, Color.WHITE)
		draw_line(flare_pos, flare_pos + aim_dir * 30.0 * _recoil, Color(color, 0.8), 2.0)
