# tools/validate_data.gd
# Prints DataRegistry contents so you can confirm the data layer loaded.
# Checks are data-driven: they never assume fixed counts, so adding a
# .tres file (tower, enemy, lesson, level) keeps passing automatically.
# Run:  Godot --headless res://tools/validate_data.tscn
extends Node

func _ready() -> void:
	print("[validate] towers   = ", DataRegistry.towers.size())
	print("[validate] levels   = ", DataRegistry.levels.size())
	print("[validate] enemies  = ", DataRegistry.enemies.size())
	print("[validate] lessons  = ", DataRegistry.lessons.size())
	print("[validate] lesson_paths = ", DataRegistry.lesson_paths.size())

	var tdefs = DataRegistry.build_tower_definitions()
	var ldefs = DataRegistry.build_level_configs()
	var edefs = DataRegistry.build_enemy_definitions()
	var lnames = DataRegistry.build_lesson_names()

	var t = DataRegistry.get_tower("tower_binary")
	print("[validate] binary tower: ", t.tower_name, " | dmg=", t.damage, " | cost=", t.ram_cost, " | ability=", t.ability_name)
	var level_nums := DataRegistry.get_level_numbers()
	if not level_nums.is_empty():
		var l = DataRegistry.get_level(level_nums.back())
		print("[validate] last level (", l.level_number, "): ", l.level_name, " | waves=", l.wave_count, " | spots=", l.tower_spots.size(), " | waypoints=", l.path_waypoints.size())
	var e = DataRegistry.get_enemy("binary_mask")
	print("[validate] binary_mask: ", e.title, " | threat=", e.threat, " | color=", e.color)

	var all_ok := true
	# Data layer cross-consistency (never assumes fixed counts)
	if DataRegistry.lessons.size() != DataRegistry.lesson_paths.size(): all_ok = false
	if tdefs.size() != DataRegistry.towers.size(): all_ok = false
	if ldefs.size() != DataRegistry.levels.size(): all_ok = false
	if edefs.size() != DataRegistry.enemies.size(): all_ok = false
	if lnames.size() != DataRegistry.lessons.size(): all_ok = false
	if tdefs.is_empty(): all_ok = false
	if ldefs.is_empty(): all_ok = false
	if edefs.is_empty(): all_ok = false
	if lnames.is_empty(): all_ok = false

	# Every lesson must have a section so the Academy sidebar shows it
	for lesson in DataRegistry.lessons:
		if lesson.section.is_empty() and not (
			lesson.lesson_id.begins_with("py_")
			or lesson.lesson_id.begins_with("ds_")
			or lesson.lesson_id.begins_with("sort_")
			or lesson.lesson_id.begins_with("search_")
		):
			print("[validate] lesson without section: ", lesson.lesson_id)
			all_ok = false

	# Every tower must have intro copy so the Index/Preview never shows blanks
	for tower_id in DataRegistry.get_tower_ids_ordered():
		var intro = TowerIntroData.get_intro(tower_id)
		if intro.get("tagline", "") == "" or intro.get("mechanic", "") == "":
			print("[validate] tower missing intro copy: ", tower_id)
			all_ok = false

	# Every tower referenced by a lesson must exist in the data layer
	for lesson_id in ProgressManager.PROGRESSION_CHAIN:
		var chain = ProgressManager.PROGRESSION_CHAIN[lesson_id]
		var tid = chain.get("id", "")
		if tid != "" and not DataRegistry.towers.has(tid):
			print("[validate] lesson ", lesson_id, " unlocks missing tower: ", tid)
			all_ok = false
		var lvl = int(chain.get("level_id", 0))
		if lvl > 0 and not DataRegistry.levels.has(lvl):
			print("[validate] lesson ", lesson_id, " unlocks missing level: ", lvl)
			all_ok = false

	# Spot checks on known content
	if tdefs.get("tower_array", {}).get("tower_name", "") != "Array Tower": all_ok = false
	if not level_nums.is_empty() and ldefs.get(level_nums[0], {}).get("concept", "") != "Arrays": all_ok = false
	if not level_nums.is_empty() and not (ldefs.get(level_nums[0], {}).get("waypoints", []) is Array): all_ok = false
	if not level_nums.is_empty():
		var wps: Array = ldefs.get(level_nums[0], {}).get("waypoints", [])
		if wps.is_empty() or not (wps[0] is Vector2): all_ok = false
	if not level_nums.is_empty() and not (ldefs.get(level_nums[0], {}).get("tower_spots", []) is Array): all_ok = false
	if edefs.get("basic_packet", {}).get("color", Color.BLACK) != Color("#FF3366"): all_ok = false
	if lnames.get("sort_quick", "") != "Quick Sort": all_ok = false

	print("[validate] ", "ALL CHECKS PASSED" if all_ok else "SOME CHECKS FAILED")
	get_tree().quit(0 if all_ok else 1)
