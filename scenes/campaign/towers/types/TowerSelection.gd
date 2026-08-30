# TowerSelection.gd
# Selection Tower — selection sort. Repeatedly selects the lowest-HP enemy
# and fires a seeker that grows in damage with each consecutive kill it lands
# REDESIGN: Executioner tower — heavy hexagonal fortress with targeting
# reticle + streak escalation scope. Mechanic = pick weakest + ramping mark.

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
	if _streak_target == current_target:
		_kill_streak += 1
	else:
		_kill_streak = 0
	_streak_target = current_target
	var mult: float = 1.8 + _kill_streak * 0.25
	_spawn_projectile("selection_sniper", damage * mult, 500.0, current_target)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.35, "speed": 1.0, "range": 1.15}

func _draw_base_geometry(color: Color, height: float) -> void:
	# Selection base: hexagonal fortress with targeting crosshair and weak-mark
	var is_shadow = color.a < 0.5
	var fort_col = Color("#0D1A2E") if not is_shadow else Color("#0D131A")
	_draw_3d_hexagon(Vector2(0, 0), 20.0, height, fort_col, color, 1.5)
	if not is_shadow:
		# Targeting crosshair on top face
		var cc = Color(color, 0.3)
		draw_line(Vector2(-10, 0), Vector2(10, 0), cc, 0.8)
		draw_line(Vector2(0, -10 * SQUASH), Vector2(0, 10 * SQUASH), cc, 0.8)
		draw_arc(Vector2.ZERO, 5.5, 0, TAU, 16, cc, 0.7)
		# Corner bracket markers (selection corners)
		for i in range(4):
			var sx = (-1 if i % 2 == 0 else 1) * 12
			var sy = (-1 if i < 2 else 1) * 7 * SQUASH
			draw_line(Vector2(sx, sy), Vector2(sx + (-2 if sx > 0 else 2), sy), Color(color, 0.4), 0.8)
			draw_line(Vector2(sx, sy), Vector2(sx, sy + (-1.5 if sy > 0 else 1.5)), Color(color, 0.4), 0.8)
		# Weak-mark — pulsing center dot
		var pulse = 0.6 + sin(_anim_time * 4.0) * 0.4
		draw_circle(Vector2.ZERO, 2.0, Color(color, pulse * 0.5))
		draw_circle(Vector2.ZERO, 1.0, Color.WHITE)
		# Kill streak chevrons
		var streak_len = clamp(_kill_streak, 0, 5)
		for s_idx in range(streak_len):
			var sx2 = -5 + s_idx * 3.0
			draw_line(Vector2(sx2, 8 * SQUASH), Vector2(sx2 + 1.0, 9.2 * SQUASH), Color("#FF4D4D", 0.6), 0.8)
			draw_line(Vector2(sx2 + 1.0, 9.2 * SQUASH), Vector2(sx2 + 2.0, 8 * SQUASH), Color("#FF4D4D", 0.6), 0.8)
	# Hex outline
	var hex_pts = PackedVector2Array()
	for i in range(6):
		var a = -PI / 2.0 + i * (TAU / 6.0)
		hex_pts.append(Vector2(cos(a) * 20.0, sin(a) * 20.0 * SQUASH))
	hex_pts.append(hex_pts[0])
	draw_polyline(hex_pts, color, 1.0 if not is_shadow else 0.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 7.0
	var t = _anim_time
	# Twin stabilizer pylons (rear)
	_draw_3d_cylinder(Vector2(-6, -6), 2.2, 4.5, Color("#0F1F33"), color, 0.9)
	_draw_3d_cylinder(Vector2(-6, 6), 2.2, 4.5, Color("#0F1F33"), color, 0.9)
	draw_circle(Vector2(-6, -6 * SQUASH), 1.0, Color(color, 0.25))
	draw_circle(Vector2(-6, 6 * SQUASH), 1.0, Color(color, 0.25))
	# Energy tethers to hub
	draw_line(Vector2(-4, -4.5), Vector2(0, -1.0), Color(color, 0.3), 0.9)
	draw_line(Vector2(-4, 4.5), Vector2(0, 1.0), Color(color, 0.3), 0.9)
	# Central execution hub
	draw_circle(Vector2.ZERO, 4.8, Color(color, 0.15))
	_draw_3d_sphere(Vector2(0, 0), 4.2, Color(color, 0.6))
	draw_circle(Vector2(-0.8, -0.6), 0.8, Color(1, 1, 1, 0.45))
	# Scope ring
	draw_arc(Vector2.ZERO, 5.8 + sin(t * 3.5) * 0.4, 0, TAU, 16, Color(color, 0.25), 0.7)
	# Marksman barrel with suppressor
	_draw_3d_cylinder(Vector2(5.0 + recoil, 0), 2.8, 9.0, Color("#1A2E4A"), color, 1.2)
	var muzz = Vector2(14.0 + recoil, 0)
	draw_circle(muzz, 2.2, Color.BLACK)
	draw_circle(muzz, 1.0, Color(color, 0.95))
	# Laser sight dot
	if _recoil < 0.2:
		var laser = muzz + Vector2(8, 0)
		draw_circle(laser, 0.8, Color(color, 0.5))
		draw_circle(laser, 0.3, Color.WHITE)
		draw_line(muzz, laser, Color(color, 0.1), 0.6)
	if _recoil > 0.3:
		draw_circle(muzz, 4.0, Color(color, 0.2))
		draw_circle(muzz, 1.5, Color.WHITE)
