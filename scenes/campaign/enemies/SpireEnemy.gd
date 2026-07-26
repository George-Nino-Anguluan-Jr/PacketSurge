extends Node2D
class_name SpireEnemy

var variant: String = ""
var current_state: String = "idle"

var _sprite: AnimatedSprite2D

const VARIANT_PATH = "res://assets/enemies/imported/enemy_pack1/"
const DISPLAY_SCALE: float = 0.7

func setup(p_variant: String) -> void:
	variant = p_variant
	_sprite = AnimatedSprite2D.new()
	_sprite.centered = true
	_sprite.scale = Vector2(DISPLAY_SCALE, DISPLAY_SCALE)
	add_child(_sprite)
	_reload_frames()

func _reload_frames() -> void:
	var dir_path = VARIANT_PATH + variant
	var sf = SpriteFrames.new()
	sf.remove_animation("idle")
	sf.remove_animation("move")
	sf.remove_animation("death")
	sf.add_animation("idle")
	sf.add_animation("move")
	sf.add_animation("death")
	sf.set_animation_loop("idle", true)
	sf.set_animation_loop("move", true)
	sf.set_animation_loop("death", false)

	for state in ["idle", "move", "death"]:
		var state_dir = dir_path + "/" + state
		if not DirAccess.open(state_dir):
			continue
		var frames = _load_dir_frames(state_dir)
		# Slow FPS so wing flaps don't look like rotation
		var fps = 5.0
		if state == "move":
			fps = 7.0
		sf.set_animation_speed(state, fps)
		for f in frames:
			sf.add_frame(state, load(state_dir + "/" + f))

	_sprite.sprite_frames = sf
	if sf.has_animation("idle"):
		_sprite.play("idle")

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
	if _sprite.sprite_frames.has_animation(state):
		_sprite.play(state)
