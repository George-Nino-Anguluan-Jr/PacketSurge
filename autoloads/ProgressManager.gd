# ProgressManager.gd
extends Node

# ─── PROGRESSION CONSTANTS ─────────────────────────────
const PROGRESSION_CHAIN: Dictionary = {
	# DS lessons → unlock towers and campaign levels
	"ds_arrays":       {"type": "both",  "id": "tower_array",       "level_id": 1},
	"ds_stacks":       {"type": "both",  "id": "tower_stack",       "level_id": 2},
	"ds_queues":       {"type": "both",  "id": "tower_queue",       "level_id": 3},
	"ds_linked_lists": {"type": "both",  "id": "tower_linked_list", "level_id": 4},
	# Sorting lessons → unlock towers and campaign levels
	"sort_bubble":     {"type": "both",  "id": "tower_bubble",      "level_id": 5},
	"sort_selection":  {"type": "both",  "id": "tower_selection",   "level_id": 6},
	"sort_insertion":  {"type": "both",  "id": "tower_insertion",   "level_id": 7},
	"sort_quick":      {"type": "both",  "id": "tower_quick",       "level_id": 8},
	"sort_merge":      {"type": "both",  "id": "tower_merge",       "level_id": 9},
	"sort_counting":   {"type": "both",  "id": "tower_counting",    "level_id": 10},
	"sort_radix":      {"type": "both",  "id": "tower_radix",       "level_id": 11},
	# Search lessons → unlock towers and campaign levels
	"search_linear":   {"type": "both",  "id": "tower_linear",      "level_id": 12},
	"search_binary":   {"type": "both",  "id": "tower_binary",      "level_id": 13},
}

const LEVEL_UNLOCKS_LESSON: Dictionary = {
	1:  "ds_stacks",
	2:  "ds_queues",
	3:  "ds_linked_lists",
	4:  "sort_bubble",
	5:  "sort_selection",
	6:  "sort_insertion",
	7:  "sort_quick",
	8:  "sort_merge",
	9:  "sort_counting",
	10: "sort_radix",
	11: "search_linear",
	12: "search_binary",
}

const ALL_LESSONS = [
	"py_variables", "py_lists", "py_loops",
	"py_conditions", "py_functions",
	"ds_arrays", "ds_stacks", "ds_queues", "ds_linked_lists",
	"sort_bubble", "sort_selection", "sort_insertion",
	"sort_quick", "sort_merge", "sort_counting", "sort_radix",
	"search_linear", "search_binary",
]

# ─── PROGRESS DATA ─────────────────────────────────────
var topic_states: Dictionary      = {}
var time_spent: Dictionary        = {}
var unlocked_towers: Array[String] = []
var new_unlocked_towers: Array[String] = []
var campaign_progress: Dictionary  = {
	"placement_quiz_done": false,
	"max_level_unlocked":  0,
	"waves_completed":     0,
	"level_stars":        {},  # level_number → int (0-3)
}
var campaign_time: Dictionary      = {}  # level_number (str) → seconds (float)
var tutorials_seen: Array[String]   = []  # tutorial scene key (e.g. "main_menu", "level_1")

# ─── STARTUP ───────────────────────────────────────────
func _ready() -> void:
	load_progress()
	_ensure_base_state()

func _ensure_base_state() -> void:
	# py_variables always unlocked
	if topic_states.get("py_variables", "locked") == "locked":
		topic_states["py_variables"] = "unlocked"

	# Fill missing topics as locked
	for topic_id in ALL_LESSONS:
		if not topic_states.has(topic_id):
			topic_states[topic_id] = "locked"

	# Level 1 always unlocked if ds_arrays mastered
	if topic_states.get("ds_arrays") == "mastered":
		if campaign_progress.get("max_level_unlocked", 0) < 1:
			campaign_progress["max_level_unlocked"] = 1

	check_all_unlocks()
	print("[ProgressManager] Base state ensured.")

# ─── TOPIC STATE ───────────────────────────────────────
func get_topic_state(topic_id: String) -> String:
	return topic_states.get(topic_id, "locked")

func unlock_topic(topic_id: String) -> void:
	if topic_states.get(topic_id, "locked") == "locked":
		topic_states[topic_id] = "unlocked"
		SignalBus.topic_unlocked.emit(topic_id)
		print("[ProgressManager] Unlocked: ", topic_id)
		save_progress()

func mark_mastered(topic_id: String) -> void:
	topic_states[topic_id] = "mastered"
	SignalBus.topic_mastered.emit(topic_id)
	print("[ProgressManager] Mastered: ", topic_id)
	save_progress()

func set_topic_state(topic_id: String, state: String) -> void:
	if state not in ["locked", "unlocked", "practice", "struggling", "mastered"]:
		return
	if topic_states.get(topic_id) == "mastered" and state != "mastered":
		return
	topic_states[topic_id] = state
	save_progress()

func get_topic_for_level(level_number: int) -> String:
	for topic_id in PROGRESSION_CHAIN:
		var entry = PROGRESSION_CHAIN[topic_id]
		if entry.get("level_id") == level_number:
			return topic_id
	return ""

# ─── UNLOCK CHECKER ────────────────────────────────────
func check_all_unlocks() -> void:
	# 1. Sequential Python unlocking
	if get_topic_state("py_variables") == "mastered":
		unlock_topic("py_lists")
	if get_topic_state("py_lists") == "mastered":
		unlock_topic("py_loops")
	if get_topic_state("py_loops") == "mastered":
		unlock_topic("py_conditions")
	if get_topic_state("py_conditions") == "mastered":
		unlock_topic("py_functions")
	if get_topic_state("py_functions") == "mastered":
		unlock_topic("ds_arrays")

	# 2. Sequential DS / Sort / Search unlocking based on BOTH mastered lesson AND completed campaign level
	var waves_done = campaign_progress.get("waves_completed", 0)

	if get_topic_state("ds_arrays") == "mastered" and waves_done >= 1:
		unlock_topic("ds_stacks")

	if get_topic_state("ds_stacks") == "mastered" and waves_done >= 2:
		unlock_topic("ds_queues")

	if get_topic_state("ds_queues") == "mastered" and waves_done >= 3:
		unlock_topic("ds_linked_lists")

	if get_topic_state("ds_linked_lists") == "mastered" and waves_done >= 4:
		unlock_topic("sort_bubble")

	if get_topic_state("sort_bubble") == "mastered" and waves_done >= 5:
		unlock_topic("sort_selection")

	if get_topic_state("sort_selection") == "mastered" and waves_done >= 6:
		unlock_topic("sort_insertion")

	if get_topic_state("sort_insertion") == "mastered" and waves_done >= 7:
		unlock_topic("sort_quick")

	if get_topic_state("sort_quick") == "mastered" and waves_done >= 8:
		unlock_topic("sort_merge")

	if get_topic_state("sort_merge") == "mastered" and waves_done >= 9:
		unlock_topic("sort_counting")

	if get_topic_state("sort_counting") == "mastered" and waves_done >= 10:
		unlock_topic("sort_radix")

	if get_topic_state("sort_radix") == "mastered" and waves_done >= 11:
		unlock_topic("search_linear")

	if get_topic_state("search_linear") == "mastered" and waves_done >= 12:
		unlock_topic("search_binary")

# ─── LESSON COMPLETION ─────────────────────────────────
func on_lesson_completed(lesson_id: String) -> void:
	mark_mastered(lesson_id)
	SignalBus.lesson_completed.emit(lesson_id)

	if PROGRESSION_CHAIN.has(lesson_id):
		var chain = PROGRESSION_CHAIN[lesson_id]

		if chain["type"] == "tower" or chain["type"] == "both":
			# DS/Sort/Search lesson → unlock tower
			var tower_id = chain["id"]
			unlock_tower(tower_id)
			SignalBus.tower_unlocked.emit(tower_id)
			print("[ProgressManager] Tower unlocked: ", tower_id)

		if chain["type"] == "level" or chain["type"] == "both":
			# Python lesson or DS lesson → unlock campaign level
			var level_num = chain.get("level_id", chain.get("id"))
			unlock_campaign_level(level_num)
			print("[ProgressManager] Campaign level unlocked: ", level_num)

	check_all_unlocks()
	save_progress()

func on_level_completed(level_number: int) -> void:
	# Track highest level completed
	var current = campaign_progress.get("waves_completed", 0)
	if level_number > current:
		campaign_progress["waves_completed"] = level_number

	# Level 1 completion always ensures Level 1 unlocked (for max_level_unlocked progression)
	if campaign_progress.get("max_level_unlocked", 0) < level_number:
		campaign_progress["max_level_unlocked"] = level_number

	check_all_unlocks()

	# Emit lesson unlocked signal for the UI notifications if applicable
	if LEVEL_UNLOCKS_LESSON.has(level_number):
		var next_lesson = LEVEL_UNLOCKS_LESSON[level_number]
		if get_topic_state(next_lesson) == "unlocked":
			SignalBus.lesson_unlocked.emit(next_lesson)
			print("[ProgressManager] Lesson unlocked notification: ", next_lesson)

	save_progress()

# ─── TIME TRACKING ─────────────────────────────────────
func add_time_spent(topic_id: String, seconds: float) -> void:
	if not time_spent.has(topic_id):
		time_spent[topic_id] = 0.0
	time_spent[topic_id] += seconds
	save_progress()

func add_campaign_time(level_number: int, seconds: float) -> void:
	var key = str(level_number)
	if not campaign_time.has(key):
		campaign_time[key] = 0.0
	campaign_time[key] += seconds
	save_progress()

# ─── UNLOCK HELPERS ────────────────────────────────────
func unlock_campaign_level(level_number: int) -> void:
	var current_max = campaign_progress.get("max_level_unlocked", 0)
	if level_number > current_max:
		campaign_progress["max_level_unlocked"] = level_number
		SignalBus.campaign_level_unlocked.emit(level_number)

func unlock_tower(tower_id: String) -> void:
	if tower_id not in unlocked_towers:
		unlocked_towers.append(tower_id)
		if tower_id not in new_unlocked_towers:
			new_unlocked_towers.append(tower_id)

func is_tower_unlocked(tower_id: String) -> bool:
	return tower_id in unlocked_towers

func get_new_unlocked_towers() -> Array[String]:
	return new_unlocked_towers.duplicate()

func mark_tower_seen(tower_id: String) -> void:
	new_unlocked_towers.erase(tower_id)

func is_level_unlocked(level_number: int) -> bool:
	return level_number <= campaign_progress.get(
		"max_level_unlocked", 0
	)

func set_level_stars(level_number: int, stars: int) -> void:
	var star_map = campaign_progress.get("level_stars", {})
	var existing = int(star_map.get(str(level_number), star_map.get(level_number, 0)))
	if existing < stars:
		star_map[str(level_number)] = stars
		campaign_progress["level_stars"] = star_map
		save_progress()

func get_level_stars(level_number: int) -> int:
	var star_map = campaign_progress.get("level_stars", {})
	return int(star_map.get(str(level_number), star_map.get(level_number, 0)))

# ─── SAVE & LOAD ───────────────────────────────────────
func save_progress() -> void:
	var data = {
		"topic_states":      topic_states,
		"time_spent":        time_spent,
		"campaign_time":     campaign_time,
		"unlocked_towers":   unlocked_towers,
		"new_unlocked_towers": new_unlocked_towers,
		"campaign_progress": campaign_progress,
		"tutorials_seen":    tutorials_seen,
	}
	var json_string = JSON.stringify(data)

	if OS.get_name() == "Web":
		JavaScriptBridge.eval(
			"localStorage.setItem('packet_surge_save', '%s')" \
			% json_string.replace("'", "\\'")
		)
	else:
		var file = FileAccess.open(
			"user://save.json", FileAccess.WRITE
		)
		if file:
			file.store_string(json_string)
			file.close()

	if get_node_or_null("/root/SupabaseManager") != null:
		if SupabaseManager.is_logged_in:
			SupabaseManager.save_progress_to_cloud()
			SupabaseManager.update_leaderboard()

	print("[ProgressManager] Progress saved.")

func load_progress() -> void:
	var json_string := ""

	if OS.get_name() == "Web":
		var result = JavaScriptBridge.eval(
			"localStorage.getItem('packet_surge_save') || ''"
		)
		if result is String:
			json_string = result
	else:
		if FileAccess.file_exists("user://save.json"):
			var file = FileAccess.open(
				"user://save.json", FileAccess.READ
			)
			if file:
				json_string = file.get_as_text()
				file.close()

	if json_string == "":
		print("[ProgressManager] No save found. Starting fresh.")
		return

	var 	parsed = JSON.parse_string(json_string)
	if parsed == null:
		print("[ProgressManager] Save corrupted. Starting fresh.")
		return

	topic_states    = parsed.get("topic_states",    {})
	time_spent      = parsed.get("time_spent",      {})
	campaign_time   = parsed.get("campaign_time",   {})

	var loaded_towers = parsed.get("unlocked_towers", [])
	unlocked_towers   = []
	for tower in loaded_towers:
		unlocked_towers.append(str(tower))

	var loaded_new = parsed.get("new_unlocked_towers", [])
	new_unlocked_towers = []
	for tower in loaded_new:
		new_unlocked_towers.append(str(tower))

	campaign_progress = parsed.get("campaign_progress", {})

	var loaded_tutorials = parsed.get("tutorials_seen", [])
	tutorials_seen = []
	for t in loaded_tutorials:
		tutorials_seen.append(str(t))

	print("[ProgressManager] Progress loaded.")

func reset_all_progress() -> void:
	topic_states        = {}
	time_spent          = {}
	campaign_time       = {}
	unlocked_towers     = []
	new_unlocked_towers = []
	tutorials_seen      = []
	campaign_progress   = {
		"placement_quiz_done": false,
		"max_level_unlocked":  0,
		"waves_completed":     0,
		"level_stars":        {},
	}
	_ensure_base_state()
	save_progress()

# ─── TUTORIAL TRACKING ─────────────────────────────────
func has_seen_tutorial(key: String) -> bool:
	return key in tutorials_seen

func mark_tutorial_seen(key: String) -> void:
	if key not in tutorials_seen:
		tutorials_seen.append(key)
		save_progress()
		print("[ProgressManager] Tutorial seen: ", key)

func reset_tutorial(key: String) -> void:
	tutorials_seen.erase(key)
	save_progress()
