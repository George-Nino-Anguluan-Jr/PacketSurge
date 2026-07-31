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

# Canonical lesson order (matches Academy sidebar / progression)
const LESSON_ORDER: Array[String] = [
	"py_variables", "py_lists", "py_loops",
	"py_conditions", "py_functions",
	"ds_arrays", "ds_stacks", "ds_queues", "ds_linked_lists",
	"sort_bubble", "sort_selection", "sort_insertion",
	"sort_quick", "sort_merge", "sort_counting", "sort_radix",
	"search_linear", "search_binary",
]

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
	var by_id: Dictionary = {}
	var path_by_id: Dictionary = {}
	for path in _list_resources(LESSONS_DIR):
		var r = load(path) as LessonData
		if r and r.lesson_id != "":
			by_id[r.lesson_id] = r
			path_by_id[r.lesson_id] = path
	for lesson_id in LESSON_ORDER:
		if by_id.has(lesson_id):
			lessons.append(by_id[lesson_id])
			lesson_paths.append(path_by_id[lesson_id])

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
		}
	return out

func build_lesson_names() -> Dictionary:
	var out: Dictionary = {}
	for lesson in lessons:
		out[lesson.lesson_id] = lesson.title
	return out
