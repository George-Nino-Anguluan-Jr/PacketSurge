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

# Visual identity
@export var color: Color        = Color("#FF3366")
