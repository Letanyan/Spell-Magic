class_name Spell

enum Element { FIRE, WATER, ROCK, AIR, ICE, ELECTRIC }

@export var element: Element

@export var x: String
@export var y: String
@export var z: String
@export var r: String
@export var m: float
@export var d: float

var x_expr: Expr
var y_expr: Expr
var z_expr: Expr
var r_expr: Expr

var time_start: float
var expired: bool
var fixed_vars: Dictionary

func _init(_x: String, _y: String, _z: String, _r: String, _m: float, _d: float, _fvars: Dictionary):
	x = _x
	y = _y
	z = _z
	r = _r
	m = _m
	d = _d
	time_start = Time.get_ticks_msec()
	expired = false
	x_expr = Expr.new(x)
	y_expr = Expr.new(y)
	z_expr = Expr.new(z)
	r_expr = Expr.new(r)
	fixed_vars = _fvars
	
func _location(t: float, vars: Dictionary) -> Vector3:
	var result = Vector3.ZERO
	result.x = x_expr.compute(vars)
	result.y = y_expr.compute(vars)
	result.z = z_expr.compute(vars)
	return result
	
func _size(t: float, vars: Dictionary) -> float:
	var result = r_expr.compute(vars)
	return result
	
func update_spell(t: float, vars: Dictionary, particle: SpellBody):
	vars.merge(fixed_vars)
	t -= time_start
	t /= 1000.0
	vars["t"] = t
	var p = _location(t, vars)
	var s = _size(t, vars)
	var er = r_expr.compute(vars)
	particle.update_shape(er)
	particle.position = Vector3(0, 2, 0) + p

func has_expired(t: float) -> bool:
	return expired or (t - time_start) >= d
	
func expire_now():
	expired = true
	
func get_particle() -> SpellBody:
	match element:
		Element.FIRE:
			var p = load("res://Projectiles/fire.tscn").instantiate()
			p.element = Spell.Element.FIRE
			p.world_hit.connect(expire_now.bind())
			return p
		_: 
			var p = load("res://Projectiles/fire.tscn").instantiate()
			return p
		
