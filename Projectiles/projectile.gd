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

var particles: Array = []

var fixed_vars: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	if spell.chain != null:
		cast_spell(func(p): if p != null: add_sibling(p), spell.chain)

func _physics_process(delta):
	var t = Time.get_unix_time_from_system()
	var should_remove = []
	for i in range(particles.size()):
		var p: SpellBody = particles[i]
		p.update_spell(t, spell_variables(false))
		if p.has_expired(t):
			print("should_remove")
			should_remove.append(i)
			p.stop_emitting()
			
	should_remove.reverse()
	for i in should_remove:
		particles.remove_at(i)

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

func update_shape(r: float, ignore_time: bool):
	match spell.element:
		Spell.Element.FIRE:
			var particles: CPUParticles3D = get_node("source")
			var shape: CollisionShape3D = get_node("source/area/shape")
			particles.emission_sphere_radius = r
			var sphere = SphereShape3D.new()
			sphere.radius = r
			shape.shape = sphere
			
		Spell.Element.ROCK:
			if not ignore_time:
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
			mbox.material.albedo_color = Color8(136, 30, 3)
			mbox.material.albedo_texture = NoiseTexture2D.new()
			mbox.material.albedo_texture.noise = FastNoiseLite.new()
			mesh.mesh = mbox
			
			var body: RigidBody3D = get_node("body")
			body.mass = r
			
		Spell.Element.WATER:
#			if not ignore_time:
#				return
			var m_shape: CollisionShape3D = get_node("source/area/shape")
			var box = SphereShape3D.new()
			box.radius = r
			m_shape.shape = box
			var mesh: MeshInstance3D = get_node("source")
			var mbox = SphereMesh.new()
			mbox.radius = r
			mbox.height = r * 2
			mbox.material = water_mat
			mbox.material.set_shader_parameter("radius", r)
			mbox.material.set_shader_parameter("displacement", clamp((1.0 / r) / 10.0, 0, 0.5))
			mesh.mesh = mbox
			
		Spell.Element.AIR:
			var m_shape: CollisionShape3D = get_node("source/area/shape")
			var box = CylinderShape3D.new()
			box.height = spell.impulse_length()
			box.radius = r
			m_shape.position.y = box.height / 2
			m_shape.shape = box
			
			var source = get_node("source")
			source.emission_ring_radius = r 
			
			

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
			var particles: CPUParticles3D = get_node("source")
			particles.direction = (velocity.normalized() + Vector3.UP).normalized()
			var s = velocity.length()
			particles.initial_velocity_min = s * 4.9
			particles.initial_velocity_max = s * 5.1
		
		Spell.Element.ROCK:
			position = p
				
		Spell.Element.WATER:
			position = p
			
		Spell.Element.AIR:
			position = p
			var particles: CPUParticles3D = get_node("source")
			var dist = spell.impulse_length()
			particles.initial_velocity_min = dist * 0.9
			particles.initial_velocity_max = dist * 1.1
			if velocity.normalized() == Vector3.ZERO:
				velocity = Vector3(0.05, 0.99, 0.05).normalized()
			var dir = global_position + velocity.normalized() * 100
			look_at(dir)
			
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
			var particles: CPUParticles3D = get_node("source")
			particles.emitting = false
			var area: Area3D = get_node("source/area")
			area.collision_mask = 0
			free_after(particles.lifetime)
			
		Spell.Element.ROCK:
			queue_free()
			
		Spell.Element.WATER:
			queue_free()
			
		Spell.Element.AIR:
			var particles: CPUParticles3D = get_node("source")
			particles.emitting = false
			var area: Area3D = get_node("source/area")
			area.collision_mask = 0
			free_after(particles.lifetime)
			
func free_after(duration: float):
	if get_tree():
		await get_tree().create_timer(duration).timeout
		queue_free()		
			
var water_mat = preload("res://Projectiles/water_mat.tres")

func spell_variables(fixed: bool) -> Dictionary:
	var result = Dictionary()
	var prefix = "" if fixed else "t"
	result[prefix + "x"] = position.x
	result[prefix + "y"] = position.y
	result[prefix + "z"] = position.z
	
	var cdir = Vector3.ZERO
	
	result[prefix + "u"] = cdir.x
	result[prefix + "v"] = cdir.y
	result[prefix + "w"] = cdir.z
	
	if fixed:
		result["abs_pos"] = position
	else:
		result["rel_pos"] = position
	
	return result

func cast_spell(insert: Callable, next_spell: Spell):
	var ps = next_spell.get_particles(spell_variables(true))
	for p in ps:
		particles.append(p)
	await get_tree().create_timer(next_spell.delay).timeout
	for p in ps:
		p.time_start = Time.get_unix_time_from_system()
		insert.call(p)
