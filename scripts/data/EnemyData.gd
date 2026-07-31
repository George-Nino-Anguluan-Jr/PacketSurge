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

# Visual identity
@export var color: Color        = Color("#FF3366")
