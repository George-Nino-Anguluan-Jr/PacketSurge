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

# ─── ANIMATION STATE ───────────────────────────────────
var _turret_angle: float       = -PI / 2
var _recoil: float             = 0.0
var _anim_time: float          = 0.0

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
	# Hide default flat texture so our high-quality procedural 2D models draw cleanly
	sprite.visible = false

func _animate_placement() -> void:
	# Keep placement animation by tweening a simple scaling effect drawn in _draw
	scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.35, 1.35), 0.35) # Scale up the tower visually by 35% globally!

func _process(delta: float) -> void:
	_anim_time += delta
	attack_timer += delta
	_update_entry_order()

	# Handle physical recoil decay
	if _recoil > 0:
		_recoil = max(0.0, _recoil - delta * 6.0)

	# Active target tracking rotation
	var target_to_track = current_target
	if not is_instance_valid(target_to_track) or position.distance_to(target_to_track.position) > attack_range:
		target_to_track = _get_closest_enemy()

	if is_instance_valid(target_to_track):
		var desired_angle = (target_to_track.position - position).angle()
		_turret_angle = lerp_angle(_turret_angle, desired_angle, delta * 8.0)
	else:
		# Slow passive scanning idle animation
		_turret_angle = lerp_angle(_turret_angle, -PI/2 + sin(_anim_time * 1.5) * 0.25, delta * 2.0)

	if _shoot_flash > 0:
		_shoot_flash -= delta * 4.0

	# Continuously request frame redraw to keep procedural 2D animations fluid and tracking alive
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
	_recoil = 1.0 # Trigger physical recoil barrel blowback on every tower type!
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
const SQUASH: float = 0.65  # Perspective squashing ratio to simulate an angled 3D camera lookup

func _draw() -> void:
	# 3D Depth Bases are drawn at ground level
	_draw_3d_base_plates(tower_color)
	
	# Rotating Turrets are offset upwards to look like they float/mount in 3D volume space
	_draw_turret_assembly(tower_color)
	
	_draw_overlays(tower_color)

# ─── VOLUMETRIC 3D PRIMITIVE DRAWING HELPERS ───────────────────────
func _draw_3d_cylinder(center: Vector2, radius: float, height: float, color: Color, outline_color: Color = Color.WHITE, line_width: float = 1.5) -> void:
	# 1. Shaded Side Extrusion (Front facing walls)
	var left_x = center.x - radius
	var right_x = center.x + radius
	var wall_rect = Rect2(left_x, center.y, radius * 2.0, height)
	draw_rect(wall_rect, Color("#0F1720"), true) # Dark metal cylinder background
	
	# Shaded left-to-right metallic panels (light source from top-left)
	draw_rect(Rect2(left_x, center.y, radius, height), Color(outline_color, 0.15), true) # Left half highlight
	draw_rect(Rect2(center.x, center.y, radius, height), Color(0, 0, 0, 0.25), true) # Right half shadow
	
	# Cylinder vertical corner edge lines
	draw_line(center + Vector2(-radius, 0), center + Vector2(-radius, height), outline_color, line_width)
	draw_line(center + Vector2(radius, 0), center + Vector2(radius, height), outline_color, line_width)
	
	# 2. Top Rim Face (Squashed circle creating perspective 3D cylinder cap)
	draw_set_transform(center, 0.0, Vector2(1.0, SQUASH))
	draw_circle(Vector2.ZERO, radius, Color("#15202E"))
	draw_circle(Vector2.ZERO, radius, outline_color, false, line_width)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_3d_box(center: Vector2, extents: Vector2, height: float, color: Color, outline_color: Color = Color.WHITE, line_width: float = 1.5) -> void:
	# Top perspective face coordinates
	var t_tl = center + Vector2(-extents.x, -extents.y * SQUASH)
	var t_tr = center + Vector2(extents.x, -extents.y * SQUASH)
	var t_br = center + Vector2(extents.x, extents.y * SQUASH)
	var t_bl = center + Vector2(-extents.x, extents.y * SQUASH)
	
	# Bottom face coordinates shifted downwards along Y axis
	var b_tl = t_tl + Vector2(0, height)
	var b_tr = t_tr + Vector2(0, height)
	var b_br = t_br + Vector2(0, height)
	var b_bl = t_bl + Vector2(0, height)

	# Right Side shadow panel (shadow side)
	var r_panel = PackedVector2Array([t_tr, t_br, b_br, b_tr])
	draw_colored_polygon(r_panel, Color("#0D141C"))
	draw_polyline(PackedVector2Array([t_tr, t_br, b_br, b_tr]), outline_color, line_width)
	
	# Front Side light panel (facing the viewer)
	var f_panel = PackedVector2Array([t_bl, t_br, b_br, b_bl])
	draw_colored_polygon(f_panel, Color("#141D29"))
	draw_colored_polygon(f_panel, Color(outline_color, 0.15)) # Combine colored alloy tint
	draw_polyline(PackedVector2Array([t_bl, t_br, b_br, b_bl]), outline_color, line_width)
	
	# Left Side shaded panel (mid-light side)
	var l_panel = PackedVector2Array([t_tl, t_bl, b_bl, b_tl])
	draw_colored_polygon(l_panel, Color("#101720"))
	draw_polyline(PackedVector2Array([t_tl, t_bl, b_bl, b_tl]), Color(outline_color, 0.4), line_width)

	# Top face (solid metallic deck)
	var top_face = PackedVector2Array([t_tl, t_tr, t_br, t_bl])
	draw_colored_polygon(top_face, Color("#1E2C3D"))
	draw_polyline(PackedVector2Array([t_tl, t_tr, t_br, t_bl, t_tl]), outline_color, line_width)

func _draw_3d_hexagon(center: Vector2, radius: float, height: float, color: Color, outline_color: Color = Color.WHITE, line_width: float = 1.5) -> void:
	# Calculate top squashed hex points
	var top_pts = PackedVector2Array()
	for i in range(6):
		var angle = i * (PI / 3.0)
		top_pts.append(center + Vector2(cos(angle) * radius, sin(angle) * radius * SQUASH))
		
	# Draw extruded side panels
	for i in range(6):
		var next_i = (i + 1) % 6
		var t1 = top_pts[i]
		var t2 = top_pts[next_i]
		var b1 = t1 + Vector2(0, height)
		var b2 = t2 + Vector2(0, height)
		
		# Directional lighting shading based on wall heading normal (source from top-left)
		var mid_angle = i * (PI / 3.0) + (PI / 6.0)
		var l_dot = cos(mid_angle - 2.2) # Left/top light source
		var shade_mix = lerp(0.05, 0.5, (l_dot + 1.0) / 2.0)
		
		var panel = PackedVector2Array([t1, t2, b2, b1])
		draw_colored_polygon(panel, Color("#0D131A"))
		draw_colored_polygon(panel, Color(outline_color, shade_mix * 0.4))
		draw_polyline(PackedVector2Array([t1, t2, b2, b1]), Color(outline_color, 0.4), 1.0)
		
	# Top metal plate face
	draw_colored_polygon(top_pts, Color("#1B2A3A"))
	var outline_loop = top_pts
	outline_loop.append(top_pts[0])
	draw_polyline(outline_loop, outline_color, line_width)

func _draw_3d_sphere(center: Vector2, radius: float, color: Color) -> void:
	# Spherical volume lighting shader mock using overlapping light offset circles
	draw_circle(center, radius, Color("#0F1721"))
	draw_circle(center, radius, Color(color, 0.25))
	
	# Highlight core shifted towards top-left light source
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
	# Draw volumetric 3D base plates with a solid height of 10 pixels extrusion
	var base_height: float = 10.0
	
	# Base Drop Shadow (cast on floor grid)
	var shadow_color = Color(0, 0, 0, 0.3)
	draw_set_transform(Vector2(4, 6), 0.0, Vector2.ONE)
	_draw_base_extrusion_geometry(shadow_color, base_height)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	
	# Draw physical extruded side walls and top rims of the bases
	_draw_base_extrusion_geometry(color, base_height)

func _draw_base_extrusion_geometry(color: Color, height: float) -> void:
	var b_offset = Vector2(0, 0) # Base ground level anchor
	match tower_id:
		"tower_array":
			_draw_3d_box(b_offset, Vector2(17, 17), height, Color("#101721"), color, 1.8)
		"tower_stack":
			_draw_3d_hexagon(b_offset, 19.0, height, Color("#101721"), color, 1.8)
		"tower_queue":
			_draw_3d_box(b_offset, Vector2(23, 13), height, Color("#101721"), color, 1.8)
		"tower_linked_list":
			# Triangular base prism
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
		"tower_bubble":
			_draw_3d_cylinder(b_offset, 18.0, height, Color("#101721"), color, 1.8)
		"tower_selection":
			_draw_3d_hexagon(b_offset, 18.0, height, Color("#101721"), color, 1.8)
		"tower_insertion":
			_draw_3d_box(b_offset, Vector2(15, 21), height, Color("#101721"), color, 1.8)
		"tower_quick":
			_draw_3d_cylinder(b_offset, 16.0, height, Color("#101721"), color, 1.8)
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
	# Set a -14px height float offset for the turret pivot, so it hovers above the base in 3D perspective
	var t_pivot = Vector2(0, -14)
	
	# Apply global turret tracking rotation transform relative to our floating pivot
	draw_set_transform(t_pivot, _turret_angle, Vector2.ONE)
	
	# Unique highly-polished pseudo-3D volumetric gun configurations
	match tower_id:
		"tower_array":
			# Array Tower — Volumetric dual blaster pod
			var recoil_offset = -_recoil * 6.0
			_draw_3d_box(Vector2.ZERO, Vector2(7, 7), 8.0, Color("#15202E"), color, 1.5)
			# Cylindrical side-cannons with hollow black muzzle caps
			_draw_3d_cylinder(Vector2(recoil_offset, -10), 3.0, 14.0, Color("#1C2C3D"), color, 1.0)
			draw_circle(Vector2(recoil_offset + 14.0, -10 * SQUASH), 1.5, Color.BLACK)
			_draw_3d_cylinder(Vector2(recoil_offset, 10), 3.0, 14.0, Color("#1C2C3D"), color, 1.0)
			draw_circle(Vector2(recoil_offset + 14.0, 10 * SQUASH), 1.5, Color.BLACK)
			
		"tower_stack":
			# Stack Tower — Sequentially compressing 3D canister stack (LIFO)
			var recoil_offset = -_recoil * 8.0
			var spacing = 5.0 - _recoil * 3.5
			# Draw 3 physical shaded canisters stacking on top of each other!
			for i in range(3):
				_draw_3d_cylinder(Vector2(-i * spacing, 0), 8.5 - i * 1.2, 5.0, Color("#15202E"), color, 1.2)
			# Heavy mortar firing pipe on top
			_draw_3d_cylinder(Vector2(2 + recoil_offset, 0), 5.0, 12.0, Color("#223344"), color, 1.5)
			draw_circle(Vector2(14 + recoil_offset, 0), 3.0, Color.BLACK) # Mortar muzzle shadow
			
		"tower_queue":
			# Queue Tower — Shaded 3D linear accelerator box channel
			var recoil_offset = -_recoil * 9.0
			_draw_3d_box(Vector2(-4, 0), Vector2(10, 5), 7.0, Color("#15202E"), color, 1.5)
			# Extruded linear gun rail
			_draw_3d_box(Vector2(8 + recoil_offset, 0), Vector2(12, 3), 4.0, Color("#203040"), color, 1.0)
			# Glowing core inside the rail
			draw_line(Vector2(recoil_offset, 0), Vector2(20 + recoil_offset, 0), Color.WHITE, 1.5)
			
		"tower_linked_list":
			# Linked List Tower — Shaded 3D central emitter globe with orbiting satellite spheres
			var spin_angle = _anim_time * 3.0
			_draw_3d_sphere(Vector2.ZERO, 6.5, color)
			
			# Draw orbiting 3D micro-satellites (Pointers) connected by geometric pointer lines
			var n1 = Vector2(cos(spin_angle), sin(spin_angle) * SQUASH) * 14.0
			var n2 = Vector2(cos(spin_angle + 2.0 * PI / 3.0), sin(spin_angle + 2.0 * PI / 3.0) * SQUASH) * 14.0
			var n3 = Vector2(cos(spin_angle + 4.0 * PI / 3.0), sin(spin_angle + 4.0 * PI / 3.0) * SQUASH) * 14.0
			
			# Pointer rays
			draw_line(n1, n2, color, 1.5)
			draw_line(n2, n3, color, 1.5)
			draw_line(n3, n1, color, 1.5)
			
			# Mini globes
			_draw_3d_sphere(n1, 4.0, color)
			_draw_3d_sphere(n2, 4.0, color)
			_draw_3d_sphere(n3, 4.0, color)
			
		"tower_bubble":
			# Bubble Tower — A majestic glowing 3D core surrounded by curved orbital sweeps
			var pulse = 1.0 + sin(_anim_time * 7.0) * 0.15
			_draw_3d_sphere(Vector2.ZERO, 7.5 * pulse, color)
			
			# 3D thick orbital shield rims
			var spin_speed = _anim_time * 4.0
			draw_set_transform(Vector2.ZERO, spin_speed, Vector2(1.0, SQUASH))
			draw_arc(Vector2.ZERO, 15.0, 0, PI * 0.5, 16, color, 2.5)
			draw_arc(Vector2.ZERO, 15.0, PI, PI + PI * 0.5, 16, color, 2.5)
			draw_set_transform(Vector2.ZERO, _turret_angle, Vector2.ONE) # Restore turret rotational space
			
		"tower_selection":
			# Selection Seeker — Volumetric triangular wedge + tracking lens
			var recoil_offset = -_recoil * 5.0
			# Draw 3D triangular wedge housing
			var t_top = Vector2(10, 0)
			var t_bl = Vector2(-8, -8 * SQUASH)
			var t_br = Vector2(-8, 8 * SQUASH)
			var b_top = t_top + Vector2(0, 8.0)
			var b_bl = t_bl + Vector2(0, 8.0)
			var b_br = t_br + Vector2(0, 8.0)
			draw_colored_polygon(PackedVector2Array([t_top, t_bl, t_br]), Color("#15202E"))
			draw_colored_polygon(PackedVector2Array([t_br, t_bl, b_bl, b_br]), Color(color, 0.15))
			draw_polyline(PackedVector2Array([t_top, t_bl, t_br, t_top]), color, 1.5)
			draw_line(t_br, b_br, color, 1.5)
			draw_line(t_bl, b_bl, color, 1.5)
			draw_line(b_bl, b_br, color, 1.5)
			
			# Volumetric targeting lens
			_draw_3d_cylinder(Vector2(6 + recoil_offset, 0), 3.0, 8.0, Color("#203040"), color, 1.0)
			draw_circle(Vector2(6 + recoil_offset + 8.0, 0), 1.5, Color.BLACK)
			
		"tower_insertion":
			# Insertion Tower — Heavy piston box chamber + slider block
			var recoil_offset = -_recoil * 10.0
			_draw_3d_box(Vector2(-2, 0), Vector2(10, 7), 8.0, Color("#15202E"), color, 1.5)
			# Slider unit sliding smoothly along the 3D track
			_draw_3d_box(Vector2(-12 + recoil_offset, 0), Vector2(5, 5), 6.0, Color("#203040"), color, 1.0)
			# Solid forward launch tube
			_draw_3d_cylinder(Vector2(8, 0), 3.5, 6.0, color, Color.WHITE, 1.0)
			
		"tower_quick":
			# Quick Tower — Robust 3D mechanical yoke holding dual swiveling blasters
			var recoil_offset = -_recoil * 7.0
			# Solid connector bracket
			_draw_3d_box(Vector2(-6, 0), Vector2(4, 3), 6.0, Color("#15202E"), color, 1.5)
			# Twin heavy gun barrels
			_draw_3d_cylinder(Vector2(2 + recoil_offset, -9), 3.0, 11.0, Color("#1C2C3D"), color, 1.0)
			draw_circle(Vector2(2 + recoil_offset + 11.0, -9 * SQUASH), 1.5, Color.BLACK)
			_draw_3d_cylinder(Vector2(2 + recoil_offset, 9), 3.0, 11.0, Color("#1C2C3D"), color, 1.0)
			draw_circle(Vector2(2 + recoil_offset + 11.0, 9 * SQUASH), 1.5, Color.BLACK)
			
		"tower_merge":
			# Merge Tower — 3D Levitating diamond prism with focus stabilizers
			var hover = sin(_anim_time * 6.0) * 2.0
			# Side collector support structures
			_draw_3d_cylinder(Vector2(-8, -11), 2.5, 8.0, Color("#15202E"), color, 1.0)
			_draw_3d_cylinder(Vector2(-8, 11), 2.5, 8.0, Color("#15202E"), color, 1.0)
			
			# Shaded 3D glass Diamond Prism suspended in the middle
			var p1 = Vector2(4, hover)
			var p2 = Vector2(-2, -6 * SQUASH + hover)
			var p3 = Vector2(-8, hover)
			var p4 = Vector2(-2, 6 * SQUASH + hover)
			var dp1 = p1 + Vector2(0, 7.0)
			var dp2 = p2 + Vector2(0, 7.0)
			var dp3 = p3 + Vector2(0, 7.0)
			var dp4 = p4 + Vector2(0, 7.0)
			
			# Shading prism panels
			draw_colored_polygon(PackedVector2Array([p1, p4, dp4, dp1]), Color(color, 0.25))
			draw_colored_polygon(PackedVector2Array([p4, p3, dp3, dp4]), Color(color, 0.1))
			draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), Color(color, 0.35)) # Top cap face
			draw_polyline(PackedVector2Array([p1, p2, p3, p4, p1]), color, 1.5)
			draw_polyline(PackedVector2Array([dp1, dp4, dp3]), Color(color, 0.4), 1.0)
			draw_line(p1, dp1, color, 1.0)
			draw_line(p3, dp3, color, 1.0)
			draw_line(p4, dp4, color, 1.0)
			
		"tower_counting":
			# Count Tower — High-gain transmitter post with stacked status ring caps
			_draw_3d_cylinder(Vector2.ZERO, 6.0, 14.0, Color("#15202E"), color, 1.5)
			# Gauge meters pulsing on side channels
			var pulse1 = 3.0 + sin(_anim_time * 8.0) * 3.0
			var pulse2 = 3.0 + cos(_anim_time * 6.0) * 3.0
			_draw_3d_box(Vector2(-6, -9), Vector2(2, 2), pulse1, color, Color.WHITE, 1.0)
			_draw_3d_box(Vector2(-6, 9), Vector2(2, 2), pulse2, color, Color.WHITE, 1.0)
			
		"tower_radix":
			# Radix Tower — Core gyro sphere inside dual-axis 3D offset rings
			var scale_1 = 1.0 + sin(_anim_time * 9.0) * 0.1
			var scale_2 = 1.0 + cos(_anim_time * 9.0) * 0.1
			_draw_3d_sphere(Vector2.ZERO, 5.5, color)
			
			# Dual rotating eccentric perspective loops
			var rot = _anim_time * 5.0
			draw_set_transform(Vector2.ZERO, rot, Vector2(1.0, SQUASH))
			draw_arc(Vector2.ZERO, 11.0 * scale_1, 0, PI * 1.3, 24, color, 2.0)
			draw_set_transform(Vector2.ZERO, -rot, Vector2(1.0, SQUASH))
			draw_arc(Vector2.ZERO, 15.0 * scale_2, 0, PI * 1.3, 24, Color(color, 0.6), 1.2)
			draw_set_transform(Vector2.ZERO, _turret_angle, Vector2.ONE)
			
		"tower_linear":
			# Linear Scanner — Rotating column holding wide-angle 3D parabolic scanner dish
			_draw_3d_cylinder(Vector2.ZERO, 6.0, 10.0, Color("#15202E"), color, 1.5)
			# 3D parabolic reflector dish
			var dish_back = Vector2(5, 0)
			_draw_3d_cylinder(dish_back, 4.5, 6.0, Color("#203040"), color, 1.2)
			# Wide receiving arc
			draw_arc(dish_back, 11.0, -PI/3, PI/3, 16, color, 2.5)
			draw_line(dish_back, dish_back + Vector2(11, 0), color, 1.5)
			
		"tower_binary", _:
			# Binary Sniper — Giant heavy-duty sniper launcher with charging 3D solenoid rings
			var recoil_offset = -_recoil * 12.0
			# Heavy 3D capacitor battery receiver
			_draw_3d_box(Vector2(-5, 0), Vector2(9, 8), 10.0, Color("#15202E"), color, 1.8)
			# Massive long sniper barrel
			_draw_3d_cylinder(Vector2(4 + recoil_offset, 0), 4.5, 20.0, Color("#203040"), color, 1.2)
			# Dark muzzle hole
			draw_circle(Vector2(4 + recoil_offset + 20.0, 0), 2.5, Color.BLACK)
			
			# 2 thick magnetic solenoid coils wrapped around the barrel
			_draw_3d_cylinder(Vector2(9 + recoil_offset, 0), 6.5, 3.5, Color("#101721"), color, 1.5)
			_draw_3d_cylinder(Vector2(16 + recoil_offset, 0), 6.5, 3.5, Color("#101721"), color, 1.5)

	# Reset coordinate transformation back to unrotated system
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_overlays(color: Color) -> void:
	# Draw shooting flash effects
	if _shoot_flash > 0:
		var flash_color = Color(color, _shoot_flash)
		# Draw vector flash lines leading from the turret pivot to the active targets
		for target_offset in _flash_targets:
			draw_line(Vector2.ZERO, target_offset, flash_color, 2.5)
		
		# Draw glowing energy ring around muzzle flash
		draw_circle(Vector2.ZERO, 8.0 * _shoot_flash, flash_color)
		draw_circle(Vector2.ZERO, 4.0 * _shoot_flash, Color.WHITE)
		
	# Draw faint subtle range ring if the player is placing a tower or selects it
	if Engine.is_editor_hint():
		draw_arc(Vector2.ZERO, attack_range, 0, TAU, 64, Color(color, 0.15), 1.0)
	elif OS.is_debug_build() or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# We can draw the range outline during placement or selections dynamically if needed
		pass

