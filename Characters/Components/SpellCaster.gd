class_name SpellCaster

enum Entity { PLAYER, ENEMY, PROJECTILE }

var entity: Entity
var particles: Array = []
var ignore_mana_cost: bool

var tracking_node: Dictionary = {}
var tracking_position: Dictionary = {}
var tracking_offset: Dictionary = {}

func _init(e: Entity):
	entity = e
	ignore_mana_cost = true
	
func deferred_update(body, delta):
	call_deferred("update", body, delta)
	
func update(body, delta):
	var t := Time.get_unix_time_from_system()
	var should_remove := []
	for i in range(particles.size()):
		var p: SpellBody = particles[i]
		
		if p.is_active():
			spell_variables(p.fixed_vars, body, false, p)
			if entity == Entity.PLAYER:
				tracking_offset[p.name] = get_spell_tracking_offset(p.spell, p.fixed_vars)
			p.update_spell(t, p.fixed_vars)
			
		if p.has_expired(t):
			if p.spell.chain_cast_kind == Spell.ChainCastKind.END and p.spell.chain != null:
				p.cast_spell(func(np): if np != null: p.call_deferred("add_sibling", np), p.spell.chain)
			tracking_node.erase(p.name)
			should_remove.append(i)

	var idx = should_remove.size() - 1
	while idx >= 0:
		var i = should_remove[idx]
		particles[i].stop_emitting()
		particles.remove_at(i)
		idx -= 1
		

func spell_variables(result: Dictionary, body: Node3D, fixed: bool, p: SpellBody) -> Dictionary:
	var prefix := "" if fixed else "t"
	result[prefix + "x"] = body.position.x
	result[prefix + "y"] = body.position.y
	result[prefix + "z"] = body.position.z

	var cdir := Vector3.ZERO
	var track := Vector3.ZERO
	match entity:
		Entity.PLAYER:
			var cam_pivot := body.get_node("CamPivot")
			var cam := body.get_node("CamPivot/Arm/Lens")
			cdir = ((body.global_position + cam_pivot.position) - cam.global_position).normalized()
			track = get_direction_to_tracking(body, p, cdir)
			
		Entity.ENEMY:
			cdir = (body.player.global_position - (body.global_position + Vector3(0, 1.9, 0))).normalized()
		Entity.PROJECTILE:
			cdir = -body.velocity.normalized()
	
	result[prefix + "u"] = cdir.x
	result[prefix + "v"] = cdir.y
	result[prefix + "w"] = cdir.z
	
	result[prefix + "U"] = track.x
	result[prefix + "V"] = track.y
	result[prefix + "W"] = track.z
	
	var c := Vector3.ZERO 
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
	
	result["abs_pos" if fixed else "rel_pos"] = body.position
		
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
		if t is CollisionShape3D and t.is_inside_tree():
			var vec: Vector3 = ((t.global_position + offset) - p.global_position).normalized()
			var dir: Vector3 = lerp(position, vec, 0.0166667).normalized()
			tracking_position[p.name] = dir
			return dir
		elif t is Vector3:
			return t
		else:
			return default
			
	
func all_spell_variables(body: Node3D, p: SpellBody) -> Dictionary:
	var result := {}
	spell_variables(result, body, true, p)
	spell_variables(result, body, false, p)
	return result

func cast_spell(body: Node3D, vitals: Vitals, insert: Callable, spell: Spell):
	if vitals != null and not ignore_mana_cost:
		if vitals.mana.value >= spell.mana_cost:
			vitals.mana.apply_ignoring_resistance(spell.mana_cost)
		else:
			print("not enough mana")
			return
	
	var node_to_track = null
	var cdir = Vector3.ZERO
	if entity == Entity.PLAYER:
		var cam_pivot := body.get_node("CamPivot")
		var cam := body.get_node("CamPivot/Arm/Lens")
		var base: Vector3 = body.global_position + cam_pivot.position
		cdir = (base - cam.global_position).normalized()
		node_to_track = Navigator.get_ray_intersection(body, cam.global_position - Vector3.UP, cam.global_position - Vector3.UP + cdir * 500)
		if node_to_track == null:
			node_to_track = cdir
			
	# it's fine that a projectile doesn't have a target set yet at the start
	# since by default camera direction equals target direction at start
	var vars := all_spell_variables(body, null)
	var ps := spell.get_particles(vars)
	var spell_offset := get_spell_tracking_offset(spell, vars)
	for p in ps:
		particles.append(p)
		tracking_node[p.name] = node_to_track
		tracking_position[p.name] = cdir
		tracking_offset[p.name] = spell_offset
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
		spell_variables(p.fixed_vars, body, true, p)
	insert.call(p)

func set_up_collision(world: Node3D, p: SpellBody):
	var new_agent_rid: RID = NavigationServer3D.agent_create()
	var default_3d_map_rid: RID = world.get_world_3d().get_navigation_map()
	NavigationServer3D.agent_set_map(new_agent_rid, default_3d_map_rid)
	NavigationServer3D.agent_set_radius(new_agent_rid, 5)
	NavigationServer3D.agent_set_position(new_agent_rid, p.global_position)
