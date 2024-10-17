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
var current_biome_during_generation: World.Biome = World.Biome.WATER

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
	if base != 1.0:
		push_error("sum of probs must equal 1.0")
	
	return default
	
func do_nothing(entity: Node3D) -> void:
	pass
	
func always_valid(normal: Dictionary) -> Dictionary:
	return {"valid": true}
	
func on_flat_surface(distance: float) -> Callable:
	return func(normal: Dictionary) -> Dictionary:
		return {"valid": (normal.get("normal", Vector3.ZERO) as Vector3).angle_to(Vector3.UP) < distance, "y_offset": distance * -2}
	
func set_world_ground(state: PhysicsDirectSpaceState3D, pos: Vector2) -> Vector3:
	var result := Vector3(pos.x, 0, pos.y)
	var world_normal := Navigator.get_world_normal_height(state, pos.x, pos.y)
	var wh: float = world_normal.get("position", Vector3.ZERO).y + pos.y
	result.y = wh
	return result
	
func prepare_entity(state: PhysicsDirectSpaceState3D, entity: Node3D, pos: Vector3, is_enemy: bool, user_info: Callable) -> Node3D:
	if entity != null:
		var world_normal := Navigator.get_world_normal_height(state, pos.x, pos.z)
		var wh: float = world_normal.get("position", Vector3.ZERO).y + pos.y
		var info: Dictionary = user_info.call(world_normal)
		var below_sea_level := (world_normal.get("position", Vector3.ZERO) as Vector3).y < Globals.sea_level()
		var not_hfil := current_biome_during_generation != World.Biome.HFIL
		var is_fish := is_enemy and (entity is Fish or entity is Fishman)
		if not info.get("valid", true) or (below_sea_level and not_hfil and not is_fish):
			if is_enemy:
				entity_manager.free_enemy(entity as Enemy)
			else:
				if entity is Foliage:
					entity_manager.free_foliage(entity as Foliage)
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
			# unfortunately the order of setup enemy must come before name generation as we must maintain
			# the rng state across generations.
			(entity as Enemy).setup(rng.randi(), current_biome_during_generation)
			entity.name = World.Enemy.keys()[(entity as Enemy).kind] + Globals.encode_v3(entity.position)
			var is_marked := entity_name_is_marked(entity.name) # check if this enemy has already been killed
			if is_marked:
				entity_manager.free_enemy(entity as Enemy)
				return null
			else:
				inhabitants[inhabitants.size()] = entity
		else:
			if entity is Foliage:
				(entity as Foliage).setup(rng, current_biome_during_generation)
				entity.name = World.Foliage.keys()[(entity as Foliage).kind] + Globals.encode_v3(entity.position)
				garden.append(entity)
			elif entity is Buildings:
				(entity as Buildings).setup(rng, current_biome_during_generation)
				entity.name = World.Building.keys()[(entity as Buildings).entity_kind] + Globals.encode_v3(entity.position)
				garden.append(entity)
			elif entity is WorldItem:
				(entity as WorldItem).setup(rng, current_biome_during_generation)
				entity.name = World.Item.keys()[(entity as WorldItem).kind] + Globals.encode_v3(entity.position)
				world_items.append(entity)
	return entity
	
func spawn_enemy(enemy: World.Enemy, state: PhysicsDirectSpaceState3D, p: Vector2, spacing: float) -> Enemy:
	var result := entity_manager.get_enemy(enemy)
	var pos := Vector3(p.x, 0, p.y)
	result.set_level_relative_to_location(rng, p.x, p.y)
	for conn: Dictionary in result.vital_update.get_connections():
		result.vital_update.disconnect(conn["callable"] as Callable)
	result.vital_update.connect(habitant_vitals_update)
	return prepare_entity(state, result, pos, true, always_valid)
	
static func generate_enemy(enemy: World.Enemy, _player: Player, x: float, y: float, z: float) -> Enemy:
	var result := Enemy.make(enemy)
	result.name = World.Enemy.keys()[enemy] + Globals.encode_v3(Vector3(x, y, z))
	result.set_level_relative_to_location(null, x, y)
	result.player = _player
	result.position = Vector3(x, y, z)
	result.setup(0, World.Biome.WATER)
	return result


func spawn_foliage(foliage: World.Foliage, state: PhysicsDirectSpaceState3D, p: Vector2, spacing: float, user_info: Callable = on_flat_surface(PI / 8)) -> Node3D:
	var result: Node3D = null
	var pos := Vector3(p.x, 0, p.y)
	result = entity_manager.get_foliage(foliage) as Foliage
	pos.x += spacing * rng.randf_range(-0.5, 0.5)
	pos.z += spacing * rng.randf_range(-0.5, 0.5)
	return prepare_entity(state, result, pos, false, user_info)
	
func spawn_building(building: World.Building, state: PhysicsDirectSpaceState3D, p: Vector2, spacing: float) -> Node3D:
	var result: Node3D = null
	var pos := Vector3(p.x, 0, p.y)
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
	
func spawn_world_item(item: World.Item, state: PhysicsDirectSpaceState3D, p: Vector2, spacing: float, config: Dictionary) -> Node3D:
	var result: Node3D = entity_manager.get_world_item(item)
	var pos := Vector3(p.x, 0, p.y)
	
	if item == World.Item.TARGET:
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
		current_biome_during_generation = biomes[i]
		match biomes[i]:
			World.Biome.GRASSLAND: result.append_array(GrasslandGen.populate(self, state, points[i], spacing))
			World.Biome.FOREST: result.append_array(ForestGen.populate(self, state, points[i], spacing))
			World.Biome.JUNGLE: result.append_array(JungleGen.populate(self, state, points[i], spacing))
			
	var high_watermark := result.size() - 1	
	for i in result.size():
		if result[i] == null:
			result[i] = result[high_watermark]
			high_watermark -= 1
			if high_watermark <= 0:
				break
				
	if high_watermark < result.size() - 1:
		result = result.slice(0, high_watermark + 1)
	
	return result
	
func despawn_all_from_world(world: Node3D) -> void:
	for habitant_index: int in inhabitants:
		var habitant: Enemy = inhabitants[habitant_index]
		habitant.spell_caster.free_particles()
		entity_manager.free_enemy(habitant)
	for f in garden:
		if f is Foliage:
			entity_manager.free_foliage(f as Foliage)
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
		if item is TargetShape:
			if (item as TargetShape).puzzle_kind == TargetShape.PuzzleKind.PLATFORM:
				(item.get_node("./static/shape") as CollisionShape3D).disabled = item.position.distance_to(player.position) > 50
			else:
				(item.get_node("./area/shape") as CollisionShape3D).disabled = item.position.distance_to(player.position) > 50
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
