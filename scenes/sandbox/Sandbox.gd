# Sandbox.gd
extends Control

@onready var back_btn: Button       = $TopBar/TopBarLayout/BackBtn
@onready var card_grid: GridContainer = $ContentArea/ScrollContainer/MainLayout/CardGrid
@onready var sandbox_subtitle: Label  = $ContentArea/ScrollContainer/MainLayout/HeaderSection/SandboxSubtitle

# ─── STRUCTURE DEFINITIONS ─────────────────────────────
const STRUCTURES = [
	{
		"id":          "array",
		"name":        "Array",
		"description": "Explore indexed storage. Add, access, and modify elements by position.",
		"icon":        "[ ]",
		"color":       "#00D4FF",
		"unlock_topic":"py_variables",
		"scene":       "res://scenes/sandbox/playgrounds/ArrayPlayground.tscn",
		"operations":  ["Access by index", "Insert", "Delete", "Search"],
	},
	{
		"id":          "stack",
		"name":        "Stack",
		"description": "Push and pop elements. Watch LIFO in action with visual animations.",
		"icon":        "↑↓",
		"color":       "#FF6B35",
		"unlock_topic":"py_lists",
		"scene":       "res://scenes/sandbox/playgrounds/StackPlayground.tscn",
		"operations":  ["Push", "Pop", "Peek", "isEmpty"],
	},
	{
		"id":          "queue",
		"name":        "Queue",
		"description": "Enqueue and dequeue elements. See FIFO ordering in real time.",
		"icon":        "→",
		"color":       "#9B59B6",
		"unlock_topic":"py_loops",
		"scene":       "res://scenes/sandbox/playgrounds/QueuePlayground.tscn",
		"operations":  ["Enqueue", "Dequeue", "Front", "isEmpty"],
	},
	{
		"id":          "linked_list",
		"name":        "Linked List",
		"description": "Add and remove nodes. See how pointers connect elements together.",
		"icon":        "→→",
		"color":       "#00FF88",
		"unlock_topic":"py_conditions",
		"scene":       "res://scenes/sandbox/playgrounds/LinkedListPlayground.tscn",
		"operations":  ["Insert Head", "Insert Tail", "Delete", "Traverse"],
	},
	{
		"id":          "bubble_sort",
		"name":        "Bubble Sort",
		"description": "Watch elements bubble up. Step through each comparison and swap.",
		"icon":        "↑↑",
		"color":       "#FFB800",
		"unlock_topic":"py_functions",
		"scene":       "res://scenes/sandbox/playgrounds/ArrayPlayground.tscn",
		"operations":  ["Step", "Play", "Reset", "Custom Input"],
	},
	{
		"id":          "selection_sort",
		"name":        "Selection Sort",
		"description": "Find the minimum each pass. See exactly how selection works step by step.",
		"icon":        "→↓",
		"color":       "#E74C3C",
		"unlock_topic":"ds_arrays",
		"scene":       "res://scenes/sandbox/playgrounds/ArrayPlayground.tscn",
		"operations":  ["Step", "Play", "Reset", "Custom Input"],
	},
	{
		"id":          "insertion_sort",
		"name":        "Insertion Sort",
		"description": "Insert each element into its correct position. Best for nearly sorted data.",
		"icon":        "←↑",
		"color":       "#1ABC9C",
		"unlock_topic":"ds_stacks",
		"scene":       "res://scenes/sandbox/playgrounds/ArrayPlayground.tscn",
		"operations":  ["Step", "Play", "Reset", "Custom Input"],
	},
]

var _time: float = 0.0

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	_setup_buttons()
	_apply_styles()
	_build_cards()
	_apply_responsive_layout()
	get_tree().root.size_changed.connect(_apply_responsive_layout)
	SignalBus.topic_mastered.connect(_on_topic_mastered)

func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	GameManager.go_to("academy")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to("academy")

# ─── BUILD CARDS ───────────────────────────────────────
func _build_cards() -> void:
	for child in card_grid.get_children():
		child.queue_free()

	var unlocked_count := 0

	for structure in STRUCTURES:
		var topic_state = ProgressManager.get_topic_state(
			structure["unlock_topic"]
		)
		var is_unlocked = topic_state == "unlocked" \
						  or topic_state == "mastered"
		if is_unlocked:
			unlocked_count += 1
		var card = _make_structure_card(structure, is_unlocked)
		card_grid.add_child(card)

	# Update subtitle
	if unlocked_count == 0:
		sandbox_subtitle.text = "Complete lessons in the Academy to unlock playgrounds."
	else:
		sandbox_subtitle.text = str(unlocked_count) + \
			" of " + str(STRUCTURES.size()) + \
			" playgrounds unlocked. Select one to explore."

func _make_structure_card(
		data: Dictionary,
		is_unlocked: bool) -> PanelContainer:

	var color   = Color(data["color"])
	var card    := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size   = Vector2(0, 180)

	# Card style
	var style   := StyleBoxFlat.new()
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.content_margin_left    = 20
	style.content_margin_right   = 20
	style.content_margin_top     = 20
	style.content_margin_bottom  = 20

	if is_unlocked:
		style.bg_color     = Color("#0A1628")
		style.border_color = color
	else:
		style.bg_color     = Color("#080F1E")
		style.border_color = Color("#1A2A3A")

	card.add_theme_stylebox_override("panel", style)

	# Card layout
	var layout  := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)

	# Top row — icon + name
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)

	var icon_label := Label.new()
	icon_label.text = data["icon"] if is_unlocked else "🔒"
	icon_label.add_theme_font_size_override("font_size", 28)
	icon_label.add_theme_color_override(
		"font_color",
		color if is_unlocked else Color("#2A3A4A")
	)
	top_row.add_child(icon_label)

	var name_col   := VBoxContainer.new()
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = data["name"]
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override(
		"font_color",
		Color("#E8F4FD") if is_unlocked else Color("#2A3A4A")
	)
	name_col.add_child(name_label)

	if is_unlocked:
		var ops_label := Label.new()
		ops_label.text = " · ".join(
			data["operations"].slice(0, 2)
		) + "..."
		ops_label.add_theme_font_size_override("font_size", 11)
		ops_label.add_theme_color_override(
			"font_color", Color("#4A7FA5")
		)
		name_col.add_child(ops_label)

	top_row.add_child(name_col)
	layout.add_child(top_row)

	# Description
	var desc_label := Label.new()
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 13)

	if is_unlocked:
		desc_label.text = data["description"]
		desc_label.add_theme_color_override(
			"font_color", Color("#E8F4FD")
		)
	else:
		desc_label.text = "🔒 Complete the " + \
			_get_lesson_name(data["unlock_topic"]) + \
			" lesson to unlock this playground."
		desc_label.add_theme_color_override(
			"font_color", Color("#4A7FA5")
		)
	layout.add_child(desc_label)

	# Operations chips (unlocked only)
	if is_unlocked:
		var chips_row := HBoxContainer.new()
		chips_row.add_theme_constant_override("separation", 6)
		for op in data["operations"]:
			var chip    := Label.new()
			chip.text   = op
			chip.add_theme_font_size_override("font_size", 10)
			chip.add_theme_color_override("font_color", color)
			var chip_style := StyleBoxFlat.new()
			chip_style.bg_color               = Color(color, 0.15)
			chip_style.border_color           = Color(color, 0.4)
			chip_style.border_width_left      = 1
			chip_style.border_width_right     = 1
			chip_style.border_width_top       = 1
			chip_style.border_width_bottom    = 1
			chip_style.corner_radius_top_left     = 10
			chip_style.corner_radius_top_right    = 10
			chip_style.corner_radius_bottom_left  = 10
			chip_style.corner_radius_bottom_right = 10
			chip_style.content_margin_left    = 8
			chip_style.content_margin_right   = 8
			chip_style.content_margin_top     = 2
			chip_style.content_margin_bottom  = 2
			chip.add_theme_stylebox_override("normal", chip_style)
			chips_row.add_child(chip)
		layout.add_child(chips_row)

		# Enter button
		var enter_btn  := Button.new()
		enter_btn.text = "▶ Open Playground"
		enter_btn.custom_minimum_size = Vector2(0, 40)
		_style_enter_btn(enter_btn, color)
		enter_btn.pressed.connect(
			_on_structure_selected.bind(data)
		)
		layout.add_child(enter_btn)

	card.add_child(layout)
	return card

# ─── STRUCTURE SELECTED ────────────────────────────────
func _on_structure_selected(data: Dictionary) -> void:
	GameManager.current_sandbox_structure = data["id"]
	if ResourceLoader.exists(data["scene"]):
		get_tree().change_scene_to_file(data["scene"])
	else:
		SignalBus.hud_message_requested.emit(
			"⚙️ " + data["name"] + " playground coming soon!", 3.0
		)

# ─── SIGNAL HANDLERS ───────────────────────────────────
func _on_topic_mastered(_topic_id: String) -> void:
	_build_cards()

# ─── HELPERS ───────────────────────────────────────────
func _get_lesson_name(topic_id: String) -> String:
	var names = {
		"py_variables":    "Variables",
		"py_lists":        "Lists",
		"py_loops":        "Loops",
		"py_conditions":   "Conditions",
		"py_functions":    "Functions",
		"ds_arrays":       "Arrays",
		"ds_stacks":       "Stacks",
	}
	return names.get(topic_id, topic_id)

# ─── STYLES ────────────────────────────────────────────
func _apply_styles() -> void:
	var top_style := StyleBoxFlat.new()
	top_style.bg_color          = Color("#0A1628")
	top_style.border_color      = Color("#00D4FF")
	top_style.border_width_bottom = 1
	$TopBar.add_theme_stylebox_override("panel", top_style)

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

func _style_enter_btn(btn: Button, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color               = Color(color, 0.2)
	style.border_color           = color
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_font_size_override("font_size", 13)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color               = Color(color, 0.35)
	hover_style.border_color           = color
	hover_style.border_width_left      = 1
	hover_style.border_width_right     = 1
	hover_style.border_width_top       = 1
	hover_style.border_width_bottom    = 1
	hover_style.corner_radius_top_left     = 4
	hover_style.corner_radius_top_right    = 4
	hover_style.corner_radius_bottom_left  = 4
	hover_style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("hover", hover_style)

# ─── RESPONSIVE ────────────────────────────────────────
func _apply_responsive_layout() -> void:
	var top_bar = $TopBar
	var content_area = $ContentArea
	var title_label = $TopBar/TopBarLayout/TitleLabel
	
	if ScreenManager.is_mobile():
		card_grid.columns = 1
		ScreenManager.apply_panel_padding(top_bar, 20)
		content_area.add_theme_constant_override("margin_left", 20)
		content_area.add_theme_constant_override("margin_right", 20)
		content_area.add_theme_constant_override("margin_top", 20)
		content_area.add_theme_constant_override("margin_bottom", 20)
		title_label.add_theme_font_size_override("font_size", 14)
		back_btn.custom_minimum_size = Vector2(70, 44)
	elif ScreenManager.is_tablet():
		card_grid.columns = 2
		ScreenManager.apply_panel_padding(top_bar, 24)
		content_area.add_theme_constant_override("margin_left", 24)
		content_area.add_theme_constant_override("margin_right", 24)
		content_area.add_theme_constant_override("margin_top", 24)
		content_area.add_theme_constant_override("margin_bottom", 24)
		title_label.add_theme_font_size_override("font_size", 16)
		back_btn.custom_minimum_size = Vector2(80, 44)
	else:
		card_grid.columns = 3
		title_label.add_theme_font_size_override("font_size", 16)
		back_btn.custom_minimum_size = Vector2(90, 0)
