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
		"damage":      18.0,
		"speed":       2.0,
		"range":       130.0,
		"time_complexity":  "O(1) Access",
		"space_complexity": "O(n)",
		"color":       "#00D4FF",
		"icon":        "[ ]",
		"description": "Fast attack with O(1) index-based targeting. Ideal for covering wide areas and countering damage-resistant enemies.",
		"strengths":   ["Fast attack speed", "O(1) targeting", "Great vs resistant enemies"],
		"weaknesses":  ["Low damage per hit", "No special ability"],
		"unlocked_by": "py_variables",
	},
	{
		"id":          "tower_stack",
		"name":        "Stack Tower",
		"ds":          "Stack",
		"cost":        75,
		"damage":      28.0,
		"speed":       1.2,
		"range":       130.0,
		"time_complexity":  "O(1) Push/Pop",
		"space_complexity": "O(n)",
		"color":       "#FF6B35",
		"icon":        "↑↓",
		"description": "LIFO targeting — hits the most recently arrived enemy first. High damage with good efficiency.",
		"strengths":   ["High damage", "LIFO targeting", "O(1) operations"],
		"weaknesses":  ["Shorter range", "Ignores spread enemies"],
		"unlocked_by": "py_lists",
	},
	{
		"id":          "tower_queue",
		"name":        "Queue Tower",
		"ds":          "Queue",
		"cost":        75,
		"damage":      22.0,
		"speed":       1.6,
		"range":       160.0,
		"time_complexity":  "O(1) Enqueue/Dequeue",
		"space_complexity": "O(n)",
		"color":       "#9B59B6",
		"icon":        "→",
		"description": "FIFO targeting with pierce — hits the first enemy and continues to the next. Excellent for chokepoints.",
		"strengths":   ["Targets lead enemy", "Long range", "Pierce ability"],
		"weaknesses":  ["Medium damage", "Less effective vs clustered"],
		"unlocked_by": "py_loops",
	},
	{
		"id":          "tower_linked_list",
		"name":        "Linked Tower",
		"ds":          "Linked List",
		"cost":        100,
		"damage":      20.0,
		"speed":       1.3,
		"range":       150.0,
		"time_complexity":  "O(n) Traversal",
		"space_complexity": "O(n)",
		"color":       "#00FF88",
		"icon":        "→→",
		"description": "Chain damage — jumps to the next nearby enemy like following a pointer. Devastating against enemy lines.",
		"strengths":   ["Chain damage", "Hits multiple enemies", "Great vs lines"],
		"weaknesses":  ["High RAM cost", "Needs clustered enemies"],
		"unlocked_by": "py_conditions",
	},
	{
		"id":          "tower_bubble",
		"name":        "Bubble Tower",
		"ds":          "Bubble Sort",
		"cost":        90,
		"damage":      16.0,
		"speed":       1.5,
		"range":       130.0,
		"time_complexity":  "O(n²) Comparisons",
		"space_complexity": "O(1)",
		"color":       "#FFB800",
		"icon":        "↑↑",
		"description": "AoE pulse — damages all enemies in range simultaneously. Perfect for clustered groups.",
		"strengths":   ["AoE damage", "Fast attack", "Shifts groups"],
		"weaknesses":  ["Low single-target damage", "O(n²) scaling"],
		"unlocked_by": "py_functions",
	},
	{
		"id":          "tower_selection",
		"name":        "Selection Tower",
		"ds":          "Selection Sort",
		"cost":        110,
		"damage":      24.0,
		"speed":       1.0,
		"range":       170.0,
		"time_complexity":  "O(n²) Selection",
		"space_complexity": "O(1)",
		"color":       "#E74C3C",
		"icon":        "→↓",
		"description": "Always targets the lowest HP enemy — finds the minimum like Selection Sort. One powerful shot at a time.",
		"strengths":   ["High damage", "Smart targeting", "Long range"],
		"weaknesses":  ["Slow attack", "Single target"],
		"unlocked_by": "ds_arrays",
	},
	{
		"id":          "tower_insertion",
		"name":        "Insertion Tower",
		"ds":          "Insertion Sort",
		"cost":        120,
		"damage":      18.0,
		"speed":       1.4,
		"range":       140.0,
		"time_complexity":  "O(n) Best Case",
		"space_complexity": "O(1)",
		"color":       "#1ABC9C",
		"icon":        "←↑",
		"description": "Applies stacking damage-over-time — inserts damage repeatedly. Shreds heavily armored enemies.",
		"strengths":   ["Damage over time", "Stacks on targets", "O(1) space"],
		"weaknesses":  ["Less effective vs full-health enemies"],
		"unlocked_by": "ds_stacks",
	},
	{
		"id":          "tower_quick",
		"name":        "Quick Tower",
		"ds":          "Quick Sort",
		"cost":        130,
		"damage":      22.0,
		"speed":       1.8,
		"range":       155.0,
		"time_complexity":  "O(n log n)",
		"space_complexity": "O(log n)",
		"color":       "#E91E63",
		"icon":        "⚡",
		"description": "Splits shots to hit 2 enemies simultaneously — like Quick Sort's pivot partitioning. Essential vs bosses.",
		"strengths":   ["Split shot", "Good vs bosses", "Fast attack"],
		"weaknesses":  ["Medium damage per target", "Requires precise timing"],
		"unlocked_by": "ds_queues",
	},
	{
		"id":          "tower_merge",
		"name":        "Merge Tower",
		"ds":          "Merge Sort",
		"cost":        140,
		"damage":      20.0,
		"speed":       1.4,
		"range":       160.0,
		"time_complexity":  "O(n log n)",
		"space_complexity": "O(n)",
		"color":       "#3F51B5",
		"icon":        "⊕",
		"description": "Guaranteed AoE damage — hits all enemies in range. Merge Sort's divide-and-conquer power in one blast.",
		"strengths":   ["AoE damage", "Consistent hits", "Great vs swarms"],
		"weaknesses":  ["Moderate speed", "High RAM cost"],
		"unlocked_by": "sort_quick",
	},
	{
		"id":          "tower_counting",
		"name":        "Count Tower",
		"ds":          "Counting Sort",
		"cost":        110,
		"damage":      14.0,
		"speed":       2.2,
		"range":       130.0,
		"time_complexity":  "O(n+k)",
		"space_complexity": "O(k)",
		"color":       "#009688",
		"icon":        "#",
		"description": "Grows stronger with more enemies in range — counts and dispatches efficiently. Rapid fire against crowds.",
		"strengths":   ["Rapid fire", "Scales with groups", "Fast attack"],
		"weaknesses":  ["Low single-target damage", "Needs many enemies"],
		"unlocked_by": "sort_merge",
	},
	{
		"id":          "tower_radix",
		"name":        "Radix Tower",
		"ds":          "Radix Sort",
		"cost":        150,
		"damage":      12.0,
		"speed":       3.0,
		"range":       145.0,
		"time_complexity":  "O(d×n)",
		"space_complexity": "O(n)",
		"color":       "#FF5722",
		"icon":        "0→9",
		"description": "Rapid multi-pass bursts — strips through armor digit by digit. Perfect against heavily armored foes.",
		"strengths":   ["Multi-pass bursts", "Strips armor", "Very fast"],
		"weaknesses":  ["Low base damage", "Expensive"],
		"unlocked_by": "sort_counting",
	},
	{
		"id":          "tower_linear",
		"name":        "Linear Tower",
		"ds":          "Linear Search",
		"cost":        80,
		"damage":      16.0,
		"speed":       1.0,
		"range":       200.0,
		"time_complexity":  "O(n)",
		"space_complexity": "O(1)",
		"color":       "#607D8B",
		"icon":        "→?",
		"description": "Wide scan range — never misses targets. Linear Search's exhaustive approach.",
		"strengths":   ["Wide range", "Never misses", "Consistent"],
		"weaknesses":  ["Slow attack", "Single target"],
		"unlocked_by": "search_linear",
	},
	{
		"id":          "tower_binary",
		"name":        "Binary Tower",
		"ds":          "Binary Search",
		"cost":        200,
		"damage":      80.0,
		"speed":       0.5,
		"range":       250.0,
		"time_complexity":  "O(log n)",
		"space_complexity": "O(1)",
		"color":       "#8BC34A",
		"icon":        "½",
		"description": "Precision sniper with massive single-target damage. Binary Search's logarithmic accuracy.",
		"strengths":   ["Massive damage", "Longest range", "O(log n) efficiency"],
		"weaknesses":  ["Very slow fire rate", "Single target only"],
		"unlocked_by": "search_binary",
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
		"icon":        "[ ]",
		"threat":      "Low",
		"special":     "None — pure data",
	},
	{
		"id":          "indexed_packet",
		"name":        "Indexed Packet",
		"description": "Has damage resistance. Shows an array index — take many quick hits to overcome it. Array Tower's fast attack excels here.",
		"health":      100.0,
		"speed":       72.0,
		"reward":      15,
		"color":       "#00D4FF",
		"icon":        "[0]",
		"threat":      "Low",
		"special":     "50% damage resistance. Teaches: Arrays use index-based access.",
	},
	{
		"id":          "overflow_packet",
		"name":        "Overflow Packet",
		"description": "Absorbs HP from enemies BEHIND it on the path. Grows stronger as enemies behind die. Must be killed LIFO (front-to-back). Stack Tower counters this.",
		"health":      300.0,
		"speed":       40.0,
		"reward":      30,
		"color":       "#8E44AD",
		"icon":        "↑↓",
		"threat":      "High",
		"special":     "Gains HP when enemies behind die. Teaches: Stack LIFO.",
	},
	{
		"id":          "queue_jumper",
		"name":        "Queue Jumper",
		"description": "Moves slowly at first but speeds up as enemies ahead of it die. Gets faster near the front of the line. Queue Tower's FIFO targeting catches it early.",
		"health":      80.0,
		"speed":       40.0,
		"reward":      15,
		"color":       "#FF6B35",
		"icon":        "▶▶",
		"threat":      "Medium",
		"special":     "Speed increases as enemies ahead die. Teaches: Queue FIFO.",
	},
	{
		"id":          "linked_drain",
		"name":        "Linked Drain",
		"description": "Spawns as a linked pair connected by a visible line. Damage is split 50/50 between partners. Linked Tower's chain damage hits both at once!",
		"health":      100.0,
		"speed":       80.0,
		"reward":      20,
		"color":       "#2ECC71",
		"icon":        "→→",
		"threat":      "Medium",
		"special":     "Shares 50% damage with linked partner. Teaches: Linked Lists connect nodes.",
	},
	{
		"id":          "bubble_shield",
		"name":        "Bubble Shield",
		"description": "Has a visible energy shield that absorbs the first 3 hits. Must pop the shield before damaging HP. Shield slowly regenerates. Bubble Tower's AoE pops shields fast.",
		"health":      100.0,
		"speed":       96.0,
		"reward":      25,
		"color":       "#95A5A6",
		"icon":        "⭕",
		"threat":      "Medium",
		"special":     "Shield absorbs 3 hits. Teaches: Bubble Sort compares adjacent pairs.",
	},
	{
		"id":          "selection_mark",
		"name":        "Selection Mark",
		"description": "Nearly invulnerable unless it is the enemy with the lowest HP on screen. When lowest, takes full damage. Selection Tower auto-targets the lowest HP enemy!",
		"health":      200.0,
		"speed":       80.0,
		"reward":      20,
		"color":       "#E74C3C",
		"icon":        "◎",
		"threat":      "High",
		"special":     "75% resistance unless lowest HP. Teaches: Selection Sort finds minimum.",
	},
	{
		"id":          "insertion_stack",
		"name":        "Insertion Stack",
		"description": "Takes 50% extra damage from Damage-over-Time effects. Insertion Tower's stacking DoT shreds this enemy type.",
		"health":      150.0,
		"speed":       64.0,
		"reward":      25,
		"color":       "#1ABC9C",
		"icon":        "◀|",
		"threat":      "Medium",
		"special":     "1.5x damage from DoT. Teaches: Insertion Sort inserts one at a time.",
	},
	{
		"id":          "pivot_splitter",
		"name":        "Pivot Splitter",
		"description": "Massive boss that splits into 2 smaller enemies on death (like Quick Sort partitioning around a pivot). Quick Tower's split shot handles the split!",
		"health":      500.0,
		"speed":       40.0,
		"reward":      100,
		"color":       "#E74C3C",
		"icon":        "⚡",
		"threat":      "Extreme",
		"special":     "Splits into 2 on death. Teaches: Quick Sort pivot partitioning.",
	},
	{
		"id":          "merge_twin",
		"name":        "Merge Twin",
		"description": "Spawns as a pair connected by a merge line. If one dies, the other absorbs its partner's remaining HP and gets stronger. Merge Tower's AoE kills both evenly!",
		"health":      150.0,
		"speed":       80.0,
		"reward":      25,
		"color":       "#3F51B5",
		"icon":        "⊕",
		"threat":      "High",
		"special":     "Absorbs partner on death. Teaches: Merge Sort splits then merges.",
	},
	{
		"id":          "count_meter",
		"name":        "Count Meter",
		"description": "Resists damage heavily (80%) but each hit increments a counter. When counter fills, takes full damage and resets. Count Tower's rapid hits fill the counter fast!",
		"health":      200.0,
		"speed":       80.0,
		"reward":      20,
		"color":       "#009688",
		"icon":        "###",
		"threat":      "Medium",
		"special":     "80% resistance until counter fills. Teaches: Counting Sort counts occurrences.",
	},
	{
		"id":          "radix_digit",
		"name":        "Radix Digit",
		"description": "Has 3 segmented health bars (1s, 10s, 100s). Must deplete units, then tens, then hundreds digit by digit. Radix Tower's multi-pass strips digits in order!",
		"health":      250.0,
		"speed":       56.0,
		"reward":      35,
		"color":       "#FF5722",
		"icon":        "1→9",
		"threat":      "High",
		"special":     "3 digit segments must be depleted in order. Teaches: Radix Sort processes digit by digit.",
	},
	{
		"id":          "scan_wave",
		"name":        "Scan Wave",
		"description": "Oscillates its position while moving along the path. Only vulnerable at the extreme ends of its oscillation. Linear Tower's guaranteed scan never misses the vulnerability window!",
		"health":      150.0,
		"speed":       72.0,
		"reward":      20,
		"color":       "#607D8B",
		"icon":        "→?",
		"threat":      "Medium",
		"special":     "90% immune between scan extremes. Teaches: Linear Search scans every element.",
	},
	{
		"id":          "binary_mask",
		"name":        "Binary Mask",
		"description": "Alternates between left-half and right-half vulnerability every few seconds. Only the highlighted half takes full damage. Binary Tower's precision shot hits the correct half!",
		"health":      200.0,
		"speed":       64.0,
		"reward":      40,
		"color":       "#8BC34A",
		"icon":        "½",
		"threat":      "Extreme",
		"special":     "Alternates vulnerable half. Teaches: Binary Search halves the search space.",
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
	left.custom_minimum_size = Vector2(120, 0)
	left.add_theme_constant_override("separation", 8)

	# Icon (rendered 3D model)
	var icon_rect := TextureRect.new()
	var icon_tex = _get_tower_icon(data["id"], color)
	if icon_tex:
		icon_rect.texture = icon_tex
		icon_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(40, 40)
		icon_rect.size = Vector2(40, 40)
		left.add_child(icon_rect)
	else:
		# Fallback to text symbol if rendering fails
		var icon_label = Label.new()
		icon_label.text = data["icon"]
		icon_label.add_theme_font_size_override("font_size", 32)
		icon_label.add_theme_color_override("font_color", color)
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
	left.custom_minimum_size = Vector2(100, 0)
	left.add_theme_constant_override("separation", 8)

	# Icon (rendered 3D model)
	var icon_rect := TextureRect.new()
	var icon_tex = _get_enemy_icon(data["id"], color)
	if icon_tex:
		icon_rect.texture = icon_tex
		icon_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(36, 36)
		icon_rect.size = Vector2(36, 36)
		left.add_child(icon_rect)
	else:
		# Fallback to text symbol if rendering fails
		var icon_label = Label.new()
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

# ─── ICON RENDERING ───────────────────────────────────────
# Cache for rendered icons
var _tower_icon_cache: Dictionary = {}
var _enemy_icon_cache: Dictionary = {}

# Viewport for 2D rendering
var _render_viewport: SubViewport

func _init_viewport() -> void:
	if _render_viewport:
		return
	
	_render_viewport = SubViewport.new()
	_render_viewport.size = Vector2(64, 64)
	_render_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_render_viewport.transparent_bg = true
	add_child(_render_viewport)

func _render_model_icon(model_scene: PackedScene, color: Color) -> ImageTexture:
	_init_viewport()
	
	var model = model_scene.instantiate()
	if not model:
		return null
	
	# Set color on the model if it has the property
	model.tower_color = color
	
	# Center the model in the viewport
	model.position = Vector2(32, 32)
	
	_render_viewport.add_child(model)
	
	# Get the rendered texture
	var tex = _render_viewport.get_texture()
	if not tex:
		model.queue_free()
		return null
	
	var img = tex.get_image()
	var result = ImageTexture.create_from_image(img)
	
	model.queue_free()
	
	return result

func _get_tower_icon(tower_id: String, color: Color) -> ImageTexture:
	if _tower_icon_cache.has(tower_id):
		return _tower_icon_cache[tower_id]
	
	var tower_scene = preload("res://scenes/campaign/towers/Tower.tscn")
	var tex = _render_model_icon(tower_scene, color)
	_tower_icon_cache[tower_id] = tex
	return tex

func _get_enemy_icon(enemy_id: String, color: Color) -> ImageTexture:
	if _enemy_icon_cache.has(enemy_id):
		return _enemy_icon_cache[enemy_id]
	
	_init_viewport()
	
	var icon_scene = preload("res://scenes/index/IconRenderer.tscn")
	var icon = icon_scene.instantiate()
	icon.enemy_type = enemy_id
	icon.draw_color = color
	icon.position = Vector2(32, 32)
	
	_render_viewport.add_child(icon)
	
	# Get the rendered texture
	var viewport_tex = _render_viewport.get_texture()
	if not viewport_tex:
		icon.queue_free()
		return null
	
	var img = viewport_tex.get_image()
	var result = ImageTexture.create_from_image(img)
	
	icon.queue_free()
	
	_enemy_icon_cache[enemy_id] = result
	return result

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
