# Enemy.gd
extends CharacterBody2D

signal enemy_defeated(enemy: Node)
signal enemy_reached_end(enemy: Node)

# ─── STATS ─────────────────────────────────────────────
var max_health: float    = 100.0
var current_health: float = 100.0
var move_speed: float    = 80.0
var ram_reward: int      = 10
var damage_to_base: int  = 1

# ─── PATH ──────────────────────────────────────────────
var waypoints: Array[Vector2] = []
var current_waypoint: int     = 0
var is_dead: bool             = false

# ─── COLORS ────────────────────────────────────────────
var enemy_color: Color = Color("#FF3366")

func initialize(
		p_waypoints: Array[Vector2],
		p_health: float,
		p_speed: float) -> void:
	waypoints      = p_waypoints
	max_health     = p_health
	current_health = p_health
	move_speed     = p_speed
	if waypoints.size() > 0:
		position = waypoints[0]

func _physics_process(delta: float) -> void:
	if is_dead or waypoints.size() == 0:
		return
	if current_waypoint >= waypoints.size():
		_reach_end()
		return
	_move_toward_waypoint(delta)

func _move_toward_waypoint(delta: float) -> void:
	var target   = waypoints[current_waypoint]
	var direction = (target - position).normalized()
	velocity     = direction * move_speed
	move_and_slide()

	# Check if reached waypoint
	if position.distance_to(target) < 8.0:
		current_waypoint += 1
		if current_waypoint >= waypoints.size():
			_reach_end()

func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_health -= amount
	queue_redraw()
	if current_health <= 0:
		_die()

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	SignalBus.enemy_defeated.emit(name)
	enemy_defeated.emit(self)
	queue_free()

func _reach_end() -> void:
	if is_dead:
		return
	is_dead = true
	SignalBus.enemy_reached_end.emit(name)
	enemy_reached_end.emit(self)
	queue_free()

func _draw() -> void:
	# Enemy body
	draw_circle(Vector2.ZERO, 20.0, enemy_color)
	draw_circle(Vector2.ZERO, 20.0, Color("#FF0044"), false)

	# Health bar above enemy
	var bar_width  := 40.0
	var bar_height := 5.0
	var bar_x      := -bar_width / 2.0
	var bar_y      := -32.0
	var hp_ratio   := current_health / max_health

	# Background
	draw_rect(
		Rect2(bar_x, bar_y, bar_width, bar_height),
		Color("#2A0A0A")
	)
	# Health fill
	draw_rect(
		Rect2(bar_x, bar_y, bar_width * hp_ratio, bar_height),
		Color("#FF3366")
	)
