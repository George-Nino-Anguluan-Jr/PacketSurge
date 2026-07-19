# AdaptiveAI.gd
# Watches student performance and adjusts difficulty automatically
extends Node

# ─── CURRENT DIFFICULTY ────────────────────────────────
enum DifficultyLevel { EASY, NORMAL, HARD }
var current_difficulty: DifficultyLevel = DifficultyLevel.NORMAL

# ─── EVALUATE A SPECIFIC TOPIC ─────────────────────────
func evaluate_topic(topic_id: String) -> String:
	var state = ProgressManager.topic_states.get(topic_id, "locked")
	if state == "locked":
		return "struggling"
	elif state == "mastered":
		return "excelling"
	return "normal"

# ─── OVERALL PERFORMANCE (for campaign difficulty) ─────
func evaluate_overall() -> String:
	var states = ProgressManager.topic_states
	var struggling_count := 0
	var excelling_count  := 0
	var total            := 0

	for topic_id in states:
		if states[topic_id] == "mastered":
			total += 1
			var perf = evaluate_topic(topic_id)
			if perf == "struggling": struggling_count += 1
			elif perf == "excelling": excelling_count += 1

	if total == 0:
		return "normal"
	if struggling_count > total * 0.4:   # 40%+ topics struggling
		return "struggling"
	if excelling_count > total * 0.6:    # 60%+ topics excelling
		return "excelling"
	return "normal"

# ─── WAVE DIFFICULTY MODIFIER ──────────────────────────
func get_wave_modifier() -> float:
	match evaluate_overall():
		"struggling": return 0.7   # fewer/slower enemies
		"excelling":  return 1.35  # more/faster enemies
		_:            return 1.0

# ─── HINT SYSTEM ───────────────────────────────────────
func should_show_hint(topic_id: String) -> bool:
	return evaluate_topic(topic_id) == "struggling"

func get_hint_for_topic(topic_id: String) -> String:
	var hints = {
		"py_variables": "A variable is like a labeled box. You put a value in, and refer to it by name.",
		"py_lists":     "A list holds multiple values in order. Use [] brackets and index from 0.",
		"py_loops":     "A for loop repeats code. Try: for i in range(5): print(i)",
		"ds_arrays":    "Arrays store items in sequence. Access them with index numbers starting at 0.",
		"ds_stacks":    "A stack is Last In, First Out — like a stack of plates.",
		"ds_queues":    "A queue is First In, First Out — like a line at a counter.",
	}
	return hints.get(topic_id, "Review the concept explanation and try the example again.")

func record_level_performance(topic_id: String, grade: String, score: int, elapsed: float) -> void:
	if topic_id.is_empty():
		return
	match grade:
		"A", "B":
			ProgressManager.set_topic_state(topic_id, "mastered")
		"C", "D":
			if ProgressManager.topic_states.get(topic_id) != "mastered":
				ProgressManager.set_topic_state(topic_id, "practice")
		"F", _:
			ProgressManager.set_topic_state(topic_id, "struggling")
	current_difficulty = _recalc_difficulty()

func _recalc_difficulty() -> DifficultyLevel:
	match evaluate_overall():
		"struggling": return DifficultyLevel.EASY
		"excelling":  return DifficultyLevel.HARD
		_:            return DifficultyLevel.NORMAL


