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
