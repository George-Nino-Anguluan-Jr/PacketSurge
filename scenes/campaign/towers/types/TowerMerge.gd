# TowerMerge.gd
# Merge Tower — closest targeting. Fires two converging beams from left/right.
# BESPOKE DESIGN: The Twin-Beam Optical Collider
# A heavy circular collider base with two distinct angled emitter horns (Left: Cobalt Blue,
# Right: Violet). Fires twin helical energy ribbons that fuse on impact.
extends TowerBase

func get_type_id() -> String:
	return "tower_merge"

func _select_target() -> Node:
	_clean_targets()
	if not targets.is_empty():
		return _get_closest(targets)
	var candidates: Array = []
	if is_inside_tree():
		candidates = get_tree().get_nodes_in_group("enemies")
	for e in candidates:
		if is_instance_valid(e) and not e.is_dead and global_position.distance_to(e.global_position) <= attack_range + 35.0:
			return e
	return null

func _perform_attack() -> void:
	if not current_target:
		return
	SoundManager.play_tower_attack(tower_id)
	_recoil = 1.0
	_flash_targets.clear()

	var aim_dir = (current_target.global_position - global_position).normalized()
	var perp_dir = Vector2(-aim_dir.y, aim_dir.x)
	var spawn_origin = get_muzzle_position()

	var offset_l = -perp_dir * 11.0
	var offset_r = perp_dir * 11.0

	for offset in [offset_l, offset_r]:
		var side_str = "left" if offset == offset_l else "right"
		var p = {
			"pos": spawn_origin + offset,
			"start_pos": spawn_origin + offset,
			"draw_pos": spawn_origin + offset,
			"target": current_target,
			"target_last_pos": current_target.global_position,
			"speed": projectile_speed,
			"damage": damage * 0.65,
			"style": "merge_beam",
			"elapsed_time": 0.0,
			"total_dist": (current_target.global_position - spawn_origin).length(),
			"merge_side": side_str,
			"armor_pierce": armor_pierce,
		}
		_spawn_custom_projectile(p)
	queue_redraw()

func _on_style_impact(p: Dictionary) -> void:
	if p.get("style") == "merge_beam" and p.get("merge_side") == "left":
		var target = p.get("target")
		if is_instance_valid(target) and not target.is_dead and target.has_method("show_floating_tag"):
			target.show_floating_tag("⚛ [L]+[R] MERGE!", Color("#E040FB"))

func _get_custom_muzzle_position() -> Vector2:
	return global_position + Vector2(16.0, 0.0).rotated(_turret_angle)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.3, "speed": 1.0, "range": 1.15}

# ─── BESPOKE PROCEDURAL RENDERING ──────────────────────────────────────────

func _draw_custom_tower(color: Color) -> void:
	var t = _anim_time
	var is_firing = _recoil > 0.2

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, 6), 26.0, 15.0, 0.35)

	# 2. Circular Collider Base Drum
	CyberVectorCanvas.draw_iso_cylinder(
		self,
		Vector2.ZERO,
		18.0,
		7.0,
		Color("#101528"),
		Color("#080B14"),
		Color(color, 0.4),
		1.2,
		24
	)

	# 3. Rotating Turret with Twin Inward-Angled Emitter Horns
	var aim_dir = Vector2.RIGHT.rotated(_turret_angle)
	var perp_dir = Vector2(-aim_dir.y, aim_dir.x)
	var recoil_offset = -aim_dir * _recoil * 6.0
	var turret_center = Vector2(0, -9.0) + recoil_offset

	# Central Optical Hub
	CyberVectorCanvas.draw_iso_cylinder(
		self,
		turret_center,
		8.5,
		4.0,
		Color("#1A203A"),
		Color("#0B0E1B"),
		Color(color, 0.6),
		1.0,
		18
	)

	# 4. Central Fusion Prism Core
	var fusion_pulse = 0.7 + sin(t * 6.0) * 0.3
	draw_circle(turret_center, 4.5, Color(color, 0.4))
	draw_circle(turret_center, 3.0, Color(color, fusion_pulse))
	draw_circle(turret_center, 1.2, Color.WHITE)

	# 5. Left and Right Converging Emitter Horns
	var horn_spread = 9.0
	var horn_len = 16.0
	var h1_base = turret_center + perp_dir * horn_spread
	var h1_tip  = h1_base + aim_dir * horn_len - perp_dir * 2.5
	var h2_base = turret_center - perp_dir * horn_spread
	var h2_tip  = h2_base + aim_dir * horn_len + perp_dir * 2.5

	# Left Emitter (Cobalt Blue: #00D4FF)
	draw_line(h1_base, h1_tip, Color("#1A3A5A"), 3.0)
	draw_line(h1_base, h1_tip, Color("#00D4FF", 0.8), 1.2)
	draw_circle(h1_tip, 2.2, Color("#00D4FF"))
	draw_circle(h1_tip, 1.0, Color.WHITE)

	# Right Emitter (Violet: #9B59B6)
	draw_line(h2_base, h2_tip, Color("#3A1A5A"), 3.0)
	draw_line(h2_base, h2_tip, Color("#9B59B6", 0.8), 1.2)
	draw_circle(h2_tip, 2.2, Color("#9B59B6"))
	draw_circle(h2_tip, 1.0, Color.WHITE)

	# 6. Converging Energy Arcs between Horns and Central Fusion Core
	draw_line(h1_base, turret_center, Color("#00D4FF", 0.5), 1.0)
	draw_line(h2_base, turret_center, Color("#9B59B6", 0.5), 1.0)

	# 7. Muzzle Discharge Fusion Flare
	if is_firing:
		draw_line(h1_tip, turret_center + aim_dir * (horn_len + 6.0), Color("#00D4FF"), 2.0)
		draw_line(h2_tip, turret_center + aim_dir * (horn_len + 6.0), Color("#9B59B6"), 2.0)
		draw_circle(turret_center + aim_dir * (horn_len + 6.0), 6.0 * _recoil, Color.WHITE)
