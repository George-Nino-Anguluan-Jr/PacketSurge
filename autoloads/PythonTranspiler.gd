extends Node

func transpile(source: String) -> Dictionary:
	var lines = source.split("\n", false)
	var declared = {}
	var out = []
	out.append("var _output_buffer = \"\"")
	out.append("func _gs_add_output(val):")
	out.append("    _output_buffer += str(val) + \"\\n\"")
	out.append("")
	out.append("func run():")
	var body = _build(lines, 0, 0, declared)
	for line in body:
		out.append("    " + line)
	out.append("    return _output_buffer")
	return { "success": true, "gdscript": "\n".join(out), "error": "" }

# Process lines starting at idx at given depth (0 = root level inside func run).
# Returns lines with "    ".repeat(depth) prefix already applied.
func _build(lines, idx, depth, declared):
	var result = []
	var i = idx
	while i < lines.size():
		var raw = lines[i]
		var stripped = raw.strip_edges()
		i += 1
		if stripped == "" or stripped.begins_with("#"):
			continue
		var lead = _count_ws(raw)
		var expect = depth * 4
		if lead < expect:
			i -= 1
			break
		var indent = "    ".repeat(depth)
		var gds = _convert_line(stripped, declared)
		result.append(indent + gds)
		if stripped.ends_with(":"):
			var body = _build(lines, i, depth + 1, declared)
			for line in body:
				result.append(line)
			i = _advance(lines, i, depth + 1)
	return result

func _advance(lines, start, depth):
	var i = start
	while i < lines.size():
		var raw = lines[i]
		if raw.strip_edges() == "":
			i += 1
			continue
		if _count_ws(raw) < depth * 4:
			return i
		i += 1
	return i

func _convert_line(line, declared):
	if line.begins_with("print("):
		return line.replace("print(", "_gs_add_output(")
	if line.begins_with("def "):
		return line.replace("def ", "func ")
	if line == "else:" or line.begins_with("else:"):
		return "else:"
	if line.begins_with("elif "):
		return line
	if line.begins_with("for ") and " in " in line:
		return line
	if line.begins_with("while "):
		return line
	if line.begins_with("return "):
		return line
	if "=" in line and not "==" in line:
		var parts = line.split("=", true, 1)
		if parts.size() == 2:
			var vname = parts[0].strip_edges()
			if vname.is_valid_identifier() and not declared.has(vname):
				declared[vname] = true
				line = "var " + line
	return line.replace("True", "true").replace("False", "false").replace("None", "null")

func _count_ws(s: String) -> int:
	var n = 0
	for i in range(s.length()):
		var c = s[i]
		if c == ' ':
			n += 1
		elif c == '\t':
			n += 4
		else:
			break
	return n

func run_code(source: String) -> Dictionary:
	var result = transpile(source)
	if not result.success:
		return { "success": false, "output": "", "error": "Transpile error: " + result.error }
	var gd = GDScript.new()
	gd.source_code = result.gdscript
	var err = gd.reload()
	if err != OK:
		return { "success": false, "output": "", "error": "Compile error: script failed to compile." }
	var instance = gd.new()
	if instance == null:
		return { "success": false, "output": "", "error": "Failed to instantiate compiled script." }
	if instance.has_method(&"run"):
		var val = instance.run()
		var output = str(val) if val != null else ""
		return { "success": true, "output": output.strip_edges(false, true), "error": "" }
	return { "success": false, "output": "", "error": "No run() method generated." }
