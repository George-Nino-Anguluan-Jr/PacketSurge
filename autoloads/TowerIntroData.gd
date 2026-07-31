extends Node

# TowerIntroData.gd
# Thin read-only wrapper over DataRegistry's TowerData resources.
# All intro copy lives in resources/towers/*.tres (tagline, mechanic,
# shooting, ability_desc, strong_against, weak_against, targeting).
# Editing a .tres file here propagates to every screen that calls
# get_intro() with zero code changes.

func get_intro(tower_id: String) -> Dictionary:
	var t = DataRegistry.get_tower(tower_id)
	if t == null:
		return {}
	return {
		"tagline":  t.tagline,
		"mechanic": t.mechanic,
		"shooting": t.shooting,
		"ability":  t.ability_desc,
		"strong":   t.strong_against,
		"weak":     t.weak_against,
		"targeting": t.targeting,
	}

func get_tower_name(tower_id: String) -> String:
	var def = GameManager.TOWER_DEFINITIONS.get(tower_id, {})
	return def.get("tower_name", tower_id)
