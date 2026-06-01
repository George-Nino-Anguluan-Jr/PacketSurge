# ToastManager.gd
extends CanvasLayer

@onready var toast_panel: PanelContainer = $ToastPanel
@onready var toast_icon: Label           = $ToastPanel/ToastLayout/ToastIcon
@onready var toast_text: Label           = $ToastPanel/ToastLayout/ToastText

var _is_showing: bool = false
var _queue: Array     = []

const SHOWN_OFFSET: float = 8.0
const HIDDEN_OFFSET: float = -100.0
const PANEL_HEIGHT: float = 60.0
const SIDE_MARGIN: float = 16.0

func _ready() -> void:
	_apply_style()
	SignalBus.hud_message_requested.connect(_on_message_requested)
	toast_panel.visible = false
	_set_offsets(HIDDEN_OFFSET)

func _set_offsets(top: float) -> void:
	toast_panel.set_anchor_and_offset(SIDE_LEFT,   0.0, SIDE_MARGIN)
	toast_panel.set_anchor_and_offset(SIDE_RIGHT,  1.0, -SIDE_MARGIN)
	toast_panel.set_anchor_and_offset(SIDE_TOP,    0.0, top)
	toast_panel.set_anchor_and_offset(SIDE_BOTTOM, 0.0, top + PANEL_HEIGHT)

func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = Color("#FFB800")
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left    = 16
	style.content_margin_right   = 16
	style.content_margin_top     = 10
	style.content_margin_bottom  = 10
	toast_panel.add_theme_stylebox_override("panel", style)

func _on_message_requested(message: String, duration: float) -> void:
	if _is_showing:
		_queue.append({"message": message, "duration": duration})
		return
	_show_toast(message, duration)

func _show_toast(message: String, duration: float) -> void:
	_is_showing         = true
	toast_text.text     = message
	toast_panel.visible = true
	_set_offsets(HIDDEN_OFFSET)

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_method(_set_offsets, HIDDEN_OFFSET, SHOWN_OFFSET, 0.4)

	await get_tree().create_timer(duration).timeout
	_hide_toast()

func _hide_toast() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(_set_offsets, SHOWN_OFFSET, HIDDEN_OFFSET, 0.3)
	await tween.finished
	toast_panel.visible = false
	_is_showing         = false

	if _queue.size() > 0:
		var next = _queue.pop_front()
		_show_toast(next["message"], next["duration"])

func show_message(
		message: String,
		duration: float = 3.0,
		icon: String    = "💡",
		color: String   = "#FFB800") -> void:
	toast_icon.text = icon
	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = Color(color)
	style.border_width_left      = 1
	style.border_width_right     = 1
	style.border_width_top       = 1
	style.border_width_bottom    = 1
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left    = 16
	style.content_margin_right   = 16
	style.content_margin_top     = 10
	style.content_margin_bottom  = 10
	toast_panel.add_theme_stylebox_override("panel", style)
	_on_message_requested(message, duration)
