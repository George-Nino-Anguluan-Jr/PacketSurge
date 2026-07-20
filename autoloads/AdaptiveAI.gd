# AdaptiveAI.gd
# Uses a trained ML model to set difficulty based on player progress
extends Node

var _ml_model: Node = null

func _ready() -> void:
	_ml_model = preload("res://autoloads/MLModel.gd").new()
	add_child(_ml_model)
	var ok = _ml_model.load_model("res://models/adaptive_weights.json")
	if not ok:
		push_warning("AdaptiveAI: ML model not loaded, using fallback")


# ─── COLLECT FEATURES ───────────────────────────────────
func _collect_features() -> Array:
	var states = ProgressManager.topic_states
	var total_topics = ProgressManager.ALL_LESSONS.size()
	var mastered = 0
	var struggling = 0
	for tid in states:
		var s = states[tid]
		if s == "mastered": mastered += 1
		if s == "struggling": struggling += 1

	var cp = ProgressManager.campaign_progress
	var levels_done = float(cp.get("waves_completed", 0))
	var max_level = float(cp.get("max_level_unlocked", 0))
	var star_map = cp.get("level_stars", {})
	var total_stars = 0
	var star_count = 0
	for _k in star_map:
		total_stars += star_map[_k]
		star_count += 1
	var avg_stars = float(total_stars) / max(1, star_count)

	var towers_unlocked = ProgressManager.unlocked_towers.size()

	return [
		float(mastered) / float(max(1, total_topics)),           # 0: topics mastered ratio
		float(struggling) / float(max(1, total_topics)),         # 1: topics struggling ratio
		levels_done / 13.0,                                      # 2: levels completed
		avg_stars / 3.0,                                         # 3: average stars
		0.0,                                                     # 4: level stars (set per-level)
		float(towers_unlocked) / 13.0,                           # 5: unlocked towers
		max_level / 13.0,                                        # 6: max level unlocked
		levels_done / 13.0,                                      # 7: waves done
	]


# ─── WAVE DIFFICULTY MODIFIER ──────────────────────────
func get_wave_modifier(level_number: int = -1) -> float:
	if _ml_model == null or not _ml_model._loaded:
		return _fallback_modifier()

	var features = _collect_features()
	if level_number > 0:
		var star_map = ProgressManager.campaign_progress.get("level_stars", {})
		var lvl_stars = float(star_map.get(level_number, 0))
		features[4] = lvl_stars / 3.0

	var raw = _ml_model.predict(features)
	# raw is 0-1, scale to 0.4-1.6 difficulty range
	var modifier = 0.4 + raw * 1.2
	return modifier


# ─── FALLBACK (rule-based) ──────────────────────────────
func _fallback_modifier() -> float:
	var states = ProgressManager.topic_states
	var struggling_count = 0
	var excelling_count = 0
	var total = 0
	for tid in states:
		var s = states[tid]
		if s == "mastered":
			total += 1
		if s == "struggling":
			struggling_count += 1
		elif s == "mastered":
			excelling_count += 1
	if total == 0:
		return 1.0
	if struggling_count > total * 0.4:
		return 0.7
	if excelling_count > total * 0.6:
		return 1.35
	return 1.0


# ─── HINT SYSTEM ───────────────────────────────────────
func should_show_hint(topic_id: String) -> bool:
	return ProgressManager.topic_states.get(topic_id) == "struggling"

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
