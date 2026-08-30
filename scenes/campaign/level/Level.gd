# Level.gd
extends Node2D

const GridSystem = preload("res://scenes/campaign/level/GridSystem.gd")

# ─── NODE REFERENCES ───────────────────────────────────
@onready var grid_visual: Node2D             = $GridLayer/GridVisual
@onready var tower_layer: Node2D             = $TowerLayer
@onready var enemy_layer: Node2D             = $EnemyLayer
@onready var projectile_layer: Node2D        = $ProjectileLayer
@onready var managers_node: Node             = $Managers
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
@onready var pause_title: Label              = $HUD/HUDControl/PauseMenu/PauseMenuLayout/PauseTitle
@onready var resume_btn: Button              = $HUD/HUDControl/PauseMenu/PauseMenuLayout/ResumeBtn
@onready var retry_btn: Button               = $HUD/HUDControl/PauseMenu/PauseMenuLayout/RetryBtn
@onready var select_level_btn: Button        = $HUD/HUDControl/PauseMenu/PauseMenuLayout/SelectLevelBtn
@onready var main_menu_btn: Button           = $HUD/HUDControl/PauseMenu/PauseMenuLayout/MainMenuBtn

@onready var wave_progress_bar: ProgressBar = $HUD/HUDControl/TopHUD/TopLayout/WaveProgressTimeline/ProgressBar
@onready var timeline_flags: Control        = $HUD/HUDControl/TopHUD/TopLayout/WaveProgressTimeline/FlagsContainer
@onready var skip_wave_btn: Button           = $HUD/HUDControl/TopHUD/TopLayout/SkipWaveBtn

var _diff_badge: Button = null
var _exercise_btn: Button = null
var _exercise_bubble: PanelContainer = null
var _tower_exercise_shown: bool = false
const TOWER_EXERCISE_MAP: Dictionary = {
	1: "tower_array", 2: "tower_stack", 3: "tower_queue", 4: "tower_linked_list",
	5: "tower_bubble", 6: "tower_selection", 7: "tower_insertion", 8: "tower_quick",
	9: "tower_merge", 10: "tower_counting", 11: "tower_radix", 12: "tower_linear", 13: "tower_binary"
}
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
var grid_system
var level_start_time: float        = 0.0
var is_level_ended: bool           = false
var _preview_tower: Node2D        = null
var _confirm_cell: Vector2i       = Vector2i(-1, -1)
var _is_fast_forward: bool        = false
var _ff_btn: Button               = null

const INTER_WAVE_DURATION: float  = 15.0
var wave_countdown: float          = INTER_WAVE_DURATION
var countdown_active: bool         = true
var _tutorial_active: bool = false
var _pause_press_time: float = 0.0

# ─── CODING CHALLENGES ──────────────────────────────────
const CHALLENGES = {
	1: [  # Arrays — Level 1: 10+ random inline-blanks (pill drag) exercises
		{ "title": "Print Two Values", "desc": "Fill both blanks to print \"7\" and \"11\".", "code_template": "my_array = [7, 12, 9, 4, 11]\n\nprint(my_array[___])\nprint(my_array[___])", "choices": ["0", "1", "4", "7"], "correct": ["0", "4"], "expected_output": "7\n11\n", "bonus_ram": 20 },
		{ "title": "Array Access", "desc": "Print the last value \"11\".", "code_template": "my_array = [7, 12, 9, 4, 11]\n\nprint(my_array[___])", "choices": ["4", "5", "-1", "11"], "correct": "4", "expected_output": "11\n", "bonus_ram": 20 },
		{ "title": "Array Length", "desc": "Print how many items are in the array.", "code_template": "my_array = [7, 12, 9, 4, 11]\n\nprint(___) ", "choices": ["len(my_array)", "my_array.len()", "count(my_array)", "size(my_array)"], "correct": "len(my_array)", "expected_output": "5\n", "bonus_ram": 20 },
		{ "title": "Middle Value", "desc": "Print the middle value \"9\" at index 2.", "code_template": "my_array = [7, 12, 9, 4, 11]\n\nprint(my_array[___])", "choices": ["2", "3", "9", "1"], "correct": "2", "expected_output": "9\n", "bonus_ram": 20 },
		{ "title": "Second Element", "desc": "Print \"12\" at index 1.", "code_template": "my_array = [7, 12, 9, 4, 11]\n\nprint(my_array[___])", "choices": ["0", "1", "12", "2"], "correct": "1", "expected_output": "12\n", "bonus_ram": 20 },
		{ "title": "Negative Index", "desc": "Use a negative index to print \"11\" (last).", "code_template": "my_array = [7, 12, 9, 4, 11]\n\nprint(my_array[___])", "choices": ["-1", "4", "-4", "11"], "correct": "-1", "expected_output": "11\n", "bonus_ram": 20 },
		{ "title": "Slice Start", "desc": "Print the first two values as a slice.", "code_template": "my_array = [7, 12, 9, 4, 11]\n\nprint(my_array[0:___])", "choices": ["2", "3", "1", "0:2"], "correct": "2", "expected_output": "[7, 12]\n", "bonus_ram": 20 },
		{ "title": "Array Update", "desc": "Change index 2 from \"9\" to \"99\".", "code_template": "my_array = [7, 12, 9, 4, 11]\nmy_array[___] = 99\nprint(my_array)", "choices": ["2", "9", "1", "3"], "correct": "2", "expected_output": "[7, 12, 99, 4, 11]\n", "bonus_ram": 20 },
		{ "title": "Append", "desc": "Add \"20\" to the end.", "code_template": "my_array = [7, 12, 9, 4, 11]\nmy_array.___(20)\nprint(my_array)", "choices": ["append", "add", "push", "insert"], "correct": "append", "expected_output": "[7, 12, 9, 4, 11, 20]\n", "bonus_ram": 20 },
		{ "title": "Contains Check", "desc": "Check if \"7\" is in the array.", "code_template": "my_array = [7, 12, 9, 4, 11]\nprint(7 ___ my_array)", "choices": ["in", "not in", "==", "[]"], "correct": "in", "expected_output": "True\n", "bonus_ram": 20 },
	],
	2: [  # Stacks
		{ "title": "Stack Push & Pop", "desc": "Push 10, 20, 30 onto a stack, then pop and print each value.", "code_template": "stack = []\nstack.append(10)\nstack.append(20)\n___\nprint(stack.pop())\nprint(stack.pop())\nprint(stack.pop())", "choices": ["stack.append(30)", "stack.append(10)", "stack.push(30)", "stack.append(20)"], "correct": "stack.append(30)", "expected_output": "30\n20\n10\n", "bonus_ram": 20 },
		{ "title": "Stack Reversal", "desc": "Push A, B, C then pop all to reverse the order. Print each popped value.", "code_template": "stack = []\nstack.append('A')\n___\nstack.append('C')\nprint(stack.pop())\nprint(stack.pop())\nprint(stack.pop())", "choices": ["stack.append('B')", "stack.append('A')", "stack.append('D')", "stack.push('B')"], "correct": "stack.append('B')", "expected_output": "C\nB\nA\n", "bonus_ram": 20 },
		{ "title": "Stack Peek", "desc": "Push 5, 15, 25. Pop once and print it, then print the new top without removing it (use stack[-1]).", "code_template": "stack = []\nstack.append(5)\nstack.append(15)\nstack.append(25)\npopped = stack.pop()\nprint(popped)\n___\nprint(top)", "choices": ["top = stack[-1]", "top = stack[0]", "top = stack.pop()", "top = stack[1]"], "correct": "top = stack[-1]", "expected_output": "25\n15\n", "bonus_ram": 20 },
	],
	3: [  # Queues
		{ "title": "Queue Dequeue All", "desc": "Enqueue 7, 14, 21 then dequeue and print each using pop(0).", "code_template": "queue = []\nqueue.append(7)\nqueue.append(14)\n___\nprint(queue.pop(0))\nprint(queue.pop(0))\nprint(queue.pop(0))", "choices": ["queue.append(21)", "queue.append(7)", "queue.push(21)", "queue.append(14)"], "correct": "queue.append(21)", "expected_output": "7\n14\n21\n", "bonus_ram": 20 },
		{ "title": "Queue Round Robin", "desc": "Enqueue 1, 2, 3. Dequeue front, enqueue it back, then dequeue all. Print each dequeued value.", "code_template": "queue = [1, 2, 3]\nfront = queue.pop(0)\nqueue.append(front)\nprint(queue.pop(0))\n___\nprint(queue.pop(0))", "choices": ["print(queue.pop(0))", "print(queue[0])", "print(front)", "queue.append(1)"], "correct": "print(queue.pop(0))", "expected_output": "2\n3\n1\n", "bonus_ram": 20 },
		{ "title": "Queue Size", "desc": "Enqueue 10, 20, 30, 40. Dequeue twice. Print the remaining queue size.", "code_template": "queue = []\nqueue.append(10)\nqueue.append(20)\nqueue.append(30)\nqueue.append(40)\nqueue.pop(0)\nqueue.pop(0)\nprint(___)", "choices": ["len(queue)", "queue.size()", "len(queue)-1", "queue.length"], "correct": "len(queue)", "expected_output": "2\n", "bonus_ram": 20 },
	],
	4: [  # Linked Lists
		{ "title": "Traverse List", "desc": "Traverse the linked chain starting at node and print each val.", "code_template": "node = {'val': 1, 'next': {'val': 2, 'next': {'val': 3, 'next': None}}}\nwhile node:\n    print(node['val'])\n    ___", "expected_output": "1\n2\n3\n", "bonus_ram": 25 },
		{ "title": "Count Nodes", "desc": "Count how many nodes are in the linked chain and print the count.", "code_template": "node = {'val': 5, 'next': {'val': 10, 'next': {'val': 15, 'next': None}}}\ncount = 0\n___\nprint(count)", "expected_output": "3\n", "bonus_ram": 25 },
		{ "title": "Find Value", "desc": "Find if value 10 exists in the linked chain. Print 'yes' or 'no'.", "code_template": "node = {'val': 5, 'next': {'val': 10, 'next': {'val': 15, 'next': None}}}\ntarget = 10\nfound = 'no'\nwhile node:\n    if node['val'] == target:\n        found = 'yes'\n        ___\n    node = node['next']\nprint(found)", "expected_output": "yes\n", "bonus_ram": 25 },
	],
	5: [  # Bubble Sort
		{ "title": "One Pass", "desc": "Perform ONE pass of bubble sort on [5,3,8,1] and print the array.", "code_template": "arr = [5, 3, 8, 1]\nfor i in range(len(arr) - 1):\n    if arr[i] > arr[i+1]:\n        ___\nprint(arr)", "choices": ["arr[i], arr[i+1] = arr[i+1], arr[i]", "arr[i] = arr[i+1]", "swap(arr[i], arr[i+1])", "arr.swap(i)"], "correct": "arr[i], arr[i+1] = arr[i+1], arr[i]", "expected_output": "[3, 5, 1, 8]\n", "bonus_ram": 25 },
		{ "title": "Two Passes", "desc": "Perform TWO passes of bubble sort on [5,3,8,1] and print the array.", "code_template": "arr = [5, 3, 8, 1]\nfor _ in range(2):\n    for i in range(len(arr) - 1):\n        if arr[i] > arr[i+1]:\n            arr[i], arr[i+1] = arr[i+1], arr[i]\nprint(arr)", "expected_output": "[1, 3, 5, 8]\n", "bonus_ram": 25 },
		{ "title": "Count Swaps", "desc": "Count how many swaps happen during one bubble sort pass on [4,2,7,1] and print the count.", "code_template": "arr = [4, 2, 7, 1]\nswaps = 0\nfor i in range(len(arr) - 1):\n    if arr[i] > arr[i+1]:\n        arr[i], arr[i+1] = arr[i+1], arr[i]\n        ___\nprint(swaps)", "choices": ["swaps += 1", "swaps = swaps +1", "count +=1", "swaps++"], "correct": "swaps += 1", "expected_output": "2\n", "bonus_ram": 25 },
	],
	6: [  # Selection Sort
		{ "title": "Find Min & Swap", "desc": "Find the minimum in [9,2,7,4] and swap it with the first element. Print the array.", "code_template": "arr = [9, 2, 7, 4]\nmin_idx = 0\nfor i in range(1, len(arr)):\n    if arr[i] < arr[min_idx]:\n        ___\narr[0], arr[min_idx] = arr[min_idx], arr[0]\nprint(arr)", "choices": ["min_idx = i", "min_idx = 0", "min = arr[i]", "min_idx = j"], "correct": "min_idx = i", "expected_output": "[2, 9, 7, 4]\n", "bonus_ram": 25 },
		{ "title": "Second Smallest", "desc": "Find the second smallest element in [9,2,7,4] and print it.", "code_template": "arr = [9, 2, 7, 4]\narr.sort()\nprint(___)", "choices": ["arr[1]", "arr[0]", "min(arr)", "arr.sort()[1]"], "correct": "arr[1]", "expected_output": "4\n", "bonus_ram": 20 },
		{ "title": "Full Selection Sort", "desc": "Complete selection sort on [6,3,8,1] and print the sorted array.", "code_template": "arr = [6, 3, 8, 1]\nfor i in range(len(arr)):\n    min_idx = i\n    for j in range(i+1, len(arr)):\n        if arr[j] < arr[min_idx]:\n            min_idx = j\n    arr[i], arr[min_idx] = arr[min_idx], arr[i]\nprint(arr)", "expected_output": "[1, 3, 6, 8]\n", "bonus_ram": 25 },
	],
	7: [  # Insertion Sort
		{ "title": "Insert Third Element", "desc": "In [3,7,2,9], insert the third element (2) into the sorted portion. Print the array.", "code_template": "arr = [3, 7, 2, 9]\nkey = arr[2]\nj = 1\nwhile j >= 0 and arr[j] > key:\n    arr[j+1] = arr[j]\n    ___\narr[j+1] = key\nprint(arr)", "choices": ["j -= 1", "j = j -1", "j++", "j = 0"], "correct": "j -= 1", "expected_output": "[2, 3, 7, 9]\n", "bonus_ram": 25 },
		{ "title": "Full Insertion Sort", "desc": "Complete insertion sort on [5,2,9,1,6] and print the sorted array.", "code_template": "arr = [5, 2, 9, 1, 6]\nfor i in range(1, len(arr)):\n    key = arr[i]\n    j = i - 1\n    while j >= 0 and arr[j] > key:\n        arr[j+1] = arr[j]\n        j -= 1\n    arr[j+1] = key\nprint(arr)", "expected_output": "[1, 2, 5, 6, 9]\n", "bonus_ram": 28 },
		{ "title": "Shifts Count", "desc": "Count how many shifts happen when inserting the last element of [2,5,7,3] and print the count.", "code_template": "arr = [2, 5, 7, 3]\nkey = arr[3]\nj = 2\nshifts = 0\nwhile j >= 0 and arr[j] > key:\n    arr[j+1] = arr[j]\n    j -= 1\n    ___\nprint(shifts)", "choices": ["shifts += 1", "shifts = shifts +1", "count +=1", "shifts++"], "correct": "shifts += 1", "expected_output": "2\n", "bonus_ram": 25 },
	],
	8: [  # Quick Sort
		{ "title": "Partition by Pivot", "desc": "Partition [7,3,9,2,6] using last element (6) as pivot. Print partitioned array.", "code_template": "arr = [7, 3, 9, 2, 6]\npivot = arr[-1]\ni = 0\nfor j in range(len(arr) - 1):\n    if arr[j] < pivot:\n        arr[i], arr[j] = arr[j], arr[i]\n        ___\narr[i], arr[-1] = arr[-1], arr[i]\nprint(arr)", "choices": ["i += 1", "i = i +1", "i++", "i = j"], "correct": "i += 1", "expected_output": "[3, 2, 6, 7, 9]\n", "bonus_ram": 30 },
		{ "title": "Count Smaller", "desc": "Count how many elements are smaller than pivot 6 in [7,3,9,2,6] and print the count.", "code_template": "arr = [7, 3, 9, 2, 6]\npivot = 6\ncount = 0\nfor v in arr:\n    if v < pivot:\n        ___\nprint(count)", "choices": ["count += 1", "count = count +1", "count++", "count = count + i"], "correct": "count += 1", "expected_output": "2\n", "bonus_ram": 25 },
		{ "title": "Pivot Position", "desc": "After partitioning with last element as pivot, print the final index of the pivot.", "code_template": "arr = [7, 3, 9, 2, 6]\npivot = arr[-1]\ni = 0\nfor j in range(len(arr) - 1):\n    if arr[j] < pivot:\n        arr[i], arr[j] = arr[j], arr[i]\n        i += 1\narr[i], arr[-1] = arr[-1], arr[i]\nprint(___)", "choices": ["i", "pivot", "j", "arr[i]"], "correct": "i", "expected_output": "2\n", "bonus_ram": 25 },
	],
	9: [  # Merge Sort
		{ "title": "Merge Two Halves", "desc": "Merge sorted arrays left=[1,4] and right=[2,3] into one sorted array and print.", "code_template": "left = [1, 4]\nright = [2, 3]\nmerged = []\ni = j = 0\nwhile i < len(left) and j < len(right):\n    if left[i] < right[j]:\n        merged.append(left[i]); i += 1\n    else:\n        ___\nmerged.extend(left[i:])\nmerged.extend(right[j:])\nprint(merged)", "choices": ["merged.append(right[j]); j += 1", "merged.append(left[i])", "right.append()", "merged.add(right[j])"], "correct": "merged.append(right[j]); j += 1", "expected_output": "[1, 2, 3, 4]\n", "bonus_ram": 30 },
		{ "title": "Merge Leftovers", "desc": "Merge left=[1,2,3] and right=[4,5,6]. After one list is exhausted, extend with the rest. Print merged.", "code_template": "left = [1, 2, 3]\nright = [4, 5, 6]\nmerged = []\ni = j = 0\nwhile i < len(left) and j < len(right):\n    if left[i] < right[j]:\n        merged.append(left[i]); i += 1\n    else:\n        merged.append(right[j]); j += 1\n___\nprint(merged)", "choices": ["merged.extend(left[i:])\nmerged.extend(right[j:])", "merged.append(left)", "extend(merged)", "merged += left"], "correct": "merged.extend(left[i:])\nmerged.extend(right[j:])", "expected_output": "[1, 2, 3, 4, 5, 6]\n", "bonus_ram": 25 },
		{ "title": "Count Merge Ops", "desc": "Count how many comparisons when merging [1,4] and [2,3]. Print the count.", "code_template": "left = [1, 4]\nright = [2, 3]\ni = j = 0\ncompares = 0\nwhile i < len(left) and j < len(right):\n    if left[i] < right[j]:\n        i += 1\n    else:\n        j += 1\n    ___\nprint(compares)", "choices": ["compares += 1", "compares = compares +1", "count +=1", "compares++"], "correct": "compares += 1", "expected_output": "3\n", "bonus_ram": 25 },
	],
	10: [  # Counting Sort
		{ "title": "Count Frequencies", "desc": "Count how many times 0,1,2 appear in [2,0,2,1,1,0]. Print [count0, count1, count2].", "code_template": "arr = [2, 0, 2, 1, 1, 0]\ncounts = [0, 0, 0]\nfor v in arr:\n    ___\nprint(counts)", "choices": ["counts[v] += 1", "counts[v] = 1", "count +=1", "counts.append(v)"], "correct": "counts[v] += 1", "expected_output": "[2, 2, 2]\n", "bonus_ram": 25 },
		{ "title": "Build Output", "desc": "Using counts=[2,2,2], build the sorted output array by repeating each index by its count. Print result.", "code_template": "counts = [2, 2, 2]\noutput = []\nfor val in range(len(counts)):\n    for _ in range(counts[val]):\n        ___\nprint(output)", "choices": ["output.append(val)", "output.add(val)", "output.push(val)", "output[val]=1"], "correct": "output.append(val)", "expected_output": "[0, 0, 1, 1, 2, 2]\n", "bonus_ram": 28 },
		{ "title": "Cumulative Counts", "desc": "Given counts=[2,2,2], compute cumulative counts [2,4,6] where each is sum of previous. Print cum.", "code_template": "counts = [2, 2, 2]\ncum = []\ntotal = 0\nfor c in counts:\n    total += c\n    ___\nprint(cum)", "choices": ["cum.append(total)", "cum.add(total)", "cum.push(total)", "cum[total]=1"], "correct": "cum.append(total)", "expected_output": "[2, 4, 6]\n", "bonus_ram": 25 },
	],
	11: [  # Radix Sort
		{ "title": "Ones Digit", "desc": "Extract the ones-place digit from each number in [43,218,7,95] using num % 10. Print as a list.", "code_template": "arr = [43, 218, 7, 95]\ndigits = []\nfor num in arr:\n    digits.append(___)\nprint(digits)", "choices": ["num % 10", "num //10", "num % 100", "str(num)[-1]"], "correct": "num % 10", "expected_output": "[3, 8, 7, 5]\n", "bonus_ram": 25 },
		{ "title": "Tens Digit", "desc": "Extract the tens-place digit from each number in [43,218,7,95] using (num // 10) % 10. Print as a list.", "code_template": "arr = [43, 218, 7, 95]\ndigits = []\nfor num in arr:\n    digits.append(___)\nprint(digits)", "choices": ["(num // 10) % 10", "num %100", "num //10", "int(str(num)[1])"], "correct": "(num // 10) % 10", "expected_output": "[4, 1, 0, 9]\n", "bonus_ram": 25 },
		{ "title": "Max Digits", "desc": "Find how many digits the largest number in [43,218,7,95] has. Print the count.", "code_template": "arr = [43, 218, 7, 95]\nmax_val = max(arr)\ncount = 0\nwhile max_val > 0:\n    count += 1\n    ___\nprint(count)", "choices": ["max_val //= 10", "max_val /=10", "max_val -=10", "max_val = max_val //10"], "correct": "max_val //= 10", "expected_output": "3\n", "bonus_ram": 25 },
	],
	12: [  # Linear Search
		{ "title": "Find Index", "desc": "Find the index of value 99 in [11,42,7,99,23] and print it (-1 if not found).", "code_template": "arr = [11, 42, 7, 99, 23]\ntarget = 99\nfound_idx = -1\nfor i in range(len(arr)):\n    if arr[i] == target:\n        found_idx = i\n        ___\nprint(found_idx)", "choices": ["break", "continue", "pass", "found = i"], "correct": "break", "expected_output": "3\n", "bonus_ram": 20 },
		{ "title": "First Occurrence", "desc": "Find the first index where 7 appears in [7,3,7,1,7,9]. Print it.", "code_template": "arr = [7, 3, 7, 1, 7, 9]\ntarget = 7\nfor i in range(len(arr)):\n    if arr[i] == target:\n        print(i)\n        ___", "choices": ["break", "continue", "pass", "return i"], "correct": "break", "expected_output": "0\n", "bonus_ram": 20 },
		{ "title": "Count Occurrences", "desc": "Count how many times 7 appears in [7,3,7,1,7,9] and print the count.", "code_template": "arr = [7, 3, 7, 1, 7, 9]\ntarget = 7\ncount = 0\n___\nprint(count)", "choices": ["for v in arr:\n    if v==target:\n        count+=1", "count = arr.count(7)", "count += arr.count", "for i in arr: count++"], "correct": "for v in arr:\n    if v==target:\n        count+=1", "expected_output": "3\n", "bonus_ram": 20 },
	],
	13: [  # Binary Search
		{ "title": "Find Target", "desc": "Binary search for 51 in [5,12,27,38,51,64,79]. Print its index.", "code_template": "arr = [5, 12, 27, 38, 51, 64, 79]\ntarget = 51\nlo, hi = 0, len(arr) - 1\nwhile lo <= hi:\n    mid = (lo + hi) // 2\n    if arr[mid] == target:\n        print(mid)\n        ___\n    elif arr[mid] < target:\n        lo = mid + 1\n    else:\n        hi = mid - 1", "choices": ["break", "continue", "pass", "found = mid"], "correct": "break", "expected_output": "4\n", "bonus_ram": 30 },
		{ "title": "Search Left Half", "desc": "Binary search for 5 (first element) in [5,12,27,38,51,64,79]. Print index.", "code_template": "arr = [5, 12, 27, 38, 51, 64, 79]\ntarget = 5\nlo, hi = 0, len(arr) - 1\nwhile lo <= hi:\n    mid = (lo + hi) // 2\n    if arr[mid] == target:\n        print(mid)\n        ___\n    elif arr[mid] < target:\n        lo = mid + 1\n    else:\n        hi = mid - 1", "choices": ["break", "continue", "pass", "return mid"], "correct": "break", "expected_output": "0\n", "bonus_ram": 28 },
		{ "title": "Not Found", "desc": "Binary search for 99 (not present) in [5,12,27,38,51,64,79]. Print the index or -1.", "code_template": "arr = [5, 12, 27, 38, 51, 64, 79]\ntarget = 99\nlo, hi = 0, len(arr) - 1\nfound = -1\nwhile lo <= hi:\n    mid = (lo + hi) // 2\n    if arr[mid] == target:\n        found = mid\n        ___\n    elif arr[mid] < target:\n        lo = mid + 1\n    else:\n        hi = mid - 1\nprint(found)", "choices": ["break", "continue", "found = -1", "pass"], "correct": "break", "expected_output": "-1\n", "bonus_ram": 28 },
	],
}

# ─── TOWER DEFINITIONS ─────────────────────────────────
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
	_apply_responsive_challenge()
	get_tree().root.size_changed.connect(_apply_responsive_challenge)
	# All levels use 🧩 Exercise button — no auto-popup, player chooses difficulty
	_maybe_show_tutorial()
	GameManager.active_level = self
	_setup_enemy_tooltip()

func _exit_tree() -> void:
	GameManager.active_level = null
	Engine.time_scale = 1.0
	SoundManager.stop_music()

# ─── ENEMY TOOLTIP ──────────────────────────────────────
var _enemy_tooltip: Control = null

func _setup_enemy_tooltip() -> void:
	var TooltipScript = preload("res://scenes/campaign/enemies/EnemyTooltip.gd")
	_enemy_tooltip = TooltipScript.new()
	_enemy_tooltip.name = "EnemyTooltip"
	_enemy_tooltip.z_index = 50
	_enemy_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD/HUDControl.add_child(_enemy_tooltip)
	# Connect enemy hover signals when enemies spawn
	enemy_layer.child_entered_tree.connect(_on_enemy_spawned)
	# Connect to enemies that will be spawned (deferred to ensure _ready ran)
	call_deferred("_connect_existing_enemies")

func _connect_existing_enemies() -> void:
	for child in enemy_layer.get_children():
		if child is Enemy:
			_connect_enemy_hover(child)

func _update_enemy_tooltip() -> void:
	if is_level_ended:
		if _enemy_tooltip and _enemy_tooltip.visible:
			_enemy_tooltip.hide_tooltip()
		return
	var mouse_screen = get_viewport().get_mouse_position()
	var closest_enemy: Enemy = null
	var closest_dist := 40.0
	for child in enemy_layer.get_children():
		if child is Enemy and not child.is_dead:
			var enemy_screen = child.get_global_transform_with_canvas().origin
			var dist = mouse_screen.distance_to(enemy_screen)
			if dist < closest_dist:
				closest_dist = dist
				closest_enemy = child
	if closest_enemy and _enemy_tooltip:
		_enemy_tooltip.show_for_enemy(closest_enemy.enemy_type)
		var epos = closest_enemy.get_global_transform_with_canvas().origin
		_enemy_tooltip.global_position = epos + Vector2(20, -80)
	elif _enemy_tooltip and _enemy_tooltip.visible:
		_enemy_tooltip.hide_tooltip()

func _on_enemy_spawned(enemy: Node) -> void:
	if enemy is Enemy:
		# Use call_deferred to ensure Enemy._ready() has run (HoverArea created)
		_connect_enemy_hover.call_deferred(enemy)

func _connect_enemy_hover(enemy: Enemy) -> void:
	var hover_area = enemy.get_node_or_null("HoverArea")
	if hover_area:
		hover_area.mouse_entered.connect(_on_enemy_hover.bind(enemy))
		hover_area.mouse_exited.connect(_on_enemy_unhover.bind(enemy))
		hover_area.input_event.connect(_on_enemy_input_event.bind(enemy))

func _on_enemy_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, enemy: Enemy) -> void:
	if event is InputEventMouseMotion and _enemy_tooltip and not enemy.is_dead:
		_enemy_tooltip.show_for_enemy(enemy.enemy_type)
		var pos = enemy.get_global_transform_with_canvas().origin
		_enemy_tooltip.global_position = pos + Vector2(20, -80)
	elif event is InputEventMouseButton and not event.pressed:
		if _enemy_tooltip:
			_enemy_tooltip.hide_tooltip()

func _on_enemy_hover(enemy: Enemy) -> void:
	if _enemy_tooltip and not enemy.is_dead:
		_enemy_tooltip.show_for_enemy(enemy.enemy_type)
		var pos = enemy.get_global_transform_with_canvas().origin
		_enemy_tooltip.global_position = pos + Vector2(20, -80)

func _on_enemy_unhover(_enemy: Enemy) -> void:
	if _enemy_tooltip:
		_enemy_tooltip.hide_tooltip()

# ─── SETUP ─────────────────────────────────────────────
func _setup_grid() -> void:
	grid_system      = GridSystem.new()
	grid_system.name = "GridSystem"
	grid_visual.add_child(grid_system)

	var config = _get_level_config()

	var waypoints: Array[Vector2] = []
	for wp in config["waypoints"]:
		waypoints.append(wp)

	# Center waypoints on cells so enemies walk through path centers
	var cs = grid_system.CELL_SIZE
	var hc = cs * 0.5
	for i in range(waypoints.size()):
		waypoints[i] = Vector2(
			int(waypoints[i].x / cs) * cs + hc,
			int(waypoints[i].y / cs) * cs + hc
		)

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

	var waypoints: Array[Vector2] = []
	for wp in config["waypoints"]:
		waypoints.append(wp)

	# Center waypoints on cells so enemies walk through path centers
	var cs = 64
	var hc = cs * 0.5
	for i in range(waypoints.size()):
		waypoints[i] = Vector2(
			int(waypoints[i].x / cs) * cs + hc,
			int(waypoints[i].y / cs) * cs + hc
		)

	wave_manager.initialize(
		config["waves"],
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

	var grid_w = grid_system.GRID_COLS * grid_system.CELL_SIZE
	var grid_h = grid_system.GRID_ROWS * grid_system.CELL_SIZE

	var hud_height = $HUD/HUDControl/TopHUD.size.y
	var avail_h = max(vp_size.y - hud_height, 100)

	var zoom_x = vp_size.x / grid_w
	var zoom_y = avail_h / grid_h
	$GameCamera.zoom = Vector2(zoom_x, zoom_y)

	var y_offset = hud_height / (2.0 * zoom_y)
	$GameCamera.position = Vector2(grid_w / 2.0, grid_h / 2.0 - y_offset)

func _build_tower_selector() -> void:
	pass

func _setup_buttons() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	pause_btn.button_down.connect(func(): _pause_press_time = Time.get_ticks_msec() / 1000.0)
	pause_btn.button_up.connect(_on_pause_released)
	resume_btn.pressed.connect(_on_resume_pressed)
	retry_btn.pressed.connect(_on_retry_pressed)
	select_level_btn.pressed.connect(_on_select_level_pressed)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	skip_wave_btn.pressed.connect(_on_skip_wave_pressed)


	_ff_btn = Button.new()
	_ff_btn.text = "▶▶"
	_ff_btn.custom_minimum_size = Vector2(36, 28)
	_ff_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_ff_btn.add_theme_color_override("font_color", Color("#4A7FA5"))
	_ff_btn.add_theme_font_size_override("font_size", 10)
	_ff_btn.tooltip_text = "Fast-forward (2x)"
	_ff_btn.pressed.connect(_on_fast_forward_pressed)
	$HUD/HUDControl/TopHUD/TopLayout.add_child(_ff_btn)
	pause_btn.get_parent().move_child(_ff_btn, pause_btn.get_index())

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

func _spawn_floating_text(text: String, global_pos: Vector2, color: Color, size := -1) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	if size <= 0:
		size = _fs(0.030, 16.0, 18.0)
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
var _menu_backdrop: ColorRect
func _set_overlay_visible(v: bool) -> void:
	overlay_menu.visible = v
	_menu_backdrop.visible = v
	if v:
		_menu_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_menu_backdrop.call_deferred("set", "mouse_filter", Control.MOUSE_FILTER_STOP)
	else:
		_menu_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _create_overlay_menu() -> void:
	_menu_backdrop = ColorRect.new()
	_menu_backdrop.color = Color(0, 0, 0, 0)
	_menu_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_backdrop.visible = false
	_menu_backdrop.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# If a preview ghost is active (check/X), cancel it properly
			if is_instance_valid(_preview_tower):
				_remove_preview_tower()
				_set_overlay_visible(false)
				return
			_set_overlay_visible(false)
			if is_instance_valid(_selected_tower):
				_selected_tower.set_selected(false)
				_selected_tower = null
	)
	$HUD/HUDControl.add_child(_menu_backdrop)

	overlay_menu = Control.new()
	overlay_menu.visible = false
	overlay_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD/HUDControl.add_child(overlay_menu)

func _show_ram_bubble() -> void:
	# Reuse exercise bubble position but with RAM-specific text
	if not is_instance_valid(_exercise_btn):
		return
	if _exercise_bubble and is_instance_valid(_exercise_bubble):
		_exercise_bubble.queue_free()
		_exercise_bubble = null
	_exercise_bubble = PanelContainer.new()
	_exercise_bubble.z_index = 10
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color("#2A0A0A")
	bs.border_color = Color("#FF3366")
	bs.border_width_left = 2
	bs.border_width_right = 2
	bs.border_width_top = 2
	bs.border_width_bottom = 2
	bs.corner_radius_top_left = 8
	bs.corner_radius_top_right = 8
	bs.corner_radius_bottom_left = 8
	bs.corner_radius_bottom_right = 8
	bs.content_margin_left = 10
	bs.content_margin_right = 10
	bs.content_margin_top = 8
	bs.content_margin_bottom = 10
	_exercise_bubble.add_theme_stylebox_override("panel", bs)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	_exercise_bubble.add_child(vbox)
	var lbl := Label.new()
	lbl.text = "⚠ Not enough RAM!"
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color("#FF5577"))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl)
	var hint := Label.new()
	hint.text = "Tap 🧩 Exercise → Easy 20 / Medium 30 / Hard 50 RAM"
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", Color("#FFCC66"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)
	$HUD/HUDControl.add_child(_exercise_bubble)
	await get_tree().process_frame
	if not is_instance_valid(_exercise_btn) or not is_instance_valid(_exercise_bubble):
		return
	var btn_pos = _exercise_btn.global_position
	var btn_size = _exercise_btn.size
	_exercise_bubble.position = btn_pos + Vector2(btn_size.x * 0.5 - _exercise_bubble.size.x * 0.5, btn_size.y + 6)
	_exercise_bubble.scale = Vector2(0.7, 0.7)
	_exercise_bubble.modulate.a = 0.0
	var t = create_tween().set_parallel(true)
	t.tween_property(_exercise_bubble, "scale", Vector2(1, 1), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_exercise_bubble, "modulate:a", 1.0, 0.25)
	# Pulse the Exercise button
	if is_instance_valid(_exercise_btn):
		var tb = create_tween()
		tb.tween_property(_exercise_btn, "scale", Vector2(1.12, 1.12), 0.15)
		tb.tween_property(_exercise_btn, "scale", Vector2(1, 1), 0.25)
	await get_tree().create_timer(4.0).timeout
	if is_instance_valid(_exercise_bubble):
		var t2 = create_tween()
		t2.tween_property(_exercise_bubble, "modulate:a", 0.0, 0.4)
		t2.tween_callback(func(): if is_instance_valid(_exercise_bubble): _exercise_bubble.queue_free(); _exercise_bubble = null)

func _on_overlay_tower_selected(tower_id: String) -> void:
	_set_overlay_visible(false)
	var def = GameManager.TOWER_DEFINITIONS[tower_id]
	if not ram_manager.can_afford(def["ram_cost"]):
		_flash_ram_label(false)
		_play_feedback(false)
		_show_ram_bubble()
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

	_confirm_cell = current_clicked_cell
	_create_preview_tower(def, _confirm_cell)
	_show_placement_confirmation(_confirm_cell)

# ─── GRID INTERACTION ──────────────────────────────────
func _on_cell_clicked(cell: Vector2i) -> void:
	if is_instance_valid(_preview_tower) and overlay_menu.visible:
		if cell == _confirm_cell:
			return  # Let the confirmation buttons handle it
		_remove_preview_tower()
		_set_overlay_visible(false)

	if overlay_menu.visible and cell == _current_menu_cell:
		_set_overlay_visible(false)
		for child in overlay_menu.get_children():
			child.queue_free()
		if is_instance_valid(_selected_tower):
			_selected_tower.set_selected(false)
			_selected_tower = null
		return

	# If tower menu is open and user clicks a different cell, just close it
	if overlay_menu.visible and is_instance_valid(_selected_tower):
		_set_overlay_visible(false)
		for child in overlay_menu.get_children():
			child.queue_free()
		_selected_tower.set_selected(false)
		_selected_tower = null
		return

	_current_menu_cell = cell
	_set_overlay_visible(false)
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

	var tower_color: Color = tower.tower_color if tower.has_method("get") and "tower_color" in tower else Color("#00D4FF")
	var data = DataRegistry.get_tower(tower.tower_id)

	# ── Dimensions ────────────────────────────────────
	var left_w := 72.0
	var right_w := 132.0
	var pad := 8.0
	var total_w = left_w + right_w + pad * 3
	var row_h := 13.0
	var stat_sep := 1.0
	var btn_h := 22.0
	var btn_sep := 5.0

	# Right side rows: name, level, 4 stats, separator, 2 buttons
	var right_rows := 1 + 1 + 4 + 1 + 2
	var content_h = right_rows * (row_h + stat_sep) + btn_sep
	var total_h = content_h + pad * 2 + 12.0 # extra bottom breathing room

	# ── Position panel beside the tower (adaptive: more screen space side) ──
	var screen_size_pre = get_viewport_rect().size
	var zoom = $GameCamera.zoom
	var cell_half_screen = 32.0 * zoom.x
	var gap := 14.0
	var side_offset = cell_half_screen + total_w * 0.5 + gap
	# If tower is on right half of screen, show panel on the left to avoid edge clamp
	var dir_x: float = -1.0 if canvas_pos.x > screen_size_pre.x * 0.5 else 1.0
	overlay_menu.position = canvas_pos + Vector2(dir_x * side_offset, -total_h * 0.25)

	# ── Background Panel ──────────────────────────────
	var bg := Panel.new()
	bg.custom_minimum_size = Vector2(total_w, total_h)
	bg.size = Vector2(total_w, total_h)
	bg.position = Vector2(-total_w / 2, -total_h / 2)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color("#070F1E", 0.95)
	bg_style.border_color = tower_color
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	bg.add_theme_stylebox_override("panel", bg_style)
	overlay_menu.add_child(bg)

	# ── Left Side: Tower Visual ───────────────────────
	var left_x := pad
	var left_y := pad
	var visual_h = total_h - pad * 2

	# Tower icon panel
	var icon_panel := Panel.new()
	icon_panel.position = Vector2(left_x, left_y)
	icon_panel.custom_minimum_size = Vector2(left_w, visual_h)
	icon_panel.size = Vector2(left_w, visual_h)
	var icon_bg := StyleBoxFlat.new()
	icon_bg.bg_color = Color(tower_color.r * 0.15, tower_color.g * 0.15, tower_color.b * 0.15, 0.9)
	icon_bg.border_color = tower_color.darkened(0.3)
	icon_bg.border_width_left = 1
	icon_bg.border_width_right = 1
	icon_bg.border_width_top = 1
	icon_bg.border_width_bottom = 1
	icon_bg.corner_radius_top_left = 6
	icon_bg.corner_radius_top_right = 6
	icon_bg.corner_radius_bottom_left = 6
	icon_bg.corner_radius_bottom_right = 6
	icon_panel.add_theme_stylebox_override("panel", icon_bg)
	bg.add_child(icon_panel)

	# Tower icon text (large)
	var icon_lbl := Label.new()
	icon_lbl.text = data.icon_text if data else "[ ]"
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.position = Vector2(0, 4)
	icon_lbl.size = Vector2(left_w, visual_h * 0.6)
	icon_lbl.add_theme_font_size_override("font_size", 28)
	icon_lbl.add_theme_color_override("font_color", tower_color)
	icon_panel.add_child(icon_lbl)

	# Tower data structure label — two lines if needed (e.g. Binary Search → Binary\nSearch)
	if data:
		var ds_text = data.data_structure
		if " " in ds_text and ds_text.length() > 8:
			ds_text = ds_text.replace(" ", "\n")
		var ds_lbl := Label.new()
		ds_lbl.text = ds_text
		ds_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ds_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ds_lbl.position = Vector2(2, visual_h * 0.55)
		ds_lbl.size = Vector2(left_w - 4, 26)
		ds_lbl.clip_text = true
		ds_lbl.add_theme_font_size_override("font_size", 7)
		ds_lbl.add_theme_color_override("font_color", Color("#6688AA"))
		icon_panel.add_child(ds_lbl)

	# ── Right Side: Info + Stats + Buttons ────────────
	var right_x := left_x + left_w + pad
	var right_y := pad
	var right_w_inner = right_w

	# Tower name
	var name_lbl := Label.new()
	name_lbl.text = tower.tower_name
	name_lbl.position = Vector2(right_x, right_y)
	name_lbl.size = Vector2(right_w_inner, row_h)
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", tower_color)
	bg.add_child(name_lbl)
	right_y += row_h + stat_sep

	# Level
	var lvl_lbl := Label.new()
	lvl_lbl.text = "Level " + str(tower.current_level) + " / " + str(tower.max_level)
	lvl_lbl.position = Vector2(right_x, right_y)
	lvl_lbl.size = Vector2(right_w_inner, row_h)
	lvl_lbl.add_theme_font_size_override("font_size", 9)
	lvl_lbl.add_theme_color_override("font_color", Color("#88AACC"))
	bg.add_child(lvl_lbl)
	right_y += row_h + stat_sep

	# ── Stats ─────────────────────────────────────────
	var max_stat_len = 20
	var raw_tgt = data.targeting if data else "—"
	if raw_tgt.length() > max_stat_len:
		raw_tgt = raw_tgt.substr(0, max_stat_len - 1) + "…"
	var stats := [
		["DMG", str(int(tower.damage))],
		["SPD", str(tower.attack_speed) + "x"],
		["RNG", str(int(tower.attack_range))],
		["TGT", raw_tgt],
	]
	for s in stats:
		var stat_lbl := Label.new()
		stat_lbl.text = s[0] + ":  " + s[1]
		stat_lbl.position = Vector2(right_x, right_y)
		stat_lbl.size = Vector2(right_w_inner, row_h)
		stat_lbl.add_theme_font_size_override("font_size", 9)
		stat_lbl.add_theme_color_override("font_color", Color("#CCDDEE"))
		bg.add_child(stat_lbl)
		right_y += row_h + stat_sep

	# ── Separator ─────────────────────────────────────
	right_y += 2
	var sep_line := ColorRect.new()
	sep_line.position = Vector2(right_x, right_y)
	sep_line.size = Vector2(right_w_inner, 1)
	sep_line.color = tower_color.darkened(0.5)
	bg.add_child(sep_line)
	right_y += btn_sep

	# ── Buttons ───────────────────────────────────────
	var half_btn_w = (right_w_inner - btn_sep) / 2.0

	# Upgrade button
	if tower.current_level < tower.max_level:
		var cost = tower.ram_cost * tower.current_level
		var upg_btn := Button.new()
		upg_btn.text = "UP\n" + str(cost) + "⚡"
		upg_btn.position = Vector2(right_x, right_y)
		upg_btn.custom_minimum_size = Vector2(half_btn_w, btn_h)
		upg_btn.size = Vector2(half_btn_w, btn_h)
		upg_btn.add_theme_font_size_override("font_size", 9)
		if ram_manager.can_afford(cost):
			upg_btn.add_theme_color_override("font_color", Color("#00FF88"))
		else:
			upg_btn.add_theme_color_override("font_color", Color("#FF3366"))
		var upg_style := StyleBoxFlat.new()
		upg_style.bg_color = Color("#0A1A10", 0.95)
		upg_style.border_color = Color("#00FF88") if ram_manager.can_afford(cost) else Color("#FF3366")
		upg_style.border_width_left = 1
		upg_style.border_width_right = 1
		upg_style.border_width_top = 1
		upg_style.border_width_bottom = 1
		upg_style.corner_radius_top_left = 6
		upg_style.corner_radius_top_right = 6
		upg_style.corner_radius_bottom_left = 6
		upg_style.corner_radius_bottom_right = 6
		upg_btn.add_theme_stylebox_override("normal", upg_style)
		upg_btn.pressed.connect(_on_upgrade_tower.bind(tower, cost))
		bg.add_child(upg_btn)

	# Sell button
	var sell_value = tower.ram_cost * tower.current_level
	var sell_btn := Button.new()
	sell_btn.text = "SELL\n" + str(sell_value) + "⚡"
	sell_btn.position = Vector2(right_x + half_btn_w + btn_sep, right_y)
	sell_btn.custom_minimum_size = Vector2(half_btn_w, btn_h)
	sell_btn.size = Vector2(half_btn_w, btn_h)
	sell_btn.add_theme_font_size_override("font_size", 9)
	sell_btn.add_theme_color_override("font_color", Color("#FF8844"))
	var sell_style := StyleBoxFlat.new()
	sell_style.bg_color = Color("#1A0E07", 0.95)
	sell_style.border_color = Color("#FF8844")
	sell_style.border_width_left = 1
	sell_style.border_width_right = 1
	sell_style.border_width_top = 1
	sell_style.border_width_bottom = 1
	sell_style.corner_radius_top_left = 6
	sell_style.corner_radius_top_right = 6
	sell_style.corner_radius_bottom_left = 6
	sell_style.corner_radius_bottom_right = 6
	sell_btn.add_theme_stylebox_override("normal", sell_style)
	sell_btn.pressed.connect(_on_sell_tower.bind(cell, tower, sell_value))
	bg.add_child(sell_btn)

	# ── Screen Clamp ──────────────────────────────────
	var screen_size = get_viewport_rect().size
	var clamp_margin = 20.0
	var half_w = total_w / 2.0
	var half_h = total_h / 2.0
	var menu_offset_x = clamp(overlay_menu.position.x, clamp_margin + half_w, screen_size.x - clamp_margin - half_w) - overlay_menu.position.x
	var menu_offset_y = clamp(overlay_menu.position.y, clamp_margin + half_h, screen_size.y - clamp_margin - half_h) - overlay_menu.position.y
	overlay_menu.position += Vector2(menu_offset_x, menu_offset_y)
	var final_pos = overlay_menu.position
	# Build-then-reveal: start at tower center small/transparent, slide to offset
	var start_pos = canvas_pos
	overlay_menu.position = start_pos
	bg.scale = Vector2(0.75, 0.75)
	bg.modulate.a = 0.0
	_set_overlay_visible(true)
	# Tower hologram pulse
	if is_instance_valid(tower):
		tower.scale = Vector2(1.15, 1.15)
		var pt = create_tween()
		pt.tween_property(tower, "scale", Vector2(1, 1), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(overlay_menu, "position", final_pos, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(bg, "scale", Vector2(1, 1), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(bg, "modulate:a", 1.0, 0.25)

func _on_sell_tower(cell: Vector2i, tower: Node, value: int) -> void:
	ram_manager.earn(value)
	grid_system.remove_tower(cell)
	if is_instance_valid(_selected_tower):
		_selected_tower.set_selected(false)
	_selected_tower = null
	tower.queue_free()
	_set_overlay_visible(false)
	_spawn_floating_text("+" + str(value) + "⚡ Sold!", tower.global_position, Color("#FF8844"), 14)
	_play_feedback(true)

func _on_upgrade_tower(tower: Node, cost: int) -> void:
	if not ram_manager.spend(cost):
		_flash_ram_label(false)
		_play_feedback(false)
		_show_ram_bubble()
		return
	var new_lvl = tower.upgrade()
	tower.set_selected(true)
	_set_overlay_visible(false)
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
	_set_overlay_visible(false)
	_spawn_floating_text(tower.get_ability_name() + "!", tower.global_position, Color("#FFB800"), 14)
	_play_feedback(true)

# ─── PLACEMENT PREVIEW & CONFIRMATION ──────────────────
func _create_preview_tower(def: Dictionary, cell: Vector2i) -> void:
	var data = TowerData.new()
	data.tower_id       = def["tower_id"]
	data.tower_name     = def["tower_name"]
	data.ram_cost       = def["ram_cost"]
	data.damage         = def["damage"]
	data.attack_speed   = def["attack_speed"]
	data.attack_range   = def["attack_range"]
	data.color          = def["color"]
	data.icon_text      = def["icon_text"]
	_preview_tower = TowerFactory.create_preview_tower(data)
	if _preview_tower:
		_preview_tower.set_selected(true)
		tower_layer.add_child(_preview_tower)
		_preview_tower.position = grid_system.get_cell_center(cell)
	_preview_tower.position = grid_system.get_cell_center(cell)

func _remove_preview_tower() -> void:
	if is_instance_valid(_preview_tower):
		_preview_tower.queue_free()
		_preview_tower = null
	_confirm_cell = Vector2i(-1, -1)

func _show_placement_confirmation(cell: Vector2i) -> void:
	var cell_center = grid_system.get_cell_center(cell)
	var canvas_pos = get_canvas_transform() * cell_center
	overlay_menu.position = canvas_pos
	for child in overlay_menu.get_children():
		child.queue_free()

	var btn_size := 36.0
	# Confirm (check) button
	var check_btn := Button.new()
	check_btn.text = "✓"
	check_btn.custom_minimum_size = Vector2(btn_size, btn_size)
	check_btn.size = Vector2(btn_size, btn_size)
	check_btn.position = Vector2(-btn_size - 6, -btn_size * 0.5)
	check_btn.add_theme_color_override("font_color", Color("#00FF88"))
	check_btn.add_theme_font_size_override("font_size", 18)
	var ok_style := StyleBoxFlat.new()
	ok_style.bg_color = Color("#071F0E", 0.95)
	ok_style.border_color = Color("#00FF88")
	ok_style.border_width_left = 2
	ok_style.border_width_right = 2
	ok_style.border_width_top = 2
	ok_style.border_width_bottom = 2
	ok_style.corner_radius_top_left = 18
	ok_style.corner_radius_top_right = 18
	ok_style.corner_radius_bottom_left = 18
	ok_style.corner_radius_bottom_right = 18
	check_btn.add_theme_stylebox_override("normal", ok_style)
	check_btn.pressed.connect(_on_confirm_placement)
	overlay_menu.add_child(check_btn)

	# Cancel (X) button
	var x_btn := Button.new()
	x_btn.text = "✗"
	x_btn.custom_minimum_size = Vector2(btn_size, btn_size)
	x_btn.size = Vector2(btn_size, btn_size)
	x_btn.position = Vector2(6, -btn_size * 0.5)
	x_btn.add_theme_color_override("font_color", Color("#FF3366"))
	x_btn.add_theme_font_size_override("font_size", 18)
	var cancel_style := StyleBoxFlat.new()
	cancel_style.bg_color = Color("#1F070E", 0.95)
	cancel_style.border_color = Color("#FF3366")
	cancel_style.border_width_left = 2
	cancel_style.border_width_right = 2
	cancel_style.border_width_top = 2
	cancel_style.border_width_bottom = 2
	cancel_style.corner_radius_top_left = 18
	cancel_style.corner_radius_top_right = 18
	cancel_style.corner_radius_bottom_left = 18
	cancel_style.corner_radius_bottom_right = 18
	x_btn.add_theme_stylebox_override("normal", cancel_style)
	x_btn.pressed.connect(_on_cancel_placement)
	overlay_menu.add_child(x_btn)

	var screen_size = get_viewport_rect().size
	var menu_offset_x = clamp(overlay_menu.position.x, 90.0, screen_size.x - 90.0) - overlay_menu.position.x
	var menu_offset_y = clamp(overlay_menu.position.y, 90.0, screen_size.y - 90.0) - overlay_menu.position.y
	overlay_menu.position += Vector2(menu_offset_x, menu_offset_y)
	_set_overlay_visible(true)

func _on_confirm_placement() -> void:
	if not is_instance_valid(_preview_tower):
		return
	_set_overlay_visible(false)
	var cell = _confirm_cell
	_remove_preview_tower()
	_place_tower(cell)

func _on_cancel_placement() -> void:
	if not is_instance_valid(_preview_tower):
		return
	_set_overlay_visible(false)
	_remove_preview_tower()

func _show_placement_radial(cell: Vector2i) -> void:
	# Determine equipped towers (bring/equip from tower select)
	var equipped = GameManager.selected_towers
	if equipped.is_empty():
		equipped = _get_level_config().get("towers", [])
	if equipped.is_empty():
		# Fail-safe backup: first 5 towers in data-driven order
		equipped = DataRegistry.get_tower_ids_ordered().slice(0, 5)
		
	# Build radial selection
	var num_options = equipped.size()
	var radius = 96.0
	var btn_w = 78.0
	var btn_h = 100.0
	
	for i in range(num_options):
		var tower_id = equipped[i]
		if not GameManager.TOWER_DEFINITIONS.has(tower_id):
			continue
		var def = GameManager.TOWER_DEFINITIONS[tower_id]
		
		# Compute angle position
		var angle = -PI/2 + (i * 2.0 * PI / num_options)
		var offset_pos = Vector2(cos(angle), sin(angle)) * radius
		
		# Generous touch target button (Works beautifully on mobile)
		var btn := TextureButton.new()
		btn.custom_minimum_size = Vector2(btn_w, btn_h)
		btn.size = Vector2(btn_w, btn_h)
		btn.position = offset_pos - Vector2(btn_w / 2.0, btn_h / 2.0)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_SCALE
		
		# Style rounded rectangle icon container
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color("#070F1E", 0.9)
		normal_style.border_color = Color(def["color"])
		normal_style.border_width_left = 2
		normal_style.border_width_right = 2
		normal_style.border_width_top = 2
		normal_style.border_width_bottom = 2
		normal_style.corner_radius_top_left = 10
		normal_style.corner_radius_top_right = 10
		normal_style.corner_radius_bottom_left = 10
		normal_style.corner_radius_bottom_right = 10
		
		# Display StyleBox as backdrop on the button using a Panel
		var bg_panel := Panel.new()
		bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg_panel.add_theme_stylebox_override("panel", normal_style)
		btn.add_child(bg_panel)
		
		# Visual tower (icon at top half of button, centered horizontally)
		var dummy_data = TowerData.new()
		dummy_data.tower_id = def["tower_id"]
		dummy_data.tower_name = def["tower_name"]
		dummy_data.ram_cost = def["ram_cost"]
		dummy_data.damage = def["damage"]
		dummy_data.attack_speed = def["attack_speed"]
		dummy_data.attack_range = def["attack_range"]
		dummy_data.color = def["color"]
		dummy_data.icon_text = def["icon_text"]

		var visual_tower = TowerFactory.create_preview_tower(dummy_data)
		if visual_tower:
			visual_tower.position = Vector2(btn_w / 2.0, 24.0)
			# Scale down model to fit in the top icon area
			visual_tower.scale = Vector2(0.42, 0.42)
			# Strip game behaviors from visual preview model
			visual_tower.set_process(false)
			visual_tower.set_physics_process(false)
			visual_tower.set_process_input(false)
			btn.add_child(visual_tower)
		
		# Tower name — split on space so Binary Tower → Binary\nTower (avoids side-border touch)
		var tname = def["tower_name"]
		if " " in tname:
			tname = tname.replace(" ", "\n")
		var name_lbl := Label.new()
		name_lbl.text = tname
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 8)
		name_lbl.add_theme_color_override("font_color", Color("#88AACC"))
		name_lbl.position = Vector2(0, 46)
		name_lbl.custom_minimum_size = Vector2(btn_w, 26)
		name_lbl.size = Vector2(btn_w, 26)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(name_lbl)
		
		# Price Tag centered horizontally and vertically at bottom
		var price_lbl := Label.new()
		price_lbl.text = str(def["ram_cost"]) + "⚡"
		price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		price_lbl.add_theme_font_size_override("font_size", 10)
		price_lbl.add_theme_color_override("font_color", Color("#00D4FF"))
		price_lbl.position = Vector2(0, 80)
		price_lbl.custom_minimum_size = Vector2(btn_w, 16)
		price_lbl.size = Vector2(btn_w, 16)
		price_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(price_lbl)

		# Effectiveness indicator — shows if tower counters enemies in this level
		var tower_res: TowerData = DataRegistry.get_tower(tower_id)
		if tower_res:
			var level_enemy_types: Array[String] = []
			var lvl_cfg = _get_level_config()
			for et in lvl_cfg.get("enemy_types", []):
				level_enemy_types.append(str(et))
			var strong_count := 0
			for et in level_enemy_types:
				if et in tower_res.strong_against:
					strong_count += 1
			if strong_count > 0:
				var eff_lbl := Label.new()
				eff_lbl.text = "2.0x"
				eff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				eff_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				eff_lbl.add_theme_font_size_override("font_size", 7)
				eff_lbl.add_theme_color_override("font_color", Color("#00FF88"))
				eff_lbl.position = Vector2(btn_w - 24, 6)
				eff_lbl.custom_minimum_size = Vector2(20, 10)
				eff_lbl.size = Vector2(20, 10)
				eff_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var eff_bg := StyleBoxFlat.new()
				eff_bg.bg_color = Color("#00FF88", 0.15)
				eff_bg.border_color = Color("#00FF88", 0.6)
				eff_bg.border_width_left = 1
				eff_bg.border_width_right = 1
				eff_bg.border_width_top = 1
				eff_bg.border_width_bottom = 1
				eff_bg.corner_radius_top_left = 3
				eff_bg.corner_radius_top_right = 3
				eff_bg.corner_radius_bottom_left = 3
				eff_bg.corner_radius_bottom_right = 3
				eff_lbl.add_theme_stylebox_override("normal", eff_bg)
				btn.add_child(eff_lbl)
		
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
	
	center_close.pressed.connect(func(): _set_overlay_visible(false); _current_menu_cell = Vector2i(-1, -1))
	overlay_menu.add_child(center_close)
	
	# Clamp positions of buttons inside screen borders for mobile viewports
	var screen_size = get_viewport_rect().size
	var clamp_margin_x = btn_w + radius
	var clamp_margin_y = btn_h + radius
	var menu_offset_x = clamp(overlay_menu.position.x, clamp_margin_x, screen_size.x - clamp_margin_x) - overlay_menu.position.x
	var menu_offset_y = clamp(overlay_menu.position.y, clamp_margin_y, screen_size.y - clamp_margin_y) - overlay_menu.position.y
	overlay_menu.position += Vector2(menu_offset_x, menu_offset_y)
	
	_set_overlay_visible(true)

func _place_tower(cell: Vector2i) -> void:
	ram_manager.spend(selected_tower_data.ram_cost)

	var tower = TowerFactory.create_tower(selected_tower_data, cell, enemy_layer)
	if tower == null:
		push_error("[Level] Failed to create tower: ", selected_tower_data.tower_id)
		return
	tower_layer.add_child(tower)
	tower.position = grid_system.get_cell_center(cell)
	grid_system.place_tower(cell, tower)

	SignalBus.tower_placed.emit(selected_tower_data.tower_id, cell)
	print("[Level] Tower placed at: ", cell)
	
	grid_system.first_tower_placed.emit(selected_tower_data.tower_id)
	_play_feedback(true)
	# Auto pop easy exercise when placing the featured tower for this level (once, non-blocking)
	var trigger = TOWER_EXERCISE_MAP.get(level_number, "")
	if not _tower_exercise_shown and trigger != "" and selected_tower_data.tower_id == trigger:
		_tower_exercise_shown = true
		_exercise_difficulty = "easy"
		# brief build pause then slide-in exercise (gameplay not paused)
		await get_tree().create_timer(0.6).timeout
		if not is_instance_valid(micro_panel) or micro_panel.visible:
			return
		_show_challenge()

# ─── TOWER SELECTION ───────────────────────────────────
func _on_tower_selected(tower_id: String) -> void:
	var def = GameManager.TOWER_DEFINITIONS[tower_id]
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
	_update_enemy_tooltip()
	if is_instance_valid(_challenge_drag_preview):
		_challenge_drag_preview.global_position = get_viewport().get_mouse_position() + Vector2(12, -12)
	if _tutorial_active:
		_update_wave_progress_bar()
		return
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
	_diff_badge.add_theme_font_size_override("font_size", _fs(0.025, 16.0, 16.0))
	_diff_badge.flat = true
	_diff_badge.pressed.connect(_show_diff_popup.bind(mod))
	skip_wave_btn.add_sibling(_diff_badge)
	# Level 1 exercise button between Skip and EXPERT
	_setup_exercise_button()

func _setup_exercise_button() -> void:
	if _exercise_btn != null and is_instance_valid(_exercise_btn):
		_exercise_btn.queue_free()
		_exercise_btn = null
	_exercise_btn = Button.new()
	_exercise_btn.text = "🧩 Exercise"
	_exercise_btn.tooltip_text = "Micro coding exercise (Level 1)"
	_exercise_btn.add_theme_font_size_override("font_size", _fs(0.025, 13.0, 15.0))
	_exercise_btn.add_theme_color_override("font_color", Color("#00D4FF"))
	var ex_style := StyleBoxFlat.new()
	ex_style.bg_color = Color("#0D1A33")
	ex_style.border_color = Color("#00D4FF", 0.6)
	ex_style.border_width_left = 1
	ex_style.border_width_right = 1
	ex_style.border_width_top = 1
	ex_style.border_width_bottom = 1
	ex_style.corner_radius_top_left = 6
	ex_style.corner_radius_top_right = 6
	ex_style.corner_radius_bottom_left = 6
	ex_style.corner_radius_bottom_right = 6
	ex_style.content_margin_left = 8
	ex_style.content_margin_right = 8
	ex_style.content_margin_top = 4
	ex_style.content_margin_bottom = 4
	_exercise_btn.add_theme_stylebox_override("normal", ex_style)
	_exercise_btn.add_theme_stylebox_override("hover", ex_style)
	_exercise_btn.pressed.connect(_on_exercise_pressed)
	# Place between Skip and EXPERT: Skip is before diff, so add as sibling before diff
	_diff_badge.add_sibling(_exercise_btn, true)

func _on_exercise_pressed() -> void:
	_hide_exercise_bubble()
	if _difficulty_picker and is_instance_valid(_difficulty_picker):
		_difficulty_picker.visible = true
		_difficulty_picker.move_to_front()
	if _exercise_btn:
		var t = create_tween()
		t.tween_property(_exercise_btn, "modulate", Color(1,1,1,0.5), 0.15)
		t.tween_property(_exercise_btn, "modulate", Color(1,1,1,1), 0.15)

func _on_difficulty_selected(diff: String) -> void:
	_exercise_difficulty = diff
	if _difficulty_picker:
		_difficulty_picker.visible = false
	_hide_exercise_bubble()
	_show_challenge()

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
		_diff_badge.add_theme_font_size_override("font_size", _fs(0.025, 16.0, 16.0))
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
		_open_pause_menu()

# ─── PAUSE / SPEED HANDLERS ────────────────────────────
func _open_pause_menu() -> void:
	get_tree().paused = true
	pause_menu.visible = true

func _on_pause_released() -> void:
	var elapsed = (Time.get_ticks_msec() / 1000.0) - _pause_press_time
	if elapsed >= 2.0:
		# Long press — open command panel
		var cp = preload("res://scenes/core/CommandPanel.gd").new()
		add_child(cp)
	else:
		# Short press — normal pause
		_open_pause_menu()

func _on_resume_pressed() -> void:
	get_tree().paused = false
	pause_menu.visible = false

func _on_fast_forward_pressed() -> void:
	_is_fast_forward = not _is_fast_forward
	if _is_fast_forward:
		Engine.time_scale = 2.0
		_ff_btn.add_theme_color_override("font_color", Color("#FFB800"))
		_ff_btn.tooltip_text = "Fast-forward (2x) — ON"
	else:
		Engine.time_scale = 1.0
		_ff_btn.add_theme_color_override("font_color", Color("#4A7FA5"))
		_ff_btn.tooltip_text = "Fast-forward (2x)"

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
	if wave_num == 1:
		call_deferred("_show_exercise_bubble")

func _show_exercise_bubble() -> void:
	if not is_instance_valid(_exercise_btn) or not _exercise_btn.visible:
		return
	if _exercise_bubble and is_instance_valid(_exercise_bubble):
		_exercise_bubble.queue_free()
	_exercise_bubble = PanelContainer.new()
	_exercise_bubble.z_index = 10
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color("#0D1A33")
	bs.border_color = Color("#00D4FF")
	bs.border_width_left = 1
	bs.border_width_right = 1
	bs.border_width_top = 1
	bs.border_width_bottom = 1
	bs.corner_radius_top_left = 8
	bs.corner_radius_top_right = 8
	bs.corner_radius_bottom_left = 8
	bs.corner_radius_bottom_right = 8
	bs.content_margin_left = 10
	bs.content_margin_right = 10
	bs.content_margin_top = 8
	bs.content_margin_bottom = 10
	_exercise_bubble.add_theme_stylebox_override("panel", bs)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	_exercise_bubble.add_child(vbox)
	var lbl := Label.new()
	lbl.text = "🧩 Try Exercise!  Easy 20 / Medium 30 / Hard 50 RAM"
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color("#E0F8FF"))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl)
	var hint := Label.new()
	hint.text = "▲ tap 🧩 Exercise between Skip and EXPERT"
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", Color("#88CCFF"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)
	$HUD/HUDControl.add_child(_exercise_bubble)
	# Position just below exercise button
	await get_tree().process_frame
	if not is_instance_valid(_exercise_btn) or not is_instance_valid(_exercise_bubble):
		return
	var btn_pos = _exercise_btn.global_position
	var btn_size = _exercise_btn.size
	_exercise_bubble.position = btn_pos + Vector2(btn_size.x * 0.5 - _exercise_bubble.size.x * 0.5, btn_size.y + 6)
	# Pop animation
	_exercise_bubble.scale = Vector2(0.7, 0.7)
	_exercise_bubble.modulate.a = 0.0
	var t = create_tween().set_parallel(true)
	t.tween_property(_exercise_bubble, "scale", Vector2(1, 1), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_exercise_bubble, "modulate:a", 1.0, 0.25)
	# Auto-hide after 5s or when exercise opened
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(_exercise_bubble):
		var t2 = create_tween()
		t2.tween_property(_exercise_bubble, "modulate:a", 0.0, 0.4)
		t2.tween_callback(func(): if is_instance_valid(_exercise_bubble): _exercise_bubble.queue_free(); _exercise_bubble = null)

func _hide_exercise_bubble() -> void:
	if _exercise_bubble and is_instance_valid(_exercise_bubble):
		_exercise_bubble.queue_free()
		_exercise_bubble = null

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
	ProgressManager.add_campaign_time(level_number, elapsed)
	ProgressManager.record_ram_efficiency(ram_manager.get_efficiency())
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
func _freeze_gameplay() -> void:
	# Stop waves + RAM accrual and freeze every live enemy, tower, projectile
	# in place WITHOUT pausing the whole SceneTree (which would block UI input
	# on the lesson-unlock popup).
	managers_node.process_mode = Node.PROCESS_MODE_DISABLED
	for n in [enemy_layer, tower_layer, projectile_layer]:
		for child in n.get_children():
			child.process_mode = Node.PROCESS_MODE_DISABLED

func _show_result_panel(victory: bool) -> void:
	_freeze_gameplay()
	SoundManager.stop_music()
	if victory:
		SoundManager.play_game_over()
	for child in game_over_panel.get_children():
		child.queue_free()
	# End-state UI must keep processing so its buttons stay clickable.
	game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", _fs(0.030, 12.0, 16.0))
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", _fs(0.070, 22.0, 32.0))
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
	score_lbl.add_theme_font_size_override("font_size", _fs(0.045, 16.0, 20.0))
	layout.add_child(score_lbl)

	var grade     = _get_grade()
	var grade_lbl := Label.new()
	grade_lbl.text = "Grade: " + grade["letter"]
	grade_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_lbl.add_theme_font_size_override("font_size", _fs(0.105, 24.0, 48.0))
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
		star_lbl.add_theme_font_size_override("font_size", _fs(0.060, 22.0, 28.0))
		layout.add_child(star_lbl)
		SignalBus.level_complete.emit(level_number, score, stars)

	if victory:
		var unlock_lbl := Label.new()
		unlock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unlock_lbl.add_theme_color_override("font_color", Color("#00D4FF"))
		unlock_lbl.add_theme_font_size_override("font_size", _fs(0.030, 16.0, 16.0))
		if ProgressManager.LEVEL_UNLOCKS_LESSON.has(level_number):
			var next_lesson = ProgressManager.LEVEL_UNLOCKS_LESSON[level_number]
			unlock_lbl.text = "🔓 New lesson unlocked: " + next_lesson
		layout.add_child(unlock_lbl)

	var stats_row := HBoxContainer.new()
	stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_row.add_theme_constant_override("separation", _fs(0.045, 16.0, 24.0))
	_add_result_stat(stats_row, "BASE HP",  str(base_health) + "/10")
	_add_result_stat(stats_row, "WAVES",
		str(wave_manager.current_wave) + "/" + str(wave_manager.total_waves))
	var elapsed = int((Time.get_ticks_msec() / 1000.0) - level_start_time)
	_add_result_stat(stats_row, "TIME", str(elapsed) + "s")
	layout.add_child(stats_row)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", _fs(0.025, 8.0, 12.0))

	var btn_h := _fs(0.075, 44.0, 52.0)
	var retry_btn := Button.new()
	retry_btn.text = "↺ Retry"
	retry_btn.custom_minimum_size = Vector2(_fs(0.25, 120.0, 140.0), btn_h)
	retry_btn.add_theme_font_size_override("font_size", _fs(0.035, 16.0, 18.0))
	retry_btn.pressed.connect(_on_retry_pressed)
	btn_row.add_child(retry_btn)

	var menu_btn := Button.new()
	menu_btn.text = "🏠 Level Select"
	menu_btn.custom_minimum_size = Vector2(_fs(0.30, 140.0, 160.0), btn_h)
	menu_btn.add_theme_font_size_override("font_size", _fs(0.035, 16.0, 18.0))
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
	col.add_theme_constant_override("separation", _fs(0.008, 2.0, 4.0))

	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", _fs(0.025, 16.0, 16.0))
	lbl.add_theme_color_override("font_color", Color("#4A7FA5"))
	col.add_child(lbl)

	var val := Label.new()
	val.text = value
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val.add_theme_font_size_override("font_size", _fs(0.030, 16.0, 18.0))
	val.add_theme_color_override("font_color", Color("#E8F4FD"))
	col.add_child(val)

	container.add_child(col)

# ─── NAVIGATION ────────────────────────────────────────
func _on_back_pressed() -> void:
	GameManager.go_to("campaign")

# ─── HUD HELPERS ───────────────────────────────────────
func _update_ram_label() -> void:
	ram_label.text = str(ram_manager.get_current())

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
	# White SVG-like fallback for HUD badge (matches hud_ram.svg: rect + pins + circle)
	return _make_icon(func(img):
		for x in range(7, 17):
			for y in range(7, 17):
				if x == 7 or x == 16 or y == 7 or y == 16:
					img.set_pixel(x, y, Color(1, 1, 1, 0.95))
					img.set_pixel(x+1, y, Color(1, 1, 1, 0.15))
					img.set_pixel(x, y+1, Color(1, 1, 1, 0.15))
		for i in range(4):
			var px = 5 + i*4
			for x in range(px, px + 2):
				for y in range(10, 14):
					if x == 5 or x == 17:
						img.set_pixel(x, y, Color(1, 1, 1, 0.9))
			for y in range(5, 7):
				for x in range(10, 14):
					if y == 5:
						img.set_pixel(10 + i, y, Color(1, 1, 1, 0.85))
			for y in range(17, 19):
				for x in range(10, 14):
					if y == 18:
						img.set_pixel(10 + i, y, Color(1, 1, 1, 0.85))
		for r in range(2):
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					if abs(dx) + abs(dy) <= 1:
						img.set_pixel(12 + dx, 12 + dy, Color(1, 1, 1, 0.95))
	)

func _icon_shield() -> ImageTexture:
	# White heart fallback (matches hud_health.svg)
	return _make_icon(func(img):
		for a in range(0, 360, 8):
			var rad = a * PI / 180.0
			var rx = 12 + cos(rad) * (8.0 - abs(sin(rad))*3.0)
			var ry = 12 + sin(rad) * 7.0 - 2.0
			if rad > PI: ry += 3.0
			img.set_pixel(int(rx), int(ry), Color(1, 1, 1, 0.95))
		for x in range(8, 17):
			for y in range(7, 15):
				var d = Vector2(x-12, y-11).length()
				if d < 5.5 and d > 4.0:
					var cur = img.get_pixel(x, y)
					img.set_pixel(x, y, cur.blend(Color(1, 1, 1, 0.55)))
	)

func _icon_star() -> ImageTexture:
	# White star fallback (matches hud_score.svg)
	return _make_icon(func(img):
		var pts: Array[Vector2] = []
		for i in range(5):
			var a = -PI/2 + i * 2*PI/5
			pts.append(Vector2(12 + cos(a) * 8, 12 + sin(a) * 8))
		for i in range(5):
			var p1 = pts[i]
			var p2 = pts[(i+1)%5]
			var steps = int(p1.distance_to(p2))
			for s in range(steps):
				var t = float(s)/steps
				var px = int(lerp(p1.x, p2.x, t))
				var py = int(lerp(p1.y, p2.y, t))
				img.set_pixel(px, py, Color(1, 1, 1, 0.95))
				img.set_pixel(px+1, py, Color(1, 1, 1, 0.3))
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				img.set_pixel(12+dx, 12+dy, Color(1, 1, 1, 0.9))
	)

func _icon_signal() -> ImageTexture:
	# White signal bars fallback (matches hud_wave.svg)
	return _make_icon(func(img):
		var xs = [5, 10, 15, 20]
		var hs = [4, 8, 12, 16]
		for i in range(4):
			var bx = xs[i]
			for y in range(20 - hs[i], 20):
				for x in range(bx-1, bx+2):
					img.set_pixel(x, y, Color(1, 1, 1, 0.95))
					if x == bx: img.set_pixel(x, y, Color(1, 1, 1, 1.0))
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
	print("[HUD] Building NEW overlapping pills — outer 114×32 icon 32 badge (ref image style)")
	var top = $HUD/HUDControl/TopHUD/TopLayout
	# Clean old pills so new overlapping-icon layout rebuilds (hot-reload + restart)
	var old_pills: Array = []
	for c in top.get_children():
		if c.has_meta("hud_pill"):
			old_pills.append(c)
		elif c is TextureRect and c.has_meta("hud_icon"):
			# legacy 18px inside icons
			old_pills.append(c)
	for outer in old_pills:
		# find any hud label inside outer and re-parent it back to top
		var lbl_found: Label = null
		var stack: Array = [outer]
		while stack.size() > 0:
			var n = stack.pop_back()
			if n is Label:
				if n == ram_label or n == wave_label or n == base_health_label or n == score_label:
					lbl_found = n
					break
			for ch in n.get_children():
				stack.append(ch)
		if lbl_found:
			var p = lbl_found.get_parent()
			if p:
				p.remove_child(lbl_found)
			top.add_child(lbl_found)
		outer.queue_free()
	# Also clean legacy inside-icons that were direct children of top
	for c in top.get_children():
		if c is TextureRect and c.has_meta("hud_icon_for"):
			c.queue_free()

	# Pill HUD — SVG icons from assets/icons (24×24 stroke white) beside pill, slightly bigger, no circle — like reference
	var tex_ram = load("res://assets/icons/hud_ram.svg") if ResourceLoader.exists("res://assets/icons/hud_ram.svg") else _icon_chip()
	var tex_wave = load("res://assets/icons/hud_wave.svg") if ResourceLoader.exists("res://assets/icons/hud_wave.svg") else _icon_signal()
	var tex_health = load("res://assets/icons/hud_health.svg") if ResourceLoader.exists("res://assets/icons/hud_health.svg") else _icon_shield()
	var tex_score = load("res://assets/icons/hud_score.svg") if ResourceLoader.exists("res://assets/icons/hud_score.svg") else _icon_star()
	_wrap_label_in_pill(top, ram_label, tex_ram, Color("#162E4A"), Color("#00D4FF"))
	_wrap_label_in_pill(top, wave_label, tex_wave, Color("#241E52"), Color("#FFD60A"))
	_wrap_label_in_pill(top, base_health_label, tex_health, Color("#4A1430"), Color("#FF2E63"))
	_wrap_label_in_pill(top, score_label, tex_score, Color("#4A3510"), Color("#C86AFF"))

	var tex_pause = load("res://assets/icons/hud_pause.svg") if ResourceLoader.exists("res://assets/icons/hud_pause.svg") else _icon_pause()
	var tex_skip = load("res://assets/icons/hud_skip.svg") if ResourceLoader.exists("res://assets/icons/hud_skip.svg") else _icon_skip()
	pause_btn.icon = tex_pause
	pause_btn.expand_icon = true
	pause_btn.text = ""
	skip_wave_btn.icon = tex_skip
	skip_wave_btn.expand_icon = true
	skip_wave_btn.text = "Skip (20⚡)"
	back_btn.icon = _icon_power()
	back_btn.expand_icon = true
	if _ff_btn and is_instance_valid(_ff_btn):
		_ff_btn.icon = tex_skip
		_ff_btn.expand_icon = true
		_ff_btn.text = ""
	if _diff_badge and is_instance_valid(_diff_badge):
		_diff_badge.icon = tex_wave
		_diff_badge.expand_icon = true

func _wrap_label_in_pill(parent: Node, label: Label, icon_tex: Texture2D, bg_col: Color, border_col: Color) -> void:
	# Already wrapped? (retry)
	if label.get_parent() != parent:
		return
	# Remove any stale icon TextureRects for this label
	for c in parent.get_children():
		if c is TextureRect and c.has_meta("hud_icon_for") and c.get_meta("hud_icon_for") == label.get_instance_id():
			c.queue_free()
	var idx = label.get_index()
	parent.remove_child(label)

	# Outer wrapper: icon slightly bigger (32) overlapping left edge of pill — like reference image, no circle
	var outer := Control.new()
	outer.set_meta("hud_pill", true)
	outer.custom_minimum_size = Vector2(116, 32)
	outer.size = Vector2(116, 32)
	outer.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var pill := PanelContainer.new()
	pill.position = Vector2(18, 2)
	pill.custom_minimum_size = Vector2(98, 28)
	pill.size = Vector2(98, 28)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.bg_color.a = 0.98
	sb.border_color = border_col
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	sb.content_margin_left = 16
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	sb.shadow_size = 4
	sb.shadow_color = Color(0, 0, 0, 0.25)
	pill.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#FFFFFF"))
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	hbox.add_child(label)
	pill.add_child(hbox)
	outer.add_child(pill)

	# Icon beside pill, slightly bigger (32 vs 28) — colored to match border_col like reference heart/bolt/gem
	# Drop shadow (dark duplicate 1.5px offset) for pop like reference
	var icon_shadow = TextureRect.new()
	icon_shadow.texture = icon_tex
	icon_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_shadow.size = Vector2(32, 32)
	icon_shadow.position = Vector2(1.5, 1.5)
	icon_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_shadow.z_index = 0
	icon_shadow.modulate = Color(0, 0, 0, 0.45)
	outer.add_child(icon_shadow)

	var icon_rect = TextureRect.new()
	icon_rect.texture = icon_tex
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.size = Vector2(32, 32)
	icon_rect.position = Vector2(0, 0)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.z_index = 1
	# SVG is white stroke — tint to border_col for vivid color like reference (red heart, yellow bolt, purple gem)
	icon_rect.modulate = border_col
	outer.add_child(icon_rect)

	parent.add_child(outer)
	parent.move_child(outer, idx)

func _add_icon_before_label(parent: Node, icon_tex: ImageTexture, label: Label, icon_size: Vector2) -> void:
	var icon_rect = TextureRect.new()
	icon_rect.texture = icon_tex
	icon_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = icon_size
	icon_rect.size = icon_size
	icon_rect.set_meta("hud_icon", true)
	icon_rect.set_meta("hud_icon_for", label.get_instance_id())
	parent.add_child(icon_rect)
	var idx = label.get_index()
	parent.move_child(icon_rect, idx)
	label.add_theme_constant_override("margin_left", 4)

# ─── HUD STYLES ────────────────────────────────────────
# ─── HELPERS ───────────────────────────────────────────
func _min_dim() -> float:
	var vp := get_viewport().get_visible_rect().size
	return minf(maxf(vp.x, 320.0), maxf(vp.y, 240.0))

func _fs(ratio: float, floor_v: float, cap_v: float) -> int:
	return int(clampf(_min_dim() * ratio, floor_v, cap_v))

func _apply_responsive_challenge() -> void:
	if _challenge_title == null or not is_instance_valid(_challenge_title):
		return
	# Fluid typography for HUD labels
	level_label.add_theme_font_size_override("font_size", _fs(0.030, 16.0, 18.0))
	ram_label.add_theme_font_size_override("font_size", _fs(0.030, 16.0, 18.0))
	wave_label.add_theme_font_size_override("font_size", _fs(0.030, 16.0, 18.0))
	base_health_label.add_theme_font_size_override("font_size", _fs(0.030, 16.0, 18.0))
	score_label.add_theme_font_size_override("font_size", _fs(0.030, 16.0, 18.0))
	# Fluid typography for pause menu
	pause_title.add_theme_font_size_override("font_size", _fs(0.055, 20.0, 28.0))
	# Fluid typography for challenge panel
	_challenge_title.add_theme_font_size_override("font_size", _fs(0.045, 18.0, 24.0))
	_challenge_desc.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 18.0))
	_challenge_code_edit.add_theme_font_size_override("font_size", _fs(0.034, 16.0, 18.0))
	_challenge_output.add_theme_font_size_override("font_size", _fs(0.030, 16.0, 16.0))
	_challenge_result.add_theme_font_size_override("font_size", _fs(0.034, 16.0, 18.0))
	# Fluid typography for wave splash
	wave_splash_label.add_theme_font_size_override("font_size", _fs(0.105, 24.0, 48.0))

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
	btn.add_theme_font_size_override("font_size", _fs(0.025, 16.0, 16.0))

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
	btn.add_theme_font_size_override("font_size", _fs(0.030, 16.0, 16.0))
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
var _challenge_choice_box: VBoxContainer = null
var _challenge_blank_btn: Button = null
var _challenge_blank_btns: Array[Button] = []
var _challenge_choices_row: HBoxContainer = null
var _challenge_selected_choice: String = ""
var _challenge_is_choice: bool = false
var _challenge_dragging_choice: String = ""
var _challenge_drag_preview: Label = null
var _level1_shuffled: Array = []
var _exercise_difficulty: String = "easy"
var _medium_blank_edits: Array[LineEdit] = []
var _difficulty_picker: PanelContainer = null

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
	_challenge_title.add_theme_font_size_override("font_size", _fs(0.045, 18.0, 24.0))
	_challenge_title.add_theme_color_override("font_color", Color("#00D4FF"))
	header.add_child(_challenge_title)
	var hspacer = Control.new()
	hspacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(hspacer)
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(28, 28)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_color_override("font_color", Color("#FF5577"))
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color("#1A0A1A", 0.0)
	close_style.corner_radius_top_left = 6
	close_style.corner_radius_top_right = 6
	close_style.corner_radius_bottom_left = 6
	close_style.corner_radius_bottom_right = 6
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.pressed.connect(_hide_challenge)
	header.add_child(close_btn)
	layout.add_child(header)

	_challenge_desc = Label.new()
	_challenge_desc.add_theme_font_size_override("font_size", _fs(0.032, 16.0, 18.0))
	_challenge_desc.add_theme_color_override("font_color", Color("#A0B8D0"))
	_challenge_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_challenge_desc)

	_challenge_code_edit = TextEdit.new()
	_challenge_code_edit.custom_minimum_size = Vector2(0, _fs(0.30, 100.0, 160.0))
	_challenge_code_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_challenge_code_edit.add_theme_font_override("font", ThemeDB.fallback_font)
	_challenge_code_edit.add_theme_font_size_override("font_size", _fs(0.034, 16.0, 18.0))
	_challenge_code_edit.add_theme_color_override("background_color", Color("#030812"))
	_challenge_code_edit.add_theme_color_override("font_color", Color("#FFFFFF"))
	_challenge_code_edit.add_theme_color_override("caret_color", Color("#00D4FF"))
	_challenge_code_edit.add_theme_color_override("selection_color", Color("#00D4FF", 0.3))
	_challenge_code_edit.syntax_highlighter = null
	_challenge_code_edit.highlight_all_occurrences = false
	layout.add_child(_challenge_code_edit)

	# ── Choice mode UI (Level 1 inline blank + chips) ──
	_challenge_choice_box = VBoxContainer.new()
	_challenge_choice_box.visible = false
	_challenge_choice_box.add_theme_constant_override("separation", 12)
	var code_panel := PanelContainer.new()
	var code_style := StyleBoxFlat.new()
	code_style.bg_color = Color("#030812")
	code_style.border_color = Color("#00D4FF", 0.3)
	code_style.border_width_left = 1
	code_style.border_width_right = 1
	code_style.border_width_top = 1
	code_style.border_width_bottom = 1
	code_style.corner_radius_top_left = 6
	code_style.corner_radius_top_right = 6
	code_style.corner_radius_bottom_left = 6
	code_style.corner_radius_bottom_right = 6
	code_style.content_margin_left = 12
	code_style.content_margin_right = 12
	code_style.content_margin_top = 12
	code_style.content_margin_bottom = 12
	code_panel.add_theme_stylebox_override("panel", code_style)
	_challenge_choice_box.add_child(code_panel)
	_challenge_choices_row = HBoxContainer.new()
	_challenge_choices_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_challenge_choices_row.add_theme_constant_override("separation", 8)
	_challenge_choice_box.add_child(_challenge_choices_row)
	layout.add_child(_challenge_choice_box)

	var btn_row = HBoxContainer.new()
	var btn_h := _fs(0.055, 36.0, 44.0)
	var run_btn = Button.new()
	run_btn.text = "▶ Run Code"
	run_btn.custom_minimum_size = Vector2(_fs(0.22, 110.0, 140.0), btn_h)
	run_btn.pressed.connect(_on_challenge_run)
	_style_challenge_btn(run_btn, Color("#00FF88"))
	btn_row.add_child(run_btn)
	var submit_btn = Button.new()
	submit_btn.text = "✔ Submit"
	submit_btn.custom_minimum_size = Vector2(_fs(0.22, 110.0, 140.0), btn_h)
	submit_btn.pressed.connect(_on_challenge_submit)
	_style_challenge_btn(submit_btn, Color("#00D4FF"))
	btn_row.add_child(submit_btn)
	var skip_btn = Button.new()
	skip_btn.text = "⏭ Skip"
	skip_btn.custom_minimum_size = Vector2(_fs(0.18, 90.0, 120.0), btn_h)
	skip_btn.pressed.connect(_on_challenge_skip)
	_style_challenge_btn(skip_btn, Color("#4A7FA5"))
	btn_row.add_child(skip_btn)
	btn_row.add_theme_constant_override("separation", 6)
	layout.add_child(btn_row)

	_challenge_output = Label.new()
	_challenge_output.add_theme_font_size_override("font_size", _fs(0.030, 16.0, 16.0))
	_challenge_output.add_theme_color_override("font_color", Color("#4A7FA5"))
	_challenge_output.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_challenge_output.custom_minimum_size = Vector2(0, _fs(0.10, 36.0, 48.0))
	layout.add_child(_challenge_output)

	_challenge_result = Label.new()
	_challenge_result.add_theme_font_size_override("font_size", _fs(0.034, 16.0, 18.0))
	_challenge_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(_challenge_result)

	micro_panel.visible = false
	_build_difficulty_picker()

func _build_difficulty_picker() -> void:
	if _difficulty_picker != null and is_instance_valid(_difficulty_picker):
		_difficulty_picker.queue_free()
	_difficulty_picker = PanelContainer.new()
	_difficulty_picker.visible = false
	_difficulty_picker.custom_minimum_size = Vector2(360, 200)
	_difficulty_picker.set_anchors_preset(Control.PRESET_CENTER)
	# PRESET_CENTER sets offsets before size is known → fix to true center
	_difficulty_picker.offset_left = -180
	_difficulty_picker.offset_top = -100
	_difficulty_picker.offset_right = 180
	_difficulty_picker.offset_bottom = 100
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color("#080F1E")
	ds.border_color = Color("#00D4FF")
	ds.border_width_left = 2
	ds.border_width_right = 2
	ds.border_width_top = 2
	ds.border_width_bottom = 2
	ds.corner_radius_top_left = 10
	ds.corner_radius_top_right = 10
	ds.corner_radius_bottom_left = 10
	ds.corner_radius_bottom_right = 10
	ds.content_margin_left = 16
	ds.content_margin_right = 16
	ds.content_margin_top = 16
	ds.content_margin_bottom = 16
	_difficulty_picker.add_theme_stylebox_override("panel", ds)
	$HUD/HUDControl.add_child(_difficulty_picker)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_difficulty_picker.add_child(vbox)
	var title := Label.new()
	title.text = "Choose Difficulty"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("#00D4FF"))
	vbox.add_child(title)
	var desc := Label.new()
	desc.text = "Easy: drag pills into blanks\nMedium: type in the blanks\nHard: type the full code"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color("#A0B8D0"))
	vbox.add_child(desc)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)
	for diff in [["Easy", "easy", Color("#00FF88"), "20 RAM"], ["Medium", "medium", Color("#FFB800"), "30 RAM"], ["Hard", "hard", Color("#FF3366"), "50 RAM"]]:
		var btn := Button.new()
		btn.text = diff[0] + "\n" + diff[3]
		btn.custom_minimum_size = Vector2(90, 56)
		btn.add_theme_font_size_override("font_size", 12)
		btn.add_theme_color_override("font_color", diff[2])
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color(diff[2].r * 0.15, diff[2].g * 0.15, diff[2].b * 0.15, 0.9)
		bs.border_color = diff[2]
		bs.border_width_left = 1
		bs.border_width_right = 1
		bs.border_width_top = 1
		bs.border_width_bottom = 1
		bs.corner_radius_top_left = 8
		bs.corner_radius_top_right = 8
		bs.corner_radius_bottom_left = 8
		bs.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", bs)
		btn.pressed.connect(_on_difficulty_selected.bind(diff[1]))
		row.add_child(btn)
	var note := Label.new()
	note.text = "▶ Gameplay continues — not paused"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 9)
	note.add_theme_color_override("font_color", Color("#88CCFF", 0.9))
	vbox.add_child(note)
	var close := Button.new()
	close.text = "✕ Close"
	close.custom_minimum_size = Vector2(80, 28)
	close.add_theme_font_size_override("font_size", 11)
	close.add_theme_color_override("font_color", Color("#FF5577"))
	close.pressed.connect(func(): _difficulty_picker.visible = false)
	vbox.add_child(close)

var _shuffled_pools: Dictionary = {}
func _get_active_challenges() -> Array:
	var base = CHALLENGES.get(level_number, [])
	if base.is_empty():
		return base
	if not _shuffled_pools.has(level_number):
		var pool = base.duplicate()
		pool.shuffle()
		_shuffled_pools[level_number] = pool
		if level_number == 1:
			_level1_shuffled = pool
	return _shuffled_pools[level_number]

func _show_challenge() -> void:
	var challenges = _get_active_challenges()
	if _challenge_progress >= challenges.size():
		return
	if challenges.is_empty():
		return
	_challenge_index = _challenge_progress
	var c = challenges[_challenge_index]
	_challenge_title.text = "⌨  " + c.title
	_challenge_desc.text = c.desc
	_challenge_output.text = ""
	_challenge_result.text = ""
	# ── Difficulty-aware display ──
	var is_level1_choice = c.has("choices")
	# Hard = full typing, Medium = blank LineEdits, Easy = draggable pills
	if level_number == 1 and is_level1_choice:
		if _exercise_difficulty == "hard":
			_challenge_is_choice = false
			_challenge_code_edit.visible = true
			_challenge_choice_box.visible = false
			_challenge_code_edit.editable = true
			_challenge_code_edit.text = c.code_template
		else:
			_challenge_is_choice = true
			_challenge_code_edit.visible = false
			_challenge_choice_box.visible = true
			_challenge_selected_choice = ""
			_challenge_blank_btns.clear()
			_challenge_blank_btn = null
			_medium_blank_edits.clear()
			# Clear old code display
			var code_panel = _challenge_choice_box.get_child(0)
			for ch in code_panel.get_children():
				ch.queue_free()
			var code_vbox := VBoxContainer.new()
			code_vbox.add_theme_constant_override("separation", 4)
			code_vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
			code_panel.add_child(code_vbox)
			var lines = c.code_template.split("\n")
			for line in lines:
				if "___" in line:
					var parts = line.split("___")
					var hbox := HBoxContainer.new()
					hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
					hbox.add_theme_constant_override("separation", 0)
					for pi in range(parts.size()):
						if parts[pi] != "":
							var pre := Label.new()
							pre.text = parts[pi]
							pre.add_theme_font_override("font", ThemeDB.fallback_font)
							pre.add_theme_font_size_override("font_size", _fs(0.034, 16.0, 18.0))
							pre.add_theme_color_override("font_color", Color("#FFFFFF"))
							hbox.add_child(pre)
						if pi < parts.size() - 1:
							if _exercise_difficulty == "medium":
								var edit := LineEdit.new()
								edit.custom_minimum_size = Vector2(72, 22)
								edit.placeholder_text = "?"
								edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
								edit.add_theme_font_size_override("font_size", 13)
								var es := StyleBoxFlat.new()
								es.bg_color = Color("#1A2A4A")
								es.border_color = Color("#FFB800")
								es.border_width_left = 1
								es.border_width_right = 1
								es.border_width_top = 1
								es.border_width_bottom = 1
								es.corner_radius_top_left = 4
								es.corner_radius_top_right = 4
								es.corner_radius_bottom_left = 4
								es.corner_radius_bottom_right = 4
								edit.add_theme_stylebox_override("normal", es)
								hbox.add_child(edit)
								_medium_blank_edits.append(edit)
							else: # easy: Button blank + chips
								var blank := Button.new()
								blank.text = "   "
								blank.custom_minimum_size = Vector2(56, 22)
								var blank_style := StyleBoxFlat.new()
								blank_style.bg_color = Color("#1A2A4A")
								blank_style.border_color = Color("#00D4FF")
								blank_style.border_width_left = 1
								blank_style.border_width_right = 1
								blank_style.border_width_top = 1
								blank_style.border_width_bottom = 1
								blank_style.corner_radius_top_left = 4
								blank_style.corner_radius_top_right = 4
								blank_style.corner_radius_bottom_left = 4
								blank_style.corner_radius_bottom_right = 4
								blank.add_theme_stylebox_override("normal", blank_style)
								blank.add_theme_color_override("font_color", Color("#FFFFFF"))
								blank.add_theme_font_size_override("font_size", _fs(0.034, 14.0, 16.0))
								blank.pressed.connect(_on_blank_pressed.bind(blank))
								hbox.add_child(blank)
								_challenge_blank_btns.append(blank)
								if _challenge_blank_btn == null:
									_challenge_blank_btn = blank
					code_vbox.add_child(hbox)
				else:
					var lbl := Label.new()
					lbl.text = line if line != "" else " "
					lbl.add_theme_font_override("font", ThemeDB.fallback_font)
					lbl.add_theme_font_size_override("font_size", _fs(0.034, 16.0, 18.0))
					lbl.add_theme_color_override("font_color", Color("#FFFFFF"))
					lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
					code_vbox.add_child(lbl)
			# Build choice chips only for Easy
			for ch in _challenge_choices_row.get_children():
				ch.queue_free()
			_challenge_choices_row.visible = (_exercise_difficulty == "easy")
			if _exercise_difficulty == "easy":
				for choice in c.choices:
					var chip := Button.new()
					chip.text = choice
					chip.custom_minimum_size = Vector2(70, 32)
					var cs := StyleBoxFlat.new()
					cs.bg_color = Color("#0D1A33")
					cs.border_color = Color("#4A7FA5")
					cs.border_width_left = 1
					cs.border_width_right = 1
					cs.border_width_top = 1
					cs.border_width_bottom = 1
					cs.corner_radius_top_left = 6
					cs.corner_radius_top_right = 6
					cs.corner_radius_bottom_left = 6
					cs.corner_radius_bottom_right = 6
					chip.add_theme_stylebox_override("normal", cs)
					chip.add_theme_color_override("font_color", Color("#A0B8D0"))
					chip.add_theme_font_size_override("font_size", _fs(0.032, 14.0, 16.0))
					chip.pressed.connect(_on_choice_selected.bind(choice, chip))
					chip.button_down.connect(_on_chip_drag_start.bind(choice))
					chip.button_up.connect(_on_chip_drag_end)
					chip.mouse_filter = Control.MOUSE_FILTER_PASS
					_challenge_choices_row.add_child(chip)
	elif is_level1_choice:
		# Other levels — respect difficulty too
		if _exercise_difficulty == "hard":
			_challenge_is_choice = false
			_challenge_code_edit.visible = true
			_challenge_choice_box.visible = false
			_challenge_code_edit.editable = true
			_challenge_code_edit.text = c.code_template
		else:
			_challenge_is_choice = true
			_challenge_code_edit.visible = false
			_challenge_choice_box.visible = true
			_challenge_selected_choice = ""
			_medium_blank_edits.clear()
			var code_panel2 = _challenge_choice_box.get_child(0)
			for ch in code_panel2.get_children():
				ch.queue_free()
			_challenge_blank_btns.clear()
			_challenge_blank_btn = null
			var code_vbox2 := VBoxContainer.new()
			code_vbox2.add_theme_constant_override("separation", 4)
			code_vbox2.alignment = BoxContainer.ALIGNMENT_BEGIN
			code_panel2.add_child(code_vbox2)
			var lines2 = c.code_template.split("\n")
			for line in lines2:
				if "___" in line:
					var parts = line.split("___")
					var hbox := HBoxContainer.new()
					hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
					hbox.add_theme_constant_override("separation", 0)
					for pi in range(parts.size()):
						if parts[pi] != "":
							var pre := Label.new()
							pre.text = parts[pi]
							pre.add_theme_font_override("font", ThemeDB.fallback_font)
							pre.add_theme_font_size_override("font_size", _fs(0.034, 16.0, 18.0))
							pre.add_theme_color_override("font_color", Color("#FFFFFF"))
							hbox.add_child(pre)
						if pi < parts.size() - 1:
							if _exercise_difficulty == "medium":
								var edit := LineEdit.new()
								edit.custom_minimum_size = Vector2(72, 22)
								edit.placeholder_text = "?"
								edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
								edit.add_theme_font_size_override("font_size", 13)
								var es := StyleBoxFlat.new()
								es.bg_color = Color("#1A2A4A")
								es.border_color = Color("#FFB800")
								es.border_width_left = 1
								es.border_width_right = 1
								es.border_width_top = 1
								es.border_width_bottom = 1
								es.corner_radius_top_left = 4
								es.corner_radius_top_right = 4
								es.corner_radius_bottom_left = 4
								es.corner_radius_bottom_right = 4
								edit.add_theme_stylebox_override("normal", es)
								hbox.add_child(edit)
								_medium_blank_edits.append(edit)
							else:
								var blank := Button.new()
								blank.text = "   "
								blank.custom_minimum_size = Vector2(56, 22)
								var blank_style := StyleBoxFlat.new()
								blank_style.bg_color = Color("#1A2A4A")
								blank_style.border_color = Color("#00D4FF")
								blank_style.border_width_left = 1
								blank_style.border_width_right = 1
								blank_style.border_width_top = 1
								blank_style.border_width_bottom = 1
								blank_style.corner_radius_top_left = 4
								blank_style.corner_radius_top_right = 4
								blank_style.corner_radius_bottom_left = 4
								blank_style.corner_radius_bottom_right = 4
								blank.add_theme_stylebox_override("normal", blank_style)
								blank.add_theme_color_override("font_color", Color("#FFFFFF"))
								blank.add_theme_font_size_override("font_size", _fs(0.034, 14.0, 16.0))
								blank.pressed.connect(_on_blank_pressed.bind(blank))
								hbox.add_child(blank)
								_challenge_blank_btns.append(blank)
								if _challenge_blank_btn == null:
									_challenge_blank_btn = blank
					code_vbox2.add_child(hbox)
				else:
					var lbl := Label.new()
					lbl.text = line if line != "" else " "
					lbl.add_theme_font_override("font", ThemeDB.fallback_font)
					lbl.add_theme_font_size_override("font_size", _fs(0.034, 16.0, 18.0))
					lbl.add_theme_color_override("font_color", Color("#FFFFFF"))
					lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
					code_vbox2.add_child(lbl)
			for ch in _challenge_choices_row.get_children():
				ch.queue_free()
			_challenge_choices_row.visible = (_exercise_difficulty == "easy")
			if _exercise_difficulty == "easy":
				for choice in c.choices:
					var chip := Button.new()
					chip.text = choice
					chip.custom_minimum_size = Vector2(70, 32)
					var cs := StyleBoxFlat.new()
					cs.bg_color = Color("#0D1A33")
					cs.border_color = Color("#4A7FA5")
					cs.border_width_left = 1
					cs.border_width_right = 1
					cs.border_width_top = 1
					cs.border_width_bottom = 1
					cs.corner_radius_top_left = 6
					cs.corner_radius_top_right = 6
					cs.corner_radius_bottom_left = 6
					cs.corner_radius_bottom_right = 6
					chip.add_theme_stylebox_override("normal", cs)
					chip.add_theme_color_override("font_color", Color("#A0B8D0"))
					chip.add_theme_font_size_override("font_size", _fs(0.032, 14.0, 16.0))
					chip.pressed.connect(_on_choice_selected.bind(choice, chip))
					chip.button_down.connect(_on_chip_drag_start.bind(choice))
					chip.button_up.connect(_on_chip_drag_end)
					chip.mouse_filter = Control.MOUSE_FILTER_PASS
					_challenge_choices_row.add_child(chip)
	else:
		_challenge_is_choice = false
		_challenge_code_edit.visible = true
		_challenge_choice_box.visible = false
		_challenge_code_edit.text = c.code_template
	micro_panel.visible = true
	micro_panel.process_mode = Node.PROCESS_MODE_ALWAYS

func _get_filled_code() -> String:
	var c = _get_active_challenges()[_challenge_index]
	var code = c.code_template
	if level_number == 1 and _exercise_difficulty == "medium" and _medium_blank_edits.size() > 0:
		for e in _medium_blank_edits:
			var v = e.text.strip_edges()
			if v == "":
				v = "___"
			code = code.replace("___", v)
	elif _challenge_blank_btns.size() > 0:
		for b in _challenge_blank_btns:
			var v = b.text.strip_edges() if b.text.strip_edges() != "" else "___"
			if v == "":
				v = "___"
			code = code.replace("___", v)
	elif _challenge_selected_choice != "":
		code = code.replace("___", _challenge_selected_choice)
	return code

func _are_blanks_filled() -> bool:
	if level_number == 1 and _exercise_difficulty == "medium" and _medium_blank_edits.size() > 0:
		for e in _medium_blank_edits:
			if e.text.strip_edges() == "":
				return false
		return true
	if _challenge_blank_btns.size() > 0:
		for b in _challenge_blank_btns:
			if b.text.strip_edges() == "" or b.text == "   ":
				return false
		return true
	return _challenge_selected_choice != ""

func _on_blank_pressed(blank: Button) -> void:
	# Click a filled blank to clear it (tap to remove)
	if blank.text.strip_edges() != "" and blank.text != "   ":
		blank.text = "   "
		var blank_style := StyleBoxFlat.new()
		blank_style.bg_color = Color("#1A2A4A")
		blank_style.border_color = Color("#00D4FF")
		blank_style.border_width_left = 1
		blank_style.border_width_right = 1
		blank_style.border_width_top = 1
		blank_style.border_width_bottom = 1
		blank_style.corner_radius_top_left = 4
		blank_style.corner_radius_top_right = 4
		blank_style.corner_radius_bottom_left = 4
		blank_style.corner_radius_bottom_right = 4
		blank.add_theme_stylebox_override("normal", blank_style)
		_challenge_selected_choice = ""
		return

func _on_chip_drag_start(choice: String) -> void:
	_challenge_dragging_choice = choice
	if is_instance_valid(_challenge_drag_preview):
		_challenge_drag_preview.queue_free()
	_challenge_drag_preview = Label.new()
	_challenge_drag_preview.text = choice
	_challenge_drag_preview.add_theme_font_size_override("font_size", 14)
	_challenge_drag_preview.add_theme_color_override("font_color", Color("#FFFFFF"))
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#00D4FF", 0.9)
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	_challenge_drag_preview.add_theme_stylebox_override("normal", s)
	_challenge_drag_preview.z_index = 100
	_challenge_drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD/HUDControl.add_child(_challenge_drag_preview)

func _on_chip_drag_end() -> void:
	if _challenge_dragging_choice == "":
		return
	var mouse_pos = get_viewport().get_mouse_position()
	# Drop onto any blank under mouse
	var dropped := false
	for b in _challenge_blank_btns:
		if b.get_global_rect().has_point(mouse_pos):
			b.text = _challenge_dragging_choice
			var filled_style := StyleBoxFlat.new()
			filled_style.bg_color = Color("#00D4FF", 0.25)
			filled_style.border_color = Color("#00FF88")
			filled_style.border_width_left = 1
			filled_style.border_width_right = 1
			filled_style.border_width_top = 1
			filled_style.border_width_bottom = 1
			filled_style.corner_radius_top_left = 4
			filled_style.corner_radius_top_right = 4
			filled_style.corner_radius_bottom_left = 4
			filled_style.corner_radius_bottom_right = 4
			b.add_theme_stylebox_override("normal", filled_style)
			dropped = true
			break
	if not dropped:
		# No blank hit — fallback: fill next empty blank (tap behavior)
		_on_choice_selected(_challenge_dragging_choice, null)
	_challenge_dragging_choice = ""
	if is_instance_valid(_challenge_drag_preview):
		_challenge_drag_preview.queue_free()
		_challenge_drag_preview = null

func _on_choice_selected(choice: String, btn: Button) -> void:
	# Fill next empty blank (supports 1 or 2+ blanks)
	var target: Button = null
	for b in _challenge_blank_btns:
		if b.text.strip_edges() == "" or b.text == "   ":
			target = b
			break
	if target == null and is_instance_valid(_challenge_blank_btn):
		target = _challenge_blank_btn
	if target == null:
		return
	target.text = choice
	var filled_style := StyleBoxFlat.new()
	filled_style.bg_color = Color("#00D4FF", 0.25)
	filled_style.border_color = Color("#00FF88")
	filled_style.border_width_left = 1
	filled_style.border_width_right = 1
	filled_style.border_width_top = 1
	filled_style.border_width_bottom = 1
	filled_style.corner_radius_top_left = 4
	filled_style.corner_radius_top_right = 4
	filled_style.corner_radius_bottom_left = 4
	filled_style.corner_radius_bottom_right = 4
	target.add_theme_stylebox_override("normal", filled_style)
	_challenge_selected_choice = choice
	# Highlight selected chip if provided
	if btn != null:
		for c in _challenge_choices_row.get_children():
			if c is Button:
				var sel = (c == btn)
				var cs2 := StyleBoxFlat.new()
				cs2.bg_color = Color("#00D4FF", 0.25) if sel else Color("#0D1A33")
				cs2.border_color = Color("#00D4FF") if sel else Color("#4A7FA5")
				cs2.border_width_left = 1
				cs2.border_width_right = 1
				cs2.border_width_top = 1
				cs2.border_width_bottom = 1
				cs2.corner_radius_top_left = 6
				cs2.corner_radius_top_right = 6
				cs2.corner_radius_bottom_left = 6
				cs2.corner_radius_bottom_right = 6
				c.add_theme_stylebox_override("normal", cs2)
				c.add_theme_color_override("font_color", Color("#FFFFFF") if sel else Color("#A0B8D0"))

func _hide_challenge() -> void:
	micro_panel.visible = false
	# Do not unpause — gameplay was never paused (exercise is non-blocking)

func _on_challenge_run() -> void:
	var code: String
	if _challenge_is_choice:
		if not _are_blanks_filled():
			_challenge_output.text = "Fill all blanks! Tap a pill then tap a blank — or drag it in."
			_challenge_output.add_theme_color_override("font_color", Color("#FFB800"))
			return
		code = _get_filled_code()
	else:
		code = _challenge_code_edit.text
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
	var challenges = _get_active_challenges()
	if not challenges or _challenge_index >= challenges.size():
		return
	var c = challenges[_challenge_index]
	var code: String
	if _challenge_is_choice:
		if not _are_blanks_filled():
			_challenge_output.text = "Fill all blanks first!"
			_challenge_output.add_theme_color_override("font_color", Color("#FFB800"))
			return
		code = _get_filled_code()
	else:
		code = _challenge_code_edit.text
	var result = PythonTranspiler.run_code(code)
	var expected = c.expected_output.strip_edges(false, true)
	var reward = 0
	if result.success and result.output == expected:
		reward = c.bonus_ram
		if _exercise_difficulty == "medium":
			reward = int(reward * 1.5)
		elif _exercise_difficulty == "hard":
			reward = int(reward * 2.5)
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
	var total = _get_active_challenges().size()
	if _challenge_progress >= total:
		_challenge_result.text = "All challenges complete!"
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(micro_panel):
			_hide_challenge()
		return
	await get_tree().create_timer(1.2).timeout
	if not is_instance_valid(micro_panel) or not micro_panel.visible:
		return
	_show_challenge()

# ─── TUTORIAL ──────────────────────────────────────────
const TutorialOverlay = preload("res://scenes/core/TutorialOverlay.gd")

func _maybe_show_tutorial() -> void:
	if ProgressManager.has_seen_tutorial("level"):
		return
	await get_tree().process_frame
	await get_tree().process_frame
	_tutorial_active = true
	var tut = TutorialOverlay.new()
	$HUD.add_child(tut)
	tut.tutorial_finished.connect(func():
		_tutorial_active = false
		ProgressManager.mark_tutorial_seen("level")
		await get_tree().create_timer(0.5).timeout
		_show_challenge()
	)
	tut.start(_get_level_tutorial_steps())

func _get_level_tutorial_steps() -> Array:
	var steps: Array = []
	steps.append({
		"title": "Battle Station",
		"body": "Welcome to the tower defense! Place towers on the grid to intercept enemies moving along the path. Defend your base at all costs.",
		"force_center": true,
	})
	steps.append({
		"title": "Command HUD",
		"body": "Your command center: RAM for tower costs, Wave counter, Base health (❤️), and Score. Each tower costs RAM to deploy.",
		"highlight": $HUD/HUDControl/TopHUD.get_path(),
	})
	steps.append({
		"title": "The Grid",
		"body": "This is your battlefield.\n\n🟢 Tap a green cell to place a tower — position them along the enemy path for maximum coverage.\n\n⬆️ Tap an existing tower to UPGRADE it (costs RAM, increases power).\n\n💰 Tap a tower and hit SELL to reclaim RAM and free up the cell.",
		"force_center": true,
	})
	steps.append({
		"title": "Wave Controls",
		"body": "The wave timeline shows your progress. Use SKIP (20⚡) to start the next wave early, or ▶▶ for 2x speed.",
		"highlight": $HUD/HUDControl/TopHUD/TopLayout/WaveProgressTimeline.get_path(),
	})
	steps.append({
		"title": "Coding Challenges",
		"body": "After this tutorial, a coding challenge will appear. Solve Python problems correctly to earn bonus RAM for more tower deployments!",
		"force_center": true,
	})
	steps.append({
		"title": "Pause & Menu",
		"body": "Tap ⏸ to pause the game. From there you can resume, retry the level, or return to the main menu.",
		"highlight": pause_btn.get_path(),
	})
	steps.append({
		"title": "Good Luck, Operator!",
		"body": "Clear all waves to secure the system. Build smart, spend wisely, and protect your base!",
		"force_center": true,
	})
	return steps
