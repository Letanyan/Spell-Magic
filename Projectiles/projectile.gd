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

var spell_caster = SpellCaster.new(SpellCaster.Entity.PROJECTILE)

var fixed_vars: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	if spell.chain != null:
		cast_spell(func(p): if p != null: add_sibling(p), spell.chain)

func _physics_process(delta):
	spell_caster.update(self, delta)

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
	
func impulse() -> Vector3:
	match spell.element:
		Spell.Element.ROCK:
			return velocity.normalized() * (spell.power * 100.0) 
		Spell.Element.AIR:
			return velocity.normalized() * (spell.power * 100.0)
		_:
			return Vector3.ZERO

func _on_body_entered(body: Node3D):
	var is_world  = body.collision_layer & 0b0001 != 0
	var is_player = body.collision_layer & 0b0010 != 0
	var is_enemy  = body.collision_layer & 0b0100 != 0
	
	var is_rock  = body.collision_layer & 0b1_0000 != 0
	match spell.element:
		Spell.Element.FIRE:
			if is_world or is_rock:
				expire_now(self, body)
			elif is_enemy or is_player:
				body.vitals.handle_damage(Spell.Element.FIRE, spell.power)
				expire_now(self, body)
		Spell.Element.ROCK:
			if body != get_node("body"):
				if is_world :
					lose_control(self, body)
				elif is_rock:
					lose_control(self, body)
					body.apply_central_impulse(impulse())
				elif is_enemy or is_player:
					CharacterCollision.handle(body, self)
					body.vitals.handle_damage(Spell.Element.ROCK, spell.power)
					lose_control(self, body)
		Spell.Element.WATER:
			if is_world or is_rock:
				expire_now(self, body)
			elif is_enemy or is_player:
				body.vitals.handle_damage(Spell.Element.WATER, spell.power)
				expire_now(self, body)
		Spell.Element.AIR:
			if is_world or is_rock:
				nothing(self, body)
			elif is_player or is_enemy:
				CharacterCollision.handle(body, self)
				body.vitals.handle_damage(Spell.Element.AIR, spell.power)
				nothing(self, body)
		Spell.Element.ICE:
			if is_world or is_rock:
				nothing(self, body)
			elif is_player or is_enemy:
				CharacterCollision.handle(body, self)
				body.vitals.handle_damage(Spell.Element.ICE, spell.power)
				nothing(self, body)
		Spell.Element.ELECTRIC:
			# Look at `_on_area_entered` for implementation
			pass

func _on_area_entered(area):
	var body = area.get_parent_node_3d()
	var is_world  = area.collision_layer & 0b0001 != 0
	var is_player = area.collision_layer & 0b0010 != 0
	var is_enemy  = area.collision_layer & 0b0100 != 0
	
	var is_rock  = area.collision_layer & 0b1_0000 != 0
	var is_water = area.collision_layer & 0b10_0000 != 0
	match spell.element:
		Spell.Element.ELECTRIC:
			if is_world or is_rock:
				expire_now(self, body)
			elif (is_player or is_enemy) and is_water:
				CharacterCollision.handle(body, self)
				body.vitals.handle_damage(Spell.Element.ELECTRIC, spell.power)
				expire_now(self, body)

func update_shape(r: float, ignore_time: bool):
	match spell.element:
		Spell.Element.FIRE:
			var particles: GPUParticles3D = get_node("source")
			var shape: CollisionShape3D = get_node("source/area/shape")
			particles.process_material.emission_sphere_radius = r
			var sphere = SphereShape3D.new()
			sphere.radius = r
			shape.shape = sphere
			
		Spell.Element.ROCK:
			if not ignore_time:
				var R = get_node("body/shape").shape.size.x
				scale = Vector3(r / R, r / R, r / R)
				return
			var p_shape: CollisionShape3D = get_node("body/shape")
			var m_shape: CollisionShape3D = get_node("body/mesh/area/shape")
			var box = BoxShape3D.new()
			box.size.x = r
			box.size.y = r
			box.size.z = r
			p_shape.shape = box
			m_shape.shape = box
			var mesh: MeshInstance3D = get_node("body/mesh")
			var mbox = BoxMesh.new()
			mbox.size.x = r
			mbox.size.y = r
			mbox.size.z = r
			mbox.material = StandardMaterial3D.new()
			mbox.material.albedo_color = Color8(96, 32, 0)
			mbox.material.albedo_texture = NoiseTexture2D.new()
			mbox.material.albedo_texture.noise = FastNoiseLite.new()
			mbox.material.normal_enabled = true
			mbox.material.normal_texture = NoiseTexture2D.new()
			mbox.material.normal_texture.as_normal_map = true
			mbox.material.normal_texture.noise = FastNoiseLite.new()
			mesh.mesh = mbox
			
			var body: RigidBody3D = get_node("body")
			body.mass = r
			scale = Vector3(1, 1, 1)
			
		Spell.Element.WATER:
#			if not ignore_time:
#				return
			var m_shape: CollisionShape3D = get_node("source/area/shape")
			var box = SphereShape3D.new()
			box.radius = r
			m_shape.shape = box
			var particles: GPUParticles3D = get_node("source")
			particles.process_material.emission_sphere_radius = r
			
		Spell.Element.AIR:
			var m_shape: CollisionShape3D = get_node("source/area/shape")
			var box = CylinderShape3D.new()
			box.height = r #spell.impulse_length()
			box.radius = r
			m_shape.position.y = box.height / 2
			m_shape.shape = box
			
			var source = get_node("source")
			source.emission_ring_radius = r 
			
		Spell.Element.ICE:
			var m_shape: CollisionShape3D = get_node("source/area/shape")
			var box = BoxShape3D.new()
			box.size.x = r * 2
			box.size.z = r * 2
			m_shape.shape = box
			
			var source: CPUParticles3D = get_node("source")
			source.emission_box_extents = Vector3(r, 0.2, r)
			
		Spell.Element.ELECTRIC:
			var m_shape: CollisionShape3D = get_node("body/area/shape")
			var box = SphereShape3D.new()
			box.radius = r
			m_shape.shape = box
			
			var source: CPUParticles3D = get_node("source")
			source.emission_sphere_radius = r
			var body = get_node("body")
			body.mesh.radius = r
			body.mesh.height = r * 2
			
			

func update_movement(p: Vector3, instance: bool, vars: Dictionary):
	var next_pos = p - (vars["rel_pos"] if spell.is_relative_to_player_current_pos else vars["abs_pos"])
	if started:
		velocity = next_pos - old_pos
		var dist = velocity.length() * 60
		velocity = velocity.normalized() * clamp(dist, -1, 1)
	old_pos = next_pos
	started = true
	
	match spell.element:
		Spell.Element.FIRE:
			position = p
			var particles: GPUParticles3D = get_node("source")
			particles.process_material.direction = (-velocity.normalized() + Vector3.UP).normalized()
			var s = velocity.length()
			particles.process_material.initial_velocity_min = s * 0.9
			particles.process_material.initial_velocity_max = s * 1.1
		
		Spell.Element.ROCK:
			position = p
				
		Spell.Element.WATER:
			position = p
			var particles: GPUParticles3D = get_node("source")
			particles.process_material.direction = -velocity.normalized()
			var s = velocity.length()
			particles.process_material.initial_velocity_min = s * 0.9
			particles.process_material.initial_velocity_max = s * 1.1
			
		Spell.Element.AIR:
			position = p
			var particles: CPUParticles3D = get_node("source")
			var dist = get_node("source/area/shape").shape.radius
			particles.initial_velocity_min = dist * 0.9
			particles.initial_velocity_max = dist * 1.1
			var v = velocity.normalized()
			if v != Vector3.ZERO:
				if v == Vector3.UP:
					v = Vector3(0.1, 0.9, 0.1).normalized()
				var dir = global_position + v * 10
				look_at(dir)
			
		Spell.Element.ICE:
			position = p
			var particles: CPUParticles3D = get_node("source")
			particles.initial_velocity_min = 0.2 * 0.9
			particles.initial_velocity_max = 0.2 * 1.1
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
	vars.merge(fixed_vars, true)
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
			var particles: CPUParticles3D = get_node("source")
			particles.emitting = false
			var area: Area3D = get_node("source/area")
			area.collision_mask = 0
			free_after(particles.lifetime)
			
		Spell.Element.ICE:
			var particles: CPUParticles3D = get_node("source")
			particles.emitting = false
			var area: Area3D = get_node("source/area")
			area.collision_mask = 0
			free_after(particles.lifetime)
			
		Spell.Element.ELECTRIC:
			var particles: CPUParticles3D = get_node("source")
			particles.emitting = false
			var body = get_node("body")
			body.visible = false
			var area: Area3D = get_node("body/area")
			area.collision_mask = 0
			free_after(particles.lifetime)
			
func free_after(duration: float):
	if get_tree():
		if duration > 0:
			await get_tree().create_timer(duration).timeout
		var max_duration = 0
		for p in spell_caster.particles:
			max_duration = max(max_duration, p.spell.duration)
		if max_duration <= 0:
			queue_free()
		else:
			free_after(max_duration)
			
var water_mat = preload("res://Projectiles/water_mat.tres")

func cast_spell(insert: Callable, next_spell: Spell):
	spell_caster.cast_spell(self, insert, next_spell)
