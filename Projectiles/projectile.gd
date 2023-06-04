class_name SpellBody
extends Node3D

signal world_hit

var spell: Spell
var n: int
var time_start: float
var expired: bool = false
var started: bool = false
var in_control: bool = true
var velocity: Vector3 = Vector3.ZERO
var old_pos: Vector3 = Vector3.ZERO
var most_recent_radius: float = 0

var spell_caster = SpellCaster.new(SpellCaster.Entity.PROJECTILE)

var fixed_vars: Dictionary

var to_remove = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if spell.chain_cast_kind == Spell.ChainCastKind.START and spell.chain != null:
		cast_spell(func(p): if p != null: call_deferred("add_sibling", p), spell.chain)

func _physics_process(delta):
	spell_caster.deferred_update(self, delta)
	if to_remove:
		get_parent().remove_child(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func has_expired(t: float) -> bool:
	if time_start <= 0:
		return false
	return expired or (t - time_start) >= spell.duration
	
func expire_now(p: Node3D, q: Node3D):
	expired = true
	
func lose_control(p: Node3D, q: Node3D):
	in_control = false
	if spell.element == Spell.Element.ROCK:
		var body: RigidBody3D = p.get_node("body")
		if body.freeze:
			body.freeze = false
			body.apply_central_impulse(velocity)

func nothing(p: Node3D, q: Node3D):
	pass
	
func actual_duration() -> float:
	var result := spell.duration - (Time.get_unix_time_from_system() - time_start)
	for p in spell_caster.particles:
		result = max(result, p.actual_duration())
	return max(0, result)
	
func impulse() -> Vector3:
	match spell.element:
		Spell.Element.ROCK:
			return velocity.normalized() * (spell.power * 1.5) 
		Spell.Element.AIR:
			return velocity.normalized() * (spell.power * 2.0)
			
		Spell.Element.FIRE:
			return velocity.normalized() * spell.power * 1
		Spell.Element.WATER:
			return velocity.normalized() * spell.power * 0.5
		Spell.Element.ELECTRIC:
			return velocity.normalized() * spell.power
		Spell.Element.ICE:
			return velocity.normalized() * spell.power
			
			
		_:
			return Vector3.ZERO

func get_shape() -> Shape3D:
	match spell.element:
		Spell.Element.FIRE: return get_node("source/area/shape").shape
		Spell.Element.WATER: return get_node("source/area/shape").shape
		Spell.Element.ROCK: return get_node("body/shape").shape
		Spell.Element.AIR: return get_node("source/area/shape").shape
		Spell.Element.ICE: return get_node("source/area/shape").shape
		Spell.Element.ELECTRIC: return get_node("body/area/shape").shape
		_: return BoxShape3D.new()

func get_spell_transform() -> Transform3D:
	if spell.element == Spell.Element.ROCK:
		return get_node("body").global_transform
	elif spell.element == Spell.Element.AIR:
		return get_node("source/area/shape").global_transform
	else:
		return global_transform

func _on_body_entered(body: Node3D, contact_points: Array[Vector3]):
	var is_world  = body.collision_layer & 0b0001 != 0
	var is_player = body.collision_layer & 0b0010 != 0
	var is_enemy  = body.collision_layer & 0b0100 != 0
	
	var is_world_object = body.collision_layer & (1 << 9) != 0
	var is_rock  = body.collision_layer & 0b1_0000 != 0
	var dmg = {"dmg": spell.power, "el": spell.element}
	match spell.element:
		Spell.Element.FIRE:
			if is_world or is_rock or is_world_object:
				expire_now(self, body)
			elif is_enemy or is_player:
				CharacterCollision.handle(body, self)
				dmg = body.vitals.handle_damage(Spell.Element.FIRE, spell.power)
				expire_now(self, body)
		Spell.Element.ROCK:
			if body != get_node("body"):
				if is_world or is_world_object:
					lose_control(self, body)
				elif is_rock:
					lose_control(self, body)
					body.apply_central_impulse(impulse())
				elif is_enemy or is_player:
					CharacterCollision.handle(body, self)
					dmg = body.vitals.handle_damage(Spell.Element.ROCK, spell.power)
					lose_control(self, body)
		Spell.Element.WATER:
			if is_world or is_rock or is_world_object:
				expire_now(self, body)
			elif is_enemy or is_player:
				CharacterCollision.handle(body, self)
				dmg = body.vitals.handle_damage(Spell.Element.WATER, spell.power)
				expire_now(self, body)
		Spell.Element.AIR:
			if is_world or is_world_object:
				nothing(self, body)
			elif is_player or is_enemy:
				CharacterCollision.handle(body, self)
				dmg = body.vitals.handle_damage(Spell.Element.AIR, spell.power)
				nothing(self, body)
			elif is_rock:
				body.apply_impulse(impulse())
				nothing(self, body)
		Spell.Element.ICE:
			if is_world or is_rock or is_world_object:
				nothing(self, body)
			elif is_player or is_enemy:
				CharacterCollision.handle(body, self)
				dmg = body.vitals.handle_damage(Spell.Element.ICE, spell.power)
				nothing(self, body)
		Spell.Element.ELECTRIC:
			# Look at `_on_area_entered` for implementation
			pass
	
	if spell.chain_cast_kind == Spell.ChainCastKind.HIT and spell.chain != null:
		cast_spell(func(p): if p != null: call_deferred("add_sibling", p), spell.chain)
	Vitals.apply_damage(get_parent(), body, dmg["dmg"], dmg["el"], is_player or is_enemy, true, contact_points, most_recent_radius, velocity)
	if is_player or is_enemy:
		body.add_shake(clamp(dmg["dmg"] / 100.0, 0.0, 1.0))

func _on_area_entered(area, contact_points: Array[Vector3]):
	var body = area.get_parent_node_3d()
	var is_world  = area.collision_layer & 0b0001 != 0
	var is_player = area.collision_layer & 0b0010 != 0
	var is_enemy  = area.collision_layer & 0b0100 != 0
	
	var is_world_object = area.collision_layer & (1 << 9) != 0
	var is_rock  = area.collision_layer & 0b1_0000 != 0
	var is_water = area.collision_layer & 0b10_0000 != 0
	var dmg = {"dmg": spell.power, "el": spell.element}
	match spell.element:
		Spell.Element.ELECTRIC:
			if is_world or is_rock or is_world_object:
				expire_now(self, body)
			elif (is_player or is_enemy) and is_water:
				CharacterCollision.handle(body, self)
				dmg = body.vitals.handle_damage(Spell.Element.ELECTRIC, spell.power)
				expire_now(self, body)
				
	if spell.chain_cast_kind == Spell.ChainCastKind.HIT and spell.chain != null:
		cast_spell(func(p): if p != null: call_deferred("add_sibling", p), spell.chain)
	Vitals.apply_damage(get_parent(), body, dmg["dmg"], dmg["el"], is_player or is_enemy, true, contact_points, most_recent_radius, velocity)
	if is_player or is_enemy:
		body.add_shake(clamp(dmg["dmg"] / 100.0, 0.0, 1.0))

func update_shape(r: float, ignore_time: bool):
	if spell.element == Spell.Element.ROCK and not ignore_time:
		most_recent_radius = r
	elif spell.element != Spell.Element.ROCK:
		most_recent_radius = r
	
	match spell.element:
		Spell.Element.FIRE:
			var particles: GPUParticles3D = get_node("source")
			var shape: CollisionShape3D = get_node("source/area/shape")
			particles.process_material.emission_sphere_radius = r
			particles.process_material.scale_min = r * 2
			particles.process_material.scale_max = r * 2
			particles.process_material.initial_velocity_max = r * 2
			shape.shape.radius = r
			get_node("shape_cast").shape.radius = r
			
		Spell.Element.ROCK:
			if not ignore_time:
#				var R = get_node("body/shape").shape.size.x
#				scale = Vector3(r / R, r / R, r / R)
				return
			var p_shape: CollisionShape3D = get_node("body/shape")
			var m_shape: CollisionShape3D = get_node("body/mesh/area/shape")
			p_shape.shape.size.x = r
			p_shape.shape.size.y = r
			p_shape.shape.size.z = r
			m_shape.shape.size.x = r
			m_shape.shape.size.y = r
			m_shape.shape.size.z = r
			get_node("shape_cast").shape.size.x = r
			get_node("shape_cast").shape.size.y = r
			get_node("shape_cast").shape.size.z = r
			var mesh: MeshInstance3D = get_node("body/mesh")
			mesh.mesh.size.x = r
			mesh.mesh.size.y = r
			mesh.mesh.size.z = r
			
			var body: RigidBody3D = get_node("body")
			body.mass = r
			scale = Vector3(1, 1, 1)
			
		Spell.Element.WATER:
			var m_shape: CollisionShape3D = get_node("source/area/shape")
			m_shape.shape.radius = r
			get_node("shape_cast").shape.radius = r
			var particles: GPUParticles3D = get_node("source")
			particles.process_material.emission_sphere_radius = r
			particles.process_material.initial_velocity_max = r * 2
			particles.process_material.scale_max = r * 2
			
		Spell.Element.AIR:
			var m_shape: CollisionShape3D = get_node("source/area/shape")
			get_node("source/area").position.y = r * 2
			m_shape.shape.height = r * 4
			m_shape.shape.radius = r
			get_node("shape_cast").shape.height = r * 4
			get_node("shape_cast").shape.radius = r
			
			var source2: GPUParticles3D = get_node("source")
			source2.draw_pass_1.surface_get_material(0).set_shader_parameter("width", r / 10.0)
			source2.draw_pass_1.surface_get_material(0).set_shader_parameter("len", r)
			source2.draw_pass_1.surface_get_material(0).set_shader_parameter("radius", r / 2)
			source2.draw_pass_1.surface_get_material(0).set_shader_parameter("period", r / 4)
			source2.process_material.emission_ring_radius = r
			
		Spell.Element.ICE:
			var m_shape: CollisionShape3D = get_node("source/area/shape")
			m_shape.shape.size.x = r * 2
			m_shape.shape.size.z = r * 2
			get_node("shape_cast").shape.size.x = r * 2
			get_node("shape_cast").shape.size.z = r * 2
			
			var source: GPUParticles3D = get_node("source")
			source.process_material.emission_box_extents = Vector3(r, 0.2, r)
			
		Spell.Element.ELECTRIC:
			var m_shape: CollisionShape3D = get_node("body/area/shape")
			m_shape.shape.radius = r
			get_node("shape_cast").shape.radius = r
			
			var source: GPUParticles3D = get_node("source")
			var mat: ShaderMaterial = source.draw_pass_1.surface_get_material(0)
			mat.set_shader_parameter("len", r * 1.2)
			var body = get_node("body")
			body.mesh.radius = r
			body.mesh.height = r * 2
			
			

func update_movement(p: Vector3, instance: bool, vars: Dictionary):
	var next_pos = p - (vars["rel_pos"] if spell.follow else vars["abs_pos"])
	if started:
		velocity = next_pos - old_pos
		var dist = velocity.length() * 60
		velocity = velocity.normalized() * clamp(dist, -1, 1)
	old_pos = next_pos
	started = true
	
	var shape_cast: ShapeCast3D = get_node("shape_cast")
	shape_cast.target_position = (p - position)
	var count = shape_cast.get_collision_count()
	for i in range(count):
		var obj = shape_cast.get_collider(i)
		var point = shape_cast.get_collision_point(i)
		if spell.element == Spell.Element.ROCK and (obj == get_node("body")):
			continue
		if obj is Area3D:
			_on_area_entered(obj, [point])
		else:
			_on_body_entered(obj, [point])
	
	match spell.element:
		Spell.Element.FIRE:
			position = p
			var particles: GPUParticles3D = get_node("source")
			particles.process_material.direction = (-velocity.normalized() + Vector3.UP).normalized()
		
		Spell.Element.ROCK:
			position = p
				
		Spell.Element.WATER:
			position = p
			var particles: GPUParticles3D = get_node("source")
			particles.process_material.direction = -velocity.normalized()
			
		Spell.Element.AIR:
			position = p
			var box: CollisionShape3D = get_node("source/area/shape")
			var h = box.shape.height
			var source: GPUParticles3D = get_node("source")
			source.process_material.initial_velocity_min = (h * 1.25 / source.lifetime) + abs(velocity.length()) * 1.0
			source.process_material.initial_velocity_max = (h * 1.25 / source.lifetime) + abs(velocity.length()) * 1.1
			
			var v = velocity.normalized()
			if v != Vector3.ZERO:
				if v == Vector3.UP:
					v = Vector3(0.1, 0.9, 0.1).normalized()
				var dir = global_position + v * 10
				look_at(dir)
			
		Spell.Element.ICE:
			position = p
			var particles: GPUParticles3D = get_node("source")
			particles.process_material.initial_velocity_min = 0.2 * 0.9
			particles.process_material.initial_velocity_max = 0.2 * 1.1
			var v = velocity.normalized()
			if v != Vector3.ZERO:
				if v == Vector3.UP:
					v = Vector3(0.1, 0.9, 0.1).normalized()
				var dir = global_position + v * 10
				look_at(dir)
			
		Spell.Element.ELECTRIC:
			position = p
			
func update_spell(t: float, vars: Dictionary):
	if not in_control or time_start == 0:
		return
	vars.merge(fixed_vars)
	vars["n"] = n
	vars["t"] = t - time_start
	var p = spell.calculate_location(vars)
	var er = spell.calculate_size(vars)
	update_shape(er, false)
	update_movement(p, false, vars)

func stop_emitting():
	match spell.element:
		Spell.Element.FIRE:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			var area: Area3D = get_node("source/area")
			area.collision_mask = 0
			free_after(particles.lifetime)
			
		Spell.Element.ROCK:
			free_after(0)
			
		Spell.Element.WATER:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			var area: Area3D = get_node("source/area")
			area.collision_mask = 0
			free_after(particles.lifetime)
			
		Spell.Element.AIR:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			var area: Area3D = get_node("source/area")
			area.collision_mask = 0
			free_after(particles.lifetime)
			
		Spell.Element.ICE:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			var area: Area3D = get_node("source/area")
			area.collision_mask = 0
			free_after(particles.lifetime)
			
		Spell.Element.ELECTRIC:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			var body = get_node("body")
			body.visible = false
			var area: Area3D = get_node("body/area")
			area.collision_mask = 0
			free_after(particles.lifetime)
			
func free_after(duration: float):
	if get_parent() != null and get_tree() != null:
		var max_duration = duration
		while max_duration > 0:
			await get_tree().create_timer(max_duration, false, true).timeout
			max_duration = actual_duration()
			if not spell_caster.particles.is_empty():
				max_duration = max(max_duration, 2)
			else:
				max_duration = 0
		to_remove = true

func cast_spell(insert: Callable, next_spell: Spell):
	spell_caster.cast_spell(self, null, insert, next_spell)
