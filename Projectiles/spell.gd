class_name Spell
extends Object

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
@export var delay: float
var chain: Spell

var x_expr: Expr
var y_expr: Expr
var z_expr: Expr
var r_expr: Expr

var is_relative_to_player_current_pos: bool

func _init(rel_pos: bool = false, _x: String = "0", _y: String = "0", _z: String = "0", _r: String = "0.2", _power: float = 0.1, _duration: float = 1000, _el: Element = Spell.Element.FIRE, _N: int = 1, _delay: float = 0.0):
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
	
	x_expr = Expr.new(x)
	y_expr = Expr.new(y)
	z_expr = Expr.new(z)
	r_expr = Expr.new(r)
	
func calculate_location(vars: Dictionary) -> Vector3:
	var result = Vector3.ZERO
	result.x = x_expr.compute(vars)
	result.y = y_expr.compute(vars)
	result.z = z_expr.compute(vars)
	return result + (vars["rel_pos"] if is_relative_to_player_current_pos else vars["abs_pos"])
	
func calculate_size(vars: Dictionary) -> float:
	var result = clamp(r_expr.compute(vars), 0.01, 10)
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
	fixed_vars["pi"] = PI
	fixed_vars.merge(fvars, true)
	var temp_vars = {}
	temp_vars.merge(fixed_vars)
#	temp_vars.merge(updated, true)
	temp_vars["tx"] = fixed_vars["x"]
	temp_vars["ty"] = fixed_vars["y"]
	temp_vars["tz"] = fixed_vars["z"]
	temp_vars["tu"] = fixed_vars["u"]
	temp_vars["tv"] = fixed_vars["v"]
	temp_vars["tw"] = fixed_vars["w"]
	temp_vars["rel_pos"] = fixed_vars["abs_pos"]
	temp_vars["n"] = n
	
	match element:
		Element.FIRE:
			var p: SpellBody = load("res://Projectiles/fire.tscn").instantiate()
			p.fixed_vars = fixed_vars
			p.spell = self
			p.position = calculate_location(temp_vars)
			return p
		
		Element.ROCK:
			var p: SpellBody = load("res://Projectiles/rock.tscn").instantiate()
			p.fixed_vars = fixed_vars
			p.spell = self
			p.position = calculate_location(temp_vars)
			var er = calculate_size(fixed_vars)
			p.update_shape(er, true)
			return p
			
		Element.WATER:
			var p: SpellBody = load("res://Projectiles/water.tscn").instantiate()
			p.fixed_vars = fixed_vars
			p.spell = self
			p.position = calculate_location(temp_vars)
			var er = calculate_size(temp_vars)
			p.update_shape(er, true)
			return p
			
		Element.AIR:
			var p: SpellBody = load("res://Projectiles/air.tscn").instantiate()
			p.fixed_vars = fixed_vars
			p.spell = self
			p.position = calculate_location(temp_vars)
			var er = calculate_size(temp_vars)
			p.update_shape(er, true)
			return p
			
		_: 
			var p = load("res://Projectiles/fire.tscn").instantiate()
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
		"chain": chain.save_dict() if chain else {},
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
	if dict["chain"] != {}:
		chain = Spell.new()
		chain.load_dict(dict["chain"])
	
	is_relative_to_player_current_pos = dict["is_rel"]
	
	x_expr = Expr.new(x)
	y_expr = Expr.new(y)
	z_expr = Expr.new(z)
	r_expr = Expr.new(r)
	
	
