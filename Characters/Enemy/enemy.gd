class_name Enemy
extends CharacterBody

var animator: AnimationPlayer
var animation_tree: AnimationTree
var animation_map: Dictionary ## [String]String

#@onready var walking_audio: AudioStreamPlayer3D = $MovementAudio
#var walking_tween: Tween = null

var spell_caster: SpellCaster
var attack_sequence: AttackSequence = null

var player: Player
var current_path: PathStyle
var still_path: PathStyle
var spawn_position: Vector3
var current_attack: AttackPatterns
var class_level: int = 10 # [1, 20]
var level_flag: int = -1 # TODO: use level flags to determine level completion. Beating a flag 0 enemy completes level. Enemies can only show the enemies with the highest flag number. Once all of the highest flags are beaten then the next lowest flag numbered enemies are spawned. 
var level: float: # Use float so it's easy to use in expressions. However, should only be whole numbers.
	set(value):
		level = value
		if level_text != null:
			level_text.text = str(int(level))
var fl: float:
	get:
		return level / 100.0
var invfl: float:
	get:
		return 1.0 - level / 100.0
var is_dead: bool = false
var kind: World.Enemy = World.Enemy.NONE
var sfx_attack: AudioManager.AudioStreamKind
var sfx_hurt: AudioManager.AudioStreamKind
var sfx_walk: AudioManager.AudioStreamKind
var sfx_idle: AudioManager.AudioStreamKind
var is_idle := true
var is_idle_is_set := false
var spell_drop_probs := {}
var artifact_drop_probs := {}

var behavior_tick: float = 0
var spell_tick: float = 0
var idle_tick: float = 0
var move_tick: float = 0
var speed_for_current_behaviour_tick := 0.0
var path_movement_remaining_duration := 0.0
var time_since_navigation_update := NAN
var frame_count := Vector2(0, 0) # animation frame count for each enemy. x=walk, y=run
var pushed_with_impulse := false
var timer_seed: Globals.Ref

var index_in_population: int = -1
signal vital_update(index_in_population: int, vitals: Vitals)
signal spell_was_cast(spell: Spell)
@onready var health_bar: MeshInstance3D = $HealthBar/Bar
@onready var level_text: Label3D = $HealthBar/Level
@onready var effects_mesh: MeshInstance3D = $HealthBar/Effects
@onready var collision: CollisionShape3D = $Collision
@onready var area: CollisionShape3D = $WetArea/WetCollision

func _ready() -> void:
	level_text.text = str(int(level))
	animator = $AnimationPlayer
	animation_tree = $AnimationTree
	collider = $Collision
	moving_platform_layers = Globals.Layer.OBJECT | Globals.Layer.ROCK
	max_snap_length = 0.0
	timer_seed = Globals.Ref.new(Time.get_ticks_usec())
	if kind == World.Enemy.NONE:
		setup(0, World.Biome.WATER)
	health_bar.visible = not is_idle
	
static func make(_kind: World.Enemy) -> Enemy:
	var result: Enemy

	
	const fish = preload("res://Characters/Enemy/Blob/Fish/fish.tscn") as PackedScene
	const bird = preload("res://Characters/Enemy/Blob/Bird/Bird.tscn") as PackedScene
	const fungi = preload("res://Characters/Enemy/Blob/Fungi/fungi.tscn") as PackedScene
	const hot_blob = preload("res://Characters/Enemy/Blob/HotBlob/hot_blob.tscn") as PackedScene
	const mushroom = preload("res://Characters/Enemy/Blob/Mushroom/mushroom.tscn") as PackedScene
	const snot_blob = preload("res://Characters/Enemy/Blob/SnotBlob/snot_blob.tscn") as PackedScene
	const snot_spike = preload("res://Characters/Enemy/Blob/SnotSpike/snot_spike.tscn") as PackedScene
	const walker_head = preload("res://Characters/Enemy/Blob/WalkerHead/walker_head.tscn") as PackedScene
	const wizard = preload("res://Characters/Enemy/Blob/Wizard/wizard.tscn") as PackedScene
	const bougeon = preload("res://Characters/Enemy/Blob/Bougeon/bougeon.tscn") as PackedScene

	const undead = preload("res://Characters/Enemy/Tall/Undead/undead.tscn") as PackedScene
	const mole = preload("res://Characters/Enemy/Tall/Mole/mole.tscn") as PackedScene
	const walker = preload("res://Characters/Enemy/Tall/Walker/walker.tscn") as PackedScene
	const birdman = preload("res://Characters/Enemy/Tall/Birdman/birdman.tscn") as PackedScene
	const fishman = preload("res://Characters/Enemy/Tall/Fishman/fishman.tscn") as PackedScene
	const bluemon = preload("res://Characters/Enemy/Tall/Bluemon/bluemon.tscn") as PackedScene
	const frog = preload("res://Characters/Enemy/Tall/Frog/frog.tscn") as PackedScene
	const mushking = preload("res://Characters/Enemy/Tall/MushKing/mushking.tscn") as PackedScene
	const rabbit = preload("res://Characters/Enemy/Tall/Rabbit/rabbit.tscn") as PackedScene
	const orc = preload("res://Characters/Enemy/Tall/Orc/orc.tscn") as PackedScene
	const orc_dead = preload("res://Characters/Enemy/Tall/OrcDead/orc_dead.tscn") as PackedScene

	const bat = preload("res://Characters/Enemy/Flying/Bat/bat.tscn") as PackedScene
	const dragon = preload("res://Characters/Enemy/Flying/Dragon/dragon.tscn") as PackedScene
	const dragoon = preload("res://Characters/Enemy/Flying/Dragoon/dragoon.tscn") as PackedScene
	const ghost = preload("res://Characters/Enemy/Flying/Ghost/ghost.tscn") as PackedScene
	const ghostly = preload("res://Characters/Enemy/Flying/Ghostly/ghostly.tscn") as PackedScene
	const batty = preload("res://Characters/Enemy/Flying/Batty/batty.tscn") as PackedScene
	const bee = preload("res://Characters/Enemy/Flying/Bee/bee.tscn") as PackedScene
	const bumble_bee = preload("res://Characters/Enemy/Flying/BumbleBee/bumble_bee.tscn") as PackedScene
	const undead_head = preload("res://Characters/Enemy/Flying/UndeadHead/undead_head.tscn") as PackedScene
	const redmon = preload("res://Characters/Enemy/Flying/Redmon/redmon.tscn") as PackedScene
	const pinkmon = preload("res://Characters/Enemy/Flying/Pinkmon/pinkmon.tscn") as PackedScene
	const flygeon = preload("res://Characters/Enemy/Flying/Flygeon/flygeon.tscn") as PackedScene
	const goblin = preload("res://Characters/Enemy/Flying/Goblin/goblin.tscn") as PackedScene
	const goblin_king = preload("res://Characters/Enemy/Flying/GoblinKing/goblin_king.tscn") as PackedScene
	match _kind:
		World.Enemy.UNDEAD: result = undead.instantiate()
		World.Enemy.MOLE: result = mole.instantiate()
		World.Enemy.WALKER: result = walker.instantiate()
		World.Enemy.BAT: result = bat.instantiate()
		World.Enemy.BIRDMAN: result = birdman.instantiate()
		World.Enemy.FISH: result = fish.instantiate()
		World.Enemy.FISHMAN: result = fishman.instantiate()
		World.Enemy.DRAGON: result = dragon.instantiate()
		World.Enemy.DRAGOON: result = dragoon.instantiate()
		World.Enemy.GHOST: result = ghost.instantiate()
		World.Enemy.GHOSTLY: result = ghostly.instantiate()
		World.Enemy.REDMON: result = redmon.instantiate()
		World.Enemy.PINKMON: result = pinkmon.instantiate()
		World.Enemy.FLYGEON: result = flygeon.instantiate()
		World.Enemy.BIRD: result = bird.instantiate() 
		World.Enemy.FUNGI: result = fungi.instantiate()
		World.Enemy.HOT_BLOB: result = hot_blob.instantiate() 
		World.Enemy.MUSHROOM: result = mushroom.instantiate()
		World.Enemy.BLUEMON: result = bluemon.instantiate()
		World.Enemy.FROG: result = frog.instantiate()
		World.Enemy.MUSHKING: result = mushking.instantiate()
		World.Enemy.RABBIT: result = rabbit.instantiate()
		World.Enemy.BATTY: result = batty.instantiate()
		World.Enemy.BEE: result = bee.instantiate() 
		World.Enemy.BUMBLE_BEE: result = bumble_bee.instantiate()
		World.Enemy.UNDEAD_HEAD: result = undead_head.instantiate()
		World.Enemy.ORC: result = orc.instantiate()
		World.Enemy.ORC_DEAD: result = orc_dead.instantiate()
		World.Enemy.GOBLIN: result = goblin.instantiate()
		World.Enemy.GOBLIN_KING: result = goblin_king.instantiate()
		World.Enemy.SNOT_BLOB: result = snot_blob.instantiate()
		World.Enemy.SNOT_SPIKE: result = snot_spike.instantiate()
		World.Enemy.WALKER_HEAD: result = walker_head.instantiate()
		World.Enemy.WIZARD: result = wizard.instantiate()
		World.Enemy.BOUGEON: result = bougeon.instantiate()
		_: push_error("Missing enemy")
		
	result.spell_caster = SpellCaster.new(result, SpellCaster.Entity.ENEMY)
	result.still_path = PathStyle.still_path_default
	result.current_path = result.still_path
	if not result.bounds:
		result.bounds = Navigator.shape_bounds((result.get_node("Collision") as CollisionShape3D).shape)
		#(result.get_node("Collision") as CollisionShape3D).disabled = true
		#(result.get_node("WetArea/WetCollision") as CollisionShape3D).disabled = true
		
	return result
	
func setup(seedling: int, biome: World.Biome) -> void:
	spawn_position = position
	update_behaviour()
	rotation.y = randf() * TAU
	match kind:
		World.Enemy.BIRDMAN, World.Enemy.BLUEMON, World.Enemy.FISHMAN, World.Enemy.FROG, \
		World.Enemy.MOLE, World.Enemy.MUSHKING, World.Enemy.RABBIT, World.Enemy.UNDEAD, World.Enemy.WALKER, World.Enemy.ORC, World.Enemy.ORC_DEAD: 
			frame_count = Vector2(30, 17)
			sfx_attack = AudioManager.AudioStreamKind.ATTACK_MED
			sfx_hurt = AudioManager.AudioStreamKind.HURT_MED
			sfx_walk = AudioManager.AudioStreamKind.WALK_MED
			sfx_idle = AudioManager.AudioStreamKind.IDLE_MED
		World.Enemy.BIRD, World.Enemy.FISH, World.Enemy.FUNGI, World.Enemy.HOT_BLOB, World.Enemy.MUSHROOM, \
		World.Enemy.SNOT_BLOB, World.Enemy.SNOT_SPIKE, World.Enemy.WALKER_HEAD, World.Enemy.WIZARD, World.Enemy.BOUGEON: 
			frame_count = Vector2(13, 13)
			sfx_attack = AudioManager.AudioStreamKind.ATTACK_BEAST
			sfx_hurt = AudioManager.AudioStreamKind.HURT_BEAST
			sfx_walk = AudioManager.AudioStreamKind.WALK_BEAST
			sfx_idle = AudioManager.AudioStreamKind.IDLE_BEAST
		World.Enemy.BAT, World.Enemy.BATTY, World.Enemy.BEE, World.Enemy.BUMBLE_BEE, World.Enemy.DRAGON, \
		World.Enemy.DRAGOON, World.Enemy.GHOST, World.Enemy.GHOSTLY, World.Enemy.UNDEAD_HEAD, World.Enemy.FLYGEON, \
		World.Enemy.PINKMON, World.Enemy.REDMON, World.Enemy.GOBLIN, World.Enemy.GOBLIN_KING: 
			frame_count = Vector2(35, 25)
			sfx_attack = AudioManager.AudioStreamKind.ATTACK_FLY
			sfx_hurt = AudioManager.AudioStreamKind.HURT_FLY
			sfx_walk = AudioManager.AudioStreamKind.WALK_FLY
			sfx_idle = AudioManager.AudioStreamKind.IDLE_FLY
		_: push_error("missing enemy kind")
	
func set_level(lvl: float) -> void:
	level = lvl
		
func separation_multiplier() -> float:
	return 1.05
	
func add_shake(amount: float) -> void:
	player.add_shake(amount)
	
func increment_ticks(delta: float) -> void:
	behavior_tick += delta
	spell_tick += delta
	move_tick += delta
	time_since_navigation_update += delta
	var is_invunerable := invunerable > 0.0
	invunerable = max(0.0, invunerable - delta)
	if is_invunerable and invunerable < SpellBody.INVUNERABLE_DURATION * 0.8 and not animation_tree.active:
		animation_tree.active = true
		
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
	
func set_path_and_attack(path: PathStyle, attack: AttackPatterns) -> void:
	var is_new_set := path != current_path or attack != current_attack
	if is_new_set:
		attack_sequence = null
		current_path = path
		current_path.time = NAN
		current_attack = attack
	
func set_attack_sequence(atk_seq: AttackSequence) -> void:
	var is_new_set := atk_seq != attack_sequence
	if is_new_set:
		current_path = null
		current_attack = null
		attack_sequence = atk_seq

#static var p_movement := Profiler.new()
#static var p_path := Profiler.new()
#static var p_nav := Profiler.new()
#static var p_anim := Profiler.new()

func manual_physics_process(delta: float) -> void:
	if kind == World.Enemy.NONE or player.magic_book.settings.is_paused:
		return
	
	#p_movement.start()
	var dist := 1.0 - clampf(maxf(position.distance_to(player.position) - Globals.enemy_update_radius(), 0.0) / Globals.enemy_update_radius(), 0.0, 1.0)
	var tick_scale := maxf(pow(dist, 2.0), 0.01 * Rand.randf_range(timer_seed, 0.5, 1.0))
	increment_ticks(delta * tick_scale)
			
	velocity_movement.update_vitals(delta, vitals, self, player.world_settings)
	if vitals.did_update_on_tick:
		vital_update.emit(index_in_population, vitals)
	if not is_dead and vitals.health.value <= vitals.health.min_value:
		die()
	update_vitals_display()
	
	var is_on_floor_1_not_on_floor_2_else_check_0: int = 0
	var did_move := false
	if current_path == null:
		current_path = still_path
	var is_ground_path_style := current_path.coord_y == PathStyle.CoordY.GROUND or current_path.coord_y == PathStyle.CoordY.GROUND_AND_DIRT
	if snappedf(move_tick, 0.00001) < Globals.move_tick():
		if velocity_movement.impulse != Vector3.ZERO or current_path.mover == PathStyle.Mover.PHYSICS:
			var current_frame_count := frame_count.x if velocity.length() < 0.166667 else frame_count.y
			velocity_movement.update_movement_speed(speed_for_current_behaviour_tick, bounds.y, current_frame_count)
			var movement := velocity_movement.update(delta, vitals, speed_for_current_behaviour_tick, self, current_path.lookat == PathStyle.LookAt.VELOCITY, player.world_settings, player.chunker)
			velocity = movement["velocity"]
			move_and_slide()
			pushed_with_impulse = not is_on_floor and is_ground_path_style
	else:
		var group_positioning_adjustment := (player.enemies_in_range[self] as Player.CombatStats).seperation if player.enemies_in_range.has(self) else Vector3.ZERO
		var current_frame_count := frame_count.x if velocity.length() < 0.166667 else frame_count.y
		velocity_movement.update_movement_speed(speed_for_current_behaviour_tick, bounds.y, current_frame_count)
		var movement := velocity_movement.update(delta, vitals, speed_for_current_behaviour_tick, self, current_path.lookat == PathStyle.LookAt.VELOCITY, player.world_settings, player.chunker)
		did_move = true
		move_tick = 0.0
		if velocity_movement.impulse != Vector3.ZERO:
			velocity = movement["velocity"]
			move_and_slide()
			pushed_with_impulse = not is_on_floor and is_ground_path_style
		else:
			match current_path.mover:
				PathStyle.Mover.PHYSICS:
					velocity = movement["velocity"]
					move_and_slide()
					pushed_with_impulse = not is_on_floor and is_ground_path_style
				PathStyle.Mover.ABSOLUTE:
					var v: Vector3 
					var t: Vector3
					v = movement["absolute"]
					t = movement["target"]
					var g := Navigator.get_world_height(get_world_3d().direct_space_state, position.x, position.z)
					if feet_position() + v.y + t.y < g + 0.005:
						if current_path.coord_y == PathStyle.CoordY.GROUND or current_path.coord_y == PathStyle.CoordY.GROUND_AND_AIR:
							if pushed_with_impulse:
								pushed_with_impulse = feet_position() + t.y < g and current_path.coord_y == PathStyle.CoordY.GROUND
								v.y = 0
							else:
								t.y = (g - feet_position()) * delta
								v.y = 0
						else:
							pushed_with_impulse = false
					elif feet_position() + v.y + t.y > g + 0.005:
						if current_path.coord_y == PathStyle.CoordY.GROUND or current_path.coord_y == PathStyle.CoordY.GROUND_AND_DIRT:
							if pushed_with_impulse:
								pushed_with_impulse = feet_position() + t.y > g
								v.y = 0
							else:
								t.y = (g - feet_position()) * delta
								v.y = 0
						else:
							pushed_with_impulse = false
					is_on_floor_1_not_on_floor_2_else_check_0 = 1 if abs(feet_position() - g) < 0.1 else 2
					velocity = Vector3(v.x, v.y + t.y, v.z)
					var adj := group_positioning_adjustment * delta * speed_for_current_behaviour_tick
					position += Vector3(v.x, v.y + t.y, v.z) + adj
					
			if current_path.lookat == PathStyle.LookAt.PLAYER:
				var t := Globals.looking_at(self, player.transform.origin)
				var v := maxf(velocity.length(), delta)
				global_transform.basis.y = global_transform.basis.y.slerp(t.basis.y, v)
				global_transform.basis.x = global_transform.basis.x.slerp(t.basis.x, v)
				global_transform.basis.z = global_transform.basis.z.slerp(t.basis.z, v)
				if not global_transform.basis.is_conformal():
					global_transform = global_transform.orthonormalized()
			elif current_path.lookat == PathStyle.LookAt.PLAYER_XZ:
				var player_transform := player.transform
				player_transform.translated(Vector3(0, -player.global_position.y + global_position.y, 0))
				var t := Globals.looking_at(self, player_transform.origin)
				var v := maxf(velocity.length(), delta)
				global_transform.basis.y = global_transform.basis.y.slerp(t.basis.y, v)
				global_transform.basis.x = global_transform.basis.x.slerp(t.basis.x, v)
				global_transform.basis.z = global_transform.basis.z.slerp(t.basis.z, v)
				if not global_transform.basis.is_conformal():
					global_transform = global_transform.orthonormalized()
	#p_movement.lap()

	var reset_spell_tick := false
	var behavior_ticked_over := ((behavior_tick > Globals.behaviour_tick()) or is_equal_approx(behavior_tick, Globals.behaviour_tick()))
	
	if is_nan(time_since_navigation_update):
		time_since_navigation_update = 0.0
	if (behavior_ticked_over or (not velocity_movement.has_navigation_target and tick_scale == 1.0)):
		if behavior_ticked_over:
			update_behaviour()
			behavior_tick = 0
		if not velocity_movement.has_navigation_target:
			#p_path.start()
			var is_done := Globals.Ref.new(false)
			var next_pos: Vector3
			var navigation_time_delta := time_since_navigation_update
			time_since_navigation_update = 0.0
			if attack_sequence:
				var me := Vec4.vec3(position, bounds.y)
				reset_spell_tick = attack_sequence.update(navigation_time_delta, me, player, is_done, get_world_3d().direct_space_state)
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
				var me := Vec4.vec3(position, bounds.y)
				var next_movement := current_path.next_position(navigation_time_delta, me, player, is_done)
				next_pos = Vector3(next_movement.x, next_movement.y, next_movement.z)
				speed_for_current_behaviour_tick = next_movement.w
			var collision_shape := get_node("Collision") as CollisionShape3D
			var options: int = 0
			if current_path.coord_y == PathStyle.CoordY.GROUND_AND_DIRT or current_path.coord_y == PathStyle.CoordY.ORIGIN:
				options |= Navigator.MovementOptions.UNDERGROUND
			if current_path.coord_y == PathStyle.CoordY.GROUND_AND_AIR or current_path.coord_y == PathStyle.CoordY.ORIGIN or current_path.coord_y == PathStyle.CoordY.AIR:
				options |= Navigator.MovementOptions.CAN_FLY
			var obj := get_node(".") as CharacterBody
			if is_idle:
				velocity_movement.target_path = PackedVector3Array([next_pos])
			else:
				velocity_movement.target_path = GlobalData.nav.find_target_path(obj, next_pos, collision_shape.shape, options, 500.0, Vec3.max(player.bounds))
			velocity_movement.target_position = Navigator.find_next_target_from_path(velocity_movement.target_path, position, obj, next_pos)
			if reset_spell_tick:
				behavior_tick = Globals.behaviour_tick()

	if (reset_spell_tick or (spell_tick >= (1.0 + vitals.freeze.value) and vitals.stun.value == 0 and vitals.freeze.value < 1.0)):
		var spell: Spell = null
		if attack_sequence:
			if attack_sequence.last_attack:
				spell = attack_sequence.last_attack.choose_spell(vitals)
		else:
			spell = current_attack.choose_spell(vitals)
		spell_tick = 0
		if spell != null:
			play_animation("attack")
			AudioManager.play(sfx_attack, position, NAN, true, Vector2(0.8, 1.2))
			await get_parent_node_3d().get_tree().create_timer(animator.get_animation(animation_map["attack"] as StringName).length / 2.0).timeout
			await get_tree().physics_frame
			cast_spell(insert_spell, spell)
		

	#p_anim.start()
	spell_caster.update(self, delta)
	if did_move:
		var final_is_on_floor: bool
		if is_on_floor_1_not_on_floor_2_else_check_0 == 0:
			final_is_on_floor = is_on_floor
		else:
			final_is_on_floor = is_on_floor_1_not_on_floor_2_else_check_0 == 1
			
		if animation_tree.active:
			if velocity != Vector3.ZERO:
				if final_is_on_floor:
					if velocity.length() < 0.166667:
						play_animation("walk", {"parameters/walk/speed/scale": velocity_movement.movement_speed_animation_scale()})
						AudioManager.play(sfx_walk, position, NAN, false, Vector2(0.8, 1.2))
						AudioManager.stop(sfx_idle)
					else:
						play_animation("run", {"parameters/run/speed/scale": velocity_movement.movement_speed_animation_scale()})
						AudioManager.play(sfx_walk, position, NAN, false, Vector2(0.8, 1.2))
						AudioManager.stop(sfx_idle)
			else:
				idle_tick += delta
				if final_is_on_floor and idle_tick > 0.5:
					AudioManager.stop(sfx_walk)
					AudioManager.play(sfx_idle, position, NAN, false, Vector2(0.8, 1.2))
					play_animation("idle")
					idle_tick = 0
				
			if not final_is_on_floor:
				play_animation("fall")
			elif current_animation_is("fall"):
				play_animation("land")
	#p_anim.lap()


func cast_spell(insert: Callable, next_spell: Spell) -> MagicBook.DisallowSpellReason:
	spell_was_cast.emit(next_spell)
	return spell_caster.cast_spell(self, vitals, insert, next_spell)

func insert_spell(p: Node3D) -> void:
	if p == null:
		return
	if p.get_parent() == null:
		add_sibling(p)
	if p is SpellBody:
		(p as SpellBody).setup()
		

func update_behaviour() -> void:
	var old_is_idle := is_idle
	if is_idle:
		if not is_dead and player.position.distance_to(position) < vitals.perception.min_value:
			is_idle = false
	else:
		if is_dead or player.position.distance_to(position) > vitals.perception.max_value or position.distance_to(spawn_position) > player.get_chunk_width():
			is_idle = true
	
	if old_is_idle != is_idle or not is_idle_is_set:
		if is_idle:
			player.ignore_enemy(self)
			is_idle_is_set = true
		elif is_inside_tree():
			player.watch_enemy(self)
			is_idle_is_set = true
			
		if health_bar != null:
			health_bar.visible = not is_idle
			
		

func handle_damage() -> void:
	pass
	
static var biome_helper := BiomeHelper.new()
func die() -> void:
	if is_dead:
		return
	is_dead = true
	var explosion: Node3D = preload("res://Characters/Enemy/enemy_die.tscn").instantiate()
	var source := explosion.get_node("source") as GPUParticles3D
	(source.process_material as ParticleProcessMaterial).emission_box_extents = bounds
	(source.process_material as ParticleProcessMaterial).color = biome_helper.color_for_biome(velocity_movement.current_biome)
		
	player.world_settings.upgrade_settings.progress_defeat_enemy(kind, int(level), player.active_enemy_kinds)
		
	AudioManager.play(sfx_hurt, position, NAN, true)
	play_animation("death")
	
	var world := get_parent_node_3d()
	await world.get_tree().create_timer(animator.get_animation("Death").length + 0.1).timeout
	var multiplier := player.kill_multiplier(self)
	player.ignore_enemy(get_node(".") as Enemy)
	explosion.position = position
	explosion.global_transform = global_transform
	world.add_child(explosion)
	source.emitting = true
	spell_caster.free_particles()
	
	drop_key_item(world)
	drop_artifact_item(world)
	drop_spell_item(world)
	if player.world_settings.game_mode_settings.has_flag(GameModeSettings.SHOP_FOR_UPGRADES):
		drop_coin_items(world)
	drop_health_item(world, multiplier)
	drop_scroll_note(world)
	
	SignalBus.enemy_death.emit(get_node("."))
	world.get_tree().create_timer(Globals.particle_system_lifetime(source)).timeout.connect(func() -> void: explosion.queue_free())
	
func ground_position(coord: Vector3) -> Vector3:
	if player.chunker == null:
		return Vector3(coord.x, Navigator.get_world_height(get_world_3d().direct_space_state, coord.x, coord.z), coord.z)
	else:
		return player.chunker.ground_position(position + Rand.point_in_circle(3, 0))
		
func drop_artifact_item(world: Node3D) -> bool:
	var artifact: Artifact = drop_artifact()
	if artifact:
		var item := ArtifactCube.make()
		var tween := item.create_tween_for_drop(position, ground_position(position + Rand.point_in_circle(3, 0)), 0.25)
		item.artifact = artifact
		world.add_child(item)
		tween.play()
		return true
	return false
		
		
func drop_spell_item(world: Node3D) -> bool:
	var spell: Spell = drop_spell()
	if spell:
		var item := SpellPaper.make()
		var tween := item.create_tween_for_drop(position, ground_position(position + Rand.point_in_circle(3, 0)), 0.25)
		item.spell = spell
		world.add_child(item)
		tween.play()
		return true
	return false
		
func drop_key_item(world: Node3D) -> bool:
	var key: int = drop_key()
	if key != 0 and (player.world_settings.player_keys & key == 0):
		var item := KeyPrism.make()
		var tween := item.create_tween_for_drop(position, ground_position(position + Rand.point_in_circle(3, 0)), 0.25)
		item.key = key
		world.add_child(item)
		tween.play()
		return true
	return false
	
func drop_coin_items(world: Node3D) -> bool:
	var coins := drop_coins()
	if not coins.is_empty():
		for coin in coins:
			var item := CoinDisc.make()
			var tween := item.create_tween_for_drop(position, ground_position(position + Rand.point_in_circle(1.0 + log(coins.size()), 0)), 0.25)
			item.amount = ceili(coin * maxf(level / 10.0, 1.0))
			world.add_child(item)
			tween.play()
		return true
	return false
	
func drop_health_item(world: Node3D, multiplier: float) -> bool:
	var amount := drop_health()
	var h := amount * 0.25 + amount * 0.75 * multiplier
	if h > 0.0:
		var item := RedCross.make()
		var tween := item.create_tween_for_drop(position, ground_position(position + Rand.point_in_circle(3, 0)), 0.25)
		item.health = h
		world.add_child(item)
		tween.play()
		return true
	return false
	
func drop_scroll_note(world: Node3D) -> bool:
	var note_id := drop_note()
	if note_id != "":
		var item := ScrollNote.make()
		var tween := item.create_tween_for_drop(position, ground_position(position + Rand.point_in_circle(3, 0)), 0.25)
		item.note_id = note_id
		world.add_child(item)
		tween.play()
		return true
	return false
	
func update_vitals_display() -> void:
	(health_bar.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("percentage", vitals.health.percentage())
	var effects_shader := effects_mesh.mesh.surface_get_material(0) as ShaderMaterial
	effects_shader.set_shader_parameter("wet_progress", vitals.wetness.percentage())
	effects_shader.set_shader_parameter("freeze_progress", vitals.freeze.percentage())
	effects_shader.set_shader_parameter("burning_progress", vitals.burning.percentage())

func drop_artifact() -> Artifact:
	var class_p := class_level / 20.0
	var level_p := maxi(int(level) % 101, 1) / 100.0
	var min_p := class_p
	var max_p := level_p
	if min_p > max_p:
		min_p = level_p
		max_p = class_p
	if randf() >= randf_range(min_p, max_p):
		return null
	return Artifact.from_config(artifact_drop_probs, player.name_generator, velocity_movement.current_biome)
	
func drop_spell() -> Spell:
	var class_p := (class_level / 20.0) ** 2.718
	var level_p := maxi(int(level) % 101, 1) / 100.0
	var min_p := class_p
	var max_p := level_p
	if min_p > max_p:
		min_p = level_p
		max_p = class_p
	if randf() >= randf_range(min_p, max_p):
		return null
	var result := Rand.entity_from_distribution(randf(), spell_drop_probs, null) as Spell
	var new_name := player.name_generator.latin_names.generate(12, 2)
	result = result.duplicate({}, false).bake(new_name)
	result.clamp_variables(player.world_settings.upgrade_settings)
	result.seen_by_player = false
	return result
	
func drop_key() -> int:
	var norm_level := maxi(int(level) % 101, 1) # == [1, 100]
	
	if norm_level < 95:
		return 0
		
	var exp_p := float(norm_level - 96) # prob == [0, 4]
	var prob := maxf(0.0, (class_level / 20.0) ** ((5.0 - exp_p) * 4.0) - 0.05)
	
	if prob < randf():
		return 0
	
	return 1 << (velocity_movement.current_biome - 1)
		
	
## values must be in range [1, 100]
func drop_coins() -> Array[int]:
	@warning_ignore("integer_division")
	return cns(class_level / 4)
	
func drop_health() -> float:
	var p := class_level / 20.0
	if randf() < fit(p * 0.5, p) * ((1.0 - player.vitals.health.percentage()) ** 2.718):
		return health_drop(class_level)
	else:
		return 0.0
	
func drop_note() -> String:
	#var key_samples := GlobalData.game_settings.notes.keys()
	#key_samples.shuffle()
	#for key: String in key_samples:
		#if not GlobalData.game_settings.unlocked_notes.has(key):
			#return key
	return ""

# returns the actual value if the enemy with a class (1-20) where 1 is low 
func fit(mn: float, mx: float) -> float:
	return snappedf(lerpf(mn, mx, fl), 0.01)
	
func fiti(mn: int, mx: int) -> int:
	return roundi(lerpf(mn, mx, fl))
	
func fits(mn: float, mx: float) -> String:
	return Globals.format_number_nearest_place(lerpf(mn, mx, fl))
	
## fit between fit(mn_i, mx_i) 
func fita(mn: Array[float], mx: Array[float]) -> Array[float]:
	var result: Array[float] = []
	if mn.size() != mx.size():
		push_error("mn and mx not same size")
		return mn
	for i in mn.size():
		result.append(fit(mn[i], mx[i]))	
	return result
	
## fit between fit(arr_i, arr_i * mult) 
func fitas(mult: float, arr: Array[float]) -> Array[float]:
	var result: Array[float] = []
	for i in arr.size():
		result.append(fit(arr[i], arr[i] * mult))	
	return result
	
## fit between fit(arr_i, arr_i - arr_i * (1 - (1-mult)^exponent))
func fitase(mult: float, exponent: float, arr: Array[float]) -> Array[float]:
	var result: Array[float] = []
	for i in arr.size():
		result.append(fit(arr[i], arr[i] - arr[i] * (1 - pow(1 - mult, exponent))))	
	return result

func atk(cls: int) -> float:
	return fit(5.0, cls * 5.0)

func def(cls: int) -> float:
	return fit(5.0, cls * 5.0)
	
func hp(cls: int) -> float:
	return fit(0.0, 1.0) * 49.75 * cls + 5
	
func mana(cls: int) -> float:
	return fit(50.0, cls * 50.0)
	
func mana_regen(cls: int) -> float:
	return fit(5.0, cls * 5.0)

func power(cls: int) -> float:
	return fit(5.0, cls * 5.0)
	
func radius(cls: int) -> float:
	return fit(0.1, cls * cls / 81.0 + 0.1)
	
func ea(cls: int) -> float:
	return fit(0, (cls + 5) * 3)

func res(per_cls: int, flat_cls: int) -> Vector2:
	return Vector2(fit(0.0, per_cls / 20.0), fit(0.0, flat_cls * 5.0))
	
func percep(mncls: int, mxcls: int) -> Vector2:
	var mn := pow(float(mncls) / 20.0, 0.5) * 100
	var mx := pow(float(mxcls) / 20.0, 0.5) * 100
	return Vector2(mn, mx)
	
func atks(mncls: int, mxcls: int) -> String:
	var mn := 1.0 + pow(float(mncls) / 20.0, 1.5) * 39.0
	var mx := 1.0 + pow(float(mxcls) / 20.0, 1.5) * 39.0
	return fits(mn, mx)
	
func runs(cls: int) -> float:
	return fit(0.5, 2.0 + cls*0.5)
	
func dst(cls: int, x1: float, y1: float, z1: float, x2: float, y2: float, z2: float) -> Vector3:
	return Vector3(x1, y1, z1).normalized().lerp(Vector3(x2, y2, z2).normalized(), fit(1, cls * 10))

func atkd(cls: int) -> float:
	var base := 5.0 - cls / 5.0
	return fit(base, base / (cls + 1))

func atkds(clses: Array[int]) -> Array[float]:
	var result: Array[float] = []
	result.resize(clses.size())
	for i in clses.size():
		result[i] = atkd(clses[i])
	return result

func timing(cls: int, value: float) -> float:
	var ratio := 1.0 - float(cls) / 20.0
	return fit(value, value * (1.0 + ratio))

func timings(cls: int, array: Array[float]) -> Array[float]:
	var ratio := 1.0 - float(cls) / 20.0
	for i in array.size():
		array[i] = fit(array[i], array[i] * (1.0 + ratio))
	return array

func health_drop(cls: int) -> float:
	return snappedf(((float(cls) / 21.0) ** 2.718) * 0.5, 0.01)
	
func spell_drop(tier: int) -> float:
	return 1.0 / fit(tier, tier ** 2.718)
	
func artier(cls: int) -> Vector2i:
	var p := cls / 20.0
	var s := fiti(1, 10) * (1 if randf() < p else -1)
	var c := roundi(p * 4) + 1
	return Vector2i(s, c)
	
# cls = [1,5]
func cns(cls: int) -> Array[int]:
	# class 1:     [worst case] -> [best case]
	# - level   1: [1] -> [10, 10]
	# - level 100: [2] -> [20, 20]
	# class 2:
	# - level   1: [1, 1] -> [10, 10, 10, 10]
	# - level 100: [4, 4] -> [40, 40, 40, 40]
	# class 3:
	# - level   1: [1, 1, 1] -> [10, 10, 10, 10, 10, 10]
	# - level 100: [6, 6, 6] -> [60, 60, 60, 60, 60, 60]
	# class 4:
	# - level   1: [1, 1, 1, 1] -> [10, 10, 10, 10, 10, 10, 10, 10]
	# - level 100: [8, 8, 8, 8] -> [80, 80, 80, 80, 80, 80, 80, 80]
	# class 5:
	# - level   1: [1, 1, 1, 1, 1] -> [10, 10, 10, 10, 10, 10, 10, 10, 10, 10]
	# - level 100: [10, 10, 10, 10, 10] -> [100, 100, 100, 100, 100, 100, 100, 100, 100, 100]
	var count := Rand.roll(2, cls, 0)
	var result: Array[int] = []
	for i in count:
		result.append(Rand.roll(10, fiti(1, cls) + fiti(0, cls), 0))
	return result
