# EnemyScanWave.gd
# Scan Wave — Oscillates perpendicular to the path. Nearly immune (90% resistance)
# between scan extremes; vulnerable only at oscillation peaks/troughs.

extends Enemy

func get_type_id() -> String:
	return "scan_wave"

func _init_type_state() -> void:
	type_data["scan_phase"] = 0.0
	type_data["scan_amplitude"] = 30.0
	type_data["vulnerable"] = true
	# Vulnerable to Linear tower (linear scan covers the whole sweep)
	type_data["tower_multipliers"] = {"tower_linear": 2.0}
	type_data["default_tower_mult"] = 0.6

func _modify_damage(amount: float) -> float:
	if not type_data["vulnerable"]:
		return amount * 0.1
	return amount

func _process_type_logic(delta: float) -> void:
	type_data["scan_phase"] += delta * 3.0
	var phase_val = sin(type_data["scan_phase"])
	type_data["vulnerable"] = abs(phase_val) > 0.85

func _apply_movement_offset(direction: Vector2, delta: float) -> Vector2:
	var perp = Vector2(-direction.y, direction.x)
	var osc = sin(type_data["scan_phase"]) * type_data.get("scan_amplitude", 30.0)
	return perp * osc * delta

func _draw_type_body(col: Color, bob: float) -> void:
	var vulnerable = type_data.get("vulnerable", true)
	# Build elongated hex top points
	var top_pts = PackedVector2Array()
	for i in range(6):
		var a = i * PI / 3.0
		var rx = 16.0 if i % 2 == 0 else 8.0
		var ry = 7.0
		top_pts.append(Vector2(cos(a) * rx, sin(a) * ry * SQUASH))
	draw_set_transform(Vector2(0, bob - 2), 0.0, Vector2.ONE)
	for i in range(6):
		var next_i = (i + 1) % 6
		var t1 = top_pts[i]
		var t2 = top_pts[next_i]
		var b1 = t1 + Vector2(0, 5)
		var b2 = t2 + Vector2(0, 5)
		draw_colored_polygon([t1, t2, b2, b1], Color("#0D141C"))
		draw_polyline(PackedVector2Array([t1, t2]), Color("#00D4FF"), 1.5)
		draw_polyline(PackedVector2Array([b1, b2]), Color("#00D4FF", 0.4), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Top face
	draw_colored_polygon(top_pts, Color("#1E2C3D"))
	draw_polyline(PackedVector2Array([top_pts[0], top_pts[1], top_pts[2], top_pts[3],
		top_pts[4], top_pts[5], top_pts[0]]), Color("#00D4FF"), 1.5)
	# Scan beam
	if vulnerable:
		draw_line(Vector2(-8, bob), Vector2(8, bob), Color("#00FF88", 0.7), 2.0)
	else:
		draw_line(Vector2(-8, bob), Vector2(8, bob), Color("#FF3366", 0.5), 2.0)
	# Drop shadow
	var s = ensure_style()
	draw_set_transform(Vector2(0, bob + 6), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 18, Color(0, 0, 0, s.shadow_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_status_effects(col: Color, bob: float) -> void:
	var vulnerable = type_data.get("vulnerable", true)
	if vulnerable:
		draw_arc(Vector2(0, 0 + bob), 20, 0, TAU, 16, Color("#00FF88", 0.6), 2.0)
	else:
		draw_arc(Vector2(0, 0 + bob), 18, 0, TAU, 16, Color("#FF3366", 0.3), 1.0)
