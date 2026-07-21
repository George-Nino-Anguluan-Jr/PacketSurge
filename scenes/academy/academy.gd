# Academy.gd
extends Control

# ─── NODE REFERENCES ───────────────────────────────────
@onready var menu_btn: Button = $TopBar/TopBarLayout/MenuBtn
@onready var back_btn: Button              = $TopBar/TopBarLayout/BackBtn
@onready var scene_title: Label            = $TopBar/TopBarLayout/SceneTitle
@onready var progress_label: Label         = $TopBar/TopBarLayout/ProgressLabel
@onready var topic_list_python: VBoxContainer = $ContentArea/Sidebar/ScrollContainer/SidebarLayout/PythonSection/TopicList_Python
@onready var topic_list_ds: VBoxContainer     = $ContentArea/Sidebar/ScrollContainer/SidebarLayout/DSSection/TopicList_DS
@onready var topic_list_sort: VBoxContainer   = $ContentArea/Sidebar/ScrollContainer/SidebarLayout/SortSection/TopicList_Sort
@onready var topic_list_search: VBoxContainer = $ContentArea/Sidebar/ScrollContainer/SidebarLayout/SearchSection/TopicList_Search
@onready var lesson_title: Label           = $ContentArea/LessonArea/LessonContainer/LessonHeader/LessonTitle
@onready var lesson_category: Label        = $ContentArea/LessonArea/LessonContainer/LessonHeader/LessonCategory
@onready var step_indicator: HBoxContainer = $ContentArea/LessonArea/LessonContainer/StepIndicator
@onready var step_container: MarginContainer = $ContentArea/LessonArea/LessonContainer/StepContainer
@onready var scroll_area: ScrollContainer  = $ContentArea/LessonArea/LessonContainer/StepContainer/ScrollArea
@onready var scroll_content: VBoxContainer = $ContentArea/LessonArea/LessonContainer/StepContainer/ScrollArea/ScrollContent
@onready var hint_button: Button           = $BottomBar/BottomLayout/HintButton
@onready var back_step_btn: Button         = $BottomBar/BottomLayout/BackStepBtn
@onready var next_step_btn: Button         = $BottomBar/BottomLayout/NextStepBtn

# ─── LESSON DATA ───────────────────────────────────────
var all_lessons: Array[LessonData] = []
var current_lesson: LessonData = null
var current_step: int = 0
var completed_steps: Array[int] = []
var _sidebar_visible: bool = true

var total_steps: int = 8
const STEP_NAMES: Array[String] = [
	"Concept", "Visualization", "Real World",
	"Guided", "Try It", "Code Editor", "Practice", "Recap", "Complete"
]

var topic_buttons: Dictionary = {}
var _lesson_start_time: float = 0.0

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	# Guarantee base state before building UI
	ProgressManager._ensure_base_state()
	
	_load_all_lessons()
	_build_sidebar()
	_setup_buttons()
	_apply_styles()
	_update_progress_label()
	_apply_responsive_layout()
	get_tree().root.size_changed.connect(_apply_responsive_layout)
	SignalBus.topic_unlocked.connect(_on_topic_state_changed)
	SignalBus.topic_mastered.connect(_on_topic_state_changed)

# ─── LOAD LESSONS ──────────────────────────────────────
func _load_all_lessons() -> void:
	var lesson_paths = [
		"res://resources/lessons/lesson_py_variables.tres",
		"res://resources/lessons/lesson_py_lists.tres",
		"res://resources/lessons/lesson_py_loops.tres",
		"res://resources/lessons/lesson_py_conditions.tres",
		"res://resources/lessons/lesson_py_functions.tres",
		"res://resources/lessons/lesson_ds_arrays.tres",
		"res://resources/lessons/lesson_ds_stacks.tres",
		"res://resources/lessons/lesson_ds_queues.tres",
		"res://resources/lessons/lesson_ds_linked_lists.tres",
		"res://resources/lessons/lesson_sort_bubble.tres",
		"res://resources/lessons/lesson_sort_selection.tres",
		"res://resources/lessons/lesson_sort_insertion.tres",
		"res://resources/lessons/lesson_sort_quick.tres",
		"res://resources/lessons/lesson_sort_merge.tres",
		"res://resources/lessons/lesson_sort_counting.tres",
		"res://resources/lessons/lesson_sort_radix.tres",
		"res://resources/lessons/lesson_search_linear.tres",
		"res://resources/lessons/lesson_search_binary.tres",
	]
	for path in lesson_paths:
		if ResourceLoader.exists(path):
			var lesson = load(path) as LessonData
			if lesson:
				all_lessons.append(lesson)

# ─── BUILD SIDEBAR ─────────────────────────────────────
# ─── SIDEBAR STATE ─────────────────────────────────────
var collapsed_groups: Dictionary = {}
var current_lesson_id: String    = ""

# ─── BUILD SIDEBAR ─────────────────────────────────────
func _build_sidebar() -> void:
	for child in topic_list_python.get_children():
		child.queue_free()
	for child in topic_list_ds.get_children():
		child.queue_free()
	for child in topic_list_sort.get_children():
		child.queue_free()
	for child in topic_list_search.get_children():
		child.queue_free()

	# Python Section
	var python_topics = [
		"py_variables", "py_lists", "py_loops",
		"py_conditions", "py_functions"
	]
	for topic_id in python_topics:
		var btn := Button.new()
		btn.text      = _get_topic_display_name(topic_id)
		btn.name      = topic_id
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_style_topic_button(btn, ProgressManager.get_topic_state(topic_id))
		btn.pressed.connect(_on_topic_selected.bind(topic_id))
		topic_list_python.add_child(btn)
		topic_buttons[topic_id] = btn

	# Data Structures Section
	var ds_topics = [
		"ds_arrays", "ds_stacks", "ds_queues", "ds_linked_lists"
	]
	for topic_id in ds_topics:
		var btn := Button.new()
		btn.text      = _get_topic_display_name(topic_id)
		btn.name      = topic_id
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_style_topic_button(btn, ProgressManager.get_topic_state(topic_id))
		btn.pressed.connect(_on_topic_selected.bind(topic_id))
		topic_list_ds.add_child(btn)
		topic_buttons[topic_id] = btn

	# Sorting Section
	var sort_topics = [
		"sort_bubble", "sort_selection", "sort_insertion",
		"sort_quick", "sort_merge", "sort_counting", "sort_radix"
	]
	for topic_id in sort_topics:
		var btn := Button.new()
		btn.text      = _get_topic_display_name(topic_id)
		btn.name      = topic_id
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_style_topic_button(btn, ProgressManager.get_topic_state(topic_id))
		btn.pressed.connect(_on_topic_selected.bind(topic_id))
		topic_list_sort.add_child(btn)
		topic_buttons[topic_id] = btn

	# Searching Section
	var search_topics = [
		"search_linear", "search_binary"
	]
	for topic_id in search_topics:
		var btn := Button.new()
		btn.text      = _get_topic_display_name(topic_id)
		btn.name      = topic_id
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_style_topic_button(btn, ProgressManager.get_topic_state(topic_id))
		btn.pressed.connect(_on_topic_selected.bind(topic_id))
		topic_list_search.add_child(btn)
		topic_buttons[topic_id] = btn

	# Sandbox/Playgrounds Section at the bottom of the sidebar
	var sidebar_layout = $ContentArea/Sidebar/ScrollContainer/SidebarLayout
	var old_sec = sidebar_layout.get_node_or_null("SandboxSection")
	if old_sec:
		old_sec.queue_free()
	var old_sep = sidebar_layout.get_node_or_null("SandboxSeparator")
	if old_sep:
		old_sep.queue_free()
		
	var sep := HSeparator.new()
	sep.name = "SandboxSeparator"
	sidebar_layout.add_child(sep)
	
	var sandbox_section := VBoxContainer.new()
	sandbox_section.name = "SandboxSection"
	sandbox_section.add_theme_constant_override("separation", 4)
	
	var label := Label.new()
	label.text = "PLAYGROUND"
	label.add_theme_color_override("font_color", Color("#4A7FA5"))
	label.add_theme_font_size_override("font_size", 11)
	sandbox_section.add_child(label)
	
	var sandbox_btn := Button.new()
	sandbox_btn.text = "🧪 Open Sandbox"
	sandbox_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_style_topic_button(sandbox_btn, "unlocked")
	sandbox_btn.pressed.connect(func(): GameManager.go_to("sandbox"))
	sandbox_section.add_child(sandbox_btn)
	
	sidebar_layout.add_child(sandbox_section)


func _get_topic_display_name(topic_id: String) -> String:
	var names = {
		"py_variables":    "Variables",
		"py_lists":        "Lists",
		"py_loops":        "Loops",
		"py_conditions":   "Conditions",
		"py_functions":    "Functions",
		"ds_arrays":       "Arrays",
		"ds_stacks":       "Stacks",
		"ds_queues":       "Queues",
		"ds_linked_lists": "Linked Lists",
		"sort_bubble":     "Bubble Sort",
		"sort_selection":  "Selection Sort",
		"sort_insertion":  "Insertion Sort",
		"sort_quick":      "Quick Sort",
		"sort_merge":      "Merge Sort",
		"sort_counting":   "Counting Sort",
		"sort_radix":      "Radix Sort",
		"search_linear":   "Linear Search",
		"search_binary":   "Binary Search",
	}
	return names.get(topic_id, topic_id)

# ─── TOPIC BUTTON STYLES ───────────────────────────────
func _style_topic_button(btn: Button, state: String) -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	style.border_width_left          = 1
	style.border_width_right         = 1
	style.border_width_top           = 1
	style.border_width_bottom        = 1

	match state:
		"locked":
			style.bg_color     = Color("#0A1628")
			style.border_color = Color("#2A3A4A")
			btn.add_theme_color_override("font_color", Color("#2A3A4A"))
			btn.disabled = true
		"unlocked":
			style.bg_color     = Color("#0D2040")
			style.border_color = Color("#00D4FF")
			btn.add_theme_color_override("font_color", Color("#E8F4FD"))
			btn.disabled = false
		"mastered":
			style.bg_color     = Color("#0D2A1A")
			style.border_color = Color("#00FF88")
			btn.add_theme_color_override("font_color", Color("#00FF88"))
			btn.disabled = false

	btn.add_theme_stylebox_override("normal", style)
	btn.custom_minimum_size = Vector2(0, 36)

# ─── TOPIC SELECTED ────────────────────────────────────
func _on_topic_selected(topic_id: String) -> void:
	# Auto close sidebar on mobile after selecting
	if ScreenManager.is_mobile() and _sidebar_visible:
		_toggle_sidebar()

	for lesson in all_lessons:
		if lesson.lesson_id == topic_id:
			_open_lesson(lesson)
			return

func _open_lesson(lesson: LessonData) -> void:
	current_lesson = lesson
	current_step   = 0
	total_steps    = 8 if lesson.challenge_code.is_empty() else 9
	completed_steps.clear()
	_lesson_start_time = Time.get_ticks_msec() / 1000.0
	lesson_title.text = lesson.title

	# Set category label based on lesson_id prefix
	if lesson.lesson_id.begins_with("py_"):
		lesson_category.text = "Python Fundamentals"
	elif lesson.lesson_id.begins_with("ds_"):
		lesson_category.text = "Data Structures"
	elif lesson.lesson_id.begins_with("sort_"):
		lesson_category.text = "Sorting Algorithms"
	elif lesson.lesson_id.begins_with("search_"):
		lesson_category.text = "Searching Algorithms"
	else:
		lesson_category.text = "Lesson"

	_build_step_indicator()
	_show_current_step()
	SignalBus.lesson_started.emit(lesson.lesson_id)
	print("[Academy] Opened lesson: ", lesson.lesson_id)

# ─── STEP INDICATOR ────────────────────────────────────
func _build_step_indicator() -> void:
	for child in step_indicator.get_children():
		child.queue_free()
	for i in range(total_steps):
		var dot   := Panel.new()
		dot.custom_minimum_size = Vector2(24, 6)
		var style := StyleBoxFlat.new()
		style.bg_color               = Color("#00D4FF") if i == 0 else Color("#2A3A4A")
		style.corner_radius_top_left     = 3
		style.corner_radius_top_right    = 3
		style.corner_radius_bottom_left  = 3
		style.corner_radius_bottom_right = 3
		dot.add_theme_stylebox_override("panel", style)
		step_indicator.add_child(dot)

func _update_step_indicator() -> void:
	var dots = step_indicator.get_children()
	for i in range(dots.size()):
		var style := StyleBoxFlat.new()
		style.corner_radius_top_left     = 3
		style.corner_radius_top_right    = 3
		style.corner_radius_bottom_left  = 3
		style.corner_radius_bottom_right = 3
		if i < current_step:
			style.bg_color = Color("#00FF88")
		elif i == current_step:
			style.bg_color = Color("#00D4FF")
		else:
			style.bg_color = Color("#2A3A4A")
		dots[i].add_theme_stylebox_override("panel", style)

# ─── SHOW CURRENT STEP ─────────────────────────────────
func _show_current_step() -> void:
	for child in scroll_content.get_children():
		child.queue_free()
	_update_step_indicator()
	_update_nav_buttons()
	match current_step:
		0: _show_concept_step()
		1: _show_visualization_step()
		2: _show_real_world_step()
		3: _show_guided_step()
		4: _show_block_puzzle_step()
		5: _show_code_editor_step()
		6: _show_practice_step()
		7: _show_recap_step()
		8: _show_complete_step()
	await get_tree().process_frame
	scroll_area.scroll_vertical = 0

# ─── STEP CONTENT ──────────────────────────────────────
func _show_concept_step() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	var title := Label.new()
	title.text = "📖 Concept"
	title.add_theme_color_override("font_color", Color("#00D4FF"))
	title.add_theme_font_size_override("font_size", 16)
	layout.add_child(title)
	layout.add_child(_make_step_label(current_lesson.concept_text))
	scroll_content.add_child(layout)

func _show_visualization_step() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	var title := Label.new()
	title.text = "🎨 Visualization"
	title.add_theme_color_override("font_color", Color("#00D4FF"))
	title.add_theme_font_size_override("font_size", 16)
	layout.add_child(title)
	if current_lesson.visualization_scene != null:
		var viz = current_lesson.visualization_scene.instantiate()
		viz.size_flags_horizontal     = Control.SIZE_EXPAND_FILL
		viz.size_flags_vertical       = Control.SIZE_EXPAND_FILL
		viz.custom_minimum_size       = Vector2(0, 620)
		layout.add_child(viz)
	else:
		var fallback := Label.new()
		fallback.text = "⚙️ Visualization coming soon for this topic."
		fallback.add_theme_color_override("font_color", Color("#4A7FA5"))
		fallback.add_theme_font_size_override("font_size", 14)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		layout.add_child(fallback)
	scroll_content.add_child(layout)

func _show_real_world_step() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	var title := Label.new()
	title.text = "🌐 Real World Example"
	title.add_theme_color_override("font_color", Color("#00D4FF"))
	title.add_theme_font_size_override("font_size", 16)
	layout.add_child(title)
	layout.add_child(_make_step_label(current_lesson.real_world_example))
	scroll_content.add_child(layout)

func _show_guided_step() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	var title := Label.new()
	title.text = "🧭 Guided Example"
	title.add_theme_color_override("font_color", Color("#00D4FF"))
	title.add_theme_font_size_override("font_size", 16)
	layout.add_child(title)
	layout.add_child(_make_step_label(current_lesson.guided_example))
	scroll_content.add_child(layout)

func _show_block_puzzle_step() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)

	var instruction := Label.new()
	instruction.text          = current_lesson.challenge_instruction
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.add_theme_color_override("font_color", Color("#E8F4FD"))
	instruction.add_theme_font_size_override("font_size", 15)
	layout.add_child(instruction)

	_show_block_puzzle(layout)

	scroll_content.add_child(layout)

func _show_code_editor_step() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	if current_lesson.challenge_code.is_empty():
		var label := Label.new()
		label.text = "No coding challenge for this lesson."
		label.add_theme_color_override("font_color", Color("#4A7FA5"))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		layout.add_child(label)
		scroll_content.add_child(layout)
		return
	var instruction := Label.new()
	instruction.text = "Type your code below. Fill in the blanks (___), then press Run to test."
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.add_theme_color_override("font_color", Color("#E8F4FD"))
	instruction.add_theme_font_size_override("font_size", 15)
	layout.add_child(instruction)
	_show_code_editor(layout)
	scroll_content.add_child(layout)

func _show_code_editor(layout: VBoxContainer) -> void:
	var editor := TextEdit.new()
	editor.name = "CodeEditor"
	editor.custom_minimum_size = Vector2(0, 250)
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor.add_theme_color_override("background_color", Color("#0A1628"))
	editor.add_theme_color_override("font_color", Color("#E8F4FD"))
	editor.add_theme_color_override("caret_color", Color("#00D4FF"))
	editor.add_theme_color_override("selection_color", Color("#003366"))
	editor.text = current_lesson.code_template if not current_lesson.code_template.is_empty() else ""
	editor.placeholder_text = "# Write your Python code here"
	layout.add_child(editor)

	var hint_line := Label.new()
	hint_line.text = "💡 Write Python code. Press Run to test, then Check Answer when output matches expected."
	hint_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_line.add_theme_color_override("font_color", Color("#4A7FA5"))
	hint_line.add_theme_font_size_override("font_size", 11)
	layout.add_child(hint_line)

	# Run button
	var run_btn := Button.new()
	run_btn.text = "▶ Run Code"
	run_btn.custom_minimum_size = Vector2(160, 44)
	_style_accent_button(run_btn)
	run_btn.pressed.connect(_on_run_code.bind(editor))
	layout.add_child(run_btn)

	# Check answer button
	var check_btn := Button.new()
	check_btn.text = "✔ Check Answer"
	check_btn.custom_minimum_size = Vector2(160, 44)
	_style_accent_button(check_btn)
	check_btn.pressed.connect(_on_check_code_answer.bind(editor))
	layout.add_child(check_btn)

	# Run output area
	var output_label := Label.new()
	output_label.name = "OutputLabel"
	output_label.text = ""
	output_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	output_label.add_theme_font_size_override("font_size", 13)
	output_label.custom_minimum_size = Vector2(0, 60)
	var output_bg := StyleBoxFlat.new()
	output_bg.bg_color = Color("#080F1E")
	output_bg.border_color = Color("#1A2A3A")
	output_bg.border_width_left = 1
	output_bg.border_width_right = 1
	output_bg.border_width_top = 1
	output_bg.border_width_bottom = 1
	output_bg.corner_radius_top_left = 4
	output_bg.corner_radius_top_right = 4
	output_bg.corner_radius_bottom_left = 4
	output_bg.corner_radius_bottom_right = 4
	output_label.add_theme_stylebox_override("normal", output_bg)
	layout.add_child(output_label)

	var result_label := Label.new()
	result_label.name = "CodeResultLabel"
	result_label.text = ""
	result_label.add_theme_font_size_override("font_size", 14)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(result_label)

func _on_run_code(editor: TextEdit) -> void:
	if editor == null or editor.get_parent() == null:
		return
	var code = editor.text
	var result = PythonTranspiler.run_code(code)
	var parent = editor.get_parent()
	var output_label = parent.get_node_or_null("OutputLabel") as Label
	var result_label = parent.get_node_or_null("CodeResultLabel") as Label
	if output_label:
		if result.success:
			output_label.text = "Output:\n" + result.output if result.output else "Output:\n(no output)"
			output_label.add_theme_color_override("font_color", Color("#00FF88"))
		else:
			output_label.text = "Error:\n" + result.error
			output_label.add_theme_color_override("font_color", Color("#FF3366"))
	if result_label:
		result_label.text = ""

func _on_check_code_answer(editor: TextEdit) -> void:
	if editor == null or editor.get_parent() == null:
		return
	var code = editor.text
	var result = PythonTranspiler.run_code(code)
	var parent = editor.get_parent()
	var result_label = parent.get_node_or_null("CodeResultLabel") as Label
	var output_label = parent.get_node_or_null("OutputLabel") as Label
	if not result.success:
		SoundManager.play_error()
		if output_label:
			output_label.text = "Error:\n" + result.error
			output_label.add_theme_color_override("font_color", Color("#FF3366"))
		if result_label:
			result_label.text = "❌ Your code has errors."
			result_label.add_theme_color_override("font_color", Color("#FF3366"))
		return
	var actual = result.output.strip_edges(false, true)
	var expected = current_lesson.expected_output.strip_edges(false, true)
	var passed = actual == expected
	if result_label:
		if passed:
			SoundManager.play_success()
			result_label.text = "✅ Correct! Output matches expected."
			result_label.add_theme_color_override("font_color", Color("#00FF88"))
			next_step_btn.disabled = false
			if current_step not in completed_steps:
				completed_steps.append(current_step)
		else:
			SoundManager.play_error()
			result_label.text = "❌ Output doesn't match expected."
			result_label.add_theme_color_override("font_color", Color("#FF3366"))
			next_step_btn.disabled = true
	if output_label:
		output_label.text = "Your Output:\n" + actual + "\n\nExpected:\n" + expected
		output_label.add_theme_color_override("font_color", Color("#E8F4FD"))

func _show_block_puzzle(layout: VBoxContainer) -> void:
	var answer_label := Label.new()
	answer_label.text = "Your Answer:"
	answer_label.add_theme_color_override("font_color", Color("#4A7FA5"))
	answer_label.add_theme_font_size_override("font_size", 12)
	layout.add_child(answer_label)

	var answer_area := VBoxContainer.new()
	answer_area.name = "AnswerArea"
	answer_area.add_theme_constant_override("separation", 6)
	answer_area.custom_minimum_size = Vector2(0, 120)
	layout.add_child(answer_area)

	layout.add_child(HSeparator.new())

	var blocks_label := Label.new()
	blocks_label.text = "Available Blocks — tap to add/remove:"
	blocks_label.add_theme_color_override("font_color", Color("#4A7FA5"))
	blocks_label.add_theme_font_size_override("font_size", 12)
	layout.add_child(blocks_label)

	var blocks_area := VBoxContainer.new()
	blocks_area.name = "BlocksArea"
	blocks_area.add_theme_constant_override("separation", 6)
	blocks_area.custom_minimum_size = Vector2(0, 80)
	layout.add_child(blocks_area)

	var shuffled = current_lesson.challenge_blocks.duplicate()
	shuffled.shuffle()
	for block_text in shuffled:
		blocks_area.add_child(_make_code_block(block_text, answer_area, blocks_area))

	var check_btn := Button.new()
	check_btn.text = "✔ Check Answer"
	check_btn.custom_minimum_size = Vector2(160, 44)
	_style_accent_button(check_btn)
	check_btn.pressed.connect(_check_code_answer.bind(answer_area))
	layout.add_child(check_btn)

	var playground_map = {
		"ds_arrays": "res://scenes/sandbox/playgrounds/ArrayPlayground.tscn",
		"ds_stacks": "res://scenes/sandbox/playgrounds/StackPlayground.tscn",
		"ds_queues": "res://scenes/sandbox/playgrounds/QueuePlayground.tscn",
		"ds_linked_lists": "res://scenes/sandbox/playgrounds/LinkedListPlayground.tscn",
	}
	if playground_map.has(current_lesson.lesson_id):
		var sandbox_btn := Button.new()
		sandbox_btn.text = "🔬 Try in Sandbox →"
		sandbox_btn.custom_minimum_size = Vector2(200, 36)
		sandbox_btn.add_theme_font_size_override("font_size", 11)
		sandbox_btn.add_theme_color_override("font_color", Color("#FFB800"))
		sandbox_btn.pressed.connect(func():
			GameManager.go_to("sandbox")
		)
		layout.add_child(sandbox_btn)

	var result_label := Label.new()
	result_label.name = "ResultLabel"
	result_label.text = ""
	result_label.add_theme_font_size_override("font_size", 14)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(result_label)

func _make_code_block(text: String, answer_area: VBoxContainer, blocks_area: VBoxContainer) -> Button:
	var btn := Button.new()
	btn.text      = text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 40)
	btn.set_meta("answer_area", answer_area)
	btn.set_meta("blocks_area", blocks_area)
	btn.set_meta("in_answer",   false)
	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0D2040")
	style.border_color           = Color("#00D4FF")
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color("#00D4FF"))
	btn.add_theme_font_size_override("font_size", 13)
	btn.pressed.connect(_on_block_tapped.bind(btn))
	return btn

func _on_block_tapped(btn: Button) -> void:
	var answer_area: VBoxContainer = btn.get_meta("answer_area")
	var blocks_area: VBoxContainer = btn.get_meta("blocks_area")
	var in_answer: bool            = btn.get_meta("in_answer")
	btn.get_parent().remove_child(btn)
	var style := StyleBoxFlat.new()
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	if in_answer:
		blocks_area.add_child(btn)
		btn.set_meta("in_answer", false)
		style.bg_color     = Color("#0D2040")
		style.border_color = Color("#00D4FF")
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_color_override("font_color", Color("#00D4FF"))
	else:
		answer_area.add_child(btn)
		btn.set_meta("in_answer", true)
		style.bg_color     = Color("#00D4FF")
		style.border_color = Color("#00D4FF")
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_color_override("font_color", Color("#050D1A"))

func _check_code_answer(answer_area: VBoxContainer) -> void:
	var result_label: Label = null
	var parent = answer_area.get_parent()
	while parent != null:
		result_label = parent.get_node_or_null("ResultLabel")
		if result_label:
			break
		parent = parent.get_parent()

	var student_answer: Array[String] = []
	for child in answer_area.get_children():
		if child is Button:
			student_answer.append(child.text)

	var passed = student_answer == current_lesson.correct_sequence

	if result_label:
		if passed:
			SoundManager.play_success()
			result_label.text = "✅ Correct! Well done."
			result_label.add_theme_color_override("font_color", Color("#00FF88"))
			next_step_btn.disabled = false
			if current_step not in completed_steps:
				completed_steps.append(current_step)
		else:
			SoundManager.play_error()
			result_label.text = "❌ Not quite. Check the order and try again."
			result_label.add_theme_color_override("font_color", Color("#FF3366"))
			next_step_btn.disabled = true

func _show_practice_step() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)

	var question := Label.new()
	question.text          = current_lesson.practice_question
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question.add_theme_color_override("font_color", Color("#E8F4FD"))
	question.add_theme_font_size_override("font_size", 16)
	layout.add_child(question)

	for i in range(current_lesson.practice_options.size()):
		var option_btn := Button.new()
		option_btn.text           = current_lesson.practice_options[i]
		option_btn.alignment      = HORIZONTAL_ALIGNMENT_LEFT
		option_btn.custom_minimum_size = Vector2(0, 44)
		_style_option_button(option_btn)
		option_btn.pressed.connect(_check_practice_answer.bind(i, layout))
		layout.add_child(option_btn)

	var explanation := Label.new()
	explanation.name          = "ExplanationLabel"
	explanation.text          = ""
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_font_size_override("font_size", 13)
	layout.add_child(explanation)

	scroll_content.add_child(layout)

func _check_practice_answer(index: int, layout: VBoxContainer) -> void:
	var explanation = layout.get_node_or_null("ExplanationLabel")
	var passed      = index == current_lesson.practice_correct_index
	if passed:
		SoundManager.play_success()
	else:
		SoundManager.play_error()
	if explanation:
		explanation.text = current_lesson.practice_explanation
		if passed:
			explanation.add_theme_color_override("font_color", Color("#00FF88"))
			next_step_btn.disabled = false
			if current_step not in completed_steps:
				completed_steps.append(current_step)
		else:
			explanation.add_theme_color_override("font_color", Color("#FF3366"))
			next_step_btn.disabled = true

func _show_recap_step() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	var title := Label.new()
	title.text = "📝 Recap"
	title.add_theme_color_override("font_color", Color("#00D4FF"))
	title.add_theme_font_size_override("font_size", 16)
	layout.add_child(title)
	layout.add_child(_make_step_label(current_lesson.recap_text))
	scroll_content.add_child(layout)

func _show_complete_step() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)

	var congrats := Label.new()
	congrats.text                 = "🎉 Lesson Complete!"
	congrats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	congrats.add_theme_color_override("font_color", Color("#00FF88"))
	congrats.add_theme_font_size_override("font_size", 28)
	layout.add_child(congrats)

	var message := Label.new()
	message.text = "You've mastered: " + current_lesson.title
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_color_override("font_color", Color("#E8F4FD"))
	message.add_theme_font_size_override("font_size", 16)
	layout.add_child(message)

	# Show unlock info using new PROGRESSION_CHAIN format
	var unlock_label := Label.new()
	unlock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unlock_label.add_theme_color_override("font_color", Color("#00D4FF"))
	unlock_label.add_theme_font_size_override("font_size", 14)
	unlock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if ProgressManager.PROGRESSION_CHAIN.has(current_lesson.lesson_id):
		var chain = ProgressManager.PROGRESSION_CHAIN[current_lesson.lesson_id]
		if chain["type"] == "tower":
			unlock_label.text = "🗼 Tower Unlocked: " + chain["id"]
		elif chain["type"] == "level":
			unlock_label.text = "⚔️ Campaign Level " + str(chain["id"]) + " Unlocked!"
	layout.add_child(unlock_label)

	var complete_btn := Button.new()
	complete_btn.text = "✔ Complete Lesson"
	complete_btn.custom_minimum_size = Vector2(200, 52)
	_style_accent_button(complete_btn)
	complete_btn.pressed.connect(_on_lesson_complete_pressed)
	layout.add_child(complete_btn)

	scroll_content.add_child(layout)

# ─── LESSON COMPLETE ───────────────────────────────────
func _on_lesson_complete_pressed() -> void:
	if current_lesson == null:
		return
	var elapsed = (Time.get_ticks_msec() / 1000.0) - _lesson_start_time
	ProgressManager.add_time_spent(current_lesson.lesson_id, elapsed)
	ProgressManager.on_lesson_completed(current_lesson.lesson_id)
	_refresh_topic_button(current_lesson.lesson_id)
	_update_progress_label()
	print("[Academy] Lesson completed: ", current_lesson.lesson_id)

# ─── NAVIGATION ────────────────────────────────────────
func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	back_step_btn.pressed.connect(_on_back_step_pressed)
	next_step_btn.pressed.connect(_on_next_step_pressed)
	hint_button.pressed.connect(_on_hint_pressed)
	menu_btn.pressed.connect(_toggle_sidebar)

func _on_back_pressed() -> void:
	GameManager.go_to("main_menu")

func _on_back_step_pressed() -> void:
	if current_lesson == null:
		return
	current_step = max(0, current_step - 1)
	_show_current_step()

func _on_next_step_pressed() -> void:
	if current_lesson == null:
		return
	current_step = min(total_steps - 1, current_step + 1)
	_show_current_step()

func _on_hint_pressed() -> void:
	if current_lesson == null:
		SignalBus.hud_message_requested.emit(
			"Select a topic from the sidebar to begin.", 3.0
		)
		return

	var hint = AdaptiveAI.get_hint_for_topic(current_lesson.lesson_id)

	# Add step-specific context to hint
	match current_step:
		4, 5:
			# Block puzzle or Code Editor step — coding hint
			SignalBus.hud_message_requested.emit(
				"💡 Code Hint: " + current_lesson.challenge_hint, 5.0
			)
		6:
			# Practice step — thinking hint
			SignalBus.hud_message_requested.emit(
				"💡 Think: " + hint, 4.0
			)
		_:
			# General concept hint
			SignalBus.hud_message_requested.emit(
				"💡 " + hint, 4.0
			)

	print("[Academy] Hint shown for step: ", current_step)

func _update_nav_buttons() -> void:
	if current_lesson == null:
		back_step_btn.disabled = true
		next_step_btn.disabled = true
		return
	back_step_btn.disabled = current_step == 0
	if current_step == 4 or current_step == 5 or current_step == 6:
		next_step_btn.disabled = current_step not in completed_steps
	else:
		next_step_btn.disabled = false
	next_step_btn.text = "Complete →" if current_step == total_steps - 1 else "Next →"

# ─── PROGRESS LABEL ────────────────────────────────────
func _update_progress_label() -> void:
	var mastered := 0
	for topic_id in ProgressManager.topic_states:
		if ProgressManager.topic_states[topic_id] == "mastered":
			mastered += 1
	progress_label.text = str(mastered) + " / 18 Mastered"

# ─── SIDEBAR REFRESH ───────────────────────────────────
func _on_topic_state_changed(_id: String) -> void:
	_refresh_all_topic_buttons()
	_update_progress_label()

func _refresh_all_topic_buttons() -> void:
	for topic_id in topic_buttons:
		_refresh_topic_button(topic_id)

func _refresh_topic_button(topic_id: String) -> void:
	if topic_buttons.has(topic_id):
		var btn   = topic_buttons[topic_id]
		var state = ProgressManager.get_topic_state(topic_id)
		_style_topic_button(btn, state)

# ─── STYLE HELPERS ─────────────────────────────────────
func _make_step_label(text: String) -> Label:
	var label := Label.new()
	label.text           = text
	label.autowrap_mode  = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color("#E8F4FD"))
	label.add_theme_font_size_override("font_size", 15)
	return label

func _style_accent_button(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#00D4FF")
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color("#050D1A"))
	btn.add_theme_font_size_override("font_size", 15)

func _style_option_button(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = Color("#00D4FF")
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color("#E8F4FD"))

func _apply_styles() -> void:
	var top_style := StyleBoxFlat.new()
	top_style.bg_color          = Color("#0A1628")
	top_style.border_color      = Color("#00D4FF")
	top_style.border_width_bottom = 1
	$TopBar.add_theme_stylebox_override("panel", top_style)

	var side_style := StyleBoxFlat.new()
	side_style.bg_color         = Color("#080F1E")
	side_style.border_color     = Color("#0D2040")
	side_style.border_width_right = 1
	$ContentArea/Sidebar.add_theme_stylebox_override("panel", side_style)

	var bottom_style := StyleBoxFlat.new()
	bottom_style.bg_color       = Color("#0A1628")
	bottom_style.border_color   = Color("#00D4FF")
	bottom_style.border_width_top = 1
	$BottomBar.add_theme_stylebox_override("panel", bottom_style)

	var back_style := StyleBoxFlat.new()
	back_style.bg_color               = Color("#0A1628")
	back_style.border_color           = Color("#00D4FF")
	back_style.border_width_left      = 1
	back_style.border_width_right     = 1
	back_style.border_width_top       = 1
	back_style.border_width_bottom    = 1
	back_style.corner_radius_top_left     = 4
	back_style.corner_radius_top_right    = 4
	back_style.corner_radius_bottom_left  = 4
	back_style.corner_radius_bottom_right = 4
	back_btn.add_theme_stylebox_override("normal", back_style)
	back_btn.add_theme_color_override("font_color", Color("#00D4FF"))

	for btn in [back_step_btn, next_step_btn]:
		_style_accent_button(btn)

	var hint_style := StyleBoxFlat.new()
	hint_style.bg_color               = Color("#1A1A00")
	hint_style.border_color           = Color("#FFB800")
	hint_style.border_width_left      = 1
	hint_style.border_width_right     = 1
	hint_style.border_width_top       = 1
	hint_style.border_width_bottom    = 1
	hint_style.corner_radius_top_left     = 4
	hint_style.corner_radius_top_right    = 4
	hint_style.corner_radius_bottom_left  = 4
	hint_style.corner_radius_bottom_right = 4
	hint_button.add_theme_stylebox_override("normal", hint_style)
	hint_button.add_theme_color_override("font_color", Color("#FFB800"))
	
	# Style scrollbar in the lesson step area
	var scroll_bar_style := StyleBoxFlat.new()
	scroll_bar_style.bg_color = Color("#0A1628")
	scroll_bar_style.border_color = Color("#1A2A3A")
	scroll_bar_style.border_width_left = 1
	scroll_bar_style.border_width_right = 1
	scroll_bar_style.border_width_top = 1
	scroll_bar_style.border_width_bottom = 1
	scroll_bar_style.corner_radius_top_left = 3
	scroll_bar_style.corner_radius_top_right = 3
	scroll_bar_style.corner_radius_bottom_left = 3
	scroll_bar_style.corner_radius_bottom_right = 3
	var scroll_grabber_style := StyleBoxFlat.new()
	scroll_grabber_style.bg_color = Color("#00D4FF")
	scroll_grabber_style.corner_radius_top_left = 3
	scroll_grabber_style.corner_radius_top_right = 3
	scroll_grabber_style.corner_radius_bottom_left = 3
	scroll_grabber_style.corner_radius_bottom_right = 3
	scroll_area.add_theme_stylebox_override("bg", scroll_bar_style)
	scroll_area.add_theme_stylebox_override("panel", scroll_bar_style)
	var v_sb = scroll_area.get_v_scroll_bar()
	if v_sb:
		v_sb.add_theme_stylebox_override("scroll", scroll_bar_style)
		v_sb.add_theme_stylebox_override("scroll_focus", scroll_bar_style)
		v_sb.add_theme_stylebox_override("grabber", scroll_grabber_style)
		v_sb.add_theme_stylebox_override("grabber_highlight", scroll_grabber_style)
		v_sb.add_theme_stylebox_override("grabber_pressed", scroll_grabber_style)
		v_sb.custom_minimum_size = Vector2(12, 0)
		v_sb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Style menu button
	var menu_style := StyleBoxFlat.new()
	menu_style.bg_color               = Color("#0A1628")
	menu_style.border_color           = Color("#00D4FF")
	menu_style.border_width_left      = 1
	menu_style.border_width_right     = 1
	menu_style.border_width_top       = 1
	menu_style.border_width_bottom    = 1
	menu_style.corner_radius_top_left     = 4
	menu_style.corner_radius_top_right    = 4
	menu_style.corner_radius_bottom_left  = 4
	menu_style.corner_radius_bottom_right = 4
	menu_btn.add_theme_stylebox_override("normal", menu_style)
	menu_btn.add_theme_color_override("font_color", Color("#00D4FF"))
	menu_btn.add_theme_font_size_override("font_size", 18)

# ─── RESPONSIVE ────────────────────────────────────────
func _apply_responsive_layout() -> void:
	if ScreenManager.is_mobile():
		_apply_mobile_layout()
	elif ScreenManager.is_tablet():
		_apply_tablet_layout()
	else:
		_apply_desktop_layout()

func _apply_desktop_layout() -> void:
	# Sidebar always visible on desktop
	$ContentArea/Sidebar.visible              = true
	$ContentArea/Sidebar.custom_minimum_size  = Vector2(220, 0)
	menu_btn.visible                          = false
	_sidebar_visible                          = true
	# Comfortable font sizes
	lesson_title.add_theme_font_size_override("font_size", 28)
	lesson_category.add_theme_font_size_override("font_size", 13)

func _apply_tablet_layout() -> void:
	# Sidebar narrower on tablet
	$ContentArea/Sidebar.visible              = true
	$ContentArea/Sidebar.custom_minimum_size  = Vector2(180, 0)
	menu_btn.visible                          = false
	_sidebar_visible                          = true
	lesson_title.add_theme_font_size_override("font_size", 22)
	lesson_category.add_theme_font_size_override("font_size", 12)

func _apply_mobile_layout() -> void:
	# Sidebar hidden by default on mobile
	$ContentArea/Sidebar.visible              = false
	$ContentArea/Sidebar.custom_minimum_size  = Vector2(200, 0)
	menu_btn.visible                          = true
	_sidebar_visible                          = false
	# Smaller fonts for mobile
	lesson_title.add_theme_font_size_override("font_size", 18)
	lesson_category.add_theme_font_size_override("font_size", 11)
	# Bigger touch targets for buttons
	back_step_btn.custom_minimum_size = Vector2(90, 52)
	next_step_btn.custom_minimum_size = Vector2(90, 52)
	hint_button.custom_minimum_size   = Vector2(80, 52)
	
func _toggle_sidebar() -> void:
	_sidebar_visible = !_sidebar_visible
	$ContentArea/Sidebar.visible = _sidebar_visible
	menu_btn.text = "✕" if _sidebar_visible else "☰"

# ─── ESC KEY ───────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to("main_menu")
