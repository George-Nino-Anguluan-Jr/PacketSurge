# EnemyRadixDigit.gd
# Radix Digit — 3-segment HP bar (units/tens/hundreds). Must deplete
# segments in order. Each segment must be fully depleted before the next.
# Bespoke Procedural Design: "The Articulated Centipede"
# An articulated 3-pod crawler train linked by flex-joints (Units: 1s, Tens: 10s, Hundreds: 100s).
# Depleted pods physically detach with sparking debris as each digit place is eliminated!

extends Enemy

func get_type_id() -> String:
	return "radix_digit"

func _init_type_state() -> void:
	type_data["segment"] = 0  # 0=units, 1=tens, 2=hundreds
	var seg_hp = max_health / 3.0
	type_data["segment_hp"] = [seg_hp, seg_hp, seg_hp]
	type_data["segment_max"] = [seg_hp, seg_hp, seg_hp]

func take_damage(amount: float, source: String = "", armor_pierce: bool = false) -> void:
	if is_dead:
		return

	if type_data.get("shield_max_hits", 0) > 0 and type_data.get("shield_hp", 0) > 0:
		type_data["shield_hp"] = float(type_data["shield_hp"]) - 1.0
		_flash_timer = 0.15
		queue_redraw()
		return

	var mult = _get_source_damage_multiplier(source)
	var final_damage = _modify_damage(amount) * mult

	if not armor_pierce:
		final_damage = maxf(0.0, final_damage - float(type_data.get("armor_flat", 0.0)))
		final_damage *= (1.0 - clampf(float(type_data.get("armor_percent", 0.0)), 0.0, 0.95))

	if source != "" and mult != 1.0:
		_show_floating_multiplier(mult)

	var seg = int(type_data["segment"])
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

func _draw_custom_enemy(col: Color, bob: float) -> void:
	var seg = int(type_data.get("segment", 0))
	var seg_hp = type_data.get("segment_hp", [100, 100, 100])
	var seg_max = type_data.get("segment_max", [100, 100, 100])
	var center = Vector2(0, bob - 2)

	# 1. Ground Drop Shadows for active pods
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, bob + 10), 18.0, 7.0, 0.35)

	# 3 Pod Colors & Labels: Pod 0 = Units (Rear), Pod 1 = Tens (Mid), Pod 2 = Hundreds (Head)
	var pod_colors = [Color("#00D4FF"), Color("#FFB800"), Color("#FF3366")]
	var pod_labels = ["1", "10", "100"]
	var pod_x_offsets = [-11.0, 0.0, 11.0]

	# Draw connecting flex-joint spines between remaining pods
	for i in range(2):
		if i >= seg and (i + 1) >= seg:
			var p1 = center + Vector2(pod_x_offsets[i], -3.0)
			var p2 = center + Vector2(pod_x_offsets[i + 1], -3.0)
			draw_line(p1, p2, Color("#3A4B60"), 3.0)
			draw_line(p1, p2, Color.WHITE, 1.0)

	# Draw each pod
	for i in range(3):
		var p_center = center + Vector2(pod_x_offsets[i], 0.0)
		var is_depleted = (i < seg)
		var is_current = (i == seg)
		var pod_col = pod_colors[i]

		if is_depleted:
			# Pod is severed! Show trailing spark connector
			draw_circle(p_center + Vector2(3, -3), 1.5, Color("#FF3366"))
			draw_line(p_center + Vector2(0, -3), p_center + Vector2(4, -3), Color.WHITE, 1.0)
			continue

		# Active or incoming pod
		var frac = seg_hp[i] / seg_max[i] if seg_max[i] > 0 else 0.0
		var display_col = pod_col if is_current else pod_col.darkened(0.3)

		# 3D Prism Pod Body
		CyberVectorCanvas.draw_iso_prism(
			self,
			p_center,
			Vector2(5.5, 7.5),
			6.0,
			Color("#152233"),
			Color("#0C141F"),
			display_col,
			1.5 if is_current else 1.0
		)

		# Digit label on top face
		var top_y = p_center.y - 6.0
		draw_circle(Vector2(p_center.x, top_y), 2.2, Color("#091017"))
		draw_circle(Vector2(p_center.x, top_y), 1.2, display_col)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(p_center.x - 4.5, top_y - 3.5),
			pod_labels[i],
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			7,
			Color.WHITE if is_current else Color("#FFFFFF", 0.5)
		)

func _draw_type_overlay(bob: float) -> void:
	var seg = int(type_data.get("segment", 0))
	var seg_hp = type_data.get("segment_hp", [])
	var seg_max = type_data.get("segment_max", [100, 100, 100])
	var pod_colors = [Color("#00D4FF"), Color("#FFB800"), Color("#FF3366")]

	# 3 segmented micro bars below
	for i in range(3):
		var x = -13 + i * 9
		var is_depleted = i < seg
		var frac = 0.0 if is_depleted else (seg_hp[i] / seg_max[i] if i < seg_hp.size() else 0.0)
		draw_rect(Rect2(x, 10 + bob, 7, 3), Color("#0B121C"))
		if not is_depleted:
			draw_rect(Rect2(x, 10 + bob, 7 * frac, 3), pod_colors[i])
