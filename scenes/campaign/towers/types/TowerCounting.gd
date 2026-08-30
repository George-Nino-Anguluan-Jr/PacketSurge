# TowerCounting.gd
# Count Tower — counting sort. Fires 1..N numbered pellets, where N is the
# number of enemies counted in range (one pellet per enemy, capped at 5).
# REDESIGN: Tally abacus tower — counting frame base with abacus beads,
# rotary counter turret. 3D isometric intact.

extends TowerBase

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
	var count: int = clamp(_count_live_enemies(), 1, 5)
	var spawn_origin = get_muzzle_position()
	for i in range(count):
		var p = {
			"pos": spawn_origin,
			"start_pos": spawn_origin,
			"draw_pos": spawn_origin,
			"target": current_target,
			"target_last_pos": current_target.position,
			"speed": 200.0 + i * 40.0,
			"damage": damage * 0.25,
			"style": "counting_pellet",
			"elapsed_time": 0.0,
			"digit": i + 1,
			"delay": i * 0.05
		}
		_spawn_custom_projectile(p)
	queue_redraw()

func _count_live_enemies() -> int:
	var n: int = 0
	for e in targets:
		if is_instance_valid(e) and not e.is_dead:
			n += 1
	return n

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.2, "speed": 1.25, "range": 1.0}

func _draw_base_geometry(color: Color, height: float) -> void:
	# Counting base: clean tally frame with 5 numbered count slots
	var is_shadow = color.a < 0.5
	var frame_col = Color("#0D1A2E") if not is_shadow else Color("#0D131A")
	_draw_3d_box(Vector2(0, 0), Vector2(20, 16), height, frame_col, color, 1.5)
	if not is_shadow:
		# 5 count slots — recessed rectangles with tally marks above
		var slot_w = 6.0
		var spacing = 1.2
		var total = 5.0 * slot_w + 4.0 * spacing
		var start_x = -total / 2.0 + slot_w / 2.0
		for i in range(5):
			var sx = start_x + i * (slot_w + spacing)
			# Slot recess
			var slot_rect = Rect2(Vector2(sx - slot_w / 2.0, -5.0 * SQUASH), Vector2(slot_w, 10.0 * SQUASH))
			draw_rect(slot_rect, Color("#08111F"), true)
			draw_rect(slot_rect, Color(color, 0.2), false, 0.7)
			# Count number
			draw_string(ThemeDB.fallback_font, Vector2(sx - 1.5, -6.0 * SQUASH), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, -1, 6, Color(color, 0.45))
			# Tally tick marks inside slot
			var tally_count = i + 1
			for t_idx in range(tally_count):
				var ty = -3.0 + t_idx * 1.5
				draw_line(Vector2(sx - 1.0, ty * SQUASH), Vector2(sx + 1.0, ty * SQUASH), Color(color, 0.35), 0.7)
		# "N=" label at center bottom
		draw_string(ThemeDB.fallback_font, Vector2(-3, 8.0 * SQUASH), "N=", HORIZONTAL_ALIGNMENT_CENTER, -1, 6, Color(color, 0.4))
	# Slab outline
	draw_polyline(PackedVector2Array([
		Vector2(-20, -16 * SQUASH), Vector2(20, -16 * SQUASH),
		Vector2(20, 16 * SQUASH), Vector2(-20, 16 * SQUASH),
		Vector2(-20, -16 * SQUASH)
	]), color, 1.0 if not is_shadow else 0.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 6.0
	# Turret housing — clean rectangular block
	_draw_3d_box(Vector2(0, 0), Vector2(18, 3.5), 5.0, Color("#0F1F33"), color, 1.2)
	# Count display — 5 small windows showing current count
	for i in range(5):
		var wx = -8 + i * 4.0
		var is_active = i < clamp(_count_live_enemies(), 1, 5)
		var win_col = Color(color, 0.6 if is_active else 0.15)
		draw_rect(Rect2(Vector2(wx - 1.5, -1.2), Vector2(3.0, 2.4)), Color("#08111F"), true)
		draw_rect(Rect2(Vector2(wx - 1.5, -1.2), Vector2(3.0, 2.4)), win_col, false, 0.7)
		if is_active:
			draw_string(ThemeDB.fallback_font, Vector2(wx - 1.0, 0.8), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, -1, 6, Color(color, 0.8))
	# Emitter barrel
	_draw_3d_cylinder(Vector2(8 + recoil, 0), 2.0, 7.0, Color("#1A2E4A"), color, 1.0)
	var muzz = Vector2(15.0 + recoil, 0)
	draw_circle(muzz, 1.8, Color.BLACK)
	draw_circle(muzz, 0.7, Color(color, 0.9))
	# Muzzle flash when firing
	if _recoil > 0.3:
		draw_circle(muzz, 3.0, Color(color, 0.2))
