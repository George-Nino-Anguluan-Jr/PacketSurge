# Level.gd
extends Node2D

# ─── NODE REFERENCES ───────────────────────────────────
@onready var grid_visual: Node2D          = $GridLayer/GridVisual
@onready var tower_layer: Node2D          = $TowerLayer
@onready var enemy_layer: Node2D          = $EnemyLayer
@onready var wave_manager: Node           = $Managers/WaveManager
@onready var ram_manager: Node            = $Managers/RAMManager
@onready var back_btn: Button             = $HUD/HUDControl/TopHUD/TopLayout/BackBtn
@onready var level_label: Label           = $HUD/HUDControl/TopHUD/TopLayout/LevelLabel
@onready var ram_label: Label             = $HUD/HUDControl/TopHUD/TopLayout/RAMLabel
@onready var wave_label: Label            = $HUD/HUDControl/TopHUD/TopLayout/WaveLabel
@onready var base_health_label: Label     = $HUD/HUDControl/TopHUD/TopLayout/BaseHealthLabel
@onready var score_label: Label           = $HUD/HUDControl/TopHUD/TopLayout/ScoreLabel
@onready var tower_buttons: HBoxContainer = $HUD/HUDControl/TowerSelector/SelectorLayout/TowerButtons
@onready var start_wave_btn: Button       = $HUD/HUDControl/TowerSelector/SelectorLayout/StartWaveBtn
@onready var game_over_panel: PanelContainer = $HUD/HUDControl/GameOverPanel

# ─── LEVEL STATE ───────────────────────────────────────
var level_number: int             = 1
var score: int                    = 0
var base_health: int              = 10
var selected_tower_data: TowerData = null
var grid_system: Node2D           = null
var level_start_time: float       = 0.0

# ─── LEVEL CONFIGS ─────────────────────────────────────
const LEVEL_CONFIGS = {
	1: {
		"name":        "Initialization",
		"concept":     "Arrays",
		"concept_desc":"Arrays store data at fixed indices. Your Array Tower accesses targets in O(1) time — instantly.",
		"enemy_tip":   "Basic packets only. Place towers near the middle of the path.",
		"waves":       3,
		"start_ram":   150,
		"tower_slots": 2,
		"waypoints": [
			Vector2(0, 320), Vector2(1152, 320)
		],
		"tower_spots": [
			Vector2i(2, 3), Vector2i(2, 6),
			Vector2i(6, 3), Vector2i(6, 6),
			Vector2i(10, 3), Vector2i(10, 6),
			Vector2i(14, 3), Vector2i(14, 6),
		],
		"required_towers": ["tower_array"],
		"towers": ["tower_array"],
	},
	2: {
		"name":        "Stack Overflow",
		"concept":     "Stacks",
		"concept_desc":"A Stack is LIFO — Last In First Out. Your Stack Tower targets the most recently arrived enemy first.",
		"enemy_tip":   "Fast packets appear in wave 3. Stack Tower hits them hard.",
		"waves":       4,
		"start_ram":   175,
		"tower_slots": 3,
		"waypoints": [
			Vector2(0, 160),
			Vector2(576, 160),
			Vector2(576, 480),
			Vector2(1152, 480),
		],
		"tower_spots": [
			Vector2i(2, 1), Vector2i(5, 1),
			Vector2i(2, 4), Vector2i(5, 4),
			Vector2i(8, 4), Vector2i(11, 4),
			Vector2i(8, 7), Vector2i(11, 7),
			Vector2i(14, 7), Vector2i(16, 7),
		],
		"required_towers": ["tower_array", "tower_stack"],
		"towers": ["tower_array", "tower_stack"],
	},
	3: {
		"name":        "Queue Protocol",
		"concept":     "Queues",
		"concept_desc":"A Queue is FIFO — First In First Out. Your Queue Tower targets the first enemy that entered its range, and pierces through to the one behind it.",
		"enemy_tip":   "Fast packets arrive early. Queue Tower's pierce ability is essential here.",
		"waves":       4,
		"start_ram":   200,
		"tower_slots": 3,
		"waypoints": [
			Vector2(0, 96),
			Vector2(384, 96),
			Vector2(384, 480),
			Vector2(768, 480),
			Vector2(768, 224),
			Vector2(1152, 224),
		],
		"tower_spots": [
			Vector2i(1, 1), Vector2i(4, 1),
			Vector2i(1, 5), Vector2i(4, 5),
			Vector2i(7, 5), Vector2i(10, 5),
			Vector2i(7, 2), Vector2i(10, 2),
			Vector2i(13, 2), Vector2i(16, 2),
		],
		"required_towers": ["tower_queue"],
		"towers": ["tower_array", "tower_stack", "tower_queue"],
	},
	4: {
		"name":        "Linked Assault",
		"concept":     "Linked Lists",
		"concept_desc":"A Linked List connects nodes with pointers. Your Linked Tower chains damage — hitting one enemy then jumping to the next nearby one.",
		"enemy_tip":   "Heavy packets appear. Linked Tower's chain damage is ideal for clustered enemies.",
		"waves":       5,
		"start_ram":   200,
		"tower_slots": 3,
		"waypoints": [
			Vector2(0, 224),
			Vector2(256, 224),
			Vector2(256, 96),
			Vector2(640, 96),
			Vector2(640, 416),
			Vector2(896, 416),
			Vector2(896, 224),
			Vector2(1152, 224),
		],
		"tower_spots": [
			Vector2i(1, 2), Vector2i(1, 5),
			Vector2i(3, 1), Vector2i(6, 1),
			Vector2i(9, 1), Vector2i(12, 1),
			Vector2i(9, 5), Vector2i(12, 5),
			Vector2i(15, 2), Vector2i(15, 5),
		],
		"required_towers": ["tower_linked_list"],
		"towers": ["tower_array", "tower_stack", "tower_queue", "tower_linked_list"],
	},
	5: {
		"name":        "Bubble Protocol",
		"concept":     "Bubble Sort",
		"concept_desc":"Bubble Sort compares adjacent elements repeatedly — O(n²). Your Bubble Tower hits ALL enemies in range simultaneously, like comparing every pair.",
		"enemy_tip":   "Encrypted packets resist single-target damage. Bubble Tower's AoE is essential.",
		"waves":       5,
		"start_ram":   225,
		"tower_slots": 4,
		"waypoints": [
			Vector2(0, 480),
			Vector2(320, 480),
			Vector2(320, 160),
			Vector2(832, 160),
			Vector2(832, 352),
			Vector2(512, 352),
			Vector2(512, 480),
			Vector2(1152, 480),
		],
		"tower_spots": [
			Vector2i(1, 6), Vector2i(4, 6),
			Vector2i(1, 2), Vector2i(4, 2),
			Vector2i(7, 2), Vector2i(11, 2),
			Vector2i(7, 5), Vector2i(11, 5),
			Vector2i(14, 6), Vector2i(16, 6),
		],
		"required_towers": ["tower_bubble"],
		"towers": ["tower_array", "tower_stack", "tower_queue", "tower_linked_list", "tower_bubble"],
	},
	6: {
		"name":        "Selection Strike",
		"concept":     "Selection Sort",
		"concept_desc":"Selection Sort finds the minimum element each pass. Your Selection Tower always targets the lowest HP enemy — finishing off the weakest first.",
		"enemy_tip":   "Stealth packets are hard to see. Selection Tower always finds and targets them regardless.",
		"waves":       5,
		"start_ram":   225,
		"tower_slots": 4,
		"waypoints": [
			Vector2(0, 96),
			Vector2(1152, 96),
			Vector2(1152, 320),
			Vector2(0, 320),
			Vector2(0, 480),
			Vector2(1152, 480),
		],
		"tower_spots": [
			Vector2i(2, 2), Vector2i(5, 2),
			Vector2i(8, 2), Vector2i(11, 2),
			Vector2i(14, 2), Vector2i(16, 2),
			Vector2i(2, 5), Vector2i(5, 5),
			Vector2i(8, 5), Vector2i(11, 5),
		],
		"required_towers": ["tower_selection"],
		"towers": ["tower_array", "tower_stack", "tower_queue", "tower_bubble", "tower_selection"],
	},
	7: {
		"name":        "Stack Defense",
		"concept":     "Insertion Sort",
		"concept_desc":"Insertion Sort inserts each element into its correct position one at a time. Your Insertion Tower applies stacking damage-over-time — inserting damage repeatedly.",
		"enemy_tip":   "Heavy and encrypted packets. Insertion Tower's DoT stacks up on high-HP enemies.",
		"waves":       6,
		"start_ram":   250,
		"tower_slots": 4,
		"waypoints": [
			Vector2(0, 320),
			Vector2(192, 320),
			Vector2(192, 96),
			Vector2(448, 96),
			Vector2(448, 416),
			Vector2(704, 416),
			Vector2(704, 160),
			Vector2(960, 160),
			Vector2(960, 480),
			Vector2(1152, 480),
		],
		"tower_spots": [
			Vector2i(1, 1), Vector2i(1, 5),
			Vector2i(4, 1), Vector2i(4, 5),
			Vector2i(8, 1), Vector2i(8, 6),
			Vector2i(12, 1), Vector2i(12, 6),
			Vector2i(16, 1), Vector2i(16, 6),
		],
		"required_towers": ["tower_insertion"],
		"towers": ["tower_array", "tower_stack", "tower_queue", "tower_linked_list", "tower_bubble", "tower_selection", "tower_insertion"],
	},
	8: {
		"name":        "Quick Strike",
		"concept":     "Quick Sort",
		"concept_desc":"Quick Sort divides around a pivot. Your Quick Tower splits its shot — hitting 2 enemies simultaneously like dividing the array into left and right partitions.",
		"enemy_tip":   "Boss packet appears in wave 5. Quick Tower's split shot is essential for the boss split.",
		"waves":       6,
		"start_ram":   250,
		"tower_slots": 4,
		"waypoints": [
			Vector2(0, 160),
			Vector2(384, 160),
			Vector2(384, 416),
			Vector2(768, 416),
			Vector2(768, 96),
			Vector2(1152, 96),
		],
		"tower_spots": [
			Vector2i(1, 1), Vector2i(1, 4),
			Vector2i(4, 1), Vector2i(4, 4),
			Vector2i(7, 4), Vector2i(7, 7),
			Vector2i(10, 4), Vector2i(10, 7),
			Vector2i(13, 1), Vector2i(16, 1),
		],
		"required_towers": ["tower_quick"],
		"towers": ["tower_array", "tower_stack", "tower_queue", "tower_linked_list", "tower_bubble", "tower_selection", "tower_insertion", "tower_quick"],
	},
	9: {
		"name":        "Merge Protocol",
		"concept":     "Merge Sort",
		"concept_desc":"Merge Sort splits arrays in half then merges sorted halves. Your Merge Tower does guaranteed AoE damage — O(n log n) means no enemy escapes.",
		"enemy_tip":   "Boss + stealth combination. Merge Tower's AoE hits all enemies including stealth.",
		"waves":       6,
		"start_ram":   275,
		"tower_slots": 5,
		"waypoints": [
			Vector2(0, 480),
			Vector2(576, 480),
			Vector2(576, 96),
			Vector2(1152, 96),
			Vector2(1152, 320),
			Vector2(768, 320),
			Vector2(768, 480),
		],
		"tower_spots": [
			Vector2i(1, 6), Vector2i(4, 6),
			Vector2i(7, 6), Vector2i(7, 1),
			Vector2i(10, 1), Vector2i(13, 1),
			Vector2i(16, 1), Vector2i(16, 4),
			Vector2i(13, 4), Vector2i(10, 6),
		],
		"required_towers": ["tower_merge"],
		"towers": ["tower_array", "tower_stack", "tower_queue", "tower_linked_list", "tower_bubble", "tower_selection", "tower_insertion", "tower_quick", "tower_merge"],
	},
	10: {
		"name":        "Count Down",
		"concept":     "Counting Sort",
		"concept_desc":"Counting Sort counts occurrences of each value. Your Count Tower gets stronger the more enemies are in range — O(n+k) means it scales with crowd size.",
		"enemy_tip":   "Large waves with mixed enemies. Count Tower excels when many enemies cluster together.",
		"waves":       7,
		"start_ram":   275,
		"tower_slots": 5,
		"waypoints": [
			Vector2(0, 96),
			Vector2(256, 96),
			Vector2(256, 480),
			Vector2(512, 480),
			Vector2(512, 96),
			Vector2(768, 96),
			Vector2(768, 480),
			Vector2(1024, 480),
			Vector2(1024, 96),
			Vector2(1152, 96),
		],
		"tower_spots": [
			Vector2i(1, 1), Vector2i(1, 6),
			Vector2i(3, 1), Vector2i(3, 6),
			Vector2i(6, 1), Vector2i(6, 6),
			Vector2i(9, 1), Vector2i(9, 6),
			Vector2i(12, 1), Vector2i(12, 6),
		],
		"required_towers": ["tower_counting"],
		"towers": ["tower_array", "tower_stack", "tower_queue", "tower_bubble", "tower_selection", "tower_insertion", "tower_quick", "tower_merge", "tower_counting"],
	},
	11: {
		"name":        "Radix Rush",
		"concept":     "Radix Sort",
		"concept_desc":"Radix Sort processes digits one at a time. Your Radix Tower fires rapid multi-pass bursts — hitting every enemy multiple times like sorting digit by digit.",
		"enemy_tip":   "Boss packet + encrypted combination. Radix Tower's rapid fire strips through armor.",
		"waves":       7,
		"start_ram":   275,
		"tower_slots": 5,
		"waypoints": [
			Vector2(0, 256),
			Vector2(192, 256),
			Vector2(192, 96),
			Vector2(576, 96),
			Vector2(576, 416),
			Vector2(384, 416),
			Vector2(384, 256),
			Vector2(768, 256),
			Vector2(768, 96),
			Vector2(1152, 96),
		],
		"tower_spots": [
			Vector2i(1, 3), Vector2i(1, 6),
			Vector2i(4, 1), Vector2i(7, 1),
			Vector2i(10, 1), Vector2i(10, 5),
			Vector2i(7, 5), Vector2i(4, 5),
			Vector2i(13, 1), Vector2i(16, 1),
		],
		"required_towers": ["tower_radix"],
		"towers": ["tower_array", "tower_stack", "tower_queue", "tower_linked_list", "tower_bubble", "tower_selection", "tower_insertion", "tower_quick", "tower_merge", "tower_counting", "tower_radix"],
	},
	12: {
		"name":        "Linear Sweep",
		"concept":     "Linear Search",
		"concept_desc":"Linear Search checks every element one by one. Your Linear Tower scans ALL enemies in a wide range — it never misses but takes time like O(n) sequential checking.",
		"enemy_tip":   "Stealth and encrypted mixed. Linear Tower's guaranteed scan hits even stealth packets.",
		"waves":       7,
		"start_ram":   300,
		"tower_slots": 5,
		"waypoints": [
			Vector2(0, 160),
			Vector2(288, 160),
			Vector2(288, 480),
			Vector2(576, 480),
			Vector2(576, 160),
			Vector2(864, 160),
			Vector2(864, 480),
			Vector2(1152, 480),
		],
		"tower_spots": [
			Vector2i(1, 1), Vector2i(1, 6),
			Vector2i(3, 1), Vector2i(3, 6),
			Vector2i(7, 1), Vector2i(7, 6),
			Vector2i(11, 1), Vector2i(11, 6),
			Vector2i(15, 1), Vector2i(15, 6),
		],
		"required_towers": ["tower_linear"],
		"towers": ["tower_array", "tower_stack", "tower_queue", "tower_linked_list", "tower_bubble", "tower_selection", "tower_insertion", "tower_quick", "tower_merge", "tower_counting", "tower_radix", "tower_linear"],
	},
	13: {
		"name":        "Binary Endgame",
		"concept":     "Binary Search",
		"concept_desc":"Binary Search finds targets in O(log n) by halving the search space. Your Binary Tower is a precision sniper — it instantly locates and destroys the highest-priority target.",
		"enemy_tip":   "All enemy types. Binary Tower one-shots most enemies. Use it wisely — slow attack speed.",
		"waves":       8,
		"start_ram":   300,
		"tower_slots": 6,
		"waypoints": [
			Vector2(0, 256),
			Vector2(192, 256),
			Vector2(192, 96),
			Vector2(576, 96),
			Vector2(576, 416),
			Vector2(384, 416),
			Vector2(384, 256),
			Vector2(768, 256),
			Vector2(768, 96),
			Vector2(1152, 96),
		],
		"tower_spots": [
			Vector2i(1, 3), Vector2i(1, 6),
			Vector2i(4, 1), Vector2i(4, 5),
			Vector2i(7, 1), Vector2i(7, 5),
			Vector2i(10, 1), Vector2i(10, 5),
			Vector2i(13, 1), Vector2i(13, 5),
			Vector2i(16, 1), Vector2i(16, 5),
		],
		"required_towers": ["tower_binary"],
		"towers": ["tower_array", "tower_stack", "tower_queue", "tower_linked_list", "tower_bubble", "tower_selection", "tower_insertion", "tower_quick", "tower_merge", "tower_counting", "tower_radix", "tower_linear", "tower_binary"],
	},
}

const TOWER_DEFINITIONS = {
	"tower_array": {
		"tower_id":    "tower_array",
		"tower_name":  "Array Tower",
		"description": "Fast attack. O(1) access speed.",
		"data_structure": "Array",
		"ram_cost":    50,
		"damage":      18.0,
		"attack_speed":2.0,
		"attack_range":140.0,
		"time_complexity": "O(1)",
		"color":       Color("#00D4FF"),
		"icon_text":   "[ ]",
	},
	"tower_stack": {
		"tower_id":    "tower_stack",
		"tower_name":  "Stack Tower",
		"description": "Hits the most recent enemy. LIFO targeting.",
		"data_structure": "Stack",
		"ram_cost":    75,
		"damage":      28.0,
		"attack_speed":1.2,
		"attack_range":130.0,
		"time_complexity": "O(1)",
		"color":       Color("#FF6B35"),
		"icon_text":   "↑↓",
	},
	"tower_queue": {
		"tower_id":    "tower_queue",
		"tower_name":  "Queue Tower",
		"description": "Pierces 2 enemies in line. FIFO targeting.",
		"data_structure": "Queue",
		"ram_cost":    75,
		"damage":      22.0,
		"attack_speed":1.6,
		"attack_range":160.0,
		"time_complexity": "O(1)",
		"color":       Color("#9B59B6"),
		"icon_text":   "→",
	},
	"tower_linked_list": {
		"tower_id":    "tower_linked_list",
		"tower_name":  "Linked Tower",
		"description": "Chain damage across 3 nearby enemies.",
		"data_structure": "Linked List",
		"ram_cost":    100,
		"damage":      20.0,
		"attack_speed":1.3,
		"attack_range":150.0,
		"time_complexity": "O(n)",
		"color":       Color("#00FF88"),
		"icon_text":   "→→",
	},
	"tower_bubble": {
		"tower_id":    "tower_bubble",
		"tower_name":  "Bubble Tower",
		"description": "AoE pulse — damages every enemy in range.",
		"data_structure": "Bubble Sort",
		"ram_cost":    90,
		"damage":      16.0,
		"attack_speed":1.5,
		"attack_range":130.0,
		"time_complexity": "O(n²)",
		"color":       Color("#FFB800"),
		"icon_text":   "↑↑",
	},
	"tower_selection": {
		"tower_id":    "tower_selection",
		"tower_name":  "Selection Tower",
		"description": "Always finishes off the weakest enemy.",
		"data_structure": "Selection Sort",
		"ram_cost":    110,
		"damage":      24.0,
		"attack_speed":1.0,
		"attack_range":170.0,
		"time_complexity": "O(n²)",
		"color":       Color("#E74C3C"),
		"icon_text":   "→↓",
	},
	"tower_insertion": {
		"tower_id":    "tower_insertion",
		"tower_name":  "Insertion Tower",
		"description": "Applies stacking damage-over-time.",
		"data_structure": "Insertion Sort",
		"ram_cost":    120,
		"damage":      18.0,
		"attack_speed":1.4,
		"attack_range":140.0,
		"time_complexity": "O(n)",
		"color":       Color("#1ABC9C"),
		"icon_text":   "←↑",
	},
}

# ─── READY ─────────────────────────────────────────────
func _ready() -> void:
	level_number     = GameManager.current_level
	level_start_time = Time.get_ticks_msec() / 1000.0
	_setup_grid()
	_setup_level()
	_setup_hud()
	_setup_buttons()
	_connect_signals()
	_apply_hud_styles()

# ─── SETUP ─────────────────────────────────────────────
func _setup_grid() -> void:
	grid_system      = GridSystem.new()
	grid_system.name = "GridSystem"
	grid_visual.add_child(grid_system)

	var config = _get_level_config()

	var waypoints: Array[Vector2] = []
	for wp in config["waypoints"]:
		waypoints.append(wp)

	var spots: Array[Vector2i] = []
	for sp in config["tower_spots"]:
		spots.append(sp)

	grid_system.initialize(waypoints, spots)
	grid_system.cell_clicked.connect(_on_cell_clicked)

func _setup_level() -> void:
	var config = _get_level_config()
	ram_manager.initialize(config["start_ram"])

	var enemy_scene = preload(
		"res://scenes/campaign/enemies/Enemy.tscn"
	)
	var waypoints: Array[Vector2] = []
	for wp in config["waypoints"]:
		waypoints.append(wp)

	wave_manager.initialize(
		config["waves"],
		enemy_scene,
		enemy_layer,
		waypoints,
		AdaptiveAI.get_wave_modifier()
	)

func _setup_hud() -> void:
	var config           = _get_level_config()
	level_label.text     = "Level " + str(level_number) + \
						   " — " + config["name"]
	wave_label.text      = "Wave: 0/" + str(config["waves"])
	base_health_label.text = "❤️ " + str(base_health)
	score_label.text     = "Score: 0"
	_update_ram_label()
	_build_tower_selector()

func _build_tower_selector() -> void:
	for child in tower_buttons.get_children():
		child.queue_free()

	var config           = _get_level_config()
	var available_towers = config["towers"]

	for tower_id in available_towers:
		if not ProgressManager.is_tower_unlocked(tower_id):
			continue
		if not TOWER_DEFINITIONS.has(tower_id):
			continue
		var def  = TOWER_DEFINITIONS[tower_id]
		var btn  := Button.new()
		btn.text = def["tower_name"] + "\n" + str(def["ram_cost"]) + " RAM"
		btn.custom_minimum_size = Vector2(110, 60)
		_style_tower_btn(btn, Color(def["color"]))
		btn.pressed.connect(_on_tower_selected.bind(tower_id))
		tower_buttons.add_child(btn)

func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	start_wave_btn.pressed.connect(wave_manager.start_next_wave)

func _connect_signals() -> void:
	ram_manager.ram_changed.connect(_on_ram_changed)
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.all_waves_completed.connect(_on_all_waves_completed)
	SignalBus.enemy_reached_end.connect(_on_enemy_reached_end)
	SignalBus.enemy_defeated.connect(_on_enemy_defeated)

# ─── GRID INTERACTION ──────────────────────────────────
func _on_cell_clicked(cell: Vector2i) -> void:
	if selected_tower_data == null:
		SignalBus.hud_message_requested.emit(
			"Select a tower from the bottom bar first.", 2.0
		)
		return
	if not grid_system.can_place_tower(cell):
		SignalBus.hud_message_requested.emit(
			"Can't place tower here.", 2.0
		)
		return
	if not ram_manager.can_afford(selected_tower_data.ram_cost):
		SignalBus.hud_message_requested.emit(
			"Not enough RAM! Need " + \
			str(selected_tower_data.ram_cost) + " RAM.", 2.0
		)
		return
	_place_tower(cell)

func _place_tower(cell: Vector2i) -> void:
	ram_manager.spend(selected_tower_data.ram_cost)

	var tower_scene = preload(
		"res://scenes/campaign/towers/Tower.tscn"
	)
	var tower = tower_scene.instantiate()
	tower_layer.add_child(tower)
	tower.position = grid_system.get_cell_center(cell)
	tower.initialize(selected_tower_data, cell, enemy_layer)

	# Pass tower node so grid tracks it
	grid_system.place_tower(cell, tower)

	SignalBus.tower_placed.emit(selected_tower_data.tower_id, cell)
	print("[Level] Tower placed at: ", cell)

# ─── TOWER SELECTION ───────────────────────────────────
func _on_tower_selected(tower_id: String) -> void:
	var def = TOWER_DEFINITIONS[tower_id]
	selected_tower_data              = TowerData.new()
	selected_tower_data.tower_id     = def["tower_id"]
	selected_tower_data.tower_name   = def["tower_name"]
	selected_tower_data.ram_cost     = def["ram_cost"]
	selected_tower_data.damage       = def["damage"]
	selected_tower_data.attack_speed = def["attack_speed"]
	selected_tower_data.attack_range = def["attack_range"]
	selected_tower_data.color        = def["color"]
	selected_tower_data.icon_text    = def["icon_text"]
	grid_system.is_placing_tower     = true
	SignalBus.hud_message_requested.emit(
		"Click a cell to place " + def["tower_name"] + \
		" (" + str(def["ram_cost"]) + " RAM)", 2.0
	)

# ─── INPUT ─────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

# ─── SIGNAL HANDLERS ───────────────────────────────────
func _on_ram_changed(_current: int, _max_ram: int) -> void:
	_update_ram_label()

func _on_wave_started(wave_num: int, total: int) -> void:
	wave_label.text = "Wave: " + str(wave_num) + "/" + str(total)
	start_wave_btn.disabled = true
	SignalBus.hud_message_requested.emit(
		"⚔️ Wave " + str(wave_num) + " incoming!", 2.0
	)

func _on_wave_completed(wave_num: int) -> void:
	score           += 100 * wave_num
	score_label.text = "Score: " + str(score)
	ram_manager.earn(50)
	start_wave_btn.disabled = false
	SignalBus.hud_message_requested.emit(
		"✅ Wave " + str(wave_num) + " complete! +50 RAM", 3.0
	)

func _on_all_waves_completed() -> void:
	var elapsed = (Time.get_ticks_msec() / 1000.0) - level_start_time
	ProgressManager.on_level_completed(level_number)
	SupabaseManager.submit_campaign_score(level_number, elapsed, score)
	_show_result_panel(true)

func _on_enemy_reached_end(_enemy_id: String) -> void:
	base_health -= 1
	_update_base_health_label()
	if base_health <= 0:
		_show_result_panel(false)

func _on_enemy_defeated(_enemy_id: String) -> void:
	var ram_reward = 10
	ram_manager.earn(ram_reward)
	score           += 10
	score_label.text = "Score: " + str(score)

# ─── BASE HEALTH ───────────────────────────────────────
func _update_base_health_label() -> void:
	base_health_label.text = "❤️ " + str(base_health)
	var tween = create_tween()
	tween.tween_property(
		base_health_label, "modulate", Color("#FF0000"), 0.1
	)
	tween.tween_property(
		base_health_label, "modulate", Color("#FFFFFF"), 0.3
	)
	if base_health <= 3:
		SignalBus.hud_message_requested.emit(
			"⚠️ Base critical! " + str(base_health) + " HP left!", 2.0
		)

# ─── RESULT PANEL ──────────────────────────────────────
func _show_result_panel(victory: bool) -> void:
	for child in game_over_panel.get_children():
		child.queue_free()

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	if victory:
		title.text = "🎉 VICTORY!"
		title.add_theme_color_override("font_color", Color("#00FF88"))
	else:
		title.text = "💀 GAME OVER"
		title.add_theme_color_override("font_color", Color("#FF3366"))
	layout.add_child(title)

	var score_lbl := Label.new()
	score_lbl.text = "Score: " + str(score)
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.add_theme_color_override("font_color", Color("#E8F4FD"))
	score_lbl.add_theme_font_size_override("font_size", 20)
	layout.add_child(score_lbl)

	var grade     = _get_grade()
	var grade_lbl := Label.new()
	grade_lbl.text = "Grade: " + grade["letter"]
	grade_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_lbl.add_theme_font_size_override("font_size", 48)
	grade_lbl.add_theme_color_override("font_color", grade["color"])
	layout.add_child(grade_lbl)

	if victory:
		var unlock_lbl := Label.new()
		if ProgressManager.LEVEL_UNLOCKS_LESSON.has(level_number):
			var next = ProgressManager.LEVEL_UNLOCKS_LESSON[level_number]
			unlock_lbl.text = "🔓 Unlocked: " + next
		unlock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unlock_lbl.add_theme_color_override("font_color", Color("#00D4FF"))
		unlock_lbl.add_theme_font_size_override("font_size", 14)
		layout.add_child(unlock_lbl)

	var stats_row := HBoxContainer.new()
	stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_row.add_theme_constant_override("separation", 24)
	_add_result_stat(stats_row, "BASE HP", str(base_health) + "/10")
	_add_result_stat(stats_row, "WAVES", str(wave_manager.current_wave) + "/" + str(wave_manager.total_waves))
	var elapsed = int((Time.get_ticks_msec() / 1000.0) - level_start_time)
	_add_result_stat(stats_row, "TIME", str(elapsed) + "s")
	layout.add_child(stats_row)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)

	var retry_btn := Button.new()
	retry_btn.text = "↺ Retry"
	retry_btn.custom_minimum_size = Vector2(120, 44)
	retry_btn.pressed.connect(func(): get_tree().reload_current_scene())
	btn_row.add_child(retry_btn)

	var menu_btn := Button.new()
	menu_btn.text = "🏠 Level Select"
	menu_btn.custom_minimum_size = Vector2(140, 44)
	menu_btn.pressed.connect(func(): GameManager.go_to("campaign"))
	btn_row.add_child(menu_btn)

	layout.add_child(btn_row)
	game_over_panel.add_child(layout)
	game_over_panel.visible = true

func _get_grade() -> Dictionary:
	var hp_ratio = float(base_health) / 10.0
	if hp_ratio >= 0.9:
		return {"letter": "S", "color": Color("#FFD700")}
	elif hp_ratio >= 0.7:
		return {"letter": "A", "color": Color("#00FF88")}
	elif hp_ratio >= 0.5:
		return {"letter": "B", "color": Color("#00D4FF")}
	elif hp_ratio >= 0.3:
		return {"letter": "C", "color": Color("#FFB800")}
	else:
		return {"letter": "F", "color": Color("#FF3366")}

func _add_result_stat(
		container: HBoxContainer,
		label: String,
		value: String) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)

	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	col.add_child(lbl)

	var val := Label.new()
	val.text = value
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val.add_theme_font_size_override("font_size", 16)
	val.add_theme_color_override("font_color", Color("#E8F4FD"))
	col.add_child(val)

	container.add_child(col)

# ─── NAVIGATION ────────────────────────────────────────
func _on_back_pressed() -> void:
	GameManager.go_to("campaign")

# ─── HUD HELPERS ───────────────────────────────────────
func _update_ram_label() -> void:
	ram_label.text = "💾 " + str(ram_manager.get_current()) + " RAM"

func _get_level_config() -> Dictionary:
	if LEVEL_CONFIGS.has(level_number):
		return LEVEL_CONFIGS[level_number]
	return LEVEL_CONFIGS[1]

# ─── HUD STYLES ────────────────────────────────────────
func _apply_hud_styles() -> void:
	var top_style := StyleBoxFlat.new()
	top_style.bg_color            = Color("#0A1628")
	top_style.border_color        = Color("#00D4FF")
	top_style.border_width_bottom = 1
	$HUD/HUDControl/TopHUD.add_theme_stylebox_override("panel", top_style)

	var sel_style := StyleBoxFlat.new()
	sel_style.bg_color          = Color("#0A1628")
	sel_style.border_color      = Color("#00D4FF")
	sel_style.border_width_top  = 1
	$HUD/HUDControl/TowerSelector.add_theme_stylebox_override("panel", sel_style)

	var go_style := StyleBoxFlat.new()
	go_style.bg_color                = Color("#050D1A")
	go_style.border_color            = Color("#00D4FF")
	go_style.border_width_left       = 1
	go_style.border_width_right      = 1
	go_style.border_width_top        = 1
	go_style.border_width_bottom     = 1
	go_style.corner_radius_top_left     = 8
	go_style.corner_radius_top_right    = 8
	go_style.corner_radius_bottom_left  = 8
	go_style.corner_radius_bottom_right = 8
	$HUD/HUDControl/GameOverPanel.add_theme_stylebox_override("panel", go_style)

	var back_style := StyleBoxFlat.new()
	back_style.bg_color               = Color("#0A1628")
	back_style.border_color           = Color("#FF3366")
	back_style.border_width_left      = 1
	back_style.border_width_right     = 1
	back_style.border_width_top       = 1
	back_style.border_width_bottom    = 1
	back_style.corner_radius_top_left     = 4
	back_style.corner_radius_top_right    = 4
	back_style.corner_radius_bottom_left  = 4
	back_style.corner_radius_bottom_right = 4
	back_btn.add_theme_stylebox_override("normal", back_style)
	back_btn.add_theme_color_override("font_color", Color("#FF3366"))

	var wave_style := StyleBoxFlat.new()
	wave_style.bg_color               = Color("#FFB800")
	wave_style.corner_radius_top_left     = 4
	wave_style.corner_radius_top_right    = 4
	wave_style.corner_radius_bottom_left  = 4
	wave_style.corner_radius_bottom_right = 4
	start_wave_btn.add_theme_stylebox_override("normal", wave_style)
	start_wave_btn.add_theme_color_override("font_color", Color("#050D1A"))
	start_wave_btn.add_theme_font_size_override("font_size", 13)

func _style_tower_btn(btn: Button, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
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
	btn.add_theme_font_size_override("font_size", 11)
