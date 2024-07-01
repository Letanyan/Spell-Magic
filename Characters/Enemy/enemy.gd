class_name Enemy
extends CharacterBody

var animator: AnimationPlayer
var animation_tree: AnimationTree
var animation_map: Dictionary # [String]String

#@onready var walking_audio: AudioStreamPlayer3D = $MovementAudio
#var walking_tween: Tween = null

var spell_caster: SpellCaster
var attack_sequence: AttackSequence = null

var player: Player
var current_path: PathStyle
var still_path: PathStyle
var current_attack: AttackPatterns
var level: float # Use float so it's easy to use in expressions. However, should only be whole numbers.
var is_dead: bool = false
var kind: World.Enemy = World.Enemy.NONE

var behavior_tick: float = 0
var spell_tick: float = 0
var idle_tick: float = 0
var speed_for_current_behaviour_tick := 0.0
var path_movement_remaining_duration := 0.0
var time_since_navigation_update := NAN

var index_in_population: int = -1
signal vital_update(index_in_population: int, vitals: Vitals)
@onready var health_bar: MeshInstance3D = $HealthBar/Bar
@onready var level_text: Label3D = $HealthBar/Level

func _ready() -> void:
	spell_caster = SpellCaster.new(get_node(".") as Node3D, SpellCaster.Entity.ENEMY)
	still_path = PathStyle.still_path()
	current_path = still_path
	level_text.text = str(int(level))
	animation_map = {}
	animator = $AnimationPlayer
	animation_tree = $AnimationTree
	if not bounds:
		bounds = Navigator.shape_bounds((get_node("Collision") as CollisionShape3D).shape)
		#(get_node("Collision") as CollisionShape3D).disabled = true
		#(get_node("WetArea/WetCollision") as CollisionShape3D).disabled = true
	setup()
	
static func make(_kind: World.Enemy) -> Enemy:
	var result: Enemy
	const undead = preload("res://Characters/Enemy/Undead/undead.tscn") as PackedScene
	const bat = preload("res://Characters/Enemy/Bat/bat.tscn") as PackedScene
	const mole = preload("res://Characters/Enemy/Mole/mole.tscn") as PackedScene
	const human = preload("res://Characters/Enemy/Human/human.tscn") as PackedScene
	const walker = preload("res://Characters/Enemy/Walker/walker.tscn") as PackedScene
	const fish = preload("res://Characters/Enemy/Fish/fish.tscn") as PackedScene
	const birdman = preload("res://Characters/Enemy/Birdman/birdman.tscn") as PackedScene
	const fishman = preload("res://Characters/Enemy/Fishman/fishman.tscn") as PackedScene
	match _kind:
		World.Enemy.UNDEAD: result = undead.instantiate()
		World.Enemy.MOLE: result = mole.instantiate()
		World.Enemy.WALKER: result = walker.instantiate()
		World.Enemy.BAT: result = bat.instantiate()
		World.Enemy.BIRDMAN: result = birdman.instantiate()
		World.Enemy.FISH: result = fish.instantiate()
		World.Enemy.HUMAN: result = human.instantiate()
		World.Enemy.FISHMAN: result = fishman.instantiate()
		_: push_error("Missing enemy")
	return result
	
func setup() -> void:
	pass
	
func add_shake(amount: float) -> void:
	player.add_shake(amount)
	
func increment_ticks(delta: float) -> void:
	behavior_tick += delta
	spell_tick += delta
	invunerable = max(0.0, invunerable - delta)
		
func current_animation_is(animation: String) -> bool:
	var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
	var current := playback.get_current_node()
	return current == animation
		
func play_animation(animation: String, parameters: Dictionary = {}) -> void:
	var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
	for path: StringName in parameters:
		animation_tree.set(path, parameters[path])
	var current := playback.get_current_node()
	if current != "death" and current != animation:
		playback.travel(animation)

func can_move() -> bool:
#	var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
#	var current := playback.get_current_node()
	return is_zero_approx(invunerable) # and (current == "idle" or current == "walk" or current == "run")

func attack_state() -> AttackPatterns:
	return AttackPatterns.none()

func _physics_process(delta: float) -> void:
	if kind == World.Enemy.NONE or player.magic_book.settings.is_paused:
		return
	
	increment_ticks(delta)
			
	var movement := velocity_movement.update(delta, vitals, speed_for_current_behaviour_tick, self)
	vital_update.emit(index_in_population, vitals)
	if not is_dead and vitals.health.value <= vitals.health.min_value:
		die()
	update_vitals_display()
	
	var is_on_floor_1_not_on_floor_2_else_check_0: int = 0
	if velocity_movement.impulse != Vector3.ZERO:
		velocity = movement["velocity"]
		move_and_slide()
	else:
		match current_path.mover:
			PathStyle.Mover.PHYSICS:
				velocity = movement["velocity"]
				move_and_slide()
			PathStyle.Mover.ABSOLUTE:
				var v: Vector3 
				var t: Vector3
				v = movement["absolute"]
				t = movement["target"]
				var g := Navigator.get_world_height(get_world_3d().direct_space_state, position.x, position.z)
				if feet_position() <= g:
					if current_path.coord_y == PathStyle.CoordY.GROUND or current_path.coord_y == PathStyle.CoordY.GROUND_AND_AIR:
						set_feet_position(g)
						t.y = 0
						v.y = 0
				elif feet_position() >= g:
					if current_path.coord_y == PathStyle.CoordY.GROUND or current_path.coord_y == PathStyle.CoordY.GROUND_AND_DIRT:
						set_feet_position(g)
						t.y = 0
						v.y = 0
				is_on_floor_1_not_on_floor_2_else_check_0 = 1 if abs(feet_position() - g) < 0.05 else 2
				velocity = Vector3(v.x, v.y + t.y, v.z)
				position += Vector3(v.x, v.y + t.y, v.z)
				
		if current_path.lookat == PathStyle.LookAt.PLAYER:
			var goal_position := position + velocity * 10
			look_at(player.position.lerp(goal_position, clampf(velocity.length() / 100.0, 0.0, 1.0)))
		elif current_path.lookat == PathStyle.LookAt.PLAYER_XZ:
			var goal_position := position + velocity * 10
			var player_position := player.position
			player_position.y = position.y
			look_at(player_position.lerp(goal_position, clampf(velocity.length() / 100.0, 0.0, 1.0)))
		

	var reset_spell_tick := false
	var behavior_ticked_over := ((behavior_tick > Globals.behaviour_tick()) or is_equal_approx(behavior_tick, Globals.behaviour_tick()))
	
	if is_nan(time_since_navigation_update):
		time_since_navigation_update = Time.get_unix_time_from_system()
	if behavior_ticked_over or not velocity_movement.has_navigation_target:
		if behavior_ticked_over:
			update_behaviour()
		if not velocity_movement.has_navigation_target:
			var is_done := Globals.Ref.new(false)
			var next_pos: Vector3
			var navigation_time_delta := minf(Time.get_unix_time_from_system() - time_since_navigation_update, Globals.behaviour_tick())
			time_since_navigation_update = Time.get_unix_time_from_system()
			if attack_sequence:
				reset_spell_tick = attack_sequence.update(navigation_time_delta, self, player, is_done)
				if attack_sequence.last_path:
					current_path = attack_sequence.last_path
					next_pos = attack_sequence.next_position
					speed_for_current_behaviour_tick = attack_sequence.next_movement_speed
				else:
					current_path = still_path
					next_pos = position
					speed_for_current_behaviour_tick = 0.0
				current_attack = attack_sequence.last_attack
			else:
				var next_movement := current_path.next_position(navigation_time_delta, self, player, is_done)
				next_pos = Vector3(next_movement.x, next_movement.y, next_movement.z)
				speed_for_current_behaviour_tick = next_movement.w
			var collision_shape := get_node("Collision") as CollisionShape3D
			var options: int = 0
			if current_path.coord_y == PathStyle.CoordY.GROUND_AND_DIRT or current_path.coord_y == PathStyle.CoordY.ORIGIN:
				options |= Navigator.MovementOptions.UNDERGROUND
			if current_path.coord_y == PathStyle.CoordY.GROUND_AND_AIR or current_path.coord_y == PathStyle.CoordY.ORIGIN:
				options |= Navigator.MovementOptions.CAN_FLY
			var obj := get_node(".") as CharacterBody
			velocity_movement.target_path = GlobalData.nav.find_target_path(obj, next_pos, collision_shape.shape, options, 1000.0, 0.5)
			velocity_movement.target_position = Navigator.find_next_target_from_path(velocity_movement.target_path, position, obj, next_pos)
		if reset_spell_tick:
			behavior_tick = Globals.behaviour_tick()
		else:
			behavior_tick = 0

	if reset_spell_tick or (spell_tick >= (1.0 + vitals.freeze.value) and vitals.stun.value == 0 and vitals.freeze.value < 1.0):
		var spell: Spell = null
		if attack_sequence:
			if attack_sequence.last_attack:
				spell = current_attack.choose_spell(vitals)
		else:
			spell = attack_state().choose_spell(vitals)
		spell_tick = 0
		if spell != null:
			play_animation("attack")
			await get_parent_node_3d().get_tree().create_timer(animator.get_animation(animation_map["attack"] as StringName).length / 2.0).timeout
			await get_tree().physics_frame
			cast_spell(func(p: Node3D) -> void: if p != null: call_deferred("add_sibling", p), spell)
		

	spell_caster.update(self, delta)
	var final_is_on_floor: bool
	# TODO: work on precision of on floor when using physics
	if is_on_floor_1_not_on_floor_2_else_check_0 == 0:
		final_is_on_floor = is_on_floor()
	else:
		final_is_on_floor = is_on_floor_1_not_on_floor_2_else_check_0 == 1
		
	if velocity != Vector3.ZERO:
		if final_is_on_floor:
			if velocity.length() < 0.166667:
				#play_walking_audio(NoiseBlender.walking_audio_for_biome(current_biome))
				play_animation("walk", {"parameters/walk/speed/scale": speed_for_current_behaviour_tick})
			else:
				#play_walking_audio(NoiseBlender.walking_audio_for_biome(current_biome))
				play_animation("run", {"parameters/run/speed/scale": speed_for_current_behaviour_tick / 10.0})
	else:
		idle_tick += delta
		if final_is_on_floor and idle_tick > 0.5:
			play_walking_audio(null)
			play_animation("idle")
			idle_tick = 0
		
	if not final_is_on_floor:
		play_animation("fall")
	elif current_animation_is("fall"):
		play_animation("land")


func cast_spell(insert: Callable, next_spell: Spell) -> MagicBook.DisallowSpellReason:
	return spell_caster.cast_spell(self, vitals, insert, next_spell)

func entity_info() -> EntityInfo:
	return EntityInfo.new(EntityInfo.Kind.ENEMY, position)

func update_entity_info(info: EntityInfo) -> bool:
	info.position = position
	return true

func update_behaviour() -> void:
	pass

func handle_damage() -> void:
	pass
	
func death_box() -> Vector3:
	return Vector3(1, 1, 1)
	
func die() -> void:
	is_dead = true
	var explosion: Node3D = preload("res://Characters/Enemy/enemy_die.tscn").instantiate()
	var source := explosion.get_node("source") as GPUParticles3D
	(source.process_material as ParticleProcessMaterial).emission_box_extents = death_box()
		
	play_animation("death")
	
	var world := get_parent_node_3d()
	await world.get_tree().create_timer(animator.get_animation("Death").length + 0.1).timeout
	player.ignore_enemy(get_node(".") as Enemy)
	explosion.position = position
	explosion.global_transform = global_transform
	world.add_child(explosion)
	source.emitting = true
	spell_caster.free_particles()
	
	# drop only one of key/artifact/spell based on said priority
	if not drop_key_item(world):
		if not drop_artifact_item(world):
			drop_spell_item(world)
	drop_coin_items(world)
	
	SignalBus.enemy_death.emit(get_node("."))
	world.get_tree().create_timer(Globals.particle_system_lifetime(source)).timeout.connect(func() -> void: world.remove_child(explosion))
	
		
func drop_artifact_item(world: Node3D) -> bool:
	var artifact: Artifact = drop_artifact()
	if artifact:
		var item := (preload("res://Models/Misc/Artifact/Cube.tscn") as PackedScene).instantiate() as ArtifactCube
		item.position = position
		item.global_transform = global_transform
		item.artifact = artifact
		world.add_child(item)
		return true
	return false
		
		
func drop_spell_item(world: Node3D) -> bool:
	var spell: Spell = drop_spell()
	if spell:
		var item := (preload("res://Models/Misc/Spell/Paper.tscn") as PackedScene).instantiate() as SpellPaper
		item.position = position
		item.global_transform = global_transform
		item.spell = spell
		world.add_child(item)
		return true
	return false
		
func drop_key_item(world: Node3D) -> bool:
	var key: int = drop_key()
	if key != 0:
		var item := (preload("res://Models/Misc/Key/Key.tscn") as PackedScene).instantiate() as KeyPrism
		item.position = position
		item.global_transform = global_transform
		item.key = key
		world.add_child(item)
		return true
	return false
	
func drop_coin_items(world: Node3D) -> bool:
	var coins := drop_coins()
	if not coins.is_empty():
		for coin in coins:
			var item := (preload("res://Models/Misc/Coin/Coin.tscn") as PackedScene).instantiate() as CoinDisc
			item.position = position
			item.global_transform = global_transform.translated(Globals.rand_point_in_circle(1.0 + log(coins.size()), 0))
			item.amount = coin
			world.add_child(item)
		return true
	return false
	
func update_vitals_display() -> void:
	(health_bar.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("percentage", vitals.health.percentage())

func drop_artifact() -> Artifact:
	return null
	
func drop_spell() -> Spell:
	return null
	
func drop_key() -> int:
	return 0
	
func drop_coins() -> Array[int]:
	return []

func world_enemy_enum() -> World.Enemy:
	var n := get_node(".")
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
	elif n is Fishman:
		return World.Enemy.FISHMAN
	
	return World.Enemy.NONE

func play_walking_audio(stream: AudioStream) -> void:
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
