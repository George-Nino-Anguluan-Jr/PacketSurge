# EnemyMergeTwin.gd
# Merge Twin — Spawns as paired enemies. If one dies, the other gains
# 50% of the partner's HP + 30% current HP and 1.3x speed.

extends Enemy

func get_type_id() -> String:
	return "merge_twin"

func _init_type_state() -> void:
	type_data["merged"] = false
	if not type_data.has("partner_id"):
		type_data["partner_id"] = 0
	# Vulnerable to Merge tower (merge sort handles the halves before merging)
	type_data["tower_multipliers"] = {"tower_merge": 2.0}
	type_data["default_tower_mult"] = 0.6

func set_partner(p: Node) -> void:
	type_data["partner_id"] = p.get_instance_id() if p != null else 0

func get_partner() -> Node:
	# Store the partner's instance ID, never a raw reference, so a freed
	# partner resolves to null instead of a dangling pointer.
	var pid: int = int(type_data.get("partner_id", 0))
	if pid == 0:
		return null
	var p = instance_from_id(pid)
	if p == null or not is_instance_valid(p):
		type_data["partner_id"] = 0
		return null
	return p

func _on_death() -> void:
	var partner = get_partner()
	if partner and is_instance_valid(partner) and not partner.is_dead:
		if partner.has_method("_on_merge_partner_died"):
			partner._on_merge_partner_died(current_health)

func _on_merge_partner_died(partner_hp: float) -> void:
	if is_dead:
		return
	type_data["merged"] = true
	max_health += partner_hp * 0.5
	current_health = min(current_health + partner_hp * 0.3, max_health)
	move_speed *= 1.3
	enemy_color = Color("#FFB800")  # Gold = merged state
	queue_redraw()

func _draw_type_body(col: Color, bob: float) -> void:
	var merged = type_data.get("merged", false)
	var draw_col = Color("#FFB800") if merged else col
	# Left sphere
	_draw_3d_sphere(Vector2(-8, bob - 2), 7.0, draw_col)
	# Right sphere
	_draw_3d_sphere(Vector2(8, bob - 2), 7.0, draw_col)
	# Merge bridge
	_draw_3d_box(Vector2(0, bob - 1), Vector2(7, 1.5), 3.0, Color("#0D141C"), draw_col, 1.2)
	# Merge arrows on top of bridge
	draw_line(Vector2(-3, bob - 4), Vector2(3, bob - 4), Color(draw_col, 0.7), 1.2)
	draw_line(Vector2(3, bob - 4), Vector2(1, bob - 6), Color(draw_col, 0.7), 1.2)
	draw_line(Vector2(3, bob - 4), Vector2(1, bob - 2), Color(draw_col, 0.7), 1.2)
	# Drop shadow
	var s = ensure_style()
	draw_set_transform(Vector2(0, bob + 6), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 14, Color(0, 0, 0, s.shadow_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_status_effects(col: Color, bob: float) -> void:
	if type_data.get("merged", false):
		draw_arc(Vector2(0, 0 + bob), 18, 0, TAU, 16, Color("#FFB800", 0.5), 2.0)
