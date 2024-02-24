class_name Enemy
extends CharacterBody3D

var movement_target_position: Vector3 = Vector3.ZERO

var animator: AnimationPlayer
var animation_tree: AnimationTree
var animation_map: Dictionary

#@onready var walking_audio: AudioStreamPlayer3D = $MovementAudio
#var walking_tween: Tween = null

var velocity_movement: VelocityMovement

var spell_caster: SpellCaster
var invunerable := 0.0
var spell_movement: AttackPatterns.SpellMovement = null
var attack_sequence: AttackSequence = null

var player: Player
var vitals: Vitals
var current_path: PathStyle
var still_path: PathStyle
var current_attack: AttackPatterns
var level: float # Use float so it's easy to use in expressions. However, should only be whole numbers.
var is_dead: bool = false

var behavior_tick: float = 0
var spell_tick: float = 0

var index_in_population: int = -1
signal vital_update(index_in_population: int, vitals: Vitals)
@onready var health_bar: MeshInstance3D = $HealthBar
@onready var level_text: Label3D = $HealthBar/Level

@export var bounds: Vector3 = Vector3(1, 1, 1)

func _ready():
	spell_caster = SpellCaster.new(get_node("."), SpellCaster.Entity.ENEMY)
	current_path = PathStyle.new(randf()).circle(position, 15).speed(2)
	level_text.text = str(int(level))
	animation_map = {}
	animator = $AnimationPlayer
	animation_tree = $AnimationTree
	still_path = PathStyle.new().set_use_me_as_origin()
	
func add_impulse(impulse: Vector3):
	velocity_movement.impulse += impulse
	
func add_shake(amount: float):
	player.add_shake(amount)
	
func increment_ticks(delta: float):
	behavior_tick += delta
	spell_tick += delta
	invunerable = max(0.0, invunerable - delta)
		
func current_animation_is(animation: String) -> bool:
	var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
	var current := playback.get_current_node()
	return current == animation
	
func play_animation(animation: String):
	var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
	var current := playback.get_current_node()
	#if current == "on_hit" and playback.get_current_play_position() < playback.get_current_length():
		#return
	if current != "death" and current != animation:
		playback.travel(animation)

func can_move() -> bool:
#	var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
#	var current := playback.get_current_node()
	return is_zero_approx(invunerable) # and (current == "idle" or current == "walk" or current == "run")

func attack_state() -> AttackPatterns:
	return AttackPatterns.new([], [])

func _physics_process(delta: float):
	if player.magic_book.settings.is_paused:
		return
	
	increment_ticks(delta)
	
	var process_path: PathStyle = current_path
	if spell_movement and spell_movement.movement.state != AttackMovement.AMState.DONE:
		var movement_path := spell_movement.movement.current_path()
		if movement_path:
			process_path = movement_path
			
	var attack_sequence_movement_speed_time := NAN
	if attack_sequence and process_path == current_path:
		attack_sequence_movement_speed_time = attack_sequence.time
			
	var movement = velocity_movement.update(delta, vitals, process_path.movement_speed(attack_sequence_movement_speed_time), self)
	vital_update.emit(index_in_population, vitals)
	if not is_dead and vitals.health.value <= vitals.health.min_value:
		die()
	update_vitals_display()
	
	var is_on_floor_1_not_on_floor_2_else_check_0: int = 0
	if velocity_movement.impulse != Vector3.ZERO:
		velocity = movement["velocity"]
		move_and_slide()
	else:
		match process_path.mover:
			PathStyle.Mover.PHYSICS:
				velocity = movement["velocity"]
				move_and_slide()
			PathStyle.Mover.ABSOLUTE:
				var v: Vector3 
				var t: Vector3
				v = movement["absolute"]
				t = movement["target"]
				var g := Navigator.get_world_height(get_world_3d().direct_space_state, position.x, position.z)
				if (position.y < g):
					if process_path.coord_y == PathStyle.CoordY.GROUND or process_path.coord_y == PathStyle.CoordY.GROUND_AND_AIR:
						position.y = g
						t.y = 0
						v.y = 0
				elif (position.y > g):
					if process_path.coord_y == PathStyle.CoordY.GROUND or process_path.coord_y == PathStyle.CoordY.GROUND_AND_DIRT:
						position.y = g
						t.y = 0
						v.y = 0
				is_on_floor_1_not_on_floor_2_else_check_0 = 1 if abs(position.y - g) < 0.05 else 2
				velocity = Vector3(v.x, v.y + t.y, v.z)
				position += Vector3(v.x, v.y + t.y, v.z)
				
		if process_path.lookat == PathStyle.LookAt.PLAYER:
			var goal_position := position + velocity * 10
			look_at(lerp(player.position, goal_position, clamp(velocity.length() / 100.0, 0, 1)))

	var moved_into_during_movement = false
	var reset_spell_tick := false
	if behavior_tick >= Globals.behaviour_tick():
		update_behaviour()
		var is_done := Globals.Ref.new(false)
		var next_pos: Vector3
		if attack_sequence and process_path == current_path:
			reset_spell_tick = attack_sequence.update(behavior_tick, self, player, is_done)
			if attack_sequence.last_path:
				current_path = attack_sequence.last_path
				next_pos = attack_sequence.next_position
			else:
				current_path = still_path
				next_pos = position
			current_attack = attack_sequence.last_attack
		else:
			next_pos = process_path.next_position(self, player, is_done)
		if is_done.data and spell_movement:
			moved_into_during_movement = spell_movement.movement.state == AttackMovement.AMState.BEFORE
			spell_movement.movement.next_state()
			if spell_movement.movement.state == AttackMovement.AMState.DONE:
				spell_movement.movement.reset_state()
				spell_movement = null
		velocity_movement.target_position = Navigator.find_target(get_node("."), next_pos, 2.0, 2.0, bounds.length() * 2)
#		if velocity_movement.target_position != next_pos:
#			DebugDraw3D.draw_sphere(velocity_movement.target_position, 1, Color(1, 0, 0), 3)
#			DebugDraw3D.draw_sphere(next_pos, 1, Color(0, 1, 0), 3)
#			prints(velocity_movement.target_position, next_pos)
#		else:
#			print("---")
		behavior_tick = 0

	if reset_spell_tick or (spell_tick >= (1.0 + vitals.freeze.value) and vitals.stun.value == 0 and vitals.freeze.value < 1.0):
		if spell_movement == null or spell_movement.movement.state == AttackMovement.AMState.DONE:
			if attack_sequence:
				if attack_sequence.last_attack:
					spell_movement = current_attack.choose_spell(vitals)
			else:
				spell_movement = attack_state().choose_spell(vitals)
			moved_into_during_movement = spell_movement and spell_movement.movement.state == AttackMovement.AMState.DONE
		spell_tick = 0
		
	if moved_into_during_movement:
		if spell_movement:
			play_animation("attack")
			var spell = spell_movement.spell
			await get_parent_node_3d().get_tree().create_timer(animator.get_animation(animation_map["attack"]).length / 2.0).timeout
			await get_tree().physics_frame
			cast_spell(func(p): if p != null: call_deferred("add_sibling", p), spell)
		

	spell_caster.update(self, delta)
	var final_is_on_floor: bool
	if is_on_floor_1_not_on_floor_2_else_check_0 == 0:
		final_is_on_floor = is_on_floor()
	else:
		final_is_on_floor = is_on_floor_1_not_on_floor_2_else_check_0 == 1
		
	if velocity != Vector3.ZERO:
		if final_is_on_floor:
			if velocity.length() < 1:
				#play_walking_audio(NoiseBlender.walking_audio_for_biome(current_biome))
				play_animation("walk")
			else:
				#play_walking_audio(NoiseBlender.walking_audio_for_biome(current_biome))
				play_animation("run")
	else:
		if final_is_on_floor:
			play_walking_audio(null)
			play_animation("idle")
		
	if not final_is_on_floor:
		play_animation("fall")
	elif current_animation_is("fall"):
		play_animation("land")


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
	is_dead = true
	var explosion: Node3D = preload("res://Characters/Enemy/enemy_die.tscn").instantiate()
	var source = explosion.get_node("source")
	source.process_material.emission_box_extents = death_box()
	
	SignalBus.enemy_death.emit(get_node("."))
		
	play_animation("death")
	
	var world := get_parent_node_3d()
	await world.get_tree().create_timer(animator.get_animation("Death").length + 0.1).timeout
	player.ignore_enemy(get_node("."))
	explosion.position = position
	explosion.global_transform = global_transform
	world.add_child(explosion)
	source.emitting = true
	spell_caster.free_particles()
	drop_artifact_item(world)
	drop_spell_item(world)
	
	queue_free()
	await world.get_tree().create_timer(Globals.particle_system_lifetime(source)).timeout
	world.remove_child(explosion)
	
		
func drop_artifact_item(world: Node3D):
	var artifact: Artifact = drop_artifact()
	if artifact:
		var item = preload("res://Models/Misc/Cube.tscn").instantiate()
		item.position = position
		item.global_transform = global_transform
		item.artifact = artifact
		world.add_child(item)
		
		
func drop_spell_item(world: Node3D):
	var spell: Spell = drop_spell()
	if spell:
		var item = preload("res://Models/Misc/Paper.tscn").instantiate()
		item.position = position
		item.global_transform = global_transform
		item.spell = spell
		world.add_child(item)
		
	
func update_vitals_display():
	health_bar.mesh.surface_get_material(0).set_shader_parameter("percentage", vitals.health.percentage())

func drop_artifact() -> Artifact:
	return null
	
func drop_spell() -> Spell:
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
	elif n is Fish:
		return World.Enemy.FISH
	elif n is Birdman:
		return World.Enemy.BIRDMAN
	
	return World.Enemy.NONE

func play_walking_audio(stream: AudioStream):
	pass
	#if walking_audio.stream == null or walking_audio.stream != stream or walking_tween:
		#if stream != null:
			#if walking_tween:
				#walking_tween.kill()
				#walking_tween = null
			#walking_audio.stream = stream
			#walking_audio.volume_db = 0
			#walking_audio.play()
		#elif walking_audio.stream != null and not walking_tween:
			#walking_tween = create_tween()
			#walking_tween.tween_property(walking_audio, "volume_db", -80, 2)
			#walking_tween.tween_callback(func(): 
				#walking_audio.stop()
				#walking_audio.stream = null
				#walking_tween.kill()
				#walking_tween = null
			#)
