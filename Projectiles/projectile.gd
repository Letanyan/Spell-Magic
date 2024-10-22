class_name SpellBody
extends Node3D

var spell: Spell
var n: int
var time_start: float
var expired: bool = false
var is_emitting: bool = true
var started: bool = false
var in_control: bool = true
var free_when_ready := NAN
var velocity: Vector3 = Vector3.ZERO
var old_velocity := Vector3.ZERO
var lifetime_velocity: float = 0.0 
var old_pos: Vector3 = Vector3.ZERO
var most_recent_radius: Vector3 = Vector3.ZERO
var rng: RandomNumberGenerator

var complexity_id: int = 0

var caster_vitals: Vitals
var spell_caster: SpellCaster
var on_hit_casts := {}

var fixed_vars: Dictionary
var expression_vars: Dictionary
var override_vars: Dictionary

var to_remove := false
var origin_node: Node3D = null
var tracking_target: Variant = null
var origin_spell_caster: SpellCaster = null

var pause_time: float = 0.0

const INVUNERABLE_DURATION: float = 0.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spell_caster = SpellCaster.new(origin_node, SpellCaster.Entity.PROJECTILE)
	if spell.chain_cast_kind == Spell.ChainCastKind.START and spell.chain != null:
		cast_spell(func(p: Node3D) -> void: if p != null: call_deferred("add_sibling", p), spell.chain)
	rng = RandomNumberGenerator.new()
	rng.seed = hash(spell.name)
	if origin_node is Player:
		origin_spell_caster = (origin_node as Player).spell_caster
	elif origin_node is Enemy:
		origin_spell_caster = (origin_node as Enemy).spell_caster
		

func _physics_process(delta: float) -> void:
	pass

func has_expired(t: float) -> bool:
	if time_start <= 0:
		return false
	return expired or (t - time_start) >= spell.duration + pause_time
	
func expire_now(p: Node3D, q: CollisionObject3D, damage: Dictionary) -> void:
	if q != null:
		SignalBus.projectile_hit.emit(origin_node, q, spell, Time.get_unix_time_from_system(), p, damage)
	expired = true
	
func explode_after(p: Node3D, q: CollisionObject3D, t: float, is_alternate: bool, damage: Dictionary) -> void:
	var timer := get_tree().create_timer(t)
	timer.timeout.connect(func() -> void:
		if q != null:
			SignalBus.projectile_hit.emit(origin_node, q, spell, Time.get_unix_time_from_system(), p, damage)
		expired = true
		var amount := clampi(int(spell.damage(caster_vitals)), 0, 100)
		Vitals.build_explosion(get_parent() as Node3D, p, amount, spell.element, p.position, most_recent_radius.length(), velocity, is_alternate)
	)
	
func is_active() -> bool:
	return in_control and time_start > 0.0  
	
func lose_control(p: Node3D, q: CollisionObject3D, damage: Dictionary) -> void:
	in_control = false
	if spell.element == Spell.Element.ROCK:
		var body: RigidBody3D = p.get_node("body")
		if body.freeze:
			body.freeze = false
			body.apply_central_impulse(velocity)
			if q != null:
				SignalBus.projectile_hit.emit(origin_node, q, spell, Time.get_unix_time_from_system(), p, damage)

func nothing(p: Node3D, q: CollisionObject3D, damage: Dictionary) -> void:
	if q != null:
		SignalBus.projectile_hit.emit(origin_node, q, spell, Time.get_unix_time_from_system(), p, damage)
	
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
			return velocity * (amp + clampf(spell.elemental_application, 0.0, 1.0)) * 20
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

func get_shape() -> Shape3D:
	return (get_node("shape_cast") as ShapeCast3D).shape

func get_spell_transform() -> Transform3D:
	if spell.element == Spell.Element.ROCK:
		return (get_node("body") as Node3D).global_transform
	elif spell.element == Spell.Element.AIR:
		return (get_node("source") as Node3D).global_transform
	else:
		return global_transform
		
func get_spell_collision_mask() -> int:
	return (get_node("shape_cast") as ShapeCast3D).collision_mask

func _on_body_entered(_body: CollisionObject3D, contact_points: Array[Vector3]) -> void:
	var is_world  : int = _body.collision_layer & 0b0001 != 0
	var is_player : int = _body.collision_layer & 0b0010 != 0
	var is_enemy  : int = _body.collision_layer & 0b0100 != 0
	
	if is_enemy and (origin_node is Enemy or origin_node is TargetShape):
		return
	
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
				expire_now(self, _body, dmg)
			elif (is_enemy or is_player) and not invunerable:
				var body := _body as CharacterBody
				body.add_impulse(impulse())
				dmg = body.vitals.handle_damage(Spell.Element.FIRE, spell.damage(caster_vitals), spell.elemental_application)
				expire_now(self, body, dmg)
		Spell.Element.ROCK:
			if _body != get_node("body"):
				if is_world or is_world_object:
					lose_control(self, _body, dmg)
				elif is_rock:
					lose_control(self, _body, dmg)
					(_body as RigidBody3D).apply_central_impulse(impulse())
				elif (is_enemy or is_player) and not invunerable:
					var body := _body as CharacterBody
					body.add_impulse(impulse())
					dmg = body.vitals.handle_damage(Spell.Element.ROCK, spell.damage(caster_vitals), spell.elemental_application)
					lose_control(self, body, dmg)
		Spell.Element.WATER:
			if is_world or is_rock or is_world_object or is_ice:
				expire_now(self, _body, dmg)
			elif (is_enemy or is_player) and not invunerable:
				var body := _body as CharacterBody
				body.add_impulse(impulse())
				dmg = body.vitals.handle_damage(Spell.Element.WATER, spell.damage(caster_vitals), spell.elemental_application)
				expire_now(self, body, dmg)
		Spell.Element.AIR:
			if is_world or is_world_object:
				nothing(self, _body, dmg)
			elif (is_player or is_enemy) and not invunerable:
				var body := _body as CharacterBody
				body.add_impulse(impulse())
				dmg = body.vitals.handle_damage(Spell.Element.AIR, spell.damage(caster_vitals), spell.elemental_application)
				nothing(self, body, dmg)
			elif is_rock:
				(_body as RigidBody3D).apply_impulse(impulse())
				nothing(self, _body, dmg)
		Spell.Element.ICE:
			if is_world or is_rock or is_world_object or is_fire:
				expire_now(self, _body, dmg)
			elif (is_player or is_enemy) and not invunerable:
				var body := _body as CharacterBody
				body.add_impulse(impulse())
				dmg = body.vitals.handle_damage(Spell.Element.ICE, spell.damage(caster_vitals), spell.elemental_application)
				nothing(self, body, dmg)
		Spell.Element.ELECTRIC:
			if is_world or is_rock or is_world_object:
				pass
			elif is_fire:
				update_shape(Vector3(1, 1, 1).normalized() * spell.radius * 2, true)
			elif (is_player or is_enemy):
				dmg = {} # set to empty so we know we can skip doing invunerable stuff
				# Look at `_on_area_entered` for implementation
				pass
		Spell.Element.VOID:
			if is_world or is_rock or is_world_object:
				nothing(self, _body, dmg)
			elif (is_enemy or is_player) and not invunerable:
				var body := _body as CharacterBody
				body.add_impulse(impulse())
				dmg = body.vitals.handle_damage(Spell.Element.VOID, spell.damage(caster_vitals), spell.elemental_application)
				nothing(self, body, dmg)
	
	if not invunerable and dmg != {}:
		if spell.chain_cast_kind == Spell.ChainCastKind.HIT and spell.chain != null and not on_hit_casts.has(_body):
			on_hit_casts[_body] = true
			cast_spell(func(p: Node3D) -> void: if p != null: call_deferred("add_sibling", p), spell.chain)
		Vitals.apply_damage(get_parent() as Node3D, _body, dmg["dmg"] as float, dmg["el"] as Spell.Element, is_player or is_enemy, true, contact_points, most_recent_radius.length(), velocity)
		if is_player and spell.element != Spell.Element.VOID:
			var body := _body as Player
			body.add_shake(clampf(dmg["dmg"] as float / 10000.0, 0.0, 1.0))
			body.invunerable = INVUNERABLE_DURATION
			if dmg["dmg"] > 0:
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
				body.invunerable = INVUNERABLE_DURATION
				if dmg["dmg"] > 0:
					body.play_animation("on_hit")

func _on_area_entered(area: Area3D, contact_points: Array[Vector3]) -> void:
	var _body := area.get_parent_node_3d() as CollisionObject3D
	var is_world  : int = area.collision_layer & 0b0001 != 0
	var is_player : int = area.collision_layer & 0b0010 != 0
	var is_enemy  : int = area.collision_layer & 0b0100 != 0
	
	if is_enemy and origin_node is Enemy:
		return
	
	var is_world_object := area.collision_layer & (1 << 9) != 0
	var is_fire  : int = area.collision_layer   & 0b0_0000_1000 != 0
	var is_rock  : int = area.collision_layer   & 0b0_0001_0000 != 0
	var is_water : int = area.collision_layer   & 0b0_0010_0000 != 0
	var is_ice   : int = area.collision_layer   & 0b0_1000_0000 != 0
	var is_electric: int = area.collision_layer & 0b1_0000_0000 != 0
	var dmg := {}
	var invunerable: bool = (is_player or is_enemy) and (_body as CharacterBody).invunerable > 0.0
	match spell.element:
		Spell.Element.FIRE:
			if not (is_enemy or is_player):
				if is_water:
					expire_now(self, _body, dmg)
				elif is_electric:
					update_shape(Vector3(1, 1, 1).normalized() * spell.radius * 3, true)
					explode_after(self, _body, 0.0166667 * 2, false, dmg)
		Spell.Element.WATER:
			if not (is_enemy or is_player):
				if is_ice:
					expire_now(self, _body, dmg)
				elif is_fire:
					explode_after(self, _body, 0.0166667 * 2, true, dmg)
		Spell.Element.ICE:
			if not (is_enemy or is_player):
				if is_water:
					spell.elemental_application = clampf(spell.elemental_application * 1.1, 0.0, 1.0)
		Spell.Element.ELECTRIC:
			if not (is_enemy or is_player):
				if is_world or is_rock or is_world_object:
					# Look at `_on_body_entered` for implementation
					pass
				elif is_fire:
					update_shape(Vector3(1, 1, 1).normalized() * spell.radius * 3, true)
					explode_after(self, _body, 0.0166667 * 2, false, dmg)
					pass
			elif is_water and not invunerable:
				var body := area.get_parent_node_3d() as CharacterBody
				body.add_impulse(impulse())
				dmg = body.vitals.handle_damage(Spell.Element.ELECTRIC, spell.damage(caster_vitals), spell.elemental_application)
				nothing(self, body, dmg)
		Spell.Element.VOID:
			if not (is_player or is_enemy):
				if is_world or is_rock or is_world_object:
					nothing(self, _body, dmg)
			elif not invunerable:
				var body := area.get_parent_node_3d() as CharacterBody
				body.add_impulse(impulse())
				dmg = body.vitals.handle_damage(Spell.Element.VOID, spell.damage(caster_vitals), spell.elemental_application)
				nothing(self, body, dmg)
		_:
			dmg = {}
				
	
	if not invunerable and dmg != {}:
		if spell.chain_cast_kind == Spell.ChainCastKind.HIT and spell.chain != null and not on_hit_casts.has(area):
			on_hit_casts[area] = true
			cast_spell(func(p: Node3D) -> void: if p != null: call_deferred("add_sibling", p), spell.chain)
		Vitals.apply_damage(get_parent() as Node3D, _body, dmg["dmg"] as float, dmg["el"] as Spell.Element, is_player or is_enemy, true, contact_points, most_recent_radius.length(), velocity)
		if is_player and spell.element != Spell.Element.VOID:
			var body := area.get_parent_node_3d() as Player
			body.add_shake(clampf(dmg["dmg"] as float / 10000.0, 0.0, 1.0))
			body.invunerable = INVUNERABLE_DURATION
			if dmg["dmg"] > 0:
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
				body.invunerable = INVUNERABLE_DURATION
				if dmg["dmg"] > 0:
					body.play_animation("on_hit")

func update_shape(r: Vector3, ignore_time: bool) -> void:
	if r == most_recent_radius:
		return
	most_recent_radius = r
	var rl := r.length()
	
	match spell.element:
		Spell.Element.FIRE:
			var particles: GPUParticles3D = get_node("source")
			(particles.process_material as ParticleProcessMaterial).emission_sphere_radius = rl
			(particles.process_material as ParticleProcessMaterial).scale_min = rl * 2
			(particles.process_material as ParticleProcessMaterial).scale_max = rl * 2
			(particles.process_material as ParticleProcessMaterial).initial_velocity_max = rl * 2
			((get_node("shape_cast") as ShapeCast3D).shape as SphereShape3D).radius = rl
			particles.amount = roundi(80 * rl)
			
			#particles.local_coords = spell.follow
			
		Spell.Element.ROCK:
			if not ignore_time:
#				var R = get_node("body/shape").shape.size.x
#				scale = Vector3(r / R, r / R, r / R)
				return
			var p_shape: CollisionShape3D = get_node("body/shape")
			
			(p_shape.shape as BoxShape3D).size.x = r.x * 2
			(p_shape.shape as BoxShape3D).size.y = r.y * 2
			(p_shape.shape as BoxShape3D).size.z = r.z * 2
			((get_node("shape_cast") as ShapeCast3D).shape as BoxShape3D).size.x = r.x * 2
			((get_node("shape_cast") as ShapeCast3D).shape as BoxShape3D).size.y = r.y * 2
			((get_node("shape_cast") as ShapeCast3D).shape as BoxShape3D).size.z = r.z * 2
			var mesh: MeshInstance3D = get_node("body/mesh")
			(mesh.mesh as BoxMesh).size.x = r.x * 2
			(mesh.mesh as BoxMesh).size.y = r.y * 2
			(mesh.mesh as BoxMesh).size.z = r.z * 2
			
			var body: RigidBody3D = get_node("body")
			body.mass = (r.x + r.y + r.z) / 3.0 * 2.0
			scale = Vector3(1, 1, 1)
			
		Spell.Element.WATER:
			((get_node("shape_cast") as ShapeCast3D).shape as SphereShape3D).radius = rl
			var particles: GPUParticles3D = get_node("source")
			(particles.process_material as ParticleProcessMaterial).emission_sphere_radius = rl
			(particles.process_material as ParticleProcessMaterial).initial_velocity_max = rl * 2
			(particles.process_material as ParticleProcessMaterial).scale_max = rl * 2
			(particles.process_material as ParticleProcessMaterial).scale_min = rl * 2.0 / 3.0
			#particles.local_coords = spell.follow
			particles.amount = roundi(80 * rl)
			
		Spell.Element.AIR:
			((get_node("shape_cast") as ShapeCast3D).shape as CylinderShape3D).height = rl * 4
			((get_node("shape_cast") as ShapeCast3D).shape as CylinderShape3D).radius = rl
			
			var source: GPUParticles3D = get_node("source")
			(source.process_material as ParticleProcessMaterial).emission_ring_height = rl * 4
			(source.process_material as ParticleProcessMaterial).emission_ring_radius = rl
			(source.draw_pass_1.surface_get_material(0) as ShaderMaterial).set_shader_parameter("width", rl / 10.0)
			(source.draw_pass_1.surface_get_material(0) as ShaderMaterial).set_shader_parameter("len", rl)
			(source.draw_pass_1.surface_get_material(0) as ShaderMaterial).set_shader_parameter("radius", rl / 2)
			(source.draw_pass_1.surface_get_material(0) as ShaderMaterial).set_shader_parameter("period", rl / 4)
			#source.local_coords = spell.follow
			source.amount = roundi(160 * rl)
			
		Spell.Element.ICE:
			((get_node("shape_cast") as ShapeCast3D).shape as BoxShape3D).size.x = rl * 2
			((get_node("shape_cast") as ShapeCast3D).shape as BoxShape3D).size.z = rl * 2
			
			var source: GPUParticles3D = get_node("source")
			(source.process_material as ParticleProcessMaterial).emission_box_extents = Vector3(rl, 0.2, rl)
			source.amount = roundi(100 * rl)
			#source.local_coords = spell.follow
			
		Spell.Element.ELECTRIC:
			((get_node("shape_cast") as ShapeCast3D).shape as SphereShape3D).radius = rl
			
			var source: GPUParticles3D = get_node("source")
			(source.process_material as ParticleProcessMaterial).emission_sphere_radius = rl
			source.amount = roundi(80 * rl)
			var mat: ShaderMaterial = source.draw_pass_1.surface_get_material(0)
			mat.set_shader_parameter("len", rl * 5)
			var body := get_node("body") as MeshInstance3D
			(body.mesh as SphereMesh).radius = rl
			(body.mesh as SphereMesh).height = rl * 2
			#source.local_coords = spell.follow
			
		Spell.Element.VOID:
			var mesh: SphereMesh = (get_node("mesh") as MeshInstance3D).mesh
			mesh.radius = rl
			mesh.height = rl * 2
			((get_node("shape_cast") as ShapeCast3D).shape as SphereShape3D).radius = rl
#			mesh.surface_get_material(0).albedo_color = Color8(0, 0, 0, mini(int(255 * (spell.power / 100.0)), 255))
			

func update_movement(p: Vector3, instance: bool, vars: Dictionary) -> void:
	var next_pos : Vector3 = p - (vars["~rel_pos"] if spell.follow else vars["~abs_pos"])
	var velocity_maintained_distance := velocity
	if started:
		var fr := vars.get("~~frame_time", 0.0166667) as float
		old_velocity = velocity
		velocity_maintained_distance = (next_pos - old_pos) / fr
		velocity = ((next_pos - old_pos) * fr).normalized()
		
		var M := PI / 2
		# parabola with max y at x=PI/2 falling off with x=0 and x=PI (y in [0,1])
		var complexity_angle := -pow(velocity.angle_to(old_velocity) - M, 2.0) / (M * M) + 1 
		if is_nan(complexity_angle) or is_inf(complexity_angle):
			complexity_angle = 0.0
		if origin_spell_caster != null:
			origin_spell_caster.update_complexity(complexity_id, complexity_angle)
			
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
			if (obj as Area3D).collision_layer & 0b0100_0000_0000 != 0:
				var parent := (obj as Area3D).get_parent() as Node3D
				if parent != null and parent is TargetShape:
					((obj as Area3D).get_parent() as TargetShape)._on_area_3d_area_entered(self, caster_vitals, obj as Area3D, [point])
			else:
				_on_area_entered(obj as Area3D, [point])
		elif obj is CollisionObject3D:
			_on_body_entered(obj as CollisionObject3D, [point])
	
	match spell.element:
		Spell.Element.FIRE:
			position = p
			var particles: GPUParticles3D = get_node("source")
			(particles.process_material as ParticleProcessMaterial).direction = (velocity + Vector3.UP * 0.15).normalized()
			(particles.process_material as ParticleProcessMaterial).initial_velocity_min = velocity_maintained_distance.length() * 0.99
			(particles.process_material as ParticleProcessMaterial).initial_velocity_max = velocity_maintained_distance.length() * 1.01
		
		Spell.Element.ROCK:
			position = p
			var rot_axis := Vector3.UP.cross(velocity).normalized()
			var rot_ang := Vector3.UP.angle_to(velocity)
			if rot_axis:
				rotate(rot_axis, rot_ang * vars.get("~~frame_time", 0.0166667) as float)
			
				
		Spell.Element.WATER:
			position = p
			var particles: GPUParticles3D = get_node("source")
			(particles.process_material as ParticleProcessMaterial).direction = (velocity + Vector3.DOWN * 0.15).normalized()
			(particles.process_material as ParticleProcessMaterial).initial_velocity_min = velocity_maintained_distance.length() * 0.99
			(particles.process_material as ParticleProcessMaterial).initial_velocity_max = velocity_maintained_distance.length() * 1.01
			
		Spell.Element.AIR:
			position = p
			var source: GPUParticles3D = get_node("source")
			(source.process_material as ParticleProcessMaterial).initial_velocity_min = velocity_maintained_distance.length() * 0.99
			(source.process_material as ParticleProcessMaterial).initial_velocity_max = velocity_maintained_distance.length() * 1.01
			
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
			(particles.process_material as ParticleProcessMaterial).initial_velocity_min = velocity_maintained_distance.length() * 0.99
			(particles.process_material as ParticleProcessMaterial).initial_velocity_max = velocity_maintained_distance.length() * 1.01
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
			
func update_spell(t: float, delta: float, vars: Dictionary) -> MagicBook.DisallowSpellReason:
	if not is_active():
		return MagicBook.DisallowSpellReason.NONE
	t = t - pause_time
	fixed_vars["t"] = clampf(t - time_start, 0.0, 100000.0)
	vars["~~frame_time"] = delta
	spell.compute_expressions(vars, expression_vars, override_vars, true)
	var exceeds := Globals.Ref.new(false)
	var p := spell.calculate_location(vars, false, exceeds)
	update_movement(p, false, vars)
	return MagicBook.DisallowSpellReason.VELOCITY if exceeds.data else MagicBook.DisallowSpellReason.NONE

func stop_emitting() -> void:
	const AUDIO_FADE_OUT = 0.7
	is_emitting = false
	match spell.element:
		Spell.Element.FIRE:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			(get_node("shape_cast") as ShapeCast3D).enabled = false
			fade_audio(-40, AUDIO_FADE_OUT, false)
			free_after(maxf(Globals.particle_system_lifetime(particles), AUDIO_FADE_OUT))
			
		Spell.Element.ROCK:
			var body: RigidBody3D = get_node("body")
			body.visible = false
			body.collision_mask = 0
			(get_node("shape_cast") as ShapeCast3D).enabled = false
			fade_audio(-40, AUDIO_FADE_OUT, false)
			free_after(max(0.1, AUDIO_FADE_OUT))
			
		Spell.Element.WATER:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			(get_node("shape_cast") as ShapeCast3D).enabled = false
			fade_audio(-40, AUDIO_FADE_OUT, false)
			free_after(maxf(Globals.particle_system_lifetime(particles), AUDIO_FADE_OUT))
			
		Spell.Element.AIR:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			(get_node("shape_cast") as ShapeCast3D).enabled = false
			fade_audio(-40, AUDIO_FADE_OUT, false)
			free_after(maxf(Globals.particle_system_lifetime(particles), AUDIO_FADE_OUT))
			
		Spell.Element.ICE:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			(get_node("shape_cast") as ShapeCast3D).enabled = false
			fade_audio(-40, AUDIO_FADE_OUT, false)
			free_after(maxf(Globals.particle_system_lifetime(particles), AUDIO_FADE_OUT))
			
		Spell.Element.ELECTRIC:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			(get_node("shape_cast") as ShapeCast3D).enabled = false
			var body := get_node("body") as MeshInstance3D
			body.visible = false
			fade_audio(-40, AUDIO_FADE_OUT, false)
			free_after(maxf(Globals.particle_system_lifetime(particles), AUDIO_FADE_OUT))
			
		Spell.Element.VOID:
			#fade_audio(-40, AUDIO_FADE_OUT, false)
			free_after(maxf(0.1, AUDIO_FADE_OUT + 0.1))
			
func free_after(duration: float) -> void:
	free_when_ready = duration
		
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
	if spell_caster != null:
		spell_caster.free_particles()
	queue_free()

func calculate_overall_complexity() -> float:
	if origin_spell_caster != null:
		return origin_spell_caster.get_complexity(complexity_id)
	else:
		return 0.0
