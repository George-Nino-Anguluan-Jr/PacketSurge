# ProgressManager.gd
extends Node

# ─── PROGRESSION DATA (derived from resources/lessons/*.tres) ──────
# These used to be hardcoded constants. They are now built at startup
# from LessonData resources, so editing/adding a lesson .tres file
# updates progression everywhere without touching code. The public
# shape (dictionaries keyed like the old consts) is unchanged so all
# existing consumers keep working.
static var PROGRESSION_CHAIN: Dictionary     = {}
static var LEVEL_UNLOCKS_LESSON: Dictionary  = {}
static var ALL_LESSONS: Array[String]         = []

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
var activity_accuracy: Dictionary    = {}  # key -> {"correct": int, "total": int, "retries": int}
var ram_efficiency_total: float     = 0.0
var ram_efficiency_count: int       = 0

# ─── STARTUP ───────────────────────────────────────────
func _ready() -> void:
	_build_progression_data()
	load_progress()
	_ensure_base_state()

func _build_progression_data() -> void:
	ALL_LESSONS = DataRegistry.get_lesson_ids()
	PROGRESSION_CHAIN = {}
	LEVEL_UNLOCKS_LESSON = {}
	for lesson in DataRegistry.lessons:
		if lesson.unlocks_tower == "" and lesson.unlocks_level <= 0:
			continue
		var entry := {
			"id":       lesson.unlocks_tower,
			"level_id": lesson.unlocks_level,
		}
		var has_tower := lesson.unlocks_tower != ""
		var has_level := lesson.unlocks_level > 0
		entry["type"] = "both" if has_tower and has_level \
			else ("tower" if has_tower else "level")
		PROGRESSION_CHAIN[lesson.lesson_id] = entry
		if lesson.unlocks_level > 1:
			LEVEL_UNLOCKS_LESSON[lesson.unlocks_level - 1] = lesson.lesson_id

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
	# Sequential unlocking: each lesson unlocks when the previous one
	# (in DataRegistry order) is mastered. Lessons that also unlock a
	# campaign level additionally require enough waves completed.
	var waves_done = campaign_progress.get("waves_completed", 0)
	for i in range(1, ALL_LESSONS.size()):
		var lesson_id: String = ALL_LESSONS[i]
		if get_topic_state(ALL_LESSONS[i - 1]) != "mastered":
			continue
		var entry = PROGRESSION_CHAIN.get(lesson_id)
		if entry and int(entry.get("level_id", 0)) > 0 \
				and waves_done < int(entry["level_id"]) - 1:
			continue
		unlock_topic(lesson_id)

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

# ─── RAM EFFICIENCY TRACKING ───────────────────────────
func record_ram_efficiency(efficiency: float) -> void:
	ram_efficiency_total += clamp(efficiency, 0.0, 1.0)
	ram_efficiency_count += 1
	save_progress()

func get_avg_ram_efficiency() -> float:
	if ram_efficiency_count <= 0:
		return 0.0
	return ram_efficiency_total / float(ram_efficiency_count)

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

# ─── BULK UNLOCK (DEBUG / COMMAND PANEL) ────────────────
func unlock_all_towers() -> Array[String]:
	var unlocked: Array[String] = []
	for tower_id in GameManager.TOWER_DEFINITIONS.keys():
		if tower_id not in unlocked_towers:
			unlocked_towers.append(tower_id)
			unlocked.append(tower_id)
	if unlocked.size() > 0:
		save_progress()
	return unlocked

func unlock_all_levels() -> Array[int]:
	var unlocked: Array[int] = []
	var total = DataRegistry.get_level_count()
	for i in range(1, total + 1):
		if not is_level_unlocked(i):
			unlock_campaign_level(i)
			unlocked.append(i)
	if unlocked.size() > 0:
		save_progress()
	return unlocked

func unlock_everything() -> Dictionary:
	var towers = unlock_all_towers()
	var levels = unlock_all_levels()
	for lesson_id in ALL_LESSONS:
		if get_topic_state(lesson_id) == "locked":
			topic_states[lesson_id] = "unlocked"
	save_progress()
	return {"towers": towers, "levels": levels}

func master_lesson(lesson_id: String) -> bool:
	if lesson_id not in ALL_LESSONS:
		return false
	mark_mastered(lesson_id)
	if PROGRESSION_CHAIN.has(lesson_id):
		var chain = PROGRESSION_CHAIN[lesson_id]
		if chain["type"] == "tower" or chain["type"] == "both":
			var tower_id = chain["id"]
			unlock_tower(tower_id)
			SignalBus.tower_unlocked.emit(tower_id)
		if chain["type"] == "level" or chain["type"] == "both":
			var level_num = chain.get("level_id", chain.get("id"))
			unlock_campaign_level(level_num)
	check_all_unlocks()
	save_progress()
	return true

func master_all_lessons() -> Array[String]:
	var mastered: Array[String] = []
	for lesson_id in ALL_LESSONS:
		if get_topic_state(lesson_id) != "mastered":
			master_lesson(lesson_id)
			mastered.append(lesson_id)
	return mastered

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
		"activity_accuracy": activity_accuracy,
		"ram_efficiency_total": ram_efficiency_total,
		"ram_efficiency_count": ram_efficiency_count,
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

	var loaded_accuracy = parsed.get("activity_accuracy", {})
	activity_accuracy = {}
	if loaded_accuracy is Dictionary:
		for key in loaded_accuracy:
			var stats = loaded_accuracy[key]
			if stats is Dictionary:
				activity_accuracy[str(key)] = {
					"correct": int(stats.get("correct", 0)),
					"total": int(stats.get("total", 0)),
					"retries": int(stats.get("retries", 0)),
				}

	ram_efficiency_total = float(parsed.get("ram_efficiency_total", 0.0))
	ram_efficiency_count = int(parsed.get("ram_efficiency_count", 0))

	print("[ProgressManager] Progress loaded.")

func reset_all_progress() -> void:
	# Keep tutorial completion tied to the current account. Clearing it here
	# makes the same player see the tutorial overlays again after each logout/login.
	var saved_tutorials = tutorials_seen.duplicate()
	topic_states        = {}
	time_spent          = {}
	campaign_time       = {}
	unlocked_towers     = []
	new_unlocked_towers = []
	tutorials_seen      = saved_tutorials
	activity_accuracy   = {}
	campaign_progress   = {
		"placement_quiz_done": false,
		"max_level_unlocked":  0,
		"waves_completed":     0,
		"level_stars":        {},
	}
	ram_efficiency_total = 0.0
	ram_efficiency_count = 0
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

func record_activity_result(key: String, correct: int, total: int, retries: int = 0) -> void:
	var stats = activity_accuracy.get(key, {"correct": 0, "total": 0, "retries": 0})
	stats["correct"] = int(stats.get("correct", 0)) + max(0, int(correct))
	stats["total"] = int(stats.get("total", 0)) + max(0, int(total))
	stats["retries"] = int(stats.get("retries", 0)) + max(0, int(retries))
	activity_accuracy[str(key)] = stats
	save_progress()

func get_activity_accuracy(key: String) -> float:
	var stats = activity_accuracy.get(key, {"correct": 0, "total": 0, "retries": 0})
	var total = int(stats.get("total", 0))
	if total <= 0:
		return 0.0
	return float(int(stats.get("correct", 0))) / float(total)
