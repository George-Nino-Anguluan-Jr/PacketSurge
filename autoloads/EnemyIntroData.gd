extends Node

# EnemyIntroData.gd
# Thin read-only wrapper over DataRegistry's EnemyData resources.
# All enemy copy lives in resources/enemies/*.tres (title, tagline,
# icon, threat, special, lesson, color). Editing a .tres file here
# propagates to every screen that calls get_intro() with zero code
# changes.

func get_intro(enemy_id: String) -> Dictionary:
	var e = DataRegistry.get_enemy(enemy_id)
	if e == null:
		return {}
	return {
		"title":    e.title,
		"tagline":  e.tagline,
		"icon":     e.icon,
		"threat":   e.threat,
		"special":  e.special,
		"lesson":   e.lesson,
		"color":    e.color,
	}

func get_enemy_name(enemy_id: String) -> String:
	var e = DataRegistry.get_enemy(enemy_id)
	return e.title if e else enemy_id

func get_threat(enemy_id: String) -> String:
	var e = DataRegistry.get_enemy(enemy_id)
	return e.threat if e and e.threat != "" else "Medium"

func get_icon(enemy_id: String) -> String:
	var e = DataRegistry.get_enemy(enemy_id)
	return e.icon if e else ""

func all_ids() -> Array:
	return DataRegistry.get_enemy_ids()
