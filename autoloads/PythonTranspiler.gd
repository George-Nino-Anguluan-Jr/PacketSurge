extends Node

# ─────────────────────────────────────────────────────────────
# PythonTranspiler.gd
# A sandboxed Python-3-style interpreter written in pure GDScript.
# Runs anywhere (desktop, mobile, web, iOS) with zero external
# dependencies. Supports a broad Python subset:
#
#   statements : assignment (= += -= *= /= //= %= **=, chained,
#                tuple unpacking, index/dict targets), print,
#                if/elif/else, for/while, break/continue/pass,
#                return, def (incl. recursion & nested bodies),
#                import / from-import, del, inline comments,
#                semicolon-separated statements, inline suites.
#   expressions: ints, floats, strings (single/double/triple,
#                escapes, f-strings), bool/None, lists, tuples,
#                dicts, sets, list/dict/set comprehensions,
#                arithmetic (+ - * / // % **, py-style floor/mod),
#                comparisons (incl. chained, in / not in, is),
#                logic (and/or/not, operand-return semantics),
#                ternary, bitwise, unary, indexing/slicing
#                (negative, step), member access & method calls.
#   builtins   : len str int float bool list dict range enumerate
#                zip min max sum abs round sorted reversed any all
#                pow chr ord deque
#   modules    : math, random, collections.deque
#
# Errors are reported with line numbers. No external calls, no I/O,
# so player code is safe to run.
# ─────────────────────────────────────────────────────────────

const MAX_LOOP_ITERS  := 100000
const MAX_STATEMENTS  := 200000
const MAX_CALL_DEPTH  := 200

const BUILTIN_NAMES := [
	"len", "str", "int", "float", "bool", "list", "dict",
	"range", "enumerate", "zip", "min", "max", "sum", "abs",
	"round", "sorted", "reversed", "any", "all", "pow", "chr",
	"ord", "deque", "print",
]

func run_code(source: String) -> Dictionary:
	var lines = _normalize_lines(source)
	var env: Dictionary = {}
	var state = _new_state()
	_exec_block(lines, 0, 0, env, state)
	if not state.ok:
		return { "success": false, "output": "", "error": state.err }
	return { "success": true, "output": state.output.strip_edges(false, true), "error": "" }

func _new_state() -> Dictionary:
	return {
		"ok": true, "err": "", "line": 0, "output": "",
		"brk": false, "cnt": false, "ret": false, "retval": null,
		"ops": 0, "depth": 0,
	}

func _fail(state: Dictionary, msg: String) -> void:
	if state.ok:
		state.ok = false
		var line_txt = "Line %d: " % state.line if state.line > 0 else ""
		state.err = line_txt + msg

func _bump(state: Dictionary) -> bool:
	state.ops += 1
	if state.ops > MAX_STATEMENTS:
		_fail(state, "Program exceeded maximum operation count (%d)." % MAX_STATEMENTS)
		return false
	return true

# ── Pre-processing ──────────────────────────────────────────

func _normalize_lines(source: String) -> Array:
	var raw = source.split("\n")
	var out: Array = []
	var buf := ""
	var in_triple := ""
	for ln in raw:
		if in_triple != "":
			var close = ln.find(in_triple)
			if close == -1:
				buf += ln + "\\n"
				continue
			buf += ln.substr(0, close)
			out.append(buf + in_triple)
			buf = ""
			in_triple = ""
			var rest = ln.substr(close + 3)
			if rest.strip_edges() != "":
				out.append(rest)
			continue
		var idx_d = ln.find("\"\"\"")
		var idx_s = ln.find("'''")
		var open_idx := -1
		var which := ""
		if idx_d != -1 and (idx_s == -1 or idx_d < idx_s):
			open_idx = idx_d
			which = "\"\"\""
		elif idx_s != -1:
			open_idx = idx_s
			which = "'''"
		if open_idx == -1:
			out.append(ln)
			continue
		var after = ln.substr(open_idx + 3)
		var close = after.find(which)
		if close != -1:
			out.append(ln)
			continue
		buf = ln.substr(0, open_idx) + which
		buf += after + "\\n"
		in_triple = which
	return out

func _strip_inline_comment(s: String) -> String:
	var in_s := false
	var in_d := false
	var i := 0
	while i < s.length():
		var c = s[i]
		if c == "'" and not in_d:
			in_s = not in_s
		elif c == "\"" and not in_s:
			in_d = not in_d
		elif c == "#" and not in_s and not in_d:
			return s.substr(0, i)
		i += 1
	return s

func _count_ws(s: String) -> int:
	var n := 0
	for i in range(s.length()):
		var c = s[i]
		if c == " ":
			n += 1
		elif c == "\t":
			n += 4
		else:
			break
	return n

# ── Block execution ─────────────────────────────────────────

func _exec_block(lines: Array, idx: int, depth: int, env: Dictionary, state: Dictionary) -> int:
	var i = idx
	while i < lines.size() and state.ok and not state.brk and not state.cnt and not state.ret:
		var raw: String = lines[i]
		state.line = i + 1
		var stripped = raw.strip_edges()
		if stripped == "" or stripped.begins_with("#"):
			i += 1
			continue
		var lead = _count_ws(raw)
		if lead < depth * 4:
			break
		i = _exec_stmt_line(lines, i, depth, env, state)
		if not state.ok or state.brk or state.cnt or state.ret:
			break
	return i

func _exec_stmt_line(lines: Array, i: int, depth: int, env: Dictionary, state: Dictionary) -> int:
	var raw: String = lines[i]
	var stripped = _strip_inline_comment(raw).strip_edges()
	if stripped == "":
		return i + 1

	if stripped.ends_with(":"):
		return _exec_header_blocks(lines, i, depth, env, state, stripped)

	# Inline suite:  if cond: stmt  /  while cond: stmt  /  for x in y: stmt
	var colon = _find_colon(stripped)
	if colon != -1 and _is_header_prefix(stripped, colon):
		var head = stripped.substr(0, colon).strip_edges()
		var body = stripped.substr(colon + 1).strip_edges()
		var synthetic: Array = [head + ":", "\t".repeat(depth + 1) + body]
		_exec_header_blocks(synthetic, 0, depth, env, state, head + ":")
		return i + 1

	if not _bump(state):
		return i + 1
	for part in _split_top(stripped, ";"):
		if not state.ok or state.brk or state.cnt or state.ret:
			break
		var st = part.strip_edges()
		if st == "" or st.begins_with("#"):
			continue
		_exec_simple(st, env, state)
	return i + 1

func _find_colon(s: String) -> int:
	var in_s := false
	var in_d := false
	var depth := 0
	for i in range(s.length()):
		var c = s[i]
		if c == "'" and not in_d:
			in_s = not in_s
		elif c == "\"" and not in_s:
			in_d = not in_d
		if not in_s and not in_d:
			if c == "(" or c == "[" or c == "{":
				depth += 1
			elif c == ")" or c == "]" or c == "}":
				depth -= 1
			elif c == ":" and depth == 0:
				return i
	return -1

func _is_header_prefix(s: String, colon: int) -> bool:
	var head = s.substr(0, colon).strip_edges()
	return head.begins_with("if ") or head.begins_with("while ") or head.begins_with("for ") or head.begins_with("def ")

func _exec_header_blocks(lines: Array, i: int, depth: int, env: Dictionary, state: Dictionary, stripped: String) -> int:
	if stripped.begins_with("def "):
		return _exec_def(lines, i, depth, env, state, stripped)
	if stripped.begins_with("if "):
		var cond = stripped.substr(3, stripped.length() - 4).strip_edges()
		var cond_val = _eval_expr(cond, env, state)
		if not state.ok:
			return lines.size()
		var header_indent = _count_ws(lines[i])
		return _exec_if_chain(lines, i + 1, depth + 1, env, state, _truthy(cond_val), header_indent)
	if stripped.begins_with("elif ") or stripped.begins_with("else:"):
		var header_indent = _count_ws(lines[i])
		return _skip_block(lines, i + 1, header_indent)
	if stripped.begins_with("for ") and " in " in stripped:
		var header_indent = _count_ws(lines[i])
		return _exec_for(lines, i, depth, env, state, stripped, header_indent)
	if stripped.begins_with("while "):
		var header_indent = _count_ws(lines[i])
		return _exec_while(lines, i, depth, env, state, stripped, header_indent)
	_fail(state, "Unknown block statement: " + stripped)
	return lines.size()

func _exec_def(lines: Array, i: int, depth: int, env: Dictionary, state: Dictionary, stripped: String) -> int:
	var parts = stripped.split("(")
	if parts.size() < 2:
		_fail(state, "Invalid function definition.")
		return lines.size()
	var fname = parts[0].substr(4).strip_edges()
	if not fname.is_valid_identifier():
		_fail(state, "Invalid function name: " + fname)
		return lines.size()
	var params_str = parts[1].substr(0, parts[1].length() - 2).strip_edges()
	var params: Array = []
	var defaults: Dictionary = {}
	if params_str != "":
		for p in _split_top(params_str, ","):
			p = p.strip_edges()
			if "=" in p and not (p.begins_with("'") or p.begins_with("\"")):
				# Default value: p = "y=10"
				var eq = _find_top_eq(p)
				if eq != -1:
					var name = p.substr(0, eq).strip_edges()
					var default_expr = p.substr(eq + 1).strip_edges()
					params.append(name)
					defaults[name] = default_expr
				else:
					params.append(p)
			else:
				params.append(p)
	var body = _collect_block(lines, i + 1, depth + 1)
	env[fname] = { "params": params, "body": body, "defaults": defaults }
	var header_indent = _count_ws(lines[i])
	return _skip_block(lines, i + 1, header_indent)

func _collect_block(lines: Array, start: int, depth: int) -> Array:
	var result: Array = []
	var i = start
	while i < lines.size():
		var raw: String = lines[i]
		if raw.strip_edges() == "":
			i += 1
			continue
		if _count_ws(raw) < depth * 4:
			break
		result.append(raw)
		i += 1
	return result

# Skip lines until we find a line at or before the header's indentation.
# header_indent is the whitespace count of the header line (e.g., "def", "if", "for").
func _skip_block(lines: Array, start: int, header_indent: int) -> int:
	var i = start
	while i < lines.size():
		var raw: String = lines[i]
		if raw.strip_edges() == "":
			i += 1
			continue
		if _count_ws(raw) <= header_indent:
			return i
		i += 1
	return i

func _skip_chain(lines: Array, start: int, header_indent: int) -> int:
	var i = _skip_block(lines, start, header_indent)
	while i < lines.size():
		var raw: String = lines[i]
		var stripped = raw.strip_edges()
		if stripped == "":
			i += 1
			continue
		if _count_ws(raw) > header_indent:
			break
		if stripped.begins_with("elif ") or stripped.begins_with("else:"):
			i = _skip_block(lines, i + 1, header_indent)
			continue
		break
	return i

func _exec_if_chain(lines: Array, start: int, depth: int, env: Dictionary, state: Dictionary, cond_val, header_indent: int) -> int:
	var i = start
	if cond_val:
		_exec_block(lines, i, depth, env, state)
		if not state.ok or state.brk or state.cnt or state.ret:
			return lines.size()
		return _skip_chain(lines, i, depth)
	var after = _skip_block(lines, i, header_indent)
	if after >= lines.size():
		return after
	var raw: String = lines[after]
	var stripped = raw.strip_edges()
	if _count_ws(raw) <= header_indent:
		if stripped.begins_with("elif "):
			var cond = stripped.substr(5, stripped.length() - 6).strip_edges()
			var val = _eval_expr(cond, env, state)
			if not state.ok:
				return lines.size()
			return _exec_if_chain(lines, after + 1, depth, env, state, _truthy(val), header_indent)
		if stripped.begins_with("else:"):
			_exec_block(lines, after + 1, depth, env, state)
			if not state.ok or state.brk or state.cnt or state.ret:
				return lines.size()
			return _skip_block(lines, after + 1, header_indent)
	return after

func _exec_for(lines: Array, i: int, depth: int, env: Dictionary, state: Dictionary, stripped: String, header_indent: int) -> int:
	var rest = stripped.substr(4).strip_edges()
	if rest.ends_with(":"):
		rest = rest.substr(0, rest.length() - 1).strip_edges()
	var in_idx = rest.find(" in ")
	if in_idx == -1:
		_fail(state, "Invalid for loop syntax.")
		return lines.size()
	var var_part = rest.substr(0, in_idx).strip_edges()
	var iter_expr = rest.substr(in_idx + 4).strip_edges()
	var iterable = _eval_expr(iter_expr, env, state)
	if not state.ok:
		return lines.size()
	var items = _iter_items(iterable, state)
	if not state.ok:
		return lines.size()
	var body_start = i + 1
	var iter_count := 0
	for element in items:
		if not state.ok:
			break
		iter_count += 1
		if iter_count > MAX_LOOP_ITERS:
			_fail(state, "Loop exceeded maximum iterations (%d)." % MAX_LOOP_ITERS)
			break
		if not _assign_loop_var(var_part, element, env, state):
			break
		_exec_block(lines, body_start, depth + 1, env, state)
		if not state.ok:
			break
		if state.brk:
			state.brk = false
			break
		if state.cnt:
			state.cnt = false
			continue
		if state.ret:
			break
	return _advance_to(lines, body_start, header_indent)

func _assign_loop_var(var_part: String, element, env: Dictionary, state: Dictionary) -> bool:
	if "," in var_part:
		var targets = _split_top(var_part, ",")
		var values = element if typeof(element) == TYPE_ARRAY else [element]
		if targets.size() != values.size():
			_fail(state, "Cannot unpack %d values into %d loop variables." % [values.size(), targets.size()])
			return false
		for k in range(targets.size()):
			_assign_single_target(targets[k].strip_edges(), values[k], env, state)
			if not state.ok:
				return false
		return true
	env[var_part.strip_edges()] = element
	return true

func _exec_while(lines: Array, i: int, depth: int, env: Dictionary, state: Dictionary, stripped: String, header_indent: int) -> int:
	var cond = stripped.substr(6, stripped.length() - 7).strip_edges()
	var body_start = i + 1
	var iter_count := 0
	while state.ok:
		var val = _eval_expr(cond, env, state)
		if not state.ok:
			return lines.size()
		if not _truthy(val):
			break
		iter_count += 1
		if iter_count > MAX_LOOP_ITERS:
			_fail(state, "Loop exceeded maximum iterations (%d)." % MAX_LOOP_ITERS)
			break
		_exec_block(lines, body_start, depth + 1, env, state)
		if not state.ok:
			break
		if state.brk:
			state.brk = false
			break
		if state.cnt:
			state.cnt = false
			continue
		if state.ret:
			break
	return _advance_to(lines, body_start, header_indent)

func _advance_to(lines: Array, start: int, header_indent: int) -> int:
	var i = start
	while i < lines.size():
		var raw: String = lines[i]
		if raw.strip_edges() == "":
			i += 1
			continue
		if _count_ws(raw) <= header_indent:
			return i
		i += 1
	return i

func _iter_items(iterable, state: Dictionary) -> Array:
	match typeof(iterable):
		TYPE_ARRAY:
			return iterable
		TYPE_DICTIONARY:
			return iterable.keys()
		TYPE_STRING:
			var out: Array = []
			for i in range(iterable.length()):
				out.append(iterable.substr(i, 1))
			return out
		TYPE_INT:
			return _py_range(0, iterable, 1, state)
		TYPE_NIL:
			_fail(state, "'NoneType' object is not iterable.")
			return []
		_:
			_fail(state, "%s object is not iterable." % _type_name(typeof(iterable)))
			return []

func _py_range(start, stop, step, state: Dictionary) -> Array:
	var out: Array = []
	if step == 0:
		_fail(state, "range() arg 3 must not be zero.")
		return out
	var i = start
	if step > 0:
		while i < stop:
			out.append(i)
			i += step
	else:
		while i > stop:
			out.append(i)
			i += step
	return out

# ── Simple statements ───────────────────────────────────────

func _exec_simple(st: String, env: Dictionary, state: Dictionary) -> void:
	if st == "pass":
		return
	if st == "break":
		state.brk = true
		return
	if st == "continue":
		state.cnt = true
		return
	if st.begins_with("return"):
		_exec_return(st, env, state)
		return
	if st.begins_with("import "):
		_exec_import(st, env, state)
		return
	if st.begins_with("from "):
		_exec_from_import(st, env, state)
		return
	if st.begins_with("del "):
		_exec_del(st, env, state)
		return
	if st.begins_with("print(") and st.ends_with(")"):
		_exec_print(st, env, state)
		return
	if _is_assignment(st):
		_exec_assignment(st, env, state)
		return
	# Bare expression statement (function call etc.) - no output.
	_eval_expr(st, env, state)

func _exec_return(st: String, env: Dictionary, state: Dictionary) -> void:
	if st == "return":
		state.ret = true
		state.retval = null
		return
	var r = st.substr(6).strip_edges()
	if _find_top_comma(r) != -1:
		var parts = _split_top(r, ",")
		var vals: Array = []
		for p in parts:
			vals.append(_eval_expr(p.strip_edges(), env, state))
			if not state.ok:
				return
		state.ret = true
		state.retval = vals
		return
	var val = _eval_expr(r, env, state)
	if not state.ok:
		return
	state.ret = true
	state.retval = val

func _is_assignment(st: String) -> bool:
	if "=" not in st:
		return false
	var in_s := false
	var in_d := false
	var depth := 0
	for i in range(st.length()):
		var c = st[i]
		if c == "'" and not in_d:
			in_s = not in_s
		elif c == "\"" and not in_s:
			in_d = not in_d
		if not in_s and not in_d:
			if c == "(" or c == "[" or c == "{":
				depth += 1
			elif c == ")" or c == "]" or c == "}":
				depth -= 1
			elif c == "=" and depth == 0:
				# Skip "=" that is part of a comparison ("==", "!=", "<=", ">=")
				# but still treat compound assignment ("+=", "//=", ...) as assignment.
				if i > 0 and (st[i - 1] in "=!<>"):
					continue
				if i + 1 < st.length() and st[i + 1] == "=":
					continue
				return true
	return false

func _exec_assignment(st: String, env: Dictionary, state: Dictionary) -> void:
	for op in ["**=", "//=", "+=", "-=", "*=", "/=", "%="]:
		if op in st:
			var idx = _find_top_op(st, op)
			if idx != -1:
				var lhs = st.substr(0, idx).strip_edges()
				var rhs = st.substr(idx + op.length()).strip_edges()
				var cur = _eval_expr(lhs, env, state)
				if not state.ok:
					return
				var rv = _eval_expr(rhs, env, state)
				if not state.ok:
					return
				var new_val: Variant
				match op:
					"**=":
						new_val = _py_pow(cur, rv, state)
					"//=":
						new_val = _apply_arith("//", cur, rv, state, true)
					_:
						new_val = _apply_arith(op[0], cur, rv, state, false)
				if not state.ok:
					return
				_assign_single_target(lhs, new_val, env, state)
				return
	var eq = _find_top_eq(st)
	if eq == -1:
		_fail(state, "Invalid assignment: " + st)
		return
	var lhs = st.substr(0, eq).strip_edges()
	var rhs = st.substr(eq + 1).strip_edges()

	# Chained assignment: a = b = expr
	if _find_top_eq(lhs) != -1:
		var val = _eval_expr(rhs, env, state)
		if not state.ok:
			return
		var chain = lhs
		while true:
			var c_eq = _find_top_eq(chain)
			if c_eq == -1:
				_assign_single_target(chain, val, env, state)
				break
			_assign_single_target(chain.substr(0, c_eq).strip_edges(), val, env, state)
			if not state.ok:
				return
			chain = chain.substr(c_eq + 1).strip_edges()
		return

	# Tuple unpacking: a, b = c, d
	if _find_top_comma(lhs) != -1:
		var lhs_targets = _split_top(lhs, ",")
		var rhs_values = _split_top(rhs, ",") if _find_top_comma(rhs) != -1 else [rhs]
		if lhs_targets.size() != rhs_values.size():
			_fail(state, "Assignment mismatch: %d targets, %d values." % [lhs_targets.size(), rhs_values.size()])
			return
		var tmp: Array = []
		for r in rhs_values:
			tmp.append(_eval_expr(r.strip_edges(), env, state))
			if not state.ok:
				return
		for k in range(lhs_targets.size()):
			_assign_single_target(lhs_targets[k].strip_edges(), tmp[k], env, state)
			if not state.ok:
				return
		return

	var val = _eval_expr(rhs, env, state)
	if not state.ok:
		return
	_assign_single_target(lhs, val, env, state)

func _find_top_eq(s: String) -> int:
	var in_s := false
	var in_d := false
	var depth := 0
	var last := -1
	for i in range(s.length()):
		var c = s[i]
		if c == "'" and not in_d:
			in_s = not in_s
		elif c == "\"" and not in_s:
			in_d = not in_d
		if not in_s and not in_d:
			if c == "(" or c == "[" or c == "{":
				depth += 1
			elif c == ")" or c == "]" or c == "}":
				depth -= 1
			elif c == "=" and depth == 0:
				if i > 0 and (s[i - 1] in "=!<>+-*/%&|^"):
					continue
				if i + 1 < s.length() and s[i + 1] == "=":
					continue
				last = i
	return last

func _find_top_comma(s: String) -> int:
	var in_s := false
	var in_d := false
	var depth := 0
	for i in range(s.length()):
		var c = s[i]
		if c == "'" and not in_d:
			in_s = not in_s
		elif c == "\"" and not in_s:
			in_d = not in_d
		if not in_s and not in_d:
			if c == "(" or c == "[" or c == "{":
				depth += 1
			elif c == ")" or c == "]" or c == "}":
				depth -= 1
			elif c == "," and depth == 0:
				return i
	return -1

func _assign_single_target(target: String, val, env: Dictionary, state: Dictionary) -> void:
	var lb = target.find("[")
	if lb != -1 and target.ends_with("]"):
		var vname = target.substr(0, lb).strip_edges()
		var idx_str = target.substr(lb + 1, target.length() - lb - 2).strip_edges()
		if not env.has(vname):
			_fail(state, "Name '" + vname + "' is not defined.")
			return
		var idx = _eval_expr(idx_str, env, state)
		if not state.ok:
			return
		var obj = env[vname]
		if typeof(obj) == TYPE_ARRAY:
			if typeof(idx) != TYPE_INT:
				_fail(state, "List indices must be integers, not %s." % _type_name(typeof(idx)))
				return
			var real = idx if idx >= 0 else obj.size() + idx
			if real < 0 or real >= obj.size():
				_fail(state, "Index %d out of range for list of size %d." % [idx, obj.size()])
				return
			obj[real] = val
			return
		if typeof(obj) == TYPE_DICTIONARY:
			obj[idx] = val
			return
		if typeof(obj) == TYPE_STRING:
			_fail(state, "'str' object does not support item assignment.")
			return
		_fail(state, "Cannot assign to index of %s." % _type_name(typeof(obj)))
		return
	if target.is_valid_identifier():
		env[target] = val
		return
	_fail(state, "Invalid assignment target: '" + target + "'.")

func _exec_del(st: String, env: Dictionary, state: Dictionary) -> void:
	var target = st.substr(4).strip_edges()
	var lb = target.find("[")
	if lb != -1 and target.ends_with("]"):
		var vname = target.substr(0, lb).strip_edges()
		var idx = _eval_expr(target.substr(lb + 1, target.length() - lb - 2).strip_edges(), env, state)
		if not state.ok:
			return
		if not env.has(vname):
			_fail(state, "Name '" + vname + "' is not defined.")
			return
		var obj = env[vname]
		if typeof(obj) == TYPE_ARRAY:
			if typeof(idx) != TYPE_INT:
				_fail(state, "List indices must be integers.")
				return
			var real = idx if idx >= 0 else obj.size() + idx
			if real < 0 or real >= obj.size():
				_fail(state, "Index %d out of range." % idx)
				return
			obj.remove_at(real)
			return
		if typeof(obj) == TYPE_DICTIONARY:
			obj.erase(idx)
			return
	_fail(state, "Cannot delete '" + target + "'.")

# ── print ───────────────────────────────────────────────────

func _exec_print(st: String, env: Dictionary, state: Dictionary) -> void:
	var inner = st.substr(6, st.length() - 7).strip_edges()
	var parts = _split_call_args(inner)
	var sep := " "
	var end := "\n"
	var vals: Array = []
	for p in parts:
		var kv = _split_kwarg(p)
		if kv.size() == 2:
			match kv[0]:
				"sep":
					sep = str(_eval_expr(kv[1], env, state))
					if not state.ok:
						return
				"end":
					end = str(_eval_expr(kv[1], env, state))
					if not state.ok:
						return
				_:
					_fail(state, "print() got an unexpected keyword argument '" + kv[0] + "'.")
					return
		else:
			vals.append(_eval_expr(p, env, state))
			if not state.ok:
				return
	var out := ""
	for v in vals:
		if out != "":
			out += sep
		out += _to_str(v)
	state.output += out + end

func _split_kwarg(p: String) -> Array:
	var eq = _find_top_eq(p)
	if eq == -1:
		return []
	var name = p.substr(0, eq).strip_edges()
	if not name.is_valid_identifier():
		return []
	return [name, p.substr(eq + 1).strip_edges()]

# ── import ──────────────────────────────────────────────────

func _exec_import(st: String, env: Dictionary, state: Dictionary) -> void:
	var mod_name = st.substr(7).strip_edges()
	if mod_name == "math":
		env["math"] = _make_math_module()
		return
	if mod_name == "random":
		env["random"] = _make_random_module()
		return
	_fail(state, "Module '" + mod_name + "' is not supported. Available: math, random.")

func _exec_from_import(st: String, env: Dictionary, state: Dictionary) -> void:
	var rest = st.substr(5).strip_edges()
	if " import " not in rest:
		_fail(state, "Invalid import statement.")
		return
	var parts = rest.split(" import ")
	var mod_name = parts[0].strip_edges()
	var items_str = parts[1].strip_edges()
	var module: Dictionary = {}
	if mod_name == "math":
		module = _make_math_module()
	elif mod_name == "random":
		module = _make_random_module()
	elif mod_name == "collections":
		module["deque"] = Callable(self, "_builtin_deque")
	else:
		_fail(state, "Module '" + mod_name + "' is not supported. Available: math, random, collections.deque.")
		return
	for item in items_str.split(","):
		var name = item.strip_edges()
		if name == "*":
			for k in module:
				env[k] = module[k]
		elif module.has(name):
			env[name] = module[name]
		else:
			_fail(state, "Cannot import name '" + name + "' from " + mod_name + ".")

func _make_math_module() -> Dictionary:
	var m := {
		"pi": PI,
		"e": exp(1),
		"sqrt": Callable(self, "_b_sqrt"),
		"floor": Callable(self, "_b_floor"),
		"ceil": Callable(self, "_b_ceil"),
		"fabs": Callable(self, "_b_abs"),
		"pow": Callable(self, "_b_pow"),
		"exp": Callable(self, "_b_exp"),
		"log": Callable(self, "_b_log"),
		"log10": Callable(self, "_b_log10"),
		"sin": Callable(self, "_b_sin"),
		"cos": Callable(self, "_b_cos"),
		"tan": Callable(self, "_b_tan"),
		"asin": Callable(self, "_b_asin"),
		"acos": Callable(self, "_b_acos"),
		"atan": Callable(self, "_b_atan"),
		"hypot": Callable(self, "_b_hypot"),
		"degrees": Callable(self, "_b_degrees"),
		"radians": Callable(self, "_b_radians"),
	}
	m["_is_module"] = true
	return m

func _make_random_module() -> Dictionary:
	var m := {
		"random": Callable(self, "_b_random"),
		"randint": Callable(self, "_b_randint"),
		"randrange": Callable(self, "_b_randrange"),
		"choice": Callable(self, "_b_choice"),
		"shuffle": Callable(self, "_b_shuffle"),
		"sample": Callable(self, "_b_sample"),
		"uniform": Callable(self, "_b_uniform"),
	}
	m["_is_module"] = true
	return m

# ── Expression evaluation ───────────────────────────────────

func _eval_expr(expr, env: Dictionary, state: Dictionary) -> Variant:
	var s = expr.strip_edges()
	if s == "":
		_fail(state, "Empty expression.")
		return null

	# Ternary:  A if COND else B
	var ti = _find_top_op(s, " if ")
	if ti != -1:
		var after = _find_top_op(s.substr(ti + 4), " else ")
		if after != -1:
			var a = s.substr(0, ti).strip_edges()
			var cond = s.substr(ti + 4, after).strip_edges()
			var b = s.substr(ti + 4 + after + 6).strip_edges()
			var cv = _eval_expr(cond, env, state)
			if not state.ok:
				return null
			return _eval_expr(a if _truthy(cv) else b, env, state)

	# string literals (incl. f-strings)
	if (s.begins_with("f\"") and s.ends_with("\"")) or (s.begins_with("f'") and s.ends_with("'")):
		return _parse_fstring(s.substr(1), env, state)
	if (s.begins_with("\"") and s.ends_with("\"")) or (s.begins_with("'") and s.ends_with("'")):
		return _parse_string_literal(s)

	# numbers
	if s.is_valid_int():
		return int(s)
	if s.is_valid_float():
		return float(s)

	if s == "True" or s == "true":
		return true
	if s == "False" or s == "false":
		return false
	if s == "None" or s == "null":
		return null

	# comprehensions
	if s.begins_with("[") and s.ends_with("]") and s.find(" for ") != -1:
		return _list_comp(s, env, state)
	if s.begins_with("{") and s.ends_with("}") and s.find(" for ") != -1:
		return _dict_comp(s, env, state)

	# list literal
	if s.begins_with("[") and s.ends_with("]") and _first_bracket_is_outer(s):
		var inner = s.substr(1, s.length() - 2).strip_edges()
		var arr: Array = []
		if inner != "":
			for item in _split_top(inner, ","):
				arr.append(_eval_expr(item.strip_edges(), env, state))
				if not state.ok:
					return null
		return arr

	# tuple literal (a, b)
	if s.begins_with("(") and s.ends_with(")") and _first_bracket_is_outer(s):
		var inner = s.substr(1, s.length() - 2).strip_edges()
		if _find_top_comma(inner) != -1:
			var tup: Array = []
			for item in _split_top(inner, ","):
				tup.append(_eval_expr(item.strip_edges(), env, state))
				if not state.ok:
					return null
			return tup
		return _eval_expr(inner, env, state)

	# dict / set literal
	if s.begins_with("{") and s.ends_with("}") and _first_bracket_is_outer(s):
		return _eval_map_literal(s, env, state)

	# logical or
	var or_i = _find_top_op(s, " or ")
	if or_i != -1:
		var left = _eval_expr(s.substr(0, or_i).strip_edges(), env, state)
		if not state.ok:
			return null
		if _truthy(left):
			return left
		return _eval_expr(s.substr(or_i + 4).strip_edges(), env, state)

	# logical and
	var and_i = _find_top_op(s, " and ")
	if and_i != -1:
		var left = _eval_expr(s.substr(0, and_i).strip_edges(), env, state)
		if not state.ok:
			return null
		if not _truthy(left):
			return left
		return _eval_expr(s.substr(and_i + 5).strip_edges(), env, state)

	# not (prefix)
	if s.begins_with("not "):
		var val = _eval_expr(s.substr(4).strip_edges(), env, state)
		if not state.ok:
			return null
		return not _truthy(val)

	# bitwise ops (ints)
	var or_bit = _find_last_binary(s, ["|"])
	if or_bit.size() == 2:
		return _eval_bin_int(s, or_bit, env, state)
	var xor_bit = _find_last_binary(s, ["^"])
	if xor_bit.size() == 2:
		return _eval_bin_int(s, xor_bit, env, state)
	var and_bit = _find_last_binary(s, ["&"])
	if and_bit.size() == 2:
		return _eval_bin_int(s, and_bit, env, state)
	var shift = _find_last_binary(s, ["<<", ">>"])
	if shift.size() == 2:
		return _eval_bin_int(s, shift, env, state)

	# comparisons (incl. chained, in, is)
	if _find_comparison(s).size() == 2:
		return _eval_comparison_chain(s, env, state)

	# additive: prefer the rightmost +/- that is NOT a leading unary sign.
	# A leading "-" or "+" at idx 0 (or right after an operator) is unary and
	# must not be treated as a binary op with an empty LHS.
	var add = []
	var add_idx = -1
	for _aop in ["+", "-"]:
		var _ai = _find_top_op(s, _aop)
		if _ai > 0 and (add_idx == -1 or _ai > add_idx):
			add_idx = _ai
			add = [_aop, _ai]
	if add.size() == 2:
		var idx = add[1]
		var op = add[0]
		var left = _eval_expr(s.substr(0, idx).strip_edges(), env, state)
		if not state.ok:
			return null
		var right = _eval_expr(s.substr(idx + op.length()).strip_edges(), env, state)
		if not state.ok:
			return null
		if op == "+":
			return _apply_add(left, right, state)
		return _apply_arith("-", left, right, state, false)

	# power (tighter than multiplicative; right-assoc)
	var pow_i = _find_top_op(s, "**")
	if pow_i != -1:
		var left = _eval_expr(s.substr(0, pow_i).strip_edges(), env, state)
		if not state.ok:
			return null
		var right = _eval_expr(s.substr(pow_i + 2).strip_edges(), env, state)
		if not state.ok:
			return null
		return _py_pow(left, right, state)

	# multiplicative (last among * / // %)
	var mult = _find_multiplicative(s)
	if mult.size() == 2:
		var op = mult[0]
		var idx = mult[1]
		var left = _eval_expr(s.substr(0, idx).strip_edges(), env, state)
		if not state.ok:
			return null
		var right = _eval_expr(s.substr(idx + op.length()).strip_edges(), env, state)
		if not state.ok:
			return null
		return _apply_arith(op, left, right, state, op == "//")

	# unary
	if s.begins_with("-") and s.length() > 1:
		var v = _eval_expr(s.substr(1).strip_edges(), env, state)
		if not state.ok:
			return null
		if not _is_num(v):
			_fail(state, "Bad operand type for unary -: '%s'." % _type_name(typeof(v)))
			return null
		return -v
	if s.begins_with("+") and s.length() > 1:
		return _eval_expr(s.substr(1).strip_edges(), env, state)
	if s.begins_with("~"):
		var v = _eval_expr(s.substr(1).strip_edges(), env, state)
		if not state.ok:
			return null
		if typeof(v) != TYPE_INT:
			_fail(state, "Bad operand type for unary ~: '%s'." % _type_name(typeof(v)))
			return null
		return ~v

	# indexing / member access / calls
	if s.find("[") != -1 and s.ends_with("]"):
		return _eval_index(s, env, state)
	if _find_top_op(s, ".") != -1:
		return _eval_member(s, env, state)
	if s.find("(") != -1 and s.ends_with(")"):
		return _eval_call(s, env, state)

	# variable
	if env.has(s):
		return env[s]
	_fail(state, "Name '" + s + "' is not defined.")
	return null

func _eval_map_literal(s: String, env: Dictionary, state: Dictionary) -> Variant:
	var inner = s.substr(1, s.length() - 2).strip_edges()
	if inner == "":
		return {}
	var first_comma = _find_top_comma(inner)
	var first_colon = _find_top_colon(inner)
	if first_colon == -1 or (first_comma != -1 and first_comma < first_colon):
		var out: Array = []
		for item in _split_top(inner, ","):
			var v = _eval_expr(item.strip_edges(), env, state)
			if not state.ok:
				return null
			if not out.has(v):
				out.append(v)
		return out
	var d: Dictionary = {}
	for pair in _split_top(inner, ","):
		var colon = _find_top_colon(pair)
		if colon == -1:
			_fail(state, "Invalid dict literal.")
			return null
		var k = _eval_expr(pair.substr(0, colon).strip_edges(), env, state)
		if not state.ok:
			return null
		var v = _eval_expr(pair.substr(colon + 1).strip_edges(), env, state)
		if not state.ok:
			return null
		d[k] = v
	return d

func _eval_bin_int(s: String, split: Array, env: Dictionary, state: Dictionary) -> Variant:
	var idx = split[1]
	var op = split[0]
	var left = _eval_expr(s.substr(0, idx).strip_edges(), env, state)
	if not state.ok:
		return null
	var right = _eval_expr(s.substr(idx + op.length()).strip_edges(), env, state)
	if not state.ok:
		return null
	if typeof(left) != TYPE_INT or typeof(right) != TYPE_INT:
		_fail(state, "Operands for '%s' must be integers, got %s and %s." % [op, _type_name(typeof(left)), _type_name(typeof(right))])
		return null
	match op:
		"|": return left | right
		"^": return left ^ right
		"&": return left & right
		"<<": return left << right
		">>": return left >> right
	return null

func _find_matching_open(s: String) -> int:
	var depth := 0
	var in_s := false
	var in_d := false
	var last_open := -1
	for i in range(s.length()):
		var c = s[i]
		if c == "'" and not in_d:
			in_s = not in_s
		elif c == "\"" and not in_s:
			in_d = not in_d
		if not in_s and not in_d:
			if c == "[":
				depth += 1
				last_open = i
			elif c == "]":
				depth -= 1
				if depth == 0:
					return last_open
	return last_open

# Returns the position of the "[" whose matching "]" is the last char of s,
# so that the caller can split s into base and index_str. Returns -1 if no
# such pair exists (e.g. plain list literal or unbalanced).
func _find_subscript_open(s: String) -> int:
	var depth := 0
	var current_open := -1
	var result := -1
	var in_s := false
	var in_d := false
	for i in range(s.length()):
		var c = s[i]
		if c == "'" and not in_d:
			in_s = not in_s
		elif c == "\"" and not in_s:
			in_d = not in_d
		if not in_s and not in_d:
			if c == "[":
				depth += 1
				current_open = i
			elif c == "]":
				if depth > 0:
					depth -= 1
					if depth == 0:
						result = current_open
	return result

func _eval_index(s: String, env: Dictionary, state: Dictionary) -> Variant:
	var open_i = _find_subscript_open(s)
	if open_i == -1:
		_fail(state, "Invalid subscript.")
		return null
	var base = s.substr(0, open_i).strip_edges()
	var index_str = s.substr(open_i + 1, s.length() - open_i - 2).strip_edges()
	var obj = _eval_expr(base, env, state)
	if not state.ok:
		return null
	if typeof(obj) == TYPE_STRING:
		return _string_index(obj, index_str, env, state)
	if typeof(obj) == TYPE_DICTIONARY:
		var key = _eval_expr(index_str, env, state)
		if not state.ok:
			return null
		if not obj.has(key):
			_fail(state, "KeyError: %s" % _repr_value(key))
			return null
		return obj[key]
	if typeof(obj) == TYPE_ARRAY:
		if index_str.find(":") != -1:
			return _array_slice(obj, index_str, env, state)
		var idx = _eval_expr(index_str, env, state)
		if not state.ok:
			return null
		if typeof(idx) != TYPE_INT:
			_fail(state, "List indices must be integers, not %s." % _type_name(typeof(idx)))
			return null
		var real = idx if idx >= 0 else obj.size() + idx
		if real < 0 or real >= obj.size():
			_fail(state, "Index %d out of range for list of size %d." % [idx, obj.size()])
			return null
		return obj[real]
	_fail(state, "'%s' object is not subscriptable." % _type_name(typeof(obj)))
	return null

func _array_slice(arr: Array, index_str: String, env: Dictionary, state: Dictionary) -> Array:
	var parts = index_str.split(":")
	var start_s = parts[0].strip_edges()
	var end_s = parts[1].strip_edges() if parts.size() > 1 else ""
	var step_s = parts[2].strip_edges() if parts.size() > 2 else ""
	var size: int = arr.size()
	var step: int = 1
	if step_s != "":
		var sv = _eval_expr(step_s, env, state)
		if not state.ok:
			return []
		step = int(sv) if typeof(sv) == TYPE_INT else 1
		if step == 0:
			_fail(state, "slice step cannot be zero.")
			return []
	var start: int
	var end: int
	if step > 0:
		if start_s != "":
			var sv = _eval_expr(start_s, env, state)
			if not state.ok:
				return []
			start = int(sv) if typeof(sv) == TYPE_INT else 0
		else:
			start = 0
		if end_s != "":
			var ev = _eval_expr(end_s, env, state)
			if not state.ok:
				return []
			end = int(ev) if typeof(ev) == TYPE_INT else size
		else:
			end = size
	else:
		if start_s != "":
			var sv = _eval_expr(start_s, env, state)
			if not state.ok:
				return []
			start = int(sv) if typeof(sv) == TYPE_INT else size - 1
		else:
			start = size - 1
		if end_s != "":
			var ev = _eval_expr(end_s, env, state)
			if not state.ok:
				return []
			end = int(ev) if typeof(ev) == TYPE_INT else -1
		else:
			end = -1
	start = _norm_index(start, size)
	if step < 0 and end < 0:
		pass
	else:
		end = _norm_index(end, size)
	var out: Array = []
	if step > 0:
		var i = start
		while i < end:
			out.append(arr[i])
			i += step
	else:
		var i = start
		while i > end:
			out.append(arr[i])
			i += step
	return out

func _norm_index(i: int, size: int) -> int:
	if i < 0:
		i = size + i
	return clampi(i, 0, size)

func _string_index(s: String, index_str: String, env: Dictionary, state: Dictionary):
	var colon = index_str.find(":")
	if colon != -1:
		var parts = index_str.split(":")
		var start_s = parts[0].strip_edges()
		var end_s = parts[1].strip_edges() if parts.size() > 1 else ""
		var step_s = parts[2].strip_edges() if parts.size() > 2 else ""
		var step: int = 1
		if step_s != "":
			var sv = _eval_expr(step_s, env, state)
			if not state.ok:
				return ""
			step = int(sv) if typeof(sv) == TYPE_INT else 1
			if step == 0:
				_fail(state, "slice step cannot be zero.")
				return ""
		var size: int = s.length()
		var start: int = 0
		var end: int = size if step > 0 else size - 1
		if start_s != "":
			var sv = _eval_expr(start_s, env, state)
			if not state.ok:
				return ""
			start = int(sv) if typeof(sv) == TYPE_INT else size
		if end_s != "":
			var ev = _eval_expr(end_s, env, state)
			if not state.ok:
				return ""
			if step > 0:
				end = int(ev) if typeof(ev) == TYPE_INT else size
			else:
				end = int(ev) if typeof(ev) == TYPE_INT else size - 1
		if step > 0:
			start = _norm_index(start, size)
			end = _norm_index(end, size)
			var out := ""
			for i in range(start, end, step):
				out += s[i]
			return out
		# negative step
		start = _norm_index(start, size)
		end = _norm_index(end, size)
		var out := ""
		var i := start
		while i > end:
			out += s[i]
			i += step
		return out
	var idx = _eval_expr(index_str, env, state)
	if not state.ok:
		return ""
	if typeof(idx) != TYPE_INT:
		_fail(state, "String indices must be integers, not %s." % _type_name(typeof(idx)))
		return ""
	var real = idx if idx >= 0 else s.length() + idx
	if real < 0 or real >= s.length():
		_fail(state, "String index %d out of range." % idx)
		return ""
	return s.substr(real, 1)

func _eval_member(s: String, env: Dictionary, state: Dictionary) -> Variant:
	var dot = _find_top_op(s, ".")
	var obj_expr = s.substr(0, dot).strip_edges()
	var rest = s.substr(dot + 1).strip_edges()
	var obj = _eval_expr(obj_expr, env, state)
	if not state.ok:
		return null
	if typeof(obj) == TYPE_DICTIONARY and obj.get("_is_module", false):
		if rest.find("(") != -1 and rest.ends_with(")"):
			var paren = rest.find("(")
			var fname = rest.substr(0, paren).strip_edges()
			var args_str = rest.substr(paren + 1, rest.length() - paren - 2).strip_edges()
			var args = _eval_call_args(args_str, env, state)
			if not state.ok:
				return null
			if not obj.has(fname):
				_fail(state, "Module has no function named '" + fname + "'.")
				return null
			return _call_value(obj[fname], args, env, state)
		if obj.has(rest):
			return obj[rest]
		_fail(state, "Module has no attribute '" + rest + "'.")
		return null
	if typeof(obj) == TYPE_ARRAY or typeof(obj) == TYPE_STRING or typeof(obj) == TYPE_DICTIONARY:
		if rest.find("(") != -1 and rest.ends_with(")"):
			var paren = rest.find("(")
			var mname = rest.substr(0, paren).strip_edges()
			var args_str = rest.substr(paren + 1, rest.length() - paren - 2).strip_edges()
			var args = _eval_call_args(args_str, env, state)
			if not state.ok:
				return null
			return _call_method(obj, mname, args, env, state)
		_fail(state, "'%s' object has no attribute '%s'." % [_type_name(typeof(obj)), rest])
		return null
	_fail(state, "'%s' object has no attribute '%s'." % [_type_name(typeof(obj)), rest])
	return null

func _eval_call(s: String, env: Dictionary, state: Dictionary) -> Variant:
	var paren = s.find("(")
	var fname = s.substr(0, paren).strip_edges()
	var args_str = s.substr(paren + 1, s.length() - paren - 2).strip_edges()
	var args = _eval_call_args(args_str, env, state)
	if not state.ok:
		return null
	if env.has(fname):
		return _call_value(env[fname], args, env, state)
	if fname in BUILTIN_NAMES:
		return _call_builtin_core(fname, args, env, state)
	if _find_top_op(fname, ".") != -1:
		var dot = _find_top_op(fname, ".")
		var obj_expr = fname.substr(0, dot).strip_edges()
		var mname = fname.substr(dot + 1).strip_edges()
		var obj = _eval_expr(obj_expr, env, state)
		if not state.ok:
			return null
		return _call_method(obj, mname, args, env, state)
	_fail(state, "Name '" + fname + "' is not defined.")
	return null

func _eval_call_args(args_str: String, env: Dictionary, state: Dictionary) -> Array:
	var out: Array = []
	if args_str.strip_edges() == "":
		return out
	for a in _split_call_args(args_str):
		var kv = _split_kwarg(a)
		if kv != null and kv.size() == 2:
			var v = _eval_expr(kv[1], env, state)
			if not state.ok:
				return []
			out.append({ "__kw": true, "name": kv[0], "value": v })
		else:
			out.append(_eval_expr(a.strip_edges(), env, state))
			if not state.ok:
				return []
	return out

func _split_call_args(s: String) -> Array:
	var out: Array = []
	var depth := 0
	var in_s := false
	var in_d := false
	var current := ""
	for i in range(s.length()):
		var c = s[i]
		if c == "'" and not in_d:
			in_s = not in_s
		elif c == "\"" and not in_s:
			in_d = not in_d
		if not in_s and not in_d:
			if c == "(" or c == "[" or c == "{":
				depth += 1
			elif c == ")" or c == "]" or c == "}":
				depth -= 1
			elif c == "," and depth == 0:
				out.append(current.strip_edges())
				current = ""
				continue
		current += c
	if current.strip_edges() != "":
		out.append(current.strip_edges())
	return out

func _call_value(value, args: Array, env: Dictionary, state: Dictionary) -> Variant:
	if typeof(value) == TYPE_CALLABLE:
		return value.call(args, env, state)
	if typeof(value) == TYPE_DICTIONARY and value.has("params") and value.has("body"):
		return _call_user_func(value, args, env, state)
	_fail(state, "'%s' object is not callable." % _type_name(typeof(value)))
	return null

func _call_user_func(func_data: Dictionary, args: Array, env: Dictionary, state: Dictionary):
	var params = func_data["params"]
	var defaults = func_data.get("defaults", {})
	if args.size() > params.size() or args.size() < params.size() - defaults.size():
		_fail(state, "Function expects %d arguments, got %d." % [params.size(), args.size()])
		return null
	state.depth += 1
	if state.depth > MAX_CALL_DEPTH:
		_fail(state, "Maximum recursion depth exceeded.")
		state.depth -= 1
		return null
	var local_env = env.duplicate()
	var saved_brk = state.brk
	var saved_cnt = state.cnt
	var saved_ret = state.ret
	var saved_line = state.line
	state.brk = false
	state.cnt = false
	state.ret = false
	for i in range(params.size()):
		if i < args.size():
			local_env[params[i]] = args[i]
		else:
			var default_expr = defaults[params[i]]
			var val = _eval_expr(default_expr, env, state)
			if not state.ok:
				return null
			local_env[params[i]] = val
	_exec_block(func_data["body"], 0, 0, local_env, state)
	var result = null
	if state.ok and state.ret:
		result = state.retval
	state.brk = saved_brk
	state.cnt = saved_cnt
	state.ret = saved_ret
	state.line = saved_line
	state.depth -= 1
	return result

func _call_method(obj, mname: String, args: Array, env: Dictionary, state: Dictionary) -> Variant:
	var t = typeof(obj)
	if t == TYPE_STRING:
		return _string_method(obj, mname, args, env, state)
	if t == TYPE_ARRAY:
		return _list_method(obj, mname, args, env, state)
	if t == TYPE_DICTIONARY:
		return _dict_method(obj, mname, args, env, state)
	_fail(state, "'%s' object has no method '%s'." % [_type_name(t), mname])
	return null

# ── String literals ─────────────────────────────────────────

func _parse_string_literal(s: String):
	var inner = s.substr(1, s.length() - 2)
	return _unescape(inner)

func _parse_fstring(s: String, env: Dictionary, state: Dictionary):
	var inner = s.substr(1, s.length() - 2)
	var out := ""
	var i := 0
	while i < inner.length():
		var c = inner[i]
		if c == "\\":
			out += _unescape_char(inner, i)
			i += 2
			continue
		if c == "{":
			if i + 1 < inner.length() and inner[i + 1] == "{":
				out += "{"
				i += 2
				continue
			var close = inner.find("}", i)
			if close == -1:
				_fail(state, "f-string: missing closing brace.")
				return ""
			var expr = inner.substr(i + 1, close - i - 1).strip_edges()
			var conv := ""
			if expr.find("!") != -1:
				var parts = expr.split("!")
				expr = parts[0].strip_edges()
				conv = parts[1].strip_edges()
			var v = _eval_expr(expr, env, state)
			if not state.ok:
				return ""
			var txt = _to_str(v)
			if conv == "r":
				txt = _repr_value(v)
			out += txt
			i = close + 1
			continue
		out += c
		i += 1
	return out

func _unescape(inner: String) -> String:
	var out := ""
	var i := 0
	while i < inner.length():
		var c = inner[i]
		if c == "\\" and i + 1 < inner.length():
			out += _unescape_char(inner, i)
			i += 2
			continue
		out += c
		i += 1
	return out

func _unescape_char(s: String, i: int) -> String:
	var nxt = s[i + 1]
	match nxt:
		"n": return "\n"
		"t": return "\t"
		"r": return "\r"
		"\\": return "\\"
		"\"": return "\""
		"'": return "'"
		"0": return char(0)
		"a": return "\a"
		"b": return "\b"
		"f": return "\f"
		"v": return "\v"
		_: return nxt

# ── Operators ───────────────────────────────────────────────

func _truthy(v) -> bool:
	match typeof(v):
		TYPE_NIL: return false
		TYPE_BOOL: return v
		TYPE_INT: return v != 0
		TYPE_FLOAT: return v != 0.0
		TYPE_STRING: return v.length() > 0
		TYPE_ARRAY: return v.size() > 0
		TYPE_DICTIONARY: return v.size() > 0
	return true

func _is_num(v) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT

func _apply_add(left, right, state: Dictionary) -> Variant:
	var lt = typeof(left)
	var rt = typeof(right)
	if lt == TYPE_STRING and rt == TYPE_STRING:
		return left + right
	if _is_num(left) and _is_num(right):
		return left + right
	if lt == TYPE_ARRAY and rt == TYPE_ARRAY:
		var out: Array = []
		out.append_array(left)
		out.append_array(right)
		return out
	_fail(state, "unsupported operand type(s) for +: '%s' and '%s'." % [_type_name(lt), _type_name(rt)])
	return null

func _apply_arith(op: String, left, right, state: Dictionary, floor_div: bool) -> Variant:
	var lt = typeof(left)
	var rt = typeof(right)
	if op == "*":
		if _is_num(left) and _is_num(right):
			return left * right
		if lt == TYPE_STRING and _is_num(right):
			return _repeat_string(left, int(right))
		if rt == TYPE_STRING and _is_num(left):
			return _repeat_string(right, int(left))
		if lt == TYPE_ARRAY and _is_num(right):
			var out: Array = []
			for i in range(int(right)):
				out.append_array(left)
			return out
		if rt == TYPE_ARRAY and _is_num(left):
			var out: Array = []
			for i in range(int(left)):
				out.append_array(right)
			return out
		_fail(state, "unsupported operand type(s) for *: '%s' and '%s'." % [_type_name(lt), _type_name(rt)])
		return null
	if op == "+":
		if lt == TYPE_STRING and rt == TYPE_STRING:
			return left + right
		if _is_num(left) and _is_num(right):
			return left + right
		_fail(state, "unsupported operand type(s) for +: '%s' and '%s'." % [_type_name(lt), _type_name(rt)])
		return null
	if not _is_num(left) or not _is_num(right):
		_fail(state, "unsupported operand type(s) for %s: '%s' and '%s'." % [op, _type_name(lt), _type_name(rt)])
		return null
	match op:
		"-":
			return left - right
		"/":
			if right == 0:
				_fail(state, "division by zero.")
				return null
			return float(left) / float(right)
		"*":
			return left * right
		"%":
			if right == 0:
				_fail(state, "modulo by zero.")
				return null
			return _py_mod(left, right)
		"//":
			if right == 0:
				_fail(state, "integer division by zero.")
				return null
			if lt == TYPE_INT and rt == TYPE_INT:
				return int(floor(float(left) / float(right)))
			return floor(float(left) / float(right))
	return null

func _repeat_string(s: String, n: int) -> String:
	if n <= 0:
		return ""
	var out := ""
	for i in range(n):
		out += s
	return out

func _py_mod(a, b):
	if typeof(a) == TYPE_INT and typeof(b) == TYPE_INT:
		var r = a % b
		if r != 0 and (r < 0) != (b < 0):
			r += b
		return r
	return fmod(float(a), float(b))

func _py_pow(left, right, state: Dictionary):
	if _is_num(left) and _is_num(right):
		if typeof(left) == TYPE_INT and typeof(right) == TYPE_INT and right >= 0:
			return int(pow(float(left), float(right)))
		return pow(float(left), float(right))
	_fail(state, "unsupported operand type(s) for **.")
	return null

func _find_multiplicative(s: String) -> Array:
	var ops = ["//", "*", "/", "%"]
	var best_idx := -1
	var best_op := ""
	for op in ops:
		var idx = _find_top_op(s, op)
		if idx != -1 and idx > best_idx:
			best_idx = idx
			best_op = op
	if best_idx == -1:
		return []
	return [best_op, best_idx]

func _find_last_binary(s: String, ops: Array) -> Array:
	var best_idx := -1
	var best_op := ""
	for op in ops:
		var idx = _find_top_op(s, op)
		if idx != -1 and idx > best_idx:
			best_idx = idx
			best_op = op
	if best_idx == -1:
		return []
	return [best_op, best_idx]

func _find_comparison(s: String) -> Array:
	var ops = ["==", "!=", "<=", ">=", "<", ">"]
	var best_idx := -1
	var best_op := ""
	for op in ops:
		var idx = _find_top_op(s, op)
		if idx != -1 and idx > best_idx:
			best_idx = idx
			best_op = op
	# Word operators: check longest first so a shorter one that matches
	# inside a longer one (e.g. " in " inside " not in ") is ignored.
	var word_ops = [" not in ", " is not ", " in ", " is "]
	for op in word_ops:
		var idx = _find_top_op(s, op)
		if idx == -1:
			continue
		if best_idx != -1 and idx >= best_idx and idx < best_idx + best_op.length():
			continue
		if idx > best_idx:
			best_idx = idx
			best_op = op
		elif best_idx != -1 and best_idx >= idx and best_idx < idx + op.length():
			best_idx = idx
			best_op = op
	if best_idx == -1:
		return []
	return [best_idx, best_op]

func _eval_comparison_chain(s: String, env: Dictionary, state: Dictionary) -> Variant:
	var terms: Array = []
	var ops: Array = []
	var rest = s
	while true:
		var cmp = _find_comparison(rest)
		if cmp.size() == 0:
			terms.append(rest.strip_edges())
			break
		terms.append(rest.substr(0, cmp[0]).strip_edges())
		ops.append(cmp[1])
		rest = rest.substr(cmp[0] + cmp[1].length()).strip_edges()
	var result := true
	var prev = _eval_expr(terms[0], env, state)
	if not state.ok:
		return false
	for k in range(ops.size()):
		var cur = _eval_expr(terms[k + 1], env, state)
		if not state.ok:
			return false
		var r = _compare(prev, ops[k], cur, state)
		if not state.ok:
			return false
		if not r:
			return false
		prev = cur
	return result

func _compare(left, op: String, right, state: Dictionary) -> bool:
	match op:
		"==": return left == right
		"!=": return left != right
		" is ":
			return left == right
		" is not ":
			return left != right
		" in ":
			return _membership(left, right, state)
		" not in ":
			return not _membership(left, right, state)
		"<", ">", "<=", ">=":
			if _is_num(left) and _is_num(right):
				return _num_cmp(left, op, right)
			if typeof(left) == TYPE_STRING and typeof(right) == TYPE_STRING:
				return _str_cmp(left, op, right)
			_fail(state, "'%s' and '%s' are not orderable." % [_type_name(typeof(left)), _type_name(typeof(right))])
			return false
	return false

func _num_cmp(left, op: String, right) -> bool:
	match op:
		"<": return left < right
		">": return left > right
		"<=": return left <= right
		">=": return left >= right
	return false

func _str_cmp(left: String, op: String, right: String) -> bool:
	match op:
		"<": return left < right
		">": return left > right
		"<=": return left <= right
		">=": return left >= right
	return false

func _membership(item, container, state: Dictionary) -> bool:
	match typeof(container):
		TYPE_ARRAY:
			return container.has(item)
		TYPE_DICTIONARY:
			return container.has(item)
		TYPE_STRING:
			return String(container).contains(str(item))
		_:
			_fail(state, "argument of type '%s' is not iterable." % _type_name(typeof(container)))
			return false

# ── Comprehensions ──────────────────────────────────────────

func _split_comp(inner: String) -> Array:
	var idx = _find_top_op(inner, " for ")
	if idx == -1:
		return []
	var head = inner.substr(0, idx)
	var rest = inner.substr(idx + 5)
	var if_idx = _find_top_op(rest, " if ")
	var loop_part := ""
	var cond := ""
	if if_idx != -1:
		loop_part = rest.substr(0, if_idx).strip_edges()
		cond = rest.substr(if_idx + 4).strip_edges()
	else:
		loop_part = rest.strip_edges()
	var in_idx = _find_top_op(loop_part, " in ")
	if in_idx == -1:
		return []
	var var_part = loop_part.substr(0, in_idx).strip_edges()
	var iter_expr = loop_part.substr(in_idx + 4).strip_edges()
	return [head, var_part, iter_expr, cond]

func _list_comp(s: String, env: Dictionary, state: Dictionary):
	var inner = s.substr(1, s.length() - 2)
	var parts = _split_comp(inner)
	if parts.size() != 4:
		_fail(state, "Unsupported comprehension syntax.")
		return []
	var expr = parts[0].strip_edges()
	var var_part = parts[1]
	var iter_expr = parts[2]
	var cond = parts[3]
	var iterable = _eval_expr(iter_expr, env, state)
	if not state.ok:
		return []
	var items = _iter_items(iterable, state)
	if not state.ok:
		return []
	var out: Array = []
	var local = env.duplicate()
	for element in items:
		if not _assign_loop_var(var_part, element, local, state):
			return []
		if cond != "":
			var c = _eval_expr(cond, local, state)
			if not state.ok:
				return []
			if not _truthy(c):
				continue
		out.append(_eval_expr(expr, local, state))
		if not state.ok:
			return []
	return out

func _dict_comp(s: String, env: Dictionary, state: Dictionary):
	var inner = s.substr(1, s.length() - 2)
	var parts = _split_comp(inner)
	if parts.size() != 4:
		_fail(state, "Unsupported comprehension syntax.")
		return {}
	var expr = parts[0].strip_edges()
	var var_part = parts[1]
	var iter_expr = parts[2]
	var cond = parts[3]
	var iterable = _eval_expr(iter_expr, env, state)
	if not state.ok:
		return {}
	var items = _iter_items(iterable, state)
	if not state.ok:
		return {}
	var local = env.duplicate()
	var colon = _find_top_colon(expr)
	if colon == -1:
		var set_out: Array = []
		for element in items:
			if not _assign_loop_var(var_part, element, local, state):
				return []
			if cond != "":
				var c = _eval_expr(cond, local, state)
				if not state.ok:
					return []
				if not _truthy(c):
					continue
			var v = _eval_expr(expr, local, state)
			if not state.ok:
				return []
			if not set_out.has(v):
				set_out.append(v)
		return set_out
	var key_expr = expr.substr(0, colon).strip_edges()
	var val_expr = expr.substr(colon + 1).strip_edges()
	var out: Dictionary = {}
	for element in items:
		if not _assign_loop_var(var_part, element, local, state):
			return {}
		if cond != "":
			var c = _eval_expr(cond, local, state)
			if not state.ok:
				return {}
			if not _truthy(c):
				continue
		var k = _eval_expr(key_expr, local, state)
		if not state.ok:
			return {}
		var v = _eval_expr(val_expr, local, state)
		if not state.ok:
			return {}
		out[k] = v
	return out

# ── Token helpers ───────────────────────────────────────────

func _find_top_op(s: String, op: String) -> int:
	var in_s := false
	var in_d := false
	var depth := 0
	var i := 0
	while i < s.length():
		var c = s[i]
		if c == "'" and not in_d:
			in_s = not in_s
		elif c == "\"" and not in_s:
			in_d = not in_d
		if not in_s and not in_d:
			if c == "(" or c == "[" or c == "{":
				depth += 1
			elif c == ")" or c == "]" or c == "}":
				depth -= 1
			elif depth == 0 and s.substr(i, op.length()) == op:
				return i
		i += 1
	return -1

func _find_top_colon(s: String) -> int:
	var in_s := false
	var in_d := false
	var depth := 0
	for i in range(s.length()):
		var c = s[i]
		if c == "'" and not in_d:
			in_s = not in_s
		elif c == "\"" and not in_s:
			in_d = not in_d
		if not in_s and not in_d:
			if c == "(" or c == "[" or c == "{":
				depth += 1
			elif c == ")" or c == "]" or c == "}":
				depth -= 1
			elif c == ":" and depth == 0:
				return i
	return -1

# Returns true if the first bracket in s (must be one of ( [ {) has its
# matching close at the last char. This lets the caller distinguish
# `[1,2,3]` (list literal) from `[1,2,3][0]` (index expression).
func _first_bracket_is_outer(s: String) -> bool:
	if s.length() < 2:
		return false
	var first = s[0]
	var close_c: String
	if first == "[": close_c = "]"
	elif first == "(": close_c = ")"
	elif first == "{": close_c = "}"
	else: return false
	if s[s.length() - 1] != close_c:
		return false
	var depth := 0
	var in_s := false
	var in_d := false
	for i in range(s.length()):
		var c = s[i]
		if c == "'" and not in_d:
			in_s = not in_s
		elif c == "\"" and not in_s:
			in_d = not in_d
		if not in_s and not in_d:
			if c == first:
				depth += 1
			elif c == close_c:
				depth -= 1
				if depth == 0:
					return i == s.length() - 1
	return false

func _split_top(s: String, sep: String) -> Array:
	var out: Array = []
	var depth := 0
	var in_s := false
	var in_d := false
	var current := ""
	var i := 0
	while i < s.length():
		var c = s[i]
		if c == "'" and not in_d:
			in_s = not in_s
		elif c == "\"" and not in_s:
			in_d = not in_d
		if not in_s and not in_d:
			if c == "(" or c == "[" or c == "{":
				depth += 1
			elif c == ")" or c == "]" or c == "}":
				depth -= 1
			elif c == sep[0] and depth == 0 and s.substr(i, sep.length()) == sep:
				out.append(current)
				current = ""
				i += sep.length()
				continue
		current += c
		i += 1
	if current != "":
		out.append(current)
	return out

func _type_name(t: int) -> String:
	match t:
		TYPE_NIL: return "NoneType"
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "str"
		TYPE_ARRAY: return "list"
		TYPE_DICTIONARY: return "dict"
		TYPE_CALLABLE: return "function"
		_: return "object"

func _to_str(v) -> String:
	match typeof(v):
		TYPE_NIL: return "None"
		TYPE_BOOL: return "True" if v else "False"
		TYPE_STRING: return v
		TYPE_ARRAY:
			var parts: Array = []
			for e in v:
				parts.append(_to_str(e))
			return "[" + ", ".join(parts) + "]"
		TYPE_DICTIONARY:
			if v.get("_is_module", false):
				return "<module>"
			var parts: Array = []
			for k in v:
				parts.append(_repr_value(k) + ": " + _to_str(v[k]))
			return "{" + ", ".join(parts) + "}"
		TYPE_CALLABLE:
			return "<function>"
		TYPE_FLOAT:
			if is_equal_approx(v, int(v)):
				if v < 0.0:
					return "-" + str(int(-v)) + ".0"
				return str(int(v)) + ".0"
			return str(v)
		_:
			return str(v)

func _repr_value(v) -> String:
	if typeof(v) == TYPE_STRING:
		return "'" + v.replace("\\", "\\\\").replace("'", "\\'") + "'"
	return _to_str(v)

# ── Builtins ────────────────────────────────────────────────

func _builtin_deque(args: Array, env: Dictionary, state: Dictionary) -> Array:
	var arr: Array = []
	if args.size() == 1 and typeof(args[0]) == TYPE_ARRAY:
		arr = args[0].duplicate()
	return arr

func _call_builtin_core(name: String, args: Array, env: Dictionary, state: Dictionary) -> Variant:
	match name:
		"len":
			if args.size() != 1:
				_fail(state, "len() takes exactly 1 argument.")
				return null
			var v = args[0]
			if v == null:
				_fail(state, "len() of NoneType.")
				return null
			if typeof(v) == TYPE_DICTIONARY:
				return v.size()
			if typeof(v) == TYPE_ARRAY:
				return v.size()
			if typeof(v) == TYPE_STRING:
				return v.length()
			_fail(state, "object of type '%s' has no len()." % _type_name(typeof(v)))
			return null
		"str":
			if args.size() != 1:
				_fail(state, "str() takes exactly 1 argument.")
				return null
			return _to_str(args[0])
		"int":
			if args.size() != 1:
				_fail(state, "int() takes exactly 1 argument.")
				return null
			var v = args[0]
			if v == null:
				_fail(state, "int() of NoneType.")
				return null
			if typeof(v) == TYPE_STRING:
				return int(v.strip_edges())
			if _is_num(v):
				return int(v)
			_fail(state, "int() cannot convert '%s'." % _type_name(typeof(v)))
			return null
		"float":
			if args.size() != 1:
				_fail(state, "float() takes exactly 1 argument.")
				return null
			var v = args[0]
			if v == null:
				_fail(state, "float() of NoneType.")
				return null
			if typeof(v) == TYPE_STRING:
				return float(v.strip_edges())
			if _is_num(v):
				return float(v)
			_fail(state, "float() cannot convert '%s'." % _type_name(typeof(v)))
			return null
		"bool":
			if args.size() != 1:
				_fail(state, "bool() takes exactly 1 argument.")
				return null
			return _truthy(args[0])
		"list":
			if args.size() == 0:
				return []
			if args.size() == 1:
				return _iter_items(args[0], state)
			_fail(state, "list() takes at most 1 argument.")
			return null
		"dict":
			if args.size() == 0:
				return {}
			if args.size() == 1 and typeof(args[0]) == TYPE_DICTIONARY:
				return args[0].duplicate()
			if args.size() == 1 and typeof(args[0]) == TYPE_ARRAY:
				var d: Dictionary = {}
				for pair in args[0]:
					if typeof(pair) == TYPE_ARRAY and pair.size() == 2:
						d[pair[0]] = pair[1]
				return d
			_fail(state, "dict() unsupported argument.")
			return null
		"range":
			return _builtin_range(args, state)
		"enumerate":
			if args.size() != 1:
				_fail(state, "enumerate() takes exactly 1 argument.")
				return null
			var items = _iter_items(args[0], state)
			if not state.ok:
				return null
			var out: Array = []
			for k in range(items.size()):
				out.append([k, items[k]])
			return out
		"zip":
			var lists: Array = []
			var min_len := 0
			var first := true
			for a in args:
				var l = _iter_items(a, state)
				if not state.ok:
					return null
				lists.append(l)
				min_len = l.size() if first else mini(min_len, l.size())
				first = false
			var out: Array = []
			for i in range(min_len):
				var row: Array = []
				for l in lists:
					row.append(l[i])
				out.append(row)
			return out
		"min":
			return _minmax(args, env, state, true)
		"max":
			return _minmax(args, env, state, false)
		"sum":
			if args.size() < 1 or args.size() > 2:
				_fail(state, "sum() takes 1 or 2 arguments.")
				return null
			var items = _iter_items(args[0], state)
			if not state.ok:
				return null
			var acc = args[1] if args.size() == 2 else 0
			for e in items:
				acc = _apply_add(acc, e, state)
				if not state.ok:
					return null
			return acc
		"abs":
			if args.size() != 1:
				_fail(state, "abs() takes exactly 1 argument.")
				return null
			var v = args[0]
			if not _is_num(v):
				_fail(state, "abs() requires a number.")
				return null
			return abs(v)
		"round":
			if args.size() < 1 or args.size() > 2:
				_fail(state, "round() takes 1 or 2 arguments.")
				return null
			var v = args[0]
			if args.size() == 2:
				return _round_to(v, int(args[1]))
			return int(round(v))
		"sorted":
			return _sorted(args, env, state)
		"reversed":
			if args.size() != 1:
				_fail(state, "reversed() takes exactly 1 argument.")
				return null
			var items = _iter_items(args[0], state)
			if not state.ok:
				return null
			var out: Array = []
			for i in range(items.size() - 1, -1, -1):
				out.append(items[i])
			return out
		"any":
			var items = _iter_items(args[0], state)
			if not state.ok:
				return null
			for e in items:
				if _truthy(e):
					return true
			return false
		"all":
			var items = _iter_items(args[0], state)
			if not state.ok:
				return null
			for e in items:
				if not _truthy(e):
					return false
			return true
		"pow":
			if args.size() == 2:
				return _py_pow(args[0], args[1], state)
			_fail(state, "pow() takes 2 arguments.")
			return null
		"chr":
			if args.size() != 1:
				_fail(state, "chr() takes exactly 1 argument.")
				return null
			return String.chr(int(args[0]))
		"ord":
			if args.size() != 1 or typeof(args[0]) != TYPE_STRING or args[0].length() != 1:
				_fail(state, "ord() expects a single character.")
				return null
			return args[0].unicode_at(0)
		"deque":
			return _builtin_deque(args, env, state)
		"print":
			var out := ""
			for a in args:
				out += _to_str(a)
			state.output += out + "\n"
			return null
		_:
			_fail(state, "Name '%s' is not defined." % name)
			return null

func _builtin_range(args: Array, state: Dictionary) -> Array:
	if args.size() == 1:
		var v = args[0]
		if not _is_num(v):
			_fail(state, "range() expects an int, got %s. Did you mean range(len(arr))?" % _type_name(typeof(v)))
			return []
		return _py_range(0, int(v), 1, state)
	if args.size() == 2:
		return _py_range(int(args[0]), int(args[1]), 1, state)
	if args.size() == 3:
		return _py_range(int(args[0]), int(args[1]), int(args[2]), state)
	_fail(state, "range() takes 1 to 3 arguments.")
	return []

func _minmax(args: Array, env: Dictionary, state: Dictionary, is_min: bool):
	if args.size() == 0:
		_fail(state, "min/max requires at least 1 argument.")
		return null
	var items: Array = []
	if args.size() == 1 and typeof(args[0]) == TYPE_ARRAY:
		items = args[0]
	elif args.size() == 1 and typeof(args[0]) == TYPE_STRING:
		items = _iter_items(args[0], state)
	else:
		items = args
	if items.size() == 0:
		_fail(state, "arg is an empty sequence.")
		return null
	var best = items[0]
	for e in items:
		if is_min:
			if e < best:
				best = e
		else:
			if e > best:
				best = e
	return best

func _sorted(args: Array, env: Dictionary, state: Dictionary):
	if args.size() < 1 or args.size() > 2:
		_fail(state, "sorted() takes 1 or 2 arguments.")
		return null
	var items = _iter_items(args[0], state)
	if not state.ok:
		return null
	var reverse := false
	if args.size() == 2:
		var kw = args[1]
		if typeof(kw) == TYPE_DICTIONARY and kw.get("__kw", false):
			if kw.get("name") == "reverse":
				reverse = _truthy(kw.get("value"))
		elif typeof(kw) == TYPE_DICTIONARY:
			reverse = _truthy(kw.get("reverse", false))
		elif typeof(kw) == TYPE_BOOL:
			reverse = kw
	items.sort()
	if reverse:
		items.reverse()
	return items

func _round_to(v, nd: int):
	if nd == 0:
		return round(v)
	var m = pow(10.0, float(nd))
	return round(v * m) / m

# ── String methods ──────────────────────────────────────────

func _string_method(s: String, mname: String, args: Array, env: Dictionary, state: Dictionary) -> Variant:
	match mname:
		"upper": return s.to_upper()
		"lower": return s.to_lower()
		"title":
			var out := ""
			var cap := true
			for i in range(s.length()):
				var c = s.substr(i, 1)
				if c == " " or c == "\t" or c == "\n":
					out += c
					cap = true
				elif cap:
					out += c.to_upper()
					cap = false
				else:
					out += c.to_lower()
			return out
		"capitalize":
			if s.length() == 0:
				return s
			return s.substr(0, 1).to_upper() + s.substr(1).to_lower()
		"strip":
			return _strip_chars(s, args[0] if args.size() == 1 else null, true, true)
		"lstrip":
			return _strip_chars(s, args[0] if args.size() == 1 else null, true, false)
		"rstrip":
			return _strip_chars(s, args[0] if args.size() == 1 else null, false, true)
		"split":
			var sep = args[0] if args.size() >= 1 else null
			if sep == null:
				return s.split(" ", false)
			if typeof(sep) == TYPE_STRING:
				if sep.length() == 0:
					return s.split(" ", false)
				return s.split(sep)
			_fail(state, "split() separator must be a string or None.")
			return []
		"splitlines":
			return s.split("\n")
		"join":
			if args.size() != 1:
				_fail(state, "join() takes exactly 1 argument.")
				return ""
			var seq = _iter_items(args[0], state)
			if not state.ok:
				return ""
			var parts: Array = []
			for e in seq:
				parts.append(_to_str(e))
			return s.join(parts)
		"replace":
			if args.size() != 2:
				_fail(state, "replace() takes exactly 2 arguments.")
				return s
			return s.replace(str(args[0]), str(args[1]))
		"find":
			if args.size() == 0:
				_fail(state, "find() requires a substring.")
				return -1
			return s.find(str(args[0]))
		"rfind":
			if args.size() == 0:
				_fail(state, "rfind() requires a substring.")
				return -1
			return s.rfind(str(args[0]))
		"index":
			var f = s.find(str(args[0])) if args.size() > 0 else -1
			if f == -1:
				_fail(state, "ValueError: substring not found.")
			return f
		"startswith":
			if args.size() == 0:
				_fail(state, "startswith() requires a prefix.")
				return false
			return s.begins_with(str(args[0]))
		"endswith":
			if args.size() == 0:
				_fail(state, "endswith() requires a suffix.")
				return false
			return s.ends_with(str(args[0]))
		"count":
			if args.size() == 0:
				_fail(state, "count() requires a substring.")
				return 0
			return s.count(str(args[0]))
		"isalpha":
			return _all_letters(s)
		"isdigit":
			if s.length() == 0:
				return false
			for i in range(s.length()):
				if not s.substr(i, 1).is_valid_int():
					return false
			return true
		"isalnum":
			if s.length() == 0:
				return false
			for i in range(s.length()):
				var c = s.substr(i, 1)
				if not (c.is_valid_int() or _is_letter(c)):
					return false
			return true
		"isspace":
			if s.length() == 0:
				return false
			for i in range(s.length()):
				var c = s.substr(i, 1)
				if not (c == " " or c == "\t" or c == "\n" or c == "\r"):
					return false
			return true
		"islower":
			return s.to_lower() == s and _has_letter(s)
		"isupper":
			return s.to_upper() == s and _has_letter(s)
		"zfill":
			if args.size() != 1:
				_fail(state, "zfill() takes exactly 1 argument.")
				return s
			var w = int(args[0])
			if s.length() >= w:
				return s
			return "0".repeat(w - s.length()) + s
		"ljust":
			if args.size() < 1:
				_fail(state, "ljust() requires a width.")
				return s
			var w = int(args[0])
			var fill = args[1] if args.size() >= 2 and typeof(args[1]) == TYPE_STRING else " "
			if s.length() >= w:
				return s
			return s + String(fill).repeat(w - s.length())
		"rjust":
			if args.size() < 1:
				_fail(state, "rjust() requires a width.")
				return s
			var w = int(args[0])
			var fill = args[1] if args.size() >= 2 and typeof(args[1]) == TYPE_STRING else " "
			if s.length() >= w:
				return s
			return String(fill).repeat(w - s.length()) + s
		"center":
			if args.size() < 1:
				_fail(state, "center() requires a width.")
				return s
			var w = int(args[0])
			if s.length() >= w:
				return s
			var pad = w - s.length()
			var left = pad / 2
			var right = pad - left
			return " ".repeat(left) + s + " ".repeat(right)
		"format":
			return _string_format(s, args, env, state)
		"swapcase":
			var out := ""
			for i in range(s.length()):
				var c = s.substr(i, 1)
				out += c.to_upper() if c == c.to_lower() else c.to_lower()
			return out
		_:
			_fail(state, "'str' object has no attribute '%s'." % mname)
			return null

func _is_letter(c: String) -> bool:
	var code = c.unicode_at(0)
	return (code >= 65 and code <= 90) or (code >= 97 and code <= 122)

func _all_letters(s: String) -> bool:
	if s.length() == 0:
		return false
	for i in range(s.length()):
		if not _is_letter(s.substr(i, 1)):
			return false
	return true

func _has_letter(s: String) -> bool:
	for i in range(s.length()):
		if _is_letter(s.substr(i, 1)):
			return true
	return false

func _strip_chars(s: String, chars, do_left: bool, do_right: bool) -> String:
	var start := 0
	var end := s.length()
	if do_left:
		while start < end:
			var c = s.substr(start, 1)
			if chars == null:
				if c != " " and c != "\t" and c != "\n" and c != "\r":
					break
			else:
				if String(chars).find(c) == -1:
					break
			start += 1
	if do_right:
		while end > start:
			var c = s.substr(end - 1, 1)
			if chars == null:
				if c != " " and c != "\t" and c != "\n" and c != "\r":
					break
			else:
				if String(chars).find(c) == -1:
					break
			end -= 1
	return s.substr(start, end - start)

func _string_format(s: String, args: Array, env: Dictionary, state: Dictionary) -> String:
	var out := ""
	var arg_idx := 0
	var i := 0
	while i < s.length():
		var c = s[i]
		if c == "{":
			if i + 1 < s.length() and s[i + 1] == "{":
				out += "{"
				i += 2
				continue
			var close = s.find("}", i)
			if close == -1:
				_fail(state, "format(): missing '}'.")
				return s
			var field = s.substr(i + 1, close - i - 1).strip_edges()
			if field == "":
				if arg_idx >= args.size():
					_fail(state, "format(): not enough arguments.")
					return s
				out += _to_str(args[arg_idx])
				arg_idx += 1
			elif field.is_valid_int():
				var idx = int(field)
				if idx >= args.size():
					_fail(state, "format(): index %d out of range." % idx)
					return s
				out += _to_str(args[idx])
			elif env.has(field):
				out += _to_str(env[field])
			else:
				_fail(state, "format(): unknown field '%s'." % field)
				return s
			i = close + 1
			continue
		if c == "}":
			if i + 1 < s.length() and s[i + 1] == "}":
				out += "}"
				i += 2
				continue
			_fail(state, "format(): unexpected '}'.")
			return s
		out += c
		i += 1
	return out

# ── List methods ────────────────────────────────────────────

func _list_method(lst: Array, mname: String, args: Array, env: Dictionary, state: Dictionary) -> Variant:
	match mname:
		"append":
			if args.size() != 1:
				_fail(state, "append() takes exactly 1 argument.")
				return null
			lst.append(args[0])
			return null
		"extend":
			if args.size() != 1:
				_fail(state, "extend() takes exactly 1 argument.")
				return null
			lst.append_array(_iter_items(args[0], state))
			return null
		"insert":
			if args.size() != 2:
				_fail(state, "insert() takes exactly 2 arguments.")
				return null
			var idx = int(args[0])
			if idx < 0:
				idx = maxi(0, lst.size() + idx)
			idx = mini(idx, lst.size())
			lst.insert(idx, args[1])
			return null
		"pop":
			if args.size() == 0:
				if lst.size() == 0:
					_fail(state, "pop from empty list.")
					return null
				return lst.pop_back()
			if args.size() == 1:
				if lst.size() == 0:
					_fail(state, "pop from empty list.")
					return null
				var idx = int(args[0])
				var real = idx if idx >= 0 else lst.size() + idx
				if real < 0 or real >= lst.size():
					_fail(state, "Index %d out of range." % idx)
					return null
				return lst.pop_at(real)
			_fail(state, "pop() takes at most 1 argument.")
			return null
		"remove":
			if args.size() != 1:
				_fail(state, "remove() takes exactly 1 argument.")
				return null
			var idx = lst.find(args[0])
			if idx == -1:
				_fail(state, "ValueError: list.remove(x): x not in list.")
				return null
			lst.remove_at(idx)
			return null
		"index":
			if args.size() != 1:
				_fail(state, "index() takes exactly 1 argument.")
				return -1
			var idx = lst.find(args[0])
			if idx == -1:
				_fail(state, "ValueError: value not in list.")
			return idx
		"count":
			if args.size() != 1:
				_fail(state, "count() takes exactly 1 argument.")
				return 0
			return lst.count(args[0])
		"clear":
			lst.clear()
			return null
		"reverse":
			lst.reverse()
			return null
		"sort":
			lst.sort()
			return null
		"copy":
			return lst.duplicate()
		"popleft":
			if lst.size() == 0:
				_fail(state, "pop from empty deque.")
				return null
			return lst.pop_at(0)
		"appendleft":
			if args.size() != 1:
				_fail(state, "appendleft() takes exactly 1 argument.")
				return null
			lst.insert(0, args[0])
			return null
		_:
			_fail(state, "'list' object has no attribute '%s'." % mname)
			return null

# ── Dict methods ────────────────────────────────────────────

func _dict_method(d: Dictionary, mname: String, args: Array, env: Dictionary, state: Dictionary):
	match mname:
		"get":
			if args.size() < 1 or args.size() > 2:
				_fail(state, "get() takes 1 or 2 arguments.")
				return null
			if d.has(args[0]):
				return d[args[0]]
			return args[1] if args.size() == 2 else null
		"keys":
			return d.keys()
		"values":
			return d.values()
		"items":
			var out: Array = []
			for k in d:
				out.append([k, d[k]])
			return out
		"pop":
			if args.size() < 1:
				_fail(state, "pop() requires a key.")
				return null
			var k = args[0]
			if not d.has(k):
				if args.size() == 2:
					return args[1]
				_fail(state, "KeyError: %s" % _repr_value(k))
				return null
			var v = d[k]
			d.erase(k)
			return v
		"setdefault":
			if args.size() < 1:
				_fail(state, "setdefault() requires a key.")
				return null
			var k = args[0]
			if d.has(k):
				return d[k]
			var def = args[1] if args.size() == 2 else null
			d[k] = def
			return def
		"update":
			if args.size() != 1:
				_fail(state, "update() takes exactly 1 argument.")
				return null
			if typeof(args[0]) == TYPE_DICTIONARY:
				for k in args[0]:
					d[k] = args[0][k]
			return null
		"clear":
			d.clear()
			return null
		"copy":
			return d.duplicate()
		"popitem":
			if d.size() == 0:
				_fail(state, "popitem(): dictionary is empty.")
				return null
			var k = d.keys()[0]
			var v = d[k]
			d.erase(k)
			return [k, v]
		_:
			_fail(state, "'dict' object has no attribute '%s'." % mname)
			return null

# ── math module ─────────────────────────────────────────────

func _b_sqrt(args: Array, env: Dictionary, state: Dictionary):
	return sqrt(float(_num_arg(args, 0, state)))

func _b_floor(args: Array, env: Dictionary, state: Dictionary):
	return int(floor(float(_num_arg(args, 0, state))))

func _b_ceil(args: Array, env: Dictionary, state: Dictionary):
	return int(ceil(float(_num_arg(args, 0, state))))

func _b_abs(args: Array, env: Dictionary, state: Dictionary):
	return abs(_num_arg(args, 0, state))

func _b_pow(args: Array, env: Dictionary, state: Dictionary):
	return pow(float(_num_arg(args, 0, state)), float(_num_arg(args, 1, state)))

func _b_exp(args: Array, env: Dictionary, state: Dictionary):
	return exp(float(_num_arg(args, 0, state)))

func _b_log(args: Array, env: Dictionary, state: Dictionary):
	var x = float(_num_arg(args, 0, state))
	if args.size() == 2:
		return log(x) / log(float(_num_arg(args, 1, state)))
	return log(x)

func _b_log10(args: Array, env: Dictionary, state: Dictionary):
	return log(float(_num_arg(args, 0, state))) / log(10.0)

func _b_sin(args: Array, env: Dictionary, state: Dictionary):
	return sin(float(_num_arg(args, 0, state)))

func _b_cos(args: Array, env: Dictionary, state: Dictionary):
	return cos(float(_num_arg(args, 0, state)))

func _b_tan(args: Array, env: Dictionary, state: Dictionary):
	return tan(float(_num_arg(args, 0, state)))

func _b_asin(args: Array, env: Dictionary, state: Dictionary):
	return asin(float(_num_arg(args, 0, state)))

func _b_acos(args: Array, env: Dictionary, state: Dictionary):
	return acos(float(_num_arg(args, 0, state)))

func _b_atan(args: Array, env: Dictionary, state: Dictionary):
	return atan(float(_num_arg(args, 0, state)))

func _b_hypot(args: Array, env: Dictionary, state: Dictionary):
	return sqrt(float(_num_arg(args, 0, state)) ** 2 + float(_num_arg(args, 1, state)) ** 2)

func _b_degrees(args: Array, env: Dictionary, state: Dictionary):
	return rad_to_deg(float(_num_arg(args, 0, state)))

func _b_radians(args: Array, env: Dictionary, state: Dictionary):
	return deg_to_rad(float(_num_arg(args, 0, state)))

# ── random module ───────────────────────────────────────────

func _b_random(args: Array, env: Dictionary, state: Dictionary):
	return randf()

func _b_randint(args: Array, env: Dictionary, state: Dictionary):
	return randi_range(int(_num_arg(args, 0, state)), int(_num_arg(args, 1, state)))

func _b_randrange(args: Array, env: Dictionary, state: Dictionary):
	if args.size() == 1:
		return randi_range(0, int(args[0]) - 1)
	if args.size() == 2:
		return randi_range(int(args[0]), int(args[1]) - 1)
	return randi_range(int(args[0]), int(args[1]) - 1)

func _b_choice(args: Array, env: Dictionary, state: Dictionary):
	if args.size() != 1 or typeof(args[0]) != TYPE_ARRAY or args[0].size() == 0:
		_fail(state, "choice() requires a non-empty sequence.")
		return null
	return args[0][randi_range(0, args[0].size() - 1)]

func _b_shuffle(args: Array, env: Dictionary, state: Dictionary):
	if args.size() != 1 or typeof(args[0]) != TYPE_ARRAY:
		_fail(state, "shuffle() requires a list.")
		return null
	var lst = args[0]
	for i in range(lst.size() - 1, 0, -1):
		var j = randi_range(0, i)
		var tmp = lst[i]
		lst[i] = lst[j]
		lst[j] = tmp
	return null

func _b_sample(args: Array, env: Dictionary, state: Dictionary):
	if args.size() != 2 or typeof(args[0]) != TYPE_ARRAY:
		_fail(state, "sample() requires a sequence and a count.")
		return null
	var k = int(args[1])
	var pool = args[0].duplicate()
	if k > pool.size():
		_fail(state, "sample larger than population.")
		return null
	var out: Array = []
	for i in range(k):
		var j = randi_range(0, pool.size() - 1)
		out.append(pool[j])
		pool.remove_at(j)
	return out

func _b_uniform(args: Array, env: Dictionary, state: Dictionary):
	return randf_range(float(_num_arg(args, 0, state)), float(_num_arg(args, 1, state)))

func _num_arg(args: Array, idx: int, state: Dictionary):
	if idx >= args.size():
		_fail(state, "Missing argument.")
		return 0
	var v = args[idx]
	if not _is_num(v):
		_fail(state, "Expected a number, got %s." % _type_name(typeof(v)))
		return 0
	return v
