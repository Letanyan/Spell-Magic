class_name SpellCaster

enum Entity { PLAYER, ENEMY, PROJECTILE }

var entity: Entity
var particles: Array = []
var ignore_mana_cost: bool

var tracking_node: Dictionary = {}
var tracking_position: Dictionary = {}
var tracking_offset: Dictionary = {}

signal projectile_hit
signal not_enough_mana_for_spell

func _init(e: Entity):
	entity = e
	ignore_mana_cost = false
	
func deferred_update(body, delta):
	call_deferred("update", body, delta)
	
func update(body, delta):
	var t := Time.get_unix_time_from_system()
	var should_remove := []
	for i in range(particles.size()):
		var p: SpellBody = particles[i]
		
		if p.is_active():
			spell_variables(p.fixed_vars, body, false, p, p.spell)
			if entity == Entity.PLAYER:
				tracking_offset[p.name] = get_spell_tracking_offset(p.spell, p.fixed_vars)
			p.update_spell(t, p.fixed_vars)
			
		if p.has_expired(t):
			if p.spell.chain_cast_kind == Spell.ChainCastKind.END and p.spell.chain != null:
				p.cast_spell(func(np): if np != null: p.call_deferred("add_sibling", np), p.spell.chain, null)
			tracking_node.erase(p.name)
			should_remove.append(i)

	var idx = should_remove.size() - 1
	while idx >= 0:
		var i = should_remove[idx]
		particles[i].stop_emitting()
		particles.remove_at(i)
		idx -= 1
		

func spell_variables(result: Dictionary, body: Node3D, fixed: bool, p: SpellBody, s: Spell) -> Dictionary:
	var prefix := "" if fixed else "t"

	var cdir := Vector3.ZERO
	var track := Vector3.ZERO # direction to enemy that was hit by raycast 
	match entity:
		Entity.PLAYER:
			var port := body.get_viewport()
			var pos := port.get_visible_rect().size / 2.0
			cdir = port.get_camera_3d().project_ray_normal(pos)
			track = get_direction_to_tracking(body, p, cdir)
			
		Entity.ENEMY:
			cdir = (body.player.global_position - (body.global_position + Vector3(0, 1.9, 0))).normalized() # direction to player
			result["l"] = body.level
			result["fl"] = body.level / 100.0
			
		Entity.PROJECTILE:
			cdir = -body.velocity.normalized() 
			if p != null:
				var hit_on := (body.position - p.position).normalized()
				track = get_direction_to_tracking(body, p, hit_on)
	
	result[prefix + "u"] = cdir.x
	result[prefix + "v"] = cdir.y
	result[prefix + "w"] = cdir.z
	result[prefix + "ru"] = cdir.signed_angle_to(Vector3(1, 0, 0), Vector3.UP)
	result[prefix + "rv"] = cdir.signed_angle_to(Vector3(0, 1, 0), Vector3.UP)
	result[prefix + "rw"] = cdir.signed_angle_to(Vector3(0, 0, 1), Vector3.UP)
	
	result[prefix + "U"] = track.x
	result[prefix + "V"] = track.y
	result[prefix + "W"] = track.z
	
	var c := Vector3.ZERO # character facing direction
	match entity:
		Entity.PLAYER:
			c = Vector3(0, 0, -1).rotated(Vector3.UP, body.get_node("Pivot").rotation.y)
		Entity.ENEMY:
			c = Vector3(0, 0, -1).rotated(Vector3.UP, body.rotation.y)
		Entity.PROJECTILE:
			c = body.velocity.normalized()
	result[prefix + "cx"] = c.x
	result[prefix + "cy"] = c.y
	result[prefix + "cz"] = c.z
	result[prefix + "rcx"] = c.signed_angle_to(Vector3(1, 0, 0), Vector3.UP)
	result[prefix + "rcy"] = c.signed_angle_to(Vector3(0, 1, 0), Vector3.UP)
	result[prefix + "rcz"] = c.signed_angle_to(Vector3(0, 0, 1), Vector3.UP)
	
	if s.player_is_origin:
		if entity == Entity.PLAYER:
			var port := body.get_viewport()
			var pos := port.get_visible_rect().size / 2.0
			result["abs_pos" if fixed else "rel_pos"] = port.get_camera_3d().project_ray_origin(pos)
		else:
			result["abs_pos" if fixed else "rel_pos"] = body.position + cdir
	else:
		result["abs_pos" if fixed else "rel_pos"] = body.position
	
	if p != null: # direction from character to spell
		var old_origin = Vector3(result.get(prefix + "X", 0), result.get(prefix + "Y", 0), result.get(prefix + "Z", 0) )
		var origin = lerp(old_origin, (body.position - p.position).normalized(), 0.0166667).normalized()
		result[prefix + "X"] = origin.x
		result[prefix + "Y"] = origin.y
		result[prefix + "Z"] = origin.z
		
	return result
	
func get_direction_to_tracking(body: Node3D, p: SpellBody, default: Vector3) -> Vector3:
	if p == null:
		return default
	if tracking_node == null:
		return default
	else:
		var t = tracking_node.get(p.name, null)
		var position = tracking_position.get(p.name, Vector3.ZERO)
		var offset = tracking_offset.get(p.name, Vector3.ZERO)
		if t == null or !p.is_inside_tree():
			return default
		if t is Node3D and t.is_inside_tree():
			var vec: Vector3 = ((t.global_position + offset) - p.global_position).normalized()
			var dir: Vector3 = lerp(position, vec, 0.0166667).normalized()
			tracking_position[p.name] = dir
			return dir
		elif t is Vector3:
			return t
		else:
			return default
			
	
func all_spell_variables(body: Node3D, p: SpellBody, spell: Spell) -> Dictionary:
	var result := {}
	spell_variables(result, body, true, p, spell)
	spell_variables(result, body, false, p, spell)
	return result

func cast_spell(body: Node3D, vitals: Vitals, insert: Callable, spell: Spell, target: Node3D = null, inherited_vars: Dictionary = {}):
	if vitals != null:
		if vitals.mana.value >= spell.actual_mana_cost() or ignore_mana_cost:
			vitals.mana.apply_ignoring_resistance(-spell.actual_mana_cost())
		else:
			not_enough_mana_for_spell.emit(spell)
			return
			
	var node_to_track = null
	var cdir = Vector3.ZERO
	if entity == Entity.PLAYER:
		var port := body.get_viewport()
		var pos := port.get_visible_rect().size / 2.0
		var coord := port.get_camera_3d().project_ray_origin(pos)
		cdir = port.get_camera_3d().project_ray_normal(pos)
		node_to_track = Navigator.get_ray_intersection(body, coord, coord + cdir * 500)
		if node_to_track == null:
			node_to_track = cdir
	elif entity == Entity.PROJECTILE:
		node_to_track = target
			
			
	# it's fine that a projectile doesn't have a target set yet at the start
	# since by default camera direction equals target direction at start
	var vars := all_spell_variables(body, null, spell)
	if inherited_vars.has("l"): # copy enemy level vars
		vars["l"] = inherited_vars["l"]
		vars["fl"] = inherited_vars["fl"]
	var ps := spell.get_particles(vars)
	var spell_offset := get_spell_tracking_offset(spell, vars)
	for p in ps:
		p.name += str(randi())
		particles.append(p)
		tracking_node[p.name] = node_to_track
		tracking_position[p.name] = cdir
		tracking_offset[p.name] = spell_offset
		spell_variables(p.fixed_vars, body, false, p, p.spell)
		var delay := spell.calculate_delay(p.fixed_vars)
		start_particle(delay, body, p, insert)
		
func get_spell_tracking_offset(spell: Spell, vars: Dictionary) -> Vector3:
	var temp := vars.duplicate()
	temp["U"] = 0.0
	temp["V"] = 0.0
	temp["W"] = 0.0
	temp["tU"] = 0.0
	temp["tV"] = 0.0
	temp["tW"] = 0.0
	return spell.calculate_location(temp, true)
	

func start_particle(delay: float, body: Node3D, p: SpellBody, insert: Callable):
	await body.get_tree().create_timer(delay, false, true).timeout
	p.time_start = Time.get_unix_time_from_system()
	if not p.spell.is_bomb:
		spell_variables(p.fixed_vars, body, true, p, p.spell)
	p.projectile_hit.connect(pass_projectile_hit)
	insert.call(p)

func set_up_collision(world: Node3D, p: SpellBody):
	var new_agent_rid: RID = NavigationServer3D.agent_create()
	var default_3d_map_rid: RID = world.get_world_3d().get_navigation_map()
	NavigationServer3D.agent_set_map(new_agent_rid, default_3d_map_rid)
	NavigationServer3D.agent_set_radius(new_agent_rid, 5)
	NavigationServer3D.agent_set_position(new_agent_rid, p.global_position)

func pass_projectile_hit(spell: Spell, time: float):
	projectile_hit.emit(spell, time)

func free_particles():
	for p in particles:
		p.free_particle()
	particles.clear()
