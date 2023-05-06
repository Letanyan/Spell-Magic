class_name Spell

enum Element { FIRE, WATER, ROCK, AIR, ICE, ELECTRIC }

@export var element: Element
@export var name: String
@export var x: String
@export var y: String
@export var z: String
@export var r: String
@export var power: float
@export var duration: float
@export var count: float
@export var delay: String
var chain: Spell

var x_expr: Expr
var y_expr: Expr
var z_expr: Expr
var r_expr: Expr
var d_expr: Expr

var is_relative_to_player_current_pos: bool
var is_bomb: bool

func _init(rel_pos: bool = false, _x: String = "0", _y: String = "0", _z: String = "0", _r: String = "0.2", _power: float = 0.1, _duration: float = 1.0, _el: Element = Spell.Element.FIRE, _N: int = 1, _delay: String = "0", _is_bomb: bool = false):
	x = _x
	y = _y
	z = _z
	r = _r
	power = _power
	duration = _duration
	element = _el
	count = _N
	delay = _delay
	chain = null
	
	is_relative_to_player_current_pos = rel_pos
	is_bomb = _is_bomb
	
	x_expr = Expr.new(x)
	y_expr = Expr.new(y)
	z_expr = Expr.new(z)
	r_expr = Expr.new(r)
	d_expr = Expr.new(delay)
	
func calculate_location(vars: Dictionary) -> Vector3:
	var result = Vector3.ZERO
	result.x = x_expr.compute(vars)
	result.y = y_expr.compute(vars)
	result.z = z_expr.compute(vars)
	return result + (vars["rel_pos"] if is_relative_to_player_current_pos else vars["abs_pos"])
	
func calculate_size(vars: Dictionary) -> float:
	var result = clamp(r_expr.compute(vars), 0.01, 10)
	return result
	
func calculate_delay(vars: Dictionary) -> float:
	var result = d_expr.compute(vars)
	return result
	
func _mass() -> float:
	match element:
		Element.ROCK: return power * 100.0
		_: return 0
			
func impulse_length() -> float:
	match element:
		Element.AIR:
			return power * 10
		_:
			return 0
	
func get_particle(n: int, fvars: Dictionary) -> SpellBody:
	var fixed_vars = {}
	fixed_vars["r0"] = randf()
	fixed_vars["r1"] = randf()
	fixed_vars["r2"] = randf()
	fixed_vars["r3"] = randf()
	fixed_vars["r4"] = randf()
	fixed_vars["r5"] = randf()
	fixed_vars["r6"] = randf()
	fixed_vars["r7"] = randf()
	fixed_vars["r8"] = randf()
	fixed_vars["r9"] = randf()
	fixed_vars["N"] = count
	fixed_vars["T"] = duration
	fixed_vars["P"] = power
	fixed_vars["D"] = delay
	fixed_vars["pi"] = PI
	fixed_vars.merge(fvars, true)
	var temp_vars = {}
	temp_vars.merge(fixed_vars)
	temp_vars["n"] = n
	
	var p: SpellBody
	match element:
		Element.FIRE: p = load("res://Projectiles/fire.tscn").instantiate()
		Element.ROCK: p = load("res://Projectiles/rock.tscn").instantiate()
		Element.WATER: p = load("res://Projectiles/water.tscn").instantiate()
		Element.AIR: p = load("res://Projectiles/air.tscn").instantiate()
		Element.ICE: p = load("res://Projectiles/ice.tscn").instantiate()
		Element.ELECTRIC: p = load("res://Projectiles/electric.tscn").instantiate()
		_: p = load("res://Projectiles/fire.tscn").instantiate()
			
	p.fixed_vars = fixed_vars
	p.spell = self
	p.position = calculate_location(temp_vars)
	var er = calculate_size(fixed_vars)
	p.update_shape(er, true)
	return p
		
func get_particles(fvars: Dictionary) -> Array:
	var result = []
	for i in range(count):
		var p = get_particle(i, fvars)
		p.n = i
		p.spell = self
		result.append(p)
	return result

func save_dict():
	return {
		"x": x, "y": y, "z": z, "r": r,
		"power": power, "duration": duration, "count": count, "delay": delay,
		"chain": chain.save_dict() if chain else {}, "is_bomb": is_bomb,
		"is_rel": is_relative_to_player_current_pos, "el": element,
		"name": name,
	}

func load_dict(dict: Dictionary):
	name = dict.get("name", "")
	x = dict["x"]
	y = dict["y"]
	z = dict["z"]
	r = dict["r"]
	power = dict["power"]
	duration = dict["duration"]
	element = dict["el"]
	count = dict["count"]
	delay = dict["delay"]
	is_bomb = dict.get("is_bomb", false)
	is_relative_to_player_current_pos = dict["is_rel"]
	if dict["chain"] != {}:
		chain = Spell.new()
		chain.load_dict(dict["chain"])
	
	x_expr = Expr.new(x)
	y_expr = Expr.new(y)
	z_expr = Expr.new(z)
	r_expr = Expr.new(r)
	d_expr = Expr.new(delay)
	
static func name_from_element(el: Element) -> String:
	match el:
		Element.FIRE: return "Fire"
		Element.ROCK: return "Rock"
		Element.WATER: return "Water"
		Element.AIR: return "Air"
		Element.ICE: return "Ice"
		Element.ELECTRIC: return "Electric"
		_: return ""

static func element_from_name(_name: String) -> Element:
	match _name.to_lower():
		"fire": return Element.FIRE
		"rock": return Element.ROCK
		"water": return Element.WATER
		"air": return Element.AIR
		"ice": return Element.ICE
		"electric": return Element.ELECTRIC
		_: return Element.FIRE
