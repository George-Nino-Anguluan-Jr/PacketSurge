# GameManager.gd
extends Node

const SCENES = {
	"login":     "res://scenes/login/Login.tscn",
	"main_menu": "res://scenes/main_menu/MainMenu.tscn",
	"academy":   "res://scenes/academy/Academy.tscn",
	"campaign":  "res://scenes/campaign/level_select/LevelSelect.tscn",
	"level":     "res://scenes/campaign/level/Level.tscn",
	"sandbox":   "res://scenes/sandbox/Sandbox.tscn",
	"index":     "res://scenes/index/Index.tscn",
	"analytics": "res://scenes/analytics/Analytics.tscn",
}

# Currently selected level
var current_level: int = 1
var current_scene_key: String = ""
var current_sandbox_structure: String = ""

func _ready() -> void:
	SignalBus.scene_change_requested.connect(_on_scene_change_requested)

func go_to(scene_key: String) -> void:
	if not SCENES.has(scene_key):
		push_error("[GameManager] Unknown scene key: " + scene_key)
		return
	current_scene_key = scene_key
	get_tree().change_scene_to_file(SCENES[scene_key])
	print("[GameManager] Navigating to: ", scene_key)

func _on_scene_change_requested(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

func quit_game() -> void:
	get_tree().quit()
