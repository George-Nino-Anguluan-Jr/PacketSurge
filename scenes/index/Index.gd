# Index.gd
extends Control

# ─── NODE REFERENCES ───────────────────────────────────
@onready var back_btn: Button           = $TopBar/TopBarLayout/BackBtn
@onready var search_field: LineEdit     = $TopBar/TopBarLayout/SearchField
@onready var towers_tab: Button         = $TabBar/TowersTab
@onready var enemies_tab: Button        = $TabBar/EnemiesTab
@onready var towers_panel: ScrollContainer  = $ContentArea/TowersPanel
@onready var enemies_panel: ScrollContainer = $ContentArea/EnemiesPanel
@onready var towers_content: VBoxContainer  = $ContentArea/TowersPanel/TowersContent
@onready var enemies_content: VBoxContainer = $ContentArea/EnemiesPanel/EnemiesContent

var path_tab: Button = null
var path_panel: ScrollContainer = null

# ─── DATA ──────────────────────────────────────────────
const TOWER_DATA = [
	{
		"id":          "tower_array",
		"name":        "Array Tower",
		"ds":          "Array",
		"cost":        50,
		"damage":      8.0,
		"speed":       1.5,
		"range":       130.0,
		"time_complexity":  "O(1) Access",
		"space_complexity": "O(n)",
		"color":       "#00D4FF",
		"icon":        "[ ]",
		"description": "The foundation of all towers. Fast attack speed with reliable O(1) index-based targeting. Best for covering wide areas.",
		"strengths":   ["Fast attack speed", "Consistent damage", "O(1) targeting"],
		"weaknesses":  ["Low damage per hit", "No special ability"],
		"unlocked_by": "py_variables",
	},
	{
		"id":          "tower_stack",
		"name":        "Stack Tower",
		"ds":          "Stack",
		"cost":        75,
		"damage":      15.0,
		"speed":       0.8,
		"range":       120.0,
		"time_complexity":  "O(1) Push/Pop",
		"space_complexity": "O(n)",
		"color":       "#FF6B35",
		"icon":        "↑↓",
		"description": "Uses LIFO strategy — targets the most recently entered enemy in range. High damage but slower attack speed.",
		"strengths":   ["High damage", "LIFO targeting", "Good vs clusters"],
		"weaknesses":  ["Slow attack speed", "Short range"],
		"unlocked_by": "py_lists",
	},
	{
		"id":          "tower_queue",
		"name":        "Queue Tower",
		"ds":          "Queue",
		"cost":        75,
		"damage":      12.0,
		"speed":       1.2,
		"range":       150.0,
		"time_complexity":  "O(1) Enqueue/Dequeue",
		"space_complexity": "O(n)",
		"color":       "#9B59B6",
		"icon":        "→",
		"description": "Uses FIFO strategy — always targets the first enemy in the path. Best for preventing enemies from reaching the base.",
		"strengths":   ["Targets lead enemy", "Good range", "Consistent"],
		"weaknesses":  ["Medium damage", "Ignores clustered enemies"],
		"unlocked_by": "py_loops",
	},
	{
		"id":          "tower_linked_list",
		"name":        "Linked Tower",
		"ds":          "Linked List",
		"cost":        100,
		"damage":      10.0,
		"speed":       1.0,
		"range":       140.0,
		"time_complexity":  "O(n) Traversal",
		"space_complexity": "O(n)",
		"color":       "#00FF88",
		"icon":        "→→",
		"description": "Chain damage — attack jumps to the next enemy like following a pointer. Excellent against enemy chains.",
		"strengths":   ["Chain damage", "Hits multiple enemies", "Great vs lines"],
		"weaknesses":  ["High RAM cost", "Less effective vs single enemies"],
		"unlocked_by": "py_conditions",
	},
	{
		"id":          "tower_bubble",
		"name":        "Bubble Tower",
		"ds":          "Bubble Sort",
		"cost":        90,
		"damage":      6.0,
		"speed":       2.0,
		"range":       120.0,
		"time_complexity":  "O(n²) Comparisons",
		"space_complexity": "O(1)",
		"color":       "#FFB800",
		"icon":        "↑↑",
		"description": "Slows enemies with each hit like bubble sort's repeated comparisons. Very fast attack but lower damage.",
		"strengths":   ["Slows enemies", "Very fast attack", "Low space cost"],
		"weaknesses":  ["Low damage", "O(n²) inefficiency"],
		"unlocked_by": "py_functions",
	},
	{
		"id":          "tower_selection",
		"name":        "Selection Tower",
		"ds":          "Selection Sort",
		"cost":        110,
		"damage":      20.0,
		"speed":       0.6,
		"range":       160.0,
		"time_complexity":  "O(n²) Selection",
		"space_complexity": "O(1)",
		"color":       "#E74C3C",
		"icon":        "→↓",
		"description": "Always targets the enemy with the lowest health — finds the minimum like Selection Sort. One powerful shot at a time.",
		"strengths":   ["High damage", "Smart targeting", "Long range"],
		"weaknesses":  ["Very slow attack", "One target at a time"],
		"unlocked_by": "ds_arrays",
	},
	{
		"id":          "tower_insertion",
		"name":        "Insertion Tower",
		"ds":          "Insertion Sort",
		"cost":        120,
		"damage":      14.0,
		"speed":       1.0,
		"range":       130.0,
		"time_complexity":  "O(n) Best Case",
		"space_complexity": "O(1)",
		"color":       "#1ABC9C",
		"icon":        "←↑",
		"description": "Inserts damage over time — applies a damage-over-time effect. Best against nearly-defeated enemies.",
		"strengths":   ["Damage over time", "Efficient vs weak enemies", "O(1) space"],
		"weaknesses":  ["Less effective vs full health enemies"],
		"unlocked_by": "ds_stacks",
	},
]

const ENEMY_DATA = [
	{
		"id":          "basic_packet",
		"name":        "Basic Packet",
		"description": "Standard network packet. No special abilities. The most common enemy in early waves.",
		"health":      100.0,
		"speed":       80.0,
		"reward":      10,
		"color":       "#FF3366",
		"icon":        "▶",
		"threat":      "Low",
		"special":     "None",
	},
	{
		"id":          "fast_packet",
		"name":        "Fast Packet",
		"description": "High-speed packet that moves twice as fast. Hard to hit with slow towers.",
		"health":      60.0,
		"speed":       160.0,
		"reward":      15,
		"color":       "#FF6B35",
		"icon":        "▶▶",
		"threat":      "Medium",
		"special":     "2x movement speed",
	},
	{
		"id":          "heavy_packet",
		"name":        "Heavy Packet",
		"description": "Heavily armored packet with high health. Slow but absorbs massive damage.",
		"health":      300.0,
		"speed":       40.0,
		"reward":      30,
		"color":       "#8E44AD",
		"icon":        "■",
		"threat":      "High",
		"special":     "3x health pool",
	},
	{
		"id":          "encrypted_packet",
		"name":        "Encrypted Packet",
		"description": "Resistant to slow effects. Standard speed and health but immune to Bubble Tower slow.",
		"health":      120.0,
		"speed":       90.0,
		"reward":      20,
		"color":       "#2ECC71",
		"icon":        "🔒",
		"threat":      "Medium",
		"special":     "Immune to slow",
	},
	{
		"id":          "stealth_packet",
		"name":        "Stealth Packet",
		"description": "Invisible until it enters a tower's range. Requires detection towers to reveal.",
		"health":      80.0,
		"speed":       100.0,
		"reward":      25,
		"color":       "#95A5A6",
		"icon":        "👻",
		"threat":      "High",
		"special":     "Invisible until in range",
	},
	{
		"id":          "boss_packet",
		"name":        "Boss Packet",
		"description": "Massive boss enemy. Splits into 3 Basic Packets on defeat. Appears at final waves.",
		"health":      500.0,
		"speed":       50.0,
		"reward":      100,
		"color":       "#E74C3C",
		"icon":        "👑",
		"threat":      "Extreme",
		"special":     "Splits into 3 on defeat",
	},
]

# ─── STATE ─────────────────────────────────────────────
var active_tab: String   = "towers"
var search_query: String = ""

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	_setup_buttons()
	_apply_styles()
	_build_towers_tab()
	_build_enemies_tab()
	_build_path_tab()
	_show_towers_tab()
	_apply_responsive_layout()
	get_tree().root.size_changed.connect(_apply_responsive_layout)

# ─── BUTTON SETUP ──────────────────────────────────────
func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	towers_tab.pressed.connect(_show_towers_tab)
	enemies_tab.pressed.connect(_show_enemies_tab)
	search_field.text_changed.connect(_on_search_changed)

	path_tab = Button.new()
	path_tab.text = "📊 Path"
	path_tab.custom_minimum_size = Vector2(80, 32)
	path_tab.pressed.connect(_show_path_tab)
	path_tab.add_theme_font_size_override("font_size", 12)
	$TabBar.add_child(path_tab)

	path_panel = ScrollContainer.new()
	path_panel.name = "PathPanel"
	path_panel.custom_minimum_size = Vector2(0, 0)
	path_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	path_panel.visible = false
	$ContentArea.add_child(path_panel)

func _on_back_pressed() -> void:
	GameManager.go_to("main_menu")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to("main_menu")

# ─── TAB SWITCHING ─────────────────────────────────────
func _show_towers_tab() -> void:
	active_tab             = "towers"
	towers_panel.visible   = true
	enemies_panel.visible  = false
	path_panel.visible     = false
	_style_active_tab(towers_tab,  true)
	_style_active_tab(enemies_tab, false)
	if path_tab: _style_active_tab(path_tab, false)

func _show_enemies_tab() -> void:
	active_tab             = "enemies"
	towers_panel.visible   = false
	enemies_panel.visible  = true
	path_panel.visible     = false
	_style_active_tab(towers_tab,  false)
	_style_active_tab(enemies_tab, true)
	if path_tab: _style_active_tab(path_tab, false)

# ─── BUILD TOWERS TAB ──────────────────────────────────
func _show_path_tab() -> void:
	active_tab             = "path"
	towers_panel.visible   = false
	enemies_panel.visible  = false
	path_panel.visible     = true
	_style_active_tab(towers_tab,  false)
	_style_active_tab(enemies_tab, false)
	if path_tab: _style_active_tab(path_tab, true)
	path_panel.queue_redraw()

func _build_path_tab() -> void:
	var content := VBoxContainer.new()
	content.name = "PathContent"
	content.add_theme_constant_override("separation", 4)
	path_panel.add_child(content)

	var title := Label.new()
	title.text = "YOUR LEARNING PATH"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("#00D4FF"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	var groups = [
		["Python", ["py_variables", "py_lists", "py_loops", "py_conditions", "py_functions"]],
		["Data Structures", ["ds_arrays", "ds_stacks", "ds_queues", "ds_linked_lists"]],
		["Sorting", ["sort_bubble", "sort_selection", "sort_insertion", "sort_quick", "sort_merge", "sort_counting", "sort_radix"]],
		["Search", ["search_linear", "search_binary"]],
	]

	var tower_map = {}
	for k in ProgressManager.PROGRESSION_CHAIN:
		var v = ProgressManager.PROGRESSION_CHAIN[k]
		if v.get("type") in ["both", "tower"]:
			tower_map[k] = v["id"]

	for group in groups:
		var section := VBoxContainer.new()
		section.add_theme_constant_override("separation", 2)
		section.add_theme_constant_override("margin_left", 16)
		section.add_theme_constant_override("margin_right", 16)
		content.add_child(section)

		var hdr := Label.new()
		hdr.text = "── " + group[0] + " ──"
		hdr.add_theme_font_size_override("font_size", 11)
		hdr.add_theme_color_override("font_color", Color("#4A7FA5"))
		hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		section.add_child(hdr)

		for lesson_id in group[1]:
			var state = ProgressManager.get_topic_state(lesson_id)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			section.add_child(row)

			var dot := Label.new()
			dot.custom_minimum_size = Vector2(20, 20)
			dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			match state:
				"mastered":
					dot.text = "✅"
				"unlocked":
					dot.text = "🔓"
				_:
					dot.text = "🔒"
			row.add_child(dot)

			var lbl := Label.new()
			lbl.text = lesson_id
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if state == "mastered":
				lbl.add_theme_color_override("font_color", Color("#00FF88"))
			elif state == "unlocked":
				lbl.add_theme_color_override("font_color", Color("#00D4FF"))
			else:
				lbl.add_theme_color_override("font_color", Color("#2A3A4A"))
			lbl.add_theme_font_size_override("font_size", 11)
			row.add_child(lbl)

			# Show tower / level unlock
			if tower_map.has(lesson_id):
				var tname = str(tower_map[lesson_id])
				var tlocked = ProgressManager.is_tower_unlocked(tower_map[lesson_id])
				var tlabel := Label.new()
				tlabel.text = "→ " + tname
				tlabel.add_theme_font_size_override("font_size", 9)
				tlabel.add_theme_color_override("font_color", Color("#00FF88") if tlocked else Color("#2A3A4A"))
				row.add_child(tlabel)

			var chain = ProgressManager.PROGRESSION_CHAIN.get(lesson_id, {})
			var lid = chain.get("level_id", 0)
			if lid > 0:
				var unlocked = ProgressManager.is_level_unlocked(lid)
				var llbl := Label.new()
				llbl.text = "Lv." + str(lid)
				llbl.add_theme_font_size_override("font_size", 9)
				llbl.add_theme_color_override("font_color", Color("#FFB800") if unlocked else Color("#2A3A4A"))
				row.add_child(llbl)

		var sep := HSeparator.new()
		sep.add_theme_color_override("color", Color("#1A2D3D"))
		content.add_child(sep)

func _build_towers_tab() -> void:
	for child in towers_content.get_children():
		child.queue_free()

	var filtered = TOWER_DATA.filter(func(t):
		return search_query == "" or \
			t["name"].to_lower().contains(search_query) or \
			t["ds"].to_lower().contains(search_query)
	)

	for tower in filtered:
		var card = _make_tower_card(tower)
		towers_content.add_child(card)

func _make_tower_card(data: Dictionary) -> PanelContainer:
	var is_unlocked = ProgressManager.is_tower_unlocked(data["id"])
	var color       = Color(data["color"])

	var card        := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Card style
	var style       := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = color if is_unlocked else Color("#2A3A4A")
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left    = 20
	style.content_margin_right   = 20
	style.content_margin_top     = 16
	style.content_margin_bottom  = 16
	card.add_theme_stylebox_override("panel", style)

	var layout      := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 20)

	# ── LEFT: Icon + Name ──
	var left        := VBoxContainer.new()
	left.custom_minimum_size = Vector2(160, 0)
	left.add_theme_constant_override("separation", 8)

	# Icon circle
	var icon_label  := Label.new()
	icon_label.text = data["icon"]
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.add_theme_color_override(
		"font_color",
		color if is_unlocked else Color("#2A3A4A")
	)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(icon_label)

	var name_label  := Label.new()
	name_label.text = data["name"]
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override(
		"font_color",
		Color("#E8F4FD") if is_unlocked else Color("#2A3A4A")
	)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(name_label)

	var ds_label    := Label.new()
	ds_label.text   = data["ds"]
	ds_label.add_theme_font_size_override("font_size", 11)
	ds_label.add_theme_color_override(
		"font_color",
		color if is_unlocked else Color("#2A3A4A")
	)
	ds_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(ds_label)

	# RAM cost
	var cost_label  := Label.new()
	cost_label.text = "💾 " + str(data["cost"]) + " RAM"
	cost_label.add_theme_font_size_override("font_size", 12)
	cost_label.add_theme_color_override(
		"font_color",
		Color("#00D4FF") if is_unlocked else Color("#2A3A4A")
	)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(cost_label)

	layout.add_child(left)

	# ── MIDDLE: Description + Stats ──
	var middle      := VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 8)

	if is_unlocked:
		var desc_label  := Label.new()
		desc_label.text = data["description"]
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.add_theme_font_size_override("font_size", 13)
		desc_label.add_theme_color_override(
			"font_color", Color("#E8F4FD")
		)
		middle.add_child(desc_label)

		# Stats row
		var stats_row   := HBoxContainer.new()
		stats_row.add_theme_constant_override("separation", 16)
		_add_stat(stats_row, "DMG",   str(data["damage"]))
		_add_stat(stats_row, "SPD",   str(data["speed"]) + "/s")
		_add_stat(stats_row, "RNG",   str(data["range"]) + "px")
		middle.add_child(stats_row)

		# Complexity
		var complex_row := HBoxContainer.new()
		complex_row.add_theme_constant_override("separation", 16)
		_add_stat(complex_row, "TIME",  data["time_complexity"])
		_add_stat(complex_row, "SPACE", data["space_complexity"])
		middle.add_child(complex_row)
	else:
		var lock_label  := Label.new()
		lock_label.text = "🔒 Complete the " + \
			_get_lesson_name(data["unlocked_by"]) + \
			" lesson to unlock this tower."
		lock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lock_label.add_theme_font_size_override("font_size", 13)
		lock_label.add_theme_color_override(
			"font_color", Color("#4A7FA5")
		)
		middle.add_child(lock_label)

	layout.add_child(middle)

	# ── RIGHT: Strengths + Weaknesses ──
	if is_unlocked:
		var right       := VBoxContainer.new()
		right.custom_minimum_size = Vector2(160, 0)
		right.add_theme_constant_override("separation", 8)

		var str_title   := Label.new()
		str_title.text  = "STRENGTHS"
		str_title.add_theme_font_size_override("font_size", 10)
		str_title.add_theme_color_override(
			"font_color", Color("#00FF88")
		)
		right.add_child(str_title)

		for s in data["strengths"]:
			var item    := Label.new()
			item.text   = "✓ " + s
			item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			item.add_theme_font_size_override("font_size", 12)
			item.add_theme_color_override(
				"font_color", Color("#E8F4FD")
			)
			right.add_child(item)

		var weak_title  := Label.new()
		weak_title.text = "WEAKNESSES"
		weak_title.add_theme_font_size_override("font_size", 10)
		weak_title.add_theme_color_override(
			"font_color", Color("#FF3366")
		)
		right.add_child(weak_title)

		for w in data["weaknesses"]:
			var item    := Label.new()
			item.text   = "✗ " + w
			item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			item.add_theme_font_size_override("font_size", 12)
			item.add_theme_color_override(
				"font_color", Color("#E8F4FD")
			)
			right.add_child(item)

		layout.add_child(right)

	card.add_child(layout)
	return card

# ─── BUILD ENEMIES TAB ─────────────────────────────────
func _build_enemies_tab() -> void:
	for child in enemies_content.get_children():
		child.queue_free()

	var filtered = ENEMY_DATA.filter(func(e):
		return search_query == "" or \
			e["name"].to_lower().contains(search_query)
	)

	for enemy in filtered:
		var card = _make_enemy_card(enemy)
		enemies_content.add_child(card)

func _make_enemy_card(data: Dictionary) -> PanelContainer:
	var color       = Color(data["color"])
	var card        := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style       := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = color
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left    = 20
	style.content_margin_right   = 20
	style.content_margin_top     = 16
	style.content_margin_bottom  = 16
	card.add_theme_stylebox_override("panel", style)

	var layout      := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 20)

	# ── LEFT: Icon + Name ──
	var left        := VBoxContainer.new()
	left.custom_minimum_size = Vector2(140, 0)
	left.add_theme_constant_override("separation", 8)

	var icon_label  := Label.new()
	icon_label.text = data["icon"]
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.add_theme_color_override("font_color", color)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(icon_label)

	var name_label  := Label.new()
	name_label.text = data["name"]
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override(
		"font_color", Color("#E8F4FD")
	)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(name_label)

	# Threat level
	var threat_label := Label.new()
	threat_label.text = "⚠ " + data["threat"] + " Threat"
	threat_label.add_theme_font_size_override("font_size", 11)
	var threat_color: Color
	match data["threat"]:
		"Low":     threat_color = Color("#00FF88")
		"Medium":  threat_color = Color("#FFB800")
		"High":    threat_color = Color("#FF6B35")
		"Extreme": threat_color = Color("#FF3366")
		_:         threat_color = Color("#E8F4FD")
	threat_label.add_theme_color_override("font_color", threat_color)
	threat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(threat_label)

	# RAM reward
	var reward_label := Label.new()
	reward_label.text = "💾 +" + str(data["reward"]) + " RAM"
	reward_label.add_theme_font_size_override("font_size", 12)
	reward_label.add_theme_color_override(
		"font_color", Color("#00D4FF")
	)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(reward_label)

	layout.add_child(left)

	# ── MIDDLE: Description + Stats ──
	var middle      := VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 8)

	var desc_label  := Label.new()
	desc_label.text = data["description"]
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override(
		"font_color", Color("#E8F4FD")
	)
	middle.add_child(desc_label)

	# Stats
	var stats_row   := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 16)
	_add_stat(stats_row, "HP",    str(data["health"]))
	_add_stat(stats_row, "SPD",   str(data["speed"]) + "px/s")
	middle.add_child(stats_row)

	# Special ability
	var special_label := Label.new()
	special_label.text = "⚡ " + data["special"]
	special_label.add_theme_font_size_override("font_size", 12)
	special_label.add_theme_color_override(
		"font_color", Color("#FFB800")
	)
	middle.add_child(special_label)

	layout.add_child(middle)
	card.add_child(layout)
	return card

# ─── SEARCH ────────────────────────────────────────────
func _on_search_changed(new_text: String) -> void:
	search_query = new_text.to_lower().strip_edges()
	match active_tab:
		"towers":  _build_towers_tab()
		"enemies": _build_enemies_tab()

# ─── HELPERS ───────────────────────────────────────────
func _add_stat(
		container: HBoxContainer,
		label: String,
		value: String) -> void:
	var vbox    := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var lbl     := Label.new()
	lbl.text    = label
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	vbox.add_child(lbl)

	var val     := Label.new()
	val.text    = value
	val.add_theme_font_size_override("font_size", 13)
	val.add_theme_color_override("font_color", Color("#E8F4FD"))
	vbox.add_child(val)

	container.add_child(vbox)

func _get_lesson_name(lesson_id: String) -> String:
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
	}
	return names.get(lesson_id, lesson_id)

# ─── STYLES ────────────────────────────────────────────
func _apply_styles() -> void:
	# TopBar
	var top_style := StyleBoxFlat.new()
	top_style.bg_color          = Color("#0A1628")
	top_style.border_color      = Color("#00D4FF")
	top_style.border_width_bottom = 1
	$TopBar.add_theme_stylebox_override("panel", top_style)

	# Back button
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

	# Search field
	var search_style := StyleBoxFlat.new()
	search_style.bg_color               = Color("#080F1E")
	search_style.border_color           = Color("#1A3A5A")
	search_style.border_width_left      = 1
	search_style.border_width_right     = 1
	search_style.border_width_top       = 1
	search_style.border_width_bottom    = 1
	search_style.corner_radius_top_left     = 4
	search_style.corner_radius_top_right    = 4
	search_style.corner_radius_bottom_left  = 4
	search_style.corner_radius_bottom_right = 4
	search_style.content_margin_left    = 12
	search_style.content_margin_right   = 12
	search_field.add_theme_stylebox_override("normal", search_style)
	search_field.add_theme_color_override(
		"font_color", Color("#E8F4FD")
	)
	search_field.add_theme_color_override(
		"font_placeholder_color", Color("#4A7FA5")
	)

	# Tab bar background
	var tab_bg := StyleBoxFlat.new()
	tab_bg.bg_color = Color("#080F1E")
	$TabBar.add_theme_stylebox_override("panel", tab_bg)

func _style_active_tab(btn: Button, active: bool) -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left     = 0
	style.corner_radius_top_right    = 0
	style.corner_radius_bottom_left  = 0
	style.corner_radius_bottom_right = 0
	if active:
		style.bg_color            = Color("#0D2040")
		style.border_color        = Color("#00D4FF")
		style.border_width_bottom = 2
		btn.add_theme_color_override("font_color", Color("#00D4FF"))
	else:
		style.bg_color            = Color("#080F1E")
		style.border_color        = Color("#080F1E")
		style.border_width_bottom = 2
		btn.add_theme_color_override("font_color", Color("#4A7FA5"))
	btn.add_theme_stylebox_override("normal",  style)
	btn.add_theme_stylebox_override("hover",   style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_font_size_override("font_size", 14)

# ─── RESPONSIVE ────────────────────────────────────────
func _apply_responsive_layout() -> void:
	if ScreenManager.is_mobile():
		search_field.visible = false
	else:
		search_field.visible = true
