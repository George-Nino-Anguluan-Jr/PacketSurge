# EnemyCountMeter.gd
# Count Meter — 80% resistance until 5 hits accumulate, then counter resets
# and takes full damage on the 5th hit.

extends Enemy

func get_type_id() -> String:
	return "count_meter"

func _init_type_state() -> void:
	type_data["count"] = 0
	type_data["count_max"] = 5

func _modify_damage(amount: float) -> float:
	type_data["count"] += 1
	if type_data["count"] >= type_data["count_max"]:
		type_data["count"] = 0
		return amount  # Full damage on counter reset
	else:
		return amount * 0.2  # Heavy resistance while counting

func _draw_type_body(col: Color, bob: float) -> void:
	# 3D cube with tally hash symbol on top
	_draw_3d_box(Vector2(0, bob - 2), Vector2(11, 11), 6.0, Color("#15202E"), col, 1.5)
	# Top hash symbol
	var hash_y = bob - 2 - 11 * SQUASH
	draw_line(Vector2(-5, hash_y), Vector2(-5, hash_y - 3), col, 2.0)
	draw_line(Vector2(0, hash_y), Vector2(0, hash_y - 3), col, 2.0)
	draw_line(Vector2(5, hash_y), Vector2(5, hash_y - 3), col, 2.0)
	draw_line(Vector2(-6, hash_y - 1.5), Vector2(6, hash_y - 1.5), col, 2.0)
	# Drop shadow
	var s = ensure_style()
	draw_set_transform(Vector2(0, bob + 5), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 12, Color(0, 0, 0, s.shadow_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_type_overlay(bob: float) -> void:
	var cnt = type_data.get("count", 0)
	var maxc = type_data.get("count_max", 5)
	for i in range(maxc):
		var x = -8 + i * 4
		var h = 4.0 if i < cnt else 2.0
		draw_rect(Rect2(x, 6 + bob, 2, h),
			Color("#FFB800") if i < cnt else Color("#FFFFFF", 0.3))
