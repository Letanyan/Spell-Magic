class_name Population

var rng: RandomNumberGenerator
var chunker: Terrain
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

func _init(_coord: Vector2, _chunk_size: float, _chunker: Terrain, _blender: NoiseBlender, _player: Player, _entity_manager: EntityManager) -> void:
	rng = RandomNumberGenerator.new()
	coord = _coord
	chunker = _chunker
	blender = _blender
	player = _player
	chunk_size = _chunk_size
	entity_manager = _entity_manager
	seed_location()
	SignalBus.enemy_death.connect(mark_entity)
	
func seed_location() -> void:
	rng.seed = hash("%f,%f" % [coord.x, coord.y])
	
func do_nothing(entity: Node3D) -> void:
	pass
	
func always_valid(normal: Dictionary) -> Dictionary:
	return {"valid": true}
	
func on_flat_surface(distance: float) -> Callable:
	return func(normal: Dictionary) -> Dictionary:
		return {"valid": (normal.get("normal", Vector3.ZERO) as Vector3).angle_to(Vector3.UP) < distance, "y_offset": distance * -2}
	
func set_world_ground(state: PhysicsDirectSpaceState3D, pos: Vector2) -> Vector3:
	var result := Vector3(pos.x, 0, pos.y)
	#var world_normal := Navigator.get_world_normal_height(state, pos.x, pos.y)
	var world_normal := chunker.terrain_normal(pos.x, pos.y)
	var wh: float = world_normal.get("position", Vector3.ZERO).y + pos.y
	result.y = wh
	return result
	
func prepare_entity(state: PhysicsDirectSpaceState3D, entity: Node3D, pos: Vector3, is_enemy: bool, user_info: Callable) -> Node3D:
	if entity != null:
		var world_normal := chunker.terrain_normal(pos.x, pos.z)
		#var world_normal := Navigator.get_world_normal_height(state, pos.x, pos.z)
		var wh: float = world_normal.get("position", Vector3.ZERO).y + pos.y
		var info: Dictionary = user_info.call(world_normal)
		var below_sea_level := (world_normal.get("position", Vector3.ZERO) as Vector3).y < blender.sea_level
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
			entity.name = World.Enemy.keys()[(entity as Enemy).kind] + Globals.encode_v3(entity.position) + Rand.id(5, rng)
			var is_marked := entity_name_is_marked(entity.name) # check if this enemy has already been killed
			if is_marked:
				entity_manager.free_enemy(entity as Enemy)
				return null
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
				entity.name = World.Item.keys()[(entity as WorldItem).kind] + Globals.encode_v3(entity.position) + Rand.id(5, rng)
				var is_marked := entity_name_is_marked(entity.name)
				if is_marked:
					entity_manager.free_world_item(entity as WorldItem)
					return null
				world_items.append(entity) 
				match (entity as WorldItem).kind:
					World.Item.ARTIFACT: SignalBus.pick_up_world_item_artifact.connect(func(a: Artifact, message: String) -> void: mark_entity(entity))
					World.Item.SPELL: SignalBus.pick_up_world_item_spell.connect(func(a: Spell, message: String) -> void: mark_entity(entity))
					World.Item.COIN: SignalBus.pick_up_world_item_coin.connect(func(a: Array[int], message: String) -> void: mark_entity(entity))
					World.Item.KEY: SignalBus.pick_up_world_item_key.connect(func(a: int, message: String) -> void: mark_entity(entity))
					World.Item.HEALTH: SignalBus.pick_up_world_item_red_cross.connect(func(a: float, message: String) -> void: mark_entity(entity))
					World.Item.NOTE: SignalBus.pick_up_world_item_scroll_note.connect(func(id: String, message: String) -> void: mark_entity(entity))
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
	var result := entity_manager.get_world_item(item) as WorldItem
	var pos := Vector3(p.x, 0, p.y)
	
	if item == World.Item.TARGET:
		var temp := result as TargetShape
		temp.configure(config)
	
	return prepare_entity(state, result, pos, false, always_valid)
	
func spawn_spawner(item: World.Item, p: Vector2, value: Variant) -> ItemSpawner:
	var result: ItemSpawner
	var world_normal := chunker.terrain_normal(p.x, p.y)
	var wh: float = world_normal.get("position", Vector3.ZERO).y
	var pos := Vector3(p.x, wh, p.y)
	match item:
		World.Item.ARTIFACT: result = ItemSpawner.artifact_spawner(self, pos, value as Artifact)
		World.Item.SPELL: result = ItemSpawner.spell_spawner(self, pos, value as Spell)
		World.Item.KEY: result = ItemSpawner.key_spawner(self, pos, value as int)
		World.Item.COIN: result = ItemSpawner.coins_spawner(self, pos, value as Array[int])
		World.Item.HEALTH: result = ItemSpawner.health_spawner(self, pos, value as float)
		World.Item.NOTE: result = ItemSpawner.note_spawner(self, pos, value as String)
		
	result.name = World.Item.keys()[item] + "Spawner" + Globals.encode_v3(pos) + Rand.id(5, rng)
	# if the spawner has already been consumed don't create a new one.
	# IMPORTANT: Even if the spawner is consumed the generation algorithm must 
	#            still assume the spawner exists. We do this to maintain the RNG
	#            state.
	if entity_name_is_marked(result.name):
		return null
		
	return result
	
static func contains_neighbour_point(collection: PackedVector2Array, point: Vector2, spacing: float) -> bool:
	for pidx in range(collection.size() - 1, -1, -1):
		if collection[pidx].distance_squared_to(point) <= spacing * spacing:
			return true
	return false
	
func group_spawn_points(spacing: float) -> Dictionary:
	var result: Array[PackedVector2Array] = []
	var biomes: Array[World.Biome] = []
	var points := PackedVector2Array([])
	var b := 0
	var offsetv := coord * chunk_size
	var biome_map := chunker.get_biomes_map(offsetv)
	var point_offset := Vector2(chunker.height_map_scale * 0.5, chunker.height_map_scale * 0.5)
	for vp in chunker.get_chunk_vertices():
		var p := -Vec2.xz(vp) + point_offset + offsetv
		points.append(p)
		var biome := biome_map[b] as World.Biome
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
		b += 1
				
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
		# FIXME: pass level to all populate calls
		match biomes[i]:
			World.Biome.GRASSLAND: result.append_array(GrasslandGen.populate(self, state, points[i], spacing))
			World.Biome.FOREST: result.append_array(ForestGen.populate(self, state, points[i], spacing))
			World.Biome.JUNGLE: result.append_array(JungleGen.populate(self, state, points[i], spacing))
			World.Biome.HFIL: result.append_array(HFILGen.populate(self, state, points[i], spacing))
			
	#var high_watermark := result.size() - 1	
	#for i in result.size():
		#if result[i] == null:
			#result[i] = result[high_watermark]
			#high_watermark -= 1
			#if high_watermark <= 0:
				#break
				#
	#if high_watermark < result.size() - 1:
		#result = result.slice(0, high_watermark + 1)
	
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
		habitant.animation_tree.active = dist < 50
	
	for g in garden:
		var s: CollisionShape3D = g.get_node("./static/shape")
		if s != null and (g as Foliage).collision_is_active:
			s.disabled = g.position.distance_to(player.position) > 50
			
	for item in world_items:
		if item is TargetShape:
			if (item as TargetShape).puzzle_kind == TargetShape.PuzzleKind.PLATFORM:
				(item.get_node("./static/shape") as CollisionShape3D).disabled = item.position.distance_to(player.position) > maxf((item as TargetShape).bounds.length() * 1.25, 50)
			else:
				(item.get_node("./area/shape") as CollisionShape3D).disabled = item.position.distance_to(player.position) > 50
		else:
			(item.get_node("./Area3D/CollisionShape3D") as CollisionShape3D).disabled = item.position.distance_to(player.position) > 50
		
		if item is TargetShape and (item as TargetShape).puzzle_kind == TargetShape.PuzzleKind.PLATFORM:
			item.is_active = item.position.distance_to(player.position) < maxf((item as TargetShape).bounds.length() * 1.25, 50) and not player.world_settings.is_paused
			if item.is_active:
				player.watch_target(item as TargetShape)
			else:
				player.ignore_target(item as TargetShape)
		else:
			item.is_active = item.position.distance_to(player.position) < 50 and not player.world_settings.is_paused
			

func habitant_vitals_update(index: int, vitals: Vitals) -> void:
	if index <= -1:
		return
	if vitals.health.value <= vitals.health.min_value:
		inhabitants[index].index_in_population = -1
		inhabitants.erase(index)

func mark_entity(entity: Node3D) -> void:
	mark_entity_name(entity.name)

func mark_entity_name(name: String) -> void:
	if not player.world_settings.marked_entities.has(coord):
		player.world_settings.marked_entities[coord] = []
	(player.world_settings.marked_entities[coord] as Array[String]).append(name)
	
func entity_name_is_marked(name: String) -> bool:
	return (player.world_settings.marked_entities.get(coord, []) as Array[String]).find(name) != -1
