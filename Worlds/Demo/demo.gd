class_name DemoWorld
extends Node3D

@onready var player: Player = $Player
@onready var menu: Menu = $SubViewportContainer/SubViewport/Menu
@onready var hud: HUD = $HUD
@onready var fps: Label = $FPS
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer


const CHUNK_SIZE = 256
@onready var blender: NoiseBlender
@onready var chunker: Terrain
@onready var population: Dictionary = {} # [Vector2]Population
var entity_manager: EntityManager

var last_biome: World.Biome = World.Biome.WATER

@onready var skybox: SkyBox
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $Sun
@onready var moon: DirectionalLight3D = $Moon
var biome_tween_next := -1
var biome_tween: Tween = null

var terrain_update_interval := 0.0
var has_init_terrain_population := false

var ready_state: GameSettings.ReadyState = GameSettings.ReadyState.NOT

var book: MagicBook
var case: WandCase
var wand: Wand
var artifacts: Artifacts

var knowledge_tick: float = 0.0
var daytime_tick: float = 0.0

var settings: WorldSettings
var pause_start: float

func setup(_settings: WorldSettings) -> void:
	settings = _settings
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if settings.is_test_arena:
		book = GlobalData.magic_book
		book.settings = settings
	else:
		book = MagicBook.new()
		book.settings = settings
		book.read(settings.world_name)
		book.rebuild_spell_chains()
		book.ignore_cooldown = OS.is_debug_build()
	
	book.update_spell_limits(settings.upgrade_settings.max_v, settings.upgrade_settings.max_r)
	settings.upgrade_settings.max_velocity_updated.connect(func(v: float) -> void:
		book.update_spell_limits(v, settings.upgrade_settings.max_r)
	)
	settings.upgrade_settings.max_radius_updated.connect(func(r: float) -> void:
		book.update_spell_limits(settings.upgrade_settings.max_v, r)
	)
	settings.upgrade_settings.upgrade_was_purchased.connect(func(us: UpgradeSettings) -> void:
		player.vitals.health.max_value = us.max_health
		player.vitals.mana.max_value = us.max_mana
		player.vitals.mana.change_per_tick = us.max_mana_regen
		player.vitals.attack.set_fixed_value(us.max_attack)
		player.vitals.defence.set_fixed_value(us.max_defence)
	)
	
	case = WandCase.new()
	case.read(settings.world_name)
	
	artifacts = Artifacts.new()
	artifacts.read(settings.world_name)
	
#	for i in ["flower 2", "feather 2", "goblet 2", "sands 2", "crown 2"]:
#		var artifact := Artifact.new(i)
#		artifact.top = Artifact.Option.make_random()
#		artifact.bottom = Artifact.Option.make_random()
#		artifact.left = Artifact.Option.make_random()
#		artifact.right = Artifact.Option.make_random()
#		artifacts.collection.append(artifact)
	
	entity_manager = EntityManager.new()
	
	GlobalData.game_settings.last_world = settings.world_name
	GlobalData.game_settings.save()
	
func run_on_ready() -> void:
	ready_state = GameSettings.ReadyState.IN
	if book == null:
		var _settings := WorldSettings.new(get_viewport())
		_settings.read("test+arena")
		_settings.is_test_arena = true
		#_settings.world_name = "demo"
		#_settings.sed = 0 
		setup(_settings)
		
	settings.upgrade_settings.currency = 10000
	menu.setup(book, case, artifacts, settings)
	
	wand = case.current_wand()
	menu.wand_case.use_current_wand = func(id: int) -> void:
		wand = case.wands[id]
		
	menu.close_menu.connect(toggle_menu)
		
	# Forest location for world seed 0
	#player.position.x = 800
	#player.position.y = 700
	#player.position.z = 2300
	player.position = settings.player_position
	player.spell_caster.ignore_mana_cost = OS.is_debug_build()
	player.spell_velocity_was_buffed.connect(func(v: float) -> void:
		book.update_spell_buff_limits(v, settings.upgrade_settings.buff_r)
	)
	player.spell_radius_was_buffed.connect(func(r: float) -> void:
		book.update_spell_buff_limits(settings.upgrade_settings.buff_v, r)
	)
	player.attack_was_buffed.connect(func(atk: float) -> void:
		book.update_spell_attack_and_defence(atk, settings.upgrade_settings.buff_defence)
	)
	player.defence_was_buffed.connect(func(def: float) -> void:
		book.update_spell_attack_and_defence(settings.upgrade_settings.buff_attack, def)
	)
	player.vitals.health.max_value = settings.upgrade_settings.max_health
	player.vitals.mana.max_value = settings.upgrade_settings.max_mana
	player.vitals.mana.change_per_tick = settings.upgrade_settings.max_mana_regen
	player.vitals.health.set_value(settings.player_health)
	player.vitals.mana.set_value(settings.player_mana)
	player.vitals.attack.set_fixed_value(settings.upgrade_settings.max_attack)
	player.vitals.defence.set_fixed_value(settings.upgrade_settings.max_defence)
	player.world_settings = settings
	player.name_generator = NameGenerator.new()
	player.name_generator.read(settings.world_name)
		
	blender = NoiseBlender.new(settings.sed)
	chunker = Terrain.new(blender, CHUNK_SIZE, 2, 0.0625, 16)
	build_terrain()
	
	SignalBus.enemy_death.connect(enemy_dies)
	
	skybox = SkyBox.new(world_environment, sun, moon)
	skybox.day_time = settings.time_of_day
	skybox.day_of_year = settings.day_of_the_year
	
	player.magic_book = book
	player.artifacts = artifacts
	hud.player = player
	hud.book = book
	hud.wand = wand
	menu.wand_case.new_wand_selected.connect(hud.set_wand)
	
	menu.settings.settings_changed.connect(hud.update_settings)
	hud.update_settings(settings)
	
	var theme := load(ProjectSettings.get("gui/theme/custom") as String) as ThemeUI
	theme.change_tint_color(Color(0.0, 0.360784, 0.643137))
	ready_state = GameSettings.ReadyState.IS
	
	await RenderingServer.frame_post_draw
	(player.interface.mesh.surface_get_material(0) as StandardMaterial3D).albedo_texture = sub_viewport.get_texture()
	sub_viewport_container.visible = false

func _ready() -> void:
	if ready_state == GameSettings.ReadyState.NOT:
		run_on_ready()

func _exit_tree() -> void:
	pass
	
func _process(delta: float) -> void:
	var b := blender.biome
	fps.text = "[" + World.Biome.keys()[b] + "] " + str(player.position) + " FPS: " + str(Engine.get_frames_per_second())
	
func _physics_process(delta: float) -> void:
	if player.magic_book.settings.is_paused:
		return
	
	knowledge_tick += delta
	daytime_tick += delta

	if knowledge_tick >= Globals.knowledge_tick() and has_init_terrain_population:
		knowledge_tick = 0.0
		for loc: Vector2 in population:
			var pop := population[loc] as Population
			pop.update_info()
			
	if daytime_tick >= 0.166667:
		const DAY_TICK = 0.000277778
		if skybox.day_time + DAY_TICK >= SkyBox.HOURS_IN_DAY:
			skybox.day_time = 0
			if skybox.day_of_year + 1 > SkyBox.DAYS_IN_YEAR:
				skybox.day_of_year = 1
			else:
				skybox.day_of_year += 1
		else:
			skybox.day_time += DAY_TICK
		daytime_tick = 0.0
		settings.time_of_day = skybox.day_time
		settings.day_of_the_year = skybox.day_of_year
		
	blender.compute_biome_distances(player.position.x, player.position.z)
	var b := blender.biome
	fps.text = "[" + World.Biome.keys()[b] + "] " + str(player.position) + " FPS: " + str(Engine.get_frames_per_second())
	if last_biome != b:
		player.set_current_biome(b)
		player.transition_bg_audio(NoiseBlender.audio_for_biome(b))
		transition_to_biome(b)
		last_biome = b
			
	if not menu.is_showing:
		const SPEED = 12.0
		var movement := VelocityMovement.get_input_strength("pan_left", "pan_right", "pan_forward", "pan_back") * SPEED
		if movement != Vector2.ZERO:
			player.pan_camera(movement)
			
	#print("total: ", Enemy.physics_time, ", movement: ", Enemy.movement_time, ", spell: ", Enemy.spell_time, ", behaviour: ", Enemy.behaviour_time, ", animation: ", Enemy.animation_time)
			
	if not has_init_terrain_population:
		var space := get_world_3d().space
		var state := PhysicsServer3D.space_get_direct_state(space)
		has_init_terrain_population = true
		update_population_at(chunker.backing.get_loaded_chunks_location(), state)
		player.position.y = Navigator.get_world_height(state, player.position.x, player.position.z) + player.bounds.y / 2.0
		player.set_underwater()
		chunker.hide_water(player.position.y, true)
		chunker.update_environment(player.position.x, player.position.z)

func close_menu_for_player() -> void:
	settings.is_paused = false
	var pause_duration := Time.get_unix_time_from_system() - pause_start
	player.spell_caster.update_pause_time(pause_duration)
	for loc: Vector2 in population:
		var pop := population[loc] as Population
		pop.update_pause_time(pause_duration)
	menu.close()
	hud.show()
	
func open_menu_for_player() -> void:
	settings.is_paused = true
	sub_viewport_container.visible = true
	pause_start = Time.get_unix_time_from_system()
	settings.player_position = player.position
	settings.player_health = player.vitals.health.value
	settings.player_mana = player.vitals.mana.value
	settings.last_save_time = Time.get_unix_time_from_system()
	menu.open(Menu.Kind.ANY)
	hud.hide()

func toggle_menu() -> void:
	if not player.menu_callbacks_are_set:
		player.setup_menu_transition(open_menu_for_player, close_menu_for_player)
	
	settings.is_paused = true
	sub_viewport_container.visible = false
	#menu.visible = true
	player.transition_menu(not menu.is_showing)
	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		toggle_menu()
		
	if not menu.is_showing and event.is_action_pressed("RT"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	if not menu.is_showing:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if event is InputEventMouseMotion:
				player.pan_camera((event as InputEventMouseMotion).relative)
	else:
		if event is InputEventJoypadMotion:
			var movement := VelocityMovement.get_input_strength("pan_left", "pan_right", "pan_forward", "pan_back") * 12
			get_viewport().warp_mouse(get_viewport().get_mouse_position() + movement)
		
	if not menu.is_showing:
		for k in wand.basic_keys:
			var s: Spell = null
			var is_down := false
			var is_rapid_fire := Globals.Ref.new(false)
			if event.is_action_pressed(k):
				s = wand.action_down(k, book, is_rapid_fire)
				is_down = true
			if event.is_action_released(k):
				s = wand.action_up(k, book)
			if s != null:
				cast_spell_with_recusive_check_for_rapid_fire(s, is_down and is_rapid_fire.data as bool)
				

func cast_spell_with_recusive_check_for_rapid_fire(s: Spell, is_down: bool) -> void:
	player.cast_spell(func(p: Node3D) -> void: if p != null: call_deferred("add_child", p), s)
	if is_down:
		get_tree().create_timer(maxf(s.cooldown + 0.02, 0.1)).timeout.connect(func() -> void: 
			var is_rapid_fire := Globals.Ref.new(false)
			s = wand.action_down("", book, is_rapid_fire)
			if s != null and is_rapid_fire.data:
				cast_spell_with_recusive_check_for_rapid_fire(s, true)
		)

func _on_player_moved(delta: float, state: PhysicsDirectSpaceState3D) -> void:
	terrain_update_interval += delta
	
	chunker.hide_water(player.position.y, false)
	
	if terrain_update_interval >= 0.25:
		terrain_update_interval = 0
		update_terrain(state)
		
func build_terrain() -> void:
	var chunks := chunker.init_chunks(player.position.x, player.position.z)
	for chunk in chunks:
		add_child(chunk)


func update_terrain(state: PhysicsDirectSpaceState3D) -> void:
	var chunks := chunker.update_chunks(player.position.x, player.position.z)
	for loc: Vector2 in chunks.get("removed", []):
		var pop := population.get(loc, null) as Population
		if pop == null:
			continue
		pop.despawn_all_from_world(get_node(".") as Node3D)
		population.erase(loc)
		
	var updated_chunks := chunks.get("updated", []) as PackedVector2Array

	await get_tree().physics_frame
	update_population_at(updated_chunks, state)
	
	chunker.update_environment(player.position.x, player.position.z)
	

func update_population_at(locations: Array[Vector2], state: PhysicsDirectSpaceState3D) -> void:
	var items_to_add := {}
	for loc: Vector2 in locations:
		var coord := chunker.convert_position_to_coord(loc.x, loc.y, CHUNK_SIZE)
		var pop := Population.new(coord, CHUNK_SIZE, blender, player, entity_manager)
		items_to_add[pop] = pop.spawn_all_into_world(state)
		population[loc] = pop
		
	for pop: Population in items_to_add:
		for item: Node3D in items_to_add[pop]:
			if item.get_parent() == null:
				add_child(item)
				#call_deferred("add_child", item)

func enemy_dies(enemy: Enemy) -> void:
	var enemy_kind := enemy.world_enemy_enum()
	if settings.enemies_killed.has(enemy_kind):
		settings.enemies_killed[enemy_kind] += 1
	else:
		settings.enemies_killed[enemy_kind] = 1
	entity_manager.free_enemy(enemy)

func _on_player_vital_update(vitals: Vitals) -> void:
	if settings == null or settings.game_mode_settings == null:
		return
	
	match settings.game_mode_settings.mode:
		GameModeSettings.GameMode.RESPAWN:
			if vitals.health.value > 0:
				return
				
			vitals.health.value = vitals.health.max_value
			if settings.game_mode_settings.flags & GameModeSettings.RESPAWN_WITH_ARTIFACTS == 0:
				artifacts.reset_by_deleting_all_artifacts()
				menu.artifacts.update_list_and_grid()
			if settings.game_mode_settings.flags & GameModeSettings.RESPAWN_WITH_UPGRADES == 0:
				settings.upgrade_settings.reset_all_stats_to_default_values()
				menu.upgrades.update_state(UpgradeSettings.PurchaseError.NONE)
			if settings.game_mode_settings.flags & GameModeSettings.RESPAWN_WITH_SPELLS_AND_WANDS == 0:
				book.reset_by_deleting_all_spells()
				case.reset_by_deleting_all_wands()
				wand = case.wands[0]
				menu.magic_book.update_book_without_selection()
				menu.wand_case.reload_wand_shelf_items(0)
			
		GameModeSettings.GameMode.PERMADEATH:
			if vitals.health.value > 0:
				return
			
			#FIXME: maybe delete save file? but definitly do something more
			SceneHandler.load_new_scene("res://GUI/Main Menu/MainMenu.tscn", "fade_to_black")

func transition_to_biome(biome: World.Biome) -> void:
	if biome_tween != null:
		biome_tween_next = biome
		return
	
	var env := get_node("WorldEnvironment") as WorldEnvironment
	var update_world := func(a: float) -> void:
		var shader := env.environment.sky.sky_material as ShaderMaterial
		shader.set_shader_parameter("transition", a)
		
	biome_tween = get_tree().create_tween()
	NoiseBlender.update_world_environment(env, biome, false)
	biome_tween.tween_method(update_world, 0.0, 1.0, 0.5)
	biome_tween.finished.connect(func() -> void:
		NoiseBlender.update_world_environment(env, biome, true)
		update_world.call(0.0)
		if biome_tween_next != -1:
			biome_tween = null
			var b := biome_tween_next
			biome_tween_next = -1
			transition_to_biome(b)
		else:
			biome_tween = null			
	)
