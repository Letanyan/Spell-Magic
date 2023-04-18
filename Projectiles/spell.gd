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
var old_local_pos: Vector3
var position: Vector3
var velocity: Vector3
var is_relative_to_player_current_pos: bool
var expired: bool
var started: bool
var in_control: bool
var fixed_vars: Dictionary

func _init(rel_pos: bool, _x: String, _y: String, _z: String, _r: String, _p: float, _d: float, _e: Element, _fvars: Dictionary):
	x = _x
	y = _y
	z = _z
	r = _r
	power = _p
	duration = _d
	element = _e
	time_start = Time.get_ticks_msec()
	old_local_pos = Vector3.ZERO
	position = Vector3.ZERO
	velocity = Vector3.ZERO
	is_relative_to_player_current_pos = rel_pos
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
	return Vector3(0, 2, 0) + result + (vars["rel_pos"] if is_relative_to_player_current_pos else vars["abs_pos"])
	
func _size(vars: Dictionary) -> float:
	var result = clamp(r_expr.compute(vars), 0.01, 10)
	return result
	
func _mass(r: float) -> float:
	match element:
		Element.ROCK: return power * 100.0
		_: return 0
	return 0
	
func impulse() -> Vector3:
	match element:
		Element.ROCK:
			return velocity.normalized() * (power * 100.0) 
		Element.AIR:
			return velocity.normalized() * (power * 100.0)
		_:
			return Vector3.ZERO
			
func impulse_length() -> float:
	match element:
		Element.AIR:
			return power * 10
		_:
			return 0
	
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
	position = p
	if started:
		var oldVel = velocity
		velocity = (position - (vars["rel_pos"] if is_relative_to_player_current_pos else vars["abs_pos"])) - old_local_pos
		var len = velocity.length()
		velocity = velocity.normalized() * clamp(len, -1, 1)
	particle.update_movement(velocity, position, false)
	old_local_pos = position - (vars["rel_pos"] if is_relative_to_player_current_pos else vars["abs_pos"])
	started = true

func has_expired(t: float) -> bool:
	return expired or (t - time_start) >= duration
	
func expire_now(p: Node3D, q: Node3D):
	expired = true
	
func lose_control(p: Node3D, q: Node3D):
	in_control = false
	if element == Element.ROCK:
		var body: RigidBody3D = p.get_node("body")
#		body.collision_layer = 1
		if body.freeze:
			body.freeze = false
			body.apply_central_impulse(velocity)
			var area = p.get_node("body/mesh/area")
#			area.collision_layer = 1
	
func nothing(p: Node3D, q: Node3D):
	pass
	
func get_particle() -> SpellBody:
	var temp_vars = {}
	temp_vars.merge(fixed_vars)
	temp_vars["tx"] = fixed_vars["x"]
	temp_vars["ty"] = fixed_vars["y"]
	temp_vars["tz"] = fixed_vars["z"]
	temp_vars["tu"] = fixed_vars["u"]
	temp_vars["tv"] = fixed_vars["v"]
	temp_vars["tw"] = fixed_vars["w"]
	temp_vars["rel_pos"] = fixed_vars["abs_pos"]
	
	match element:
		Element.FIRE:
			var p = load("res://Projectiles/fire.tscn").instantiate()
			p.spell = self
			p.world_hit.connect(expire_now.bind())
			p.position = _location(temp_vars)
			return p
		
		Element.ROCK:
			var p = load("res://Projectiles/rock.tscn").instantiate()
			p.spell = self
			p.world_hit.connect(lose_control.bind())
			p.position = _location(temp_vars)
			var er = _size(fixed_vars)
			p.update_shape(er, true)
			return p
			
		Element.WATER:
			var p = load("res://Projectiles/water.tscn").instantiate()
			p.spell = self
			p.world_hit.connect(expire_now.bind())
			p.position = _location(temp_vars)
			var er = _size(temp_vars)
			p.update_shape(er, true)
			return p
			
		Element.AIR:
			var p = load("res://Projectiles/air.tscn").instantiate()
			p.spell = self
			p.world_hit.connect(nothing.bind())
			p.position = _location(temp_vars)
			var er = _size(temp_vars)
			p.update_shape(er, true)
			return p
			
		_: 
			var p = load("res://Projectiles/fire.tscn").instantiate()
			return p
		
