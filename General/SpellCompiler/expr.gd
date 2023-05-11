class_name Expr

var expression: Array
var error: String

func _init(expr: String):
	var tokens = Token.tokenize(expr)
	
	error = ""
	expression = []
	var operators = []
	var i = 0
	while i < tokens.size():
		var token: Token = tokens[i]
		i += 1
		
		if token.kind == Token.Kind.NUMBER or token.kind == Token.Kind.VAR:
			expression.append(token)
		elif token.kind == Token.Kind.FUNC:
			operators.append(token)
		elif token.kind == Token.Kind.OP:
			if operators.size() > 0:
				var op2: Token = operators[-1]
				while op2.kind != Token.Kind.OPEN and operator_precedes(op2, token):
					expression.append(op2)
					operators.pop_back()
					if operators.size() > 0:
						op2 = operators[-1]
					else:
						break
			operators.append(token)
		elif token.kind == Token.Kind.PREFIX_OP:
			operators.append(token)
		elif token.kind == Token.Kind.OPEN:
			operators.append(token)
		elif token.kind == Token.Kind.CLOSE:
			if operators.size() > 0:
				var op2: Token = operators[-1]
				while op2.kind != Token.Kind.OPEN:
					expression.append(op2)
					operators.pop_back()
					if operators.size() > 0:
						op2 = operators[-1]
					else:
						break
				if operators.size() < 0:
					expression.append(Token.new(Token.Kind.ERROR, "Missing Opening Paren"))
				operators.pop_back()
				if operators.size() > 0 and operators[-1].kind == Token.Kind.FUNC:
					var op = operators.pop_back()
					expression.append(op)
			else:
				expression.append(Token.new(Token.Kind.ERROR, "Missing Opening Paren"))
		elif token.kind == Token.Kind.COMMA:
			if operators.size() > 0:
				var op: Token = operators[-1]
				while op.kind != Token.Kind.OPEN:
					expression.append(op)
					operators.pop_back()
					if operators.size() > 0:
						op = operators[-1]
					else:
						break
		
	while operators.size() > 0:
		var op = operators.pop_back()
		if op.kind == Token.Kind.OPEN:
			expression.append(Token.new(Token.Kind.ERROR, "Missing Closing Paren"))
		expression.append(op)

func operator_precedes(op1: Token, op2: Token) -> bool:
	if "^" == op1.raw and "*/".contains(op2.raw):
		return true
	if "*/^".contains(op1.raw) and "+-".contains(op2.raw):
		return true
	
	if "*/".contains(op1.raw) and "*/".contains(op2.raw):
		return true
	if "+-".contains(op1.raw) and "+-".contains(op2.raw):
		return true
	
	return false

func compute(vars: Dictionary, display: bool = false) -> float:
	var tape = [] 
	
	for expr in expression:
		var e: Token = expr
		if e.kind == Token.Kind.ERROR:
			error = e.raw
			return 0
			
		if e.kind == Token.Kind.NUMBER:
			tape.append(e.raw.to_float())
		elif e.kind == Token.Kind.VAR:
			if e.raw.begins_with("-"):
				tape.append(-vars.get(e.raw.right(-1), 0.0))
			else:
				tape.append(vars.get(e.raw, 0.0))
		elif e.kind == Token.Kind.OP:
			var b = tape.pop_back()
			var a = tape.pop_back()
			if b == null:
				error = "incomplete expression"
				return 0.0
			if a == null:
				error = "incomplete expression"
				return 0.0
			match e.raw:
				"+": tape.append(a + b)
				"-": tape.append(a - b)
				"*": tape.append(a * b)
				"/": tape.append(a / b)
				"^": tape.append(a ^ b)
		elif e.kind == Token.Kind.PREFIX_OP:
			var a = tape.pop_back()
			match e.raw:
				"-": tape.append(-a)
				"+": tape.append(a)
		elif e.kind ==Token.Kind.FUNC:
			var a = tape.pop_back()
			match e.raw:
				"sin": tape.append(sin(a))
				"cos": tape.append(cos(a))
				"tan": tape.append(tan(a))
				
				"sinh": tape.append(sinh(a))
				"cosh": tape.append(cosh(a))
				"tanh": tape.append(tanh(a))
				
				"asin": tape.append(asin(a))
				"acos": tape.append(acos(a))
				"atan": tape.append(atan(a))
				
				"inv": tape.append(1.0 / a if a != 0 else 0)
				"mod": tape.append(fmod(tape.pop_back(), a) if a != 0 else 0.0)
				"div": tape.append(floor(tape.pop_back() / a) if a != 0 else 0.0)
				"floor": tape.append(floor(a))
				"ceil": tape.append(ceil(a))
				"round": tape.append(round(a))
				
				"max": tape.append(max(tape.pop_back(), a))
				"min": tape.append(min(tape.pop_back(), a))
				
				"lt": tape.append(1 if a < 0 else 0)
				"gt": tape.append(1 if a > 0 else 0)
				"lte": tape.append(1 if a <= 0 else 0)
				"gte": tape.append(1 if a >= 0 else 0)
				"eq": tape.append(1 if a == 0 else 0)
				"neq": tape.append(1 if a != 0 else 0)
				
	if tape.is_empty():
		return 0
	
	return tape.back()
