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
var other_objects: Array = []
var world_items: Array[WorldItem] = []

func _init(_coord: Vector2, _chunk_size: float, _blender: NoiseBlender, _player: Player, _entity_manager: EntityManager) -> void:
	rng = RandomNumberGenerator.new()
	coord = _coord
	blender = _blender
	player = _player
	chunk_size = _chunk_size
	entity_manager = _entity_manager
	seed_location()
	SignalBus.enemy_death.connect(mark_entity)
	
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
		var info: Dictionary = user_info.call(world_normal)
		if not info.get("valid", true):
			if is_enemy:
				entity_manager.free_enemy(entity as Enemy)
			else:
				if entity is Trees:
					entity_manager.free_tree(entity as Trees)
				elif entity is Buildings:
					entity_manager.free_building(entity as Buildings)
				elif entity is WorldItem:
					entity_manager.free_world_item(entity as WorldItem)
			return null
		entity.position.x = pos.x
		entity.position.y = wh + info.get("y_offset", 0.0)
		entity.position.z = pos.z
		if is_enemy:
			(entity as Enemy).player = player
			(entity as Enemy).index_in_population = inhabitants.size()
			(entity as Enemy).is_dead = false
			(entity as Enemy).setup(rng.randi())
			entity.name = World.Enemy.keys()[(entity as Enemy).kind] + " " + str(rng.randi())
			var is_marked := entity_name_is_marked(entity.name)
			if is_marked:
				entity_manager.free_enemy(entity as Enemy)
				return null
			else:
				inhabitants[inhabitants.size()] = entity
		else:
			if entity is Trees:
				(entity as Trees).setup(rng)
				entity.name = World.Foliage.keys()[(entity as Trees).kind] + " " + str(rng.randi())
				garden.append(entity)
			elif entity is Buildings:
				(entity as Buildings).setup(rng)
				entity.name = World.Building.keys()[(entity as Buildings).entity_kind] + " " + str(rng.randi())
				garden.append(entity)
			elif entity is WorldItem:
				(entity as WorldItem).setup()
				entity.name = World.Item.keys()[(entity as WorldItem).kind] + " " + str(rng.randi())
				world_items.append(entity)
	return entity
	
# FIXME: don't spawn enemy if this `enemy: World.Enemy` at this position `x`,`y` has been killed
func spawn_enemy(enemy: World.Enemy, state: PhysicsDirectSpaceState3D, x: float, y: float, spacing: float) -> Enemy:
	var result: Enemy = null
	var pos := Vector3(x, 0, y)
	match enemy:
		World.Enemy.UNDEAD: result = entity_manager.get_enemy(World.Enemy.UNDEAD)
		World.Enemy.BAT: result = entity_manager.get_enemy(World.Enemy.BAT)
		World.Enemy.MOLE: result = entity_manager.get_enemy(World.Enemy.MOLE)
		World.Enemy.WALKER: result = entity_manager.get_enemy(World.Enemy.WALKER)
		World.Enemy.FISH: result = entity_manager.get_enemy(World.Enemy.FISH)
		World.Enemy.BIRDMAN: result = entity_manager.get_enemy(World.Enemy.BIRDMAN)
		World.Enemy.FISHMAN: result = entity_manager.get_enemy(World.Enemy.FISHMAN)
		World.Enemy.DRAGON: result = entity_manager.get_enemy(World.Enemy.DRAGON)
		World.Enemy.DRAGOON: result = entity_manager.get_enemy(World.Enemy.DRAGOON)
		World.Enemy.GHOST: result = entity_manager.get_enemy(World.Enemy.GHOST)
		World.Enemy.GHOSTLY: result = entity_manager.get_enemy(World.Enemy.GHOSTLY)
		World.Enemy.BIRD: result = entity_manager.get_enemy(World.Enemy.BIRD)
		World.Enemy.FUNGI: result = entity_manager.get_enemy(World.Enemy.FUNGI)
		World.Enemy.HOT_BLOB: result = entity_manager.get_enemy(World.Enemy.HOT_BLOB)
		World.Enemy.MUSHROOM: result = entity_manager.get_enemy(World.Enemy.MUSHROOM)
		World.Enemy.BLUEMON: result = entity_manager.get_enemy(World.Enemy.BLUEMON)
		World.Enemy.FROG: result = entity_manager.get_enemy(World.Enemy.FROG)
		World.Enemy.MUSHKING: result = entity_manager.get_enemy(World.Enemy.MUSHKING)
		World.Enemy.RABBIT: result = entity_manager.get_enemy(World.Enemy.RABBIT)
		World.Enemy.BATTY: result = entity_manager.get_enemy(World.Enemy.BATTY)
		World.Enemy.BEE: result = entity_manager.get_enemy(World.Enemy.BEE)
		World.Enemy.BUMBLE_BEE: result = entity_manager.get_enemy(World.Enemy.BUMBLE_BEE)
		World.Enemy.UNDEAD_HEAD: result = entity_manager.get_enemy(World.Enemy.UNDEAD_HEAD)
		World.Enemy.SNOT_BLOB: result = entity_manager.get_enemy(World.Enemy.SNOT_BLOB)
		World.Enemy.SNOT_SPIKE: result = entity_manager.get_enemy(World.Enemy.SNOT_SPIKE)
		World.Enemy.WALKER_HEAD: result = entity_manager.get_enemy(World.Enemy.WALKER_HEAD)
		World.Enemy.WIZARD: result = entity_manager.get_enemy(World.Enemy.WIZARD)
			
	result.set_level_relative_to_location(rng, x, y)
	for conn: Dictionary in result.vital_update.get_connections():
		result.vital_update.disconnect(conn["callable"] as Callable)
	result.vital_update.connect(habitant_vitals_update)
	return prepare_entity(state, result, pos, true)
	
static func generate_enemy(enemy: World.Enemy, _player: Player, x: float, y: float, z: float) -> Enemy:
	var result: Enemy = null
	match enemy:
		World.Enemy.UNDEAD: result = Enemy.make(World.Enemy.UNDEAD)
		World.Enemy.BAT: result = Enemy.make(World.Enemy.BAT)
		World.Enemy.MOLE: result = Enemy.make(World.Enemy.MOLE)
		World.Enemy.WALKER: result = Enemy.make(World.Enemy.WALKER)
		World.Enemy.FISH: result = Enemy.make(World.Enemy.FISH)
		World.Enemy.BIRDMAN: result = Enemy.make(World.Enemy.BIRDMAN)
		World.Enemy.FISHMAN: result = Enemy.make(World.Enemy.FISHMAN)
		World.Enemy.DRAGON: result = Enemy.make(World.Enemy.DRAGON)
		World.Enemy.DRAGOON: result = Enemy.make(World.Enemy.DRAGOON)
		World.Enemy.GHOST: result = Enemy.make(World.Enemy.GHOST)
		World.Enemy.GHOSTLY: result = Enemy.make(World.Enemy.GHOSTLY)
		World.Enemy.BIRD: result = Enemy.make(World.Enemy.BIRD)
		World.Enemy.FUNGI: result = Enemy.make(World.Enemy.FUNGI)
		World.Enemy.HOT_BLOB: result = Enemy.make(World.Enemy.HOT_BLOB)
		World.Enemy.MUSHROOM: result = Enemy.make(World.Enemy.MUSHROOM)
		World.Enemy.BLUEMON: result = Enemy.make(World.Enemy.BLUEMON) 
		World.Enemy.FROG: result = Enemy.make(World.Enemy.FROG) 
		World.Enemy.MUSHKING: result = Enemy.make(World.Enemy.MUSHKING) 
		World.Enemy.RABBIT: result = Enemy.make(World.Enemy.RABBIT)
		World.Enemy.BATTY: result = Enemy.make(World.Enemy.BATTY)
		World.Enemy.BEE: result = Enemy.make(World.Enemy.BEE)
		World.Enemy.BUMBLE_BEE: result = Enemy.make(World.Enemy.BUMBLE_BEE)
		World.Enemy.UNDEAD_HEAD: result = Enemy.make(World.Enemy.UNDEAD_HEAD)
		World.Enemy.SNOT_BLOB: result = Enemy.make(World.Enemy.SNOT_BLOB)
		World.Enemy.SNOT_SPIKE: result = Enemy.make(World.Enemy.SNOT_SPIKE)
		World.Enemy.WALKER_HEAD: result = Enemy.make(World.Enemy.WALKER_HEAD)
		World.Enemy.WIZARD: result = Enemy.make(World.Enemy.WIZARD)
		
	result.name = World.Enemy.keys()[enemy] + str(randi())
			
	result.set_level_relative_to_location(null, x, y)
	result.player = _player
	result.position = Vector3(x, y, z)
	result.setup(0)
	return result


func spawn_foliage(foliage: World.Foliage, state: PhysicsDirectSpaceState3D, x: float, y: float, spacing: float) -> Node3D:
	var result: Node3D = null
	var pos := Vector3(x, 0, y)
	match foliage:
		World.Foliage.TREE_ROUND, World.Foliage.TREE_PYRAMID, World.Foliage.TREE_CHRISTMAS, World.Foliage.TREE_BRANCHED, World.Foliage.TREE_SAFARI:
			result = entity_manager.get_tree(foliage) as Trees
			pos.x += spacing * rng.randf_range(-0.5, 0.5)
			pos.z += spacing * rng.randf_range(-0.5, 0.5)
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
			ground_angle = PI / 8
		World.Building.FANTASY_WELL:
			result = entity_manager.get_building(building)
			pos.x += spacing * rng.randf_range(-0.25, 0.25)
			pos.z += spacing * rng.randf_range(-0.25, 0.25)
			ground_angle = PI / 16
	return prepare_entity(state, result, pos, false, on_flat_surface(ground_angle))
	
func spawn_world_item(item: World.Item, state: PhysicsDirectSpaceState3D, x: float, y: float, spacing: float, config: Dictionary) -> Node3D:
	var result: Node3D = entity_manager.get_world_item(item)
	var pos := Vector3(x, 0, y)
	
	match item:
		World.Item.TARGET:
			var temp := result as TargetShape
			temp.configure(config)
	
	return prepare_entity(state, result, pos, false, always_valid)
	
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
			var found_subsets := PackedInt32Array([])
			for i in range(result.size()):
				if biomes[i] == biome and Population.contains_neighbour_point(result[i], p, spacing):
					found_subsets.append(i)
					break		
			if found_subsets.is_empty():
				result.append(PackedVector2Array([p]))
				biomes.append(biome)
			elif found_subsets.size() == 1:
				result[found_subsets[0]].append(p)
			else:
				found_subsets.sort()
				found_subsets.reverse()
				var new_pack := PackedVector2Array([])
				for subset in found_subsets:
					new_pack.append_array(result[subset])
					result.remove_at(subset)
					biomes.remove_at(subset)
				result.append(new_pack)
				biomes.append(biome)
				
	return {"points": result, "biomes": biomes}
	
static func points_around(point: Vector2, distance: float, offset: int, area: PackedVector2Array, exluding: Dictionary, rang: RandomNumberGenerator) -> PackedInt64Array:
	var indices: PackedInt64Array = []
	for i in range(offset, area.size()):
		if point.distance_to(area[i]) < distance and not exluding.has(i):
			indices.append(i)
	if rang != null:
		for i in indices.size():
			var temp := indices[i]
			var j := rang.randi_range(0, indices.size() - 1)
			indices[i] = indices[j]
			indices[j] = temp
	return indices
	
func spawn_all_into_world(state: PhysicsDirectSpaceState3D) -> Array[Node3D]:
	const spacing = 16.0
	rng.seed = hash(coord)
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
	for item in world_items:
		entity_manager.free_world_item(item)
	other_objects.clear()		
	inhabitants.clear()
	garden.clear()
	world_items.clear()
	SignalBus.enemy_death.disconnect(mark_entity)

func update_info() -> void:
	for habitant_index: int in inhabitants:
		var habitant: Enemy = inhabitants[habitant_index]
		var dist: float = habitant.position.distance_to(player.position) 
		var col: CollisionShape3D = habitant.get_node("./Collision")
		var area: CollisionShape3D = habitant.get_node("./WetArea/WetCollision")
		col.disabled = dist > 50
		area.disabled = col.disabled
		habitant.animation_tree.active = dist < 150
	
	for g in garden:
		var s: CollisionShape3D = g.get_node("./static/shape")
		if s != null:
			s.disabled = g.position.distance_to(player.position) > 50
			
	for item in world_items:
		item.is_active = item.position.distance_to(player.position) < 150 and not player.world_settings.is_paused

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

func mark_entity(entity: Node3D) -> void:
	mark_entity_name(entity.name)
	
func get_tag_from_name(name: String) -> int:
	var tag := name.substr(name.find(" ") + 1)
	if tag.is_valid_int():
		return tag.to_int()
	else:
		return -1

func mark_entity_name(name: String) -> void:
	var tag := get_tag_from_name(name)
	if tag != -1:
		if not player.world_settings.marked_entities.has(coord):
			player.world_settings.marked_entities[coord] = []
		(player.world_settings.marked_entities[coord] as Array[int]).append(tag)
	
func entity_name_is_marked(name: String) -> bool:
	var tag := get_tag_from_name(name)
	return (player.world_settings.marked_entities.get(coord, []) as Array[int]).find(tag) != -1
