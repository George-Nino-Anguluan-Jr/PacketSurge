# tools/validate_data.gd
# Prints DataRegistry contents so you can confirm the data layer loaded.
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
	var l = DataRegistry.get_level(13)
	print("[validate] level 13: ", l.level_name, " | waves=", l.wave_count, " | spots=", l.tower_spots.size(), " | waypoints=", l.path_waypoints.size())
	var e = DataRegistry.get_enemy("binary_mask")
	print("[validate] binary_mask: ", e.title, " | threat=", e.threat, " | color=", e.color)

	var all_ok := true
	if tdefs.size() != 13: all_ok = false
	if ldefs.size() != 13: all_ok = false
	if edefs.size() != 14: all_ok = false
	if lnames.size() != 18: all_ok = false
	if tdefs.get("tower_array", {}).get("tower_name", "") != "Array Tower": all_ok = false
	if ldefs.get(1, {}).get("concept", "") != "Arrays": all_ok = false
	if not (ldefs.get(1, {}).get("waypoints", []) is Array): all_ok = false
	var wps: Array = ldefs.get(1, {}).get("waypoints", [])
	if wps.is_empty() or not (wps[0] is Vector2): all_ok = false
	if not (ldefs.get(1, {}).get("tower_spots", []) is Array): all_ok = false
	if edefs.get("basic_packet", {}).get("color", Color.BLACK) != Color("#FF3366"): all_ok = false
	if lnames.get("sort_quick", "") != "Quick Sort": all_ok = false

	print("[validate] ", "ALL CHECKS PASSED" if all_ok else "SOME CHECKS FAILED")
	get_tree().quit(0 if all_ok else 1)
