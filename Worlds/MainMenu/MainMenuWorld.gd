class_name MainMenuWorld
extends Node3D

@onready var player: Marker3D = $Player
var player_movement_direction := Vector3.ZERO
var player_rotation_direction := 0.0
var requested_player_height := 0.0

@export var noise_temperature: Noise
@export var noise_dryness: Noise
@onready var chunker: Terrain
@onready var population: Dictionary = {}

var last_biome: World.Biome = World.Biome.WATER

@onready var skybox: SkyBox

var terrain_update_interval = 0
var has_init_terrain_population = false

var daytime_tick: int

var settings: WorldSettings

func setup(_settings: WorldSettings) -> void:
	settings = _settings
	
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
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
	var _settings := WorldSettings.new()
	_settings.world_name = "empty"
	_settings.sed = randi()
	setup(_settings)
	
		
	# Forest location for world seed 0
	player.position.x = randf_range(-10000, 10000)
	player.position.z = randf_range(-10000, 10000)
	player_movement_direction = Vector3(randf(), 0, randf()).normalized()
	player_rotation_direction = (randf() * 2 - 1) * PI / 16
		
	chunker = Terrain.new(noise_dryness, noise_temperature, settings.sed, 256, 2, 0.0625)
	#chunker.ignore_physics = true
	build_terrain()
	
	skybox = SkyBox.new($WorldEnvironment, $Sun, $Moon)
	skybox.day_time = randf_range(0.0, 24.0)
	skybox.day_of_year = randi_range(1, 365)
	
	$MainMenu.main_menu_world = get_node(".")
	$LoadGame.main_menu_world = get_node(".")
	$NewGame.main_menu_world = get_node(".")
	$SettingsMenu.main_menu_world = get_node(".")

		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _physics_process(delta):
	daytime_tick += 1
			
	if daytime_tick == 10:
		const DAY_TICK = 0.000277783
		if skybox.day_time + DAY_TICK >= SkyBox.HOURS_IN_DAY:
			skybox.day_time = 0
			if skybox.day_of_year + 1 > SkyBox.DAYS_IN_YEAR:
				skybox.day_of_year = 1
			else:
				skybox.day_of_year += 1
		else:
			skybox.day_time += DAY_TICK
		daytime_tick = 0
		settings.time_of_day = skybox.day_time
		settings.day_of_the_year = skybox.day_of_year
		var space := get_world_3d().space
		var state := PhysicsServer3D.space_get_direct_state(space)
		_on_player_moved(0.25, state)
		
	player.position += player_movement_direction * delta
	player.rotate_y(player_rotation_direction * delta)
			
	if not has_init_terrain_population:
		var space := get_world_3d().space
		var state := PhysicsServer3D.space_get_direct_state(space)
		has_init_terrain_population = true
		player.position.y = Navigator.get_world_height(state, player.position.x, player.position.z)
		chunker.update_environment(player.position.x, player.position.z)

func _input(event):
	pass
				

func _on_player_moved(delta: float, state: PhysicsDirectSpaceState3D):	
	terrain_update_interval += delta
	
	if terrain_update_interval >= 0.25:
		terrain_update_interval = 0
		update_terrain(state)
		player_movement_direction.y = Navigator.get_world_height(state, player.position.x, player.position.z) - player.position.y
		player_movement_direction.y = player_movement_direction.normalized().y
		
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

	await get_tree().physics_frame
	chunker.update_environment(player.position.x, player.position.z)

	
func quit_to_main_menu():
	get_tree().change_scene_to_file("res://GUI/Main Menu/MainMenu.tscn")

enum MenuScreenKind { MAIN, LOAD, NEW, SETTINGS }
func show_menu_screen(kind: MenuScreenKind):
	$MainMenu.hide()
	$LoadGame.hide()
	$NewGame.hide()
	$SettingsMenu.hide()
	match kind:
		MenuScreenKind.MAIN: $MainMenu.show()
		MenuScreenKind.LOAD: $LoadGmae.show()
		MenuScreenKind.NEW: $NewGame.show()
		MenuScreenKind.SETTINGS: $SettingsMenu.show()
