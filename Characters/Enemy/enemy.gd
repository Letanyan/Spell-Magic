class_name Enemy
extends CharacterBody3D

var movement_target_position: Vector3 = Vector3.ZERO

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var velocity_movement = VeloctyMovement.new()

var spell_caster = SpellCaster.new(SpellCaster.Entity.ENEMY)

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
	
	if interval_check(500, 10):
		var spell = patterns.choose_spell(0.5 if behaviour.is_aggresive() else 0)
		if spell != null:
			cast_spell(func(p): if p != null: add_sibling(p), spell)
		
	spell_caster.update(self, delta)

func cast_spell(insert: Callable, next_spell: Spell):
	spell_caster.cast_spell(self, insert, next_spell)
