extends Control

# Base class for all academy lesson visualizations
# Provides: layout regions, button wiring, code label, common drawing helpers

# ── Layout regions (computed by _layout) ──
var _diagram_rect: Rect2 = Rect2()
var _anim_rect: Rect2 = Rect2()
var _code_label_rect: Rect2 = Rect2()
var _controls_rect: Rect2 = Rect2()
var _concept_title_y: float = 0.0
var _anim_title_y: float = 0.0

# ── Buttons ──
var _btn_play: Button
var _btn_step: Button
var _btn_reset: Button

# ── Step state (set by subclass) ──
var current_step: int = 0
var _animating: bool = false
var _anim_progress: float = 0.0
var _anim_speed: float = 0.6
var _playing_all: bool = false

# ── Override in subclass ──
func get_steps() -> Array:
	return []

func get_concept_title() -> String:
	return "Concept"

func get_anim_title() -> String:
	return "Animation"

# ── Override to draw concept diagram into _diagram_rect ──
func _draw_diagram() -> void:
	pass

# ── Override to draw the main animation into _anim_rect ──
func _draw_anim() -> void:
	pass

# ── Lifecycle ──
func _ready() -> void:
	_build_buttons()
	_set_step(0)
	resized.connect(_layout)

func _layout() -> void:
	var pad: float = 8.0
	var w: float = size.x
	var h: float = size.y
	if w <= 0 or h <= 0:
		return
	var concept_title_h: float = 18.0
	var anim_title_h: float = 16.0
	var code_h: float = 22.0
	var ctl_h: float = 36.0
	var gap: float = 5.0
	var avail: float = h - pad * 2 - concept_title_h - anim_title_h - code_h - ctl_h - gap * 4
	var diagram_h: float = clamp(avail * 0.14, 50, 90)
	var anim_h: float = max(120, avail - diagram_h)
	var y: float = pad
	# Concept title at top
	_concept_title_y = y + 13
	y += concept_title_h + gap
	# Diagram area
	_diagram_rect = Rect2(pad, y, w - pad * 2, diagram_h)
	y += diagram_h + gap
	# Animation title
	_anim_title_y = y + 12
	y += anim_title_h
	# Code label
	_code_label_rect = Rect2(pad, y, w - pad * 2, code_h)
	y += code_h + gap
	# Anim area
	_anim_rect = Rect2(pad, y, w - pad * 2, anim_h)
	y += anim_h + gap
	# Controls
	_controls_rect = Rect2(pad, y, w - pad * 2, ctl_h)
	_position_buttons()
	queue_redraw()

func _position_buttons() -> void:
	if _btn_play == null:
		return
	var bw: float = 90.0
	var sep: float = 10.0
	var total: float = bw * 3 + sep * 2
	var start: float = _controls_rect.position.x + (_controls_rect.size.x - total) * 0.5
	var by: float = _controls_rect.position.y
	_btn_play.position = Vector2(start, by)
	_btn_step.position = Vector2(start + bw + sep, by)
	_btn_reset.position = Vector2(start + (bw + sep) * 2, by)

func _build_buttons() -> void:
	_btn_play = VizUtil.make_btn("▶ Play", VizUtil.C_VAL)
	_btn_step = VizUtil.make_btn("⏭ Step", VizUtil.C_HIGHLIGHT)
	_btn_reset = VizUtil.make_btn("↺ Reset", VizUtil.C_WARN)
	add_child(_btn_play)
	add_child(_btn_step)
	add_child(_btn_reset)
	_btn_play.pressed.connect(_on_play)
	_btn_step.pressed.connect(_on_step)
	_btn_reset.pressed.connect(_on_reset)
	_position_buttons()

func _on_play() -> void:
	# If currently playing, treat as Stop
	if _playing_all and _animating:
		_playing_all = false
		_animating = false
		_btn_play.text = "▶ Play"
		return
	if _animating and _anim_progress < 1.0:
		return
	if current_step >= get_steps().size() - 1:
		current_step = 0
	_set_step(current_step)
	_animating = true
	_anim_progress = 0.0
	_playing_all = true
	_btn_play.text = "■ Stop"

func _on_step() -> void:
	if _animating:
		return
	_playing_all = false
	if current_step < get_steps().size() - 1:
		current_step += 1
		_set_step(current_step)

func _on_reset() -> void:
	current_step = 0
	_animating = false
	_anim_progress = 0.0
	_playing_all = false
	_set_step(0)
	if _btn_play:
		_btn_play.text = "▶ Play"

func _set_step(_idx: int) -> void:
	# Override in subclass if you need to update state per step
	queue_redraw()

func _process(delta: float) -> void:
	if _animating:
		_anim_progress += delta * _anim_speed
		if _anim_progress >= 1.0:
			_anim_progress = 1.0
			_animating = false
			# Auto-advance if playing through all steps
			if _playing_all and current_step < get_steps().size() - 1:
				current_step += 1
				_set_step(current_step)
				_animating = true
				_anim_progress = 0.0
			elif _playing_all and current_step >= get_steps().size() - 1:
				_playing_all = false
				if _btn_play:
					_btn_play.text = "▶ Play"
		queue_redraw()

func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	# Concept title (above diagram)
	draw_string(ThemeDB.fallback_font, Vector2(8, _concept_title_y), get_concept_title(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VizUtil.C_LABEL)
	# Diagram area background + content
	draw_rect(_diagram_rect, VizUtil.C_BG, true)
	_draw_diagram()
	# Animation title (above anim)
	draw_string(ThemeDB.fallback_font, Vector2(8, _anim_title_y), get_anim_title(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, VizUtil.C_LABEL)
	# Code label
	_draw_code_label()
	# Animation area background + content
	draw_rect(_anim_rect, VizUtil.C_BG, true)
	_draw_anim()

# Override in subclass to draw a code label; default is empty
func _draw_code_label() -> void:
	draw_rect(_code_label_rect, Color("#0A1628"), true)
	draw_rect(_code_label_rect, Color("#1A2A3A"), false, 1)
	var steps := get_steps()
	if current_step >= 0 and current_step < steps.size():
		var code_text: String = steps[current_step].get("code", "")
		draw_string(ThemeDB.fallback_font, Vector2(_code_label_rect.position.x + _code_label_rect.size.x * 0.5 - code_text.length() * 4, _code_label_rect.position.y + 16), code_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VizUtil.C_HIGHLIGHT)
