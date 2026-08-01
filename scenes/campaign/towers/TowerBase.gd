# TowerBase.gd
# Base class for all towers. Contains shared logic: range detection,
# attack timers, projectile management, turret rotation, drawing helpers.
# Subclasses override: _select_target, _perform_attack, _get_upgrade_stats,
# _draw_base_geometry, _draw_turret_assembly, _get_ability_targets

class_name TowerBase
extends Node2D

const ENEMY_RADIUS: float = 20.0
const SQUASH: float = 0.65

# ─── STATS (shared) ─────────────────────────────────────
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
var targets: Array[Node]       = []
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

# ─── STYLE ─────────────────────────────────────────────
var style: TowerStyle = null

# ─── NODE REFERENCES ───────────────────────────────────
@onready var base_sprite: Node2D    = $BaseSprite
@onready var turret_head: Node2D    = $TurretHead
@onready var muzzle_point: Node2D   = $TurretHead/MuzzlePoint
@onready var projectile_layer: Node2D = $ProjectileLayer

func _ready() -> void:
	if tower_id == "":
		_setup_visual()

func initialize(data: TowerData, cell: Vector2i, e_layer: Node2D) -> void:
	tower_id      = data.tower_id
	tower_name    = data.tower_name
	damage        = data.damage
	attack_speed  = data.attack_speed
	attack_range  = data.attack_range
	ram_cost      = data.ram_cost
	tower_color   = data.color
	icon_text     = data.icon_text
	style         = data.get("style") if data.has_method("get") and data.get("style") != null else null
	grid_cell     = cell
	enemy_layer   = e_layer
	current_level = 1
	_setup_visual()
	z_index = 1
	if not preview_mode:
		_setup_range_area()
		_animate_placement()
	queue_redraw()

func _setup_visual() -> void:
	if base_sprite:
		base_sprite.visible = true
	if turret_head:
		turret_head.position = Vector2(0, -14)
	if muzzle_point:
		muzzle_point.position = Vector2.ZERO

func ensure_style() -> TowerStyle:
	if style == null:
		style = TowerStyle.new()
	return style

func get_muzzle_position() -> Vector2:
	# Returns spawn point in parent (tower_layer) local space — same coordinate
	# space as the original `position + Vector2(0, -14).rotated(_turret_angle)`.
	# Projectiles and targets are in this same parent space when layers
	# are siblings at origin.
	var head_offset = turret_head.position if turret_head else Vector2(0, -14)
	var muzzle_offset = muzzle_point.position if muzzle_point else Vector2.ZERO
	var total_offset = (head_offset + muzzle_offset).rotated(_turret_angle)
	return position + total_offset

func _setup_range_area() -> void:
	var range_area = Area2D.new()
	range_area.name = "RangeDetector"
	range_area.collision_mask = 1
	range_area.monitoring = true
	range_area.monitorable = false

	var range_shape = CollisionShape2D.new()
	range_shape.name = "RangeShape"
	var circle = CircleShape2D.new()
	circle.radius = attack_range + ENEMY_RADIUS
	range_shape.shape = circle
	range_area.add_child(range_shape)

	range_area.body_entered.connect(_on_enemy_entered)
	range_area.body_exited.connect(_on_enemy_exited)
	add_child(range_area)

func _on_enemy_entered(body: Node) -> void:
	if not body.has_method("take_damage"):
		return
	if not targets.has(body):
		targets.append(body)
		if not preview_mode:
			attack_timer = 0.0
			_perform_attack()

func _on_enemy_exited(body: Node) -> void:
	targets.erase(body)
	if body == current_target:
		current_target = null

func _clean_targets() -> void:
	targets = targets.filter(func(t):
		return is_instance_valid(t) and not t.is_dead
	)

# ─── TARGET SELECTION (virtual) ────────────────────────
func _select_target() -> Node:
	_clean_targets()
	if targets.is_empty():
		return null
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

func _get_nearby(count: int) -> Array:
	var result: Array[Node] = []
	for t in targets:
		result.append(t)
		if result.size() >= count + 1:
			break
	return result

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

# ─── ABILITY (framework) ───────────────────────────────
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
	var abil_targets = _get_ability_targets()
	_apply_ability_damage(damage * dmg_mult, abil_targets)
	ability_cooldown = ability_max_cooldown
	_animate_upgrade()
	return true

func _get_ability_targets() -> Array:
	# Default: all enemies within 1.5x range
	if not enemy_layer:
		return targets.duplicate()
	var result: Array = []
	var radius = attack_range * 1.5
	for child in enemy_layer.get_children():
		if is_instance_valid(child) and child.has_method("take_damage"):
			var dist = global_position.distance_to(child.global_position)
			if dist <= radius:
				result.append(child)
	return result

func _get_ability_damage_multiplier() -> float:
	return 1.0

func _apply_ability_damage(dmg: float, abil_targets: Array) -> void:
	if not enemy_layer:
		return
	if abil_targets.is_empty():
		return
	var mult = _get_ability_damage_multiplier()
	for e in abil_targets:
		if is_instance_valid(e) and e.has_method("take_damage"):
			e.take_damage(dmg * mult)
	_shoot_flash = 2.0
	queue_redraw()

# ─── UPGRADE (framework) ─────────────────────────────────
func upgrade() -> int:
	if current_level >= max_level:
		return current_level
	current_level += 1
	var mults = _get_upgrade_stats(current_level)
	damage *= mults.get("damage", 1.0)
	attack_speed *= mults.get("speed", 1.0)
	attack_range *= mults.get("range", 1.0)
	var ra = get_node_or_null("RangeDetector")
	if ra and ra.has_node("RangeShape"):
		var shape = ra.get_node("RangeShape").shape as CircleShape2D
		if shape:
			shape.radius = attack_range + ENEMY_RADIUS
	SignalBus.tower_upgraded.emit(tower_id, current_level)
	_animate_upgrade()
	return current_level

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.0, "speed": 1.0, "range": 1.0}

func _animate_upgrade() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
	tween.tween_property(self, "scale", Vector2(1.35, 1.35), 0.25)
	_shoot_flash = 1.5
	queue_redraw()

func _animate_placement() -> void:
	scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.35, 1.35), 0.35)

# ─── PROCESS ────────────────────────────────────────────
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

	var target = _select_target()
	if target != current_target:
		current_target = target

	# Rotate turret toward target
	if is_instance_valid(current_target):
		var desired_angle = (current_target.global_position - global_position).angle()
		_turret_angle = lerp_angle(_turret_angle, desired_angle, delta * 8.0)
	else:
		_turret_angle = lerp_angle(_turret_angle, -PI / 2, delta * 2.0)

	# Sync turret_head node rotation
	if turret_head:
		turret_head.rotation = _turret_angle

	if _shoot_flash > 0:
		_shoot_flash -= delta * 4.0

	_mobile_redraw_skip += 1
	if _mobile_redraw_skip % 2 == 0:
		queue_redraw()

	_update_projectiles(delta)
	_update_explosions(delta)
	_update_arcs(delta)

	if attack_timer >= 1.0 / attack_speed and current_target != null:
		attack_timer = 0.0
		_perform_attack()

# ─── ATTACK (virtual — subclasses override) ──────────────
func _perform_attack() -> void:
	if not current_target:
		return
	SoundManager.play_tower_attack(tower_id)
	_recoil = 1.0
	_flash_targets.clear()

# ─── SHARED PROJECTILE SYSTEM ────────────────────────────
func _play_attack_sound() -> void:
	SoundManager.play_tower_attack(tower_id)

func _spawn_projectile(p_style: String, p_damage: float, p_speed: float, p_target: Node, extra: Dictionary = {}) -> void:
	if not is_instance_valid(p_target):
		return
	var spawn_origin = get_muzzle_position()
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
		"total_dist": (p_target.position - spawn_origin).length(),
	}
	for k in extra.keys():
		p[k] = extra[k]
	_projectiles.append(p)

func _spawn_custom_projectile(p: Dictionary) -> void:
	_projectiles.append(p)

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
	_draw_base()
	_draw_turret()
	_draw_overlays(tower_color)
	_draw_hud_elements()

func _draw_base() -> void:
	var s = ensure_style()
	var base_height = s.base_height
	var shadow_color = Color(0, 0, 0, s.shadow_alpha)
	draw_set_transform(s.shadow_offset, 0.0, Vector2.ONE)
	_draw_base_geometry(shadow_color, base_height)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_base_geometry(tower_color, base_height)

func _draw_turret() -> void:
	var s = ensure_style()
	var t_pivot = turret_head.position if turret_head else Vector2(0, -14)
	var t_rot = turret_head.rotation if turret_head else _turret_angle
	draw_set_transform(t_pivot, t_rot, Vector2.ONE)
	_draw_turret_assembly(tower_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_base_geometry(color: Color, height: float) -> void:
	# Virtual — subclasses override with type-specific base shape
	pass

func _draw_turret_assembly(color: Color) -> void:
	# Virtual — subclasses override with type-specific turret
	pass

func _draw_hud_elements() -> void:
	if current_level > 1:
		draw_string(ThemeDB.fallback_font, Vector2(10, -36),
			"Lv" + str(current_level), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#FFB800"))

	if _selected:
		draw_circle(Vector2.ZERO, attack_range + ENEMY_RADIUS, Color(tower_color, 0.06))
		draw_arc(Vector2.ZERO, attack_range + ENEMY_RADIUS, 0, TAU, 64, Color(tower_color, 0.25), 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(0, -attack_range - ENEMY_RADIUS - 14),
			"Range: " + str(attack_range), HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(tower_color, 0.7))

	if Engine.is_editor_hint():
		draw_arc(Vector2.ZERO, attack_range, 0, TAU, 64, Color(tower_color, 0.15), 1.0)

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
					var next_pt = base_pos + jitter
					draw_line(prev, next_pt, Color.WHITE, 2.5 - j * 0.3)
					draw_line(prev, next_pt, color, 1.0)
					prev = next_pt
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
			"bubble_pulse":
				var t = p["elapsed_time"] / (p["total_dist"] / p["speed"]) if p["total_dist"] > 0 else 1.0
				var pulse = sin(t * PI * 4.0) * 2.0
				draw_circle(rd, 4.0 + pulse, Color(color, 0.4))
				draw_circle(rd, 2.0, Color.WHITE)
				draw_line(rd - Vector2(6, 0), rd + Vector2(6, 0), color, 2.0)
				draw_line(rd - Vector2(0, 6), rd + Vector2(0, 6), color, 2.0)
			"selection_sniper":
				var heading = (p["target_last_pos"] - p["pos"]).normalized() if (p["target_last_pos"] - p["pos"]).length() > 0 else Vector2.RIGHT
				var perp = Vector2(-heading.y, heading.x)
				draw_line(rd - perp * 12.0, rd + perp * 12.0, Color.WHITE, 1.5)
				draw_line(rd - perp * 12.0, rd + perp * 12.0, color, 1.0)
				draw_line(rd - Vector2(16, 0), rd + Vector2(16, 0), Color.WHITE, 1.0)
				draw_circle(rd, 3.0, Color.WHITE)
				draw_circle(rd, 6.0, Color(color, 0.6))
			"insertion_needle":
				var heading = (p["target_last_pos"] - p["pos"]).normalized() if (p["target_last_pos"] - p["pos"]).length() > 0 else Vector2.RIGHT
				var perp = Vector2(-heading.y, heading.x)
				draw_line(rd - heading * 10.0, rd + heading * 10.0, Color.WHITE, 3.0)
				draw_line(rd - heading * 10.0, rd + heading * 10.0, color, 2.0)
				draw_line(rd - perp * 4.0, rd + perp * 4.0, Color(color, 0.5), 1.5)
				draw_circle(rd, 2.0, Color.WHITE)
			"quick_split":
				var heading = (p["target_last_pos"] - p["pos"]).normalized() if (p["target_last_pos"] - p["pos"]).length() > 0 else Vector2.RIGHT
				var perp = Vector2(-heading.y, heading.x)
				draw_line(rd - perp * 8.0, rd + perp * 8.0, Color.WHITE, 2.5)
				draw_line(rd - perp * 8.0, rd + perp * 8.0, color, 1.5)
				draw_circle(rd + perp * 8.0, 2.0, Color.WHITE)
				draw_circle(rd - perp * 8.0, 2.0, Color.WHITE)
				draw_circle(rd, 3.0, Color(color, 0.7))
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

# ─── 3D PRIMITIVE HELPERS (shared) ──────────────────────
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

func _draw_shaded_capsule(center: Vector2, radius: float, base_color: Color, highlight_color: Color) -> void:
	draw_circle(center, radius, base_color)
	draw_circle(center, radius, Color(highlight_color, 0.35))
	draw_circle(center - Vector2(radius * 0.25, radius * 0.25), radius * 0.5, Color.WHITE)

func _get_polygon_points(sides: int, radius: float, offset: Vector2 = Vector2.ZERO, start_angle: float = 0.0) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(sides):
		var angle = start_angle + i * (TAU / sides)
		points.append(offset + Vector2(cos(angle), sin(angle)) * radius)
	return points

# ─── UTILITY ────────────────────────────────────────────
func get_type_id() -> String:
	# Override in each subclass to return the tower_id (e.g., "tower_array")
	return ""

func get_tower_id() -> String:
	return tower_id

func get_tower_name() -> String:
	return tower_name

func get_icon_text() -> String:
	return icon_text

func get_tower_color() -> Color:
	return tower_color

func can_target() -> bool:
	return not targets.is_empty()
