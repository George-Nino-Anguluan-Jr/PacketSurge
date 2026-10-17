# TowerData.gd
class_name TowerData
extends Resource

@export var tower_id: String         = ""
@export var tower_name: String       = ""
@export var description: String      = ""
@export var data_structure: String   = ""
@export var ram_cost: int            = 50

# Ordering in the Index / codex (0 = appended after ordered entries)
@export var order: int               = 0

# Stats
@export var damage: float            = 10.0
@export var attack_speed: float      = 1.0
@export var attack_range: float      = 150.0

# ── Combat parameters (data-driven; unique per tower) ──────────────
# Projectile travel speed — matters vs fast enemies (travel time).
@export var projectile_speed: float  = 350.0
# AoE splash radius on impact. 0 = single-target only.
@export var splash_radius: float     = 0.0
# Max enemies a single shot can hit. 1 = single, higher = multi/pierce.
@export var max_targets: int         = 1
# Sell-back fraction of total invested (0.6–0.8 typical).
@export var sell_ratio: float        = 0.7

# ── Signature effects (each tower uses the ones matching its algorithm) ──
# Binary search: sniper round ignores enemy armor (cuts the search space).
@export var armor_pierce: bool       = false
# Linear search / Bubble: on-hit slow.
@export var slow_percent: float      = 0.0
@export var slow_duration: float     = 0.0
# Insertion sort: on-hit burn damage-over-time.
@export var burn_dps: float          = 0.0
@export var burn_duration: float     = 0.0
# Linked list: chain lightning hops.
@export var chain_count: int         = 0
@export var chain_radius: float      = 0.0
# Selection sort: ramping damage per consecutive kill (already in code, now data).
@export var ramp_per_kill: float     = 0.25
@export var ramp_max: int            = 5
# Counting sort: bonus damage per extra enemy in range.
@export var bonus_per_enemy: float   = 0.15

# Complexity info for Index
@export var time_complexity: String  = "O(1)"
@export var space_complexity: String = "O(n)"
@export var strengths: Array[String] = []
@export var weaknesses: Array[String] = []

# Ability
@export var ability_name: String     = ""

# Intro / codex copy (previously hardcoded in TowerIntroData.gd)
@export var tagline: String          = ""
@export_multiline var mechanic: String    = ""
@export_multiline var shooting: String    = ""
@export_multiline var ability_desc: String = ""
@export var strong_against: Array[String] = []
@export var weak_against: Array[String]   = []
@export var targeting: String        = ""

# Visual
@export var color: Color             = Color("#00D4FF")
@export var icon_text: String        = "[ ]"
@export var style: TowerStyle          # Shared visual style resource (optional)
