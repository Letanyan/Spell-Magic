extends Node3D

@onready var player: Player = $Player
@onready var menu: Menu = $Menu

@export var noise_temperature: Noise
@export var noise_dryness: Noise
@onready var chunker: Terrain
@onready var population: Dictionary = {}

@onready var skybox: SkyBox

var terrain_update_interval = 0
var has_init_terrain_population = false

var book: MagicBook
var case: WandCase
var wand: Wand

var knowledge_tick: int

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	book = MagicBook.new()
	book.load()
	
	case = WandCase.new()
	case.load()
	
	menu.setup(book, case)
	
	wand = case.wands[0]
	menu.wand_case.use_current_wand = func(id: int):
		wand = case.wands[id]
	
	noise_temperature.frequency = 0.0001
	noise_dryness.frequency = 0.0001
	
	chunker = Terrain.new(noise_dryness, noise_temperature, 256, 2)
	build_terrain()
	
	skybox = SkyBox.new($WorldEnvironment, $Sun, $Moon)
	skybox.day_time = 14
	
	player.is_menu_showing = func(): return menu.is_showing

		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	chunker.blender.compute_biome_distances(player.position.x, player.position.z)
	var b := chunker.blender.biome
	$FPS.text = "[" + World.Biome.keys()[b] + "] " + str(player.position) + " FPS: " + str(Engine.get_frames_per_second())
	pass
	
func _physics_process(delta):
	knowledge_tick += 1

	if knowledge_tick == 60 and has_init_terrain_population:
		knowledge_tick = 0
		for loc in population:
			var pop = population[loc]
			pop.update_info()
			
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
		player.position.y = Navigator.get_world_height(state, 0, 0)
		chunker.update_environment(player.position.x, player.position.z)

func _input(event):
	if event.is_action_pressed("menu"):
		if menu.is_showing:
			menu.close()
		else:
			menu.open(Menu.Kind.ANY)
			
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
			if event.is_action_pressed(k):
				s = wand.action_down(k, book)
			if event.is_action_released(k):
				s = wand.action_up(k, book)
			if s != null:
				player.cast_spell(func(p): if p != null: call_deferred("add_child", p), s)


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
		result.append_array(pop.spawn_all_into_world(state))
		population[loc] = pop
		
	return result
