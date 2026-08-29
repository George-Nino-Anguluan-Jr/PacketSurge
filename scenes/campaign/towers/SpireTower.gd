extends Node2D
class_name SpireTower

var variant: String = ""
var current_level: int = 1

var _base: Sprite2D
var _weapon: AnimatedSprite2D
var _turret_angle: float = -PI / 2

const ASSET_ROOT: String = "res://assets/sprites/towers/spire/imported/"

# Projectiles drawn pointing UP need +PI/2 rotation offset
const UP_FACING_VARIANTS: Array = ["tower_01", "tower_06", "tower_07"]

func _proj_rotation(dir: Vector2) -> float:
	if variant in UP_FACING_VARIANTS:
		return dir.angle() + PI / 2
	return dir.angle()

func setup(v: String) -> void:
	variant = v
	_base = Sprite2D.new()
	_base.centered = true
	_base.scale = Vector2(0.5, 0.5)
	add_child(_base)

	_weapon = AnimatedSprite2D.new()
	_weapon.centered = true
	_weapon.scale = Vector2(0.6, 0.6)
	add_child(_weapon)

	_update_visuals()

func _base_path() -> String:
	return ASSET_ROOT + variant

func _base_file(level: int) -> String:
	return _base_path() + "/base/level_0" + str(level) + ".png"

func _weapon_dir(level: int) -> String:
	return _base_path() + "/weapons/L" + str(level) + "/"

func _projectile_dir(level: int) -> String:
	return _base_path() + "/projectiles/L" + str(level) + "/"

func _impact_dir(level: int) -> String:
	if variant in ["tower_02", "tower_03", "tower_04", "tower_05", "tower_07"]:
		return _base_path() + "/impact/L" + str(level) + "/"
	return _base_path() + "/impact/"

func _update_visuals() -> void:
	if variant == "":
		return
	var path: String = _base_file(current_level)
	if ResourceLoader.exists(path):
		var tex = load(path)
		if tex:
			_base.texture = tex
	_load_weapon_frames()

func _load_weapon_frames() -> void:
	var dir_path: String = _weapon_dir(current_level)
	var dir = DirAccess.open(dir_path)
	if not dir:
		return
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
	if files.is_empty():
		return

	var sf = SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	sf.add_animation("idle")
	sf.add_animation("attack")
	sf.set_animation_loop("idle", true)
	sf.set_animation_loop("attack", false)
	var anim_fps: float = 12.0
	if files.size() > 0:
		anim_fps = files.size() / 0.35
	sf.set_animation_speed("attack", anim_fps)

	var first: String = str(files[0])
	if ResourceLoader.exists(dir_path + first):
		sf.add_frame("idle", load(dir_path + first))
	for file in files:
		var fp: String = dir_path + str(file)
		if ResourceLoader.exists(fp):
			sf.add_frame("attack", load(fp))

	_weapon.sprite_frames = sf
	_weapon.play("idle")
	if _weapon.animation_finished.is_connected(_on_anim_done):
		_weapon.animation_finished.disconnect(_on_anim_done)
	_weapon.animation_finished.connect(_on_anim_done)

func _on_anim_done() -> void:
	if _weapon and _weapon.sprite_frames and _weapon.animation == "attack":
		_weapon.play("idle")

func set_level(lvl: int) -> void:
	current_level = lvl
	_update_visuals()

func aim(angle: float) -> void:
	_turret_angle = angle
	if _weapon:
		_weapon.rotation = _turret_angle + PI / 2

func fire(target: Node, damage: float) -> void:
	if variant == "" or not is_instance_valid(target):
		return
	if _weapon and _weapon.sprite_frames:
		_weapon.play("attack")

	var proj = AnimatedSprite2D.new()
	proj.centered = true
	proj.scale = Vector2(0.8, 0.8)
	var pdir: String = _projectile_dir(current_level)
	var sf = _load_sprite_frames_from(pdir, 15.0)
	if sf:
		proj.sprite_frames = sf
		proj.play("play")
	add_child(proj)

	var origin = Vector2(0, -14).rotated(_turret_angle)
	proj.position = origin
	var t_local = to_local(target.global_position)
	var dir = t_local - origin
	if dir.length() > 0:
		proj.rotation = _proj_rotation(dir)

	var tw = create_tween()
	var travel_time = origin.distance_to(t_local) / 300.0
	tw.tween_method(func(t):
		if not is_instance_valid(proj):
			return
		var pos
		if is_instance_valid(target):
			var tl = to_local(target.global_position)
			pos = origin.lerp(tl, t)
			var d = tl - pos
			if d.length() > 0 and t < 0.95:
				proj.rotation = _proj_rotation(d)
		else:
			pos = origin.lerp(origin + Vector2(0, -200), t)
		proj.position = pos
	, 0.0, 1.0, travel_time)
	tw.tween_callback(func(): _on_hit(proj, target, damage))

func _load_sprite_frames_from(dir_path: String, speed: float = 10.0) -> SpriteFrames:
	var dir = DirAccess.open(dir_path)
	if not dir:
		return null
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
	if files.is_empty():
		return null
	var sf = SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	sf.add_animation("play")
	sf.set_animation_loop("play", true)
	sf.set_animation_speed("play", speed)
	for file in files:
		var fp: String = dir_path + str(file)
		if ResourceLoader.exists(fp):
			sf.add_frame("play", load(fp))
	return sf

func _on_hit(proj: AnimatedSprite2D, target: Node, dmg: float) -> void:
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(dmg)

	if is_instance_valid(proj):
		var hit = proj.global_position
		var impact = AnimatedSprite2D.new()
		impact.centered = true
		impact.z_index = 5
		impact.scale = Vector2(0.7, 0.7)
		var idir: String = _impact_dir(current_level)
		var sf = _load_sprite_frames_from(idir)
		if sf:
			sf.set_animation_loop("play", false)
			impact.sprite_frames = sf
			impact.play("play")
			impact.animation_finished.connect(func():
				if is_instance_valid(impact): impact.queue_free()
			)
		if get_parent():
			get_parent().add_child(impact)
		impact.global_position = hit
		proj.queue_free()
