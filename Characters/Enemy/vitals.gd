class_name Vitals

class Stat:
	var min_value: float
	var max_value: float
	var value: float
	var change_per_tick: float
	var resistance: float
	
	func _init(v: float, min_v: float, max_v: float, change: float = 0, res: float = 0):
		value = v
		min_value = min_v
		max_value = max_v
		change_per_tick = change
		resistance = res
		
	func amount_of_change(p: float) -> float:
		return (1 - resistance) * p
		
	func apply_ignoring_resistance(amount: float):
		value = clamp(value + amount, min_value, max_value)
		
	func update_per_tick() -> float:
		apply_ignoring_resistance(change_per_tick)
		return change_per_tick
		

var health: Stat
var mana: Stat
var aggression: Stat

var burning: Stat
var wetness: Stat
var freeze: Stat

var hunger: Stat
var thirst: Stat
var perception: Stat


func _init(_health: Stat, _mana: Stat, _burning := Stat.new(0, 0, 1, -0.05), _wetness := Stat.new(0, 0, 1, -0.001), _freeze := Stat.new(0, 0, 1, -0.01)):
	health = _health
	mana = _mana
	burning = _burning
	wetness = _wetness
	freeze = _freeze
	hunger = Stat.new(0, 0, 0)
	thirst = Stat.new(0, 0, 0)
	perception = Stat.new(50, 0, 100)
	aggression = Stat.new(0, 0, 1)

func handle_damage(kind: Spell.Element, power: float) -> Dictionary:
	match kind:
		Spell.Element.FIRE:
			var amount = burning.amount_of_change(power)
			if wetness.value <= 0 and freeze.value <= 0:
				burning.apply_ignoring_resistance(amount)
			else:
				power = power * 0.5
			wetness.apply_ignoring_resistance(-amount)
			freeze.apply_ignoring_resistance(-amount * 1.5)
		Spell.Element.WATER:
			var amount = wetness.amount_of_change(power)
			if burning.value <= 0:
				wetness.apply_ignoring_resistance(amount)
			else:
				power = power * 0.5
			burning.apply_ignoring_resistance(-amount)
			freeze.apply_ignoring_resistance(amount * freeze.value)
		Spell.Element.ICE:
			var amount = freeze.amount_of_change(wetness.value * power)
			if wetness.value > 0:
				freeze.apply_ignoring_resistance(amount)
				wetness.apply_ignoring_resistance(-amount)
			if burning.value > 0:
				power = power * 0.25
			burning.apply_ignoring_resistance(-amount)
			
	health.apply_ignoring_resistance(-power)
	print("health: ", health.value, ", burning: ", burning.value, ", wetness: ", wetness.value, ", freeze: ", freeze.value)
	print("element: ", Spell.name_from_element(kind))
	print(wetness_scale())
	
	return {"dmg": power, "el": kind}

func update_vitals() -> Array:
	freeze.update_per_tick()
	wetness.update_per_tick()
	burning.update_per_tick()
	var h = health.update_per_tick()
	var result = [{"dmg": h, "el": Spell.Element.FIRE}]
	mana.update_per_tick()
	if burning.value > 0:
		health.apply_ignoring_resistance(-int(burning.value * health.value / 100.0))
		result.append({"dmg": int(burning.value * health.value / 100.0), "el": Spell.Element.FIRE})
		
	return result

func wetness_scale():
	return 1 + wetness.value

static func apply_damage(world: Node3D, body: Node3D, amount: float, element: Spell.Element, show_label: bool, show_exp: bool, locations: Array[Vector3], r: float = 0, v: Vector3 = Vector3.ZERO):
	amount = int(clamp(amount, 0, 100))
	if amount <= 0:
		return
	
	if show_label:	
		var lbl = load("res://Projectiles/explosion/BodyMessage.tscn").instantiate()
		lbl.position.y = 2.0
		lbl.text = str(int(amount))
		body.add_child(lbl)
		var clr = Spell.color_from_element(element)
		lbl.set_rise_modulate(clr, clr.lerp(Color.TRANSPARENT, 1.0))
		lbl.set_rise_outline_modulate(clr.darkened(0.2), clr.lerp(Color.TRANSPARENT, 1.0))
	
	if show_exp:
		for location in locations:
			build_explosion(world, int(amount), element, location, r, v)

static func build_explosion(world: Node3D, amount: int, element: Spell.Element, location: Vector3, r: float, v: Vector3):
	var explosion: Node3D
	var source: GPUParticles3D
	match element:
		Spell.Element.FIRE:
			explosion = load("res://Projectiles/explosion/fire_exp.tscn").instantiate()
			source = explosion.get_node("source")
			source.process_material.emission_sphere_radius = r
			source.process_material.scale_min = r * 2
			source.process_material.scale_max = r * 2
			source.process_material.initial_velocity_max = r * 2
			source.amount = amount
		Spell.Element.WATER:
			explosion = load("res://Projectiles/explosion/water_exp.tscn").instantiate()
			source = explosion.get_node("source")
			source.process_material.emission_sphere_radius = r
			source.process_material.initial_velocity_max = r * 2
			source.process_material.scale_max = r * 2
			source.amount = amount
		Spell.Element.ROCK:
			explosion = load("res://Projectiles/explosion/rock_exp.tscn").instantiate()
			source = explosion.get_node("source")
			source.amount = amount
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
			source.amount = int(amount / 10) + 1
		Spell.Element.ICE:
			explosion = load("res://Projectiles/explosion/ice_exp.tscn").instantiate()
			source = explosion.get_node("source")
			source.process_material.emission_ring_radius = r
			source.amount = amount
		Spell.Element.ELECTRIC:
			explosion = load("res://Projectiles/explosion/electric_exp.tscn").instantiate()
			source = explosion.get_node("source")
			var mat: ShaderMaterial = source.draw_pass_1.surface_get_material(0)
			mat.set_shader_parameter("len", r * 1.2)
			source.process_material.emission_ring_radius = r
			source.amount = amount
			
	explosion.position = world.to_local(location)
	world.add_child(explosion)
	source.emitting = true
	await world.get_tree().create_timer(source.lifetime + 0.1).timeout
	world.remove_child(explosion)
	explosion.queue_free()
