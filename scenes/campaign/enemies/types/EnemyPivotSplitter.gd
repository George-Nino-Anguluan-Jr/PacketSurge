# EnemyPivotSplitter.gd
# Pivot Splitter — Boss enemy with 500 HP. On death, splits into 2 weaker
# basic packet enemies. Uses Quick Sort pivot partitioning concept.
# Bespoke Procedural Design: "The Dreadnought Carrier"
# A massive armored mobile fortress featuring heavy track skirts, twin internal drone bays,
# and an illuminated center bulkhead dividing seam ready to cleave the boss on death.

extends Enemy

func get_type_id() -> String:
	return "pivot_splitter"

func _init_type_state() -> void:
	type_data["has_split"] = false

func _on_death() -> void:
	if not type_data["has_split"]:
		type_data["has_split"] = true
		_spawn_split_enemies(2)

func _draw_custom_enemy(col: Color, bob: float) -> void:
	var center = Vector2(0, bob - 2)

	# 1. Massive Boss Ground Shadow
	CyberVectorCanvas.draw_drop_shadow(self, Vector2(0, bob + 14), 26.0, 12.0, 0.45)

	# 2. Heavy Dual Track Assemblies (Left and Right)
	var track_col = Color("#0A0F16")
	var tread_col = Color("#182332")
	# Left Track
	CyberVectorCanvas.draw_iso_prism(self, center + Vector2(-16, 2), Vector2(4, 15), 6.0, tread_col, track_col, Color("#2B3D55"), 1.0)
	# Right Track
	CyberVectorCanvas.draw_iso_prism(self, center + Vector2(16, 2), Vector2(4, 15), 6.0, tread_col, track_col, Color("#2B3D55"), 1.0)

	# 3. Main Fortress Bulkhead Hull
	CyberVectorCanvas.draw_iso_chamfered_slab(
		self,
		center,
		Vector2(16.0, 14.0),
		4.0,
		9.0,
		Color("#172537"),
		Color("#0C131D"),
		Color(col, 0.8),
		1.8
	)

	# 4. Command Superstructure Deck
	var bridge_center = center + Vector2(0, -9.0)
	CyberVectorCanvas.draw_iso_prism(
		self,
		bridge_center,
		Vector2(10.0, 8.0),
		5.0,
		Color("#21344D"),
		Color("#121E2C"),
		Color(col, 0.6),
		1.2
	)

	# 5. Twin Drone Hangar Launch Bays (Left & Right)
	var bay_l = bridge_center + Vector2(-6.0, 0.0)
	var bay_r = bridge_center + Vector2(6.0, 0.0)
	draw_rect(Rect2(bay_l.x - 2.5, bay_l.y - 2.0, 5.0, 4.0), Color("#080D14"))
	draw_rect(Rect2(bay_r.x - 2.5, bay_r.y - 2.0, 5.0, 4.0), Color("#080D14"))
	# Runway landing strip lights
	var runway_pulse = 0.5 + 0.5 * sin(_bob_time * 6.0)
	draw_circle(bay_l, 1.2, Color("#00FF88", runway_pulse))
	draw_circle(bay_r, 1.2, Color("#00FF88", runway_pulse))

	# 6. Central Pivot Bulkhead Divide Seam (QuickSort Partition Seam)
	# Glowing dividing line cleaving the fortress in half
	var pivot_col = Color("#FF0055")
	var pulse = 0.8 + 0.2 * sin(_bob_time * 7.0)
	draw_line(center + Vector2(0, -18), center + Vector2(0, 11), Color(pivot_col, 0.4), 4.5)
	draw_line(center + Vector2(0, -18), center + Vector2(0, 11), Color(pivot_col, pulse), 2.0)
	draw_line(center + Vector2(0, -18), center + Vector2(0, 11), Color.WHITE, 1.0)

	# Pivot Point Target Reticle at prow
	draw_circle(center + Vector2(0, 9), 3.0, Color("#0C131D"))
	draw_circle(center + Vector2(0, 9), 2.0, pivot_col)
	draw_circle(center + Vector2(0, 9), 0.9, Color.WHITE)

	# 7. Side Heavy Radar Calipers
	draw_line(center + Vector2(-12, -7), center + Vector2(-15, -12), Color(col, 0.7), 1.5)
	draw_circle(center + Vector2(-15, -12), 1.5, Color.WHITE)
	draw_line(center + Vector2(12, -7), center + Vector2(15, -12), Color(col, 0.7), 1.5)
	draw_circle(center + Vector2(15, -12), 1.5, Color.WHITE)
