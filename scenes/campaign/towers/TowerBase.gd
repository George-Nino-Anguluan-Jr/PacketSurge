# TowerBase.gd
# Base class for all towers. Contains shared logic: range detection,
# attack timers, projectile management, turret rotation, drawing helpers.
# Subclasses override: _select_target, _perform_attack, _get_upgrade_stats,
# _draw_base_geometry, _draw_turret_assembly, _get_ability_targets

class_name TowerBase
extends Node2D

const ENEMY_RADIUS: float = 20.0
const IMPACT_DISTANCE: float = 14.0
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

# ─── SPRITE ───────────────────────────────────────────
var _base_sprite_2d: Sprite2D = null
var _using_sprites: bool = false
var _spire: Node2D = null

const SPIRE_VARIANT_MAP: Dictionary = {}

func _ready() -> void:
	if tower_id == "":
		_setup_visual()
	if not _using_sprites and tower_id != "":
		_load_sprites()

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
	if is_inside_tree():
		_load_sprites()
	else:
		tree_entered.connect(_load_sprites)
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

func _load_sprites() -> void:
	if tower_id == "":
		return
	if not is_inside_tree():
		return
	if _using_sprites:
		return
	if not SPIRE_VARIANT_MAP.has(tower_id):
		return

	var variant: String = str(SPIRE_VARIANT_MAP[tower_id])
	var test_path: String = "res://assets/sprites/towers/spire/imported/" + variant + "/base/level_01.png"
	if not ResourceLoader.exists(test_path):
		return

	var SpireTowerScript = preload("res://scenes/campaign/towers/SpireTower.gd")
	_spire = SpireTowerScript.new()
	add_child(_spire)
	_spire.setup(variant)
	_spire.set_level(current_level)
	_using_sprites = true

	if turret_head:
		turret_head.visible = false
	if base_sprite:
		base_sprite.visible = false
	queue_redraw()

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

func _get_closest_to_point(point: Vector2, exclude: Array[Node], max_dist: float = -1.0) -> Node:
	_clean_targets()
	var best: Node = null
	var best_dist: float = attack_range + ENEMY_RADIUS * 2 if max_dist < 0.0 else max_dist
	for e in targets:
		if exclude.has(e):
			continue
		var d = point.distance_to(e.global_position)
		if d <= best_dist:
			best_dist = d
			best = e
	return best

func _get_nearest(count: int) -> Array:
	# Returns the closest `count` live enemies to this tower (by global distance).
	var list: Array = []
	for e in targets:
		if is_instance_valid(e) and not e.is_dead:
			list.append(e)
	list.sort_custom(func(a, b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	var out: Array = []
	for i in range(min(count, list.size())):
		out.append(list[i])
	return out

func _get_enemies_sorted_by_progress() -> Array:
	# Enemies ordered along the path (waypoint progress). Used by Queue/Linked
	# List/Stack to express list/queue/tree ordering instead of raw distance.
	var list: Array = []
	for e in targets:
		if is_instance_valid(e) and not e.is_dead and e.has_method("get_path_progress"):
			list.append(e)
	list.sort_custom(func(a, b): return a.get_path_progress() < b.get_path_progress())
	return list

func _get_median_target() -> Node:
	# Binary tower: divide & conquer picks the middle enemy along the path.
	var list = _get_enemies_sorted_by_progress()
	if list.is_empty():
		return null
	return list[int(list.size() / 2)]

func _get_next_along_path(anchor, exclude: Array[Node], max_dist: float) -> Node:
	# Linked List / Quick: following the linked nodes in path order == the next enemy
	# along the route (lowest progress greater than the anchor's), within range.
	if not anchor or not is_instance_valid(anchor) or not anchor.has_method("get_path_progress"):
		return null
	var anchor_prog: float = anchor.get_path_progress()
	var best: Node = null
	var best_prog: float = INF
	for e in targets:
		if not is_instance_valid(e) or e.is_dead or exclude.has(e):
			continue
		if not e.has_method("get_path_progress"):
			continue
		var prog: float = e.get_path_progress()
		if prog <= anchor_prog:
			continue
		if anchor.global_position.distance_to(e.global_position) > max_dist:
			continue
		if prog < best_prog:
			best_prog = prog
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
			e.take_damage(dmg * mult, tower_id)
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
	if _spire:
		_spire.set_level(current_level)
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

	if _spire:
		_spire.aim(_turret_angle)

	if _shoot_flash > 0:
		_shoot_flash -= delta * 4.0

	_mobile_redraw_skip += 1
	if not _projectiles.is_empty() or not _explosions.is_empty() or not _chain_arcs.is_empty():
		queue_redraw()
	elif _mobile_redraw_skip % 2 == 0:
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
	if _spire:
		_spire.fire(p_target, p_damage)
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
	if _spire and p.has("damage"):
		var t = p.get("target", current_target)
		if is_instance_valid(t):
			_spire.fire(t, p["damage"])
			return
	_projectiles.append(p)

func _update_projectiles(delta: float) -> void:
	var remaining: Array[Dictionary] = []
	for p in _projectiles:
		if p.get("impacted"):
			if is_instance_valid(p["target"]):
				var aim: Vector2 = p["target"].get_aim_point() if p["target"].has_method("get_aim_point") else p["target"].position
				p["pos"] = aim
				p["draw_pos"] = aim
			p["impacted_frames"] = p.get("impacted_frames", 1) - 1
			if p["impacted_frames"] > 0:
				remaining.append(p)
			continue
		p["elapsed_time"] += delta
		if p.has("delay") and p["delay"] > 0:
			p["delay"] -= delta
			if p["delay"] > 0:
				remaining.append(p)
				continue
		if _is_pierce_beam(p):
			if _update_pierce_beam(p, delta):
				remaining.append(p)
			continue
		var target_pos = p["target_last_pos"]
		if is_instance_valid(p["target"]):
			target_pos = p["target"].get_aim_point() if p["target"].has_method("get_aim_point") else p["target"].position
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
		if next_pos.distance_to(target_pos) < IMPACT_DISTANCE:
			p["pos"] = target_pos
			p["draw_pos"] = target_pos
			_on_projectile_impact(p)
			p["impacted"] = true
			p["impacted_frames"] = 3
			remaining.append(p)
		else:
			remaining.append(p)
	_projectiles = remaining

func _is_pierce_beam(p: Dictionary) -> bool:
	var s: String = p.get("style", "")
	return s == "queue_pierce" or s == "linear_beam"

func _update_pierce_beam(p: Dictionary, delta: float) -> bool:
	# Straight-line beam: flies along beam_dir, sweeps a lateral hit zone,
	# and hits each enemy on the line exactly once (via hit_list).
	var step = p["speed"] * delta
	p["pos"] += p["beam_dir"] * step
	p["traveled"] += step
	p["draw_pos"] = p["pos"]
	var hit_list: Array = p["hit_list"]
	var falloff: float = p.get("falloff", 1.0)
	var beam_dir: Vector2 = p["beam_dir"]
	var perp = Vector2(-beam_dir.y, beam_dir.x)
	var half_width: float = p.get("beam_width", 12.0)
	for e in targets:
		if not is_instance_valid(e) or e.is_dead:
			continue
		if hit_list.has(e):
			continue
		var offset = e.position - p["start_pos"]
		var along = offset.dot(beam_dir)
		if along < -ENEMY_RADIUS:
			continue
		var ahead = offset.length() - p["traveled"]
		if ahead > 18.0 + ENEMY_RADIUS:
			continue
		var lateral = abs(offset.dot(perp))
		if lateral > half_width + ENEMY_RADIUS:
			continue
		if e.has_method("take_damage"):
			e.take_damage(p["damage"] * falloff, tower_id)
		hit_list.append(e)
		falloff *= p.get("decay", 0.8)
		var aim = e.get_aim_point() if e.has_method("get_aim_point") else e.position
		_spawn_impact_explosion(aim, "linear_scan", e)
	p["falloff"] = falloff
	return p["traveled"] < p["max_range"]

func _on_projectile_impact(p: Dictionary) -> bool:
	if is_instance_valid(p["target"]) and p["target"].has_method("take_damage"):
		p["target"].take_damage(p["damage"], tower_id)
	if p.get("pop", false):
		_pop_burst(p)
	_on_style_impact(p)
	var track: Node = p["target"] if is_instance_valid(p["target"]) else null
	_spawn_impact_explosion(p["target_last_pos"], p["style"], track)
	if p["style"] == "chain_lightning" and p.has("chains_left") and p["chains_left"] > 0:
		var last_pos = p["target_last_pos"]
		var chained: Array[Node] = []
		var anchor: Node = p["target"] if is_instance_valid(p["target"]) else null
		if anchor != null:
			chained.append(anchor)
		for n in p["chained_targets"]:
			chained.append(n)
		var current_damage = p["damage"]
		var chains_left = p["chains_left"]
		var chain_radius = p.get("chain_radius", 60.0)
		var traverse_path: bool = p.get("traverse_path", false)
		while chains_left > 0 and anchor != null and is_instance_valid(anchor):
			var next_target: Node = null
			if traverse_path:
				next_target = _get_next_along_path(anchor, chained, chain_radius)
			else:
				next_target = _get_closest_to_point(last_pos, chained, chain_radius)
			if not next_target:
				break
			chains_left -= 1
			chained.append(next_target)
			current_damage *= 0.8
			var next_pos = next_target.get_aim_point() if next_target.has_method("get_aim_point") else next_target.position
			_spawn_chain_arc(last_pos, next_pos)
			if next_target.has_method("take_damage"):
				next_target.take_damage(current_damage, tower_id)
			_spawn_impact_explosion(next_pos, "chain_lightning", next_target)
			last_pos = next_pos
			anchor = next_target
		return false
	if p.has("on_hit") and p["on_hit"] is Callable:
		p["on_hit"].call(p)
	return false

func _pop_burst(p: Dictionary) -> void:
	# Stack POP: burst damage to enemies near the impact point.
	var origin: Vector2 = p["target_last_pos"]
	var radius: float = p.get("pop_radius", 80.0)
	for e in targets:
		if not is_instance_valid(e) or e.is_dead or e == p["target"]:
			continue
		if origin.distance_to(e.position) <= radius:
			e.take_damage(p["damage"] * 0.5, tower_id)
			var aim = e.get_aim_point() if e.has_method("get_aim_point") else e.position
			_spawn_impact_explosion(aim, "stack_mortar", e)


func _on_style_impact(p: Dictionary) -> void:
	# Virtual — subclasses override to add per-style impact effects.
	pass

func _update_explosions(delta: float) -> void:
	var remaining: Array[Dictionary] = []
	for e in _explosions:
		e["elapsed"] += delta
		var track = e.get("track")
		if track != null and is_instance_valid(track):
			e["pos"] = (track.get_aim_point() if track.has_method("get_aim_point") else track.position) - position
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

func _spawn_impact_explosion(pos: Vector2, style: String, track: Node = null) -> void:
	var radius_map = {
		"stack_mortar": 18.0, "chain_lightning": 22.0, "queue_rail": 14.0,
		"binary_sniper": 16.0, "index_bolt": 8.0, "merge_beam": 14.0,
		"counting_pellet": 10.0, "radix_digit": 8.0, "linear_scan": 12.0,
		"linear_beam": 16.0, "queue_pierce": 14.0
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
	if track != null:
		e["track"] = track
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
	if _using_sprites:
		if _selected:
			draw_circle(Vector2.ZERO, attack_range + ENEMY_RADIUS, Color(tower_color, 0.06))
			draw_arc(Vector2.ZERO, attack_range + ENEMY_RADIUS, 0, TAU, 64, Color(tower_color, 0.25), 1.5)
		_draw_overlays(tower_color)
		return
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

	if Engine.is_editor_hint():
		draw_arc(Vector2.ZERO, attack_range, 0, TAU, 64, Color(tower_color, 0.15), 1.0)

func _draw_overlays(color: Color) -> void:
	# ── PROJECTILES — full redesign: one distinct silhouette per tower ──
	for p in _projectiles:
		var rd = p["draw_pos"] - position
		var rp = p["pos"] - position
		match p["style"]:
			"index_bolt":
				# Array: O(1) memory chip — square PCB chip with index digit, neon rim + drop shadow + trailing ghost chips
				var idx = p.get("index", 0)
				var heading = (p["target_last_pos"] - p["pos"]).normalized() if (p["target_last_pos"] - p["pos"]).length() > 0 else Vector2.RIGHT
				# trailing ghosts
				for j in range(3):
					var ghost = rd - heading * (j + 1) * 7.0
					var a = 0.22 - j * 0.06
					var gs = 7.0 - j * 1.0
					draw_rect(Rect2(ghost - Vector2(gs, gs) * 0.5, Vector2(gs, gs)), Color(color, a), true)
					draw_rect(Rect2(ghost - Vector2(gs, gs) * 0.5, Vector2(gs, gs)), Color(color, a * 0.6), false, 0.8)
				# shadow
				draw_rect(Rect2(rp + Vector2(2, 5) - Vector2(4, 4), Vector2(8, 8)), Color(0, 0, 0, 0.18), true)
				var pulse = 0.5 + sin(_anim_time * 18.0 + idx * 1.2) * 0.15
				var s = 8.0 * pulse
				var cr = 1.6
				# outer glow
				draw_rect(Rect2(rd - Vector2(s, s) * 0.5 - Vector2(2, 2), Vector2(s + 4, s + 4)), Color(color, 0.18), true)
				# chip body
				var chip_rect = Rect2(rd - Vector2(s, s) * 0.5, Vector2(s, s))
				draw_rect(chip_rect, Color("#0F1A2A"), true)
				draw_rect(chip_rect, color, false, 1.2)
				# inner PCB lines
				draw_line(rd + Vector2(-s * 0.5, -s * 0.25), rd + Vector2(s * 0.5, -s * 0.25), Color(color, 0.25), 0.7)
				draw_line(rd + Vector2(-s * 0.5, s * 0.15), rd + Vector2(s * 0.5, s * 0.15), Color(color, 0.2), 0.7)
				# pins
				for pin in [-1, 1]:
					draw_rect(Rect2(rd + Vector2(pin * s * 0.5 - 0.6, -s * 0.35), Vector2(1.2, s * 0.7)), Color(color, 0.55), true)
				# index digit centered
				draw_string(ThemeDB.fallback_font, rd + Vector2(-3, 3.5), str(idx), HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color.WHITE)
				# corner highlight
				draw_circle(rd - Vector2(s * 0.28, s * 0.28), 0.9, Color.WHITE)
			"stack_mortar":
				# Stack: arcing mortar shell — bulky capsule with striped body, fuse spark, parabolic shadow + smoke puff
				var t = p["elapsed_time"] / (p["total_dist"] / p["speed"]) if p["total_dist"] > 0 else 1.0
				var arc_h = sin(t * PI) * 1.0
				var grow = 5.5 + arc_h * 1.5
				# ground shadow that shrinks at apex
				var shadow_a = lerp(0.28, 0.08, arc_h)
				var shadow_s = lerp(6.0, 2.5, arc_h)
				_draw_ellipse(rp + Vector2(3, 6), shadow_s, Color(0, 0, 0, shadow_a), true)
				# smoke trail puff behind
				for j in range(2):
					var puff = rd + Vector2(0, grow * 0.6 + j * 4.0)
					var pa = (0.14 - j * 0.05) * (1.0 - t * 0.5)
					draw_circle(puff, (3.5 - j) * 0.9, Color(Color.WHITE, pa))
				# capsule body
				_draw_shaded_capsule(rd, grow, Color("#2A3442"), color)
				# hazard stripes
				for s_idx in range(2):
					var sy = -grow * 0.35 + s_idx * grow * 0.45
					draw_line(rd + Vector2(-grow * 0.7, sy), rd + Vector2(grow * 0.7, sy), Color("#FFB800"), 1.0)
				# fuse
				var fuse_tip = rd - Vector2(0, grow + 2.0)
				draw_line(rd - Vector2(0, grow * 0.6), fuse_tip, Color("#7A8A9A"), 1.6)
				draw_circle(fuse_tip, 1.8, Color("#FF5533"))
				draw_circle(fuse_tip, 3.2, Color("#FF8833", 0.45 + sin(_anim_time * 30.0) * 0.2))
				draw_circle(fuse_tip + Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)), 0.7, Color.WHITE)
				# highlight glint
				draw_circle(rd - Vector2(grow * 0.32, grow * 0.22), grow * 0.22, Color.WHITE)
				if p.get("pop", false):
					# charged POP shell rings
					draw_arc(rd, grow + 4.0, 0, TAU, 22, Color("#FFB800", 0.55), 1.2)
					draw_arc(rd, grow + 7.0, 0, TAU, 22, Color(color, 0.25), 0.8)
			"queue_rail", "queue_pierce":
				# Queue: FIFO rail slug — arrowhead slug with queue blocks trailing + speed streak
				var heading = p.get("beam_dir", (p["target_last_pos"] - p["pos"]).normalized() if (p["target_last_pos"] - p["pos"]).length() > 0 else Vector2.RIGHT)
				var perp = Vector2(-heading.y, heading.x)
				var trail_len = 18.0
				# speed streak wedge
				var streak_start = rd - heading * trail_len
				var streak_pts = PackedVector2Array([rd + perp * 2.2, streak_start + perp * 0.6, streak_start - perp * 0.6, rd - perp * 2.2])
				draw_colored_polygon(streak_pts, Color(color, 0.22))
				draw_line(streak_start, rd, Color(color, 0.55), 1.2)
				# slug body: rounded rect
				var slug_len = 10.0
				var slug_w = 5.0
				var body_pts = PackedVector2Array([
					rd - heading * slug_len * 0.7 + perp * slug_w * 0.5,
					rd + heading * slug_len * 0.3 + perp * slug_w * 0.45,
					rd + heading * slug_len * 0.65,
					rd + heading * slug_len * 0.3 - perp * slug_w * 0.45,
					rd - heading * slug_len * 0.7 - perp * slug_w * 0.5
				])
				draw_colored_polygon(body_pts, Color.WHITE)
				draw_colored_polygon(body_pts, Color(color, 0.85))
				draw_polyline(body_pts, Color.WHITE, 0.8, true)
				# arrow chevron
				draw_line(rd + heading * 2.0 - perp * 2.0, rd + heading * 4.2, Color.WHITE, 1.0)
				draw_line(rd + heading * 2.0 + perp * 2.0, rd + heading * 4.2, Color.WHITE, 1.0)
				# queue block ghosts trailing
				for j in range(3):
					var bpos = streak_start + heading * j * 4.0
					draw_rect(Rect2(bpos - Vector2(1.2, 1.2), Vector2(2.4, 2.4)), Color(color, 0.35 - j * 0.08), true)
				draw_circle(rd - heading * slug_len * 0.35, 1.1, Color.WHITE)
			"chain_lightning":
				# LinkedList: chain lightning — jagged bolt with node beads at kinks + dual glow
				var bolt_from = rd
				var bolt_to = p["target_last_pos"] - position
				var segments = 7
				var pts: PackedVector2Array = PackedVector2Array()
				pts.append(bolt_from)
				var dir_chain = bolt_to - bolt_from
				var dist_chain = dir_chain.length()
				if dist_chain > 2.0:
					var n = Vector2(-dir_chain.y, dir_chain.x).normalized() if dist_chain > 0 else Vector2.UP
					for j in range(1, segments):
						var f = float(j) / segments
						var base_pos = bolt_from.lerp(bolt_to, f)
						var amp = (1.0 - abs(f - 0.5) * 1.4) * 7.0
						var jitter_ang = _anim_time * 38.0 + j * 2.6
						var jitter = n * sin(jitter_ang) * amp + dir_chain.normalized() * cos(jitter_ang * 1.3) * 2.0
						pts.append(base_pos + jitter)
				pts.append(bolt_to)
				# outer glow
				draw_polyline(pts, Color(color, 0.32), 6.0, true)
				# core
				draw_polyline(pts, Color.WHITE, 2.2, true)
				draw_polyline(pts, color, 1.0, true)
				# node beads at midpoints
				for j in range(1, pts.size() - 1):
					var bead_a = 0.7 + sin(_anim_time * 12.0 + j) * 0.3
					draw_circle(pts[j], 2.0, Color(color, bead_a))
					draw_circle(pts[j], 1.0, Color.WHITE)
				draw_circle(bolt_to, 3.0, Color.WHITE)
				draw_circle(bolt_to, 5.5, Color(color, 0.35))
			"merge_beam":
				# Merge: twin spiraling beams converging — ribbon + orbiting particle
				var frac = clamp(p["elapsed_time"] / (p["total_dist"] / p["speed"] if p["total_dist"] > 0 else 1.0), 0.0, 1.0)
				var side = p.get("merge_side", "left")
				var sway = sin(_anim_time * 14.0 + (0 if side == "left" else 3)) * 1.5 * (1.0 - frac)
				var perp_m = Vector2(-(p["target_last_pos"] - p["pos"]).normalized().y, (p["target_last_pos"] - p["pos"]).normalized().x) if (p["target_last_pos"] - p["pos"]).length() > 0 else Vector2.UP
				var offset = (perp_m * (6 if side == "left" else -6) * (1.0 - frac)) + perp_m * sway
				var head = rd + offset
				var tail = rd - (p["target_last_pos"] - p["pos"]).normalized() * 14.0 + offset * 0.3
				# ribbon
				draw_line(tail, head, Color(color, 0.18), 6.0)
				draw_line(tail, head, Color.WHITE, 2.4)
				draw_line(tail, head, color, 1.3)
				# spiral particle orbiting head
				var orb_r = 4.5
				var orb_a = _anim_time * 10.0 + (0 if side == "left" else PI)
				draw_circle(head + Vector2(cos(orb_a), sin(orb_a)) * orb_r, 1.5, Color(color, 0.9))
				draw_circle(head, 3.2, Color.WHITE)
				draw_circle(head, 5.8, Color(color, 0.28))
				# merge line toward center when close
				if frac > 0.5:
					var mid = rd.lerp(head, 0.5)
					draw_line(head, mid, Color(color, 0.35 * (frac - 0.5) * 2.0), 1.0)
			"counting_pellet":
				# Counting: numbered pellet — solid sphere with digit hud + counting tick trail
				var digit = p.get("digit", 1)
				var heading_cp = (p["target_last_pos"] - p["pos"]).normalized() if (p["target_last_pos"] - p["pos"]).length() > 0 else Vector2.RIGHT
				# tick trail behind
				for j in range(4):
					var tpos = rd - heading_cp * (j + 1) * 6.0 + Vector2(0, sin(_anim_time * 12.0 + j * 0.9) * 1.4)
					var a = 0.45 - j * 0.10
					var tick = "I" if j < digit else "."
					draw_circle(tpos, 2.2 - j * 0.3, Color(color, a))
					draw_circle(tpos, 1.0, Color.WHITE if j == 0 else Color(color, a))
				# pellet body
				draw_circle(rd, 6.0, Color(color, 0.22))
				draw_circle(rd, 4.2, Color.WHITE)
				draw_circle(rd, 4.2, Color(color, 0.55))
				draw_circle(rd - Vector2(1.4, 1.4), 1.2, Color.WHITE)
				draw_string(ThemeDB.fallback_font, rd + Vector2(-3.2, 3.2), str(digit), HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color("#0F1720"))
			"radix_digit":
				# Radix: digit orb — bucket-colored orb with place value (1/10/100) + orbital ring
				var digit_r = p.get("digit", 1)
				var place_col: Color
				var label: String
				if digit_r == 1:
					place_col = Color("#00D4FF"); label = "1"
				elif digit_r == 10:
					place_col = Color("#FFB800"); label = "10"
				else:
					place_col = Color("#FF4D8D"); label = "100"
				var heading_r = (p["target_last_pos"] - p["pos"]).normalized() if (p["target_last_pos"] - p["pos"]).length() > 0 else Vector2.RIGHT
				for j in range(3):
					var gpos = rd - heading_r * (j + 1) * 5.5
					draw_circle(gpos, 1.6 - j * 0.3, Color(place_col, 0.32 - j * 0.08))
				# orbital ring
				var ring_r = 7.0 + sin(_anim_time * 6.0 + digit_r) * 0.6
				draw_arc(rd, ring_r, 0, TAU, 22, Color(place_col, 0.22), 1.0)
				draw_arc(rd, ring_r, _anim_time * 4.0, _anim_time * 4.0 + PI * 1.2, 22, place_col, 1.3)
				draw_circle(rd, 5.5, Color(place_col, 0.22))
				draw_circle(rd, 4.0, Color.WHITE)
				draw_circle(rd, 4.0, Color(place_col, 0.7))
				draw_circle(rd - Vector2(1.2, 1.2), 1.0, Color.WHITE)
				draw_string(ThemeDB.fallback_font, rd + Vector2(-6 if digit_r == 100 else -3, 3), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 6, Color.WHITE if digit_r == 100 else Color("#0F1720"))
			"bubble_pulse":
				# Bubble: iridescent bubble orb — translucent sphere with highlight + inner glow + wobble ring
				var t = p["elapsed_time"] / (p["total_dist"] / p["speed"] if p["total_dist"] > 0 else 1.0)
				var wobble = sin(_anim_time * 10.0) * 0.6
				var pulse = sin(t * PI * 5.0) * 1.2
				var r = 6.5 + pulse + wobble * 0.5
				# shadow
				_draw_ellipse(rp + Vector2(2, 6), r * 0.7, Color(0, 0, 0, 0.14), true)
				# outer glow
				draw_circle(rd, r + 3.5, Color(color, 0.14))
				# bubble body translucent
				draw_circle(rd, r, Color.WHITE)
				draw_circle(rd, r, Color(color, 0.22))
				# inner gradient
				draw_circle(rd + Vector2(1, 1), r * 0.62, Color(color, 0.18))
				# specular highlight (top-left)
				draw_circle(rd - Vector2(r * 0.28, r * 0.32), r * 0.32, Color.WHITE)
				draw_circle(rd - Vector2(r * 0.18, r * 0.22), r * 0.14, Color(1, 1, 1, 0.0))
				# rim light
				draw_arc(rd, r, 0, TAU, 26, Color(color, 0.55), 1.2)
				# horizontal shimmer line
				draw_line(rd - Vector2(r * 0.55, 0), rd + Vector2(r * 0.55, 0), Color(1, 1, 1, 0.32), 0.8)
			"selection_sniper":
				# Selection: executioner seeker — diamond reticle with corner brackets + streak tail + pulsing lock
				var heading_s = (p["target_last_pos"] - p["pos"]).normalized() if (p["target_last_pos"] - p["pos"]).length() > 0 else Vector2.RIGHT
				var perp_s = Vector2(-heading_s.y, heading_s.x)
				# streak tail
				draw_line(rd - heading_s * 16.0, rd, Color(color, 0.28), 3.0)
				draw_line(rd - heading_s * 16.0, rd, Color.WHITE, 1.2)
				# corner brackets (4x L)
				var b = 9.0
				var th = 1.4
				var c1 = rd + perp_s * b + heading_s * b; var c2 = rd - perp_s * b + heading_s * b; var c3 = rd - perp_s * b - heading_s * b; var c4 = rd + perp_s * b - heading_s * b
				for corners in [[c1, -perp_s, -heading_s], [c2, perp_s, -heading_s], [c3, perp_s, heading_s], [c4, -perp_s, heading_s]]:
					var cp = corners[0]; var d1 = corners[1]; var d2 = corners[2]
					draw_line(cp, cp + d1 * 5.0, Color.WHITE, th); draw_line(cp, cp + d2 * 5.0, Color.WHITE, th)
					draw_line(cp + Vector2(0.5, 0.5), cp + d1 * 5.0, color, 1.0); draw_line(cp + Vector2(0.5, 0.5), cp + d2 * 5.0, color, 1.0)
				# center diamond
				var ch = 5.0 + sin(_anim_time * 16.0) * 0.7
				var diamond = PackedVector2Array([rd + Vector2(ch, 0), rd + Vector2(0, -ch), rd + Vector2(-ch, 0), rd + Vector2(0, ch)])
				draw_colored_polygon(diamond, Color.WHITE)
				draw_colored_polygon(diamond, Color(color, 0.7))
				draw_polyline(diamond, Color(color, 0.9), 0.8, true)
				draw_circle(rd, 1.8, Color.WHITE)
				draw_circle(rd, 7.0, Color(color, 0.22))
			"insertion_needle":
				# Insertion: needle dart — sharp shaft with barbs + venom tip glow + motion blur
				var heading_n = (p["target_last_pos"] - p["pos"]).normalized() if (p["target_last_pos"] - p["pos"]).length() > 0 else Vector2.RIGHT
				var perp_n = Vector2(-heading_n.y, heading_n.x)
				var shaft_len = 14.0
				var wid = 2.2
				# motion blur trail
				for j in range(3):
					var blur_p = rd - heading_n * (j + 1) * 5.0
					draw_line(blur_p - heading_n * 4.0, blur_p + heading_n * 4.0, Color(color, 0.14 - j * 0.04), 1.0)
				# shaft polygon
				var shaft = PackedVector2Array([
					rd - heading_n * shaft_len * 0.55 + perp_n * wid,
					rd + heading_n * shaft_len * 0.45 + perp_n * wid * 0.6,
					rd + heading_n * shaft_len * 0.72,
					rd + heading_n * shaft_len * 0.45 - perp_n * wid * 0.6,
					rd - heading_n * shaft_len * 0.55 - perp_n * wid
				])
				draw_colored_polygon(shaft, Color.WHITE)
				draw_colored_polygon(shaft, Color(color, 0.92))
				draw_polyline(shaft, Color(1, 1, 1, 0.9), 0.7, true)
				# barbs
				var barb_base = rd - heading_n * 2.0
				draw_line(barb_base + perp_n * wid, barb_base + perp_n * wid + heading_n * 3.2, Color(color, 0.7), 1.0)
				draw_line(barb_base - perp_n * wid, barb_base - perp_n * wid + heading_n * 3.2, Color(color, 0.7), 1.0)
				# venom tip glow
				var tip = rd + heading_n * shaft_len * 0.72
				draw_circle(tip, 3.2, Color(color, 0.28))
				draw_circle(tip, 1.6, Color.WHITE)
				draw_circle(rd - heading_n * 1.0, 0.8, Color.WHITE)
			"quick_split":
				# Quick: pivot fork — central bolt that forks into two prongs
				var heading_q = (p["target_last_pos"] - p["pos"]).normalized() if (p["target_last_pos"] - p["pos"]).length() > 0 else Vector2.RIGHT
				var perp_q = Vector2(-heading_q.y, heading_q.x)
				var is_pivot = p.get("is_pivot", false)
				# trailing fork ghosts
				for j in range(2):
					var gp = rd - heading_q * (j + 1) * 6.0
					draw_line(gp - perp_q * (4.0 - j), gp + perp_q * (4.0 - j), Color(color, 0.18 - j * 0.06), 1.0)
				# central shaft
				draw_line(rd - heading_q * 10.0, rd + heading_q * 8.0, Color.WHITE, 3.2)
				draw_line(rd - heading_q * 10.0, rd + heading_q * 8.0, color, 1.8)
				# fork prongs at tip
				var tip_q = rd + heading_q * 8.0
				draw_line(tip_q, tip_q - heading_q * 4.0 + perp_q * 6.0, Color.WHITE, 2.0)
				draw_line(tip_q, tip_q - heading_q * 4.0 - perp_q * 6.0, Color.WHITE, 2.0)
				draw_line(tip_q, tip_q - heading_q * 4.0 + perp_q * 6.0, color, 1.1)
				draw_line(tip_q, tip_q - heading_q * 4.0 - perp_q * 6.0, color, 1.1)
				draw_circle(tip_q + perp_q * 6.0 - heading_q * 4.0, 2.0, Color.WHITE)
				draw_circle(tip_q - perp_q * 6.0 - heading_q * 4.0, 2.0, Color.WHITE)
				draw_circle(tip_q + perp_q * 6.0 - heading_q * 4.0, 1.0, color)
				draw_circle(tip_q - perp_q * 6.0 - heading_q * 4.0, 1.0, color)
				if is_pivot:
					draw_circle(rd, 4.5, Color.WHITE)
					draw_circle(rd, 4.5, Color(color, 0.45))
					draw_circle(rd, 7.5, Color(color, 0.18))
				else:
					draw_circle(rd, 2.6, Color.WHITE)
			"linear_scan":
				# Linear: scan pulse — thin scanning line (legacy) — kept subtle
				var heading_l = (p["target_last_pos"] - p["pos"]).normalized() if (p["target_last_pos"] - p["pos"]).length() > 0 else Vector2.RIGHT
				var perp_l = Vector2(-heading_l.y, heading_l.x)
				draw_line(rd - perp_l * 10.0, rd + perp_l * 10.0, Color(1, 1, 1, 0.9), 2.0)
				draw_line(rd - perp_l * 10.0, rd + perp_l * 10.0, Color(color, 0.55), 1.0)
				draw_circle(rd, 2.4, Color.WHITE)
				draw_circle(rd, 5.0, Color(color, 0.28))
			"linear_beam", "queue_pierce":
				# Linear/Queue pierce beam — wide energy bar with scanning ticks + bloom
				var beam_heading = p.get("beam_dir", Vector2.RIGHT)
				var beam_perp = Vector2(-beam_heading.y, beam_heading.x)
				# bloom trail behind
				draw_line(rd - beam_heading * 32.0, rd, Color(color, 0.20), 7.0)
				draw_line(rd - beam_heading * 32.0, rd, Color(1, 1, 1, 0.65), 2.0)
				draw_line(rd - beam_heading * 32.0, rd, color, 1.0)
				# scan bar (perpendicular)
				draw_line(rd - beam_perp * 11.0, rd + beam_perp * 11.0, Color.WHITE, 2.6)
				draw_line(rd - beam_perp * 11.0, rd + beam_perp * 11.0, color, 1.4)
				# tick marks along bar
				for tk in [-5.0, 0.0, 5.0]:
					var tkp = rd + beam_perp * tk
					draw_line(tkp - beam_heading * 2.0, tkp + beam_heading * 2.0, Color(1, 1, 1, 0.7), 0.8)
				draw_circle(rd, 2.8, Color.WHITE)
				draw_circle(rd, 6.2, Color(color, 0.28))
			"binary_sniper":
				# Binary: sniper tracer — needle tracer with binary 0/1 digits trailing + pulsing crosshair
				var heading_b = (p["target_last_pos"] - p["pos"]).normalized() if (p["target_last_pos"] - p["pos"]).length() > 0 else Vector2.RIGHT
				var perp_b = Vector2(-heading_b.y, heading_b.x)
				# binary digit trail behind
				for j in range(4):
					var dpos = rd - heading_b * (j + 1) * 7.0 + perp_b * sin(_anim_time * 10.0 + j) * 1.2
					var bit = "1" if (j % 2 == 0) else "0"
					draw_string(ThemeDB.fallback_font, dpos + Vector2(-3, 3), bit, HORIZONTAL_ALIGNMENT_CENTER, -1, 7, Color(color, 0.55 - j * 0.10))
				# tracer line
				draw_line(rd - heading_b * 14.0, rd, Color(color, 0.35), 3.5)
				draw_line(rd - heading_b * 14.0, rd, Color.WHITE, 1.4)
				# crosshair
				var ch = 5.0 + sin(_anim_time * 18.0) * 0.8
				draw_line(rd + perp_b * ch, rd - perp_b * ch, Color.WHITE, 1.6)
				draw_line(rd + heading_b * ch, rd - heading_b * ch, Color.WHITE, 1.6)
				draw_circle(rd, 2.0, Color.WHITE)
				draw_circle(rd, 6.0, Color(color, 0.42))
				draw_circle(rd, 9.0, Color(color, 0.14))
			_:
				draw_circle(rd, 3.2, Color.WHITE)
				draw_circle(rd, 5.0, color)
				draw_circle(rd, 7.5, Color(color, 0.18))

	# ── IMPACTS — one distinct explosion identity per tower ──
	for e in _explosions:
		var life_ratio = e["elapsed"] / e["lifetime"]
		var flash_val = 1.0 - life_ratio
		var e_color = Color(color, flash_val)
		match e["style"]:
			"stack_mortar":
				# Stack POP — expanding double ring + POP label + debris sparks + shockwave
				var r1 = e["radius"] * (1.0 + flash_val * 0.25)
				draw_arc(e["pos"], r1, 0, TAU, 28, Color("#FFB800", flash_val * 0.9), 2.4)
				draw_arc(e["pos"], r1 * 0.62, 0, TAU, 24, Color(color, flash_val * 0.45), 1.6)
				draw_circle(e["pos"], r1 * 0.38, Color(color, flash_val * 0.28))
				draw_circle(e["pos"], 4.5 * flash_val + 2.0, Color.WHITE)
				for j in range(5):
					var a = (TAU / 5.0) * j + _anim_time * 6.0
					draw_circle(e["pos"] + Vector2(cos(a), sin(a)) * r1 * 0.85, 1.4, Color("#FFB800", flash_val * 0.8))
				draw_string(ThemeDB.fallback_font, e["pos"] + Vector2(-10, -10), "POP!", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color("#FFB800" if flash_val > 0.5 else Color(color, flash_val)))
			"chain_lightning":
				# LinkedList chain — electric burst + branching sparks
				draw_circle(e["pos"], e["radius"] * 0.5, Color.WHITE)
				draw_circle(e["pos"], e["radius"] * 0.75, Color(color, flash_val * 0.5))
				for j in range(6):
					var a = (TAU / 6.0) * j + _anim_time * 8.0
					var tip = e["pos"] + Vector2(cos(a), sin(a)) * e["radius"] * 0.95
					draw_line(e["pos"], tip, Color(color, flash_val * 0.7), 1.2)
					draw_circle(tip, 1.6, Color(1, 1, 1, flash_val))
			"queue_rail", "queue_pierce":
				# Queue dequeue — directional arrow burst + sliding blocks fade
				draw_line(e["pos"] - Vector2(e["radius"], 0), e["pos"] + Vector2(e["radius"], 0), e_color, 2.2)
				draw_line(e["pos"] - Vector2(0, e["radius"] * 0.6), e["pos"] + Vector2(0, e["radius"] * 0.6), Color(color, flash_val * 0.5), 1.2)
				# arrowhead
				var ah = e["pos"] + Vector2(e["radius"] * 0.55, 0)
				draw_line(ah, ah + Vector2(-5, -4), Color(1, 1, 1, flash_val), 1.5)
				draw_line(ah, ah + Vector2(-5, 4), Color(1, 1, 1, flash_val), 1.5)
				draw_circle(e["pos"], 3.5 * flash_val + 1.5, Color.WHITE)
				draw_circle(e["pos"], e["radius"] * 0.45, Color(color, flash_val * 0.18))
			"binary_sniper":
				# Binary sniper hit — crosshair shatter + binary digits dispersing
				draw_line(e["pos"] - Vector2(e["radius"], 0), e["pos"] + Vector2(e["radius"], 0), e_color, 1.8)
				draw_line(e["pos"] - Vector2(0, e["radius"]), e["pos"] + Vector2(0, e["radius"]), e_color, 1.8)
				draw_arc(e["pos"], e["radius"] * 0.55, 0, TAU, 24, Color(color, flash_val * 0.35), 1.0)
				draw_circle(e["pos"], 4.0 * flash_val + 1.0, Color.WHITE)
				for j in range(4):
					var a = (TAU / 4.0) * j + PI / 4
					var bit_pos = e["pos"] + Vector2(cos(a), sin(a)) * e["radius"] * 0.7 * (0.5 + flash_val * 0.5)
					var bit = "1" if j % 2 == 0 else "0"
					draw_string(ThemeDB.fallback_font, bit_pos + Vector2(-3, 3), bit, HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color(color, flash_val))
			"counting_pellet", "radix_digit":
				# Counting/Radix — orbiting count ticks that expand + digit ghosts
				var cnt = 5
				for j in range(cnt):
					var a = (TAU / cnt) * j + _anim_time * 6.0
					var r = e["radius"] * (0.55 + flash_val * 0.45)
					var p2 = e["pos"] + Vector2(cos(a), sin(a)) * r
					draw_circle(p2, 2.2, Color(color, flash_val * (1.0 - j * 0.12)))
					draw_circle(p2, 1.0, Color(1, 1, 1, flash_val * 0.85))
				draw_circle(e["pos"], 3.0 * flash_val + 1.0, Color.WHITE)
				draw_arc(e["pos"], e["radius"] * 0.45, 0, TAU, 16, Color(color, flash_val * 0.4), 1.0)
			"index_bolt":
				# Array — memory grid flash — square burst + index echo
				var sq = e["radius"] * 1.2
				draw_rect(Rect2(e["pos"] - Vector2(sq, sq) * 0.5, Vector2(sq, sq)), Color(color, flash_val * 0.22), true)
				draw_rect(Rect2(e["pos"] - Vector2(sq, sq) * 0.5, Vector2(sq, sq)), e_color, false, 1.4)
				draw_rect(Rect2(e["pos"] - Vector2(sq * 0.55, sq * 0.55) * 0.5, Vector2(sq * 0.55, sq * 0.55)), Color(1, 1, 1, flash_val * 0.85), true)
				for j in range(4):
					var a = (TAU / 4.0) * j + PI / 4
					draw_circle(e["pos"] + Vector2(cos(a), sin(a)) * e["radius"] * 0.35, 1.2, Color(color, flash_val * 0.7))
			"bubble_pulse":
				# Bubble pop — iridescent expanding rings + droplet particles
				draw_arc(e["pos"], e["radius"], 0, TAU, 26, Color(color, flash_val * 0.65), 1.6)
				draw_arc(e["pos"], e["radius"] * 0.58, 0, TAU, 20, Color(1, 1, 1, flash_val * 0.55), 1.0)
				draw_circle(e["pos"], e["radius"] * 0.32, Color(color, flash_val * 0.18))
				for j in range(6):
					var a = (TAU / 6.0) * j + _anim_time * 4.0
					var d = e["radius"] * (0.45 + flash_val * 0.5)
					draw_circle(e["pos"] + Vector2(cos(a), sin(a)) * d, 1.5, Color(1, 1, 1, flash_val * 0.7))
					draw_circle(e["pos"] + Vector2(cos(a), sin(a)) * d, 0.8, color)
			"insertion_needle":
				# Insertion — needle punch + venom ring + shift arrow echo
				draw_arc(e["pos"], e["radius"], 0, TAU, 20, Color(color, flash_val * 0.55), 1.5)
				draw_arc(e["pos"], e["radius"] * 0.45, 0, TAU, 16, Color(1, 1, 1, flash_val * 0.7), 1.0)
				draw_line(e["pos"] + Vector2(-e["radius"] * 0.5, 0), e["pos"] + Vector2(e["radius"] * 0.55, 0), Color(color, flash_val * 0.6), 1.2)
				# shift chevron
				var ap = e["pos"] + Vector2(e["radius"] * 0.3, 0)
				draw_line(ap, ap + Vector2(-4, -3), Color(1, 1, 1, flash_val), 1.2)
				draw_line(ap, ap + Vector2(-4, 3), Color(1, 1, 1, flash_val), 1.2)
				draw_circle(e["pos"], 2.5 * flash_val + 1.0, Color.WHITE)
			"selection_sniper", "quick_split":
				# Selection/Quick — bracket collapse + converging ticks
				draw_arc(e["pos"], e["radius"], 0, TAU, 24, e_color, 1.6)
				draw_arc(e["pos"], e["radius"] * 0.5, 0, TAU, 16, Color(color, flash_val * 0.35), 1.0)
				var b = e["radius"] * 0.45
				for c in [Vector2(b, b), Vector2(-b, b), Vector2(-b, -b), Vector2(b, -b)]:
					var cp = e["pos"] + c * flash_val
					draw_line(cp, cp + Vector2(3, 0).rotated(c.angle()), Color(1, 1, 1, flash_val), 1.0)
				draw_circle(e["pos"], 2.8 * flash_val + 1.0, Color.WHITE)
			"merge_beam":
				# Merge — twin orbs colliding into one + implosion ring
				var r_a = e["radius"] * (0.9 - flash_val * 0.35)
				var r_b = e["radius"] * flash_val * 0.9
				draw_arc(e["pos"], e["radius"] * 0.7, 0, TAU, 22, Color(color, flash_val * 0.5), 1.4)
				draw_circle(e["pos"] + Vector2(-r_a, 0), 3.0 * flash_val + 1.0, Color(1, 1, 1, flash_val))
				draw_circle(e["pos"] + Vector2(r_a, 0), 3.0 * flash_val + 1.0, Color(1, 1, 1, flash_val))
				draw_circle(e["pos"], r_b + 2.0, Color(color, flash_val * 0.35))
				draw_circle(e["pos"], 2.5, Color.WHITE)
			"linear_scan", "linear_beam":
				# Linear scan — horizontal scan line echo + bloom
				draw_line(e["pos"] - Vector2(e["radius"], 0), e["pos"] + Vector2(e["radius"], 0), Color(1, 1, 1, flash_val * 0.85), 1.8)
				draw_line(e["pos"] - Vector2(e["radius"], 0), e["pos"] + Vector2(e["radius"], 0), Color(color, flash_val * 0.5), 4.0)
				draw_line(e["pos"] - Vector2(e["radius"] * 0.6, 0), e["pos"] + Vector2(e["radius"] * 0.6, 0), Color(color, flash_val * 0.25), 7.0)
				draw_circle(e["pos"], 2.2, Color.WHITE)
			_:
				draw_arc(e["pos"], e["radius"], 0, TAU, 16, e_color, 1.5)
				draw_circle(e["pos"], 2.2 * flash_val + 1.0, Color(1, 1, 1, flash_val))

	if _shoot_flash > 0:
		var flash_color = Color(color, _shoot_flash * 0.55)
		for target_offset in _flash_targets:
			draw_line(Vector2.ZERO, target_offset, flash_color, 2.5)
		draw_circle(Vector2.ZERO, 10.0 * _shoot_flash, Color(color, _shoot_flash * 0.22))
		draw_circle(Vector2.ZERO, 5.5 * _shoot_flash, Color(1, 1, 1, _shoot_flash * 0.85))
		draw_circle(Vector2.ZERO, 2.5 * _shoot_flash, color)

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
				var jag = sin(_anim_time * 25.0 + i * 5.0) * (dist * 0.14)
				pts.append(arc["from"] + dir * f + n * jag)
		pts.append(arc["to"])
		draw_polyline(pts, Color(color, life * 0.45), 5.0)
		draw_polyline(pts, Color(color, life), 2.2)
		draw_polyline(pts, Color(1, 1, 1, life * 0.9), 1.0)
		# node beads along chain
		for i in range(1, pts.size() - 1):
			draw_circle(pts[i], 1.6 * life + 0.4, Color(color, life))
			draw_circle(pts[i], 0.7, Color(1, 1, 1, life))

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
