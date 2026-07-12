# ProgressManager.gd
extends Node

# ─── PROGRESSION CONSTANTS ─────────────────────────────
const PROGRESSION_CHAIN: Dictionary = {
	# Python lessons → unlock Campaign levels
	"py_variables":    {"type": "level",  "id": 1},
	"py_lists":        {"type": "level",  "id": 2},
	"py_loops":        {"type": "level",  "id": 3},
	"py_conditions":   {"type": "level",  "id": 4},
	"py_functions":    {"type": "level",  "id": 5},
	# DS lessons → unlock towers
	"ds_arrays":       {"type": "tower",  "id": "tower_array"},
	"ds_stacks":       {"type": "tower",  "id": "tower_stack"},
	"ds_queues":       {"type": "tower",  "id": "tower_queue"},
	"ds_linked_lists": {"type": "tower",  "id": "tower_linked_list"},
	# Sorting lessons → unlock towers
	"sort_bubble":     {"type": "tower",  "id": "tower_bubble"},
	"sort_selection":  {"type": "tower",  "id": "tower_selection"},
	"sort_insertion":  {"type": "tower",  "id": "tower_insertion"},
	"sort_quick":      {"type": "tower",  "id": "tower_quick"},
	"sort_merge":      {"type": "tower",  "id": "tower_merge"},
	"sort_counting":   {"type": "tower",  "id": "tower_counting"},
	"sort_radix":      {"type": "tower",  "id": "tower_radix"},
	# Search lessons → unlock towers
	"search_linear":   {"type": "tower",  "id": "tower_linear"},
	"search_binary":   {"type": "tower",  "id": "tower_binary"},
}

const LEVEL_UNLOCKS_LESSON: Dictionary = {
	1:  "ds_arrays",
	2:  "ds_stacks",
	3:  "ds_queues",
	4:  "ds_linked_lists",
	5:  "sort_bubble",
	6:  "sort_selection",
	7:  "sort_insertion",
	8:  "sort_quick",
	9:  "sort_merge",
	10: "sort_counting",
	11: "sort_radix",
	12: "search_linear",
	13: "search_binary",
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
var coding_accuracy: Dictionary   = {}
var retry_counts: Dictionary      = {}
var time_spent: Dictionary        = {}
var unlocked_towers: Array[String] = []
var campaign_progress: Dictionary  = {
	"max_level_unlocked": 0,
	"waves_completed":    0,
	"placement_quiz_done": false,
}

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

	# tower_array always available as starter
	if "tower_array" not in unlocked_towers:
		unlocked_towers.append("tower_array")

	# Level 1 always unlocked if py_variables mastered
	if topic_states.get("py_variables") == "mastered":
		if campaign_progress.get("max_level_unlocked", 0) < 1:
			campaign_progress["max_level_unlocked"] = 1

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

# ─── LESSON COMPLETION ─────────────────────────────────
func on_lesson_completed(lesson_id: String) -> void:
	mark_mastered(lesson_id)

	if not PROGRESSION_CHAIN.has(lesson_id):
		return

	var chain = PROGRESSION_CHAIN[lesson_id]

	if chain["type"] == "tower":
		# DS/Sort/Search lesson → unlock tower
		var tower_id = chain["id"]
		unlock_tower(tower_id)
		SignalBus.tower_unlocked.emit(tower_id)
		print("[ProgressManager] Tower unlocked: ", tower_id)

	elif chain["type"] == "level":
		# Python lesson → unlock campaign level
		var level_num = chain["id"]
		unlock_campaign_level(level_num)
		print("[ProgressManager] Campaign level unlocked: ", level_num)

	save_progress()

func on_level_completed(level_number: int) -> void:
	# Track highest level completed
	var current = campaign_progress.get("waves_completed", 0)
	if level_number > current:
		campaign_progress["waves_completed"] = level_number

	# Unlock next lesson
	if LEVEL_UNLOCKS_LESSON.has(level_number):
		var next_lesson = LEVEL_UNLOCKS_LESSON[level_number]
		unlock_topic(next_lesson)
		SignalBus.lesson_unlocked.emit(next_lesson)
		print("[ProgressManager] Lesson unlocked: ", next_lesson)

	save_progress()

# ─── CODING PERFORMANCE ────────────────────────────────
func record_challenge_attempt(
		challenge_id: String,
		passed: bool) -> void:
	if not retry_counts.has(challenge_id):
		retry_counts[challenge_id] = 0
	if not passed:
		retry_counts[challenge_id] += 1

	var score = 1.0 if passed else 0.0
	if not coding_accuracy.has(challenge_id):
		coding_accuracy[challenge_id] = score
	else:
		coding_accuracy[challenge_id] = lerp(
			coding_accuracy[challenge_id], score, 0.4
		)
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

# ─── UNLOCK HELPERS ────────────────────────────────────
func unlock_campaign_level(level_number: int) -> void:
	var current_max = campaign_progress.get("max_level_unlocked", 0)
	if level_number > current_max:
		campaign_progress["max_level_unlocked"] = level_number
		SignalBus.campaign_level_unlocked.emit(level_number)

func unlock_tower(tower_id: String) -> void:
	if tower_id not in unlocked_towers:
		unlocked_towers.append(tower_id)

func is_tower_unlocked(tower_id: String) -> bool:
	return tower_id in unlocked_towers

func is_level_unlocked(level_number: int) -> bool:
	return level_number <= campaign_progress.get(
		"max_level_unlocked", 0
	)

# ─── SAVE & LOAD ───────────────────────────────────────
func save_progress() -> void:
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

	var parsed = JSON.parse_string(json_string)
	if parsed == null:
		print("[ProgressManager] Save corrupted. Starting fresh.")
		return

	topic_states    = parsed.get("topic_states",    {})
	coding_accuracy = parsed.get("coding_accuracy", {})
	retry_counts    = parsed.get("retry_counts",    {})
	time_spent      = parsed.get("time_spent",      {})

	var loaded_towers = parsed.get("unlocked_towers", [])
	unlocked_towers   = []
	for tower in loaded_towers:
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
		"max_level_unlocked":  0,
		"waves_completed":     0,
		"placement_quiz_done": false,
	}
	_ensure_base_state()
	save_progress()
