# DataRegistry.gd
# Single source of truth for game data. Loads every named .tres data file
# from resources/towers, resources/levels, resources/enemies and
# resources/lessons, and exposes them as resources or as the legacy
# dictionary shapes other scripts expect.
#
# Editing any .tres here never touches code, and no code in this file
# references any gameplay logic.
extends Node

# ─── LOADED DATA ────────────────────────────────────────
var towers: Dictionary = {}      # tower_id -> TowerData
var levels: Dictionary = {}      # level_number(int) -> LevelData
var enemies: Dictionary = {}     # enemy_id -> EnemyData
var lessons: Array[LessonData] = []
var lesson_paths: Array[String] = []

const TOWERS_DIR   := "res://resources/towers"
const LEVELS_DIR   := "res://resources/levels"
const ENEMIES_DIR  := "res://resources/enemies"
const LESSONS_DIR  := "res://resources/lessons"

func _ready() -> void:
	_load_towers()
	_load_levels()
	_load_enemies()
	_load_lessons()

# ─── LOADERS ────────────────────────────────────────────
func _load_towers() -> void:
	for path in _list_resources(TOWERS_DIR):
		var r = load(path) as TowerData
		if r and r.tower_id != "":
			towers[r.tower_id] = r

func _load_levels() -> void:
	for path in _list_resources(LEVELS_DIR):
		var r = load(path) as LevelData
		if r and r.level_number > 0:
			levels[r.level_number] = r

func _load_enemies() -> void:
	for path in _list_resources(ENEMIES_DIR):
		var r = load(path) as EnemyData
		if r and r.enemy_id != "":
			enemies[r.enemy_id] = r

func _load_lessons() -> void:
	var all: Array = []  # of LessonData
	var path_by_id: Dictionary = {}
	for path in _list_resources(LESSONS_DIR):
		var r = load(path) as LessonData
		if r and r.lesson_id != "":
			all.append(r)
			path_by_id[r.lesson_id] = path
	# Sort: entries with order > 0 first (ascending), then any with
	# order == 0 (unassigned) alphabetically by id, so new .tres files
	# are appended automatically without touching code.
	all.sort_custom(func(a: LessonData, b: LessonData) -> bool:
		var ao := a.order
		var bo := b.order
		if ao == 0 and bo != 0:
			return false
		if bo == 0 and ao != 0:
			return true
		if ao != bo:
			return ao < bo
		return a.lesson_id < b.lesson_id)
	for r in all:
		lessons.append(r)
		lesson_paths.append(path_by_id[r.lesson_id])

func _list_resources(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if not dir:
		push_warning("DataRegistry: missing data dir " + dir_path)
		return out
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if not dir.current_is_dir() and f.ends_with(".tres"):
			out.append(dir_path.path_join(f))
		f = dir.get_next()
	return out

# ─── ACCESSORS ──────────────────────────────────────────
func get_tower(tower_id: String) -> TowerData:
	return towers.get(tower_id, null)

func get_level(level_number: int) -> LevelData:
	return levels.get(level_number, null)

func get_enemy(enemy_id: String) -> EnemyData:
	return enemies.get(enemy_id, null)

func get_lesson(lesson_id: String) -> LessonData:
	for lesson in lessons:
		if lesson.lesson_id == lesson_id:
			return lesson
	return null

# ─── COUNTS / ORDER HELPERS ─────────────────────────────
# Every UI that used to hardcode "18", "13", "39" reads these instead,
# so adding a .tres file automatically updates every counter.

func get_lesson_count() -> int:
	return lessons.size()

func get_lesson_ids_in_section(section: String) -> Array[String]:
	var out: Array[String] = []
	for lesson in lessons:
		if lesson.section == section:
			out.append(lesson.lesson_id)
	return out

func get_lesson_ids() -> Array[String]:
	var out: Array[String] = []
	for lesson in lessons:
		out.append(lesson.lesson_id)
	return out

func get_level_count() -> int:
	return levels.size()

func get_level_numbers() -> Array[int]:
	var nums: Array[int] = []
	for k in levels.keys():
		nums.append(k)
	nums.sort()
	return nums

func get_total_stars_possible() -> int:
	return get_level_count() * 3

func get_tower_count() -> int:
	return towers.size()

func get_tower_ids_ordered() -> Array[String]:
	var list: Array = towers.values()  # Array of TowerData
	list.sort_custom(func(a: TowerData, b: TowerData) -> bool:
		var ao := a.order
		var bo := b.order
		if ao == 0 and bo != 0:
			return false
		if bo == 0 and ao != 0:
			return true
		if ao != bo:
			return ao < bo
		return a.tower_id < b.tower_id)
	var out: Array[String] = []
	for r in list:
		out.append(r.tower_id)
	return out

func get_enemy_count() -> int:
	return enemies.size()

func get_enemy_ids() -> Array[String]:
	var out: Array[String] = []
	for enemy_id in enemies:
		out.append(enemy_id)
	out.sort()
	return out

# ─── LEGACY DICTIONARY SHAPES ───────────────────────────
# These reproduce the exact dictionaries old code read from GameManager,
# so every existing consumer keeps working unchanged.
func build_tower_definitions() -> Dictionary:
	var out: Dictionary = {}
	for tower_id in towers:
		var r: TowerData = towers[tower_id]
		out[tower_id] = {
			"tower_id":        r.tower_id,
			"tower_name":      r.tower_name,
			"description":     r.description,
			"data_structure":  r.data_structure,
			"ram_cost":        r.ram_cost,
			"damage":          r.damage,
			"attack_speed":    r.attack_speed,
			"attack_range":    r.attack_range,
			"time_complexity": r.time_complexity,
			"color":           r.color,
			"icon_text":       r.icon_text,
			"ability_name":    r.ability_name,
			"spire_variant":   r.spire_variant,
			"spire_base_h":    r.spire_base_h,
		}
	return out

func build_level_configs() -> Dictionary:
	var out: Dictionary = {}
	for level_number in levels:
		var r: LevelData = levels[level_number]
		out[level_number] = {
			"name":            r.level_name,
			"concept":         r.data_structure,
			"concept_desc":    r.concept_desc,
			"enemy_tip":       r.enemy_tip,
			"waves":           r.wave_count,
			"start_ram":       r.starting_ram,
			"tower_slots":     r.tower_slots,
			"waypoints":       r.path_waypoints,
			"tower_spots":     r.tower_spots,
			"required_towers": r.required_towers,
			"towers":          r.available_towers,
			"enemy_types":     r.enemy_types,
		}
	return out

func build_enemy_definitions() -> Dictionary:
	var out: Dictionary = {}
	for enemy_id in enemies:
		var r: EnemyData = enemies[enemy_id]
		out[enemy_id] = {
			"color": r.color,
			"max_health": r.max_health,
			"speed": r.speed,
			"ram_reward": r.ram_reward,
			"is_boss": r.is_boss,
		}
	return out

func build_lesson_names() -> Dictionary:
	var out: Dictionary = {}
	for lesson in lessons:
		out[lesson.lesson_id] = lesson.title
	return out
