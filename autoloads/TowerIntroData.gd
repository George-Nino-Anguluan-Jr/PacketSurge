extends Node

var tower_intros: Dictionary = {
	"tower_array": {
		"title": "Array Tower",
		"tagline": "Rapid-fire index-based targeting",
		"color": Color("#00D4FF"),
		"icon": "[ ]",
		"mechanic": "Fires up to 5 bolts simultaneously at the nearest enemies — one per target. Each bolt hits for moderate damage. Think of it like accessing every element in an array at once.",
		"shooting": "Multiple arcing index-bolts fly toward targets in quick succession. Each bolt is labeled with its target index.",
		"ability": "O(1) Burst — Fires a double-damage blast at the closest enemy, bypassing all targeting logic.",
		"strong": ["basic_packet", "queue_jumper"],
		"weak": ["overflow_packet", "indexed_packet"],
		"targeting": "Targets the 5 closest enemies simultaneously."
	},
	"tower_stack": {
		"title": "Stack Tower",
		"tagline": "LIFO — last in, first out",
		"color": Color("#FF6B35"),
		"icon": "↑↓",
		"mechanic": "Always attacks the most recent enemy that entered its range (Last-In-First-Out). Launches a heavy mortar shell dealing high single-target damage.",
		"shooting": "A lobbed mortar shell arcs upward then crashes down on the target with a satisfying POP explosion.",
		"ability": "Stack Pop — Deals damage to the most recently entered enemy with bonus punch-through.",
		"strong": ["basic_packet", "bubble_shield"],
		"weak": ["queue_jumper", "overflow_packet"],
		"targeting": "LIFO — always hits the newest (last-entered) enemy in range."
	},
	"tower_queue": {
		"title": "Queue Tower",
		"tagline": "FIFO — first in, first out railgun",
		"color": Color("#9B59B6"),
		"icon": "→",
		"mechanic": "Targets the enemy that entered its range first (First-In-First-Out). Shots pierce through to hit a second enemy behind the first.",
		"shooting": "A piercing rail shot that cuts through the first target and continues to the next enemy in line.",
		"ability": "FIFO Pierce — Fires a wide blast that hits ALL enemies in range with reduced damage.",
		"strong": ["overflow_packet", "basic_packet"],
		"weak": ["selection_mark", "merge_twin"],
		"targeting": "FIFO — always hits the oldest (first-entered) enemy, then pierces to a second."
	},
	"tower_linked_list": {
		"title": "Linked Tower",
		"tagline": "Chain lightning — jumps between enemies",
		"color": Color("#00FF88"),
		"icon": "→→",
		"mechanic": "Fires chain lightning that hits a primary target then bounces to up to 2 more nearby enemies. Each chain jump deals reduced damage — like traversing nodes in a linked list.",
		"shooting": "A crackling lightning bolt arcs from the tower to the first target, then chains to adjacent enemies.",
		"ability": "Chain Link — Unleashes a triple-chain burst hitting 3 enemies with full damage.",
		"strong": ["merge_twin", "linked_drain"],
		"weak": ["overflow_packet", "radix_digit"],
		"targeting": "Closest enemy first, then chain to nearby enemies (up to 3 total)."
	},
	"tower_bubble": {
		"title": "Bubble Tower",
		"tagline": "AoE — compares and clears all in range",
		"color": Color("#FFB800"),
		"icon": "↑↑",
		"mechanic": "Swaps projectiles between the two nearest enemies, dealing damage to both. If fewer than 2 enemies are in range, hits all with reduced damage. Emulates the pairwise comparison of Bubble Sort.",
		"shooting": "A glowing orb zips between the two nearest enemies, pulsing with each swap.",
		"ability": "AoE Pulse — Deals damage to every enemy in range simultaneously.",
		"strong": ["overflow_packet", "scan_wave"],
		"weak": ["selection_mark", "insertion_stack"],
		"targeting": "Swaps between the 2 closest enemies. Only 1 enemy? Hits all in range with reduced damage."
	},
	"tower_selection": {
		"title": "Selection Tower",
		"tagline": "Picks off the weakest target",
		"color": Color("#E74C3C"),
		"icon": "→↓",
		"mechanic": "Always targets the enemy with the lowest remaining health in range. Fires a homing seeker projectile that deals very high single-target damage — like selection sort finding the minimum element.",
		"shooting": "A homing seeker with orbiting markers tracks and strikes the lowest-HP enemy with precision.",
		"ability": "Find Weakest — Instantly deals massive damage to the lowest-HP enemy across the entire map.",
		"strong": ["selection_mark", "insertion_stack"],
		"weak": ["basic_packet", "count_meter"],
		"targeting": "Always aims at the enemy with the lowest current HP in range."
	},
	"tower_insertion": {
		"title": "Insertion Tower",
		"tagline": "Stacks damage over time",
		"color": Color("#1ABC9C"),
		"icon": "←↑",
		"mechanic": "Shoots a stake that deals initial damage plus a stacking damage-over-time (DoT) effect. Each new application increases the DoT — like inserting elements one by one into a sorted position.",
		"shooting": "A glowing stake embeds into the target, leaving a venomous DoT trail.",
		"ability": "Insert DOT — Applies a massive instant DoT stack to the target enemy.",
		"strong": ["insertion_stack", "overflow_packet"],
		"weak": ["radix_digit", "scan_wave"],
		"targeting": "Targets the closest enemy and applies stacking DoT."
	},
	"tower_quick": {
		"title": "Quick Tower",
		"tagline": "Splits — hits 2 enemies at once",
		"color": Color("#E91E63"),
		"icon": "⚡",
		"mechanic": "Fires a shot that splits into two projectiles, hitting the two nearest enemies simultaneously. Like Quick Sort's partition — splitting the problem in half.",
		"shooting": "A split projectile divides mid-flight into two homing shots that track separate targets.",
		"ability": "Quick Split — Fires 4 simultaneous split shots that cover the entire range.",
		"strong": ["merge_twin", "overflow_packet"],
		"weak": ["linked_drain", "binary_mask"],
		"targeting": "Targets the 2 closest enemies with split projectiles."
	},
	"tower_merge": {
		"title": "Merge Tower",
		"tagline": "Twin beams that merge on target",
		"color": Color("#3F51B5"),
		"icon": "⊕",
		"mechanic": "Fires two beams that converge on the target, combining their damage for a powerful blast. Like Merge Sort combining two sorted halves into one.",
		"shooting": "Two parallel beams spiral toward the target and merge into a single devastating blast on impact.",
		"ability": "Merge Blast — Fires a massive combined beam that hits all enemies in a line.",
		"strong": ["overflow_packet", "linked_drain"],
		"weak": ["selection_mark", "count_meter"],
		"targeting": "Fires two merging beams at the closest enemy."
	},
	"tower_counting": {
		"title": "Count Tower",
		"tagline": "More enemies = more damage",
		"color": Color("#009688"),
		"icon": "#",
		"mechanic": "Fires a barrage of 5 counting pellets at the nearest target. Damage scales with the number of enemies in range — each enemy counted adds power. Like counting sort tallying occurrences.",
		"shooting": "A stream of numbered pellets (1 through 5) fly at the target in rapid succession, leaving counting trails.",
		"ability": "Count Barrage — Unleashes 10 pellets at once, each hitting for full damage.",
		"strong": ["count_meter", "basic_packet"],
		"weak": ["selection_mark", "binary_mask"],
		"targeting": "Fires 5 rapid pellets at the closest enemy."
	},
	"tower_radix": {
		"title": "Radix Tower",
		"tagline": "Multi-pass digit-based volley",
		"color": Color("#FF5722"),
		"icon": "0→9",
		"mechanic": "Fires 3 passes of digit-orbiting projectiles (ones, tens, hundreds place). Each pass deals damage — like Radix Sort processing each digit position separately.",
		"shooting": "Three glowing digit orbs spiral outward in sequence, each labeled with its place value (1s, 10s, 100s).",
		"ability": "Radix Volley — Fires 9 orbs covering all digits at once for massive burst damage.",
		"strong": ["radix_digit", "scan_wave"],
		"weak": ["basic_packet", "queue_jumper"],
		"targeting": "Fires 3 digit orbs (1, 10, 100) at the closest enemy."
	},
	"tower_linear": {
		"title": "Linear Tower",
		"tagline": "Wide scan — never misses",
		"color": Color("#607D8B"),
		"icon": "→?",
		"mechanic": "Scans a wide straight line and hits every enemy along that line. Has much longer effective range than other towers but in a narrow cone. Never misses a target in its scan path — like linear search checking every element.",
		"shooting": "A horizontal scan line sweeps across the range, hitting all enemies it passes through.",
		"ability": "Linear Sweep — Rotates the scan line 360°, hitting every enemy in the full radius.",
		"strong": ["queue_jumper", "scan_wave"],
		"weak": ["overflow_packet", "selection_mark"],
		"targeting": "Hits all enemies along a wide horizontal scan line within range."
	},
	"tower_binary": {
		"title": "Binary Tower",
		"tagline": "Precision sniper — divide and conquer",
		"color": Color("#8BC34A"),
		"icon": "½",
		"mechanic": "Deals massive single-target damage with every shot but fires very slowly. Perfect for taking down high-HP priority targets. Like binary search splitting the search space and zeroing in on the target.",
		"shooting": "A high-velocity binary sniper round with a crosshair reticle, dealing enormous impact damage.",
		"ability": "Binary Snipe — Fires an ultra-powerful shot dealing 5x normal damage to a single target.",
		"strong": ["binary_mask", "radix_digit", "any high-HP enemy"],
		"weak": ["queue_jumper", "overflow_packet"],
		"targeting": "Targets the closest enemy with devastating single-shot damage."
	},
}

func get_intro(tower_id: String) -> Dictionary:
	return tower_intros.get(tower_id, {})

func get_tower_name(tower_id: String) -> String:
	var d = tower_intros.get(tower_id, {})
	return d.get("title", tower_id)

func get_color(tower_id: String) -> Color:
	var d = tower_intros.get(tower_id, {})
	return d.get("color", Color.WHITE)

func get_icon(tower_id: String) -> String:
	var d = tower_intros.get(tower_id, {})
	return d.get("icon", "")
