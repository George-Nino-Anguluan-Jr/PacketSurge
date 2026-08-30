# TowerBubble.gd
# Bubble Tower — bubble sort swap pass. Fires pulse orbs at two adjacent
# enemies; on impact the targets SWAP places along the path (a bubble pass).
# REDESIGN: Iridescent bubble lab — rounded capsule base with rising bubble
# chambers, swap-loop turret. 3D isometric intact, mechanic = pair swap.

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
		_spawn_projectile("bubble_pulse", damage * 0.8, 280.0, a)
		_spawn_projectile("bubble_pulse", damage * 0.8, 280.0, b, {
			"on_hit": _bubble_swap,
			"swap_a": a,
			"swap_b": b,
		})
	else:
		_spawn_projectile("bubble_pulse", damage * 0.8, 280.0, current_target, {"on_hit": _bubble_pop})

func _bubble_swap(p: Dictionary) -> void:
	var a = p.get("swap_a")
	var b = p.get("swap_b")
	if is_instance_valid(a) and is_instance_valid(b) and not a.is_dead and not b.is_dead:
		var mid: Vector2 = (a.position + b.position) * 0.5
		_spawn_impact_explosion(mid, "bubble_pulse", null)
		a.swap_progress(b)

func _bubble_pop(p: Dictionary) -> void:
	var track: Node = p["target"] if is_instance_valid(p.get("target")) else null
	_spawn_impact_explosion(p["target_last_pos"], "bubble_pulse", track)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.25, "speed": 1.0, "range": 1.2}

func _draw_base_geometry(color: Color, height: float) -> void:
	# Bubble base: rounded platform with swap arrows and bubble indicators
	var is_shadow = color.a < 0.5
	var base_col = Color("#0D1C2E") if not is_shadow else Color("#0D131A")
	_draw_3d_box(Vector2(0, 0), Vector2(19, 16), height, base_col, color, 1.5)
	if not is_shadow:
		# Swap-loop glyph — two curved arrows forming a loop (centered)
		draw_arc(Vector2(-3, 0), 5.0, -PI * 0.7, PI * 0.75, 14, Color(color, 0.35), 0.9)
		draw_arc(Vector2(3, 0), 5.0, PI * 0.3, PI * 1.75, 14, Color(color, 0.35), 0.9)
		# Arrowheads
		draw_line(Vector2(-6.5, -3.0), Vector2(-3.0, -4.8), Color(color, 0.5), 0.9)
		draw_line(Vector2(-6.5, -3.0), Vector2(-7.5, 0), Color(color, 0.5), 0.9)
		draw_line(Vector2(6.5, 3.0), Vector2(3.0, 4.8), Color(color, 0.5), 0.9)
		draw_line(Vector2(6.5, 3.0), Vector2(7.5, 0), Color(color, 0.5), 0.9)
		# 4 bubble indicators along bottom — circles with bubbles inside
		for i in range(4):
			var bx = -9 + i * 6.0
			draw_circle(Vector2(bx, 7.0 * SQUASH), 2.0, Color(color, 0.15))
			draw_circle(Vector2(bx, 7.0 * SQUASH), 2.0, Color(color, 0.3), false, 0.7)
			# Small bubble inside
			draw_circle(Vector2(bx, 7.0 * SQUASH), 0.8, Color(color, 0.4))
	# Slab outline
	draw_polyline(PackedVector2Array([
		Vector2(-19, -16 * SQUASH), Vector2(19, -16 * SQUASH),
		Vector2(19, 16 * SQUASH), Vector2(-19, 16 * SQUASH),
		Vector2(-19, -16 * SQUASH)
	]), color, 1.0 if not is_shadow else 0.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 4.0
	var t = _anim_time
	# Turret housing
	_draw_3d_box(Vector2(0, 0), Vector2(18, 3.0), 4.0, Color("#0F1F33"), color, 1.1)
	# 3 bubble chambers — cylinders that bob gently
	for i in range(3):
		var bx = -5 + i * 5.0
		var bob = sin(t * 2.0 + i * 0.9) * 0.3
		var bh = 4.0 + i * 1.0
		_draw_3d_cylinder(Vector2(bx + recoil, -bh * 0.4 - 1.0 + bob), 1.5, bh, Color("#12233A"), Color(color, 0.25 + i * 0.1), 0.9)
		# Bubble dome highlight
		var top = Vector2(bx + recoil, (-bh * 0.4 - 1.0 + bob) - bh * 0.5 * SQUASH)
		draw_circle(top, 0.9, Color(1, 1, 1, 0.45))
	# Emitter nozzle
	_draw_3d_cylinder(Vector2(8 + recoil, 0), 1.8, 6.0, Color("#1A2E4A"), color, 1.0)
	var muzz = Vector2(14.0 + recoil, 0)
	draw_circle(muzz, 1.5, Color.BLACK)
	draw_circle(muzz, 0.6, Color(color, 0.9))
	if _recoil > 0.3:
		draw_circle(muzz, 2.5, Color(color, 0.2))
