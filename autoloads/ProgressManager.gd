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

# ─── SUB-LEVEL PROGRESSION ─────────────────────────────
const SUB_LEVELS_PER_LEVEL = 3
const TOTAL_MAIN_LEVELS = 13
const TOTAL_SUB_LEVELS = TOTAL_MAIN_LEVELS * SUB_LEVELS_PER_LEVEL  # 39

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

# Sub-level progress (39 sub-levels) - synced with LevelProgression
var sub_level_progress: Dictionary = {}

# ─── SUB-LEVEL PROGRESS API ────────────────────────────
func get_sub_level_progress(sub_level_id: int) -> Dictionary:
	"""Get progress data for a specific sub-level"""
	return sub_level_progress.get(str(sub_level_id), {
		"unlocked": sub_level_id == 0,
		"completed": false,
		"best_score": 0,
		"stars": 0,
	})

func is_sub_level_unlocked(sub_level_id: int) -> bool:
	"""Check if a sub-level is unlocked"""
	var prog = get_sub_level_progress(sub_level_id)
	return prog.get("unlocked", sub_level_id == 0)

func is_sub_level_completed(sub_level_id: int) -> bool:
	"""Check if a sub-level is completed"""
	var prog = get_sub_level_progress(sub_level_id)
	return prog.get("completed", false)

func get_sub_level_stars(sub_level_id: int) -> int:
	"""Get stars earned for a sub-level"""
	var prog = get_sub_level_progress(sub_level_id)
	return prog.get("stars", 0)

func get_sub_level_best_score(sub_level_id: int) -> int:
	"""Get best score for a sub-level"""
	var prog = get_sub_level_progress(sub_level_id)
	return prog.get("best_score", 0)

func complete_sub_level(sub_level_id: int, score: int, stars: int) -> void:
	"""Mark a sub-level as completed with score and stars"""
	var key = str(sub_level_id)
	if not sub_level_progress.has(key):
		sub_level_progress[key] = {}
	
	sub_level_progress[key].unlocked = true
	sub_level_progress[key].completed = true
	sub_level_progress[key].best_score = max(sub_level_progress[key].get("best_score", 0), score)
	sub_level_progress[key].stars = max(sub_level_progress[key].get("stars", 0), stars)
	
	# Unlock next sub-level
	var next_id = sub_level_id + 1
	if next_id < TOTAL_SUB_LEVELS:
		var next_key = str(next_id)
		if not sub_level_progress.has(next_key):
			sub_level_progress[next_key] = {}
		sub_level_progress[next_key].unlocked = true
	
	# Also update LevelProgression
	var level_progression = LevelProgression.get_instance()
	level_progression.complete_sub_level(sub_level_id, score)
	
	save_progress()

func get_main_level_progress(main_level: int) -> Dictionary:
	"""Get progress for a main level (all 3 sub-levels)"""
	var completed = 0
	var total = 0
	var stars = 0
	var max_stars = 0
	
	for sub_idx in range(SUB_LEVELS_PER_LEVEL):
		var sub_id = (main_level - 1) * SUB_LEVELS_PER_LEVEL + sub_idx
		var prog = get_sub_level_progress(sub_id)
		total += 1
		max_stars += 3
		if prog.get("completed", false):
			completed += 1
			stars += prog.get("stars", 0)
	
	return {
		"main_level": main_level,
		"completed": completed,
		"total": total,
		"progress": float(completed) / float(total) if total > 0 else 0.0,
		"stars": stars,
		"max_stars": max_stars,
		"is_complete": completed == total,
	}

func get_overall_sub_level_progress() -> Dictionary:
	"""Get overall progress across all 39 sub-levels"""
	var total_completed = 0
	var total_stars = 0
	var max_stars = TOTAL_SUB_LEVELS * 3
	
	for sub_id in range(TOTAL_SUB_LEVELS):
		var prog = get_sub_level_progress(sub_id)
		if prog.get("completed", false):
			total_completed += 1
			total_stars += prog.get("stars", 0)
	
	return {
		"completed": total_completed,
		"total": TOTAL_SUB_LEVELS,
		"progress": float(total_completed) / float(TOTAL_SUB_LEVELS),
		"stars": total_stars,
		"max_stars": max_stars,
	}

func sync_with_level_progression() -> void:
	"""Sync sub_level_progress with LevelProgression data"""
	var level_progression = LevelProgression.get_instance()
	var save_data = level_progression.get_save_data()
	
	for key in save_data:
		var sub_id = key.to_int()
		var sd = save_data[key]
		var prog_key = str(sub_id)
		
		if not sub_level_progress.has(prog_key):
			sub_level_progress[prog_key] = {}
		
		sub_level_progress[prog_key].unlocked = sd.get("unlocked", sub_id == 0)
		sub_level_progress[prog_key].completed = sd.get("completed", false)
		sub_level_progress[prog_key].best_score = sd.get("best_score", 0)
		sub_level_progress[prog_key].stars = sd.get("stars", 0)
	
	save_progress()

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
