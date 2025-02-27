class_name SpellBody
extends Node3D

var spell: Spell
var sub_spell: Spell
var skip_update_shape_check: bool
var n: int
var time_stamp: float
var update_tick: float
var expired: bool
var is_emitting: bool
var started: bool
var in_control: bool
var is_off: bool
var free_when_ready: float
var velocity: Vector3
var old_velocity: Vector3
var lifetime_velocity: float
var old_pos: Vector3
var most_recent_radius: Vector3
var rotation_angle: float
var rng: RandomNumberGenerator

var complexity_id: int

var caster_vitals: Vitals
var spell_caster: SpellCaster
var on_hit_casts: Dictionary

var fixed_vars: Vars
var expression_vars: Vars

var to_remove: bool
var origin_node: Node3D
var tracking_target: Node3D
var tracking_position: Vector3
var tracking_offset: Vector3
var origin_spell_caster: SpellCaster

const INVUNERABLE_DURATION: float = 0.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rng = RandomNumberGenerator.new()
		
func setup() -> void:
	update_tick = 0.0
	expired = false
	is_emitting = true
	started = false
	in_control = true
	is_off = true
	free_when_ready = NAN
	velocity = Vector3.ZERO
	old_velocity = Vector3.ZERO
	old_pos = Vector3.ZERO
	rotation_angle = NAN
	on_hit_casts = {}
	sub_spell = null
	skip_update_shape_check = false

	to_remove = false
	
	update_sub_entities(false)
	spell_caster = SpellCaster.new(origin_node, SpellCaster.Entity.PROJECTILE)
	if spell.chain_cast_kind == Spell.ChainCastKind.START and spell.chain != null:
		cast_spell(insert_spell, spell.chain)
	rng.seed = hash(spell.name)
	if origin_node is Player:
		origin_spell_caster = (origin_node as Player).spell_caster
	elif origin_node is Enemy:
		origin_spell_caster = (origin_node as Enemy).spell_caster
	else:
		origin_spell_caster = null
		
		
	start_emitting()

func _physics_process(delta: float) -> void:
	if not is_nan(free_when_ready):
		free_when_ready -= delta
		if free_when_ready <= 0.0:
			if not spell_caster.particles.is_empty():
				free_when_ready = max(free_when_ready, 2)
			else:
				SpellBuffer.free_projectile(self)

func has_expired() -> bool:
	if time_stamp < 0:
		return false
	return expired or time_stamp > spell.duration
	
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
		Vitals.build_explosion(get_parent() as Node3D, p, amount, spell.element, p.position, most_recent_radius.length(), velocity, is_alternate, null)
	)
	
func is_active() -> bool:
	return in_control and time_stamp >= 0 
	
func lose_control(p: Node3D, q: CollisionObject3D, damage: Dictionary) -> void:
	in_control = false
	if spell.element == Spell.Element.ROCK:
		var body: RigidBody3D = p.get_node("body")
		if body.freeze:
			body.freeze = false
			body.apply_central_impulse(velocity)
			if q != null:
				SignalBus.projectile_hit.emit(origin_node, q, spell, Time.get_unix_time_from_system(), p, damage)
		var timer := get_tree().create_timer(spell.duration - time_stamp)
		timer.timeout.connect(func() -> void:
			expired = true
		)

func nothing(p: Node3D, q: CollisionObject3D, damage: Dictionary) -> void:
	if q != null:
		SignalBus.projectile_hit.emit(origin_node, q, spell, Time.get_unix_time_from_system(), p, damage)
	
func actual_duration() -> float:
	var result := spell.duration - time_stamp
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
			return velocity * (amp + clampf(spell.elemental_application, 0.0, 1.0) * 50)
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
	return get_shape_cast().shape

func get_spell_transform() -> Transform3D:
	if spell.element == Spell.Element.ROCK:
		return (get_node("body") as Node3D).global_transform
	elif spell.element == Spell.Element.AIR:
		return (get_node("source") as Node3D).global_transform
	else:
		return global_transform
		
func get_spell_collision_mask() -> int:
	return get_shape_cast().collision_mask

func get_shape_cast() -> ShapeCast3D:
	match spell.element:
		Spell.Element.FIRE: return get_node("shape_cast") as ShapeCast3D
		Spell.Element.WATER: return get_node("shape_cast") as ShapeCast3D
		Spell.Element.AIR: return get_node("shape_cast") as ShapeCast3D
		Spell.Element.ICE: return get_node("shape_cast") as ShapeCast3D
		Spell.Element.ELECTRIC: return get_node("shape_cast") as ShapeCast3D
		Spell.Element.ROCK: return get_node("shape_cast") as ShapeCast3D
		Spell.Element.VOID: return get_node("shape_cast") as ShapeCast3D
	return null
	
func get_area_node() -> Area3D:
	match spell.element:
		Spell.Element.FIRE: return get_node("area") as Area3D
		Spell.Element.WATER: return get_node("area") as Area3D
		Spell.Element.AIR: return get_node("area") as Area3D
		Spell.Element.ICE: return get_node("area") as Area3D
		Spell.Element.ELECTRIC: return get_node("area") as Area3D
		Spell.Element.ROCK: return null
		Spell.Element.VOID: return get_node("area") as Area3D
	return null
	
func get_area_collision() -> CollisionShape3D:
	match spell.element:
		Spell.Element.FIRE: return get_node("area/collision") as CollisionShape3D
		Spell.Element.WATER: return get_node("area/collision") as CollisionShape3D
		Spell.Element.AIR: return get_node("area/collision") as CollisionShape3D
		Spell.Element.ICE: return get_node("area/collision") as CollisionShape3D
		Spell.Element.ELECTRIC: return get_node("area/collision") as CollisionShape3D
		Spell.Element.ROCK: return null
		Spell.Element.VOID: return get_node("area/collision") as CollisionShape3D
	return null

func _on_body_entered(_body: CollisionObject3D, contact_points: Array[Vector3]) -> void:
	var is_world  : int = _body.collision_layer & Globals.Layer.WORLD != 0
	var is_player : int = _body.collision_layer & Globals.Layer.PLAYER != 0
	var is_enemy  : int = _body.collision_layer & Globals.Layer.ENEMY != 0
	
	if is_enemy and (origin_node is Enemy or origin_node is TargetShape):
		return
		
	var is_world_object : int = _body.collision_layer & Globals.Layer.OBJECT != 0
	var is_fire    : int = _body.collision_layer & Globals.Layer.FIRE != 0
	var is_rock    : int = _body.collision_layer & Globals.Layer.ROCK != 0
	#var is_water   : int = _body.collision_layer & Globals.Layer.WATER != 0
	var is_ice     : int = _body.collision_layer & Globals.Layer.ICE != 0
	#var is_electric: int = _body.collision_layer & Globals.Layer.ELECTRIC != 0
	var dmg := {"el": spell.element, "dmg": spell.power} # set default for contact with non player/enemy
	var sub_dmg := {}
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
					if not (is_player and origin_node is Player):
						lose_control(self, body, dmg)
		Spell.Element.WATER:
			if is_world or is_rock or is_world_object or is_ice:
				expire_now(self, _body, dmg)
			elif (is_enemy or is_player) and not invunerable:
				var body := _body as CharacterBody
				body.add_impulse(impulse())
				dmg = body.vitals.handle_damage(Spell.Element.WATER, spell.damage(caster_vitals), spell.elemental_application)
				if sub_spell != null:
					sub_dmg = body.vitals.handle_damage(Spell.Element.ELECTRIC, 0.0, sub_spell.elemental_application)
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
				if sub_spell != null:
					sub_dmg = body.vitals.handle_damage(Spell.Element.ELECTRIC, sub_spell.damage(caster_vitals), 0.0)
				nothing(self, body, dmg)
		Spell.Element.ELECTRIC:
			if is_world or is_rock or is_world_object:
				pass
			elif is_fire:
				update_shape(Vector3(1, 1, 1).normalized() * most_recent_radius.length() * 2, true)
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
			cast_spell(insert_spell, spell.chain)
		if spell.element != Spell.Element.VOID:
			if is_player:
				var body := _body as Player
				Vitals.apply_damage(get_parent() as Node3D, _body, dmg["dmg"] as float, dmg["el"] as Spell.Element, is_player or is_enemy, true, contact_points, most_recent_radius.length(), velocity, body.vitals)
				body.add_shake(clampf(dmg["dmg"] as float / 100.0, 0.0, 1.0))
				UIAudioPlayer.hurt()
				if sub_dmg != {}:
					Vitals.apply_damage(get_parent() as Node3D, _body, sub_dmg["dmg"] as float, sub_dmg["el"] as Spell.Element, is_player or is_enemy, true, contact_points, most_recent_radius.length(), velocity, body.vitals)
					body.add_shake(clampf(sub_dmg["dmg"] as float / 100.0, 0.0, 1.0))
				body.invunerable = INVUNERABLE_DURATION
				if dmg["dmg"] > 0:
					body.play_animation("on_hit")
				body.update_artifact_effects(Artifact.Event.RECEIVE, spell)
				body.emit_vitals_update()
			elif is_enemy:
				var body := _body as Enemy
				Vitals.apply_damage(get_parent() as Node3D, _body, dmg["dmg"] as float, dmg["el"] as Spell.Element, is_player or is_enemy, true, contact_points, most_recent_radius.length(), velocity, body.vitals)
				body.add_shake(clampf(dmg["dmg"] as float / 100.0, 0.0, 1.0))
				AudioManager.play(body.sfx_hurt, body.position, NAN, true, Vector2(0.8, 1.2))
				if sub_dmg != {}:
					Vitals.apply_damage(get_parent() as Node3D, _body, sub_dmg["dmg"] as float, sub_dmg["el"] as Spell.Element, is_player or is_enemy, true, contact_points, most_recent_radius.length(), velocity, body.vitals)
					body.add_shake(clampf(sub_dmg["dmg"] as float / 100.0, 0.0, 1.0))
				if body.vitals.health.value <= body.vitals.health.min_value:
					body.vital_update.emit(body.index_in_population, body.vitals)
					body.die()
				else:
					body.invunerable = INVUNERABLE_DURATION
					if dmg["dmg"] > 0:
						body.play_animation("on_hit")
						body.animation_tree.active = false
			else:
				Vitals.apply_damage(get_parent() as Node3D, _body, dmg["dmg"] as float, dmg["el"] as Spell.Element, is_player or is_enemy, true, contact_points, most_recent_radius.length(), velocity, null)
				if sub_dmg != {}:
					Vitals.apply_damage(get_parent() as Node3D, _body, sub_dmg["dmg"] as float, sub_dmg["el"] as Spell.Element, is_player or is_enemy, true, contact_points, most_recent_radius.length(), velocity, null)
				

func _on_area_entered(area: Area3D, contact_points: Array[Vector3]) -> void:
	var _body := area.get_parent_node_3d() as Node3D
	var is_world  : int = area.collision_layer & Globals.Layer.WORLD != 0
	var is_player : int = area.collision_layer & Globals.Layer.PLAYER != 0
	var is_enemy  : int = area.collision_layer & Globals.Layer.ENEMY != 0
	
	if is_enemy and origin_node is Enemy:
		return
	
	var is_world_object := area.collision_layer & (1 << 9) != 0
	var is_fire  : int = area.collision_layer   & Globals.Layer.FIRE != 0
	var is_rock  : int = area.collision_layer   & Globals.Layer.ROCK != 0
	var is_water : int = area.collision_layer   & Globals.Layer.WATER != 0
	var is_ice   : int = area.collision_layer   & Globals.Layer.ICE != 0
	var is_electric: int = area.collision_layer & Globals.Layer.ELECTRIC != 0
	var dmg := {}
	var invunerable: bool = (is_player or is_enemy) and (_body as CharacterBody).invunerable > 0.0
	match spell.element:
		Spell.Element.FIRE:
			if not (is_enemy or is_player):
				if is_water:
					expire_now(self, null, dmg)
				elif is_electric:
					update_shape(Vector3(1, 1, 1).normalized() * most_recent_radius.length() * 3, true)
					explode_after(self, null, 0.0166667 * 2, false, dmg)
		Spell.Element.WATER:
			if not (is_enemy or is_player):
				if is_ice:
					expire_now(self, null, dmg)
				elif is_fire:
					explode_after(self, null, 0.0166667 * 2, true, dmg)
				elif is_electric:
					if _body is SpellBody:
						var body := _body as SpellBody
						sub_spell = body.spell
						skip_update_shape_check = true
						update_shape(most_recent_radius, true)
		Spell.Element.ICE:
			if not (is_enemy or is_player):
				if is_water:
					spell.elemental_application = clampf(spell.elemental_application * 1.1, 0.0, 1.0)
				elif is_electric:
					if _body is SpellBody:
						var body := _body as SpellBody
						sub_spell = body.spell
						skip_update_shape_check = true
						update_shape(most_recent_radius, true)
		Spell.Element.ELECTRIC:
			if not (is_enemy or is_player):
				if is_world or is_rock or is_world_object:
					# Look at `_on_body_entered` for implementation
					pass
				elif is_fire:
					update_shape(Vector3(1, 1, 1).normalized() * most_recent_radius.length() * 3, true)
					explode_after(self, null, 0.0166667 * 2, false, dmg)
			elif is_water and not invunerable:
				var body := area.get_parent_node_3d() as CharacterBody
				body.add_impulse(impulse())
				dmg = body.vitals.handle_damage(Spell.Element.ELECTRIC, spell.damage(caster_vitals), spell.elemental_application)
				nothing(self, body, dmg)
		Spell.Element.VOID:
			if not (is_player or is_enemy):
				if is_world or is_rock or is_world_object:
					nothing(self, null, dmg)
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
			cast_spell(insert_spell, spell.chain)
		Vitals.apply_damage(get_parent() as Node3D, _body, dmg["dmg"] as float, dmg["el"] as Spell.Element, is_player or is_enemy, true, contact_points, most_recent_radius.length(), velocity)
		if is_player and spell.element != Spell.Element.VOID:
			var body := area.get_parent_node_3d() as Player
			body.add_shake(clampf(dmg["dmg"] as float / 100.0, 0.0, 1.0))
			UIAudioPlayer.hurt()
			body.invunerable = INVUNERABLE_DURATION
			if dmg["dmg"] > 0:
				body.play_animation("on_hit")
			body.update_artifact_effects(Artifact.Event.RECEIVE, spell)
			body.emit_vitals_update()
		if is_enemy and spell.element != Spell.Element.VOID:
			var body := area.get_parent_node_3d() as Enemy
			body.add_shake(clampf(dmg["dmg"] as float / 100.0, 0.0, 1.0))
			AudioManager.play(body.sfx_hurt, body.position, NAN, true, Vector2(0.8, 1.2))
			if body.vitals.health.value <= body.vitals.health.min_value:
				body.vital_update.emit(body.index_in_population, body.vitals)
				body.die()
			else:
				body.invunerable = INVUNERABLE_DURATION
				if dmg["dmg"] > 0:
					body.play_animation("on_hit")

func update_shape(r: Vector3, ignore_time: bool) -> void:
	if r == most_recent_radius and not skip_update_shape_check:
		return
	skip_update_shape_check = false
	most_recent_radius = r
	var rl := r.length()
	
	match spell.element:
		Spell.Element.FIRE:
			var particles: GPUParticles3D = get_node("source")
			(particles.process_material as ParticleProcessMaterial).emission_sphere_radius = rl
			(particles.process_material as ParticleProcessMaterial).scale_min = rl * 2
			(particles.process_material as ParticleProcessMaterial).scale_max = rl * 2
			particles.amount = roundi(80 * rl)
			var trail: GPUParticles3D = get_node("source_trail")
			(trail.process_material as ParticleProcessMaterial).emission_sphere_radius = rl
			(trail.process_material as ParticleProcessMaterial).scale_min = rl * 2
			(trail.process_material as ParticleProcessMaterial).scale_max = rl * 2
			trail.amount = roundi(80 * rl)
			
			(get_shape_cast().shape as SphereShape3D).radius = rl
			(get_area_collision().shape as SphereShape3D).radius = rl
			
			#particles.local_coords = spell.follow
			
		Spell.Element.ROCK:
			if not ignore_time:
#				var R = get_node("body/shape").shape.size.x
#				scale = Vector3(r / R, r / R, r / R)
				return
			var p_shape: CollisionShape3D = get_node("body/shape")
			
			(p_shape.shape as BoxShape3D).size = r * 2
			(get_shape_cast().shape as BoxShape3D).size = r * 2
			var mesh: MeshInstance3D = get_node("body/mesh")
			(mesh.mesh as BoxMesh).size = r * 2
			
			var body: RigidBody3D = get_node("body")
			body.mass = (r.x + r.y + r.z) / 3.0 * 2.0
			scale = Vector3(1, 1, 1)
			
		Spell.Element.WATER:
			(get_shape_cast().shape as SphereShape3D).radius = rl
			(get_area_collision().shape as SphereShape3D).radius = rl
			var particles: GPUParticles3D = get_node("source")
			(particles.process_material as ParticleProcessMaterial).emission_sphere_radius = rl
			(particles.process_material as ParticleProcessMaterial).scale_max = rl * 3
			(particles.process_material as ParticleProcessMaterial).scale_min = rl * 2.0 / 3.0
			particles.amount = ceili(80 * rl)
			var trail: GPUParticles3D = get_node("source_trail")
			(trail.process_material as ParticleProcessMaterial).emission_sphere_radius = rl
			(trail.process_material as ParticleProcessMaterial).scale_max = rl * 3
			(trail.process_material as ParticleProcessMaterial).scale_min = rl * 2.0 / 3.0
			trail.amount = ceili(80 * rl)
			
			if sub_spell != null and sub_spell.element == Spell.Element.ELECTRIC:
				var electric_trail: GPUParticles3D = get_node("electric_trail")
				(electric_trail.process_material as ParticleProcessMaterial).emission_sphere_radius = rl
				electric_trail.amount = ceili(80 * rl)
				electric_trail.emitting = true
				var mat: ShaderMaterial = electric_trail.draw_pass_1.surface_get_material(0)
				mat.set_shader_parameter("len", rl * 5)
			else:
				var electric_trail: GPUParticles3D = get_node("electric_trail")
				electric_trail.emitting = false
			
		Spell.Element.AIR:
			(get_shape_cast().shape as CylinderShape3D).height = rl * 4
			(get_shape_cast().shape as CylinderShape3D).radius = rl
			(get_area_collision().shape as CylinderShape3D).height = rl * 4
			(get_area_collision().shape as CylinderShape3D).radius = rl
			
			var source: GPUParticles3D = get_node("source")
			(source.process_material as ParticleProcessMaterial).emission_ring_height = rl * 4
			(source.process_material as ParticleProcessMaterial).emission_ring_radius = rl
			(source.draw_pass_1.surface_get_material(0) as ShaderMaterial).set_shader_parameter("width", lerpf(0.01, 0.1, rl))
			source.amount = ceili(100 * rl)
			var trail: GPUParticles3D = get_node("source_trail")
			(trail.process_material as ParticleProcessMaterial).emission_ring_height = rl * 4
			(trail.process_material as ParticleProcessMaterial).emission_ring_radius = rl
			(trail.draw_pass_1.surface_get_material(0) as ShaderMaterial).set_shader_parameter("width", lerpf(0.01, 0.1, rl))
			trail.amount = ceili(100 * rl)
			
		Spell.Element.ICE:
			(get_shape_cast().shape as BoxShape3D).size = r * 2
			(get_area_collision().shape as BoxShape3D).size = r * 2
			
			var source: GPUParticles3D = get_node("source")
			(source.process_material as ParticleProcessMaterial).emission_box_extents = r
			(source.process_material as ParticleProcessMaterial).scale_max = rl
			(source.process_material as ParticleProcessMaterial).scale_min = rl / 3.0
			source.amount = ceili(100 * rl)
			var trail: GPUParticles3D = get_node("source_trail")
			(trail.process_material as ParticleProcessMaterial).emission_box_extents = r
			(trail.process_material as ParticleProcessMaterial).scale_max = rl
			(trail.process_material as ParticleProcessMaterial).scale_min = rl / 3.0
			trail.amount = ceili(100 * rl)
			
			if sub_spell != null and sub_spell.element == Spell.Element.ELECTRIC:
				var electric_trail: GPUParticles3D = get_node("electric_trail")
				(electric_trail.process_material as ParticleProcessMaterial).emission_box_extents = r
				electric_trail.amount = ceili(80 * rl)
				electric_trail.emitting = true
				var mat: ShaderMaterial = electric_trail.draw_pass_1.surface_get_material(0)
				mat.set_shader_parameter("len", rl * 5)
			else:
				var electric_trail: GPUParticles3D = get_node("electric_trail")
				electric_trail.emitting = false
			
		Spell.Element.ELECTRIC:
			(get_shape_cast().shape as SphereShape3D).radius = rl
			(get_area_collision().shape as SphereShape3D).radius = rl
			
			var source: GPUParticles3D = get_node("source")
			(source.process_material as ParticleProcessMaterial).emission_sphere_radius = rl
			source.amount = ceili(80 * rl)
			var mat: ShaderMaterial = source.draw_pass_1.surface_get_material(0)
			mat.set_shader_parameter("len", rl * 5)
			var body := get_node("body") as MeshInstance3D
			(body.mesh as SphereMesh).radius = rl
			(body.mesh as SphereMesh).height = rl * 2
			
		Spell.Element.VOID:
			var mesh: SphereMesh = (get_node("mesh") as MeshInstance3D).mesh
			mesh.radius = rl
			mesh.height = rl * 2
			(get_shape_cast().shape as SphereShape3D).radius = rl
			var color := Color(0, 0, 0, spell.power / UpgradeSettings.LIMIT_P)
			(mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("albedo", color)
			

func update_movement(p: Vector3, instance: bool, vars: Vars) -> void:
	var next_pos : Vector3 = p - (vars.get_vector(Vars.rel_pos) if spell.follow else vars.get_vector(Vars.abs_pos))
	var velocity_maintained_distance := velocity
	if started:
		var fr := vars.get_value(Vars.frame_time)
		old_velocity = velocity
		velocity_maintained_distance = (next_pos - old_pos) / fr
		if spell.element == Spell.Element.ROCK:
			var rigid_body := get_node("body") as RigidBody3D
			rigid_body.linear_velocity = velocity_maintained_distance
		
		velocity = ((next_pos - old_pos) * fr).normalized()
		
		var M := PI / 2
		# parabola with max y at x=PI/2 falling off with x=0 and x=PI (y in [0,1])
		var complexity_angle := -pow(velocity.angle_to(old_velocity) - M, 2.0) / (M * M) + 1 
		if is_nan(complexity_angle) or is_inf(complexity_angle):
			complexity_angle = 0.0
		if origin_spell_caster != null:
			origin_spell_caster.update_complexity(complexity_id, complexity_angle)
			
	old_pos = next_pos
	var count: int = 0
	var shape_cast := get_shape_cast()
	if started:
		var target := position - p
		if target.length() > 1 or target.distance_squared_to(shape_cast.target_position) > 1.0:
			if spell.element == Spell.Element.ROCK:
				shape_cast.target_position = position - p
			else:
				shape_cast.target_position = Vector3.BACK * (position - p).length()
		elif shape_cast.target_position != Vector3.ZERO:
			shape_cast.target_position = Vector3.ZERO
		count = shape_cast.get_collision_count()
		
	started = true
	for i in range(count):
		var obj := shape_cast.get_collider(i)
		var point := shape_cast.get_collision_point(i)
		if spell.element == Spell.Element.ROCK and (obj == get_node("body")):
			continue
		if obj is Area3D:
			if (obj as Area3D).collision_layer & Globals.Layer.ITEM != 0:
				var parent := (obj as Area3D).get_parent() as Node3D
				if parent != null and parent is TargetShape:
					(parent as TargetShape)._on_area_3d_area_entered(self, caster_vitals, obj as Area3D, [point])
			else:
				_on_area_entered(obj as Area3D, [point])
		elif obj is CollisionObject3D:
			_on_body_entered(obj as CollisionObject3D, [point])
	
	match spell.element:
		Spell.Element.FIRE:
			position = p
			Globals.look_at(self, velocity)
		
		Spell.Element.ROCK:
			position = p
			var rot_axis := Vector3.UP.cross(velocity).normalized()
			var rot_ang := Vector3.UP.angle_to(velocity) if is_nan(rotation_angle) else rotation_angle
			if rot_axis and rot_ang:
				rotate(rot_axis, rot_ang * vars.get_value(Vars.frame_time))
				
		Spell.Element.WATER:
			position = p
			Globals.look_at(self, velocity)
			var biome := World.Biome.WATER
			var world_radius := 10000.0
			var difficulty_curve := 2
			var player: Player
			if origin_node is Player:
				player = (origin_node as Player)
				biome = player.velocity_movement.current_biome
				world_radius = player.world_settings.world_radius
				difficulty_curve = player.world_settings.difficulty_level
				if player != null:
					var lvl := Population.level_relative_to_position_within_radius(null, p.x, p.z, world_radius, difficulty_curve)
					if biome == World.Biome.DESERT or biome == World.Biome.HFIL:
						if time_stamp > lerpf(0.0, UpgradeSettings.LIMIT_T * (1 - spell.elemental_application), fmod(lvl, 101.0) / 100.0):
							explode_after(self, null, 0.0166667 * 2, true, {})
			elif origin_node is Enemy:
				player = (origin_node as Enemy).player
				biome = (origin_node as Enemy).velocity_movement.current_biome
				world_radius = player.world_settings.world_radius
				difficulty_curve = player.world_settings.difficulty_level
			
		Spell.Element.AIR:
			position = p
			Globals.look_at(self, velocity)
			
		Spell.Element.ICE:
			position = p
			Globals.look_at(self, velocity)
			
		Spell.Element.ELECTRIC:
			position = p
			Globals.look_at(self, velocity)
			
		Spell.Element.VOID:
			position = p
			Globals.look_at(self, velocity)
			
func prepare_update_spell(delta: float) -> void:
	if not is_active():
		return
	time_stamp += delta
	
func update_sub_entities(turn_off: bool) -> void:
	if is_off == turn_off:
		return
	is_off = turn_off
	match spell.element:
		Spell.Element.FIRE, Spell.Element.ELECTRIC:
			var tween := create_tween()
			var light: OmniLight3D = get_node("light")
			var fade_light := func(t: float) -> void:
				if turn_off:
					light.omni_range = lerpf(5.0, 0.0, t)
				else:
					light.omni_range = lerpf(0.0, 5.0, t)
			tween.tween_method(fade_light, 0, 1, 0.2)
			if turn_off:
				tween.finished.connect(func() -> void:
					light.visible = false
				)
			else:
				light.visible = true
				tween.finished.connect(func() -> void:
					light.visible = true
				)
			tween.play()
			
func update_spell(delta: float, vars: Vars) -> MagicBook.DisallowSpellReason:
	if not is_active():
		return MagicBook.DisallowSpellReason.NONE
	time_stamp += delta
	fixed_vars.set_value(Vars.t, time_stamp)
	vars.set_value(Vars.frame_time, delta)
	spell.compute_expressions(vars, expression_vars, true)
	var exceeds := Globals.Ref.new(false)
	var p := spell.calculate_location(vars, false, exceeds)
	update_movement(p, false, vars)
	return MagicBook.DisallowSpellReason.VELOCITY if exceeds.data else MagicBook.DisallowSpellReason.NONE

func start_emitting() -> void:
	match spell.element:
		Spell.Element.FIRE:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = true
			var trail: GPUParticles3D = get_node("source_trail")
			trail.emitting = true
			var light: OmniLight3D = get_node("light")
			light.omni_range = 5.0
			get_shape_cast().enabled = true
			get_area_collision().disabled = false
			
		Spell.Element.ROCK:
			var body: RigidBody3D = get_node("body")
			body.visible = true
			body.collision_mask = 0b11_1111_1111
			get_shape_cast().enabled = true
			(get_node("body/shape") as CollisionShape3D).disabled = false
			
		Spell.Element.WATER:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = true
			var trail: GPUParticles3D = get_node("source_trail")
			trail.emitting = true
			get_shape_cast().enabled = true
			get_area_collision().disabled = false
			
		Spell.Element.AIR:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = true
			var trail: GPUParticles3D = get_node("source_trail")
			trail.emitting = true
			get_shape_cast().enabled = true
			get_area_collision().disabled = false
			
		Spell.Element.ICE:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = true
			var trail: GPUParticles3D = get_node("source_trail")
			trail.emitting = true
			get_shape_cast().enabled = true
			get_area_collision().disabled = false
			
		Spell.Element.ELECTRIC:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = true
			var light: OmniLight3D = get_node("light")
			light.omni_range = 5.0
			get_shape_cast().enabled = true
			get_area_collision().disabled = false
			var body := get_node("body") as MeshInstance3D
			body.visible = true
			
		Spell.Element.VOID:
			get_area_collision().disabled = false

func stop_emitting() -> void:
	is_emitting = false
	match spell.element:
		Spell.Element.FIRE:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			var trail: GPUParticles3D = get_node("source_trail")
			trail.emitting = false
			var tween := create_tween().set_parallel(false)
			var light: OmniLight3D = get_node("light")
			var particle_wait_time := Globals.particle_system_lifetime(particles)
			var fade_light := func(t: float) -> void:
				light.omni_range = lerpf(5.0, 0.0, t)
			tween.tween_interval(particle_wait_time * 0.5)
			tween.tween_method(fade_light, 0, 1, 0.2)
			tween.play()
			get_shape_cast().enabled = false
			get_area_collision().disabled = true
			free_after(particle_wait_time)
			
		Spell.Element.ROCK:
			var particles: GPUParticles3D = get_node("source")
			(particles.process_material as ParticleProcessMaterial).scale_min = most_recent_radius.length() * 0.125
			(particles.process_material as ParticleProcessMaterial).scale_max = most_recent_radius.length() * 0.25
			(particles.process_material as ParticleProcessMaterial).emission_box_extents = most_recent_radius
			particles.emitting = true
			var body: RigidBody3D = get_node("body")
			body.visible = false
			body.collision_mask = 0
			get_shape_cast().enabled = false
			(get_node("body/shape") as CollisionShape3D).disabled = true
			free_after(Globals.particle_system_lifetime(particles))
			
		Spell.Element.WATER:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			var trail: GPUParticles3D = get_node("source_trail")
			trail.emitting = false
			var electric_trail: GPUParticles3D = get_node("electric_trail")
			electric_trail.emitting = false
			get_shape_cast().enabled = false
			get_area_collision().disabled = true
			free_after(Globals.particle_system_lifetime(particles))
			
		Spell.Element.AIR:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			var trail: GPUParticles3D = get_node("source_trail")
			trail.emitting = false
			get_shape_cast().enabled = false
			get_area_collision().disabled = true
			free_after(Globals.particle_system_lifetime(particles))
			
		Spell.Element.ICE:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			var trail: GPUParticles3D = get_node("source_trail")
			trail.emitting = false
			var electric_trail: GPUParticles3D = get_node("electric_trail")
			electric_trail.emitting = false
			get_shape_cast().enabled = false
			get_area_collision().disabled = true
			free_after(Globals.particle_system_lifetime(particles))
			
		Spell.Element.ELECTRIC:
			var particles: GPUParticles3D = get_node("source")
			particles.emitting = false
			var tween := create_tween().set_parallel(false)
			var light: OmniLight3D = get_node("light")
			var particle_wait_time := Globals.particle_system_lifetime(particles)
			var fade_light := func(t: float) -> void:
				light.omni_range = lerpf(5.0, 0.0, t)
			tween.tween_interval(particle_wait_time * 0.5)
			tween.tween_method(fade_light, 0, 1, 0.2)
			tween.play()
			get_shape_cast().enabled = false
			get_area_collision().disabled = true
			var body := get_node("body") as MeshInstance3D
			body.visible = false
			free_after(particle_wait_time)
			
		Spell.Element.VOID:
			get_area_collision().disabled = true
			free_after(0.1)
			
func free_after(duration: float) -> void:
	free_when_ready = duration

func cast_spell(insert: Callable, next_spell: Spell) -> void:
	await get_tree().physics_frame
	spell_caster.cast_spell(self, caster_vitals, insert, next_spell, tracking_target, fixed_vars)

func insert_spell(p: Node3D) -> void:
	if p == null:
		return
	if p.get_parent() == null:
		add_sibling(p)
	if p is SpellBody:
		(p as SpellBody).setup()

func free_particle() -> void:
	if spell_caster != null:
		spell_caster.free_particles()
	SpellBuffer.free_projectile(self)

func calculate_overall_complexity() -> float:
	if origin_spell_caster != null:
		return origin_spell_caster.get_complexity(complexity_id)
	else:
		return 0.0
