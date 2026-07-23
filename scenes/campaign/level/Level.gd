# Level.gd
extends Node2D

# ─── NODE REFERENCES ───────────────────────────────────
@onready var grid_visual: Node2D             = $GridLayer/GridVisual
@onready var tower_layer: Node2D             = $TowerLayer
@onready var enemy_layer: Node2D             = $EnemyLayer
@onready var wave_manager: Node              = $Managers/WaveManager
@onready var ram_manager: Node               = $Managers/RAMManager
@onready var back_btn: Button                = $HUD/HUDControl/TopHUD/TopLayout/BackBtn
@onready var level_label: Label              = $HUD/HUDControl/TopHUD/TopLayout/LevelLabel
@onready var ram_label: Label                = $HUD/HUDControl/TopHUD/TopLayout/RAMLabel
@onready var wave_label: Label               = $HUD/HUDControl/TopHUD/TopLayout/WaveLabel
@onready var base_health_label: Label        = $HUD/HUDControl/TopHUD/TopLayout/BaseHealthLabel
@onready var score_label: Label              = $HUD/HUDControl/TopHUD/TopLayout/ScoreLabel
@onready var game_over_panel: PanelContainer = $HUD/HUDControl/GameOverPanel

@onready var pause_btn: Button               = $HUD/HUDControl/TopHUD/TopLayout/PauseBtn
@onready var pause_menu: PanelContainer      = $HUD/HUDControl/PauseMenu
@onready var resume_btn: Button              = $HUD/HUDControl/PauseMenu/PauseMenuLayout/ResumeBtn
@onready var retry_btn: Button               = $HUD/HUDControl/PauseMenu/PauseMenuLayout/RetryBtn
@onready var select_level_btn: Button        = $HUD/HUDControl/PauseMenu/PauseMenuLayout/SelectLevelBtn
@onready var main_menu_btn: Button           = $HUD/HUDControl/PauseMenu/PauseMenuLayout/MainMenuBtn

@onready var wave_progress_bar: ProgressBar = $HUD/HUDControl/TopHUD/TopLayout/WaveProgressTimeline/ProgressBar
@onready var timeline_flags: Control        = $HUD/HUDControl/TopHUD/TopLayout/WaveProgressTimeline/FlagsContainer
@onready var skip_wave_btn: Button           = $HUD/HUDControl/TopHUD/TopLayout/SkipWaveBtn
@onready var challenge_btn: Button           = $HUD/HUDControl/TopHUD/TopLayout/ChallengeBtn
var _diff_badge: Button = null
@onready var micro_panel: PanelContainer     = $HUD/HUDControl/MicroCodingPanel
@onready var wave_splash: Control            = $HUD/HUDControl/WaveSplash
@onready var wave_splash_label: Label        = $HUD/HUDControl/WaveSplash/WaveSplashLabel

var _is_retrying: bool = false
var _sound_ok: AudioStreamPlayer2D
var _sound_fail: AudioStreamPlayer2D
var _prev_ram: int = -1
var _challenge_index: int  = 0
var _challenge_progress: int = 0

# ─── LEVEL STATE ───────────────────────────────────────
var level_number: int              = 1
var score: int                     = 0
var base_health: int               = 10
var selected_tower_data: TowerData = null
var grid_system: Node2D            = null
var level_start_time: float        = 0.0
var is_level_ended: bool           = false

const INTER_WAVE_DURATION: float  = 15.0
var wave_countdown: float          = INTER_WAVE_DURATION
var countdown_active: bool         = true

# ─── CODING CHALLENGES ──────────────────────────────────
const CHALLENGES = {
	1: [  # Arrays
		{ "title": "Array Sum", "desc": "Sum all elements of [4, 8, 15, 16, 23, 42] using a loop and print the total.", "code_template": "arr = [4, 8, 15, 16, 23, 42]\ntotal = 0\n___\nprint(total)", "expected_output": "108\n", "bonus_ram": 20 },
		{ "title": "Find Maximum", "desc": "Find and print the largest value in [3, 17, 8, 42, 9].", "code_template": "arr = [3, 17, 8, 42, 9]\nmax_val = arr[0]\n___\nprint(max_val)", "expected_output": "42\n", "bonus_ram": 20 },
		{ "title": "Count Occurrences", "desc": "Count how many times 7 appears in [7, 3, 7, 1, 7, 9] and print the count.", "code_template": "arr = [7, 3, 7, 1, 7, 9]\ntarget = 7\ncount = 0\n___\nprint(count)", "expected_output": "3\n", "bonus_ram": 20 },
	],
	2: [  # Stacks
		{ "title": "Stack Push & Pop", "desc": "Push 10, 20, 30 onto a stack, then pop and print each value.", "code_template": "stack = []\nstack.append(10)\nstack.append(20)\n___\nprint(stack.pop())\nprint(stack.pop())\nprint(stack.pop())", "expected_output": "30\n20\n10\n", "bonus_ram": 20 },
		{ "title": "Stack Reversal", "desc": "Push A, B, C then pop all to reverse the order. Print each popped value.", "code_template": "stack = []\nstack.append('A')\n___\nstack.append('C')\nprint(stack.pop())\nprint(stack.pop())\nprint(stack.pop())", "expected_output": "C\nB\nA\n", "bonus_ram": 20 },
		{ "title": "Stack Peek", "desc": "Push 5, 15, 25. Pop once and print it, then print the new top without removing it (use stack[-1]).", "code_template": "stack = []\nstack.append(5)\nstack.append(15)\nstack.append(25)\npopped = stack.pop()\nprint(popped)\n___\nprint(top)", "expected_output": "25\n15\n", "bonus_ram": 20 },
	],
	3: [  # Queues
		{ "title": "Queue Dequeue All", "desc": "Enqueue 7, 14, 21 then dequeue and print each using pop(0).", "code_template": "queue = []\nqueue.append(7)\nqueue.append(14)\n___\nprint(queue.pop(0))\nprint(queue.pop(0))\nprint(queue.pop(0))", "expected_output": "7\n14\n21\n", "bonus_ram": 20 },
		{ "title": "Queue Round Robin", "desc": "Enqueue 1, 2, 3. Dequeue front, enqueue it back, then dequeue all. Print each dequeued value.", "code_template": "queue = [1, 2, 3]\nfront = queue.pop(0)\nqueue.append(front)\nprint(queue.pop(0))\n___\nprint(queue.pop(0))", "expected_output": "2\n3\n1\n", "bonus_ram": 20 },
		{ "title": "Queue Size", "desc": "Enqueue 10, 20, 30, 40. Dequeue twice. Print the remaining queue size.", "code_template": "queue = []\nqueue.append(10)\nqueue.append(20)\nqueue.append(30)\nqueue.append(40)\nqueue.pop(0)\nqueue.pop(0)\nprint(___)", "expected_output": "2\n", "bonus_ram": 20 },
	],
	4: [  # Linked Lists
		{ "title": "Traverse List", "desc": "Traverse the linked chain starting at node and print each val.", "code_template": "node = {'val': 1, 'next': {'val': 2, 'next': {'val': 3, 'next': None}}}\nwhile node:\n    print(node['val'])\n    ___", "expected_output": "1\n2\n3\n", "bonus_ram": 25 },
		{ "title": "Count Nodes", "desc": "Count how many nodes are in the linked chain and print the count.", "code_template": "node = {'val': 5, 'next': {'val': 10, 'next': {'val': 15, 'next': None}}}\ncount = 0\n___\nprint(count)", "expected_output": "3\n", "bonus_ram": 25 },
		{ "title": "Find Value", "desc": "Find if value 10 exists in the linked chain. Print 'yes' or 'no'.", "code_template": "node = {'val': 5, 'next': {'val': 10, 'next': {'val': 15, 'next': None}}}\ntarget = 10\nfound = 'no'\nwhile node:\n    if node['val'] == target:\n        found = 'yes'\n        ___\n    node = node['next']\nprint(found)", "expected_output": "yes\n", "bonus_ram": 25 },
	],
	5: [  # Bubble Sort
		{ "title": "One Pass", "desc": "Perform ONE pass of bubble sort on [5,3,8,1] and print the array.", "code_template": "arr = [5, 3, 8, 1]\nfor i in range(len(arr) - 1):\n    if arr[i] > arr[i+1]:\n        ___\nprint(arr)", "expected_output": "[3, 5, 1, 8]\n", "bonus_ram": 25 },
		{ "title": "Two Passes", "desc": "Perform TWO passes of bubble sort on [5,3,8,1] and print the array.", "code_template": "arr = [5, 3, 8, 1]\nfor _ in range(2):\n    for i in range(len(arr) - 1):\n        if arr[i] > arr[i+1]:\n            arr[i], arr[i+1] = arr[i+1], arr[i]\nprint(arr)", "expected_output": "[1, 3, 5, 8]\n", "bonus_ram": 25 },
		{ "title": "Count Swaps", "desc": "Count how many swaps happen during one bubble sort pass on [4,2,7,1] and print the count.", "code_template": "arr = [4, 2, 7, 1]\nswaps = 0\nfor i in range(len(arr) - 1):\n    if arr[i] > arr[i+1]:\n        arr[i], arr[i+1] = arr[i+1], arr[i]\n        ___\nprint(swaps)", "expected_output": "2\n", "bonus_ram": 25 },
	],
	6: [  # Selection Sort
		{ "title": "Find Min & Swap", "desc": "Find the minimum in [9,2,7,4] and swap it with the first element. Print the array.", "code_template": "arr = [9, 2, 7, 4]\nmin_idx = 0\nfor i in range(1, len(arr)):\n    if arr[i] < arr[min_idx]:\n        ___\narr[0], arr[min_idx] = arr[min_idx], arr[0]\nprint(arr)", "expected_output": "[2, 9, 7, 4]\n", "bonus_ram": 25 },
		{ "title": "Second Smallest", "desc": "Find the second smallest element in [9,2,7,4] and print it.", "code_template": "arr = [9, 2, 7, 4]\narr.sort()\nprint(___)", "expected_output": "4\n", "bonus_ram": 20 },
		{ "title": "Full Selection Sort", "desc": "Complete selection sort on [6,3,8,1] and print the sorted array.", "code_template": "arr = [6, 3, 8, 1]\nfor i in range(len(arr)):\n    min_idx = i\n    for j in range(i+1, len(arr)):\n        if arr[j] < arr[min_idx]:\n            min_idx = j\n    arr[i], arr[min_idx] = arr[min_idx], arr[i]\nprint(arr)", "expected_output": "[1, 3, 6, 8]\n", "bonus_ram": 25 },
	],
	7: [  # Insertion Sort
		{ "title": "Insert Third Element", "desc": "In [3,7,2,9], insert the third element (2) into the sorted portion. Print the array.", "code_template": "arr = [3, 7, 2, 9]\nkey = arr[2]\nj = 1\nwhile j >= 0 and arr[j] > key:\n    arr[j+1] = arr[j]\n    ___\narr[j+1] = key\nprint(arr)", "expected_output": "[2, 3, 7, 9]\n", "bonus_ram": 25 },
		{ "title": "Full Insertion Sort", "desc": "Complete insertion sort on [5,2,9,1,6] and print the sorted array.", "code_template": "arr = [5, 2, 9, 1, 6]\nfor i in range(1, len(arr)):\n    key = arr[i]\n    j = i - 1\n    while j >= 0 and arr[j] > key:\n        arr[j+1] = arr[j]\n        j -= 1\n    arr[j+1] = key\nprint(arr)", "expected_output": "[1, 2, 5, 6, 9]\n", "bonus_ram": 28 },
		{ "title": "Shifts Count", "desc": "Count how many shifts happen when inserting the last element of [2,5,7,3] and print the count.", "code_template": "arr = [2, 5, 7, 3]\nkey = arr[3]\nj = 2\nshifts = 0\nwhile j >= 0 and arr[j] > key:\n    arr[j+1] = arr[j]\n    j -= 1\n    ___\nprint(shifts)", "expected_output": "2\n", "bonus_ram": 25 },
	],
	8: [  # Quick Sort
		{ "title": "Partition by Pivot", "desc": "Partition [7,3,9,2,6] using last element (6) as pivot. Print partitioned array.", "code_template": "arr = [7, 3, 9, 2, 6]\npivot = arr[-1]\ni = 0\nfor j in range(len(arr) - 1):\n    if arr[j] < pivot:\n        arr[i], arr[j] = arr[j], arr[i]\n        ___\narr[i], arr[-1] = arr[-1], arr[i]\nprint(arr)", "expected_output": "[3, 2, 6, 7, 9]\n", "bonus_ram": 30 },
		{ "title": "Count Smaller", "desc": "Count how many elements are smaller than pivot 6 in [7,3,9,2,6] and print the count.", "code_template": "arr = [7, 3, 9, 2, 6]\npivot = 6\ncount = 0\nfor v in arr:\n    if v < pivot:\n        ___\nprint(count)", "expected_output": "2\n", "bonus_ram": 25 },
		{ "title": "Pivot Position", "desc": "After partitioning with last element as pivot, print the final index of the pivot.", "code_template": "arr = [7, 3, 9, 2, 6]\npivot = arr[-1]\ni = 0\nfor j in range(len(arr) - 1):\n    if arr[j] < pivot:\n        arr[i], arr[j] = arr[j], arr[i]\n        i += 1\narr[i], arr[-1] = arr[-1], arr[i]\nprint(___)", "expected_output": "2\n", "bonus_ram": 25 },
	],
	9: [  # Merge Sort
		{ "title": "Merge Two Halves", "desc": "Merge sorted arrays left=[1,4] and right=[2,3] into one sorted array and print.", "code_template": "left = [1, 4]\nright = [2, 3]\nmerged = []\ni = j = 0\nwhile i < len(left) and j < len(right):\n    if left[i] < right[j]:\n        merged.append(left[i]); i += 1\n    else:\n        ___\nmerged.extend(left[i:])\nmerged.extend(right[j:])\nprint(merged)", "expected_output": "[1, 2, 3, 4]\n", "bonus_ram": 30 },
		{ "title": "Merge Leftovers", "desc": "Merge left=[1,2,3] and right=[4,5,6]. After one list is exhausted, extend with the rest. Print merged.", "code_template": "left = [1, 2, 3]\nright = [4, 5, 6]\nmerged = []\ni = j = 0\nwhile i < len(left) and j < len(right):\n    if left[i] < right[j]:\n        merged.append(left[i]); i += 1\n    else:\n        merged.append(right[j]); j += 1\n___\nprint(merged)", "expected_output": "[1, 2, 3, 4, 5, 6]\n", "bonus_ram": 25 },
		{ "title": "Count Merge Ops", "desc": "Count how many comparisons when merging [1,4] and [2,3]. Print the count.", "code_template": "left = [1, 4]\nright = [2, 3]\ni = j = 0\ncompares = 0\nwhile i < len(left) and j < len(right):\n    if left[i] < right[j]:\n        i += 1\n    else:\n        j += 1\n    ___\nprint(compares)", "expected_output": "3\n", "bonus_ram": 25 },
	],
	10: [  # Counting Sort
		{ "title": "Count Frequencies", "desc": "Count how many times 0,1,2 appear in [2,0,2,1,1,0]. Print [count0, count1, count2].", "code_template": "arr = [2, 0, 2, 1, 1, 0]\ncounts = [0, 0, 0]\nfor v in arr:\n    ___\nprint(counts)", "expected_output": "[2, 2, 2]\n", "bonus_ram": 25 },
		{ "title": "Build Output", "desc": "Using counts=[2,2,2], build the sorted output array by repeating each index by its count. Print result.", "code_template": "counts = [2, 2, 2]\noutput = []\nfor val in range(len(counts)):\n    for _ in range(counts[val]):\n        ___\nprint(output)", "expected_output": "[0, 0, 1, 1, 2, 2]\n", "bonus_ram": 28 },
		{ "title": "Cumulative Counts", "desc": "Given counts=[2,2,2], compute cumulative counts [2,4,6] where each is sum of previous. Print cum.", "code_template": "counts = [2, 2, 2]\ncum = []\ntotal = 0\nfor c in counts:\n    total += c\n    ___\nprint(cum)", "expected_output": "[2, 4, 6]\n", "bonus_ram": 25 },
	],
	11: [  # Radix Sort
		{ "title": "Ones Digit", "desc": "Extract the ones-place digit from each number in [43,218,7,95] using num % 10. Print as a list.", "code_template": "arr = [43, 218, 7, 95]\ndigits = []\nfor num in arr:\n    digits.append(___)\nprint(digits)", "expected_output": "[3, 8, 7, 5]\n", "bonus_ram": 25 },
		{ "title": "Tens Digit", "desc": "Extract the tens-place digit from each number in [43,218,7,95] using (num // 10) % 10. Print as a list.", "code_template": "arr = [43, 218, 7, 95]\ndigits = []\nfor num in arr:\n    digits.append(___)\nprint(digits)", "expected_output": "[4, 1, 0, 9]\n", "bonus_ram": 25 },
		{ "title": "Max Digits", "desc": "Find how many digits the largest number in [43,218,7,95] has. Print the count.", "code_template": "arr = [43, 218, 7, 95]\nmax_val = max(arr)\ncount = 0\nwhile max_val > 0:\n    count += 1\n    ___\nprint(count)", "expected_output": "3\n", "bonus_ram": 25 },
	],
	12: [  # Linear Search
		{ "title": "Find Index", "desc": "Find the index of value 99 in [11,42,7,99,23] and print it (-1 if not found).", "code_template": "arr = [11, 42, 7, 99, 23]\ntarget = 99\nfound_idx = -1\nfor i in range(len(arr)):\n    if arr[i] == target:\n        found_idx = i\n        ___\nprint(found_idx)", "expected_output": "3\n", "bonus_ram": 20 },
		{ "title": "First Occurrence", "desc": "Find the first index where 7 appears in [7,3,7,1,7,9]. Print it.", "code_template": "arr = [7, 3, 7, 1, 7, 9]\ntarget = 7\nfor i in range(len(arr)):\n    if arr[i] == target:\n        print(i)\n        ___", "expected_output": "0\n", "bonus_ram": 20 },
		{ "title": "Count Occurrences", "desc": "Count how many times 7 appears in [7,3,7,1,7,9] and print the count.", "code_template": "arr = [7, 3, 7, 1, 7, 9]\ntarget = 7\ncount = 0\n___\nprint(count)", "expected_output": "3\n", "bonus_ram": 20 },
	],
	13: [  # Binary Search
		{ "title": "Find Target", "desc": "Binary search for 51 in [5,12,27,38,51,64,79]. Print its index.", "code_template": "arr = [5, 12, 27, 38, 51, 64, 79]\ntarget = 51\nlo, hi = 0, len(arr) - 1\nwhile lo <= hi:\n    mid = (lo + hi) // 2\n    if arr[mid] == target:\n        print(mid)\n        ___\n    elif arr[mid] < target:\n        lo = mid + 1\n    else:\n        hi = mid - 1", "expected_output": "4\n", "bonus_ram": 30 },
		{ "title": "Search Left Half", "desc": "Binary search for 5 (first element) in [5,12,27,38,51,64,79]. Print index.", "code_template": "arr = [5, 12, 27, 38, 51, 64, 79]\ntarget = 5\nlo, hi = 0, len(arr) - 1\nwhile lo <= hi:\n    mid = (lo + hi) // 2\n    if arr[mid] == target:\n        print(mid)\n        ___\n    elif arr[mid] < target:\n        lo = mid + 1\n    else:\n        hi = mid - 1", "expected_output": "0\n", "bonus_ram": 28 },
		{ "title": "Not Found", "desc": "Binary search for 99 (not present) in [5,12,27,38,51,64,79]. Print the index or -1.", "code_template": "arr = [5, 12, 27, 38, 51, 64, 79]\ntarget = 99\nlo, hi = 0, len(arr) - 1\nfound = -1\nwhile lo <= hi:\n    mid = (lo + hi) // 2\n    if arr[mid] == target:\n        found = mid\n        ___\n    elif arr[mid] < target:\n        lo = mid + 1\n    else:\n        hi = mid - 1\nprint(found)", "expected_output": "-1\n", "bonus_ram": 28 },
	],
}

# ─── TOWER DEFINITIONS ─────────────────────────────────
const TOWER_DEFINITIONS = {
		"tower_array": {
		"tower_id":       "tower_array",
		"tower_name":     "Array Tower",
		"description":    "Fast attack. O(1) access speed.",
		"data_structure": "Array",
		"ram_cost":       40,
		"damage":         18.0,
		"attack_speed":   2.0,
		"attack_range":   140.0,
		"time_complexity":"O(1)",
		"color":          Color("#00D4FF"),
		"icon_text":      "[ ]",
	},
	"tower_stack": {
		"tower_id":       "tower_stack",
		"tower_name":     "Stack Tower",
		"description":    "Hits most recent enemy. LIFO.",
		"data_structure": "Stack",
		"ram_cost":       60,
		"damage":         28.0,
		"attack_speed":   1.2,
		"attack_range":   130.0,
		"time_complexity":"O(1)",
		"color":          Color("#FF6B35"),
		"icon_text":      "↑↓",
	},
	"tower_queue": {
		"tower_id":       "tower_queue",
		"tower_name":     "Queue Tower",
		"description":    "Pierces 2 enemies. FIFO.",
		"data_structure": "Queue",
		"ram_cost":       60,
		"damage":         22.0,
		"attack_speed":   1.6,
		"attack_range":   160.0,
		"time_complexity":"O(1)",
		"color":          Color("#9B59B6"),
		"icon_text":      "→",
	},
	"tower_linked_list": {
		"tower_id":       "tower_linked_list",
		"tower_name":     "Linked Tower",
		"description":    "Chain damage 3 enemies.",
		"data_structure": "Linked List",
		"ram_cost":       80,
		"damage":         20.0,
		"attack_speed":   1.3,
		"attack_range":   150.0,
		"time_complexity":"O(n)",
		"color":          Color("#00FF88"),
		"icon_text":      "→→",
	},
	"tower_bubble": {
		"tower_id":       "tower_bubble",
		"tower_name":     "Bubble Tower",
		"description":    "AoE — hits all in range.",
		"data_structure": "Bubble Sort",
		"ram_cost":       70,
		"damage":         16.0,
		"attack_speed":   1.5,
		"attack_range":   130.0,
		"time_complexity":"O(n²)",
		"color":          Color("#FFB800"),
		"icon_text":      "↑↑",
	},
	"tower_selection": {
		"tower_id":       "tower_selection",
		"tower_name":     "Selection Tower",
		"description":    "Targets lowest HP enemy.",
		"data_structure": "Selection Sort",
		"ram_cost":       90,
		"damage":         24.0,
		"attack_speed":   1.0,
		"attack_range":   170.0,
		"time_complexity":"O(n²)",
		"color":          Color("#E74C3C"),
		"icon_text":      "→↓",
	},
	"tower_insertion": {
		"tower_id":       "tower_insertion",
		"tower_name":     "Insertion Tower",
		"description":    "Damage over time stacking.",
		"data_structure": "Insertion Sort",
		"ram_cost":       100,
		"damage":         18.0,
		"attack_speed":   1.4,
		"attack_range":   140.0,
		"time_complexity":"O(n)",
		"color":          Color("#1ABC9C"),
		"icon_text":      "←↑",
	},
	"tower_quick": {
		"tower_id":       "tower_quick",
		"tower_name":     "Quick Tower",
		"description":    "Splits shot hits 2 enemies.",
		"data_structure": "Quick Sort",
		"ram_cost":       130,
		"damage":         22.0,
		"attack_speed":   1.8,
		"attack_range":   155.0,
		"time_complexity":"O(n log n)",
		"color":          Color("#E91E63"),
		"icon_text":      "⚡",
	},
	"tower_merge": {
		"tower_id":       "tower_merge",
		"tower_name":     "Merge Tower",
		"description":    "Guaranteed AoE damage.",
		"data_structure": "Merge Sort",
		"ram_cost":       140,
		"damage":         20.0,
		"attack_speed":   1.4,
		"attack_range":   160.0,
		"time_complexity":"O(n log n)",
		"color":          Color("#3F51B5"),
		"icon_text":      "⊕",
	},
	"tower_counting": {
		"tower_id":       "tower_counting",
		"tower_name":     "Count Tower",
		"description":    "Stronger vs groups.",
		"data_structure": "Counting Sort",
		"ram_cost":       110,
		"damage":         14.0,
		"attack_speed":   2.2,
		"attack_range":   130.0,
		"time_complexity":"O(n+k)",
		"color":          Color("#009688"),
		"icon_text":      "#",
	},
	"tower_radix": {
		"tower_id":       "tower_radix",
		"tower_name":     "Radix Tower",
		"description":    "Rapid multi-pass bursts.",
		"data_structure": "Radix Sort",
		"ram_cost":       150,
		"damage":         12.0,
		"attack_speed":   3.0,
		"attack_range":   145.0,
		"time_complexity":"O(d×n)",
		"color":          Color("#FF5722"),
		"icon_text":      "0→9",
	},
	"tower_linear": {
		"tower_id":       "tower_linear",
		"tower_name":     "Linear Tower",
		"description":    "Wide scan, guaranteed hit.",
		"data_structure": "Linear Search",
		"ram_cost":       80,
		"damage":         16.0,
		"attack_speed":   1.0,
		"attack_range":   200.0,
		"time_complexity":"O(n)",
		"color":          Color("#607D8B"),
		"icon_text":      "→?",
	},
	"tower_binary": {
		"tower_id":       "tower_binary",
		"tower_name":     "Binary Tower",
		"description":    "Precision sniper. O(log n).",
		"data_structure": "Binary Search",
		"ram_cost":       200,
		"damage":         80.0,
		"attack_speed":   0.5,
		"attack_range":   250.0,
		"time_complexity":"O(log n)",
		"color":          Color("#8BC34A"),
		"icon_text":      "½",
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
	
	# Dynamically handle auto-centering of the grid system on any viewport screen size
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	_create_overlay_menu()
	_setup_sounds()
	SoundManager.play_level_music(level_number)
	_build_challenge_panel()
	if level_number == 1:
		call_deferred("_show_tutorial")
	else:
		call_deferred("_show_challenge")

func _exit_tree() -> void:
	SoundManager.stop_music()

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

	# Build tilemap visual (z_index -1 so it renders below GridSystem)
	var tilemap = preload("res://scenes/campaign/level/GridTilemap.gd").new()
	tilemap.name = "GridTilemap"
	tilemap.z_index = -1
	grid_visual.add_child(tilemap)
	var last_wp = waypoints[-1] if waypoints.size() > 0 else Vector2.ZERO
	var base_cell = Vector2i(int(last_wp.x / 64), int(last_wp.y / 64))
	tilemap.build_from_grid(grid_system, base_cell)

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
		AdaptiveAI.get_wave_modifier(level_number),
		config.get("enemy_types", ["basic_packet"])
	)

func _setup_hud() -> void:
	var config             = _get_level_config()
	level_label.text       = "Level " + str(level_number) + \
		" — " + config["name"]
	wave_label.text        = "0/" + str(config["waves"])
	base_health_label.text = str(base_health)
	score_label.text       = "0"
	back_btn.visible       = false
	back_btn.text = "Exit"
	level_label.visible    = false
	skip_wave_btn.text = "Skip (20⚡)"
	_update_ram_label()
	_build_tower_selector()
	_setup_wave_timeline()
	_setup_hud_icons()
	_setup_diff_badge()

func _setup_wave_timeline() -> void:
	for child in timeline_flags.get_children():
		child.queue_free()

	var total_waves = wave_manager.total_waves
	var timeline_width = 200.0

	wave_progress_bar.max_value = float(total_waves)
	wave_progress_bar.value = 0.0

	for i in range(1, total_waves + 1):
		var fraction = float(i) / float(total_waves)
		var x_pos = fraction * timeline_width

		var flag := ColorRect.new()
		flag.color = Color("#00D4FF")
		flag.custom_minimum_size = Vector2(8, 10)
		flag.size = Vector2(8, 10)
		flag.position = Vector2(x_pos - 4, -5)
		timeline_flags.add_child(flag)
		# Pulse animation on wave flags
		var t = create_tween().set_loops()
		t.tween_property(flag, "modulate", Color(1, 1, 1, 0.3), 0.8 + i * 0.1)
		t.tween_property(flag, "modulate", Color(1, 1, 1, 1), 0.8 + i * 0.1)

func _on_viewport_size_changed() -> void:
	var vp_size = get_viewport().get_visible_rect().size
	var grid_w = GridSystem.GRID_COLS * GridSystem.CELL_SIZE
	var grid_h = GridSystem.GRID_ROWS * GridSystem.CELL_SIZE
	var zoom_x = vp_size.x / grid_w
	var zoom_y = vp_size.y / grid_h
	var zoom = max(zoom_x, zoom_y)
	$GameCamera.zoom = Vector2(zoom, zoom)
	$GameCamera.position = Vector2(grid_w / 2.0, grid_h / 2.0)

func _build_tower_selector() -> void:
	pass

func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	pause_btn.pressed.connect(_on_pause_pressed)
	resume_btn.pressed.connect(_on_resume_pressed)
	retry_btn.pressed.connect(_on_retry_pressed)
	select_level_btn.pressed.connect(_on_select_level_pressed)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	skip_wave_btn.pressed.connect(_on_skip_wave_pressed)
	challenge_btn.pressed.connect(_show_challenge)

func _connect_signals() -> void:
	ram_manager.ram_changed.connect(_on_ram_changed)
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.all_waves_completed.connect(_on_all_waves_completed)
	SignalBus.enemy_reached_end.connect(_on_enemy_reached_end)
	SignalBus.enemy_defeated.connect(_on_enemy_defeated)

# ─── FEEDBACK HELPERS ──────────────────────────────────
func _setup_sounds() -> void:
	_sound_ok = AudioStreamPlayer2D.new()
	_sound_ok.stream = _generate_beep(520.0, 0.08)
	_sound_ok.volume_db = -6.0
	add_child(_sound_ok)
	_sound_fail = AudioStreamPlayer2D.new()
	_sound_fail.stream = _generate_beep(260.0, 0.12)
	_sound_fail.volume_db = -8.0
	add_child(_sound_fail)

func _generate_beep(freq: float, dur: float) -> AudioStreamWAV:
	var sr = 44100
	var frames = int(sr * dur)
	var data = PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / sr
		var amp = 1.0 - float(i) / frames
		var val = int(sin(t * freq * TAU) * amp * 8000)
		data.encode_s16(i * 2, clampi(val, -32768, 32767))
	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.mix_rate = sr
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = false
	return wav

func _spawn_floating_text(text: String, global_pos: Vector2, color: Color, size := 13) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", size)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD/HUDControl.add_child(lbl)
	lbl.reset_size()
	lbl.position = global_pos - Vector2(lbl.size.x / 2, 0)
	var tween = create_tween().set_parallel()
	tween.tween_property(lbl, "position", lbl.position + Vector2(0, -36), 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.8)
	tween.tween_callback(lbl.queue_free)

func _flash_ram_label(green: bool) -> void:
	var tween = create_tween()
	var c = Color("#00FF88") if green else Color("#FF3366")
	tween.tween_property(ram_label, "modulate", c, 0.08)
	tween.tween_property(ram_label, "modulate", Color("#FFFFFF"), 0.25)
	if not green:
		var orig = ram_label.offset_left
		var sh = create_tween().set_parallel()
		sh.tween_property(ram_label, "offset_left", orig - 4, 0.04)
		sh.tween_property(ram_label, "offset_left", orig + 4, 0.04)
		sh.tween_property(ram_label, "offset_left", orig, 0.04)

func _play_feedback(ok: bool) -> void:
	(_sound_ok if ok else _sound_fail).play()

# ─── OVERLAY MENU FOR PLACEMENT (CIRCULAR MODE - SHOWS EQUIPPED TOWER MODELS) ───────
var overlay_menu: Control = null
var current_clicked_cell: Vector2i = Vector2i(-1, -1)
var _current_menu_cell: Vector2i = Vector2i(-1, -1)
var _selected_tower: Node = null

var _tutorial_step: int = 0
var _tutorial_overlay: Control = null

func _show_tutorial() -> void:
	_tutorial_overlay = Control.new()
	_tutorial_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	$HUD/HUDControl.add_child(_tutorial_overlay)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	_tutorial_overlay.add_child(bg)

	_tutorial_step = 0
	_show_tutorial_step()

func _show_tutorial_step() -> void:
	for child in _tutorial_overlay.get_children():
		if child is ColorRect: continue
		child.queue_free()

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 220)
	card.set_anchors_preset(Control.PRESET_CENTER)
	var st := StyleBoxFlat.new()
	st.bg_color = Color("#0A1628")
	st.border_color = Color("#00D4FF")
	st.border_width_left = 2
	st.border_width_right = 2
	st.border_width_top = 2
	st.border_width_bottom = 2
	st.corner_radius_top_left = 12
	st.corner_radius_top_right = 12
	st.corner_radius_bottom_left = 12
	st.corner_radius_bottom_right = 12
	card.add_theme_stylebox_override("panel", st)
	_tutorial_overlay.add_child(card)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("margin_left", 20)
	layout.add_theme_constant_override("margin_right", 20)
	layout.add_theme_constant_override("margin_top", 20)
	layout.add_theme_constant_override("margin_bottom", 20)
	card.add_child(layout)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#00D4FF"))
	title.add_theme_font_size_override("font_size", 16)
	layout.add_child(title)

	var body := Label.new()
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", Color("#E8F4FD"))
	body.add_theme_font_size_override("font_size", 13)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)

	var steps_lbl := Label.new()
	steps_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	steps_lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	steps_lbl.add_theme_font_size_override("font_size", 10)
	layout.add_child(steps_lbl)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(160, 40)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 13)
	layout.add_child(btn)

	var tutorial_data = [
		{
			"title": "Welcome, Operator!",
			"body": "This is your first mission.\nPackets will flow along the path from left to right.\nYour job: place towers to destroy them before they reach the end."
		},
		{
			"title": "Placing Towers",
			"body": "Click on any highlighted grid cell to open the tower selector.\nChoose a tower to place it.\nEach tower costs RAM (shown on the button)."
		},
		{
			"title": "RAM & Waves",
			"body": "You earn RAM by destroying enemies and completing waves.\nUse RAM to place and upgrade towers.\nSurvive all waves with high base HP for a better grade!"
		},
		{
			"title": "Upgrading Towers",
			"body": "Click an existing tower to open its menu.\nUpgrade it to increase damage and range.\nUpgrades cost RAM — manage your budget wisely!"
		},
	]

	if _tutorial_step < tutorial_data.size():
		var d = tutorial_data[_tutorial_step]
		title.text = d["title"]
		body.text = d["body"]
		steps_lbl.text = "Step " + str(_tutorial_step + 1) + " of " + str(tutorial_data.size())
		btn.text = "Next →" if _tutorial_step < tutorial_data.size() - 1 else "Let's Go!"
		btn.pressed.connect(_on_tutorial_next)
	else:
		_tutorial_overlay.queue_free()
		_tutorial_overlay = null

func _on_tutorial_next() -> void:
	_tutorial_step += 1
	_show_tutorial_step()
	if _tutorial_overlay == null:
		call_deferred("_show_challenge")

func _create_overlay_menu() -> void:
	# Use Control instead of PanelContainer for custom radial layout
	overlay_menu = Control.new()
	overlay_menu.visible = false
	$HUD/HUDControl.add_child(overlay_menu)

func _on_overlay_tower_selected(tower_id: String) -> void:
	overlay_menu.visible = false
	var def = TOWER_DEFINITIONS[tower_id]
	if not ram_manager.can_afford(def["ram_cost"]):
		_flash_ram_label(false)
		_play_feedback(false)
		return
		
	selected_tower_data              = TowerData.new()
	selected_tower_data.tower_id     = def["tower_id"]
	selected_tower_data.tower_name   = def["tower_name"]
	selected_tower_data.ram_cost     = def["ram_cost"]
	selected_tower_data.damage       = def["damage"]
	selected_tower_data.attack_speed = def["attack_speed"]
	selected_tower_data.attack_range = def["attack_range"]
	selected_tower_data.color        = def["color"]
	selected_tower_data.icon_text    = def["icon_text"]
	
	_place_tower(current_clicked_cell)

# ─── GRID INTERACTION ──────────────────────────────────
func _on_cell_clicked(cell: Vector2i) -> void:
	if overlay_menu.visible and cell == _current_menu_cell:
		return
	_current_menu_cell = cell
	overlay_menu.visible = false
	for child in overlay_menu.get_children():
		child.queue_free()
	if is_instance_valid(_selected_tower):
		_selected_tower.set_selected(false)
	_selected_tower = null

	var existing = grid_system.get_tower_at(cell)
	if existing:
		_show_tower_menu(cell, existing)
		return

	if not grid_system.can_place_tower(cell):
		return

	current_clicked_cell = cell
	var cell_center = grid_system.get_cell_center(cell)
	var canvas_pos = get_canvas_transform() * cell_center
	overlay_menu.position = canvas_pos

	_show_placement_radial(cell)

func _show_tower_menu(cell: Vector2i, tower: Node) -> void:
	_selected_tower = tower
	tower.set_selected(true)
	var cell_center = grid_system.get_cell_center(cell)
	var canvas_pos = get_canvas_transform() * cell_center
	overlay_menu.position = canvas_pos

	var margin := 10
	var btn_w := 140
	var btn_h := 26
	var sep := 4
	var title_h := 18
	var num_rows = 1 + (1 if tower.current_level < tower.max_level else 0) + 1 + 1 + 1
	var total_h = title_h + num_rows * btn_h + (num_rows + 1) * sep + margin * 2
	var total_w = btn_w + margin * 2

	var bg := Panel.new()
	bg.custom_minimum_size = Vector2(total_w, total_h)
	bg.size = Vector2(total_w, total_h)
	bg.position = Vector2(-total_w / 2, -total_h / 2)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color("#070F1E", 0.95)
	bg_style.border_color = Color("#00D4FF")
	bg_style.border_width_left = 1
	bg_style.border_width_right = 1
	bg_style.border_width_top = 1
	bg_style.border_width_bottom = 1
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	bg.add_theme_stylebox_override("panel", bg_style)
	overlay_menu.add_child(bg)

	var layout := VBoxContainer.new()
	layout.position = Vector2(margin, margin + title_h + sep)
	layout.size = Vector2(btn_w, total_h - margin * 2 - title_h - sep)
	layout.add_theme_constant_override("separation", sep)
	bg.add_child(layout)

	var lvl_lbl := Label.new()
	lvl_lbl.text = tower.tower_name + " Lv." + str(tower.current_level)
	lvl_lbl.add_theme_color_override("font_color", Color("#00D4FF"))
	lvl_lbl.add_theme_font_size_override("font_size", 11)
	lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl_lbl.position = Vector2(margin, margin)
	lvl_lbl.size = Vector2(btn_w, title_h)
	bg.add_child(lvl_lbl)

	if tower.current_level < tower.max_level:
		var cost = tower.ram_cost * tower.current_level
		var upg_btn := Button.new()
		upg_btn.text = "⬆ Upgrade (" + str(cost) + "⚡)"
		upg_btn.custom_minimum_size = Vector2(btn_w, btn_h)
		upg_btn.size = Vector2(btn_w, btn_h)
		upg_btn.add_theme_font_size_override("font_size", 10)
		if ram_manager.can_afford(cost):
			upg_btn.add_theme_color_override("font_color", Color("#00FF88"))
		else:
			upg_btn.add_theme_color_override("font_color", Color("#FF3366"))
		upg_btn.pressed.connect(_on_upgrade_tower.bind(tower, cost))
		layout.add_child(upg_btn)

	var abil_cost = tower.get_ability_cost()
	var abil_btn := Button.new()
	abil_btn.text = "⚡ " + tower.get_ability_name() + " (" + str(abil_cost) + "⚡)"
	abil_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	abil_btn.size = Vector2(btn_w, btn_h)
	abil_btn.add_theme_font_size_override("font_size", 9)
	if tower.is_ability_ready() and ram_manager.can_afford(abil_cost):
		abil_btn.add_theme_color_override("font_color", Color("#FFB800"))
	else:
		abil_btn.add_theme_color_override("font_color", Color("#4A3A1A"))
	abil_btn.pressed.connect(_on_ability_used.bind(tower, abil_cost))
	layout.add_child(abil_btn)

	var sell_value = tower.ram_cost * tower.current_level
	var sell_btn := Button.new()
	sell_btn.text = "💰 Sell (" + str(sell_value) + "⚡)"
	sell_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	sell_btn.size = Vector2(btn_w, btn_h)
	sell_btn.add_theme_font_size_override("font_size", 9)
	sell_btn.add_theme_color_override("font_color", Color("#FF8844"))
	sell_btn.pressed.connect(_on_sell_tower.bind(cell, tower, sell_value))
	layout.add_child(sell_btn)

	var close_btn := Button.new()
	close_btn.text = "✕ Close"
	close_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	close_btn.size = Vector2(btn_w, btn_h)
	close_btn.add_theme_font_size_override("font_size", 9)
	close_btn.add_theme_color_override("font_color", Color("#4A7FA5"))
	close_btn.pressed.connect(func():
		overlay_menu.visible = false
		_current_menu_cell = Vector2i(-1, -1)
		if is_instance_valid(_selected_tower):
			_selected_tower.set_selected(false)
		_selected_tower = null)
	layout.add_child(close_btn)

	overlay_menu.visible = true

func _on_sell_tower(cell: Vector2i, tower: Node, value: int) -> void:
	ram_manager.earn(value)
	grid_system.remove_tower(cell)
	if is_instance_valid(_selected_tower):
		_selected_tower.set_selected(false)
	_selected_tower = null
	tower.queue_free()
	overlay_menu.visible = false
	_spawn_floating_text("+" + str(value) + "⚡ Sold!", tower.global_position, Color("#FF8844"), 14)
	_play_feedback(true)

func _on_upgrade_tower(tower: Node, cost: int) -> void:
	if not ram_manager.spend(cost):
		_flash_ram_label(false)
		_play_feedback(false)
		return
	var new_lvl = tower.upgrade()
	tower.set_selected(true)
	overlay_menu.visible = false
	_spawn_floating_text("⬆ Lv." + str(new_lvl), tower.global_position, Color("#00FF88"), 14)
	_play_feedback(true)

func _on_ability_used(tower: Node, cost: int) -> void:
	if not tower.is_ability_ready():
		_spawn_floating_text("⏳ Cooldown!", tower.global_position, Color("#4A3A1A"), 12)
		_play_feedback(false)
		return
	if not ram_manager.spend(cost):
		_flash_ram_label(false)
		_play_feedback(false)
		return
	tower.activate_ability()
	overlay_menu.visible = false
	_spawn_floating_text(tower.get_ability_name() + "!", tower.global_position, Color("#FFB800"), 14)
	_play_feedback(true)

func _show_placement_radial(cell: Vector2i) -> void:
	# Determine equipped towers (bring/equip from tower select)
	var equipped = GameManager.selected_towers
	if equipped.is_empty():
		equipped = _get_level_config().get("towers", [])
	if equipped.is_empty():
		# Fail-safe backup
		equipped = ["tower_array", "tower_stack", "tower_queue", "tower_linked_list", "tower_bubble"]
		
	# Build radial selection
	var num_options = equipped.size()
	var radius = 72.0
	var btn_size = 54.0
	
	for i in range(num_options):
		var tower_id = equipped[i]
		if not TOWER_DEFINITIONS.has(tower_id):
			continue
		var def = TOWER_DEFINITIONS[tower_id]
		
		# Compute angle position
		var angle = -PI/2 + (i * 2.0 * PI / num_options)
		var offset_pos = Vector2(cos(angle), sin(angle)) * radius
		
		# Generous touch target button (Works beautifully on mobile)
		var btn := TextureButton.new()
		btn.custom_minimum_size = Vector2(btn_size, btn_size)
		btn.size = Vector2(btn_size, btn_size)
		btn.position = offset_pos - Vector2(btn_size/2.0, btn_size/2.0)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_SCALE
		
		# Style circular icon container
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color("#070F1E", 0.9)
		normal_style.border_color = Color(def["color"])
		normal_style.border_width_left = 2
		normal_style.border_width_right = 2
		normal_style.border_width_top = 2
		normal_style.border_width_bottom = 2
		normal_style.corner_radius_top_left = int(btn_size / 2.0)
		normal_style.corner_radius_top_right = int(btn_size / 2.0)
		normal_style.corner_radius_bottom_left = int(btn_size / 2.0)
		normal_style.corner_radius_bottom_right = int(btn_size / 2.0)
		
		# Display StyleBox as backdrop on the button using a Panel
		var bg_panel := Panel.new()
		bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg_panel.add_theme_stylebox_override("panel", normal_style)
		btn.add_child(bg_panel)
		
		# Create a sub-viewport or small instanced tower that displays the actual model directly!
		# Since Godot 4 allows us to put Node2D inside Control using a Node2D container or directly,
		# let's instantiate the actual tower scene directly inside the button as a lightweight visual node.
		var tower_scene = load("res://scenes/campaign/towers/Tower.tscn")
		var visual_tower = tower_scene.instantiate()
		
		# Initialize visual tower node
		var dummy_data = TowerData.new()
		dummy_data.tower_id = def["tower_id"]
		dummy_data.tower_name = def["tower_name"]
		dummy_data.ram_cost = def["ram_cost"]
		dummy_data.damage = def["damage"]
		dummy_data.attack_speed = def["attack_speed"]
		dummy_data.attack_range = def["attack_range"]
		dummy_data.color = def["color"]
		dummy_data.icon_text = def["icon_text"]
		
		visual_tower.initialize(dummy_data, Vector2i(-1, -1), null)
		visual_tower.position = Vector2(btn_size / 2.0, btn_size / 2.0)
		
		# Scale down model nicely so it fits perfect in the circular button
		visual_tower.scale = Vector2(0.5, 0.5)
		
		# Strip game behaviors from visual preview model
		visual_tower.set_process(false)
		visual_tower.set_physics_process(false)
		visual_tower.set_process_input(false)
		
		btn.add_child(visual_tower)
		
		# Price Tag (small overlay at the bottom of the node)
		var price_lbl := Label.new()
		price_lbl.text = str(def["ram_cost"])
		price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_lbl.add_theme_font_size_override("font_size", 8)
		price_lbl.add_theme_color_override("font_color", Color("#00D4FF"))
		price_lbl.position = Vector2(0, btn_size - 8)
		price_lbl.custom_minimum_size = Vector2(btn_size, 10)
		price_lbl.size = Vector2(btn_size, 10)
		price_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(price_lbl)
		
		# Connect trigger action
		btn.pressed.connect(_on_overlay_tower_selected.bind(tower_id))
		overlay_menu.add_child(btn)
		
	# Small Central "Close" Button
	var center_close := Button.new()
	center_close.text = "X"
	center_close.custom_minimum_size = Vector2(24, 24)
	center_close.size = Vector2(24, 24)
	center_close.position = Vector2(-12, -12)
	center_close.add_theme_color_override("font_color", Color("#FF3366"))
	center_close.add_theme_font_size_override("font_size", 9)
	
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color("#12050E")
	close_style.border_color = Color("#FF3366")
	close_style.border_width_left = 1
	close_style.border_width_right = 1
	close_style.border_width_top = 1
	close_style.border_width_bottom = 1
	close_style.corner_radius_top_left = 12
	close_style.corner_radius_top_right = 12
	close_style.corner_radius_bottom_left = 12
	close_style.corner_radius_bottom_right = 12
	center_close.add_theme_stylebox_override("normal", close_style)
	
	center_close.pressed.connect(func(): overlay_menu.visible = false; _current_menu_cell = Vector2i(-1, -1))
	overlay_menu.add_child(center_close)
	
	# Clamp positions of buttons inside screen borders for mobile viewports
	var screen_size = get_viewport_rect().size
	var menu_offset_x = clamp(overlay_menu.position.x, 90.0, screen_size.x - 90.0) - overlay_menu.position.x
	var menu_offset_y = clamp(overlay_menu.position.y, 90.0, screen_size.y - 90.0) - overlay_menu.position.y
	overlay_menu.position += Vector2(menu_offset_x, menu_offset_y)
	
	overlay_menu.visible = true

func _place_tower(cell: Vector2i) -> void:
	ram_manager.spend(selected_tower_data.ram_cost)

	var tower_scene = preload(
		"res://scenes/campaign/towers/Tower.tscn"
	)
	var tower = tower_scene.instantiate()
	tower_layer.add_child(tower)
	tower.position = grid_system.get_cell_center(cell)
	tower.initialize(selected_tower_data, cell, enemy_layer)
	grid_system.place_tower(cell, tower)

	SignalBus.tower_placed.emit(selected_tower_data.tower_id, cell)
	print("[Level] Tower placed at: ", cell)
	
	grid_system.first_tower_placed.emit(selected_tower_data.tower_id)
	_play_feedback(true)

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
	_spawn_floating_text("Click to place " + def["tower_name"] + " (" + str(def["ram_cost"]) + "⚡)",
		Vector2(get_viewport_rect().size.x / 2, 36), Color("#00D4FF"), 11)

# ─── PROCESS ───────────────────────────────────────────
func _process(delta: float) -> void:
	if countdown_active and not is_level_ended:
		wave_countdown -= delta
		if wave_countdown <= 0.0:
			wave_countdown = 0.0
			countdown_active = false
			_trigger_wave_start()
	_update_wave_progress_bar()

func _trigger_wave_start() -> void:
	if wave_manager.wave_in_progress or is_level_ended:
		return
	wave_manager.start_next_wave()

func _update_wave_progress_bar() -> void:
	if is_level_ended:
		skip_wave_btn.disabled = true
		return

	var total_waves = wave_manager.total_waves
	var current_wave = wave_manager.current_wave

	if wave_manager.wave_in_progress:
		wave_progress_bar.value = float(current_wave)
		skip_wave_btn.disabled = true
	else:
		if current_wave >= total_waves:
			wave_progress_bar.value = float(total_waves)
			skip_wave_btn.disabled = true
		else:
			var progress_frac = 1.0 - (wave_countdown / INTER_WAVE_DURATION)
			wave_progress_bar.value = float(current_wave) + progress_frac
			skip_wave_btn.disabled = false

func _setup_diff_badge() -> void:
	if _diff_badge != null and is_instance_valid(_diff_badge):
		_diff_badge.queue_free()
	var mod = AdaptiveAI.get_wave_modifier(level_number)
	var label = _get_diff_label(mod)
	_diff_badge = Button.new()
	_diff_badge.text = label
	_diff_badge.add_theme_color_override("font_color", _get_diff_color(mod))
	_diff_badge.add_theme_font_size_override("font_size", 11)
	_diff_badge.flat = true
	_diff_badge.pressed.connect(_show_diff_popup.bind(mod))
	challenge_btn.add_sibling(_diff_badge)

func _show_diff_popup(mod: float) -> void:
	SignalBus.hud_message_requested.emit(_get_diff_tip(mod), 3.0)

func _get_diff_label(mod: float) -> String:
	if mod < 0.7: return "⚡ EASY"
	if mod < 0.95: return "⚡ NORMAL"
	if mod < 1.25: return "⚡ HARD"
	return "⚡ EXPERT"

func _get_diff_color(mod: float) -> Color:
	if mod < 0.7: return Color("#4A7FA5")
	if mod < 0.95: return Color("#00FF88")
	if mod < 1.25: return Color("#FFB800")
	return Color("#FF3366")

func _get_diff_tip(mod: float) -> String:
	if mod < 0.7: return "Easy mode: Enemies have 30% less HP, move slower, and spawn slower."
	if mod < 0.95: return "Normal mode: Default enemy stats."
	if mod < 1.25: return "Hard mode: Enemies have 35% more HP, move faster, and spawn quicker!"
	return "Expert mode: Enemies have 60% more HP, move much faster, and spawn back-to-back!"

func _show_wave_splash_animation(wave_num: int) -> void:
	var text = "WAVE %d" % wave_num
	if wave_num == 1:
		var mod = AdaptiveAI.get_wave_modifier(level_number)
		var label = _get_diff_label(mod)
		text += "\n" + label
		print("[AdaptiveAI] Difficulty: ", label, " (", snapped(mod, 0.01), "x)")
		_diff_badge.text = label
		_diff_badge.add_theme_color_override("font_color", _get_diff_color(mod))
	wave_splash_label.text = text
	wave_splash_label.modulate = Color("#00FF88")
	wave_splash_label.scale = Vector2(0.5, 0.5)
	wave_splash_label.pivot_offset = wave_splash_label.size / 2.0
	wave_splash.visible = true
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(wave_splash_label, "modulate:a", 1.0, 0.4).from(0.0)
	tween.tween_property(wave_splash_label, "scale", Vector2(1.2, 1.2), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var seq = create_tween()
	seq.tween_interval(1.8)
	seq.tween_property(wave_splash_label, "modulate:a", 0.0, 0.5)
	seq.tween_callback(func(): wave_splash.visible = false)

# ─── INPUT ─────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_pause_pressed()

# ─── PAUSE HANDLERS ────────────────────────────────────
func _on_pause_pressed() -> void:
	get_tree().paused = true
	pause_menu.visible = true

func _on_resume_pressed() -> void:
	get_tree().paused = false
	pause_menu.visible = false

func _on_select_level_pressed() -> void:
	get_tree().paused = false
	GameManager.go_to("campaign")

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	GameManager.go_to("main_menu")

func _on_skip_wave_pressed() -> void:
	if wave_manager.wave_in_progress or is_level_ended:
		return
	if ram_manager.spend(20):
		wave_countdown = 0.0
		countdown_active = false
		_trigger_wave_start()
		_play_feedback(true)
	else:
		_flash_ram_label(false)
		_play_feedback(false)

# ─── SIGNAL HANDLERS ───────────────────────────────────
func _on_ram_changed(current: int, _max_ram: int) -> void:
	_update_ram_label()
	if _prev_ram >= 0:
		if current > _prev_ram:
			_flash_ram_label(true)
		elif current < _prev_ram:
			_flash_ram_label(false)
	_prev_ram = current

func _on_wave_started(wave_num: int, total: int) -> void:
	wave_label.text = str(wave_num) + "/" + str(total)
	countdown_active = false
	_show_wave_splash_animation(wave_num)

func _on_wave_completed(wave_num: int) -> void:
	score            += 100 * wave_num
	score_label.text  = str(score)
	ram_manager.earn(50)
	wave_countdown = INTER_WAVE_DURATION
	countdown_active = true
	_spawn_floating_text("Wave " + str(wave_num) + " done! +50⚡",
		Vector2(get_viewport_rect().size.x / 2, 60), Color("#00FF88"), 13)
	_play_feedback(true)

func _calc_performance() -> float:
	return float(base_health) * 6.0 + min(float(score), 40.0)

func _get_stars() -> int:
	var p = _calc_performance()
	if p >= 90:
		return 3
	elif p >= 70:
		return 2
	return 1

func _on_all_waves_completed() -> void:
	if is_level_ended:
		return
	is_level_ended = true
	var elapsed = (Time.get_ticks_msec() / 1000.0) - level_start_time
	var stars = _get_stars()
	var grade_dict = _get_grade()
	var grade = grade_dict.letter
	var topic_id = ProgressManager.get_topic_for_level(level_number)
	ProgressManager.set_level_stars(level_number, stars)
	ProgressManager.on_level_completed(level_number)
	SupabaseManager.submit_campaign_score(level_number, elapsed, score)
	AdaptiveAI.record_level_performance(topic_id, grade, score, elapsed)
	_show_result_panel(true)

func _on_enemy_reached_end(_enemy_id: String) -> void:
	if is_level_ended:
		return
	base_health -= 1
	_update_base_health_label()
	if base_health <= 0:
		is_level_ended = true
		var topic_id = ProgressManager.get_topic_for_level(level_number)
		AdaptiveAI.record_level_performance(topic_id, "F", 0, 0.0)
		_show_result_panel(false)

func _on_enemy_defeated(_enemy_id: String) -> void:
	ram_manager.earn(10)
	score            += 10
	score_label.text  = str(score)

# ─── BASE HEALTH ───────────────────────────────────────
func heal_base(amount: int) -> void:
	"""Heal the base by the given amount"""
	base_health = min(base_health + amount, 10)
	_update_base_health_label()
	_spawn_floating_text("💚 +" + str(amount) + " HP", base_health_label.global_position - Vector2(0, 16), Color("#00FF88"), 13)
	_play_feedback(true)

func _update_base_health_label() -> void:
	base_health_label.text = str(base_health)
	var tween = create_tween()
	tween.tween_property(
		base_health_label, "modulate", Color("#FF0000"), 0.1
	)
	tween.tween_property(
		base_health_label, "modulate", Color("#FFFFFF"), 0.3
	)
	if base_health <= 3:
		_spawn_floating_text("Base Critical!", base_health_label.global_position - Vector2(0, 36), Color("#FF3366"), 14)
		_play_feedback(false)

# ─── RESULT PANEL ──────────────────────────────────────
func _show_result_panel(victory: bool) -> void:
	SoundManager.stop_music()
	if victory:
		SoundManager.play_game_over()
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
		var stars = _get_stars()
		var star_str = ""
		for s in range(3):
			star_str += "⭐" if s < stars else "☆"
		var star_lbl := Label.new()
		star_lbl.text = star_str
		star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_lbl.add_theme_font_size_override("font_size", 28)
		layout.add_child(star_lbl)
		SignalBus.level_complete.emit(level_number, score, stars)

	if victory:
		var unlock_lbl := Label.new()
		unlock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unlock_lbl.add_theme_color_override("font_color", Color("#00D4FF"))
		unlock_lbl.add_theme_font_size_override("font_size", 14)
		if ProgressManager.LEVEL_UNLOCKS_LESSON.has(level_number):
			var next_lesson = ProgressManager.LEVEL_UNLOCKS_LESSON[level_number]
			unlock_lbl.text = "🔓 New lesson unlocked: " + next_lesson
		layout.add_child(unlock_lbl)

	var stats_row := HBoxContainer.new()
	stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_row.add_theme_constant_override("separation", 24)
	_add_result_stat(stats_row, "BASE HP",  str(base_health) + "/10")
	_add_result_stat(stats_row, "WAVES",
		str(wave_manager.current_wave) + "/" + str(wave_manager.total_waves))
	var elapsed = int((Time.get_ticks_msec() / 1000.0) - level_start_time)
	_add_result_stat(stats_row, "TIME", str(elapsed) + "s")
	layout.add_child(stats_row)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)

	var retry_btn := Button.new()
	retry_btn.text = "↺ Retry"
	retry_btn.custom_minimum_size = Vector2(120, 44)
	retry_btn.pressed.connect(_on_retry_pressed)
	btn_row.add_child(retry_btn)

	var menu_btn := Button.new()
	menu_btn.text = "🏠 Level Select"
	menu_btn.custom_minimum_size = Vector2(140, 44)
	menu_btn.pressed.connect(_on_menu_pressed)
	btn_row.add_child(menu_btn)

	layout.add_child(btn_row)
	game_over_panel.add_child(layout)
	game_over_panel.visible = true

func _on_retry_pressed() -> void:
	if _is_retrying:
		return
	_is_retrying = true
	call_deferred(&"_do_retry")

func _do_retry() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/retry_redirect/retry_redirect.tscn")

func _on_menu_pressed() -> void:
	GameManager.go_to("campaign")

func _get_grade() -> Dictionary:
	var p = _calc_performance()
	if p >= 90:
		return {"letter": "S", "color": Color("#FFD700")}
	elif p >= 70:
		return {"letter": "A", "color": Color("#00FF88")}
	elif p >= 50:
		return {"letter": "B", "color": Color("#00D4FF")}
	elif p >= 30:
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
	ram_label.text = str(ram_manager.get_current()) + " RAM"

func _get_level_config() -> Dictionary:
	if GameManager.LEVEL_CONFIGS.has(level_number):
		return GameManager.LEVEL_CONFIGS[level_number]
	return GameManager.LEVEL_CONFIGS[1]

# ─── HUD ICONS ─────────────────────────────────────────
func _make_icon(draw_fn: Callable) -> ImageTexture:
	var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	draw_fn.call(img)
	return ImageTexture.create_from_image(img)

func _icon_chip() -> ImageTexture:
	return _make_icon(func(img):
		for x in range(4, 20):
			for y in range(6, 18):
				img.set_pixel(x, y, Color(0.0, 0.6, 1.0, 0.3))
		for i in range(4):
			for x in range(4 + i*4, 7 + i*4):
				for y in range(2, 6):
					img.set_pixel(x, y, Color(0.0, 0.8, 1.0, 0.6))
				for y in range(18, 22):
					img.set_pixel(x, y, Color(0.0, 0.8, 1.0, 0.6))
		for r in range(3):
			for dx in range(-r, r+1):
				for dy in range(-r, r+1):
					img.set_pixel(12 + dx, 12 + dy, Color(0.0, 1.0, 0.5, 0.5 - r * 0.15))
	)

func _icon_shield() -> ImageTexture:
	return _make_icon(func(img):
		for y in range(3, 20):
			var hw = int(10.0 * (1.0 - float(y - 3) / 17.0 * 0.4))
			for x in range(12 - hw, 12 + hw):
				img.set_pixel(x, y, Color(0.0, 1.0, 0.5, 0.5))
			if y >= 5 and y <= 18:
				var ihw = int(8.0 * (1.0 - float(y - 5) / 13.0 * 0.4))
				for x in range(12 - ihw, 12 + ihw):
					img.set_pixel(x, y, Color(0.0, 0.4, 0.2, 0.3))
		for x in range(9, 16):
			for y in range(8, 17):
				img.set_pixel(x, y, Color(0.0, 0.8, 1.0, 0.4))
	)

func _icon_star() -> ImageTexture:
	return _make_icon(func(img):
		for i in range(5):
			var a = -PI/2 + i * 2*PI/5
			var px = int(12 + cos(a) * 9.0)
			var py = int(12 + sin(a) * 9.0)
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var d = Vector2(px + dx - 12, py + dy - 12).length() / 9.0
					img.set_pixel(px + dx, py + dy, Color(1.0, 0.7, 0.0, 0.5 - d * 0.3))
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				var d = Vector2(dx, dy).length() / 3.0
				img.set_pixel(12 + dx, 12 + dy, Color(1.0, 0.9, 0.4, 0.6 - d * 0.2))
	)

func _icon_signal() -> ImageTexture:
	return _make_icon(func(img):
		var bars = [4, 7, 10, 13]
		var heights = [4, 8, 12, 16]
		var cols = [Color(0.0, 0.4, 0.6, 0.4), Color(0.0, 0.6, 0.8, 0.5), Color(0.0, 0.8, 1.0, 0.6), Color(0.0, 1.0, 0.8, 0.7)]
		for i in range(4):
			var bx = bars[i]
			for y in range(21 - heights[i], 20):
				for x in range(bx, bx + 3):
					img.set_pixel(x, y, cols[i])
	)

func _icon_pause() -> ImageTexture:
	return _make_icon(func(img):
		for bar_x in [7, 14]:
			for x in range(bar_x, bar_x + 3):
				for y in range(4, 20):
					img.set_pixel(x, y, Color(0.0, 0.8, 1.0, 0.7))
	)

func _icon_skip() -> ImageTexture:
	return _make_icon(func(img):
		for y in range(4, 20):
			var hw = int((y - 3) * 7.0 / 16.0)
			for x in range(12 - hw, 12):
				img.set_pixel(x, y, Color(0.0, 1.0, 0.5, 0.6))
			for x in range(17 - hw, 17):
				var c = img.get_pixel(x, y)
				c = c.blend(Color(0.0, 1.0, 0.5, 0.6))
				img.set_pixel(x, y, c)
		for x in range(21, 23):
			for y in range(4, 20):
				var c = img.get_pixel(x, y)
				c = c.blend(Color(0.0, 0.8, 1.0, 0.5))
				img.set_pixel(x, y, c)
	)

func _icon_power() -> ImageTexture:
	return _make_icon(func(img):
		for a in range(360):
			var rad = a * PI / 180.0
			if a > 45 and a < 135:
				continue
			for r in range(7, 10):
				var px = int(12 + cos(rad) * r)
				var py = int(12 + sin(rad) * r)
				if px >= 0 and px < 24 and py >= 0 and py < 24:
					img.set_pixel(px, py, Color(0.0, 0.8, 1.0, 0.3 + (r - 7) * 0.15))
		for y in range(3, 14):
			for x in range(11, 14):
				img.set_pixel(x, y, Color(0.0, 0.8, 1.0, 0.6))
	)

func _setup_hud_icons() -> void:
	var top = $HUD/HUDControl/TopHUD/TopLayout
	var icon_size = Vector2(18, 18)
	
	_add_icon_before_label(top, _icon_chip(), ram_label, icon_size)
	_add_icon_before_label(top, _icon_shield(), base_health_label, icon_size)
	_add_icon_before_label(top, _icon_star(), score_label, icon_size)
	_add_icon_before_label(top, _icon_signal(), wave_label, icon_size)
	
	pause_btn.icon = _icon_pause()
	pause_btn.expand_icon = true
	pause_btn.text = ""
	skip_wave_btn.icon = _icon_skip()
	skip_wave_btn.expand_icon = true
	back_btn.icon = _icon_power()
	back_btn.expand_icon = true

func _add_icon_before_label(parent: Node, icon_tex: ImageTexture, label: Label, icon_size: Vector2) -> void:
	var icon_rect = TextureRect.new()
	icon_rect.texture = icon_tex
	icon_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = icon_size
	icon_rect.size = icon_size
	parent.add_child(icon_rect)
	var idx = label.get_index()
	parent.move_child(icon_rect, idx)
	label.add_theme_constant_override("margin_left", 4)

# ─── HUD STYLES ────────────────────────────────────────
func _apply_hud_styles() -> void:
	var top_style := StyleBoxEmpty.new()
	$HUD/HUDControl/TopHUD.add_theme_stylebox_override("panel", top_style)

	var go_style := StyleBoxFlat.new()
	go_style.bg_color                    = Color("#050D1A")
	go_style.border_color                = Color("#00D4FF")
	go_style.border_width_left           = 1
	go_style.border_width_right          = 1
	go_style.border_width_top            = 1
	go_style.border_width_bottom         = 1
	go_style.corner_radius_top_left      = 8
	go_style.corner_radius_top_right     = 8
	go_style.corner_radius_bottom_left   = 8
	go_style.corner_radius_bottom_right  = 8
	$HUD/HUDControl/GameOverPanel.add_theme_stylebox_override(
		"panel", go_style
	)

	var pause_menu_style := StyleBoxFlat.new()
	pause_menu_style.bg_color                    = Color("#050D1A")
	pause_menu_style.border_color                = Color("#00D4FF")
	pause_menu_style.border_width_left           = 1
	pause_menu_style.border_width_right          = 1
	pause_menu_style.border_width_top            = 1
	pause_menu_style.border_width_bottom         = 1
	pause_menu_style.corner_radius_top_left      = 8
	pause_menu_style.corner_radius_top_right     = 8
	pause_menu_style.corner_radius_bottom_left   = 8
	pause_menu_style.corner_radius_bottom_right  = 8
	pause_menu.add_theme_stylebox_override("panel", pause_menu_style)

	_style_neon_btn(pause_btn, Color("#00D4FF"))
	_style_neon_btn(skip_wave_btn, Color("#FFB800"))
	_style_neon_btn(back_btn, Color("#FF3366"))

	# Style pause menu buttons
	_style_neon_btn(resume_btn, Color("#00FF88"))
	_style_neon_btn(retry_btn, Color("#00D4FF"))
	_style_neon_btn(select_level_btn, Color("#FFB800"))
	_style_neon_btn(main_menu_btn, Color("#FF3366"))

	var bg_bar_style := StyleBoxFlat.new()
	bg_bar_style.bg_color = Color("#050D1A")
	bg_bar_style.corner_radius_top_left = 4
	bg_bar_style.corner_radius_top_right = 4
	bg_bar_style.corner_radius_bottom_left = 4
	bg_bar_style.corner_radius_bottom_right = 4
	wave_progress_bar.add_theme_stylebox_override("background", bg_bar_style)

	var fill_bar_style := StyleBoxFlat.new()
	fill_bar_style.bg_color = Color("#00FF88")
	fill_bar_style.corner_radius_top_left = 4
	fill_bar_style.corner_radius_top_right = 4
	fill_bar_style.corner_radius_bottom_left = 4
	fill_bar_style.corner_radius_bottom_right = 4
	wave_progress_bar.add_theme_stylebox_override("fill", fill_bar_style)

func _style_neon_btn(btn: Button, color: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#0A1628")
	normal.border_color = color
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_font_size_override("font_size", 11)

	var hover := StyleBoxFlat.new()
	hover.bg_color = color
	hover.bg_color.a = 0.15
	hover.border_color = color
	hover.border_width_left = 1
	hover.border_width_right = 1
	hover.border_width_top = 1
	hover.border_width_bottom = 1
	hover.corner_radius_top_left = 4
	hover.corner_radius_top_right = 4
	hover.corner_radius_bottom_left = 4
	hover.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_hover_color", color.lightened(0.4))

func _style_tower_btn(btn: Button, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color                    = Color("#0A1628")
	style.border_color                = color
	style.border_width_left           = 1
	style.border_width_right          = 1
	style.border_width_top            = 1
	style.border_width_bottom         = 1
	style.corner_radius_top_left      = 4
	style.corner_radius_top_right     = 4
	style.corner_radius_bottom_left   = 4
	style.corner_radius_bottom_right  = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_font_size_override("font_size", 11)

# ─── CODING CHALLENGE PANEL ─────────────────────────────
func _style_challenge_btn(btn: Button, color: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#0A1628")
	s.border_color = color
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_font_size_override("font_size", 11)
	var hover := StyleBoxFlat.new()
	hover.bg_color = color
	hover.bg_color.a = 0.15
	hover.border_color = color
	hover.border_width_left = 1
	hover.border_width_right = 1
	hover.border_width_top = 1
	hover.border_width_bottom = 1
	hover.corner_radius_top_left = 4
	hover.corner_radius_top_right = 4
	hover.corner_radius_bottom_left = 4
	hover.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_hover_color", color.lightened(0.4))
var _challenge_code_edit: TextEdit = null
var _challenge_output: Label = null
var _challenge_title: Label = null
var _challenge_desc: Label = null
var _challenge_result: Label = null

func _build_challenge_panel() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#080F1E")
	style.border_color = Color("#00D4FF")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	micro_panel.add_theme_stylebox_override("panel", style)

	var layout = VBoxContainer.new()
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 6)
	micro_panel.add_child(layout)

	var header = HBoxContainer.new()
	_challenge_title = Label.new()
	_challenge_title.add_theme_font_size_override("font_size", 14)
	_challenge_title.add_theme_color_override("font_color", Color("#00D4FF"))
	header.add_child(_challenge_title)
	var hspacer = Control.new()
	hspacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(hspacer)
	layout.add_child(header)

	_challenge_desc = Label.new()
	_challenge_desc.add_theme_font_size_override("font_size", 10)
	_challenge_desc.add_theme_color_override("font_color", Color("#A0B8D0"))
	_challenge_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_challenge_desc)

	_challenge_code_edit = TextEdit.new()
	_challenge_code_edit.custom_minimum_size = Vector2(0, 120)
	_challenge_code_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_challenge_code_edit.add_theme_font_override("font", ThemeDB.fallback_font)
	_challenge_code_edit.add_theme_font_size_override("font_size", 11)
	_challenge_code_edit.add_theme_color_override("background_color", Color("#030812"))
	_challenge_code_edit.add_theme_color_override("font_color", Color("#FFFFFF"))
	_challenge_code_edit.add_theme_color_override("caret_color", Color("#00D4FF"))
	_challenge_code_edit.add_theme_color_override("selection_color", Color("#00D4FF", 0.3))
	_challenge_code_edit.syntax_highlighter = null
	_challenge_code_edit.highlight_all_occurrences = false
	layout.add_child(_challenge_code_edit)

	var btn_row = HBoxContainer.new()
	var run_btn = Button.new()
	run_btn.text = "▶ Run Code"
	run_btn.custom_minimum_size = Vector2(110, 28)
	run_btn.pressed.connect(_on_challenge_run)
	_style_challenge_btn(run_btn, Color("#00FF88"))
	btn_row.add_child(run_btn)
	var submit_btn = Button.new()
	submit_btn.text = "✔ Submit"
	submit_btn.custom_minimum_size = Vector2(110, 28)
	submit_btn.pressed.connect(_on_challenge_submit)
	_style_challenge_btn(submit_btn, Color("#00D4FF"))
	btn_row.add_child(submit_btn)
	var skip_btn = Button.new()
	skip_btn.text = "⏭ Skip"
	skip_btn.custom_minimum_size = Vector2(90, 28)
	skip_btn.pressed.connect(_on_challenge_skip)
	_style_challenge_btn(skip_btn, Color("#4A7FA5"))
	btn_row.add_child(skip_btn)
	btn_row.add_theme_constant_override("separation", 6)
	layout.add_child(btn_row)

	_challenge_output = Label.new()
	_challenge_output.add_theme_font_size_override("font_size", 10)
	_challenge_output.add_theme_color_override("font_color", Color("#4A7FA5"))
	_challenge_output.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_challenge_output.custom_minimum_size = Vector2(0, 40)
	layout.add_child(_challenge_output)

	_challenge_result = Label.new()
	_challenge_result.add_theme_font_size_override("font_size", 11)
	_challenge_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(_challenge_result)

	micro_panel.visible = false

func _show_challenge() -> void:
	if _challenge_progress >= 3:
		return
	var level_num = level_number
	var challenges = CHALLENGES.get(level_num)
	if not challenges or challenges.is_empty():
		return
	_challenge_index = _challenge_progress
	var c = challenges[_challenge_index]
	_challenge_title.text = "⌨  " + c.title + "  (" + str(_challenge_index + 1) + "/3)"
	_challenge_desc.text = c.desc
	_challenge_code_edit.text = c.code_template
	_challenge_output.text = ""
	_challenge_result.text = ""
	micro_panel.visible = true
	micro_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true

func _hide_challenge() -> void:
	micro_panel.visible = false
	get_tree().paused = false

func _on_challenge_run() -> void:
	var code = _challenge_code_edit.text
	_challenge_output.text = "Running..."
	var result = PythonTranspiler.run_code(code)
	if result.success:
		_challenge_output.text = result.output if result.output != "" else "(no output)"
		_challenge_output.add_theme_color_override("font_color", Color("#00FF88"))
	else:
		_challenge_output.text = "Error: " + result.error
		_challenge_output.add_theme_color_override("font_color", Color("#FF3366"))

func _on_challenge_submit() -> void:
	if _challenge_progress > _challenge_index:
		return
	var challenges = CHALLENGES.get(level_number)
	if not challenges or _challenge_index >= challenges.size():
		return
	var c = challenges[_challenge_index]
	var code = _challenge_code_edit.text
	var result = PythonTranspiler.run_code(code)
	var expected = c.expected_output.strip_edges(false, true)
	var reward = 0
	if result.success and result.output == expected:
		reward = c.bonus_ram
		ram_manager.earn(reward)
		_update_ram_label()
		_sound_ok.play()
		_challenge_result.text = "✔ Correct! +" + str(reward) + " RAM"
		_challenge_result.add_theme_color_override("font_color", Color("#00FF88"))
		_challenge_output.add_theme_color_override("font_color", Color("#00FF88"))
	else:
		_challenge_result.text = "✕ Wrong"
		_challenge_result.add_theme_color_override("font_color", Color("#FF3366"))
		_challenge_output.add_theme_color_override("font_color", Color("#FFB800"))
	var user_out = result.output.replace("\n", "  ") if result.success else "Error: " + result.error
	_challenge_output.text = "Your output:  " + user_out + "\nExpected:     " + expected.replace("\n", "  ")
	_challenge_progress += 1
	_advance_challenge.call_deferred()

func _on_challenge_skip() -> void:
	if _challenge_progress > _challenge_index:
		return
	_challenge_result.text = "⏭ Skipped"
	_challenge_result.add_theme_color_override("font_color", Color("#4A7FA5"))
	_challenge_output.text = ""
	_challenge_progress += 1
	_advance_challenge.call_deferred()

func _advance_challenge() -> void:
	if _challenge_progress >= 3:
		_challenge_result.text = "All challenges complete!"
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(micro_panel):
			_hide_challenge()
		return
	await get_tree().create_timer(1.2).timeout
	if not is_instance_valid(micro_panel) or not micro_panel.visible:
		return
	_show_challenge()
