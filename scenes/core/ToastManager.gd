# ToastManager.gd
extends CanvasLayer

@onready var toast_panel: PanelContainer = $ToastPanel
@onready var toast_icon: Label           = $ToastPanel/ToastLayout/ToastIcon
@onready var toast_text: Label           = $ToastPanel/ToastLayout/ToastText

var _is_showing: bool = false
var _queue: Array     = []
var _active_tween: Tween = null

const SHOWN_OFFSET: float = 16.0
const PANEL_HEIGHT: float = 60.0
const SIDE_MARGIN: float = 16.0

func _ready() -> void:
	_apply_style()
	SignalBus.hud_message_requested.connect(_on_message_requested)
	toast_panel.visible = false
	toast_panel.modulate.a = 0.0
	_set_offsets(SHOWN_OFFSET)

	SignalBus.tower_unlocked.connect(_on_tower_unlocked)
	SignalBus.lesson_unlocked.connect(_on_lesson_unlocked)
	SignalBus.campaign_level_unlocked.connect(_on_level_unlocked)
	SignalBus.topic_mastered.connect(_on_topic_mastered)
	SignalBus.lesson_completed.connect(_on_lesson_completed_redirect)
	SignalBus.level_complete.connect(_on_level_complete_redirect)

func _set_offsets(top: float) -> void:
	toast_panel.set_anchor_and_offset(SIDE_LEFT,   0.0, SIDE_MARGIN)
	toast_panel.set_anchor_and_offset(SIDE_RIGHT,  1.0, -SIDE_MARGIN)
	toast_panel.set_anchor_and_offset(SIDE_TOP,    0.0, top)
	toast_panel.set_anchor_and_offset(SIDE_BOTTOM, 0.0, top + PANEL_HEIGHT)

func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = Color("#00D4FF")
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left    = 16
	style.content_margin_right   = 16
	style.content_margin_top     = 10
	style.content_margin_bottom  = 10
	toast_panel.add_theme_stylebox_override("panel", style)

func _on_message_requested(message: String, duration: float) -> void:
	if _is_showing:
		_interrupt_and_show_toast(message, duration)
		return
	_show_toast(message, duration)

func _show_toast(message: String, duration: float) -> void:
	_is_showing         = true
	toast_text.text     = message
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	_set_offsets(SHOWN_OFFSET)

	if _active_tween:
		_active_tween.kill()

	_active_tween = create_tween()
	_active_tween.set_ease(Tween.EASE_OUT)
	_active_tween.set_trans(Tween.TRANS_CUBIC)
	_active_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.3)
	
	_active_tween.finished.connect(func():
		_start_hide_timer(duration)
	)

func _interrupt_and_show_toast(message: String, duration: float) -> void:
	_queue.clear()
	toast_text.text = message

	if _active_tween:
		_active_tween.kill()

	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	
	# Bump animation: quickly slide up and back down to the SHOWN_OFFSET
	_active_tween.tween_method(_set_offsets, SHOWN_OFFSET - 12.0, SHOWN_OFFSET, 0.25)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK)
	
	# Instantly restore full visibility/opacity
	_active_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.1)

	_active_tween.chain().finished.connect(func():
		_start_hide_timer(duration)
	)

func _start_hide_timer(duration: float) -> void:
	if _active_tween:
		_active_tween.kill()

	_active_tween = create_tween()
	_active_tween.tween_interval(duration)
	_active_tween.finished.connect(_hide_toast)

func _hide_toast() -> void:
	if _active_tween:
		_active_tween.kill()

	_active_tween = create_tween()
	_active_tween.set_ease(Tween.EASE_IN)
	_active_tween.set_trans(Tween.TRANS_CUBIC)
	_active_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.3)
	
	_active_tween.finished.connect(func():
		toast_panel.visible = false
		_is_showing         = false
		
		if _queue.size() > 0:
			var next = _queue.pop_front()
			_show_toast(next["message"], next["duration"])
	)

const TOWER_NAMES = {
	"tower_array":      "Array Tower",
	"tower_stack":      "Stack Tower",
	"tower_queue":      "Queue Tower",
	"tower_linked_list":"Linked Tower",
	"tower_bubble":     "Bubble Tower",
	"tower_selection":  "Selection Tower",
	"tower_insertion":  "Insertion Tower",
	"tower_quick":      "Quick Tower",
	"tower_merge":      "Merge Tower",
	"tower_counting":   "Count Tower",
	"tower_radix":      "Radix Tower",
	"tower_linear":     "Linear Tower",
	"tower_binary":     "Binary Tower",
}

const LESSON_NAMES = {
	"py_variables":   "Python Variables",
	"py_lists":       "Python Lists",
	"py_loops":       "Python Loops",
	"py_conditions":  "Python Conditions",
	"py_functions":   "Python Functions",
	"ds_arrays":      "Arrays (DS)",
	"ds_stacks":      "Stacks (DS)",
	"ds_queues":      "Queues (DS)",
	"ds_linked_lists":"Linked Lists (DS)",
	"sort_bubble":    "Bubble Sort",
	"sort_selection": "Selection Sort",
	"sort_insertion": "Insertion Sort",
	"sort_quick":     "Quick Sort",
	"sort_merge":     "Merge Sort",
	"sort_counting":  "Counting Sort",
	"sort_radix":     "Radix Sort",
	"search_linear":  "Linear Search",
	"search_binary":  "Binary Search",
}

func _on_tower_unlocked(tower_id: String) -> void:
	var name = TOWER_NAMES.get(tower_id, tower_id)
	show_message(name + " unlocked! Equip it in Tower Select.", 3.0, "🔓", "#00FF88")

func _on_lesson_unlocked(lesson_id: String) -> void:
	var name = LESSON_NAMES.get(lesson_id, lesson_id)
	show_message("New lesson: " + name, 3.0, "📘", "#00D4FF")

func _on_level_unlocked(level_number: int) -> void:
	show_message("Campaign Level " + str(level_number) + " unlocked!", 3.0, "🏰", "#FFB800")

func _on_topic_mastered(topic_id: String) -> void:
	var name = LESSON_NAMES.get(topic_id, topic_id)
	show_message("Mastered: " + name + "!", 3.0, "🎉", "#00FF88")

func _on_lesson_completed_redirect(lesson_id: String) -> void:
	var chain = ProgressManager.PROGRESSION_CHAIN.get(lesson_id)
	if not chain:
		return
	if chain.get("type") in ["both", "tower"]:
		var tower_id = chain["id"]
		var tower_name = TOWER_NAMES.get(tower_id, tower_id)
		var level_id = chain.get("level_id", 0)
		if level_id > 0 and ProgressManager.is_level_unlocked(level_id):
			show_redirect(
				tower_name + " unlocked!\nPlay Campaign Level " + str(level_id) + " now?",
				"▶ Play Level " + str(level_id),
				"campaign",
				"🔓", "#00FF88"
			)

func _on_level_complete_redirect(level_number: int, _score: int, _stars: int) -> void:
	var next_lesson = ProgressManager.LEVEL_UNLOCKS_LESSON.get(level_number)
	if not next_lesson:
		return
	var lesson_name = LESSON_NAMES.get(next_lesson, next_lesson)
	if ProgressManager.get_topic_state(next_lesson) == "unlocked":
		show_redirect(
			"Level " + str(level_number) + " complete!\nNew lesson: " + lesson_name + ". Learn now?",
			"📘 Go to Academy",
			"academy",
			"🎓", "#00D4FF"
		)

var _redirect_popup: Control = null

func show_redirect(
		message: String,
		btn_text: String,
		target_scene: String,
		icon: String = "🚀",
		color: String = "#00FF88") -> void:
	if _redirect_popup:
		_redirect_popup.queue_free()

	_redirect_popup = Control.new()
	_redirect_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_redirect_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_redirect_popup)

	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	_redirect_popup.add_child(overlay)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 200)
	card.position = Vector2(0, 0)
	card.set_anchors_preset(Control.PRESET_CENTER)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#0A1628")
	card_style.border_color = Color(color)
	card_style.border_width_left = 2
	card_style.border_width_right = 2
	card_style.border_width_top = 2
	card_style.border_width_bottom = 2
	card_style.corner_radius_top_left = 12
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_left = 12
	card_style.corner_radius_bottom_right = 12
	card.add_theme_stylebox_override("panel", card_style)
	_redirect_popup.add_child(card)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("margin_left", 24)
	layout.add_theme_constant_override("margin_right", 24)
	layout.add_theme_constant_override("margin_top", 24)
	layout.add_theme_constant_override("margin_bottom", 24)
	card.add_child(layout)

	var icon_lbl := Label.new()
	icon_lbl.text = icon
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 36)
	layout.add_child(icon_lbl)

	var msg_lbl := Label.new()
	msg_lbl.text = message
	msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_lbl.add_theme_color_override("font_color", Color("#E8F4FD"))
	msg_lbl.add_theme_font_size_override("font_size", 14)
	layout.add_child(msg_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	layout.add_child(btn_row)

	var go_btn := Button.new()
	go_btn.text = btn_text
	go_btn.custom_minimum_size = Vector2(140, 44)
	go_btn.add_theme_font_size_override("font_size", 14)
	go_btn.pressed.connect(func():
		var temp = _redirect_popup
		_redirect_popup = null
		temp.queue_free()
		GameManager.go_to(target_scene)
	)
	btn_row.add_child(go_btn)

	var later_btn := Button.new()
	later_btn.text = "Later"
	later_btn.custom_minimum_size = Vector2(100, 44)
	later_btn.add_theme_font_size_override("font_size", 12)
	later_btn.add_theme_color_override("font_color", Color("#4A7FA5"))
	later_btn.pressed.connect(func():
		_redirect_popup.queue_free()
		_redirect_popup = null
	)
	btn_row.add_child(later_btn)

func show_message(
		message: String,
		duration: float = 3.0,
		icon: String    = "💡",
		color: String   = "#00D4FF") -> void:
	toast_icon.text = icon
	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = Color(color)
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left    = 16
	style.content_margin_right   = 16
	style.content_margin_top     = 10
	style.content_margin_bottom  = 10
	toast_panel.add_theme_stylebox_override("panel", style)
	_on_message_requested(message, duration)
