extends Node

var enemy_intros: Dictionary = {
	"basic_packet": {
		"title":    "Basic Packet",
		"tagline":  "The standard network packet — no special abilities.",
		"color":    Color("#FF3366"),
		"icon":     "[ ]",
		"threat":   "Low",
		"special":  "No special ability — pure data, the most common enemy in early waves.",
		"lesson":   "Foundational — every campaign starts with these.",
	},
	"indexed_packet": {
		"title":    "Indexed Packet",
		"tagline":  "Resistant to single hits. Array Tower's fast attack excels here.",
		"color":    Color("#00D4FF"),
		"icon":     "[0]",
		"threat":   "Low",
		"special":  "50% damage resistance. Quick, repeated hits (Array Tower) bypass it.",
		"lesson":   "Arrays use index-based access — multiple bolts at different indices.",
	},
	"overflow_packet": {
		"title":    "Overflow Packet",
		"tagline":  "Grows stronger as enemies behind it die. Kill front-to-back.",
		"color":    Color("#8E44AD"),
		"icon":     "↑↓",
		"threat":   "High",
		"special":  "Gains HP when enemies behind it die. Must be killed LIFO.",
		"lesson":   "Stack LIFO — last in, first out targeting.",
	},
	"queue_jumper": {
		"title":    "Queue Jumper",
		"tagline":  "Speeds up as enemies ahead of it die.",
		"color":    Color("#FF6B35"),
		"icon":     "▶▶",
		"threat":   "Medium",
		"special":  "Speed scales with the number of enemies ahead — near the front = fast.",
		"lesson":   "Queue FIFO — handle the oldest arrival first.",
	},
	"linked_drain": {
		"title":    "Linked Drain",
		"tagline":  "Linked pair — damage is split between partners.",
		"color":    Color("#2ECC71"),
		"icon":     "→→",
		"threat":   "Medium",
		"special":  "Spawns as a linked pair connected by a line. 50/50 damage split with partner.",
		"lesson":   "Linked Lists connect nodes — follow the pointers to damage both at once.",
	},
	"bubble_shield": {
		"title":    "Bubble Shield",
		"tagline":  "Shield absorbs the first 3 hits. Pop it first.",
		"color":    Color("#95A5A6"),
		"icon":     "⭕",
		"threat":   "Medium",
		"special":  "Shield blocks 3 hits before HP is exposed. Shield slowly regenerates.",
		"lesson":   "Bubble Sort compares adjacent pairs — pop two at once with AoE.",
	},
	"pivot_splitter": {
		"title":    "Pivot Splitter",
		"tagline":  "Boss — splits into 2 smaller enemies on death.",
		"color":    Color("#E74C3C"),
		"icon":     "⚡",
		"threat":   "Extreme",
		"special":  "Massive HP boss. On death, splits into 2 weaker basic packets.",
		"lesson":   "Quick Sort pivot partitioning — handle the split halves.",
	},
	"selection_mark": {
		"title":    "Selection Mark",
		"tagline":  "Nearly invulnerable unless it's the lowest-HP enemy on screen.",
		"color":    Color("#E74C3C"),
		"icon":     "◎",
		"threat":   "High",
		"special":  "75% damage resistance unless it has the lowest HP in range.",
		"lesson":   "Selection Sort finds the minimum — Selection Tower auto-targets the weakest.",
	},
	"insertion_stack": {
		"title":    "Insertion Stack",
		"tagline":  "Takes 50% extra damage from damage-over-time effects.",
		"color":    Color("#1ABC9C"),
		"icon":     "◀|",
		"threat":   "Medium",
		"special":  "1.5x damage from any DoT source. Direct hits are normal.",
		"lesson":   "Insertion Sort inserts one at a time — Insertion Tower's DoT stacks.",
	},
	"merge_twin": {
		"title":    "Merge Twin",
		"tagline":  "Pair that absorbs its partner's HP on death.",
		"color":    Color("#3F51B5"),
		"icon":     "⊕",
		"threat":   "High",
		"special":  "Spawns as a pair. If one dies, the other gains bonus HP & speed.",
		"lesson":   "Merge Sort splits then merges — Merge Tower's AoE kills both evenly.",
	},
	"count_meter": {
		"title":    "Count Meter",
		"tagline":  "Resists damage until a counter fills.",
		"color":    Color("#009688"),
		"icon":     "###",
		"threat":   "Medium",
		"special":  "80% damage resistance until 5 hits land — then the counter resets.",
		"lesson":   "Counting Sort tallies occurrences — Count Tower's rapid hits fill it fast.",
	},
	"radix_digit": {
		"title":    "Radix Digit",
		"tagline":  "Three segmented HP bars — must be depleted in order.",
		"color":    Color("#FF5722"),
		"icon":     "1→9",
		"threat":   "High",
		"special":  "HP split across 3 segments (1s, 10s, 100s) — must deplete units first.",
		"lesson":   "Radix Sort processes digit by digit — Radix Tower's multi-pass strips them.",
	},
	"scan_wave": {
		"title":    "Scan Wave",
		"tagline":  "Only vulnerable at the extreme ends of its oscillation.",
		"color":    Color("#607D8B"),
		"icon":     "→?",
		"threat":   "Medium",
		"special":  "Oscillates while moving. 90% damage resistance between scan extremes.",
		"lesson":   "Linear Search scans every element — Linear Tower's wide sweep catches it.",
	},
	"binary_mask": {
		"title":    "Binary Mask",
		"tagline":  "Alternates vulnerable half every few seconds.",
		"color":    Color("#8BC34A"),
		"icon":     "½",
		"threat":   "Extreme",
		"special":  "Only the highlighted half takes full damage. Switches every 2-3 seconds.",
		"lesson":   "Binary Search halves the search space — Binary Tower's precision hits the right side.",
	},
}

func get_intro(enemy_id: String) -> Dictionary:
	return enemy_intros.get(enemy_id, {})

func get_enemy_name(enemy_id: String) -> String:
	var d = enemy_intros.get(enemy_id, {})
	return d.get("title", enemy_id)

func get_color(enemy_id: String) -> Color:
	var d = enemy_intros.get(enemy_id, {})
	return d.get("color", Color.WHITE)

func get_threat(enemy_id: String) -> String:
	var d = enemy_intros.get(enemy_id, {})
	return d.get("threat", "Medium")

func get_icon(enemy_id: String) -> String:
	var d = enemy_intros.get(enemy_id, {})
	return d.get("icon", "")

func all_ids() -> Array:
	return enemy_intros.keys()
