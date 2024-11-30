class_name Spell

enum Element { VOID, FIRE, ROCK, ELECTRIC, WATER, AIR, ICE }
enum ChainCastKind { NONE, START, END, HIT }
const preview_images: Array[String] = [
	"Line 1", "Line 2", "Line 3", "Line 4", "Line 5", "Line 6", 
	"Bomb 1", "Bomb 2", "Bomb 3", "Bomb 4", "Bomb 5", "Bomb 6",
	"Circle 1", "Circle 2", "Circle 3", "Circle 4", "Circle 5", "Circle 6",
	"Outward 1", "Outward 2", "Outward 3", "Outward 4", "Outward 5", "Outward 6",
	"Inward 1", "Inward 2", "Inward 3", "Inward 4", "Inward 5", "Inward 6",
]

var element: Element
var name: String
var preview_image: PackedInt64Array = PackedInt64Array([0])
var preview_flags: PackedInt64Array = PackedInt64Array([0])
enum PreviewFlags {
	FLIP_H = 1 << 0,
	FLIP_V = 1 << 1,
	ROTATE = 0b111 << 2,
	SCALE = 0b111 << 5,
	OFFSET = 0b1111 << 8,
}
var x: String
var y: String
var z: String
var r: String
var power: float:
	set(value):
		power = clamp(value, 0, UpgradeSettings.LIMIT_P)
var duration: float:
	set(value):
		duration = clamp(value, 0.0166667, UpgradeSettings.LIMIT_T)
var count: int:
	set(value):
		count = clamp(value, 1, UpgradeSettings.LIMIT_N)
var delay: String
var mana_cost: float = 0.0
var chain_cast_kind: ChainCastKind = ChainCastKind.NONE:
	set(value):
		chain_cast_kind = value
		calculate_cooldown()
var chain: Spell = null:
	set(spell):
		chain = spell
		calculate_cooldown()

var x_expr: Expr
var y_expr: Expr
var z_expr: Expr
var r_expr: Expr
var radius_cache: float # WARNING: fragile. only use after ensuring a call to basic_fixed_variables first
var d_expr: Expr

var follow: bool
var is_bomb: bool
var player_is_origin: bool
var is_active: bool
var cooldown: float
var charge: float
var elemental_application: float
var crit_rate: float
var crit_dmg: float
var spherical_coords: bool
var ignore_cooldown_when_calculating_elemental_application: bool = false

var expression_strings: Dictionary = {}
var expressions: Dictionary = {}
var time_dependent_vars: Dictionary = {}
		
var id: int = -1

var limit_r: float = UpgradeSettings.LIMIT_r
var limit_v: float = UpgradeSettings.LIMIT_v
var buff_r: float = 0.0
var buff_v: float = 0.0
var buff_attack: float = 0.0
var buff_defence: float = 0.0

var configuration_parameters_for_chain: Dictionary = {}

func _init(_follow: bool = false, _x: String = "0", _y: String = "0", _z: String = "0", _r: String = "0.1", _power: float = 1, _duration: float = 1.0, _el: Element = Spell.Element.FIRE, _N: int = 1, _delay: String = "0", _is_bomb: bool = false, _mana: float = 0.0, _player_is_origin: bool = false, no_comp: bool = false) -> void:
	x = _x
	y = _y
	z = _z
	r = _r
	power = _power
	duration = _duration
	element = _el
	count = _N
	delay = _delay
	mana_cost = _mana
	
	follow = _follow
	is_bomb = _is_bomb
	player_is_origin = _player_is_origin
	charge = 0.0
	expression_strings = {}
	
	crit_rate = 0.0
	crit_dmg = 0.0
	
	spherical_coords = false
	
	is_active = true
	
	if not no_comp:
		x_expr = Expr.new(x)
		y_expr = Expr.new(y)
		z_expr = Expr.new(z)
		d_expr = Expr.new(delay)
		r_expr = Expr.new(r)
		
	
func duplicate(override_expr: Dictionary = {}, for_player: bool = false) -> Spell:
	var result := Spell.new(follow, x, y, z, r, power, duration, element, count, delay, is_bomb, mana_cost, player_is_origin, true)
	result.x_expr = x_expr
	result.y_expr = y_expr
	result.z_expr = z_expr
	result.r_expr = r_expr
	result.d_expr = d_expr
	result.chain = chain
	result.chain_cast_kind = chain_cast_kind
	result.name = name
	result.preview_image = preview_image
	result.preview_flags = preview_flags
	result.crit_rate = crit_rate
	result.crit_dmg = crit_dmg
	result.spherical_coords = spherical_coords
	result.configuration_parameters_for_chain.merge(configuration_parameters_for_chain, true)
	if for_player:
		result.limit_r = limit_r
		result.limit_v = limit_v
		result.buff_r = buff_r
		result.buff_v = buff_v
		result.buff_attack = buff_attack
		result.buff_defence = buff_defence
	result.expression_strings = expression_strings.duplicate()
	if not override_expr.is_empty():
		result.expression_strings.merge(override_expr, true)
	# use build_expressions() if override_expr adds new vars. But we do this copy 
	# for performance reasons
	result.expressions.merge(expressions, true)
	result.time_dependent_vars.merge(time_dependent_vars, true)
	#result.build_expressions()
	#result.expressions = expressions 
	result.elemental_application = elemental_application
	result.cooldown = cooldown
	result.charge = charge
	result.is_active = is_active
	return result
	
@warning_ignore("shadowed_variable")
func configure(constants: Dictionary, element: Spell.Element, duration: float, power: float, radius: float, count: int, crit_rate: float, crit_dmg: float, mana: float, chain: Spell = null, delay: String = "") -> void:
	self.element = element
	if not is_nan(radius):
		self.r = str(radius)
		self.r_expr = Expr.new(self.r)
	if not is_nan(power):
		self.power = power
	if not is_nan(duration):
		self.duration = duration
	if count != 0:
		self.count = count
	if not is_nan(crit_rate):
		self.crit_rate = crit_rate
	if not is_nan(crit_dmg):
		self.crit_dmg = crit_dmg
	if not is_nan(mana):
		self.mana_cost = mana
		ignore_cooldown_when_calculating_elemental_application = true
	if chain != null:
		self.chain = chain
	if not delay.is_empty():
		self.delay = delay
		self.d_expr = Expr.new(delay)
	calculate_cooldown()
	overwrite_expressions(constants)
	
func call_with_parameter_collection_description() -> String:
	var result := name + "("
	result += "element=" + Element.keys()[element] + ","
	result += "r=" + r + ","
	result += "D=" + delay + ","
	result += "P=" + str(power) + ","
	result += "T=" + str(duration) + ","
	result += "N=" + str(count) + ","
	result += "CR=" + str(crit_rate) + ","
	result += "CD=" + str(crit_dmg) + ","
	result += "M=" + str(mana_cost) + ","
	for v: String in expression_strings:
		result += v + "=" + expression_strings[v] + ","
	return result.substr(0, result.length() - 1) + ")"
	
func configure_using_parameter_collection(parameters: Dictionary, vars: Vars) -> void:
	var params := parameters.duplicate()
	if params.has("element"):
		element = Element.keys().find((params["element"] as String).to_upper()) as Element
		params.erase("element")
	if params.has("r"):
		r = params["r"] as String
		r_expr = Expr.new(r)
		params.erase("r")
	if params.has("D"):
		delay = params["D"] as String
		d_expr = Expr.new(delay)
		params.erase("D")
	if params.has("P"):
		power = Expr.new(params["P"] as String).compute_value(vars)
		params.erase("P")
	if params.has("T"):
		duration = Expr.new(params["T"] as String).compute_value(vars)
		params.erase("T")
	if params.has("N"):
		count = roundi(Expr.new(params["N"] as String).compute_value(vars))
		params.erase("N")
	if params.has("CR"):
		crit_rate = Expr.new(params["CR"] as String).compute_value(vars)
		params.erase("CR")
	if params.has("CD"):
		crit_dmg = Expr.new(params["CD"] as String).compute_value(vars)
		params.erase("CD")
	if params.has("M"):
		mana_cost = Expr.new(params["M"] as String).compute_value(vars)
		params.erase("M")
	calculate_cooldown()
	overwrite_expressions(params)
	if chain != null:
		if not configuration_parameters_for_chain.is_empty():
			chain.configure_using_parameter_collection(configuration_parameters_for_chain, global_constant_variables())
	
func set_delay(d: String) -> void:
	delay = d
	d_expr = Expr.new(delay)
	
func set_x(x_: String) -> void:
	x = x_
	x_expr = Expr.new(x)
	
func set_y(y_: String) -> void:
	y = y_
	y_expr = Expr.new(y)
	
func set_z(z_: String) -> void:
	z = z_
	z_expr = Expr.new(z)
	
func set_r(r_: String) -> void:
	r = r_
	r_expr = Expr.new(r)
	
func update_r() -> void:
	var vars := basic_fixed_vars()
	vars.set_value(Vars.r, 0.0)
	radius_cache = r_expr.compute(vars)
	
func calculate_cartesian_point(vars: Vars) -> Vector3:
	var sphere := Vector3.ZERO
	sphere.x = x_expr.compute_value(vars)
	sphere.y = y_expr.compute_value(vars)
	sphere.z = z_expr.compute_value(vars)
	
	var result := Vector3.ZERO
	if spherical_coords:
		result.x = sphere.z * sin(sphere.y) * cos(sphere.x)
		result.y = sphere.z * cos(sphere.y)
		result.z = sphere.z * sin(sphere.y) * sin(sphere.x)
	else:
		result = sphere
	
	return result
	
	
func calculate_location(vars: Vars, only_delta: bool = false, velocity_exceeds_limit: Globals.Ref = null) -> Vector3:
	var result := calculate_cartesian_point(vars)
	
	if vars.has_vector(Vars.old_pos) and not only_delta:
		var old_pos := vars.get_vector(Vars.old_pos)
		var frame_time := vars.get_value(Vars.frame_time)
		var velocity := (result - old_pos)
		if not velocity.is_zero_approx():
			var limit := (limit_v + buff_v) * frame_time
			if velocity_exceeds_limit != null and velocity.length() > limit:
				velocity_exceeds_limit.data = true
				
			var temp := old_pos + velocity.normalized() * clampf(velocity.length(), 0.0, limit)
			result = temp
		else:
			result = old_pos
		vars.set_vector(Vars.old_pos, result)
	else:
		vars.set_vector(Vars.old_pos, result)
	
	if not only_delta:
		result += (vars.get_vector(Vars.rel_pos) if follow else vars.get_vector(Vars.abs_pos))
	
	return result
	
func approximate_distance_traveled_at_time(vars: Vars, time: float, samples: int = 29) -> float:
	var ft := Vector3.ZERO
	var ftp := Vector3.ZERO
	var temp_vars := Vars.new()
	temp_vars.copy_from(vars)
	temp_vars.set_value(Vars.t, 0.0)
	ftp = calculate_cartesian_point(temp_vars)
	
	var fixed_step_result := 0.0
	var frame_step_result := 0.0
	var step := time / randf_range(samples - 5, samples + 5)
	var t := step
	
	# calculate distance 
	while t <= time + step:
		temp_vars.set_value(Vars.t, t)
		ft = calculate_cartesian_point(temp_vars)
		fixed_step_result += ftp.distance_to(ft)
		t += step
		ftp = ft
		
	t = 0.0
	step = time / 60.0 * randf_range(samples - 5, samples + 5)
	while t <= time + step:
		temp_vars.set_value(Vars.t, t)
		ft = calculate_cartesian_point(temp_vars)
		frame_step_result += ftp.distance_to(ft)
		t += step
		ftp = ft
	
	return (fixed_step_result + frame_step_result) / 2.0

	
func calculate_delay(vars: Vars) -> float:
	var result := clampf(d_expr.compute_value(vars), 0, UpgradeSettings.LIMIT_T)
	return result
	
func _mass() -> float:
	match element:
		Element.ROCK: return power * 100.0
		_: return 0
	
func build_expressions() -> void:
	expressions.clear()
	time_dependent_vars.clear()
	for k: String in expression_strings:
		var expr: Expr
		if (expression_strings[k] as String).contains(";"):
			expr = Expr.new((expression_strings[k] as String).split(";", false, 2)[0])
		else:
			expr = Expr.new(expression_strings[k] as String)
		expressions[k] = expr
		if expr.contains_variable("t"):
			time_dependent_vars[k] = true
		elif expr.contains_variable("tu") or expr.contains_variable("tv") or expr.contains_variable("tw"):
			time_dependent_vars[k] = true
		elif expr.contains_variable("tru") or expr.contains_variable("trv") or expr.contains_variable("trw"):
			time_dependent_vars[k] = true
		elif expr.contains_variable("tU") or expr.contains_variable("tV") or expr.contains_variable("tW"):
			time_dependent_vars[k] = true
		elif expr.contains_variable("trU") or expr.contains_variable("trV") or expr.contains_variable("trW"):
			time_dependent_vars[k] = true
		elif expr.contains_variable("ti") or expr.contains_variable("tj") or expr.contains_variable("tk"):
			time_dependent_vars[k] = true
		elif expr.contains_variable("tri") or expr.contains_variable("trj") or expr.contains_variable("trk"):
			time_dependent_vars[k] = true
		elif expr.contains_variable("tI") or expr.contains_variable("tJ") or expr.contains_variable("tK"):
			time_dependent_vars[k] = true
		elif expr.contains_variable("trI") or expr.contains_variable("trJ") or expr.contains_variable("trK"):
			time_dependent_vars[k] = true
		else:
			for variable: String in time_dependent_vars:
				if expr.contains_variable(variable):
					time_dependent_vars[k] = true
		
func overwrite_expressions(mappings: Dictionary) -> void:
	# FIXME: speed up
	for k: String in mappings:
		expression_strings[k] = mappings[k]
		var expr := Expr.new(mappings[k] as String)
		expressions[k] = expr
		
	time_dependent_vars.clear()
	for k: String in expressions:
		var expr := expressions[k] as Expr
		if expr.contains_variable("t"):
			time_dependent_vars[k] = true
		elif expr.contains_variable("tu") or expr.contains_variable("tv") or expr.contains_variable("tw"):
			time_dependent_vars[k] = true
		elif expr.contains_variable("tru") or expr.contains_variable("trv") or expr.contains_variable("trw"):
			time_dependent_vars[k] = true
		elif expr.contains_variable("tU") or expr.contains_variable("tV") or expr.contains_variable("tW"):
			time_dependent_vars[k] = true
		elif expr.contains_variable("trU") or expr.contains_variable("trV") or expr.contains_variable("trW"):
			time_dependent_vars[k] = true
		elif expr.contains_variable("ti") or expr.contains_variable("tj") or expr.contains_variable("tk"):
			time_dependent_vars[k] = true
		elif expr.contains_variable("tri") or expr.contains_variable("trj") or expr.contains_variable("trk"):
			time_dependent_vars[k] = true
		elif expr.contains_variable("tI") or expr.contains_variable("tJ") or expr.contains_variable("tK"):
			time_dependent_vars[k] = true
		elif expr.contains_variable("trI") or expr.contains_variable("trJ") or expr.contains_variable("trK"):
			time_dependent_vars[k] = true
		else:
			for variable: String in time_dependent_vars:
				if expr.contains_variable(variable):
					time_dependent_vars[k] = true
	
func compute_expressions(fvars: Vars, additional: Vars = null, only_time_dependent: bool = false) -> void:
	var temp := Vars.new()
	temp.copy_from(fvars)
	if additional != null:
		temp.merge(additional, false)
	for k: String in (time_dependent_vars if only_time_dependent else expressions):
		var e := expressions[k] as Expr
		if e.contains_variable(k): # handle recursion by placing value in temp storage
			if fvars.has("~" + k):
				temp.set_raw(k, fvars.get_raw_now("~" + k))
				var val: Variant = e.compute(temp)
				fvars.set_raw(k, val)
				temp.set_raw(k, val)
			else:
				var val: Variant = e.compute(temp)
				fvars.set_raw(k, val)
				temp.set_raw(k, val)
				temp.set_raw("~" + k, val)
		else:
			var val: Variant = e.compute(temp)
			fvars.set_raw(k, val)
			temp.set_raw(k, val)
			
func find_chain_list(include_self: bool) -> PackedStringArray:
	var result := PackedStringArray([])
	var s := chain
	if include_self:
		result.append(name)
	while s != null:
		result.append(s.name)
		s = s.chain
	return result
			
func calculate_cooldown() -> float:
	var chain_cost := 0.0
	var basic_cost: float 
	update_r()
	if element == Element.VOID:
		basic_cost = 0.0
	else:
		var radius := radius_cache
		var no_crit_hit := power / UpgradeSettings.LIMIT_P
		var crit_hit := no_crit_hit * (1.0 + crit_dmg / 100.0)
		var rate := clampf(crit_rate / 100.0, 0.0, 1.0)
		var avg_dmg := crit_hit * rate + no_crit_hit * (1.0 - rate)
		basic_cost = maxf(avg_dmg ** 1.25 * 30.0, 1.0) * \
		(duration / UpgradeSettings.LIMIT_T + 1.0) * \
		(((radius + 1) ** 2) / UpgradeSettings.LIMIT_r + 1.0) * \
		(maxf(1.0, count * 0.98))
	if chain_cast_kind != ChainCastKind.NONE and chain != null:
		chain_cost = chain.calculate_cooldown() * count
		
	elemental_application = clampf(power / UpgradeSettings.LIMIT_P * 0.25, 0.0, 0.25)
	if ignore_cooldown_when_calculating_elemental_application:
		elemental_application += clampf(mana_cost / 100.0, 0.0, 0.75)
	else:
		elemental_application += clampf((mana_cost - (basic_cost + chain_cost)) / 100, 0.0, 0.75)
	elemental_application = clampf(elemental_application, 0.0, 1.0)
		
	if chain_cast_kind == ChainCastKind.HIT:
		cooldown = (basic_cost if element != Element.VOID else maxf(1.0, count * 0.98)) * chain_cost - mana_cost
	else:
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
	var crit := (1.0 + crit_dmg / 100.0) if (crit_rate / 100.0) >= randf() else 1.0
	var atk := vitals.attack.value + buff_attack
	var p := power / UpgradeSettings.LIMIT_P
	p = pow(1 - (p - 1) * (p - 1), 0.6913)
	match element:
		Element.FIRE    : return p * (      atk                                               ) * crit
		Element.WATER   : return p * (0.5 * atk + 0.05 * vitals.health.value                  ) * crit
		Element.AIR     : return p * (0.5 * atk + 0.05 * vitals.mana.max_value                ) * crit
		Element.ROCK    : return p * (0.5 * atk + 0.5  * (vitals.defence.value + buff_defence)) * crit
		Element.ICE     : return p * (0.5 * atk + 0.05 * vitals.health.max_value              ) * crit
		Element.ELECTRIC: return p * (0.5 * atk + 0.05 * vitals.mana.value                    ) * crit
		Element.VOID    : return 0.0
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
	
func get_particle(n: int, fvars: Vars, exvars: Vars) -> SpellBody:
	var fixed_vars := Vars.new()
	fixed_vars.copy_from(fvars)
	fixed_vars.set_value(Vars.rn0, randf())
	fixed_vars.set_value(Vars.rn1, randf())
	fixed_vars.set_value(Vars.rn2, randf())
	fixed_vars.set_value(Vars.rn3, randf())
	fixed_vars.set_value(Vars.rn4, randf())
	fixed_vars.set_value(Vars.rn5, randf())
	fixed_vars.set_value(Vars.rn6, randf())
	fixed_vars.set_value(Vars.rn7, randf())
	fixed_vars.set_value(Vars.rn8, randf())
	fixed_vars.set_value(Vars.rn9, randf())
	fixed_vars.set_value(Vars.n, float(n))
	compute_expressions(fixed_vars)
	fixed_vars.set_value(Vars.D, d_expr.compute_value(fixed_vars))
	
	
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
	p.expression_vars = Vars.new()
	p.expression_vars.copy_from(exvars)
	compute_expressions(p.expression_vars, fixed_vars)
	p.spell = self
	p.rotation_angle = clampf(fixed_vars.get_value(Vars.spinrate), -2 * PI, 2 * PI)
	p.position = calculate_location(fixed_vars)
	
	var nr := Vector3(1, 0.2 if element == Element.ICE else 1.0, 1).normalized()
	var radius := fixed_vars.get_value(Vars.r)
	if fixed_vars.has("size"):
		var temp_nr: Variant = fixed_vars.get_raw_now("size")
		if temp_nr is Vector3:
			nr = (temp_nr as Vector3).normalized() * radius
		elif temp_nr is float or temp_nr is int:
			nr = nr * radius * clampf(temp_nr as float, 0, 1)
	else:
		nr = nr * radius
	if is_zero_approx(nr.length()):
		nr = Vector3(1, 0.2 if element == Element.ICE else 1.0, 1).normalized() * 0.1
	p.update_shape(nr, true)
	
	p.lifetime_velocity = approximate_distance_traveled_at_time(fixed_vars, duration, 20) / duration
	p.lifetime_velocity = clamp(p.lifetime_velocity, 0, limit_v + buff_v)
	
	fixed_vars.set_value(Vars.t, 0.0)
	var base_pos := calculate_cartesian_point(fixed_vars)
	fixed_vars.set_value(Vars.t, 0.016667)
	var next_pos := calculate_cartesian_point(fixed_vars)
	fixed_vars.set_value(Vars.t, 0.0)
	var dir: Vector3 = next_pos - base_pos
	Globals.look_at(p, dir)
	
	return p
		
func get_particles(fvars: Vars, exvars: Vars) -> Array[SpellBody]:
	var result: Array[SpellBody] = []
	var fixed_vars := basic_fixed_vars()
	charge = 0.0
	fixed_vars.merge(fvars, true)
	for i in range(count):
		var p := get_particle(i, fixed_vars, exvars)
		p.n = i
		p.spell = self
		result.append(p)
	return result
	
const fixed_var_list = [
	"pi", "N", "M", "C", "L", "T", "P", "CR", "CD", "x", "y", "z", "r", "n", "D",
]
	
func basic_fixed_vars() -> Vars:
	var fixed_vars := Vars.new()
	fixed_vars.set_value(Vars.r0, randf())
	fixed_vars.set_value(Vars.r1, randf())
	fixed_vars.set_value(Vars.r2, randf())
	fixed_vars.set_value(Vars.r3, randf())
	fixed_vars.set_value(Vars.r4, randf())
	fixed_vars.set_value(Vars.r5, randf())
	fixed_vars.set_value(Vars.r6, randf())
	fixed_vars.set_value(Vars.r7, randf())
	fixed_vars.set_value(Vars.r8, randf())
	fixed_vars.set_value(Vars.r9, randf())
	fixed_vars.set_value(Vars.pi, PI)
	fixed_vars.set_value(Vars.N, float(count))
	fixed_vars.set_value(Vars.M, mana_cost)
	fixed_vars.set_value(Vars.C, charge)
	fixed_vars.set_value(Vars.L, charge)
	fixed_vars.set_value(Vars.T, duration)
	fixed_vars.set_value(Vars.P, power)
	fixed_vars.set_value(Vars.CR, crit_rate)
	fixed_vars.set_value(Vars.CD, crit_dmg)
	fixed_vars.set_value(Vars.x, 0)
	fixed_vars.set_value(Vars.y, 1)
	fixed_vars.set_value(Vars.z, 2)
	fixed_vars.set_value(Vars.r, radius_cache)
	return fixed_vars
	
func global_constant_variables() -> Vars:
	var result := basic_fixed_vars()
	for key: String in expressions:
		result.set_raw(key, (expressions[key] as Expr).compute(result))
	return result
	
func get_turret(n: int, fvars: Vars) -> Node3D:
	var fixed_vars := Vars.new()
	fixed_vars.set_value(Vars.rn0, randf())
	fixed_vars.set_value(Vars.rn1, randf())
	fixed_vars.set_value(Vars.rn2, randf())
	fixed_vars.set_value(Vars.rn3, randf())
	fixed_vars.set_value(Vars.rn4, randf())
	fixed_vars.set_value(Vars.rn5, randf())
	fixed_vars.set_value(Vars.rn6, randf())
	fixed_vars.set_value(Vars.rn7, randf())
	fixed_vars.set_value(Vars.rn8, randf())
	fixed_vars.set_value(Vars.rn9, randf())
	fixed_vars.set_value(Vars.n, float(n))
	fixed_vars.merge(fvars, true)
	compute_expressions(fixed_vars)
	fixed_vars.set_value(Vars.D, d_expr.compute_value(fixed_vars))
	
	var p := turret.instantiate() as Node3D
			
	p.position = calculate_location(fixed_vars)
	
	var radius := fixed_vars.get_value(Vars.r)
	var mesh: MeshInstance3D = p.get_node("outer") as MeshInstance3D
	var ring: TorusMesh = mesh.mesh as TorusMesh
	ring.inner_radius = radius
	ring.outer_radius = radius + radius * 0.1
	var mat: ShaderMaterial = ring.material as ShaderMaterial
	mat.set_shader_parameter("albedo", Spell.real_color_from_element(element))
	
	ring = (p.get_node("mid") as MeshInstance3D).mesh
	ring.inner_radius = radius * 0.67
	ring.outer_radius = radius * 0.67 + radius * 0.1
	
	ring = (p.get_node("inner") as MeshInstance3D).mesh
	ring.inner_radius = radius * 0.25
	ring.outer_radius = radius * 0.25 + radius * 0.1
	
	var anim := p.get_node("AnimationPlayer") as AnimationPlayer
	anim.play("rotate")
	anim.seek(randf() * 2, true)
	
	return p

func save_dict() -> Dictionary:
	var pimages: Array[int] = []
	var pflags: Array[int] = []
	pimages.assign(preview_image)
	pflags.assign(preview_flags)
	return {
		"x": x, "y": y, "z": z, "r": r,
		"power": power, "duration": duration, "count": count, "delay": delay,
		"chain": chain.save_dict() if chain else {}, "is_bomb": is_bomb,
		"is_rel": follow, "el": element, "chain_cast_kind": chain_cast_kind,
		"name": name, "id": id, "mana": mana_cost, "player_is_origin": player_is_origin,
		"expression_strings": expression_strings, "is_active": is_active, 
		"elemental_application": elemental_application, "crit_rate": crit_rate, "crit_dmg": crit_dmg,
		"spherical_coords": spherical_coords, "preview_image": pimages, "preview_flags": pflags,
		"configuration_parameters_for_chain": configuration_parameters_for_chain,
	}

func load_dict(dict: Dictionary) -> void:
	name = dict.get("name", "") as String
	if dict.get("preview_image", 0) is int:
		preview_image = PackedInt64Array([0])
	else:
		preview_image = PackedInt64Array(dict.get("preview_image", [0]) as Array[int])
	if dict.get("preview_flags", 0) is int:
		preview_flags = PackedInt64Array([0])
	else:
		preview_flags = PackedInt64Array(dict.get("preview_flags", [0]) as Array[int])
	if preview_image.size() != preview_flags.size():
		while preview_image.size() < preview_flags.size(): preview_image.append(0)
		while preview_image.size() > preview_flags.size(): preview_flags.append(0)
	x = dict["x"] as String
	y = dict["y"] as String
	z = dict["z"] as String
	r = str(dict["r"])
	power = dict["power"]
	duration = dict["duration"]
	element = dict["el"]
	count = dict["count"]
	delay = dict["delay"]
	is_bomb = dict.get("is_bomb", false)
	follow = dict["is_rel"]
	crit_rate = dict.get("crit_rate", 0.0)
	crit_dmg = dict.get("crit_dmg", 0.0)
	spherical_coords = dict.get("spherical_coords", false)
	charge = 0.0
	id = dict.get("id", -1)
	mana_cost = dict.get("mana", 0.0)
	chain_cast_kind = dict.get("chain_cast_kind", 0) as ChainCastKind
	player_is_origin = dict.get("player_is_origin", true)
	expression_strings = dict.get("expression_strings", {})
	is_active = dict.get("is_active", false)
	elemental_application = dict.get("elemental_application", 0.0)
	configuration_parameters_for_chain = dict.get("configuration_parameters_for_chain", {})
	for e: String in expression_strings:
		expression_strings[e] = (expression_strings[e] as String).strip_edges()
	
	x_expr = Expr.new(x)
	y_expr = Expr.new(y)
	z_expr = Expr.new(z)
	d_expr = Expr.new(delay)
	r_expr = Expr.new(r)
	build_expressions()
	
	if dict["chain"] != {}:
		chain = Spell.new()
		chain.load_dict(dict["chain"] as Dictionary)
		chain.configure_using_parameter_collection(configuration_parameters_for_chain, global_constant_variables())
	
	calculate_cooldown()
	
func elemental_application_description() -> String:
	match element:
		Element.FIRE: return " [img=l,24x24, color=FF0000]res://GUI/Images/fire.svg[/img] Burn: %d%%" % int(elemental_application * 100)
		Element.WATER: return " [img=l,24x24, color=0080FF]res://GUI/Images/water.svg[/img] Wet: %d%%" % int(elemental_application * 100)
		Element.ICE: return " [img=l,24x24, color=00FFFF]res://GUI/Images/ice.svg[/img] Freeze: %d%%" % int(elemental_application * 100)
		Element.ELECTRIC: return " [img=l,24x24, color=FF0080]res://GUI/Images/electric.svg[/img] Stun: %d%%" % int(elemental_application * 100)
		Element.AIR: return " [img=l,24x24, color=00FF80]res://GUI/Images/wind.svg[/img] Feather: x%d" % int(clampf(elemental_application * 100, 1, 100))
	return ""
	
func make_gdscript_init(variable_name: String, wrap_in_function: bool = false) -> String:
	var indent := func(lines: String, indent: String) -> String:
		return lines.replace("\n", "\n%s" % indent)
	
	var repr_element := func(v: Element) -> String:
		match v as Element:
			Element.VOID: return "Spell.Element.VOID"
			Element.FIRE: return "Spell.Element.FIRE"
			Element.ROCK: return "Spell.Element.ROCK"
			Element.ELECTRIC: return "Spell.Element.ELECTRIC"
			Element.WATER: return "Spell.Element.WATER"
			Element.AIR: return "Spell.Element.AIR"
			Element.ICE: return "Spell.Element.ICE"
		return "0"
		
	var repr_chain_cast_kind := func(v: ChainCastKind) -> String:
		match v as ChainCastKind:
			ChainCastKind.NONE: return "Spell.ChainCastKind.NONE"
			ChainCastKind.START: return "Spell.ChainCastKind.START"
			ChainCastKind.END: return "Spell.ChainCastKind.END"
			ChainCastKind.HIT: return "Spell.ChainCastKind.HIT"
		return "0"
		
	var repr := func(v: Variant) -> String:
		return var_to_str(v)
		
	var iden := func(s: String) -> String:
		return s.replace("-", "_").replace(" ", "_").replace("+", "_")
	
	variable_name = iden.call(variable_name)
	var chain_name := "null"
	var chain_creation := ""
	if chain != null:
		chain_name = "%s_%s" % [variable_name, iden.call(chain.name)]
		chain_creation = chain.make_gdscript_init(chain_name)
	
	var result := """%s
var %s := Spell.new(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
%s.chain = %s
%s.chain_cast_kind = %s
%s.name = %s
%s.limit_r = %s
%s.limit_v = %s
%s.buff_r = %s
%s.buff_v = %s
%s.buff_attack = %s
%s.buff_defence = %s
%s.expression_strings = %s
%s.build_expressions()
%s.calculate_cooldown()
%s.charge = %s
%s.is_active = %s
%s.crit_rate = %s
%s.crit_dmg = %s
%s.spherical_coords = %s
""" % [
	chain_creation,
	variable_name, repr.call(follow), repr.call(x), repr.call(y), repr.call(z),
	repr.call(r), repr.call(power), repr.call(duration), repr_element.call(element), 
	repr.call(count), repr.call(delay), repr.call(is_bomb), repr.call(mana_cost), 
	repr.call(player_is_origin),
	variable_name, chain_name,	
	variable_name, repr_chain_cast_kind.call(chain_cast_kind),
	variable_name, repr.call(name),
	variable_name, repr.call(limit_r),
	variable_name, repr.call(limit_v),
	variable_name, repr.call(buff_r),
	variable_name, repr.call(buff_v),
	variable_name, repr.call(buff_attack),
	variable_name, repr.call(buff_defence),
	variable_name, repr.call(expression_strings),
	variable_name,
	variable_name,
	variable_name, repr.call(charge),
	variable_name, repr.call(is_active),
	variable_name, repr.call(crit_rate),
	variable_name, repr.call(crit_dmg),
	variable_name, repr.call(spherical_coords)
]

	if wrap_in_function:
		return """func make_spell_%s() -> Spell:%s
\treturn %s
""" % [variable_name, indent.call(result, "\t"), variable_name]
	else:
		return result
	
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
		
static func collision_layer_from_element(el: Element) -> int:
	match el:
		Element.FIRE: return Globals.Layer.FIRE
		Element.ROCK: return Globals.Layer.ROCK
		Element.WATER: return Globals.Layer.WATER
		Element.AIR: return Globals.Layer.AIR
		Element.ICE: return Globals.Layer.ICE
		Element.ELECTRIC: return Globals.Layer.ELECTRIC
		Element.VOID: return 0b0000_0000
		_: return 0

static func color_from_element(el: Element) -> Color:
	if el == Element.VOID:
		return Color(0.25, 0.25, 0.25)
	else:
		return Artifact.color_for_element(el as Artifact.Element)
		
static func real_color_from_element(el: Element) -> Color:
	match el:
		Element.FIRE: return Color(1, 0.38, 0)
		Element.ROCK: return Color(0.718, 0.353, 0.141)
		Element.WATER: return Color(0.02, 0.051, 0.502)
		Element.AIR: return Color(0.502, 1, 0.502)
		Element.ICE: return Color(0.133, 0.553, 1)
		Element.ELECTRIC: return Color(0.486, 0, 0.569)
		Element.VOID: return Color(0.25, 0.25, 0.25)
		_: return Color.WHITE

func bake(new_name: String) -> Spell: 
	var bx := GDExpr.bake(x, expression_strings)
	var by := GDExpr.bake(y, expression_strings)
	var bz := GDExpr.bake(z, expression_strings)
	var bd := GDExpr.bake(delay, expression_strings)
	var br := GDExpr.bake(r, expression_strings)
	var result := Spell.new(follow, bx, by, bz, br, power, duration, element, count, bd, is_bomb, mana_cost, player_is_origin)
	result.chain = chain
	result.chain_cast_kind = chain_cast_kind
	result.name = new_name
	result.limit_r = limit_r
	result.limit_v = limit_v
	result.buff_r = buff_r
	result.buff_v = buff_v
	result.buff_attack = buff_attack
	result.buff_defence = buff_defence
	result.crit_rate = crit_rate
	result.crit_dmg = crit_dmg
	result.spherical_coords = spherical_coords
	result.expression_strings = {}
	result.build_expressions()
	result.calculate_cooldown()
	result.charge = charge
	result.is_active = is_active
	return result

func generate_image_preview(size: Vector2, caster: SpellCaster, player: Player, samples: int) -> Image:
	var img := Image.create_empty(floori(size.x), floori(size.y), false, Image.Format.FORMAT_RGBA8)
	
	var vars := caster.all_spell_variables(player, null, self)
	var ft := Vector3.ZERO
	var step := duration / samples
	
	var ps := get_particles(vars, null)
	for p in ps:
		var t := 0.0
		var minv := Vector3(INF, INF, INF)
		var maxv := Vector3(-INF, -INF, -INF)
		var coords := PackedVector3Array([])
		var temp_vars := Vars.new()
		temp_vars.copy_from(p.fixed_vars)
		temp_vars.set_value(Vars.C, 5.0)
		while t <= duration + step:
			temp_vars.set_value(Vars.t, t)
			compute_expressions(temp_vars, null, true)
			ft = calculate_cartesian_point(temp_vars)
			t += step
			coords.append(ft)
			minv = minv.min(ft)
			maxv = maxv.max(ft)
		
		var rangev := maxv - minv
		rangev = Vector3(maxf(rangev.x, rangev.z), rangev.y, maxf(rangev.x, rangev.z))
		for i in coords.size():
			var c := coords[i]
			c = (c - Vector3(0, minv.y, 0)) / rangev 
			if is_nan(c.x) or is_inf(c.x): c.x = 0.0
			if is_nan(c.y) or is_inf(c.y): c.y = 0.0
			if is_nan(c.z) or is_inf(c.z): c.z = 0.0
			c = c * Vector3(size.x, 0.05, size.y) * 0.5 + Vector3(size.x, 0.05, size.y) * 0.5
			coords[i] = c
		
		var clr := color_from_element(element)
		for i in coords.size():
			var c := coords[i]
			var a := 0.25 + i / float(coords.size()) * 0.75
			var hs := size * c.y
			clr.a = a
			img.fill_rect(Rect2i(roundi(c.x - hs.x * 0.5), roundi(c.z - hs.y * 0.5), roundi(hs.x), roundi(hs.y)), Color.BLACK.blend(clr))
		
	return img
	
func preview_is_horizontal_flip(idx: int) -> bool:
	return (preview_flags[idx] & PreviewFlags.FLIP_H) != 0
	
func set_preview_is_horizontal_flip(idx: int, is_set: bool) -> void:
	if is_set:
		preview_flags[idx] = preview_flags[idx] | PreviewFlags.FLIP_H
	else:
		preview_flags[idx] = preview_flags[idx] & ~PreviewFlags.FLIP_H
	
func preview_is_vertical_flip(idx: int) -> bool:
	return (preview_flags[idx] & PreviewFlags.FLIP_V) != 0
	
func set_preview_is_vertical_flip(idx: int, is_set: bool) -> void:
	if is_set:
		preview_flags[idx] = preview_flags[idx] | PreviewFlags.FLIP_V
	else:
		preview_flags[idx] = preview_flags[idx] & ~PreviewFlags.FLIP_V
	
func preview_rotation_tag(idx: int) -> int:
	return (preview_flags[idx] & PreviewFlags.ROTATE) >> 2
	
func set_preview_rotation_tag(idx: int, tag: int) -> void:
	preview_flags[idx] = preview_flags[idx] & ~PreviewFlags.ROTATE
	preview_flags[idx] = preview_flags[idx] | ((tag & 0b111) << 2)
	
func preview_rotation(idx: int) -> float:
	return (preview_rotation_tag(idx) / 8.0) * 2.0 * PI

func preview_scale_tag(idx: int) -> int:
	return (preview_flags[idx] & PreviewFlags.SCALE) >> 5
	
func set_preview_scale_tag(idx: int, tag: int) -> void:
	preview_flags[idx] = preview_flags[idx] & ~PreviewFlags.SCALE
	preview_flags[idx] = preview_flags[idx] | ((tag & 0b111) << 5)
	
func preview_scale(idx: int) -> Vector2:
	var s := preview_scale_tag(idx) + 8
	if s > 8:
		s -= 8
	var result := s / 8.0
	return Vector2(result, result)
	
func preview_offset_tag(idx: int) -> int:
	return (preview_flags[idx] & PreviewFlags.OFFSET) >> 8
	
func set_preview_offset_tag(idx: int, tag: int) -> void:
	preview_flags[idx] = preview_flags[idx] & ~PreviewFlags.OFFSET
	preview_flags[idx] = preview_flags[idx] | ((tag & 0b1111) << 8)
	
func preview_offset(idx: int) -> Vector2:
	var tag := preview_offset_tag(idx)
	var p33 := (1.0 / 3.0) - (1.0 / 9.0)
	var p66 := (2.0 / 3.0) + (1.0 / 9.0)
	match tag:
		0: return Vector2(0.5, 0.5)   # center
		
		1: return Vector2(0.25, 0.25) # 2x2 top left
		2: return Vector2(0.75, 0.25) # 2x2 top right
		3: return Vector2(0.25, 0.75) # 2x2 bottom left
		4: return Vector2(0.75, 0.75) # 2x2 bottom right
		
		5: return Vector2(p33, p33) # 3x3 top left
		6: return Vector2(0.5, p33) # 3x3 top center
		7: return Vector2(p66, p33) # 3x3 top right
		
		8: return Vector2(p33, 0.5) # 3x3 center left
		9: return Vector2(p66, 0.5) # 3x3 center right
		
		10: return Vector2(p33, p66) # 3x3 bottom left
		11: return Vector2(0.5, p66) # 3x3 bottom center
		12: return Vector2(p66, p66) # 3x3 bottom right
		
	return Vector2(0.5, 0.5)

func create_thumbnail(is_small: bool, cache: Dictionary) -> Texture2D:
	var size := "small" if is_small else "large"
	var result := MultiTexture.new()
	for i in preview_image.size():
		if not cache.has(preview_image[i]):
			var tex := load("res://GUI/Images/Spell Preview/[%s] %s.svg" % [size, preview_images[preview_image[i]]])
			cache[preview_image[i]] = tex
		var tinted := TintedTexture.new()
		tinted.stretch_mode = TextureRect.StretchMode.STRETCH_TILE
		tinted.texture = cache[preview_image[i]]
		tinted.tint = Spell.color_from_element(element)
		tinted.flip_horizontal = preview_is_horizontal_flip(i)
		tinted.flip_vertical = preview_is_vertical_flip(i)
		tinted.rotation = preview_rotation(i)
		tinted.scale = preview_scale(i)
		tinted.offset = preview_offset(i)
		result.texture.append(tinted)
		
	return result

func chain_configuration_call_text() -> String:
	if chain == null:
		return ""
	var result := chain.name
	if not configuration_parameters_for_chain.is_empty():
		result += "("
		var j := 0
		for k: String in configuration_parameters_for_chain:
			result += k + " = " + configuration_parameters_for_chain[k]
			if j < configuration_parameters_for_chain.size() - 1:
				result += ", "
			j += 1
		result += ")"
	return result
