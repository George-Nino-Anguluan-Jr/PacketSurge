# Tower.gd
extends Node2D

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
var current_target: Node  = null
var attack_timer: float   = 0.0
var enemy_layer: Node2D   = null
var grid_cell: Vector2i   = Vector2i.ZERO

func initialize(data: TowerData, cell: Vector2i, e_layer: Node2D) -> void:
	tower_id     = data.tower_id
	tower_name   = data.tower_name
	damage       = data.damage
	attack_speed = data.attack_speed
	attack_range = data.attack_range
	ram_cost     = data.ram_cost
	tower_color  = data.color
	icon_text    = data.icon_text
	grid_cell    = cell
	enemy_layer  = e_layer
	queue_redraw()

func _process(delta: float) -> void:
	attack_timer += delta
	if attack_timer >= 1.0 / attack_speed:
		attack_timer = 0.0
		_find_and_attack()

func _find_and_attack() -> void:
	if enemy_layer == null:
		return
	var closest_enemy: Node  = null
	var closest_dist: float  = attack_range

	for enemy in enemy_layer.get_children():
		if not enemy.has_method("take_damage"):
			continue
		var dist = position.distance_to(enemy.position)
		if dist <= closest_dist:
			closest_dist  = dist
			closest_enemy = enemy

	if closest_enemy:
		closest_enemy.take_damage(damage)
		current_target = closest_enemy
		queue_redraw()

func _draw() -> void:
	# Range circle
	draw_arc(
		Vector2.ZERO, attack_range,
		0, TAU, 32,
		Color(tower_color, 0.15), 1.0
	)
	# Tower base
	draw_circle(Vector2.ZERO, 24.0, Color("#0A1628"))
	draw_arc(
		Vector2.ZERO, 24.0,
		0, TAU, 32,
		tower_color, 2.0
	)
	# Tower icon text drawn as a visual indicator
	draw_circle(Vector2.ZERO, 8.0, tower_color)

	# Line to target
	if current_target and is_instance_valid(current_target):
		draw_line(
			Vector2.ZERO,
			current_target.position - position,
			Color(tower_color, 0.6),
			1.5
		)
