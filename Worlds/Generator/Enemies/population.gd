class_name Population

var rng: RandomNumberGenerator
var blender: NoiseBlender
var player: Player
var entity_manager: EntityManager

var coord: Vector2
var chunk_size: float

var is_ready := false

var inhabitants: Dictionary = {}
var garden: Array[Node3D] = []

func _init(_coord: Vector2, _chunk_size: float, _blender: NoiseBlender, _player: Player, _entity_manager: EntityManager) -> void:
	rng = RandomNumberGenerator.new()
	coord = _coord
	blender = _blender
	player = _player
	chunk_size = _chunk_size
	entity_manager = _entity_manager
	seed_location()
	
func seed_location() -> void:
	rng.seed = hash("%f,%f" % [coord.x, coord.y])
	
# probs: [Variant]float|int
# probs is a dictionary where each key has its 'value' as a value of being choosen relative to other siblings
static func random_entity_from_distribution(r: float, probs: Dictionary, default: Variant = 0) -> Variant:
	var keys := probs.keys()
	if keys.size() == 0:
		return default
	
	if keys.size() == 1:
		return keys[0]
		
	var sum := 0.0
	for n: float in probs.values():
		sum += n
		
	var base := 0.0
	for n in range(0, keys.size()):
		var i: Variant = keys[n]
		var next_base : float = base + probs[i] / sum
		if base <= r and r < next_base:
			return i
		base = next_base
	
	return default
	
# probs: [Variant]float
# probs is a dictionary where each key has its 'value' as a value of being choosen. Sum of all values must equal 1.0
static func random_entity_from_non_relative_distribution(r: float, probs: Dictionary, default: Variant = 0) -> Variant:
	var keys := probs.keys()
	if keys.size() == 0:
		return default
	
	if keys.size() == 1:
		return keys[0]
		
	var base := 0.0
	for n in range(0, keys.size()):
		var i: Variant = keys[n]
		var next_base : float = base + probs[i]
		if base <= r and r < next_base:
			return i
		base = next_base
	
	return default
	
func always_valid(normal: Dictionary) -> Dictionary:
	return {"valid": true}
	
func on_flat_surface(distance: float) -> Callable:
	return func(normal: Dictionary) -> Dictionary:
		return {"valid": (normal.get("normal", Vector3.ZERO) as Vector3).angle_to(Vector3.UP) < distance, "y_offset": distance * -2}
	
func prepare_entity(state: PhysicsDirectSpaceState3D, entity: Node3D, pos: Vector3, is_enemy: bool, user_info: Callable = always_valid) -> Node3D:
	if entity != null:
		var world_normal := Navigator.get_world_normal_height(state, pos.x, pos.z)
		var wh: float = world_normal.get("position", Vector3.ZERO).y + pos.y
		if wh < Globals.sea_level():
			return null
		var info: Dictionary = user_info.call(world_normal) 
		if not info.get("valid", true):
			if is_enemy:
				entity_manager.free_enemy(entity as Enemy)
			else:
				if entity is Trees:
					entity_manager.free_tree(entity as Trees)
				elif entity is Buildings:
					entity_manager.free_building(entity as Buildings)
			return null
		entity.position.x = pos.x
		entity.position.y = wh + info.get("y_offset", 0.0)
		entity.position.z = pos.z
		if is_enemy:
			(entity as Enemy).player = player
			(entity as Enemy).index_in_population = inhabitants.size()
			inhabitants[inhabitants.size()] = entity
		else:
			garden.append(entity)
	return entity
	
func spawn_enemy(enemy: World.Enemy, state: PhysicsDirectSpaceState3D, x: float, y: float, spacing: float) -> Enemy:
	var result: Enemy = null
	var pos := Vector3(x, 0, y)
	match enemy:
		World.Enemy.UNDEAD:
			result = entity_manager.get_enemy(World.Enemy.UNDEAD)
			result.name = "Undead" + str(rng.randi())
		World.Enemy.BAT:
			result = entity_manager.get_enemy(World.Enemy.BAT)
			result.name = "Bat" + str(rng.randi())
		World.Enemy.MOLE:
			result = entity_manager.get_enemy(World.Enemy.MOLE)
			result.name = "Mole" + str(rng.randi())
		World.Enemy.HUMAN:
			result = entity_manager.get_enemy(World.Enemy.HUMAN)
			result.name = "Human" + str(rng.randi())
		World.Enemy.WALKER:
			result = entity_manager.get_enemy(World.Enemy.WALKER)
			result.name = "Walker" + str(rng.randi())
		World.Enemy.FISH:
			result = entity_manager.get_enemy(World.Enemy.FISH)
			result.name = "Fish" + str(rng.randi())
		World.Enemy.BIRDMAN:
			result = entity_manager.get_enemy(World.Enemy.BIRDMAN)
			result.name = "Birdman" + str(rng.randi())
			
	result.level = Vector2(x, y).length() / 1000.0
	result.level += rng.randi_range(0, int(result.level * 0.2)) + 1.0
	result.vital_update.connect(habitant_vitals_update)
	if result.get_parent(): 
		result.setup()
	return prepare_entity(state, result, pos, true)
	
static func generate_enemy(enemy: World.Enemy, _player: Player, x: float, y: float, z: float) -> Enemy:
	var result: Enemy = null
	match enemy:
		World.Enemy.UNDEAD:
			result = Enemy.make(World.Enemy.UNDEAD)
			result.name = "Undead" + str(randi())
		World.Enemy.BAT:
			result = Enemy.make(World.Enemy.BAT)
			result.name = "Bat" + str(randi())
		World.Enemy.MOLE:
			result = Enemy.make(World.Enemy.MOLE)
			result.name = "Mole" + str(randi())
		World.Enemy.HUMAN:
			result = Enemy.make(World.Enemy.HUMAN)
			result.name = "Human" + str(randi())
		World.Enemy.WALKER:
			result = Enemy.make(World.Enemy.WALKER)
			result.name = "Walker" + str(randi())
		World.Enemy.FISH:
			result = Enemy.make(World.Enemy.FISH)
			result.name = "Fish" + str(randi())
		World.Enemy.BIRDMAN:
			result = Enemy.make(World.Enemy.BIRDMAN)
			result.name = "Birdman" + str(randi())
			
	result.level = Vector2(x, y).length() / 1000.0
	result.level += randi_range(0, int(result.level * 0.2)) + 1.0
	result.player = _player
	result.position = Vector3(x, y, z)
	if result.get_parent():
		result.setup()
	return result

	
func spawn_foliage(foliage: World.Foliage, state: PhysicsDirectSpaceState3D, x: float, y: float, spacing: float) -> Node3D:
	var result: Node3D = null
	var pos := Vector3(x, 0, y)
	match foliage:
		World.Foliage.TREE_ROUND, World.Foliage.TREE_PYRAMID, World.Foliage.TREE_CHRISTMAS, World.Foliage.TREE_BRANCHED, World.Foliage.TREE_SAFARI:
			result = entity_manager.get_tree(foliage) as Trees
			pos.x += spacing * rng.randf_range(-0.5, 0.5)
			pos.z += spacing * rng.randf_range(-0.5, 0.5)
			result.name = World.Foliage.keys()[foliage] + str(rng.randi())
	
	(result as Trees).setup(rng)
	return prepare_entity(state, result, pos, false, on_flat_surface(PI / 8))
	
func spawn_building(building: World.Building, state: PhysicsDirectSpaceState3D, x: float, y: float, spacing: float) -> Node3D:
	var result: Node3D = null
	var pos := Vector3(x, 0, y)
	var ground_angle := 0.0
	match building:
		World.Building.FANTASY_VALLEY_SINGLE, World.Building.FANTASY_VALLEY_DOUBLE:
			result = entity_manager.get_building(building)
			pos.x += spacing * rng.randf_range(-0.25, 0.25)
			pos.z += spacing * rng.randf_range(-0.25, 0.25)
			result.name = World.Building.keys()[building] + str(rng.randi())
			ground_angle = PI / 8
		World.Building.FANTASY_WELL:
			result = entity_manager.get_building(building)
			pos.x += spacing * rng.randf_range(-0.25, 0.25)
			pos.z += spacing * rng.randf_range(-0.25, 0.25)
			result.name = World.Building.keys()[building] + str(rng.randi())
			ground_angle = PI / 16
	(result as Buildings).setup(rng)
	return prepare_entity(state, result, pos, false, on_flat_surface(ground_angle))
	
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
	
func spawn_all_into_world(state: PhysicsDirectSpaceState3D) -> Array[Node3D]:
	const spacing = 16.0
	var areas := group_spawn_points(spacing)
	var points: Array[PackedVector2Array] = areas["points"]
	var biomes: Array[World.Biome] = areas["biomes"]

	var result: Array[Node3D] = []
	for i in range(biomes.size()):
		match biomes[i]:
			World.Biome.GRASSLAND: result.append_array(GrasslandGen.populate(self, state, points[i], spacing))
			World.Biome.FOREST: result.append_array(ForestGen.populate(self, state, points[i], spacing))
	
	return result
	
func despawn_all_from_world(world: Node3D) -> void:
	for habitant_index: int in inhabitants:
		var habitant: Enemy = inhabitants[habitant_index]
		habitant.spell_caster.free_particles()
		entity_manager.free_enemy(habitant)
	for f in garden:
		if f is Trees:
			entity_manager.free_tree(f as Trees)
		elif f is Buildings:
			entity_manager.free_building(f as Buildings)
	inhabitants.clear()
	garden.clear()

func update_info() -> void:
	for habitant_index: int in inhabitants:
		var habitant: Enemy = inhabitants[habitant_index]
		var dist: float = habitant.position.distance_to(player.position) 
		var col: CollisionShape3D = habitant.get_node("./Collision")
		var area: CollisionShape3D = habitant.get_node("./WetArea/WetCollision")
		col.disabled = dist > 50
		area.disabled = col.disabled
	
	for g in garden:
		var s: CollisionShape3D = g.get_node("./static/shape")
		if s != null:
			s.disabled = g.position.distance_to(player.position) > 50
				

func habitant_vitals_update(index: int, vitals: Vitals) -> void:
	if index <= -1:
		return
	if vitals.health.value <= vitals.health.min_value:
		inhabitants[index].index_in_population = -1
		inhabitants.erase(index)


func update_pause_time(pause_time: float) -> void:
	for habitant_index: int in inhabitants:
		var habitant: Enemy = inhabitants[habitant_index]
		habitant.spell_caster.update_pause_time(pause_time)
