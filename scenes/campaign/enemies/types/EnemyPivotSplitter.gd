# EnemyPivotSplitter.gd
# Pivot Splitter — Boss enemy with 500 HP. On death, splits into 2 weaker
# basic packet enemies. Uses Quick Sort pivot partitioning concept.

extends Enemy

func get_type_id() -> String:
	return "pivot_splitter"

func _init_type_state() -> void:
	type_data["has_split"] = false

func _on_death() -> void:
	if not type_data["has_split"]:
		type_data["has_split"] = true
		_spawn_split_enemies(2)

func _draw_type_body(col: Color, bob: float) -> void:
	# Large 3D box boss with prominent pivot line and spike rods
	_draw_3d_box(Vector2(0, bob - 4), Vector2(20, 12), 12.0, Color("#15202E"), col, 2.0)
	# Top-face pivot rod
	_draw_3d_box(Vector2(0, bob - 4 - 12 * SQUASH), Vector2(22, 1.5), 3.0,
		Color("#0D141C"), Color("#FFFFFF", 0.8), 1.0)
	# Top face warning markers
	draw_circle(Vector2(-14, bob - 4 - 12 * SQUASH), 2.0, Color("#FFFFFF", 0.7))
	draw_circle(Vector2(14, bob - 4 - 12 * SQUASH), 2.0, Color("#FFFFFF", 0.7))
	# Side spikes (3D cylinders pointing up)
	var spike_positions = [-12.0, 0.0, 12.0]
	for sx in spike_positions:
		_draw_3d_cylinder(Vector2(sx, bob - 4 - 12 * SQUASH - 6), 2.0, 6.0, Color("#0F1720"), col, 1.2)
		_draw_3d_sphere(Vector2(sx, bob - 4 - 12 * SQUASH - 12), 2.5, col)
	# Drop shadow
	var s = ensure_style()
	draw_set_transform(Vector2(0, bob + 8), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 22, Color(0, 0, 0, s.shadow_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
