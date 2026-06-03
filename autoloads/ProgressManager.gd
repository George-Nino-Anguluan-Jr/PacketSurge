# ProgressManager.gd
# Tracks everything the student has done across the entire game
extends Node

# ─── PROGRESSION CONSTANTS ─────────────────────────────
const PROGRESSION_CHAIN: Dictionary = {
	"py_variables":    {"unlocks_tower": "tower_array",      "unlocks_level": 1},
	"py_lists":        {"unlocks_tower": "tower_stack",      "unlocks_level": 2},
	"py_loops":        {"unlocks_tower": "tower_queue",      "unlocks_level": 3},
	"py_conditions":   {"unlocks_tower": "tower_linked_list","unlocks_level": 4},
	"py_functions":    {"unlocks_tower": "tower_bubble",     "unlocks_level": 5},
	"ds_arrays":       {"unlocks_tower": "tower_selection",  "unlocks_level": 6},
	"ds_stacks":       {"unlocks_tower": "tower_insertion",  "unlocks_level": 7},
	"ds_queues":       {"unlocks_tower": "tower_bonus_1",    "unlocks_level": 8},
	"ds_linked_lists": {"unlocks_tower": "tower_bonus_2",    "unlocks_level": 9},
	"sort_bubble":     {"unlocks_tower": "tower_upgrade_1",  "unlocks_level": 10},
	"sort_selection":  {"unlocks_tower": "tower_upgrade_2",  "unlocks_level": 11},
	"sort_insertion":  {"unlocks_tower": "tower_mastery",    "unlocks_level": 0},
}

const LEVEL_UNLOCKS_LESSON: Dictionary = {
	1:  "py_lists",
	2:  "py_loops",
	3:  "py_conditions",
	4:  "py_functions",
	5:  "ds_arrays",
	6:  "ds_stacks",
	7:  "ds_queues",
	8:  "ds_linked_lists",
	9:  "sort_bubble",
	10: "sort_selection",
	11: "sort_insertion",
}

# ─── PROGRESS DATA ─────────────────────────────────────
var topic_states: Dictionary = {}
var coding_accuracy: Dictionary = {}
var retry_counts: Dictionary = {}
var time_spent: Dictionary = {}
var unlocked_towers: Array[String] = []
var campaign_progress: Dictionary = {
	"current_level":      0,
	"waves_completed":    0,
	"towers_unlocked":    [],
	"max_level_unlocked": 0,
}

# ─── STARTUP ───────────────────────────────────────────
func _ready() -> void:
	load_progress()        # Load saved data first
	_ensure_base_state()   # Then guarantee base unlocks on top

func _ensure_base_state() -> void:
	# py_variables is ALWAYS unlocked or mastered — never locked
	if topic_states.get("py_variables", "locked") == "locked":
		topic_states["py_variables"] = "unlocked"

	# Fill missing topics as locked
	var all_topics = [
		"py_variables", "py_lists", "py_loops",
		"py_conditions", "py_functions",
		"ds_arrays", "ds_stacks", "ds_queues", "ds_linked_lists",
		"sort_bubble", "sort_selection", "sort_insertion",
	]
	for topic_id in all_topics:
		if not topic_states.has(topic_id):
			topic_states[topic_id] = "locked"

	# Always ensure tower_array is unlocked
	if "tower_array" not in unlocked_towers:
		unlocked_towers.append("tower_array")

	# Always ensure level 1 is unlocked
	if campaign_progress.get("max_level_unlocked", 0) < 1:
		campaign_progress["max_level_unlocked"] = 1

	print("[ProgressManager] Base state ensured. py_variables = ",
		topic_states.get("py_variables", "MISSING"))

func _initialize_topics() -> void:
	var all_topics = {
		"py_variables":    "unlocked",
		"py_lists":        "locked",
		"py_loops":        "locked",
		"py_conditions":   "locked",
		"py_functions":    "locked",
		"ds_arrays":       "locked",
		"ds_stacks":       "locked",
		"ds_queues":       "locked",
		"ds_linked_lists": "locked",
		"sort_bubble":     "locked",
		"sort_selection":  "locked",
		"sort_insertion":  "locked",
	}
	for topic_id in all_topics:
		if not topic_states.has(topic_id):
			topic_states[topic_id] = all_topics[topic_id]

# ─── TOPIC STATE ───────────────────────────────────────
func get_topic_state(topic_id: String) -> String:
	return topic_states.get(topic_id, "locked")

func unlock_topic(topic_id: String) -> void:
	if topic_states.get(topic_id) == "locked":
		topic_states[topic_id] = "unlocked"
		SignalBus.topic_unlocked.emit(topic_id)
		print("[ProgressManager] Unlocked: ", topic_id)
		save_progress()

func mark_mastered(topic_id: String) -> void:
	topic_states[topic_id] = "mastered"
	SignalBus.topic_mastered.emit(topic_id)
	print("[ProgressManager] Mastered: ", topic_id)
	save_progress()

# ─── CODING PERFORMANCE ────────────────────────────────
func record_challenge_attempt(challenge_id: String, passed: bool) -> void:
	if not retry_counts.has(challenge_id):
		retry_counts[challenge_id] = 0
	if not passed:
		retry_counts[challenge_id] += 1

	var score = 1.0 if passed else 0.0
	if not coding_accuracy.has(challenge_id):
		coding_accuracy[challenge_id] = score
	else:
		coding_accuracy[challenge_id] = lerp(coding_accuracy[challenge_id], score, 0.4)

	SignalBus.code_challenge_submitted.emit(challenge_id, passed)
	save_progress()

func get_retry_count(challenge_id: String) -> int:
	return retry_counts.get(challenge_id, 0)

func get_accuracy(challenge_id: String) -> float:
	return coding_accuracy.get(challenge_id, 1.0)

# ─── TIME TRACKING ─────────────────────────────────────
func add_time_spent(topic_id: String, seconds: float) -> void:
	if not time_spent.has(topic_id):
		time_spent[topic_id] = 0.0
	time_spent[topic_id] += seconds
	save_progress()

# ─── PROGRESSION ───────────────────────────────────────
func on_lesson_completed(lesson_id: String) -> void:
	mark_mastered(lesson_id)
	if not PROGRESSION_CHAIN.has(lesson_id):
		return

	var chain = PROGRESSION_CHAIN[lesson_id]

	# Unlock tower
	var tower = chain["unlocks_tower"]
	if tower != "" and tower not in unlocked_towers:
		unlocked_towers.append(tower)
		SignalBus.tower_unlocked.emit(tower)
		print("[ProgressManager] Tower unlocked: ", tower)

	# Unlock campaign level
	var level = chain["unlocks_level"]
	if level > 0:
		var current_max = campaign_progress.get("max_level_unlocked", 0)
		if level > current_max:
			campaign_progress["max_level_unlocked"] = level
			SignalBus.campaign_level_unlocked.emit(level)
			print("[ProgressManager] Campaign Level unlocked: ", level)

# ── DEV MODE: unlock next lesson directly ──────────
	# Remove this block once Campaign is built
	if LEVEL_UNLOCKS_LESSON.has(level):
		var next_lesson = LEVEL_UNLOCKS_LESSON[level]
		unlock_topic(next_lesson)
		SignalBus.lesson_unlocked.emit(next_lesson)
		print("[ProgressManager] DEV: Lesson unlocked directly: ", next_lesson)
	# ────────────
	
	save_progress()

func on_level_completed(level_number: int) -> void:
	var current = campaign_progress.get("waves_completed", 0)
	if level_number > current:
		campaign_progress["waves_completed"] = level_number

	if LEVEL_UNLOCKS_LESSON.has(level_number):
		var next_lesson = LEVEL_UNLOCKS_LESSON[level_number]
		unlock_topic(next_lesson)
		SignalBus.lesson_unlocked.emit(next_lesson)
		print("[ProgressManager] Lesson unlocked: ", next_lesson)

	save_progress()

# ─── UTILITY ───────────────────────────────────────────
func is_tower_unlocked(tower_id: String) -> bool:
	return tower_id in unlocked_towers

func is_level_unlocked(level_number: int) -> bool:
	return level_number <= campaign_progress.get("max_level_unlocked", 0)

# ─── SAVE & LOAD ───────────────────────────────────────
func save_progress() -> void:
	# Save locally first
	var data = {
		"topic_states":      topic_states,
		"coding_accuracy":   coding_accuracy,
		"retry_counts":      retry_counts,
		"time_spent":        time_spent,
		"unlocked_towers":   unlocked_towers,
		"campaign_progress": campaign_progress,
	}
	var json_string = JSON.stringify(data)

	if OS.get_name() == "Web":
		JavaScriptBridge.eval(
			"localStorage.setItem('packet_surge_save', '%s')" \
			% json_string.replace("'", "\\'")
		)
	else:
		var file = FileAccess.open("user://save.json", FileAccess.WRITE)
		file.store_string(json_string)
		file.close()

	# Sync to cloud if logged in
	if Engine.has_singleton("SupabaseManager") or \
	   get_node_or_null("/root/SupabaseManager") != null:
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
			var file = FileAccess.open("user://save.json", FileAccess.READ)
			json_string = file.get_as_text()
			file.close()

	if json_string == "":
		print("[ProgressManager] No save found. Starting fresh.")
		return

	var parsed = JSON.parse_string(json_string)
	if parsed == null:
		print("[ProgressManager] Save file corrupted. Starting fresh.")
		return

	topic_states      = parsed.get("topic_states",      {})
	coding_accuracy   = parsed.get("coding_accuracy",   {})
	retry_counts      = parsed.get("retry_counts",      {})
	time_spent        = parsed.get("time_spent",         {})
	
	var loaded_towers = parsed.get("unlocked_towers", [])
	for tower in loaded_towers:
		if tower not in unlocked_towers:
			unlocked_towers.append(str(tower))
	campaign_progress = parsed.get("campaign_progress", {})
	print("[ProgressManager] Progress loaded.")

func reset_all_progress() -> void:
	topic_states      = {}
	coding_accuracy   = {}
	retry_counts      = {}
	time_spent        = {}
	unlocked_towers   = []
	campaign_progress = {
		"current_level":      0,
		"waves_completed":    0,
		"towers_unlocked":    [],
		"max_level_unlocked": 0,
	}
	_initialize_topics()
	save_progress()
