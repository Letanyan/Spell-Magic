class_name Population

# Each enemy has a probability of spawning in a biome
const ENEMY_SPAWN_PROB: Dictionary = {
	NoiseBlender.Biome.GRASSLAND: 0.01,
	NoiseBlender.Biome.SAVANNAH: 0.02,
	NoiseBlender.Biome.WATER: 0.01,
}

var rng: RandomNumberGenerator
var blender: NoiseBlender

var coord: Vector2
var chunk_size: float

var inhabitants = []

func _init(_coord: Vector2, _chunk_size: float, _blender: NoiseBlender):
	rng = RandomNumberGenerator.new()
	coord = _coord
	blender = _blender
	chunk_size = _chunk_size
	seed_location()
	
func seed_location():
	rng.seed = hash("%f,%f" % [coord.x, coord.y])
	
func spawn(x: float, y: float) -> Enemy:
	var biome = blender.biome(x, y)
	var prob = ENEMY_SPAWN_PROB.get(biome, 0.0)
	
	var result = null
	if rng.randf() < prob:
		result = load("res://Characters/Enemy/enemy.tscn").instantiate()
		result.blender = blender
		result.position.x = x
		result.position.y = blender.height(x, y) + 5
		result.position.z = y
		
	if result != null:
		inhabitants.append(result)
		
	return result
	
func spawn_all_into_world(world: Node):
	var spacing = 16
	for x in range(-chunk_size / 2, chunk_size / 2 + 1, spacing):
		for y in range(-chunk_size / 2, chunk_size / 2 + 1, spacing):
			var p = spawn(coord.x * chunk_size + x, coord.y * chunk_size + y)
			if p != null:
				world.add_child(p)
	
func despawn_all_from_world(world: Node):
	for habitant in inhabitants:
		world.remove_child(habitant)
	inhabitants.clear()
