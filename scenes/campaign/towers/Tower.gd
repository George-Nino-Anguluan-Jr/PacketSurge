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
var current_target: Node       = null
var attack_timer: float        = 0.0
var enemy_layer: Node2D        = null
var grid_cell: Vector2i        = Vector2i.ZERO
var _shoot_flash: float        = 0.0
var _entry_order: Array[Node]  = []  # Tracks enemies in order they entered range (for Stack/Queue)
var _flash_targets: Array[Vector2] = []  # Multiple flash lines for AoE/chain attacks

# ─── SPRITE LOOKUP ──────────────────────────────────────
const TOWER_SPRITES = {
	"tower_array": "res://assets/sprites/towers/tower_array.png",
}

@onready var sprite: Sprite2D = $TowerSprite

func initialize(data: TowerData, cell: Vector2i, e_layer: Node2D) -> void:
	tower_id      = data.tower_id
	tower_name    = data.tower_name
	damage        = data.damage
	attack_speed  = data.attack_speed
	attack_range  = data.attack_range
	ram_cost      = data.ram_cost
	tower_color   = data.color
	icon_text     = data.icon_text
	grid_cell     = cell
	enemy_layer   = e_layer
	_setup_sprite()
	_animate_placement()
	queue_redraw()

func _setup_sprite() -> void:
	if TOWER_SPRITES.has(tower_id):
		var tex = load(TOWER_SPRITES[tower_id])
		if tex:
			sprite.texture = tex
			sprite.visible = true
			sprite.z_index = 10
			sprite.offset = Vector2(0, -tex.get_height() * sprite.scale.y * 0.35)
	else:
		sprite.visible = false

func _animate_placement() -> void:
	sprite.scale = sprite.scale * 0.3
	var target_scale = sprite.scale / 0.3
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(sprite, "scale", target_scale, 0.35)

func _process(delta: float) -> void:
	attack_timer += delta
	_update_entry_order()

	if _shoot_flash > 0:
		_shoot_flash -= delta * 4.0
		queue_redraw()

	if attack_timer >= 1.0 / attack_speed:
		attack_timer = 0.0
		_attack()

# ─── TRACK ENEMIES ENTERING RANGE (needed for Stack/Queue logic) ──
func _update_entry_order() -> void:
	if enemy_layer == null:
		return

	# Remove enemies that left range or died
	_entry_order = _entry_order.filter(func(e):
		return is_instance_valid(e) and position.distance_to(e.position) <= attack_range
	)

	# Add newly entered enemies
	for enemy in enemy_layer.get_children():
		if not enemy.has_method("take_damage"):
			continue
		var dist = position.distance_to(enemy.position)
		if dist <= attack_range and not _entry_order.has(enemy):
			_entry_order.append(enemy)

# ─── MAIN ATTACK ROUTER ────────────────────────────────
func _attack() -> void:
	_flash_targets.clear()
	match tower_id:
		"tower_array":     _attack_array()
		"tower_stack":     _attack_stack()
		"tower_queue":     _attack_queue()
		"tower_linked_list": _attack_linked()
		"tower_bubble":    _attack_bubble()
		"tower_selection": _attack_selection()
		"tower_insertion": _attack_insertion()
		_:                 _attack_default()

# ─── ARRAY — fast single target, closest enemy (O(1) access) ──
func _attack_array() -> void:
	var target = _get_closest_enemy()
	if target:
		target.take_damage(damage)
		current_target = target
		_flash_targets.append(target.position - position)
		_shoot_flash = 1.0
		queue_redraw()

# ─── STACK — hits the LAST enemy that entered range (LIFO) ────
func _attack_stack() -> void:
	if _entry_order.is_empty():
		return
	var target = _entry_order[_entry_order.size() - 1]  # last in
	if is_instance_valid(target):
		target.take_damage(damage * 1.4)  # Stack hits harder
		current_target = target
		_flash_targets.append(target.position - position)
		_shoot_flash = 1.0
		queue_redraw()

# ─── QUEUE — hits FIRST enemy in range, pierces to 1 enemy behind it (FIFO) ──
func _attack_queue() -> void:
	if _entry_order.is_empty():
		return
	var target = _entry_order[0]  # first in
	if not is_instance_valid(target):
		return
	target.take_damage(damage)
	current_target = target
	_flash_targets.append(target.position - position)

	# Pierce — also hit the 2nd enemy in the queue for less damage
	if _entry_order.size() > 1 and is_instance_valid(_entry_order[1]):
		_entry_order[1].take_damage(damage * 0.5)
		_flash_targets.append(_entry_order[1].position - position)

	_shoot_flash = 1.0
	queue_redraw()

# ─── LINKED LIST — chain hit: jumps to 2 nearby enemies (pointer chasing) ──
func _attack_linked() -> void:
	var target = _get_closest_enemy()
	if not target:
		return
	target.take_damage(damage)
	current_target = target
	_flash_targets.append(target.position - position)

	# Chain to next closest enemies from the first target's position
	var chained: Array[Node] = [target]
	for i in range(2):  # chain up to 2 more
		var next_link = _get_closest_to_point(target.position, chained)
		if next_link:
			next_link.take_damage(damage * 0.7)
			_flash_targets.append(next_link.position - position)
			chained.append(next_link)
			target = next_link
		else:
			break

	_shoot_flash = 1.0
	queue_redraw()

# ─── BUBBLE SORT — AoE pulse, hits ALL enemies in range (O(n²) = touches everyone) ──
func _attack_bubble() -> void:
	if enemy_layer == null:
		return
	var hit_any = false
	for enemy in enemy_layer.get_children():
		if not enemy.has_method("take_damage"):
			continue
		var dist = position.distance_to(enemy.position)
		if dist <= attack_range:
			enemy.take_damage(damage * 0.6)  # weaker per-hit since it hits everyone
			_flash_targets.append(enemy.position - position)
			hit_any = true
	if hit_any:
		_shoot_flash = 1.0
		queue_redraw()

# ─── SELECTION SORT — always targets lowest HP enemy (finds the "minimum") ──
func _attack_selection() -> void:
	var target = _get_lowest_hp_enemy()
	if target:
		target.take_damage(damage * 1.8)  # guaranteed strong hit, like a "finishing" tower
		current_target = target
		_flash_targets.append(target.position - position)
		_shoot_flash = 1.0
		queue_redraw()

# ─── INSERTION SORT — damage-over-time stacking effect ────
func _attack_insertion() -> void:
	var target = _get_closest_enemy()
	if target and target.has_method("apply_dot"):
		target.apply_dot(damage * 0.3, 3.0)  # 30% damage per tick over 3s
		current_target = target
		_flash_targets.append(target.position - position)
		_shoot_flash = 1.0
		queue_redraw()
	elif target:
		# Fallback if Enemy.gd doesn't have apply_dot yet
		target.take_damage(damage)
		current_target = target
		_flash_targets.append(target.position - position)
		_shoot_flash = 1.0
		queue_redraw()

func _attack_default() -> void:
	_attack_array()

# ─── TARGETING HELPERS ─────────────────────────────────
func _get_closest_enemy() -> Node:
	if enemy_layer == null:
		return null
	var closest: Node = null
	var closest_dist: float = attack_range
	for enemy in enemy_layer.get_children():
		if not enemy.has_method("take_damage"):
			continue
		var dist = position.distance_to(enemy.position)
		if dist <= closest_dist:
			closest_dist = dist
			closest = enemy
	return closest

func _get_closest_to_point(point: Vector2, exclude: Array[Node]) -> Node:
	if enemy_layer == null:
		return null
	var closest: Node = null
	var closest_dist: float = attack_range
	for enemy in enemy_layer.get_children():
		if not enemy.has_method("take_damage"):
			continue
		if exclude.has(enemy):
			continue
		var dist = point.distance_to(enemy.position)
		if dist <= closest_dist:
			closest_dist = dist
			closest = enemy
	return closest

func _get_lowest_hp_enemy() -> Node:
	if enemy_layer == null:
		return null
	var lowest: Node = null
	var lowest_hp: float = INF
	for enemy in enemy_layer.get_children():
		if not enemy.has_method("take_damage"):
			continue
		var dist = position.distance_to(enemy.position)
		if dist > attack_range:
			continue
		if "current_health" in enemy and enemy.current_health < lowest_hp:
			lowest_hp = enemy.current_health
			lowest = enemy
	return lowest

# ─── DRAW ───────────────────────────────────────────────
func _draw() -> void:
	# If no sprite loaded, fall back to a simple circle so it's never invisible
	if not sprite.visible:
		draw_circle(Vector2.ZERO, 20.0, Color(tower_color, 0.3))
		draw_arc(Vector2.ZERO, 20.0, 0, TAU, 32, tower_color, 2.0)

	# Draw flash lines to all hit targets this attack
	if _shoot_flash > 0:
		var flash_color = Color(tower_color, _shoot_flash)
		for target_offset in _flash_targets:
			draw_line(Vector2(0, -20), target_offset, flash_color, 2.0)
		draw_circle(Vector2(0, -20), 6.0 * _shoot_flash, flash_color)
