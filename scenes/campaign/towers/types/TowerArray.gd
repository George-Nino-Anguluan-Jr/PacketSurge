# TowerArray.gd
# Array Tower — O(1) random access. Fires a volley of indexed bolts at the
# nearest N enemies simultaneously (direct index access, no search cost).
# REDESIGN: PCB motherboard tower — memory-grid base + 5-barrel indexed railgun.
# Each barrel is a memory slot with an index chip ready to fire.

extends TowerBase

func get_type_id() -> String:
	return "tower_array"

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
	var index_count: int = clamp(1 + current_level, 1, 5)
	var hit_list: Array = []
	var nearest = _get_nearest(index_count)
	for e in nearest:
		if is_instance_valid(e) and not hit_list.has(e):
			hit_list.append(e)
	for i in range(hit_list.size()):
		_spawn_projectile("index_bolt", damage * 0.4, 350.0, hit_list[i], {"index": i})

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.3, "speed": 1.15, "range": 1.1}

func _get_ability_targets() -> Array:
	if targets.is_empty():
		return []
	return [targets[0]]

func _draw_base_geometry(color: Color, height: float) -> void:
	# Array base: clean rectangular slab with 5 indexed memory slots
	var is_shadow = color.a < 0.5
	var slab_col = Color("#0E1A2C") if not is_shadow else Color("#0D131A")
	var slot_inactive = Color("#0B1420") if not is_shadow else Color("#0D131A")
	# Main slab
	_draw_3d_box(Vector2(0, 0), Vector2(20, 16), height, slab_col, color, 1.6)
	if not is_shadow:
		# 5 indexed memory slots in a row — each is a recessed rectangle
		var slot_w = 5.8
		var slot_h = 5.0
		var spacing = 1.0
		var total_w = 5.0 * slot_w + 4.0 * spacing
		var start_x = -total_w / 2.0 + slot_w / 2.0
		for i in range(5):
			var sx = start_x + i * (slot_w + spacing)
			var slot_rect = Rect2(Vector2(sx - slot_w / 2.0, -slot_h / 2.0), Vector2(slot_w, slot_h))
			# Recessed slot
			draw_rect(slot_rect, slot_inactive, true)
			draw_rect(slot_rect, Color(color, 0.25), false, 0.7)
			# Index label above slot
			draw_string(ThemeDB.fallback_font, Vector2(sx - 1.5, -slot_h / 2.0 - 1.5), str(i), HORIZONTAL_ALIGNMENT_CENTER, -1, 7, Color(color, 0.55))
			# Small address dot inside slot
			draw_circle(Vector2(sx, 0.0), 0.7, Color(color, 0.35))
		# Access arrows — thin lines from center outward to each slot
		for i in range(5):
			var sx = start_x + i * (slot_w + spacing)
			draw_line(Vector2(0, 4.0), Vector2(sx, slot_h / 2.0 - 0.5), Color(color, 0.12), 0.5)
	draw_polyline(PackedVector2Array([
		Vector2(-20, -16 * SQUASH), Vector2(20, -16 * SQUASH),
		Vector2(20, 16 * SQUASH), Vector2(-20, 16 * SQUASH),
		Vector2(-20, -16 * SQUASH)
	]), color, 1.0 if not is_shadow else 0.8)

func _draw_turret_assembly(color: Color) -> void:
	var recoil = -_recoil * 6.0
	var is_firing = _recoil > 0.25
	# Turret body — simple rectangular housing
	_draw_3d_box(Vector2(0, -1.0), Vector2(22, 4.0), 6.0, Color("#0F1E32"), color, 1.2)
	# 5 indexed barrels — each a clean cylinder with index digit
	var barrel_count = clamp(1 + current_level, 1, 5)
	var barrel_spacing = 4.5
	var total_barrels_w = (barrel_count - 1) * barrel_spacing
	var start_x = -total_barrels_w / 2.0
	for i in range(barrel_count):
		var bx = start_x + i * barrel_spacing + recoil
		# Barrel cylinder
		_draw_3d_cylinder(Vector2(bx, -1.0), 1.5, 12.0, Color("#12233A"), color, 0.9)
		# Muzzle bore
		var bore = Vector2(bx + 11.7, -1.0 * SQUASH)
		draw_circle(bore, 1.1, Color.BLACK)
		# Muzzle glow
		var glow_alpha = 0.25 if is_firing else 0.10
		draw_circle(bore, 2.0, Color(color, glow_alpha))
		draw_circle(bore, 0.6, Color(color, 0.9))
		# Index digit on barrel body
		var label_x = bx - 1.0
		draw_string(ThemeDB.fallback_font, Vector2(label_x - 0.8, 0.8), str(i), HORIZONTAL_ALIGNMENT_CENTER, -1, 6, Color.WHITE if i < barrel_count else Color(color, 0.3))
	# Status LEDs above each barrel
	for i in range(barrel_count):
		var bx = start_x + i * barrel_spacing + recoil
		var led_alpha = 0.9 if is_firing else 0.35
		draw_circle(Vector2(bx, -4.0), 0.5, Color(color, led_alpha))
	# Glow line along bottom
	draw_line(Vector2(-total_barrels_w / 2.0 - 2, 2.5), Vector2(total_barrels_w / 2.0 + 2, 2.5), Color(color, 0.4), 1.0)
