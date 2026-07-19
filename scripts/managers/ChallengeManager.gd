# ChallengeManager.gd
# Event-driven challenge orchestration system
# Listens to game events and triggers appropriate coding challenges
extends Node

class_name ChallengeManager

signal challenge_triggered(challenge: Dictionary)

# ─── CHALLENGE EVENT TYPES ────────────────────────────────
enum ChallengeEventType {
	FIRST_TOWER_PLACEMENT,
	WAVE_START,
	ENEMY_LEAKED,
	TOWER_UPGRADE,
	LOW_RAM,
	LEVEL_COMPLETE,
}

# ─── CHALLENGE TYPES ──────────────────────────────────────
enum ChallengeType {
	FILL_BLANK,
	FIX_SYNTAX,
	PREDICT_PATTERN,
	FIX_BUG,
	OPTIMIZE,
	REFATOR,
	EFFICIENCY,
	MASTERY,
}

# ─── STATE ────────────────────────────────────────────────
var _current_level: int = 1
var _current_sub_level_id: int = 0
var _tower_types_placed: Array[String] = []
var _challenges_triggered_this_level: Dictionary = {}
var _active_challenge: Dictionary = {}
var _challenge_ui: Node = null
var _level_progression: LevelProgression = null
var _challenge_data: ChallengeData = null
var _adaptive_ai: AdaptiveAI = null

# ─── INITIALIZATION ───────────────────────────────────────
func _ready() -> void:
	_level_progression = LevelProgression.get_instance()
	_challenge_data = ChallengeData.get_instance()
	_adaptive_ai = AdaptiveAI
	
	# Connect to game events
	_connect_signals()
	
	print("[ChallengeManager] Initialized")

func _connect_signals() -> void:
	# Tower placement events
	# SignalBus.tower_placed.connect(_on_tower_placed)
	
	# Wave events
	# SignalBus.wave_started.connect(_on_wave_started)
	
	# Enemy events
	# SignalBus.enemy_reached_end.connect(_on_enemy_reached_end)
	
	# Level completion
	# SignalBus.campaign_level_unlocked.connect(_on_level_unlocked)
	
	# Challenge completion (from CodeChallenge UI)
	SignalBus.challenge_completed.connect(_on_challenge_completed)

func initialize_for_level(level_number: int, sub_level_id: int) -> void:
	_current_level = level_number
	_current_sub_level_id = sub_level_id
	_tower_types_placed.clear()
	_challenges_triggered_this_level.clear()
	
	# Get sub-level data
	var sub_level_data = _level_progression.get_sub_level_data(sub_level_id)
	var topic_id = sub_level_data.get("topic_id", "py_variables")
	
	# Pre-load challenges for this topic
	_preload_challenges(topic_id)
	
	print("[ChallengeManager] Initialized for level %d, sub-level %d (topic: %s)" % [level_number, sub_level_id, topic_id])

func _preload_challenges(topic_id: String) -> void:
	# Ensure challenges are loaded
	_challenge_data.get_challenge(topic_id)

# ─── EVENT HANDLERS ───────────────────────────────────────

func _on_tower_placed(tower_id: String, grid_position: Vector2i) -> void:
	# Check if this is the first time placing this tower type
	if tower_id not in _tower_types_placed:
		_tower_types_placed.append(tower_id)
		_trigger_challenge(ChallengeEventType.FIRST_TOWER_PLACEMENT, {"tower_id": tower_id})

func _on_wave_started(wave_number: int) -> void:
	# Trigger challenge on wave 2, 3, etc. (not wave 1)
	if wave_number >= 2:
		_trigger_challenge(ChallengeEventType.WAVE_START, {"wave_number": wave_number})

func _on_enemy_reached_end(enemy_id: String) -> void:
	# Trigger challenge when enemy leaks
	_trigger_challenge(ChallengeEventType.ENEMY_LEAKED, {"enemy_id": enemy_id})

func _on_level_unlocked(level_number: int) -> void:
	# Trigger mastery challenge on level complete
	_trigger_challenge(ChallengeEventType.LEVEL_COMPLETE, {"level_number": level_number})

# ─── CHALLENGE TRIGGERING ─────────────────────────────────

func _trigger_challenge(event_type: ChallengeEventType, context: Dictionary) -> void:
	# Check if we already triggered this event type this level
	var event_key = _event_type_to_string(event_type)
	if _challenges_triggered_this_level.has(event_key):
		# For some events, allow multiple triggers (e.g., ENEMY_LEAKED)
		if event_type != ChallengeEventType.ENEMY_LEAKED:
			return
	
	_challenges_triggered_this_level[event_key] = true
	
	# Get sub-level data
	var sub_level_data = _level_progression.get_sub_level_data(_current_sub_level_id)
	var topic_id = sub_level_data.get("topic_id", "py_variables")
	var sub_type = sub_level_data.get("type", "lesson")
	
	# Determine challenge type based on event, sub-level type, and adaptive AI
	var challenge_type = _determine_challenge_type(event_type, sub_type, topic_id)
	
	# Get a random challenge of this type for the topic
	var challenge = _challenge_data.get_random_challenge(topic_id, challenge_type)
	
	if challenge.is_empty():
		# Fallback: try other challenge types
		challenge = _get_fallback_challenge(topic_id, challenge_type)
	
	if challenge.is_empty():
		print("[ChallengeManager] No challenge found for topic: %s, type: %s" % [topic_id, challenge_type])
		return
	
	# Add context to challenge
	challenge["event_type"] = event_type
	challenge["context"] = context
	challenge["sub_level_id"] = _current_sub_level_id
	
	# Show challenge UI
	_show_challenge_ui(challenge)
	
	# Emit signal
	SignalBus.challenge_started.emit(challenge.get("id", "unknown"), _current_sub_level_id)

func _determine_challenge_type(event_type: ChallengeEventType, sub_type: String, topic_id: String) -> String:
	# Base challenge type from sub-level config
	var sub_level_data = _level_progression.get_sub_level_data(_current_sub_level_id)
	var base_challenge_type = sub_level_data.get("challenge_type", "fill_blank")
	
	# Adaptive AI can override based on performance
	var adaptive_type = _adaptive_ai.get_micro_challenge_type()
	
	# Event-specific overrides
	match event_type:
		ChallengeEventType.FIRST_TOWER_PLACEMENT:
			# Tutorial: always fill_blank for first placement
			if sub_type == "lesson":
				return "fill_blank"
			return base_challenge_type
		
		ChallengeEventType.WAVE_START:
			# Practice/Challenge: fix_syntax or predict_pattern
			if sub_type == "lesson":
				return "fill_blank"
			elif sub_type == "practice":
				return "fix_syntax"
			else:
				return "predict_pattern"
		
		ChallengeEventType.ENEMY_LEAKED:
			# Fix bug or optimize
			if sub_type == "lesson":
				return "fix_syntax"
			elif sub_type == "practice":
				return "fix_bug"
			else:
				return "optimize"
		
		ChallengeEventType.TOWER_UPGRADE:
			# Optimize or refactor
			return "optimize"
		
		ChallengeEventType.LOW_RAM:
			# Efficiency challenge
			return "efficiency"
		
		ChallengeEventType.LEVEL_COMPLETE:
			# Mastery challenge
			return "mastery"
	
	# Default to adaptive or base type
	return adaptive_type if adaptive_type != "fix_syntax" else base_challenge_type

func _get_fallback_challenge(topic_id: String, preferred_type: String) -> Dictionary:
	# Try other challenge types in order of preference
	var fallback_types = ["fill_blank", "fix_syntax", "fix_and_optimize"]
	
	for ctype in fallback_types:
		if ctype == preferred_type:
			continue
		var challenge = _challenge_data.get_random_challenge(topic_id, ctype)
		if not challenge.is_empty():
			return challenge
	
	return {}

# ─── CHALLENGE UI ─────────────────────────────────────────

func _show_challenge_ui(challenge: Dictionary) -> void:
	_active_challenge = challenge
	
	# Pause the game
	get_tree().paused = true
	
	# Load and instance the CodeChallenge scene
	var challenge_scene = preload("res://scenes/placement_quiz/CodeChallenge.tscn")
	_challenge_ui = challenge_scene.instantiate()
	
	# Pass challenge data to the UI
	if _challenge_ui.has_method("set_challenge"):
		_challenge_ui.set_challenge(challenge, _current_sub_level_id)
	
	# Add to scene tree (as overlay)
	get_tree().root.add_child(_challenge_ui)
	
	# Connect completion signal
	_challenge_ui.challenge_completed.connect(_on_challenge_ui_completed)

func _on_challenge_ui_completed(passed: bool, score: int) -> void:
	# Resume game
	get_tree().paused = false
	
	# Clean up UI
	if _challenge_ui:
		_challenge_ui.queue_free()
		_challenge_ui = null
	
	# Record result
	var challenge_id = _active_challenge.get("id", "unknown")
	ProgressManager.record_challenge_attempt(challenge_id, passed)
	
	# Apply rewards if passed
	if passed:
		_apply_challenge_reward(_active_challenge)
	
	# Emit completion signal
	SignalBus.challenge_completed.emit(challenge_id, passed, score)
	
	_active_challenge = {}

func _on_challenge_completed(challenge_id: String, passed: bool, score: int) -> void:
	# This is called from SignalBus when challenge completes
	# The actual UI handling is in _on_challenge_ui_completed
	pass

# ─── REWARDS ──────────────────────────────────────────────

func _apply_challenge_reward(challenge: Dictionary) -> void:
	var event_type = challenge.get("event_type", ChallengeEventType.FIRST_TOWER_PLACEMENT)
	var context = challenge.get("context", {})
	
	match event_type:
		ChallengeEventType.FIRST_TOWER_PLACEMENT:
			# Tower already placed, concept explained via UI
			SignalBus.hud_message_requested.emit("💡 Concept learned! Check the code challenge.", 3.0)
		
		ChallengeEventType.WAVE_START:
			# Bonus RAM
			var ram_bonus = 25
			if has_node("../Managers/RAMManager"):
				get_node("../Managers/RAMManager").earn(ram_bonus)
			SignalBus.hud_message_requested.emit("💾 Challenge passed! +%d RAM" % ram_bonus, 3.0)
		
		ChallengeEventType.ENEMY_LEAKED:
			# Base heal or slow enemies
			if has_node(".."):
				var level = get_node("..")
				if level.has_method("heal_base"):
					level.heal_base(1)
				SignalBus.hud_message_requested.emit("💚 Base healed! Enemies slowed.", 3.0)
		
		ChallengeEventType.TOWER_UPGRADE:
			# Reduced upgrade cost (handled by tower system)
			SignalBus.hud_message_requested.emit("⚡ Upgrade cost reduced!", 3.0)
		
		ChallengeEventType.LOW_RAM:
			# RAM bonus
			if has_node("../Managers/RAMManager"):
				get_node("../Managers/RAMManager").earn(50)
			SignalBus.hud_message_requested.emit("💾 Emergency RAM allocation! +50 RAM", 3.0)
		
		ChallengeEventType.LEVEL_COMPLETE:
			# Cosmetic / leaderboard score
			SignalBus.hud_message_requested.emit("🏆 Mastery challenge complete! Bonus score awarded.", 3.0)

# ─── PUBLIC API ───────────────────────────────────────────

func force_challenge(challenge_type: String, topic_id: String = "") -> void:
	"""Force trigger a specific challenge type (for testing)"""
	if topic_id == "":
		var sub_level_data = _level_progression.get_sub_level_data(_current_sub_level_id)
		topic_id = sub_level_data.get("topic_id", "py_variables")
	
	var challenge = _challenge_data.get_random_challenge(topic_id, challenge_type)
	if not challenge.is_empty():
		challenge["event_type"] = ChallengeEventType.FIRST_TOWER_PLACEMENT
		challenge["context"] = {}
		challenge["sub_level_id"] = _current_sub_level_id
		_show_challenge_ui(challenge)

func get_pending_challenges() -> Array[Dictionary]:
	"""Get list of challenges that could be triggered"""
	var result = []
	var sub_level_data = _level_progression.get_sub_level_data(_current_sub_level_id)
	var topic_id = sub_level_data.get("topic_id", "py_variables")
	
	for event_type in ChallengeEventType:
		var event_key = _event_type_to_string(event_type)
		if event_key not in _challenges_triggered_this_level:
			var ctype = _determine_challenge_type(event_type, sub_level_data.get("type", "lesson"), topic_id)
			var challenge = _challenge_data.get_random_challenge(topic_id, ctype)
			if not challenge.is_empty():
				result.append({
					"event": event_key,
					"challenge_type": ctype,
					"challenge_id": challenge.get("id", ""),
				})
	
	return result

# ─── HELPER FUNCTIONS ─────────────────────────────────────

func _event_type_to_string(event_type: ChallengeEventType) -> String:
	match event_type:
		ChallengeEventType.FIRST_TOWER_PLACEMENT:
			return "FIRST_TOWER_PLACEMENT"
		ChallengeEventType.WAVE_START:
			return "WAVE_START"
		ChallengeEventType.ENEMY_LEAKED:
			return "ENEMY_LEAKED"
		ChallengeEventType.TOWER_UPGRADE:
			return "TOWER_UPGRADE"
		ChallengeEventType.LOW_RAM:
			return "LOW_RAM"
		ChallengeEventType.LEVEL_COMPLETE:
			return "LEVEL_COMPLETE"
	return "UNKNOWN"

# ─── STATIC ACCESS ────────────────────────────────────────
static var _instance: ChallengeManager = null

static func get_instance() -> ChallengeManager:
	if _instance == null:
		_instance = ChallengeManager.new()
	return _instance
