class_name Enemy
extends CharacterBody3D

var movement_target_position: Vector3 = Vector3.ZERO

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var velocity_movement = VeloctyMovement.new()

var particles: Array = []

var player: Player
var blender: NoiseBlender
var behaviour: Behaviour
var vitals: Vitals
var patterns: AttackPatterns

func _ready():
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5
	velocity_movement.navigation_agent = navigation_agent

	behaviour = Behaviour.new(
		PathStyle.new(blender, get_rid().get_id()).circle(position, 15),
		PathStyle.new(blender, get_rid().get_id()).follow_player(5, 10)
	)
	behaviour.update_state(self, player)
	
	vitals = Vitals.new(100, 50)
	
	patterns = AttackPatterns.new(
		[
			Spell.new(false, "u * t * 5", "v * t * 5 + 2", "w * t * 5", "1", 0.1, 5000, Spell.Element.FIRE, 1),
			Spell.new(false, "u * t * 5", "v * t * 5 + 2", "w * t * 5", "1", 0.1, 5000, Spell.Element.WATER, 1),
			Spell.new(false, "u * t * 5", "v * t * 5 + 2", "w * t * 5", "1", 0.1, 5000, Spell.Element.ROCK, 1),
		],
		[
			5,
			3,
			2,
		]
	)

	# Make sure to not await during _ready.
	call_deferred("actor_setup")

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame

	# Now that the navigation map is no longer empty, set the movement target.
	set_movement_target(movement_target_position)

func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)
	
func apply_impulse(impulse: Vector3):
	velocity_movement.impulse += impulse

func interval_check(interval: int, epsilon: int):
	var t = Time.get_ticks_msec() % interval
	return t < epsilon
	

func _physics_process(delta):
	var movement = velocity_movement.update(delta, vitals, behaviour.movement_speed(), self)
	velocity = movement["velocity"]
	move_and_slide()
		
	if interval_check(250, 50):
		behaviour.update_state(self, player)
		var next_pos = behaviour.next_position(self, player)
		set_movement_target(next_pos)
		
	var t = Time.get_unix_time_from_system()
	var should_remove = []
	for i in range(particles.size()):
		var p: SpellBody = particles[i]
		p.update_spell(t, spell_variables(false))
		if p.has_expired(t):
			should_remove.append(i)
			p.stop_emitting()
			
	should_remove.reverse()
	for i in should_remove:
		particles.remove_at(i)

func spell_variables(fixed: bool) -> Dictionary:
	var result = Dictionary()
	var prefix = "" if fixed else "t"
	result[prefix + "x"] = position.x
	result[prefix + "y"] = position.y
	result[prefix + "z"] = position.z
	
#	var cdir = ((global_position + Vector3(0, 1.2, 0)) - player.global_position).normalized()
	var cdir = (player.global_position - (global_position + Vector3(0, 1.2, 0))).normalized()
	
	result[prefix + "u"] = cdir.x
	result[prefix + "v"] = cdir.y
	result[prefix + "w"] = cdir.z
	
	if fixed:
		result["abs_pos"] = position
		var c = Vector3(0, 0, -1).rotated(Vector3.UP, rotation.y)
		result["cx"] = c.x
		result["cy"] = c.y
		result["cz"] = c.z
	else:
		result["rel_pos"] = position
		var c = Vector3(0, 0, -1).rotated(Vector3.UP, rotation.y)
		result["tcx"] = c.x
		result["tcy"] = c.y
		result["tcz"] = c.z
	
	return result
	
func all_spell_variables():
	var result = spell_variables(true)
	result.merge(spell_variables(false))
	return result

func cast_spell(insert: Callable, spell: Spell):
	var vars = all_spell_variables()
	var ps = spell.get_particles(vars)
	for p in ps:
		particles.append(p)
		var temps_vars = vars.duplicate()
		temps_vars["n"] = p.n
		var delay = spell.calculate_delay(temps_vars)
		get_tree().create_timer(delay).connect("timeout", start_particle(p, insert))
		

func start_particle(p: SpellBody, insert: Callable):
	return func():
		p.time_start = Time.get_unix_time_from_system()
		if not p.spell.is_bomb:
			p.fixed_vars.merge(spell_variables(true), true)
		insert.call(p)
