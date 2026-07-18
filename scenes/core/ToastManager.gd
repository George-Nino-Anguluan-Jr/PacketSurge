# ToastManager.gd
extends CanvasLayer

@onready var toast_panel: PanelContainer = $ToastPanel
@onready var toast_icon: Label           = $ToastPanel/ToastLayout/ToastIcon
@onready var toast_text: Label           = $ToastPanel/ToastLayout/ToastText

var _is_showing: bool = false
var _queue: Array     = []
var _active_tween: Tween = null

const SHOWN_OFFSET: float = 16.0
const PANEL_HEIGHT: float = 60.0
const SIDE_MARGIN: float = 16.0

func _ready() -> void:
	_apply_style()
	SignalBus.hud_message_requested.connect(_on_message_requested)
	toast_panel.visible = false
	toast_panel.modulate.a = 0.0
	_set_offsets(SHOWN_OFFSET)

func _set_offsets(top: float) -> void:
	toast_panel.set_anchor_and_offset(SIDE_LEFT,   0.0, SIDE_MARGIN)
	toast_panel.set_anchor_and_offset(SIDE_RIGHT,  1.0, -SIDE_MARGIN)
	toast_panel.set_anchor_and_offset(SIDE_TOP,    0.0, top)
	toast_panel.set_anchor_and_offset(SIDE_BOTTOM, 0.0, top + PANEL_HEIGHT)

func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color               = Color("#0A1628")
	style.border_color           = Color("#00D4FF")
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
		_interrupt_and_show_toast(message, duration)
		return
	_show_toast(message, duration)

func _show_toast(message: String, duration: float) -> void:
	_is_showing         = true
	toast_text.text     = message
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	_set_offsets(SHOWN_OFFSET)

	if _active_tween:
		_active_tween.kill()

	_active_tween = create_tween()
	_active_tween.set_ease(Tween.EASE_OUT)
	_active_tween.set_trans(Tween.TRANS_CUBIC)
	_active_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.3)
	
	_active_tween.finished.connect(func():
		_start_hide_timer(duration)
	)

func _interrupt_and_show_toast(message: String, duration: float) -> void:
	_queue.clear()
	toast_text.text = message

	if _active_tween:
		_active_tween.kill()

	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	
	# Bump animation: quickly slide up and back down to the SHOWN_OFFSET
	_active_tween.tween_method(_set_offsets, SHOWN_OFFSET - 12.0, SHOWN_OFFSET, 0.25)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK)
	
	# Instantly restore full visibility/opacity
	_active_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.1)

	_active_tween.chain().finished.connect(func():
		_start_hide_timer(duration)
	)

func _start_hide_timer(duration: float) -> void:
	if _active_tween:
		_active_tween.kill()

	_active_tween = create_tween()
	_active_tween.tween_interval(duration)
	_active_tween.finished.connect(_hide_toast)

func _hide_toast() -> void:
	if _active_tween:
		_active_tween.kill()

	_active_tween = create_tween()
	_active_tween.set_ease(Tween.EASE_IN)
	_active_tween.set_trans(Tween.TRANS_CUBIC)
	_active_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.3)
	
	_active_tween.finished.connect(func():
		toast_panel.visible = false
		_is_showing         = false
		
		if _queue.size() > 0:
			var next = _queue.pop_front()
			_show_toast(next["message"], next["duration"])
	)

func show_message(
		message: String,
		duration: float = 3.0,
		icon: String    = "💡",
		color: String   = "#00D4FF") -> void:
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
