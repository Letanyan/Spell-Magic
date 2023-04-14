class_name Spell

enum Element { FIRE, WATER, ROCK, AIR, ICE, ELECTRIC }

@export var element: Element

@export var x: String
@export var y: String
@export var z: String
@export var r: String
@export var m: float
@export var d: float

var x_expr: ParseNode
var y_expr: ParseNode
var z_expr: ParseNode
var r_expr: ParseNode

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
	x_expr = ParseNode.parse(x)
	y_expr = ParseNode.parse(y)
	z_expr = ParseNode.parse(z)
	r_expr = ParseNode.parse(r)
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
	
func update_spell(t: float, vars: Dictionary, particle: CPUParticles3D):
	vars.merge(fixed_vars)
	t -= time_start
	t /= 1000.0
	vars["t"] = t
	var p = _location(t, vars)
	var s = _size(t, vars)
	particle.emission_sphere_radius = s
	particle.position = Vector3(0, 2, 0) + p

func has_expired(t: float) -> bool:
	return expired or (t - time_start) >= d
	
func expire_now():
	expired = true
	
func get_particle() -> CPUParticles3D:
	match element:
		Element.FIRE: 
			var p = load("res://Projectiles/fire.tscn").instantiate()
			p.world_hit.connect(expire_now.bind())
			return p
		_: 
			var p = load("res://Projectiles/fire.tscn").instantiate()
			return p
		
