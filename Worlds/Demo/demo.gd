extends Node

@onready var player: Player = $Player
@onready var ground = $Ground
# @onready var ground_mesh = $Ground/Mesh
# @onready var ground_collision = $Ground/Collision
@onready var magic_book = $MagicBook
@onready var wand_case = $WandCase

@export var noise_elevation: Noise
@export var noise_temperature: Noise
@export var noise_dryness: Noise
@onready var chunker = Terrain.new(noise_elevation, noise_dryness, noise_temperature, 128, 512)
@onready var population: Dictionary = {}

var terrain_update_interval = 0

var book: MagicBook
var case: WandCase
var wand: Wand

var showing_gui: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	book = MagicBook.new()
	book.load()
	
	build_terrain()
	
#	var w = Wand.new()
#	w.mods["LT"] = true
#	w.name = "Test"
#	w.build_keys()
#	w.keys[["LT"]] = Wand.Option.new(Wand.Kind.MOD)
	
	case = WandCase.new()
#	case.wands = [w]
	case.load()
	# FIXME: Support user selecting wands
	wand = case.wands[0]
	wand_case.use_current_wand = func(id: int):
		wand = case.wands[id]

		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _physics_process(delta):
	pass

var spell_index = 5

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if showing_gui:
			if magic_book.visible:
				book.save()
			if wand_case.visible:
				case.save()
			magic_book.visible = false
			wand_case.visible = false
			showing_gui = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
	if not showing_gui and event.is_action_pressed("magic_book"):
		magic_book.visible = true
		magic_book.book = book
		showing_gui = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
	if not showing_gui and event.is_action_pressed("wand_case"):
		wand_case.visible = true
		wand_case.case = case
		showing_gui = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if not showing_gui and event.is_action_pressed("RT"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
#		await player.cast_spell(func(p): if p != null: add_child(p), book.spells[spell_index])
		
	if not showing_gui:
		for k in wand.basic_keys:
			if event.is_action_pressed(k):
				var s = wand.action_down(k, book)
				if s != null:
					await player.cast_spell(func(p): if p != null: add_child(p), s)
			if event.is_action_released(k):
				wand.action_up(k)
		
	if not showing_gui and event.is_action_pressed("LT"):
		var hover = Spell.new(true, "-0.5", "t * 30 - 20", "0.5", "2", 1, 0.5, Spell.Element.AIR, 1)
		player.cast_spell(func(p): add_child(p), hover)


func _on_player_moved(delta: float):
	terrain_update_interval += delta
	if terrain_update_interval >= 0.5: # update once per 5 second
		terrain_update_interval = 0
		update_terrain()
		
func build_terrain():
	var chunks = chunker.init_chunks(player.position.x, player.position.z)
	for chunk in chunks:
		ground.add_child(chunk)
		
	update_population_at(chunker.loaded_chunks_location)


func update_terrain():
	var chunks = chunker.update_chunks(player.position.x, player.position.z)
	
	for loc in chunks.get("removed", []):
		var pop = population[loc]
		pop.despawn_all_from_world(self)
		population.erase(loc)
		
	update_population_at(chunks.get("updated", []))

func update_population_at(locations: Array):
	for loc in locations:
		var coord = chunker.convert_position_to_coord(loc.x, loc.y)
		var pop = Population.new(coord, chunker.chunk_size, chunker.blender, player)
		pop.spawn_all_into_world(self)
		population[loc] = pop
