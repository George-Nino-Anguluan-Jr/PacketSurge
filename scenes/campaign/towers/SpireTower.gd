extends Node2D
class_name SpireTower

var variant: String = ""
var current_level: int = 1

var _base: Sprite2D
var _weapon: AnimatedSprite2D
var _turret_angle: float = -PI / 2

func setup(v: String) -> void:
	variant = v
	_base = Sprite2D.new()
	_base.centered = true
	_base.scale = Vector2(0.5, 0.5)
	add_child(_base)

	_weapon = AnimatedSprite2D.new()
	_weapon.centered = true
	_weapon.scale = Vector2(0.5, 0.5)
	add_child(_weapon)

	_update_visuals()

func _base_path() -> String:
	return "res://assets/towers/spire/imported/" + variant

func _base_file(level: int) -> String:
	return _base_path() + "/base/level_0" + str(level) + ".png"

func _weapon_dir(level: int) -> String:
	return _base_path() + "/weapons/L" + str(level) + "/"

func _projectile_dir(level: int) -> String:
	return _base_path() + "/projectiles/L" + str(level) + "/"

func _impact_dir(level: int) -> String:
	if variant == "tower_02":
		return _base_path() + "/impact/L" + str(level) + "/"
	return _base_path() + "/impact/"

func _update_visuals() -> void:
	if variant == "":
		return
	var path = _base_file(current_level)
	if ResourceLoader.exists(path):
		_base.texture = load(path)
	_load_weapon_frames()

func _load_weapon_frames() -> void:
	var dir_path = _weapon_dir(current_level)
	var dir = DirAccess.open(dir_path)
	if not dir:
		return
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
	if files.is_empty():
		return

	var sf = SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("idle")
	sf.add_animation("attack")
	sf.set_animation_loop("idle", true)
	sf.set_animation_loop("attack", false)
	sf.set_animation_speed("attack", 12.0)

	var first = files[0]
	if ResourceLoader.exists(dir_path + first):
		sf.add_frame("idle", load(dir_path + first))
	for file in files:
		if ResourceLoader.exists(dir_path + file):
			sf.add_frame("attack", load(dir_path + file))

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
	_weapon.rotation = _turret_angle + PI / 2

func fire(target: Node, damage: float) -> void:
	if variant == "" or not is_instance_valid(target):
		return
	if _weapon and _weapon.sprite_frames:
		_weapon.play("attack")

	var proj = AnimatedSprite2D.new()
	proj.centered = true
	proj.scale = Vector2(0.5, 0.5)
	var pdir = _projectile_dir(current_level)
	var sf = _load_sprite_frames_from(pdir)
	if sf:
		proj.sprite_frames = sf
		proj.play("play")
	add_child(proj)

	var origin = Vector2(0, -14).rotated(_turret_angle)
	proj.position = origin
	var t_local = to_local(target.global_position)
	var dir = t_local - origin
	if dir.length() > 0:
		proj.rotation = dir.angle()

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
				proj.rotation = d.angle()
		else:
			pos = origin.lerp(origin + Vector2(0, -200), t)
		proj.position = pos
	, 0.0, 1.0, travel_time)
	tw.tween_callback(func(): _on_hit(proj, target, damage))

func _load_sprite_frames_from(dir_path: String) -> SpriteFrames:
	var dir = DirAccess.open(dir_path)
	if not dir:
		return null
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
	if files.is_empty():
		return null
	var sf = SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("play")
	sf.set_animation_loop("play", true)
	sf.set_animation_speed("play", 10.0)
	for file in files:
		if ResourceLoader.exists(dir_path + file):
			sf.add_frame("play", load(dir_path + file))
	return sf

func _on_hit(proj: AnimatedSprite2D, target: Node, dmg: float) -> void:
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(dmg)

	if is_instance_valid(proj):
		var hit = proj.global_position
		var impact = AnimatedSprite2D.new()
		impact.centered = true
		impact.z_index = 5
		impact.scale = Vector2(1.5, 1.5)
		var idir = _impact_dir(current_level)
		var sf = _load_sprite_frames_from(idir)
		if sf:
			sf.set_animation_loop("play", false)
			impact.sprite_frames = sf
			impact.play("play")
			impact.animation_finished.connect(func():
				if is_instance_valid(impact): impact.queue_free()
			)
		impact.global_position = hit
		if get_parent():
			get_parent().add_child(impact)
		proj.queue_free()
