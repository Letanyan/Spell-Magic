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
var garden: Array[Vector2i] = []
var other_objects: Array = []
var world_items: Array[WorldItem] = []
var current_biome_during_generation: World.Biome = World.Biome.WATER
var current_fl_during_generation: float = 0.0
#var spawn_areas: Dictionary ## {"points": [][]Vector2, "biomes": []World.Biome} // groups of points categoriesed by biomes
var spawn_area_biomes: Array[World.Biome]
var spawn_area_points: Array[Array]
var spawn_point_spacing: float = 16.0

# x = index into current biome, y = index into current point in biome indexed by x. 
# See spawn_areas: x indexes the top level of points and biomes, while y indexes the second level of points
var spawn_cursor := Vector2i.ZERO
var current_iteration_spawn_count: int = 0 # gets reset each generation cycle. Only to be used by generators to track whether the limit has been reached for this frame
var generators: Array[BiomeGenerator] = [] 

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
	for b: World.Biome in World.Biome.values():
		match b:
			World.Biome.GRASSLAND: generators.append(GrasslandGen.new())
			World.Biome.FOREST: generators.append(ForestGen.new())
			World.Biome.HFIL: generators.append(HFILGen.new())
			World.Biome.TUNDRA: generators.append(TundraGen.new())
			World.Biome.JUNGLE: generators.append(JungleGen.new())
			_: generators.append(BiomeGenerator.new())
	
func seed_location() -> void:
	rng.seed = hash("%f,%f" % [coord.x, coord.y])
	
func do_nothing(entity: Node3D) -> void:
	pass
	
func always_valid(normal: Dictionary) -> Dictionary:
	return {"valid": true}
	
func on_flat_surface(distance: float) -> Callable:
	return func(normal: Dictionary) -> Dictionary:
		return {"valid": (normal.get("normal", Vector3.ZERO) as Vector3).angle_to(Vector3.UP) < distance, "y_offset": distance * -2}
	
func set_world_ground(pos: Vector2) -> Vector3:
	var result := Vector3(pos.x, 0, pos.y)
	#var world_normal := Navigator.get_world_normal_height(state, pos.x, pos.y)
	var world_normal := chunker.terrain_normal(pos.x, pos.y)
	var wh: float = world_normal.get("position", Vector3.ZERO).y + pos.y
	result.y = wh
	return result
	
func prepare_foliage(kind: World.Foliage, index: int, pos: Vector3, user_info: Callable) -> int:
	current_iteration_spawn_count += 1
	if index != -1:
		var world_normal := chunker.terrain_normal(pos.x, pos.z)
		#var world_normal := Navigator.get_world_normal_height(state, pos.x, pos.z)
		var wh: float = world_normal.get("position", Vector3.ZERO).y + pos.y
		var info: Dictionary = user_info.call(world_normal)
		var below_sea_level := (world_normal.get("position", Vector3.ZERO) as Vector3).y < blender.sea_level
		var not_hfil := current_biome_during_generation != World.Biome.HFIL
		if not info.get("valid", true) or (below_sea_level and not_hfil) or is_nan(wh):
			entity_manager.buffer_foliage.remove(kind, index)
			return -1
		var position := Vec3.xz_y(pos, wh + info.get("y_offset", 0.0) as float)
		entity_manager.buffer_foliage.setup(kind, index, position, rng, current_biome_during_generation)
		blender.compute_biome_distances(position.x, position.z, chunker.get_noise_scale())
		entity_manager.buffer_foliage.set_albedo_blend(kind, index, blender.color)
		garden.append(Vector2i(kind, index))
		
	#current_iteration_spawn_count += 1
	return index
	
func prepare_entity(entity: Node3D, pos: Vector3, is_enemy: bool, user_info: Callable) -> Node3D:
	current_iteration_spawn_count += 1
	if entity != null:
		var world_normal := chunker.terrain_normal(pos.x, pos.z)
		#var world_normal := Navigator.get_world_normal_height(state, pos.x, pos.z)
		var wh: float = world_normal.get("position", Vector3.ZERO).y + pos.y
		var info: Dictionary = user_info.call(world_normal)
		var below_sea_level := (world_normal.get("position", Vector3.ZERO) as Vector3).y < blender.sea_level
		var not_hfil := current_biome_during_generation != World.Biome.HFIL
		var is_fish := is_enemy and (entity is Fish or entity is Fishman)
		if not info.get("valid", true) or (below_sea_level and not_hfil and not is_fish) or is_nan(wh):
			if is_enemy:
				entity_manager.free_enemy(entity as Enemy)
			else:
				if entity is Buildings:
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
			(entity as Enemy).velocity_movement.current_biome = current_biome_during_generation
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
			if entity is WorldItem:
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
					
	#current_iteration_spawn_count += 1
	return entity
	
func spawn_enemy(enemy: World.Enemy, p: Vector2, spacing: float) -> Enemy:
	var result := entity_manager.get_enemy(enemy)
	var pos := Vector3(p.x, 0, p.y)
	result.set_level(level_relative_to_position(rng, p.x, p.y))
	for conn: Dictionary in result.vital_update.get_connections():
		result.vital_update.disconnect(conn["callable"] as Callable)
	result.vital_update.connect(habitant_vitals_update)
	return prepare_entity(result, pos, true, always_valid)
	
static func generate_enemy(enemy: World.Enemy, _player: Player, x: float, y: float, z: float) -> Enemy:
	var result := Enemy.make(enemy)
	result.name = World.Enemy.keys()[enemy] + Globals.encode_v3(Vector3(x, y, z))
	result.set_level(1)
	result.player = _player
	result.position = Vector3(x, y, z)
	result.setup(0, World.Biome.WATER)
	return result


func spawn_foliage(foliage: World.Foliage, p: Vector2, spacing: float, user_info: Callable = on_flat_surface(PI / 8)) -> int:
	var pos := Vector3(p.x, 0, p.y)
	var result := entity_manager.get_foliage(foliage)
	pos.x += spacing * rng.randf_range(-0.5, 0.5)
	pos.z += spacing * rng.randf_range(-0.5, 0.5)
	return prepare_foliage(foliage, result, pos, user_info)
	
func spawn_world_item(item: World.Item, p: Vector2, spacing: float, config: Dictionary) -> Node3D:
	var result := entity_manager.get_world_item(item) as WorldItem
	var pos := Vector3(p.x, 0, p.y)
	
	if item == World.Item.TARGET:
		var temp := result as TargetShape
		temp.configure(config)
	
	return prepare_entity(result, pos, false, always_valid)
	
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
		
	# we don't increment the count becuase it isn't expensive
	#current_iteration_spawn_count += 1
	return result
	
static func contains_neighbour_point(collection: PackedVector2Array, point: Vector2, spacing: float) -> bool:
	return GDTerrain.contains_neighbour_point(collection, point, spacing)
	
func group_spawn_points(spacing: float) -> Dictionary:
	return chunker.backing.group_spawn_points(coord, spacing)
	
static func points_around(point: Vector2, distance: float, offset: int, area: PackedVector2Array, exluding: Dictionary, shuffler: RandomNumberGenerator) -> PackedInt64Array:
	var indices: PackedInt64Array = []
	for i in range(offset, area.size()):
		if point.distance_to(area[i]) < distance and not exluding.has(i):
			indices.append(i)
	if shuffler != null:
		for i in indices.size():
			var temp := indices[i]
			var j := shuffler.randi_range(0, indices.size() - 1)
			indices[i] = indices[j]
			indices[j] = temp
	return indices
	
func setup_spawning_state(spacing: float = 16.0) -> void:
	spawn_point_spacing = spacing
	rng.seed = hash(coord)
	var spawn_areas := group_spawn_points(spawn_point_spacing)
	spawn_area_points = spawn_areas["points"]
	spawn_area_biomes = spawn_areas["biomes"]
	current_fl_during_generation = level_relative_to_position(rng, coord.x * chunk_size, coord.y * chunk_size) / 100.0
	spawn_cursor = Vector2i.ZERO
	
func is_spawning_complete() -> bool:
	return spawn_cursor.x == spawn_area_biomes.size()
	
func spawn_into_world(limit: int = 50) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var i := spawn_cursor.x
	var j := Globals.Ref.new(spawn_cursor.y)
	current_iteration_spawn_count = 0
	while i < spawn_area_biomes.size():
		current_biome_during_generation = spawn_area_biomes[i]
		result.append_array(generators[current_biome_during_generation].populate(self, spawn_area_points[i], j, limit, rng, spawn_point_spacing))
		if j.data == spawn_area_points[i].size():
			i += 1
			j.data = 0
		if current_iteration_spawn_count >= limit:
			break
			
	spawn_cursor.x = i
	spawn_cursor.y = j.data
	return result
	
func despawn_all_from_world(world: Node3D) -> void:
	for habitant_index: int in inhabitants:
		var habitant: Enemy = inhabitants[habitant_index]
		habitant.spell_caster.free_particles()
		entity_manager.free_enemy(habitant)
	for f in garden:
		var clr := Color(0, 0, 0)
		entity_manager.buffer_foliage.set_albedo_blend(f.x, f.y, clr) 
		entity_manager.buffer_foliage.remove(f.x, f.y)
		entity_manager.buffer_foliage.free_static_body(f)
	for item in world_items:
		entity_manager.free_world_item(item)
	other_objects.clear()
	inhabitants.clear()
	garden.clear()
	world_items.clear()
	SignalBus.enemy_death.disconnect(mark_entity)

func update_info(world: Node3D) -> void:
	for habitant_index: int in inhabitants:
		var habitant: Enemy = inhabitants[habitant_index]
		var dist: float = habitant.position.distance_to(player.position) 
		var col: CollisionShape3D = habitant.get_node("./Collision")
		var area: CollisionShape3D = habitant.get_node("./WetArea/WetCollision")
		col.disabled = dist > 50
		area.disabled = col.disabled
		if habitant.is_node_ready():
			habitant.animation_tree.active = dist < 50
	
	for g: Vector2i in garden:
		var t := entity_manager.buffer_foliage.get_transform(g.x, g.y)
		var s := entity_manager.buffer_foliage.get_collision_shape(g)
		if t.origin.distance_to(player.position) > 50: # FIXME: use size of shape in condition
			if s != null:
				entity_manager.buffer_foliage.free_static_body(g)
		else:
			if s == null:
				var body := entity_manager.buffer_foliage.make_static_body(g)
				if body.get_parent() == null:
					world.add_child(body)
				s = body.get_node("shape") as CollisionShape3D
			s.disabled = false

			
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

static func level_relative_to_position_within_radius(rang: RandomNumberGenerator, x: float, z: float, world_radius: float) -> float:
	var p := clampf(Vector2(x, z).length() / world_radius, 0.0, 100.0)
	var base := 45.0 * (log(p + 1.0) / log(10.0))
	var offset_max_range := (p * p) / 10000.0 + 9 * sin(p * PI / 10.0)
	var random_offset := 0.0
	if rang == null:
		random_offset = 0
	else:
		random_offset = rang.randf_range(0.0, absf(offset_max_range))
	var result := maxf(base + random_offset, 1.0)
	return result
	
func level_relative_to_position(rang: RandomNumberGenerator, x: float, z: float) -> float:
	return Population.level_relative_to_position_within_radius(rang, x, z, blender.world_radius)

func fit(mn: float, mx: float) -> float:
	return lerpf(mn, mx, current_fl_during_generation)
	
func fiti(mn: int, mx: int) -> int:
	return roundi(lerpf(mn, mx, current_fl_during_generation))
	
func fits(mn: float, mx: float) -> String:
	return Globals.format_number_nearest_place(lerpf(mn, mx, current_fl_during_generation))
	
## fit between fit(mn_i, mx_i) 
func fita(mn: Array[float], mx: Array[float]) -> Array[float]:
	var result: Array[float] = []
	if mn.size() != mx.size():
		push_error("mn and mx not same size")
		return mn
	for i in mn.size():
		result.append(fit(mn[i], mx[i]))	
	return result
	
## fit between fit(arr_i, arr_i * mult) 
func fitas(mult: float, arr: Array[float]) -> Array[float]:
	var result: Array[float] = []
	for i in arr.size():
		result.append(fit(arr[i], arr[i] * mult))	
	return result
	
## fit between fit(arr_i, arr_i - arr_i * (1 - (1-mult)^exponent))
func fitas_dict(mult: float, dict: Dictionary) -> Dictionary:
	var result := {}
	for k: Variant in dict:
		result[k] = fit(dict[k] as float, (dict[k] as float) * mult)
	return result
	
## fit between fit(arr_i, arr_i - arr_i * (1 - (1-mult)^exponent))
func fitase(mult: float, exponent: float, arr: Array[float]) -> Array[float]:
	var result: Array[float] = []
	for i in arr.size():
		result.append(fit(arr[i], arr[i] - arr[i] * (1 - pow(1 - mult, exponent))))	
	return result
	
# returns the actual value if the enemy with a class (1-20) where 1 is low 
func atk(cls: int) -> float:
	return fit(5.0, cls * 5.0)

func def(cls: int) -> float:
	return fit(5.0, cls * 5.0)
	
func hp(cls: int) -> float:
	return fit(50.0, cls * 50.0)
	
func mana(cls: int) -> float:
	return fit(50.0, cls * 50.0)
	
func mana_regen(cls: int) -> float:
	return fit(5.0, cls * 5.0)

func power(cls: int) -> float:
	return fit(5.0, cls * 5.0)
	
func radius(cls: int) -> float:
	return fit(0.1, minf(cls * cls / 80.0 + 0.875, 5.0))

func res(per_cls: int, flat_cls: int) -> Vector2:
	return Vector2(fit(0.0, per_cls / 20.0), fit(0.0, flat_cls * 5.0))
	
func percep(mncls: int, mxcls: int) -> Vector2:
	var mn := pow(float(mncls) / 20.0, 0.5) * 100
	var mx := pow(float(mxcls) / 20.0, 0.5) * 100
	return Vector2(mn, mx)
	
func atks(mncls: int, mxcls: int) -> String:
	var mn := 1.0 + pow(float(mncls) / 20.0, 1.5) * 31.0
	var mx := 1.0 + pow(float(mxcls) / 20.0, 1.5) * 31.0
	return fits(mn, mx)
	
func runs(cls: int) -> float:
	return fit(0.5, 2.0 + cls*0.5)
	
func dst(cls: int, x1: float, y1: float, z1: float, x2: float, y2: float, z2: float) -> Vector3:
	return Vector3(x1, y1, z1).normalized().lerp(Vector3(x2, y2, z2).normalized(), fit(1, cls * 10))

func timing(cls: int, value: float) -> float:
	var ratio := 1.0 - float(cls) / 20.0
	return fit(value, value * (1.0 + ratio))

func timings(cls: int, array: Array[float]) -> Array[float]:
	var ratio := 1.0 - float(cls) / 20.0
	for i in array.size():
		array[i] = fit(array[i], array[i] * (1.0 + ratio))
	return array

func health_drop(cls: int) -> float:
	return float(cls) / 20.0

func arttv(mn: int, mx: int) -> Vector2i:
	return Vector2i(fiti(0, mn), fiti(0, mx))
	
func arttd(probs: Dictionary) -> Dictionary:
	for t: int in probs:
		var val := probs[t] as float
		probs.erase(t)
		probs[fiti(0, t)] = val
	return probs	
