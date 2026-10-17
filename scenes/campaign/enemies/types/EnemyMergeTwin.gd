# EnemyMergeTwin.gd
# Merge Twin — Spawns as paired enemies. If one dies, the other gains
# 50% of the partner's HP + 30% current HP and 1.3x speed.
# Bespoke Procedural Design: "The Polarity Scarabs"
# Cybernetic twin scarabs with magnetic runes. When one falls, the survivor absorbs
# its polarity energy, expanding in scale into a supercharged golden juggernaut.

extends Enemy

func get_type_id() -> String:
	return "merge_twin"

func _init_type_state() -> void:
	type_data["merged"] = false
	if not type_data.has("partner_id"):
		type_data["partner_id"] = 0

func set_partner(p: Node) -> void:
	type_data["partner_id"] = p.get_instance_id() if p != null else 0

func get_partner() -> Node:
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
	enemy_color = Color("#FFB800")  # Gold = merged supercharge
	queue_redraw()

func _draw_custom_enemy(col: Color, bob: float) -> void:
	var merged = type_data.get("merged", false)
	var scale_mult = 1.35 if merged else 1.0
	var scarab_col = Color("#FFB800") if merged else col
	var center = Vector2(0, bob - 2)

	# 1. Ground Drop Shadow
	CyberVectorCanvas.draw_drop_shadow(
		self,
		Vector2(0, bob + 10),
		16.0 * scale_mult,
		8.0 * scale_mult,
		0.4 if merged else 0.35
	)

	# 2. Dual Biomagnetic Shell Hemispheres
	var left_c = center + Vector2(-7.0 * scale_mult, 0.0)
	var right_c = center + Vector2(7.0 * scale_mult, 0.0)
	var shell_r = 7.5 * scale_mult

	# Left Carapace
	draw_circle(left_c, shell_r, Color("#0F1722"))
	draw_circle(left_c, shell_r - 1.0, scarab_col.darkened(0.2))
	draw_circle(left_c - Vector2(1.5, 1.5) * scale_mult, shell_r * 0.4, Color.WHITE)

	# Right Carapace
	draw_circle(right_c, shell_r, Color("#0F1722"))
	draw_circle(right_c, shell_r - 1.0, scarab_col.darkened(0.2))
	draw_circle(right_c - Vector2(1.5, 1.5) * scale_mult, shell_r * 0.4, Color.WHITE)

	# 3. Central Magnetic Fusion Core
	var core_rect = Rect2(center.x - 3.5 * scale_mult, center.y - 7.0 * scale_mult, 7.0 * scale_mult, 14.0 * scale_mult)
	draw_rect(core_rect, Color("#091017"))
	draw_rect(core_rect, scarab_col, false, 1.2)

	# Core Diode / Fusion Arc
	var pulse = 0.8 + 0.2 * sin(_bob_time * 6.0)
	draw_circle(center, 3.5 * scale_mult, Color(scarab_col, 0.5 * pulse))
	draw_circle(center, 1.8 * scale_mult, Color.WHITE)

	# 4. Merged Supercharge Aura & Overload Lightning
	if merged:
		var aura_pulse = 0.5 + 0.5 * sin(_bob_time * 8.0)
		draw_arc(center, 20.0, 0, TAU, 20, Color("#FFB800", 0.6 * aura_pulse), 2.0)
		draw_arc(center, 23.0, 0, TAU, 20, Color("#FF3366", 0.35 * aura_pulse), 1.2)

		# Overload arc between left and right shell
		CyberVectorCanvas.draw_plasma_arc(
			self,
			left_c + Vector2(0, -shell_r),
			right_c + Vector2(0, -shell_r),
			Color("#FFE57F"),
			3.0,
			4,
			1.5
		)
