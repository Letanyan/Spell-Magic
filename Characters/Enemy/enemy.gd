class_name Enemy
extends CharacterBody3D

var movement_target_position: Vector3 = Vector3.ZERO

@export var speed = 14
@export var fall_acceleration: float = 75
@export var friction = 25
@export var jump_impulse = 20

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var target_velocity = Vector3.ZERO
var impulse = Vector3.ZERO

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

	behaviour = Behaviour.new(
		PathStyle.new(blender, get_rid().get_id()).circle(position, 15),
		PathStyle.new(blender, get_rid().get_id()).follow_player(5, 10)
	)
	behaviour.update_state(self, player)
	
	vitals = Vitals.new(100, 50)
	
	patterns = AttackPatterns.new(
		[
			Spell.new(false, "u * t * 5", "v * t * 5", "w * t * 5", "1", 0.1, 5000, Spell.Element.FIRE, 1),
			Spell.new(false, "u * t * 5", "v * t * 5", "w * t * 5", "1", 0.1, 5000, Spell.Element.WATER, 1),
			Spell.new(false, "u * t * 5", "v * t * 5", "w * t * 5", "1", 0.1, 5000, Spell.Element.ROCK, 1),
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

func interval_check(interval: int, epsilon: int):
	var t = Time.get_ticks_msec() % interval
	return t < epsilon
	

func _physics_process(delta):
	if not navigation_agent.is_navigation_finished():
		var current_agent_position: Vector3 = global_transform.origin
		var next_path_position: Vector3 = navigation_agent.get_next_path_position()

		var new_velocity: Vector3 = next_path_position - current_agent_position
		new_velocity = new_velocity.normalized()
		new_velocity = new_velocity * behaviour.movement_speed()

		set_velocity(new_velocity)
		move_and_slide()
		if interval_check(250, 50):
			behaviour.update_state(self, player)
			set_movement_target(behaviour.next_position(self, player))
		if interval_check(100, 20):
			var spell = patterns.choose_spell(0.5 if behaviour.is_aggresive() else 0.0)
			if spell != null:
				await cast_spell(func(p): if p != null: add_sibling(p), spell)
	else:
		if interval_check(250, 50):
			set_movement_target(behaviour.next_position(self, player))

	
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	else:
		target_velocity.y = 0
		
	target_velocity.y = clampf(target_velocity.y, -100, 100)
	target_velocity.x = clampf(target_velocity.x, -100, 100)
	target_velocity.z = clampf(target_velocity.z, -100, 100)
	
	if absf(impulse.length()) > 1:
		var nor = impulse.normalized()
		var fri = friction * delta 
		impulse = Vector3(
			impulse.x - nor.x * fri,
			impulse.y - nor.y * fri,
			impulse.z - nor.z * fri,
		)
	else:
		impulse.x = 0
		impulse.y = 0
		impulse.z = 0
	
	velocity = target_velocity + impulse
	move_and_slide()
				
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
	else:
		result["rel_pos"] = position
	
	return result
	

func cast_spell(insert: Callable, spell: Spell):
	var vars = spell_variables(true)
	var ps = spell.get_particles(spell_variables(true))
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
			p.fixed_vars["abs_pos"] = position
			var cdir = (player.global_position - (global_position + Vector3(0, 1.2, 0))).normalized()
			p.fixed_vars["u"] = cdir.x
			p.fixed_vars["v"] = cdir.y
			p.fixed_vars["w"] = cdir.z
		insert.call(p)
