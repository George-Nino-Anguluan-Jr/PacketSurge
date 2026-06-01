# TowerData.gd
class_name TowerData
extends Resource

@export var tower_id: String         = ""
@export var tower_name: String       = ""
@export var description: String      = ""
@export var data_structure: String   = ""
@export var ram_cost: int            = 50

# Stats
@export var damage: float            = 10.0
@export var attack_speed: float      = 1.0
@export var attack_range: float      = 150.0

# Complexity info for Index
@export var time_complexity: String  = "O(1)"
@export var space_complexity: String = "O(n)"
@export var strengths: Array[String] = []
@export var weaknesses: Array[String] = []

# Visual
@export var color: Color             = Color("#00D4FF")
@export var icon_text: String        = "[ ]"
