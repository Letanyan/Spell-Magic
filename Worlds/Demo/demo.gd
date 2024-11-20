class_name DemoWorld
extends Node3D

@onready var player: Player = $Player
@onready var menu: Menu = $SubViewportContainer/SubViewport/Menu
@onready var hud: HUD = $HUD
@onready var fps: Label = $FPS
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer

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
		book.ignore_cooldown = OS.is_debug_build()
	
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
		
	settings.upgrade_settings.currency = 10000
	menu.setup(book, case, artifacts, settings)
	
	wand = case.current_wand()
	menu.wand_case.use_current_wand = func(id: int) -> void:
		wand = case.wands[id]
		
	menu.close_menu.connect(toggle_menu)
	
	var noise_tex := preload("res://Worlds/Generator/Terrain/noise_texture.tres") as NoiseTexture2D
	noise_image = noise_tex.get_image()
		
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
	#chunker = Terrain.new(blender, CHUNK_SIZE, CHUNK_SIZE * 0.5 * settings.graphics_settings.grass_size, 4, 0.0625, 16, false)
	chunker = Chunker.new(CHUNK_SIZE, 0.0625, CHUNK_SIZE * 0.5 * settings.graphics_settings.grass_size, blender, [3, 8, 16, 24], false)
	build_terrain()
	update_terrain()
	
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
	
	menu.settings.settings_changed.connect(hud.update_settings)
	hud.update_settings(settings)
	
	var theme := load(ProjectSettings.get("gui/theme/custom") as String) as ThemeUI
	theme.change_tint_color(Color(0, 0.533, 0.8))
	ready_state = GameSettings.ReadyState.IS
	
	await RenderingServer.frame_post_draw
	(player.interface.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("albedo_texture", sub_viewport.get_texture())
	sub_viewport_container.visible = true

func _ready() -> void:
	if ready_state == GameSettings.ReadyState.NOT:
		run_on_ready()

func _exit_tree() -> void:
	chunker.deinit()
	
func _process(delta: float) -> void:
	if OS.is_debug_build():
		var b := blender.biome
		fps.text = "[" + World.Biome.keys()[b] + "] " + str(player.position) + " FPS: " + str(Engine.get_frames_per_second())
	
func _physics_process(delta: float) -> void:
	update_terrain_queue()
	update_population_spawning()
	
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
			
		#for chunk in chunker.get_loaded_chunks():
			#var mi := chunk.get_node("mesh")
			#var static_body := mi.get_node("static")
			#var collision := static_body.get_node("collision")
			#var V := chunker.height_at_position(collision, player.position.x, player.position.z)
			#if not is_nan(V.x):
				#DebugDraw3D.draw_sphere(Vec3.xz_y(player.position, V.w), 0.2, Color.RED, Globals.knowledge_tick())
				#DebugDraw3D.draw_arrow_ray(player.position, Vector3(V.x, V.y, V.z), 2, Color.BLUE, 0.5, false, Globals.knowledge_tick())
			
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
		
	blender.compute_biome_distances(player.position.x, player.position.z, chunker.get_noise_scale())
	const MULT = 2.5
	var clr := Color(blender.color.r * MULT, blender.color.g * MULT, blender.color.b * MULT)
	player.set_current_biome_grass_color(clr)
	var b := blender.biome
	if last_biome != b:
		player.set_current_biome(b)
		player.transition_bg_audio(NoiseBlender.audio_for_biome(b))
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
		
	if OS.is_debug_build():
		fps.text = "[" + World.Biome.keys()[b] + "] " + str(player.position) + " FPS: " + str(Engine.get_frames_per_second())
			
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
	menu.open(Menu.Kind.ANY)
	hud.hide()

func toggle_menu() -> void:
	if not player.menu_callbacks_are_set:
		player.setup_menu_transition(open_menu_for_player, close_menu_for_player)
		
	if player.vitals.health.value < 0:
		return
	
	settings.is_paused = true
	sub_viewport_container.visible = false
	#menu.visible = true
	player.transition_menu(not menu.is_showing)
	

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
				
	if not settings.is_paused:
		if event is InputEventKey:
			var ev := event as InputEventKey
			if ev.is_released() and ev.keycode == KEY_1:
				for loc: Vector2i in population:
					var pop := population[loc] as Population
					if pop == null: continue
					if pop.display_only: continue
					var y := 0.0
					print(pop.coord)
					for i in pop.spawn_area_biomes.size():
						for p: Vector2 in pop.spawn_area_points[i]:
							p += pop.coord * chunker.chunk_width
							var res := chunker.terrain_normal(p.x, p.y)
							if not res.is_empty():
								y = (res["position"] as Vector3).y
							else:
								y = 250.0
							DebugDraw3D.draw_sphere(Vector3(p.x, y, p.y), 2.0, Color.RED, 5)
				
	if not settings.is_paused:
		GlobalData.controller.handle_input(event)
		
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
	player.cast_spell(func(p: Node3D) -> void: if p != null: call_deferred("add_child", p), s)
	if is_down:
		get_tree().create_timer(maxf(s.cooldown + 0.02, 0.1)).timeout.connect(func() -> void: 
			var is_rapid_fire := Globals.Ref.new(false)
			var ns := wand.action_down("", book, is_rapid_fire)
			if ns != null and is_rapid_fire.data:
				cast_spell_with_recusive_check_for_rapid_fire(ns, true)
		)

func _on_player_moved(delta: float) -> void:
	terrain_update_interval += delta
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
	var pop := Population.new(coord, CHUNK_SIZE, chunker, blender, player, entity_manager, true)
	pop.setup_spawning_state(not display_only)
	population[coord] = pop
				
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
				
			settings.is_paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
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
				
			settings.save()
				
			var subtitle := ""
			if subtitle_components.size() == 1:
				subtitle = subtitle_components[0] + " have been removed"
			elif subtitle_components.size() == 2:
				subtitle = subtitle_components[0] + " and " + subtitle_components[1] + " have been removed"
			elif subtitle_components.size() == 3:
				subtitle = subtitle_components[0] + ", " + subtitle_components[1] + " and " + subtitle_components[2] + " have been removed"
			var overlay := OverlayScreen.display("DEATH", subtitle, "Revive")
			overlay.confirmed.connect(func() -> void:
				player.play_animation("revive")
				settings.is_paused = false
				vitals.health.value = vitals.health.max_value
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			)
			overlay.show_in_root(self)
			
			
		GameModeSettings.GameMode.PERMADEATH:
			if vitals.health.value > 0:
				return
			
			settings.is_paused = true
			var overlay := OverlayScreen.display("GAME OVER", "Permadeath Mode Active\nSave File will be Deleted", "Main Menu")
			overlay.confirmed.connect(func() -> void:
				OS.move_to_trash(ProjectSettings.globalize_path("user://worlds/%s" % (settings.world_name)))
				SceneHandler.load_new_scene("res://GUI/Main Menu/MainMenu.tscn", "fade_to_black")
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
