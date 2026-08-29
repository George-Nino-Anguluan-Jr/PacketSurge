extends Node2D
class_name SpireEnemy

var variant: String = ""
var pack: String = "enemy_pack1"
var current_state: String = "idle"
var current_direction: String = "down"

var _sprite: AnimatedSprite2D

const DISPLAY_SCALE: float = 0.7
const ASSET_ROOT: String = "res://assets/sprites/enemies/imported/"

func setup(p_variant: String, p_pack: String = "enemy_pack1", p_scale: float = DISPLAY_SCALE) -> void:
	variant = p_variant
	pack = p_pack
	_sprite = AnimatedSprite2D.new()
	_sprite.centered = true
	_sprite.scale = Vector2(p_scale, p_scale)
	add_child(_sprite)
	_reload_frames()

func _reload_frames() -> void:
	var base_path: String = ASSET_ROOT + pack + "/" + variant
	var sf = SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	for state in ["idle", "move", "death"]:
		for dir in ["down", "up", "right"]:
			var anim_name: String = state + "_" + dir
			sf.add_animation(anim_name)
			sf.set_animation_loop(anim_name, state != "death")
			sf.set_animation_speed(anim_name, 5.0 if state != "move" else 7.0)
			var sub_dir: String = base_path + "/" + anim_name
			var dir_access = DirAccess.open(sub_dir)
			if not dir_access:
				continue
			var frames = _load_dir_frames(sub_dir)
			for f in frames:
				var frame_path: String = sub_dir + "/" + f
				if ResourceLoader.exists(frame_path):
					sf.add_frame(anim_name, load(frame_path))

	_sprite.sprite_frames = sf
	_play_current()

func _play_current() -> void:
	if not _sprite or not _sprite.sprite_frames:
		return
	var anim_name: String = current_state + "_" + current_direction
	if _sprite.sprite_frames.has_animation(anim_name):
		_sprite.play(anim_name)

func _load_dir_frames(dir_path: String) -> Array:
	var dir = DirAccess.open(dir_path)
	if not dir:
		return []
	var files: Array = []
	dir.list_dir_begin()
	var f: String = dir.get_next()
	while f != "":
		if f.ends_with(".png") and not f.begins_with("."):
			if not files.has(f):
				files.append(f)
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
