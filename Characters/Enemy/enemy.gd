class_name Enemy
extends CharacterBody3D

var movement_speed: float = 2.0
var movement_target_position: Vector3 = Vector3(-3.0,0.0,2.0)

@export var speed = 14 * 8
@export var fall_acceleration = 75
@export var friction = 25
@export var jump_impulse = 20

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
#@onready var navigation_agent: NavigationAgent3D = NavigationAgent3D.new()

var target_velocity = Vector3.ZERO
var impulse = Vector3.ZERO

var spells: Array = []
var particles: Array = []

var player: Player
var blender: NoiseBlender
var state: StateManager

func _ready():
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5

	state = StateManager.new(
		PathStyle.new(blender).circle(position, 15),
		PathStyle.new(blender).circle_player(5)
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
		new_velocity = new_velocity * movement_speed

		set_velocity(new_velocity)
		move_and_slide()
		if interval_check(1000, 100):
			state.update_state(self, player)
			set_movement_target(state.next_position(player))
		return
	else:
		if interval_check(1000, 100):
			set_movement_target(state.next_position(player))

	
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
				
	var t = Time.get_ticks_msec()
	var should_remove = []
	for i in range(spells.size()):
		var p: SpellBody = particles[i]
		var spell: Spell = spells[i]
		spell.update_spell(t, spell_variables(false), p)
		if spell.has_expired(t):
			should_remove.append(i)
			p.stop_emitting()
			
	should_remove.reverse()
	for i in should_remove:
		spells.remove_at(i)
		particles.remove_at(i)

func spell_variables(fixed: bool) -> Dictionary:
	var result = Dictionary()
	var prefix = "" if fixed else "t"
	result[prefix + "x"] = position.x
	result[prefix + "y"] = position.y
	result[prefix + "z"] = position.z
	
	var cdir = ((global_position + Vector3(0, 1.2, 0)) - player.global_position).normalized()
	
	result[prefix + "u"] = cdir.x
	result[prefix + "v"] = cdir.y
	result[prefix + "w"] = cdir.z
	
	if fixed:
		result["abs_pos"] = position
	else:
		result["rel_pos"] = position
	
	return result
	

func cast_spell(spell: Spell) -> SpellBody:
	spells.append(spell)
	var p = spell.get_particle()
	p.spell = spell
	particles.append(p)
	return p
