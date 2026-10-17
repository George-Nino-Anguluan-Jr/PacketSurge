# EnemyScanWave.gd
# Scan Wave — Oscillates perpendicular to the path. Nearly immune (90% resistance)
# between scan extremes; vulnerable only at oscillation peaks/troughs.
# Bespoke Procedural Design: "The Phase Frequency Entity"
# An ethereal sinusoidal waveform entity that shifts out of phase while sweeping across
# the track, condensing into a solid, vulnerable emerald core only at the wave peaks.

extends Enemy

func get_type_id() -> String:
	return "scan_wave"

func _init_type_state() -> void:
	type_data["scan_phase"] = 0.0
	type_data["scan_amplitude"] = 30.0
	type_data["vulnerable"] = true

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

func _draw_custom_enemy(col: Color, bob: float) -> void:
	var vulnerable = type_data.get("vulnerable", true)
	var center = Vector2(0, bob - 2)

	# 1. Ground Drop Shadow (Fades when out of phase)
	var shadow_alpha = 0.35 if vulnerable else 0.12
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, bob + 10), 16.0, 7.0, shadow_alpha)

	# 2. Sinusoidal Frequency Waveform Ribbons
	var wave_color = Color("#00FF88") if vulnerable else Color("#00D4FF")
	var wave_alpha = 0.9 if vulnerable else 0.4
	var pts_upper = PackedVector2Array()
	var pts_lower = PackedVector2Array()
	var num_pts = 16

	for i in range(num_pts):
		var t = float(i) / float(num_pts - 1)
		var wx = lerp(-14.0, 14.0, t)
		var wy = sin(t * TAU * 1.5 + _bob_time * 5.0) * (4.5 if vulnerable else 6.0)
		pts_upper.append(center + Vector2(wx, wy - 3.0))
		pts_lower.append(center + Vector2(wx, -wy + 3.0))

	# Draw sine waveforms
	draw_polyline(pts_upper, Color(wave_color, wave_alpha * 0.5), 3.0)
	draw_polyline(pts_upper, Color(wave_color, wave_alpha), 1.5)
	draw_polyline(pts_upper, Color.WHITE, 0.8)

	draw_polyline(pts_lower, Color(wave_color, wave_alpha * 0.35), 2.0)
	draw_polyline(pts_lower, Color(wave_color, wave_alpha * 0.7), 1.0)

	# 3. Central Frequency Core
	if vulnerable:
		# SOLID VULNERABLE CORE: Glowing emerald core with exposed circuit ribs
		CyberVectorCanvas.draw_iso_cylinder(
			self,
			center,
			8.0,
			6.0,
			Color("#00FF88"),
			Color("#092215"),
			Color.WHITE,
			1.5
		)
		# Pulse halo
		var pulse = 0.8 + 0.2 * sin(_bob_time * 8.0)
		draw_circle(center - Vector2(0, 6.0), 4.0, Color("#00FF88", 0.4 * pulse))
		draw_circle(center - Vector2(0, 6.0), 2.0, Color.WHITE)
	else:
		# OUT OF PHASE: Translucent oscilloscope ring with scanline interference
		var shimmer = 0.3 + 0.2 * sin(_bob_time * 12.0)
		draw_arc(center, 9.0, 0, TAU, 16, Color("#00D4FF", shimmer), 1.5)
		draw_circle(center, 2.5, Color("#00D4FF", shimmer * 0.5))

func _draw_status_effects(col: Color, bob: float) -> void:
	var vulnerable = type_data.get("vulnerable", true)
	if vulnerable:
		draw_arc(Vector2(0, bob), 18.0, 0, TAU, 16, Color("#00FF88", 0.6), 2.0)
	else:
		draw_arc(Vector2(0, bob), 16.0, 0, TAU, 12, Color("#FF3366", 0.25), 1.0)
