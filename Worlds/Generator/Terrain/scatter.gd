class_name Scatter

const ENEMY_SPAWN_PROB: Dictionary = {
	World.Biome.GRASSLAND: {
		World.Foliage.TREE_ROUND: 0.01
	},
	World.Biome.SAVANNAH: {
		World.Foliage.TREE_ROUND: 0.02
	},
	World.Biome.WATER: {
		World.Foliage.TREE_ROUND: 0.01
	},
	World.Biome.FOREST: {
		World.Foliage.TREE_ROUND: 0.01,
		World.Foliage.TREE_PYRAMID: 0.24
	}
}

var rng: RandomNumberGenerator
var blender: NoiseBlender
var player: Player

var coord: Vector2
var chunk_size: float

var inhabitants: Array[Node3D] = []

func _init(_coord: Vector2, _chunk_size: float, _blender: NoiseBlender, _player: Player) -> void:
	rng = RandomNumberGenerator.new()
	coord = _coord
	blender = _blender
	player = _player
	chunk_size = _chunk_size
	seed_location()
	
func seed_location() -> void:
	rng.seed = hash("%f,%f" % [coord.x, coord.y])
	
func random_terrain(biome: World.Biome) -> World.Foliage:
	var probs := ENEMY_SPAWN_PROB.get(biome, {}) as Dictionary
	var keys := probs.keys()
	if keys.size() == 0:
		return World.Foliage.NONE
	
	var r := rng.randf()
	if keys.size() == 1:
		var i := keys[0] as int
		return keys[0] if r < probs[i] else World.Enemy.NONE
		
	var base := 0.0
	for n in range(0, keys.size()):
		var i := keys[n] as int
		var next_base := base + (probs[i] as float)
		if base <= probs[i] and probs[i] < next_base:
			return i
		base = next_base
	
	return World.Foliage.NONE
		
	
func spawn(world: Node3D, x: float, y: float, spacing: float) -> Node3D:
	blender.compute_biome_distances(x, y)
	var biome := blender.biome
	
	var result: Node3D = null
	var displace := 0.0
	match random_terrain(biome):
		World.Foliage.TREE_ROUND:
			result = Trees.make(World.Foliage.TREE_ROUND, rng)
			displace = rng.randf_range(-0.5, 0.5)
			result.name = "RoundTree" + str(rng.randi())
		World.Foliage.TREE_PYRAMID:
			result = Trees.make(World.Foliage.TREE_PYRAMID, rng)
			displace = rng.randf_range(-0.5, 0.5)
			result.name = "PyramidTree" + str(rng.randi())
		
	if result != null:
		if displace:
			x += displace * spacing
			y += displace * spacing
		
		result.position.x = x
		result.position.y = Navigator.get_world_height(world.get_world_3d().direct_space_state, x, y)
		result.position.z = y
		inhabitants.append(result)
		
	return result
	
func spawn_all_into_world(world: Node3D) -> void:
	var spacing := 16.0
	for x in range(-chunk_size / 2.0 + spacing / 2.0, chunk_size / 2.0 - spacing / 2.0, spacing):
		for y in range(-chunk_size / 2.0 + spacing / 2.0, chunk_size / 2.0 - spacing / 2.0, spacing):
			var p := spawn(world, coord.x * chunk_size + x, coord.y * chunk_size + y, spacing)
			if p != null:
				world.add_child(p)
	
func despawn_all_from_world(world: Node3D) -> void:
	for habitant in inhabitants:
		world.remove_child(habitant)
	inhabitants.clear()
