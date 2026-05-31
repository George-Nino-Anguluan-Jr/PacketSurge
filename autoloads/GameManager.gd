# GameManager.gd
# Controls scene transitions and top-level game state
extends Node

# ─── SCENE PATHS ───────────────────────────────────────
# We'll fill these in as we build each scene
const SCENES = {
	"main_menu": "res://scenes/main_menu/MainMenu.tscn",
	"academy":   "res://scenes/academy/Academy.tscn",
	"campaign":  "res://scenes/campaign/Campaign.tscn",
	"sandbox":   "res://scenes/sandbox/Sandbox.tscn",
	"index":     "res://scenes/index/Index.tscn",
	"analytics": "res://scenes/analytics/Analytics.tscn",
}

var current_scene_key: String = ""

func _ready() -> void:
	SignalBus.scene_change_requested.connect(_on_scene_change_requested)

# ─── SCENE TRANSITION ──────────────────────────────────
func go_to(scene_key: String) -> void:
	if not SCENES.has(scene_key):
		push_error("[GameManager] Unknown scene key: " + scene_key)
		return
	current_scene_key = scene_key
	# Simple immediate transition for now
	# Later we'll add a fade animation
	get_tree().change_scene_to_file(SCENES[scene_key])
	print("[GameManager] Navigating to: ", scene_key)

func _on_scene_change_requested(scene_path: String) -> void:
	# Called via SignalBus from anywhere
	get_tree().change_scene_to_file(scene_path)

# ─── UTILITY ───────────────────────────────────────────
func quit_game() -> void:
	get_tree().quit()
