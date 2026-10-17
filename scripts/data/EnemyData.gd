# EnemyData.gd
class_name EnemyData
extends Resource

@export var enemy_id: String    = ""
@export var title: String       = "Enemy"
@export var tagline: String     = ""
@export var icon: String        = "[ ]"
@export var threat: String      = "Medium"
@export_multiline var special: String = ""
@export_multiline var lesson: String  = ""

# Combat stats (effective base values, before level difficulty/wave scaling)
@export var max_health: float   = 100.0
@export var speed: float        = 80.0
@export var ram_reward: int     = 10
@export var is_boss: bool       = false

# ── Defense (data-driven; unique per enemy) ─────────────────────
# Flat damage reduced from every hit (after tower-type multiplier).
@export var armor_flat: float       = 0.0
# Fraction of damage reduced (0.3 = take 70%). Applied after armor_flat.
@export var armor_percent: float    = 0.0
# Cannot be slowed by any tower effect.
@export var slow_immune: bool       = false
# HP recovered per second while alive.
@export var regen_per_sec: float    = 0.0
# Shield that absorbs the first N hits (0 = no shield).
@export var shield_max_hits: int    = 0
# Shield hits regenerated per second once broken.
@export var shield_regen_per_sec: float = 0.0

# ── Wave scaling (per-enemy multipliers on the base growth curve) ──
# HP growth per wave: final = max_health * wave_hp_mult * (1 + wave * 0.3).
@export var wave_hp_mult: float     = 1.0
# Speed growth per wave: final = speed * wave_speed_mult (1.0 = no growth).
@export var wave_speed_mult: float  = 1.0

# Visual identity
@export var color: Color        = Color("#FF3366")
@export var style: EnemyStyle   # Shared visual style resource (optional)
