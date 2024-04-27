class_name ParseNode

var data: Token
var left: ParseNode
var right: ParseNode

func _init(d: Token, l: ParseNode, r: ParseNode) -> void:
	data = d
	left = l
	right = r
	
func display(t: String) -> void:
	print(t, " ", data.raw)
	if left == null:
		print(t + "-")
	else:
		left.display(t + "-")
	if right == null:
		print(t + "-")
	else:
		right.display(t + "-")
		
func compute(vars: Dictionary, disp: bool = false) -> float:
	var result := 0.0
	match data.kind:
		Token.Kind.NUMBER:
			result = data.raw.to_float()
		Token.Kind.WORD:
			result = vars[data.raw]
		Token.Kind.OP:
			var l := 0.0
			if left != null:
				l = left.compute(vars, disp)
			var r := 0.0
			if right != null:
				r = right.compute(vars, disp)
			match data.raw:
				"+": result = l + r
				"-": result = l - r
				"*": result = l * r
				"/": result = l / r
				"^": result = l ** r
		Token.Kind.OPEN:
			var l := 0.0
			if left != null:
				l = left.compute(vars, disp)
			result = l
		Token.Kind.CLOSE:
			result = 0.0
	if disp:
		print(data.raw, ": ", result)
	return result

static func parse(expr: String) -> ParseNode:
	var tokens := Token.tokenize(expr)
	var node := parse_tokens(tokens, 0)
	node = node.fix_op_priority()
	return node

static func parse_tokens(tokens: Array[Token], o: int) -> ParseNode:
	var a := tokens[o]
	if o == tokens.size() - 1:
		return ParseNode.new(a, null, null)
		
	var b: Token = tokens[o + 1]
	if o + 1 == tokens.size() - 1:
		return ParseNode.new(a, null, ParseNode.new(b, null, null))
		
	var c: Token = tokens[o + 2]
	if o + 2 == tokens.size() - 1:
		return ParseNode.new(b, ParseNode.new(a, null, null), ParseNode.new(c, null, null))
	
	if c.kind == Token.Kind.OPEN:
		return ParseNode.new(b, ParseNode.new(a, null, null), ParseNode.new(c, ParseNode.parse_tokens(tokens, o + 3), null))
	else:
		return ParseNode.new(b, ParseNode.new(a, null, null), ParseNode.parse_tokens(tokens, o + 2))
	
func rotate_left() -> ParseNode:
	if right != null:
		print("head: ", data.raw)
		print("right: ", right.data.raw)
		if right.left != null:
			print("right-left: ", right.left.data.raw)
		var n := right
		var temp := n.left
		n.left = self
		right = temp
		return n
	return self
	
func fix_op_priority() -> ParseNode:
	if data.kind == Token.Kind.OPEN:
		if left != null:
			return left.fix_op_priority()
	if data.kind == Token.Kind.OP:
		if "*/^".contains(data.raw):
			if right != null and "+-".contains(right.data.raw):
				var p := rotate_left()
				return p.fix_op_priority()
		if "^".contains(data.raw):
			if right != null and "^/*".contains(right.data.raw):
				var p := rotate_left()
				return p.fix_op_priority()
	return self
	
				
	
