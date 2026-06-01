# LevelData.gd
class_name LevelData
extends Resource

@export var level_number: int        = 1
@export var level_name: String       = "Level 1"
@export var description: String      = ""
@export var data_structure: String   = "Arrays"

# RAM settings
@export var starting_ram: int        = 150
@export var ram_per_kill: int        = 10

# Wave settings
@export var wave_count: int          = 3
@export var enemy_speed_modifier: float = 1.0
@export var enemy_health_modifier: float = 1.0

# Available towers for this level
@export var available_towers: Array[String] = []

# Path waypoints — Vector2 positions on the grid
@export var path_waypoints: Array[Vector2] = []

# Unlock requirement
@export var required_lesson: String  = ""
