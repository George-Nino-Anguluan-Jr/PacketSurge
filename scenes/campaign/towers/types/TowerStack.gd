# TowerStack.gd
# Stack Tower — LIFO targeting. Stacks damage charges; on 4th hit POPs a massive burst.
# BESPOKE DESIGN: The LIFO Hydraulic Mortar Silo
# An industrial pressure chamber with an exposed vertical containment tube showing
# physical data plates stacked inside (1..4). Hits 1-3 compress the piston down;
# the 4th hit violently snaps the hydraulic piston upward with a seismic Pop explosion.
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

	var spawn_origin = get_muzzle_position()
	if _stack_charge >= STACK_CAPACITY:
		_stack_charge = 0
		_spawn_projectile("stack_mortar", damage * 3.0, projectile_speed, current_target, {"pop": true})
	else:
		_spawn_projectile("stack_mortar", damage * 0.7, projectile_speed, current_target)

func _get_custom_muzzle_position() -> Vector2:
	return global_position + Vector2(0, -22.0)

func _on_style_impact(p: Dictionary) -> void:
	if p.get("pop", false):
		var target = p.get("target")
		if is_instance_valid(target) and not target.is_dead and target.has_method("show_floating_tag"):
			target.show_floating_tag("💥 POP! (AoE)", Color("#FF3366"))
		var origin = p["target_last_pos"]
		var radius = splash_radius
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

# ─── BESPOKE PROCEDURAL RENDERING ──────────────────────────────────────────

func _draw_custom_tower(color: Color) -> void:
	var t = _anim_time
	var is_popping = _recoil > 0.4 and _stack_charge == 0

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, 6), 24.0, 15.0, 0.4)

	# 2. Heavy Hexagonal Industrial Silo Base
	var base_col = Color("#141B26")
	var side_col = Color("#0A0F17")
	CyberVectorCanvas.draw_iso_hexagon(
		self,
		Vector2.ZERO,
		20.0,
		8.0,
		base_col,
		side_col,
		Color(color, 0.4),
		1.4
	)

	# 3. Outer Silo Ring with Industrial Hazard Markings
	var ring_color = Color("#1B2636")
	CyberVectorCanvas.draw_iso_cylinder(
		self,
		Vector2.ZERO,
		15.0,
		5.0,
		ring_color,
		side_col,
		Color(color, 0.3),
		1.0,
		20
	)

	# 4. Vertical Stack Containment Core (Exposed Piston Tube)
	# Piston compression: downward offset increases as charge accumulates
	var compression = float(_stack_charge) * 2.5
	var piston_y = -8.0 + compression * (1.0 - _recoil)
	if is_popping:
		piston_y -= 8.0 * _recoil # Violent upward kickback on Pop

	# Glass containment cylinder
	CyberVectorCanvas.draw_iso_cylinder(
		self,
		Vector2(0, 0),
		9.0,
		14.0,
		Color("#0B131D", 0.6),
		Color("#050A10", 0.8),
		Color(color, 0.5),
		1.0,
		18
	)

	# 5. Physical Stacked Plates Inside Chamber (1..4)
	for i in range(4):
		var plate_h = -2.0 - i * 3.5
		var is_filled = i < _stack_charge
		var plate_col = color if is_filled else Color(color, 0.15)
		var plate_top = color.lightened(0.25) if is_filled else Color("#0C1520")

		if is_filled:
			# Shaded glowing stack plate
			CyberVectorCanvas.draw_iso_cylinder(
				self,
				Vector2(0, plate_h),
				7.0,
				2.0,
				plate_top,
				plate_col.darkened(0.3),
				Color.WHITE if i == _stack_charge - 1 else plate_col,
				0.8,
				16
			)
			# Level/plate number pip
			draw_circle(Vector2(0, plate_h - 2.0), 1.0, Color.WHITE)

	# 6. Top Piston Head & Mortar Bore
	var piston_head_y = piston_y - 8.0
	CyberVectorCanvas.draw_iso_cylinder(
		self,
		Vector2(0, piston_head_y),
		8.5,
		4.0,
		Color("#223044"),
		Color("#101824"),
		Color(color, 0.7),
		1.2,
		18
	)

	# Open Mortar Muzzle Hole
	var bore_center = Vector2(0, piston_head_y - 4.0)
	draw_circle(bore_center, 4.5, Color.BLACK)
	draw_arc(bore_center, 4.5, 0, TAU, 20, Color(color, 0.8), 1.2)

	# 7. Pop Explosion & Steam Vent VFX
	if is_popping:
		# Blast ring
		draw_arc(bore_center, 12.0 * _recoil, 0, TAU, 24, Color("#FFB800", 0.8), 2.0)
		draw_circle(bore_center, 6.0 * _recoil, Color.WHITE)
		# Side steam jets
		draw_line(Vector2(-12, -10), Vector2(-20 * _recoil - 12, -10), Color(Color.WHITE, 0.6), 2.5)
		draw_line(Vector2(12, -10), Vector2(20 * _recoil + 12, -10), Color(Color.WHITE, 0.6), 2.5)
	elif _stack_charge > 0:
		# Glowing core heat
		var charge_pulse = float(_stack_charge) / 4.0
		draw_circle(bore_center, 2.5 * charge_pulse, Color(color, 0.6))

	# 8. Level 2 & 3 Reinforced Seismic Footing
	if current_level >= 2:
		for i in range(3):
			var a = i * TAU / 3.0 + PI / 6.0
			var foot_pos = Vector2(cos(a) * 20.0, sin(a) * 20.0 * SQUASH)
			CyberVectorCanvas.draw_iso_prism(
				self,
				foot_pos,
				Vector2(3.5, 3.5),
				4.0,
				Color("#1A2432"),
				Color("#0C121B"),
				Color(color, 0.4),
				1.0
			)
