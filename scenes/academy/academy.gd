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

# ─── HELPERS ───────────────────────────────────────────
func _min_dim() -> float:
	var vp := get_viewport().get_visible_rect().size
	return minf(maxf(vp.x, 320.0), maxf(vp.y, 240.0))

func _fs(ratio: float, floor_v: float, cap_v: float) -> int:
	return int(clampf(_min_dim() * ratio, floor_v, cap_v))

func _is_mobile_view() -> bool:
	return _min_dim() < 600.0

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
	ScreenManager.make_scroll_touch_friendly(scroll_area)
	ScreenManager.make_scroll_touch_friendly($ContentArea/Sidebar/ScrollContainer)
	get_tree().root.size_changed.connect(_apply_responsive_layout)
	_maybe_show_tutorial()
	SignalBus.topic_unlocked.connect(_on_topic_state_changed)
	SignalBus.topic_mastered.connect(_on_topic_state_changed)

# ─── LOAD LESSONS ──────────────────────────────────────
func _load_all_lessons() -> void:
	for path in DataRegistry.lesson_paths:
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

	# Lessons come from DataRegistry (ordered). Sections are read from
	# each lesson's `section` field, so new lessons in existing sections
	# appear automatically without code changes.
	var containers := {
		"Python Basics":    topic_list_python,
		"Data Structures":  topic_list_ds,
		"Sorting":          topic_list_sort,
		"Searching":        topic_list_search,
	}

	for lesson in all_lessons:
		var section := lesson.section
		if section.is_empty():
			section = _section_from_id(lesson.lesson_id)
		var container = containers.get(section, topic_list_ds)
		var topic_id := lesson.lesson_id
		var btn := Button.new()
		btn.text      = _get_topic_display_name(topic_id)
		btn.name      = topic_id
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_style_topic_button(btn, ProgressManager.get_topic_state(topic_id))
		btn.pressed.connect(_on_topic_selected.bind(topic_id))
		container.add_child(btn)
		topic_buttons[topic_id] = btn

func _section_from_id(topic_id: String) -> String:
	if topic_id.begins_with("py_"):
		return "Python Basics"
	if topic_id.begins_with("ds_"):
		return "Data Structures"
	if topic_id.begins_with("sort_"):
		return "Sorting"
	if topic_id.begins_with("search_"):
		return "Searching"
	return "Data Structures"

func _get_topic_display_name(topic_id: String) -> String:
	return GameManager.LESSON_NAMES.get(topic_id, topic_id)

func _category_label(section: String) -> String:
	if section.is_empty():
		return "Lesson"
	match section:
		"Python Basics":
			return "Python Fundamentals"
		"Data Structures":
			return "Data Structures"
		"Sorting":
			return "Sorting Algorithms"
		"Searching":
			return "Searching Algorithms"
	return section

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
	btn.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 18.0))
	btn.custom_minimum_size = Vector2(0, _fs(0.090, 36.0, 48.0))

# ─── TOPIC SELECTED ────────────────────────────────────
func _on_topic_selected(topic_id: String) -> void:
	# Auto close sidebar on mobile after selecting
	if _is_mobile_view() and _sidebar_visible:
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

	# Set category label based on lesson section (from data)
	lesson_category.text = _category_label(lesson.section)

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
		dot.custom_minimum_size = Vector2(_fs(0.058, 16.0, 28.0), _fs(0.013, 4.0, 6.0))
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
	if current_lesson.challenge_code.is_empty():
		match current_step:
			0: _show_concept_step()
			1: _show_visualization_step()
			2: _show_real_world_step()
			3: _show_guided_step()
			4: _show_block_puzzle_step()
			5: _show_practice_step()
			6: _show_recap_step()
			7: _show_complete_step()
	else:
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
	layout.add_theme_constant_override("separation", _fs(0.030, 12.0, 16.0))
	var title := Label.new()
	title.text = "📖 Concept"
	title.add_theme_color_override("font_color", Color("#00D4FF"))
	title.add_theme_font_size_override("font_size", _fs(0.045, 18.0, 22.0))
	layout.add_child(title)
	layout.add_child(_make_step_label(current_lesson.concept_text))
	scroll_content.add_child(layout)

func _show_visualization_step() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", _fs(0.025, 8.0, 12.0))
	var title := Label.new()
	title.text = "🎨 Visualization"
	title.add_theme_color_override("font_color", Color("#00D4FF"))
	title.add_theme_font_size_override("font_size", _fs(0.045, 18.0, 22.0))
	layout.add_child(title)
	if current_lesson.visualization_scene != null:
		var viz = current_lesson.visualization_scene.instantiate()
		viz.size_flags_horizontal     = Control.SIZE_EXPAND_FILL
		viz.size_flags_vertical       = Control.SIZE_EXPAND_FILL
		# Skipped: visualization-specific sizing intentionally left alone
		layout.add_child(viz)
	else:
		var fallback := Label.new()
		fallback.text = "⚙️ Visualization coming soon for this topic."
		fallback.add_theme_color_override("font_color", Color("#4A7FA5"))
		fallback.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		layout.add_child(fallback)
	scroll_content.add_child(layout)

func _show_real_world_step() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", _fs(0.025, 8.0, 12.0))
	var title := Label.new()
	title.text = "🌐 Real World Example"
	title.add_theme_color_override("font_color", Color("#00D4FF"))
	title.add_theme_font_size_override("font_size", _fs(0.045, 18.0, 22.0))
	layout.add_child(title)
	layout.add_child(_make_step_label(current_lesson.real_world_example))
	scroll_content.add_child(layout)

func _show_guided_step() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", _fs(0.025, 8.0, 12.0))
	var title := Label.new()
	title.text = "🧭 Guided Example"
	title.add_theme_color_override("font_color", Color("#00D4FF"))
	title.add_theme_font_size_override("font_size", _fs(0.045, 18.0, 22.0))
	layout.add_child(title)
	layout.add_child(_make_step_label(current_lesson.guided_example))
	scroll_content.add_child(layout)

func _show_block_puzzle_step() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", _fs(0.025, 8.0, 12.0))

	var instruction := Label.new()
	instruction.text          = current_lesson.challenge_instruction
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.add_theme_color_override("font_color", Color("#E8F4FD"))
	instruction.add_theme_font_size_override("font_size", _fs(0.038, 16.0, 20.0))
	layout.add_child(instruction)

	_show_block_puzzle(layout)

	scroll_content.add_child(layout)

func _show_code_editor_step() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", _fs(0.025, 8.0, 12.0))
	if current_lesson.challenge_code.is_empty():
		var label := Label.new()
		label.text = "No coding challenge for this lesson."
		label.add_theme_color_override("font_color", Color("#4A7FA5"))
		label.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		layout.add_child(label)
		scroll_content.add_child(layout)
		return
	var instruction := Label.new()
	instruction.text = "Type your code below. Fill in the blanks (___), then press Run to test."
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.add_theme_color_override("font_color", Color("#E8F4FD"))
	instruction.add_theme_font_size_override("font_size", _fs(0.038, 16.0, 20.0))
	layout.add_child(instruction)
	_show_code_editor(layout)
	scroll_content.add_child(layout)

func _show_code_editor(layout: VBoxContainer) -> void:
	var editor := TextEdit.new()
	editor.name = "CodeEditor"
	editor.custom_minimum_size = Vector2(0, _fs(0.50, 200.0, 280.0))
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor.add_theme_color_override("background_color", Color("#0A1628"))
	editor.add_theme_color_override("font_color", Color("#E8F4FD"))
	editor.add_theme_color_override("caret_color", Color("#00D4FF"))
	editor.add_theme_color_override("selection_color", Color("#003366"))
	editor.add_theme_font_size_override("font_size", _fs(0.034, 16.0, 18.0))
	editor.text = current_lesson.code_template if not current_lesson.code_template.is_empty() else ""
	editor.placeholder_text = "# Write your Python code here"
	layout.add_child(editor)

	var hint_line := Label.new()
	hint_line.text = "💡 Write Python code. Press Run to test, then Check Answer when output matches expected."
	hint_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_line.add_theme_color_override("font_color", Color("#4A7FA5"))
	hint_line.add_theme_font_size_override("font_size", _fs(0.030, 16.0, 16.0))
	layout.add_child(hint_line)

	# Run button
	var run_btn := Button.new()
	run_btn.text = "▶ Run Code"
	run_btn.custom_minimum_size = Vector2(_fs(0.40, 140.0, 180.0), _fs(0.075, 40.0, 48.0))
	_style_accent_button(run_btn)
	run_btn.pressed.connect(_on_run_code.bind(editor))
	layout.add_child(run_btn)

	# Check answer button
	var check_btn := Button.new()
	check_btn.text = "✔ Check Answer"
	check_btn.custom_minimum_size = Vector2(_fs(0.40, 140.0, 180.0), _fs(0.075, 40.0, 48.0))
	_style_accent_button(check_btn)
	check_btn.pressed.connect(_on_check_code_answer.bind(editor))
	layout.add_child(check_btn)

	# Run output area
	var output_label := Label.new()
	output_label.name = "OutputLabel"
	output_label.text = ""
	output_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	output_label.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
	output_label.custom_minimum_size = Vector2(0, _fs(0.12, 48.0, 72.0))
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
	result_label.add_theme_font_size_override("font_size", _fs(0.034, 16.0, 18.0))
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
	answer_label.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
	layout.add_child(answer_label)

	var answer_area := VBoxContainer.new()
	answer_area.name = "AnswerArea"
	answer_area.add_theme_constant_override("separation", _fs(0.012, 4.0, 6.0))
	answer_area.custom_minimum_size = Vector2(0, _fs(0.24, 96.0, 140.0))
	layout.add_child(answer_area)

	layout.add_child(HSeparator.new())

	var blocks_label := Label.new()
	blocks_label.text = "Available Blocks — tap to add/remove:"
	blocks_label.add_theme_color_override("font_color", Color("#4A7FA5"))
	blocks_label.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 16.0))
	layout.add_child(blocks_label)

	var blocks_area := VBoxContainer.new()
	blocks_area.name = "BlocksArea"
	blocks_area.add_theme_constant_override("separation", _fs(0.012, 4.0, 6.0))
	blocks_area.custom_minimum_size = Vector2(0, _fs(0.16, 64.0, 96.0))
	layout.add_child(blocks_area)

	var shuffled = current_lesson.challenge_blocks.duplicate()
	shuffled.shuffle()
	for block_text in shuffled:
		blocks_area.add_child(_make_code_block(block_text, answer_area, blocks_area))

	var check_btn := Button.new()
	check_btn.text = "✔ Check Answer"
	check_btn.custom_minimum_size = Vector2(_fs(0.40, 140.0, 180.0), _fs(0.075, 40.0, 48.0))
	_style_accent_button(check_btn)
	check_btn.pressed.connect(_check_code_answer.bind(answer_area))
	layout.add_child(check_btn)

	var result_label := Label.new()
	result_label.name = "ResultLabel"
	result_label.text = ""
	result_label.add_theme_font_size_override("font_size", _fs(0.034, 16.0, 18.0))
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(result_label)

func _make_code_block(text: String, answer_area: VBoxContainer, blocks_area: VBoxContainer) -> Button:
	var btn := Button.new()
	btn.text      = text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, _fs(0.080, 32.0, 44.0))
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
	btn.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 18.0))
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
	layout.add_theme_constant_override("separation", _fs(0.025, 8.0, 12.0))

	var question := Label.new()
	question.text          = current_lesson.practice_question
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question.add_theme_color_override("font_color", Color("#E8F4FD"))
	question.add_theme_font_size_override("font_size", _fs(0.045, 18.0, 22.0))
	layout.add_child(question)

	for i in range(current_lesson.practice_options.size()):
		var option_btn := Button.new()
		option_btn.text           = current_lesson.practice_options[i]
		option_btn.alignment      = HORIZONTAL_ALIGNMENT_LEFT
		option_btn.custom_minimum_size = Vector2(0, _fs(0.090, 36.0, 48.0))
		_style_option_button(option_btn)
		option_btn.pressed.connect(_check_practice_answer.bind(i, layout))
		layout.add_child(option_btn)

	var explanation := Label.new()
	explanation.name          = "ExplanationLabel"
	explanation.text          = ""
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_font_size_override("font_size", _fs(0.034, 16.0, 18.0))
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
	layout.add_theme_constant_override("separation", _fs(0.025, 8.0, 12.0))
	var title := Label.new()
	title.text = "📝 Recap"
	title.add_theme_color_override("font_color", Color("#00D4FF"))
	title.add_theme_font_size_override("font_size", _fs(0.045, 18.0, 22.0))
	layout.add_child(title)
	layout.add_child(_make_step_label(current_lesson.recap_text))
	scroll_content.add_child(layout)

func _show_complete_step() -> void:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", _fs(0.030, 12.0, 16.0))

	var congrats := Label.new()
	congrats.text                 = "🎉 Lesson Complete!"
	congrats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	congrats.add_theme_color_override("font_color", Color("#00FF88"))
	congrats.add_theme_font_size_override("font_size", _fs(0.075, 26.0, 34.0))
	layout.add_child(congrats)

	var message := Label.new()
	message.text = "You've mastered: " + current_lesson.title
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_color_override("font_color", Color("#E8F4FD"))
	message.add_theme_font_size_override("font_size", _fs(0.045, 18.0, 22.0))
	layout.add_child(message)

	# Show unlock info using new PROGRESSION_CHAIN format
	var unlock_label := Label.new()
	unlock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unlock_label.add_theme_color_override("font_color", Color("#00D4FF"))
	unlock_label.add_theme_font_size_override("font_size", _fs(0.038, 16.0, 18.0))
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
	complete_btn.custom_minimum_size = Vector2(_fs(0.45, 180.0, 220.0), _fs(0.075, 44.0, 52.0))
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
	var needs_completion = current_step == 4 or current_step == 5
	if not current_lesson.challenge_code.is_empty() and current_step == 6:
		needs_completion = true
	if needs_completion:
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
	progress_label.text = str(mastered) + " / " + str(DataRegistry.get_lesson_count()) + " Mastered"

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
	label.add_theme_font_size_override("font_size", _fs(0.038, 16.0, 20.0))
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
	btn.add_theme_font_size_override("font_size", _fs(0.038, 16.0, 18.0))

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
	btn.add_theme_font_size_override("font_size", _fs(0.034, 16.0, 18.0))

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
	back_btn.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 18.0))

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
	hint_button.add_theme_font_size_override("font_size", _fs(0.034, 16.0, 18.0))
	
	# Style scrollbar in the lesson step area
	var scroll_grabber_style := StyleBoxFlat.new()
	scroll_grabber_style.bg_color = Color("#00D4FF")
	scroll_grabber_style.corner_radius_top_left = 3
	scroll_grabber_style.corner_radius_top_right = 3
	scroll_grabber_style.corner_radius_bottom_left = 3
	scroll_grabber_style.corner_radius_bottom_right = 3
	var v_sb = scroll_area.get_v_scroll_bar()
	if v_sb:
		v_sb.add_theme_stylebox_override("grabber", scroll_grabber_style)
		v_sb.add_theme_stylebox_override("grabber_highlight", scroll_grabber_style)
		v_sb.add_theme_stylebox_override("grabber_pressed", scroll_grabber_style)
		v_sb.custom_minimum_size = Vector2(_fs(0.020, 6.0, 10.0), 0)
	
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
	menu_btn.add_theme_font_size_override("font_size", _fs(0.045, 18.0, 22.0))

# ─── RESPONSIVE ────────────────────────────────────────
func _apply_responsive_layout() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var w := maxf(vp.x, 320.0)
	var h := maxf(vp.y, 240.0)
	var min_dim := minf(w, h)

	var top_bar = $TopBar
	var content_area = $ContentArea
	var bottom_bar = $BottomBar
	var sidebar = $ContentArea/Sidebar

	# Fluid TopBar height + offset
	var top_h := clampf(h * 0.065, 52.0, 64.0)
	top_bar.custom_minimum_size = Vector2(0, top_h)
	content_area.offset_top = top_h

	# Fluid BottomBar height + offset
	var bottom_h := clampf(h * 0.080, 56.0, 68.0)
	bottom_bar.custom_minimum_size = Vector2(0, bottom_h)
	content_area.offset_bottom = -bottom_h

	# Fluid typography
	scene_title.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.045, 18.0, 26.0)))
	progress_label.add_theme_font_size_override("font_size", _fs(0.030, 16.0, 18.0))
	lesson_title.add_theme_font_size_override("font_size", int(clampf(min_dim * 0.060, 22.0, 32.0)))
	lesson_category.add_theme_font_size_override("font_size", _fs(0.030, 16.0, 18.0))

	# Fluid button sizes
	var btn_h := clampf(h * 0.080, 44.0, 56.0)
	back_btn.custom_minimum_size = Vector2(clampf(w * 0.18, 80.0, 110.0), btn_h)
	back_step_btn.custom_minimum_size = Vector2(clampf(w * 0.20, 100.0, 130.0), btn_h)
	next_step_btn.custom_minimum_size = Vector2(clampf(w * 0.20, 100.0, 130.0), btn_h)
	hint_button.custom_minimum_size   = Vector2(clampf(w * 0.18, 90.0, 110.0), btn_h)
	menu_btn.custom_minimum_size = Vector2(_fs(0.075, 44.0, 48.0), _fs(0.075, 44.0, 48.0))

	# Fluid sidebar width and visibility
	sidebar.custom_minimum_size = Vector2(clampf(min_dim * 0.32, 180.0, 260.0), 0)

	# Auto-hide sidebar on small screens, show menu button
	if min_dim < 600:
		menu_btn.visible = true
		sidebar.visible  = _sidebar_visible
	else:
		menu_btn.visible = false
		sidebar.visible  = true
		_sidebar_visible = true

func _toggle_sidebar() -> void:
	_sidebar_visible = !_sidebar_visible
	$ContentArea/Sidebar.visible = _sidebar_visible
	menu_btn.text = "✕" if _sidebar_visible else "☰"

# ─── ESC KEY ───────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to("main_menu")

# ─── TUTORIAL ──────────────────────────────────────────
const TutorialOverlay = preload("res://scenes/core/TutorialOverlay.gd")

func _maybe_show_tutorial() -> void:
	if ProgressManager.has_seen_tutorial("academy"):
		return
	await get_tree().process_frame
	var tut = TutorialOverlay.new()
	add_child(tut)
	tut.tutorial_finished.connect(func(): ProgressManager.mark_tutorial_seen("academy"))
	tut.start(_get_academy_tutorial_steps())

func _get_academy_tutorial_steps() -> Array:
	var steps: Array = []
	steps.append({
		"title": "Welcome to the Academy",
		"body": "This is your learning hub, operator!\n\nMaster Python, data structures, sorting, and searching through interactive lessons — no coding experience needed.",
		"force_center": true,
	})
	steps.append({
		"title": "Topics Sidebar",
		"body": "Browse topics organized by category: Python Fundamentals, Data Structures, Sorting, and Searching.\n\nTap any unlocked topic to start learning. Complete lessons to unlock more.",
		"highlight": $ContentArea/Sidebar.get_path(),
	})
	steps.append({
		"title": "Your Progress",
		"body": "Keep an eye on your mastery count here. Every completed lesson unlocks new towers and enemies in Campaign mode.",
		"highlight": progress_label.get_path(),
	})
	steps.append({
		"title": "Lesson Content",
		"body": "Lessons appear here with interactive content, visualizations, code editors, and practice exercises.\n\nEach lesson has 8 steps to guide you from concept to mastery.",
		"highlight": $ContentArea/LessonArea.get_path(),
	})
	steps.append({
		"title": "Step Navigation",
		"body": "Move through lesson steps with Previous and Next. Tap 💡 Hint when you're stuck on a problem — it won't affect your score.",
		"highlight": $BottomBar.get_path(),
	})
	steps.append({
		"title": "Ready to Learn!",
		"body": "That's the tour! Start with Python Fundamentals and work your way up to Sorting and Searching.\n\nGood luck, operator!",
		"force_center": true,
	})
	return steps
