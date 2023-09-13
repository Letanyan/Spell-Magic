class_name Spell

enum Element { VOID, FIRE, WATER, ROCK, AIR, ICE, ELECTRIC }
enum ChainCastKind { START, END, HIT }

@export var element: Element
@export var name: String
@export var x: String
@export var y: String
@export var z: String
@export var r: String
@export var power: float:
	set(value):
		power = clamp(value, 0, WorldSettings.LIMIT_P)
@export var duration: float:
	set(value):
		duration = clamp(value, 0.0166667, WorldSettings.LIMIT_T)
@export var count: int:
	set(value):
		count = clamp(value, 1, WorldSettings.LIMIT_N)
@export var delay: String
@export var mana_cost: float = 0.0:
	set(value):
		mana_cost = clamp(value, 0, WorldSettings.LIMIT_MANA)
var chain_cast_kind: ChainCastKind:
	set(value):
		chain_cast_kind = value
		calculate_cooldown()
var chain: Spell:
	set(spell):
		chain = spell
		calculate_cooldown()

var x_expr: Expr
var y_expr: Expr
var z_expr: Expr
var r_expr: Expr
var d_expr: Expr

var follow: bool
var is_bomb: bool
var player_is_origin: bool
var cooldown: float
var charge: float

var constants: Dictionary = {}

var id: int = -1

var limit_r: float = WorldSettings.LIMIT_r
var limit_v: float = WorldSettings.LIMIT_v
var buff_r: float = 0.0
var buff_v: float = 0.0

func _init(_follow: bool = false, _x: String = "0", _y: String = "0", _z: String = "0", _r: String = "0.2", _power: float = 1, _duration: float = 1.0, _el: Element = Spell.Element.FIRE, _N: int = 1, _delay: String = "0", _is_bomb: bool = false, _mana: float = 0.0, _player_is_origin: bool = false):
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
	mana_cost = _mana
	
	follow = _follow
	is_bomb = _is_bomb
	player_is_origin = _player_is_origin
	charge = 0.0
	constants = {}
	
	x_expr = Expr.new(x)
	y_expr = Expr.new(y)
	z_expr = Expr.new(z)
	r_expr = Expr.new(r)
	d_expr = Expr.new(delay)
	
	chain_cast_kind = ChainCastKind.START
	
func duplicate() -> Spell:
	var result := Spell.new(follow, x, y, z, r, power, duration, element, count, delay, is_bomb, mana_cost, player_is_origin)
	result.chain = chain
	result.chain_cast_kind = chain_cast_kind
	result.name = name
	result.limit_r = limit_r
	result.limit_v = limit_v
	result.buff_r = buff_r
	result.buff_v = buff_v
	result.constants = constants
	return result
	
func calculate_location(vars: Dictionary, only_delta: bool = false) -> Vector3:
	var result := Vector3.ZERO
	result.x = x_expr.compute(vars)
	result.y = y_expr.compute(vars)
	result.z = z_expr.compute(vars)
	
	if vars.has("old_pos") and not only_delta:
		var old_pos = vars["old_pos"]
		vars["old_pos"] = result
		var t = vars.get("t", 0.0)
		var origin = vars.get("origin", Vector3.ZERO)
		var velocity = (result - old_pos) * (1 / vars.get("__frame_time", 60.0))
		result = velocity.normalized() * (clampf(velocity.length(), 0, limit_v + buff_v) * t) + origin
	else:
		vars["old_pos"] = result
	if not vars.has("origin") and not only_delta:
		vars["origin"] = result
	
	if not only_delta:
		result += (vars["rel_pos"] if follow else vars["abs_pos"])
	
	return result
	
func calculate_size(vars: Dictionary) -> float:
	var result := clampf(r_expr.compute(vars), 0.05, limit_r + buff_r)
	return result
	
func calculate_delay(vars: Dictionary) -> float:
	var result := clampf(d_expr.compute(vars), 0, 25)
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
			
func calculate_cooldown() -> float:
	var chain_cost := 0.0
	var basic_cost: float 
	if element == Element.VOID:
		basic_cost = 0.0
	else:
		basic_cost = (power / 100.0 + 1.0) * (1.0 if count == 1 else count * 0.98) + duration - mana_cost
	if chain != null:
		chain_cost = chain.calculate_cooldown()
	cooldown = basic_cost + chain_cost
	if cooldown < 0.0:
		cooldown = 0.0
	return cooldown
	
func actual_mana_cost() -> float:
	var result := mana_cost
	if chain != null:
		result += chain.actual_mana_cost() * count
	return result
	
const fire = preload("res://Projectiles/fire.tscn")
const rock = preload("res://Projectiles/rock.tscn")
const water = preload("res://Projectiles/water.tscn")
const air = preload("res://Projectiles/air.tscn")
const ice = preload("res://Projectiles/ice.tscn")
const electric = preload("res://Projectiles/electric.tscn")
const _void = preload("res://Projectiles/void.tscn")
	
func get_particle(n: int, fvars: Dictionary) -> SpellBody:
	var fixed_vars := {}
	fixed_vars["rn0"] = randf()
	fixed_vars["rn1"] = randf()
	fixed_vars["rn2"] = randf()
	fixed_vars["rn3"] = randf()
	fixed_vars["rn4"] = randf()
	fixed_vars["rn5"] = randf()
	fixed_vars["rn6"] = randf()
	fixed_vars["rn7"] = randf()
	fixed_vars["rn8"] = randf()
	fixed_vars["rn9"] = randf()
	fixed_vars["N"] = count
	fixed_vars["T"] = duration
	fixed_vars["P"] = power
	fixed_vars["D"] = delay
	fixed_vars["pi"] = PI
	fixed_vars["n"] = float(n)
	fixed_vars["M"] = mana_cost
	fixed_vars["C"] = charge
	charge = 0.0
	fixed_vars.merge(fvars, true)
	fixed_vars.merge(constants, true)
	
	var p: SpellBody
	match element:
		Element.FIRE: p = fire.instantiate()
		Element.ROCK: p = rock.instantiate()
		Element.WATER: p = water.instantiate()
		Element.AIR: p = air.instantiate()
		Element.ICE: p = ice.instantiate()
		Element.ELECTRIC: p = electric.instantiate()
		Element.VOID: p = _void.instantiate()
		_: p = fire.instantiate()
			
	p.fixed_vars = fixed_vars
	p.spell = self
	p.position = calculate_location(fixed_vars)
	var er := calculate_size(fixed_vars)
	p.update_shape(er, true)
	return p
		
func get_particles(fvars: Dictionary) -> Array:
	var result := []
	var fixed_vars := {}
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
	fixed_vars.merge(fvars, true)
	for i in range(count):
		var p := get_particle(i, fixed_vars)
		p.n = i
		p.spell = self
		result.append(p)
	return result

func save_dict():
	return {
		"x": x, "y": y, "z": z, "r": r,
		"power": power, "duration": duration, "count": count, "delay": delay,
		"chain": chain.save_dict() if chain else {}, "is_bomb": is_bomb,
		"is_rel": follow, "el": element, "chain_cast_kind": chain_cast_kind,
		"name": name, "id": id, "mana": mana_cost, "player_is_origin": player_is_origin,
		"constants": constants
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
	follow = dict["is_rel"]
	charge = 0.0
	if dict["chain"] != {}:
		chain = Spell.new()
		chain.load_dict(dict["chain"])
	id = dict.get("id", -1)
	mana_cost = dict.get("mana", 0.0)
	chain_cast_kind = dict.get("chain_cast_kind", 0) as ChainCastKind
	player_is_origin = dict.get("player_is_origin", true)
	constants = dict.get("constants", {})
	
	x_expr = Expr.new(x)
	y_expr = Expr.new(y)
	z_expr = Expr.new(z)
	r_expr = Expr.new(r)
	d_expr = Expr.new(delay)
	
	calculate_cooldown()
	
static func name_from_element(el: Element) -> String:
	match el:
		Element.FIRE: return "Fire"
		Element.ROCK: return "Rock"
		Element.WATER: return "Water"
		Element.AIR: return "Air"
		Element.ICE: return "Ice"
		Element.ELECTRIC: return "Electric"
		Element.VOID: return "Void"
		_: return ""

static func element_from_name(_name: String) -> Element:
	match _name.to_lower():
		"fire": return Element.FIRE
		"rock": return Element.ROCK
		"water": return Element.WATER
		"air": return Element.AIR
		"ice": return Element.ICE
		"electric": return Element.ELECTRIC
		"void": return Element.VOID
		_: return Element.FIRE

static func color_from_element(el: Element) -> Color:
	match el:
		Element.FIRE: return Color.RED
		Element.ROCK: return Color.SADDLE_BROWN
		Element.WATER: return Color.BLUE
		Element.AIR: return Color.GREEN_YELLOW
		Element.ICE: return Color.DODGER_BLUE
		Element.ELECTRIC: return Color.YELLOW
		Element.VOID: return Color.BLACK
		_: return Color.WHITE
