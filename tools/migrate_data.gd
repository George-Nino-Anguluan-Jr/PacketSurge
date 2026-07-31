# tools/migrate_data.gd
# One-time migration: writes named .tres data files from the legacy
# hardcoded dicts in GameManager.gd / EnemyIntroData.gd.
# Run:  Godot --headless res://tools/migrate_data.tscn
extends Node

func _ready() -> void:
	_generate_towers()
	_generate_levels()
	_generate_enemies()
	print("[migrate] Done.")
	get_tree().quit()

func _generate_towers() -> void:
	var TowerData = load("res://scripts/data/TowerData.gd")
	DirAccess.make_dir_recursive_absolute("res://resources/towers")
	for tower_id in GameManager.TOWER_DEFINITIONS:
		var d: Dictionary = GameManager.TOWER_DEFINITIONS[tower_id]
		var r = TowerData.new()
		r.tower_id        = d.get("tower_id", tower_id)
		r.tower_name      = d.get("tower_name", "")
		r.description     = d.get("description", "")
		r.data_structure  = d.get("data_structure", "")
		r.ram_cost        = d.get("ram_cost", 50)
		r.damage          = d.get("damage", 10.0)
		r.attack_speed    = d.get("attack_speed", 1.0)
		r.attack_range    = d.get("attack_range", 150.0)
		r.time_complexity = d.get("time_complexity", "O(1)")
		r.ability_name    = d.get("ability_name", "")
		r.color           = d.get("color", Color("#00D4FF"))
		r.icon_text       = d.get("icon_text", "[ ]")
		r.spire_variant   = d.get("spire_variant", "")
		r.spire_base_h    = d.get("spire_base_h", 0)
		var path = "res://resources/towers/%s.tres" % tower_id
		var err = ResourceSaver.save(r, path)
		print("[migrate] tower %s -> %s (%s)" % [tower_id, path, error_string(err)])

func _generate_levels() -> void:
	var LevelData = load("res://scripts/data/LevelData.gd")
	DirAccess.make_dir_recursive_absolute("res://resources/levels")
	for level_num in GameManager.LEVEL_CONFIGS:
		var d: Dictionary = GameManager.LEVEL_CONFIGS[level_num]
		var r = LevelData.new()
		r.level_number       = level_num
		r.level_name         = d.get("name", "Level %d" % level_num)
		r.description        = d.get("concept_desc", "")
		r.data_structure     = d.get("concept", "")
		r.concept_desc       = d.get("concept_desc", "")
		r.enemy_tip          = d.get("enemy_tip", "")
		r.starting_ram       = d.get("start_ram", 150)
		r.wave_count         = d.get("waves", 3)
		r.tower_slots        = d.get("tower_slots", 2)
		r.required_towers    = _to_string_array(d.get("required_towers", []))
		r.enemy_types        = _to_string_array(d.get("enemy_types", []))
		r.available_towers   = _to_string_array(d.get("towers", []))
		r.path_waypoints     = _to_vec2_array(d.get("waypoints", []))
		r.tower_spots        = _to_vec2i_array(d.get("tower_spots", []))
		var path = "res://resources/levels/level_%02d.tres" % level_num
		var err = ResourceSaver.save(r, path)
		print("[migrate] level %d -> %s (%s)" % [level_num, path, error_string(err)])

func _generate_enemies() -> void:
	var EnemyData = load("res://scripts/data/EnemyData.gd")
	DirAccess.make_dir_recursive_absolute("res://resources/enemies")
	for enemy_id in EnemyIntroData.enemy_intros:
		var d: Dictionary = EnemyIntroData.enemy_intros[enemy_id]
		var r = EnemyData.new()
		r.enemy_id = enemy_id
		r.title    = d.get("title", enemy_id)
		r.tagline  = d.get("tagline", "")
		r.icon     = d.get("icon", "[ ]")
		r.threat   = d.get("threat", "Medium")
		r.special  = d.get("special", "")
		r.lesson   = d.get("lesson", "")
		r.color    = GameManager.ENEMY_DEFINITIONS.get(enemy_id, {}).get("color", Color("#FF3366"))
		var path = "res://resources/enemies/enemy_%s.tres" % enemy_id
		var err = ResourceSaver.save(r, path)
		print("[migrate] enemy %s -> %s (%s)" % [enemy_id, path, error_string(err)])

func _to_string_array(a: Array) -> Array[String]:
	var out: Array[String] = []
	for v in a:
		out.append(str(v))
	return out

func _to_vec2_array(a: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for v in a:
		out.append(v)
	return out

func _to_vec2i_array(a: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for v in a:
		out.append(v)
	return out
