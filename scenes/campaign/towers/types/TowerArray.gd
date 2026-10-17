# TowerArray.gd
# Array Tower — O(1) random access.
# BESPOKE DESIGN: The Index Memory Matrix
# Features a wide hexagonal silicon motherboard with 5 distinct vertical heatsink silos
# arranged in an arc, each representing an array index [0]..[4]. No generic rotating turret.
# When targeting, the active index silos pneumatically rise and pulse with bright cyan neon.
extends TowerBase

var _active_indices: Array[int] = []

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

	var active_slots: int = clamp(2 + current_level, 3, max_targets)
	var nearest = _get_nearest(active_slots)
	if nearest.is_empty():
		return

	_active_indices.clear()
	for i in range(active_slots):
		_active_indices.append(i)
		var assigned_target = nearest[i % nearest.size()]
		var muzzle = _get_silo_muzzle_pos(i)
		var p = {
			"pos": muzzle,
			"start_pos": muzzle,
			"draw_pos": muzzle,
			"target": assigned_target,
			"target_last_pos": assigned_target.global_position,
			"speed": projectile_speed,
			"damage": damage * (0.45 if nearest.size() > 1 else 0.35),
			"style": "index_bolt",
			"elapsed_time": 0.0,
			"total_dist": (assigned_target.global_position - muzzle).length(),
			"armor_pierce": armor_pierce,
			"index": i,
		}
		_spawn_custom_projectile(p)

func _get_silo_muzzle_pos(idx: int) -> Vector2:
	# Calculate world spawn point of silo index [0..4]
	var total = 5
	var angle = -PI * 0.75 + float(idx) / float(total - 1) * PI * 0.5
	var r = 16.0
	var offset = Vector2(cos(angle) * r, sin(angle) * r * SQUASH - 10.0)
	return global_position + offset

func _get_upgrade_stats(level: int) -> Dictionary:
	return {"damage": 1.3, "speed": 1.15, "range": 1.1}

func _get_ability_targets() -> Array:
	if targets.is_empty():
		return []
	return [targets[0]]

# ─── BESPOKE PROCEDURAL RENDERING ──────────────────────────────────────────

func _draw_custom_tower(color: Color) -> void:
	var t = _anim_time
	var is_firing = _recoil > 0.2

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, 6), 26.0, 16.0, 0.35)

	# 2. Main Silicon Motherboard Platform (Chamfered Slab)
	var slab_col = Color("#0A1422")
	var side_col = Color("#060C16")
	CyberVectorCanvas.draw_iso_chamfered_slab(
		self,
		Vector2.ZERO,
		Vector2(24, 16),
		6.0,
		7.0,
		slab_col,
		side_col,
		Color(color, 0.4),
		1.2
	)

	# 3. Printed Circuit Board (PCB) Copper Bus Traces
	var bus_color = Color(color, 0.35)
	for i in range(5):
		var ang = -PI * 0.75 + float(i) / 4.0 * PI * 0.5
		var silo_pt = Vector2(cos(ang) * 16.0, sin(ang) * 16.0 * SQUASH)
		var center_pt = Vector2(0, 2.0 * SQUASH)
		var mid_pt = Vector2(silo_pt.x * 0.4, silo_pt.y * 0.8 + 2.0)
		CyberVectorCanvas.draw_circuit_traces(
			self,
			PackedVector2Array([center_pt, mid_pt, silo_pt]),
			bus_color,
			1.0,
			1.5
		)

	# 4. Central CPU Memory Controller Core (Prism with glowing heat sink)
	var cpu_pulse = 0.7 + sin(t * 4.0) * 0.3
	CyberVectorCanvas.draw_iso_prism(
		self,
		Vector2(0, 2 * SQUASH),
		Vector2(6, 6),
		4.0,
		Color("#0E1E34"),
		Color("#081220"),
		Color(color, cpu_pulse),
		1.0
	)
	# CPU Core Die
	draw_circle(Vector2(0, 2 * SQUASH - 4), 2.5, Color(color, cpu_pulse * 0.8))
	draw_circle(Vector2(0, 2 * SQUASH - 4), 1.2, Color.WHITE)

	# 5. The 5 Vertical Register Silos ([0]..[4])
	var max_active = clamp(2 + current_level, 3, max_targets)
	for i in range(5):
		var ang = -PI * 0.75 + float(i) / 4.0 * PI * 0.5
		var silo_base = Vector2(cos(ang) * 16.0, sin(ang) * 16.0 * SQUASH)
		var is_slot_unlocked = i < max_active
		var is_active = _active_indices.has(i) or (is_firing and is_slot_unlocked)

		# Pneumatic rise height: active silos elevate higher
		var base_h = 6.0
		if is_active:
			base_h += 3.5 + sin(t * 14.0 + i) * 1.0
		elif is_slot_unlocked:
			base_h += 1.5

		CyberVectorCanvas.draw_register_silo(
			self,
			silo_base,
			6.5,
			6.5,
			base_h,
			is_active,
			color,
			str(i)
		)

		# Muzzle flash spark on active silos
		if is_active and _recoil > 0.4:
			var muzz_pt = silo_base + Vector2(0, -base_h)
			draw_circle(muzz_pt, 4.0 * _recoil, Color(color, 0.4))
			draw_circle(muzz_pt, 1.8 * _recoil, Color.WHITE)

	# 6. Holographic Data Bus Level Arc
	if current_level >= 2:
		var arc_pts = PackedVector2Array()
		for i in range(16):
			var a = -PI * 0.8 + float(i) / 15.0 * PI * 0.6
			arc_pts.append(Vector2(cos(a) * 20.0, sin(a) * 20.0 * SQUASH - 6.0))
		draw_polyline(arc_pts, Color(color, 0.5), 1.2)
		if current_level == 3:
			draw_polyline(arc_pts, Color.WHITE, 0.6)
