# GameManager.gd
extends Node

# Add these variables to GameManager.gd:
var selected_towers: Array = []

# ─── GAME DATA (single source: resources/*.tres) ────────
# Populated in _ready() from DataRegistry. Access stays identical to the
# old hardcoded consts: GameManager.TOWER_DEFINITIONS, .LEVEL_CONFIGS,
# .ENEMY_DEFINITIONS, .LESSON_NAMES.
static var TOWER_DEFINITIONS: Dictionary = {}
static var LEVEL_CONFIGS: Dictionary = {}
static var ENEMY_DEFINITIONS: Dictionary = {}
static var LESSON_NAMES: Dictionary = {}

# Add tower_select to your scene map:
const SCENES = {
	"login":        "res://scenes/login/Login.tscn",
	"main_menu":    "res://scenes/main_menu/MainMenu.tscn",
	"academy":      "res://scenes/academy/Academy.tscn",
	"campaign":     "res://scenes/campaign/level_select/LevelSelect.tscn",
	"placement_quiz": "res://scenes/placement_quiz/PlacementQuiz.tscn",
	"tower_select": "res://scenes/campaign/tower_select/TowerSelect.tscn",
	"level":        "res://scenes/campaign/level/Level.tscn",
	"index":        "res://scenes/index/Index.tscn",
	"sandbox":      "res://scenes/sandbox/Sandbox.tscn",
	"leaderboard":  "res://scenes/leaderboard/Leaderboard.tscn",
	"analytics":    "res://scenes/analytics/Analytics.tscn",
	"settings":     "res://scenes/settings/Settings.tscn",
	"profile":      "res://scenes/profile/Profile.tscn",

}

# Currently selected level
var current_level: int = 1
var current_scene_key: String = ""
var current_sandbox_structure: String = ""

func _ready() -> void:
	TOWER_DEFINITIONS = DataRegistry.build_tower_definitions()
	LEVEL_CONFIGS     = DataRegistry.build_level_configs()
	ENEMY_DEFINITIONS = DataRegistry.build_enemy_definitions()
	LESSON_NAMES      = DataRegistry.build_lesson_names()
	SignalBus.scene_change_requested.connect(_on_scene_change_requested)

func go_to(scene_key: String) -> void:
	if not SCENES.has(scene_key):
		push_error("[GameManager] Unknown scene key: " + scene_key)
		return
	current_scene_key = scene_key
	get_tree().change_scene_to_file(SCENES[scene_key])

func _on_scene_change_requested(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

func quit_game() -> void:
	get_tree().quit()
