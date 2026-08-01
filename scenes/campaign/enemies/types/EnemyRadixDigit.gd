# EnemyRadixDigit.gd
# Radix Digit — 3-segment HP bar (units/tens/hundreds). Must deplete
# segments in order. Each segment must be fully depleted before the next.

extends Enemy

func get_type_id() -> String:
	return "radix_digit"

func _init_type_state() -> void:
	type_data["segment"] = 0  # 0=units, 1=tens, 2=hundreds
	var seg_hp = max_health / 3.0
	type_data["segment_hp"] = [seg_hp, seg_hp, seg_hp]
	type_data["segment_max"] = [seg_hp, seg_hp, seg_hp]
	# Vulnerable to Radix tower (radix sort buckets by digit place)
	type_data["tower_multipliers"] = {"tower_radix": 2.0}
	type_data["default_tower_mult"] = 0.6

func take_damage(amount: float, source: String = "") -> void:
	if is_dead:
		return

	var final_damage = _modify_damage(amount) * _get_source_damage_multiplier(source)
	if is_dead:
		return

	# Radix uses segment-based HP instead of direct current_health
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

	_flash_timer = 0.15
	queue_redraw()

func _process_type_logic(delta: float) -> void:
	var seg_hp = type_data["segment_hp"]
	var total_hp = seg_hp[0] + seg_hp[1] + seg_hp[2]
	current_health = total_hp
	var seg_max = type_data["segment_max"]
	max_health = seg_max[0] + seg_max[1] + seg_max[2]

func get_health_ratio() -> float:
	var seg_hp = type_data.get("segment_hp", [])
	if seg_hp.size() >= 3:
		var total_hp = seg_hp[0] + seg_hp[1] + seg_hp[2]
		var total_max = type_data["segment_max"][0] + type_data["segment_max"][1] + type_data["segment_max"][2]
		return clamp(total_hp / total_max, 0.0, 1.0)
	return 1.0

func _draw_type_body(col: Color, bob: float) -> void:
	var seg = type_data.get("segment", 0)
	var seg_hp = type_data.get("segment_hp", [])
	var seg_max = type_data.get("segment_max", [100, 100, 100])
	# 3 small 3D boxes side by side with different brightness based on depletion
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
	var s = ensure_style()
	draw_set_transform(Vector2(0, bob + 5), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 15, Color(0, 0, 0, s.shadow_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_type_overlay(bob: float) -> void:
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
