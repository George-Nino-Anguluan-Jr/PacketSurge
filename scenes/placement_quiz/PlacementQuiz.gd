# PlacementQuiz.gd
extends Control

# ─── NODE REFERENCES ───────────────────────────────────
@onready var title_label: Label           = $TopBar/TopBarLayout/TitleLabel
@onready var progress_label: Label        = $TopBar/TopBarLayout/ProgressLabel
@onready var intro_panel: PanelContainer  = $ContentArea/Content/IntroPanel
@onready var quiz_panel: VBoxContainer    = $ContentArea/Content/QuizPanel
@onready var result_panel: VBoxContainer  = $ContentArea/Content/ResultPanel
@onready var question_label: Label        = $ContentArea/Content/QuizPanel/QuestionLabel
@onready var options_container: VBoxContainer = $ContentArea/Content/QuizPanel/OptionsContainer
@onready var feedback_label: Label        = $ContentArea/Content/QuizPanel/FeedbackLabel
@onready var result_icon: Label           = $ContentArea/Content/ResultPanel/ResultIcon
@onready var result_title: Label          = $ContentArea/Content/ResultPanel/ResultTitle
@onready var result_desc: Label           = $ContentArea/Content/ResultPanel/ResultDesc
@onready var continue_btn: Button         = $ContentArea/Content/ResultPanel/ContinueBtn

# ─── QUIZ QUESTIONS ────────────────────────────────────
const QUESTIONS = [
	{
		"question":     "What is the correct way to create a variable in Python?",
		"options":      ["var x = 5", "x = 5", "int x = 5", "let x = 5"],
		"correct":      1,
		"explanation":  "Python uses simple assignment: x = 5. No type declaration needed.",
	},
	{
		"question":     "How do you create an empty list in Python?",
		"options":      ["list = {}", "list = ()", "list = []", "list = array()"],
		"correct":      2,
		"explanation":  "Square brackets [] create an empty list in Python.",
	},
	{
		"question":     "What does this print?\nx = [1, 2, 3]\nprint(x[1])",
		"options":      ["1", "2", "3", "Error"],
		"correct":      1,
		"explanation":  "Lists are 0-indexed. x[1] is the second element: 2.",
	},
	{
		"question":     "Which loop correctly prints numbers 0 to 4?",
		"options":      ["for i in range(5):", "for i in range(1, 5):", "for i in range(4):", "for i from 0 to 4:"],
		"correct":      0,
		"explanation":  "range(5) generates 0, 1, 2, 3, 4 — five numbers starting from 0.",
	},
	{
		"question":     "What does 'if x > 5:' check?",
		"options":      ["If x equals 5", "If x is greater than 5", "If x is less than 5", "If x is not 5"],
		"correct":      1,
		"explanation":  "The > operator checks if the left value is greater than the right.",
	},
	{
		"question":     "How do you define a function in Python?",
		"options":      ["function greet():", "def greet():", "func greet():", "define greet():"],
		"correct":      1,
		"explanation":  "Python uses the 'def' keyword to define functions.",
	},
	{
		"question":     "What does len([1, 2, 3, 4]) return?",
		"options":      ["3", "4", "5", "Error"],
		"correct":      1,
		"explanation":  "len() returns the number of elements. This list has 4 elements.",
	},
	{
		"question":     "How do you add an item to the end of a list?",
		"options":      ["list.add(item)", "list.insert(item)", "list.append(item)", "list.push(item)"],
		"correct":      2,
		"explanation":  "append() adds an item to the end of a Python list.",
	},
	{
		"question":     "What is the output of:\nprint(type(42))",
		"options":      ["<class 'str'>", "<class 'float'>", "<class 'number'>", "<class 'int'>"],
		"correct":      3,
		"explanation":  "42 is an integer. type() returns the data type of a value.",
	},
	{
		"question":     "What does this function return?\ndef add(a, b):\n    return a + b",
		"options":      ["Nothing", "The sum of a and b", "The string 'a + b'", "An error"],
		"correct":      1,
		"explanation":  "The function returns a + b which is the sum of the two parameters.",
	},
]

# ─── STATE ─────────────────────────────────────────────
var current_question: int = 0
var correct_count: int    = 0
var answered: bool        = false
var _last_device: String = ""

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	_apply_styles()
	_show_intro()
	_apply_responsive_layout()
	get_tree().root.size_changed.connect(_apply_responsive_layout)

# ─── INTRO SCREEN ──────────────────────────────────────
func _show_intro() -> void:
	intro_panel.visible  = true
	quiz_panel.visible   = false
	result_panel.visible = false
	progress_label.text  = ""
	_build_intro()

func _build_intro() -> void:
	var content = $ContentArea/Content/IntroPanel/IntroMargin/IntroContent
	for child in content.get_children():
		child.queue_free()

	# Icon
	var icon := Label.new()
	icon.text = "🧠"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 56)
	content.add_child(icon)

	# Title
	var title := Label.new()
	title.text = "Python Knowledge Check"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("#E8F4FD"))
	content.add_child(title)

	# Description
	var desc := Label.new()
		desc.text = "Answer 10 quick questions about Python basics.\n\n" + \
		"Score 80% or higher  →  Skip Python lessons\n" + \
		"Score below 80%  →  Start Academy from the beginning\n\n" + \
		"This takes about 2 minutes."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color("#4A7FA5"))
	content.add_child(desc)

	# Buttons
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)

	var start_btn := Button.new()
	start_btn.text = "▶ START QUIZ"
	start_btn.custom_minimum_size = Vector2(180, 52)
	_style_primary_btn(start_btn)
	start_btn.pressed.connect(_start_quiz)
	btn_row.add_child(start_btn)

	var skip_btn := Button.new()
	skip_btn.text = "Skip — Start from Beginning"
	skip_btn.custom_minimum_size = Vector2(220, 52)
	_style_secondary_btn(skip_btn)
	skip_btn.pressed.connect(_skip_quiz)
	btn_row.add_child(skip_btn)

	content.add_child(btn_row)

# ─── QUIZ SCREEN ───────────────────────────────────────
func _start_quiz() -> void:
	current_question = 0
	correct_count    = 0
	answered         = false
	intro_panel.visible  = false
	quiz_panel.visible   = true
	result_panel.visible = false
	_show_question()

func _show_question() -> void:
	answered               = false
	feedback_label.text    = ""
	feedback_label.visible = false

	var q = QUESTIONS[current_question]
	question_label.text = "Q" + str(current_question + 1) + ".  " + q["question"]
	progress_label.text = str(current_question + 1) + " / " + str(QUESTIONS.size())

	for child in options_container.get_children():
		child.queue_free()

	var letters = ["A", "B", "C", "D"]
	for i in range(q["options"].size()):
		var btn := Button.new()
		btn.text = letters[i] + ")   " + q["options"][i]
		btn.custom_minimum_size  = Vector2(0, 52)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
		_style_option_btn(btn, "default")
		btn.pressed.connect(_on_option_pressed.bind(i))
		options_container.add_child(btn)

func _on_option_pressed(index: int) -> void:
	if answered:
		return
	answered = true

	var q          = QUESTIONS[current_question]
	var correct    = q["correct"]
	var is_correct = index == correct
	var btns       = options_container.get_children()

	if is_correct:
		correct_count += 1
		_style_option_btn(btns[index], "correct")
		feedback_label.add_theme_color_override(
			"font_color", Color("#00FF88")
		)
		feedback_label.text = "✅  Correct!  " + q["explanation"]
	else:
		_style_option_btn(btns[index], "wrong")
		if correct < btns.size():
			_style_option_btn(btns[correct], "correct")
		feedback_label.add_theme_color_override(
			"font_color", Color("#FF3366")
		)
		feedback_label.text = "❌  " + q["explanation"]

	feedback_label.visible = true

	for btn in btns:
		btn.disabled = true

	await get_tree().create_timer(2.2).timeout
	_next_question()

func _next_question() -> void:
	current_question += 1
	if current_question >= QUESTIONS.size():
		_show_result()
	else:
		_show_question()

# ─── RESULT SCREEN ─────────────────────────────────────
func _show_result() -> void:
	quiz_panel.visible   = false
	result_panel.visible = true
	progress_label.text  = ""

	var score_pct = float(correct_count) / float(QUESTIONS.size()) * 100.0
	var passed    = score_pct >= 80.0

	result_icon.add_theme_font_size_override("font_size", 64)

	if passed:
		result_icon.text  = "🎉"
		result_title.text = str(int(score_pct)) + "% — Python Knowledge Confirmed!"
		result_title.add_theme_color_override(
			"font_color", Color("#00FF88")
		)
		result_desc.text = "You scored " + str(correct_count) + " out of " + \
			str(QUESTIONS.size()) + " correct.\n\n" + \
			"Python lessons are now unlocked as optional review."
		continue_btn.text = "▶  Go to Academy"
		# Clear previous connections
		if continue_btn.pressed.is_connected(_on_failed):
			continue_btn.pressed.disconnect(_on_failed)
		if not continue_btn.pressed.is_connected(_on_passed):
			continue_btn.pressed.connect(_on_passed)
	else:
		result_icon.text  = "📚"
		result_title.text = str(int(score_pct)) + "% — Let's Build Your Foundation"
		result_title.add_theme_color_override(
			"font_color", Color("#FFB800")
		)
		result_desc.text = "You scored " + str(correct_count) + " out of " + \
			str(QUESTIONS.size()) + " correct.\n\n" + \
			"That's okay! Complete the Python lessons in Academy\n" + \
			"to build a solid foundation before tackling Campaign."
		continue_btn.text = "▶  Start Academy"
		if continue_btn.pressed.is_connected(_on_passed):
			continue_btn.pressed.disconnect(_on_passed)
		if not continue_btn.pressed.is_connected(_on_failed):
			continue_btn.pressed.connect(_on_failed)

# ─── OUTCOME HANDLERS ──────────────────────────────────
func _on_passed() -> void:
	# Mark all Python lessons as mastered
	var python_lessons = [
		"py_variables", "py_lists", "py_loops",
		"py_conditions", "py_functions"
	]
	for lesson in python_lessons:
		ProgressManager.topic_states[lesson] = "mastered"

	# Unlock ds_arrays (first DSA lesson)
	ProgressManager.topic_states["ds_arrays"] = "unlocked"

	# Mark quiz done
	ProgressManager.campaign_progress["placement_quiz_done"] = true
	ProgressManager.save_progress()

	GameManager.go_to("academy")

func _on_failed() -> void:
	# Lock python lessons, only variables is unlocked but not mastered
	ProgressManager.topic_states["py_variables"] = "unlocked"
	ProgressManager.topic_states["py_lists"] = "locked"
	ProgressManager.topic_states["py_loops"] = "locked"
	ProgressManager.topic_states["py_conditions"] = "locked"
	ProgressManager.topic_states["py_functions"] = "locked"
	ProgressManager.topic_states["ds_arrays"] = "locked"

	ProgressManager.campaign_progress["placement_quiz_done"] = true
	ProgressManager.save_progress()
	GameManager.go_to("academy")

func _skip_quiz() -> void:
	# Lock python lessons, only variables is unlocked but not mastered
	ProgressManager.topic_states["py_variables"] = "unlocked"
	ProgressManager.topic_states["py_lists"] = "locked"
	ProgressManager.topic_states["py_loops"] = "locked"
	ProgressManager.topic_states["py_conditions"] = "locked"
	ProgressManager.topic_states["py_functions"] = "locked"
	ProgressManager.topic_states["ds_arrays"] = "locked"

	ProgressManager.campaign_progress["placement_quiz_done"] = true
	ProgressManager.save_progress()
	GameManager.go_to("academy")

# ─── STYLE HELPERS ─────────────────────────────────────
func _apply_styles() -> void:
	# TopBar
	var top_style := StyleBoxFlat.new()
	top_style.bg_color            = Color("#0A1628")
	top_style.border_color        = Color("#00D4FF")
	top_style.border_width_bottom = 1
	$TopBar.add_theme_stylebox_override("panel", top_style)

	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color("#00D4FF"))

	progress_label.add_theme_font_size_override("font_size", 13)
	progress_label.add_theme_color_override("font_color", Color("#4A7FA5"))

	question_label.add_theme_font_size_override("font_size", 18)
	question_label.add_theme_color_override("font_color", Color("#E8F4FD"))

	feedback_label.add_theme_font_size_override("font_size", 13)

	result_title.add_theme_font_size_override("font_size", 22)
	result_desc.add_theme_font_size_override("font_size", 14)
	result_desc.add_theme_color_override("font_color", Color("#4A7FA5"))

	_style_primary_btn(continue_btn)

	# Intro panel border
	var intro_style := StyleBoxFlat.new()
	intro_style.bg_color               = Color("#0A1628")
	intro_style.border_color           = Color("#00D4FF")
	intro_style.border_width_left      = 1
	intro_style.border_width_right     = 1
	intro_style.border_width_top       = 1
	intro_style.border_width_bottom    = 1
	intro_style.corner_radius_top_left     = 8
	intro_style.corner_radius_top_right    = 8
	intro_style.corner_radius_bottom_left  = 8
	intro_style.corner_radius_bottom_right = 8
	intro_panel.add_theme_stylebox_override("panel", intro_style)

func _style_option_btn(btn: Button, state: String) -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left          = 2
	style.border_width_right         = 2
	style.border_width_top           = 2
	style.border_width_bottom        = 2
	style.content_margin_left        = 16
	style.content_margin_right       = 16
	style.content_margin_top         = 12
	style.content_margin_bottom      = 12

	match state:
		"correct":
			style.bg_color     = Color("#0D2A1A")
			style.border_color = Color("#00FF88")
			btn.add_theme_color_override("font_color", Color("#00FF88"))
		"wrong":
			style.bg_color     = Color("#2A0A0A")
			style.border_color = Color("#FF3366")
			btn.add_theme_color_override("font_color", Color("#FF3366"))
		_:
			style.bg_color     = Color("#0A1628")
			style.border_color = Color("#1A3A5A")
			btn.add_theme_color_override("font_color", Color("#E8F4FD"))

	btn.add_theme_stylebox_override("normal",   style)
	btn.add_theme_stylebox_override("hover",    style)
	btn.add_theme_stylebox_override("pressed",  style)
	btn.add_theme_font_size_override("font_size", 13)

func _style_primary_btn(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color                   = Color("#00D4FF")
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color("#050D1A"))
	btn.add_theme_font_size_override("font_size", 14)

func _style_secondary_btn(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color                   = Color("#0A1628")
	style.border_color               = Color("#4A7FA5")
	style.border_width_left          = 1
	style.border_width_right         = 1
	style.border_width_top           = 1
	style.border_width_bottom        = 1
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color("#4A7FA5"))
	btn.add_theme_font_size_override("font_size", 14)

# ─── RESPONSIVE ────────────────────────────────────────
func _apply_responsive_layout() -> void:
	var content_area = $ContentArea
	var top_bar = $TopBar
	
	if ScreenManager.is_mobile():
		ScreenManager.apply_panel_padding(top_bar, 20)
		content_area.add_theme_constant_override("margin_left", 20)
		content_area.add_theme_constant_override("margin_right", 20)
		content_area.add_theme_constant_override("margin_top", 20)
		content_area.add_theme_constant_override("margin_bottom", 20)
		title_label.add_theme_font_size_override("font_size", 14)
		progress_label.add_theme_font_size_override("font_size", 12)
		question_label.add_theme_font_size_override("font_size", 15)
		result_title.add_theme_font_size_override("font_size", 18)
		result_desc.add_theme_font_size_override("font_size", 13)
		continue_btn.custom_minimum_size = Vector2(180, 48)
		intro_panel.add_theme_constant_override("margin_left", 12)
		intro_panel.add_theme_constant_override("margin_right", 12)
		intro_panel.add_theme_constant_override("margin_top", 12)
		intro_panel.add_theme_constant_override("margin_bottom", 12)
	elif ScreenManager.is_tablet():
		ScreenManager.apply_panel_padding(top_bar, 24)
		content_area.add_theme_constant_override("margin_left", 24)
		content_area.add_theme_constant_override("margin_right", 24)
		content_area.add_theme_constant_override("margin_top", 24)
		content_area.add_theme_constant_override("margin_bottom", 24)
		title_label.add_theme_font_size_override("font_size", 15)
		progress_label.add_theme_font_size_override("font_size", 13)
		question_label.add_theme_font_size_override("font_size", 17)
		result_title.add_theme_font_size_override("font_size", 20)
		result_desc.add_theme_font_size_override("font_size", 14)
		continue_btn.custom_minimum_size = Vector2(200, 50)
		intro_panel.add_theme_constant_override("margin_left", 16)
		intro_panel.add_theme_constant_override("margin_right", 16)
		intro_panel.add_theme_constant_override("margin_top", 16)
		intro_panel.add_theme_constant_override("margin_bottom", 16)
	else:
		title_label.add_theme_font_size_override("font_size", 16)
		progress_label.add_theme_font_size_override("font_size", 13)
		question_label.add_theme_font_size_override("font_size", 18)
		result_title.add_theme_font_size_override("font_size", 22)
		result_desc.add_theme_font_size_override("font_size", 14)
		continue_btn.custom_minimum_size = Vector2(200, 52)
		intro_panel.add_theme_constant_override("margin_left", 24)
		intro_panel.add_theme_constant_override("margin_right", 24)
		intro_panel.add_theme_constant_override("margin_top", 24)
		intro_panel.add_theme_constant_override("margin_bottom", 24)
