class_name Enemy
extends CharacterBody3D

var movement_target_position: Vector3 = Vector3.ZERO

var animator: AnimationPlayer
var animation_tree: AnimationTree
var animation_map: Dictionary

var velocity_movement: VelocityMovement

var spell_caster = SpellCaster.new(SpellCaster.Entity.ENEMY)
var invunerable := 0

var player: Player
var behaviour: Behaviour
var vitals: Vitals
var knowledge: Knowledge
var hormones: Hormones
var current_path: PathStyle
var level: float # Use float so it's easy to use in expressions. However, should only be whole numbers.

var behavior_tick: int = 0
var spell_tick: int = 0

var index_in_population: int = -1
signal vitals_signal
signal on_death(artifact_drop: Artifact)
@onready var health_bar: MeshInstance3D = $HealthBar
@onready var level_text: Label3D = $HealthBar/Level

var stored_entity_knowledge: Dictionary = {}

var action_state: Knowledge.Action
var action_is_satisfied: bool = true
var choices: Dictionary = {}

func _ready():
	current_path = PathStyle.new(randf()).circle(position, 15).speed(2)
	choices = {}
	level_text.text = str(int(level))
	animation_map = {}
	if not self is Human:
		animator = $AnimationPlayer
		animation_tree = $AnimationTree
		
		
func update_stored_entity_knowledge():
	for e in stored_entity_knowledge:
		knowledge.direct_entry(e, stored_entity_knowledge[e])
	
func add_impulse(impulse: Vector3):
	velocity_movement.impulse += impulse
	
func add_shake(amount: float):
	player.add_shake(amount)
	
func increment_ticks():
	behavior_tick += 1
	spell_tick += 1
	if invunerable > 0:
		invunerable -= 1
	
func play_animation(animation: String):
	var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
	var current := playback.get_current_node()
	if current != "death" and current != animation:
		playback.travel(animation)

func can_move() -> bool:
#	var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
#	var current := playback.get_current_node()
	return invunerable == 0 # and (current == "idle" or current == "walk" or current == "run")

func attack_state() -> AttackPatterns:
	return AttackPatterns.new([], [], false)

func _physics_process(delta):
	increment_ticks()

	var movement = velocity_movement.update(delta, vitals, current_path.movement_speed, self)
	vitals_signal.emit(index_in_population, vitals)
	if vitals.health.value <= vitals.health.min_value:
		die()
	update_vitals_display()
	
	if velocity_movement.impulse != Vector3.ZERO:
		velocity = movement["velocity"]
		move_and_slide()
	else:
		match current_path.mover:
			PathStyle.Mover.PHYSICS:
				velocity = movement["velocity"]
				move_and_slide()
			PathStyle.Mover.ABSOLUTE:
				velocity = movement["absolute"]
				position += movement["absolute"]
			PathStyle.Mover.ABSOLUTE_XZ:
				var v: Vector3 
				var t: Vector3
				v = movement["absolute"]
				t = movement["target"]
				var g := Navigator.get_world_height(get_world_3d().direct_space_state, position.x, position.z)
				if position.y < g or position.y > g:
					position.y = g
					t.y = 0
					v.y = 0
				velocity = Vector3(v.x, v.y + t.y, v.z)
				position += Vector3(v.x, v.y + t.y, v.z)
		if current_path.lookat == PathStyle.LookAt.PLAYER:
			var goal_position := position + velocity * 10
			look_at(lerp(player.position, goal_position, clamp(velocity.length() / 100.0, 0, 1)))

	if behavior_tick == 30:
		update_behaviour()
		var next_pos := current_path.next_position(self, player)
		velocity_movement.target_position = Navigator.find_target(get_node("."), next_pos)
#		if velocity_movement.target_position != next_pos:
#			prints(velocity_movement.target_position, next_pos)
#		else:
#			print("---")
		behavior_tick = 0

	if spell_tick >= int(30 * (1.0 + vitals.freeze.value)) and vitals.stun.value == 0 and vitals.freeze.value < 1.0:
		var spell := attack_state().choose_spell(vitals, behaviour)
		if spell != null:
			play_animation("attack")
			await get_parent_node_3d().get_tree().create_timer(animator.get_animation(animation_map["attack"]).length / 2.0).timeout
			await get_tree().physics_frame
			cast_spell(func(p): if p != null: call_deferred("add_sibling", p), spell)
		spell_tick = 0

	spell_caster.update(self, delta)

	if velocity != Vector3.ZERO:
		if velocity.length() > 5:
			play_animation("run")
		else:
			play_animation("walk")
	else:
		play_animation("idle")


func cast_spell(insert: Callable, next_spell: Spell):
	spell_caster.cast_spell(self, vitals, insert, next_spell)

func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.ENEMY, position)

func update_entity_info(info: EntityInfo) -> bool:
	info.position = position
	return true

func update_behaviour():
	pass

func handle_damage():
	pass
	
func death_box() -> Vector3:
	return Vector3(1, 1, 1)
	
func die():
	var explosion: Node3D = preload("res://Characters/Enemy/enemy_die.tscn").instantiate()
	var source = explosion.get_node("source")
	source.process_material.emission_box_extents = death_box()
	
	on_death.emit(get_node("."), drop_artifact())
		
	play_animation("death")
	
	var world := get_parent_node_3d()
	await world.get_tree().create_timer(animator.get_animation("Death").length + 0.1).timeout
	explosion.position = position
	explosion.global_transform = global_transform
	world.add_child(explosion)
	source.emitting = true
	spell_caster.free_particles()
	queue_free()
	await world.get_tree().create_timer(Globals.particle_system_lifetime(source)).timeout
	world.remove_child(explosion)
	
func update_vitals_display():
	health_bar.mesh.surface_get_material(0).set_shader_parameter("percentage", vitals.health.percentage())

func update_state():
	update_action_is_satisfied()
	if randf() < (0.9 if action_is_satisfied else 0.01):
		var has_updated := false
		var actions: Dictionary = knowledge.actions
		
		if knowledge.has_been_updated:
			knowledge.has_been_updated = false
			actions = knowledge.actions_list()
			
		var total_weight := 0.0
		for action_key in actions:
			var action = actions[action_key]
			var w := hormones.weight_for_action(action, vitals)
			total_weight += w
			choices[action] = w
		for action in choices:
			choices[action] = choices[action] / total_weight
		var new_state = Population.random_entity_from_distribution(randf(), choices)
		
		if new_state != action_state:
			action_state = new_state
			has_updated = true
			action_is_satisfied = false
		else:
			has_updated = false
				
		if action_is_satisfied:
			hormones.update_from_action(action_state)
			vitals.update_from_action(action_state)
				
		return has_updated
	else:
		return false
		
func update_action_is_satisfied():
	if action_state == null:
		action_is_satisfied = true
		return
	match action_state.kind:
		Knowledge.ActionKind.WALK:
			action_is_satisfied = true
		Knowledge.ActionKind.DRINK:
			action_is_satisfied = action_state.entity.position.distance_to(position) <= action_state.entity.bounds.shape.radius * 2

func drop_artifact() -> Artifact:
	return null

func world_enemy_enum() -> World.Enemy:
	var n = get_node(".")
	if n is Undead:
		return World.Enemy.UNDEAD
	elif n is Mole:
		return World.Enemy.MOLE
	elif n is Walker:
		return World.Enemy.WALKER
	elif n is Bat:
		return World.Enemy.BAT
	
	return World.Enemy.NONE
