# TowerStack.gd
# Stack Tower — LIFO targeting. Stacks damage charges; on 4th hit POPs a massive burst.
# Targets: last enemy entered (LIFO / pop semantics).

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

	# Stack charge: if hitting same target, build up; else reset
	if _stack_target == current_target and is_instance_valid(_stack_target):
		_stack_charge += 1
	else:
		_stack_charge = 1
		_stack_target = current_target

	if _stack_charge >= STACK_CAPACITY:
		_stack_charge = 0
		# POP: big mortar + splash
		_spawn_projectile("stack_mortar", damage * 3.0, 280.0, current_target, {"pop": true})
	else:
		# Normal push: small mortar
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
	_draw_3d_hexagon(Vector2(0, 0), 19.0, height, Color("#101721"), color, 1.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 8.0
	for i in range(4):
		var sy = 5 - i * 3.5
		_draw_3d_cylinder(Vector2(0, sy), 4.5 - i * 0.4, 2.5, Color("#15202E"), Color(color, 0.3 + i * 0.12), 1.0)
	_draw_3d_cylinder(Vector2(recoil, -7), 4.0, 9.0, Color("#223344"), color, 1.5)
	draw_circle(Vector2(recoil + 9.0, -7 * SQUASH), 2.5, Color.BLACK)
