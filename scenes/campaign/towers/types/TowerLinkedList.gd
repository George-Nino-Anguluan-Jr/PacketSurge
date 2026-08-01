# TowerLinkedList.gd
# Linked List Tower — fires chain lightning that walks the enemy list in path
# order (one node to the next), like following linked list pointers.

extends TowerBase

func get_type_id() -> String:
	return "tower_linked_list"

func _select_target() -> Node:
	_clean_targets()
	if targets.is_empty():
		return null
	return _get_closest(targets)

func _perform_attack() -> void:
	if not current_target:
		return
	SoundManager.play_tower_attack(tower_id)
	_recoil = 1.0
	_flash_targets.clear()

	var spawn_origin = get_muzzle_position()
	var p = {
		"pos": spawn_origin,
		"start_pos": spawn_origin,
		"draw_pos": spawn_origin,
		"target": current_target,
		"target_last_pos": current_target.position,
		"speed": 350.0,
		"damage": damage,
		"style": "chain_lightning",
		"elapsed_time": 0.0,
		"total_dist": (current_target.position - spawn_origin).length(),
		"chains_left": 3,
		"chained_targets": [],
		"chain_radius": 60.0,
		"traverse_path": true,
	}
	_spawn_custom_projectile(p)

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.3, "speed": 1.0, "range": 1.2}

func _get_ability_targets() -> Array:
	var all = super._get_ability_targets()
	var result: Array = []
	for i in range(min(3, all.size())):
		result.append(all[i])
	return result

func _draw_base_geometry(color: Color, height: float) -> void:
	var b_offset = Vector2(0, 0)
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

func _draw_turret_assembly(color: Color) -> void:
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
