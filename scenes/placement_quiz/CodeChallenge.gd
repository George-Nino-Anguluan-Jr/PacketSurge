# CodeChallenge.gd
# Main script for the code challenge scene
extends Control

signal challenge_completed(passed: bool, score: int)

@onready var title_label = %Title
@onready var sub_level_info = %SubLevelInfo
@onready var progress_bar = %ProgressBar
@onready var prompt_label = %Prompt
@onready var code_editor = %CodeEditor
@onready var hints_area = %HintsArea
@onready var hints_list = %HintsList
@onready var run_button = %RunButton
@onready var submit_button = %SubmitButton
@onready var hint_button = %HintButton
@onready var skip_button = %SkipButton
@onready var result_panel = %ResultPanel
@onready var result_title = %ResultTitle
@onready var result_message = %ResultMessage
@onready var star1 = %Star1
@onready var star2 = %Star2
@onready var star3 = %Star3
@onready var continue_button = %ContinueButton
@onready var retry_button = %RetryButton
@onready var timer_label = %TimerLabel
@onready var error_popup = %ErrorPopup
@onready var success_popup = %SuccessPopup

var current_sub_level_id: int = 0
var current_challenge: Dictionary = {}
var start_time: float = 0.0
var timer_running: bool = false
var hints_shown: bool = false
var challenge_passed: bool = false
var current_score: int = 0
var current_stars: int = 0

func _ready() -> void:
	# Connect signals
	run_button.pressed.connect(_on_run_pressed)
	submit_button.pressed.connect(_on_submit_pressed)
	hint_button.pressed.connect(_on_hint_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	
	# Connect to signals
	SignalBus.sub_level_unlocked.connect(_on_sub_level_unlocked)
	
	# Load sub-level from GameManager or ProgressManager if not already manually set
	if current_challenge.is_empty():
		_load_current_sub_level()
	else:
		var level_progression = LevelProgression.get_instance()
		var sub_level_data = level_progression.get_sub_level_data(current_sub_level_id)
		_setup_ui(sub_level_data, current_challenge)
	
	# Start timer
	start_time = Time.get_ticks_msec() / 1000.0
	timer_running = true

func _process(delta: float) -> void:
	if timer_running:
		var elapsed = Time.get_ticks_msec() / 1000.0 - start_time
		var minutes = int(elapsed / 60)
		var seconds = int(elapsed % 60)
		timer_label.text = "Time: %02d:%02d" % [minutes, seconds]

func _load_current_sub_level() -> void:
	# Get current sub-level from GameManager or ProgressManager
	var level_progression = LevelProgression.get_instance()
	current_sub_level_id = level_progression.get_next_unlocked()
	
	if current_sub_level_id < 0:
		current_sub_level_id = 0
	
	var sub_level_data = level_progression.get_sub_level_data(current_sub_level_id)
	
	# Get challenge from ChallengeData
	var challenge_data = ChallengeData.get_instance()
	var topic_id = sub_level_data.get("topic_id", "py_variables")
	var challenge_type = sub_level_data.get("challenge_type", "fill_blank")
	
	current_challenge = challenge_data.get_random_challenge(topic_id, challenge_type)
	
	if current_challenge.is_empty():
		# Fallback to first challenge of this type
		var challenges = challenge_data.get_challenge_by_type(topic_id, challenge_type)
		if not challenges.is_empty():
			current_challenge = challenges[0]
	
	_setup_ui(sub_level_data, current_challenge)

func _setup_ui(sub_level_data: Dictionary, challenge: Dictionary) -> void:
	title_label.text = "Code Challenge"
	sub_level_info.text = sub_level_data.get("title", "Unknown Level")
	
	var prompt_text = challenge.get("prompt", "Complete the challenge")
	var template = challenge.get("template", "")
	
	if template:
		prompt_label.bbcode_text = "[b]Task:[/b] %s\n\n[b]Template:[/b]\n[code]%s[/code]" % [prompt_text, template]
		code_editor.text = template
	else:
		prompt_label.bbcode_text = "[b]Task:[/b] %s" % prompt_text
		code_editor.text = ""
	
	# Setup hints
	var hints = challenge.get("hints", [])
	if hints.size() > 0:
		var hint_lines = []
		for h in hints:
			hint_lines.append("• %s" % h)
		hints_list.text = "\n".join(hint_lines)
	else:
		hints_list.text = "No hints available"
	
	# Update progress bar
	var level_progression = LevelProgression.get_instance()
	var overall = level_progression.get_overall_progress()
	progress_bar.value = overall.progress
	
	# Reset result panel
	result_panel.visible = false
	challenge_passed = false
	current_score = 0
	current_stars = 0

func _on_run_pressed() -> void:
	var code = code_editor.text
	if code.strip() == "":
		error_popup.dialog_text = "Please write some code first!"
		error_popup.popup_centered()
		return
	
	# Validate syntax only
	var validator = ChallengeValidator.new()
	var result = validator.validate(code, [] as Array[ChallengeValidator.PatternType], [] as Array[ChallengeValidator.PatternType])
	
	if result.syntax_errors.size() > 0:
		error_popup.dialog_text = "Syntax Errors:\n" + "\n".join(result.syntax_errors)
		error_popup.popup_centered()
	else:
		success_popup.dialog_text = "Code runs without syntax errors!\n\n[Note: This is a static check. Full validation happens on Submit.]"
		success_popup.popup_centered()

func _on_submit_pressed() -> void:
	var code = code_editor.text
	if code.strip() == "":
		error_popup.dialog_text = "Please write some code first!"
		error_popup.popup_centered()
		return
	
	# Get required patterns for this sub-level
	var level_progression = LevelProgression.get_instance()
	var sub_level_data = level_progression.get_sub_level_data(current_sub_level_id)
	var required_patterns = sub_level_data.get("required_patterns", [])
	var forbidden_patterns = sub_level_data.get("forbidden_patterns", [])
	
	# Validate with ChallengeValidator
	var validator = ChallengeValidator.new()
	var result = validator.validate(code, required_patterns, forbidden_patterns)
	
	challenge_passed = result.passed
	current_score = int(result.score * 100)
	
	# Calculate stars
	var sub_type = sub_level_data.get("type", "lesson")
	current_stars = _calculate_stars(current_score, sub_type)
	
	# Show result
	_show_result(result, current_stars)
	
	# Record attempt
	ProgressManager.record_challenge_attempt(current_challenge.get("id", "unknown"), result.passed)
	
	# If passed, complete sub-level
	if result.passed:
		level_progression.complete_sub_level(current_sub_level_id, current_score)
		SignalBus.challenge_completed.emit(current_challenge.get("id", "unknown"), true, current_score)
		SignalBus.sub_level_completed.emit(current_sub_level_id, current_score, current_stars)
	else:
		SignalBus.challenge_completed.emit(current_challenge.get("id", "unknown"), false, current_score)
	
	timer_running = false

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

func _show_result(result: ChallengeValidator.ValidationResult, stars: int) -> void:
	result_panel.visible = true
	
	if result.passed:
		result_title.text = "✅ Challenge Passed!"
		result_title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	else:
		result_title.text = "❌ Challenge Failed"
		result_title.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	
	result_message.bbcode_text = result.feedback
	
	# Show stars using text (since texture files don't exist)
	var stars_array = [star1, star2, star3]
	for i in range(stars_array.size()):
		var star = stars_array[i]
		if i < stars:
			star.text = "★"
			star.add_theme_color_override("font_color", Color("#FFD700"))
		else:
			star.text = "☆"
			star.add_theme_color_override("font_color", Color("#666666"))
		star.add_theme_font_size_override("font_size", 32)
	
	# Show appropriate buttons
	continue_button.visible = result.passed
	retry_button.visible = not result.passed

func _on_hint_pressed() -> void:
	hints_shown = not hints_shown
	hints_area.visible = hints_shown
	hint_button.text = "Hide Hint" if hints_shown else "Show Hint"

func _on_skip_pressed() -> void:
	# Skip this challenge (no score)
	timer_running = false
	var level_progression = LevelProgression.get_instance()
	level_progression.complete_sub_level(current_sub_level_id, 0)
	SignalBus.challenge_completed.emit(current_challenge.get("id", "unknown"), false, 0)
	SignalBus.sub_level_completed.emit(current_sub_level_id, 0, 0)
	challenge_completed.emit(false, 0)
	_load_current_sub_level()
	start_time = Time.get_ticks_msec() / 1000.0
	timer_running = true

func _on_continue_pressed() -> void:
	# Load next sub-level
	challenge_completed.emit(true, current_score)
	_load_current_sub_level()
	start_time = Time.get_ticks_msec() / 1000.0
	timer_running = true

func _on_retry_pressed() -> void:
	# Reset and retry same challenge
	result_panel.visible = false
	code_editor.text = current_challenge.get("template", "")
	challenge_passed = false
	current_score = 0
	current_stars = 0
	start_time = Time.get_ticks_msec() / 1000.0
	timer_running = true

func _on_sub_level_unlocked(sub_level_id: int) -> void:
	# Update progress bar
	var level_progression = LevelProgression.get_instance()
	var overall = level_progression.get_overall_progress()
	progress_bar.value = overall.progress

func set_challenge(challenge: Dictionary, sub_level_id: int) -> void:
	"""Set challenge data from ChallengeManager"""
	current_challenge = challenge
	current_sub_level_id = sub_level_id
	
	# Start timer
	start_time = Time.get_ticks_msec() / 1000.0
	timer_running = true
	
	if is_node_ready():
		var level_progression = LevelProgression.get_instance()
		var sub_level_data = level_progression.get_sub_level_data(sub_level_id)
		_setup_ui(sub_level_data, challenge)
		
		# Reset result panel
		result_panel.visible = false
		challenge_passed = false
		current_score = 0
		current_stars = 0
		
		# Update progress bar
		var overall = level_progression.get_overall_progress()
		progress_bar.value = overall.progress
	
	# Emit signal that challenge started
	SignalBus.challenge_started.emit(challenge.get("id", "unknown"), sub_level_id)
