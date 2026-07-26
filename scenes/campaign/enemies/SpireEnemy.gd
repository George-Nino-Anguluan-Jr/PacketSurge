extends Node2D
class_name SpireEnemy

var variant: String = ""
var pack: String = "enemy_pack1"
var current_state: String = "idle"
var current_direction: String = "down"

var _sprite: AnimatedSprite2D

const DISPLAY_SCALE: float = 0.7

func setup(p_variant: String, p_pack: String = "enemy_pack1") -> void:
	variant = p_variant
	pack = p_pack
	_sprite = AnimatedSprite2D.new()
	_sprite.centered = true
	_sprite.scale = Vector2(DISPLAY_SCALE, DISPLAY_SCALE)
	add_child(_sprite)
	_reload_frames()

func _reload_frames() -> void:
	var base_path = "res://assets/enemies/imported/" + pack + "/" + variant
	var sf = SpriteFrames.new()
	for state in ["idle", "move", "death"]:
		for dir in ["down", "up", "right"]:
			var anim_name = "%s_%s" % [state, dir]
			sf.remove_animation(anim_name)
			sf.add_animation(anim_name)
			sf.set_animation_loop(anim_name, state != "death")
			sf.set_animation_speed(anim_name, 5.0 if state != "move" else 7.0)
			var sub_dir = base_path + "/" + state + "_" + dir
			var dir_access = DirAccess.open(sub_dir)
			if not dir_access:
				continue
			var frames = _load_dir_frames(sub_dir)
			for f in frames:
				sf.add_frame(anim_name, load(sub_dir + "/" + f))

	_sprite.sprite_frames = sf
	_play_current()

func _play_current() -> void:
	if not _sprite or not _sprite.sprite_frames:
		return
	var anim_name = "%s_%s" % [current_state, current_direction]
	if _sprite.sprite_frames.has_animation(anim_name):
		_sprite.play(anim_name)

func _load_dir_frames(dir_path: String) -> Array[String]:
	var dir = DirAccess.open(dir_path)
	if not dir:
		return []
	var files: Array[String] = []
	dir.list_dir_begin()
	var f = dir.get_next()
	while f != "":
		if f.ends_with(".png") or f.ends_with(".import"):
			var clean = f.trim_suffix(".import")
			if clean.ends_with(".png") and not files.has(clean):
				files.append(clean)
		f = dir.get_next()
	dir.list_dir_end()
	files.sort()
	return files

func set_state(state: String) -> void:
	if state == current_state:
		return
	if not _sprite or not _sprite.sprite_frames:
		return
	current_state = state
	_play_current()

func set_direction(direction: String) -> void:
	if direction == current_direction:
		return
	current_direction = direction
	_play_current()

func set_flip_h(flipped: bool) -> void:
	if _sprite:
		_sprite.flip_h = flipped
