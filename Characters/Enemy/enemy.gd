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
var current_path: PathStyle:
	set(value):
		if value != current_path:
			current_path = value
			current_path.time = NAN
var still_path: PathStyle
var current_attack: AttackPatterns
var class_level: int = 10 # [1, 20]
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

var index_in_population: int = -1
signal vital_update(index_in_population: int, vitals: Vitals)
signal spell_was_cast(spell: Spell)
@onready var health_bar: MeshInstance3D = $HealthBar/Bar
@onready var level_text: Label3D = $HealthBar/Level
@onready var effects_mesh: MeshInstance3D = $HealthBar/Effects

func _ready() -> void:
	level_text.text = str(int(level))
	animator = $AnimationPlayer
	animation_tree = $AnimationTree
	collider = $Collision
	moving_platform_layers = Globals.Layer.OBJECT | Globals.Layer.ROCK
	max_snap_length = 0.0
	if kind == World.Enemy.NONE:
		setup(0, World.Biome.WATER)
	health_bar.visible = not is_idle
	
static func make(_kind: World.Enemy) -> Enemy:
	var result: Enemy

	
	const fish = preload("res://Characters/Enemy/Blob/Fish/fish.tscn") as PackedScene
	const bird = preload("res://Characters/Enemy/Blob/Bird/bird.tscn") as PackedScene
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
	update_behaviour()
	rotation.y = randf() * 2 * PI
	match kind:
		World.Enemy.BIRDMAN, World.Enemy.BLUEMON, World.Enemy.FISHMAN, World.Enemy.FROG, \
		World.Enemy.MOLE, World.Enemy.MUSHKING, World.Enemy.RABBIT, World.Enemy.UNDEAD, World.Enemy.WALKER, World.Enemy.ORC, World.Enemy.ORC_DEAD: 
			frame_count = Vector2(30, 17)
			sfx_attack = AudioManager.AudioStreamKind.ATTACK_MED
			sfx_hurt = AudioManager.AudioStreamKind.HURT_MED
		World.Enemy.BIRD, World.Enemy.FISH, World.Enemy.FUNGI, World.Enemy.HOT_BLOB, World.Enemy.MUSHROOM, \
		World.Enemy.SNOT_BLOB, World.Enemy.SNOT_SPIKE, World.Enemy.WALKER_HEAD, World.Enemy.WIZARD, World.Enemy.BOUGEON: 
			frame_count = Vector2(13, 13)
			sfx_attack = AudioManager.AudioStreamKind.ATTACK_BEAST
			sfx_hurt = AudioManager.AudioStreamKind.HURT_BEAST
		World.Enemy.BAT, World.Enemy.BATTY, World.Enemy.BEE, World.Enemy.BUMBLE_BEE, World.Enemy.DRAGON, \
		World.Enemy.DRAGOON, World.Enemy.GHOST, World.Enemy.GHOSTLY, World.Enemy.UNDEAD_HEAD, World.Enemy.FLYGEON, \
		World.Enemy.PINKMON, World.Enemy.REDMON, World.Enemy.GOBLIN, World.Enemy.GOBLIN_KING: 
			frame_count = Vector2(35, 25)
			sfx_attack = AudioManager.AudioStreamKind.ATTACK_FLY
			sfx_hurt = AudioManager.AudioStreamKind.HURT_FLY
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
	
func set_path_and_attack(path: PathStyle, attack: AttackPatterns) -> void:
	attack_sequence = null
	current_path = path
	current_attack = attack
	
func set_attack_sequence(atk_seq: AttackSequence) -> void:
	current_path = null
	current_attack = null
	attack_sequence = atk_seq

func _physics_process(delta: float) -> void:
	if kind == World.Enemy.NONE or player.magic_book.settings.is_paused:
		return
	
	var dist := 1.0 - clampf(maxf(position.distance_to(player.position) - Globals.enemy_update_radius(), 0.0) / Globals.enemy_update_radius(), 0.0, 1.0)
	var tick_scale := maxf(pow(dist, 2.0), 0.01)
	increment_ticks(delta * tick_scale)
			
	var group_positioning_adjustment := (player.enemies_in_range[self] as Player.CombatStats).seperation if player.enemies_in_range.has(self) else Vector3.ZERO
	var current_frame_count := frame_count.x if velocity.length() < 0.166667 else frame_count.y
	velocity_movement.update_movement_speed(speed_for_current_behaviour_tick, bounds.y, current_frame_count)
	var movement := velocity_movement.update(delta, vitals, speed_for_current_behaviour_tick, self, current_path.lookat == PathStyle.LookAt.VELOCITY, player.world_settings.sea_level, player.world_settings.world_radius, player.chunker)
	if vitals.did_update_on_tick:
		vital_update.emit(index_in_population, vitals)
	if not is_dead and vitals.health.value <= vitals.health.min_value:
		die()
	update_vitals_display()
	
	var is_on_floor_1_not_on_floor_2_else_check_0: int = 0
	var did_move := false
	if snappedf(move_tick, 0.00001) < Globals.move_tick():
		if velocity_movement.impulse != Vector3.ZERO or current_path.mover == PathStyle.Mover.PHYSICS:
			velocity = movement["velocity"]
			move_and_slide()
			pushed_with_impulse = not is_on_floor
	else:
		did_move = true
		move_tick = 0.0
		if velocity_movement.impulse != Vector3.ZERO:
			velocity = movement["velocity"]
			move_and_slide()
			pushed_with_impulse = not is_on_floor
		else:
			match current_path.mover:
				PathStyle.Mover.PHYSICS:
					velocity = movement["velocity"]
					move_and_slide()
					pushed_with_impulse = not is_on_floor
				PathStyle.Mover.ABSOLUTE:
					var v: Vector3 
					var t: Vector3
					v = movement["absolute"]
					t = movement["target"]
					var g := Navigator.get_world_height(get_world_3d().direct_space_state, position.x, position.z)
					if feet_position() < g:
						if current_path.coord_y == PathStyle.CoordY.GROUND or current_path.coord_y == PathStyle.CoordY.GROUND_AND_AIR:
							if pushed_with_impulse:
								pushed_with_impulse = feet_position() + t.y < g
								v.y = 0
							else:
								set_feet_position(g)
								t.y = 0
								v.y = 0
						else:
							pushed_with_impulse = false
					elif feet_position() > g:
						if current_path.coord_y == PathStyle.CoordY.GROUND or current_path.coord_y == PathStyle.CoordY.GROUND_AND_DIRT:
							if pushed_with_impulse:
								pushed_with_impulse = feet_position() + t.y > g
								v.y = 0
							else:
								set_feet_position(g)
								t.y = 0
								v.y = 0
						else:
							pushed_with_impulse = false
					is_on_floor_1_not_on_floor_2_else_check_0 = 1 if abs(feet_position() - g) < 0.1 else 2
					velocity = Vector3(v.x, v.y + t.y, v.z)
					position += Vector3(v.x, v.y + t.y, v.z) + group_positioning_adjustment * delta * speed_for_current_behaviour_tick
					
			if current_path.lookat == PathStyle.LookAt.PLAYER:
				var t := Globals.looking_at(self, player.transform.origin)
				var v := maxf(velocity.length(), delta)
				global_transform.basis.y = global_transform.basis.y.slerp(t.basis.y, v)
				global_transform.basis.x = global_transform.basis.x.slerp(t.basis.x, v)
				global_transform.basis.z = global_transform.basis.z.slerp(t.basis.z, v)
			elif current_path.lookat == PathStyle.LookAt.PLAYER_XZ:
				var player_transform := player.transform
				player_transform.translated(Vector3(0, -player.global_position.y + global_position.y, 0))
				var t := Globals.looking_at(self, player_transform.origin)
				var v := maxf(velocity.length(), delta)
				global_transform.basis.y = global_transform.basis.y.slerp(t.basis.y, v)
				global_transform.basis.x = global_transform.basis.x.slerp(t.basis.x, v)
				global_transform.basis.z = global_transform.basis.z.slerp(t.basis.z, v)
		

	var reset_spell_tick := false
	var behavior_ticked_over := ((behavior_tick > Globals.behaviour_tick()) or is_equal_approx(behavior_tick, Globals.behaviour_tick()))
	
	if is_nan(time_since_navigation_update):
		time_since_navigation_update = 0.0
	if (behavior_ticked_over or (not velocity_movement.has_navigation_target and tick_scale == 1.0)):
		if behavior_ticked_over:
			update_behaviour()
			behavior_tick = 0
		if not velocity_movement.has_navigation_target:
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
			velocity_movement.target_path = GlobalData.nav.find_target_path(obj, next_pos, collision_shape.shape, options, 1000.0, Vec3.max(player.bounds))
			velocity_movement.target_position = Navigator.find_next_target_from_path(velocity_movement.target_path, position, obj, next_pos)
			#var clr := Color(randf(), randf(), randf())
			#Debug3D.draw_sphere(position + Vector3(0, 2, 0), 0.5, clr, 0.2)
			#for p in velocity_movement.target_path:
				#Debug3D.draw_sphere(p, 0.1, clr, 0.2)
			if reset_spell_tick:
				behavior_tick = Globals.behaviour_tick()

	if (reset_spell_tick or (spell_tick >= (1.0 + vitals.freeze.value) and vitals.stun.value == 0 and vitals.freeze.value < 1.0)):
		var spell: Spell = null
		if attack_sequence:
			if attack_sequence.last_attack:
				spell = current_attack.choose_spell(vitals)
		else:
			spell = current_attack.choose_spell(vitals)
		spell_tick = 0
		if spell != null:
			play_animation("attack")
			AudioManager.play(sfx_attack, position, NAN, true, Vector2(0.8, 1.2))
			await get_parent_node_3d().get_tree().create_timer(animator.get_animation(animation_map["attack"] as StringName).length / 2.0).timeout
			await get_tree().physics_frame
			cast_spell(insert_spell, spell)
		

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
						#play_walking_audio(NoiseBlender.walking_audio_for_biome(current_biome))
						play_animation("walk", {"parameters/walk/speed/scale": velocity_movement.movement_speed_animation_scale()})
					else:
						#play_walking_audio(NoiseBlender.walking_audio_for_biome(current_biome))
						play_animation("run", {"parameters/run/speed/scale": velocity_movement.movement_speed_animation_scale()})
			else:
				idle_tick += delta
				if final_is_on_floor and idle_tick > 0.5:
					play_walking_audio("empty")
					play_animation("idle")
					idle_tick = 0
				
			if not final_is_on_floor:
				play_animation("fall")
			elif current_animation_is("fall"):
				play_animation("land")


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
		if player.position.distance_to(position) < vitals.perception.min_value:
			is_idle = false
	else:
		if player.position.distance_to(position) > vitals.perception.max_value:
			is_idle = true
	
	if old_is_idle != is_idle or not is_idle_is_set:
		if is_idle:
			player.ignore_enemy(self)
		else:
			player.watch_enemy(self)
			
		if health_bar != null:
			health_bar.visible = not is_idle
			
		is_idle_is_set = true
		

func handle_damage() -> void:
	pass
	
func die() -> void:
	is_dead = true
	var explosion: Node3D = preload("res://Characters/Enemy/enemy_die.tscn").instantiate()
	var source := explosion.get_node("source") as GPUParticles3D
	(source.process_material as ParticleProcessMaterial).emission_box_extents = bounds
		
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
	
	# drop only one of key/artifact/spell based on said priority
	if not drop_key_item(world):
		if not drop_artifact_item(world):
			drop_spell_item(world)
	drop_coin_items(world)
	drop_health_item(world, multiplier)
	drop_scroll_note(world)
	
	SignalBus.enemy_death.emit(get_node("."))
	world.get_tree().create_timer(Globals.particle_system_lifetime(source)).timeout.connect(func() -> void: explosion.queue_free())
	
		
func drop_artifact_item(world: Node3D) -> bool:
	var artifact: Artifact = drop_artifact()
	if artifact:
		var item := ArtifactCube.make()
		item.position = position
		item.global_transform = global_transform
		item.artifact = artifact
		world.add_child(item)
		return true
	return false
		
		
func drop_spell_item(world: Node3D) -> bool:
	var spell: Spell = drop_spell()
	if spell:
		var item := SpellPaper.make()
		item.position = position
		item.global_transform = global_transform
		item.spell = spell
		world.add_child(item)
		return true
	return false
		
func drop_key_item(world: Node3D) -> bool:
	var key: int = drop_key()
	if key != 0 and (player.world_settings.player_keys & key == 0):
		var item := KeyPrism.make()
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
			var item := CoinDisc.make()
			item.position = position
			item.global_transform = global_transform.translated(Rand.point_in_circle(1.0 + log(coins.size()), 0))
			item.amount = ceili(coin * maxf(level / 10.0, 1.0))
			world.add_child(item)
		return true
	return false
	
func drop_health_item(world: Node3D, multiplier: float) -> bool:
	var amount := drop_health()
	var h := amount * 0.25 + amount * 0.75 * multiplier
	if h > 0.0:
		var item := RedCross.make()
		item.position = position
		item.global_transform = global_transform.translated(Rand.point_in_circle(3, 0))
		item.health = h
		world.add_child(item)
		return true
	return false
	
func drop_scroll_note(world: Node3D) -> bool:
	var note_id := drop_note()
	if note_id != "":
		var item := ScrollNote.make()
		item.position = position
		item.global_transform = global_transform.translated(Rand.point_in_circle(3, 0))
		item.note_id = note_id
		world.add_child(item)
		return true
	return false
	
func update_vitals_display() -> void:
	(health_bar.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("percentage", vitals.health.percentage())
	var effects_shader := effects_mesh.mesh.surface_get_material(0) as ShaderMaterial
	effects_shader.set_shader_parameter("wet_progress", vitals.wetness.percentage())
	effects_shader.set_shader_parameter("freeze_progress", vitals.freeze.percentage())
	effects_shader.set_shader_parameter("burning_progress", vitals.burning.percentage())

func drop_artifact() -> Artifact:
	if artifact_drop_probs.is_empty():
		return null
		
	var n: String
	var b: World.Biome = (velocity_movement.current_biome - 1) as World.Biome
	match b:
		World.Biome.GRASSLAND: n = player.name_generator.german_names.generate(16, 2)
		World.Biome.TAIGA: n = player.name_generator.russian_names.generate(14, 2)
		World.Biome.FOREST: n = player.name_generator.english_names.generate(8, 1)
		World.Biome.DESERT: n = player.name_generator.spanish_names.generate(16, 3)
		World.Biome.JUNGLE: n = player.name_generator.indian_names.generate(12, 2)
		World.Biome.SAVANNAH: n = player.name_generator.roman_names.generate(12, 2)
		World.Biome.TUNDRA: n = player.name_generator.iclandic_names.generate(14, 2)
		World.Biome.OTHERWORLD: n = player.name_generator.constellations.generate(18, 4)
		World.Biome.HFIL: n = player.name_generator.capital_cities.generate(18, 4)
		_: push_error("missing biome kind")
		
	var result := Artifact.nulled(n)
	var fill_with := func (positions: Array[Vector2i], probs: Dictionary) -> void:
		var tier := probs["tier"] as Vector2i
		var pattern := probs["pattern"] as Dictionary
		if probs.has("is_effect"):
			var is_effect := probs["is_effect"] as float
			var ev_element := probs["ev_element"] as Dictionary
			var ef_element := probs["ef_element"] as Dictionary
			var effect := probs["effect"] as Dictionary
			var event := probs["event"] as Dictionary
			result.fill([Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT], is_effect, effect, event, ef_element, ev_element, pattern, tier)
		elif probs.has("effect"):
			var element := probs["element"] as Dictionary
			var effect := probs["effect"] as Dictionary
			result.fill([Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT], 1.0, effect, {}, element, {}, pattern, tier)
		elif probs.has("event"):
			var element := probs["element"] as Dictionary
			var event := probs["event"] as Dictionary
			result.fill([Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT], 1.0, {}, event, {}, element, pattern, tier)
		
	
	if artifact_drop_probs.has("all"):
		fill_with.call([Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT], artifact_drop_probs["all"])
	else:
		for key: String in artifact_drop_probs:
			var probs := artifact_drop_probs[key] as Dictionary
			if key.contains("W"): fill_with.call([Vector2i.LEFT], probs)
			if key.contains("E"): fill_with.call([Vector2i.RIGHT], probs)
			if key.contains("N"): fill_with.call([Vector2i.UP], probs)
			if key.contains("S"): fill_with.call([Vector2i.DOWN], probs)
	
	result.seen_by_player = false
	return result
	
func drop_spell() -> Spell:
	var result := Rand.entity_from_distribution(randf(), spell_drop_probs, null) as Spell
	var new_name := player.name_generator.latin_names.generate(12, 2)
	result.duplicate({}, false).bake(new_name)
	result.seen_by_player = false
	return result
	
func drop_key() -> int:
	var norm_level := int(level) % 101 # == [0, 100]
	
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
	if randf() < fit(p * 0.5, p) * (1.0 - player.vitals.health.percentage()):
		return health_drop(class_level)
	else:
		return 0.0
	
func drop_note() -> String:
	var key_samples := GlobalData.game_settings.notes.keys()
	key_samples.shuffle()
	for key: String in key_samples:
		if not GlobalData.game_settings.unlocked_notes.has(key):
			return key
	return ""

func play_walking_audio(stream: String) -> void:
	pass

# returns the actual value if the enemy with a class (1-20) where 1 is low 
func fit(mn: float, mx: float) -> float:
	return lerpf(mn, mx, fl)
	
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
	return fit(50.0, cls * 50.0)
	
func mana(cls: int) -> float:
	return fit(50.0, cls * 50.0)
	
func mana_regen(cls: int) -> float:
	return fit(5.0, cls * 5.0)

func power(cls: int) -> float:
	return fit(5.0, cls * 5.0)
	
func radius(cls: int) -> float:
	return fit(0.1, minf(cls * cls / 80.0 + 0.875, 5.0))
	
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
	return float(cls) / 20.0
	
func spell_drop(tier: int) -> float:
	return 1.0 / fit(tier, tier ** 2)
	
func artier(cls: int) -> Vector2i:
	var p := cls / 20.0
	var s := fiti(1, 10) * (1 if randf() < p else -1)
	var c := roundi(p * 9) + 1
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
