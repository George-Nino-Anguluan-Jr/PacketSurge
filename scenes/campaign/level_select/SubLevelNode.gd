# SubLevelNode.gd
# Visual node for a sub-level (1A, 1B, 1C, etc.) on the level select map
extends Control

class_name SubLevelNode

signal sub_level_selected(sub_level_id: int)

@onready var background: Panel = %Background
@onready var type_icon: Label = %TypeIcon
@onready var title: Label = %Title
@onready var description: Label = %Description
@onready var star1: Label = %Star1
@onready var star2: Label = %Star2
@onready var star3: Label = %Star3
@onready var lock_overlay: Panel = %LockOverlay
@onready var lock_label: Label = %LockLabel
@onready var play_button: Button = %PlayButton
@onready var best_score_label: Label = %BestScore
@onready var tooltip: PanelContainer = %Tooltip
@onready var visual_container: Control = %VisualContainer
@onready var short_name_label: Label = %ShortNameLabel

var sub_level_id: int = 0
var sub_level_data: Dictionary = {}
var is_unlocked: bool = false
var is_completed: bool = false
var stars_earned: int = 0
var best_score: int = 0

func _ready() -> void:
    play_button.pressed.connect(_on_play_pressed)
    play_button.mouse_entered.connect(_on_mouse_entered)
    play_button.mouse_exited.connect(_on_mouse_exited)
    gui_input.connect(_on_gui_input)
    
    # Hide tooltip by default
    tooltip.modulate.a = 0.0
    tooltip.visible = false
    tooltip.scale = Vector2(0.8, 0.8)

func _on_mouse_entered() -> void:
    SoundManager.play_hover()
    tooltip.visible = true
    
    var tween = create_tween().set_parallel(true)
    tween.tween_property(tooltip, "modulate:a", 1.0, 0.15)
    tween.tween_property(tooltip, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK)
    tween.tween_property(visual_container, "scale", Vector2(1.15, 1.15), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_mouse_exited() -> void:
    var tween = create_tween().set_parallel(true)
    tween.tween_property(tooltip, "modulate:a", 0.0, 0.1)
    tween.tween_property(tooltip, "scale", Vector2(0.8, 0.8), 0.1)
    tween.tween_property(visual_container, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    await tween.finished
    if tooltip.modulate.a == 0.0:
        tooltip.visible = false

func setup(sub_level_id: int, data: Dictionary) -> void:
    self.sub_level_id = sub_level_id
    self.sub_level_data = data
    
    # Get progress from ProgressManager
    var progress = ProgressManager.get_sub_level_progress(sub_level_id)
    is_unlocked = progress.get("unlocked", sub_level_id == 0)
    is_completed = progress.get("completed", false)
    stars_earned = progress.get("stars", 0)
    best_score = progress.get("best_score", 0)
    
    # Prevents Nil crash if setup() is called immediately after .instantiate()
    if not is_inside_tree():
        await ready
        
    _update_ui()

func _update_ui() -> void:
    var sub_type = sub_level_data.get("type", "lesson")
    var main_level = sub_level_data.get("main_level", 1)
    var sub_index = sub_level_data.get("sub_index", 0)
    
    # Set type icon and color
    match sub_type:
        "lesson":
            type_icon.text = "📚"
            background.add_theme_color_override("border_color", Color("#00D4FF"))
        "practice":
            type_icon.text = "🎯"
            background.add_theme_color_override("border_color", Color("#00FF88"))
        "challenge":
            type_icon.text = "⚔️"
            background.add_theme_color_override("border_color", Color("#FFB800"))
    
    # Set title
    var type_names = {"lesson": "Lesson", "practice": "Practice", "challenge": "Challenge"}
    var sub_letter = _get_sub_letter(sub_index)
    title.text = "%d%s: %s" % [main_level, sub_letter, type_names.get(sub_type, sub_type.capitalize())]
    
    # Update short name label on the circle
    short_name_label.text = "%d%s" % [main_level, sub_letter]
    
    # Set description
    description.text = sub_level_data.get("description", "")
    
    # Update stars
    var stars = [star1, star2, star3]
    for i in range(3):
        if i < stars_earned:
            stars[i].text = "★"
            stars[i].add_theme_color_override("font_color", Color("#FFD700"))
        else:
            stars[i].text = "☆"
            stars[i].add_theme_color_override("font_color", Color("#666666"))
    
    # Update lock state
    lock_overlay.visible = not is_unlocked
    play_button.disabled = not is_unlocked
    
    if is_unlocked:
        background.add_theme_color_override("border_color", background.get_theme_color("border_color"))
    else:
        background.add_theme_color_override("border_color", Color("#444444"))
    
    # Update best score
    best_score_label.text = "Best: %d%%" % best_score
    
    # Visual feedback for completed
    if is_completed:
        background.add_theme_color_override("bg_color", Color("#0A1A0A"))
        play_button.text = "Replay"
    else:
        background.add_theme_color_override("bg_color", Color("#050510"))
        play_button.text = "Play"

func _get_sub_letter(index: int) -> String:
    return String.chr(65 + index)  # A, B, C

func _on_play_pressed() -> void:
    if not is_unlocked:
        return
    
    # Set the current sub-level in GameManager
    GameManager.set_current_sub_level_id(sub_level_id)
    GameManager.current_level = sub_level_data.get("main_level", 1)
    
    # Navigate to tower select or level
    GameManager.go_to("tower_select")
    
    sub_level_selected.emit(sub_level_id)

func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        if is_unlocked:
            _on_play_pressed()

func set_unlocked(unlocked: bool) -> void:
    is_unlocked = unlocked
    _update_ui()

func set_completed(completed: bool, stars: int = 0, score: int = 0) -> void:
    is_completed = completed
    stars_earned = stars
    best_score = score
    _update_ui()