class_name Vitals

class Stat:
	@export var min_value: float
	@export var max_value: float
	@export var value: float
	@export var change_per_tick: float
	@export var resistance: float
	
	func _init(v: float, min_v: float, max_v: float, change: float = 0, res: float = 0):
		value = v
		min_value = min_v
		max_value = max_v
		change_per_tick = change
		resistance = res
		
	func amount_of_change(p: float) -> float:
		return clampf((1 - resistance) * p, min_value, max_value)
		
	func apply_ignoring_resistance(amount: float):
		value = clampf(value + amount, min_value, max_value)
		
	func apply(p: float):
		apply_ignoring_resistance(amount_of_change(p))
		
	func update_per_tick() -> float:
		apply_ignoring_resistance(change_per_tick)
		return change_per_tick
		
	func percentage() -> float:
		return value / (max_value - min_value)
		

var health: Stat
var mana: Stat
var aggression: Stat
var attack: Stat
var defence: Stat

var burning: Stat
var wetness: Stat
var freeze: Stat
var stun: Stat

var hunger: Stat
var thirst: Stat
var perception: Stat

var damage_resistance: Dictionary # Artifact.Element -> Vector2 (flat, percentage)


func _init(_health: Stat, _mana: Stat, _burning := Stat.new(0, 0, 1, -0.05), _wetness := Stat.new(0, 0, 1, -0.001), _freeze := Stat.new(0, 0, 1, -0.01), _stun := Stat.new(0, 0, 1.0, -0.25)):
	health = _health
	mana = _mana
	burning = _burning
	wetness = _wetness
	freeze = _freeze
	stun = _stun
	attack = Stat.new(10, 0, 100)
	defence = Stat.new(10, 0, 100)
	hunger = Stat.new(0, 0, 0)
	thirst = Stat.new(0, 0, 0)
	perception = Stat.new(50, 0, 100)
	aggression = Stat.new(0, 0, 1)
	damage_resistance = {}

func handle_damage(kind: Spell.Element, power: float, gauge: float) -> Dictionary:
	match kind:
		Spell.Element.FIRE:
			var amount = burning.amount_of_change(gauge / 100.0)
			if wetness.value <= 0 and freeze.value <= 0:
				burning.apply_ignoring_resistance(amount)
			else:
				power = power * 0.5
			wetness.apply_ignoring_resistance(-amount)
			freeze.apply_ignoring_resistance(-amount * 1.5)
		Spell.Element.WATER:
			var amount = wetness.amount_of_change(gauge / 100.0)
			if burning.value <= 0:
				wetness.apply_ignoring_resistance(amount)
			else:
				power = power * 0.5
			burning.apply_ignoring_resistance(-amount)
			freeze.apply_ignoring_resistance(amount * freeze.value)
		Spell.Element.ICE:
			var amount = freeze.amount_of_change(wetness.value * gauge / 100.0)
			if wetness.value > 0:
				freeze.apply_ignoring_resistance(amount)
				wetness.apply_ignoring_resistance(-amount)
			if burning.value > 0:
				power = power * 0.25
			burning.apply_ignoring_resistance(-amount)
		Spell.Element.ELECTRIC:
			var amount = stun.amount_of_change(maxf(wetness.value, burning.value) * gauge / 100.0)
			stun.apply_ignoring_resistance(amount)
		Spell.Element.AIR:
			power = 0.0
		Spell.Element.VOID:
			power = 0.0
			
	for e in damage_resistance:
		var def := defence.value / (defence.value + 500)
		power = power * (1.0 - def)
		if e == kind or e == Artifact.Element.ANY:
			power = power * (1.0 - damage_resistance[e].y) - damage_resistance[e].x
	health.apply_ignoring_resistance(-power)
	print("power: ", power, ", gauge: ", gauge)
	print("health: ", health.value, ", burning: ", burning.value, ", wetness: ", wetness.value, ", freeze: ", freeze.value, ", stun: ", stun.value)
	print("element: ", Spell.name_from_element(kind))
	
	return {"dmg": power, "el": kind}

func update_vitals(body: Node3D) -> Array:
	freeze.update_per_tick()
	wetness.update_per_tick()
	burning.update_per_tick()
	stun.update_per_tick()
	var h = health.update_per_tick()
	var result = [{"dmg": h, "el": Spell.Element.FIRE}]
	mana.update_per_tick()
	if burning.value > 0:
		var burn_damage := int(burning.value * health.max_value * 0.05)
		health.apply_ignoring_resistance(-burn_damage)
		result.append({"dmg": burn_damage, "el": Spell.Element.FIRE})
		
	hunger.update_per_tick()
	thirst.update_per_tick()
	
	var effect: Node3D
	
	effect = body.find_child("burn_effect", false, false)
	if effect != null:
		if burning.value == 0.0:
			body.remove_child(effect)
		else:
			var source = effect.get_node("source")
			source.process_material.scale_min = burning.value
			source.process_material.scale_max = burning.value
		
	effect = body.find_child("stun_effect", false, false)
	if effect != null:
		if stun.value == 0.0:
			body.remove_child(effect)
		else:
			var source = effect.get_node("source")
			var mat: ShaderMaterial = source.draw_pass_1.surface_get_material(0)
			mat.set_shader_parameter("len", 2.5 * stun.value)
			
	effect = body.find_child("wet_effect", false, false)
	if effect != null:
		if wetness.value == 0.0:
			body.remove_child(effect)
		else:
			var source = effect.get_node("source")
			source.process_material.scale_max = wetness.value
			
	effect = body.find_child("freeze_effect", false, false)
	if effect != null:
		if freeze.value == 0.0:
			body.remove_child(effect)
		else:
			var source = effect.get_node("source")
			source.amount = int(freeze.value * 100)
				
	return result

func wetness_scale():
	return 1 + wetness.value

static func apply_damage(world: Node3D, body: Node3D, amount: float, element: Spell.Element, show_label: bool, show_exp: bool, locations: Array[Vector3], r: float = 0, v: Vector3 = Vector3.ZERO):
	amount = int(clamp(amount, 0, 100))
	if amount <= 0:
		return
	
	if show_label:	
		var lbl = load("res://Projectiles/explosion/BodyMessage.tscn").instantiate()
		var collision: CollisionShape3D = body.get_node("Collision")
		if collision.shape is BoxShape3D:
			lbl.position.y = collision.shape.size.y
		elif collision.shape is SphereShape3D:
			lbl.position.y = collision.shape.radius
		lbl.text = str(int(amount))
		body.add_child(lbl)
		var clr = Spell.color_from_element(element)
		lbl.set_rise_modulate(clr, clr.lerp(Color.TRANSPARENT, 1.0))
		lbl.set_rise_outline_modulate(clr.darkened(0.2), clr.lerp(Color.TRANSPARENT, 1.0))
	
	if show_exp:
		for location in locations:
			build_explosion(world, body, int(amount), element, location, r, v)

static func build_explosion(world: Node3D, body: Node3D, amount: int, element: Spell.Element, location: Vector3, r: float, v: Vector3):
	if element == Spell.Element.VOID:
		return
	
	var explosion: Node3D
	var source: GPUParticles3D
	
	var visual_effect: Node3D = null
	var visual_source: GPUParticles3D = null
	match element:
		Spell.Element.FIRE:
			explosion = load("res://Projectiles/explosion/fire_exp.tscn").instantiate()
			source = explosion.get_node("source")
			source.process_material.emission_sphere_radius = r
			source.process_material.scale_min = r * 2
			source.process_material.scale_max = r * 2
			source.process_material.initial_velocity_max = r * 2
			source.amount = amount
			
			if not body.has_node("burn_effect"):
				visual_effect = load("res://Projectiles/explosion/fire_exp.tscn").instantiate()
				visual_effect.name = "burn_effect"
				visual_source = visual_effect.get_node("source")
				visual_source.process_material.emission_sphere_radius = r
				visual_source.process_material.scale_min = r * 2
				visual_source.process_material.scale_max = r * 2
				visual_source.process_material.initial_velocity_max = r * 2
				visual_source.amount = amount
		Spell.Element.WATER:
			explosion = load("res://Projectiles/explosion/water_exp.tscn").instantiate()
			source = explosion.get_node("source")
			source.process_material.emission_sphere_radius = r
			source.process_material.initial_velocity_max = r * 2
			source.process_material.scale_max = r * 2
			source.amount = amount
			
			if not body.has_node("wet_effect"):
				visual_effect = load("res://Projectiles/explosion/water_exp.tscn").instantiate()
				visual_effect.name = "wet_effect"
				visual_source = visual_effect.get_node("source")
				visual_source.process_material.emission_sphere_radius = r
				visual_source.process_material.initial_velocity_max = r * 2
				visual_source.process_material.scale_max = r * 2
				visual_source.amount = amount
		Spell.Element.ROCK:
			explosion = load("res://Projectiles/explosion/rock_exp.tscn").instantiate()
			source = explosion.get_node("source")
			source.amount = (amount + 1) * 100
			source.draw_pass_1.size.x = r * 0.1
			source.draw_pass_1.size.y = r * 0.1
			source.draw_pass_1.size.z = r * 0.1
		Spell.Element.AIR:
			explosion = load("res://Projectiles/explosion/air_exp.tscn").instantiate()
			source = explosion.get_node("source")
			source.draw_pass_1.surface_get_material(0).set_shader_parameter("width", r / 10.0)
			source.draw_pass_1.surface_get_material(0).set_shader_parameter("len", r)
			source.draw_pass_1.surface_get_material(0).set_shader_parameter("radius", r / 2)
			source.draw_pass_1.surface_get_material(0).set_shader_parameter("period", r / 4)
			source.process_material.emission_ring_radius = r
			source.process_material.direction = v.normalized()
			source.amount = int(float(amount) / 10.0) + 1
		Spell.Element.ICE:
			explosion = load("res://Projectiles/explosion/ice_exp.tscn").instantiate()
			source = explosion.get_node("source")
			source.process_material.emission_ring_radius = r
			source.amount = amount
			
			if not body.has_node("freeze_effect"):
				visual_effect = load("res://Projectiles/explosion/ice_exp.tscn").instantiate()
				visual_effect.name = "freeze_effect"
				visual_source = visual_effect.get_node("source")
				visual_source.process_material.emission_ring_radius = r
				visual_source.amount = amount
		Spell.Element.ELECTRIC:
			explosion = load("res://Projectiles/explosion/electric_exp.tscn").instantiate()
			source = explosion.get_node("source")
			var mat: ShaderMaterial = source.draw_pass_1.surface_get_material(0)
			mat.set_shader_parameter("len", r * 1.2)
			source.process_material.emission_ring_radius = r
			source.amount = amount
			
			if not body.has_node("stun_effect"):
				visual_effect = load("res://Projectiles/explosion/electric_exp.tscn").instantiate()
				visual_effect.name = "stun_effect"
				visual_source = visual_effect.get_node("source")
				var visual_mat: ShaderMaterial = visual_source.draw_pass_1.surface_get_material(0)
				visual_mat.set_shader_parameter("len", r * 1.2)
				visual_source.process_material.emission_ring_radius = r
				visual_source.amount = amount
			
			
	if visual_effect != null and (body is Enemy or body is Player):
		visual_effect.position = body.to_local(location)
		visual_source.one_shot = false
		visual_source.explosiveness = 0.0
		visual_source.emitting = true
		body.add_child(visual_effect)
			
	explosion.position = world.to_local(location)
	world.add_child(explosion)
	source.emitting = true
	await world.get_tree().create_timer(Globals.particle_system_lifetime(source)).timeout
	world.remove_child(explosion)
	explosion.queue_free()
