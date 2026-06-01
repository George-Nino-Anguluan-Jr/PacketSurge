# LevelSelect.gd
extends Control

@onready var back_btn: Button         = $TopBar/TopBarLayout/BackBtn
@onready var ram_label: Label         = $TopBar/TopBarLayout/RAMLabel
@onready var level_grid: GridContainer = $ContentArea/MainLayout/LevelGrid
@onready var locked_label: Label      = $ContentArea/MainLayout/LockedLabel

# Level definitions
const LEVEL_INFO = [
	{"number": 1,  "name": "Initialization",    "ds": "Arrays",       "waves": 3},
	{"number": 2,  "name": "Stack Overflow",     "ds": "Stacks",       "waves": 4},
	{"number": 3,  "name": "Queue Protocol",     "ds": "Queues",       "waves": 4},
	{"number": 4,  "name": "Linked Assault",     "ds": "Linked Lists", "waves": 5},
	{"number": 5,  "name": "Function Call",      "ds": "Functions",    "waves": 5},
	{"number": 6,  "name": "Array Breach",       "ds": "Arrays+",      "waves": 5},
	{"number": 7,  "name": "Stack Defense",      "ds": "Stacks+",      "waves": 6},
	{"number": 8,  "name": "Queue Surge",        "ds": "Queues+",      "waves": 6},
	{"number": 9,  "name": "Bubble Protocol",    "ds": "Bubble Sort",  "waves": 6},
	{"number": 10, "name": "Selection Strike",   "ds": "Select Sort",  "waves": 7},
	{"number": 11, "name": "Final Insertion",    "ds": "Insert Sort",  "waves": 8},
]

func _ready() -> void:
	_setup_buttons()
	_build_level_grid()
	_apply_styles()
	_apply_responsive_layout()
	get_tree().root.size_changed.connect(_apply_responsive_layout)
	SignalBus.campaign_level_unlocked.connect(_on_level_unlocked)

func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	_style_back_btn()

func _on_back_pressed() -> void:
	GameManager.go_to("main_menu")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to("main_menu")

# ─── BUILD LEVEL GRID ──────────────────────────────────
func _build_level_grid() -> void:
	# Clear existing cards
	for child in level_grid.get_children():
		child.queue_free()

	var unlocked_count := 0

	for info in LEVEL_INFO:
		var level_num   = info["number"]
		var is_unlocked = ProgressManager.is_level_unlocked(level_num)
		var is_completed = ProgressManager.campaign_progress.get(
			"waves_completed", 0
		) >= level_num

		if is_unlocked:
			unlocked_count += 1

		var card = _make_level_card(
			info, is_unlocked, is_completed
		)
		level_grid.add_child(card)

	# Update header
	ram_label.text = str(unlocked_count) + " / 11 Unlocked"

	# Show hint if not all unlocked
	locked_label.visible = unlocked_count < 11

func _make_level_card(
		info: Dictionary,
		is_unlocked: bool,
		is_completed: bool) -> PanelContainer:

	var card     := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 120)

	# Card style
	var style    := StyleBoxFlat.new()
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1

	if is_completed:
		style.bg_color     = Color("#0D2A1A")
		style.border_color = Color("#00FF88")
	elif is_unlocked:
		style.bg_color     = Color("#0D2040")
		style.border_color = Color("#00D4FF")
	else:
		style.bg_color     = Color("#0A1628")
		style.border_color = Color("#2A3A4A")

	card.add_theme_stylebox_override("panel", style)

	# Card layout
	var layout   := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)

	# Level number
	var num_label := Label.new()
	num_label.text = "LEVEL " + str(info["number"])
	num_label.add_theme_font_size_override("font_size", 11)
	if is_completed:
		num_label.add_theme_color_override("font_color", Color("#00FF88"))
	elif is_unlocked:
		num_label.add_theme_color_override("font_color", Color("#00D4FF"))
	else:
		num_label.add_theme_color_override("font_color", Color("#2A3A4A"))
	layout.add_child(num_label)

	# Level name
	var name_label := Label.new()
	name_label.text          = info["name"] if is_unlocked else "???"
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 14)
	if is_unlocked:
		name_label.add_theme_color_override("font_color", Color("#E8F4FD"))
	else:
		name_label.add_theme_color_override("font_color", Color("#2A3A4A"))
	layout.add_child(name_label)

	# Data structure tag
	var ds_label := Label.new()
	ds_label.text = info["ds"] if is_unlocked else "Locked"
	ds_label.add_theme_font_size_override("font_size", 11)
	if is_completed:
		ds_label.add_theme_color_override("font_color", Color("#00FF88"))
	elif is_unlocked:
		ds_label.add_theme_color_override("font_color", Color("#4A7FA5"))
	else:
		ds_label.add_theme_color_override("font_color", Color("#2A3A4A"))
	layout.add_child(ds_label)

	# Waves info
	if is_unlocked:
		var waves_label := Label.new()
		waves_label.text = str(info["waves"]) + " Waves"
		waves_label.add_theme_font_size_override("font_size", 11)
		waves_label.add_theme_color_override("font_color", Color("#4A7FA5"))
		layout.add_child(waves_label)

	# Completed badge
	if is_completed:
		var badge := Label.new()
		badge.text = "✅ Completed"
		badge.add_theme_font_size_override("font_size", 11)
		badge.add_theme_color_override("font_color", Color("#00FF88"))
		layout.add_child(badge)

	card.add_child(layout)

	# Make clickable if unlocked
	if is_unlocked:
		var btn      := Button.new()
		btn.flat     = true
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.pressed.connect(
			_on_level_selected.bind(info["number"])
		)
		card.add_child(btn)

	return card

# ─── LEVEL SELECTED ────────────────────────────────────
func _on_level_selected(level_number: int) -> void:
	GameManager.current_level = level_number
	GameManager.go_to("level")   # ← was "campaign"

# ─── SIGNAL HANDLERS ───────────────────────────────────
func _on_level_unlocked(_level: int) -> void:
	_build_level_grid()

# ─── STYLES ────────────────────────────────────────────
func _apply_styles() -> void:
	var top_style := StyleBoxFlat.new()
	top_style.bg_color          = Color("#0A1628")
	top_style.border_color      = Color("#00D4FF")
	top_style.border_width_bottom = 1
	$TopBar.add_theme_stylebox_override("panel", top_style)

func _style_back_btn() -> void:
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
	back_btn.add_theme_stylebox_override("normal", style)
	back_btn.add_theme_color_override("font_color", Color("#00D4FF"))

# ─── RESPONSIVE ────────────────────────────────────────
func _apply_responsive_layout() -> void:
	if ScreenManager.is_mobile():
		level_grid.columns = 2
	else:
		level_grid.columns = 3
