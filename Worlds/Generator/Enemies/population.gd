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

var inhabitants: Array[Enemy] = []

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
		
	
func spawn(world: Node3D, x: float, y: float) -> Enemy:
	var biome = blender.biome(x, y)
	
	var result = null
	match random_enemy(biome):
		World.Enemy.UNDEAD:
			result = undead.instantiate()
			result.name = "Undead" + str(rng.randi())
		
	if result != null:
		result.player = player
		result.position.x = x
		result.position.y = Navigator.get_world_height(world.get_world_3d().direct_space_state, x, y)
		result.position.z = y
		inhabitants.append(result)
		
	return result
	
static func contains_neighbour_point(collection: Array, point: Vector2, spacing: float) -> bool:
	for p in collection:
		if p.distance_to(point) <= spacing:
			return true
	return false
	
func group_spawn_points(spacing: float) -> Dictionary:
	var result: Array = []
	var biomes: Array = []
	for x in range(-chunk_size / 2.0 + spacing / 2.0, chunk_size / 2.0 - spacing / 2.0 + 1.0, spacing):
		for y in range(-chunk_size / 2.0 + spacing / 2.0, chunk_size / 2.0 - spacing / 2.0 + 1.0, spacing):
			var p = Vector2(coord.x * chunk_size + x, coord.y * chunk_size + y)
			var biome = blender.biome(p.x, p.y)
			var found_subset = false
			for i in range(result.size()):
				if biomes[i] == biome and Population.contains_neighbour_point(result[i], p, spacing):
					result[i].append(p)
					found_subset = true
					break
			if not found_subset:
				result.append([p])
				biomes.append(biome)
	return {"points": result, "biomes": biomes}
	
func spawn_all_into_world(world: Node3D):
#	var areas = group_spawn_points(16.0)
#	var points = areas["points"]
#	var biomes = areas["biomes"]
#
#	for i in range(biomes.size()):
#		if biomes[i] == World.Biome.GRASSLAND:
#			for pos in points[i]:
#				var p = spawn(world, pos.x, pos.y)
#				if p != null:
#					world.add_child(p)
	
	var spacing = 16.0
	var limit = 100000
	for x in range(-chunk_size / 2.0 + spacing / 2.0, chunk_size / 2.0 - spacing / 2.0 + 1.0, spacing):
		for y in range(-chunk_size / 2.0 + spacing / 2.0, chunk_size / 2.0 - spacing / 2.0 + 1.0, spacing):
			if limit <= 0:
				return
			var p = spawn(world, coord.x * chunk_size + x, coord.y * chunk_size + y)
			if p != null:
				limit -= 1
				world.add_child(p)
	
func despawn_all_from_world(world: Node3D):
	for habitant in inhabitants:
		world.remove_child(habitant)
	inhabitants.clear()

func update_info(scatter: Scatter):
	for habitant in inhabitants:
		if abs(habitant.position.distance_to(player.position)) < habitant.vitals.perception.value:
			habitant.knowledge.update_entry_from(player)
		for other in inhabitants:
			if habitant != other and abs(habitant.position.distance_to(other.position)) < habitant.vitals.perception.value:
				habitant.knowledge.update_entry_from(other)
	for habitant in inhabitants:
		for object in scatter.inhabitants:
			if abs(habitant.position.distance_to(object.position)) < habitant.vitals.perception.value:
				habitant.knowledge.update_entry_from(object)
