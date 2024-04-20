class_name Token

enum Kind { NUMBER, WORD, VAR, FUNC, OP, OPEN, CLOSE, COMMA, PREFIX_OP, NONE, ERROR }

var kind: Kind
var raw: String

func _init(k: Kind, r: String) -> void:
	kind = k
	raw = r

static func tokenize(expr: String) -> Array[Token]:
	var state := Kind.NONE
	var result: Array[Token] = []
	
	var current := ""
	var lastWasOp := true
	for c in expr:
		match state:
			Kind.NUMBER:
				if "1234567890.".contains(c):
					current = current + c
				else:
					result.append(Token.new(Kind.NUMBER, current))
					lastWasOp = false
					current = ""
					state = Kind.NONE
			Kind.WORD:
				if "qwertyuiopasdfghjklzxcvbnm1234567890".contains(c.to_lower()):
					current = current + c
				else:
					var k := Kind.VAR
					if is_func(current):
						k = Kind.FUNC
					result.append(Token.new(k, current))
					lastWasOp = false
					current = ""
					state = Kind.NONE
		match state:
			Kind.NONE:
				if "1234567890".contains(c):
					state = Kind.NUMBER
					current = current + c
				elif "qwertyuiopasdfghjklzxcvbnm".contains(c.to_lower()):
					state = Kind.WORD
					current = current + c
				elif "+-*/^".contains(c):
					if lastWasOp and "-+".contains(c):
						result.append(Token.new(Kind.PREFIX_OP, c))
					else: 
						result.append(Token.new(Kind.OP, c))
						lastWasOp = true
				elif c == "(":
					result.append(Token.new(Kind.OPEN, c))
					lastWasOp = true
				elif c == ")":
					result.append(Token.new(Kind.CLOSE, c))
					lastWasOp = false
				elif c == ",":
					result.append(Token.new(Kind.COMMA, c))
					lastWasOp = true
				elif c == " ":
					pass
				else:
					result.append(Token.new(Kind.ERROR, c))
					lastWasOp = false
	
	if current.length() > 0:
		match state:
			Kind.NUMBER:
				result.append(Token.new(Kind.NUMBER, current))
			Kind.WORD:
				var k := Kind.VAR
				if is_func(current):
					k = Kind.FUNC
				result.append(Token.new(k, current))
	
	return result
					
static func is_func(txt: String) -> bool:
	match txt:
		"sin", "cos", "tan", "asin", "acos", "atan", "sinh", "cosh", "tanh": return true
		"inv", "mod", "div", "floor", "ceil", "round", "max", "min": return true
		"lt", "gt", "lte", "gte", "eq", "neq": return true
	
	return false
