# LevelProgression.gd
# Manages sub-level unlock logic and progression tracking
extends Resource

class_name LevelProgression

# Sub-level configuration: 13 main levels × 3 sub-levels = 39 total
# Sub-level types: 0 = lesson, 1 = practice, 2 = challenge
const SUB_LEVEL_TYPES = ["lesson", "practice", "challenge"]
const SUB_LEVELS_PER_LEVEL = 3
const TOTAL_MAIN_LEVELS = 13
const TOTAL_SUB_LEVELS = TOTAL_MAIN_LEVELS * SUB_LEVELS_PER_LEVEL  # 39

# Progression requirements
const LESSON_COMPLETE_REQUIRED = true
const PRACTICE_MIN_SCORE = 70  # percentage
const CHALLENGE_MIN_SCORE = 80  # percentage

# Pattern type names (matching ChallengeValidator.PatternType enum)
# Using integer values directly to avoid circular dependency issues
const PATTERN_TYPES = {
	"HAS_FOR_LOOP": 0,
	"HAS_WHILE_LOOP": 1,
	"HAS_IF": 2,
	"HAS_ELIF": 3,
	"HAS_ELSE": 4,
	"HAS_LIST": 5,
	"HAS_DICT": 6,
	"HAS_TUPLE": 7,
	"HAS_SET": 8,
	"USES_APPEND": 9,
	"USES_POP": 10,
	"USES_INDEX": 11,
	"USES_RANGE": 12,
	"USES_LEN": 13,
	"USES_ENUMERATE": 14,
	"USES_ZIP": 15,
	"USES_SUM": 16,
	"USES_MAX": 17,
	"USES_MIN": 18,
	"USES_SORTED": 19,
	"USES_REVERSED": 20,
	"USES_IN_OPERATOR": 21,
	"USES_NOT_IN": 22,
	"USES_AND": 23,
	"USES_OR": 24,
	"USES_NOT": 25,
	"VARIABLE_ASSIGNMENT": 26,
	"FUNCTION_DEF": 27,
	"FUNCTION_CALL": 28,
	"RETURN_STATEMENT": 29,
	"CLASS_DEF": 30,
	"TRY_EXCEPT": 31,
	"WITH_STATEMENT": 32,
	"LAMBDA_EXPR": 33,
	"LIST_COMPREHENSION": 34,
	"DICT_COMPREHENSION": 35,
	"SET_COMPREHENSION": 36,
	"GENERATOR_EXPR": 37,
	"CORRECT_SYNTAX": 38,
	"NO_SYNTAX_ERRORS": 39,
	"NO_HARDCODED_ANSWER": 40,
	"USES_SLICE": 41,
	"USES_NEGATIVE_INDEX": 42,
	"USES_MODULO": 43,
	"USES_FLOOR_DIV": 44,
	"USES_POWER": 45,
	"USES_F_STRING": 46,
	"USES_FORMAT": 47,
	"USES_JOIN": 48,
	"USES_SPLIT": 49,
	"USES_STRIP": 50,
	"USES_REPLACE": 51,
	"USES_LOWER": 52,
	"USES_UPPER": 53,
	"USES_ISINSTANCE": 54,
	"USES_TYPE": 55,
	"USES_INT": 56,
	"USES_STR": 57,
	"USES_FLOAT": 58,
	"USES_BOOL": 59,
	"USES_LIST_CTOR": 60,
	"USES_DICT_CTOR": 61,
	"USES_SET_CTOR": 62,
	"USES_TUPLE_CTOR": 63,
}

var _sub_level_data: Dictionary = {}
var _unlocked_sub_levels: Array[int] = [0] as Array[int]  # Start with first sub-level unlocked
var _pattern_type_cache: Dictionary = {}

func _init():
	_initialize_sub_levels()

func _initialize_sub_levels() -> void:
	"""Initialize all 39 sub-levels with their configurations"""
	for main_level in range(1, TOTAL_MAIN_LEVELS + 1):
		for sub_idx in range(SUB_LEVELS_PER_LEVEL):
			var sub_level_id = (main_level - 1) * SUB_LEVELS_PER_LEVEL + sub_idx
			var sub_type = SUB_LEVEL_TYPES[sub_idx]
			
			_sub_level_data[sub_level_id] = {
				"id": sub_level_id,
				"main_level": main_level,
				"sub_index": sub_idx,
				"type": sub_type,
				"title": _generate_title(main_level, sub_type),
				"topic_id": _get_topic_for_level(main_level, sub_type),
				"difficulty": _get_difficulty_for_level(main_level),
				"unlocked": sub_level_id == 0,
				"completed": false,
				"best_score": 0,
				"stars": 0,
				"required_patterns": _get_required_patterns(main_level, sub_type),
				"forbidden_patterns": _get_forbidden_patterns(main_level, sub_type),
			}

func _generate_title(main_level: int, sub_type: String) -> String:
	var type_names = {"lesson": "Lesson", "practice": "Practice", "challenge": "Challenge"}
	return "Level %d: %s" % [main_level, type_names.get(sub_type, sub_type.capitalize())]

func _get_topic_for_level(main_level: int, sub_type: String) -> String:
	"""Map main levels to programming topics"""
	var topics = {
		1: "py_variables",
		2: "py_lists",
		3: "py_loops",
		4: "py_conditions",
		5: "py_functions",
		6: "ds_arrays",
		7: "ds_stacks",
		8: "ds_queues",
		9: "ds_linked_lists",
		10: "sort_bubble",
		11: "sort_selection",
		12: "sort_insertion",
		13: "sort_quick",
	}
	var base_topic = topics.get(main_level, "py_variables")
	
	# For practice/challenge, use same topic but could vary
	return base_topic

func _get_difficulty_for_level(main_level: int) -> String:
	if main_level <= 5:
		return "easy"
	elif main_level <= 9:
		return "medium"
	else:
		return "hard"

func _get_required_patterns(main_level: int, sub_type: String) -> Array[int]:
	"""Get required code patterns for this sub-level"""
	var patterns: Array[int] = []
	
	match sub_type:
		"lesson":
			# Lessons require basic patterns
			patterns.assign([PATTERN_TYPES.VARIABLE_ASSIGNMENT, PATTERN_TYPES.CORRECT_SYNTAX])
		"practice":
			# Practice requires specific patterns based on topic
			patterns = _get_topic_patterns(main_level)
		"challenge":
			# Challenges require optimization patterns
			patterns = _get_topic_patterns(main_level)
			patterns.append(PATTERN_TYPES.NO_HARDCODED_ANSWER)
	
	return patterns

func _get_forbidden_patterns(main_level: int, sub_type: String) -> Array[int]:
	"""Get forbidden patterns (e.g., no hardcoded answers in challenges)"""
	var patterns: Array[int] = []
	if sub_type == "challenge":
		patterns.append(PATTERN_TYPES.NO_HARDCODED_ANSWER)
	return patterns

func _get_topic_patterns(main_level: int) -> Array[int]:
	"""Map topics to required patterns"""
	var topic_patterns = {
		1: [PATTERN_TYPES.VARIABLE_ASSIGNMENT, PATTERN_TYPES.USES_STR, PATTERN_TYPES.USES_INT],  # variables
		2: [PATTERN_TYPES.HAS_LIST, PATTERN_TYPES.USES_APPEND, PATTERN_TYPES.USES_INDEX],  # lists
		3: [PATTERN_TYPES.HAS_FOR_LOOP, PATTERN_TYPES.USES_RANGE],  # loops
		4: [PATTERN_TYPES.HAS_IF, PATTERN_TYPES.USES_AND, PATTERN_TYPES.USES_OR],  # conditions
		5: [PATTERN_TYPES.FUNCTION_DEF, PATTERN_TYPES.RETURN_STATEMENT],  # functions
		6: [PATTERN_TYPES.HAS_LIST, PATTERN_TYPES.USES_LEN, PATTERN_TYPES.USES_MAX],  # arrays
		7: [PATTERN_TYPES.USES_APPEND, PATTERN_TYPES.USES_POP],  # stacks
		8: [PATTERN_TYPES.USES_APPEND, PATTERN_TYPES.USES_INDEX],  # queues
		9: [PATTERN_TYPES.CLASS_DEF, PATTERN_TYPES.VARIABLE_ASSIGNMENT],  # linked lists
		10: [PATTERN_TYPES.HAS_FOR_LOOP, PATTERN_TYPES.HAS_IF],  # bubble sort
		11: [PATTERN_TYPES.HAS_FOR_LOOP, PATTERN_TYPES.USES_MIN],  # selection sort
		12: [PATTERN_TYPES.HAS_WHILE_LOOP, PATTERN_TYPES.USES_INDEX],  # insertion sort
		13: [PATTERN_TYPES.FUNCTION_DEF, PATTERN_TYPES.HAS_FOR_LOOP],  # quick sort
	}
	var raw_patterns = topic_patterns.get(main_level, [PATTERN_TYPES.CORRECT_SYNTAX])
	var patterns: Array[int] = []
	patterns.assign(raw_patterns)
	return patterns

# ─── PUBLIC API ────────────────────────────────────────────

func get_sub_level_data(sub_level_id: int) -> Dictionary:
	return _sub_level_data.get(sub_level_id, {})

func get_sub_level_count() -> int:
	return TOTAL_SUB_LEVELS

func get_main_level_count() -> int:
	return TOTAL_MAIN_LEVELS

func is_unlocked(sub_level_id: int) -> bool:
	return sub_level_id in _unlocked_sub_levels

func is_completed(sub_level_id: int) -> bool:
	var data = _sub_level_data.get(sub_level_id)
	return data.get("completed", false)

func get_unlocked_sub_levels() -> Array[int]:
	return _unlocked_sub_levels.duplicate()

func get_next_unlocked() -> int:
	for i in range(TOTAL_SUB_LEVELS):
		if i in _unlocked_sub_levels and not is_completed(i):
			return i
	return -1

func complete_sub_level(sub_level_id: int, score: int = 100) -> bool:
	var data = _sub_level_data.get(sub_level_id)
	if not data:
		return false
	
	var passed = false
	var sub_type = data.type
	
	match sub_type:
		"lesson":
			passed = true  # Lessons just need completion
		"practice":
			passed = score >= PRACTICE_MIN_SCORE
		"challenge":
			passed = score >= CHALLENGE_MIN_SCORE
	
	if passed:
		data.completed = true
		data.best_score = max(data.best_score, score)
		data.stars = _calculate_stars(score, sub_type)
		_unlock_next_sub_level(sub_level_id)
		return true
	
	return false

func _calculate_stars(score: int, sub_type: String) -> int:
	match sub_type:
		"lesson":
			return 1 if score > 0 else 0
		"practice":
			if score >= 90: return 3
			elif score >= 70: return 2
			else: return 1
		"challenge":
			if score >= 95: return 3
			elif score >= 80: return 2
			else: return 1
	return 0

func _unlock_next_sub_level(completed_id: int) -> void:
	var next_id = completed_id + 1
	if next_id < TOTAL_SUB_LEVELS and next_id not in _unlocked_sub_levels:
		# Check if main level progression allows it
		var current_data = _sub_level_data[completed_id]
		var next_data = _sub_level_data[next_id]
		
		# Always unlock next sub-level in sequence
		_unlocked_sub_levels.append(next_id)
		_sub_level_data[next_id].unlocked = true
		
		# Emit signal for UI update
		SignalBus.emit_signal("sub_level_unlocked", next_id)

func get_main_level_progress(main_level: int) -> Dictionary:
	var completed = 0
	var total = 0
	var stars = 0
	var max_stars = 0
	
	for sub_idx in range(SUB_LEVELS_PER_LEVEL):
		var sub_id = (main_level - 1) * SUB_LEVELS_PER_LEVEL + sub_idx
		var data = _sub_level_data.get(sub_id, {})
		total += 1
		max_stars += 3
		if data.get("completed", false):
			completed += 1
			stars += data.get("stars", 0)
	
	return {
		"main_level": main_level,
		"completed": completed,
		"total": total,
		"progress": float(completed) / float(total) if total > 0 else 0.0,
		"stars": stars,
		"max_stars": max_stars,
		"is_complete": completed == total,
	}

func get_overall_progress() -> Dictionary:
	var total_completed = 0
	var total_stars = 0
	var max_stars = TOTAL_SUB_LEVELS * 3
	
	for sub_id in range(TOTAL_SUB_LEVELS):
		var data = _sub_level_data.get(sub_id, {})
		if data.get("completed", false):
			total_completed += 1
			total_stars += data.get("stars", 0)
	
	return {
		"completed": total_completed,
		"total": TOTAL_SUB_LEVELS,
		"progress": float(total_completed) / float(TOTAL_SUB_LEVELS),
		"stars": total_stars,
		"max_stars": max_stars,
	}

func get_sub_levels_for_main_level(main_level: int) -> Array[Dictionary]:
	var result = []
	for sub_idx in range(SUB_LEVELS_PER_LEVEL):
		var sub_id = (main_level - 1) * SUB_LEVELS_PER_LEVEL + sub_idx
		result.append(get_sub_level_data(sub_id))
	return result

func reset_progress() -> void:
	_unlocked_sub_levels = [0] as Array[int]
	for sub_id in _sub_level_data:
		_sub_level_data[sub_id].unlocked = (sub_id == 0)
		_sub_level_data[sub_id].completed = false
		_sub_level_data[sub_id].best_score = 0
		_sub_level_data[sub_id].stars = 0

# ─── SAVE/LOAD ────────────────────────────────────────────

func get_save_data() -> Dictionary:
	var data = {}
	for sub_id in _sub_level_data:
		var sd = _sub_level_data[sub_id]
		data[str(sub_id)] = {
			"unlocked": sd.unlocked,
			"completed": sd.completed,
			"best_score": sd.best_score,
			"stars": sd.stars,
		}
	return data

func load_save_data(data: Dictionary) -> void:
	for key in data:
		var sub_id = key.to_int()
		if _sub_level_data.has(sub_id):
			var sd = data[key]
			_sub_level_data[sub_id].unlocked = sd.get("unlocked", sub_id == 0)
			_sub_level_data[sub_id].completed = sd.get("completed", false)
			_sub_level_data[sub_id].best_score = sd.get("best_score", 0)
			_sub_level_data[sub_id].stars = sd.get("stars", 0)
			
			if _sub_level_data[sub_id].unlocked and sub_id not in _unlocked_sub_levels:
				_unlocked_sub_levels.append(sub_id)
	
	_unlocked_sub_levels.sort()

# ─── STATIC ACCESS ──────────────────────────────────────────
static var _instance: LevelProgression = null

static func get_instance() -> LevelProgression:
	if _instance == null:
		_instance = LevelProgression.new()
	return _instance
