class_name SpellBody
extends Node3D

var spell: Spell
var n: int
var time_start: float
var expired: bool = false
var started: bool = false
var in_control: bool = true
var velocity: Vector3 = Vector3.ZERO
var lifetime_velocity: float = 0.0 
var old_pos: Vector3 = Vector3.ZERO
var most_recent_radius: float = 0

var caster_vitals: Vitals
var spell_caster: SpellCaster
var on_hit_casts := {}

var fixed_vars: Dictionary
var expression_vars: Dictionary

var to_remove := false
var origin_node: Node3D = null
var tracking_target: Variant = null

var pause_time: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spell_caster = SpellCaster.new(get_node(".") as Node3D, SpellCaster.Entity.PROJECTILE)
	if spell.chain_cast_kind == Spell.ChainCastKind.START and spell.chain != null:
		cast_spell(func(p: Node3D) -> void: if p != null: call_deferred("add_sibling", p), spell.chain)

func _physics_process(delta: float) -> void:
	spell_caster.update(self, delta)
	if to_remove:
		get_parent().remove_child(self)

func has_expired(t: float) -> bool:
	if time_start <= 0:
		return false
	return expired or (t - time_start) >= spell.duration + pause_time
	
func expire_now(p: Node3D, q: CollisionObject3D) -> void:
	SignalBus.projectile_hit.emit(origin_node, q.collision_layer, spell, Time.get_unix_time_from_system())
	expired = true
	
func explode_after(p: Node3D, q: CollisionObject3D, t: float) -> void:
	var timer := get_tree().create_timer(t)
	timer.timeout.connect(func() -> void:
		SignalBus.projectile_hit.emit(origin_node, q.collision_layer, spell, Time.get_unix_time_from_system())
		expired = true
		var amount := clampi(int(spell.damage(caster_vitals)), 0, 100)
		Vitals.build_explosion(get_parent() as Node3D, p, amount, spell.element, p.position, most_recent_radius, velocity)
	)
	
func is_active() -> bool:
	return in_control and time_start > 0.0  
	
func lose_control(p: Node3D, q: CollisionObject3D) -> void:
	in_control = false
	if spell.element == Spell.Element.ROCK:
		var body: RigidBody3D = p.get_node("body")
		if body.freeze:
			body.freeze = false
			body.apply_central_impulse(velocity)
			SignalBus.projectile_hit.emit(origin_node, q.collision_layer, spell, Time.get_unix_time_from_system())

func nothing(p: Node3D, q: CollisionObject3D) -> void:
	SignalBus.projectile_hit.emit(origin_node, q.collision_layer, spell, Time.get_unix_time_from_system())
	
func actual_duration() -> float:
	var result := (spell.duration + pause_time) - (Time.get_unix_time_from_system() - time_start)
	for p: SpellBody in spell_caster.particles:
		result = max(result, p.actual_duration())
	return max(0, result)
	
func impulse() -> Vector3:
	match spell.element:
		Spell.Element.ROCK:
			var amp := lifetime_velocity / (spell.limit_v + spell.buff_v)
			return velocity * (amp)
		Spell.Element.AIR:
			var amp := lifetime_velocity / (spell.limit_v + spell.buff_v)
			return velocity * (amp * clampf(spell.elemental_application, 0.01, 1.0) * 100)
			
		Spell.Element.FIRE:
			var amp := lifetime_velocity / (spell.limit_v + spell.buff_v)
			return velocity * (amp * 4)
		Spell.Element.WATER:
			var amp := lifetime_velocity / (spell.limit_v + spell.buff_v)
			return velocity * (amp * 2)
		Spell.Element.ELECTRIC:
			return Vector3.ZERO
		Spell.Element.ICE:
			return Vector3.ZERO
			
		Spell.Element.VOID:
			return Vector3.ZERO
			
		_:
			return Vector3.ZERO

func get_collision_object() -> CollisionObject3D:
	match spell.element:
		Spell.Element.FIRE: return (get_node("source/area") as CollisionObject3D)
		Spell.Element.WATER: return (get_node("source/area") as CollisionObject3D)
		Spell.Element.ROCK: return (get_node("body") as CollisionObject3D)
		Spell.Element.AIR: return (get_node("source/area") as CollisionObject3D)
		Spell.Element.ICE: return (get_node("source/area") as CollisionObject3D)
		Spell.Element.ELECTRIC: return (get_node("body/area") as CollisionObject3D)
		Spell.Element.VOID: return (get_node("mesh/area") as CollisionObject3D)
	return null

func get_shape() -> Shape3D:
	match spell.element:
		Spell.Element.FIRE: return (get_node("source/area/shape") as CollisionShape3D).shape
		Spell.Element.WATER: return (get_node("source/area/shape") as CollisionShape3D).shape
		Spell.Element.ROCK: return (get_node("body/shape") as CollisionShape3D).shape
		Spell.Element.AIR: return (get_node("source/area/shape") as CollisionShape3D).shape
		Spell.Element.ICE: return (get_node("source/area/shape") as CollisionShape3D).shape
		Spell.Element.ELECTRIC: return (get_node("body/area/shape") as CollisionShape3D).shape
		Spell.Element.VOID: return (get_node("mesh/area/shape") as CollisionShape3D).shape
		_: return BoxShape3D.new()

func get_spell_transform() -> Transform3D:
	if spell.element == Spell.Element.ROCK:
		return (get_node("body") as Node3D).global_transform
	elif spell.element == Spell.Element.AIR:
		return (get_node("source/area/shape") as Node3D).global_transform
	else:
		return global_transform
		
func get_spell_collision_mask() -> int:
	match spell.element:
		Spell.Element.FIRE: return (get_node("source/area") as Area3D).collision_mask
		Spell.Element.WATER: return (get_node("source/area") as Area3D).collision_mask
		Spell.Element.ROCK: return (get_node("body") as Area3D).collision_mask
		Spell.Element.AIR: return (get_node("source/area") as Area3D).collision_mask
		Spell.Element.ICE: return (get_node("source/area") as Area3D).collision_mask
		Spell.Element.ELECTRIC: return (get_node("source/area") as Area3D).collision_mask
		Spell.Element.VOID: return (get_node("mesh/area") as Area3D).collision_mask
		_: return ~0

func _on_body_entered(_body: CollisionObject3D, contact_points: Array[Vector3]) -> void:
	var is_world  : int = _body.collision_layer & 0b0001 != 0
	var is_player : int = _body.collision_layer & 0b0010 != 0
	var is_enemy  : int = _body.collision_layer & 0b0100 != 0
	
	var is_world_object : int = _body.collision_layer & (1 << 9) != 0
	var is_fire    : int = _body.collision_layer & 0b0_0000_1000 != 0
	var is_rock    : int = _body.collision_layer & 0b0_0001_0000 != 0
	#var is_water   : int = _body.collision_layer & 0b0_0010_0000 != 0
	var is_ice     : int = _body.collision_layer & 0b0_1000_0000 != 0
	#var is_electric: int = _body.collision_layer & 0b1_0000_0000 != 0
	var dmg := {"el": spell.element, "dmg": spell.power} # set default for contact with non player/enemy
	var invunerable: bool = (is_player or is_enemy) and (_body as CharacterBody).invunerable > 0.0
	match spell.element:
		Spell.Element.FIRE:
			if is_world or is_rock or is_world_object:
				expire_now(self, _body)
			elif (is_enemy or is_player) and not invunerable:
				var body := _body as CharacterBody
				CharacterCollision.handle(body, self)
				dmg = body.vitals.handle_damage(Spell.Element.FIRE, spell.damage(caster_vitals), spell.elemental_application)
				expire_now(self, body)
		Spell.Element.ROCK:
			if _body != get_node("body"):
				if is_world or is_world_object:
					lose_control(self, _body)
				elif is_rock:
					lose_control(self, _body)
					(_body as RigidBody3D).apply_central_impulse(impulse())
				elif (is_enemy or is_player) and not invunerable:
					var body := _body as CharacterBody
					CharacterCollision.handle(body, self)
					dmg = body.vitals.handle_damage(Spell.Element.ROCK, spell.damage(caster_vitals), spell.elemental_application)
					lose_control(self, body)
		Spell.Element.WATER:
			if is_world or is_rock or is_world_object or is_ice:
				expire_now(self, _body)
			elif (is_enemy or is_player) and not invunerable:
				var body := _body as CharacterBody
				CharacterCollision.handle(body, self)
				dmg = body.vitals.handle_damage(Spell.Element.WATER, spell.damage(caster_vitals), spell.elemental_application)
				expire_now(self, body)
		Spell.Element.AIR:
			if is_world or is_world_object:
				nothing(self, _body)
			elif (is_player or is_enemy) and not invunerable:
				var body := _body as CharacterBody
				CharacterCollision.handle(body, self)
				dmg = body.vitals.handle_damage(Spell.Element.AIR, spell.damage(caster_vitals), spell.elemental_application)
				nothing(self, body)
			elif is_rock:
				(_body as RigidBody3D).apply_impulse(impulse())
				nothing(self, _body)
		Spell.Element.ICE:
			if is_world or is_rock or is_world_object or is_fire:
				expire_now(self, _body)
			elif (is_player or is_enemy) and not invunerable:
				var body := _body as CharacterBody
				CharacterCollision.handle(body, self)
				dmg = body.vitals.handle_damage(Spell.Element.ICE, spell.damage(caster_vitals), spell.elemental_application)
				nothing(self, body)
		Spell.Element.ELECTRIC:
			if is_world or is_rock or is_world_object:
				pass
			elif is_fire:
				update_shape(spell.radius * 2, true)
			elif (is_player or is_enemy):
				dmg = {} # set to empty so we know we can skip doing invunerable stuff
				# Look at `_on_area_entered` for implementation
				pass
		Spell.Element.VOID:
			if is_world or is_rock or is_world_object:
				nothing(self, _body)
			elif (is_enemy or is_player) and not invunerable:
				var body := _body as CharacterBody
				CharacterCollision.handle(body, self)
				dmg = body.vitals.handle_damage(Spell.Element.VOID, spell.damage(caster_vitals), spell.elemental_application)
				nothing(self, body)
	
	if not invunerable and dmg != {}:
		if spell.chain_cast_kind == Spell.ChainCastKind.HIT and spell.chain != null and not on_hit_casts.has(_body):
			on_hit_casts[_body] = true
			cast_spell(func(p: Node3D) -> void: if p != null: call_deferred("add_sibling", p), spell.chain)
		Vitals.apply_damage(get_parent() as Node3D, _body, dmg["dmg"] as float, dmg["el"] as Spell.Element, is_player or is_enemy, true, contact_points, most_recent_radius, velocity)
		if is_player and spell.element != Spell.Element.VOID:
			var body := _body as Player
			body.add_shake(clampf(dmg["dmg"] as float / 10000.0, 0.0, 1.0))
			body.invunerable = 0.33
			body.play_animation("on_hit")
			body.update_artifact_effects(Artifact.Event.RECEIVE, spell)
			body.emit_vitals_update()
		if is_enemy and spell.element != Spell.Element.VOID:
			var body := _body as Enemy
			body.add_shake(clampf(dmg["dmg"] as float / 10000.0, 0.0, 1.0))
			if body.vitals.health.value <= body.vitals.health.min_value:
				body.vital_update.emit(body.index_in_population, body.vitals)
				body.die()
			else:
				body.invunerable = 0.33
				body.play_animation("on_hit")

func _on_area_entered(area: Area3D, contact_points: Array[Vector3]) -> void:
	var _body := area.get_parent_node_3d() as CollisionObject3D
	var is_world  : int = area.collision_layer & 0b0001 != 0
	var is_player : int = area.collision_layer & 0b0010 != 0
	var is_enemy  : int = area.collision_layer & 0b0100 != 0
	
	var is_world_object := area.collision_layer & (1 << 9) != 0
	var is_fire  : int = area.collision_layer & 0b0_0000_1000 != 0
	var is_rock  : int = area.collision_layer & 0b1_0000 != 0
	var is_water : int = area.collision_layer & 0b10_0000 != 0
	var is_ice   : int = area.collision_layer & 0b0_1000_0000 != 0
	var is_electric: int = area.collision_layer & 0b1_0000_0000 != 0
	var dmg := {}
	var invunerable: bool = (is_player or is_enemy) and (_body as CharacterBody).invunerable > 0.0
	match spell.element:
		Spell.Element.FIRE:
			if is_water:
				expire_now(self, _body)
			elif is_electric:
				update_shape(spell.radius * 3, true)
				explode_after(self, _body, 0.0166667 * 2)
		Spell.Element.WATER:
			if is_ice:
				expire_now(self, _body)
		Spell.Element.ICE:
			if is_water:
				spell.elemental_application = clampf(spell.elemental_application * 1.1, 0.0, 1.0)
		Spell.Element.ELECTRIC:
			if is_world or is_rock or is_world_object:
				# Look at `_on_body_entered` for implementation
				pass
			elif is_fire:
				update_shape(spell.radius * 3, true)
				explode_after(self, _body, 0.0166667 * 2)
				pass
			elif (is_player or is_enemy) and is_water and not invunerable:
				var body := area.get_parent_node_3d() as CharacterBody
				CharacterCollision.handle(body, self)
				dmg = body.vitals.handle_damage(Spell.Element.ELECTRIC, spell.damage(caster_vitals), spell.elemental_application)
				nothing(self, body)
		Spell.Element.VOID:
			if is_world or is_rock or is_world_object:
				nothing(self, _body)
			elif (is_enemy or is_player) and not invunerable:
				var body := area.get_parent_node_3d() as CharacterBody
				CharacterCollision.handle(body, self)
				dmg = body.vitals.handle_damage(Spell.Element.VOID, spell.damage(caster_vitals), spell.elemental_application)
				nothing(self, body)
		_:
			dmg = {}
				
	
	if not invunerable and dmg != {}:
		if spell.chain_cast_kind == Spell.ChainCastKind.HIT and spell.chain != null and not on_hit_casts.has(area):
			on_hit_casts[area] = true
			cast_spell(func(p: Node3D) -> void: if p != null: call_deferred("add_sibling", p), spell.chain)
		Vitals.apply_damage(get_parent() as Node3D, _body, dmg["dmg"] as float, dmg["el"] as Spell.Element, is_player or is_enemy, true, contact_points, most_recent_radius, velocity)
		if is_player and spell.element != Spell.Element.VOID:
			var body := area.get_parent_node_3d() as Player
			body.add_shake(clampf(dmg["dmg"] as float / 10000.0, 0.0, 1.0))
			body.invunerable = 0.33
			body.play_animation("on_hit")
			body.update_artifact_effects(Artifact.Event.RECEIVE, spell)
			body.emit_vitals_update()
		if is_enemy and spell.element != Spell.Element.VOID:
			var body := area.get_parent_node_3d() as Enemy
			body.add_shake(clampf(dmg["dmg"] as float / 10000.0, 0.0, 1.0))
			if body.vitals.health.value <= body.vitals.health.min_value:
				body.vital_update.emit(body.index_in_population, body.vitals)
				body.die()
			else:
				body.invunerable = 0.33
				body.play_animation("on_hit")

func update_shape(r: float, ignore_time: bool) -> void:
	if r == most_recent_radius:
		return
	most_recent_radius = r
	
	match spell.element:
		Spell.Element.FIRE:
			var particles: GPUParticles3D = get_node("source")
			var shape: CollisionShape3D = get_node("source/area/shape")
			(particles.process_material as ParticleProcessMaterial).emission_sphere_radius = r
			(particles.process_material as ParticleProcessMaterial).scale_min = r * 2
			(particles.process_material as ParticleProcessMaterial).scale_max = r * 2
			(particles.process_material as ParticleProcessMaterial).initial_velocity_max = r * 2
			(shape.shape as SphereShape3D).radius = r
			((get_node("shape_cast") as ShapeCast3D).shape as SphereShape3D).radius = r
			
		Spell.Element.ROCK:
			if not ignore_time:
#				var R = get_node("body/shape").shape.size.x
#				scale = Vector3(r / R, r / R, r / R)
				return
			var p_shape: CollisionShape3D = get_node("body/shape")
			var m_shape: CollisionShape3D = get_node("body/mesh/area/shape")
			(p_shape.shape as BoxShape3D).size.x = r
			(p_shape.shape as BoxShape3D).size.y = r
			(p_shape.shape as BoxShape3D).size.z = r
			(m_shape.shape as BoxShape3D).size.x = r
			(m_shape.shape as BoxShape3D).size.y = r
			(m_shape.shape as BoxShape3D).size.z = r
			((get_node("shape_cast") as ShapeCast3D).shape as BoxShape3D).size.x = r
			((get_node("shape_cast") as ShapeCast3D).shape as BoxShape3D).size.y = r
			((get_node("shape_cast") as ShapeCast3D).shape as BoxShape3D).size.z = r
			var mesh: MeshInstance3D = get_node("body/mesh")
			(mesh.mesh as BoxMesh).size.x = r
			(mesh.mesh as BoxMesh).size.y = r
			(mesh.mesh as BoxMesh).size.z = r
			
			var body: RigidBody3D = get_node("body")
			body.mass = r
			scale = Vector3(1, 1, 1)
			
		Spell.Element.WATER:
			var m_shape: CollisionShape3D = get_node("source/area/shape")
			(m_shape.shape as SphereShape3D).radius = r
			((get_node("shape_cast") as ShapeCast3D).shape as SphereShape3D).radius = r
			var particles: GPUParticles3D = get_node("source")
			(particles.process_material as ParticleProcessMaterial).emission_sphere_radius = r
			(particles.process_material as ParticleProcessMaterial).initial_velocity_max = r * 2
			(particles.process_material as ParticleProcessMaterial).scale_max = r * 2
			(particles.process_material as ParticleProcessMaterial).scale_min = r * 2.0 / 3.0
			
		Spell.Element.AIR:
			var m_shape: CollisionShape3D = get_node("source/area/shape")
			(get_node("source/area") as Node3D).position.y = r * 2
			(m_shape.shape as CylinderShape3D).height = r * 4
			(m_shape.shape as CylinderShape3D).radius = r
			((get_node("shape_cast") as ShapeCast3D).shape as CylinderShape3D).height = r * 4
			((get_node("shape_cast") as ShapeCast3D).shape as CylinderShape3D).radius = r
			
			var source: GPUParticles3D = get_node("source")
			(source.process_material as ParticleProcessMaterial).emission_ring_height = r * 4
			
			var source2: GPUParticles3D = get_node("source")
			(source2.draw_pass_1.surface_get_material(0) as ShaderMaterial).set_shader_parameter("width", r / 10.0)
			(source2.draw_pass_1.surface_get_material(0) as ShaderMaterial).set_shader_parameter("len", r)
			(source2.draw_pass_1.surface_get_material(0) as ShaderMaterial).set_shader_parameter("radius", r / 2)
			(source2.draw_pass_1.surface_get_material(0) as ShaderMaterial).set_shader_parameter("period", r / 4)
			(source2.process_material as ParticleProcessMaterial).emission_ring_radius = r
			
		Spell.Element.ICE:
			var m_shape: CollisionShape3D = get_node("source/area/shape")
			(m_shape.shape as BoxShape3D).size.x = r * 2
			(m_shape.shape as BoxShape3D).size.z = r * 2
			((get_node("shape_cast") as ShapeCast3D).shape as BoxShape3D).size.x = r * 2
			((get_node("shape_cast") as ShapeCast3D).shape as BoxShape3D).size.z = r * 2
			
			var source: GPUParticles3D = get_node("source")
			(source.process_material as ParticleProcessMaterial).emission_box_extents = Vector3(r, 0.2, r)
			
		Spell.Element.ELECTRIC:
			var m_shape: CollisionShape3D = get_node("body/area/shape")
			(m_shape.shape as SphereShape3D).radius = r
			((get_node("shape_cast") as ShapeCast3D).shape as SphereShape3D).radius = r
			
			var source: GPUParticles3D = get_node("source")
			(source.process_material as ParticleProcessMaterial).emission_sphere_radius = r
			var mat: ShaderMaterial = source.draw_pass_1.surface_get_material(0)
			mat.set_shader_parameter("len", r * 5)
			var body := get_node("body") as MeshInstance3D
			(body.mesh as SphereMesh).radius = r
			(body.mesh as SphereMesh).height = r * 2
			
		Spell.Element.VOID:
			var mesh: SphereMesh = (get_node("mesh") as MeshInstance3D).mesh
			var shape: CollisionShape3D = get_node("mesh/area/shape")
			mesh.radius = r
			mesh.height = r * 2
			(shape.shape as SphereShape3D).radius = r
			((get_node("shape_cast") as ShapeCast3D).shape as SphereShape3D).radius = r
#			mesh.surface_get_material(0).albedo_color = Color8(0, 0, 0, mini(int(255 * (spell.power / 100.0)), 255))
			

func update_movement(p: Vector3, instance: bool, vars: Dictionary) -> void:
	var next_pos : Vector3 = p - (vars["rel_pos"] if spell.follow else vars["abs_pos"])
	if started:
		velocity = (next_pos - old_pos) * vars.get("__frame_time", 0.0166667)
		velocity = velocity.normalized()
	old_pos = next_pos
	started = true

	var shape_cast: ShapeCast3D = get_node("shape_cast")
	var target := p - position
	if target.length() > 1.0 or target.distance_to(shape_cast.target_position) > 1.0:
		shape_cast.target_position = target
	var count := shape_cast.get_collision_count()
	for i in range(count):
		var obj := shape_cast.get_collider(i)
		var point := shape_cast.get_collision_point(i)
		if spell.element == Spell.Element.ROCK and (obj == get_node("body")):
			continue
		if obj is Area3D:
			_on_area_entered(obj as Area3D, [point])
		elif obj is CollisionObject3D:
			_on_body_entered(obj as CollisionObject3D, [point])
	
	match spell.element:
		Spell.Element.FIRE:
			position = p
			var particles: GPUParticles3D = get_node("source")
			(particles.process_material as ParticleProcessMaterial).direction = (-velocity + Vector3.UP).normalized()
		
		Spell.Element.ROCK:
			position = p
			var rot_axis := Vector3.UP.cross(velocity).normalized()
			var rot_ang := Vector3.UP.angle_to(velocity)
			if rot_axis:
				rotate(rot_axis, rot_ang * vars.get("__frame_time", 0.0166667) as float)
			
				
		Spell.Element.WATER:
			position = p
			var particles: GPUParticles3D = get_node("source")
			(particles.process_material as ParticleProcessMaterial).direction = -velocity.normalized()
			
		Spell.Element.AIR:
			position = p
			var box: CollisionShape3D = get_node("source/area/shape")
			var h : float = (box.shape as CylinderShape3D).height
			var source: GPUParticles3D = get_node("source")
			(source.process_material as ParticleProcessMaterial).initial_velocity_min = (h / source.lifetime) + abs(velocity.length()) * 0.99
			(source.process_material as ParticleProcessMaterial).initial_velocity_max = (h / source.lifetime) + abs(velocity.length()) * 1.01
			
			var v := velocity.normalized()
			if v != Vector3.ZERO:
				if v == Vector3.UP:
					v = Vector3(0.1, 0.9, 0.1).normalized()
				var dir : Vector3 = global_position + v * 10
				if not Vector3.UP.cross(dir - global_position).is_zero_approx():
					look_at(dir)
			
		Spell.Element.ICE:
			position = p
			var particles: GPUParticles3D = get_node("source")
			(particles.process_material as ParticleProcessMaterial).initial_velocity_min = 0.2 * 0.9
			(particles.process_material as ParticleProcessMaterial).initial_velocity_max = 0.2 * 1.1
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
			
func update_spell(t: float, delta: float, vars: Dictionary) -> void:
	if not is_active():
		return
	t = t - pause_time
	fixed_vars["t"] = clampf(t - time_start, 0.0, 100000.0)
	vars["__frame_time"] = delta 
	var p := spell.calculate_location(vars)
	update_movement(p, false, vars)

func stop_emitting() -> void:
	const AUDIO_FADE_OUT = 0.7
	match spell.element:
		Spell.Element.FIRE:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			var area: Area3D = get_node("source/area")
			area.collision_mask = 0
			fade_audio(-40, AUDIO_FADE_OUT, false)
			free_after(maxf(Globals.particle_system_lifetime(particles), AUDIO_FADE_OUT))
			
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
			free_after(maxf(Globals.particle_system_lifetime(particles), AUDIO_FADE_OUT))
			
		Spell.Element.AIR:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			var area: Area3D = get_node("source/area")
			area.collision_mask = 0
			fade_audio(-40, AUDIO_FADE_OUT, false)
			free_after(maxf(Globals.particle_system_lifetime(particles), AUDIO_FADE_OUT))
			
		Spell.Element.ICE:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			var area: Area3D = get_node("source/area")
			area.collision_mask = 0
			fade_audio(-40, AUDIO_FADE_OUT, false)
			free_after(maxf(Globals.particle_system_lifetime(particles), AUDIO_FADE_OUT))
			
		Spell.Element.ELECTRIC:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			var body := get_node("body") as MeshInstance3D
			body.visible = false
			var area: Area3D = get_node("body/area")
			area.collision_mask = 0
			fade_audio(-40, AUDIO_FADE_OUT, false)
			free_after(maxf(Globals.particle_system_lifetime(particles), AUDIO_FADE_OUT))
			
		Spell.Element.VOID:
			#fade_audio(-40, AUDIO_FADE_OUT, false)
			free_after(maxf(0.1, AUDIO_FADE_OUT + 0.1))
			
func free_after(duration: float) -> void:
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
		
func fade_audio(final: float, duration: float, is_in: bool) -> void:
	var audio: AudioStreamPlayer3D = get_node("audio")
	var tween := get_tree().create_tween()
	if is_in:
		audio.volume_db = -40
		audio.play(0)
	tween.tween_property(audio, "volume_db", final, duration)
	if not is_in:
		tween.tween_callback(audio.stop)

func cast_spell(insert: Callable, next_spell: Spell) -> void:
	await get_tree().physics_frame
	spell_caster.cast_spell(self, null, insert, next_spell, tracking_target, fixed_vars)

func free_particle() -> void:
	spell_caster.free_particles()
	queue_free()
