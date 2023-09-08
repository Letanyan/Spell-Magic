class_name Population

var rng: RandomNumberGenerator
var blender: NoiseBlender
var player: Player

var coord: Vector2
var chunk_size: float

var is_ready := false

var inhabitants: Dictionary = {}
var garden: Array[Node3D] = []

const undead = preload("res://Characters/Enemy/Undead/undead.tscn")
const bat = preload("res://Characters/Enemy/Bat/bat.tscn")
const mole = preload("res://Characters/Enemy/Mole/mole.tscn")
const human = preload("res://Characters/Enemy/Human/human.tscn")
const walker = preload("res://Characters/Enemy/Walker/walker.tscn")

signal on_enemy_death(drop_artifact: Artifact)

func _init(_coord: Vector2, _chunk_size: float, _blender: NoiseBlender, _player: Player):
	rng = RandomNumberGenerator.new()
	coord = _coord
	blender = _blender
	player = _player
	chunk_size = _chunk_size
	seed_location()
	
func seed_location():
	rng.seed = hash("%f,%f" % [coord.x, coord.y])
	
# probs: (prob: Variant -> float)
# probs is a dictionary where each key has its 'value' as a value of being choosen relative to other siblings
static func random_entity_from_distribution(r: float, probs: Dictionary, default = 0) -> Variant:
	var keys := probs.keys()
	if keys.size() == 0:
		return default
	
	if keys.size() == 1:
		return keys[0]
		
	var sum := 0.0
	for n in probs.values():
		sum += n
		
	var base := 0.0
	for n in range(0, keys.size()):
		var i = keys[n]
		var next_base : float = base + probs[i] / sum
		if base <= r and r < next_base:
			return i
		base = next_base
	
	return default
	
func random_enemy(probs: Dictionary) -> World.Enemy:
	return Population.random_entity_from_distribution(rng.randf(), probs) as World.Enemy
	
func random_foliage(probs: Dictionary) -> World.Foliage:
	return Population.random_entity_from_distribution(rng.randf(), probs) as World.Foliage
	
func random_building(probs: Dictionary) -> World.Building:
	return Population.random_entity_from_distribution(rng.randf(), probs) as World.Building
	
func always_valid(normal: Dictionary) -> bool:
	return true
	
func on_flat_surface(distance: float) -> Callable:
	return func(normal: Dictionary) -> bool:
		return normal.get("normal", Vector3.ZERO).distance_to(Vector3.UP) < distance
	
func prepare_entity(state: PhysicsDirectSpaceState3D, entity: Node3D, pos: Vector3, is_enemy: bool, condition: Callable = always_valid):
	if entity != null:
		var world_normal = Navigator.get_world_normal_height(state, pos.x, pos.z)
		var wh: float = world_normal.get("position", Vector3.ZERO).y + pos.y
		if wh < Globals.sea_level():
			return null
		if not condition.call(world_normal):
			return null
		entity.position.x = pos.x
		entity.position.y = wh
		entity.position.z = pos.z
		if is_enemy:
			entity.player = player
			entity.index_in_population = inhabitants.size()
			inhabitants[inhabitants.size()] = entity
		else:
			garden.append(entity)
	return entity
	
func spawn_enemy(enemy: World.Enemy, state: PhysicsDirectSpaceState3D, x: float, y: float, spacing: float) -> Enemy:
	var result: Enemy = null
	var pos := Vector3(x, 0, y)
	match enemy:
		World.Enemy.UNDEAD:
			result = undead.instantiate() as Enemy
			result.name = "Undead" + str(rng.randi())
		World.Enemy.BAT:
			result = bat.instantiate()
			result.name = "Bat" + str(rng.randi())
		World.Enemy.MOLE:
			result = mole.instantiate()
			result.name = "Mole" + str(rng.randi())
		World.Enemy.HUMAN:
			result = human.instantiate()
			result.name = "Human" + str(rng.randi())
		World.Enemy.WALKER:
			result = walker.instantiate()
			result.name = "Walker" + str(rng.randi())
			
	result.level = Vector2(x, y).length() / 1000.0
	result.level += rng.randi_range(0, int(result.level * 0.2))
	result.on_death.connect(on_enemy_death_update)
	result.vitals_signal.connect(habitant_vitals_update)
	return prepare_entity(state, result, pos, true)
	
func spawn_foliage(foliage: World.Foliage, state: PhysicsDirectSpaceState3D, x: float, y: float, spacing: float) -> Node3D:
	var result: Node3D = null
	var pos := Vector3(x, 0, y)
	match foliage:
		World.Foliage.TREE_ROUND, World.Foliage.TREE_PYRAMID, World.Foliage.TREE_CHRISTMAS, World.Foliage.TREE_BRANCHED, World.Foliage.TREE_SAFARI:
			result = Trees.make(foliage, rng)
			pos.x += spacing * rng.randf_range(-0.5, 0.5)
			pos.z += spacing * rng.randf_range(-0.5, 0.5)
			result.name = World.Foliage.keys()[foliage] + str(rng.randi())
	
	return prepare_entity(state, result, pos, false)
	
func spawn_building(building: World.Building, state: PhysicsDirectSpaceState3D, x: float, y: float, spacing: float) -> Node3D:
	var result: Node3D = null
	var pos := Vector3(x, 0, y)
	var ground_angle := 0.0
	match building:
		World.Building.FANTASY_VALLEY_SINGLE, World.Building.FANTASY_VALLEY_DOUBLE:
			result = Buildings.make(building, rng)
			pos.x += spacing * rng.randf_range(-0.25, 0.25)
			pos.z += spacing * rng.randf_range(-0.25, 0.25)
			result.name = World.Building.keys()[building] + str(rng.randi())
			ground_angle = 0.1
		World.Building.FANTASY_WELL:
			result = Buildings.make(building, rng)
			pos.x += spacing * rng.randf_range(-0.25, 0.25)
			pos.z += spacing * rng.randf_range(-0.25, 0.25)
			result.name = World.Building.keys()[building] + str(rng.randi())
			ground_angle = 0.2
	
	return prepare_entity(state, result, pos, false, on_flat_surface(ground_angle))
	
func spawn_random_enemy(biome_prob: Dictionary, state: PhysicsDirectSpaceState3D, x: float, y: float, spacing: float) -> Enemy:
	return spawn_enemy(random_enemy(biome_prob), state, x, y, spacing)
	
func spawn_random_foliage(biome_prob: Dictionary, state: PhysicsDirectSpaceState3D, x: float, y: float, spacing: float) -> Node3D:
	return spawn_foliage(random_foliage(biome_prob), state, x, y, spacing)
	
func spawn_random_building(biome_prob: Dictionary, state: PhysicsDirectSpaceState3D, x: float, y: float, spacing: float) -> Node3D:
	return spawn_building(random_building(biome_prob), state, x, y, spacing)
	
static func contains_neighbour_point(collection: PackedVector2Array, point: Vector2, spacing: float) -> bool:
	for p in collection:
		if p.distance_to(point) <= spacing:
			return true
	return false
	
func group_spawn_points(spacing: float) -> Dictionary:
	var result: Array[PackedVector2Array] = []
	var biomes: Array[World.Biome] = []
	for x in range(-chunk_size / 2.0 + spacing / 2.0, chunk_size / 2.0 - spacing / 2.0 + 1.0, spacing):
		for y in range(-chunk_size / 2.0 + spacing / 2.0, chunk_size / 2.0 - spacing / 2.0 + 1.0, spacing):
			var p := Vector2(coord.x * chunk_size + x, coord.y * chunk_size + y)
			blender.compute_biome_distances(p.x, p.y)
			var biome := blender.biome
			var found_subset := false
			for i in range(result.size()):
				if biomes[i] == biome and Population.contains_neighbour_point(result[i], p, spacing):
					result[i].append(p)
					found_subset = true
					break
			if not found_subset:
				result.append(PackedVector2Array([p]))
				biomes.append(biome)
	return {"points": result, "biomes": biomes}
	
static func points_around(point: Vector2, distance: float, offset: int, area: PackedVector2Array, exluding: Dictionary) -> PackedInt64Array:
	var indices: PackedInt64Array = []
	for i in range(offset, area.size()):
		if point.distance_to(area[i]) < distance and not exluding.has(i):
			indices.append(i)
	return indices
	
func spawn_all_into_world(state: PhysicsDirectSpaceState3D) -> Array:
	const spacing = 16.0
	var areas := group_spawn_points(spacing)
	var points: Array[PackedVector2Array] = areas["points"]
	var biomes: Array[World.Biome] = areas["biomes"]

	var result := []
	for i in range(biomes.size()):
		match biomes[i]:
			World.Biome.GRASSLAND: result.append_array(GrasslandGen.populate(self, state, points[i], spacing))
			World.Biome.FOREST: result.append_array(ForestGen.populate(self, state, points[i], spacing))
	
	return result
	
func despawn_all_from_world(world: Node3D):
	for habitant_index in inhabitants:
		var habitant = inhabitants[habitant_index]
		habitant.spell_caster.free_particles()
		habitant.queue_free()
	for f in garden:
		f.queue_free()
	inhabitants.clear()
	garden.clear()

func update_info():
	for habitant_index in inhabitants:
		var habitant = inhabitants[habitant_index]
		var dist: float = habitant.position.distance_to(player.position) 
		if dist < habitant.vitals.perception.value:
			habitant.knowledge.update_entry_from(player)
		var col: CollisionShape3D = habitant.get_node("./Collision")
		var area: CollisionShape3D = habitant.get_node("./WetArea/WetCollision")
		col.disabled = dist > 50
		area.disabled = col.disabled
		for other_index in inhabitants:
			var other = inhabitants[other_index]
			if habitant != other and abs(habitant.position.distance_to(other.position)) < habitant.vitals.perception.value:
				habitant.knowledge.update_entry_from(other)
	for habitant_index in inhabitants:
		var habitant = inhabitants[habitant_index]
		for object in garden:
			if habitant.position.distance_to(object.position) < habitant.vitals.perception.value:
				habitant.knowledge.update_entry_from(object)
	for g in garden:
		var s: CollisionShape3D = g.get_node("./static/shape")
		if s != null:
			s.disabled = g.position.distance_to(player.position) > 50
				

func habitant_vitals_update(index: int, vitals: Vitals):
	if index <= -1:
		return
	if vitals.health.value <= vitals.health.min_value:
		inhabitants[index].index_in_population = -1
		inhabitants.erase(index)

func on_enemy_death_update(enemy: Enemy, drop_artifact: Artifact):
	on_enemy_death.emit(enemy, drop_artifact)
