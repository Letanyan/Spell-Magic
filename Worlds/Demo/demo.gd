extends Node

@onready var player: Player = $Player
@onready var ground = $Ground
# @onready var ground_mesh = $Ground/Mesh
# @onready var ground_collision = $Ground/Collision
@onready var menu: Menu = $Menu

@export var noise_elevation: Noise
@export var noise_temperature: Noise
@export var noise_dryness: Noise
@onready var chunker = Terrain.new(noise_elevation, noise_dryness, noise_temperature, 128, 1280)
@onready var population: Dictionary = {}

@onready var raycast = $RayCast3D

var terrain_update_interval = 0

var book: MagicBook
var case: WandCase
var wand: Wand

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
	
	chunker.raycast = raycast
	
	noise_elevation.frequency = 0.0001
	noise_temperature.frequency = 0.0001
	noise_dryness.frequency = 0.0001
	
	build_terrain()

		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _physics_process(delta):
	pass

var spell_index = 5

func _input(event):
	if event.is_action_pressed("ui_cancel"):
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
#		await player.cast_spell(func(p): if p != null: add_child(p), book.spells[spell_index])
		
	if not menu.is_showing:
		for k in wand.basic_keys:
			if event.is_action_pressed(k):
				var s = wand.action_down(k, book)
				if s != null:
					await player.cast_spell(func(p): if p != null: add_child(p), s)
			if event.is_action_released(k):
				wand.action_up(k)


func _on_player_moved(delta: float):
	terrain_update_interval += delta
	if terrain_update_interval >= 0.5: # update once per 5 second
		terrain_update_interval = 0
		update_terrain()
		
func build_terrain():
	var chunks = chunker.init_chunks(player.position.x, player.position.z)
	for chunk in chunks:
		ground.add_child(chunk)
	chunker.update_environment()
	update_population_at(chunker.loaded_chunks_location)


func update_terrain():
	var work = func():
		var chunks = chunker.update_chunks(player.position.x, player.position.z)

		for loc in chunks.get("removed", []):
			var pop = population[loc]
			pop.despawn_all_from_world(self)
			population.erase(loc)
		
		update_population_at(chunks.get("updated", []))
		return chunks.get("updated", []).size() > 0
	
	if work.call():
		chunker.update_environment()
		
#	var thread = Thread.new()
#	thread.start(work)
#	if not thread.is_alive() and thread.wait_to_finish():
#		chunker.update_environment()
	

func update_population_at(locations: Array):
	for loc in locations:
		var coord = chunker.convert_position_to_coord(loc.x, loc.y)
		var pop = Population.new(coord, chunker.chunk_size, chunker.blender, player)
		pop.spawn_all_into_world(self)
		population[loc] = pop
