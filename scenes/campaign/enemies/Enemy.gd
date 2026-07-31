# Enemy.gd
class_name Enemy
extends CharacterBody2D

signal enemy_defeated(enemy: Node)
signal enemy_reached_end(enemy: Node)

# ─── STATS ─────────────────────────────────────────────
var max_health: float     = 100.0
var current_health: float = 100.0
var move_speed: float     = 80.0
var ram_reward: int       = 10
var damage_to_base: int   = 1
var enemy_type: String    = "basic_packet"

# ─── PATH ──────────────────────────────────────────────
var waypoints: Array[Vector2] = []
var current_waypoint: int     = 0
var is_dead: bool             = false

# ─── VISUAL ────────────────────────────────────────────
var enemy_color: Color    = Color("#FF3366")
var _flash_timer: float   = 0.0
var _bob_time: float      = 0.0
var _mobile_redraw_skip: int = 0

# ─── SPIRE SPRITE MODE ───────────────────────────────────
const _SpireEnemy = preload("res://scenes/campaign/enemies/SpireEnemy.gd")
var _spire: Node2D = null

const SPIRE_VARIANTS: Dictionary = {}

var _last_position: Vector2 = Vector2.ZERO

# ─── PREVIEW MODE (Index screen) ───────────────────────
# When true, the enemy is frozen in place and acts purely as a
# static 3D model (no pathing, no DoT, no collisions). Toggled
# externally; default false so existing scenes behave identically.
var preview_mode: bool         = false

# ─── DAMAGE OVER TIME (Insertion Tower) ────────────────
var _dot_damage: float        = 0.0
var _dot_timer: float         = 0.0
var _dot_tick_interval: float = 0.5
var _dot_tick_timer: float    = 0.0

# ─── TYPE-SPECIFIC STATE ───────────────────────────────
var type_data: Dictionary = {}

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
	type_data          = p_type_data
	_setup_type()
	_setup_spire()
	if waypoints.size() > 0:
		position = waypoints[0]
		_last_position = waypoints[0]

	# Allow enemies to pass through each other
	collision_mask = 0	

func _setup_type() -> void:
	var edef = GameManager.ENEMY_DEFINITIONS.get(enemy_type, {})
	enemy_color = edef.get("color", Color.WHITE)
	# Base stats come pre-scaled from EnemyData (via WaveManager/initialize).
	ram_reward = int(edef.get("ram_reward", 10))
	match enemy_type:
		"queue_jumper":
			type_data["base_speed"] = move_speed
		"overflow_packet":
			type_data["layers"] = 0
			type_data["base_max_hp"] = max_health
		"linked_drain":
			type_data["link_color"] = Color("#00FF88")
			if not type_data.has("partner"):
				type_data["partner"] = null
		"bubble_shield":
			type_data["shield_hp"] = 3
			type_data["shield_max"] = 3
		"pivot_splitter":
			type_data["has_split"] = false
		"indexed_packet":
			type_data["index"] = randi() % 5
		"selection_mark":
			type_data["marked"] = false
		"merge_twin":
			type_data["merged"] = false
			if not type_data.has("partner"):
				type_data["partner"] = null
		"count_meter":
			type_data["count"] = 0
			type_data["count_max"] = 5
		"radix_digit":
			type_data["segment"] = 0  # 0=units, 1=tens, 2=hundreds
			var seg_hp = max_health / 3.0
			type_data["segment_hp"] = [seg_hp, seg_hp, seg_hp]
			type_data["segment_max"] = [seg_hp, seg_hp, seg_hp]
		"scan_wave":
			type_data["scan_phase"] = 0.0
			type_data["scan_amplitude"] = 30.0
			type_data["vulnerable"] = true
		"binary_mask":
			type_data["binary_side"] = false  # false=left vulnerable, true=right
			type_data["switch_timer"] = 2.0

func _setup_spire() -> void:
	if not SPIRE_VARIANTS.has(enemy_type):
		return
	var entry = SPIRE_VARIANTS[enemy_type]
	var variant_name = entry["variant"] if entry is Dictionary else entry
	var pack_name = entry.get("pack", "enemy_pack1") if entry is Dictionary else "enemy_pack1"
	_spire = _SpireEnemy.new()
	_spire.name = "SpireSprite"
	add_child(_spire)
	_spire.setup(variant_name, pack_name)

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

	# Damage-over-time tick (from Insertion Tower)
	if _dot_timer > 0:
		_dot_tick_timer -= delta
		_dot_timer      -= delta
		if _dot_tick_timer <= 0:
			var dot_amt = _dot_damage
			if enemy_type == "insertion_stack":
				dot_amt *= 1.5
			take_damage(dot_amt)
			_dot_tick_timer = _dot_tick_interval

	# Type-specific per-frame logic
	_process_type(delta)

	_bob_time += delta * 3.0
	if _flash_timer > 0:
		_flash_timer -= delta
	if current_waypoint >= waypoints.size():
		_reach_end()
		return
	_move_toward_waypoint(delta)

	# Update spire animation state based on movement
	if _spire:
		var is_moving = current_waypoint < waypoints.size() and not is_dead
		_spire.set_state("move" if is_moving else "idle")
		# Update direction based on actual movement delta
		var move_delta = position - _last_position
		if move_delta.length() > 0.5:
			var dir_str = _dir_from_velocity(move_delta)
			_spire.set_direction(dir_str)
			_spire.set_flip_h(move_delta.x < 0)
		_last_position = position

	_mobile_redraw_skip += 1
	if _mobile_redraw_skip % 2 == 0:
		queue_redraw()

func _process_type(delta: float) -> void:
	match enemy_type:
		"queue_jumper":
			# Speed up as enemies ahead die: scan ahead on path, fewer enemies = faster
			var ahead_count = _count_enemies_ahead()
			var speed_scale = 0.5 + (1.0 - float(ahead_count) / 10.0) * 1.0
			move_speed = type_data["base_speed"] * clamp(speed_scale, 0.5, 1.5)

		"overflow_packet":
			# Grow layers over time or when nearby enemies die — handled via external call
			pass

		"bubble_shield":
			# Shield regenerates slowly
			if type_data["shield_hp"] < type_data["shield_max"]:
				type_data["shield_hp"] += delta * 0.5

		"scan_wave":
			type_data["scan_phase"] += delta * 3.0
			# Vulnerable only at extremes of oscillation
			var phase_val = sin(type_data["scan_phase"])
			type_data["vulnerable"] = abs(phase_val) > 0.85

		"binary_mask":
			type_data["switch_timer"] -= delta
			if type_data["switch_timer"] <= 0:
				type_data["binary_side"] = not type_data["binary_side"]
				type_data["switch_timer"] = 2.0 + randf() * 1.0

		"selection_mark":
			# Re-check lowest HP status each frame
			type_data["marked"] = _is_lowest_hp_enemy()

		"radix_digit":
			# Update segment display based on remaining HP
			var total_hp = type_data["segment_hp"][0] + type_data["segment_hp"][1] + type_data["segment_hp"][2]
			current_health = total_hp
			max_health = type_data["segment_max"][0] + type_data["segment_max"][1] + type_data["segment_max"][2]

		"linked_drain":
			# Pulse link line
			_bob_time += delta * 1.5

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

func _dir_from_velocity(vel: Vector2) -> String:
	# Map a 2D movement vector to one of 3 sprite directions: down, up, right
	# down = facing the camera (positive y in Godot 2D = downward on screen)
	if abs(vel.y) > abs(vel.x):
		return "down" if vel.y > 0 else "up"
	else:
		return "right"

func _move_toward_waypoint(delta: float) -> void:
	var target    = waypoints[current_waypoint]
	var direction = (target - position).normalized()

	# scan_wave oscillates perpendicular to path direction
	if enemy_type == "scan_wave":
		var perp = Vector2(-direction.y, direction.x)
		var osc = sin(type_data["scan_phase"]) * type_data["scan_amplitude"]
		position += perp * osc * delta

	velocity      = direction * move_speed
	move_and_slide()

	# Path correction — snap back to the line between waypoints
	# Prevents enemies drifting off the path due to collisions
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

# ─── DAMAGE-OVER-TIME ──────────────────────────────────
func apply_dot(total_damage: float, duration: float) -> void:
	_dot_damage = total_damage / (duration / _dot_tick_interval)
	if enemy_type == "insertion_stack":
		_dot_damage *= 1.5
	_dot_timer  = duration

func take_damage(amount: float) -> void:
	if is_dead:
		return

	var final_damage = amount

	# Type-specific damage modifiers
	match enemy_type:
		"indexed_packet":
			final_damage *= 0.5  # Always reduced — Array Tower's fast multi-hit counters this

		"overflow_packet":
			final_damage *= 0.7  # Inherent resistance, weakens as layers are removed

		"bubble_shield":
			if type_data["shield_hp"] > 0:
				type_data["shield_hp"] -= 1
				final_damage = 0.0
				_flash_timer = 0.1
				queue_redraw()
				return

		"linked_drain":
			var partner = type_data.get("partner")
			if partner and is_instance_valid(partner) and not partner.is_dead:
				var shared = final_damage * 0.5
				final_damage *= 0.5
				partner.take_damage_direct(shared)

		"selection_mark":
			if not type_data["marked"]:
				final_damage *= 0.25  # Heavy resistance unless it's lowest HP

		"insertion_stack":
			# DoT does extra, direct damage is normal — handled in apply_dot
			pass

		"count_meter":
			type_data["count"] += 1
			if type_data["count"] >= type_data["count_max"]:
				type_data["count"] = 0
				# Takes full damage on counter reset
			else:
				final_damage *= 0.2  # Heavy resistance while counting

		"radix_digit":
			var seg = type_data["segment"]
			var seg_hp = type_data["segment_hp"]
			if seg < 3:
				seg_hp[seg] -= final_damage
				if seg_hp[seg] <= 0:
					var overflow = -seg_hp[seg]
					seg_hp[seg] = 0
					type_data["segment"] += 1
					if type_data["segment"] < 3:
						seg_hp[type_data["segment"]] -= overflow
			var total_left = seg_hp[0] + seg_hp[1] + seg_hp[2]
			if total_left <= 0:
				current_health = 0
				_die()
				return
			return

		"scan_wave":
			if not type_data["vulnerable"]:
				final_damage *= 0.1  # Nearly immune between scan extremes

		"binary_mask":
			# Binary search concept: 50/50 chance of hitting vulnerable side
			# When you guess right side, full damage; wrong side, minimal
			var hit_correct = randi() % 2 == 0
			if type_data["binary_side"]:
				hit_correct = not hit_correct
			if not hit_correct:
				final_damage *= 0.2

	current_health -= final_damage
	_flash_timer    = 0.15
	queue_redraw()
	if current_health <= 0:
		_die()

# Direct damage for linked partners
func take_damage_direct(amount: float) -> void:
	if is_dead:
		return
	current_health -= amount
	_flash_timer    = 0.15
	queue_redraw()
	if current_health <= 0:
		_die()

func _die() -> void:
	if is_dead:
		return
	is_dead = true

	# Notify overflow packets ahead that an enemy behind them died
	_notify_overflow_ahead()

	match enemy_type:
		"pivot_splitter":
			if not type_data["has_split"]:
				type_data["has_split"] = true
				_spawn_split_enemies(2)

		"merge_twin":
			var partner = type_data.get("partner")
			if partner and is_instance_valid(partner) and not partner.is_dead:
				partner._on_merge_partner_died(current_health)

		"linked_drain":
			var partner = type_data.get("partner")
			if partner and is_instance_valid(partner) and not partner.is_dead:
				partner.type_data["partner"] = null

	SoundManager.play_enemy_death()
	SignalBus.enemy_defeated.emit(name)
	enemy_defeated.emit(self)

	# For spire enemies, play death animation before freeing
	if _spire:
		_spire.set_state("death")
		set_physics_process(false)
		set_process(false)
		# Fade out the spire sprite, then free
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.8)
		tween.tween_callback(queue_free)
	else:
		queue_free()

func _on_merge_partner_died(partner_hp: float) -> void:
	if is_dead:
		return
	type_data["merged"] = true
	max_health += partner_hp * 0.5
	current_health = min(current_health + partner_hp * 0.3, max_health)
	move_speed *= 1.3
	enemy_color = Color("#FFB800")  # Gold = merged state
	queue_redraw()

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
		var split = duplicate()
		if split and get_parent():
			get_parent().add_child(split)
			split.position      = position + perp * (i * 20 - 10)
			split.enemy_type    = "basic_packet"
			split.max_health    = 60.0
			split.current_health = 60.0
			split.move_speed    = 90.0
			split._setup_type()
			split.current_waypoint = current_waypoint
			split.waypoints     = waypoints
			if wm:
				split.connect("enemy_defeated", Callable(wm, "_on_enemy_defeated"))
				split.connect("enemy_reached_end", Callable(wm, "_on_enemy_reached_end"))
				wm.enemies_alive += 1
				wm.enemy_spawned.emit(split)

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
	var layers = type_data.get("layers", 0) + 1
	type_data["layers"] = layers
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

# ─── DRAW CONSTANTS ────────────────────────────────────
const SQUASH: float = 0.65  # Perspective squashing ratio for 3D camera lookup

# ─── 3D PRIMITIVE HELPERS ───────────────────────────────
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
	var outline_loop = top_pts.duplicate()
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

# ─── DRAW ──────────────────────────────────────────────
func _draw() -> void:
	var flash = _flash_timer > 0
	var col   = Color("#FFFFFF") if flash else enemy_color
	var bob   = sin(_bob_time) * 2.0

	# For spire-mapped enemies, skip procedural body drawing (the spire sprite is shown instead)
	if not _spire:
		match enemy_type:
			"basic_packet":      _draw_basic(col, bob)
			"queue_jumper":      _draw_queue_jumper(col, bob)
			"overflow_packet":   _draw_overflow(col, bob)
			"linked_drain":      _draw_linked(col, bob)
			"bubble_shield":     _draw_bubble(col, bob)
			"pivot_splitter":    _draw_pivot(col, bob)
			"indexed_packet":    _draw_indexed(col, bob)
			"selection_mark":    _draw_selection(col, bob)
			"insertion_stack":   _draw_insertion(col, bob)
			"merge_twin":        _draw_merge(col, bob)
			"count_meter":       _draw_count(col, bob)
			"radix_digit":       _draw_radix(col, bob)
			"scan_wave":         _draw_scan(col, bob)
			"binary_mask":       _draw_binary(col, bob)
			_:
				# Fallback for any future types
				_draw_3d_box(Vector2(0, bob - 2), Vector2(12, 12), 10.0, col, col.lightened(0.3), 1.5)
	else:
		# Damage flash overlay for spire enemies
		if flash:
			var pulse = (sin(_bob_time * 8.0) + 1.0) * 0.3
			modulate = Color(1.0 + pulse, 1.0 + pulse, 1.0 + pulse, 1.0)

	_draw_health_bar()

	# DOT visual indicator
	if _dot_timer > 0:
		var pulse = (sin(_bob_time * 4.0) + 1.0) * 0.5
		draw_circle(Vector2(16, -32), 3.0 + pulse * 1.5, Color("#1ABC9C", 0.8))

	# Type-specific overlay draws
	_draw_type_overlay(bob)

func _draw_type_overlay(bob: float) -> void:
	match enemy_type:
		"indexed_packet":
			var idx = type_data.get("index", 0)
			draw_string(ThemeDB.fallback_font, Vector2(-4, 6 + bob), str(idx),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#FFFFFF"))

		"queue_jumper":
			var ahead = _count_enemies_ahead()
			draw_string(ThemeDB.fallback_font, Vector2(-6, 14 + bob), "#" + str(ahead),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#FFFFFF", 0.7))

		"count_meter":
			var cnt = type_data.get("count", 0)
			var maxc = type_data.get("count_max", 5)
			for i in range(maxc):
				var x = -8 + i * 4
				var h = 4.0 if i < cnt else 2.0
				draw_rect(Rect2(x, 6 + bob, 2, h),
					Color("#FFB800") if i < cnt else Color("#FFFFFF", 0.3))

		"radix_digit":
			var seg = type_data.get("segment", 0)
			var seg_hp = type_data.get("segment_hp", [])
			for i in range(3):
				var x = -14 + i * 14
				var frac = 0.0 if i < seg else \
					(seg_hp[i] / type_data["segment_max"][i] if i < seg_hp.size() else 0.0)
				var h = 4.0
				var c = Color("#FFFFFF", 0.15) if i < seg else \
					(Color("#FF5722") if frac > 0.5 else Color("#FFB800"))
				draw_rect(Rect2(x, 10 + bob, 10, h), Color("#1A0A0A"))
				draw_rect(Rect2(x, 10 + bob, 10 * frac, h), c)

		"binary_mask":
			var side = type_data.get("binary_side", false)
			# Draw half-highlight to indicate vulnerable side
			if side:
				draw_rect(Rect2(0, -14 + bob, 14, 28), Color("#FFFFFF", 0.15))
			else:
				draw_rect(Rect2(-14, -14 + bob, 14, 28), Color("#FFFFFF", 0.15))
			# Draw divider line
			draw_line(Vector2(0, -14 + bob), Vector2(0, 14 + bob), Color("#FFFFFF", 0.4), 1.0)

		"merge_twin":
			if type_data.get("merged", false):
				draw_arc(Vector2(0, 0 + bob), 18, 0, TAU, 16, Color("#FFB800", 0.5), 2.0)

		"linked_drain":
			# Draw link line to partner if exists
			var partner = type_data.get("partner")
			if partner and is_instance_valid(partner) and not partner.is_dead:
				var link_col = type_data.get("link_color", Color("#00FF88"))
				var pulse = (sin(_bob_time * 2.0) + 1.0) * 0.3
				draw_line(Vector2(0, 0), to_local(partner.position),
					Color(link_col, 0.4 + pulse), 1.5)
				# Small circle at connection point
				draw_circle(Vector2(0, -16 + bob), 2.0, Color(link_col, 0.6))

		"scan_wave":
			var vulnerable = type_data.get("vulnerable", true)
			if vulnerable:
				draw_arc(Vector2(0, 0 + bob), 20, 0, TAU, 16, Color("#00FF88", 0.6), 2.0)
			else:
				draw_arc(Vector2(0, 0 + bob), 18, 0, TAU, 16, Color("#FF3366", 0.3), 1.0)

# --- OLD PROCEDURAL DRAW FUNCTIONS (RESTORED) -------------------

func _draw_basic(col: Color, bob: float) -> void:
	# 3D data packet cube
	_draw_3d_box(Vector2(0, bob - 4), Vector2(13, 13), 8.0, Color("#15202E"), col, 1.5)
	# Top face circuit lines
	draw_line(Vector2(-7, bob - 4 - 8 * SQUASH + 2), Vector2(7, bob - 4 - 8 * SQUASH + 2), Color(col, 0.6), 1.0)
	draw_circle(Vector2(0, bob - 4 - 8 * SQUASH), 2.0, Color(col, 0.7))
	# Drop shadow
	draw_set_transform(Vector2(0, bob + 4), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 12, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_queue_jumper(col: Color, bob: float) -> void:
	# 3D arrow/wedge (pointing right = motion direction)
	var ahead = _count_enemies_ahead()
	var scale = 0.85 + (1.0 - float(ahead) / 10.0) * 0.3
	var w = 12.0 * scale
	var h = 8.0 * scale
	# Body: 3D extruded arrow shape using diamond prism
	var tip = Vector2(w * 1.1, bob)
	var top = Vector2(-w * 0.6, bob - h)
	var bot = Vector2(-w * 0.6, bob + h)
	var back = Vector2(-w * 0.9, bob)
	# Draw extruded arrow as 3D box on its side
	_draw_3d_box(Vector2(0, bob - 1), Vector2(w, h), 7.0, Color("#15202E"), col, 1.5)
	# Tip cone
	_draw_3d_hexagon(Vector2(w + 4, bob), 6.0, 5.0, Color("#15202E"), col, 1.3)
	# Speed lines (more when faster)
	var trail_count = max(1, 5 - int(ahead / 2))
	for i in range(trail_count):
		var tx = -w * 0.9 - 6 - i * 4
		draw_line(Vector2(tx, bob - 3), Vector2(tx - 4, bob), Color(col, 0.5 - i * 0.07), 1.5)
		draw_line(Vector2(tx - 4, bob), Vector2(tx, bob + 3), Color(col, 0.5 - i * 0.07), 1.5)
	# Drop shadow
	draw_set_transform(Vector2(0, bob + 8), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 14, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_overflow(col: Color, bob: float) -> void:
	# 3D stacked cubes - grows with layers
	var layers = type_data.get("layers", 0)
	var stack_height = min(layers, 4) * 4.0
	# Bottom base layer (always)
	_draw_3d_box(Vector2(0, bob - 2), Vector2(13, 13), 7.0, Color("#15202E"), col, 1.5)
	# Stacked layers above
	for i in range(min(layers, 4)):
		var y_offset = bob - 10 - i * 8.0
		var layer_col = Color(col).lerp(Color("#FFB800"), float(i) / 4.0)
		_draw_3d_box(Vector2(0, y_offset), Vector2(10 - i * 0.8, 10 - i * 0.8), 6.0,
			Color("#15202E"), layer_col, 1.3)
	# Top crown spike
	if layers > 0:
		var top_y = bob - 10 - stack_height
		draw_line(Vector2(0, top_y - 8 * SQUASH), Vector2(0, top_y - 18), Color("#FFB800"), 2.0)

func _draw_linked(col: Color, bob: float) -> void:
	# 3D hexagonal prism (linked list node)
	_draw_3d_hexagon(Vector2(0, bob - 2), 12.0, 7.0, Color("#15202E"), col, 1.5)
	# Top face connector dots
	for i in range(6):
		var a = i * PI / 3.0
		var px = cos(a) * 8
		var py = bob - 2 + sin(a) * 8 * SQUASH
		draw_circle(Vector2(px, py - 7 * SQUASH), 1.2, Color("#00FF88", 0.8))
	# Drop shadow
	draw_set_transform(Vector2(0, bob + 5), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 12, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_bubble(col: Color, bob: float) -> void:
	# 3D sphere core
	_draw_3d_sphere(Vector2(0, bob - 2), 11.0, col)
	# Shield ring (orbiting segments)
	var shield_hp = type_data.get("shield_hp", 0)
	var shield_max = type_data.get("shield_max", 3)
	if shield_hp > 0:
		var seg_angle = TAU / shield_max
		for i in range(shield_max):
			var a = i * seg_angle + _bob_time * 0.3
			var sx = cos(a) * 16
			var sy = bob - 2 + sin(a) * 16 * SQUASH
			var is_active = i < shield_hp
			var seg_col = Color("#00D4FF", 0.8) if is_active else Color("#1A3A5A", 0.4)
			draw_circle(Vector2(sx, sy), 2.5, seg_col)
			# Connecting ring
			if i < shield_max - 1:
				var a2 = (i + 1) * seg_angle + _bob_time * 0.3
				draw_line(Vector2(sx, sy), Vector2(cos(a2) * 16, bob - 2 + sin(a2) * 16 * SQUASH), Color("#00D4FF", 0.3), 1.0)
	# Drop shadow
	draw_set_transform(Vector2(0, bob + 8), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 16, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_pivot(col: Color, bob: float) -> void:
	# Large 3D box boss with prominent pivot line
	_draw_3d_box(Vector2(0, bob - 4), Vector2(20, 12), 12.0, Color("#15202E"), col, 2.0)
	# Top-face pivot rod (long thin 3D box running through center)
	_draw_3d_box(Vector2(0, bob - 4 - 12 * SQUASH), Vector2(22, 1.5), 3.0, Color("#0D141C"), Color("#FFFFFF", 0.8), 1.0)
	# Top face warning markers
	draw_circle(Vector2(-14, bob - 4 - 12 * SQUASH), 2.0, Color("#FFFFFF", 0.7))
	draw_circle(Vector2(14, bob - 4 - 12 * SQUASH), 2.0, Color("#FFFFFF", 0.7))
	# Side spikes (3D cylinders pointing up)
	var spike_positions = [-12.0, 0.0, 12.0]
	for sx in spike_positions:
		_draw_3d_cylinder(Vector2(sx, bob - 4 - 12 * SQUASH - 6), 2.0, 6.0, Color("#0F1720"), col, 1.2)
		_draw_3d_sphere(Vector2(sx, bob - 4 - 12 * SQUASH - 12), 2.5, col)
	# Drop shadow
	draw_set_transform(Vector2(0, bob + 8), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 22, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_indexed(col: Color, bob: float) -> void:
	# 3D data packet with bracket frame and number tile on top
	# Outer bracket frame (3D box, narrow)
	_draw_3d_box(Vector2(0, bob - 2), Vector2(13, 13), 8.0, Color("#15202E"), col, 1.5)
	# Index number tile on top (smaller 3D box)
	var idx = type_data.get("index", 0)
	var tile_y = bob - 2 - 8 * SQUASH - 4
	_draw_3d_box(Vector2(0, tile_y), Vector2(7, 7), 3.0, Color("#0F1A2E"), Color("#FFFFFF", 0.9), 1.2)
	# Bracket corners (drawn as short cylinder posts on each corner)
	var corners = [Vector2(-11, -11), Vector2(11, -11), Vector2(-11, 11), Vector2(11, 11)]
	for c in corners:
		draw_line(Vector2(c.x * 0.4, bob - 2 + c.y * 0.4 - 8 * SQUASH),
			Vector2(c.x * 0.4 + c.x * 0.3, bob - 2 + c.y * 0.4 - 8 * SQUASH),
			col, 1.5)
	# Drop shadow
	draw_set_transform(Vector2(0, bob + 6), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 14, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_selection(col: Color, bob: float) -> void:
	# 3D octagonal prism with crosshair target
	var marked = type_data.get("marked", false)
	var outline_col = Color("#FFD700") if marked else col
	# Build octagonal top points (in local coords)
	var top_pts = PackedVector2Array()
	for i in range(8):
		var a = i * TAU / 8.0
		top_pts.append(Vector2(cos(a) * 12, sin(a) * 12 * SQUASH))
	# Translate to bob position
	draw_set_transform(Vector2(0, bob - 3), 0.0, Vector2.ONE)
	# Draw extruded side panels (8 faces)
	for i in range(8):
		var next_i = (i + 1) % 8
		var t1 = top_pts[i]
		var t2 = top_pts[next_i]
		var b1 = t1 + Vector2(0, 6)
		var b2 = t2 + Vector2(0, 6)
		draw_colored_polygon([t1, t2, b2, b1], Color("#0D141C"))
		draw_polyline(PackedVector2Array([t1, t2]), outline_col, 1.5)
		draw_polyline(PackedVector2Array([b1, b2]), outline_col, 1.5)
	# Top face
	draw_colored_polygon(top_pts, Color("#1E2C3D"))
	draw_polyline(PackedVector2Array([top_pts[0], top_pts[1], top_pts[2], top_pts[3], top_pts[4], top_pts[5], top_pts[6], top_pts[7], top_pts[0]]), outline_col, 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Crosshair target on top
	draw_line(Vector2(-5, 0), Vector2(5, 0), outline_col, 1.0)
	draw_line(Vector2(0, -5), Vector2(0, 5), outline_col, 1.0)
	draw_circle(Vector2.ZERO, 2.0, outline_col, true, 1.0)
	# Drop shadow
	draw_set_transform(Vector2(0, bob + 8), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 18, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_scan(col: Color, bob: float) -> void:
	# 3D elongated hexagon with scan beam
	var vulnerable = type_data.get("vulnerable", true)
	# Build elongated hex top points
	var top_pts = PackedVector2Array()
	for i in range(6):
		var a = i * PI / 3.0
		var rx = 16.0 if i % 2 == 0 else 8.0
		var ry = 7.0
		top_pts.append(Vector2(cos(a) * rx, sin(a) * ry * SQUASH))
	# Side panels
	draw_set_transform(Vector2(0, bob - 2), 0.0, Vector2.ONE)
	for i in range(6):
		var next_i = (i + 1) % 6
		var t1 = top_pts[i]
		var t2 = top_pts[next_i]
		var b1 = t1 + Vector2(0, 5)
		var b2 = t2 + Vector2(0, 5)
		draw_colored_polygon([t1, t2, b2, b1], Color("#0D141C"))
		draw_polyline(PackedVector2Array([t1, t2]), Color("#00D4FF"), 1.5)
		draw_polyline(PackedVector2Array([b1, b2]), Color("#00D4FF", 0.4), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Top face
	draw_colored_polygon(top_pts, Color("#1E2C3D"))
	draw_polyline(PackedVector2Array([top_pts[0], top_pts[1], top_pts[2], top_pts[3], top_pts[4], top_pts[5], top_pts[0]]), Color("#00D4FF"), 1.5)
	# Scan beam
	if vulnerable:
		draw_line(Vector2(-8, bob), Vector2(8, bob), Color("#00FF88", 0.7), 2.0)
	else:
		draw_line(Vector2(-8, bob), Vector2(8, bob), Color("#FF3366", 0.5), 2.0)
	# Drop shadow
	draw_set_transform(Vector2(0, bob + 6), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 18, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_insertion(col: Color, bob: float) -> void:
	# 3D triangular wedge pointing right (insertion direction)
	# Build triangular top points (pointing right)
	var top_pts = PackedVector2Array([
		Vector2(13, 0),
		Vector2(-9, -11 * SQUASH),
		Vector2(-9, 11 * SQUASH)
	])
	# Translate to bob position
	draw_set_transform(Vector2(0, bob - 2), 0.0, Vector2.ONE)
	# Side panels (3 faces)
	for i in range(3):
		var next_i = (i + 1) % 3
		var t1 = top_pts[i]
		var t2 = top_pts[next_i]
		var b1 = t1 + Vector2(0, 7)
		var b2 = t2 + Vector2(0, 7)
		var panel = PackedVector2Array([t1, t2, b2, b1])
		draw_colored_polygon(panel, Color("#0D141C"))
		draw_colored_polygon(panel, Color(col, 0.3))
		draw_polyline(PackedVector2Array([t1, t2, b2, b1]), col, 1.5)
	# Top face
	draw_colored_polygon(top_pts, Color("#1E2C3D"))
	var outline_loop = top_pts.duplicate()
	outline_loop.append(top_pts[0])
	draw_polyline(outline_loop, col, 1.5)
	# Insertion arrow indicator on top
	draw_line(Vector2(-7, -3 * SQUASH), Vector2(2, -3 * SQUASH), Color("#FFFFFF", 0.8), 1.5)
	draw_line(Vector2(2, -3 * SQUASH), Vector2(-1, -6 * SQUASH), Color("#FFFFFF", 0.8), 1.5)
	draw_line(Vector2(2, -3 * SQUASH), Vector2(-1, 0), Color("#FFFFFF", 0.8), 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Drop shadow
	draw_set_transform(Vector2(0, bob + 6), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 12, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_merge(col: Color, bob: float) -> void:
	# Two 3D spheres connected by a bridge (merge concept)
	var merged = type_data.get("merged", false)
	var draw_col = Color("#FFB800") if merged else col
	# Left sphere
	_draw_3d_sphere(Vector2(-8, bob - 2), 7.0, draw_col)
	# Right sphere
	_draw_3d_sphere(Vector2(8, bob - 2), 7.0, draw_col)
	# Merge bridge (3D box connecting them)
	_draw_3d_box(Vector2(0, bob - 1), Vector2(7, 1.5), 3.0, Color("#0D141C"), draw_col, 1.2)
	# Merge arrows on top of bridge
	draw_line(Vector2(-3, bob - 4), Vector2(3, bob - 4), Color(draw_col, 0.7), 1.2)
	draw_line(Vector2(3, bob - 4), Vector2(1, bob - 6), Color(draw_col, 0.7), 1.2)
	draw_line(Vector2(3, bob - 4), Vector2(1, bob - 2), Color(draw_col, 0.7), 1.2)
	# Drop shadow
	draw_set_transform(Vector2(0, bob + 6), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 14, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_count(col: Color, bob: float) -> void:
	# 3D cube with tally counter block on top
	_draw_3d_box(Vector2(0, bob - 2), Vector2(11, 11), 6.0, Color("#15202E"), col, 1.5)
	# Top hash symbol (3D cylinder bars on top face)
	var hash_y = bob - 2 - 11 * SQUASH
	draw_line(Vector2(-5, hash_y), Vector2(-5, hash_y - 3), col, 2.0)
	draw_line(Vector2(0, hash_y), Vector2(0, hash_y - 3), col, 2.0)
	draw_line(Vector2(5, hash_y), Vector2(5, hash_y - 3), col, 2.0)
	draw_line(Vector2(-6, hash_y - 1.5), Vector2(6, hash_y - 1.5), col, 2.0)
	# Drop shadow
	draw_set_transform(Vector2(0, bob + 5), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 12, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_radix(col: Color, bob: float) -> void:
	# 3D segmented bar (3 digit sections stacked horizontally)
	var seg = type_data.get("segment", 0)
	var seg_hp = type_data.get("segment_hp", [])
	var seg_max = type_data.get("segment_max", [100, 100, 100])
	# 3 small 3D boxes side by side, with different brightness based on depletion
	for i in range(3):
		var x_off = (i - 1) * 9.0
		var is_depleted = i < seg
		var is_current = i == seg
		var box_col = col
		if is_depleted:
			box_col = Color("#1A2A3A")
		elif is_current and seg_hp.size() > i:
			var frac = seg_hp[i] / seg_max[i] if seg_max[i] > 0 else 0
			box_col = Color(col).lerp(Color("#FFB800"), 1.0 - frac)
		_draw_3d_box(Vector2(x_off, bob - 2), Vector2(7, 8), 6.0, Color("#15202E"), box_col, 1.3)
	# Top digit labels
	draw_set_transform(Vector2(0, bob - 12), 0.0, Vector2.ONE)
	var labels = ["1", "10", "100"]
	for i in range(3):
		var dx = (i - 1) * 9.0
		var lbl_col = Color("#FFFFFF", 0.9) if i == seg else Color("#FFFFFF", 0.25)
		draw_string(ThemeDB.fallback_font, Vector2(dx - 5, 0),
			labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, lbl_col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Drop shadow
	draw_set_transform(Vector2(0, bob + 5), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 15, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_binary(col: Color, bob: float) -> void:
	# 3D cube split into two halves
	var side = type_data.get("binary_side", false)
	var v_col = Color("#00FF88") if side else Color("#FF3366")
	var nv_col = Color("#FF3366", 0.4) if side else Color("#00FF88", 0.4)
	# Left half
	_draw_3d_box(Vector2(-7, bob - 2), Vector2(6, 12), 7.0, Color("#15202E"), v_col if not side else nv_col, 1.5)
	# Right half
	_draw_3d_box(Vector2(7, bob - 2), Vector2(6, 12), 7.0, Color("#15202E"), v_col if side else nv_col, 1.5)
	# Gap line between halves
	draw_line(Vector2(0, bob - 14), Vector2(0, bob + 5), Color("#FFFFFF", 0.6), 1.5)
	# Top marker arrows indicating which side is vulnerable
	draw_line(Vector2(0, bob - 16), Vector2(0, bob - 12), v_col, 2.0)
	draw_circle(Vector2(0, bob - 17), 2.0, v_col)
	# Drop shadow
	draw_set_transform(Vector2(0, bob + 5), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 14, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_health_bar() -> void:
	var bar_width  = 36.0
	var bar_height = 5.0
	var bar_x      = -bar_width / 2.0
	var bar_y      = -32.0

	var hp_ratio: float
	if enemy_type == "radix_digit":
		var seg_hp = type_data.get("segment_hp", [])
		var total_hp = seg_hp[0] + seg_hp[1] + seg_hp[2] if seg_hp.size() >= 3 else current_health
		var total_max = type_data["segment_max"][0] + type_data["segment_max"][1] + type_data["segment_max"][2]
		hp_ratio = clamp(total_hp / total_max, 0.0, 1.0)
	else:
		hp_ratio = clamp(current_health / max_health, 0.0, 1.0)

	draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), Color("#1A0A0A"))

	var hp_color = Color("#00FF88") if hp_ratio > 0.6 \
				   else Color("#FFB800") if hp_ratio > 0.3 \
				   else Color("#FF3366")
	draw_rect(
		Rect2(bar_x, bar_y, bar_width * hp_ratio, bar_height),
		hp_color
	)

	draw_rect(
		Rect2(bar_x, bar_y, bar_width, bar_height),
		Color("#FFFFFF", 0.3), false, 1.0
	)

	# Shield bar for bubble_shield
	if enemy_type == "bubble_shield":
		var shield_ratio = clamp(float(type_data["shield_hp"]) / float(type_data["shield_max"]), 0.0, 1.0)
		draw_rect(Rect2(bar_x, bar_y - 3, bar_width * shield_ratio, 2), Color("#00D4FF"))

	if enemy_type == "pivot_splitter":
		draw_string(
			ThemeDB.fallback_font,
			Vector2(bar_x, bar_y - 4),
			str(int(current_health)) + "/" + str(int(max_health)),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
			Color("#E8F4FD")
		)
