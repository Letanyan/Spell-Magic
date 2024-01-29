extends Node3D

@onready var player: Player = $Player
@onready var menu: Menu = $Menu
@onready var hud: HUD = $HUD

@export var noise_temperature: Noise
@export var noise_dryness: Noise
@onready var chunker: Terrain
@onready var population: Dictionary = {}

var last_biome: World.Biome = World.Biome.WATER

@onready var skybox: SkyBox

var terrain_update_interval = 0
var has_init_terrain_population = false

var book: MagicBook
var case: WandCase
var wand: Wand
var artifacts: Artifacts

var knowledge_tick: float = 0.0
var daytime_tick: float = 0.0

var settings: WorldSettings

func setup(_settings: WorldSettings) -> void:
	settings = _settings
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	book = MagicBook.new()
	book.settings = settings
	if _settings.world_name == "demo":
		book.read_absolute_path("res://magic_book.json")
	else:
		book.read(settings.world_name)
	book.rebuild_spell_chains()
	book.ignore_cooldown = true
	
	book.update_spell_limits(settings.upgrade_settings.max_v, settings.upgrade_settings.max_r)
	settings.upgrade_settings.max_velocity_updated.connect(func(v):
		book.update_spell_limits(v, settings.upgrade_settings.max_r)
	)
	settings.upgrade_settings.max_radius_updated.connect(func(r):
		book.update_spell_limits(settings.upgrade_settings.max_v, r)
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
	
	noise_temperature.frequency = 0.0001
	noise_dryness.frequency = 0.0001
	noise_dryness.seed = settings.sed
	noise_temperature.seed = settings.sed
	
	var game_settings := GameSettings.new()
	game_settings.read()
	game_settings.last_world = settings.world_name
	game_settings.save()
	
	

# Called when the node enters the scene tree for the first time.
func _ready():
	if book == null:
		var _settings := WorldSettings.new()
		_settings.world_name = "demo"
		_settings.sed = 0 
		setup(_settings)
		
	settings.upgrade_settings.currency = 10000
	menu.setup(book, case, artifacts, settings)
	
#	book.ignore_cooldown = true
	wand = case.wands[0]
	menu.wand_case.use_current_wand = func(id: int):
		wand = case.wands[id]
		
	# Forest location for world seed 0
#	player.position.x = 800
#	player.position.y = 700
#	player.position.z = 2300
	player.position = settings.player_position
	player.spell_caster.ignore_mana_cost = true
	player.spell_velocity_was_buffed.connect(func(v):
		book.update_spell_buff_limits(v, settings.upgrade_settings.buff_r)
	)
	player.spell_radius_was_buffed.connect(func(r):
		book.update_spell_buff_limits(settings.upgrade_settings.buff_v, r)
	)
		
	chunker = Terrain.new(noise_dryness, noise_temperature, settings.sed, 256, 2, 0.0625)
	build_terrain()
	
	skybox = SkyBox.new($WorldEnvironment, $Sun, $Moon)
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
	
	var theme := load(ProjectSettings.get("gui/theme/custom")) as ThemeUI
	theme.change_tint_color(Color(0.0, 0.360784, 0.643137))

		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	chunker.blender.compute_biome_distances(player.position.x, player.position.z)
	var b := chunker.blender.biome
	$FPS.text = "[" + World.Biome.keys()[b] + "] " + str(player.position) + " FPS: " + str(Engine.get_frames_per_second())
	
	if last_biome != b:
		player.current_biome = b
		player.transition_bg_audio(NoiseBlender.audio_for_biome(b))
		last_biome = b
	
func _physics_process(delta):
	knowledge_tick += delta
	daytime_tick += delta

	if knowledge_tick >= Globals.knowledge_tick() and has_init_terrain_population:
		knowledge_tick = 0.0
		for loc in population:
			var pop = population[loc]
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
			
	if not menu.is_showing:
		const SPEED = 12.0
		var movement := VelocityMovement.get_input_strength("pan_left", "pan_right", "pan_forward", "pan_back") * SPEED
		if movement != Vector2.ZERO:
			player.pan_camera(movement)
			
	if not has_init_terrain_population:
		var space := get_world_3d().space
		var state := PhysicsServer3D.space_get_direct_state(space)
		has_init_terrain_population = true
		var items := update_population_at(chunker.loaded_chunks_location, state)
		for item in items:
			add_child(item)
		player.position.y = Navigator.get_world_height(state, player.position.x, player.position.z)
		chunker.update_environment(player.position.x, player.position.z)

func _input(event):
	if event.is_action_pressed("menu"):
		if menu.is_showing:
			settings.is_paused = false
			menu.close()
			hud.show()
		else:
			settings.is_paused = true			
			settings.player_position = player.position
			menu.open(Menu.Kind.ANY)
			hud.hide()
			
	if not menu.is_showing and event.is_action_pressed("magic_book"):
		menu.open(Menu.Kind.SPELLS)
			
	if not menu.is_showing and event.is_action_pressed("wand_case"):
		menu.open(Menu.Kind.WANDS)
		
	if not menu.is_showing and event.is_action_pressed("RT"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	if not menu.is_showing:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if event is InputEventMouseMotion:
				player.pan_camera(event.relative)
		
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
				cast_spell_with_recusive_check_for_rapid_fire(s, is_down and is_rapid_fire.data)
				

func cast_spell_with_recusive_check_for_rapid_fire(s: Spell, is_down: bool):
	player.cast_spell(func(p): if p != null: call_deferred("add_child", p), s)
	if is_down:
		get_tree().create_timer(maxf(s.cooldown + 0.02, 0.1)).timeout.connect(func(): 
			var is_rapid_fire := Globals.Ref.new(false)
			s = wand.action_down("", book, is_rapid_fire)
			if s != null and is_rapid_fire.data:
				cast_spell_with_recusive_check_for_rapid_fire(s, true)
		)

func _on_player_moved(delta: float, state: PhysicsDirectSpaceState3D):	
	terrain_update_interval += delta
	
	if terrain_update_interval >= 0.25:
		terrain_update_interval = 0
		update_terrain(state)
		
func build_terrain():
	var chunks := chunker.init_chunks(player.position.x, player.position.z)
	for chunk in chunks:
		add_child(chunk)


func update_terrain(state: PhysicsDirectSpaceState3D):
	var chunks := chunker.update_chunks(player.position.x, player.position.z)
	for loc in chunks.get("removed", []):
		var pop : Population = population.get(loc, null)
		if pop == null:
			continue
		pop.despawn_all_from_world(get_node("."))
		population.erase(loc)
	
	var updated_chunks = chunks.get("updated", [])

	await get_tree().physics_frame
	var items := update_population_at(updated_chunks, state)
	for item in items:
		add_child(item)
	
	chunker.update_environment(player.position.x, player.position.z)
	

func update_population_at(locations: Array, state: PhysicsDirectSpaceState3D) -> Array:
	var result := []
	for loc in locations:
		var coord := chunker.convert_position_to_coord(loc.x, loc.y, chunker.chunk_size)
		
		var pop := Population.new(coord, chunker.chunk_size, chunker.blender, player)
		pop.on_enemy_death.connect(enemy_drops_artifact)
		result.append_array(pop.spawn_all_into_world(state))
		population[loc] = pop
		
	return result

func enemy_drops_artifact(enemy: Enemy, artifact: Artifact):
	if artifact != null:
		artifacts.collection.append(artifact)
	var enemy_kind = enemy.world_enemy_enum()
	if settings.enemies_killed.has(enemy_kind):
		settings.enemies_killed[enemy_kind] += 1
	else:
		settings.enemies_killed[enemy_kind] = 1

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
			get_tree().change_scene_to_file("res://GUI/Main Menu/MainMenu.tscn")
