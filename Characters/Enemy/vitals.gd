class_name Vitals

class Stat:
	@export var min_value: float
	@export var max_value: float
	@export var value: float
	@export var change_per_tick: float # assumed once per second
	@export var resistance: float
	
	func _init(v: float, min_v: float = v, max_v: float = v, change: float = 0, res: float = 0) -> void:
		value = v
		min_value = min_v
		max_value = max_v
		change_per_tick = change
		resistance = res
		
	func amount_of_change(p: float) -> float:
		return (1 - resistance) * p
		
	func set_value(amount: float) -> void:
		value = clampf(amount, min_value, max_value)
		
	func apply_ignoring_resistance(amount: float) -> void:
		value = clampf(value + amount, min_value, max_value)
		
	func apply(p: float) -> void:
		apply_ignoring_resistance(amount_of_change(p))
		
	func apply_by_percentage_on_max(p: float) -> void:
		apply_ignoring_resistance(amount_of_change(p * max_value))
		
	func apply_by_percentage_on_value(p: float) -> void:
		apply_ignoring_resistance(amount_of_change(p * value))
		
	func update_per_tick() -> float:
		apply_ignoring_resistance(change_per_tick)
		return change_per_tick
		
	func percentage() -> float:
		return value / (max_value - min_value)
		
	func set_fixed_value(amount: float) -> void:
		min_value = amount
		max_value = amount
		value = amount
		
		

var health: Stat
var mana: Stat
var attack: Stat
var defence: Stat

var burning: Stat
var wetness: Stat
var freeze: Stat
var stun: Stat

var perception: Stat

var damage_resistance: Dictionary # Artifact.Element -> Vector2 (flat, percentage)


func _init(_health: Stat, _mana: Stat) -> void:
	health = _health
	mana = _mana
	burning = Stat.new(0, 0, 1, -0.05)
	wetness = Stat.new(0, 0, 1, -0.001)
	freeze = Stat.new(0, 0, 1, -0.01)
	stun = Stat.new(0, 0, 1.0, -0.25)
	attack = Stat.new(10, 0, 100)
	defence = Stat.new(10, 0, 100)
	perception = Stat.new(50, 0, 100)
	damage_resistance = {}
	
static func enemy(health_max: float, mana_max: float, mana_rate: float, percep: float, atk: float, def: float, res: Dictionary = {}) -> Vitals:
	var result := Vitals.new(Stat.new(health_max, 0, health_max, 0), Stat.new(mana_max, 0, mana_max, mana_rate))
	result.burning = Stat.new(0, 0, 1, -0.05)
	result.wetness = Stat.new(0, 0, 1, -0.001)
	result.freeze = Stat.new(0, 0, 1, -0.01)
	result.stun = Stat.new(0, 0, 1, -0.25)
	result.attack = Stat.new(atk)
	result.defence = Stat.new(def)
	result.perception = Stat.new(percep, percep, percep * 2)
	result.damage_resistance = res
	return result

func handle_damage(kind: Spell.Element, power: float, gauge: float) -> Dictionary:
	match kind:
		Spell.Element.FIRE:
			var amount := burning.amount_of_change(gauge)
			if wetness.value <= 0 and freeze.value <= 0:
				burning.apply_ignoring_resistance(amount)
			else:
				power = power * (1.0 + wetness.value * amount) * (1.0 + 1.5 * freeze.value * amount)
			wetness.apply_ignoring_resistance(-amount)
			freeze.apply_ignoring_resistance(-amount * 1.5)
		Spell.Element.WATER:
			var amount := wetness.amount_of_change(gauge)
			if burning.value <= 0:
				wetness.apply_ignoring_resistance(amount)
			else:
				power = power * 0.5
			burning.apply_ignoring_resistance(-amount)
			freeze.apply_ignoring_resistance(amount * freeze.value)
		Spell.Element.ICE:
			var amount := freeze.amount_of_change(wetness.value * gauge)
			if wetness.value > 0:
				freeze.apply_ignoring_resistance(amount)
				wetness.apply_ignoring_resistance(-amount)
			if burning.value > 0:
				power = power * 0.25
			burning.apply_ignoring_resistance(-amount)
		Spell.Element.ELECTRIC:
			var amount := stun.amount_of_change(maxf(wetness.value, burning.value) * gauge)
			stun.apply_ignoring_resistance(amount)
		Spell.Element.AIR:
			pass
		Spell.Element.VOID:
			power = 0.0
			
	var def := defence.value / (defence.value + 500)
	power = power * (1.0 - def)
	for e: Artifact.Element in damage_resistance:
		if e == kind or e == Artifact.Element.ANY:
			power = power * (1.0 - damage_resistance[e].y) - damage_resistance[e].x
	health.apply_ignoring_resistance(-power)
	print("power: ", power, ", gauge: ", gauge)
	print("health: ", health.value, ", burning: ", burning.value, ", wetness: ", wetness.value, ", freeze: ", freeze.value, ", stun: ", stun.value)
	print("element: ", Spell.name_from_element(kind))
	
	return {"dmg": power, "el": kind}

# we assume this is called once per second everywhere
func update_vitals(body: Node3D) -> Array[Dictionary]: # [][String(dmg, el)](float, Spell.Element)
	freeze.update_per_tick()
	wetness.update_per_tick()
	burning.update_per_tick()
	stun.update_per_tick()
	var h := health.update_per_tick()
	var result: Array[Dictionary] = []
	if h > 0.0:
		result.append([{"dmg": h, "el": Spell.Element.VOID}])
	mana.update_per_tick()
	if burning.value > 0:
		var burn_damage := int(burning.value * health.max_value * 0.05)
		health.apply_ignoring_resistance(-burn_damage)
		if burn_damage > 0.0:
			result.append({"dmg": burn_damage, "el": Spell.Element.FIRE})
		defence.value = defence.max_value * burning.value
	
	var effect: Node3D
	
	effect = body.find_child("burn_effect", false, false)
	if effect != null:
		if burning.value == 0.0:
			body.remove_child(effect)
		else:
			var source := effect.get_node("source") as GPUParticles3D
			(source.process_material as ParticleProcessMaterial).scale_min = burning.value
			(source.process_material as ParticleProcessMaterial).scale_max = burning.value
		
	effect = body.find_child("stun_effect", false, false)
	if effect != null:
		if stun.value == 0.0:
			body.remove_child(effect)
		else:
			var source := effect.get_node("source") as GPUParticles3D
			var mat: ShaderMaterial = source.draw_pass_1.surface_get_material(0)
			mat.set_shader_parameter("len", 2.5 * stun.value)
			
	effect = body.find_child("wet_effect", false, false)
	if effect != null:
		if wetness.value == 0.0:
			body.remove_child(effect)
		else:
			var source := effect.get_node("source") as GPUParticles3D
			(source.process_material as ParticleProcessMaterial).scale_max = wetness.value
			
	effect = body.find_child("freeze_effect", false, false)
	if effect != null:
		if freeze.value == 0.0:
			body.remove_child(effect)
		else:
			var source := effect.get_node("source") as GPUParticles3D
			source.amount = int(freeze.value * 100)
				
	return result

func wetness_scale() -> float:
	return 1 + wetness.value

static func apply_damage(world: Node3D, body: Node3D, amount: float, element: Spell.Element, show_label: bool, show_exp: bool, locations: Array[Vector3], r: float = 0, v: Vector3 = Vector3.ZERO) -> void:
	amount = clampi(int(amount), 0, 100)
	if show_label:	
		var lbl := (preload("res://Projectiles/explosion/BodyMessage.tscn") as PackedScene).instantiate() as BodyMessage
		var collision: CollisionShape3D = body.get_node("Collision")
		if collision.shape is BoxShape3D:
			lbl.position.y = (collision.shape as BoxShape3D).size.y
		elif collision.shape is SphereShape3D:
			lbl.position.y = (collision.shape as SphereShape3D).radius
		elif collision.shape is CylinderShape3D:
			lbl.position.y = (collision.shape as CylinderShape3D).height
		elif collision.shape is CapsuleShape3D:
			lbl.position.y = (collision.shape as CapsuleShape3D).height
		body.add_child(lbl)
		lbl.text = str(int(amount))
		var clr := Spell.color_from_element(element)
		lbl.set_rise_modulate(clr, clr.lerp(Color.TRANSPARENT, 1.0))
		lbl.set_rise_outline_modulate(clr.darkened(0.2), clr.lerp(Color.TRANSPARENT, 1.0))
		lbl.set_rise_position_change(Globals.rand_point_in_sphere(1))
	
	if show_exp:
		for location in locations:
			build_explosion(world, body, int(amount), element, location, r, v, false)

const steam_exp = preload("res://Projectiles/explosion/steam_exp.tscn") as PackedScene
const fire_exp = preload("res://Projectiles/explosion/fire_exp.tscn") as PackedScene
const water_exp = preload("res://Projectiles/explosion/water_exp.tscn") as PackedScene
const ice_exp = preload("res://Projectiles/explosion/ice_exp.tscn") as PackedScene
const air_exp = preload("res://Projectiles/explosion/air_exp.tscn") as PackedScene
const rock_exp = preload("res://Projectiles/explosion/rock_exp.tscn") as PackedScene
const electric_exp = preload("res://Projectiles/explosion/electric_exp.tscn") as PackedScene

static func build_explosion(world: Node3D, body: Node3D, amount: int, element: Spell.Element, location: Vector3, r: float, v: Vector3, is_alternate: bool) -> void:
	if element == Spell.Element.VOID:
		return
	if amount <= 0:
		return
	
	var explosion: Node3D
	var source: GPUParticles3D
	
	var visual_effect: Node3D = null
	var visual_source: GPUParticles3D = null
	match element:
		Spell.Element.FIRE:
			if not is_alternate:
				explosion = fire_exp.instantiate()
				source = explosion.get_node("source")
				(source.process_material as ParticleProcessMaterial).emission_sphere_radius = r
				(source.process_material as ParticleProcessMaterial).scale_min = r * 2
				(source.process_material as ParticleProcessMaterial).scale_max = r * 2
				(source.process_material as ParticleProcessMaterial).initial_velocity_max = r * 2
				source.amount = amount
			else:
				explosion = steam_exp.instantiate()
				source = explosion.get_node("source")
				(source.process_material as ParticleProcessMaterial).emission_sphere_radius = r
				(source.process_material as ParticleProcessMaterial).scale_min = r * 2
				(source.process_material as ParticleProcessMaterial).scale_max = r * 2
				source.amount = 80 + roundi(20 * (amount / 100.0))
			
			if not body.has_node("burn_effect"):
				visual_effect = fire_exp.instantiate()
				visual_effect.name = "burn_effect"
				visual_source = visual_effect.get_node("source")
				(visual_source.process_material as ParticleProcessMaterial).emission_sphere_radius = r
				(visual_source.process_material as ParticleProcessMaterial).scale_min = r * 2
				(visual_source.process_material as ParticleProcessMaterial).scale_max = r * 2
				(visual_source.process_material as ParticleProcessMaterial).initial_velocity_max = 0
				visual_source.amount = amount
		Spell.Element.WATER:
			if not is_alternate:
				explosion = water_exp.instantiate()
				source = explosion.get_node("source")
				(source.process_material as ParticleProcessMaterial).emission_sphere_radius = r
				(source.process_material as ParticleProcessMaterial).initial_velocity_max = r * 2
				(source.process_material as ParticleProcessMaterial).scale_max = r * 2
				source.amount = amount
			else:
				explosion = steam_exp.instantiate()
				source = explosion.get_node("source")
				(source.process_material as ParticleProcessMaterial).emission_sphere_radius = r
				(source.process_material as ParticleProcessMaterial).scale_min = r * 2
				(source.process_material as ParticleProcessMaterial).scale_max = r * 2
				source.amount = 80 + roundi(20 * (amount / 100.0))
			
			if not body.has_node("wet_effect"):
				visual_effect = water_exp.instantiate()
				visual_effect.name = "wet_effect"
				visual_source = visual_effect.get_node("source")
				(visual_source.process_material as ParticleProcessMaterial).emission_sphere_radius = r
				(visual_source.process_material as ParticleProcessMaterial).initial_velocity_max = 0
				(visual_source.process_material as ParticleProcessMaterial).scale_max = r * 2
				visual_source.amount = amount
		Spell.Element.ROCK:
			explosion = rock_exp.instantiate()
			source = explosion.get_node("source")
			(source.draw_pass_1 as BoxMesh).size.x = r * 0.1
			(source.draw_pass_1 as BoxMesh).size.y = r * 0.1
			(source.draw_pass_1 as BoxMesh).size.z = r * 0.1
			source.amount = amount
		Spell.Element.AIR:
			explosion = air_exp.instantiate()
			source = explosion.get_node("source")
			((source.draw_pass_1 as Mesh).surface_get_material(0) as ShaderMaterial).set_shader_parameter("width", r / 10.0)
			((source.draw_pass_1 as Mesh).surface_get_material(0) as ShaderMaterial).set_shader_parameter("len", r)
			((source.draw_pass_1 as Mesh).surface_get_material(0) as ShaderMaterial).set_shader_parameter("radius", r / 2)
			((source.draw_pass_1 as Mesh).surface_get_material(0) as ShaderMaterial).set_shader_parameter("period", r / 4)
			(source.process_material as ParticleProcessMaterial).emission_ring_radius = r
			(source.process_material as ParticleProcessMaterial).direction = v.normalized()
			source.amount = int(float(amount) / 10.0) + 1
		Spell.Element.ICE:
			explosion = ice_exp.instantiate()
			source = explosion.get_node("source")
			(source.process_material as ParticleProcessMaterial).emission_ring_radius = r
			source.amount = amount
			
			if not body.has_node("freeze_effect"):
				visual_effect = ice_exp.instantiate()
				visual_effect.name = "freeze_effect"
				visual_source = visual_effect.get_node("source")
				(visual_source.process_material as ParticleProcessMaterial).emission_ring_radius = r
				visual_source.amount = amount
		Spell.Element.ELECTRIC:
			explosion = electric_exp.instantiate()
			source = explosion.get_node("source")
			var mat: ShaderMaterial = source.draw_pass_1.surface_get_material(0)
			mat.set_shader_parameter("len", r * 1.2)
			(source.process_material as ParticleProcessMaterial).emission_ring_radius = r
			@warning_ignore("integer_division")
			source.amount = clampi(amount / 10, 1, 100)
			
			if not body.has_node("stun_effect"):
				visual_effect = electric_exp.instantiate()
				visual_effect.name = "stun_effect"
				visual_source = visual_effect.get_node("source")
				var visual_mat: ShaderMaterial = visual_source.draw_pass_1.surface_get_material(0)
				visual_mat.set_shader_parameter("len", r * 1.2)
				(visual_source.process_material as ParticleProcessMaterial).emission_ring_radius = r
				@warning_ignore("integer_division")
				visual_source.amount = clampi(amount / 10, 1, 100)
			
			
	if visual_effect != null and (body is CharacterBody):
		visual_effect.position = Vector3(0, (body as CharacterBody).bounds.y / 4, 0) # body.to_local(location)
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
