class_name SpellCaster

enum Entity { PLAYER, ENEMY, PROJECTILE, TARGET }

var origin_node: Node3D
var entity: Entity
var particles: Array[SpellBody] = []
var ignore_mana_cost: bool
var spells_on_hold: Dictionary = {}

var complexity_tracker := {} ## [int]{count: float, mean: float, M2: float}
var update_index := 0

func _init(o: Node3D, e: Entity) -> void:
	origin_node = o
	entity = e
	ignore_mana_cost = true
	
func update(body: Node3D, delta: float, is_level_editor: bool = false) -> Dictionary:
	var should_remove := []
	var should_halt := []
	var limit_reasons := {}
	var time_spent := 0
	if update_index >= particles.size():
		update_index = 0
	while update_index < particles.size():
		var time_start := Time.get_ticks_usec()
		var p: SpellBody = particles[update_index]
		if p == null:
			should_remove.append(update_index)
			update_index += 1
			continue
			
		if p.update_tick - delta > 0:
			p.update_tick -= delta
			p.prepare_update_spell(delta)
			update_index += 1
			continue
		else:
			p.update_tick = 0.0
		
		if p.is_active() and (not p.has_expired() or (p.spell.is_infinite and is_level_editor)):
			spell_variables(p.fixed_vars, body, SpellVariableKind.TIMED, p, p.spell)
			if entity == Entity.PLAYER:
				p.tracking_offset = get_spell_tracking_offset(p.spell, p.fixed_vars)
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
			
		if p.has_expired() and (not is_level_editor or is_level_editor and not p.spell.is_infinite):
			if p.is_emitting and p.spell.chain_cast_kind == Spell.ChainCastKind.END and p.spell.chain != null and not p.spell.is_infinite:
				can_remove = false
				var insert_func := func(np: Node3D) -> void:
					if np == null:
						return
					if np.get_parent() == null:
						p.add_sibling(np)
					if np is SpellBody:
						(np as SpellBody).setup()
				p.cast_spell(insert_func, p.spell.chain)
			if can_remove:
				should_remove.append(update_index)
			elif p.is_emitting:
				should_halt.append(update_index)
				
		update_index += 1
		time_spent += Time.get_ticks_usec() - time_start
		if time_spent > 5000:
			print("break at: ", update_index, " < ", particles.size(), " after: ", time_spent)
			break
			
	for i in range(update_index, particles.size()):
		var p := particles[i]
		if p.update_tick - delta > 0:
			p.update_tick -= delta
		p.prepare_update_spell(delta)
				
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
	var _C := Vars.tC
	var _uvw := Vector3i(Vars.tu, Vars.tv, Vars.tw)
	var _ruvw := Vector3i(Vars.tru, Vars.trv, Vars.trw)
	var _UVW := Vector3i(Vars.tU, Vars.tV, Vars.tW)
	var _rUVW := Vector3i(Vars.trU, Vars.trV, Vars.trW)
	var _ijk := Vector3i(Vars.ti, Vars.tj, Vars.tk)
	var _rijk := Vector3i(Vars.tri, Vars.trj, Vars.trk)
	var _IJK := Vector3i(Vars.tI, Vars.tJ, Vars.tK)
	var _rIJK := Vector3i(Vars.trI, Vars.trJ, Vars.trK)
	var __uvw := Vars.tuvw
	var __ruvw := Vars.truvw
	var __UVW := Vars.tUVW
	var __rUVW := Vars.trUVW
	var __ijk := Vars.tijk
	var __rijk := Vars.trijk
	var __IJK := Vars.tIJK
	var __rIJK := Vars.trIJK
	var is_timed := false
	match variable_kind:
		SpellVariableKind.TIMED: # values at the current time
			is_timed = true
		SpellVariableKind.BOMB: # values after projectile delay
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
		SpellVariableKind.FIXED: # values when the spell is cast
			_C = Vars.C
			_uvw = Vector3i(Vars.u, Vars.v, Vars.w)
			_ruvw = Vector3i(Vars.ru, Vars.rv, Vars.rw)
			_UVW = Vector3i(Vars.U, Vars.V, Vars.W)
			_rUVW = Vector3i(Vars.rU, Vars.rV, Vars.rW)
			_ijk = Vector3i(Vars.i, Vars.j, Vars.k)
			_rijk = Vector3i(Vars.ri, Vars.rj, Vars.rk)
			_IJK = Vector3i(Vars.I, Vars.J, Vars.K)
			_rIJK = Vector3i(Vars.rI, Vars.rJ, Vars.rK)
			__uvw = Vars.uvw
			__ruvw = Vars.ruvw
			__UVW = Vars.UVW
			__rUVW = Vars.rUVW
			__ijk = Vars.ijk
			__rijk = Vars.rijk
			__IJK = Vars.IJK
			__rIJK = Vars.rIJK
	
	
	if not is_timed or s.variable_update_set_contains(Spell.VariableUpdateSet.C):
		if entity == Entity.ENEMY:
			var body := _body as Enemy
			result.set_value(_C, (body as Enemy).player.global_position.distance_to(body.global_position))
		elif entity == Entity.TARGET:
			var body := _body as TargetShape
			var pos := body.get_caster_target_position()
			result.set_value(_C, body.caster_position.distance_to(pos))
	
	var cdir := Vector3.ZERO
	if not is_timed or s.variable_update_set_contains(Spell.VariableUpdateSet.uvw) or s.variable_update_set_contains(Spell.VariableUpdateSet.ruvw):
		match entity:
			Entity.PLAYER:
				var body := _body as Player
				var port := body.get_viewport()
				var pos := port.get_visible_rect().size / 2.0
				cdir = port.get_camera_3d().project_ray_normal(pos)
				if variable_kind == SpellVariableKind.FIXED:
					result.set_value(Vars.l, 100)
					result.set_value(Vars.fl, 1.0)
					result.set_vector(Vars.Bxyz, body.bounds)
					result.set_value(Vars.Bx, body.bounds.x)
					result.set_value(Vars.By, body.bounds.y)
					result.set_value(Vars.Bz, body.bounds.z)
					result.set_value(Vars.Br, sqrt((body.bounds.x / 2) ** 2 + (body.bounds.z / 2) ** 2))
					
			Entity.ENEMY:
				var body := _body as Enemy
				result.set_value(_C, (body as Enemy).player.global_position.distance_to(body.global_position))
				cdir = ((body as Enemy).player.global_position - body.global_position).normalized() # direction to player
				if variable_kind == SpellVariableKind.FIXED:
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
				if variable_kind == SpellVariableKind.FIXED:
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
				cdir = (pos - body.caster_position).normalized() # direction to player
				if variable_kind == SpellVariableKind.FIXED:
					result.set_vector(Vars.Bxyz, body.bounds)
					result.set_value(Vars.Bx, body.bounds.x)
					result.set_value(Vars.By, body.bounds.y)
					result.set_value(Vars.Bz, body.bounds.z)
					result.set_value(Vars.Br, maxf(body.bounds.x, maxf(body.bounds.y, body.bounds.z)))
		
		# direction to camera
		if not is_timed or s.variable_update_set_contains(Spell.VariableUpdateSet.uvw):
			result.set_vector(__uvw, cdir)
			result.set_value(_uvw.x, cdir.x)
			result.set_value(_uvw.y, cdir.y)
			result.set_value(_uvw.z, cdir.z)
		if not is_timed or s.variable_update_set_contains(Spell.VariableUpdateSet.ruvw):
			var ruvw := Vector3(Vector3(cdir.x, 0, cdir.z).signed_angle_to(Vector3(1, 0, 0), Vector3.UP), cdir.signed_angle_to(Vector3(0, 1, 0), Vector3.UP), Vector3(cdir.x, 0, cdir.z).signed_angle_to(Vector3(0, 0, 1), Vector3.UP))
			result.set_vector(__ruvw, ruvw)
			result.set_value(_ruvw.x, ruvw.x)
			result.set_value(_ruvw.y, ruvw.y)
			result.set_value(_ruvw.z, ruvw.z)
				
	var track := Vector3.ZERO
	if not is_timed or s.variable_update_set_contains(Spell.VariableUpdateSet.UVW) or s.variable_update_set_contains(Spell.VariableUpdateSet.rUVW):
		match entity:
			Entity.PLAYER:
				var body := _body as Player
				track = get_direction_to_tracking(body, p, cdir)
			Entity.PROJECTILE:
				if p != null:
					var body := _body as SpellBody
					var hit_on := (body.position - p.position).normalized()
					track = get_direction_to_tracking(body, p, hit_on)
				
		# direction to homing target	
		if not is_timed or s.variable_update_set_contains(Spell.VariableUpdateSet.UVW):
			result.set_vector(__UVW, track)
			result.set_value(_UVW.x, track.x)
			result.set_value(_UVW.y, track.y)
			result.set_value(_UVW.z, track.z)
		if not is_timed or s.variable_update_set_contains(Spell.VariableUpdateSet.rUVW):
			var rUVW := Vector3(Vector3(track.x, 0, track.z).signed_angle_to(Vector3(1, 0, 0), Vector3.UP), track.signed_angle_to(Vector3(0, 1, 0), Vector3.UP), Vector3(track.x, 0, track.z).signed_angle_to(Vector3(0, 0, 1), Vector3.UP))
			result.set_vector(__rUVW, rUVW)
			result.set_value(_rUVW.x, rUVW.x)
			result.set_value(_rUVW.y, rUVW.y)
			result.set_value(_rUVW.z, rUVW.z)
	
	
	if not is_timed or s.variable_update_set_contains(Spell.VariableUpdateSet.ijk) or s.variable_update_set_contains(Spell.VariableUpdateSet.rijk):
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
		var cxz := Vector3(c.x, 0, c.z)
				
		if not is_timed or s.variable_update_set_contains(Spell.VariableUpdateSet.ijk):
			result.set_vector(__ijk, c)
			result.set_value(_ijk.x, c.x)
			result.set_value(_ijk.y, c.y)
			result.set_value(_ijk.z, c.z)
		if not is_timed or s.variable_update_set_contains(Spell.VariableUpdateSet.rijk):
			var rijk := Vector3(cxz.signed_angle_to(Vector3.RIGHT, Vector3.UP), c.signed_angle_to(Vector3.UP, Vector3.UP), cxz.signed_angle_to(Vector3.BACK, Vector3.UP))
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
		elif s.follow and variable_kind == SpellVariableKind.TIMED:
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
			elif s.follow and variable_kind == SpellVariableKind.TIMED:
				result.set_vector(Vars.rel_pos, port.get_camera_3d().project_position(pos, dist.spring_length))
		elif entity == Entity.ENEMY:
			if variable_kind == SpellVariableKind.FIXED:
				result.set_vector(Vars.abs_pos, _body.position + cdir + Vector3(0, (_body as CharacterBody).bounds.y, 0) / 4)
			elif s.follow and variable_kind == SpellVariableKind.TIMED:
				result.set_vector(Vars.rel_pos, _body.position + cdir + Vector3(0, (_body as CharacterBody).bounds.y, 0) / 4)
		elif entity == Entity.PROJECTILE:
			if variable_kind == SpellVariableKind.FIXED:
				result.set_vector(Vars.abs_pos, _body.position + cdir)
			elif s.follow and variable_kind == SpellVariableKind.TIMED:
				result.set_vector(Vars.rel_pos, _body.position + cdir)
		elif entity == Entity.TARGET:
			if variable_kind == SpellVariableKind.FIXED:
				result.set_vector(Vars.abs_pos, (_body as TargetShape).caster_position + cdir)
			elif s.follow and variable_kind == SpellVariableKind.TIMED:
				result.set_vector(Vars.rel_pos, (_body as TargetShape).caster_position + cdir)
	
	
	if p != null and (not is_timed or s.variable_update_set_contains(Spell.VariableUpdateSet.IJK) or s.variable_update_set_contains(Spell.VariableUpdateSet.rIJK)): # direction from character to spell
		var old_origin := Vector3(result.get_value(_IJK.x), result.get_value(_IJK.y), result.get_value(_IJK.z))
		var origin: Vector3
		if entity == Entity.TARGET:
			origin = old_origin.lerp(((_body as TargetShape).caster_position - p.position).normalized(), 0.0166667).normalized()
		else:
			origin = old_origin.lerp((_body.position - p.position).normalized(), 0.0166667).normalized()
		
		if not is_timed or s.variable_update_set_contains(Spell.VariableUpdateSet.IJK):
			result.set_vector(__IJK, origin)
			result.set_value(_IJK.x, origin.x)
			result.set_value(_IJK.y, origin.y)
			result.set_value(_IJK.z, origin.z)
		if not is_timed or s.variable_update_set_contains(Spell.VariableUpdateSet.rIJK):
			var rIJK := Vector3(Vector3(origin.x, 0, origin.z).signed_angle_to(Vector3(1, 0, 0), Vector3.UP), origin.signed_angle_to(Vector3(0, 1, 0), Vector3.UP), Vector3(origin.x, 0, origin.z).signed_angle_to(Vector3(0, 0, 1), Vector3.UP))
			result.set_vector(__rIJK, rIJK)
			result.set_value(_rIJK.x, rIJK.x)
			result.set_value(_rIJK.y, rIJK.y)
			result.set_value(_rIJK.z, rIJK.z)
	
func get_direction_to_tracking(body: Node3D, p: SpellBody, default: Vector3) -> Vector3:
	if p == null or p.tracking_target == null:
		return default
		
	var t: Node3D = p.tracking_target
	if !p.is_inside_tree() or !t.is_inside_tree():
		return default
		
	var position := p.tracking_position
	var offset := p.tracking_offset
	var vec: Vector3 = ((t.position + offset) - p.position).normalized()
	var dir: Vector3 = position.lerp(vec, 0.0166667).normalized()
	p.tracking_position = dir
	return dir
			
	
func all_spell_variables(body: Node3D, p: SpellBody, spell: Spell) -> Vars:
	var result := Vars.new()
	spell_variables(result, body, SpellVariableKind.FIXED, p, spell)
	spell_variables(result, body, SpellVariableKind.TIMED, p, spell)
	return result

## is_projection: when given an object will fill with turret nodes
func cast_spell(body: Node3D, vitals: Vitals, insert: Callable, spell: Spell, target: Node3D = null, inherited_vars: Vars = null, is_projection: Globals.Ref = null) -> MagicBook.DisallowSpellReason:
	if vitals != null:
		if vitals.mana.value >= spell.actual_mana_cost() or ignore_mana_cost:
			if is_projection == null:
				vitals.mana.apply_ignoring_resistance(-spell.actual_mana_cost())
		else:
			return MagicBook.DisallowSpellReason.MANA
			
	var node_to_track: Node3D = null
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
		p.origin_node = origin_node
		p.tracking_target = node_to_track
		p.tracking_position = cdir
		p.tracking_offset = spell_offset
		p.caster_vitals = vitals
		p.complexity_id = cid
		particles.append(p)
		spell_variables(p.fixed_vars, body, SpellVariableKind.TIMED, p, p.spell)
		var delay := spell.calculate_delay(p.fixed_vars)
		if is_projection != null:
			var turret := start_projecting_particle(delay, body, p, insert)
			turret.projectile = p
			turret.spell_caster = self
			turret.body = body
			(is_projection.data as Array).append(turret)
		else:
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
	var q: SpellTurret = null
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
	insert.call(p)
	SignalBus.spell_added_to_world.emit(p)
	if q and q.get_parent():
		SpellBuffer.free_turrent(q)
		
func start_projecting_particle(delay: float, body: Node3D, p: SpellBody, insert: Callable) -> SpellTurret:
	var q := p.spell.get_turret(p.n, p.fixed_vars)
	insert.call(q)
	return q

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
		
