extends ScrollContainer

var _touch_id := -1
var _touch_pos := Vector2.ZERO
var _is_dragging := false
var _can_scroll_h := false
var _can_scroll_v := false
var _initialized := false

func _input(event: InputEvent) -> void:
	if not _initialized:
		_can_scroll_h = horizontal_scroll_mode != 0
		_can_scroll_v = vertical_scroll_mode != 0
		_initialized = true
	
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if not get_global_rect().has_point(event.position):
			if event is InputEventScreenTouch and not event.pressed and event.index == _touch_id:
				_touch_id = -1
				_is_dragging = false
			return
	
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			_touch_id = event.index
			_touch_pos = event.position
			_is_dragging = false
		elif not event.pressed and event.index == _touch_id:
			_touch_id = -1
			_is_dragging = false
	
	elif event is InputEventScreenDrag:
		if _touch_id == -1:
			return
		var dx = event.position.x - _touch_pos.x
		var dy = event.position.y - _touch_pos.y
		
		if not _is_dragging:
			if _can_scroll_h and abs(dx) > max(1, scroll_deadzone):
				_is_dragging = true
			elif _can_scroll_v and abs(dy) > max(1, scroll_deadzone):
				_is_dragging = true
		
		if _is_dragging:
			if _can_scroll_h:
				scroll_horizontal -= int(dx)
			if _can_scroll_v:
				scroll_vertical -= int(dy)
			_touch_pos = event.position
	
	if _is_dragging:
		if event is InputEventMouseButton or event is InputEventMouseMotion:
			get_viewport().set_input_as_handled()
