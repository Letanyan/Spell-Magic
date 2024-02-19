class_name SpellBody
extends Node3D

var spell: Spell
var n: int
var time_start: float
var expired: bool = false
var started: bool = false
var in_control: bool = true
var velocity: Vector3 = Vector3.ZERO
var old_pos: Vector3 = Vector3.ZERO
var most_recent_radius: float = 0

var spell_caster: SpellCaster
var on_hit_casts := {}

var fixed_vars: Dictionary
var expression_vars: Dictionary

var to_remove := false
var origin_node: Node3D = null

var pause_time: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	spell_caster = SpellCaster.new(get_node("."), SpellCaster.Entity.PROJECTILE)
	if spell.chain_cast_kind == Spell.ChainCastKind.START and spell.chain != null:
		cast_spell(func(p): if p != null: call_deferred("add_sibling", p), spell.chain, null)

func _physics_process(delta):
	spell_caster.update(self, delta)
	if to_remove:
		get_parent().remove_child(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func has_expired(t: float) -> bool:
	if time_start <= 0:
		return false
	return expired or (t - time_start) >= spell.duration + pause_time
	
func expire_now(p: Node3D, q: Node3D):
	SignalBus.projectile_hit.emit(origin_node, spell, Time.get_unix_time_from_system())
	expired = true
	
func is_active() -> bool:
	return in_control and time_start > 0.0  
	
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
	var result := (spell.duration + pause_time) - (Time.get_unix_time_from_system() - time_start)
	for p in spell_caster.particles:
		result = max(result, p.actual_duration())
	return max(0, result)
	
func impulse() -> Vector3:
	match spell.element:
		Spell.Element.ROCK:
			return velocity.normalized() * spell.power
		Spell.Element.AIR:
			return velocity.normalized() * (spell.power * 2.0)
			
		Spell.Element.FIRE:
			return velocity.normalized() * spell.power * 0.25
		Spell.Element.WATER:
			return velocity.normalized() * spell.power * 0.1
		Spell.Element.ELECTRIC:
			return Vector3.ZERO
		Spell.Element.ICE:
			return Vector3.ZERO
			
		Spell.Element.VOID:
			return Vector3.ZERO
			
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
		Spell.Element.VOID: return get_node("mesh/area/shape").shape
		_: return BoxShape3D.new()

func get_spell_transform() -> Transform3D:
	if spell.element == Spell.Element.ROCK:
		return get_node("body").global_transform
	elif spell.element == Spell.Element.AIR:
		return get_node("source/area/shape").global_transform
	else:
		return global_transform
		
func get_spell_collision_mask() -> int:
	match spell.element:
		Spell.Element.FIRE: return get_node("source/area").collision_mask
		Spell.Element.WATER: return get_node("source/area").collision_mask
		Spell.Element.ROCK: return get_node("body").collision_mask
		Spell.Element.AIR: return get_node("source/area").collision_mask
		Spell.Element.ICE: return get_node("source/area").collision_mask
		Spell.Element.ELECTRIC: return get_node("source/area").collision_mask
		Spell.Element.VOID: return get_node("mesh/area").collision_mask
		_: return ~0

func _on_body_entered(body: Node3D, contact_points: Array[Vector3]):
	var is_world  : int = body.collision_layer & 0b0001 != 0
	var is_player : int = body.collision_layer & 0b0010 != 0
	var is_enemy  : int = body.collision_layer & 0b0100 != 0
	
	var is_world_object : int = body.collision_layer & (1 << 9) != 0
	var is_fire    : int = body.collision_layer & 0b0_0000_1000 != 0
	var is_rock    : int = body.collision_layer & 0b0_0001_0000 != 0
	var is_water   : int = body.collision_layer & 0b0_0010_0000 != 0
	var is_ice     : int = body.collision_layer & 0b0_1000_0000 != 0
	var is_electric: int = body.collision_layer & 0b1_0000_0000 != 0
	var dmg := {"dmg": spell.power, "el": spell.element}
	var invunerable: bool = (is_player or is_enemy) and body.invunerable > 0.0
	match spell.element:
		Spell.Element.FIRE:
			if is_world or is_rock or is_world_object or is_water:
				expire_now(self, body)
			elif (is_enemy or is_player) and not invunerable:
				CharacterCollision.handle(body, self)
				dmg = body.vitals.handle_damage(Spell.Element.FIRE, spell.damage(body.vitals), spell.power)
				expire_now(self, body)
		Spell.Element.ROCK:
			if body != get_node("body"):
				if is_world or is_world_object:
					lose_control(self, body)
				elif is_rock:
					lose_control(self, body)
					body.apply_central_impulse(impulse())
				elif (is_enemy or is_player) and not invunerable:
					CharacterCollision.handle(body, self)
					dmg = body.vitals.handle_damage(Spell.Element.ROCK, spell.damage(body.vitals), spell.power)
					lose_control(self, body)
		Spell.Element.WATER:
			if is_world or is_rock or is_world_object or is_electric or is_ice:
				expire_now(self, body)
			elif (is_enemy or is_player) and not invunerable:
				CharacterCollision.handle(body, self)
				dmg = body.vitals.handle_damage(Spell.Element.WATER, spell.damage(body.vitals), spell.power)
				expire_now(self, body)
		Spell.Element.AIR:
			if is_world or is_world_object:
				nothing(self, body)
			elif (is_player or is_enemy) and not invunerable:
				CharacterCollision.handle(body, self)
				dmg = body.vitals.handle_damage(Spell.Element.AIR, spell.damage(body.vitals), spell.power)
				nothing(self, body)
			elif is_rock:
				body.apply_impulse(impulse())
				nothing(self, body)
		Spell.Element.ICE:
			if is_world or is_rock or is_world_object or is_fire:
				expire_now(self, body)
			elif (is_player or is_enemy) and not invunerable:
				CharacterCollision.handle(body, self)
				dmg = body.vitals.handle_damage(Spell.Element.ICE, spell.damage(body.vitals), spell.power)
				nothing(self, body)
		Spell.Element.ELECTRIC:
			if is_world or is_rock or is_world_object or is_ice or is_fire:
				pass
			elif (is_player or is_enemy):
				dmg = {} # set to empty so we know we can skip doing invunerable stuff
				# Look at `_on_area_entered` for implementation
				pass
		Spell.Element.VOID:
			if is_world or is_rock or is_world_object:
				nothing(self, body)
			elif (is_enemy or is_player) and not invunerable:
				CharacterCollision.handle(body, self)
				dmg = body.vitals.handle_damage(Spell.Element.VOID, spell.damage(body.vitals), spell.power)
				nothing(self, body)
	
	if not invunerable and dmg != {}:
		if spell.chain_cast_kind == Spell.ChainCastKind.HIT and spell.chain != null and not on_hit_casts.has(body):
			on_hit_casts[body] = true
			cast_spell(func(p): if p != null: call_deferred("add_sibling", p), spell.chain, body)
		Vitals.apply_damage(get_parent(), body, dmg["dmg"], dmg["el"], is_player or is_enemy, true, contact_points, most_recent_radius, velocity)
		if is_player and spell.element != Spell.Element.VOID:
			body.add_shake(clamp(dmg["dmg"] / 10000.0, 0.0, 1.0))
			body.invunerable = 0.33
			body.play_animation("on_hit")
			body.update_artifact_effects(Artifact.Event.RECEIVE, spell)
			body.emit_vitals_update()
		if is_enemy and spell.element != Spell.Element.VOID:
			body.add_shake(clamp(dmg["dmg"] / 10000.0, 0.0, 1.0))
			if body.vitals.health.value <= body.vitals.health.min_value:
				body.vital_update.emit(body.index_in_population, body.vitals)
				body.die()
			else:
				body.invunerable = 0.33
				body.play_animation("on_hit")

func _on_area_entered(area: Area3D, contact_points: Array[Vector3]):
	var body := area.get_parent_node_3d()
	var is_world  : int = area.collision_layer & 0b0001 != 0
	var is_player : int = area.collision_layer & 0b0010 != 0
	var is_enemy  : int = area.collision_layer & 0b0100 != 0
	
	var is_world_object := area.collision_layer & (1 << 9) != 0
	var is_fire  : int = area.collision_layer & 0b0_0000_1000 != 0
	var is_rock  : int = area.collision_layer & 0b1_0000 != 0
	var is_water : int = area.collision_layer & 0b10_0000 != 0
	var is_ice   : int = area.collision_layer & 0b0_1000_0000 != 0
	var is_electric: int = area.collision_layer & 0b1_0000_0000 != 0
	var dmg := {"dmg": spell.power, "el": spell.element}
	var invunerable: bool = (is_player or is_enemy) and body.invunerable > 0.0
	match spell.element:
		Spell.Element.FIRE:
			if is_water:
				expire_now(self, body)
		Spell.Element.WATER:
			if is_electric or is_ice:
				expire_now(self, body)
		Spell.Element.ICE:
			if is_fire:
				expire_now(self, body)
		Spell.Element.ELECTRIC:
			if is_world or is_rock or is_world_object or is_ice or is_fire:
				# Look at `_on_body_entered` for implementation
				pass
			elif (is_player or is_enemy) and is_water and not invunerable:
				CharacterCollision.handle(body, self)
				dmg = body.vitals.handle_damage(Spell.Element.ELECTRIC, spell.damage(body.vitals), spell.power)
				nothing(self, body)
		Spell.Element.VOID:
			if is_world or is_rock or is_world_object:
				nothing(self, body)
			elif (is_enemy or is_player) and not invunerable:
				CharacterCollision.handle(body, self)
				dmg = body.vitals.handle_damage(Spell.Element.VOID, spell.damage(body.vitals), spell.power)
				nothing(self, body)
		_:
			dmg = {}
				
	
	if not invunerable and dmg != {}:
		if spell.chain_cast_kind == Spell.ChainCastKind.HIT and spell.chain != null and not on_hit_casts.has(area):
			on_hit_casts[area] = true
			cast_spell(func(p): if p != null: call_deferred("add_sibling", p), spell.chain, body)
		Vitals.apply_damage(get_parent(), body, dmg["dmg"], dmg["el"], is_player or is_enemy, true, contact_points, most_recent_radius, velocity)
		if is_player and spell.element != Spell.Element.VOID:
			body.add_shake(clamp(dmg["dmg"] / 10000.0, 0.0, 1.0))
			body.invunerable = 0.33
			body.play_animation("on_hit")
			body.update_artifact_effects(Artifact.Event.RECEIVE, spell)
			body.emit_vitals_update()
		if is_enemy and spell.element != Spell.Element.VOID:
			body.add_shake(clamp(dmg["dmg"] / 10000.0, 0.0, 1.0))
			if body.vitals.health.value <= body.vitals.health.min_value:
				body.vital_update.emit(body.index_in_population, body.vitals)
				body.die()
			else:
				body.invunerable = 0.33
				body.play_animation("on_hit")

func update_shape(r: float, ignore_time: bool):
	if r == most_recent_radius:
		return
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
			particles.process_material.scale_min = r * 2.0 / 3.0
			
		Spell.Element.AIR:
			var m_shape: CollisionShape3D = get_node("source/area/shape")
			get_node("source/area").position.y = r * 2
			m_shape.shape.height = r * 4
			m_shape.shape.radius = r
			get_node("shape_cast").shape.height = r * 4
			get_node("shape_cast").shape.radius = r
			
			var source: GPUParticles3D = get_node("source")
			source.process_material.emission_ring_height = r * 4
			
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
			source.process_material.emission_sphere_radius = r
			var mat: ShaderMaterial = source.draw_pass_1.surface_get_material(0)
			mat.set_shader_parameter("len", r * 5)
			var body := get_node("body")
			body.mesh.radius = r
			body.mesh.height = r * 2
			
		Spell.Element.VOID:
			var mesh: SphereMesh = get_node("mesh").mesh
			var shape: CollisionShape3D = get_node("mesh/area/shape")
			mesh.radius = r
			mesh.height = r * 2
			shape.shape.radius = r
			get_node("shape_cast").shape.radius = r
#			mesh.surface_get_material(0).albedo_color = Color8(0, 0, 0, mini(int(255 * (spell.power / 100.0)), 255))
			

func update_movement(p: Vector3, instance: bool, vars: Dictionary):
	var next_pos : Vector3 = p - (vars["rel_pos"] if spell.follow else vars["abs_pos"])
	if started:
		velocity = (next_pos - old_pos) * vars.get("__frame_time", 0.0166667)
		velocity = velocity.normalized()
	old_pos = next_pos
	started = true

	var shape_cast: ShapeCast3D = get_node("shape_cast")
	var target = p - position
	if target.length() > 1.0 or target.distance_to(shape_cast.target_position) > 1.0:
		shape_cast.target_position = target
	var count := shape_cast.get_collision_count()
	for i in range(count):
		var obj := shape_cast.get_collider(i)
		var point := shape_cast.get_collision_point(i)
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
			particles.process_material.direction = (-velocity + Vector3.UP).normalized()
		
		Spell.Element.ROCK:
			position = p
			var rot_axis := Vector3.UP.cross(velocity).normalized()
			var rot_ang := Vector3.UP.angle_to(velocity)
			if rot_axis:
				rotate(rot_axis, rot_ang * vars.get("__frame_time", 0.0166667))
			
				
		Spell.Element.WATER:
			position = p
			var particles: GPUParticles3D = get_node("source")
			particles.process_material.direction = -velocity.normalized()
			
		Spell.Element.AIR:
			position = p
			var box: CollisionShape3D = get_node("source/area/shape")
			var h : float = box.shape.height
			var source: GPUParticles3D = get_node("source")
			source.process_material.initial_velocity_min = (h / source.lifetime) + abs(velocity.length()) * 0.99
			source.process_material.initial_velocity_max = (h / source.lifetime) + abs(velocity.length()) * 1.01
			
			var v = velocity.normalized()
			if v != Vector3.ZERO:
				if v == Vector3.UP:
					v = Vector3(0.1, 0.9, 0.1).normalized()
				var dir : Vector3 = global_position + v * 10
				if not Vector3.UP.cross(dir - global_position).is_zero_approx():
					look_at(dir)
			
		Spell.Element.ICE:
			position = p
			var particles: GPUParticles3D = get_node("source")
			particles.process_material.initial_velocity_min = 0.2 * 0.9
			particles.process_material.initial_velocity_max = 0.2 * 1.1
			var v : Vector3 = velocity.normalized()
			if v != Vector3.ZERO:
				if v == Vector3.UP:
					v = Vector3(0.1, 0.9, 0.1).normalized()
				var dir : Vector3 = global_position + v * 10
				look_at(dir)
			
		Spell.Element.ELECTRIC:
			position = p
			
		Spell.Element.VOID:
			position = p
			
func update_spell(t: float, delta: float, vars: Dictionary):
	if not is_active():
		return
	t = t - pause_time
	fixed_vars["t"] = clampf(t - time_start, 0.0, 100000.0)
	vars["__frame_time"] = delta 
	var p = spell.calculate_location(vars)
	update_movement(p, false, vars)

func stop_emitting():
	const AUDIO_FADE_OUT = 0.7
	match spell.element:
		Spell.Element.FIRE:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			var area: Area3D = get_node("source/area")
			area.collision_mask = 0
			fade_audio(-40, AUDIO_FADE_OUT, false)
			free_after(max(Globals.particle_system_lifetime(particles), AUDIO_FADE_OUT))
			
		Spell.Element.ROCK:
			var body: RigidBody3D = get_node("body")
			body.visible = false
			body.collision_mask = 0
			var area: Area3D = get_node("body/mesh/area")
			area.collision_mask = 0
			fade_audio(-40, AUDIO_FADE_OUT, false)
			free_after(max(0.1, AUDIO_FADE_OUT))
			
		Spell.Element.WATER:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			var area: Area3D = get_node("source/area")
			area.collision_mask = 0
			fade_audio(-40, AUDIO_FADE_OUT, false)
			free_after(max(Globals.particle_system_lifetime(particles), AUDIO_FADE_OUT))
			
		Spell.Element.AIR:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			var area: Area3D = get_node("source/area")
			area.collision_mask = 0
			fade_audio(-40, AUDIO_FADE_OUT, false)
			free_after(max(Globals.particle_system_lifetime(particles), AUDIO_FADE_OUT))
			
		Spell.Element.ICE:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			var area: Area3D = get_node("source/area")
			area.collision_mask = 0
			fade_audio(-40, AUDIO_FADE_OUT, false)
			free_after(max(Globals.particle_system_lifetime(particles), AUDIO_FADE_OUT))
			
		Spell.Element.ELECTRIC:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			var body = get_node("body")
			body.visible = false
			var area: Area3D = get_node("body/area")
			area.collision_mask = 0
			fade_audio(-40, AUDIO_FADE_OUT, false)
			free_after(max(Globals.particle_system_lifetime(particles), AUDIO_FADE_OUT))
			
		Spell.Element.VOID:
			#fade_audio(-40, AUDIO_FADE_OUT, false)
			free_after(max(0.1, AUDIO_FADE_OUT + 0.1))
			
func free_after(duration: float):
	if get_parent() != null and get_tree() != null:
		var max_duration: float = duration
		if max_duration <= 0.0 and not spell_caster.particles.is_empty():
			max_duration = 0.1
		while max_duration > 0:
			await get_tree().create_timer(max_duration, false, true).timeout
			max_duration = actual_duration()
			if not spell_caster.particles.is_empty():
				max_duration = max(max_duration, 2)
			else:
				max_duration = 0
		to_remove = true
		
func fade_audio(final: float, duration: float, is_in: bool):
	var audio: AudioStreamPlayer3D = get_node("audio")
	var tween = get_tree().create_tween()
	if is_in:
		audio.volume_db = -40
		audio.play(0)
	tween.tween_property(audio, "volume_db", final, duration)
	if not is_in:
		tween.tween_callback(audio.stop)

func cast_spell(insert: Callable, next_spell: Spell, target: Node3D):
	await get_tree().physics_frame
	spell_caster.cast_spell(self, null, insert, next_spell, target, fixed_vars)

func free_particle():
	spell_caster.free_particles()
	queue_free()
