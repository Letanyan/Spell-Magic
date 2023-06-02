extends Node

@onready var player: Player = $Player
@onready var menu: Menu = $Menu

@export var noise_elevation: Noise
@export var noise_temperature: Noise
@export var noise_dryness: Noise
@onready var chunker: Terrain
@onready var population: Dictionary = {}

@onready var raycast = $RayCast3D
@onready var skybox: SkyBox

var terrain_update_interval = 0

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
	
	noise_elevation.frequency = 0.0002
	noise_temperature.frequency = 0.0001
	noise_dryness.frequency = 0.0001
	
	chunker = Terrain.new(noise_elevation, noise_dryness, noise_temperature, 256, 2)
	chunker.raycast = raycast
	build_terrain()
	
	skybox = SkyBox.new($WorldEnvironment, $Sun, $Moon)
	skybox.day_time = 14
	
	player.is_menu_showing = func(): return menu.is_showing
	player.position.y = Navigator.get_world_height(player.get_world_3d().direct_space_state, 0, 0)  # chunker.blender.height(0, 0) + 5

		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var b = chunker.blender.biome(player.position.x, player.position.z)
	$FPS.text = "[" + World.Biome.keys()[b] + "] " + str(player.position) + " FPS: " + str(Engine.get_frames_per_second())
	pass
	
func _physics_process(delta):
	knowledge_tick += 1

	if knowledge_tick == 60:
		knowledge_tick = 0
		for loc in population:
			var pop = population[loc]
			pop.update_info()
			
	if not menu.is_showing:
		const SPEED = 12.0
		var movement = VelocityMovement.get_input_strength("pan_left", "pan_right", "pan_forward", "pan_back") * SPEED
		if movement != Vector2.ZERO:
			player.pan_camera(movement)

func _input(event):
#	if event.is_action_pressed("debug1"):
#		chunker.switch_detail()
	
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


func _on_player_moved(delta: float):
	terrain_update_interval += delta
	if terrain_update_interval >= 0.5: # update once per 5 second
		terrain_update_interval = 0
		update_terrain()
#		await get_tree().physics_frame
#		chunker.update_environment(player.position.x, player.position.z)
		
func build_terrain():
	var chunks = chunker.init_chunks(player.position.x, player.position.z)
	for chunk in chunks:
		add_child(chunk)
	chunker.update_environment(player.position.x, player.position.z)
	update_population_at(chunker.loaded_chunks_location)


func update_terrain():
	var work = func():
		var chunks = chunker.update_chunks(player.position.x, player.position.z)

		for loc in chunks.get("removed", []):
			var pop = population.get(loc, null)
			if pop == null:
				continue
			pop.despawn_all_from_world(get_node("."))
			population.erase(loc)

		await get_tree().process_frame
		update_population_at(chunks.get("updated", []))
		return chunks.get("updated", []).size() > 0

	if await work.call() or true:
		await get_tree().physics_frame
		chunker.update_environment(player.position.x, player.position.z)
		
#	var thread = Thread.new()
#	thread.start(work)
#	if not thread.is_alive() and thread.wait_to_finish():
#		chunker.update_environment()
	

func update_population_at(locations: Array):
	for loc in locations:
		var coord = chunker.convert_position_to_coord(loc.x, loc.y, chunker.chunk_size)
		
		var pop = Population.new(coord, chunker.chunk_size, chunker.blender, player)
		pop.spawn_all_into_world(get_node("."))
		population[loc] = pop
