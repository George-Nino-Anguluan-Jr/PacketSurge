# TowerMerge.gd
# Merge Tower — closest targeting. Fires two converging beams from left/right.
# REDESIGN: Converging foundry — large drum base with twin intake hoppers that
# merge into a single emitter. Mechanic = twin beams merging = merge sort.

extends TowerBase

func get_type_id() -> String:
	return "tower_merge"

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
	var spawn_origin = get_muzzle_position()
	var offset_l = Vector2(-6, -6).rotated(_turret_angle)
	var offset_r = Vector2(-6, 6).rotated(_turret_angle)
	for offset in [offset_l, offset_r]:
		var p = {
			"pos": spawn_origin + offset,
			"start_pos": spawn_origin + offset,
			"draw_pos": spawn_origin + offset,
			"target": current_target,
			"target_last_pos": current_target.position,
			"speed": 260.0,
			"damage": damage * 0.6,
			"style": "merge_beam",
			"elapsed_time": 0.0,
			"total_dist": (current_target.position - spawn_origin).length(),
			"merge_side": "left" if offset == offset_l else "right"
		}
		_spawn_custom_projectile(p)
	queue_redraw()

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.3, "speed": 1.0, "range": 1.15}

func _draw_base_geometry(color: Color, height: float) -> void:
	# Merge base: circular drum with two intake arrows converging to center
	var is_shadow = color.a < 0.5
	var drum_col = Color("#0D1A2E") if not is_shadow else Color("#0D131A")
	_draw_3d_cylinder(Vector2(0, 0), 18.0, height, drum_col, color, 1.5)
	if not is_shadow:
		# Two converging arrows from top-left and top-right to center
		var arrow_l_start = Vector2(-12, -10 * SQUASH)
		var arrow_r_start = Vector2(12, -10 * SQUASH)
		var center = Vector2(0, 2 * SQUASH)
		# Left arrow
		draw_line(arrow_l_start, center, Color(color, 0.4), 1.0)
		draw_line(center, center + Vector2(-1.5, -1.2), Color(color, 0.5), 0.9)
		draw_line(center, center + Vector2(-1.5, 1.2), Color(color, 0.5), 0.9)
		# Right arrow
		draw_line(arrow_r_start, center, Color(color, 0.4), 1.0)
		draw_line(center, center + Vector2(1.5, -1.2), Color(color, 0.5), 0.9)
		draw_line(center, center + Vector2(1.5, 1.2), Color(color, 0.5), 0.9)
		# Merge point glow
		draw_circle(center, 2.5, Color(color, 0.25))
		draw_circle(center, 1.2, Color(color, 0.8))
		# Outer ring
		draw_arc(Vector2.ZERO, 14.0, 0, TAU, 22, Color(color, 0.15), 0.7)
	# Drum outline
	draw_arc(Vector2.ZERO, 18.0, 0, TAU, 28, color, 1.0 if not is_shadow else 0.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 7.0
	# Twin intake pylons (left and right)
	_draw_3d_cylinder(Vector2(-5, -6), 2.2, 4.5, Color("#0F1F33"), color, 0.9)
	_draw_3d_cylinder(Vector2(-5, 6), 2.2, 4.5, Color("#0F1F33"), color, 0.9)
	# Pylon glows
	draw_circle(Vector2(-5, -6 * SQUASH), 1.5, Color(color, 0.3))
	draw_circle(Vector2(-5, 6 * SQUASH), 1.5, Color(color, 0.3))
	# Converging energy lines to hub
	draw_line(Vector2(-3, -4.5), Vector2(0, -0.8), Color(color, 0.4), 1.2)
	draw_line(Vector2(-3, 4.5), Vector2(0, 0.8), Color(color, 0.4), 1.2)
	# Flow dots
	for i in range(2):
		var t = fmod(_anim_time * 3.0 + i * 1.5, 1.0)
		draw_circle(Vector2(-3, -4.5).lerp(Vector2(0, -0.8), t), 0.6, Color(1, 1, 1, 0.8))
		draw_circle(Vector2(-3, 4.5).lerp(Vector2(0, 0.8), t), 0.6, Color(1, 1, 1, 0.8))
	# Central merge hub
	draw_circle(Vector2.ZERO, 4.5, Color(color, 0.15))
	_draw_3d_sphere(Vector2(0, 0), 4.0, Color(color, 0.6))
	draw_circle(Vector2(-0.7, -0.5), 0.8, Color(1, 1, 1, 0.5))
	# Main emitter barrel
	_draw_3d_cylinder(Vector2(5.0 + recoil, 0), 2.8, 8.5, Color("#1A2E4A"), color, 1.2)
	var muzz = Vector2(13.5 + recoil, 0)
	draw_circle(muzz, 2.2, Color.BLACK)
	draw_circle(muzz, 1.0, Color(color, 0.9))
	if _recoil > 0.3:
		draw_circle(muzz, 4.0, Color(color, 0.2))
		draw_circle(muzz, 1.5, Color.WHITE)
