class_name Spell

enum Element { VOID, FIRE, ROCK, ELECTRIC, WATER, AIR, ICE }
enum ChainCastKind { START, END, HIT }

var element: Element
var name: String
var x: String:
	set(value):
		x = value
		x_expr = Expr.new(value)
var y: String:
	set(value):
		y = value
		y_expr = Expr.new(value)
var z: String:
	set(value):
		z = value
		z_expr = Expr.new(value)
var radius: float:
	set(value):
		radius = clamp(value, 0, UpgradeSettings.LIMIT_r)
var power: float:
	set(value):
		power = clamp(value, 0, UpgradeSettings.LIMIT_P)
var duration: float:
	set(value):
		duration = clamp(value, 0.0166667, UpgradeSettings.LIMIT_T)
var count: int:
	set(value):
		count = clamp(value, 1, UpgradeSettings.LIMIT_N)
var delay: String:
	set(value):
		delay = value
		d_expr = Expr.new(value)
var mana_cost: float = 0.0
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
var d_expr: Expr

var follow: bool
var is_bomb: bool
var player_is_origin: bool
var is_active: bool
var cooldown: float
var charge: float

var expression_strings: Dictionary = {}
var expressions: Dictionary = {}
		

var id: int = -1

var limit_r: float = UpgradeSettings.LIMIT_r
var limit_v: float = UpgradeSettings.LIMIT_v
var buff_r: float = 0.0
var buff_v: float = 0.0
var buff_attack: float = 0.0
var buff_defence: float = 0.0

func _init(_follow: bool = false, _x: String = "0", _y: String = "0", _z: String = "0", _radius: float = 0.1, _power: float = 1, _duration: float = 1.0, _el: Element = Spell.Element.FIRE, _N: int = 1, _delay: String = "0", _is_bomb: bool = false, _mana: float = 0.0, _player_is_origin: bool = false):
	x = _x
	y = _y
	z = _z
	radius = _radius
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
	expression_strings = {}
	
	x_expr = Expr.new(x)
	y_expr = Expr.new(y)
	z_expr = Expr.new(z)
	d_expr = Expr.new(delay)
	
	chain_cast_kind = ChainCastKind.START
	is_active = true
	
func duplicate(override_expr: Dictionary = {}) -> Spell:
	var result := Spell.new(follow, x, y, z, radius, power, duration, element, count, delay, is_bomb, mana_cost, player_is_origin)
	result.chain = chain
	result.chain_cast_kind = chain_cast_kind
	result.name = name
	result.limit_r = limit_r
	result.limit_v = limit_v
	result.buff_r = buff_r
	result.buff_v = buff_v
	result.buff_attack = buff_attack
	result.buff_defence = buff_defence
	result.expression_strings = expression_strings.duplicate()
	if not override_expr.is_empty():
		result.expression_strings.merge(override_expr, true)
	result.build_expressions()
	result.charge = charge
	result.is_active = is_active
	return result
	
func calculate_location(vars: Dictionary, only_delta: bool = false) -> Vector3:
	var result := Vector3.ZERO
	result.x = x_expr.compute(vars)
	result.y = y_expr.compute(vars)
	result.z = z_expr.compute(vars)
	
	if vars.has("old_pos") and not only_delta:
		var old_pos = vars["old_pos"]
		var frame_time = vars.get("__frame_time", 0.0166667)
		var velocity = (result - old_pos) * frame_time
		if not velocity.is_zero_approx():
			result = old_pos + velocity.normalized() * clampf(velocity.length(), 0, (limit_v + buff_v) * frame_time)
		else:
			result = old_pos
		vars["old_pos"] = result
	else:
		vars["old_pos"] = result
	
	if not only_delta:
		result += (vars["rel_pos"] if follow else vars["abs_pos"])
	
	return result
	
func approximate_distance_traveled_at_time(vars: Dictionary, time: float, samples: int = 29) -> float:
	var ft := Vector3.ZERO
	var ftp := Vector3.ZERO
	var temp_vars = vars.duplicate()
	temp_vars["t"] = 0.0
	ftp.x = x_expr.compute(temp_vars)
	ftp.y = y_expr.compute(temp_vars)
	ftp.z = z_expr.compute(temp_vars)
	
	var result := 0.0
	var step := time / float(samples)
	var t := step
	
	# calculate distance
	while t <= time + step:
		temp_vars["t"] = t
		ft.x = x_expr.compute(temp_vars)
		ft.y = y_expr.compute(temp_vars)
		ft.z = z_expr.compute(temp_vars)
		result += ftp.distance_to(ft)
		t += step
		ftp = ft
	
	return result

	
func calculate_delay(vars: Dictionary) -> float:
	var result := clampf(d_expr.compute(vars), 0, 25)
	return result
	
func _mass() -> float:
	match element:
		Element.ROCK: return power * 100.0
		_: return 0
	
func build_expressions():
	for k in expression_strings:
		if expression_strings[k].contains(";"):
			expressions[k] = Expr.new(expression_strings[k].split(";", false, 2)[0])
		else:
			expressions[k] = Expr.new(expression_strings[k])
		
func overwrite_expressions(mappings: Dictionary):
	for k in mappings:
		expressions[k] = Expr.new(mappings[k])
	
func compute_expressions(fvars: Dictionary, additional: Dictionary = {}):
	var temp = {}
	temp.merge(fvars)
	temp.merge(additional)
	for k in expressions:
		fvars[k] = expressions[k].compute(temp)
		temp[k] = fvars[k]
			
func calculate_cooldown() -> float:
	var chain_cost := 0.0
	var basic_cost: float 
	if element == Element.VOID:
		basic_cost = 0.0
	else:
		basic_cost = maxf((power / UpgradeSettings.LIMIT_P) ** 1.25 * 30.0, 1.0) * \
		(duration / UpgradeSettings.LIMIT_T + 1.0) * \
		(((radius + 1) ** 2) / UpgradeSettings.LIMIT_r + 1.0) * \
		(maxf(1.0, count * 0.98))
	if chain != null:
		chain_cost = chain.calculate_cooldown() * count
	cooldown = basic_cost + chain_cost - mana_cost
	if cooldown < 0.0:
		cooldown = 0.0
	return cooldown
	
func actual_mana_cost() -> float:
	var result := mana_cost
	if chain != null:
		result += chain.actual_mana_cost() * count
	return result
	
func damage(vitals: Vitals) -> float:
	match element:
		Element.FIRE: return (power / UpgradeSettings.LIMIT_P) * (vitals.attack.value + buff_attack)
		Element.WATER: return (power / UpgradeSettings.LIMIT_P * 0.1) * vitals.health.value
		Element.AIR: return power
		Element.ROCK: return (power / UpgradeSettings.LIMIT_P) * (vitals.defence.value + buff_defence)
		Element.ICE: return (power / UpgradeSettings.LIMIT_P) * (vitals.health.value * 0.0005 + (vitals.attack.value + buff_attack) * 0.005)
		Element.ELECTRIC: return power
		Element.VOID: return 0.0
	return 0.0
	
const fire = preload("res://Projectiles/fire.tscn")
const rock = preload("res://Projectiles/rock.tscn")
const water = preload("res://Projectiles/water.tscn")
const air = preload("res://Projectiles/air.tscn")
const ice = preload("res://Projectiles/ice.tscn")
const electric = preload("res://Projectiles/electric.tscn")
const _void = preload("res://Projectiles/void.tscn")
const turret = preload("res://Projectiles/turret/turret.tscn")
const turret_mat = preload("res://Projectiles/turret/turret.tres")
	
func get_particle(n: int, fvars: Dictionary, exvars: Dictionary) -> SpellBody:
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
	fixed_vars["T"] = duration
	fixed_vars["P"] = power
	fixed_vars["n"] = float(n)
	fixed_vars["r"] = radius
	fixed_vars.merge(fvars, true)
	compute_expressions(fixed_vars)
	fixed_vars["D"] = d_expr.compute(fixed_vars)
	
	
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
	p.expression_vars = {}
	p.expression_vars.merge(exvars, true)
	compute_expressions(p.expression_vars, fixed_vars)
	p.spell = self
	p.update_shape(radius, true)
	p.position = calculate_location(fixed_vars)
	
	p.lifetime_velocity = approximate_distance_traveled_at_time(fixed_vars, duration, 20) / duration
	p.lifetime_velocity = clamp(p.lifetime_velocity, 0, limit_v + buff_v)
	
	if element == Element.ROCK:
		var origin: Vector3 = fixed_vars.get("abs_pos", Vector3.ZERO)
		var dir: Vector3 = origin.direction_to(p.position)
		var rot_axis = dir.cross(Vector3.BACK).normalized()
		var rot_angle = dir.angle_to(Vector3.BACK)
		if not rot_axis.is_zero_approx():
			p.rotate_object_local(rot_axis, rot_angle)
	
	return p
		
func get_particles(fvars: Dictionary, exvars: Dictionary) -> Array:
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
	fixed_vars["pi"] = PI
	fixed_vars["N"] = float(count)
	fixed_vars["M"] = mana_cost
	fixed_vars["C"] = charge
	fixed_vars["L"] = charge
	charge = 0.0
	fixed_vars.merge(fvars, true)
	for i in range(count):
		var p := get_particle(i, fixed_vars, exvars)
		p.n = i
		p.spell = self
		result.append(p)
	return result
	
func get_turret(n: int, fvars: Dictionary) -> Node3D:
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
	fixed_vars["T"] = duration
	fixed_vars["P"] = power
	fixed_vars["n"] = float(n)
	fixed_vars.merge(fvars, true)
	compute_expressions(fixed_vars)
	fixed_vars["D"] = d_expr.compute(fixed_vars)
	
	
	var p = turret.instantiate()
			
	p.position = calculate_location(fixed_vars)
	
	var mesh: MeshInstance3D = p.get_node("outer") as MeshInstance3D
	var ring: TorusMesh = mesh.mesh as TorusMesh
	ring.inner_radius = radius
	ring.outer_radius = radius + radius * 0.1
	var mat: ShaderMaterial = ring.material as ShaderMaterial
	mat.set_shader_parameter("albedo", Spell.real_color_from_element(element))
	
	ring = p.get_node("mid").mesh
	ring.inner_radius = radius * 0.67
	ring.outer_radius = radius * 0.67 + radius * 0.1
	
	ring = p.get_node("inner").mesh
	ring.inner_radius = radius * 0.25
	ring.outer_radius = radius * 0.25 + radius * 0.1
	
	var anim := p.get_node("AnimationPlayer") as AnimationPlayer
	anim.play("rotate")
	anim.seek(randf() * 2, true)
	
	return p

func save_dict():
	return {
		"x": x, "y": y, "z": z, "r": radius,
		"power": power, "duration": duration, "count": count, "delay": delay,
		"chain": chain.save_dict() if chain else {}, "is_bomb": is_bomb,
		"is_rel": follow, "el": element, "chain_cast_kind": chain_cast_kind,
		"name": name, "id": id, "mana": mana_cost, "player_is_origin": player_is_origin,
		"expression_strings": expression_strings, "is_active": is_active
	}

func load_dict(dict: Dictionary):
	name = dict.get("name", "")
	x = dict["x"]
	y = dict["y"]
	z = dict["z"]
	var temp_r = dict["r"]
	radius = temp_r if temp_r is float else temp_r.to_float()
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
	expression_strings = dict.get("expression_strings", {})
	is_active = dict.get("is_active", false)
	for e in expression_strings:
		expression_strings[e] = expression_strings[e].strip_edges()
	
	x_expr = Expr.new(x)
	y_expr = Expr.new(y)
	z_expr = Expr.new(z)
	d_expr = Expr.new(delay)
	build_expressions()
	
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
		Element.ELECTRIC: return Color.WEB_PURPLE
		Element.VOID: return Color.BLACK
		_: return Color.WHITE
		
static func real_color_from_element(el: Element) -> Color:
	match el:
		Element.FIRE: return Color(1, 0.38, 0)
		Element.ROCK: return Color(0.718, 0.353, 0.141)
		Element.WATER: return Color(0.02, 0.051, 0.502)
		Element.AIR: return Color(0.502, 1, 0.502)
		Element.ICE: return Color(0.133, 0.553, 1)
		Element.ELECTRIC: return Color(0.486, 0, 0.569)
		Element.VOID: return Color.BLACK
		_: return Color.WHITE
