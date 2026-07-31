# LevelData.gd
class_name LevelData
extends Resource

@export var level_number: int        = 1
@export var level_name: String       = "Level 1"
@export var description: String      = ""
@export var data_structure: String   = "Arrays"

# Concept copy shown in UI
@export_multiline var concept_desc: String = ""
@export_multiline var enemy_tip: String    = ""

# RAM settings
@export var starting_ram: int        = 150
@export var ram_per_kill: int        = 10

# Wave settings
@export var wave_count: int          = 3
@export var enemy_speed_modifier: float = 1.0
@export var enemy_health_modifier: float = 1.0

# Build / layout
@export var tower_slots: int         = 2
@export var required_towers: Array[String] = []
@export var enemy_types: Array[String] = []

# Available towers for this level
@export var available_towers: Array[String] = []

# Path waypoints — Vector2 positions on the grid
@export var path_waypoints: Array[Vector2] = []

# Valid tower spots — grid cells
@export var tower_spots: Array[Vector2i] = []

# Unlock requirement
@export var required_lesson: String  = ""
