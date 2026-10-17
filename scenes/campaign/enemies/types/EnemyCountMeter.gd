# EnemyCountMeter.gd
# Count Meter — 80% resistance until 5 hits accumulate, then counter resets
# and takes full damage on the 5th hit.
# Bespoke Procedural Design: "The Tally Clockwork Automaton"
# A heavy bronze and teal mechanical automaton with an exposed circular
# odometer dial displaying illuminated tally notches (I, II, III, IIII, V).

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
		queue_redraw()
		return amount  # Full damage on counter reset
	else:
		queue_redraw()
		return amount * 0.2  # Heavy resistance while counting

func _draw_custom_enemy(col: Color, bob: float) -> void:
	var center = Vector2(0, bob - 2)
	var cnt = int(type_data.get("count", 0))
	var maxc = int(type_data.get("count_max", 5))

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, bob + 10), 16.0, 8.0, 0.35)

	# 2. Main Octagonal Bronze Chassis
	CyberVectorCanvas.draw_iso_chamfered_slab(
		self,
		center,
		Vector2(13.0, 13.0),
		4.0,
		7.0,
		Color("#2A261D"), # Bronze top
		Color("#17140E"), # Dark bronze side
		Color("#C89B3C", 0.6), # Golden bronze outline
		1.5
	)

	# 3. Exposed Circular Rotary Odometer Dial
	var dial_center = center + Vector2(0, -7.0)
	draw_circle(dial_center, 9.0, Color("#0D1017"))
	draw_circle(dial_center, 8.0, Color("#161F2E"))
	draw_arc(dial_center, 8.0, 0, TAU, 20, Color("#C89B3C"), 1.2)

	# 4. 5 Rotary Tally Notches around the dial
	var rot_offset = float(cnt) * (TAU / 5.0) # Ratchets with hits
	for i in range(maxc):
		var a = i * (TAU / float(maxc)) - PI * 0.5 + rot_offset
		var is_active = i < cnt
		var notch_pos = dial_center + Vector2(cos(a) * 5.8, sin(a) * 4.5)
		var notch_col = Color("#FFB800") if is_active else Color("#3A4B60", 0.5)

		# Tally notch point
		draw_circle(notch_pos, 1.8 if is_active else 1.2, notch_col)
		if is_active:
			draw_circle(notch_pos, 0.8, Color.WHITE)

	# 5. Center Ratchet Hub
	draw_circle(dial_center, 3.2, Color("#0D1017"))
	draw_circle(dial_center, 2.2, Color("#FFB800") if cnt == 4 else Color("#C89B3C"))
	draw_circle(dial_center, 1.0, Color.WHITE)

	# 6. Flash / Steam Venting on 5th hit (when cnt is 4 or reset)
	if cnt == 4:
		# Imminent trigger warning: pulsing red/amber border
		var warn_pulse = 0.6 + 0.4 * sin(_bob_time * 8.0)
		draw_arc(dial_center, 10.5, 0, TAU, 16, Color("#FF3366", warn_pulse), 1.5)

func _draw_type_overlay(bob: float) -> void:
	# Overlay: Roman numeral or digital count tally bar
	var cnt = int(type_data.get("count", 0))
	var maxc = int(type_data.get("count_max", 5))

	# 5 Micro tally hashmarks below the health bar
	for i in range(maxc):
		var x = -8 + i * 4
		var is_lit = i < cnt
		var hash_col = Color("#FFB800") if is_lit else Color("#FFFFFF", 0.25)
		draw_line(Vector2(x, 10 + bob), Vector2(x, 14 + bob), hash_col, 1.5)
	# 5th slash tally diagonal
	if cnt >= 5:
		draw_line(Vector2(-9, 14 + bob), Vector2(9, 10 + bob), Color("#FF3366"), 1.8)
