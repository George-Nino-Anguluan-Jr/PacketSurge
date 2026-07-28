extends Node

func run_code(source: String) -> Dictionary:
	var lines = source.split("\n", false)
	var env = {}
	var state = { "ok": true, "err": "", "output": "" }
	_exec_block(lines, 0, 0, env, state)
	if not state.ok:
		return { "success": false, "output": "", "error": state.err }
	return { "success": true, "output": state.output.strip_edges(false, true), "error": "" }

func _exec_block(lines, idx, depth, env, state):
	var i = idx
	while i < lines.size() and state.ok:
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
		_exec_stmt(stripped, env, state)
		if not state.ok:
			return
		if not stripped.ends_with(":"):
			continue
		if stripped.begins_with("def ") and stripped.ends_with(":"):
			var parts = stripped.split("(")
			if parts.size() < 2:
				state.ok = false
				state.err = "Invalid function definition."
				return
			var fname = parts[0].substr(4).strip_edges()
			var params_str = parts[1].substr(0, parts[1].length() - 2).strip_edges()
			var params = []
			if params_str != "":
				for p in params_str.split(","):
					params.append(p.strip_edges())
			var body = _collect_block(lines, i, depth + 1)
			env[fname] = { "params": params, "body": body }
			i = _skip_block(lines, i, depth + 1)
		elif stripped.begins_with("if "):
			var cond = stripped.substr(3, stripped.length() - 4).strip_edges()
			var cond_val = _eval_expr(cond, env, state)
			if not state.ok:
				return
			i = _exec_if_chain(lines, i, depth + 1, env, state, cond_val)
		elif stripped.begins_with("elif ") or stripped.begins_with("else:"):
			i = _skip_block(lines, i, depth + 1)
		elif stripped.begins_with("for ") and " in " in stripped:
			var parsed = _parse_for(stripped)
			if parsed.size() != 3:
				state.ok = false
				state.err = "Invalid for loop syntax."
				return
			var iterable = _eval_expr(parsed[2], env, state)
			if not state.ok:
				return
			if typeof(iterable) != TYPE_ARRAY:
				state.ok = false
				state.err = "Can only iterate over arrays."
				return
			for element in iterable:
				env[parsed[0]] = element
				_exec_block(lines, i, depth + 1, env, state)
				if not state.ok:
					return
			i = _advance_to(lines, i, depth + 1)
		elif stripped.begins_with("while "):
			var loop_cond = stripped.substr(6, stripped.length() - 7).strip_edges()
			var max_iter = 10000
			var iter_count = 0
			while _eval_expr(loop_cond, env, state):
				if not state.ok:
					return
				iter_count += 1
				if iter_count > max_iter:
					state.ok = false
					state.err = "Loop exceeded maximum iterations (10000)."
					return
				_exec_block(lines, i, depth + 1, env, state)
				if not state.ok:
					return
			i = _advance_to(lines, i, depth + 1)

func _exec_if_chain(lines, idx, depth, env, state, cond_val):
	var i = idx
	if cond_val:
		_exec_block(lines, i, depth, env, state)
		if not state.ok:
			return lines.size()
		return _skip_chain(lines, i, depth)
	var after = _skip_block(lines, i, depth)
	if after >= lines.size():
		return after
	var raw = lines[after]
	var stripped = raw.strip_edges()
	var lead = _count_ws(raw)
	if lead < depth * 4:
		if stripped.begins_with("elif "):
			var cond = stripped.substr(5, stripped.length() - 6).strip_edges()
			var val = _eval_expr(cond, env, state)
			if not state.ok:
				return lines.size()
			return _exec_if_chain(lines, after + 1, depth, env, state, val)
		if stripped == "else:" or stripped.begins_with("else:"):
			_exec_block(lines, after + 1, depth, env, state)
			if not state.ok:
				return lines.size()
			return _skip_block(lines, after + 1, depth)
	return after

func _collect_block(lines, start, depth):
	var result = []
	var i = start
	while i < lines.size():
		var raw = lines[i]
		if raw.strip_edges() == "":
			i += 1
			continue
		if _count_ws(raw) < depth * 4:
			break
		result.append(raw)
		i += 1
	return result

func _skip_block(lines, start, depth):
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

func _skip_chain(lines, start, depth):
	var i = _skip_block(lines, start, depth)
	while i < lines.size():
		var raw = lines[i]
		var stripped = raw.strip_edges()
		if stripped == "":
			i += 1
			continue
		var lead = _count_ws(raw)
		if lead >= depth * 4:
			break
		if stripped.begins_with("elif ") or stripped == "else:" or stripped.begins_with("else:"):
			i = _skip_block(lines, i + 1, depth)
			continue
		break
	return i

func _advance_to(lines, start, depth):
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

func _exec_stmt(stripped, env, state):
	if stripped.begins_with("print("):
		var inner = stripped.substr(6, stripped.length() - 7).strip_edges()
		var args = _split_print_args(inner)
		var parts = []
		for a in args:
			var v = _eval_expr(a.strip_edges(), env, state)
			if not state.ok:
				return
			parts.append(str(v))
		state.output += " ".join(parts) + "\n"
		return
	if stripped.begins_with("def ") or stripped.begins_with("if ") or stripped.begins_with("elif ") or stripped.begins_with("else:") or stripped.begins_with("for ") or stripped.begins_with("while ") or stripped.begins_with("return ") or stripped.begins_with("from ") or stripped.begins_with("import "):
		return
	if "=" in stripped and not "==" in stripped:
		# Handle compound assignment: += -= *= /=
		for op_str in ["+=", "-=", "*=", "/="]:
			if op_str in stripped:
				var idx = stripped.find(op_str)
				var lhs = stripped.substr(0, idx).strip_edges()
				var rhs = stripped.substr(idx + 2).strip_edges()
				stripped = lhs + " = " + lhs + " " + op_str[0] + " " + rhs
				break
		var parts = stripped.split("=", true, 1)
		if parts.size() == 2:
			var lhs = parts[0].strip_edges()
			var rhs = parts[1].strip_edges()
			# Tuple / list unpacking: a, b = c, d  or  arr[i], arr[j] = arr[j], arr[i]
			if "," in lhs:
				var lhs_targets = _split_comma(lhs)
				var rhs_values  = _split_comma(rhs)
				if lhs_targets.size() != rhs_values.size():
					state.ok = false
					state.err = "Assignment mismatch: " + str(lhs_targets.size()) + " targets, " + str(rhs_values.size()) + " values."
					return
				# Evaluate RHS first into a temp list so the swap semantics work
				# (e.g. arr[j], arr[j+1] = arr[j+1], arr[j]).
				var tmp = []
				for r in rhs_values:
					var v = _eval_expr(r.strip_edges(), env, state)
					if not state.ok:
						return
					tmp.append(v)
				for k in range(lhs_targets.size()):
					var target = lhs_targets[k].strip_edges()
					_assign_single_target(target, tmp[k], env, state)
					if not state.ok:
						return
				return
			var val = _eval_expr(rhs, env, state)
			if not state.ok:
				return
			_assign_single_target(lhs, val, env, state)
			return
	if "(" in stripped and stripped.ends_with(")"):
		_eval_expr(stripped, env, state)
		return
	state.ok = false
	state.err = "Unknown statement: " + stripped

func _assign_single_target(target: String, val, env: Dictionary, state: Dictionary) -> void:
	# Handles both `name = value` and `name[idx] = value` for a single target.
	var lb = target.find("[")
	if lb != -1 and target.ends_with("]"):
		var vname = target.substr(0, lb).strip_edges()
		var idx_str = target.substr(lb + 1, target.length() - lb - 2).strip_edges()
		var idx = _eval_expr(idx_str, env, state)
		if not state.ok:
			return
		if env.has(vname) and typeof(env[vname]) == TYPE_ARRAY and typeof(idx) == TYPE_INT:
			env[vname][idx] = val
			return
		state.ok = false
		state.err = "Invalid array index in assignment: '" + target + "'."
		return
	if target.is_valid_identifier():
		env[target] = val
		return
	state.ok = false
	state.err = "Invalid assignment: '" + target + "' is not a valid variable name or array index."

func _eval_expr(expr, env, state):
	var s = expr.strip_edges()
	if s == "":
		state.ok = false
		state.err = "Empty expression."
		return null
	if (s.begins_with("\"") and s.ends_with("\"")) or (s.begins_with("'") and s.ends_with("'")):
		return s.substr(1, s.length() - 2)
	if s.is_valid_int():
		return int(s)
	if s.is_valid_float():
		return float(s)
	if s == "true" or s == "True":
		return true
	if s == "false" or s == "False":
		return false
	if s == "null" or s == "None":
		return null
	if s.begins_with("[") and s.ends_with("]"):
		var inner = s.substr(1, s.length() - 2).strip_edges()
		var arr = []
		if inner != "":
			for item in _split_comma(inner):
				var v = _eval_expr(item.strip_edges(), env, state)
				if not state.ok:
					return null
				arr.append(v)
		return arr
	# Handle logical operators: or (lowest precedence), then and
	var or_idx = _find_op(s, " or ")
	if or_idx != -1:
		var left = _eval_expr(s.substr(0, or_idx).strip_edges(), env, state)
		if not state.ok:
			return null
		if left:
			return left
		return _eval_expr(s.substr(or_idx + 4).strip_edges(), env, state)
	var and_idx = _find_op(s, " and ")
	if and_idx != -1:
		var left = _eval_expr(s.substr(0, and_idx).strip_edges(), env, state)
		if not state.ok:
			return null
		if not left:
			return left
		return _eval_expr(s.substr(and_idx + 5).strip_edges(), env, state)
	# Handle not (prefix operator)
	if s.begins_with("not "):
		var val = _eval_expr(s.substr(4).strip_edges(), env, state)
		if not state.ok:
			return null
		return not val

	var ops_compare = ["==", "!=", "<=", ">=", "<", ">"]
	for op in ops_compare:
		var idx = _find_op(s, op)
		if idx != -1:
			var left = _eval_expr(s.substr(0, idx).strip_edges(), env, state)
			if not state.ok:
				return null
			var right = _eval_expr(s.substr(idx + op.length()).strip_edges(), env, state)
			if not state.ok:
				return null
			if op in ["<", ">", "<=", ">="]:
				var lt = typeof(left)
				var rt = typeof(right)
				if not ((lt == TYPE_INT or lt == TYPE_FLOAT) and (rt == TYPE_INT or rt == TYPE_FLOAT)):
					state.ok = false
					state.err = "Cannot compare " + _type_name(lt) + " and " + _type_name(rt) + " with " + op + "."
					return null
			match op:
				"==": return left == right
				"!=": return left != right
				"<=": return left <= right
				">=": return left >= right
				"<": return left < right
				">": return left > right
	var mult_idx = _find_op(s, "*")
	if mult_idx != -1:
		var left = _eval_expr(s.substr(0, mult_idx).strip_edges(), env, state)
		if not state.ok:
			return null
		var right = _eval_expr(s.substr(mult_idx + 1).strip_edges(), env, state)
		if not state.ok:
			return null
		var lt = typeof(left)
		var rt = typeof(right)
		if not ((_is_numeric(left) and _is_numeric(right)) or (lt == TYPE_ARRAY and rt == TYPE_INT) or (lt == TYPE_INT and rt == TYPE_ARRAY)):
			state.ok = false
			state.err = "Cannot multiply " + _type_name(lt) + " and " + _type_name(rt) + "."
			return null
		return left * right
	var mod_idx = _find_op(s, "%")
	if mod_idx != -1:
		var left = _eval_expr(s.substr(0, mod_idx).strip_edges(), env, state)
		if not state.ok:
			return null
		var right = _eval_expr(s.substr(mod_idx + 1).strip_edges(), env, state)
		if not state.ok:
			return null
		if not _is_numeric(left) or not _is_numeric(right):
			state.ok = false
			state.err = "Cannot modulo " + _type_name(typeof(left)) + " and " + _type_name(typeof(right)) + "."
			return null
		if right == 0:
			state.ok = false
			state.err = "Modulo by zero."
			return null
		return int(left) % int(right)
	var fdiv_idx = _find_op(s, "//")
	if fdiv_idx != -1:
		var left = _eval_expr(s.substr(0, fdiv_idx).strip_edges(), env, state)
		if not state.ok:
			return null
		var right = _eval_expr(s.substr(fdiv_idx + 2).strip_edges(), env, state)
		if not state.ok:
			return null
		if not _is_numeric(left) or not _is_numeric(right):
			state.ok = false
			state.err = "Cannot floor divide " + _type_name(typeof(left)) + " and " + _type_name(typeof(right)) + "."
			return null
		if right == 0:
			state.ok = false
			state.err = "Division by zero."
			return null
		return int(left / right)
	var div_idx = _find_op(s, "/")
	if div_idx != -1:
		var left = _eval_expr(s.substr(0, div_idx).strip_edges(), env, state)
		if not state.ok:
			return null
		var right = _eval_expr(s.substr(div_idx + 1).strip_edges(), env, state)
		if not state.ok:
			return null
		if not _is_numeric(left) or not _is_numeric(right):
			state.ok = false
			state.err = "Cannot divide " + _type_name(typeof(left)) + " and " + _type_name(typeof(right)) + "."
			return null
		if right == 0:
			state.ok = false
			state.err = "Division by zero."
			return null
		return left / right
	var plus_idx = _find_op(s, "+")
	if plus_idx != -1:
		var left = _eval_expr(s.substr(0, plus_idx).strip_edges(), env, state)
		if not state.ok:
			return null
		var right = _eval_expr(s.substr(plus_idx + 1).strip_edges(), env, state)
		if not state.ok:
			return null
		var lt = typeof(left)
		var rt = typeof(right)
		if lt == TYPE_STRING or rt == TYPE_STRING:
			return str(left) + str(right)
		if lt == TYPE_FLOAT or rt == TYPE_FLOAT:
			return float(left) + float(right)
		if _is_numeric(left) and _is_numeric(right):
			return left + right
		if lt == TYPE_ARRAY and rt == TYPE_ARRAY:
			var out = []
			out.append_array(left)
			out.append_array(right)
			return out
		state.ok = false
		state.err = "Cannot add " + _type_name(lt) + " and " + _type_name(rt) + "."
		return null
	var minus_idx = _find_op(s, "-")
	if minus_idx != -1:
		var left = _eval_expr(s.substr(0, minus_idx).strip_edges(), env, state)
		if not state.ok:
			return null
		var right = _eval_expr(s.substr(minus_idx + 1).strip_edges(), env, state)
		if not state.ok:
			return null
		if not _is_numeric(left) or not _is_numeric(right):
			state.ok = false
			state.err = "Cannot subtract " + _type_name(typeof(left)) + " and " + _type_name(typeof(right)) + "."
			return null
		return left - right
	var idx_dot = _find_op(s, ".")
	if idx_dot != -1:
		var obj_name = s.substr(0, idx_dot).strip_edges()
		var rest = s.substr(idx_dot + 1).strip_edges()
		if env.has(obj_name):
			var obj = env[obj_name]
			if rest == "pop()":
				if typeof(obj) == TYPE_ARRAY and obj.size() > 0:
					return obj.pop_back()
			elif rest.begins_with("pop("):
				var arg = _eval_expr(rest.substr(4, rest.length() - 5).strip_edges(), env, state)
				if state.ok and typeof(obj) == TYPE_ARRAY and typeof(arg) == TYPE_INT:
					return obj.pop_at(arg)
			elif rest.begins_with("remove("):
				var arg = _eval_expr(rest.substr(7, rest.length() - 8).strip_edges(), env, state)
				if state.ok and typeof(obj) == TYPE_ARRAY and typeof(arg) == TYPE_INT:
					obj.remove_at(arg)
					return obj
			elif rest.begins_with("append("):
				var arg = _eval_expr(rest.substr(7, rest.length() - 8).strip_edges(), env, state)
				if state.ok and typeof(obj) == TYPE_ARRAY:
					obj.append(arg)
					return obj
		return null

	if s.begins_with("(") and s.ends_with(")"):
		var inner = s.substr(1, s.length() - 2).strip_edges()
		return _eval_expr(inner, env, state)
	var paren_idx = s.find("(")
	if paren_idx != -1 and s.ends_with(")"):
		var fname = s.substr(0, paren_idx).strip_edges()
		var args_str = s.substr(paren_idx + 1, s.length() - paren_idx - 2).strip_edges()
		var arg_vals = []
		if args_str != "":
			for a in _split_comma(args_str):
				var v = _eval_expr(a.strip_edges(), env, state)
				if not state.ok:
					return null
				arg_vals.append(v)
		match fname:
			"len":
				if arg_vals.size() != 1:
					state.ok = false
					state.err = "len() takes exactly 1 argument, got " + str(arg_vals.size()) + "."
					return null
				var v = arg_vals[0]
				if v == null:
					state.ok = false
					state.err = "len() of None."
					return null
				return v.size()
			"str":
				if arg_vals.size() != 1:
					state.ok = false
					state.err = "str() takes exactly 1 argument, got " + str(arg_vals.size()) + "."
					return null
				return str(arg_vals[0])
			"int":
				if arg_vals.size() != 1:
					state.ok = false
					state.err = "int() takes exactly 1 argument, got " + str(arg_vals.size()) + "."
					return null
				if arg_vals[0] == null:
					state.ok = false
					state.err = "int() of None."
					return null
				return int(arg_vals[0])
			"float":
				if arg_vals.size() != 1:
					state.ok = false
					state.err = "float() takes exactly 1 argument, got " + str(arg_vals.size()) + "."
					return null
				if arg_vals[0] == null:
					state.ok = false
					state.err = "float() of None."
					return null
				return float(arg_vals[0])
			"range":
				var start = 0
				var stop = 0
				if arg_vals.size() == 1:
					var v = arg_vals[0]
					if v == null:
						state.ok = false
						state.err = "range() argument is None."
						return null
					if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
						state.ok = false
						state.err = "range() expects an int, got an array. Did you mean range(len(arr))?"
						return null
					stop = int(v)
				elif arg_vals.size() == 2:
					var s_val = arg_vals[0]
					var e_val = arg_vals[1]
					if s_val == null or e_val == null:
						state.ok = false
						state.err = "range() argument is None."
						return null
					if typeof(s_val) != TYPE_INT and typeof(s_val) != TYPE_FLOAT:
						state.ok = false
						state.err = "range() start expects an int, got " + _type_name(typeof(s_val)) + "."
						return null
					if typeof(e_val) != TYPE_INT and typeof(e_val) != TYPE_FLOAT:
						state.ok = false
						state.err = "range() stop expects an int, got " + _type_name(typeof(e_val)) + "."
						return null
					start = int(s_val)
					stop = int(e_val)
				else:
					state.ok = false
					state.err = "range() takes 1 or 2 arguments, got " + str(arg_vals.size()) + "."
					return null
				var r = []
				var i = start
				while i < stop:
					r.append(i)
					i += 1
				return r
			"deque": return []
		if env.has(fname):
			return _call_func(fname, arg_vals, env, state)
		var dot_idx = fname.find(".")
		if dot_idx != -1:
			var obj_name = fname.substr(0, dot_idx)
			var method = fname.substr(dot_idx + 1)
			if env.has(obj_name):
				var obj = env[obj_name]
				if typeof(obj) == TYPE_ARRAY:
					match method:
						"append":
							if arg_vals.size() == 1:
								obj.append(arg_vals[0])
							return null
						"pop":
							if arg_vals.size() == 0:
								return obj.pop_back()
							return obj.pop_at(arg_vals[0])
						"extend":
							if arg_vals.size() == 1:
								obj.append_array(arg_vals[0])
							return null
						"popleft": return obj.pop_at(0)
						"appendleft":
							if arg_vals.size() == 1:
								obj.insert(0, arg_vals[0])
							return null
						_:
							state.ok = false
							state.err = "Unsupported list method: " + method
							return null
				state.ok = false
				state.err = "Can't call methods on " + obj_name + " (type " + str(typeof(obj)) + ")"
				return null
	var idx_br = _find_op(s, "[")
	if idx_br != -1 and s.ends_with("]"):
		var var_name = s.substr(0, idx_br).strip_edges()
		var index_str = s.substr(idx_br + 1, s.length() - idx_br - 2).strip_edges()
		# Handle slice syntax: arr[start:end] or arr[:end] or arr[start:] or arr[:]
		var colon_idx = index_str.find(":")
		if colon_idx != -1:
			var start_str = index_str.substr(0, colon_idx).strip_edges()
			var end_str = index_str.substr(colon_idx + 1).strip_edges()
			if env.has(var_name):
				var target = env[var_name]
				if typeof(target) == TYPE_ARRAY:
					var start_idx = 0 if start_str == "" else _eval_expr(start_str, env, state)
					if not state.ok:
						return null
					var end_idx = target.size() if end_str == "" else _eval_expr(end_str, env, state)
					if not state.ok:
						return null
					if typeof(start_idx) != TYPE_INT or typeof(end_idx) != TYPE_INT:
						state.ok = false
						state.err = "Slice indices must be integers."
						return null
					if start_idx < 0:
						start_idx = max(0, target.size() + start_idx)
					if end_idx < 0:
						end_idx = max(0, target.size() + end_idx)
					var result = []
					for si in range(start_idx, min(end_idx, target.size())):
						result.append(target[si])
					return result
		var index = _eval_expr(index_str, env, state)
		if state.ok and env.has(var_name):
			var target = env[var_name]
			if typeof(target) == TYPE_ARRAY and typeof(index) == TYPE_INT:
				if index >= 0 and index < target.size():
					return target[index]
				state.ok = false
				state.err = "Index " + str(index) + " out of range for array of size " + str(target.size()) + "."
				return null
	if env.has(s):
		return env[s]
	state.ok = false
	state.err = "Unknown variable or expression: " + s
	return null

func _call_func(fname, args, env, state):
	if not env.has(fname) or typeof(env[fname]) != TYPE_DICTIONARY:
		state.ok = false
		state.err = "Function not defined: " + fname
		return null
	var func_data = env[fname]
	var params = func_data.get("params", [])
	var body = func_data.get("body", [])
	if args.size() != params.size():
		state.ok = false
		state.err = "Function " + fname + " expects " + str(params.size()) + " arguments, got " + str(args.size())
		return null
	var local_env = env.duplicate()
	for i in range(params.size()):
		local_env[params[i]] = args[i]
	var func_state = { "ok": true, "err": "", "output": "" }
	for line in body:
		var s = line.strip_edges()
		if s.begins_with("return "):
			var r = s.substr(7).strip_edges()
			var val = _eval_expr(r, local_env, func_state)
			if not func_state.ok:
				state.ok = false
				state.err = func_state.err
				return null
			return val
		_exec_stmt(s, local_env, func_state)
		if not func_state.ok:
			state.ok = false
			state.err = func_state.err
			return null
	return null

func _parse_for(stripped):
	var rest = stripped.substr(4).strip_edges()
	var in_idx = rest.find(" in ")
	if in_idx == -1:
		return []
	var var_name = rest.substr(0, in_idx).strip_edges()
	var rest2 = rest.substr(in_idx + 4).strip_edges()
	var list_expr = rest2.substr(0, rest2.length() - 1).strip_edges() if rest2.ends_with(":") else rest2
	return [var_name, "in", list_expr]

func _split_comma(s):
	var result = []
	var depth = 0
	var current = ""
	for i in range(s.length()):
		var c = s[i]
		if c == "(" or c == "[":
			depth += 1
			current += c
		elif c == ")" or c == "]":
			depth -= 1
			current += c
		elif c == "," and depth == 0:
			result.append(current.strip_edges())
			current = ""
		else:
			current += c
	if current.strip_edges() != "":
		result.append(current.strip_edges())
	return result

func _split_print_args(s):
	var result = []
	var depth = 0
	var in_single = false
	var in_double = false
	var current = ""
	for i in range(s.length()):
		var c = s[i]
		if c == "'" and not in_double:
			in_single = not in_single
			current += c
		elif c == "\"" and not in_single:
			in_double = not in_double
			current += c
		elif c == "(" or c == "[":
			if not in_single and not in_double:
				depth += 1
			current += c
		elif c == ")" or c == "]":
			if not in_single and not in_double:
				depth -= 1
			current += c
		elif c == "," and depth == 0 and not in_single and not in_double:
			result.append(current.strip_edges())
			current = ""
		else:
			current += c
	if current.strip_edges() != "":
		result.append(current.strip_edges())
	return result

func _find_op(s, op):
	if op == ".":
		var idx = s.find(".")
		if idx > 0 and idx < s.length() - 1:
			return idx
		return -1
	var depth = 0
	for i in range(s.length()):
		var c = s[i]
		if depth == 0:
			if s.substr(i, op.length()) == op:
				return i
		if c == '(' or c == '[':
			depth += 1
		elif c == ')' or c == ']':
			depth -= 1
	return -1

func _is_numeric(v) -> bool:
	var t = typeof(v)
	return t == TYPE_INT or t == TYPE_FLOAT

func _type_name(t: int) -> String:
	match t:
		TYPE_NIL:       return "None"
		TYPE_BOOL:      return "bool"
		TYPE_INT:       return "int"
		TYPE_FLOAT:     return "float"
		TYPE_STRING:    return "str"
		TYPE_ARRAY:     return "list"
		TYPE_DICTIONARY: return "dict"
		_:              return "unknown"

func _count_ws(s):
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
