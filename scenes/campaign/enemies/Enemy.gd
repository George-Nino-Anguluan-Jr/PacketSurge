# Enemy.gd
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

# ─── DAMAGE OVER TIME (Insertion Tower) ────────────────
var _dot_damage: float        = 0.0
var _dot_timer: float         = 0.0
var _dot_tick_interval: float = 0.5
var _dot_tick_timer: float    = 0.0

func initialize(
		p_waypoints: Array[Vector2],
		p_health: float,
		p_speed: float,
		p_type: String = "basic_packet") -> void:
	waypoints      = p_waypoints
	max_health     = p_health
	current_health = p_health
	move_speed     = p_speed
	enemy_type     = p_type
	_setup_type()
	if waypoints.size() > 0:
		position = waypoints[0]

func _setup_type() -> void:
	match enemy_type:
		"basic_packet":
			enemy_color = Color("#FF3366")
			ram_reward  = 10
		"fast_packet":
			enemy_color = Color("#FF6B35")
			ram_reward  = 15
			move_speed  *= 2.0
		"heavy_packet":
			enemy_color = Color("#8E44AD")
			ram_reward  = 30
			move_speed  *= 0.5
			max_health  *= 3.0
			current_health = max_health
		"encrypted_packet":
			enemy_color = Color("#2ECC71")
			ram_reward  = 20
		"stealth_packet":
			enemy_color = Color("#95A5A6")
			ram_reward  = 25
			move_speed  *= 1.2
		"boss_packet":
			enemy_color = Color("#E74C3C")
			ram_reward  = 100
			move_speed  *= 0.5
			max_health  *= 5.0
			current_health = max_health

func _physics_process(delta: float) -> void:
	if is_dead or waypoints.size() == 0:
		return

	# Damage-over-time tick (from Insertion Tower)
	if _dot_timer > 0:
		_dot_tick_timer -= delta
		_dot_timer      -= delta
		if _dot_tick_timer <= 0:
			take_damage(_dot_damage)
			_dot_tick_timer = _dot_tick_interval

	_bob_time += delta * 3.0
	if _flash_timer > 0:
		_flash_timer -= delta
	if current_waypoint >= waypoints.size():
		_reach_end()
		return
	_move_toward_waypoint(delta)
	queue_redraw()

func _move_toward_waypoint(delta: float) -> void:
	var target    = waypoints[current_waypoint]
	var direction = (target - position).normalized()
	velocity      = direction * move_speed
	move_and_slide()
	if position.distance_to(target) < 8.0:
		current_waypoint += 1
		if current_waypoint >= waypoints.size():
			_reach_end()

# ─── DAMAGE-OVER-TIME (called by Insertion Tower) ──────
func apply_dot(total_damage: float, duration: float) -> void:
	_dot_damage = total_damage / (duration / _dot_tick_interval)
	_dot_timer  = duration

func take_damage(amount: float) -> void:
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
	# Boss splits into 3
	if enemy_type == "boss_packet":
		_spawn_split_enemies()
	SignalBus.enemy_defeated.emit(name)
	enemy_defeated.emit(self)
	queue_free()

func _spawn_split_enemies() -> void:
	for i in range(3):
		var split = duplicate()
		if split and get_parent():
			get_parent().add_child(split)
			split.position      = position + Vector2(i * 20 - 20, 0)
			split.enemy_type    = "basic_packet"
			split.max_health    = 60.0
			split.current_health = 60.0
			split.move_speed    = 90.0
			split._setup_type()
			split.current_waypoint = current_waypoint
			split.waypoints     = waypoints

func _reach_end() -> void:
	if is_dead:
		return
	is_dead = true
	SignalBus.enemy_reached_end.emit(name)
	enemy_reached_end.emit(self)
	queue_free()

func _draw() -> void:
	var flash = _flash_timer > 0
	var col   = Color("#FFFFFF") if flash else enemy_color
	var bob   = sin(_bob_time) * 2.0

	match enemy_type:
		"basic_packet":    _draw_basic(col, bob)
		"fast_packet":     _draw_fast(col, bob)
		"heavy_packet":    _draw_heavy(col, bob)
		"encrypted_packet":_draw_encrypted(col, bob)
		"stealth_packet":  _draw_stealth(col, bob)
		"boss_packet":     _draw_boss(col, bob)
		_:                 _draw_basic(col, bob)

	_draw_health_bar()

	# DOT visual indicator — small pulsing dot above health bar
	if _dot_timer > 0:
		var pulse = (sin(_bob_time * 4.0) + 1.0) * 0.5
		draw_circle(Vector2(16, -32), 3.0 + pulse * 1.5, Color("#1ABC9C", 0.8))

func _draw_basic(col: Color, bob: float) -> void:
	var y = bob
	draw_rect(Rect2(-14, -14 + y, 28, 28), Color(col, 0.3))
	draw_rect(Rect2(-14, -14 + y, 28, 28), col, false, 2.0)
	for i in range(3):
		var ly = -7 + i * 7 + y
		draw_line(Vector2(-8, ly), Vector2(8, ly), Color(col, 0.5), 1.0)

func _draw_fast(col: Color, bob: float) -> void:
	var y = bob
	var diamond = PackedVector2Array([
		Vector2(0, -12 + y), Vector2(16, y),
		Vector2(0, 12 + y), Vector2(-16, y)
	])
	draw_colored_polygon(diamond, Color(col, 0.3))
	for i in range(4):
		draw_line(diamond[i], diamond[(i + 1) % 4], col, 2.0)
	for i in range(3):
		var ly = -6 + i * 6 + y
		draw_line(Vector2(-24, ly), Vector2(-18, ly), Color(col, 0.4), 1.5)

func _draw_heavy(col: Color, bob: float) -> void:
	var y   = bob * 0.3
	var size = 20.0
	draw_rect(Rect2(-size, -size + y, size * 2, size * 2), Color(col, 0.4))
	draw_rect(Rect2(-size, -size + y, size * 2, size * 2), col, false, 3.0)
	draw_line(Vector2(-size, y), Vector2(size, y), Color(col, 0.6), 2.0)
	draw_line(Vector2(0, -size + y), Vector2(0, size + y), Color(col, 0.6), 2.0)

func _draw_encrypted(col: Color, bob: float) -> void:
	var y = bob
	draw_rect(Rect2(-14, -14 + y, 28, 28), Color(col, 0.3))
	draw_rect(Rect2(-14, -14 + y, 28, 28), col, false, 2.0)
	draw_rect(Rect2(-6, -2 + y, 12, 10), Color(col, 0.8))
	draw_arc(Vector2(0, -2 + y), 5.0, PI, TAU, 16, col, 2.0)

func _draw_stealth(col: Color, bob: float) -> void:
	var alpha = 0.35
	var y     = bob
	var points = PackedVector2Array([
		Vector2(0, -16 + y), Vector2(12, -4 + y),
		Vector2(12, 12 + y), Vector2(6, 8 + y),
		Vector2(0, 12 + y), Vector2(-6, 8 + y),
		Vector2(-12, 12 + y), Vector2(-12, -4 + y)
	])
	draw_colored_polygon(points, Color(col, alpha))
	for i in range(points.size()):
		draw_line(
			points[i], points[(i + 1) % points.size()],
			Color(col, alpha + 0.1), 1.5
		)
	draw_circle(Vector2(-4, -2 + y), 2.5, Color(col, 0.8))
	draw_circle(Vector2(4, -2 + y), 2.5, Color(col, 0.8))

func _draw_boss(col: Color, bob: float) -> void:
	var y     = bob * 0.2
	var size  = 24.0
	draw_rect(Rect2(-size, -size * 0.5 + y, size * 2, size), Color(col, 0.4))
	draw_rect(Rect2(-size, -size * 0.5 + y, size * 2, size), col, false, 3.0)
	var spike_positions = [-16.0, 0.0, 16.0]
	for sx in spike_positions:
		draw_line(
			Vector2(sx, -size * 0.5 + y),
			Vector2(sx, -size * 0.5 - 12 + y),
			col, 3.0
		)
		draw_circle(Vector2(sx, -size * 0.5 - 12 + y), 4.0, col)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-8, 6 + y),
		"BOSS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
		Color("#FFFFFF")
	)

func _draw_health_bar() -> void:
	var bar_width  = 36.0
	var bar_height = 5.0
	var bar_x      = -bar_width / 2.0
	var bar_y      = -32.0
	var hp_ratio   = clamp(current_health / max_health, 0.0, 1.0)

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

	if enemy_type == "boss_packet":
		draw_string(
			ThemeDB.fallback_font,
			Vector2(bar_x, bar_y - 4),
			str(int(current_health)) + "/" + str(int(max_health)),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
			Color("#E8F4FD")
		)
