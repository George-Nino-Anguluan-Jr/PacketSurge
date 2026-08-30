# TowerInsertion.gd
# Insertion Tower — insertion sort "shift". Fires a needle that on impact
# PUSHES the target backward along the path (shifting elements) + applies DoT.
# REDESIGN: Precision injector — cartridge tray base + piston needle turret,
# shift-arrow mechanic visualized. 3D isometric intact.

extends TowerBase

func get_type_id() -> String:
	return "tower_insertion"

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
	_spawn_projectile("insertion_needle", damage, 350.0, current_target, {"on_hit": _insert_shift})
	if current_target.has_method("apply_dot"):
		current_target.apply_dot(damage * 0.3, 3.0, tower_id)

func _insert_shift(p: Dictionary) -> void:
	var target = p["target"]
	if is_instance_valid(target) and not target.is_dead and target.has_method("push_back"):
		target.push_back(40.0)
		var aim = target.get_aim_point() if target.has_method("get_aim_point") else target.position
		_spawn_impact_explosion(aim, "insertion_needle", target)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.3, "speed": 1.15, "range": 1.0}

func _draw_base_geometry(color: Color, height: float) -> void:
	# Insertion base: clean rectangular tray with 4 sorted slots and shift arrows
	var is_shadow = color.a < 0.5
	var tray_col = Color("#0D1A2E") if not is_shadow else Color("#0D131A")
	_draw_3d_box(Vector2(0, 0), Vector2(20, 14), height, tray_col, color, 1.5)
	if not is_shadow:
		# 4 sorted cartridge slots
		for i in range(4):
			var sx = -9 + i * 6.0
			var slot = Rect2(Vector2(sx - 1.5, -7 * SQUASH), Vector2(3.0, 14 * SQUASH))
			draw_rect(slot, Color("#08111F"), true)
			draw_rect(slot, Color(color, 0.2), false, 0.7)
			# Sorted element indicator (filled = sorted)
			if i < 3:
				draw_rect(Rect2(Vector2(sx - 0.8, -5 * SQUASH), Vector2(1.6, 10 * SQUASH)), Color(color, 0.15), true)
		# Shift arrows along bottom (insertion direction)
		for i in range(3):
			var ax = -6 + i * 5.0
			var ay = 8.0 * SQUASH
			draw_line(Vector2(ax - 2, ay), Vector2(ax + 2, ay), Color(color, 0.35), 0.8)
			draw_line(Vector2(ax + 2, ay), Vector2(ax + 0.5, ay - 1.2), Color(color, 0.4), 0.8)
			draw_line(Vector2(ax + 2, ay), Vector2(ax + 0.5, ay + 1.2), Color(color, 0.4), 0.8)
		# Insertion chevron at top
		draw_line(Vector2(0, -9 * SQUASH), Vector2(-2, -7 * SQUASH), Color(color, 0.5), 0.9)
		draw_line(Vector2(0, -9 * SQUASH), Vector2(2, -7 * SQUASH), Color(color, 0.5), 0.9)
	# Slab outline
	draw_polyline(PackedVector2Array([
		Vector2(-20, -14 * SQUASH), Vector2(20, -14 * SQUASH),
		Vector2(20, 14 * SQUASH), Vector2(-20, 14 * SQUASH),
		Vector2(-20, -14 * SQUASH)
	]), color, 1.0 if not is_shadow else 0.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 5.0
	# Turret housing
	_draw_3d_box(Vector2(0, 0), Vector2(18, 2.8), 3.2, Color("#0F1F33"), color, 1.1)
	# Piston rail on top
	var rail_y = -2.5
	draw_line(Vector2(-7, rail_y), Vector2(7, rail_y), Color(color, 0.22), 0.7)
	# Needle barrel
	_draw_3d_cylinder(Vector2(6 + recoil, 0), 1.8, 7.5, Color("#1A2E4A"), color, 1.0)
	# Needle tip — sharp diamond
	var tip = Vector2(13.5 + recoil, 0)
	var tip_pts = PackedVector2Array([tip + Vector2(2.2, 0), tip + Vector2(0, -1.1), tip + Vector2(-0.8, 0), tip + Vector2(0, 1.1)])
	draw_colored_polygon(tip_pts, Color.WHITE)
	draw_colored_polygon(tip_pts, Color(color, 0.85))
	draw_polyline(tip_pts, Color(1, 1, 1, 0.85), 0.5, true)
	# Plunger at rear
	_draw_3d_cylinder(Vector2(-6 + recoil * 0.4, 0), 2.2, 2.0, Color("#0D1A2E"), color, 0.9)
	# DoT reservoir indicator
	draw_rect(Rect2(Vector2(-2, -3.5), Vector2(5, 1.2)), Color(color, 0.15), true)
	draw_rect(Rect2(Vector2(-2, -3.5), Vector2(5, 1.2)), Color(color, 0.3), false, 0.6)
	draw_rect(Rect2(Vector2(-1, -3.2), Vector2(2.5, 0.6)), Color(color, 0.6), true)
