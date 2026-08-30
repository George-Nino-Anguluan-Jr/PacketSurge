# TowerStack.gd
# Stack Tower — LIFO targeting. Stacks damage charges; on 4th hit POPs a massive burst.
# REDESIGN: Pancake stack foundry — hexagonal base with 4 stacked plates
# + mortar ejector. Mechanic = LIFO stack push/pop with POP explosion.

extends TowerBase

var _stack_charge: int = 0
var _stack_target: Node = null
const STACK_CAPACITY: int = 4

func get_type_id() -> String:
	return "tower_stack"

func _select_target() -> Node:
	_clean_targets()
	if targets.is_empty():
		return null
	return targets[-1]

func _perform_attack() -> void:
	if targets.is_empty():
		return
	current_target = targets[-1]
	SoundManager.play_tower_attack(tower_id)
	_recoil = 1.0
	_flash_targets.clear()
	if _stack_target == current_target and is_instance_valid(_stack_target):
		_stack_charge += 1
	else:
		_stack_charge = 1
		_stack_target = current_target
	if _stack_charge >= STACK_CAPACITY:
		_stack_charge = 0
		_spawn_projectile("stack_mortar", damage * 3.0, 280.0, current_target, {"pop": true})
	else:
		_spawn_projectile("stack_mortar", damage * 0.7, 300.0, current_target)

func _on_style_impact(p: Dictionary) -> void:
	if p.get("pop", false):
		var origin = p["target_last_pos"]
		var radius = 80.0
		for e in targets:
			if e == p["target"] or not is_instance_valid(e) or e.is_dead:
				continue
			if origin.distance_to(e.position) <= radius:
				e.take_damage(p["damage"] * 0.5, tower_id)
				var aim = e.get_aim_point() if e.has_method("get_aim_point") else e.position
				_spawn_impact_explosion(aim, "stack_mortar", e)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.4, "speed": 1.0, "range": 1.15}

func _get_ability_targets() -> Array:
	var all = super._get_ability_targets()
	if all.is_empty():
		return []
	return [all[-1]]

func _draw_base_geometry(color: Color, height: float) -> void:
	# Stack base: hexagonal platform with 4 clearly numbered plate slots
	var is_shadow = color.a < 0.5
	var base_col = Color("#0D1A2E") if not is_shadow else Color("#0D131A")
	_draw_3d_hexagon(Vector2(0, 0), 19.0, height, base_col, color, 1.5)
	if not is_shadow:
		# 4 plate slots — recessed rectangles showing capacity
		for i in range(4):
			var slot_y = -6.0 + i * 4.0
			var slot_rect = Rect2(Vector2(-5.0, slot_y * SQUASH), Vector2(10.0, 3.0 * SQUASH))
			draw_rect(slot_rect, Color("#08111F"), true)
			draw_rect(slot_rect, Color(color, 0.2), false, 0.7)
			# Slot number
			draw_string(ThemeDB.fallback_font, Vector2(-7.0, (slot_y + 2.5) * SQUASH), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, -1, 6, Color(color, 0.4))
			# Filled indicator
			if i < _stack_charge:
				draw_rect(slot_rect, Color(color, 0.25), true)
				draw_rect(slot_rect, Color(color, 0.6), false, 0.9)
		# PUSH/POP labels
		draw_string(ThemeDB.fallback_font, Vector2(7.0, -4.0), "P", HORIZONTAL_ALIGNMENT_CENTER, -1, 6, Color(color, 0.4))
		draw_string(ThemeDB.fallback_font, Vector2(7.0, 6.0), "O", HORIZONTAL_ALIGNMENT_CENTER, -1, 6, Color(color, 0.4))
		# Arrow from POP to PUSH (LIFO direction)
		draw_arc(Vector2(9.0, 0.0), 4.0, -PI * 0.4, PI * 0.4, 10, Color(color, 0.25), 0.8)
	# Hex outline
	var hex_pts = PackedVector2Array()
	for i in range(6):
		var a = -PI / 2.0 + i * (TAU / 6.0)
		hex_pts.append(Vector2(cos(a) * 19.0, sin(a) * 19.0 * SQUASH))
	hex_pts.append(hex_pts[0])
	draw_polyline(hex_pts, color, 1.0 if not is_shadow else 0.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 8.0
	var t = _anim_time
	# 4 stacked plates — clean cylinders, bob when charged
	for i in range(4):
		var sy = 5.0 - i * 3.2
		var plate_w = 5.0 - i * 0.3
		var is_charged = i < _stack_charge
		var plate_col = Color(color, 0.7 if is_charged else 0.2 + i * 0.04)
		var bob = sin(t * 1.8 + i * 0.7) * 0.2 if is_charged else 0.0
		_draw_3d_cylinder(Vector2(0, sy + bob), plate_w, 2.0, Color("#0F1F33"), plate_col, 0.9)
		if is_charged:
			draw_circle(Vector2(0, sy + bob), 0.6, Color(1, 1, 1, 0.5))
	# Mortar ejector — simple angled tube
	_draw_3d_cylinder(Vector2(recoil, -7.0), 3.5, 9.0, Color("#1A2E4A"), color, 1.2)
	var muzz = Vector2(recoil + 8.8, -7.0 * SQUASH)
	draw_circle(muzz, 2.5, Color.BLACK)
	draw_circle(muzz, 1.0, Color(color, 0.9))
	# Muzzle glow when firing
	if _recoil > 0.25:
		draw_circle(muzz, 4.0, Color(color, 0.2))
		draw_circle(muzz, 1.5, Color("#FFB800", 0.3))
	# Charge indicator dots on the side
	for i in range(_stack_charge):
		var dot_y = -2.0 - i * 2.0
		draw_circle(Vector2(6.0, dot_y), 0.8, Color(color, 0.7))
