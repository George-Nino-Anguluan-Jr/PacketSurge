# Tower.gd — real tower defense pattern: Area2D range detection + simple timer
extends Node2D

const ENEMY_RADIUS: float = 20.0

# ─── STATS ─────────────────────────────────────────────
var tower_id: String      = ""
var tower_name: String    = "Tower"
var damage: float         = 10.0
var attack_speed: float   = 1.0
var attack_range: float   = 150.0
var ram_cost: int         = 50
var tower_color: Color    = Color("#00D4FF")
var icon_text: String     = "[ ]"

# ─── STATE ─────────────────────────────────────────────
var current_target: Node       = null
var attack_timer: float        = 0.0
var enemy_layer: Node2D        = null
var grid_cell: Vector2i        = Vector2i.ZERO
var targets: Array[Node]       = []  # Enemies currently in range (by Area2D)
var _shoot_flash: float        = 0.0
var _flash_targets: Array[Vector2] = []
var _selected: bool = false

# Upgrade state
var current_level: int         = 1
var max_level: int             = 3

# ─── PREVIEW MODE ──────────────────────────────────────
var preview_mode: bool         = false

# Ability state
var ability_cooldown: float    = 0.0
var ability_max_cooldown: float = 8.0

# ─── ANIMATION STATE ───────────────────────────────────
var _turret_angle: float       = -PI / 2
var _recoil: float             = 0.0
var _anim_time: float          = 0.0
var _mobile_redraw_skip: int   = 0

# ─── PROJECTILE & EXPLOSION STATE ─────────────────────
var _projectiles: Array[Dictionary] = []
var _explosions: Array[Dictionary]  = []
var _chain_arcs: Array[Dictionary]  = []

@onready var sprite: Sprite2D = $TowerSprite

# ─── SPRITE MODE ───────────────────────────────────────
const _SpireTower = preload("res://scenes/campaign/towers/SpireTower.gd")
var _spire = null
var spire_variant: String = ""
var spire_base_h: int = 0

# ─── AREA2D RANGE DETECTOR ─────────────────────────────
var _range_area: Area2D = null
var _range_shape: CollisionShape2D = null

func _ready() -> void:
	if tower_id == "":
		_setup_sprite()

func initialize(data: TowerData, cell: Vector2i, e_layer: Node2D) -> void:
	tower_id      = data.tower_id
	tower_name    = data.tower_name
	damage        = data.damage
	attack_speed  = data.attack_speed
	attack_range  = data.attack_range
	ram_cost      = data.ram_cost
	tower_color   = data.color
	icon_text     = data.icon_text
	spire_variant = data.spire_variant
	spire_base_h  = data.spire_base_h
	grid_cell     = cell
	enemy_layer   = e_layer
	current_level = 1
	z_index = 1
	_setup_sprite()
	_setup_range_area()
	_animate_placement()
	queue_redraw()

func _setup_range_area() -> void:
	_range_area = Area2D.new()
	_range_area.name = "RangeDetector"
	_range_area.collision_mask = 1
	_range_area.monitoring = true
	_range_area.monitorable = false
	add_child(_range_area)

	_range_shape = CollisionShape2D.new()
	_range_shape.name = "RangeShape"
	var circle = CircleShape2D.new()
	circle.radius = attack_range + ENEMY_RADIUS
	_range_shape.shape = circle
	_range_area.add_child(_range_shape)

	_range_area.body_entered.connect(_on_enemy_entered)
	_range_area.body_exited.connect(_on_enemy_exited)

func _on_enemy_entered(body: Node) -> void:
	if not body.has_method("take_damage"):
		return
	if not targets.has(body):
		targets.append(body)
		# Fire immediately when enemy enters range
		attack_timer = 0.0
		_attack()

func _on_enemy_exited(body: Node) -> void:
	targets.erase(body)
	if body == current_target:
		current_target = null

func _clean_targets() -> void:
	targets = targets.filter(func(t):
		return is_instance_valid(t) and not t.is_dead
	)

# ─── TARGET SELECTION ──────────────────────────────────
func _get_target() -> Node:
	_clean_targets()
	if targets.is_empty():
		return null
	match tower_id:
		"tower_stack":
			return targets[-1]
		"tower_queue":
			return targets[0]
		"tower_selection":
			return _get_lowest_hp(targets)
		"tower_bubble":
			return targets[0]
		"tower_quick":
			return targets[0]
		_:
			return _get_closest(targets)

func _get_closest(list: Array) -> Node:
	var best: Node = null
	var best_dist: float = INF
	for t in list:
		var d = global_position.distance_to(t.global_position)
		if d < best_dist:
			best_dist = d
			best = t
	return best

func _get_lowest_hp(list: Array) -> Node:
	var best: Node = null
	var best_hp: float = INF
	for t in list:
		if t.current_health < best_hp:
			best_hp = t.current_health
			best = t
	return best

# ─── ABILITY ───────────────────────────────────────────
func get_ability_name() -> String:
	var def = GameManager.TOWER_DEFINITIONS.get(tower_id, {})
	return def.get("ability_name", "Special")

func get_ability_cost() -> int:
	return ram_cost * 2

func is_ability_ready() -> bool:
	return ability_cooldown <= 0.0

func set_selected(v: bool) -> void:
	_selected = v
	queue_redraw()

func activate_ability() -> bool:
	if not is_ability_ready():
		return false
	var dmg_mult = 2.5 + current_level * 0.5
	_apply_ability_damage(damage * dmg_mult)
	ability_cooldown = ability_max_cooldown
	_animate_upgrade()
	return true

func _apply_ability_damage(dmg: float) -> void:
	if not enemy_layer:
		return
	var enemies = []
	for child in enemy_layer.get_children():
		if is_instance_valid(child) and child.has_method("take_damage"):
			var dist = global_position.distance_to(child.global_position)
			if dist <= attack_range * 1.5:
				enemies.append(child)
	if enemies.is_empty():
		return
	match tower_id:
		"tower_array":
			if enemies.size() > 0:
				enemies[0].take_damage(dmg * 2)
		"tower_stack":
			enemies[-1].take_damage(dmg)
		"tower_queue":
			for e in enemies:
				e.take_damage(dmg * 0.6)
		"tower_linked_list":
			for i in range(min(3, enemies.size())):
				enemies[i].take_damage(dmg)
		_:
			for e in enemies:
				e.take_damage(dmg)
	_shoot_flash = 2.0
	queue_redraw()

# ─── UPGRADE ───────────────────────────────────────────
func upgrade() -> int:
	if current_level >= max_level:
		return current_level
	current_level += 1
	match tower_id:
		"tower_array":
			damage *= 1.3
			attack_speed *= 1.15
			attack_range *= 1.1
		"tower_stack":
			damage *= 1.4
			attack_range *= 1.15
		"tower_queue":
			damage *= 1.25
			attack_speed *= 1.2
			attack_range *= 1.1
		"tower_linked_list":
			damage *= 1.3
			attack_range *= 1.2
		"tower_bubble":
			damage *= 1.25
			attack_range *= 1.2
		"tower_selection":
			damage *= 1.35
			attack_range *= 1.15
		"tower_insertion":
			damage *= 1.3
			attack_speed *= 1.15
		"tower_quick":
			damage *= 1.25
			attack_speed *= 1.2
		"tower_merge":
			damage *= 1.3
			attack_range *= 1.15
		"tower_counting":
			damage *= 1.2
			attack_speed *= 1.25
		"tower_radix":
			damage *= 1.2
			attack_speed *= 1.3
		"tower_linear":
			damage *= 1.25
			attack_range *= 1.2
		"tower_binary":
			damage *= 1.4
			attack_range *= 1.1
	if _spire:
		_spire.set_level(current_level)
	SignalBus.tower_upgraded.emit(tower_id, current_level)
	_animate_upgrade()
	return current_level

func _animate_upgrade() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
	tween.tween_property(self, "scale", Vector2(1.35, 1.35), 0.25)
	_shoot_flash = 1.5
	queue_redraw()

func _setup_sprite() -> void:
	if spire_variant != "":
		if not _spire:
			_spire = _SpireTower.new()
			add_child(_spire)
		_spire.setup(spire_variant)
		_spire.set_level(current_level)
		if sprite:
			sprite.visible = false
	elif sprite:
		sprite.visible = true

func _animate_placement() -> void:
	scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.35, 1.35), 0.35)

# ─── PROCESS ──────────────────────────────────────────
func _process(delta: float) -> void:
	if preview_mode:
		_anim_time += delta
		queue_redraw()
		return

	_anim_time += delta
	attack_timer += delta
	if ability_cooldown > 0:
		ability_cooldown -= delta

	if _recoil > 0:
		_recoil = max(0.0, _recoil - delta * 6.0)

	# Pick best target
	var target = _get_target()
	if target != current_target:
		current_target = target

	# Rotate turret toward target
	if is_instance_valid(current_target):
		var desired_angle = (current_target.global_position - global_position).angle()
		_turret_angle = lerp_angle(_turret_angle, desired_angle, delta * 8.0)
	else:
		_turret_angle = lerp_angle(_turret_angle, -PI / 2, delta * 2.0)

	if _shoot_flash > 0:
		_shoot_flash -= delta * 4.0

	if _spire:
		_spire.aim(_turret_angle)

	_mobile_redraw_skip += 1
	if _mobile_redraw_skip % 2 == 0:
		queue_redraw()

	# Update projectiles
	_update_projectiles(delta)
	_update_explosions(delta)
	_update_arcs(delta)

	# Fire at fire rate
	if attack_timer >= 1.0 / attack_speed and current_target != null:
		attack_timer = 0.0
		_attack()

# ─── PROJECTILE UPDATE ─────────────────────────────────
func _update_projectiles(delta: float) -> void:
	var remaining: Array[Dictionary] = []
	for p in _projectiles:
		p["elapsed_time"] += delta
		if p.has("delay") and p["delay"] > 0:
			p["delay"] -= delta
			if p["delay"] > 0:
				remaining.append(p)
				continue
		var target_pos = p["target_last_pos"]
		if is_instance_valid(p["target"]):
			target_pos = p["target"].position
			p["target_last_pos"] = target_pos
		var current_pos = p["pos"]
		var next_pos = current_pos.move_toward(target_pos, p["speed"] * delta)
		p["pos"] = next_pos
		if p["style"] == "stack_mortar":
			var dir_vec = target_pos - p["start_pos"]
			var d_total = dir_vec.length()
			var d_current = (next_pos - p["start_pos"]).length()
			if d_total > 0:
				var t = clamp(d_current / d_total, 0.0, 1.0)
				var arc_height = sin(t * PI) * -45.0
				p["draw_pos"] = next_pos + Vector2(0, arc_height)
			else:
				p["draw_pos"] = next_pos
		else:
			p["draw_pos"] = next_pos
		if next_pos.distance_to(target_pos) < 25.0:
			_on_projectile_impact(p)
		else:
			remaining.append(p)
	_projectiles = remaining

func _update_explosions(delta: float) -> void:
	var remaining: Array[Dictionary] = []
	for e in _explosions:
		e["elapsed"] += delta
		e["radius"] = lerp(0.0, e["max_radius"], e["elapsed"] / e["lifetime"])
		if e["elapsed"] < e["lifetime"]:
			remaining.append(e)
	_explosions = remaining

func _update_arcs(delta: float) -> void:
	var remaining: Array[Dictionary] = []
	for arc in _chain_arcs:
		arc["elapsed"] += delta
		if arc["elapsed"] < arc["lifetime"]:
			remaining.append(arc)
	_chain_arcs = remaining

# ─── ATTACK ────────────────────────────────────────────
func _attack() -> void:
	if not _get_target():
		return
	SoundManager.play_tower_attack(tower_id)
	_flash_targets.clear()
	_recoil = 1.0

	match tower_id:
		"tower_array":        _attack_array()
		"tower_stack":        _attack_stack()
		"tower_queue":        _attack_queue()
		"tower_linked_list":  _attack_linked()
		"tower_bubble":       _attack_bubble()
		"tower_selection":    _attack_selection()
		"tower_insertion":    _attack_insertion()
		"tower_quick":        _attack_quick()
		"tower_merge":        _attack_merge()
		"tower_counting":     _attack_counting()
		"tower_radix":        _attack_radix()
		"tower_linear":       _attack_linear()
		"tower_binary":       _attack_binary()
		_:                    _attack_default()

func _attack_array() -> void:
	if not _spire or not current_target:
		return
	current_target = current_target
	var hit_list = [current_target]
	var nearby = _get_nearby(2)
	for e in nearby:
		if e != current_target and not hit_list.has(e):
			hit_list.append(e)
			if hit_list.size() >= 3:
				break
	for t in hit_list:
		_spire.fire(t, damage * 0.4)

func _attack_stack() -> void:
	if not _spire or targets.is_empty():
		return
	var t = targets[-1]
	current_target = t
	_spire.fire(t, damage * 1.4)

func _attack_queue() -> void:
	if not _spire or targets.is_empty():
		return
	var t = targets[0]
	current_target = t
	_spire.fire(t, damage)

func _attack_linked() -> void:
	if not _spire or not current_target:
		return
	_spire.fire(current_target, damage)

func _attack_bubble() -> void:
	if not _spire or targets.is_empty():
		return
	var t = targets[0]
	current_target = t
	var nearby = _get_nearby(1)
	if nearby.size() >= 2:
		_spire.fire(t, damage * 0.8)
		_spire.fire(nearby[1], damage * 0.8)
	else:
		_spire.fire(t, damage * 0.6)

func _attack_selection() -> void:
	if not _spire or targets.is_empty():
		return
	var t = _get_lowest_hp(targets)
	current_target = t
	_spire.fire(t, damage * 1.8)

func _attack_insertion() -> void:
	if not _spire or not current_target:
		return
	_spire.fire(current_target, damage)
	if current_target.has_method("apply_dot"):
		current_target.apply_dot(damage * 0.3, 3.0)

func _attack_quick() -> void:
	if not _spire or targets.is_empty():
		return
	var t = targets[0]
	current_target = t
	_spire.fire(t, damage * 0.8)
	var nearby = _get_nearby(1)
	if nearby.size() >= 2:
		_spire.fire(nearby[1], damage * 0.8)

func _attack_merge() -> void:
	if not current_target:
		return
	var spawn_origin = position + Vector2(0, -14).rotated(_turret_angle)
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
		_projectiles.append(p)
	queue_redraw()

func _attack_counting() -> void:
	if not current_target:
		return
	var spawn_origin = position + Vector2(0, -14).rotated(_turret_angle)
	for i in range(5):
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
		_projectiles.append(p)
	queue_redraw()

func _attack_radix() -> void:
	if not current_target:
		return
	var spawn_origin = position + Vector2(0, -14).rotated(_turret_angle)
	var digits = [1, 10, 100]
	for i in range(3):
		var p = {
			"pos": spawn_origin,
			"start_pos": spawn_origin,
			"draw_pos": spawn_origin,
			"target": current_target,
			"target_last_pos": current_target.position,
			"speed": 320.0,
			"damage": damage * 0.4,
			"style": "radix_digit",
			"elapsed_time": 0.0,
			"digit": digits[i],
			"delay": i * 0.08
		}
		_projectiles.append(p)
	queue_redraw()

func _attack_linear() -> void:
	if not current_target:
		return
	var spawn_origin = position + Vector2(0, -14).rotated(_turret_angle)
	var p = {
		"pos": spawn_origin,
		"start_pos": spawn_origin,
		"draw_pos": spawn_origin,
		"target": current_target,
		"target_last_pos": current_target.position,
		"speed": 350.0,
		"damage": damage,
		"style": "linear_scan",
		"elapsed_time": 0.0,
		"total_dist": (current_target.position - spawn_origin).length()
	}
	_projectiles.append(p)
	queue_redraw()

func _attack_binary() -> void:
	if not current_target:
		return
	var spawn_origin = position + Vector2(0, -14).rotated(_turret_angle)
	var p = {
		"pos": spawn_origin,
		"start_pos": spawn_origin,
		"draw_pos": spawn_origin,
		"target": current_target,
		"target_last_pos": current_target.position,
		"speed": 450.0,
		"damage": damage * 2.2,
		"style": "binary_sniper",
		"elapsed_time": 0.0,
		"total_dist": (current_target.position - spawn_origin).length()
	}
	_projectiles.append(p)
	queue_redraw()

func _attack_default() -> void:
	_attack_array()

func _get_nearby(count: int) -> Array:
	var result: Array[Node] = []
	for t in targets:
		result.append(t)
		if result.size() >= count + 1:
			break
	return result

# ─── PROJECTILE SYSTEM ─────────────────────────────────
func _spawn_projectile(p_style: String, p_damage: float, p_speed: float, p_target: Node) -> void:
	if not is_instance_valid(p_target):
		return
	var spawn_origin = position + Vector2(0, -14).rotated(_turret_angle)
	var p = {
		"pos": spawn_origin,
		"start_pos": spawn_origin,
		"draw_pos": spawn_origin,
		"target": p_target,
		"target_last_pos": p_target.position,
		"speed": p_speed,
		"damage": p_damage,
		"style": p_style,
		"elapsed_time": 0.0,
		"total_dist": (p_target.position - spawn_origin).length()
	}
	_projectiles.append(p)

func _on_projectile_impact(p: Dictionary) -> void:
	if is_instance_valid(p["target"]) and p["target"].has_method("take_damage"):
		p["target"].take_damage(p["damage"])
	_spawn_impact_explosion(p["target_last_pos"], p["style"])
	if p["style"] == "chain_lightning" and p.has("chains_left") and p["chains_left"] > 0:
		var last_pos = p["target_last_pos"]
		var chained: Array[Node] = []
		for n in p["chained_targets"]:
			chained.append(n)
		var current_damage = p["damage"]
		var chains_left = p["chains_left"]
		while chains_left > 0:
			var next_target = _get_closest_to_point(last_pos, chained)
			if not next_target:
				break
			chains_left -= 1
			chained.append(next_target)
			current_damage *= 0.8
			var next_pos = next_target.position
			_spawn_chain_arc(last_pos, next_pos)
			if next_target.has_method("take_damage"):
				next_target.take_damage(current_damage)
			_spawn_impact_explosion(next_pos, "chain_lightning")
			last_pos = next_pos

func _get_closest_to_point(point: Vector2, exclude: Array[Node]) -> Node:
	_clean_targets()
	var best: Node = null
	var best_dist: float = attack_range + ENEMY_RADIUS * 2
	for e in targets:
		if exclude.has(e):
			continue
		var d = point.distance_to(e.global_position)
		if d <= best_dist:
			best_dist = d
			best = e
	return best

func _spawn_impact_explosion(pos: Vector2, style: String) -> void:
	var radius_map = {
		"stack_mortar": 18.0, "chain_lightning": 22.0, "queue_rail": 14.0,
		"binary_sniper": 16.0, "index_bolt": 8.0, "merge_beam": 14.0,
		"counting_pellet": 10.0, "radix_digit": 8.0, "linear_scan": 12.0
	}
	var max_r = radius_map.get(style, 8.0)
	var e = {
		"pos": pos - position,
		"style": style,
		"radius": 0.0,
		"max_radius": max_r,
		"elapsed": 0.0,
		"lifetime": 0.22
	}
	_explosions.append(e)

func _spawn_chain_arc(from_pos: Vector2, to_pos: Vector2) -> void:
	_chain_arcs.append({
		"from": from_pos - position,
		"to": to_pos - position,
		"elapsed": 0.0,
		"lifetime": 0.35
	})

# ─── DRAW ───────────────────────────────────────────────
func _draw() -> void:
	if _spire:
		if current_level > 1:
			draw_string(ThemeDB.fallback_font, Vector2(10, -spire_base_h * 0.5 * 0.5 - 14),
				"Lv" + str(current_level), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#FFB800"))
		if _selected:
			draw_circle(Vector2.ZERO, attack_range + ENEMY_RADIUS, Color(tower_color, 0.06))
			draw_arc(Vector2.ZERO, attack_range + ENEMY_RADIUS, 0, TAU, 64, Color(tower_color, 0.25), 1.5)
			draw_string(ThemeDB.fallback_font, Vector2(0, -attack_range - ENEMY_RADIUS - 14),
				"Range: " + str(attack_range), HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(tower_color, 0.7))
		return

	_draw_3d_base_plates(tower_color)
	_draw_turret_assembly(tower_color)
	_draw_overlays(tower_color)

	if current_level > 1:
		draw_string(ThemeDB.fallback_font, Vector2(10, -36),
			"Lv" + str(current_level), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#FFB800"))

	if _selected:
		draw_circle(Vector2.ZERO, attack_range + ENEMY_RADIUS, Color(tower_color, 0.06))
		draw_arc(Vector2.ZERO, attack_range + ENEMY_RADIUS, 0, TAU, 64, Color(tower_color, 0.25), 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(0, -attack_range - ENEMY_RADIUS - 14),
			"Range: " + str(attack_range), HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(tower_color, 0.7))

# ─── VOLUMETRIC 3D DRAWING HELPERS ─────────────────────
const SQUASH: float = 0.65

func _draw_ellipse(center: Vector2, radius: float, color: Color, filled: bool = true, width: float = -1.0) -> void:
	var points = PackedVector2Array()
	var steps = 24
	for i in range(steps + 1):
		var angle = i * (TAU / steps)
		points.append(center + Vector2(cos(angle) * radius, sin(angle) * radius * SQUASH))
	if filled:
		draw_colored_polygon(points, color)
	else:
		draw_polyline(points, color, width)

func _draw_lightning_bolt(from: Vector2, to: Vector2, color: Color) -> void:
	var steps = 4
	var points = PackedVector2Array()
	points.append(from)
	var dir = to - from
	var dist = dir.length()
	if dist > 4.0:
		var normal = Vector2(-dir.y, dir.x).normalized()
		for i in range(1, steps):
			var t = float(i) / steps
			var jag = sin(_anim_time * 25.0 + i * 5.0) * (dist * 0.12)
			var pt = from + dir * t + normal * jag
			points.append(pt)
	points.append(to)
	draw_polyline(points, color, 2.5)
	draw_polyline(points, Color.WHITE, 1.0)

func _draw_3d_cylinder(center: Vector2, radius: float, height: float, color: Color, outline_color: Color = Color.WHITE, line_width: float = 1.5) -> void:
	var left_x = center.x - radius
	var right_x = center.x + radius
	var wall_rect = Rect2(left_x, center.y, radius * 2.0, height)
	draw_rect(wall_rect, Color("#0F1720"), true)
	draw_rect(Rect2(left_x, center.y, radius, height), Color(outline_color, 0.15), true)
	draw_rect(Rect2(center.x, center.y, radius, height), Color(0, 0, 0, 0.25), true)
	draw_line(center + Vector2(-radius, 0), center + Vector2(-radius, height), outline_color, line_width)
	draw_line(center + Vector2(radius, 0), center + Vector2(radius, height), outline_color, line_width)
	draw_set_transform(center, 0.0, Vector2(1.0, SQUASH))
	draw_circle(Vector2.ZERO, radius, Color("#15202E"))
	draw_circle(Vector2.ZERO, radius, outline_color, false, line_width)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_3d_box(center: Vector2, extents: Vector2, height: float, color: Color, outline_color: Color = Color.WHITE, line_width: float = 1.5) -> void:
	var t_tl = center + Vector2(-extents.x, -extents.y * SQUASH)
	var t_tr = center + Vector2(extents.x, -extents.y * SQUASH)
	var t_br = center + Vector2(extents.x, extents.y * SQUASH)
	var t_bl = center + Vector2(-extents.x, extents.y * SQUASH)
	var b_tl = t_tl + Vector2(0, height)
	var b_tr = t_tr + Vector2(0, height)
	var b_br = t_br + Vector2(0, height)
	var b_bl = t_bl + Vector2(0, height)
	var r_panel = PackedVector2Array([t_tr, t_br, b_br, b_tr])
	draw_colored_polygon(r_panel, Color("#0D141C"))
	draw_polyline(PackedVector2Array([t_tr, t_br, b_br, b_tr]), outline_color, line_width)
	var f_panel = PackedVector2Array([t_bl, t_br, b_br, b_bl])
	draw_colored_polygon(f_panel, Color("#141D29"))
	draw_colored_polygon(f_panel, Color(outline_color, 0.15))
	draw_polyline(PackedVector2Array([t_bl, t_br, b_br, b_bl]), outline_color, line_width)
	var l_panel = PackedVector2Array([t_tl, t_bl, b_bl, b_tl])
	draw_colored_polygon(l_panel, Color("#101720"))
	draw_polyline(PackedVector2Array([t_tl, t_bl, b_bl, b_tl]), Color(outline_color, 0.4), line_width)
	var top_face = PackedVector2Array([t_tl, t_tr, t_br, t_bl])
	draw_colored_polygon(top_face, Color("#1E2C3D"))
	draw_polyline(PackedVector2Array([t_tl, t_tr, t_br, t_bl, t_tl]), outline_color, line_width)

func _draw_3d_hexagon(center: Vector2, radius: float, height: float, color: Color, outline_color: Color = Color.WHITE, line_width: float = 1.5) -> void:
	var top_pts = PackedVector2Array()
	for i in range(6):
		var angle = i * (PI / 3.0)
		top_pts.append(center + Vector2(cos(angle) * radius, sin(angle) * radius * SQUASH))
	for i in range(6):
		var next_i = (i + 1) % 6
		var t1 = top_pts[i]
		var t2 = top_pts[next_i]
		var b1 = t1 + Vector2(0, height)
		var b2 = t2 + Vector2(0, height)
		var mid_angle = i * (PI / 3.0) + (PI / 6.0)
		var l_dot = cos(mid_angle - 2.2)
		var shade_mix = lerp(0.05, 0.5, (l_dot + 1.0) / 2.0)
		var panel = PackedVector2Array([t1, t2, b2, b1])
		draw_colored_polygon(panel, Color("#0D131A"))
		draw_colored_polygon(panel, Color(outline_color, shade_mix * 0.4))
		draw_polyline(PackedVector2Array([t1, t2, b2, b1]), Color(outline_color, 0.4), 1.0)
	draw_colored_polygon(top_pts, Color("#1B2A3A"))
	var outline_loop = top_pts
	outline_loop.append(top_pts[0])
	draw_polyline(outline_loop, outline_color, line_width)

func _draw_3d_sphere(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(center, radius, Color("#0F1721"))
	draw_circle(center, radius, Color(color, 0.25))
	var highlight_c = center - Vector2(radius * 0.25, radius * 0.25)
	draw_circle(highlight_c, radius * 0.6, Color(color, 0.4))
	draw_circle(highlight_c, radius * 0.2, Color.WHITE)

func _get_polygon_points(sides: int, radius: float, offset: Vector2 = Vector2.ZERO, start_angle: float = 0.0) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(sides):
		var angle = start_angle + i * (TAU / sides)
		points.append(offset + Vector2(cos(angle), sin(angle)) * radius)
	return points

func _draw_3d_base_plates(color: Color) -> void:
	var base_height: float = 10.0
	var shadow_color = Color(0, 0, 0, 0.3)
	draw_set_transform(Vector2(4, 6), 0.0, Vector2.ONE)
	_draw_base_extrusion_geometry(shadow_color, base_height)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_base_extrusion_geometry(color, base_height)

func _draw_base_extrusion_geometry(color: Color, height: float) -> void:
	var b_offset = Vector2(0, 0)
	match tower_id:
		"tower_array":
			_draw_3d_box(b_offset, Vector2(17, 17), height, Color("#101721"), color, 1.8)
		"tower_stack":
			_draw_3d_hexagon(b_offset, 19.0, height, Color("#101721"), color, 1.8)
		"tower_queue":
			_draw_3d_box(b_offset, Vector2(23, 13), height, Color("#101721"), color, 1.8)
		"tower_linked_list":
			var top_pts = PackedVector2Array()
			for i in range(3):
				var angle = -PI/2 + i * (TAU / 3.0)
				top_pts.append(b_offset + Vector2(cos(angle) * 22.0, sin(angle) * 22.0 * SQUASH))
			for i in range(3):
				var next_i = (i + 1) % 3
				var t1 = top_pts[i]
				var t2 = top_pts[next_i]
				var b1 = t1 + Vector2(0, height)
				var b2 = t2 + Vector2(0, height)
				var panel = PackedVector2Array([t1, t2, b2, b1])
				draw_colored_polygon(panel, Color("#0D131A") if color.a < 0.5 else Color(color, 0.15))
				draw_polyline(PackedVector2Array([t1, t2, b2, b1]), color, 1.0)
			draw_colored_polygon(top_pts, Color("#141D29") if color.a < 0.5 else Color("#15202E"))
			var outline_loop = top_pts
			outline_loop.append(top_pts[0])
			draw_polyline(outline_loop, color, 1.8)
		"tower_merge":
			_draw_3d_cylinder(b_offset, 20.0, height, Color("#101721"), color, 1.8)
		"tower_counting":
			_draw_3d_box(b_offset, Vector2(18, 18), height, Color("#101721"), color, 1.8)
		"tower_radix":
			_draw_3d_cylinder(b_offset, 18.0, height, Color("#101721"), color, 1.8)
		"tower_linear":
			_draw_3d_cylinder(b_offset, 17.0, height, Color("#101721"), color, 1.8)
		"tower_binary", _:
			_draw_3d_box(b_offset, Vector2(25, 17), height, Color("#101721"), color, 1.8)

func _draw_turret_assembly(color: Color) -> void:
	var t_pivot = Vector2(0, -14)
	draw_set_transform(t_pivot, _turret_angle, Vector2.ONE)
	match tower_id:
		"tower_array":
			var recoil = -_recoil * 6.0
			_draw_3d_box(Vector2(0, 0), Vector2(22, 5), 7.0, Color("#15202E"), color, 1.5)
			for i in range(5):
				var bx = -9 + i * 4.5
				_draw_3d_cylinder(Vector2(bx + recoil, -2), 1.8, 8.0, Color("#1C2C3D"), color, 1.0)
				draw_circle(Vector2(bx + recoil + 8.0, -2 * SQUASH), 1.2, Color.BLACK)
			for i in range(5):
				draw_circle(Vector2(-9 + i * 4.5, 5), 1.0, Color(color, 0.5))
		"tower_stack":
			var recoil = -_recoil * 8.0
			for i in range(4):
				var sy = 5 - i * 3.5
				_draw_3d_cylinder(Vector2(0, sy), 4.5 - i * 0.4, 2.5, Color("#15202E"), Color(color, 0.3 + i * 0.12), 1.0)
			_draw_3d_cylinder(Vector2(recoil, -7), 4.0, 9.0, Color("#223344"), color, 1.5)
			draw_circle(Vector2(recoil + 9.0, -7 * SQUASH), 2.5, Color.BLACK)
		"tower_queue":
			var recoil = -_recoil * 9.0
			_draw_3d_box(Vector2(0, 0), Vector2(20, 3), 4.0, Color("#15202E"), color, 1.2)
			for i in range(4):
				var qx = -8 + i * 4.5
				_draw_3d_box(Vector2(qx, -2), Vector2(3, 2), 4.0, Color("#203040"), Color(color, 0.25 + i * 0.12), 1.0)
			_draw_3d_box(Vector2(9 + recoil, 0), Vector2(3, 6), 6.0, Color("#223344"), color, 1.2)
			draw_circle(Vector2(12 + recoil, 0), 2.0, Color.BLACK)
			draw_line(Vector2(-12, 4), Vector2(-14, 1), Color(color, 0.4), 1.0)
			draw_line(Vector2(-12, 4), Vector2(-14, 7), Color(color, 0.4), 1.0)
		"tower_linked_list":
			var recoil = -_recoil * 5.0
			_draw_3d_sphere(Vector2.ZERO, 4.0, color)
			var nodes = [
				Vector2(8.0, 0.0),
				Vector2(-4.0, -6.0 * SQUASH),
				Vector2(-4.0, 6.0 * SQUASH)
			]
			for i in range(3):
				var j = (i + 1) % 3
				draw_line(nodes[i], nodes[j], color, 1.5)
			for i in range(3):
				var n = nodes[i]
				_draw_3d_sphere(n, 3.0, Color(color, 0.4 + i * 0.2))
				_draw_3d_cylinder(Vector2(n.x + 3 + recoil, n.y), 1.5, 5.0, Color("#203040"), color, 1.0)
				draw_circle(Vector2(n.x + 8 + recoil, n.y * SQUASH), 1.0, Color.BLACK)
		"tower_merge":
			var recoil = -_recoil * 7.0
			_draw_3d_cylinder(Vector2(-6, -7), 2.5, 5.0, Color("#15202E"), color, 1.0)
			_draw_3d_cylinder(Vector2(-6, 7), 2.5, 5.0, Color("#15202E"), color, 1.0)
			draw_line(Vector2(-4, -5), Vector2(0, 0), color, 1.5)
			draw_line(Vector2(-4, 5), Vector2(0, 0), color, 1.5)
			_draw_3d_sphere(Vector2.ZERO, 4.5, Color(color, 0.6))
			_draw_3d_cylinder(Vector2(5 + recoil, 0), 3.5, 9.0, Color("#223344"), color, 1.5)
			draw_circle(Vector2(14 + recoil, 0), 2.5, Color.BLACK)
		"tower_counting":
			var recoil = -_recoil * 4.0
			_draw_3d_box(Vector2(0, 0), Vector2(24, 3), 4.0, Color("#15202E"), color, 1.2)
			for i in range(6):
				var bx = -11 + i * 4.5
				var bh = 3.0 + i * 2.0
				_draw_3d_cylinder(Vector2(bx + recoil, -bh/2 - 1), 1.8, bh, Color("#1C2C3D"), Color(color, 0.3 + i * 0.1), 1.0)
				draw_circle(Vector2(bx + recoil + bh, (-bh/2 - 1) * SQUASH), 1.0, Color.BLACK)
			_draw_3d_box(Vector2(0, -10), Vector2(14, 2), 2.0, Color("#203040"), Color(color, 0.5), 1.0)
		"tower_radix":
			var recoil = -_recoil * 6.0
			_draw_3d_sphere(Vector2.ZERO, 4.5, color)
			for i in range(3):
				draw_set_transform(Vector2.ZERO, i * 0.4, Vector2(1.0, SQUASH))
				draw_arc(Vector2.ZERO, 9.0 + i * 2.5, 0, PI * 1.7, 14, Color(color, 0.25 + i * 0.15), 2.0 - i * 0.3)
				draw_set_transform(t_pivot, _turret_angle, Vector2.ONE)
			_draw_3d_cylinder(Vector2(6 + recoil, 0), 2.5, 7.0, Color("#203040"), color, 1.0)
			draw_circle(Vector2(13 + recoil, 0), 1.8, Color.BLACK)
			for i in range(8):
				var da = i * TAU / 8.0
				draw_circle(Vector2(cos(da) * 7.5, sin(da) * 7.5 * SQUASH), 0.8, Color(color, 0.6))
		"tower_linear":
			var recoil = -_recoil * 9.0
			_draw_3d_box(Vector2(0, 0), Vector2(24, 2), 2.0, Color("#101721"), Color(color, 0.25), 1.0)
			_draw_3d_box(Vector2(recoil, -2), Vector2(5, 3), 3.0, Color("#15202E"), color, 1.2)
			_draw_3d_cylinder(Vector2(4 + recoil, -2), 2.5, 8.0, Color("#203040"), color, 1.0)
			draw_circle(Vector2(12 + recoil, -2 * SQUASH), 1.5, Color.BLACK)
			for i in range(7):
				draw_circle(Vector2(-12 + i * 4, 3), 0.6, Color(color, 0.3))
		"tower_binary", _:
			var recoil = -_recoil * 12.0
			_draw_3d_box(Vector2(-4, 0), Vector2(10, 8), 9.0, Color("#15202E"), color, 1.8)
			_draw_3d_cylinder(Vector2(6 + recoil, 0), 3.5, 18.0, Color("#203040"), color, 1.2)
			draw_circle(Vector2(24 + recoil, 0), 2.5, Color.BLACK)
			_draw_3d_cylinder(Vector2(4 + recoil, 0), 6.0, 3.0, Color("#101721"), color, 1.2)
			_draw_3d_cylinder(Vector2(16 + recoil, 0), 5.0, 3.0, Color("#101721"), color, 1.2)
			var ch = 3.5
			draw_line(Vector2(4 + recoil, -ch), Vector2(4 + recoil, ch), Color(color, 0.8), 1.5)
			draw_line(Vector2(4 + recoil - ch, 0), Vector2(4 + recoil + ch, 0), Color(color, 0.8), 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_shaded_capsule(center: Vector2, radius: float, base_color: Color, highlight_color: Color) -> void:
	draw_circle(center, radius, base_color)
	draw_circle(center, radius, Color(highlight_color, 0.35))
	draw_circle(center - Vector2(radius * 0.25, radius * 0.25), radius * 0.5, Color.WHITE)

func _draw_binary_trail(pos: Vector2, trail_color: Color) -> void:
	var is_one = int(pos.x + pos.y + _anim_time * 20.0) % 2 == 0
	var col = Color(trail_color, 0.5)
	if is_one:
		draw_line(pos - Vector2(0, 3), pos + Vector2(0, 3), col, 1.5)
	else:
		draw_rect(Rect2(pos - Vector2(2, 3), Vector2(4, 6)), col, false, 1.0)

func _draw_overlays(color: Color) -> void:
	for p in _projectiles:
		var rd = p["draw_pos"] - position
		var rp = p["pos"] - position
		match p["style"]:
			"index_bolt":
				var idx = p.get("index", 0)
				var phase = sin(_anim_time * 20.0 + idx) * 1.5
				var sz = 3.0 + phase * 0.3
				var pts = PackedVector2Array([rd + Vector2(sz, 0), rd + Vector2(0, -sz), rd + Vector2(-sz, 0), rd + Vector2(0, sz)])
				draw_colored_polygon(pts, Color.WHITE)
				draw_colored_polygon(pts, Color(color, 0.5))
				draw_string(ThemeDB.fallback_font, rd + Vector2(-3, 3), str(idx), HORIZONTAL_ALIGNMENT_CENTER, -1, 7, color)
				draw_circle(rp + Vector2(2, 5), 3.0, Color(0, 0, 0, 0.15))
			"stack_mortar":
				var t = p["elapsed_time"] / (p["total_dist"] / p["speed"]) if p["total_dist"] > 0 else 1.0
				var grow = 4.0 + sin(t * PI) * 2.0
				draw_circle(rp + Vector2(2, 5), 5.0, Color(0, 0, 0, 0.2))
				_draw_shaded_capsule(rd, grow, Color("#4B5B6D"), color)
				draw_circle(rd - Vector2(3, -2), 1.5, Color(color, 0.7))
				draw_line(rd - Vector2(0, grow), rd - Vector2(0, grow + 4), Color("#8899AA"), 2.0)
			"queue_rail":
				var heading = (p["target_last_pos"] - p["pos"]).normalized()
				var line_start = rd - heading * 16.0
				draw_line(line_start, rd, Color.WHITE, 4.0)
				draw_line(line_start, rd, color, 2.0)
				for j in range(3):
					var dot_pos = line_start + heading * j * 5.0
					draw_circle(dot_pos, 1.5, Color(color, 0.6 - j * 0.15))
			"chain_lightning":
				var heading = (p["target_last_pos"] - p["pos"]).normalized() if (p["target_last_pos"] - p["pos"]).length() > 0 else Vector2.RIGHT
				var dist = p["total_dist"]
				var travel = clamp(p["elapsed_time"] / (dist / p["speed"]), 0.0, 1.0) if dist > 0 else 1.0
				var segments = 6
				var prev = rd
				for j in range(segments):
					var frac = (j + 1.0) / segments
					var base_pos = rd + heading * frac * dist * travel * 0.5
					var jitter = Vector2(cos(_anim_time * 40.0 + j * 3.0), sin(_anim_time * 40.0 + j * 3.0)) * 4.0
					var next = base_pos + jitter
					draw_line(prev, next, Color.WHITE, 2.5 - j * 0.3)
					draw_line(prev, next, color, 1.0)
					prev = next
			"merge_beam":
				var frac = clamp(p["elapsed_time"] / (p["total_dist"] / p["speed"]), 0.0, 1.0) if p["total_dist"] > 0 else 1.0
				var side = p.get("merge_side", "left")
				var offset = Vector2((-6 if side == "left" else 6) * (1.0 - frac), (-6 if side == "left" else 6) * (1.0 - frac))
				var beam_pos = rd + offset
				draw_line(rd, beam_pos, Color(color, 0.6), 2.5)
				draw_circle(beam_pos, 3.0, Color.WHITE)
				draw_circle(beam_pos, 5.0, Color(color, 0.3))
			"counting_pellet":
				var digit = p.get("digit", 1)
				var trail_pts = PackedVector2Array()
				var step = 4
				for j in range(5):
					var t_pos = rd - Vector2(j * step, sin(_anim_time * 10.0 + j + digit) * 2.0)
					trail_pts.append(t_pos)
				for j in range(trail_pts.size() - 1):
					draw_line(trail_pts[j], trail_pts[j + 1], Color(color, 0.4 - j * 0.07), 1.5)
				var sz = 2.0 + digit * 0.3
				draw_circle(rd, sz, Color.WHITE)
				draw_circle(rd, sz + 1.5, Color(color, 0.5))
				draw_string(ThemeDB.fallback_font, rd + Vector2(-2, 3), str(digit), HORIZONTAL_ALIGNMENT_CENTER, -1, 6, color)
			"radix_digit":
				var digit = p.get("digit", 1)
				var rot_off = _anim_time * 8.0 + digit
				var orbit_pos = rd + Vector2(cos(rot_off) * 4.0, sin(rot_off) * 4.0)
				draw_circle(orbit_pos, 2.5, Color.WHITE)
				draw_circle(orbit_pos, 4.5, Color(color, 0.5 - (digit % 10) * 0.05))
				draw_arc(orbit_pos, 6.0, rot_off, rot_off + PI * 0.8, 6, color, 1.5)
				draw_string(ThemeDB.fallback_font, orbit_pos + Vector2(-3, 3), str(digit), HORIZONTAL_ALIGNMENT_CENTER, -1, 6, Color("#FFFFFF"))
			"linear_scan":
				var heading = (p["target_last_pos"] - p["pos"]).normalized() if (p["target_last_pos"] - p["pos"]).length() > 0 else Vector2.RIGHT
				var perp = Vector2(-heading.y, heading.x)
				draw_line(rd - perp * 8.0, rd + perp * 8.0, Color.WHITE, 2.0)
				draw_line(rd - perp * 8.0, rd + perp * 8.0, Color(color, 0.6), 1.0)
				draw_circle(rd, 2.0, Color.WHITE)
				draw_circle(rd, 4.0, Color(color, 0.4))
			"binary_sniper":
				var heading = (p["target_last_pos"] - p["pos"]).normalized() if (p["target_last_pos"] - p["pos"]).length() > 0 else Vector2.RIGHT
				var perp = Vector2(-heading.y, heading.x)
				var ch = 4.0 + sin(_anim_time * 15.0) * 1.0
				draw_line(rd + perp * ch, rd - perp * ch, Color.WHITE, 2.0)
				draw_line(rd + heading * ch, rd - heading * ch, Color.WHITE, 2.0)
				draw_circle(rd, 2.5, Color.WHITE)
				draw_circle(rd, 5.0, Color(color, 0.6))
				draw_line(rd - heading * 6.0, rd, Color(color, 0.8), 2.5)
			_:
				draw_circle(rd, 2.8, Color.WHITE)
				draw_circle(rd, 4.8, color)

	for e in _explosions:
		var life_ratio = e["elapsed"] / e["lifetime"]
		var flash_val = 1.0 - life_ratio
		var e_color = Color(color, flash_val)
		match e["style"]:
			"stack_mortar":
				draw_arc(e["pos"], e["radius"], 0, TAU, 32, e_color, 2.5)
				draw_circle(e["pos"], e["radius"] * 0.6, Color(color, flash_val * 0.35))
				draw_string(ThemeDB.fallback_font, e["pos"] + Vector2(-8, -8), "POP", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color("#FFB800"))
			"queue_rail", "binary_sniper":
				draw_line(e["pos"] - Vector2(e["radius"], 0), e["pos"] + Vector2(e["radius"], 0), e_color, 2.0)
				draw_line(e["pos"] - Vector2(0, e["radius"]), e["pos"] + Vector2(0, e["radius"]), e_color, 2.0)
				draw_circle(e["pos"], 4.5 * flash_val, Color.WHITE)
			"counting_pellet", "radix_digit":
				var count = 5
				for j in range(count):
					var a = (TAU / count) * j + _anim_time * 5.0
					draw_circle(e["pos"] + Vector2(cos(a), sin(a)) * e["radius"] * 0.6, 2.0, Color(color, flash_val * (1.0 - j * 0.1)))
			"index_bolt":
				draw_circle(e["pos"], e["radius"] * 0.5, Color.WHITE)
				draw_circle(e["pos"], e["radius"], Color(color, flash_val * 0.5))
			_:
				draw_arc(e["pos"], e["radius"], 0, TAU, 16, e_color, 1.5)

	if _shoot_flash > 0:
		var flash_color = Color(color, _shoot_flash)
		for target_offset in _flash_targets:
			draw_line(Vector2.ZERO, target_offset, flash_color, 2.5)
		draw_circle(Vector2.ZERO, 8.0 * _shoot_flash, flash_color)
		draw_circle(Vector2.ZERO, 4.0 * _shoot_flash, Color.WHITE)

	for arc in _chain_arcs:
		var life = 1.0 - (arc["elapsed"] / arc["lifetime"])
		var pts = PackedVector2Array()
		pts.append(arc["from"])
		var dir = arc["to"] - arc["from"]
		var dist = dir.length()
		if dist > 4.0:
			var n = Vector2(-dir.y, dir.x).normalized()
			for i in range(1, 4):
				var f = float(i) / 4.0
				var jag = sin(_anim_time * 25.0 + i * 5.0) * (dist * 0.12)
				pts.append(arc["from"] + dir * f + n * jag)
		pts.append(arc["to"])
		draw_polyline(pts, Color(color, life), 2.5)
		draw_polyline(pts, Color(1, 1, 1, life), 1.0)

	if Engine.is_editor_hint():
		draw_arc(Vector2.ZERO, attack_range, 0, TAU, 64, Color(color, 0.15), 1.0)
