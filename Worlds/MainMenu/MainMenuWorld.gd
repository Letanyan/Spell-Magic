class_name MainMenuWorld
extends Node3D

@onready var main_menu: MainMenuScreen = $MainMenu
@onready var load_game: LoadGameScreen = $LoadGame
@onready var new_game: NewGameScreen = $NewGame
@onready var settings_menu: SettingsMenuScreen = $SettingsMenu

@onready var player: Marker3D = $Player
var player_movement_direction := Vector3.ZERO
var player_rotation_direction := 0.0
var requested_player_height := 0.0

@onready var blender: NoiseBlender
@onready var chunker: Terrain
@onready var population: Dictionary = {}

var last_biome: World.Biome = World.Biome.WATER

@onready var skybox: SkyBox
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $Sun
@onready var moon: DirectionalLight3D = $Moon
@onready var title: MeshInstance3D = $Player/Arm/Lens/Title
@onready var source: GPUParticles3D = $Player/Arm/Lens/Title/Source
@onready var placard: MeshInstance3D = $Player/Arm/Lens/placard
var biome_tween_next: World.Biome = World.Biome.WATER
var biome_tween: Tween = null


var terrain_update_interval := 0
var has_init_terrain_population := false

var daytime_tick: float

var settings: WorldSettings

func setup(_settings: WorldSettings) -> void:
	settings = _settings

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var _settings := WorldSettings.new(get_viewport())
	_settings.world_name = "empty"
	_settings.sed = Time.get_ticks_usec()
	setup(_settings)
	
	var rng := RandomNumberGenerator.new()
	rng.seed = _settings.sed
	print("VERSION: ", _settings.world_generation_version, ", WORLD SEED: ", _settings.sed, ", RNG SEED: ", rng.seed)
	player.position.x = rng.randf_range(-10000, 10000)
	player.position.z = rng.randf_range(-10000, 10000)
	player_movement_direction = Vector3(rng.randf(), 0, rng.randf()).normalized() * rng.randfn(1.0, 0.1)
	player_rotation_direction = (rng.randf() * 2 - 1) * PI / 16
		
	blender = NoiseBlender.make(settings.world_generation_version, settings.sed)
	
	#blender.count_biomes([
	#Vector2(0, 0), Vector2(0, 1), Vector2(1, 0), \
	#Vector2(0, -1), Vector2(-1, 0), Vector2(1, -1), \
	#Vector2(-1, 1), Vector2(1, 1), Vector2(-1, -1), \
	#Vector2(0, 2), Vector2(2, 0), \
	#Vector2(0, -2), Vector2(-2, 0), Vector2(2, -2), \
	#Vector2(-2, 2), Vector2(2, 2), Vector2(-2, -2), \
	#Vector2(0, 200), Vector2(200, 0), \
	#Vector2(0, -200), Vector2(-200, 0), Vector2(200, -200), \
	#Vector2(-200, 200), Vector2(200, 200), Vector2(-200, -200), \
	#Vector2(0, 2000), Vector2(2000, 0), \
	#Vector2(0, -2000), Vector2(-2000, 0), Vector2(2000, -2000), \
	#Vector2(-2000, 2000), Vector2(2000, 2000), Vector2(-2000, -2000), \
	#])
	
	chunker = Terrain.new(blender, 256, 128, 4, 0.0625, 16, true)
	build_terrain()
	var space := get_world_3d().space
	var state := PhysicsServer3D.space_get_direct_state(space)
	update_terrain(state)
	
	skybox = SkyBox.new(world_environment, sun, moon)
	skybox.day_time = rng.randf_range(0.0, 24.0)
	skybox.day_of_year = rng.randi_range(1, 365)
	
	main_menu.main_menu_world = get_node(".")
	load_game.main_menu_world = get_node(".")
	new_game.main_menu_world = get_node(".")
	settings_menu.main_menu_world = get_node(".")
	
	(title.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("base_seed", randi_range(0, 1000000))
	
func _physics_process(delta: float) -> void:
	daytime_tick += delta
			
	if daytime_tick >= 0.166667:
		const DAY_TICK = 0.000277783
		if skybox.day_time + DAY_TICK >= SkyBox.HOURS_IN_DAY:
			skybox.day_time = 0.0
			if skybox.day_of_year + 1 > SkyBox.DAYS_IN_YEAR:
				skybox.day_of_year = 1
			else:
				skybox.day_of_year += 1
		else:
			skybox.day_time += DAY_TICK
		daytime_tick = 0.0
		settings.time_of_day = skybox.day_time
		settings.day_of_the_year = skybox.day_of_year
		world_environment.environment.ambient_light_color = NoiseBlender.environment_ambient_color(settings.time_of_day, sun, moon)
		sun.light_color = world_environment.environment.ambient_light_color
		
		var space := get_world_3d().space
		var state := PhysicsServer3D.space_get_direct_state(space)
		_on_player_moved(0.25, state)
		
	player.position += player_movement_direction * delta
	player.rotate_y(player_rotation_direction * delta)
	blender.compute_biome_distances(player.position.x, player.position.z, chunker.get_noise_scale())
	var b := blender.biome
	if last_biome != b:
		print(World.Biome.keys()[b])
		last_biome = b
		var theme := load(ProjectSettings.get("gui/theme/custom") as String) as ThemeUI
		var tint := NoiseBlender.color_for_biome(b).darkened(0.5)
		theme.change_tint_color(tint)
		var day_ratio := skybox.day_time / SkyBox.HOURS_IN_DAY
		var is_day := 0.25 <= day_ratio and day_ratio <= 0.75 
		var fg := tint
		var bg := tint
		if not is_day:
			fg.v = fg.v * 1.5
		else:
			bg.v = bg.v * 1.5
		(title.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("fg_color", Color(fg, 1.0))
		#(title.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("bg_color", Color(bg, 1.0))
		#title.modulate = tint
		#title.outline_modulate = tint
		var particle_color := tint
		particle_color.v = particle_color.v * 1.5
		(source.process_material as ParticleProcessMaterial).color = particle_color
		(placard.mesh.surface_get_material(0) as ShaderMaterial).set_shader_parameter("outline_color", tint)
		transition_to_biome(b)
			
	if not has_init_terrain_population:
		var space := get_world_3d().space
		var state := PhysicsServer3D.space_get_direct_state(space)
		has_init_terrain_population = true
		player.position.y = Navigator.get_world_height(state, player.position.x, player.position.z)
		chunker.update_environment(player.position.x, player.position.z)
		
	player.position.y = maxf(player.position.y, blender.sea_level)
				

func _on_player_moved(delta: float, state: PhysicsDirectSpaceState3D) -> void:	
	terrain_update_interval = 0
	update_terrain(state)
	var h := Navigator.get_world_height(state, player.position.x, player.position.z)
	player_movement_direction.y = h - player.position.y
	if player.position.y < h + 1.0:
		player.position.y = lerpf(player.position.y, h + 1.0, 0.1)
		
		
func build_terrain() -> void:
	var chunks := chunker.init_chunks(player.position.x, player.position.z)
	for chunk in chunks:
		add_child(chunk)
	var heighest_pos := chunker.backing.get_max_height_position()
	if heighest_pos.is_finite():
		player.position = heighest_pos
		player.position.y = maxf(player.position.y, blender.sea_level)
	
	var direction := player.position.direction_to(chunker.backing.get_min_height_position())
	var goal_position := player.position + direction * 10.0
	goal_position.y = player.position.y
	if not goal_position.is_equal_approx(player.position):
		player.look_at(goal_position)

func update_terrain(state: PhysicsDirectSpaceState3D) -> void:
	var chunks := chunker.update_chunks(player.position.x, player.position.z)
	for loc: Vector2 in chunks.get("removed", []):
		var pop : Population = population.get(loc, null)
		if pop == null:
			continue
		pop.despawn_all_from_world(get_node(".") as Node3D)
		population.erase(loc)

	await get_tree().physics_frame
	chunker.update_environment(player.position.x, player.position.z)

	
func quit_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://GUI/Main Menu/MainMenu.tscn")

enum MenuScreenKind { MAIN, LOAD, NEW, SETTINGS }
func show_menu_screen(kind: MenuScreenKind) -> void:
	main_menu.hide()
	load_game.hide()
	new_game.hide()
	settings_menu.hide()
	title.hide()
	placard.hide()
	match kind:
		MenuScreenKind.MAIN: 
			main_menu.show()
			placard.show()
			title.show()
		MenuScreenKind.LOAD: load_game.show()
		MenuScreenKind.NEW: new_game.show()
		MenuScreenKind.SETTINGS: settings_menu.show()


func transition_to_biome(biome: World.Biome) -> void:
	if biome_tween != null:
		biome_tween_next = biome
		return
	
	#var env := get_node("WorldEnvironment") as WorldEnvironment
	var update_world := func(a: float) -> void:
		var shader := world_environment.environment.sky.sky_material as ShaderMaterial
		shader.set_shader_parameter("transition", a)
		
	biome_tween = get_tree().create_tween()
	var lvl := Population.level_relative_to_position_within_radius(null, player.position.x, player.position.z, settings.world_radius)
	NoiseBlender.update_world_environment(world_environment, sun, moon, lvl, biome, false)
	biome_tween.tween_method(update_world, 0.0, 1.0, 0.5)
	biome_tween.finished.connect(func() -> void:
		NoiseBlender.update_world_environment(world_environment, sun, moon, lvl, biome, true)
		update_world.call(0.0)
		if biome_tween_next != World.Biome.WATER:
			biome_tween = null
			var b := biome_tween_next
			biome_tween_next = World.Biome.WATER
			transition_to_biome(b)
		else:
			biome_tween = null			
	)


func _on_button_pressed() -> void:
	NoiseBlender.print_world_environment(world_environment, sun, moon)


func _on_button_2_pressed() -> void:
	skybox.day_time = fmod(snappedf(skybox.day_time + 6, 6), 24)
