# EnemyBase.gd
# Base class for all enemies. Contains shared logic: movement, damage,
# health bar, DOT, death framework. Subclasses override virtual methods
# for type-specific behavior.
#
# NOTE: class_name Enemy is preserved so existing `is Enemy` checks
# throughout the codebase continue to work.

class_name Enemy
extends CharacterBody2D

signal enemy_defeated(enemy: Node)
signal enemy_reached_end(enemy: Node)

const SQUASH: float = 0.65
const ENEMY_RADIUS: float = 20.0

# ─── STATS (shared) ─────────────────────────────────────
var max_health: float     = 100.0
var current_health: float = 100.0
var move_speed: float     = 80.0
var ram_reward: int       = 10
var damage_to_base: int   = 1
var enemy_type: String    = "basic_packet"

# ─── PATH ────────────────────────────────────────────────
var waypoints: Array[Vector2] = []
var current_waypoint: int     = 0
var is_dead: bool             = false

# ─── VISUAL ─────────────────────────────────────────────
var enemy_color: Color    = Color("#FF3366")
var _flash_timer: float   = 0.0
var _bob_time: float      = 0.0
var _mobile_redraw_skip: int = 0

# ─── PREVIEW MODE ────────────────────────────────────────
var preview_mode: bool    = false

# ─── DAMAGE OVER TIME ────────────────────────────────────
var _dot_damage: float        = 0.0
var _dot_timer: float         = 0.0
var _dot_tick_interval: float = 0.5
var _dot_tick_timer: float    = 0.0

# ─── TYPE-SPECIFIC STATE ─────────────────────────────────
# Subclasses use this for type-specific data (backward compat with original).
# Each subclass populates it in _init_type_state().
var type_data: Dictionary = {}

# ─── STYLE ───────────────────────────────────────────────
var style: EnemyStyle = null

# ─── NODE REFERENCES ─────────────────────────────────────
@onready var collider: CollisionShape2D = $Collider
@onready var sprite: Node2D            = $Sprite
@onready var health_bar: Node2D         = $HealthBar
@onready var status_layer: Node2D       = $StatusEffectLayer

func initialize(
		p_waypoints: Array[Vector2],
		p_health: float,
		p_speed: float,
		p_type: String = "basic_packet",
		p_type_data: Dictionary = {}) -> void:
	waypoints          = p_waypoints
	current_waypoint   = 0
	max_health         = p_health
	current_health     = p_health
	move_speed         = p_speed
	enemy_type         = p_type
	type_data          = p_type_data.duplicate(true)
	_setup_type()
	if waypoints.size() > 0:
		position = waypoints[0]
	collision_mask = 0

func _setup_type() -> void:
	var edef = GameManager.ENEMY_DEFINITIONS.get(enemy_type, {})
	enemy_color = edef.get("color", Color.WHITE)
	ram_reward = int(edef.get("ram_reward", 10))
	_init_type_state()

func _init_type_state() -> void:
	# Virtual — subclasses override to initialize type-specific state
	pass

func ensure_style() -> EnemyStyle:
	if style == null:
		style = EnemyStyle.new()
	return style

# ─── PHYSICS PROCESS (shared) ───────────────────────────
func _physics_process(delta: float) -> void:
	if is_dead or waypoints.size() == 0:
		return

	if preview_mode:
		_bob_time += delta * 3.0
		if _flash_timer > 0:
			_flash_timer -= delta
		_mobile_redraw_skip += 1
		if _mobile_redraw_skip % 2 == 0:
			queue_redraw()
		return

	# Damage-over-time tick
	if _dot_timer > 0:
		_dot_tick_timer -= delta
		_dot_timer      -= delta
		if _dot_tick_timer <= 0:
			var dot_amt = _dot_damage * _get_dot_damage_multiplier()
			take_damage(dot_amt)
			_dot_tick_timer = _dot_tick_interval

	# Type-specific per-frame logic
	_process_type_logic(delta)

	_bob_time += delta * 3.0
	if _flash_timer > 0:
		_flash_timer -= delta
	if current_waypoint >= waypoints.size():
		_reach_end()
		return
	_move_toward_waypoint(delta)

	_mobile_redraw_skip += 1
	if _mobile_redraw_skip % 2 == 0:
		queue_redraw()

# ─── MOVEMENT (shared) ────────────────────────────────────
func _process_type_logic(delta: float) -> void:
	# Virtual — subclasses override for type-specific per-frame behavior
	pass

func _get_dot_damage_multiplier() -> float:
	# Virtual — override for types with DoT multipliers (e.g., insertion_stack: 1.5x)
	return 1.0

func _apply_movement_offset(direction: Vector2, delta: float) -> Vector2:
	# Virtual — override for types with special movement (e.g., scan_wave oscillation)
	return Vector2.ZERO

func _move_toward_waypoint(delta: float) -> void:
	var target    = waypoints[current_waypoint]
	var direction = (target - position).normalized()

	var offset = _apply_movement_offset(direction, delta)
	if offset != Vector2.ZERO:
		position += offset

	velocity = direction * move_speed
	move_and_slide()

	# Path correction
	if current_waypoint > 0:
		var prev = waypoints[current_waypoint - 1]
		var seg  = target - prev
		var seg_len_sq = seg.length_squared()
		if seg_len_sq > 0.0:
			var t = clamp((position - prev).dot(seg) / seg_len_sq, 0.0, 1.0)
			var closest = prev + seg * t
			var drift = position.distance_to(closest)
			if drift > 4.0:
				position = position.lerp(closest, 0.3)

	if position.distance_to(target) < 8.0:
		current_waypoint += 1
		if current_waypoint >= waypoints.size():
			_reach_end()

# ─── DAMAGE (framework) ───────────────────────────────────
func apply_dot(total_damage: float, duration: float) -> void:
	_dot_damage = total_damage / (duration / _dot_tick_interval)
	_dot_damage *= _get_dot_scaling_on_apply()
	_dot_timer  = duration
	queue_redraw()

func _get_dot_scaling_on_apply() -> float:
	# Virtual — override for types that scale DoT on application
	# (e.g., insertion_stack: 1.5x on apply AND 1.5x on tick = 2.25x total)
	return 1.0

func take_damage(amount: float) -> void:
	if is_dead:
		return

	var final_damage = _modify_damage(amount)

	# Some types (e.g., radix_digit) handle death internally in _modify_damage.
	# If _die() was called there, skip the standard HP application.
	if is_dead:
		return

	current_health -= final_damage
	_flash_timer = 0.15
	queue_redraw()

	if current_health <= 0:
		_die()

func _modify_damage(amount: float) -> float:
	# Virtual — subclasses override for type-specific resistance/absorption
	# Default: no modification
	return amount

func _notify_damage_taken(damage_dealt: float) -> void:
	# Hook for subclasses that need to react to damage (e.g., count_meter)
	pass

# Direct damage for linked partners
func take_damage_direct(amount: float) -> void:
	if is_dead:
		return
	current_health -= amount
	_flash_timer = 0.15
	queue_redraw()
	if current_health <= 0:
		_die()

# ─── PARTNER MANAGEMENT (for linked_drain / merge_twin) ───
func set_partner(p: Node) -> void:
	# Virtual — subclasses override if they need partner tracking
	pass

func get_partner() -> Node:
	return null

# ─── DEATH (framework) ────────────────────────────────────
func _die() -> void:
	if is_dead:
		return
	is_dead = true

	_notify_overflow_ahead()

	_on_death()

	SoundManager.play_enemy_death()
	SignalBus.enemy_defeated.emit(name)
	enemy_defeated.emit(self)

	queue_free()

func _on_death() -> void:
	# Virtual — subclasses override for type-specific death behavior
	pass

func _notify_overflow_ahead() -> void:
	if not get_parent():
		return
	for child in get_parent().get_children():
		if child == self or not (child is Enemy):
			continue
		var e: Enemy = child
		if e.is_dead or e.enemy_type != "overflow_packet":
			continue
		if e.current_waypoint > current_waypoint:
			e._add_overflow_layer()

func _add_overflow_layer() -> void:
	# Called by overflow_packet enemies when an enemy behind them dies
	# Subclasses using this should set type_data["layers"], ["base_max_hp"]
	var layers = type_data.get("layers", 0) + 1
	type_data["layers"] = layers
	if type_data.has("base_max_hp"):
		var bonus = type_data["base_max_hp"] * 0.2
		max_health += bonus
		current_health = min(current_health + bonus * 0.3, max_health)
		queue_redraw()

func _reach_end() -> void:
	if is_dead:
		return
	is_dead = true
	SignalBus.enemy_reached_end.emit(name)
	enemy_reached_end.emit(self)
	queue_free()

# ─── HEALTH HELPERS (shared) ─────────────────────────────
func get_health_ratio() -> float:
	# Virtual — subclasses override for segmented HP (e.g., radix_digit)
	return clamp(current_health / max_health, 0.0, 1.0)

func _has_shield() -> bool:
	return false

func _draw_extra_health_bar() -> void:
	# Virtual — subclasses override for shield bar etc.
	pass

# ─── DRAW ────────────────────────────────────────────────
func _draw() -> void:
	var flash = _flash_timer > 0
	var col   = Color("#FFFFFF") if flash else enemy_color
	var bob   = sin(_bob_time) * 2.0

	_draw_type_body(col, bob)

	_draw_health_bar()

	# DOT visual indicator
	if _dot_timer > 0:
		var pulse = (sin(_bob_time * 4.0) + 1.0) * 0.5
		var s = ensure_style()
		draw_circle(Vector2(16, -32), s.dot_indicator_size + pulse * 1.5, s.dot_indicator_color)

	# Type-specific overlay draws
	_draw_type_overlay(bob)

	# Status effect layer (tints, etc.)
	_draw_status_effects(col, bob)

func _draw_type_body(col: Color, bob: float) -> void:
	# Virtual — subclasses override with type-specific 3D shape drawing
	pass

func _draw_type_overlay(bob: float) -> void:
	# Virtual — subclasses override for index numbers, tally marks, etc.
	pass

func _draw_status_effects(col: Color, bob: float) -> void:
	# Virtual — subclasses override for slow/burn tints, link lines, etc.
	pass

func _draw_health_bar() -> void:
	var s = ensure_style()
	var bar_width  = s.health_bar_width
	var bar_height = s.health_bar_height
	var bar_x      = -bar_width / 2.0
	var bar_y      = s.health_bar_offset.y

	var hp_ratio = get_health_ratio()

	draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), s.health_bg_color)

	var hp_color = s.health_full_color if hp_ratio > 0.6 \
				   else s.health_mid_color if hp_ratio > 0.3 \
				   else s.health_low_color
	draw_rect(
		Rect2(bar_x, bar_y, bar_width * hp_ratio, bar_height),
		hp_color
	)

	draw_rect(
		Rect2(bar_x, bar_y, bar_width, bar_height),
		Color("#FFFFFF", s.health_border_alpha), false, 1.0
	)

	# Shield bar for bubble_shield (drawn by subclass)
	_draw_extra_health_bar()

	# Boss HP number
	if enemy_type == "pivot_splitter":
		draw_string(
			ThemeDB.fallback_font,
			Vector2(bar_x, bar_y - 4),
			str(int(current_health)) + "/" + str(int(max_health)),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
			Color("#E8F4FD")
		)

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

func get_type_id() -> String:
	# Override in each subclass to return the enemy_type (e.g., "basic_packet")
	return ""

# ─── SHARED TYPE HELPERS (used by subclasses) ────────────
func _count_enemies_ahead() -> int:
	var count = 0
	if not get_parent():
		return count
	for child in get_parent().get_children():
		if child == self or not child is Enemy:
			continue
		var e: Enemy = child
		if e.is_dead:
			continue
		if e.current_waypoint > current_waypoint:
			count += 1
	return count

func _is_lowest_hp_enemy() -> bool:
	if not get_parent():
		return true
	var lowest_hp = current_health
	var is_lowest = true
	for child in get_parent().get_children():
		if child == self or not child is Enemy:
			continue
		var e: Enemy = child
		if e.is_dead:
			continue
		if e.current_health < lowest_hp and e.enemy_type != "overflow_packet":
			is_lowest = false
			break
	return is_lowest

func _spawn_split_enemies(count: int) -> void:
	var perp = Vector2.RIGHT
	if current_waypoint > 0 and current_waypoint < waypoints.size():
		var dir = (waypoints[current_waypoint] - waypoints[current_waypoint - 1]).normalized()
		perp = Vector2(-dir.y, dir.x)
	elif current_waypoint < waypoints.size() - 1:
		var dir = (waypoints[current_waypoint + 1] - waypoints[current_waypoint]).normalized()
		perp = Vector2(-dir.y, dir.x)
	var wm_nodes = get_tree().get_nodes_in_group("wave_manager")
	var wm = wm_nodes[0] if wm_nodes.size() > 0 else null
	for i in range(count):
		var split = EnemyFactory.create(
			"basic_packet", waypoints, 60.0, 90.0, {}, 0
		)
		if split and get_parent():
			get_parent().add_child(split)
			split.position = position + perp * (i * 20 - 10)
			if wm:
				split.connect("enemy_defeated", Callable(wm, "_on_enemy_defeated"))
				split.connect("enemy_reached_end", Callable(wm, "_on_enemy_reached_end"))
				wm.enemies_alive += 1
				wm.enemy_spawned.emit(split)
