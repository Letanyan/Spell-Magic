class_name Population

# Each enemy has a probability of spawning in a biome
const ENEMY_SPAWN_PROB: Dictionary = {
	World.Biome.GRASSLAND: {
		World.Enemy.UNDEAD: 0.01
	},
	World.Biome.SAVANNAH: {
		World.Enemy.UNDEAD: 0.02
	},
	World.Biome.WATER: {
		World.Enemy.UNDEAD: 0.01
	},
}


var rng: RandomNumberGenerator
var blender: NoiseBlender
var player: Player

var coord: Vector2
var chunk_size: float

var inhabitants = []

var undead = preload("res://Characters/Enemy/Undead/undead.tscn")

func _init(_coord: Vector2, _chunk_size: float, _blender: NoiseBlender, _player: Player):
	rng = RandomNumberGenerator.new()
	coord = _coord
	blender = _blender
	player = _player
	chunk_size = _chunk_size
	seed_location()
	
func seed_location():
	rng.seed = hash("%f,%f" % [coord.x, coord.y])
	
func random_enemy(biome: World.Biome) -> World.Enemy:
	var probs = ENEMY_SPAWN_PROB.get(biome, {})
	var keys = probs.keys()
	if keys.size() == 0:
		return World.Enemy.NONE
	
	var r = rng.randf()
	if keys.size() == 1:
		var i = keys[0]
		return keys[0] if r < probs[i] else World.Enemy.NONE
		
	var base := 0.0
	for n in range(0, keys.size()):
		var i = keys[n]
		var next_base = base + probs[i]
		if base <= probs[i] and probs[i] < next_base:
			return i
		base = next_base
	
	return World.Enemy.NONE
		
	
func spawn(x: float, y: float) -> Enemy:
	var biome = blender.biome(x, y)
	
	var result = null
	match random_enemy(biome):
		World.Enemy.UNDEAD:
			result = undead.instantiate()
		
	if result != null:
		result.blender = blender
		result.player = player
		result.position.x = x
		result.position.y = blender.height(x, y) + 5
		result.position.z = y
		inhabitants.append(result)
		
	return result
	
func spawn_all_into_world(world: Node):
	var spacing = 16
	for x in range(-chunk_size / 2 + spacing / 2, chunk_size / 2 - spacing / 2 + 1, spacing):
		for y in range(-chunk_size / 2 + spacing / 2, chunk_size / 2 - spacing / 2 + 1, spacing):
			var p = spawn(coord.x * chunk_size + x, coord.y * chunk_size + y)
			if p != null:
				world.add_child(p)
	
func despawn_all_from_world(world: Node):
	for habitant in inhabitants:
		world.remove_child(habitant)
	inhabitants.clear()
