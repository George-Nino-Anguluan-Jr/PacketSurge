# TowerQueue.gd
# Queue Tower — FIFO targeting. Fires a piercing rail shot.
# REDESIGN: Conveyor FIFO foundry — long conveyor belt base with queuing blocks
# + rail ejector. Mechanic = FIFO dequeue + pierce through line.

extends TowerBase

func get_type_id() -> String:
	return "tower_queue"

func _select_target() -> Node:
	_clean_targets()
	if targets.is_empty():
		return null
	return targets[0]

func _perform_attack() -> void:
	if targets.is_empty():
		return
	current_target = targets[0]
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
		"speed": 500.0,
		"damage": damage,
		"style": "queue_pierce",
		"elapsed_time": 0.0,
		"traveled": 0.0,
		"max_range": attack_range,
		"hit_list": [],
		"falloff": 1.0,
		"decay": 0.7,
		"beam_width": 10.0,
	}
	_spawn_custom_projectile(p)
	queue_redraw()

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.25, "speed": 1.2, "range": 1.1}

func _get_ability_damage_multiplier() -> float:
	return 0.6

func _draw_base_geometry(color: Color, height: float) -> void:
	# Queue base: clean conveyor belt with FIFO queue blocks
	var is_shadow = color.a < 0.5
	var belt_col = Color("#0D1A2E") if not is_shadow else Color("#0D131A")
	var groove_col = Color("#08111F") if not is_shadow else Color("#0D131A")
	_draw_3d_box(Vector2(0, 0), Vector2(24, 12), height, belt_col, color, 1.5)
	if not is_shadow:
		# Belt surface groove
		var belt_rect = PackedVector2Array([
			Vector2(-20, -7 * SQUASH), Vector2(20, -7 * SQUASH),
			Vector2(20, 7 * SQUASH), Vector2(-20, 7 * SQUASH)
		])
		draw_colored_polygon(belt_rect, groove_col)
		draw_polyline(PackedVector2Array([belt_rect[0], belt_rect[1], belt_rect[2], belt_rect[3], belt_rect[0]]), Color(color, 0.2), 0.7)
		# Belt dashes (animated conveyor)
		for i in range(8):
			var bx = -17 + i * 4.5 + fmod(_anim_time * 8.0, 4.5)
			if bx > 18:
				continue
			draw_line(Vector2(bx, -7 * SQUASH), Vector2(bx, 7 * SQUASH), Color(color, 0.12), 0.7)
		# FIFO direction arrows
		for i in range(3):
			var ax = -8 + i * 8.0
			draw_line(Vector2(ax - 2, 0), Vector2(ax + 2, 0), Color(color, 0.3), 0.8)
			draw_line(Vector2(ax + 2, 0), Vector2(ax + 0.5, -1.2), Color(color, 0.35), 0.8)
			draw_line(Vector2(ax + 2, 0), Vector2(ax + 0.5, 1.2), Color(color, 0.35), 0.8)
		# IN / OUT labels
		draw_string(ThemeDB.fallback_font, Vector2(-18, -8 * SQUASH), "IN", HORIZONTAL_ALIGNMENT_CENTER, -1, 5, Color(color, 0.35))
		draw_string(ThemeDB.fallback_font, Vector2(16, -8 * SQUASH), "OUT", HORIZONTAL_ALIGNMENT_CENTER, -1, 5, Color(color, 0.35))
	# Belt outline
	draw_polyline(PackedVector2Array([
		Vector2(-24, -12 * SQUASH), Vector2(24, -12 * SQUASH),
		Vector2(24, 12 * SQUASH), Vector2(-24, 12 * SQUASH),
		Vector2(-24, -12 * SQUASH)
	]), color, 1.0 if not is_shadow else 0.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 9.0
	var shift = fmod(_anim_time * 3.0, 4.5)
	# Turret housing
	_draw_3d_box(Vector2(0, 0), Vector2(20, 3.0), 4.0, Color("#0F1F33"), color, 1.1)
	# 4 queue blocks sliding left-to-right (FIFO: left = oldest, right = newest)
	for i in range(4):
		var qx = -9 + i * 4.8 + (shift * 0.15 if i == 0 else 0)
		var is_head = i == 3
		var bcol = Color(color, 0.5 if is_head else 0.2 + i * 0.06)
		_draw_3d_box(Vector2(qx + recoil * 0.15, -1.5), Vector2(2.6, 1.6), 3.2, Color("#1A2E4A"), bcol, 0.9)
		# Block index
		draw_string(ThemeDB.fallback_font, Vector2(qx - 0.8 + recoil * 0.15, 0.5), str(i), HORIZONTAL_ALIGNMENT_CENTER, -1, 5, Color.WHITE if is_head else Color(color, 0.3))
	# Rail ejector at front
	_draw_3d_box(Vector2(10 + recoil, 0), Vector2(2.8, 6.0), 5.5, Color("#1A2E4A"), color, 1.1)
	var eject_tip = Vector2(13.0 + recoil, 0)
	draw_circle(eject_tip, 2.0, Color.BLACK)
	draw_circle(eject_tip, 0.8, Color(color, 0.85))
	# Muzzle flash
	if _recoil > 0.3:
		draw_circle(eject_tip, 3.5, Color(color, 0.2))
