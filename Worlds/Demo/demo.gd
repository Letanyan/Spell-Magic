extends Node

@onready var player: Player = $Player
@onready var ground = $Ground
# @onready var ground_mesh = $Ground/Mesh
# @onready var ground_collision = $Ground/Collision

@export var noise_elevation: Noise
@export var noise_temperature: Noise
@export var noise_dryness: Noise
@onready var chunker = Terrain.new(noise_elevation, noise_dryness, noise_temperature, 128, 512)
@onready var population: Dictionary = {}

var terrain_update_interval = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	build_terrain()

		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _physics_process(delta):
	pass

var spell_index = 5

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if event.is_action_pressed("one"):
		spell_index = 0
	if event.is_action_pressed("two"):
		spell_index = 1
	if event.is_action_pressed("three"):
		spell_index = 2
	if event.is_action_pressed("four"):
		spell_index = 3
	if event.is_action_pressed("five"):
		spell_index = 4
	if event.is_action_pressed("six"):
		spell_index = 5
	if event.is_action_pressed("seven"):
		spell_index = 6
	if event.is_action_pressed("eight"):
		spell_index = 7
	if event.is_action_pressed("nine"):
		spell_index = 8
	if event.is_action_pressed("zero"):
		spell_index = 9
		
	if event.is_action_pressed("fire"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		var spell_vars = player.spell_variables(true)
		var circle = Spell.new(true, "sin(t * 2) * 5", "-0.2", "cos(t * 2) * 5", "1", 0.5, 50000, Spell.Element.FIRE, 1, spell_vars)
		var blast = Spell.new(false, 
			"u * 2 + (t - n) * u * 10 * gt(t - n)", 
			"v * 2 + (t - n) * v * 10 * gt(t - n)", 
			"w * 2 + (t - n) * w * 10 * gt(t - n)", 
			"1", 0.3, 5000, Spell.Element.FIRE, 1, spell_vars)
		var drop = Spell.new(false, "u * 5", "t * -9.8 * 3 + 15", "w * 5", "1 + r0 * 5", 0.5, 50000, Spell.Element.ROCK, 1, spell_vars)
		var push = Spell.new(false, "u * 30 * t + u * 2", "t * 20 * v", "w * 30 * t + w * 2", "1 + r0 * 0", 0.2, 50000, Spell.Element.ROCK, 1, spell_vars)
		var aqua = Spell.new(false, "t * u * 10", "t * v * 10 + 2", "t * w * 10", "t", 0, 5000, Spell.Element.WATER, 1, spell_vars)
		var back = Spell.new(false, "u * -20 * t + u * 5", "-0.75", "w * -20 * t + w * 5", "1 + r0 * 0", 0.3, 50000, Spell.Element.ROCK, 1, spell_vars)
		var fan = Spell.new(false, "u * 2 + u * 2 * (t / 5)", "-0.75 + v * (t / 5)", "w * 2 + w * 2 * (t / 5)", "2", 0.8, 50000, Spell.Element.AIR, 1, spell_vars)
		var hover = Spell.new(true, "-6 * u + u * t * 6", "-6 * v + v * t * 6", "-6 * w + w * t * 6", "2", 0.8, 500, Spell.Element.AIR, 1, spell_vars)
		var spire = Spell.new(false, "sin(n / N * pi * 2) * t * 5", "3", "cos(n / N * pi * 2) * t * 5", "0.5", 0.1, 10000, Spell.Element.FIRE, 8, spell_vars)
		
		var spells = [
			drop, # 1
			push, # 2
			back, # 3
			fan,  # 4
			circle, # 5
			blast, # 6
			aqua, # 7
			hover, #8
			spire, #9
		]
		
		for p in player.cast_spell(spells[spell_index]):
			add_child(p)
		
	if event.is_action_pressed("shift"):
#		player.set_movement_target(Vector3(randf() * 10, randf() * 10, randf() * 10))
		var spell_vars = player.spell_variables(true)
		var hover = Spell.new(true, "-0.5", "t * 30 - 20", "0.5", "2", 1, 500, Spell.Element.AIR, 1, spell_vars)
		for p in player.cast_spell(hover):
			add_child(p)


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
