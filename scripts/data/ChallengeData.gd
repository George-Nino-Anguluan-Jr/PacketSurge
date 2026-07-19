# ChallengeData.gd
# Loads and manages challenge definitions from JSON resources
extends Resource

class_name ChallengeData

@export var challenge_resources: Array[Resource] = []

var _challenges: Dictionary = {}
var _topics: Array[String] = []
var _loaded: bool = false

func _init():
	_load_all_challenges()

func _load_all_challenges() -> void:
	if _loaded:
		return
	
	# Load from resources/challenges/ directory
	var dir = DirAccess.open("res://resources/challenges/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json") and not file_name.begins_with("."):
				var path = "res://resources/challenges/%s" % file_name
				var resource = ResourceLoader.load(path)
				if resource:
					_parse_challenge_json(resource, file_name.get_file().get_basename())
			file_name = dir.get_next()
		dir.list_dir_end()
	
	# Also load from exported resources
	for resource in challenge_resources:
		if resource:
			_parse_challenge_json(resource, resource.resource_path.get_file().get_basename())
	
	_loaded = true

func _parse_challenge_json(resource: Resource, topic_id: String) -> void:
	if not resource is JSON:
		push_error("Resource is not a JSON resource for topic: %s" % topic_id)
		return
	
	var data = resource.data
	if data == null:
		push_error("Failed to parse challenge JSON or data is null for %s" % topic_id)
		return
	
	if not data.has("challenge_id"):
		push_error("Challenge JSON missing challenge_id: %s" % topic_id)
		return
	
	_challenges[topic_id] = data
	if topic_id not in _topics:
		_topics.append(topic_id)

func get_challenge(topic_id: String) -> Dictionary:
	if not _loaded:
		_load_all_challenges()
	return _challenges.get(topic_id, {})

func get_all_challenges() -> Dictionary:
	if not _loaded:
		_load_all_challenges()
	return _challenges

func get_topics() -> Array[String]:
	if not _loaded:
		_load_all_challenges()
	return _topics.duplicate()

func get_challenge_by_type(topic_id: String, challenge_type: String) -> Array[Dictionary]:
	var challenge = get_challenge(topic_id)
	var empty: Array[Dictionary] = []
	if not challenge or not challenge.has("challenges"):
		return empty
	var raw_array = challenge.challenges.get(challenge_type, [])
	if raw_array is Array:
		var typed_array: Array[Dictionary] = []
		typed_array.assign(raw_array)
		return typed_array
	return empty

func get_random_challenge(topic_id: String, challenge_type: String) -> Dictionary:
	var challenges = get_challenge_by_type(topic_id, challenge_type)
	if challenges.is_empty():
		return {}
	return challenges.pick_random()

func get_challenge_count(topic_id: String) -> int:
	var challenge = get_challenge(topic_id)
	if not challenge or not challenge.has("challenges"):
		return 0
	var count = 0
	for type_challenges in challenge.challenges.values():
		count += type_challenges.size()
	return count

func get_difficulty(topic_id: String) -> String:
	var challenge = get_challenge(topic_id)
	return challenge.get("difficulty", "easy")

func get_challenge_types(topic_id: String) -> Array[String]:
	var challenge = get_challenge(topic_id)
	if not challenge or not challenge.has("types"):
		return []
	return challenge.types.duplicate()

# Static access
static var _instance: ChallengeData = null

static func get_instance() -> ChallengeData:
	if _instance == null:
		_instance = ChallengeData.new()
	return _instance

static func get_challenge_static(topic_id: String) -> Dictionary:
	return get_instance().get_challenge(topic_id)

static func get_random_challenge_static(topic_id: String, challenge_type: String) -> Dictionary:
	return get_instance().get_random_challenge(topic_id, challenge_type)