class_name DemoWorld
extends Node3D

@onready var player: Player = $Player
@onready var menu: Menu = $SubViewportContainer/SubViewport/Menu
@onready var hud: HUD = $HUD
@onready var fps: Label = $FPS
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer
@onready var totem: Totem = $Totem

#var noise_image := preload("res://Worlds/Generator/Terrain/noise_texture.tres") as NoiseTexture2D
var noise_image: Image

const CHUNK_SIZE = 256
@onready var blender: NoiseBlender
@onready var chunker: Chunker
@onready var population: Dictionary = {} ## [Vector2i]Population
var entity_manager: EntityManager

var last_last_biome: World.Biome = World.Biome.WATER
var last_biome: World.Biome = World.Biome.WATER

@onready var skybox: SkyBox
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $Sun
@onready var moon: DirectionalLight3D = $Moon
var biome_tick := 0.0
var biome_transition_duration := 1.0
var biome_start_settings := {}
var biome_final_settings := {}

var texture_transition_biome_x: Texture2D = null
var texture_transition_biome_y: Texture2D = null
var texture_transition_height: Texture2D = null

var terrain_update_interval := 0.0
var has_init_terrain_population := false

var ready_state: GameSettings.ReadyState = GameSettings.ReadyState.NOT

var book: MagicBook
var case: WandCase
var wand: Wand
var artifacts: Artifacts

var knowledge_tick: float = 0.0
var daytime_tick: float = 0.0
var environment_effect_tick: float = 0.0
var environment_timer: float = 0.0

var settings: WorldSettings
var pause_start: float

var is_mouse_down: bool = false

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
		book.ignore_cooldown = GlobalData.is_debug
	
	book.update_spell_limits(settings.upgrade_settings.max_v(), settings.upgrade_settings.max_r())
	settings.upgrade_settings.max_velocity_updated.connect(func(v: float) -> void:
		book.update_spell_limits(v, settings.upgrade_settings.max_r())
	)
	settings.upgrade_settings.max_radius_updated.connect(func(r: float) -> void:
		book.update_spell_limits(settings.upgrade_settings.max_v(), r)
	)
	settings.upgrade_settings.upgrade_was_purchased.connect(func(us: UpgradeSettings) -> void:
		player.vitals.health.max_value = us.max_health()
		player.vitals.mana.max_value = us.max_mana()
		player.vitals.mana.change_per_tick = us.max_mana_regen()
		player.vitals.attack.set_fixed_value(us.max_attack())
		player.vitals.defence.set_fixed_value(us.max_defence())
	)
	
	case = WandCase.new()
	if not case.read(settings.world_name, book):
		var w := case.wands[case.selected_wand]
		var opt := w.keys[PackedStringArray(["RT"])] as Wand.Option
		opt.kind = Wand.Kind.FIRE
		opt.parse_spells("Blast", book)
	book.spell_was_updated.connect(case.spell_was_updated)
	
	artifacts = Artifacts.new()
	artifacts.read(settings.world_name)
	
	entity_manager = EntityManager.new()
	entity_manager.buffer_foliage_lod0.add_all_meshes(self)
	entity_manager.buffer_foliage_lod1.add_all_meshes(self)
	
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
		
	menu.setup(book, case, artifacts, settings, player)
	
	wand = case.current_wand()
	menu.wand_case.use_current_wand = func(id: int) -> void:
		wand = case.wands[id]
		
	menu.close_menu.connect(toggle_menu)
	
	var noise_tex := preload("res://Worlds/Generator/Terrain/noise_texture.tres") as NoiseTexture2D
	noise_image = noise_tex.get_image()
		
	player.position = settings.player_position
	player.spell_caster.ignore_mana_cost = GlobalData.is_debug
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
	player.vitals.health.max_value = settings.upgrade_settings.max_health()
	player.vitals.mana.max_value = settings.upgrade_settings.max_mana()
	player.vitals.mana.change_per_tick = settings.upgrade_settings.max_mana_regen()
	player.vitals.health.set_value(settings.player_health)
	player.vitals.mana.set_value(settings.player_mana)
	player.vitals.attack.set_fixed_value(settings.upgrade_settings.max_attack())
	player.vitals.defence.set_fixed_value(settings.upgrade_settings.max_defence())
	player.world_settings = settings
	player.name_generator = NameGenerator.new()
	player.name_generator.read(settings.world_name)
		
	blender = NoiseBlender.make(settings.world_generation_version, settings.sed)
	settings.sea_level = blender.sea_level
	settings.world_radius = blender.world_radius
	settings.customisation_settings.update_all(player.skeleton_3d)
	if GlobalData.is_debug:
		chunker = Chunker.new(CHUNK_SIZE, 0.0625, CHUNK_SIZE * 0.5 * settings.graphics_settings.grass_size, blender, [3, 5, 7, 9], false)
	else:
		chunker = Chunker.new(CHUNK_SIZE, 0.0625, CHUNK_SIZE * 0.5 * settings.graphics_settings.grass_size, blender, [3, 8, 16, 24], false)
	build_terrain()
	update_terrain()
	
	#texture_transition_biome_x = blender.back.biome_texture(0, 0, 256.0, 256.0, 256.0, 0)
	#texture_transition_biome_y = blender.back.biome_texture(0, 0, 256.0, 256.0, 256.0, 1)
	#var heights := blender.back.height_map(0, 0, 256.0, 256.0, 256.0)
	#var max_height := -INF
	#var min_height := INF
	#for h in heights:
		#if h > max_height: max_height = h
		#if h < min_height: min_height = h
	#for i in heights.size():
		#heights.set(i, (heights[i] - min_height) / (max_height - min_height) )
	#texture_transition_height = blender.back.height_texture(heights, 256.0, 256.0)
	
	SignalBus.enemy_death.connect(enemy_dies)
	
	skybox = SkyBox.new(world_environment, sun, moon)
	skybox.day_time = settings.time_of_day
	skybox.day_of_year = settings.day_of_the_year
	
	player.chunker = chunker
	player.magic_book = book
	player.artifacts = artifacts
	hud.player = player
	hud.book = book
	hud.wand = wand
	menu.wand_case.new_wand_selected.connect(hud.set_wand)
	
	#for i in 18:
		#var n: String
		#match randi_range(0, 5):
			#0: n = player.name_generator.capital_cities.generate(15, 3)
			#1: n = player.name_generator.constellations.generate(15, 4)
			#2: n = player.name_generator.english_names.generate(10, 1)
			#3: n = player.name_generator.french_names.generate(12, 2)
			#4: n = player.name_generator.iclandic_names.generate(15, 3)
			#5: n = player.name_generator.italian_names.generate(14, 2)
		#var artifact := Artifact.new(n)
		#artifact.fill(
			#[Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT],
			#randf() < 0.5,
			#{ Artifact.Effect.BOOST_PERCENTAGE: 10, Artifact.Effect.RESISTANCE_PERCENTAGE: 10, },
			#{ Artifact.Event.DEAL: 10, Artifact.Event.RECEIVE: 10, },
			#{ Artifact.Element.FIRE: 10, Artifact.Element.WATER: 10, Artifact.Element.ICE: 10, Artifact.Element.AIR: 10, Artifact.Element.ELECTRIC: 10, Artifact.Element.ROCK: 10, Artifact.Element.RUNNING_SPEED: 10, Artifact.Element.ATTACK: 10, Artifact.Element.DEFENCE: 10, Artifact.Element.CRIT_RATE: 10, Artifact.Element.CRIT_DMG: 10, Artifact.Element.SPELL_RADIUS: 10, },
			#{ Artifact.Element.FIRE: 10, Artifact.Element.WATER: 10, Artifact.Element.ICE: 10, Artifact.Element.AIR: 10, Artifact.Element.ELECTRIC: 10, Artifact.Element.ROCK: 10, },
			#{ Artifact.Pattern.CIRCLE: 10, Artifact.Pattern.TRIANGLE: 10, Artifact.Pattern.SQUARE: 10, },
			#Vector2i(7, 3),
		#)
		#player.artifacts.collection.append(artifact)
	#player.artifacts.save(settings.world_name)
	#menu.artifacts.update_list_and_grid()
	
	menu.settings.settings_changed.connect(hud.update_settings)
	hud.update_settings(settings)
	
	AudioManager.world = self
	AudioManager.camera = player.cam
	
	var theme := load(ProjectSettings.get("gui/theme/custom") as String) as ThemeUI
	theme.change_tint_color(settings.hud_settings.theme_color, settings.hud_settings.theme_variation)
	hud.update_theme_colors(settings.hud_settings.theme_color, settings.hud_settings.theme_variation)
	ready_state = GameSettings.ReadyState.IS
	
	await RenderingServer.frame_post_draw
	(player.interface.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("texture_albedo", sub_viewport.get_texture())
	sub_viewport_container.visible = true

func _ready() -> void:
	if ready_state == GameSettings.ReadyState.NOT:
		run_on_ready()

func _exit_tree() -> void:
	chunker.deinit()
	AudioManager.world = null
	AudioManager.camera = null
	
func _process(delta: float) -> void:
	if GlobalData.is_debug:
		var b := blender.biome
		fps.text = "[" + World.Biome.keys()[b] + "] " + str(player.position) + " FPS: " + str(Engine.get_frames_per_second())
	
func _physics_process(delta: float) -> void:
	update_terrain_queue()
	update_population_spawning()
	
	AudioManager.update(delta)
	player.update_audio_state(delta)
	
	if player.magic_book.settings.is_paused:
		if get_window().has_focus():
			if Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0:
				if not is_mouse_down:
					var event := InputEventMouseButton.new()
					is_mouse_down = true
					event.position = get_viewport().get_mouse_position()
					event.pressed = true
					event.button_index = MOUSE_BUTTON_LEFT
					Input.parse_input_event(event)
			elif is_mouse_down:
				is_mouse_down = false
				var event := InputEventMouseButton.new()
				event.position = get_viewport().get_mouse_position()
				event.pressed = false
				event.button_index = MOUSE_BUTTON_LEFT
				Input.parse_input_event(event)
			if GlobalData.controller.last_input_type == Controller.InputType.CONTROLLER:
				var movement := VelocityMovement.get_input_strength("pan_left", "pan_right", "pan_forward", "pan_back") * 12
				get_viewport().warp_mouse(get_viewport().get_mouse_position() + movement)
		return
	
	knowledge_tick += delta
	daytime_tick += delta
	environment_effect_tick += delta
	
	update_transition_to_biome(delta)
	book.update_spell_cooldowns(delta)
	hud.update_spell_cooldowns(delta)

	if knowledge_tick >= Globals.knowledge_tick() and has_init_terrain_population:
		knowledge_tick = 0.0
		for loc: Vector2i in population:
			var pop := population[loc] as Population
			pop.update_info(self)
			pop.update_enemies(delta)
	else:
		for loc: Vector2i in population:
			var pop := population[loc] as Population
			pop.update_enemies(delta)
			
	if daytime_tick >= 0.166667:
		const DAY_TICK = 0.000277778
		skybox.day_time += DAY_TICK
		if skybox.day_time >= SkyBox.HOURS_IN_DAY:
			skybox.day_time = fmod(skybox.day_time, SkyBox.HOURS_IN_DAY)
			if skybox.day_of_year + 1 > SkyBox.DAYS_IN_YEAR:
				skybox.day_of_year = 1
			else:
				skybox.day_of_year += 1
		daytime_tick = 0.0
		settings.time_of_day = skybox.day_time
		settings.day_of_the_year = skybox.day_of_year
		if is_equal_approx(biome_tick, biome_transition_duration) or biome_start_settings.is_empty() or biome_final_settings.is_empty():
			var env := get_node("WorldEnvironment") as WorldEnvironment
			env.environment.ambient_light_color = NoiseBlender.environment_ambient_color(last_biome, skybox.day_time, sun, moon)
		RenderingServer.global_shader_parameter_set("tick_time_s", float(Time.get_ticks_msec()) / 1000.0)
		
	blender.compute_biome_distances(player.position.x, player.position.z, chunker.get_noise_scale())
	const MULT = 2.5
	var clr := Color(blender.color.r * MULT, blender.color.g * MULT, blender.color.b * MULT)
	player.set_current_biome_grass_color(clr)
	var b := blender.biome
	if last_biome != b:
		player.set_current_biome(b)
		player.play_bg_audio(b)
		transition_to_biome(b, 0.1 if last_biome == World.Biome.WATER else 15.0)
		last_last_biome = last_biome
		last_biome = b
		
	if environment_effect_tick >= 2.0:
		environment_timer += delta
		if environment_timer > 1.0:
			environment_timer = 0.0
		environment_effect_tick = 0.0
		var lvl := Population.level_relative_to_position_within_radius(null, player.position.x, player.position.z, player.world_settings.world_radius)
		var chance := lvl / 100.0
		if last_biome == World.Biome.HFIL:
			if randf() < chance * 0.01:
				player.apply_environment_impulse(Color.RED, Vector3(0, lvl, 0) * 100)
		elif last_biome == World.Biome.TAIGA:
			var nx := noise_image.get_pixel(1, floori(environment_timer * noise_image.get_height())).r / 255.0
			var ny := noise_image.get_pixel(floori(environment_timer * noise_image.get_height()), 1).r / 255.0
			if randf() < chance * 0.1:
				player.apply_environment_impulse(Color.WHITE, Vector3(nx, 0, ny).normalized() * (lvl / 100.0 * 3))
		
	if GlobalData.is_debug:
		fps.text = "[" + World.Biome.keys()[b] + "] " + str(player.position) + " FPS: " + str(Engine.get_frames_per_second())
			
	if not menu.is_showing:
		var movement := VelocityMovement.get_input_strength("pan_left", "pan_right", "pan_forward", "pan_back") * settings.camera_settings.panning_speed
		if movement != Vector2.ZERO:
			player.pan_camera(movement)
			
	#print("total: ", Enemy.physics_time, ", movement: ", Enemy.movement_time, ", spell: ", Enemy.spell_time, ", behaviour: ", Enemy.behaviour_time, ", animation: ", Enemy.animation_time)
			
	if not has_init_terrain_population:
		var space := get_world_3d().space
		var state := PhysicsServer3D.space_get_direct_state(space)
		has_init_terrain_population = true
		for coord: Vector2i in chunker.chunk_lods:
			var lod := chunker.chunk_lods[coord] as int
			if lod < chunker.track_biomes_upto_lod:
				update_population_at(coord, lod != 0)
		var world_h := Navigator.get_world_height(state, player.position.x, player.position.z)
		var platform_h := Navigator.get_platform_height(state, player.position.x, player.position.z)
		if abs(player.position.y - world_h) < abs(player.position.y - platform_h):
			player.set_feet_position(world_h)
		else:
			player.set_feet_position(platform_h)
		player.set_underwater()
		#chunker.hide_water(player.position.y, true)
		chunker.update_environment(player.position.x, player.position.z)

func close_menu_for_player() -> void:
	settings.is_paused = false
	sub_viewport_container.visible = false
	totem.show_message()
	menu.close()
	hud.show()
	
func open_menu_for_player() -> void:
	settings.is_paused = true
	for loc: Vector2i in population:
		var pop := population[loc] as Population
		pop.update_info(self)
	sub_viewport_container.visible = true
	pause_start = Time.get_unix_time_from_system()
	settings.player_position = player.position
	settings.player_health = player.vitals.health.value
	settings.player_mana = player.vitals.mana.value
	settings.last_save_time = Time.get_unix_time_from_system()
	totem.hide_message()
	menu.player_in_combat = not player.enemies_in_range.is_empty()
	menu.open(Menu.Kind.ANY)
	if menu.current_index == 4 and menu.settings.tab_container.get_current_tab_control().name == "Customisation":
		player.animate_spring_arm_length(3, 0.2)
	hud.hide()

func toggle_menu() -> void:
	if not player.menu_callbacks_are_set:
		player.setup_menu_transition(open_menu_for_player, close_menu_for_player)
		
	if player.vitals.health.value < 0:
		return
	
	settings.is_paused = true
	sub_viewport_container.visible = false
	player.transition_menu(not menu.is_showing, menu.current_index == 4 and menu.settings.tab_container.get_current_tab_control().name == "Customisation")
	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		toggle_menu()
		
	if not settings.is_paused and event.is_action_pressed("RT"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	if not settings.is_paused:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if event is InputEventMouseMotion:
				player.pan_camera((event as InputEventMouseMotion).relative)
				
	if GlobalData.is_debug and not settings.is_paused:
		if event is InputEventKey:
			var ev := event as InputEventKey
			if ev.is_released() and ev.keycode == KEY_2:
				chunker.update_environment(player.position.x + 0.5, player.position.z + 0.5)
			if ev.is_released() and ev.keycode == KEY_1:
				for loc: Vector2i in population:
					var pop := population[loc] as Population
					if pop == null: continue
					if pop.display_only: continue
					var y := 0.0
					for i in pop.spawn_area_biomes.size():
						for p: Vector2 in pop.spawn_area_points[i]:
							p += pop.coord * chunker.chunk_width
							var res := chunker.terrain_normal(p.x, p.y)
							if not res.is_empty():
								y = (res["position"] as Vector3).y
							else:
								y = 250.0
							Debug3D.draw_sphere(Vector3(p.x, y, p.y), 2.0, Color.RED, 5)
				
	if not settings.is_paused:
		GlobalData.controller.handle_input(event)
		
		if player.can_level_up_world and event is InputEventMouseButton:
			if event.is_action_released("RT") or event.is_action_pressed("S"):
				UIAudioPlayer.world_level_up()
				player.world_settings.world_level += 1
				player.world_settings.player_keys = 0
				reset_enemy_populations()
				SignalBus.level_up_world.emit(player, player.world_settings.world_level)
				Steamworks.set_achievement(Steamworks.Achievements.ACH_INCREASED_WORLD_LEVEL)
				settings.save()
				transition_world_level()
			return
			
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN):
			if settings.camera_settings.distance > 1:
				settings.camera_settings.distance -= 1
				menu.settings.settings_changed.emit(settings)
				menu.settings.update_controls()
				settings.save()
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP):
			if settings.camera_settings.distance < 10:
				settings.camera_settings.distance += 1
				menu.settings.settings_changed.emit(settings)
				menu.settings.update_controls()
				settings.save()
		
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
	player.cast_spell(insert_spell, s)
	if is_down:
		get_tree().create_timer(maxf(s.cooldown + 0.02, 0.1)).timeout.connect(func() -> void: 
			var is_rapid_fire := Globals.Ref.new(false)
			var ns := wand.action_down("", book, is_rapid_fire)
			if ns != null and is_rapid_fire.data:
				cast_spell_with_recusive_check_for_rapid_fire(ns, true)
		)

func insert_spell(p: Node3D) -> void:
	if p == null:
		return
	if p.get_parent() == null:
		add_child(p)
	if p is SpellBody:
		(p as SpellBody).setup()

func _on_player_moved(delta: float) -> void:
	terrain_update_interval += delta
	if Vec2.xz(player.position).distance_to(Vector2.ZERO) < 8.0:
		match GlobalData.controller.last_input_type:
			Controller.InputType.KEYBOARD:
				var message := "[center]"
				message += GlobalData.controller.key_images(PackedStringArray(["move_forward"]))
				message += GlobalData.controller.key_images(PackedStringArray(["move_left"]))
				message += GlobalData.controller.key_images(PackedStringArray(["move_back"]))
				message += GlobalData.controller.key_images(PackedStringArray(["move_right"])) + "[b]Move[/b] "
				message += GlobalData.controller.key_images(PackedStringArray(["RT"])) + "[b]Attack[/b] "
				message += GlobalData.controller.key_images(PackedStringArray(["ESC"])) + "[b]Menu[/b]"
				message += "[/center]"
				hud.show_message(message)
			Controller.InputType.CONTROLLER:
				var message := "[center]"
				message += GlobalData.controller.key_images(PackedStringArray(["dpad"])) + "[b]Move[/b] "
				message += GlobalData.controller.key_images(PackedStringArray(["RT"])) + "[b]Attack[/b] "
				message += GlobalData.controller.key_images(PackedStringArray(["ESC"])) + "[b]Menu[/b]"
				message += "[/center]"
				hud.show_message(message)
	else:
		hud.show_message("")
		
	if terrain_update_interval >= 0.25:
		terrain_update_interval = 0
		update_terrain()
		
func build_terrain() -> void:
	chunker.init_chunks(player.position.x, player.position.z)
	chunker.set_world(self)

func update_terrain_queue() -> void:
	if chunker.has_chunks_to_update():
		var coords := chunker.update_chunks_in_queue(Time.get_ticks_msec(), 3)
		var updated_coords := coords["updated"] as Array[Vector4i]
		var removed_coords := coords["removed"] as Array[Vector4i]
		for _removed in removed_coords:
			var removed := Vector2i(_removed.x, _removed.y)
			if _removed.z == 0:
				var pop := population.get(removed, null) as Population
				if pop != null:
					pop.habitant_set_display_only(true)
			elif _removed.z == 1 and _removed.w > 1:
				var pop := population.get(removed, null) as Population
				if pop != null:
					pop.despawn_all_from_world(get_node(".") as Node3D)
					population.erase(removed)
				
		for updated in updated_coords:
			if updated.z < chunker.track_biomes_upto_lod:
				if updated.z == 0:
					var pop := population.get(Vector2i(updated.x, updated.y), null) as Population
					if pop != null:
						pop.habitant_set_display_only(false)
				elif updated.z == 1 and updated.w > 1:
					update_population_at(Vector2i(updated.x, updated.y), updated.z != 0)

func update_terrain() -> void:
	chunker.update_chunks(player.position.x, player.position.z)
	chunker.update_environment(player.position.x, player.position.z)

func update_population_at(coord: Vector2i, display_only: bool) -> void:
	var pop := Population.new(settings.world_generation_version, coord, CHUNK_SIZE, chunker, blender, player, entity_manager, true)
	pop.setup_spawning_state(not display_only)
	population[coord] = pop
	
	if coord.x == 0 and coord.y == 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = settings.sed
		var pos := pop.get_flat_ground(Vector2.ZERO, 1.5, 32.0, rng)
		totem.position = pos
		totem.open_book(GDNavigator.popcnt(player.world_settings.player_keys) >= player.world_settings.max_keys())
		var count := Rand.roll(10, 2, 0, rng, Rand.Accum.AVG)
		var path := Pathway.new().circle(16.0, 0, 1)
		path.apply_transform(T.translated(pos))
		for p in path.sample_points_xz(count):
			match rng.randi_range(0, 2):
				0: pop.spawn_foliage(World.Foliage.ROCK_TALL, p + Rand.point_in_circle_2d(2.0, rng), 16.0)
				1: pop.spawn_foliage(World.Foliage.ROCK_SQUASHED, p + Rand.point_in_circle_2d(2.0, rng), 16.0)
				2: pop.spawn_foliage(World.Foliage.ROCK_EGG, p + Rand.point_in_circle_2d(2.0, rng), 16.0)
				
func update_population_spawning() -> void:
	var items_to_add := {}
	var start_time_ms := Time.get_ticks_msec()
	for loc: Vector2i in population:
		var pop := population[loc] as Population
		if not pop.is_spawning_complete():
			items_to_add[pop] = pop.spawn_into_world(start_time_ms, 3)
			
	for pop: Population in items_to_add:
		for item: Node3D in items_to_add[pop]:
			if item.get_parent() == null:
				add_child(item)
				
func reset_enemy_populations() -> void:
	for coord: Vector2i in population:
		var pop := population[coord] as Population
		if pop.display_only:
			continue
		pop.habitant_set_display_only(true)
		pop.habitant_set_display_only(false)

func enemy_dies(enemy: Enemy) -> void:
	if settings.enemies_killed.has(enemy.kind):
		settings.enemies_killed[enemy.kind] += 1
	else:
		settings.enemies_killed[enemy.kind] = 1
	entity_manager.free_enemy(enemy)

func _on_player_vital_update(vitals: Vitals) -> void:
	if settings == null or settings.game_mode_settings == null:
		return
	
	match settings.game_mode_settings.mode:
		GameModeSettings.GameMode.RESPAWN:
			if vitals.health.value > 0:
				return
				
			settings.is_paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			UIAudioPlayer.hurt()
			player.play_animation("death")
			var subtitle_components := []
			if settings.game_mode_settings.flags & GameModeSettings.RESPAWN_WITH_ARTIFACTS == 0:
				subtitle_components.append("Artifacts")
				artifacts.reset_by_deleting_all_artifacts()
				menu.artifacts.update_list_and_grid()
				menu.artifacts.artifacts.save(settings.world_name)
			if settings.game_mode_settings.flags & GameModeSettings.RESPAWN_WITH_UPGRADES == 0:
				subtitle_components.append("Upgrades")
				settings.upgrade_settings.reset_all_stats_to_default_values()
				menu.upgrades.update_state(UpgradeSettings.PurchaseError.NONE)
				menu.upgrades.settings.save()
			if settings.game_mode_settings.flags & GameModeSettings.RESPAWN_WITH_SPELLS_AND_WANDS == 0:
				subtitle_components.append("Spells")
				book.reset_by_deleting_all_spells()
				case.reset_by_deleting_all_wands()
				wand = case.wands[0]
				menu.magic_book.update_book_without_selection()
				menu.wand_case.reload_wand_shelf_items(0)
				menu.wand_case.case.save(settings.world_name)
				menu.magic_book.book.save(settings.world_name)
			if settings.game_mode_settings.flags & GameModeSettings.RESPAWN_WITH_COINS == 0:
				subtitle_components.append("Coins")
				settings.upgrade_settings.currency = 0
				menu.upgrades.update_state(UpgradeSettings.PurchaseError.NONE)
				menu.upgrades.settings.save()
				
			settings.player_position = player.position
			settings.player_health = player.vitals.health.max_value
			settings.player_mana = player.vitals.mana.max_value
			settings.last_save_time = Time.get_unix_time_from_system()
			settings.save()
			totem.hide_message()
			hud.hide()
			
			for enemy: Enemy in player.enemies_in_range:
				enemy.vitals.reset()
				
			var subtitle := ""
			if subtitle_components.size() == 1:
				subtitle = subtitle_components[0] + " have been removed"
			elif subtitle_components.size() == 2:
				subtitle = subtitle_components[0] + " and " + subtitle_components[1] + " have been removed"
			elif subtitle_components.size() == 3:
				subtitle = subtitle_components[0] + ", " + subtitle_components[1] + " and " + subtitle_components[2] + " have been removed"
			elif subtitle_components.size() == 4:
				subtitle = subtitle_components[0] + ", " + subtitle_components[1] + ", " + subtitle_components[2] + " and " + subtitle_components[3] + " have been removed"
			var overlay := OverlayScreen.display("DEATH", subtitle, "Revive")
			overlay.confirmed.connect(func() -> void:
				player.play_animation("revive")
				totem.show_message()
				hud.show()
				settings.is_paused = false
				vitals.health.value = vitals.health.max_value
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			)
			overlay.show_in_root(self)
			
			
		GameModeSettings.GameMode.PERMADEATH:
			if vitals.health.value > 0:
				return
			
			UIAudioPlayer.hurt()
			player.play_animation("death")
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			settings.is_paused = true
			totem.hide_message()
			hud.hide()
			GlobalData.game_settings.last_world = ""
			GlobalData.game_settings.save()
			OS.move_to_trash(ProjectSettings.globalize_path("user://worlds/%s" % (settings.world_name)))
			var overlay := OverlayScreen.display("DEATH", "Game Over", "Main Menu")
			overlay.confirmed.connect(func() -> void:
				SceneHandler.load_new_scene("res://Worlds/MainMenu/MainMenuWorld.tscn", "fade_to_black")
			)
			overlay.show_in_root(self)

func transition_to_biome(biome: World.Biome, duration: float) -> void:
	var env := get_node("WorldEnvironment") as WorldEnvironment
	var shader := env.environment.sky.sky_material as ShaderMaterial
	var lvl := Population.level_relative_to_position_within_radius(null, player.position.x, player.position.z, settings.world_radius)
	if biome_final_settings.is_empty():
		NoiseBlender.update_for_world_environment(biome_final_settings, env, sun, moon, lvl, biome, settings.time_of_day)
		biome_start_settings.merge(biome_final_settings, true)
		biome_tick = biome_transition_duration
		shader.set_shader_parameter("transition", 0.0)
		for key: String in biome_final_settings: 
			if not key.begins_with("*"): 
				shader.set_shader_parameter("final_" + key, biome_final_settings[key])
				shader.set_shader_parameter("start_" + key, biome_final_settings[key])
		env.environment.ambient_light_color = biome_start_settings["*ambient_light_color"]
		sun.light_color = world_environment.environment.ambient_light_color
		env.environment.fog_density = biome_start_settings["*fog_density"]
		env.environment.fog_sky_affect = biome_start_settings["*fog_sky_affect"]
		env.environment.fog_light_color = biome_start_settings["*fog_light_color"]
	elif is_equal_approx(biome_tick, biome_transition_duration):
		biome_tick = 0.0
		shader.set_shader_parameter("transition", 0.0)
		NoiseBlender.update_for_world_environment(biome_final_settings, env, sun, moon, lvl, biome, settings.time_of_day)
		for key: String in biome_final_settings: if not key.begins_with("*"): shader.set_shader_parameter("final_" + key, biome_final_settings[key])
		biome_transition_duration = duration
	else:
		var t := biome_tick / biome_transition_duration
		var elapsed := biome_tick
		biome_tick = 0.0
		for key: String in biome_start_settings: 
			var value: Variant = lerp(biome_start_settings[key], biome_final_settings[key], t)
			biome_start_settings[key] = value
			if not key.begins_with("*"):
				shader.set_shader_parameter("start_" + key, value)
				shader.set_shader_parameter("final_" + key, value)
		shader.set_shader_parameter("transition", 0.0)
		NoiseBlender.update_for_world_environment(biome_final_settings, env, sun, moon, lvl, biome, settings.time_of_day)
		for key: String in biome_final_settings: if not key.begins_with("*"): shader.set_shader_parameter("final_" + key, biome_final_settings[key])
		if last_last_biome == biome:
			biome_transition_duration = elapsed
		else:
			biome_transition_duration = duration - elapsed
		
func update_transition_to_biome(delta: float) -> void:
	if is_equal_approx(biome_tick, biome_transition_duration) or biome_start_settings.is_empty() or biome_final_settings.is_empty():
		return
		
	biome_tick += delta
	var env := get_node("WorldEnvironment") as WorldEnvironment
	var shader := env.environment.sky.sky_material as ShaderMaterial
	if biome_tick > biome_transition_duration or is_equal_approx(biome_tick, biome_transition_duration):
		biome_tick = biome_transition_duration
		biome_start_settings.merge(biome_final_settings, true)
		for key: String in biome_start_settings: if not key.begins_with("*"): shader.set_shader_parameter("start_" + key, biome_start_settings[key])
		shader.set_shader_parameter("transition", 0.0)
		env.environment.ambient_light_color = biome_start_settings["*ambient_light_color"]
		sun.light_color = world_environment.environment.ambient_light_color
		env.environment.fog_density = biome_start_settings["*fog_density"]
		env.environment.fog_sky_affect = biome_start_settings["*fog_sky_affect"]
		env.environment.fog_light_color = biome_start_settings["*fog_light_color"]
	else:
		var t := biome_tick / biome_transition_duration
		shader.set_shader_parameter("transition", t)
		env.environment.ambient_light_color = lerp(biome_start_settings["*ambient_light_color"], biome_final_settings["*ambient_light_color"], t)
		sun.light_color = world_environment.environment.ambient_light_color
		env.environment.fog_density = lerp(biome_start_settings["*fog_density"], biome_final_settings["*fog_density"], t)
		env.environment.fog_sky_affect = lerp(biome_start_settings["*fog_sky_affect"], biome_final_settings["*fog_sky_affect"], t)
		env.environment.fog_light_color = lerp(biome_start_settings["*fog_light_color"], biome_final_settings["*fog_light_color"], t)

func transition_world_level() -> void:
	settings.is_paused = true
	var tween := create_tween()
	var bg := player.canvas_layer_transition_rect
	var mat := bg.material as ShaderMaterial
	var SIZE := (bg.size * 0.1).round()
	var SCALE := minf(SIZE.x, SIZE.y)
	var POS := Vector2(randf() * 10000, randf() * 10000)
	mat.set_shader_parameter("transition", 0.0)
	mat.set_shader_parameter("locations", blender.back.get_locations())
	mat.set_shader_parameter("biome_x", blender.back.biome_texture(POS.x, POS.y, SIZE.x, SIZE.y, SCALE, 0))
	mat.set_shader_parameter("biome_y", blender.back.biome_texture(POS.x, POS.y, SIZE.x, SIZE.y, SCALE, 1))
	var heights := blender.back.height_map(POS.x, POS.y, SIZE.x, SIZE.y, SCALE)
	var max_height := -INF
	var min_height := INF
	for h in heights:
		if h > max_height: max_height = h
		if h < min_height: min_height = h
	for i in heights.size():
		heights.set(i, (heights[i] - min_height) / (max_height - min_height) )
	mat.set_shader_parameter("height", blender.back.height_texture(heights, SIZE.x, SIZE.y))
	
	bg.visible = true
	totem.hide_message()
	const DURATION = 0.5
	tween.set_parallel(false)
	tween.set_trans(Tween.TRANS_SPRING)
	tween.tween_method(func(t: float) -> void: mat.set_shader_parameter("transition", t), 0.0, 1.1, DURATION)
	tween.tween_interval(DURATION * 2)
	tween.tween_method(func(t: float) -> void: mat.set_shader_parameter("transition", t), 1.1, 0.0, DURATION)
	tween.finished.connect(func() -> void: 
		bg.visible = false
		settings.is_paused = false
		totem.show_message()
	)
