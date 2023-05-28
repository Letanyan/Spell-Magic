class_name Population

var rng: RandomNumberGenerator
var blender: NoiseBlender
var player: Player

var coord: Vector2
var chunk_size: float

var inhabitants: Array[Enemy] = []
var garden: Array[Node3D] = []

const undead = preload("res://Characters/Enemy/Undead/undead.tscn")

func _init(_coord: Vector2, _chunk_size: float, _blender: NoiseBlender, _player: Player):
	rng = RandomNumberGenerator.new()
	coord = _coord
	blender = _blender
	player = _player
	chunk_size = _chunk_size
	seed_location()
	
func seed_location():
	rng.seed = hash("%f,%f" % [coord.x, coord.y])
	
func random_entity_from_distribution(probs: Dictionary) -> int:
	var keys = probs.keys()
	if keys.size() == 0:
		return 0
	
	var r = rng.randf()
	if keys.size() == 1:
		var i = keys[0]
		return keys[0] if r < probs[i] else 0
		
	var base := 0.0
	for n in range(0, keys.size()):
		var i = keys[n]
		var next_base = base + probs[i]
		if base <= r and r < next_base:
			return i
		base = next_base
	
	return 0
	
func random_enemy(probs: Dictionary) -> World.Enemy:
	return random_entity_from_distribution(probs) as World.Enemy
	
func random_foliage(probs: Dictionary) -> World.Foliage:
	return random_entity_from_distribution(probs) as World.Foliage
	
func random_building(probs: Dictionary) -> World.Building:
	return random_entity_from_distribution(probs) as World.Building
	
func prepare_entity(world: Node3D, entity: Node3D, pos: Vector3, is_enemy: bool):
	if entity != null:
		entity.position.x = pos.x
		entity.position.y = Navigator.get_world_height(world.get_world_3d().direct_space_state, pos.x, pos.z) + pos.y
		entity.position.z = pos.z
		if is_enemy:
			entity.player = player
			inhabitants.append(entity)
		else:
			garden.append(entity)
	return entity
	
func spawn_enemy(enemy: World.Enemy, world: Node3D, x: float, y: float, spacing: float) -> Enemy:
	var result = null
	var pos = Vector3(x, 0, y)
	match enemy:
		World.Enemy.UNDEAD:
			result = undead.instantiate()
			result.name = "Undead" + str(rng.randi())
	
	return prepare_entity(world, result, pos, true)
	
func spawn_foliage(foliage: World.Foliage, world: Node3D, x: float, y: float, spacing: float) -> Node3D:
	var result = null
	var pos = Vector3(x, 0, y)
	match foliage:
		World.Foliage.TREE_ROUND:
			result = Trees.make(Trees.Kind.ROUND, rng)
			pos.x += spacing * rng.randf_range(-0.5, 0.5)
			pos.z += spacing * rng.randf_range(-0.5, 0.5)
			result.name = "RoundTree" + str(rng.randi())
		World.Foliage.TREE_PYRAMID:
			result = Trees.make(Trees.Kind.PYRAMID, rng)
			pos.x += spacing * rng.randf_range(-0.5, 0.5)
			pos.z += spacing * rng.randf_range(-0.5, 0.5)
			result.name = "PyramidTree" + str(rng.randi())
	
	return prepare_entity(world, result, pos, false)
	
func spawn_building(building: World.Building, world: Node3D, x: float, y: float, spacing: float) -> Node3D:
	var result = null
	var pos = Vector3(x, 0, y)
	match building:
		World.Building.FANTASY_VALLEY_SINGLE:
			result = Buildings.make(Buildings.Kind.FANTASY_VALLEY_SINGLE, rng)
			pos.x += spacing * rng.randf_range(-0.25, 0.25)
			pos.z += spacing * rng.randf_range(-0.25, 0.25)
			result.name = "FantasyValleySingle" + str(rng.randi())
		World.Building.FANTASY_VALLEY_DOUBLE:
			result = Buildings.make(Buildings.Kind.FANTASY_VALLEY_DOUBLE, rng)
			pos.x += spacing * rng.randf_range(-0.25, 0.25)
			pos.z += spacing * rng.randf_range(-0.25, 0.25)
			result.name = "FantasyValleyDouble" + str(rng.randi())
	
	return prepare_entity(world, result, pos, false)
	
func spawn_random_enemy(biome_prob: Dictionary, world: Node3D, x: float, y: float, spacing: float) -> Enemy:
	return spawn_enemy(random_enemy(biome_prob), world, x, y, spacing)
	
func spawn_random_foliage(biome_prob: Dictionary, world: Node3D, x: float, y: float, spacing: float) -> Node3D:
	return spawn_foliage(random_foliage(biome_prob), world, x, y, spacing)
	
func spawn_random_building(biome_prob: Dictionary, world: Node3D, x: float, y: float, spacing: float) -> Node3D:
	return spawn_building(random_building(biome_prob), world, x, y, spacing)
	
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
	const spacing = 16.0
	var areas = group_spawn_points(spacing)
	var points = areas["points"]
	var biomes = areas["biomes"]

	for i in range(biomes.size()):
		match biomes[i]:
			World.Biome.GRASSLAND: GrasslandGen.populate(self, world, points[i], spacing)
			World.Biome.FOREST: ForestGen.populate(self, world, points[i], spacing)
	
func despawn_all_from_world(world: Node3D):
	for habitant in inhabitants:
		world.remove_child(habitant)
	for f in garden:
		world.remove_child(f)
	inhabitants.clear()
	garden.clear()

func update_info():
	for habitant in inhabitants:
		if abs(habitant.position.distance_to(player.position)) < habitant.vitals.perception.value:
			habitant.knowledge.update_entry_from(player)
		for other in inhabitants:
			if habitant != other and abs(habitant.position.distance_to(other.position)) < habitant.vitals.perception.value:
				habitant.knowledge.update_entry_from(other)
	for habitant in inhabitants:
		for object in garden:
			if abs(habitant.position.distance_to(object.position)) < habitant.vitals.perception.value:
				habitant.knowledge.update_entry_from(object)
