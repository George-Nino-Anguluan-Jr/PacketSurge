# Splash.gd
extends Control

@onready var background: ColorRect    = $Background
@onready var title_label: Label       = $CenterContainer/VBox/TitleLabel
@onready var tagline_label: Label     = $CenterContainer/VBox/TaglineLabel
@onready var status_label: Label      = $StatusLabel

const FADE_IN_DURATION: float  = 0.9
const HOLD_DURATION: float     = 1.6
const FADE_OUT_DURATION: float = 0.6

func _ready() -> void:
	# Lightweight sonar ping background (no grid, matches the Surge theme)
	var bg_material := ShaderMaterial.new()
	bg_material.shader = load("res://assets/themes/splash_ping.gdshader")
	background.material = bg_material

	# Sci-fi title outline/shadow styling (matches main_menu / login)
	title_label.add_theme_color_override("font_outline_color", Color("#004C66"))
	title_label.add_theme_constant_override("outline_size", 10)
	title_label.add_theme_color_override("font_shadow_color", Color("#000D1A", 0.8))
	title_label.add_theme_constant_override("shadow_offset_x", 5)
	title_label.add_theme_constant_override("shadow_offset_y", 5)

	# Keep the navy background fully visible from frame one (same color as the
	# engine boot splash) so there's no visible "second splash" gap.
	# Only the text content fades in.
	for node in [title_label, tagline_label, status_label]:
		node.modulate.a = 0.0
	_run_splash_sequence()

func _run_splash_sequence() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	# 1. Fade the title + tagline in
	tween.tween_property(title_label, "modulate:a", 1.0, FADE_IN_DURATION)
	tween.parallel().tween_property(tagline_label, "modulate:a", 1.0, FADE_IN_DURATION)

	# 2. Hold on the title (with a subtle status ticker)
	var status_dots: Array[String] = [".", "..", "..."]
	var dot_index: int = 0
	for i in range(int(HOLD_DURATION / 0.4)):
		tween.tween_callback(func():
			status_label.text = "INITIALIZING NETWORK" + status_dots[dot_index % 3]
			dot_index += 1
		)
		tween.tween_interval(0.4)

	# 3. Fade everything out and go to login
	tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION)
	tween.tween_callback(_go_to_login)

func _go_to_login() -> void:
	GameManager.go_to("login")
