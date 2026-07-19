# ChallengeValidator.gd
# Pattern-matching validation engine for Python code challenges
# Works without Python runtime - uses static analysis
extends Resource

class_name ChallengeValidator

# ─── PATTERN TYPES ────────────────────────────────────────
enum PatternType {
	HAS_FOR_LOOP,
	HAS_WHILE_LOOP,
	HAS_IF,
	HAS_ELIF,
	HAS_ELSE,
	HAS_LIST,
	HAS_DICT,
	HAS_TUPLE,
	HAS_SET,
	USES_APPEND,
	USES_POP,
	USES_INDEX,
	USES_RANGE,
	USES_LEN,
	USES_ENUMERATE,
	USES_ZIP,
	USES_SUM,
	USES_MAX,
	USES_MIN,
	USES_SORTED,
	USES_REVERSED,
	USES_IN_OPERATOR,
	USES_NOT_IN,
	USES_AND,
	USES_OR,
	USES_NOT,
	VARIABLE_ASSIGNMENT,
	FUNCTION_DEF,
	FUNCTION_CALL,
	RETURN_STATEMENT,
	CLASS_DEF,
	TRY_EXCEPT,
	WITH_STATEMENT,
	LAMBDA_EXPR,
	LIST_COMPREHENSION,
	DICT_COMPREHENSION,
	SET_COMPREHENSION,
	GENERATOR_EXPR,
	CORRECT_SYNTAX,
	NO_SYNTAX_ERRORS,
	NO_HARDCODED_ANSWER,
	USES_SLICE,
	USES_NEGATIVE_INDEX,
	USES_MODULO,
	USES_FLOOR_DIV,
	USES_POWER,
	USES_F_STRING,
	USES_FORMAT,
	USES_JOIN,
	USES_SPLIT,
	USES_STRIP,
	USES_REPLACE,
	USES_LOWER,
	USES_UPPER,
	USES_ISINSTANCE,
	USES_TYPE,
	USES_INT,
	USES_STR,
	USES_FLOAT,
	USES_BOOL,
	USES_LIST_CTOR,
	USES_DICT_CTOR,
	USES_SET_CTOR,
	USES_TUPLE_CTOR,
}

# ─── VALIDATION RESULT ────────────────────────────────────
class ValidationResult:
	var passed: bool = false
	var score: float = 0.0
	var feedback: String = ""
	var matched_patterns: Array = []
	var missing_patterns: Array = []
	var forbidden_patterns: Array = []
	var syntax_errors: Array = []

# ─── MAIN VALIDATION ──────────────────────────────────────
func validate(code: String, required_patterns: Array, forbidden_patterns: Array = []) -> ValidationResult:
	var result = ValidationResult.new()
	
	# 1. Quick syntax check
	var syntax_errors = _check_syntax(code)
	if syntax_errors.size() > 0:
		result.syntax_errors = syntax_errors
		result.feedback = "Syntax errors found:\n" + "\n".join(syntax_errors)
		result.passed = false
		return result
	
	# 2. Check required patterns
	var matched = []
	var missing = []
	for pattern in required_patterns:
		if _check_pattern(code, pattern):
			matched.append(pattern)
		else:
			missing.append(pattern)
	
	# 3. Check forbidden patterns
	var forbidden_found = []
	for pattern in forbidden_patterns:
		if _check_pattern(code, pattern):
			forbidden_found.append(pattern)
	
	# 4. Calculate score
	var total_required = required_patterns.size()
	var matched_count = matched.size()
	var forbidden_penalty = forbidden_found.size() * 0.2
	
	result.matched_patterns = matched
	result.missing_patterns = missing
	result.forbidden_patterns = forbidden_found
	result.score = max(0.0, (float(matched_count) / float(total_required)) - forbidden_penalty) if total_required > 0 else 1.0
	result.passed = (missing.size() == 0) and (forbidden_found.size() == 0)
	
	# 5. Generate feedback
	result.feedback = _generate_feedback(result)
	
	return result

# ─── SYNTAX CHECKING ──────────────────────────────────────
func _check_syntax(code: String) -> Array[String]:
	var errors = []
	
	# Check balanced brackets
	var brackets = {"(": ")", "[": "]", "{": "}"}
	var stack = []
	for i in range(code.length()):
		var char = code[i]
		if char in brackets:
			stack.append([char, i])
		elif char in brackets.values():
			if stack.size() == 0:
				errors.append("Unmatched closing bracket '%s' at position %d" % [char, i])
			else:
				var open_char = stack.pop_back()
				var open_pos = open_char[1]
				open_char = open_char[0]
				if brackets[open_char] != char:
					errors.append("Mismatched brackets: '%s' at %d doesn't match '%s' at %d" % [open_char, open_pos, char, i])
	
	if stack.size() > 0:
		for item in stack:
			var open_char = item[0]
			var open_pos = item[1]
			errors.append("Unclosed bracket '%s' at position %d" % [open_char, open_pos])
	
	# Check for basic Python syntax issues
	var lines = code.split("\n")
	for i in range(lines.size()):
		var line = lines[i]
		var stripped = line.strip_edges()
		if stripped == "" or stripped.begins_with("#"):
			continue
		
		# Check for missing colons after control structures
		var control_keywords = ["if ", "elif ", "else:", "for ", "while ", "def ", "class ", "try:", "except:", "finally:", "with "]
		for kw in control_keywords:
			if stripped.begins_with(kw) and not stripped.ends_with(":"):
				# But allow multiline statements
				if not _continues_next_line(lines, i):
					errors.append("Line %d: Missing ':' after '%s'" % [i + 1, kw.strip()])
		
		# Check indentation consistency (basic)
		if i > 0:
			var prev_line = lines[i - 1].rstrip(" \t\r\n")
			if prev_line.ends_with(":"):
				# Next line should be indented
				if not line.begins_with(" ") and not line.begins_with("\t") and stripped != "":
					errors.append("Line %d: Expected indentation after ':'" % [i + 1])
	
	return errors

func _continues_next_line(lines: Array[String], line_num: int) -> bool:
	if line_num + 1 >= lines.size():
		return false
	var next_line = lines[line_num + 1]
	return next_line.begins_with(" ") or next_line.begins_with("\t")

# ─── PATTERN MATCHING ─────────────────────────────────────
func _check_pattern(code: String, pattern: PatternType) -> bool:
	match pattern:
		PatternType.HAS_FOR_LOOP:
			return _has_for_loop(code)
		PatternType.HAS_WHILE_LOOP:
			return _has_while_loop(code)
		PatternType.HAS_IF:
			return _has_if(code)
		PatternType.HAS_ELIF:
			return _has_elif(code)
		PatternType.HAS_ELSE:
			return _has_else(code)
		PatternType.HAS_LIST:
			return _has_list_literal(code)
		PatternType.HAS_DICT:
			return _has_dict_literal(code)
		PatternType.HAS_TUPLE:
			return _has_tuple_literal(code)
		PatternType.HAS_SET:
			return _has_set_literal(code)
		PatternType.USES_APPEND:
			return _uses_method(code, "append")
		PatternType.USES_POP:
			return _uses_method(code, "pop")
		PatternType.USES_INDEX:
			return _uses_indexing(code)
		PatternType.USES_RANGE:
			return _uses_function(code, "range")
		PatternType.USES_LEN:
			return _uses_function(code, "len")
		PatternType.USES_ENUMERATE:
			return _uses_function(code, "enumerate")
		PatternType.USES_ZIP:
			return _uses_function(code, "zip")
		PatternType.USES_SUM:
			return _uses_function(code, "sum")
		PatternType.USES_MAX:
			return _uses_function(code, "max")
		PatternType.USES_MIN:
			return _uses_function(code, "min")
		PatternType.USES_SORTED:
			return _uses_function(code, "sorted")
		PatternType.USES_REVERSED:
			return _uses_function(code, "reversed")
		PatternType.USES_IN_OPERATOR:
			return _uses_in_operator(code)
		PatternType.USES_NOT_IN:
			return _uses_not_in_operator(code)
		PatternType.USES_AND:
			return _uses_logical(code, "and")
		PatternType.USES_OR:
			return _uses_logical(code, "or")
		PatternType.USES_NOT:
			return _uses_logical(code, "not")
		PatternType.VARIABLE_ASSIGNMENT:
			return _has_assignment(code)
		PatternType.FUNCTION_DEF:
			return _has_function_def(code)
		PatternType.FUNCTION_CALL:
			return _has_function_call(code)
		PatternType.RETURN_STATEMENT:
			return _has_return(code)
		PatternType.CLASS_DEF:
			return _has_class_def(code)
		PatternType.TRY_EXCEPT:
			return _has_try_except(code)
		PatternType.WITH_STATEMENT:
			return _has_with(code)
		PatternType.LAMBDA_EXPR:
			return _has_lambda(code)
		PatternType.LIST_COMPREHENSION:
			return _has_list_comp(code)
		PatternType.DICT_COMPREHENSION:
			return _has_dict_comp(code)
		PatternType.SET_COMPREHENSION:
			return _has_set_comp(code)
		PatternType.GENERATOR_EXPR:
			return _has_generator(code)
		PatternType.CORRECT_SYNTAX:
			return _check_syntax(code).size() == 0
		PatternType.NO_SYNTAX_ERRORS:
			return _check_syntax(code).size() == 0
		PatternType.NO_HARDCODED_ANSWER:
			return not _has_hardcoded_answer(code)
		PatternType.USES_SLICE:
			return _uses_slice(code)
		PatternType.USES_NEGATIVE_INDEX:
			return _uses_negative_index(code)
		PatternType.USES_MODULO:
			return _uses_operator(code, "%")
		PatternType.USES_FLOOR_DIV:
			return _uses_operator(code, "//")
		PatternType.USES_POWER:
			return _uses_operator(code, "**")
		PatternType.USES_F_STRING:
			return _uses_f_string(code)
		PatternType.USES_FORMAT:
			return _uses_method(code, "format")
		PatternType.USES_JOIN:
			return _uses_method(code, "join")
		PatternType.USES_SPLIT:
			return _uses_method(code, "split")
		PatternType.USES_STRIP:
			return _uses_method(code, "strip")
		PatternType.USES_REPLACE:
			return _uses_method(code, "replace")
		PatternType.USES_LOWER:
			return _uses_method(code, "lower")
		PatternType.USES_UPPER:
			return _uses_method(code, "upper")
		PatternType.USES_ISINSTANCE:
			return _uses_function(code, "isinstance")
		PatternType.USES_TYPE:
			return _uses_function(code, "type")
		PatternType.USES_INT:
			return _uses_function(code, "int")
		PatternType.USES_STR:
			return _uses_function(code, "str")
		PatternType.USES_FLOAT:
			return _uses_function(code, "float")
		PatternType.USES_BOOL:
			return _uses_function(code, "bool")
		PatternType.USES_LIST_CTOR:
			return _uses_constructor(code, "list")
		PatternType.USES_DICT_CTOR:
			return _uses_constructor(code, "dict")
		PatternType.USES_SET_CTOR:
			return _uses_constructor(code, "set")
		PatternType.USES_TUPLE_CTOR:
			return _uses_constructor(code, "tuple")
	
	return false

# ─── HELPER PATTERN CHECKS ────────────────────────────────
func _has_for_loop(code: String) -> bool:
	# Match: for <var> in <iterable>:
	var regex = RegEx.new()
	regex.compile("\\bfor\\s+\\w+\\s+in\\s+")
	return regex.search(code) != null

func _has_while_loop(code: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\bwhile\\s+")
	return regex.search(code) != null

func _has_if(code: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\bif\\s+")
	return regex.search(code) != null

func _has_elif(code: String) -> bool:
	return "elif " in code

func _has_else(code: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\belse\\s*:")
	return regex.search(code) != null

func _has_list_literal(code: String) -> bool:
	# Match [ ... ] but not indexing
	var regex = RegEx.new()
	regex.compile("\\[[^\\]]*\\]")
	var regex_match = regex.search(code)
	if regex_match:
		# Make sure it's not just indexing like arr[0]
		var content = regex_match.get_string()
		var inner = content.substr(1, content.length() - 2).strip_edges()
		return not (content.begins_with("[") and content.ends_with("]") and content.length() < 10 and inner.is_valid_int())
	return false

func _has_dict_literal(code: String) -> bool:
	return "{" in code and ":" in code and _has_dict_pattern(code)

func _has_dict_pattern(code: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\{[^}]*:[^}]*\\}")
	return regex.search(code) != null

func _has_tuple_literal(code: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\([^)]*,[^)]*\\)")
	return regex.search(code) != null

func _has_set_literal(code: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\{[^}:]*,[^}]*\\}")
	return regex.search(code) != null

func _uses_method(code: String, method: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\.\\b%s\\b\\s*\\(" % method)
	return regex.search(code) != null

func _uses_function(code: String, func_name: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\b%s\\s*\\(" % func_name)
	return regex.search(code) != null

func _uses_indexing(code: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\[\\s*\\d+\\s*\\]")
	return regex.search(code) != null

func _uses_in_operator(code: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\bin\\b")
	return regex.search(code) != null

func _uses_not_in_operator(code: String) -> bool:
	return "not in" in code

func _uses_logical(code: String, op: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\b%s\\b" % op)
	return regex.search(code) != null

func _has_assignment(code: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\b\\w+\\s*=\\s*")
	return regex.search(code) != null

func _has_function_def(code: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\bdef\\s+\\w+\\s*\\(")
	return regex.search(code) != null

func _has_function_call(code: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\b\\w+\\s*\\(")
	return regex.search(code) != null

func _has_return(code: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\breturn\\b")
	return regex.search(code) != null

func _has_class_def(code: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\bclass\\s+\\w+")
	return regex.search(code) != null

func _has_try_except(code: String) -> bool:
	return "try:" in code and "except" in code

func _has_with(code: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\bwith\\s+")
	return regex.search(code) != null

func _has_lambda(code: String) -> bool:
	return "lambda " in code

func _has_list_comp(code: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\[[^\\]]*for\\s+\\w+\\s+in\\s+")
	return regex.search(code) != null

func _has_dict_comp(code: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\{[^}]*for\\s+\\w+\\s+in\\s+")
	return regex.search(code) != null

func _has_set_comp(code: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\{[^}]*for\\s+\\w+\\s+in\\s+")
	return regex.search(code) != null

func _has_generator(code: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\([^)]*for\\s+\\w+\\s+in\\s+")
	return regex.search(code) != null

func _has_hardcoded_answer(code: String) -> bool:
	# Check for suspicious patterns like direct answer values
	# This is heuristic - would need customization per challenge
	return false

func _uses_slice(code: String) -> bool:
	return ":" in code and "[" in code and "]" in code

func _uses_negative_index(code: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\[\\s*-\\d+\\s*\\]")
	return regex.search(code) != null

func _uses_operator(code: String, op: String) -> bool:
	return op in code

func _uses_f_string(code: String) -> bool:
	var regex = RegEx.new()
	regex.compile("f[\"']")
	return regex.search(code) != null

func _uses_constructor(code: String, ctor: String) -> bool:
	var regex = RegEx.new()
	regex.compile("\\b%s\\s*\\(" % ctor)
	return regex.search(code) != null

# ─── FEEDBACK GENERATION ──────────────────────────────────
func _generate_feedback(result: ValidationResult) -> String:
	var lines = []
	
	if result.passed:
		lines.append("✅ Challenge passed! Great job!")
	else:
		lines.append("❌ Challenge not passed. Keep trying!")
	
	if result.missing_patterns.size() > 0:
		lines.append("\nMissing concepts:")
		for pattern in result.missing_patterns:
			lines.append("  • %s" % _pattern_to_hint(pattern))
	
	if result.forbidden_patterns.size() > 0:
		lines.append("\nAvoid these patterns:")
		for pattern in result.forbidden_patterns:
			lines.append("  • %s" % _pattern_to_hint(pattern))
	
	if result.syntax_errors.size() > 0:
		lines.append("\nSyntax errors:")
		for err in result.syntax_errors:
			lines.append("  • %s" % err)
	
	lines.append("\nScore: %.0f%%" % (result.score * 100))
	
	return "\n".join(lines)

func _pattern_to_hint(pattern: PatternType) -> String:
	match pattern:
		PatternType.HAS_FOR_LOOP: return "Use a for loop"
		PatternType.HAS_WHILE_LOOP: return "Use a while loop"
		PatternType.HAS_IF: return "Use an if statement"
		PatternType.HAS_ELIF: return "Use elif for multiple conditions"
		PatternType.HAS_ELSE: return "Use else for the default case"
		PatternType.HAS_LIST: return "Create a list with []"
		PatternType.HAS_DICT: return "Create a dictionary with {}"
		PatternType.HAS_TUPLE: return "Create a tuple with ()"
		PatternType.HAS_SET: return "Create a set with {}"
		PatternType.USES_APPEND: return "Use .append() to add to list"
		PatternType.USES_POP: return "Use .pop() to remove from list"
		PatternType.USES_INDEX: return "Use indexing like arr[0]"
		PatternType.USES_RANGE: return "Use range() for number sequences"
		PatternType.USES_LEN: return "Use len() to get length"
		PatternType.USES_ENUMERATE: return "Use enumerate() for index + value"
		PatternType.USES_ZIP: return "Use zip() to combine iterables"
		PatternType.USES_SUM: return "Use sum() to add numbers"
		PatternType.USES_MAX: return "Use max() to find maximum"
		PatternType.USES_MIN: return "Use min() to find minimum"
		PatternType.USES_SORTED: return "Use sorted() to sort"
		PatternType.USES_REVERSED: return "Use reversed() to reverse"
		PatternType.USES_IN_OPERATOR: return "Use 'in' to check membership"
		PatternType.USES_NOT_IN: return "Use 'not in' to check absence"
		PatternType.USES_AND: return "Use 'and' to combine conditions"
		PatternType.USES_OR: return "Use 'or' for alternatives"
		PatternType.USES_NOT: return "Use 'not' to negate"
		PatternType.VARIABLE_ASSIGNMENT: return "Assign a variable with ="
		PatternType.FUNCTION_DEF: return "Define a function with def"
		PatternType.FUNCTION_CALL: return "Call a function with ()"
		PatternType.RETURN_STATEMENT: return "Use return to send value back"
		PatternType.CLASS_DEF: return "Define a class with class"
		PatternType.TRY_EXCEPT: return "Use try/except for error handling"
		PatternType.WITH_STATEMENT: return "Use with for context managers"
		PatternType.LAMBDA_EXPR: return "Use lambda for anonymous functions"
		PatternType.LIST_COMPREHENSION: return "Use list comprehension [x for x in...]"
		PatternType.DICT_COMPREHENSION: return "Use dict comprehension {k:v for...}"
		PatternType.SET_COMPREHENSION: return "Use set comprehension {x for...}"
		PatternType.GENERATOR_EXPR: return "Use generator (x for x in...)"
		PatternType.CORRECT_SYNTAX: return "Fix syntax errors"
		PatternType.NO_SYNTAX_ERRORS: return "Fix syntax errors"
		PatternType.NO_HARDCODED_ANSWER: return "Don't hardcode the answer"
		PatternType.USES_SLICE: return "Use slicing like arr[1:5]"
		PatternType.USES_NEGATIVE_INDEX: return "Use negative index like arr[-1]"
		PatternType.USES_MODULO: return "Use % for remainder"
		PatternType.USES_FLOOR_DIV: return "Use // for integer division"
		PatternType.USES_POWER: return "Use ** for exponentiation"
		PatternType.USES_F_STRING: return "Use f-strings for formatting"
		PatternType.USES_FORMAT: return "Use .format() for strings"
		PatternType.USES_JOIN: return "Use .join() to combine strings"
		PatternType.USES_SPLIT: return "Use .split() to separate strings"
		PatternType.USES_STRIP: return "Use .strip() to trim whitespace"
		PatternType.USES_REPLACE: return "Use .replace() to substitute"
		PatternType.USES_LOWER: return "Use .lower() for lowercase"
		PatternType.USES_UPPER: return "Use .upper() for uppercase"
		PatternType.USES_ISINSTANCE: return "Use isinstance() for type checking"
		PatternType.USES_TYPE: return "Use type() to check type"
		PatternType.USES_INT: return "Use int() to convert to integer"
		PatternType.USES_STR: return "Use str() to convert to string"
		PatternType.USES_FLOAT: return "Use float() to convert to float"
		PatternType.USES_BOOL: return "Use bool() to convert to boolean"
		PatternType.USES_LIST_CTOR: return "Use list() constructor"
		PatternType.USES_DICT_CTOR: return "Use dict() constructor"
		PatternType.USES_SET_CTOR: return "Use set() constructor"
		PatternType.USES_TUPLE_CTOR: return "Use tuple() constructor"
	
	return str(pattern)

# ─── CONVENIENCE METHODS ──────────────────────────────────
static func validate_code(code: String, required: Array[PatternType], forbidden: Array[PatternType] = []) -> ValidationResult:
	var validator = ChallengeValidator.new()
	return validator.validate(code, required, forbidden)

static func pattern_from_string(name: String) -> PatternType:
	return PatternType[name.to_upper()]

static func patterns_from_strings(names: Array[String]) -> Array[PatternType]:
	var result = []
	for name in names:
		result.append(pattern_from_string(name))
	return result