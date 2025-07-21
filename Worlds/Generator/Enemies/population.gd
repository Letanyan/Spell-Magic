class_name Population

var rng: RandomNumberGenerator
var chunker: Chunker
var blender: NoiseBlender
var player: Player
var entity_manager: EntityManager
var display_only: bool
var spawn_enemies_in_display_only: bool
var foliage_manager: Foliage

var coord: Vector2i
var chunk_size: float

var is_ready := false

var inhabitants: Dictionary = {}
var garden: Array[Vector2i] = []
var garden_item_radius: PackedFloat32Array = PackedFloat32Array([])
var garden_item_origin: Array[Vector3] = []
var other_objects: Array = []
var world_items: Array[WorldItem] = []
var buildings: Array[Building] = []
var current_biome_during_generation: World.Biome = World.Biome.WATER
var current_fl_during_generation: float = 0.0
#var spawn_areas: Dictionary ## {"points": [][]Vector2, "biomes": []World.Biome} // groups of points categoriesed by biomes
var spawn_area_biomes: Array[World.Biome]
var spawn_area_points: Array[PackedVector2Array]
var spawn_point_spacing: float = 16.0

# x = index into current biome, y = index into current point in biome indexed by x. 
# See spawn_areas: x indexes the top level of points and biomes, while y indexes the second level of points
var spawn_cursor := Vector2i.ZERO
var current_spawn_start_time_us: int = 0 # gets reset each generation cycle. Only to be used by generators to track whether the limit has been reached for this frame
var current_spawn_duration_us: int = 0 # gets reset each generation cycle. Only to be used by generators to track whether the limit has been reached for this frame
var generators: Array[BiomeGenerator] = []

var inhabitant_cursor := 0

func _init(version: int, _coord: Vector2i, _chunk_size: float, _chunker: Chunker, _blender: NoiseBlender, _player: Player, _entity_manager: EntityManager, _display_only: bool) -> void:
	rng = RandomNumberGenerator.new()
	coord = _coord
	chunker = _chunker
	blender = _blender
	player = _player
	chunk_size = _chunk_size
	entity_manager = _entity_manager
	display_only = _display_only
	if display_only:
		foliage_manager = entity_manager.buffer_foliage_lod1
	else:
		foliage_manager = entity_manager.buffer_foliage_lod0
	seed_location()
	SignalBus.enemy_death.connect(mark_entity)
	#SignalBus.pick_up_world_item_artifact.connect(func(entity: ArtifactCube, a: Artifact, message: String) -> void: mark_entity(entity))
	#SignalBus.pick_up_world_item_spell.connect(func(entity: SpellPaper, a: Spell, message: String) -> void: mark_entity(entity))
	#SignalBus.pick_up_world_item_coin.connect(func(entity: CoinDisc, a: int, message: String) -> void: mark_entity(entity))
	#SignalBus.pick_up_world_item_key.connect(func(entity: KeyPrism, a: int, message: String) -> void: mark_entity(entity))
	#SignalBus.pick_up_world_item_red_cross.connect(func(entity: RedCross, a: float, message: String) -> void: mark_entity(entity))
	#SignalBus.pick_up_world_item_scroll_note.connect(func(entity: ScrollNote, id: String, message: String) -> void: mark_entity(entity))
	#SignalBus.pick_up_world_item_flag.connect(func(entity: Flag, tag: int, message: String) -> void: mark_entity(entity))
	SignalBus.pick_up_world_item_artifact.connect(mark_world_item_entity)
	SignalBus.pick_up_world_item_spell.connect(mark_world_item_entity)
	SignalBus.pick_up_world_item_coin.connect(mark_world_item_entity)
	SignalBus.pick_up_world_item_key.connect(mark_world_item_entity)
	SignalBus.pick_up_world_item_red_cross.connect(mark_world_item_entity)
	SignalBus.pick_up_world_item_scroll_note.connect(mark_world_item_entity)
	SignalBus.pick_up_world_item_flag.connect(mark_world_item_entity)
	match version:
		1: build_generators_version1()
		_: build_generators_version1()
	
			
func build_generators_version1() -> void:
	for b: World.Biome in World.Biome.values():
		match b:
			World.Biome.GRASSLAND: generators.append(GrasslandGen.new())
			World.Biome.FOREST: generators.append(ForestGen.new())
			World.Biome.HFIL: generators.append(HFILGen.new())
			World.Biome.TUNDRA: generators.append(TundraGen.new())
			World.Biome.JUNGLE: generators.append(JungleGen.new())
			World.Biome.SAVANNAH: generators.append(SavannahGen.new())
			World.Biome.TAIGA: generators.append(TaigaGen.new())
			World.Biome.DESERT: generators.append(DesertGen.new())
			World.Biome.OTHERWORLD: generators.append(OtherworldGen.new())
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
	
func get_ground_level(pos: Vector2, offset: float = 0.0) -> Vector3:
	var result := Vector3(pos.x, 0, pos.y)
	#var world_normal := Navigator.get_world_normal_height(state, pos.x, pos.y)
	var world_normal := chunker.terrain_normal(pos.x, pos.y)
	var wh: float = world_normal.get("position", Vector3.ZERO).y
	result.y = wh + offset
	return result
	
func get_flat_ground(center: Vector2, offset_y: float, r: float, rang: RandomNumberGenerator) -> Vector3:
	var max_check := 16
	var best := INF
	var result := Vector3(center.x, 0, center.y)
	for i in max_check:
		var pos := Vector3(center.x, 0, center.y) + Vec3.polar(r, TAU * rang.randf(), 0)
		var world_normal := chunker.terrain_normal(pos.x, pos.z)
		var wh: float = world_normal.get("position", Vector3.ZERO).y
		var norm: Vector3 = world_normal.get("normal", Vector3.UP)
		var angle := absf(Vector3.UP.angle_to(norm))
		if angle < best:
			best = angle
			if not is_nan(wh):
				result = Vector3(pos.x, wh + offset_y, pos.z)
	return result
	
func prepare_foliage(kind: World.Foliage, index: int, pos: Vector3, user_info: Callable, seedling: int, config: Dictionary) -> int:
	current_spawn_duration_us = Time.get_ticks_usec() - current_spawn_start_time_us
	if index != -1:
		var world_normal := chunker.terrain_normal(pos.x, pos.z)
		#var world_normal := Navigator.get_world_normal_height(state, pos.x, pos.z)
		var wh: float = world_normal.get("position", Vector3.ZERO).y + pos.y
		var info: Dictionary = user_info.call(world_normal)
		var below_sea_level := (world_normal.get("position", Vector3.ZERO) as Vector3).y < blender.sea_level
		var not_hfil := current_biome_during_generation != World.Biome.HFIL
		if not info.get("valid", true) or (below_sea_level and not_hfil) or is_nan(wh):
			foliage_manager.remove(kind, index)
			#print(info, " or (", below_sea_level, " and ", not_hfil, ") or ", world_normal)
			return -1
		var position := Vec3.xz_y(pos, wh + info.get("y_offset", 0.0) as float)
		foliage_manager.set_albedo_blend(kind, index, chunker.get_color_at_position(position.x, position.z))
		foliage_manager.setup(kind, index, position, seedling, current_biome_during_generation, config)
		var g := Vector2i(kind, index)
		var t := foliage_manager.get_transform(g.x, g.y)
		garden.append(g)
		garden_item_origin.append(t.origin)
		garden_item_radius.append(foliage_manager.get_scaled_shape_length(g, t))
		
		
	#current_iteration_spawn_count += 1
	return index
	
func prepare_world_item(entity: WorldItem, pos: Vector3, user_info: Callable, seedling: int, should_free: bool = false) -> Node3D:
	current_spawn_duration_us = Time.get_ticks_usec() - current_spawn_start_time_us
	if entity != null:
		var world_normal := chunker.terrain_normal(pos.x, pos.z)
		#var world_normal := Navigator.get_world_normal_height(state, pos.x, pos.z)
		var wh: float = world_normal.get("position", Vector3.ZERO).y + pos.y
		var info: Dictionary = user_info.call(world_normal)
		var below_sea_level := (world_normal.get("position", Vector3.ZERO) as Vector3).y < blender.sea_level
		var not_hfil := current_biome_during_generation != World.Biome.HFIL
		if not info.get("valid", true) or (below_sea_level and not_hfil) or is_nan(wh):
			entity_manager.free_world_item(entity)
			return null
		entity.set_base_position(Vector3(pos.x, wh + info.get("y_offset", 0.0) as float, pos.z))
		var scur := Globals.Ref.new(seedling)
		entity.setup(Rand.randi(scur), current_biome_during_generation)
		entity.name = str(entity.kind) + "_" + Rand.id(4, Rand.randi(scur))
		var is_marked := entity_name_is_marked(entity.name)
		if is_marked or should_free:
			entity_manager.free_world_item(entity)
			return null
		world_items.append(entity) 
	return entity
	
func prepare_building(building: Building, pos: Vector3, user_info: Callable, seedling: int) -> Node3D:
	current_spawn_duration_us = Time.get_ticks_usec() - current_spawn_start_time_us
	if building != null:
		var world_normal := chunker.terrain_normal(pos.x, pos.z)
		#var world_normal := Navigator.get_world_normal_height(state, pos.x, pos.z)
		var wh: float = world_normal.get("position", Vector3.ZERO).y + pos.y
		var info: Dictionary = user_info.call(world_normal)
		var below_sea_level := (world_normal.get("position", Vector3.ZERO) as Vector3).y < blender.sea_level
		var not_hfil := current_biome_during_generation != World.Biome.HFIL
		if not info.get("valid", true) or (below_sea_level and not_hfil) or is_nan(wh):
			entity_manager.free_building(building)
			return null
		building.position = Vector3(pos.x, wh + info.get("y_offset", 0.0) as float, pos.z)
		if building.kind == World.Building.TOWER_BASE:
			building.position.y -= building.scale.x * 0.2
		var scur := Globals.Ref.new(seedling)
		#building.setup(Rand.randi(scur), current_biome_during_generation)
		building.name = str(building.kind) + "_" + Rand.id(4, Rand.randi(scur))
		buildings.append(building)
	return building
	
func prepare_enemy(entity: Enemy, pos: Vector3, is_enemy: World.Enemy, user_info: Callable, seedling: int, should_free: bool = false) -> Node3D:
	current_spawn_duration_us = Time.get_ticks_usec() - current_spawn_start_time_us
	if entity != null:
		var world_normal := chunker.terrain_normal(pos.x, pos.z)
		#var world_normal := Navigator.get_world_normal_height(state, pos.x, pos.z)
		var wh: float = world_normal.get("position", Vector3.ZERO).y + pos.y
		var info: Dictionary = user_info.call(world_normal)
		var below_sea_level := (world_normal.get("position", Vector3.ZERO) as Vector3).y < blender.sea_level
		var not_hfil := current_biome_during_generation != World.Biome.HFIL
		var is_fish := (is_enemy != World.Enemy.NONE) and (entity is Fish or entity is Fishman)
		if not info.get("valid", true) or (below_sea_level and not_hfil and not is_fish) or is_nan(wh):
			if is_enemy != World.Enemy.NONE:
				entity_manager.free_enemy(entity, is_enemy)
			return null
		entity.position.x = pos.x
		entity.position.y = wh + info.get("y_offset", 0.0)
		entity.position.z = pos.z
		if is_enemy != World.Enemy.NONE:
			entity.player = player
			entity.index_in_population = inhabitants.size()
			entity.is_dead = false
			entity.velocity_movement.current_biome = current_biome_during_generation
			# unfortunately the order of setup enemy must come before name generation as we must maintain
			# the rng state across generations.
			var scur := Globals.Ref.new(seedling)
			entity.setup(Rand.randi(scur), current_biome_during_generation)
			entity.name = str(entity.kind) + "_" + Rand.id(4, Rand.randi(scur))
			var is_marked := entity_name_is_marked(entity.name) # check if this enemy has already been killed
			if is_marked or should_free:
				entity_manager.free_enemy(entity)
				return null
			inhabitants[inhabitants.size()] = entity
	return entity
	
func spawn_enemy(enemy: World.Enemy, p: Vector2, spacing: float) -> Enemy:
	var seedling := rng.randi()
	if display_only and not spawn_enemies_in_display_only: return null
	var result := entity_manager.get_enemy(enemy)
	result.process_mode = Node.PROCESS_MODE_INHERIT
	result.show()
	var pos := Vector3(p.x, 0, p.y)
	result.set_level(level_relative_to_position(rng, p.x, p.y))
	for conn: Dictionary in result.vital_update.get_connections():
		result.vital_update.disconnect(conn["callable"] as Callable)
	result.vital_update.connect(habitant_vitals_update)
	return prepare_enemy(result, pos, enemy, always_valid, seedling)
	
static func generate_enemy(enemy: World.Enemy, _player: Player, x: float, y: float, z: float, lvl: int = 1) -> Enemy:
	var result := Enemy.make(enemy)
	result.name = World.Enemy.keys()[enemy] + "_" + Rand.id(4, Time.get_ticks_usec())
	result.set_level(lvl)
	result.player = _player
	result.position = Vector3(x, y, z)
	result.setup(0, World.Biome.WATER)
	return result


func spawn_foliage(foliage: World.Foliage, p: Vector2, config: Dictionary, user_info: Callable = on_flat_surface(PI / 8)) -> int:
	var seedling := rng.randi()
	if not display_only: return -1
	var pos := Vector3(p.x, 0, p.y)
	var result := foliage_manager.make(foliage)
	var scur := Globals.Ref.new(seedling)
	pos.x += config["spacing"] * Rand.randf_range(scur, -0.5, 0.5)
	pos.z += config["spacing"] * Rand.randf_range(scur, -0.5, 0.5)
	return prepare_foliage(foliage, result, pos, user_info, scur.data as int, config)
	
func spawn_world_item(item: World.Item, p: Vector2, spacing: float, config: Dictionary, should_free: bool = false) -> Node3D:
	var seedling := rng.randi()
	if display_only and not spawn_enemies_in_display_only: return null
	var result := entity_manager.get_world_item(item) as WorldItem
	var pos := Vector3(p.x, 0, p.y)
	
	if item == World.Item.TARGET:
		var temp := result as TargetShape
		temp.configure(config)
	
	return prepare_world_item(result, pos, always_valid, seedling, should_free)
	
func spawn_building(building: World.Building, p: Vector2, spacing: float, config: Dictionary) -> Node3D:
	var seedling := rng.randi()
	if display_only and not spawn_enemies_in_display_only: return null
	var result := entity_manager.get_building(building, config) as Building
	var pos := Vector3(p.x, 0, p.y)
	
	result.scale = Vec3.a(config.get("scale", 1.0) as float)
	result.rotate(Vector3.UP, config.get("rot_y", 0.0) as float)
	
	return prepare_building(result, pos, always_valid, seedling)
	
func spawn_spawner(item: World.Item, p: Vector2, value: Variant) -> ItemSpawner:
	var seedling := rng.randi()
	if display_only and not spawn_enemies_in_display_only: return null
	var result: ItemSpawner
	var world_normal := chunker.terrain_normal(p.x, p.y)
	var wh: float = world_normal.get("position", Vector3.ZERO).y
	var pos := Vector3(p.x, wh + 2.0, p.y)
	match item:
		World.Item.ARTIFACT: result = ItemSpawner.artifact_spawner(self, pos, value as Artifact)
		World.Item.SPELL: result = ItemSpawner.spell_spawner(self, pos, value as Spell)
		World.Item.KEY: result = ItemSpawner.key_spawner(self, pos, value as int)
		World.Item.COIN: result = ItemSpawner.coins_spawner(self, pos, value as Array[int])
		World.Item.HEALTH: result = ItemSpawner.health_spawner(self, pos, value as float)
		World.Item.NOTE: result = ItemSpawner.note_spawner(self, pos, value as String)
		World.Item.FLAG: result = ItemSpawner.flag_spawner(self, pos, value as int)
		
	result.name = str(item) + "_" + Rand.id(3, seedling)
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
	
func setup_spawning_state(spawn_enemies: bool = false, spacing: float = 16.0) -> void:
	spawn_enemies_in_display_only = spawn_enemies
	if spawn_enemies:
		foliage_manager = entity_manager.buffer_foliage_lod0
	else:
		foliage_manager = entity_manager.buffer_foliage_lod1
	spawn_point_spacing = spacing
	rng.seed = hash(coord)
	var spawn_areas := chunker.group_spawn_points(coord, spawn_point_spacing)
	spawn_area_points = spawn_areas["points"]
	spawn_area_biomes = spawn_areas["biomes"]
	current_fl_during_generation = minf(fmod(level_relative_to_position(rng, coord.x * chunk_size, coord.y * chunk_size), 101.0) / 100.0, 1.0)
	spawn_cursor = Vector2i.ZERO
	for b: World.Biome in World.Biome.values():
		generators[b].setup_state(self) 
	
func is_spawning_complete() -> bool:
	return spawn_cursor.x == spawn_area_biomes.size()
	
func spawn_into_world(start_time_us: int, limit: int) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var i := spawn_cursor.x
	var j := Globals.Ref.new(spawn_cursor.y)
	current_spawn_start_time_us = start_time_us
	current_spawn_duration_us = Time.get_ticks_usec() - current_spawn_start_time_us
	while i < spawn_area_biomes.size() and current_spawn_duration_us < limit:
		current_biome_during_generation = spawn_area_biomes[i]
		result.append_array(generators[current_biome_during_generation].populate(self, spawn_area_points[i], j, limit, rng, spawn_point_spacing))
		if j.data == spawn_area_points[i].size():
			i += 1
			j.data = 0
			
	spawn_cursor.x = i
	spawn_cursor.y = j.data
	if is_spawning_complete():
		spawn_enemies_in_display_only = false
		display_only = false
	return result
	
func despawn_all_from_world(world: Node3D, active_enemy_kinds: Dictionary, hud: HUD) -> void:
	for habitant_index: int in inhabitants:
		var habitant: Enemy = inhabitants[habitant_index]
		habitant.spell_caster.free_particles()
		active_enemy_kinds[habitant.kind] -= 1
		if active_enemy_kinds[habitant.kind] < 0:
			active_enemy_kinds[habitant.kind] = 0
		entity_manager.free_enemy(habitant)
	for f in garden:
		var clr := Color(0, 0, 0)
		foliage_manager.set_albedo_blend(f.x, f.y, clr) 
		foliage_manager.remove(f.x, f.y)
		foliage_manager.free_static_body(f)
	for item in world_items:
		if item is ScrollNote or item is ArtifactCube or item is SpellPaper:
			hud.remove_marker(item.name)
		entity_manager.free_world_item(item)
	for building in buildings:
		entity_manager.free_building(building)
	other_objects.clear()
	inhabitants.clear()
	garden.clear()
	garden_item_radius.clear()
	garden_item_origin.clear()
	world_items.clear()
	buildings.clear()
	spawn_cursor.x = spawn_area_biomes.size()
	SignalBus.enemy_death.disconnect(mark_entity)
	SignalBus.pick_up_world_item_artifact.disconnect(mark_world_item_entity)
	SignalBus.pick_up_world_item_spell.disconnect(mark_world_item_entity)
	SignalBus.pick_up_world_item_coin.disconnect(mark_world_item_entity)
	SignalBus.pick_up_world_item_key.disconnect(mark_world_item_entity)
	SignalBus.pick_up_world_item_red_cross.disconnect(mark_world_item_entity)
	SignalBus.pick_up_world_item_scroll_note.disconnect(mark_world_item_entity)
	SignalBus.pick_up_world_item_flag.disconnect(mark_world_item_entity)

func update_enemies(delta: float) -> void:
	if display_only: return
	
	var timer := Time.get_ticks_usec()
	#Enemy.p_movement.reset()
	#Enemy.p_nav.reset()
	#Enemy.p_path.reset()
	#Enemy.p_anim.reset()
	for i in range(inhabitant_cursor, inhabitants.size()):
		var habitant: Enemy = inhabitants[inhabitants.keys()[i]]
		habitant.manual_physics_process(delta)
		inhabitant_cursor += 1
		if Time.get_ticks_usec() - timer > 500:
			break
	#if Enemy.p_movement.seconds() + Enemy.p_nav.seconds() + Enemy.p_path.seconds() + Enemy.p_anim.seconds() > 0.25:
		#print("movement: ", Enemy.p_movement.elapsed, ", nav: ", Enemy.p_nav.elapsed, ", path: ", Enemy.p_path.elapsed, ", anim: ", Enemy.p_anim.elapsed)
		
	if inhabitant_cursor >= inhabitants.size():
		inhabitant_cursor = 0

func update_info(world: Node3D, cam: Camera3D) -> void:
	if display_only: return
	
	for habitant: Enemy in inhabitants.values():
		var dist: float = habitant.global_position.distance_to(player.global_position) 
		habitant.collision.disabled = dist > 50
		habitant.area.disabled = habitant.collision.disabled
		if habitant.is_node_ready():
			habitant.animation_tree.active = dist < chunker.chunk_width * 1.5 and cam.is_position_in_frustum(habitant.global_position)
	
	for g: Vector2i in foliage_manager.static_body_map:
		var t := foliage_manager.get_transform(g.x, g.y)
		var mxb := foliage_manager.get_scaled_shape_length(g, t)
		if t.origin.distance_to(player.position) > 50 + mxb * 2.0:
			foliage_manager.free_static_body(g)
		
	var i := 0
	for g: Vector2i in garden:
		var pos := garden_item_origin[i]
		var mxb := garden_item_radius[i]
		if foliage_manager.uses_static_body(g) and pos.distance_to(player.position) <= 50 + mxb * 2.0:
			var s := foliage_manager.get_collision_shape(g)
			if s == null:
				var body := foliage_manager.make_static_body(g)
				if body.get_parent() == null:
					world.add_child(body)
				s = body.get_node("shape") as CollisionShape3D
			s.disabled = false
				
		i += 1

			
	for item in world_items:
		if item is TargetShape:
			if (item as TargetShape).puzzle_kind == TargetShape.PuzzleKind.PLATFORM:
				(item.get_node("./static/shape") as CollisionShape3D).disabled = display_only or item.position.distance_to(player.position) > (item as TargetShape).bounds.length() * 1.25 + 50
			elif (item as TargetShape).puzzle_kind != TargetShape.PuzzleKind.EMPTY:
				(item.get_node("./area/shape") as CollisionShape3D).disabled = display_only or item.position.distance_to(player.position) > 50
		else:
			(item.get_node("./area/shape") as CollisionShape3D).disabled = display_only or item.position.distance_to(player.position) > 50
		
		if item is TargetShape and (item as TargetShape).puzzle_kind == TargetShape.PuzzleKind.PLATFORM:
			item.is_active = not display_only and item.position.distance_to(player.position) < (item as TargetShape).bounds.length() * 2.0 + 50 and not player.world_settings.is_paused
			if item.is_active:
				player.watch_target(item as TargetShape)
			else:
				player.ignore_target(item as TargetShape)
		else:
			item.is_active = not display_only and item.position.distance_to(player.position) < 50 and not player.world_settings.is_paused
			
	for building in buildings:
		var body := building.get_node("./static/") as Node3D
		var is_in_range := building.position.distance_to(player.position) > 50
		for shape in body.get_children():
			if shape is CollisionShape3D:
				(shape as CollisionShape3D).disabled = display_only or is_in_range
		building.is_active = not display_only and building.position.distance_to(player.position) < 50 and not player.world_settings.is_paused
		if building.has_node("./static_csg/"):
			var csg := building.get_node("./static_csg/") as CSGShape3D
			csg.use_collision = not (display_only or is_in_range)
			if building.kind == World.Building.TOWER_BASE:
				for child in building.get_children():
					if child is Building and child.has_node("./static_csg/"):
						var icsg := child.get_node("./static_csg/") as CSGShape3D
						icsg.use_collision = not (display_only or is_in_range)
						
			
			
			
func habitant_set_display_only(only_display: bool, active_enemy_kinds: Dictionary, hud: HUD) -> void:
	display_only = only_display
	if display_only:
		for habitant_index: int in inhabitants:
			var habitant: Enemy = inhabitants[habitant_index]
			habitant.spell_caster.free_particles()
			active_enemy_kinds[habitant.kind] -= 1
			if active_enemy_kinds[habitant.kind] < 0:
				active_enemy_kinds[habitant.kind] = 0
			entity_manager.free_enemy(habitant)
		for item in world_items:
			if item is ScrollNote or item is ArtifactCube or item is SpellPaper:
				hud.remove_marker(item.name)
			entity_manager.free_world_item(item)
		inhabitants.clear()
		world_items.clear()
		other_objects.clear()
	else:
		setup_spawning_state()

func habitant_vitals_update(index: int, vitals: Vitals) -> void:
	if index <= -1:
		return
	if vitals.health.value <= vitals.health.min_value:
		inhabitants[index].index_in_population = -1
		inhabitants.erase(index)

func mark_entity(entity: Node3D) -> void:
	mark_entity_name(entity.name)
	
func mark_world_item_entity(entity: WorldItem, x: Variant, y: Variant) -> void:
	mark_entity_name(entity.name)

func mark_entity_name(name: String) -> void:
	if not player.world_settings.marked_entities.has(coord):
		player.world_settings.marked_entities[coord] = []
	(player.world_settings.marked_entities[coord] as Array[String]).append(name)
	
func entity_name_is_marked(name: String) -> bool:
	return (player.world_settings.marked_entities.get(coord, []) as Array[String]).find(name) != -1

static func curve_for_difficulty(difficulty: int, x: float) -> float:
	match difficulty:
		0: return 1.0 - pow(1.0 - x, 0.25)
		1: return 1.0 - pow(1.0 - x, 0.33)
		2: return 1.0 - pow(1.0 - x, 0.50)
		3: return 1.0 - pow(1.0 - x, 1.00)
		4: return 1.0 - pow(1.0 - x, 1.50)
	return 1.0 - pow(1.0 - x, 0.5)

static func level_relative_to_position_within_radius(rang: RandomNumberGenerator, x: float, z: float, world_radius: float, difficulty_curve: int, world_level: int = 1) -> float:
	var p := clampf(Vector2(x, z).length() / world_radius + (0.3 if GlobalData.is_demo else 0.0), 0.0, 1.0)
	var base := Population.curve_for_difficulty(difficulty_curve, p) * 90
	var offset_max_range := 10.0 * sin(p * PI * 10.0)
	var random_offset := 0.0
	if rang == null:
		random_offset = 0
	else:
		random_offset = rang.randf_range(0.0, absf(offset_max_range))
	var result := maxf(base + random_offset, 1.0) + (world_level - 1) * 100.0
	return result
	
func level_relative_to_position(rang: RandomNumberGenerator, x: float, z: float) -> float:
	return Population.level_relative_to_position_within_radius(rang, x, z, blender.world_radius, player.world_settings.difficulty_level, player.world_settings.world_level)

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
	
func artier(cls: int) -> Vector2i:
	var p := cls / 20.0
	var sides := fiti(1, 10) * (1 if randf() < p else -1)
	var count := roundi(p * 4) + 1
	return Vector2i(sides, count)

# number of coins dropped. cls = [1,5]
func cns(cls: int) -> Array[int]:
	var count := Rand.roll(3, fiti(1, cls), 0, rng)
	var result: Array[int] = []
	for i in count:
		result.append(Rand.roll(10, fiti(1, cls * 2), 0, rng))
	return result
