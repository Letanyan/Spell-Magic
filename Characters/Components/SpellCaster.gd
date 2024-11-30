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
	
func update(body: Node3D, delta: float) -> Dictionary:
	var should_remove := []
	var should_halt := []
	var limit_reasons := {}
	for i in range(particles.size()):
		var p: SpellBody = particles[i]
		if p == null:
			should_remove.append(i)
			continue
		
		if p.is_active() and not p.has_expired():
			spell_variables(p.fixed_vars, body, SpellVariableKind.TIMED, p, p.spell)
			if entity == Entity.PLAYER:
				tracking_offset[p.name] = get_spell_tracking_offset(p.spell, p.fixed_vars)
			var reason := p.update_spell(delta, p.fixed_vars)
			if reason != MagicBook.DisallowSpellReason.NONE:
				limit_reasons[p.spell] = reason
			
		var can_remove := false
		if p.spell_caster != null:
			var reasons := p.spell_caster.update(p, delta)
			limit_reasons.merge(reasons)
			can_remove = p.spell_caster.particles.is_empty()
		else:
			can_remove = true
			
		if p.has_expired():
			if p.is_emitting and p.spell.chain_cast_kind == Spell.ChainCastKind.END and p.spell.chain != null:
				can_remove = false
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
		if origin_spell_caster != null and origin_spell_caster.complexity_tracker.has(particles[i].complexity_id):
			should_remove_complexity[particles[i].complexity_id] = true
		if particles[i].is_emitting:
			particles[i].stop_emitting()
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
				
	return limit_reasons
		

enum SpellVariableKind { FIXED, TIMED, BOMB }
func spell_variables(result: Vars, _body: Node3D, variable_kind: SpellVariableKind, p: SpellBody, s: Spell) -> void:
	# FIXME: perf
	var prefix := ""
	var _C := Vars.C
	var _uvw := Vector3i.ZERO
	var _ruvw := Vector3i.ZERO
	var _UVW := Vector3i.ZERO
	var _rUVW := Vector3i.ZERO
	var _ijk := Vector3i.ZERO
	var _rijk := Vector3i.ZERO
	var _IJK := Vector3i.ZERO
	var _rIJK := Vector3i.ZERO
	var __uvw := Vars.uvw
	var __ruvw := Vars.ruvw
	var __UVW := Vars.UVW
	var __rUVW := Vars.rUVW
	var __ijk := Vars.ijk
	var __rijk := Vars.rijk
	var __IJK := Vars.IJK
	var __rIJK := Vars.rIJK
	match variable_kind:
		SpellVariableKind.TIMED: 
			prefix = "t" # values at the current time
			_C = Vars.tC
			_uvw = Vector3i(Vars.tu, Vars.tv, Vars.tw)
			_ruvw = Vector3i(Vars.tru, Vars.trv, Vars.trw)
			_UVW = Vector3i(Vars.tU, Vars.tV, Vars.tW)
			_rUVW = Vector3i(Vars.trU, Vars.trV, Vars.trW)
			_ijk = Vector3i(Vars.ti, Vars.tj, Vars.tk)
			_rijk = Vector3i(Vars.tri, Vars.trj, Vars.trk)
			_IJK = Vector3i(Vars.tI, Vars.tJ, Vars.tK)
			_rIJK = Vector3i(Vars.trI, Vars.trJ, Vars.trK)
			__uvw = Vars.tuvw
			__ruvw = Vars.truvw
			__UVW = Vars.tUVW
			__rUVW = Vars.trUVW
			__ijk = Vars.tijk
			__rijk = Vars.trijk
			__IJK = Vars.tIJK
			__rIJK = Vars.trIJK
		SpellVariableKind.BOMB: 
			prefix = "T" # values after projectile delay
			_C = Vars.TC
			_uvw = Vector3i(Vars.Tu, Vars.Tv, Vars.Tw)
			_ruvw = Vector3i(Vars.Tru, Vars.Trv, Vars.Trw)
			_UVW = Vector3i(Vars.TU, Vars.TV, Vars.TW)
			_rUVW = Vector3i(Vars.TrU, Vars.TrV, Vars.TrW)
			_ijk = Vector3i(Vars.Ti, Vars.Tj, Vars.Tk)
			_rijk = Vector3i(Vars.Tri, Vars.Trj, Vars.Trk)
			_IJK = Vector3i(Vars.TI, Vars.TJ, Vars.TK)
			_rIJK = Vector3i(Vars.TrI, Vars.TrJ, Vars.TrK)
			__uvw = Vars.Tuvw
			__ruvw = Vars.Truvw
			__UVW = Vars.TUVW
			__rUVW = Vars.TrUVW
			__ijk = Vars.Tijk
			__rijk = Vars.Trijk
			__IJK = Vars.TIJK
			__rIJK = Vars.TrIJK
		SpellVariableKind.FIXED: 
			prefix = "" # values when the spell is cast
			_uvw = Vector3i(Vars.u, Vars.v, Vars.w)
			_ruvw = Vector3i(Vars.ru, Vars.rv, Vars.rw)
			_UVW = Vector3i(Vars.U, Vars.V, Vars.W)
			_rUVW = Vector3i(Vars.rU, Vars.rV, Vars.rW)
			_ijk = Vector3i(Vars.i, Vars.j, Vars.k)
			_rijk = Vector3i(Vars.ri, Vars.rj, Vars.rk)
			_IJK = Vector3i(Vars.I, Vars.J, Vars.K)
			_rIJK = Vector3i(Vars.rI, Vars.rJ, Vars.rK)

	var cdir := Vector3.ZERO
	var track := Vector3.ZERO # direction to enemy that was hit by raycast 
	match entity:
		Entity.PLAYER:
			var body := _body as Player
			var port := body.get_viewport()
			var pos := port.get_visible_rect().size / 2.0
			cdir = port.get_camera_3d().project_ray_normal(pos)
			track = get_direction_to_tracking(body, p, cdir)
			result.set_value(Vars.l, 100)
			result.set_value(Vars.fl, 1.0)
			result.set_vector(Vars.Bxyz, body.bounds)
			result.set_value(Vars.Bx, body.bounds.x)
			result.set_value(Vars.By, body.bounds.y)
			result.set_value(Vars.Bz, body.bounds.z)
			result.set_value(Vars.Br, sqrt((body.bounds.x / 2) ** 2 + (body.bounds.z / 2) ** 2))
			
		Entity.ENEMY:
			var body := _body as Enemy
			result[prefix + "C"] = (body as Enemy).player.global_position.distance_to(body.global_position)
			cdir = ((body as Enemy).player.global_position - body.global_position).normalized() # direction to player
			result.set_value(Vars.l, body.level)
			result.set_value(Vars.fl, body.level / 100.0)
			result.set_vector(Vars.Bxyz, body.bounds)
			result.set_value(Vars.Bx, body.bounds.x)
			result.set_value(Vars.By, body.bounds.y)
			result.set_value(Vars.Bz, body.bounds.z)
			result.set_value(Vars.Br, sqrt((body.bounds.x / 2) ** 2 + (body.bounds.z / 2) ** 2))
			
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
				result.set_vector(Vars.Bxyz, body.most_recent_radius)
				result.set_value(Vars.Bx, body.most_recent_radius.x)
				result.set_value(Vars.By, body.most_recent_radius.y)
				result.set_value(Vars.Bz, body.most_recent_radius.z)
				result.set_value(Vars.Br, maxf(body.most_recent_radius.x, maxf(body.most_recent_radius.y, body.most_recent_radius.z)))
			elif s.element == Spell.Element.ICE:
				var rl := body.most_recent_radius.length()
				result.set_vector(Vars.Bxyz, Vector3(rl, 0.2, rl))
				result.set_value(Vars.Bx, rl)
				result.set_value(Vars.By, 0.2)
				result.set_value(Vars.Bz, rl)
				result.set_value(Vars.Br, maxf(rl, 0.2))
			else:
				var rl := body.most_recent_radius.length()
				result.set_vector(Vars.Bxyz, Vector3(rl, rl, rl))
				result.set_value(Vars.Bx, rl)
				result.set_value(Vars.By, rl)
				result.set_value(Vars.Bz, rl)
				result.set_value(Vars.Br, rl)
				
		Entity.TARGET:
			var body := _body as TargetShape
			var pos := body.get_caster_target_position()
			result.set_value(_C, body.caster_position.distance_to(pos))
			cdir = (pos - body.caster_position).normalized() # direction to player
			result.set_vector(Vars.Bxyz, body.bounds)
			result.set_value(Vars.Bx, body.bounds.x)
			result.set_value(Vars.By, body.bounds.y)
			result.set_value(Vars.Bz, body.bounds.z)
			result.set_value(Vars.Br, maxf(body.bounds.x, maxf(body.bounds.y, body.bounds.z)))
	
	# direction to camera
	result.set_vector(__uvw, cdir)
	result.set_value(_uvw.x, cdir.x)
	result.set_value(_uvw.y, cdir.y)
	result.set_value(_uvw.z, cdir.z)
	var ruvw := Vector3(Vector3(cdir.x, 0, cdir.z).signed_angle_to(Vector3(1, 0, 0), Vector3.UP), cdir.signed_angle_to(Vector3(0, 1, 0), Vector3.UP), Vector3(cdir.x, 0, cdir.z).signed_angle_to(Vector3(0, 0, 1), Vector3.UP))
	result.set_vector(__ruvw, ruvw)
	result.set_value(_ruvw.x, ruvw.x)
	result.set_value(_ruvw.y, ruvw.y)
	result.set_value(_ruvw.z, ruvw.z)
	
	
	# direction to homing target
	result.set_vector(__UVW, track)
	result.set_value(_UVW.x, track.x)
	result.set_value(_UVW.y, track.y)
	result.set_value(_UVW.z, track.z)
	var rUVW := Vector3(Vector3(track.x, 0, track.z).signed_angle_to(Vector3(1, 0, 0), Vector3.UP), track.signed_angle_to(Vector3(0, 1, 0), Vector3.UP), Vector3(track.x, 0, track.z).signed_angle_to(Vector3(0, 0, 1), Vector3.UP))
	result.set_vector(__rUVW, rUVW)
	result.set_value(_rUVW.x, rUVW.x)
	result.set_value(_rUVW.y, rUVW.y)
	result.set_value(_rUVW.z, rUVW.z)
	
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
			
	result.set_vector(__ijk, c)
	result.set_value(_ijk.x, c.x)
	result.set_value(_ijk.y, c.y)
	result.set_value(_ijk.z, c.z)
	var rijk := Vector3(Vector3(c.x, 0, c.z).signed_angle_to(Vector3(1, 0, 0), Vector3.UP), c.signed_angle_to(Vector3(0, 1, 0), Vector3.UP), Vector3(c.x, 0, c.z).signed_angle_to(Vector3(0, 0, 1), Vector3.UP))
	result.set_vector(__rijk, rijk)
	result.set_value(_rijk.x, rijk.x)
	result.set_value(_rijk.y, rijk.y)
	result.set_value(_rijk.z, rijk.z)
		
	
	if s.player_is_origin:
		if variable_kind == SpellVariableKind.FIXED:
			if entity == Entity.PLAYER or entity == Entity.ENEMY:
				result.set_vector(Vars.abs_pos, Vec3.xz_y(_body.position, (_body as CharacterBody).feet_position()))
			else:
				result.set_vector(Vars.abs_pos, _body.position)
		elif variable_kind == SpellVariableKind.TIMED:
			if entity == Entity.PLAYER or entity == Entity.ENEMY:
				result.set_vector(Vars.rel_pos, Vec3.xz_y(_body.position, (_body as CharacterBody).feet_position()))
			else:
				result.set_vector(Vars.rel_pos, _body.position)
	else:
		if entity == Entity.PLAYER:
			var port := _body.get_viewport()
			var pos := port.get_visible_rect().size / 2.0
			var dist: SpringArm3D = _body.get_node("./CamPivot/Arm")
			if variable_kind == SpellVariableKind.FIXED:
				result.set_vector(Vars.abs_pos, port.get_camera_3d().project_position(pos, dist.spring_length))
			elif variable_kind == SpellVariableKind.TIMED:
				result.set_vector(Vars.rel_pos, port.get_camera_3d().project_position(pos, dist.spring_length))
		elif entity == Entity.ENEMY:
			if variable_kind == SpellVariableKind.FIXED:
				result.set_vector(Vars.abs_pos, _body.position + cdir + Vector3(0, (_body as CharacterBody).bounds.y, 0) / 4)
			elif variable_kind == SpellVariableKind.TIMED:
				result.set_vector(Vars.rel_pos, _body.position + cdir + Vector3(0, (_body as CharacterBody).bounds.y, 0) / 4)
		elif entity == Entity.PROJECTILE:
			if variable_kind == SpellVariableKind.FIXED:
				result.set_vector(Vars.abs_pos, _body.position + cdir)
			elif variable_kind == SpellVariableKind.TIMED:
				result.set_vector(Vars.rel_pos, _body.position + cdir)
		elif entity == Entity.TARGET:
			if variable_kind == SpellVariableKind.FIXED:
				result.set_vector(Vars.abs_pos, (_body as TargetShape).caster_position + cdir)
			elif variable_kind == SpellVariableKind.TIMED:
				result.set_vector(Vars.rel_pos, (_body as TargetShape).caster_position + cdir)
	
	if p != null: # direction from character to spell
		var old_origin := Vector3(result.get_value(_IJK.x), result.get_value(_IJK.y), result.get_value(_IJK.z))
		var origin: Vector3
		if entity == Entity.TARGET:
			origin = old_origin.lerp(((_body as TargetShape).caster_position - p.position).normalized(), 0.0166667).normalized()
		else:
			origin = old_origin.lerp((_body.position - p.position).normalized(), 0.0166667).normalized()
		
		result.set_vector(__IJK, origin)
		result.set_value(_IJK.x, origin.x)
		result.set_value(_IJK.y, origin.y)
		result.set_value(_IJK.z, origin.z)
		var rIJK := Vector3(Vector3(origin.x, 0, origin.z).signed_angle_to(Vector3(1, 0, 0), Vector3.UP), origin.signed_angle_to(Vector3(0, 1, 0), Vector3.UP), Vector3(origin.x, 0, origin.z).signed_angle_to(Vector3(0, 0, 1), Vector3.UP))
		result.set_vector(__rIJK, rIJK)
		result.set_value(_rIJK.x, rIJK.x)
		result.set_value(_rIJK.y, rIJK.y)
		result.set_value(_rIJK.z, rIJK.z)
	
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
			
	
func all_spell_variables(body: Node3D, p: SpellBody, spell: Spell) -> Vars:
	var result := Vars.new()
	spell_variables(result, body, SpellVariableKind.FIXED, p, spell)
	spell_variables(result, body, SpellVariableKind.TIMED, p, spell)
	return result

func cast_spell(body: Node3D, vitals: Vitals, insert: Callable, spell: Spell, target: Variant = null, inherited_vars: Vars = null) -> MagicBook.DisallowSpellReason:
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
	var exvars := Vars.new()
	if inherited_vars != null and inherited_vars.has("l"): # copy enemy level vars
		vars.set_value(Vars.l, inherited_vars.get_value(Vars.l))
		vars.set_value(Vars.fl, inherited_vars.get_value(Vars.fl))
		vars.set_value(Vars.C, inherited_vars.get_value(Vars.C))
		
	var cid := 0
	if body is SpellBody:
		var spell_body := body as SpellBody
		exvars.merge(spell_body.expression_vars, true)
		vars.merge(exvars, true)
		cid = spell_body.complexity_id
	else:
		cid = randi()
		while complexity_tracker.has(cid): cid = randi()
			
	var ps := spell.get_particles(vars, exvars)
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
		
func get_spell_tracking_offset(spell: Spell, vars: Vars) -> Vector3:
	var temp_U := vars.get_value(Vars.U)
	var temp_V := vars.get_value(Vars.V)
	var temp_W := vars.get_value(Vars.W)
	var temp_tU := vars.get_value(Vars.tU)
	var temp_tV := vars.get_value(Vars.tV)
	var temp_tW := vars.get_value(Vars.tW)
	
	vars.set_value(Vars.U, 0.0)
	vars.set_value(Vars.V, 0.0)
	vars.set_value(Vars.W, 0.0)
	vars.set_value(Vars.tU, 0.0)
	vars.set_value(Vars.tV, 0.0)
	vars.set_value(Vars.tW, 0.0)
	var result := spell.calculate_location(vars, true)
	vars.set_value(Vars.U, temp_U)
	vars.set_value(Vars.V, temp_V)
	vars.set_value(Vars.W, temp_W)
	vars.set_value(Vars.tU, temp_tU)
	vars.set_value(Vars.tV, temp_tV)
	vars.set_value(Vars.tW, temp_tW)
	
	return result
	

func start_particle(delay: float, body: Node3D, p: SpellBody, insert: Callable) -> void:
	var q: Node3D = null
	if delay > 0 and p.spell.is_bomb:
		q = p.spell.get_turret(p.n, p.fixed_vars)
		insert.call(q)
	await body.get_tree().create_timer(delay, false, true).timeout
	p.time_stamp = 0.0
	if p.spell.is_bomb:
		spell_variables(p.fixed_vars, body, SpellVariableKind.BOMB, p, p.spell)
	else:
		spell_variables(p.fixed_vars, body, SpellVariableKind.FIXED, p, p.spell)
	p.spell.compute_expressions(p.fixed_vars, null)
	#p.fixed_vars.print_values()
	insert.call(p)
	if q and q.get_parent():
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

func apply_to_all_particles(callback: Callable, result: Dictionary) -> void:
	var stack: Array[SpellCaster] = [self]
	while not stack.is_empty():
		var caster := stack.pop_back() as SpellCaster
		for p: SpellBody in caster.particles:
			callback.call(p, result)
			if p.spell_caster != null and not p.spell_caster.particles.is_empty():
				stack.push_back(p.spell_caster)
		
