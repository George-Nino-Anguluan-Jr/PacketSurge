# BackButtonBar.gd
extends HBoxContainer

@export var destination: String = "main_menu"
@export var scene_title: String = "ACADEMY"

@onready var back_btn: Button       = $BackBtn
@onready var scene_title_label: Label = $SceneTitleLabel

func _ready() -> void:
	scene_title_label.text = scene_title
	back_btn.pressed.connect(_on_back_pressed)
	_apply_style()

func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = Color("#00D4FF")
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	back_btn.add_theme_stylebox_override("normal", style)
	back_btn.add_theme_color_override("font_color", Color("#00D4FF"))
	back_btn.add_theme_font_size_override("font_size", 13)
	scene_title_label.add_theme_color_override("font_color", Color("#4A7FA5"))
	scene_title_label.add_theme_font_size_override("font_size", 14)

func _on_back_pressed() -> void:
	GameManager.go_to(destination)
