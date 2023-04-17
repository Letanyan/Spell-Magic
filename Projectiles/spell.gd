class_name Spell

enum Element { FIRE, WATER, ROCK, AIR, ICE, ELECTRIC }

@export var element: Element

@export var x: String
@export var y: String
@export var z: String
@export var r: String
@export var power: float
@export var duration: float

var x_expr: Expr
var y_expr: Expr
var z_expr: Expr
var r_expr: Expr

var time_start: float
var position: Vector3
var velocity: Vector3
var accel: Vector3
var force: Vector3
var expired: bool
var started: bool
var in_control: bool
var fixed_vars: Dictionary

func _init(_x: String, _y: String, _z: String, _r: String, _p: float, _d: float, _e: Element, _fvars: Dictionary):
	x = _x
	y = _y
	z = _z
	r = _r
	power = _p
	duration = _d
	element = _e
	time_start = Time.get_ticks_msec()
	position = Vector3.ZERO
	velocity = Vector3.ZERO
	accel = Vector3.ZERO
	expired = false
	started = false
	in_control = true
	x_expr = Expr.new(x)
	y_expr = Expr.new(y)
	z_expr = Expr.new(z)
	r_expr = Expr.new(r)
	fixed_vars = _fvars
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
	
func _location(vars: Dictionary) -> Vector3:
	var result = Vector3.ZERO
	result.x = x_expr.compute(vars)
	result.y = y_expr.compute(vars)
	result.z = z_expr.compute(vars)
	return Vector3(0, 2, 0) + result
	
func _size(vars: Dictionary) -> float:
	var result = clamp(r_expr.compute(vars), 0.01, 10)
	return result
	
func _mass(r: float) -> float:
	match element:
		Element.FIRE: return 0
		Element.ROCK: return r
		Element.WATER: return r / 10
	return 0
	
func _force(r: float) -> Vector3:
	return _mass(r) * velocity
	
func update_spell(t: float, vars: Dictionary, particle: SpellBody):
	if not in_control:
		return
	vars.merge(fixed_vars, true)
	t -= time_start
	t /= 1000.0
	vars["t"] = t
	var p = _location(vars)
	var er = _size(vars)
	particle.update_shape(er, false)
	var oldPos = position
	position = p
	if started:
		var oldVel = velocity
		velocity = position - oldPos
		var len = velocity.length()
		velocity = velocity.normalized() * clamp(len, -1, 1)
		if oldVel:
			accel = oldVel - velocity
			force = _force(er)
	particle.update_movement(velocity, false)
	started = true

func has_expired(t: float) -> bool:
	return expired or (t - time_start) >= duration
	
func expire_now(p: Node3D, q: Node3D):
	expired = true
	
func lose_control(p: Node3D, q: Node3D):
	in_control = false
	if element == Element.ROCK:
		var body: RigidBody3D = p.get_node("body")
		body.collision_layer = 1
		if body.freeze:
			body.freeze = false
			body.apply_central_impulse(velocity)
			var area = p.get_node("body/mesh/area")
			area.collision_layer = 1
	
func get_particle() -> SpellBody:
	match element:
		Element.FIRE:
			var p = load("res://Projectiles/fire.tscn").instantiate()
			p.spell = self
			p.world_hit.connect(expire_now.bind())
			p.position = _location(fixed_vars)
			return p
		
		Element.ROCK:
			var p = load("res://Projectiles/rock.tscn").instantiate()
			p.spell = self
			p.world_hit.connect(lose_control.bind())
			p.position = _location(fixed_vars)
			var er = _size(fixed_vars)
			p.update_shape(er, true)
			return p
			
		Element.WATER:
			var p = load("res://Projectiles/water.tscn").instantiate()
			p.spell = self
			p.world_hit.connect(expire_now.bind())
			p.position = _location(fixed_vars)
			var er = _size(fixed_vars)
			p.update_shape(er, true)
			return p
			
		_: 
			var p = load("res://Projectiles/fire.tscn").instantiate()
			return p
		
