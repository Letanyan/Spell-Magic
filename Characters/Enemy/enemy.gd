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
var level: float # Use float so it's easy to use in expressions. However, should only be whole numbers.
var fl: float:
	get:
		return level / 100.0
var invfl: float:
	get:
		return 1.0 - level / 100.0
var is_dead: bool = false
var kind: World.Enemy = World.Enemy.NONE
var is_idle := true
var is_idle_is_set := false

var behavior_tick: float = 0
var spell_tick: float = 0
var idle_tick: float = 0
var move_tick: float = 0
var speed_for_current_behaviour_tick := 0.0
var path_movement_remaining_duration := 0.0
var time_since_navigation_update := NAN

var index_in_population: int = -1
signal vital_update(index_in_population: int, vitals: Vitals)
@onready var health_bar: MeshInstance3D = $HealthBar/Bar
@onready var level_text: Label3D = $HealthBar/Level
@onready var effects_mesh: MeshInstance3D = $HealthBar/Effects

func _ready() -> void:
	level_text.text = str(int(level))
	animator = $AnimationPlayer
	animation_tree = $AnimationTree
	collider = $Collision
	moving_platform_layers = Globals.Layer.OBJECT | Globals.Layer.ROCK
	if kind == World.Enemy.NONE:
		setup(0, World.Biome.WATER)
	health_bar.visible = not is_idle
	
static func make(_kind: World.Enemy) -> Enemy:
	var result: Enemy
	const fish = preload("res://Characters/Enemy/Blob/Fish/fish.tscn") as PackedScene
	const bird = preload("res://Characters/Enemy/Blob/Bird/Bird.tscn") as PackedScene
	const fungi = preload("res://Characters/Enemy/Blob/Fungi/Fungi.tscn") as PackedScene
	const hot_blob = preload("res://Characters/Enemy/Blob/HotBlob/HotBlob.tscn") as PackedScene
	const mushroom = preload("res://Characters/Enemy/Blob/Mushroom/Mushroom.tscn") as PackedScene
	const snot_blob = preload("res://Characters/Enemy/Blob/SnotBlob/snot_blob.tscn") as PackedScene
	const snot_spike = preload("res://Characters/Enemy/Blob/SnotSpike/snot_spike.tscn") as PackedScene
	const walker_head = preload("res://Characters/Enemy/Blob/WalkerHead/walker_head.tscn") as PackedScene
	const wizard = preload("res://Characters/Enemy/Blob/Wizard/wizard.tscn") as PackedScene
	
	const undead = preload("res://Characters/Enemy/Tall/Undead/undead.tscn") as PackedScene
	const mole = preload("res://Characters/Enemy/Tall/Mole/mole.tscn") as PackedScene
	const walker = preload("res://Characters/Enemy/Tall/Walker/walker.tscn") as PackedScene
	const birdman = preload("res://Characters/Enemy/Tall/Birdman/birdman.tscn") as PackedScene
	const fishman = preload("res://Characters/Enemy/Tall/Fishman/fishman.tscn") as PackedScene
	const bluemon = preload("res://Characters/Enemy/Tall/Bluemon/bluemon.tscn") as PackedScene
	const frog = preload("res://Characters/Enemy/Tall/Frog/frog.tscn") as PackedScene
	const mushking = preload("res://Characters/Enemy/Tall/MushKing/mushking.tscn") as PackedScene
	const rabbit = preload("res://Characters/Enemy/Tall/Rabbit/rabbit.tscn") as PackedScene
	
	const bat = preload("res://Characters/Enemy/Flying/Bat/bat.tscn") as PackedScene
	const dragon = preload("res://Characters/Enemy/Flying/Dragon/Dragon.tscn") as PackedScene
	const dragoon = preload("res://Characters/Enemy/Flying/Dragoon/Dragoon.tscn") as PackedScene
	const ghost = preload("res://Characters/Enemy/Flying/Ghost/Ghost.tscn") as PackedScene
	const ghostly = preload("res://Characters/Enemy/Flying/Ghostly/Ghostly.tscn") as PackedScene
	const batty = preload("res://Characters/Enemy/Flying/Batty/batty.tscn") as PackedScene
	const bee = preload("res://Characters/Enemy/Flying/Bee/bee.tscn") as PackedScene
	const bumble_bee = preload("res://Characters/Enemy/Flying/BumbleBee/bumble_bee.tscn") as PackedScene
	const undead_head = preload("res://Characters/Enemy/Flying/UndeadHead/undead_head.tscn") as PackedScene
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
		World.Enemy.SNOT_BLOB: result = snot_blob.instantiate()
		World.Enemy.SNOT_SPIKE: result = snot_spike.instantiate()
		World.Enemy.WALKER_HEAD: result = walker_head.instantiate()
		World.Enemy.WIZARD: result = wizard.instantiate()
		_: push_error("Missing enemy")
		
	result.spell_caster = SpellCaster.new(result, SpellCaster.Entity.ENEMY)
	result.still_path = PathStyle.still_path()
	result.current_path = result.still_path
	if not result.bounds:
		result.bounds = Navigator.shape_bounds((result.get_node("Collision") as CollisionShape3D).shape)
		#(result.get_node("Collision") as CollisionShape3D).disabled = true
		#(result.get_node("WetArea/WetCollision") as CollisionShape3D).disabled = true
		
	return result
	
func setup(seedling: int, biome: World.Biome) -> void:
	update_behaviour()
	rotation.y = randf() * 2 * PI
	
func set_level_relative_to_location(rng: RandomNumberGenerator, x: float, y: float) -> void:
	var p := clampf(Vector2(x, y).length() / 10000.0, 0.0, 100.0)
	var base := 45.0 * (log(p + 1.0) / log(10.0))
	var offset_max_range := (p * p) / 10000.0 + 2 * sin(p * PI / 10.0)
	var random_offset := 0.0
	if rng == null:
		random_offset = randf_range(0.0, absf(offset_max_range))
	else:
		random_offset = rng.randf_range(0.0, absf(offset_max_range))
	level = maxf(base + random_offset, 1.0)
	if level_text != null:
		level_text.text = str(int(level))
		
func separation_multiplier() -> float:
	return 1.05
	
func add_shake(amount: float) -> void:
	player.add_shake(amount)
	
func increment_ticks(delta: float) -> void:
	behavior_tick += delta
	spell_tick += delta
	move_tick += delta
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
	
	var dist := 1.0 - clampf(maxf(position.distance_to(player.position) - Globals.enemy_update_radius(), 0.0) / Globals.enemy_update_radius(), 0.0, 1.0)
	var tick_scale := maxf(pow(dist, 2.0), 0.01)
	increment_ticks(delta * tick_scale)
			
	var group_positioning_adjustment := (player.enemies_in_range[self] as Player.CombatStats).seperation if player.enemies_in_range.has(self) else Vector3.ZERO
	var movement := velocity_movement.update(delta, vitals, speed_for_current_behaviour_tick, self, current_path.lookat == PathStyle.LookAt.VELOCITY)
	vital_update.emit(index_in_population, vitals)
	if not is_dead and vitals.health.value <= vitals.health.min_value:
		die()
	update_vitals_display()
	
	var is_on_floor_1_not_on_floor_2_else_check_0: int = 0
	if move_tick >= Globals.move_tick():
		move_tick = 0.0
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
					if feet_position() < g:
						if current_path.coord_y == PathStyle.CoordY.GROUND or current_path.coord_y == PathStyle.CoordY.GROUND_AND_AIR:
							set_feet_position(g)
							t.y = 0
							v.y = 0
					elif feet_position() > g:
						if current_path.coord_y == PathStyle.CoordY.GROUND or current_path.coord_y == PathStyle.CoordY.GROUND_AND_DIRT:
							set_feet_position(g)
							t.y = 0
							v.y = 0
					is_on_floor_1_not_on_floor_2_else_check_0 = 1 if abs(feet_position() - g) < 0.1 else 2
					velocity = Vector3(v.x, v.y + t.y, v.z)
					position += Vector3(v.x, v.y + t.y, v.z) + group_positioning_adjustment * delta * speed_for_current_behaviour_tick
					
			if current_path.lookat == PathStyle.LookAt.PLAYER:
				var goal_position := position + velocity * 10
				var looking_at := player.position.lerp(goal_position, clampf(velocity.length() / 100.0, 0.0, 1.0))
				if not looking_at.is_equal_approx(position):
					look_at(looking_at)
			elif current_path.lookat == PathStyle.LookAt.PLAYER_XZ:
				var goal_position := position + velocity * 10
				var player_position := player.position
				player_position.y = position.y
				var looking_at := player_position.lerp(goal_position, clampf(velocity.length() / 100.0, 0.0, 1.0))
				if not looking_at.is_equal_approx(position):
					look_at(looking_at)
		

	var reset_spell_tick := false
	var behavior_ticked_over := ((behavior_tick > Globals.behaviour_tick()) or is_equal_approx(behavior_tick, Globals.behaviour_tick()))
	
	if is_nan(time_since_navigation_update):
		time_since_navigation_update = Time.get_unix_time_from_system()
	if (behavior_ticked_over or (not velocity_movement.has_navigation_target and tick_scale == 1.0)):
		if behavior_ticked_over:
			update_behaviour()
			behavior_tick = 0
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
			if current_path.coord_y == PathStyle.CoordY.GROUND_AND_AIR or current_path.coord_y == PathStyle.CoordY.ORIGIN or current_path.coord_y == PathStyle.CoordY.AIR:
				options |= Navigator.MovementOptions.CAN_FLY
			var obj := get_node(".") as CharacterBody
			velocity_movement.target_path = GlobalData.nav.find_target_path(obj, next_pos, collision_shape.shape, options, 1000.0, 0.5)
			velocity_movement.target_position = Navigator.find_next_target_from_path(velocity_movement.target_path, position, obj, next_pos)
			#var clr := Color(randf(), randf(), randf())
			#DebugDraw3D.draw_sphere(position + Vector3(0, 2, 0), 0.5, clr, 0.2)
			#for p in velocity_movement.target_path:
				#DebugDraw3D.draw_sphere(p, 0.1, clr, 0.2)
			if reset_spell_tick:
				behavior_tick = Globals.behaviour_tick()

	if (reset_spell_tick or (spell_tick >= (1.0 + vitals.freeze.value) and vitals.stun.value == 0 and vitals.freeze.value < 1.0)):
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
		final_is_on_floor = is_on_floor
	else:
		final_is_on_floor = is_on_floor_1_not_on_floor_2_else_check_0 == 1
		
	if animation_tree.active:
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
				play_walking_audio("empty")
				play_animation("idle")
				idle_tick = 0
			
		if not final_is_on_floor:
			play_animation("fall")
		elif current_animation_is("fall"):
			play_animation("land")


func cast_spell(insert: Callable, next_spell: Spell) -> MagicBook.DisallowSpellReason:
	return spell_caster.cast_spell(self, vitals, insert, next_spell)


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
	if key != 0:
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
	return null
	
func drop_spell() -> Spell:
	return null
	
func drop_key() -> int:
	return 0
	
func drop_coins() -> Array[int]: # values must be in range [1, 10]
	return []
	
func drop_health() -> float:
	return 0.0
	
func drop_note() -> String:
	var key_samples := GlobalData.game_settings.notes.keys()
	key_samples.shuffle()
	for key: String in key_samples:
		if not GlobalData.game_settings.unlocked_notes.has(key):
			return key
	return ""
	

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
	elif n is Bird:
		return World.Enemy.BIRD
	elif n is Fungi:
		return World.Enemy.FUNGI
	elif n is HotBlob:
		return World.Enemy.HOT_BLOB
	elif n is Mushroom:
		return World.Enemy.MUSHROOM
	elif n is Bluemon:
		return World.Enemy.BLUEMON
	elif n is Frog:
		return World.Enemy.FROG
	elif n is Mushking:
		return World.Enemy.MUSHKING
	elif n is Rabbit:
		return World.Enemy.RABBIT
	elif n is Batty:
		return World.Enemy.BATTY
	elif n is Bee:
		return World.Enemy.BEE
	elif n is BumbleBee:
		return World.Enemy.BUMBLE_BEE
	elif n is UndeadHead:
		return World.Enemy.UNDEAD_HEAD
	elif n is SnotBlob:
		return World.Enemy.SNOT_BLOB 
	elif n is SnotSpike:
		return World.Enemy.SNOT_SPIKE 
	elif n is WalkerHead:
		return World.Enemy.WALKER_HEAD 
	elif n is Wizard:
		return World.Enemy.WIZARD
	
	return World.Enemy.NONE

func play_walking_audio(stream: String) -> void:
	pass

# returns the actual value if the enemy with a class (1-20) where 1 is low 
func fit(mn: float, mx: float) -> float:
	return lerpf(mn, mx, fl)
	
func fiti(mn: int, mx: int) -> int:
	return roundi(lerpf(mn, mx, fl))
	
func fits(mn: float, mx: float) -> String:
	return Globals.format_number_nearest_place(lerpf(mn, mx, fl))
	
func fita(mn: Array[float], mx: Array[float]) -> Array[float]:
	var result: Array[float] = []
	if mn.size() != mx.size():
		push_error("mn and mx not same size")
		return mn
	for i in mn.size():
		result.append(fit(mn[i], mx[i]))	
	return result
	
func fitas(mult: float, arr: Array[float]) -> Array[float]:
	var result: Array[float] = []
	for i in arr.size():
		result.append(fit(arr[i], arr[i] * mult))	
	return result
	
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

func res(per_cls: int, flat_cls: int) -> Vector2:
	return Vector2(fit(0.0, per_cls / 20.0), fit(0.0, flat_cls * 5.0))
	
func percep(mncls: int, mxcls: int) -> Vector2:
	var mn := pow(float(mncls) / 20.0, 0.5) * 100
	var mx := pow(float(mxcls) / 20.0, 0.5) * 100
	return Vector2(mn, mx)
	
func atks(mncls: int, mxcls: int) -> String:
	var mn := 1.0 + pow(float(mncls) / 20.0, 1.5) * 31.0
	var mx := 1.0 + pow(float(mxcls) / 20.0, 1.5) * 31.0
	return fits(mn, mx)

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
