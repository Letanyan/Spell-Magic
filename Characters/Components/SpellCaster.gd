class_name SpellCaster

enum Entity { PLAYER, ENEMY, PROJECTILE }

var entity: Entity
var particles: Array = []
var ignore_mana_cost: bool

func _init(e: Entity):
	entity = e
	ignore_mana_cost = true
	
func deferred_update(body, delta):
	call_deferred("update", body, delta)
	
func update(body, delta):
	var t = Time.get_unix_time_from_system()
	var should_remove = []
	for i in range(particles.size()):
		var p: SpellBody = particles[i]
		p.update_spell(t, spell_variables(body, false))
		if p.has_expired(t):
			if p.spell.chain_cast_kind == Spell.ChainCastKind.END and p.spell.chain != null:
				p.cast_spell(func(np): if np != null: p.call_deferred("add_sibling", np), p.spell.chain)
			should_remove.append(i)

	should_remove.reverse()
	for i in should_remove:
		particles[i].stop_emitting()
		particles.remove_at(i)
		

func spell_variables(body: Node3D, fixed: bool) -> Dictionary:
	var result = Dictionary()
	var prefix = "" if fixed else "t"
	result[prefix + "x"] = body.position.x
	result[prefix + "y"] = body.position.y
	result[prefix + "z"] = body.position.z

	var cdir = Vector3.ZERO
	match entity:
		Entity.PLAYER:
			var cam_pivot = body.get_node("CamPivot")
			var cam = body.get_node("CamPivot/Arm/Lens")
			cdir = ((body.global_position + cam_pivot.position) - cam.global_position).normalized()
		Entity.ENEMY:
			cdir = (body.player.global_position - (body.global_position + Vector3(0, 1.9, 0))).normalized()
		Entity.PROJECTILE:
			cdir = -body.velocity.normalized()
	
	result[prefix + "u"] = cdir.x
	result[prefix + "v"] = cdir.y
	result[prefix + "w"] = cdir.z
	
	var c = Vector3.ZERO 
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
	
func all_spell_variables(body: Node3D):
	var result = spell_variables(body, true)
	result.merge(spell_variables(body, false))
	return result

func cast_spell(body: Node3D, vitals: Vitals, insert: Callable, spell: Spell):
	if vitals != null and not ignore_mana_cost:
		if vitals.mana.value >= spell.mana_cost:
			vitals.mana.apply_ignoring_resistance(spell.mana_cost)
		else:
			print("not enough mana")
			return
	var vars = all_spell_variables(body)
	var ps = spell.get_particles(vars)
	for p in ps:
		particles.append(p)
		var temps_vars = vars.duplicate()
		temps_vars["n"] = p.n
		var delay = spell.calculate_delay(temps_vars)
		start_particle(delay, body, p, insert)
		

func start_particle(delay: float, body: Node3D, p: SpellBody, insert: Callable):
	await body.get_tree().create_timer(delay, false, true).timeout
	p.time_start = Time.get_unix_time_from_system()
	if not p.spell.is_bomb:
		p.fixed_vars.merge(spell_variables(body, true), true)
	insert.call(p)

func set_up_collision(world: Node3D, p: SpellBody):
	var new_agent_rid: RID = NavigationServer3D.agent_create()
	var default_3d_map_rid: RID = world.get_world_3d().get_navigation_map()
	NavigationServer3D.agent_set_map(new_agent_rid, default_3d_map_rid)
	NavigationServer3D.agent_set_radius(new_agent_rid, 5)
	NavigationServer3D.agent_set_position(new_agent_rid, p.global_position)
