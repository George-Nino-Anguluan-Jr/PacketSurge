extends Node

# Tiny neural network inference engine
# Architecture: 8 inputs -> 6 hidden (ReLU) -> 1 output (sigmoid)
# Trained in Python, weights loaded from JSON

var W1: Array = []
var b1: Array = []
var W2: Array = []
var b2: Array = []
var _loaded: bool = false


func load_model(path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("MLModel: Could not open ", path)
		return false
	var text = file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if not data or not data.has("W1"):
		push_warning("MLModel: Invalid weights file")
		return false
	W1 = data.W1
	b1 = data.b1
	W2 = data.W2
	b2 = data.b2
	_loaded = true
	return true


func predict(features: Array) -> float:
	if not _loaded:
		return 0.5
	# Hidden layer: 8 -> 6 with ReLU
	var h: Array = []
	h.resize(6)
	for i in range(6):
		var s = b1[i]
		var row = W1[i]
		for j in range(8):
			s += row[j] * features[j]
		h[i] = max(0.0, s)
	# Output layer: 6 -> 1 with sigmoid
	var s = b2[0]
	var row = W2[0]
	for j in range(6):
		s += row[j] * h[j]
	return 1.0 / (1.0 + exp(-s))
