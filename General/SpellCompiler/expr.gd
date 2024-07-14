class_name Expr

#var expression: Array[Token]
#var error: String
var back: GDExpr
var error: String:
	set(v):
		back.error = v
	get:
		return back.error

func _init(expr: String) -> void:
	back = GDExpr.new()
	back.build(expr)
	
func contains_variable(var_name: String) -> bool:
	return back.contains_variable(var_name)
	
#	var tokens = Token.tokenize(expr)
#
#	error = ""
#	expression = []
#	var operators: Array[Token] = []
#	var i = 0
#	while i < tokens.size():
#		var token: Token = tokens[i]
#		i += 1
#
#		if token.kind == Token.Kind.NUMBER or token.kind == Token.Kind.VAR:
#			expression.append(token)
#		elif token.kind == Token.Kind.FUNC:
#			operators.append(token)
#		elif token.kind == Token.Kind.OP:
#			if operators.size() > 0:
#				var op2: Token = operators[-1]
#				while op2.kind != Token.Kind.OPEN and operator_precedes(op2, token):
#					expression.append(op2)
#					operators.pop_back()
#					if operators.size() > 0:
#						op2 = operators[-1]
#					else:
#						break
#			operators.append(token)
#		elif token.kind == Token.Kind.PREFIX_OP:
#			operators.append(token)
#		elif token.kind == Token.Kind.OPEN:
#			operators.append(token)
#		elif token.kind == Token.Kind.CLOSE:
#			if operators.size() > 0:
#				var op2: Token = operators[-1]
#				while op2.kind != Token.Kind.OPEN:
#					expression.append(op2)
#					operators.pop_back()
#					if operators.size() > 0:
#						op2 = operators[-1]
#					else:
#						break
#				if operators.size() < 0:
#					expression.append(Token.new(Token.Kind.ERROR, "Missing Opening Paren"))
#				operators.pop_back()
#				if operators.size() > 0 and operators[-1].kind == Token.Kind.FUNC:
#					var op: Token = operators.pop_back()
#					expression.append(op)
#			else:
#				expression.append(Token.new(Token.Kind.ERROR, "Missing Opening Paren"))
#		elif token.kind == Token.Kind.COMMA:
#			if operators.size() > 0:
#				var op: Token = operators[-1]
#				while op.kind != Token.Kind.OPEN:
#					expression.append(op)
#					operators.pop_back()
#					if operators.size() > 0:
#						op = operators[-1]
#					else:
#						break
#
#	while operators.size() > 0:
#		var op: Token = operators.pop_back()
#		if op.kind == Token.Kind.OPEN:
#			expression.append(Token.new(Token.Kind.ERROR, "Missing Closing Paren"))
#		expression.append(op)

func free() -> void:
	back.free()

func operator_precedes(op1: Token, op2: Token) -> bool:
	if "^" == op1.raw and ("*" == op2.raw or "/" == op2.raw):
		return true
	if ("^" == op1.raw or "*" == op1.raw or "/" == op1.raw) and ("+" == op2.raw or "-" == op2.raw):
		return true
	
	if ("*" == op1.raw or "/" == op1.raw) and ("*" == op2.raw or "/" == op2.raw):
		return true
	if ("+" == op1.raw or "-" == op1.raw) and ("+" == op2.raw or "-" == op2.raw):
		return true
	
	return false

func compute(vars: Dictionary, display: bool = false) -> float:
	if not back.error.is_empty():
		return 0.0
	return back.compute(vars, GlobalData.game_settings.user_functions)
	
#	var tape: PackedFloat64Array = [] 
#	var tape_index := 0
#	for expr in expression:
#		var e: Token = expr
#		if e.kind == Token.Kind.ERROR:
#			error = e.raw
#			return 0
#
#		print(tape, " ", tape_index)
#
#		if e.kind == Token.Kind.NUMBER:
#			if tape_index == tape.size():
#				tape.append(e.raw.to_float())
#			else:
#				tape[tape_index] = e.raw.to_float()
#			tape_index += 1
#		elif e.kind == Token.Kind.VAR:
#			var value := 0.0
#			if e.raw.begins_with("-"):
#				value = -vars.get(e.raw.right(-1), 0.0)
#			else:
#				value = vars.get(e.raw, 0.0)
#			if tape_index == tape.size():
#				tape.append(value)
#			else:
#				tape[tape_index] = value			
#			tape_index += 1
#		elif e.kind == Token.Kind.OP:
#			tape_index -= 1
#			var b: float = tape[tape_index]
#			tape_index -= 1
#			var a: float = tape[tape_index]
#			if b == null:
#				error = "incomplete expression"
#				return 0.0
#			if a == null:
#				error = "incomplete expression"
#				return 0.0
#			var value := 0.0
#			match e.raw:
#				"+": value = a + b
#				"-": value = a - b
#				"*": value = a * b
#				"/": value = a / b
#				"^": value = a ** b
#			if tape_index == tape.size():
#				tape.append(value)
#			else:
#				tape[tape_index] = value
#			tape_index += 1
#		elif e.kind == Token.Kind.PREFIX_OP:
#			tape_index -= 1
#			var a: float = tape[tape_index]
#			var value := 0.0
#			match e.raw:
#				"-": value = -a
#				"+": value = a
#			if tape_index == tape.size():
#				tape.append(value)
#			else:
#				tape[tape_index] = value
#			tape_index += 1
#		elif e.kind == Token.Kind.FUNC:
#			tape_index -= 1
#			var a: float = tape[tape_index]
#			var value := 0.0
#			match e.raw:
#				"sin": value = sin(a)
#				"cos": value = cos(a)
#				"tan": value = tan(a)
#
#				"sinh": value = sinh(a)
#				"cosh": value = cosh(a)
#				"tanh": value = tanh(a)
#
#				"asin": value = asin(a)
#				"acos": value = acos(a)
#				"atan": value = atan(a)
#
#				"inv": value = 1.0 / a if a != 0.0 else 0.0
#				"mod":
#					tape_index -= 1
#					value = fmod(tape[tape_index], a) if a != 0 else 0.0
#				"div":
#					tape_index -= 1
#					value = floor(tape[tape_index] / a) if a != 0 else 0.0
#				"floor": value = floor(a)
#				"ceil": value = ceil(a)
#				"round": value = round(a)
#
#				"max":
#					tape_index -= 1
#					value = max(tape[tape_index], a)
#				"min": 
#					tape_index -= 1
#					value = min(tape[tape_index], a)
#
#				"lt": value = 1 if a < 0 else 0
#				"gt": value = 1 if a > 0 else 0
#				"lte": value = 1 if a <= 0 else 0
#				"gte": value = 1 if a >= 0 else 0
#				"eq": value = 1 if a == 0 else 0
#				"neq": value = 1 if a != 0 else 0
#
#			if tape_index == tape.size():
#				tape.append(value)
#			else:
#				tape[tape_index] = value
#			tape_index += 1
#
#	if tape.is_empty():
#		return 0
#
#	return tape[tape_index - 1]
