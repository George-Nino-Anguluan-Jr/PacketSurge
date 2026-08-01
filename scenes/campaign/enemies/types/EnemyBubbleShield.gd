# EnemyBubbleShield.gd
# Bubble Shield — First 3 hits are fully absorbed by a regenerating shield.
# After shield breaks, takes normal damage.

extends Enemy

func get_type_id() -> String:
	return "bubble_shield"

func _init_type_state() -> void:
	type_data["shield_hp"] = 3
	type_data["shield_max"] = 3

func _modify_damage(amount: float) -> float:
	if type_data.get("shield_hp", 0) > 0:
		type_data["shield_hp"] -= 1
		# Flash for blocked hit
		_flash_timer = 0.1
		queue_redraw()
		return 0.0
	return amount

func _process_type_logic(delta: float) -> void:
	if type_data["shield_hp"] < type_data["shield_max"]:
		type_data["shield_hp"] += delta * 0.5

func _has_shield() -> bool:
	return true

func _draw_extra_health_bar() -> void:
	var s = ensure_style()
	var shield_ratio = clamp(float(type_data["shield_hp"]) / float(type_data["shield_max"]), 0.0, 1.0)
	draw_rect(Rect2(-s.health_bar_width / 2.0, s.health_bar_offset.y + s.shield_bar_offset,
		s.health_bar_width * shield_ratio, s.shield_bar_height), s.shield_bar_color)

func _draw_type_body(col: Color, bob: float) -> void:
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
			if i < shield_max - 1:
				var a2 = (i + 1) * seg_angle + _bob_time * 0.3
				draw_line(Vector2(sx, sy), Vector2(cos(a2) * 16, bob - 2 + sin(a2) * 16 * SQUASH), Color("#00D4FF", 0.3), 1.0)
	# Drop shadow
	var s = ensure_style()
	draw_set_transform(Vector2(0, bob + 8), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 16, Color(0, 0, 0, s.shadow_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
