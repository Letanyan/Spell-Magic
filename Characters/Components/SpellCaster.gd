class_name SpellCaster

enum Entity { PLAYER, ENEMY, PROJECTILE, TARGET }

var origin_node: Node3D = null
var entity: Entity
var particles: Array[SpellBody] = []
var ignore_mana_cost: bool

var tracking_node: Dictionary = {} # [String]Node3D
var tracking_position: Dictionary = {} # [String]Vector3
var tracking_offset: Dictionary = {} # [String]Vector3

var complexity_tracker := {} ## [int]{count: float, mean: float, M2: float}

func _init(o: Node3D, e: Entity) -> void:
	origin_node = o
	entity = e
	ignore_mana_cost = true
	
func update(body: Node3D, delta: float) -> void:
	var t := Time.get_unix_time_from_system()
	var should_remove := []
	var should_halt := []
	for i in range(particles.size()):
		var p: SpellBody = particles[i]
		
		if p.is_active() and not p.has_expired(t):
			spell_variables(p.fixed_vars, body, SpellVariableKind.TIMED, p, p.spell)
			if entity == Entity.PLAYER:
				tracking_offset[p.name] = get_spell_tracking_offset(p.spell, p.fixed_vars)
			p.update_spell(t, delta, p.fixed_vars)
			
		var can_remove := false
		if p.spell_caster != null:
			p.spell_caster.update(p, delta)
			can_remove = p.spell_caster.particles.is_empty()
		else:
			can_remove = true
			
		if p.has_expired(t):
			if p.spell.chain_cast_kind == Spell.ChainCastKind.END and p.spell.chain != null:
				p.cast_spell(func(np: Node3D) -> void: if np != null: p.call_deferred("add_sibling", np), p.spell.chain)
			tracking_node.erase(p.name)
			if can_remove:
				should_remove.append(i)
			elif p.is_emitting:
				should_halt.append(i)
				
	var idx := should_halt.size() - 1
	while idx >= 0:
		var i := should_halt[idx] as int
		particles[i].stop_emitting()
		idx -= 1
		
	idx = should_remove.size() - 1
	var should_remove_complexity := {}
	var origin_spell_caster: SpellCaster = null
	if origin_node is Player:
		origin_spell_caster = (origin_node as Player).spell_caster
	elif origin_node is Enemy:
		origin_spell_caster = (origin_node as Enemy).spell_caster
	while idx >= 0:
		var i := should_remove[idx] as int
		particles[i].get_parent().remove_child(particles[i])
		if origin_spell_caster != null and origin_spell_caster.complexity_tracker.has(particles[i].complexity_id):
			should_remove_complexity[particles[i].complexity_id] = true
		particles.remove_at(i)
		idx -= 1
		
	if origin_spell_caster != null:
		for cid: int in should_remove_complexity:
			var should_skip := false
			for p in origin_spell_caster.particles:
				if p.complexity_id == cid:
					should_skip = true
					break
			if should_skip:
				continue
			if origin_spell_caster.complexity_tracker.has(cid):
				origin_spell_caster.complexity_tracker.erase(cid)
		

enum SpellVariableKind { FIXED, TIMED, BOMB }
func spell_variables(result: Dictionary, _body: Node3D, variable_kind: SpellVariableKind, p: SpellBody, s: Spell) -> Dictionary:
	var prefix := ""
	match variable_kind:
		SpellVariableKind.TIMED: prefix = "t" # values at the current time
		SpellVariableKind.BOMB: prefix = "T" # values after projectile delay
		SpellVariableKind.FIXED: prefix = "" # values when the spell is cast

	var cdir := Vector3.ZERO
	var track := Vector3.ZERO # direction to enemy that was hit by raycast 
	match entity:
		Entity.PLAYER:
			var body := _body as Player
			var port := body.get_viewport()
			var pos := port.get_visible_rect().size / 2.0
			cdir = port.get_camera_3d().project_ray_normal(pos)
			track = get_direction_to_tracking(body, p, cdir)
			result["l"] = 100
			result["fl"] = 1.0
			result["Bx"] = body.bounds.x
			result["By"] = body.bounds.y
			result["Bz"] = body.bounds.z
			result["Br"] = sqrt((body.bounds.x / 2) ** 2 + (body.bounds.z / 2) ** 2)
			
		Entity.ENEMY:
			var body := _body as Enemy
			result[prefix + "C"] = (body as Enemy).player.global_position.distance_to(body.global_position)
			cdir = ((body as Enemy).player.global_position - body.global_position).normalized() # direction to player
			result["l"] = body.level
			result["fl"] = body.level / 100.0
			result["Bx"] = body.bounds.x
			result["By"] = body.bounds.y
			result["Bz"] = body.bounds.z
			result["Br"] = sqrt((body.bounds.x / 2) ** 2 + (body.bounds.z / 2) ** 2)
			
		Entity.PROJECTILE:
			var body := _body as SpellBody
			#cdir = -body.velocity.normalized()
			var port := body.get_viewport()
			var pos := port.get_visible_rect().size / 2.0
			cdir = port.get_camera_3d().project_ray_normal(pos)
			if p != null:
				var hit_on := (body.position - p.position).normalized()
				track = get_direction_to_tracking(body, p, hit_on)
			if s.element == Spell.Element.ROCK:
				result["Bx"] = body.most_recent_radius.x
				result["By"] = body.most_recent_radius.y
				result["Bz"] = body.most_recent_radius.z
				result["Br"] = maxf(body.most_recent_radius.x, maxf(body.most_recent_radius.y, body.most_recent_radius.z))
			elif s.element == Spell.Element.ICE:
				var rl := body.most_recent_radius.length()
				result["Bx"] = rl
				result["By"] = 0.2
				result["Bz"] = rl
				result["Br"] = maxf(rl, 0.2)
			else:
				var rl := body.most_recent_radius.length()
				result["Bx"] = rl
				result["By"] = rl
				result["Bz"] = rl
				result["Br"] = rl
				
		Entity.TARGET:
			var body := _body as TargetShape
			var pos := body.get_caster_target_position()
			result[prefix + "C"] = body.caster_position.distance_to(pos)
			cdir = (pos - body.caster_position).normalized() # direction to player
			result["Bx"] = body.bounds.x
			result["By"] = body.bounds.y
			result["Bz"] = body.bounds.z
			result["Br"] = maxf(body.bounds.x, maxf(body.bounds.y, body.bounds.z))
	
	# direction to camera
	result[prefix + "u"] = cdir.x
	result[prefix + "v"] = cdir.y
	result[prefix + "w"] = cdir.z
	result[prefix + "ru"] = Vector3(cdir.x, 0, cdir.z).signed_angle_to(Vector3(1, 0, 0), Vector3.UP)
	result[prefix + "rv"] = cdir.signed_angle_to(Vector3(0, 1, 0), Vector3.UP)
	result[prefix + "rw"] = Vector3(cdir.x, 0, cdir.z).signed_angle_to(Vector3(0, 0, 1), Vector3.UP)
	
	
	# direction to homing target
	result[prefix + "U"] = track.x
	result[prefix + "V"] = track.y
	result[prefix + "W"] = track.z
	result[prefix + "rU"] = Vector3(track.x, 0, track.z).signed_angle_to(Vector3(1, 0, 0), Vector3.UP)
	result[prefix + "rV"] = track.signed_angle_to(Vector3(0, 1, 0), Vector3.UP)
	result[prefix + "rW"] = Vector3(track.x, 0, track.z).signed_angle_to(Vector3(0, 0, 1), Vector3.UP)
	
	var c := Vector3.ZERO # character facing direction
	match entity:
		Entity.PLAYER:
			c = (_body as CharacterBody).velocity.normalized()
		Entity.ENEMY:
			c = (_body as CharacterBody).velocity.normalized()
		Entity.PROJECTILE:
			c = (_body as SpellBody).velocity.normalized()
		Entity.TARGET:
			c = cdir
			
	result[prefix + "i"] = c.x
	result[prefix + "j"] = c.y
	result[prefix + "k"] = c.z
	result[prefix + "ri"] = Vector3(c.x, 0, c.z).signed_angle_to(Vector3(1, 0, 0), Vector3.UP)
	result[prefix + "rj"] = c.signed_angle_to(Vector3(0, 1, 0), Vector3.UP)
	result[prefix + "rk"] = Vector3(c.x, 0, c.z).signed_angle_to(Vector3(0, 0, 1), Vector3.UP)
		
	
	if s.player_is_origin:
		if variable_kind == SpellVariableKind.FIXED:
			result["~abs_pos"] = _body.position
		elif variable_kind == SpellVariableKind.TIMED:
			result["~rel_pos"] = _body.position
	else:
		if entity == Entity.PLAYER:
			var port := _body.get_viewport()
			var pos := port.get_visible_rect().size / 2.0
			var dist: SpringArm3D = _body.get_node("./CamPivot/Arm")
			if variable_kind == SpellVariableKind.FIXED:
				result["~abs_pos"] = port.get_camera_3d().project_position(pos, dist.spring_length)
			elif variable_kind == SpellVariableKind.TIMED:
				result["~rel_pos"] = port.get_camera_3d().project_position(pos, dist.spring_length)
		elif entity == Entity.ENEMY:
			if variable_kind == SpellVariableKind.FIXED:
				result["~abs_pos"] = _body.position + cdir + Vector3(0, (_body as CharacterBody).bounds.y, 0) / 4
			elif variable_kind == SpellVariableKind.TIMED:
				result["~rel_pos"] = _body.position + cdir + Vector3(0, (_body as CharacterBody).bounds.y, 0) / 4
		elif entity == Entity.PROJECTILE:
			if variable_kind == SpellVariableKind.FIXED:
				result["~abs_pos"] = _body.position + cdir
			elif variable_kind == SpellVariableKind.TIMED:
				result["~rel_pos"] = _body.position + cdir
		elif entity == Entity.TARGET:
			if variable_kind == SpellVariableKind.FIXED:
				result["~abs_pos"] = (_body as TargetShape).caster_position + cdir
			elif variable_kind == SpellVariableKind.TIMED:
				result["~rel_pos"] = (_body as TargetShape).caster_position + cdir
			
	
	if p != null: # direction from character to spell
		var old_origin := Vector3(result.get(prefix + "I", 0) as float, result.get(prefix + "J", 0) as float, result.get(prefix + "K", 0) as float)
		var origin: Vector3
		if entity == Entity.TARGET:
			origin = old_origin.lerp(((_body as TargetShape).caster_position - p.position).normalized(), 0.0166667).normalized()
		else:
			origin = old_origin.lerp((_body.position - p.position).normalized(), 0.0166667).normalized()
		
		result[prefix + "I"] = origin.x
		result[prefix + "J"] = origin.y
		result[prefix + "K"] = origin.z
		result[prefix + "rI"] = Vector3(origin.x, 0, origin.z).signed_angle_to(Vector3(1, 0, 0), Vector3.UP)
		result[prefix + "rJ"] = origin.signed_angle_to(Vector3(0, 1, 0), Vector3.UP)
		result[prefix + "rK"] = Vector3(origin.x, 0, origin.z).signed_angle_to(Vector3(0, 0, 1), Vector3.UP)
		
	return result
	
func get_direction_to_tracking(body: Node3D, p: SpellBody, default: Vector3) -> Vector3:
	if p == null:
		return default
	if tracking_node == null:
		return default
	else:
		var t: Variant = tracking_node.get(p.name, null)
		var position := tracking_position.get(p.name, Vector3.ZERO) as Vector3
		var offset := tracking_offset.get(p.name, Vector3.ZERO) as Vector3
		if t == null or !p.is_inside_tree():
			return default
		if t is Node3D and (t as Node3D).is_inside_tree():
			var vec: Vector3 = (((t as Node3D).global_position + offset) - p.global_position).normalized()
			var dir: Vector3 = position.lerp(vec, 0.0166667).normalized()
			tracking_position[p.name] = dir
			return dir
		elif t is Vector3:
			return t
		else:
			return default
			
	
func all_spell_variables(body: Node3D, p: SpellBody, spell: Spell) -> Dictionary:
	var result := {}
	spell_variables(result, body, SpellVariableKind.FIXED, p, spell)
	spell_variables(result, body, SpellVariableKind.TIMED, p, spell)
	return result

func cast_spell(body: Node3D, vitals: Vitals, insert: Callable, spell: Spell, target: Variant = null, inherited_vars: Dictionary = {}) -> MagicBook.DisallowSpellReason:
	if vitals != null:
		if vitals.mana.value >= spell.actual_mana_cost() or ignore_mana_cost:
			vitals.mana.apply_ignoring_resistance(-spell.actual_mana_cost())
		else:
			return MagicBook.DisallowSpellReason.MANA
			
	var node_to_track: Variant = null
	var cdir := Vector3.ZERO
	if entity == Entity.PLAYER:
		var port := body.get_viewport()
		var pos := port.get_visible_rect().size / 2.0
		var coord := port.get_camera_3d().project_ray_origin(pos)
		cdir = port.get_camera_3d().project_ray_normal(pos)
		if body is CharacterBody:
			node_to_track = GlobalData.nav.get_ray_intersection(body as CharacterBody, coord, coord + cdir * 500)
		elif body is SpellBody:
			#node_to_track = GlobalData.nav.get_ray_intersection((body as SpellBody).get_collision_object(), coord, coord + cdir * 500)
			node_to_track = Navigator.get_ray_intersection_from_spell_body((body as SpellBody), coord, coord + cdir * 500)
		if node_to_track == null:
			node_to_track = cdir
	elif entity == Entity.PROJECTILE:
		node_to_track = target
			
			
	# it's fine that a projectile doesn't have a target set yet at the start
	# since by default camera direction equals target direction at start
	var vars := all_spell_variables(body, null, spell)
	var exvars := {}
	var override_vars := {}
	if inherited_vars.has("l"): # copy enemy level vars
		vars["l"] = inherited_vars["l"]
		vars["fl"] = inherited_vars["fl"]
		vars["C"] = inherited_vars["C"]
		
	var cid := 0
	if body is SpellBody:
		var spell_body := body as SpellBody
		exvars.merge(spell_body.expression_vars, true)
		vars.merge(exvars, true)
		cid = spell_body.complexity_id
		for id: String in spell_body.override_vars:
			override_vars[id] = spell_body.override_vars[id]
	else:
		cid = randi()
		while complexity_tracker.has(cid): cid = randi()
		
		
	for id: String in inherited_vars:
		if id.begins_with("^"):
			override_vars[id.substr(1)] = inherited_vars[id]
			
	var ps := spell.get_particles(vars, exvars, override_vars)
	var spell_offset := get_spell_tracking_offset(spell, vars)
	for p: SpellBody in ps:
		p.name += str(randi())
		p.origin_node = origin_node
		p.tracking_target = node_to_track
		p.caster_vitals = vitals
		p.complexity_id = cid
		particles.append(p)
		tracking_node[p.name] = node_to_track
		tracking_position[p.name] = cdir
		tracking_offset[p.name] = spell_offset
		spell_variables(p.fixed_vars, body, SpellVariableKind.TIMED, p, p.spell)
		var delay := spell.calculate_delay(p.fixed_vars)
		start_particle(delay, body, p, insert)
		
	return MagicBook.DisallowSpellReason.NONE
		
func get_spell_tracking_offset(spell: Spell, vars: Dictionary) -> Vector3:
	var temp := vars.duplicate()
	temp["U"] = 0.0
	temp["V"] = 0.0
	temp["W"] = 0.0
	temp["tU"] = 0.0
	temp["tV"] = 0.0
	temp["tW"] = 0.0
	return spell.calculate_location(temp, true)
	

func start_particle(delay: float, body: Node3D, p: SpellBody, insert: Callable) -> void:
	var q: Node3D = null
	if delay > 0 and p.spell.is_bomb:
		q = p.spell.get_turret(p.n, p.fixed_vars, p.override_vars)
		insert.call(q)
	await body.get_tree().create_timer(delay, false, true).timeout
	p.time_start = Time.get_unix_time_from_system()
	if p.spell.is_bomb:
		spell_variables(p.fixed_vars, body, SpellVariableKind.BOMB, p, p.spell)
	else:
		spell_variables(p.fixed_vars, body, SpellVariableKind.FIXED, p, p.spell)
	p.spell.compute_expressions(p.fixed_vars, {}, p.override_vars)
	insert.call(p)
	if q and q.get_parent():
		q.get_parent().remove_child(q)
		q.queue_free()
	
func set_up_collision(world: Node3D, p: SpellBody) -> void:
	var new_agent_rid: RID = NavigationServer3D.agent_create()
	var default_3d_map_rid: RID = world.get_world_3d().get_navigation_map()
	NavigationServer3D.agent_set_map(new_agent_rid, default_3d_map_rid)
	NavigationServer3D.agent_set_radius(new_agent_rid, 5)
	NavigationServer3D.agent_set_position(new_agent_rid, p.global_position)

func free_particles() -> void:
	for p: SpellBody in particles:
		p.free_particle()
	particles.clear()

func update_pause_time(pause_time: float) -> void:
	for p: SpellBody in particles:
		p.pause_time += pause_time
		if p.spell_caster != null:
			p.spell_caster.update_pause_time(pause_time)

func update_complexity(id: int, value: float) -> void:
	var dict := complexity_tracker.get(id, {"count": 0.0, "mean": 0.0, "M2": 0.0}) as Dictionary
	dict["count"] += 1
	var delta := value - dict["mean"] as float
	dict["mean"] += delta / dict["count"] as float
	var delta2 := dict["count"] as float - dict["mean"] as float
	dict["M2"] += delta * delta2
	complexity_tracker[id] = dict

func get_complexity(id: int) -> float:
	var dict := complexity_tracker.get(id, {"count": 0.0, "mean": 0.0, "M2": 0.0}) as Dictionary
	#var mean := dict["mean"] as float
	var count := dict["count"] as float
	var M2 := dict["M2"] as float
		
	if count >= 2:
		var sample_variance := absf(M2) / (count - 1)
		var stddev := sqrt(sample_variance)
		return stddev
	else:
		return 0.0
